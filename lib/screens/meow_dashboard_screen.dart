import '../widgets/bank_badge.dart';
import 'app_features_showcase_screen.dart';
import '../widgets/meow_paywall_modal.dart';
import '../widgets/custom_photo_avatar_dialog.dart';
import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction_item.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../widgets/meow_mascot_widget.dart';
import '../widgets/tactile_button.dart';
import '../widgets/voice_record_modal.dart';
import '../widgets/slip_image_viewer_dialog.dart';
import '../services/native_bridge_service.dart';
import '../services/slip_auto_sync_service.dart';
import 'meow_entry_screen.dart';
import 'meow_analytics_screen.dart';
import 'calendar_overview_screen.dart';
import 'slip_auto_record_screen.dart';
import 'edit_transaction_screen.dart';
import 'app_guide_screen.dart';
import '../widgets/transaction_detail_sheet.dart';
import '../widgets/daily_budget_quota_card.dart';
import '../widgets/meow_wheel_date_picker.dart';
import '../widgets/app_logo_widget.dart';
import '../utils/format_utils.dart';
import '../services/thai_bank_detector.dart';
import '../services/slip_storage_service.dart';

class MeowDashboardScreen extends StatefulWidget {
  final ExpenseController controller;

  const MeowDashboardScreen({super.key, required this.controller});

  static VoidCallback? onScrollToTopRequested;

  @override
  State<MeowDashboardScreen> createState() => _MeowDashboardScreenState();
}

class _MeowDashboardScreenState extends State<MeowDashboardScreen> with WidgetsBindingObserver {
  final GlobalKey _arrowButtonKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  // Batch delete & undo countdown state (3.5s)
  final List<TransactionItem> _pendingDeletedItems = [];
  Timer? _undoTimer;
  double _undoCountdown = 3.5;

