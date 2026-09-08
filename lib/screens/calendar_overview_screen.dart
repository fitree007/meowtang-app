import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction_item.dart';
import '../state/expense_controller.dart';
import '../theme/app_theme_model.dart';
import '../theme/meow_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/transaction_detail_sheet.dart';
import '../widgets/meow_wheel_date_picker.dart';
import '../widgets/slip_image_viewer_dialog.dart';
import '../services/slip_storage_service.dart';
import 'meow_entry_screen.dart';

class CalendarOverviewScreen extends StatefulWidget {
  final ExpenseController controller;

  const CalendarOverviewScreen({super.key, required this.controller});

  @override
  State<CalendarOverviewScreen> createState() => _CalendarOverviewScreenState();
}

class _CalendarOverviewScreenState extends State<CalendarOverviewScreen> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime.now();

  // Batch delete & undo countdown state (3.5s)
  // Batch delete & undo countdown state (3.5s) - Zero Lag with ValueNotifier
  final ValueNotifier<List<TransactionItem>> _pendingDeletedNotifier = ValueNotifier<List<TransactionItem>>([]);
  final ValueNotifier<double> _undoCountdownNotifier = ValueNotifier<double>(3.5);
  Timer? _undoTimer;

  List<TransactionItem> get _pendingDeletedItems => _pendingDeletedNotifier.value;
  double get _undoCountdown => _undoCountdownNotifier.value;

  @override
  void dispose() {
    _undoTimer?.cancel();
    super.dispose();
  }

  String _formatMonthYear(DateTime d) {
    if (widget.controller.isEnglish) {
      const enMonths = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${enMonths[d.month - 1]} ${d.year}';
    }
    const thaiMonths = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    final mName = thaiMonths[d.month - 1];
    final thaiYear = d.year + 543;
    return '$mName $thaiYear';
  }

  String _formatSelectedDateHeader(DateTime d) {
    if (widget.controller.isEnglish) {
      const enMonthsShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${d.day} ${enMonthsShort[d.month - 1]} ${d.year}';
    }
    const shortMonths = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
    return '${d.day} ${shortMonths[d.month - 1]} ${d.year + 543}';
  }

  void _previousMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _jumpToToday() {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month, 1);
      _selectedDate = now;
    });
  }

  void _handleTransactionDismissed(TransactionItem tx) {
    HapticFeedback.mediumImpact();
    widget.controller.deleteTransaction(tx.id);
    _pendingDeletedNotifier.value = [..._pendingDeletedNotifier.value, tx];
    _undoCountdownNotifier.value = 3.5;
    _undoTimer?.cancel();
    _undoTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final nextVal = _undoCountdownNotifier.value - 0.2;
      if (nextVal <= 0.05) {
        timer.cancel();
        _undoTimer = null;
        _pendingDeletedNotifier.value = [];
        _undoCountdownNotifier.value = 3.5;
      } else {
        _undoCountdownNotifier.value = nextVal;
      }
    });
  }

  void _undoBatchDelete() async {
    HapticFeedback.selectionClick();
    _undoTimer?.cancel();
    _undoTimer = null;
    final itemsToRestore = List<TransactionItem>.from(_pendingDeletedNotifier.value);
    _pendingDeletedNotifier.value = [];
    _undoCountdownNotifier.value = 3.5;
    for (final tx in itemsToRestore) {
      await widget.controller.restoreTransaction(tx);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showMonthPicker() async {
    HapticFeedback.selectionClick();
    final currentTheme = widget.controller.currentTheme;
    int tempYear = _focusedMonth.year;
    int tempMonth = _focusedMonth.month;

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
          final isEng = widget.controller.isEnglish;

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
                          _focusedMonth = DateTime(now.year, now.month, 1);
                          _selectedDate = now;
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

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
                    final isSel = tempMonth == m && tempYear == _focusedMonth.year;
                    final isThisMonth = m == DateTime.now().month && tempYear == DateTime.now().year;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _focusedMonth = DateTime(tempYear, m, 1);
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
                const SizedBox(height: 14),

                // Wheel Picker Option Link
                TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final picked = await MeowWheelDatePicker.showWheelMonthYearPicker(
                      context: context,
                      initialDate: _focusedMonth,
                      isEnglish: isEng,
                      isDarkMode: currentTheme.isDark,
                    );
                    if (picked != null) {
                      setState(() {
                        _focusedMonth = DateTime(picked.year, picked.month, 1);
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

  @override
  Widget build(BuildContext context) {
    final currentTheme = widget.controller.currentTheme;
    final isEng = widget.controller.isEnglish;

    final expenseTotal = widget.controller.getMonthlyExpenseTotal(_focusedMonth.year, _focusedMonth.month);
    final incomeTotal = widget.controller.getMonthlyIncomeTotal(_focusedMonth.year, _focusedMonth.month);
    final netTotal = incomeTotal - expenseTotal;

    final dailyExpenses = widget.controller.getDailyExpensesForMonth(_focusedMonth.year, _focusedMonth.month);
    final dailyIncomes = widget.controller.getDailyIncomesForMonth(_focusedMonth.year, _focusedMonth.month);

    final selectedTransactions = widget.controller.getTransactionsForDate(_selectedDate);

    // Calculate calendar grid days
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;

    // Monday as first day of week (weekday 1..7 -> Monday=1)
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun
    final leadingEmptyDays = startingWeekday - 1;
    final totalGridCells = ((leadingEmptyDays + daysInMonth) / 7).ceil() * 7;

    // Selected day summary
    double selectedDayExpense = 0.0;
    double selectedDayIncome = 0.0;
    for (final tx in selectedTransactions) {
      if (tx.type == TransactionType.expense) {
        selectedDayExpense += tx.amount;
      } else if (tx.type == TransactionType.income) {
        selectedDayIncome += tx.amount;
      }
    }

    final isFocusedThisMonth = _focusedMonth.year == DateTime.now().year && _focusedMonth.month == DateTime.now().month;

    return Scaffold(
      backgroundColor: currentTheme.scaffoldBackground,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // 1. Modern Header Bar (Month Selector + Quick Next/Prev + Today Shortcut)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Row(
                      children: [
                        // Month & Year Selector Trigger
                        GestureDetector(
                          onTap: _showMonthPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: currentTheme.cardBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: currentTheme.borderColor.withValues(alpha: 0.6)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_month_rounded, size: 18, color: currentTheme.primaryColor),
                                const SizedBox(width: 6),
                                Text(
                                  _formatMonthYear(_focusedMonth),
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: currentTheme.textColor,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.keyboard_arrow_down_rounded, color: currentTheme.textColor, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),

                        // Jump to Today Shortcut Button
                        if (!isFocusedThisMonth)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: _jumpToToday,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: currentTheme.primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: currentTheme.primaryColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.today_rounded, size: 14, color: currentTheme.primaryColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      isEng ? 'Today' : 'วันนี้',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: currentTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Fast Previous & Next Month Navigation Buttons
                        Container(
                          decoration: BoxDecoration(
                            color: currentTheme.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: currentTheme.borderColor.withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: _previousMonth,
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(Icons.chevron_left_rounded, size: 22, color: currentTheme.textColor),
                                ),
                              ),
                              Container(width: 1, height: 18, color: currentTheme.borderColor),
                              InkWell(
                                onTap: _nextMonth,
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(Icons.chevron_right_rounded, size: 22, color: currentTheme.textColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Monthly Financial Summary Cards
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: currentTheme.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: currentTheme.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Expense Card
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isEng ? 'Expense' : 'รายจ่ายรวม',
                                    style: TextStyle(fontSize: 11.5, color: currentTheme.textSecondaryColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '฿${FormatUtils.formatCurrency(expenseTotal)}',
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEF4444),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 32, color: currentTheme.borderColor),

                        // Income Card
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isEng ? 'Income' : 'รายรับรวม',
                                      style: TextStyle(fontSize: 11.5, color: currentTheme.textSecondaryColor),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '฿${FormatUtils.formatCurrency(incomeTotal)}',
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(width: 1, height: 32, color: currentTheme.borderColor),

                        // Net Total Card
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: netTotal >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isEng ? 'Net' : 'ยอดสุทธิ',
                                      style: TextStyle(fontSize: 11.5, color: currentTheme.textSecondaryColor),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${netTotal >= 0 ? "+" : ""}฿${FormatUtils.formatCurrency(netTotal)}',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: netTotal >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Weekday Row Header (จ. อ. พ. พฤ. ศ. ส. อา.)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: isEng
                          ? const [
                              _WeekdayLabel('M'),
                              _WeekdayLabel('T'),
                              _WeekdayLabel('W'),
                              _WeekdayLabel('T'),
                              _WeekdayLabel('F'),
                              _WeekdayLabel('S'),
                              _WeekdayLabel('S'),
                            ]
                          : const [
                              _WeekdayLabel('จ.'),
                              _WeekdayLabel('อ.'),
                              _WeekdayLabel('พ.'),
                              _WeekdayLabel('พฤ.'),
                              _WeekdayLabel('ศ.'),
                              _WeekdayLabel('ส.'),
                              _WeekdayLabel('อา.'),
                            ],
                    ),
                  ),

                  // 4. Calendar Days Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: currentTheme.cardBackground,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: currentTheme.borderColor),
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 0.88,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: totalGridCells,
                        itemBuilder: (context, index) {
                          final dayNum = index - leadingEmptyDays + 1;
                          final isCurrentMonthDay = dayNum >= 1 && dayNum <= daysInMonth;

                          if (!isCurrentMonthDay) {
                            // Out of current month cell
                            final prevDays = DateTime(_focusedMonth.year, _focusedMonth.month, 0).day;
                            final displayDay = dayNum < 1 ? prevDays + dayNum : dayNum - daysInMonth;
                            return Container(
                              decoration: BoxDecoration(
                                color: currentTheme.surfaceBackground.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '$displayDay',
                                  style: TextStyle(
                                    color: currentTheme.textSecondaryColor.withValues(alpha: 0.35),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            );
                          }

                          final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
                          final isToday = cellDate.year == DateTime.now().year &&
                              cellDate.month == DateTime.now().month &&
                              cellDate.day == DateTime.now().day;

                          final isSelected = cellDate.year == _selectedDate.year &&
                              cellDate.month == _selectedDate.month &&
                              cellDate.day == _selectedDate.day;

                          final dayExpense = dailyExpenses[dayNum] ?? 0.0;
                          final dayIncome = dailyIncomes[dayNum] ?? 0.0;

                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedDate = cellDate);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? currentTheme.primaryColor.withValues(alpha: 0.22)
                                    : (isToday
                                        ? currentTheme.primaryColor.withValues(alpha: 0.08)
                                        : currentTheme.surfaceBackground.withValues(alpha: 0.4)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? currentTheme.primaryColor
                                      : (isToday ? currentTheme.primaryColor.withValues(alpha: 0.5) : Colors.transparent),
                                  width: isSelected ? 1.8 : 1.0,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Day Number & Today dot
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (isToday)
                                        Container(
                                          width: 5,
                                          height: 5,
                                          margin: const EdgeInsets.only(right: 2),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFF59E0B),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      Text(
                                        '$dayNum',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isToday
                                              ? currentTheme.primaryDark
                                              : (isSelected ? currentTheme.primaryColor : currentTheme.textColor),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Daily Expense / Income Indicators
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (dayExpense > 0)
                                        Text(
                                          dayExpense >= 10000 ? '${(dayExpense / 1000).toStringAsFixed(1)}k' : dayExpense.toStringAsFixed(0),
                                          style: const TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFEF4444),
                                          ),
                                          maxLines: 1,
                                        ),
                                      if (dayIncome > 0)
                                        Text(
                                          dayIncome >= 10000 ? '${(dayIncome / 1000).toStringAsFixed(1)}k' : dayIncome.toStringAsFixed(0),
                                          style: const TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF10B981),
                                          ),
                                          maxLines: 1,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),

                  const SizedBox(height: 10),

                  // 5. Selected Day Transactions Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    decoration: BoxDecoration(
                      color: currentTheme.cardBackground,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                      border: Border.all(color: currentTheme.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header: Selected Date + Add Transaction Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.event_note_rounded, size: 16, color: currentTheme.primaryColor),
                                    const SizedBox(width: 5),
                                    Text(
                                      _formatSelectedDateHeader(_selectedDate),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: currentTheme.textColor,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: currentTheme.surfaceBackground,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${selectedTransactions.length} ${isEng ? "items" : "รายการ"}',
                                        style: TextStyle(fontSize: 11, color: currentTheme.textSecondaryColor),
                                      ),
                                    ),
                                  ],
                                ),
                                if (selectedDayExpense > 0 || selectedDayIncome > 0) ...[
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      if (selectedDayExpense > 0)
                                        Text(
                                          '${isEng ? "Spent" : "จ่าย"}: ฿${FormatUtils.formatCurrency(selectedDayExpense)}  ',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
                                        ),
                                      if (selectedDayIncome > 0)
                                        Text(
                                          '${isEng ? "Income" : "รับ"}: ฿${FormatUtils.formatCurrency(selectedDayIncome)}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),

                            // Add Transaction Button
                            InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MeowEntryScreen(
                                      controller: widget.controller,
                                      initialDate: _selectedDate,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: currentTheme.primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: currentTheme.primaryColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.add_rounded, size: 16, color: currentTheme.primaryColor),
                                    const SizedBox(width: 3),
                                    Text(
                                      isEng ? 'Add' : 'เพิ่มรายการ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: currentTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 16),

                        // Transaction List or Empty State
                        selectedTransactions.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 28),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.inbox_outlined, size: 36, color: currentTheme.textSecondaryColor.withValues(alpha: 0.5)),
                                      const SizedBox(height: 8),
                                      Text(
                                        isEng ? 'No transactions on this day' : 'ไม่มีรายการในวันนี้',
                                        style: TextStyle(fontSize: 13, color: currentTheme.textSecondaryColor),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(top: 2, bottom: 90),
                                itemCount: selectedTransactions.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 6),
                                itemBuilder: (context, idx) {
                                  final tx = selectedTransactions[idx];
                                  final isExp = tx.type == TransactionType.expense;
                                  final isInc = tx.type == TransactionType.income;
                                  final color = isInc ? const Color(0xFF10B981) : (isExp ? const Color(0xFFEF4444) : const Color(0xFF3B82F6));
                                  final hasSlip = tx.slipImageUrl != null && tx.slipImageUrl!.isNotEmpty;

                                  return Dismissible(
                                    key: Key('cal_tx_${tx.id}'),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: const [
                                          Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                                          SizedBox(width: 6),
                                          Text(
                                            'ลบรายการ',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    onDismissed: (_) {
                                      _handleTransactionDismissed(tx);
                                    },
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(14),
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
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: currentTheme.surfaceBackground.withValues(alpha: 0.6),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: currentTheme.borderColor.withValues(alpha: 0.5)),
                                          ),
                                          child: Row(
                                            children: [
                                              // Icon or Slip Thumbnail
                                              if (hasSlip) ...[
                                                GestureDetector(
                                                  onTap: () {
                                                    SlipImageViewerDialog.show(context, tx.slipImageUrl!, title: tx.title);
                                                  },
                                                  child: Stack(
                                                    alignment: Alignment.bottomRight,
                                                    children: [
                                                      Container(
                                                        width: 48,
                                                        height: 54,
                                                        decoration: BoxDecoration(
                                                          color: currentTheme.isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                                          borderRadius: BorderRadius.circular(9),
                                                          border: Border.all(
                                                            color: currentTheme.primaryColor.withValues(alpha: 0.35),
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
                                                              width: 48,
                                                              height: 54,
                                                              color: const Color(0xFF0F172A),
                                                              child: const Icon(Icons.receipt, color: Color(0xFFF59E0B), size: 18),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.all(2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black.withValues(alpha: 0.75),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(Icons.zoom_in, color: Colors.white, size: 9),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ] else ...[
                                                Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: color.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Icon(
                                                    isInc
                                                        ? Icons.arrow_downward_rounded
                                                        : (isExp ? Icons.arrow_upward_rounded : Icons.swap_horiz_rounded),
                                                    color: color,
                                                    size: 18,
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(width: 10),

                                              // Title, category, tags
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      tx.title,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                        color: currentTheme.textColor,
                                                        height: 1.25,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          tx.categoryName,
                                                          style: TextStyle(fontSize: 11, color: currentTheme.textSecondaryColor),
                                                        ),
                                                        if (tx.tags.isNotEmpty) ...[
                                                          const SizedBox(width: 6),
                                                          Flexible(
                                                            child: Text(
                                                              tx.tags.map((t) => '#${t.replaceAll('#', '')}').join(' '),
                                                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: currentTheme.primaryDark),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    if (tx.note != null && tx.note!.trim().isNotEmpty) ...[
                                                      const SizedBox(height: 3),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                        decoration: BoxDecoration(
                                                          color: currentTheme.surfaceBackground,
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(
                                                            color: currentTheme.primaryColor.withValues(alpha: 0.2),
                                                            width: 0.8,
                                                          ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(Icons.notes_rounded, size: 10, color: currentTheme.primaryColor),
                                                            const SizedBox(width: 3),
                                                            Flexible(
                                                              child: Text(
                                                                tx.note!.trim(),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                                style: TextStyle(
                                                                  fontSize: 9.5,
                                                                  fontStyle: FontStyle.italic,
                                                                  color: currentTheme.textColor.withValues(alpha: 0.85),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),

                                              // Amount and time
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '${isInc ? "+" : (isExp ? "-" : "")}฿${FormatUtils.formatCurrency(tx.amount)}',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13.5,
                                                      color: color,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')} น.',
                                                    style: TextStyle(fontSize: 10, color: currentTheme.textSecondaryColor),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(Icons.chevron_right_rounded, size: 16, color: currentTheme.textSecondaryColor),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // 6. Lightweight Zero-Lag Floating Countdown Undo Banner (Matching MeowDashboard)
            ValueListenableBuilder<List<TransactionItem>>(
              valueListenable: _pendingDeletedNotifier,
              builder: (context, pendingList, _) {
                final isVisible = pendingList.isNotEmpty;
                final isEng = widget.controller.isEnglish;
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  bottom: isVisible ? 20 : -120,
                  left: 16,
                  right: 16,
                  child: RepaintBoundary(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isVisible ? 1.0 : 0.0,
                      child: isVisible
                          ? Material(
                              color: Colors.transparent,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: MeowTheme.mustardYellow.withOpacity(0.4),
                                    width: 1.0,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x66000000),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ValueListenableBuilder<double>(
                                  valueListenable: _undoCountdownNotifier,
                                  builder: (context, countdown, _) {
                                    final itemTitle = pendingList.length > 1
                                        ? (isEng
                                            ? 'Deleted ${pendingList.length} transactions'
                                            : 'ลบแล้ว ${pendingList.length} รายการ')
                                        : 'ลบ "${pendingList.last.title}"';

                                    return Row(
                                      children: [
                                        // Clean Minimal Countdown Indicator
                                        Container(
                                          width: 32,
                                          height: 32,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: MeowTheme.mustardYellow.withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            countdown.toStringAsFixed(1),
                                            style: const TextStyle(
                                              color: MeowTheme.mustardYellow,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                itemTitle,
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
                                                isEng
                                                    ? 'Undo available (${countdown.toStringAsFixed(1)}s)'
                                                    : 'กดยกเลิกได้ใน ${countdown.toStringAsFixed(1)} วิ...',
                                                style: const TextStyle(
                                                  color: Color(0xFF94A3B8),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: _undoBatchDelete,
                                          borderRadius: BorderRadius.circular(10),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF59E0B),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.undo_rounded, color: Color(0xFF0F172A), size: 15),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isEng ? 'Undo' : 'เลิกทำ',
                                                  style: const TextStyle(
                                                    color: Color(0xFF0F172A),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;

  const _WeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8C7A6B),
          ),
        ),
      ),
    );
  }
}