  void _handleTransactionDismissed(TransactionItem tx) {
    HapticFeedback.mediumImpact();
    widget.controller.deleteTransaction(tx.id);
    _pendingDeletedItems.add(tx);
    _undoCountdown = 3.5;
    _undoTimer?.cancel();
    _undoTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _undoCountdown = (_undoCountdown - 0.1);
        if (_undoCountdown <= 0.05) {
          timer.cancel();
          _undoTimer = null;
          _pendingDeletedItems.clear();
        }
      });
    });
    setState(() {});
  }

  Future<void> _undoBatchDelete() async {
    HapticFeedback.selectionClick();
    _undoTimer?.cancel();
    _undoTimer = null;
    final itemsToRestore = List<TransactionItem>.from(_pendingDeletedItems);
    _pendingDeletedItems.clear();
    for (final tx in itemsToRestore) {
      await widget.controller.restoreTransaction(tx);
    }
    if (mounted) setState(() {});
  }
  DateTime _currentMonth = DateTime.now();
  String _statusMessage = 'คู่หูพร้อมดักจับสลิปใหม่แบบ Real-time และบันทึกอัตโนมัติแล้วนะ';
  bool _isAutoScanning = false;
  bool _isSortNewestFirst = true;
  late Set<String> _enabledBankCodes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MeowDashboardScreen.onScrollToTopRequested = _scrollToTop;
    _scrollController.addListener(() {
      final show = _scrollController.hasClients && _scrollController.offset > 150;
      if (show != _showScrollToTop && mounted) {
        setState(() => _showScrollToTop = show);
      }
    });

    _enabledBankCodes = ThaiBankDetector.supportedBanks.map((b) => b.code).toSet();
    _enabledBankCodes.add('OTHER');

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // 0. Register Native Reload Trigger
    NativeBridgeService.setDataReloadListener(() {
      if (mounted) _autoScanSlipsInBackground(showFeedback: false);
    });

    // 0.1 Request OS permissions on app launch (Photos, Camera, Audio) for iOS & Android
    await NativeBridgeService.requestAppPermissions();

    // 1. Initial background scan for unimported bank slips with gentle delay (800ms) for smooth startup
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _autoScanSlipsInBackground(showFeedback: false);
      }
    });

    // 2. Setup real-time ContentObserver listener for any new incoming slips!
    SlipAutoSyncService.setupRealtimeSlipObserver(
     widget.controller,
     onNewTransactionCreated: (newItem) {
      if (mounted) {
       setState(() {
        _statusMessage = 'ตรวจพบสลิปใหม่ "${newItem.title}" ฿${newItem.amount.toStringAsFixed(2)} บันทึกแล้ว!';
       });
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
         content: Row(
          children: [
           const Icon(Icons.receipt_long, color: Colors.white),
           const SizedBox(width: 10),
           Expanded(
            child: Text(
             'ดักจับสลิปใหม่และบันทึก ฿${newItem.amount.toStringAsFixed(2)} ลงบัญชีเรียบร้อยแล้ว!',
             style: const TextStyle(fontWeight: FontWeight.bold),
            ),
           ),
          ],
         ),
         backgroundColor: MeowTheme.incomeGreen,
         duration: const Duration(seconds: 4),
        ),
       );
      }
     },
    );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _autoScanSlipsInBackground(showFeedback: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (MeowDashboardScreen.onScrollToTopRequested == _scrollToTop) {
      MeowDashboardScreen.onScrollToTopRequested = null;
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    HapticFeedback.lightImpact();
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _autoScanSlipsInBackground({bool showFeedback = true}) async {
    if (_isAutoScanning) return;
    if (showFeedback) {
      HapticFeedback.mediumImpact();
      setState(() {
        _isAutoScanning = true;
        _statusMessage = 'กำลังค้นหาภาพสลิปใหม่ในเครื่อง...';
      });
    } else {
      _isAutoScanning = true;
    }

  if (showFeedback) {
   ScaffoldMessenger.of(context).hideCurrentSnackBar();
   ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
     content: const Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
       SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
       SizedBox(width: 10),
       Text('กำลังสแกนหาภาพสลิป...', style: TextStyle(fontSize: 13)),
      ],
     ),
     behavior: SnackBarBehavior.floating,
     margin: const EdgeInsets.only(bottom: 90, left: 40, right: 40),
     backgroundColor: const Color(0xFF1E293B),
     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
     duration: const Duration(milliseconds: 1200),
    ),
   );
  }

  try {
    await NativeBridgeService.requestAppPermissions();
    final imported = await SlipAutoSyncService.scanAndAutoImportNewSlips(widget.controller);
   if (!mounted) return;

   if (imported.isNotEmpty) {
    setState(() {
     _statusMessage = 'ตรวจพบและบันทึกสลิปใหม่ ${imported.length} รายการแล้ว!';
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(
      content: Row(
       mainAxisAlignment: MainAxisAlignment.center,
       children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text('ดึงสลิปสำเร็จ ${imported.length} รายการ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
       ],
      ),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(bottom: 90, left: 30, right: 30),
      backgroundColor: MeowTheme.incomeGreen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      duration: const Duration(milliseconds: 1500),
     ),
    );
   } else {
    setState(() {
     _statusMessage = 'สแกนแล้ว ไม่พบสลิปใหม่';
    });
    if (showFeedback) {
     ScaffoldMessenger.of(context).hideCurrentSnackBar();
     ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
       content: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
         Icon(Icons.info_outline, color: MeowTheme.mustardYellow, size: 18),
         SizedBox(width: 8),
         Text('ไม่พบภาพสลิปใหม่ในอัลบั้ม', style: TextStyle(fontSize: 13)),
        ],
       ),
       behavior: SnackBarBehavior.floating,
       margin: const EdgeInsets.only(bottom: 90, left: 40, right: 40),
       backgroundColor: const Color(0xFF1E293B),
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
       duration: const Duration(milliseconds: 1500),
      ),
     );
    }
   }
  } catch (e) {
   if (mounted) {
    setState(() {
     _statusMessage = 'แตะ "ดึงสลิปอัตโนมัติ" หรือกดปุ่ม "จดเพิ่ม" ได้เลย';
    });
    if (showFeedback) {
     ScaffoldMessenger.of(context).hideCurrentSnackBar();
     ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
       content: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
         Icon(Icons.error_outline, color: Colors.orange, size: 18),
         SizedBox(width: 8),
         Text('เกิดข้อผิดพลาดในการเข้าถึงอัลบั้มภาพ', style: TextStyle(fontSize: 13)),
        ],
       ),
       behavior: SnackBarBehavior.floating,
       margin: const EdgeInsets.only(bottom: 90, left: 40, right: 40),
       backgroundColor: const Color(0xFF1E293B),
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
       duration: const Duration(milliseconds: 1500),
      ),
     );
    }
   }
  } finally {
   if (mounted) {
    setState(() {
     _isAutoScanning = false;
    });
   }
  }
 }

 String _getDetectedBankCode(TransactionItem tx) {
  return ThaiBankDetector.detectBankCode(tx, widget.controller.accounts);
 }

 /// All transactions in the current selected month (unfiltered by bank)
 List<TransactionItem> get _allMonthTransactions {
  return widget.controller.allTransactions.where((t) {
   return t.date.year == _currentMonth.year && t.date.month == _currentMonth.month;
  }).toList();
 }

 /// Filtered transactions in the current selected month respecting enabled bank codes
 List<TransactionItem> get _monthlyTransactions {
  final list = _allMonthTransactions.where((t) {
   final bankCode = _getDetectedBankCode(t);
   return _enabledBankCodes.contains(bankCode);
  }).toList();
  if (_isSortNewestFirst) {
   list.sort((a, b) => b.date.compareTo(a.date));
  } else {
   list.sort((a, b) => a.date.compareTo(b.date));
  }
  return list;
 }

 double get _monthlyExpense {
  return _monthlyTransactions
    .where((t) => t.type == TransactionType.expense)
    .fold(0.0, (sum, t) => sum + t.amount);
 }

  double get _monthlyIncome {
   return _monthlyTransactions
     .where((t) => t.type == TransactionType.income)
     .fold(0.0, (sum, t) => sum + t.amount);
  }

  Color get _monthlyExpenseTextColor {
    final currentTheme = widget.controller.currentTheme;
    final income = _monthlyIncome;
    final expense = _monthlyExpense;

    // Detect if current theme's hero header is light-colored or dark-colored
    final lum1 = currentTheme.primaryColor.computeLuminance();
    final lum2 = currentTheme.primaryDark.computeLuminance();
    final avgLum = (lum1 + lum2) / 2.0;
    final bool isHeroLight = avgLum > 0.55;

    // Base color for normal state (when income is healthy)
    final normalColor = isHeroLight ? const Color(0xFF0F172A) : Colors.white;

    if (income <= 0) {
      if (expense > 0) {
        // Red alert adapted to light/dark themes
        return isHeroLight ? const Color(0xFFDC2626) : const Color(0xFFEF4444);
      }
      return normalColor;
    }

    final remaining = income - expense;
    if (remaining <= 0) {
      // รายรับหมดแล้ว หรือ ติดลบ -> สีแดง (เข้มขึ้นบนธีมสว่าง, สดใสบนธีมมืด)
      return isHeroLight ? const Color(0xFFB91C1C) : const Color(0xFFEF4444);
    } else if (remaining <= income * 0.20 || remaining < 500) {
      // รายรับใกล้หมด (เหลือน้อยกว่า 20% หรือ ต่ำกว่า 500 บาท) -> สีเหลือง/อำพัน (ส้มอำพันบนธีมสว่าง, สีทองสว่างบนธีมมืด)
      return isHeroLight ? const Color(0xFFD97706) : const Color(0xFFFDE047);
    } else {
      return normalColor;
    }
  }

 String _formatMonthYear(DateTime d) {
  if (widget.controller.isEnglish) {
   const enMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
   ];
   return '${enMonths[d.month - 1]} ${d.year}';
  }
  const months = [
   'ม.ค.',
   'ก.พ.',
   'มี.ค.',
   'เม.ย.',
   'พ.ค.',
   'มิ.ย.',
   'ก.ค.',
   'ส.ค.',
   'ก.ย.',
   'ต.ค.',
   'พ.ย.',
   'ธ.ค.'
  ];
  final thaiYear = (d.year + 543) % 100;
  return '${months[d.month - 1]} $thaiYear';
 }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  Future<void> _showMonthPickerModal() async {
    HapticFeedback.selectionClick();
    final currentTheme = widget.controller.currentTheme;
    int tempYear = _currentMonth.year;
    int tempMonth = _currentMonth.month;
    final isEng = widget.controller.isEnglish;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          const shortMonths = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
          const fullMonths = [
            'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
            'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
          ];

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: currentTheme.cardBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: currentTheme.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: currentTheme.textSecondaryColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title and Quick Jump to Today
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEng ? 'Select Month & Year' : 'เลือกเดือนและปี',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: currentTheme.textColor,
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: currentTheme.primaryColor.withValues(alpha: 0.12),
                        foregroundColor: currentTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.today_rounded, size: 16),
                      label: Text(
                        isEng ? 'This Month' : 'เดือนนี้ (วันนี้)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        final now = DateTime.now();
                        setState(() {
                          _currentMonth = DateTime(now.year, now.month, 1);
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Year Switcher Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: currentTheme.surfaceBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: currentTheme.borderColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: currentTheme.textColor),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setModalState(() => tempYear--);
                        },
                      ),
                      Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 18, color: currentTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            isEng ? '$tempYear' : 'พ.ศ. ${tempYear + 543} ($tempYear)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: currentTheme.textColor,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: currentTheme.textColor),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setModalState(() => tempYear++);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 12 Months Grid (4x3)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, idx) {
                    final m = idx + 1;
                    final isSel = tempMonth == m && tempYear == _currentMonth.year;
                    final isThisMonth = m == DateTime.now().month && tempYear == DateTime.now().year;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _currentMonth = DateTime(tempYear, m, 1);
                          });
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSel
                                ? currentTheme.primaryColor
                                : (isThisMonth
                                    ? currentTheme.primaryColor.withValues(alpha: 0.15)
                                    : currentTheme.surfaceBackground),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSel
                                  ? currentTheme.primaryColor
                                  : (isThisMonth ? currentTheme.primaryColor : currentTheme.borderColor),
                              width: isSel || isThisMonth ? 1.5 : 1.0,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isEng ? shortMonths[idx] : fullMonths[idx],
                                  style: TextStyle(
                                    fontWeight: isSel || isThisMonth ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 13,
                                    color: isSel
                                        ? Colors.white
                                        : (isThisMonth ? currentTheme.primaryColor : currentTheme.textColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Quick jump to current month (Today) button
                if (_currentMonth.year != DateTime.now().year || _currentMonth.month != DateTime.now().month)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          final now = DateTime.now();
                          setState(() {
                            _currentMonth = DateTime(now.year, now.month, 1);
                          });
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.today_rounded, size: 16),
                        label: Text(isEng ? 'Jump to Current Month (Today)' : 'กลับสู่เดือนปัจจุบัน (วันนี้)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: currentTheme.primaryColor,
                          side: BorderSide(color: currentTheme.primaryColor.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),

                // Wheel Picker Option Link
                TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final picked = await MeowWheelDatePicker.showWheelMonthYearPicker(
                      context: context,
                      initialDate: _currentMonth,
                      isEnglish: isEng,
                      isDarkMode: currentTheme.isDark,
                    );
                    if (picked != null) {
                      setState(() {
                        _currentMonth = picked;
                      });
                    }
                  },
                  icon: Icon(Icons.swap_vert_rounded, size: 16, color: currentTheme.primaryColor),
                  label: Text(
                    isEng ? 'Use Scroll Wheel Picker' : 'เลือกด้วยวงล้อเลื่อน (Wheel Picker)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: currentTheme.primaryColor),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

 Future<void> _pickCustomDate() async {
  _showMonthPickerModal();
 }

 Future<void> _openSlipAutoRecord() async {
  final imagePath = await NativeBridgeService.pickImageFromGallery();
  if (imagePath != null && imagePath.isNotEmpty && mounted) {
   Navigator.push(
    context,
    MaterialPageRoute(
     builder: (_) => SlipAutoRecordScreen(
      controller: widget.controller,
      initialImagePath: imagePath,
     ),
    ),
   );
  }
 }

 void _openVoiceRecording() {
  VoiceRecordModal.show(context, widget.controller);
 }

 void _openCalendarScreen() {
  HapticFeedback.mediumImpact();
  Navigator.push(
   context,
   MaterialPageRoute(
    builder: (_) => CalendarOverviewScreen(controller: widget.controller),
   ),
  );
 }

 void _showFloatingArrowMenu() {
  final isDark = widget.controller.isDarkMode;
  final isEn = widget.controller.isEnglish;
  final currentTheme = widget.controller.currentTheme;
  final cardBg = isDark ? MeowTheme.navySurface : Colors.white;
  final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
  final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

  final renderBox = _arrowButtonKey.currentContext?.findRenderObject() as RenderBox?;
  final buttonPos = renderBox?.localToGlobal(Offset.zero) ?? const Offset(0, 0);

  final screenHeight = MediaQuery.of(context).size.height;
  final bottomOffset = (screenHeight - buttonPos.dy) + 12;

  showGeneralDialog(
   context: context,
   barrierDismissible: true,
   barrierLabel: 'FloatingMenu',
   barrierColor: Colors.transparent,
   transitionDuration: const Duration(milliseconds: 240),
   pageBuilder: (ctx, anim1, anim2) {
    return Stack(
     children: [
      // 1. Blurred Backdrop Overlay
      Positioned.fill(
       child: GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: BackdropFilter(
         filter: ImageFilter.blur(
          sigmaX: 10.0 * anim1.value,
          sigmaY: 10.0 * anim1.value,
         ),
         child: Container(
          color: Colors.black.withValues(alpha: 0.45 * anim1.value),
         ),
        ),
       ),
      ),

      // 2. Floating Menu Card anchored directly at the arrow button
      Positioned(
       right: 20,
       bottom: bottomOffset,
       child: ScaleTransition(
        scale: CurvedAnimation(
         parent: anim1,
         curve: Curves.easeOutBack,
        ),
        alignment: const Alignment(0.85, 1.0),
        child: FadeTransition(
         opacity: anim1,
         child: Material(
          color: Colors.transparent,
          child: Container(
           width: 300,
           decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
             BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
              blurRadius: 28,
              offset: const Offset(0, 10),
             ),
            ],
           ),
           child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
              // Header
              Padding(
               padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
               child: Row(
                children: [
                 const Icon(Icons.flash_on_rounded, color: MeowTheme.mustardYellow, size: 20),
                 const SizedBox(width: 6),
                 Text(
                  isEn ? 'Quick Record Menu' : 'เมนูจดบันทึกด่วน',
                  style: TextStyle(
                   color: textPrimary,
                   fontSize: 14.5,
                   fontWeight: FontWeight.bold,
                  ),
                 ),
                ],
               ),
              ),
              const Divider(height: 1),

              // Option 1: จดบันทึกรายรับ-รายจ่าย (Manual Entry)
              _buildFloatingMenuItem(
               ctx: ctx,
               icon: Icons.edit_note_rounded,
               iconBg: currentTheme.primaryColor.withValues(alpha: 0.15),
               iconColor: currentTheme.primaryColor,
               title: widget.controller.tr('btn_add_record'),
               subtitle: isEn ? 'Manual record with calculator' : 'จดบันทึกด้วยแป้นคิดเลข',
               textPrimary: textPrimary,
               isDark: isDark,
               onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                 context,
                 MaterialPageRoute(
                  builder: (_) => MeowEntryScreen(controller: widget.controller),
                 ),
                );
               },
              ),



              const Divider(height: 1),

              // Option 3: Pick Slip Image (OCR)
              _buildFloatingMenuItem(
               ctx: ctx,
               icon: Icons.receipt_long_rounded,
               iconBg: MeowTheme.actionBlue.withValues(alpha: 0.15),
               iconColor: MeowTheme.actionBlue,
               title: widget.controller.tr('btn_upload_slip'),
               subtitle: isEn ? 'Pick slip image from gallery' : 'เลือกรูปสลิปจากคลังภาพ (OCR)',
               textPrimary: textPrimary,
               isDark: isDark,
               onTap: () {
                Navigator.pop(ctx);
                _openSlipAutoRecord();
               },
              ),

              const Divider(height: 1),

              // Option 4: Auto Pull Bank Slips
              _buildFloatingMenuItem(
               ctx: ctx,
               icon: Icons.sync_rounded,
               iconBg: MeowTheme.incomeGreen.withValues(alpha: 0.15),
               iconColor: MeowTheme.incomeGreen,
               title: widget.controller.tr('btn_auto_pull_slips'),
               subtitle: isEn ? 'Scan slips from bank & PaoTang' : 'ดึงสลิปจากอัลบั้มธนาคาร & เป๋าตัง',
               textPrimary: textPrimary,
               isDark: isDark,
               onTap: () {
                Navigator.pop(ctx);
                _autoScanSlipsInBackground();
               },
              ),

              const Divider(height: 1),

              // Option 4: Voice STT with AI
              _buildFloatingMenuItem(
               ctx: ctx,
               icon: Icons.mic,
               iconBg: const Color(0xFFF59E0B).withOpacity(0.15),
               iconColor: const Color(0xFFF59E0B),
               title: isEn ? 'Voice Record with AI' : 'พูดเพื่อจดบันทึกด้วย AI',
               subtitle: isEn ? 'Speak expense e.g. "Lunch 60"' : 'พูดสั้นๆ เช่น "กินข้าว 60 บาท"',
               textPrimary: textPrimary,
               isDark: isDark,
               onTap: () {
                Navigator.pop(ctx);
                _openVoiceRecording();
               },
              ),
             ],
            ),
           ),
          ),
         ),
        ),
       ),
      ),
     ],
    );
   },
  );
 }

 Widget _buildFloatingMenuItem({
  required BuildContext ctx,
  required IconData icon,
  required Color iconBg,
  required Color iconColor,
  required String title,
  required String subtitle,
  required Color textPrimary,
  required bool isDark,
  required VoidCallback onTap,
  String? badgeText,
  Color? badgeColor,
 }) {
  return InkWell(
   onTap: () {
    HapticFeedback.lightImpact();
    onTap();
   },
   child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(
     children: [
      Container(
       padding: const EdgeInsets.all(8),
       decoration: BoxDecoration(
        color: iconBg,
        borderRadius: BorderRadius.circular(10),
       ),
       child: Icon(icon, color: iconColor, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
       child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Row(
          children: [
           Text(
            title,
            style: TextStyle(
             color: textPrimary,
             fontSize: 13,
             fontWeight: FontWeight.bold,
            ),
           ),
           if (badgeText != null) ...[
            const SizedBox(width: 6),
            Container(
             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
             decoration: BoxDecoration(
              color: (badgeColor ?? const Color(0xFF06B6D4)).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
               color: (badgeColor ?? const Color(0xFF06B6D4)).withValues(alpha: 0.5),
               width: 0.8,
              ),
             ),
             child: Text(
              badgeText,
              style: TextStyle(
               color: badgeColor ?? const Color(0xFF06B6D4),
               fontSize: 9.5,
               fontWeight: FontWeight.w900,
              ),
             ),
            ),
           ],
          ],
         ),
         const SizedBox(height: 2),
         Text(
          subtitle,
          style: TextStyle(
           color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
           fontSize: 11,
          ),
         ),
        ],
       ),
      ),
     ],
    ),
   ),
  );
 }

 // Group transactions by date
 Map<String, List<TransactionItem>> get _groupedTransactions {
  final map = <String, List<TransactionItem>>{};
  final now = DateTime.now();
  final todayKey = '${now.year}-${now.month}-${now.day}';
  final yest = now.subtract(const Duration(days: 1));
  final yesterdayKey = '${yest.year}-${yest.month}-${yest.day}';

  for (final tx in _monthlyTransactions) {
   final txKey = '${tx.date.year}-${tx.date.month}-${tx.date.day}';
   String label;
   final yearShort = (tx.date.year + 543).toString().substring(2);
   if (txKey == todayKey) {
    label = 'วันนี้\n${tx.date.day} ${_formatThaiMonthShort(tx.date.month)} \'$yearShort';
   } else if (txKey == yesterdayKey) {
    label = 'เมื่อวาน\n${tx.date.day} ${_formatThaiMonthShort(tx.date.month)} \'$yearShort';
   } else {
    label = '${tx.date.day} ${_formatThaiMonthShort(tx.date.month)}\n\'$yearShort';
   }

   map.putIfAbsent(label, () => []).add(tx);
  }
  return map;
 }

 String _formatThaiMonthShort(int m) {
  const months = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
  return months[m - 1];
 }

 String _formatTime(DateTime d) {
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m';
 }

void _handleMascotPetting() {
  HapticFeedback.mediumImpact();
  final isEn = widget.controller.isEnglish;
  final quotesTh = [
   'ริซกีดีๆ กำลังเข้ามาหาคุณเหมียว~ ',
   'วันนี้เก่งมาก บันทึกครบถ้วนเลยนะเหมียว! ',
   'มีวินัยทางการเงินแบบนี้ รวยแน่นอนเหมียว~ ',
   'เหมียวเป็นกำลังใจให้เสมอ ลุยต่อเลย! ',
   'ออมเงินวันละนิด เพื่ออนาคตที่สดใสเหมียว~ ',
  ];
  final quotesEn = [
   'Good Rizqi & blessings are on the way! ',
   'Awesome job tracking your finances today! ',
   'Consistent savings build true wealth! ',
   'Meow is always cheering for you! ',
   'Keep up the great financial discipline! ',
  ];
  final randomQuote = (isEn ? quotesEn : quotesTh)[DateTime.now().microsecond % quotesTh.length];

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
   SnackBar(
    content: Row(
     children: [
      const Text(' ', style: TextStyle(fontSize: 18)),
      Expanded(child: Text(randomQuote, style: const TextStyle(fontWeight: FontWeight.bold))),
     ],
    ),
    backgroundColor: const Color(0xFF0F172A),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    duration: const Duration(seconds: 2),
   ),
  );
 }

 @override
 Widget build(BuildContext context) {
  final currentTheme = widget.controller.currentTheme;
  final isDark = widget.controller.isDarkMode;
  final bgColor = currentTheme.scaffoldBackground;
  final cardBg = currentTheme.cardBackground;
  final textPrimary = currentTheme.textColor;
  final borderColor = currentTheme.borderColor;

  return Scaffold(
   backgroundColor: bgColor,
   body: Stack(
    children: [
      RefreshIndicator(
       onRefresh: _autoScanSlipsInBackground,
       child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: EdgeInsets.zero,
        children: [
        // Top Bar with App Brand
        Container(
         color: bgColor,
         padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 6,
          left: 20,
          right: 20,
          bottom: 4,
         ),
         child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           // Avatar & Actions Row
           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
             Row(
              children: [
               Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                 color: isDark ? MeowTheme.navyCard : Colors.white,
                 borderRadius: BorderRadius.circular(14),
                 border: Border.all(color: borderColor),
                ),
                child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                  const AppLogoWidget(
                   size: 22,
                   borderRadius: 6,
                   withBorder: false,
                  ),
                  const SizedBox(width: 8),
                  Text(widget.controller.tr('app_name'), style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                 ],
                ),
               ),
              ],
             ),
             Row(
               children: [
                // Quota capsule for free users (0/15)
                if (!widget.controller.isPremium)
                  Builder(
                    builder: (context) {
                      final monthlyUsed = widget.controller.currentMonthSlipCount;
                      final monthlyMax = widget.controller.maxFreeSlipsPerMonth;
                      final isLimitReached = monthlyUsed >= monthlyMax;

                      final labelText = '$monthlyUsed/$monthlyMax';
                      final reasonText = 'โควต้าสลิปฟรีเดือนนี้: $monthlyUsed/$monthlyMax สลิป (รีเซ็ตเป็น 0/$monthlyMax ทุกวันที่ 1) ปลดล็อค VIP เพื่อสแกนไม่จำกัด 👑';

                      return InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          MeowPaywallModal.show(
                            context,
                            controller: widget.controller,
                            reason: reasonText,
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: (isLimitReached ? Colors.redAccent : Colors.blueGrey).withValues(alpha: isDark ? 0.22 : 0.14),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: (isLimitReached ? Colors.redAccent : Colors.blueGrey).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                color: isLimitReached ? Colors.redAccent : Colors.blueGrey,
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                labelText,
                                style: TextStyle(
                                  color: isLimitReached ? Colors.redAccent : (isDark ? Colors.white70 : Colors.black87),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                // App Guide Button (คู่มือและวิธีใช้งานแอพ)
                IconButton(
                 icon: Icon(Icons.help_outline_rounded, color: currentTheme.primaryColor, size: 24),
                tooltip: widget.controller.isEnglish ? 'User Guide' : 'คู่มือและวิธีใช้งานแอพ',
                onPressed: () {
                 Navigator.push(
                  context,
                  MaterialPageRoute(
                   builder: (_) => AppFeaturesShowcaseScreen(controller: widget.controller, isFromOverview: true),
                  ),
                 );
                },
               ),
              ],
             ),
            ],
           ),
          ],
         ),
        ),

        // Account bar removed per user request
        // Main Theme Highlight Card
        RepaintBoundary(
          child: Container(
            margin: const EdgeInsets.only(left: 20, right: 20, top: 2, bottom: 8),
              decoration: BoxDecoration(
                gradient: currentTheme.heroGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: currentTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 16, top: 16, bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Month and Expense Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Modern Glassmorphic Month Bar (with Tactile Nav Buttons, Today quick-badge)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Previous Month Button
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)),
                                            onTap: () {
                                              HapticFeedback.lightImpact();
                                              _prevMonth();
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                              child: Icon(Icons.chevron_left_rounded, color: Colors.white, size: 22),
                                            ),
                                          ),
                                        ),
                                        Container(width: 1, height: 16, color: Colors.white.withValues(alpha: 0.2)),
                                        // Month & Year Picker Button
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              HapticFeedback.selectionClick();
                                              _showMonthPickerModal();
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.calendar_month_rounded, size: 15, color: Colors.white),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    _formatMonthYear(_currentMonth),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w800,
                                                      letterSpacing: -0.2,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.white),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(width: 1, height: 16, color: Colors.white.withValues(alpha: 0.2)),
                                        // Next Month Button
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(13)),
                                            onTap: () {
                                              HapticFeedback.lightImpact();
                                              _nextMonth();
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                              child: Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                                child: KeyedSubtree(
                                  key: ValueKey('${_currentMonth.year}_${_currentMonth.month}'),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            widget.controller.tr('this_month_expense'),
                                            style: TextStyle(
                                              color: (currentTheme.primaryColor.computeLuminance() > 0.55) ? Colors.black54 : Colors.white70,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          // Small Privacy Eye Toggle Button
                                          GestureDetector(
                                            onTap: () {
                                              HapticFeedback.selectionClick();
                                              widget.controller.toggleHideBalance();
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 0.18),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    widget.controller.isHideBalance
                                                        ? Icons.visibility_off_rounded
                                                        : Icons.visibility_rounded,
                                                    size: 13,
                                                    color: Colors.white,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (_monthlyIncome > 0 && (_monthlyIncome - _monthlyExpense) <= 0) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                                              ),
                                              child: const Text(
                                                'รายรับหมดแล้ว 🚨',
                                                style: TextStyle(color: Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ] else if (_monthlyIncome > 0 && ((_monthlyIncome - _monthlyExpense) <= _monthlyIncome * 0.20 || (_monthlyIncome - _monthlyExpense) < 500)) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                                              ),
                                              child: const Text(
                                                'รายรับใกล้หมด ⚠️',
                                                style: TextStyle(color: Color(0xFFFDE047), fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          widget.controller.isHideBalance
                                              ? '•••••• ฿'
                                              : '${CurrencyFormat.format(_monthlyExpense)} ฿',
                                          style: TextStyle(
                                            color: _monthlyExpenseTextColor,
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                            shadows: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.18),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      // Small compact monthly income pill
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.7),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.arrow_downward, color: Color(0xFF34D399), size: 10),
                                            const SizedBox(width: 3),
                                            Text(
                                              widget.controller.isHideBalance
                                                  ? '${widget.controller.isEnglish ? "Income" : "รายรับเดือนนี้"}: •••••• ฿'
                                                  : '${widget.controller.isEnglish ? "Income" : "รายรับเดือนนี้"}: ฿${CurrencyFormat.format(_monthlyIncome)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 11),
                            // Action Pill Buttons Row (Analytics + Calendar side-by-side)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Summary Pill Button
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MeowAnalyticsScreen(controller: widget.controller),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.pie_chart, color: currentTheme.primaryDark, size: 14),
                                          const SizedBox(width: 5),
                                          Text(
                                            widget.controller.tr('view_analytics'),
                                            style: TextStyle(
                                              color: currentTheme.primaryDark,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Calendar Pill Button
                                  GestureDetector(
                                    onTap: _openCalendarScreen,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.22),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            widget.controller.isEnglish ? 'Calendar' : 'ปฏิทิน',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right: Mascot Cat with visible Camera Badge
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          MeowMascotWidget(
                            size: 100,
                            withPen: true,
                            mascotId: widget.controller.selectedMascotId,
                            accessory: widget.controller.selectedMascotAccessory,
                            customPhotoPath: widget.controller.customAvatarPath,
                            isCustomPhoto: widget.controller.isCustomAvatarEnabled,
                            mood: widget.controller.mascotMood,
                            onTap: _handleMascotPetting,
                          ),
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                CustomPhotoAvatarDialog.show(
                                  context,
                                  widget.controller,
                                  onSaved: (_) => setState(() {}),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Quick Financial Overview inside Card (Yearly Income & Yearly Expense in Compact Style)
                Container(
                  margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Builder(
                    builder: (context) {
                      final selectedYear = _currentMonth.year;
                      final yearlyIncome = widget.controller.getYearlyIncome(selectedYear);
                      final yearlyExpense = widget.controller.getYearlyExpense(selectedYear);
                      final isEn = widget.controller.isEnglish;
                      final yearLabel = isEn ? '$selectedYear' : 'ปี ${selectedYear + 543}';

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_downward, color: Color(0xFF34D399), size: 13),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${isEn ? "Yearly Income" : "รายรับ"}($yearLabel): ฿${CurrencyFormat.format(yearlyIncome)}',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 14, color: Colors.white.withValues(alpha: 0.3)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Icon(Icons.arrow_upward, color: Color(0xFFFCA5A5), size: 13),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '${isEn ? "Yearly Expense" : "รายจ่าย"}($yearLabel): ฿${CurrencyFormat.format(yearlyExpense)}',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // Quick Back to Today Button (Only shown when viewing other months)
                if (_currentMonth.year != DateTime.now().year || _currentMonth.month != DateTime.now().month)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        final now = DateTime.now();
                        setState(() {
                          _currentMonth = DateTime(now.year, now.month, 1);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.today_rounded, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              widget.controller.isEnglish ? 'Back to this month (Today)' : 'กลับสู่เดือนนี้ (วันนี้)',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Quick Action Bar (Voice + Auto-Sync)
        Padding(
         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
         child: Row(
          children: [
           Expanded(
            child: TactileButton(
             onTap: _openVoiceRecording,
             child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
               color: cardBg,
               borderRadius: BorderRadius.circular(14),
               border: Border.all(color: MeowTheme.actionBlue.withOpacity(0.4)),
              ),
              child: Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                const Icon(Icons.mic, color: MeowTheme.actionBlue, size: 18),
                const SizedBox(width: 6),
                Text(widget.controller.tr('voice_ai_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
               ],
              ),
             ),
            ),
           ),
           const SizedBox(width: 10),
           Expanded(
            child: TactileButton(
             onTap: _autoScanSlipsInBackground,
             child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
               color: cardBg,
               borderRadius: BorderRadius.circular(14),
               border: Border.all(color: MeowTheme.incomeGreen.withOpacity(0.4)),
              ),
              child: Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                const Icon(Icons.sync, color: MeowTheme.incomeGreen, size: 18),
                const SizedBox(width: 6),
                Text(widget.controller.tr('auto_slip_title'), style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
               ],
              ),
             ),
            ),
           ),
          ],
         ),
        ),
        const SizedBox(height: 6),

        // Daily Budget Awareness Quota Card
        RepaintBoundary(
         child: DailyBudgetQuotaCard(controller: widget.controller),
        ),
        const SizedBox(height: 6),

        // Bank Slips & Nationwide Filter Bar
        _buildBankSlipsFilterSection(),
        const SizedBox(height: 6),

        // Sort Toggle & History Header
        if (_monthlyTransactions.isNotEmpty)
         Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
            Row(
             children: [
              const Icon(Icons.history_rounded, size: 16, color: MeowTheme.mustardYellow),
              const SizedBox(width: 6),
              Text(
               '${widget.controller.tr('transactions_history')} (${_monthlyTransactions.length})',
               style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
             ],
            ),
            Row(
             children: [
              TactileButton(
               onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                 _isSortNewestFirst = !_isSortNewestFirst;
                });
               },
               child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                 color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(
                  color: _isSortNewestFirst ? MeowTheme.mustardYellow.withOpacity(0.5) : borderColor,
                 ),
                 boxShadow: [
                  BoxShadow(
                   color: Colors.black.withOpacity(0.05),
                   blurRadius: 4,
                   offset: const Offset(0, 1),
                  ),
                 ],
                ),
                child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                  Icon(
                   _isSortNewestFirst ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                   size: 14,
                   color: MeowTheme.mustardYellow,
                  ),
                  const SizedBox(width: 5),
                  Text(
                   _isSortNewestFirst ? widget.controller.tr('sort_newest') : widget.controller.tr('sort_oldest'),
                   style: TextStyle(
                    color: textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                   ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.swap_vert_rounded, size: 14, color: MeowTheme.textLightMuted),
                 ],
                ),
               ),
              ),
             ],
            ),
           ],
          ),
         ),



        // Timeline Feed
        if (_monthlyTransactions.isEmpty) ...[
         Padding(
          padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
          child: Center(
           child: Column(
            children: [
             MeowMascotWidget(
              size: 80,
              isHeadOnly: true,
              mascotId: widget.controller.selectedMascotId,
              accessory: widget.controller.selectedMascotAccessory,
             ),
             const SizedBox(height: 16),
             Text(
              widget.controller.tr('no_transactions'),
              style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
             ),
             const SizedBox(height: 8),
             Text(
              widget.controller.tr('no_transactions_hint'),
              style: const TextStyle(color: MeowTheme.textLightMuted, fontSize: 13),
             ),
            ],
           ),
          ),
         ),
        ] else ...[
         ..._groupedTransactions.entries.map((group) {
          final dateLabel = group.key;
          final txList = group.value;
          final dayExpense = txList
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (sum, t) => sum + t.amount);

          return Container(
           margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
           child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             // Left Date Column
             SizedBox(
              width: 60,
              child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                Container(
                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                 decoration: BoxDecoration(
                  color: MeowTheme.mustardYellow,
                  borderRadius: BorderRadius.circular(6),
                 ),
                 child: Text(
                  dateLabel,
                  style: const TextStyle(
                   color: MeowTheme.textDarkPrimary,
                   fontSize: 12,
                   fontWeight: FontWeight.bold,
                  ),
                 ),
                ),
               ],
              ),
             ),
             const SizedBox(width: 8),

             // Right Transactions Area
             Expanded(
              child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                // Day Summary Header
                Padding(
                 padding: const EdgeInsets.only(bottom: 8),
                 child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                   const Text(
                    '↑ รายจ่าย',
                    style: TextStyle(color: MeowTheme.textLightMuted, fontSize: 12),
                   ),
                   Text(
                    '${CurrencyFormat.format(dayExpense)} ฿',
                    style: TextStyle(
                     color: textPrimary,
                     fontSize: 14,
                     fontWeight: FontWeight.bold,
                    ),
                   ),
                  ],
                 ),
                ),

                // Transaction Cards with Smooth Swipe-Left-to-Delete and Tap-to-View Slip
                ...txList.map((tx) {
                 final transferText = tx.slipTransferDescription;
                 final cleanNote = tx.cleanNote;

                 return RepaintBoundary(
                  key: ValueKey('tx_repaint_${tx.id}'),
                  child: Dismissible(
                  key: ValueKey('tx_dismiss_${tx.id}'),
                  direction: DismissDirection.horizontal,
                  movementDuration: const Duration(milliseconds: 200),
                  resizeDuration: const Duration(milliseconds: 200),
                  dismissThresholds: const {
                    DismissDirection.endToStart: 0.25,
                    DismissDirection.startToEnd: 0.25,
                  },
                  // Swipe Right -> Edit
                  background: Container(
                   margin: const EdgeInsets.only(bottom: 8),
                   padding: const EdgeInsets.symmetric(horizontal: 20),
                   decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(14),
                   ),
                   alignment: Alignment.centerLeft,
                   child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                     Icon(Icons.edit_rounded, color: Colors.white, size: 22),
                     SizedBox(width: 8),
                     Text(
                      'แก้ไขรายการ',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                     ),
                    ],
                   ),
                  ),
                  // Swipe Left -> Delete
                  secondaryBackground: Container(
                   margin: const EdgeInsets.only(bottom: 8),
                   padding: const EdgeInsets.symmetric(horizontal: 20),
                   decoration: BoxDecoration(
                    color: MeowTheme.expenseRed,
                    borderRadius: BorderRadius.circular(14),
                   ),
                   alignment: Alignment.centerRight,
                   child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                     Text(
                      'ลบรายการด่วน',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                     ),
                     SizedBox(width: 8),
                     Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 24),
                    ],
                   ),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditTransactionScreen(
                            controller: widget.controller,
                            transaction: tx,
                          ),
                        ),
                      );
                      return false; // Don't remove item from list
                    }
                    return true; // Proceed with deletion
                  },
                  onDismissed: (direction) {
                    _handleTransactionDismissed(tx);
                  },
                  child: GestureDetector(
                   onTap: () {
                    TransactionDetailSheet.show(
                      context,
                      widget.controller,
                      tx,
                      onDelete: (deletedTx) {
                        _handleTransactionDismissed(deletedTx);
                      },
                    );
                   },
                   child: Container(
                     margin: const EdgeInsets.only(bottom: 7),
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                     decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: borderColor),
                     ),
                     child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                       Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Icon or Slip Thumbnail with Real Bank Logo
                          if (tx.slipImageUrl != null) ...[
                           GestureDetector(
                            onTap: () {
                             SlipImageViewerDialog.show(context, tx.slipImageUrl!, title: tx.title);
                            },
                            child: Stack(
                             clipBehavior: Clip.none,
                             alignment: Alignment.bottomRight,
                             children: [
                              Container(
                               width: 48,
                               height: 54,
                               decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                 color: currentTheme.primaryColor.withOpacity(0.35),
                                 width: 1,
                                ),
                               ),
                               child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                 SlipStorageService.resolveSlipFile(tx.slipImageUrl) ?? File(tx.slipImageUrl!),
                                 width: 48,
                                 height: 54,
                                 fit: BoxFit.contain,
                                 errorBuilder: (_, __, ___) => Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                   color: MeowTheme.navyCard,
                                   borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: const Icon(Icons.receipt, color: MeowTheme.mustardYellow, size: 18),
                                 ),
                                ),
                               ),
                              ),
                              // Official Real Bank Logo Badge Overlay at Top-Left
                              () {
                                final detectedCode = ThaiBankDetector.detectBankCode(tx, widget.controller.accounts);
                                if (detectedCode.isNotEmpty && detectedCode != 'CASH' && detectedCode != 'OTHER') {
                                  return Positioned(
                                    top: -4,
                                    left: -4,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.white, width: 1.5),
                                      ),
                                      child: BankBadge(bankCode: detectedCode, size: 18),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }(),
                              // Zoom Icon at Bottom-Right
                              Container(
                               padding: const EdgeInsets.all(2),
                               decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.75),
                                shape: BoxShape.circle,
                              ),
                               child: const Icon(Icons.zoom_in, color: Colors.white, size: 9),
                              ),
                             ],
                            ),
                           ),
                          ] else ...[
                           // No Slip -> Full 40px Official Bank Logo
                           () {
                             final detectedCode = ThaiBankDetector.detectBankCode(tx, widget.controller.accounts);
                             if (detectedCode.isNotEmpty && detectedCode != 'CASH' && detectedCode != 'OTHER') {
                               return BankBadge(bankCode: detectedCode, size: 40);
                             }
                             return Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                               color: tx.type == TransactionType.expense
                                 ? MeowTheme.expenseRed.withValues(alpha: 0.12)
                                 : tx.type == TransactionType.income
                                   ? MeowTheme.incomeGreen.withValues(alpha: 0.12)
                                   : MeowTheme.transferBlue.withValues(alpha: 0.12),
                               shape: BoxShape.circle,
                              ),
                              child: Icon(
                               tx.type == TransactionType.expense
                                 ? Icons.arrow_upward_rounded
                                 : tx.type == TransactionType.income
                                   ? Icons.arrow_downward_rounded
                                   : Icons.swap_horiz_rounded,
                               color: tx.type == TransactionType.expense
                                 ? MeowTheme.expenseRed
                                 : tx.type == TransactionType.income
                                   ? MeowTheme.incomeGreen
                                   : MeowTheme.transferBlue,
                               size: 20,
                              ),
                             );
                           }(),
                          ],
                          const SizedBox(width: 10),
                         // Title & Metadata (Neatly Aligned Rows with Compact Font)
                         Expanded(
                          child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                            Text(
                             tx.title,
                             maxLines: 2,
                             softWrap: true,
                             overflow: TextOverflow.ellipsis,
                             style: TextStyle(
                              color: textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              letterSpacing: -0.2,
                             ),
                            ),
                            const SizedBox(height: 3.5),
                            SingleChildScrollView(
                             scrollDirection: Axis.horizontal,
                             physics: const BouncingScrollPhysics(),
                             child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                               // Non-duplicate Category Pill (Locks horizontal text, never wraps vertically)
                               if (tx.title != tx.categoryName && tx.title != widget.controller.trCategory(tx.categoryName))
                                Container(
                                 margin: const EdgeInsets.only(right: 5),
                                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                 decoration: BoxDecoration(
                                  color: isDark ? MeowTheme.navyCard : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: currentTheme.primaryColor.withValues(alpha: 0.18), width: 0.7),
                                 ),
                                 child: Text(
                                  widget.controller.trCategory(tx.categoryName),
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(
                                   color: currentTheme.primaryColor,
                                   fontSize: 10,
                                   fontWeight: FontWeight.bold,
                                  ),
                                 ),
                                ),

                               // Distinct #Tags Chips
                               if (tx.tags.isNotEmpty)
                                ...tx.tags.map((t) => Container(
                                 margin: const EdgeInsets.only(right: 4),
                                 padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                 decoration: BoxDecoration(
                                  color: currentTheme.primaryColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: currentTheme.primaryColor.withOpacity(0.3)),
                                 ),
                                 child: Text(
                                  '#$t',
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(
                                   color: currentTheme.primaryDark,
                                   fontSize: 9,
                                   fontWeight: FontWeight.bold,
                                  ),
                                 ),
                                )),

                               // Recurring badge
                               if (tx.isRecurring)
                                Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                 decoration: BoxDecoration(
                                  color: currentTheme.secondaryColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(5),
                                 ),
                                 child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                   Icon(Icons.repeat, color: currentTheme.secondaryColor, size: 9),
                                   const SizedBox(width: 2),
                                   Text(
                                    widget.controller.isEnglish ? 'Recurring' : 'ประจำ',
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(color: currentTheme.secondaryColor, fontSize: 9, fontWeight: FontWeight.bold),
                                   ),
                                  ],
                                 ),
                                ),
                              ],
                             ),
                            ),
                           ],
                          ),
                         ),
                          const SizedBox(width: 8),

                          // Standard Amount Display (Keeps full width for title & category)
                          Text(
                           tx.amount <= 0.0
                               ? '0 ฿'
                               : '${tx.type == TransactionType.expense ? '-' : tx.type == TransactionType.income ? '+' : ''}${tx.amount.toStringAsFixed(tx.amount.truncateToDouble() == tx.amount ? 0 : 2)} ฿',
                           style: TextStyle(
                            color: tx.amount <= 0.0
                                ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
                                : (tx.type == TransactionType.expense
                                    ? MeowTheme.expenseRed
                                    : tx.type == TransactionType.income
                                      ? MeowTheme.incomeGreen
                                      : MeowTheme.transferBlue),
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                           ),
                          ),
                         ],
                        ),

                        // Full-Width No-QR Tap-to-Enter Banner OR Standard Note Box
                        if (tx.amount <= 0.0 || (cleanNote != null && cleanNote.contains('สลิปไม่มี QR Code'))) ...[
                         GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditTransactionScreen(
                                  controller: widget.controller,
                                  transaction: tx,
                                ),
                              ),
                            );
                          },
                          child: Container(
                           margin: const EdgeInsets.only(top: 6),
                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                           decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.18 : 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4), width: 0.8),
                           ),
                           child: Row(
                            children: [
                             const Icon(Icons.edit_note_rounded, size: 15, color: Color(0xFFD97706)),
                             const SizedBox(width: 5),
                             Expanded(
                              child: Text(
                               widget.controller.isEnglish ? 'No QR Code • Tap to enter amount' : 'สลิปไม่มี QR Code (แตะเพื่อระบุยอดเงิน)',
                               style: const TextStyle(
                                color: Color(0xFFD97706),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                               ),
                              ),
                             ),
                             const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFD97706)),
                            ],
                           ),
                          ),
                         ),
                        ] else if (cleanNote != null && cleanNote.isNotEmpty) ...[
                        GestureDetector(
                         onTap: () {
                          TransactionDetailSheet.show(
                            context,
                            widget.controller,
                            tx,
                            onDelete: (deletedTx) {
                              _handleTransactionDismissed(deletedTx);
                            },
                          );
                         },
                         child: Container(
                          margin: const EdgeInsets.only(top: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                           color: isDark ? const Color(0xFF0F2744) : const Color(0xFFF0F9FF),
                           borderRadius: BorderRadius.circular(8),
                           border: Border.all(
                            color: const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.3 : 0.35),
                            width: 0.8,
                           ),
                          ),
                          child: Row(
                           mainAxisSize: MainAxisSize.min,
                           crossAxisAlignment: CrossAxisAlignment.center,
                           children: [
                            const Icon(Icons.edit_note_rounded, size: 14, color: Color(0xFF0284C7)),
                            const SizedBox(width: 4),
                            Flexible(
                             child: Text(
                              cleanNote,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                               color: isDark ? const Color(0xFFBAE6FD) : const Color(0xFF0369A1),
                               fontSize: 11,
                               fontWeight: FontWeight.w500,
                               height: 1.2,
                              ),
                             ),
                            ),
                           ],
                          ),
                         ),
                        ),
                       ],

                       // Transfer Details (Who transferred to Whom)
                       if (transferText != null && transferText.isNotEmpty) ...[
                        Container(
                         margin: const EdgeInsets.only(top: 5),
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F2744) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                           color: const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.3 : 0.2),
                           width: 0.8,
                          ),
                         ),
                         child: Row(
                          children: [
                           const Icon(Icons.swap_horiz_rounded, color: Color(0xFF0284C7), size: 13),
                           const SizedBox(width: 4),
                           Expanded(
                            child: Text(
                             transferText,
                             style: TextStyle(
                              color: isDark ? const Color(0xFFBAE6FD) : const Color(0xFF0369A1),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                             ),
                             maxLines: 2,
                             overflow: TextOverflow.ellipsis,
                            ),
                           ),
                          ],
                         ),
                        ),
                       ],

                        // Stamped Date & Time & Minimalist Swipe Micro-Hints (Swipe Right: Edit | Date/Time | Delete :Swipe Left)
                        () {
                          final swipeHintColor = (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)).withValues(alpha: 0.50);
                          return Container(
                           margin: const EdgeInsets.only(top: 6, left: -8, right: -8),
                           child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                             // Left: Swipe Right to Edit (Flush to bottom-left edge)
                             Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                               SwipeActionGlyph(
                                direction: SwipeActionGlyphDirection.right,
                                width: 15,
                                height: 9.5,
                                color: swipeHintColor,
                               ),
                               const SizedBox(width: 3),
                               Text(
                                widget.controller.isEnglish ? 'Edit' : 'แก้ไข',
                                style: TextStyle(
                                 color: swipeHintColor,
                                 fontSize: 8.5,
                                 fontWeight: FontWeight.w500,
                                ),
                               ),
                              ],
                             ),

                             // Center: Date & Time
                             Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                               const Icon(Icons.calendar_today_rounded, size: 9.5, color: MeowTheme.mustardYellowDark),
                               const SizedBox(width: 3.5),
                               Text(
                                '${tx.date.day} ${_formatThaiMonthShort(tx.date.month)} ${widget.controller.isEnglish ? tx.date.year : tx.date.year + 543} • ${_formatTime(tx.date)}${widget.controller.isEnglish ? "" : " น."}',
                                style: TextStyle(
                                 color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                 fontSize: 9.5,
                                 fontWeight: FontWeight.w500,
                                ),
                               ),
                              ],
                             ),

                             // Right: Swipe Left to Delete (Flush to bottom-right edge)
                             Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                               Text(
                                widget.controller.isEnglish ? 'Delete' : 'ลบ',
                                style: TextStyle(
                                 color: swipeHintColor,
                                 fontSize: 8.5,
                                 fontWeight: FontWeight.w500,
                                ),
                               ),
                               const SizedBox(width: 3),
                               SwipeActionGlyph(
                                direction: SwipeActionGlyphDirection.left,
                                width: 15,
                                height: 9.5,
                                color: swipeHintColor,
                               ),
                              ],
                             ),
                            ],
                           ),
                          );
                        }(),
                      ],
                    ),
                   ),
                  ),
                  ),
                 );
                }),
               ],
              ),
             ),
            ],
           ),
          );
         }),
        ],
        const SizedBox(height: 100),
       ],
      ),
     ),

     // Scroll To Top Floating Button (Bottom Left)
     AnimatedPositioned(
       duration: const Duration(milliseconds: 250),
       curve: Curves.easeOutCubic,
       left: 20,
       bottom: _showScrollToTop ? 24 : -70,
       child: AnimatedOpacity(
         duration: const Duration(milliseconds: 200),
         opacity: _showScrollToTop ? 1.0 : 0.0,
         child: TactileButton(
           onTap: () {
             HapticFeedback.lightImpact();
             _scrollToTop();
           },
           child: Container(
             height: 50,
             padding: const EdgeInsets.symmetric(horizontal: 14),
             decoration: BoxDecoration(
               color: isDark ? const Color(0xFF1E293B) : Colors.white,
               borderRadius: BorderRadius.circular(25),
               border: Border.all(
                 color: currentTheme.primaryColor.withValues(alpha: 0.8),
                 width: 1.5,
               ),
               boxShadow: [
                                 BoxShadow(
                   color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                   blurRadius: 14,
                   offset: const Offset(0, 4),
                 ),
               ],
             ),
             child: Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Icon(Icons.arrow_upward_rounded, color: currentTheme.primaryColor, size: 20),
                 const SizedBox(width: 5),
                 Text(
                   widget.controller.isEnglish ? 'Top' : 'บนสุด',
                   style: TextStyle(
                     color: textPrimary,
                     fontSize: 13,
                     fontWeight: FontWeight.bold,
                   ),
                 ),
               ],
             ),
           ),
         ),
       ),
     ),

      // Animated Floating Live Countdown Undo Banner (Bottom Floating Center)
      AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        bottom: _pendingDeletedItems.isNotEmpty ? 92 : -120,
        left: 20,
        right: 20,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _pendingDeletedItems.isNotEmpty ? 1.0 : 0.0,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: MeowTheme.mustardYellow.withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: MeowTheme.mustardYellow.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Countdown Ring & Number
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          value: (_undoCountdown / 3.5).clamp(0.0, 1.0),
                          strokeWidth: 3.0,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(MeowTheme.mustardYellow),
                        ),
                      ),
                      Text(
                        _undoCountdown.toStringAsFixed(1),
                        style: const TextStyle(
                          color: MeowTheme.mustardYellow,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Information label
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _pendingDeletedItems.length > 1
                              ? (widget.controller.isEnglish
                                  ? 'Deleted ${_pendingDeletedItems.length} transactions'
                                  : 'ลบแล้ว ${_pendingDeletedItems.length} รายการ')
                              : (_pendingDeletedItems.isNotEmpty
                                  ? 'ลบ "${_pendingDeletedItems.last.title}"'
                                  : 'ลบรายการแล้ว'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.controller.isEnglish
                              ? 'Undo available (${_undoCountdown.toStringAsFixed(1)}s)'
                              : 'กดยกเลิกได้ใน ${_undoCountdown.toStringAsFixed(1)} วินาที...',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tactile Undo Button
                  TactileButton(
                    onTap: _undoBatchDelete,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.undo_rounded, color: Color(0xFF0F172A), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            widget.controller.isEnglish ? 'Undo' : 'เลิกทำ',
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // Minimal + Modern Floating Arrow Up Action Button (Bottom Right)
      Positioned(
       right: 20,
       bottom: 24,
       child: RepaintBoundary(
        child: TactileButton(
         onTap: () {
          HapticFeedback.mediumImpact();
          _showFloatingArrowMenu();
         },
         child: Container(
          key: _arrowButtonKey,
          width: 58,
          height: 58,
          decoration: BoxDecoration(
           shape: BoxShape.circle,
           gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
             Color(0xFF38BDF8),
             Color(0xFF2563EB),
             Color(0xFF1D4ED8),
            ],
           ),
           border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 1.5,
           ),
           boxShadow: [
            BoxShadow(
             color: const Color(0xFF2563EB).withValues(alpha: 0.45),
             blurRadius: 18,
             spreadRadius: 1,
             offset: const Offset(0, 8),
            ),
            BoxShadow(
             color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
             blurRadius: 10,
             offset: const Offset(0, 4),
            ),
           ],
          ),
          child: const Center(
           child: Icon(
            Icons.keyboard_arrow_up_rounded,
            color: Colors.white,
            size: 36,
           ),
          ),
         ),
        ),
       ),
      ),
    ],
   ),
  );
 }

   Widget _buildBankSlipsFilterSection() {
  final isDark = widget.controller.isDarkMode;
  final isEn = widget.controller.isEnglish;
  final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
  final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  final borderColor = isDark ? MeowTheme.borderColor : const Color(0xFFE2E8F0);

  // Group month transactions by detected bank
  final monthTxs = _allMonthTransactions;
  final Map<String, List<TransactionItem>> bankTxsMap = {};
  for (final tx in monthTxs) {
   final code = _getDetectedBankCode(tx);
   bankTxsMap.putIfAbsent(code, () => []).add(tx);
  }

  final activeBankCodes = bankTxsMap.keys.toList();
  final totalBankCount = ThaiBankDetector.supportedBanks.length + 1;
  final isFiltered = _enabledBankCodes.length < totalBankCount;

  return Padding(
   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
   child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
     // Header Row
     Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
       Row(
        children: [
         const Icon(Icons.account_balance_rounded, size: 16, color: MeowTheme.actionBlue),
         const SizedBox(width: 6),
         Text(
          isEn ? 'Bank Slips Filter' : 'แยกสลิปตามธนาคาร',
          style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
         ),
         if (isFiltered) ...[
          const SizedBox(width: 6),
          Container(
           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
           decoration: BoxDecoration(
            color: MeowTheme.mustardYellow.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: MeowTheme.mustardYellow.withValues(alpha: 0.5)),
           ),
           child: Text(
            isEn ? 'Filtered' : 'กรองอยู่',
            style: const TextStyle(color: MeowTheme.mustardYellowDark, fontSize: 10, fontWeight: FontWeight.bold),
           ),
          ),
         ],
        ],
       ),
       TactileButton(
        onTap: _showBankFilterBottomSheet,
        child: Container(
         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
         decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: MeowTheme.actionBlue.withValues(alpha: 0.3)),
         ),
         child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
           const Icon(Icons.tune_rounded, size: 13, color: MeowTheme.actionBlue),
           const SizedBox(width: 4),
           Text(
            isEn ? 'All Banks' : 'ธนาคารทั้งหมด',
            style: const TextStyle(color: MeowTheme.actionBlue, fontSize: 11.5, fontWeight: FontWeight.bold),
           ),
          ],
         ),
        ),
       ),
      ],
     ),
     const SizedBox(height: 6),

     // Horizontal Bank Chips (For banks present in this month)
     if (activeBankCodes.isNotEmpty)
      SizedBox(
       height: 38,
       child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: activeBankCodes.length,
        itemBuilder: (ctx, idx) {
         final code = activeBankCodes[idx];
         final bankMeta = ThaiBankDetector.getBank(code) ??
           const ThaiBankMeta(
            code: 'OTHER',
            nameTh: 'อื่นๆ',
            nameEn: 'Other',
            shortNameTh: 'อื่นๆ',
            shortNameEn: 'Other',
            primaryColor: Color(0xFF64748B),
            secondaryColor: Color(0xFF475569),
            keywords: [],
           );
         final isChecked = _enabledBankCodes.contains(code);
         final count = bankTxsMap[code]?.length ?? 0;

         return TactileButton(
          onTap: () {
           HapticFeedback.selectionClick();
           setState(() {
            if (isChecked) {
             _enabledBankCodes.remove(code);
            } else {
             _enabledBankCodes.add(code);
            }
           });
          },
          child: AnimatedContainer(
           duration: const Duration(milliseconds: 200),
           margin: const EdgeInsets.only(right: 8),
           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
           decoration: BoxDecoration(
            color: isChecked ? bankMeta.primaryColor.withValues(alpha: 0.12) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
             color: isChecked ? bankMeta.primaryColor : borderColor,
             width: isChecked ? 1.5 : 1,
            ),
           ),
           child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
             BankBadge(bankCode: code, size: 18),
             const SizedBox(width: 5),
             Text(
              isEn ? bankMeta.shortNameEn : bankMeta.shortNameTh,
              style: TextStyle(
               color: isChecked ? (isDark ? Colors.white : bankMeta.primaryColor) : textSecondary,
               fontSize: 12,
               fontWeight: isChecked ? FontWeight.bold : FontWeight.w500,
              ),
             ),
             const SizedBox(width: 4),
             Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
               color: isChecked ? bankMeta.primaryColor : Colors.grey.withOpacity(0.3),
               borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
               '$count',
               style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
             ),
            ],
           ),
          ),
         );
        },
       ),
      )
     else
      Container(
       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
       decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
       ),
       child: Row(
        children: [
         const Icon(Icons.info_outline_rounded, size: 15, color: MeowTheme.actionBlue),
         const SizedBox(width: 8),
         Expanded(
          child: Text(
           isEn ? 'No bank slip transactions recorded in this month' : 'ยังไม่มีสลิปหรือรายการธนาคารในเดือนนี้',
           style: TextStyle(color: textSecondary, fontSize: 11.5),
          ),
         ),
        ],
       ),
      ),
    ],
   ),
  );
 }

 void _showBankFilterBottomSheet() {
  HapticFeedback.mediumImpact();
  final isDark = widget.controller.isDarkMode;
  final isEn = widget.controller.isEnglish;
  final cardBg = isDark ? MeowTheme.navySurface : Colors.white;
  final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
  final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  final borderColor = isDark ? MeowTheme.borderColor : const Color(0xFFE2E8F0);

  // Group monthly items by detected bank
  final monthTxs = _allMonthTransactions;
  final Map<String, List<TransactionItem>> bankTxsMap = {};
  for (final tx in monthTxs) {
   final code = _getDetectedBankCode(tx);
   bankTxsMap.putIfAbsent(code, () => []).add(tx);
  }

  showModalBottomSheet(
   context: context,
   isScrollControlled: true,
   backgroundColor: Colors.transparent,
   builder: (ctx) {
    return StatefulBuilder(
     builder: (modalContext, setModalState) {
      return Container(
       constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
       decoration: BoxDecoration(
        color: isDark ? MeowTheme.navyBackground : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: borderColor),
       ),
       child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
         // Drag Handle
         Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          decoration: BoxDecoration(
           color: Colors.grey.withOpacity(0.3),
           borderRadius: BorderRadius.circular(2),
          ),
         ),
         // Header
         Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
           children: [
            Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(
              color: MeowTheme.actionBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
             ),
             child: const Icon(Icons.account_balance_rounded, color: MeowTheme.actionBlue, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
             child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               Text(
                isEn ? 'Nationwide Bank Filter' : 'แยกสลิปตามธนาคารทั่วประเทศ',
                style: TextStyle(
                 color: textPrimary,
                 fontSize: 17,
                 fontWeight: FontWeight.bold,
                ),
               ),
               Text(
                isEn
                  ? 'Check/uncheck banks to show/hide in totals & history'
                  : 'ติ๊กเปิด/ปิดธนาคารเพื่อแสดงผลข้อมูลการเงินและยอดรวม',
                style: TextStyle(color: textSecondary, fontSize: 12),
               ),
              ],
             ),
            ),
            IconButton(
             icon: const Icon(Icons.close_rounded),
             onPressed: () => Navigator.pop(modalContext),
            ),
           ],
          ),
         ),

         // Quick Select / Deselect Bar
         Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
           children: [
            Expanded(
             child: OutlinedButton.icon(
              onPressed: () {
               HapticFeedback.selectionClick();
               setState(() {
                _enabledBankCodes = ThaiBankDetector.supportedBanks.map((b) => b.code).toSet()..add('OTHER');
               });
               setModalState(() {});
              },
              icon: const Icon(Icons.select_all_rounded, size: 16),
              label: Text(isEn ? 'Select All' : 'เลือกทั้งหมด', style: const TextStyle(fontSize: 12.5)),
              style: OutlinedButton.styleFrom(
               foregroundColor: MeowTheme.actionBlue,
               side: const BorderSide(color: MeowTheme.actionBlue),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               padding: const EdgeInsets.symmetric(vertical: 8),
              ),
             ),
            ),
            const SizedBox(width: 10),
            Expanded(
             child: OutlinedButton.icon(
              onPressed: () {
               HapticFeedback.selectionClick();
               setState(() {
                _enabledBankCodes.clear();
               });
               setModalState(() {});
              },
              icon: const Icon(Icons.clear_all_rounded, size: 16),
              label: Text(isEn ? 'Clear All' : 'ปิดทั้งหมด', style: const TextStyle(fontSize: 12.5)),
              style: OutlinedButton.styleFrom(
               foregroundColor: MeowTheme.expenseRed,
               side: const BorderSide(color: MeowTheme.expenseRed),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               padding: const EdgeInsets.symmetric(vertical: 8),
              ),
             ),
            ),
           ],
          ),
         ),
         const Divider(height: 16),

         // Bank List
         Expanded(
          child: ListView.builder(
           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
           itemCount: ThaiBankDetector.supportedBanks.length + 1,
           itemBuilder: (ctx, idx) {
            final bool isOther = idx == ThaiBankDetector.supportedBanks.length;
            final bankInfo = isOther
              ? const ThaiBankMeta(
                code: 'OTHER',
                nameTh: 'เงินสด / บัญชีอื่นๆ',
                nameEn: 'Cash / Other Account',
                shortNameTh: 'อื่นๆ',
                shortNameEn: 'Other',
                primaryColor: Color(0xFF64748B),
                secondaryColor: Color(0xFF475569),
                keywords: [],
               )
              : ThaiBankDetector.supportedBanks[idx];

            final isChecked = _enabledBankCodes.contains(bankInfo.code);
            final txList = bankTxsMap[bankInfo.code] ?? [];
            final count = txList.length;
            final totalExp = txList
              .where((t) => t.type == TransactionType.expense)
              .fold(0.0, (s, t) => s + t.amount);
            final totalInc = txList
              .where((t) => t.type == TransactionType.income)
              .fold(0.0, (s, t) => s + t.amount);

            return TactileButton(
             onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
               if (isChecked) {
                _enabledBankCodes.remove(bankInfo.code);
               } else {
                _enabledBankCodes.add(bankInfo.code);
               }
              });
              setModalState(() {});
             },
             child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
               color: isChecked
                 ? (isDark ? const Color(0xFF1E293B) : cardBg)
                 : (isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF1F5F9).withOpacity(0.5)),
               borderRadius: BorderRadius.circular(16),
               border: Border.all(
                color: isChecked ? bankInfo.primaryColor.withOpacity(0.6) : borderColor,
                width: isChecked ? 1.5 : 1,
               ),
              ),
              child: Row(
               children: [
                // Real Official Bank Logo Badge
                BankBadge(bankCode: bankInfo.code, size: 38),
                const SizedBox(width: 12),
                // Bank Details
                Expanded(
                 child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                   Row(
                    children: [
                     Text(
                      isEn ? bankInfo.nameEn : bankInfo.nameTh,
                      style: TextStyle(
                       color: isChecked ? textPrimary : textSecondary,
                       fontWeight: FontWeight.bold,
                       fontSize: 13.5,
                      ),
                     ),
                     if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                       decoration: BoxDecoration(
                        color: bankInfo.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                       ),
                       child: Text(
                        '$count ${isEn ? "slips" : "สลิป"}',
                        style: TextStyle(
                         color: bankInfo.primaryColor,
                         fontSize: 10.5,
                         fontWeight: FontWeight.bold,
                        ),
                       ),
                      ),
                     ],
                    ],
                   ),
                   if (count > 0)
                    Padding(
                     padding: const EdgeInsets.only(top: 2),
                     child: Text(
                      totalExp > 0
                        ? '-฿${FormatUtils.formatCurrency(totalExp)}'
                        : '+฿${FormatUtils.formatCurrency(totalInc)}',
                      style: TextStyle(
                       color: totalExp > 0 ? MeowTheme.expenseRed : MeowTheme.incomeGreen,
                       fontSize: 11.5,
                       fontWeight: FontWeight.w600,
                      ),
                     ),
                    )
                   else
                    Padding(
                     padding: const EdgeInsets.only(top: 2),
                     child: Text(
                      isEn ? 'No transactions this month' : 'ไม่มีรายการในเดือนนี้',
                      style: TextStyle(color: textSecondary.withOpacity(0.7), fontSize: 11),
                     ),
                    ),
                  ],
                 ),
                ),
                // Checkbox
                Checkbox(
                 value: isChecked,
                 activeColor: bankInfo.primaryColor,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                 onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setState(() {
                   if (val == true) {
                    _enabledBankCodes.add(bankInfo.code);
                   } else {
                    _enabledBankCodes.remove(bankInfo.code);
                   }
                  });
                  setModalState(() {});
                 },
                ),
               ],
              ),
             ),
            );
           },
          ),
         ),

         // Bottom Done Button
         Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: TactileButton(
           onTap: () => Navigator.pop(modalContext),
           child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
             color: MeowTheme.mustardYellow,
             borderRadius: BorderRadius.circular(16),
             boxShadow: [
              BoxShadow(
               color: MeowTheme.mustardYellow.withValues(alpha: 0.3),
               blurRadius: 12,
               offset: const Offset(0, 4),
              ),
             ],
            ),
            child: Center(
             child: Text(
              isEn ? 'Apply Filter' : 'ใช้งานตัวกรอง',
              style: const TextStyle(
               color: MeowTheme.textDarkPrimary,
               fontSize: 15.5,
               fontWeight: FontWeight.bold,
              ),
             ),
            ),
           ),
          ),
         ),
        ],
       ),
      );
     },
    );
   },
  );
 }
}

enum SwipeActionGlyphDirection { left, right }

/// Modern 3-line arrow glyph matching media_1788894303903.png and media_1788893976611.png
/// Provides speed lines on top and middle, with the bottom shaft feeding into a sleek arrowhead triangle.
class SwipeActionGlyph extends StatelessWidget {
  final SwipeActionGlyphDirection direction;
  final double width;
  final double height;
  final Color color;

  const SwipeActionGlyph({
    super.key,
    required this.direction,
    this.width = 15.0,
    this.height = 9.5,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _SwipeGlyphPainter(direction: direction, color: color),
    );
  }
}

class _SwipeGlyphPainter extends CustomPainter {
  final SwipeActionGlyphDirection direction;
  final Color color;

  _SwipeGlyphPainter({required this.direction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.save();
    if (direction == SwipeActionGlyphDirection.left) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }

    final linePaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Arrowhead specifications: centered on bottom shaft (yCenter)
    final yCenter = h * 0.78;
    final arrowHeadWidth = 4.8;
    final halfArrowHeight = 3.2;
    final shaftRight = w - arrowHeadWidth + 0.6;

    // 1. Top line (shortest, ~38% width)
    final y1 = h * 0.16;
    canvas.drawLine(Offset(0.65, y1), Offset(w * 0.38, y1), linePaint);

    // 2. Middle line (medium, ~58% width)
    final y2 = h * 0.47;
    canvas.drawLine(Offset(0.65, y2), Offset(w * 0.58, y2), linePaint);

    // 3. Bottom shaft line (longest, feeds cleanly into the arrowhead triangle)
    canvas.drawLine(Offset(0.65, yCenter), Offset(shaftRight, yCenter), linePaint);

    // 4. Solid triangle arrowhead
    final path = Path()
      ..moveTo(w - arrowHeadWidth, yCenter - halfArrowHeight)
      ..lineTo(w, yCenter)
      ..lineTo(w - arrowHeadWidth, yCenter + halfArrowHeight)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SwipeGlyphPainter oldDelegate) =>
      oldDelegate.direction != direction || oldDelegate.color != color;
}
