import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction_item.dart';
import '../models/category_item.dart';
import '../models/account_item.dart';
import '../state/expense_controller.dart';
import '../widgets/calculator_numpad.dart';
import '../theme/app_theme_model.dart';
import '../widgets/meow_wheel_date_picker.dart';
import '../widgets/tactile_button.dart';
import '../widgets/slip_image_viewer_dialog.dart';
import '../services/native_gallery_service.dart';
import '../services/slip_storage_service.dart';
import '../services/native_bridge_service.dart';
import '../services/qr_slip_parser_service.dart';
import '../services/ocr_engine_service.dart';
import '../services/easyocr_tesseract_fusion_service.dart';
import '../utils/format_utils.dart';
import 'category_management_screen.dart';
import 'account_management_screen.dart';
import '../widgets/currency_quick_convert_sheet.dart';
import '../widgets/bank_badge.dart';
import '../services/thai_bank_detector.dart';
import '../widgets/meow_paywall_modal.dart';

class MeowEntryScreen extends StatefulWidget {
  final ExpenseController controller;
  final TransactionType initialType;
  final DateTime? initialDate;
  final double? initialAmount;
  final String? initialNote;

  const MeowEntryScreen({
    super.key,
    required this.controller,
    this.initialType = TransactionType.expense,
    this.initialDate,
    this.initialAmount,
    this.initialNote,
  });

  @override
  State<MeowEntryScreen> createState() => _MeowEntryScreenState();
}

class _MeowEntryScreenState extends State<MeowEntryScreen> {
  late TransactionType _selectedType;
  late DateTime _selectedDate;
  String _calcInput = '0';
  String _note = '';
  String _selectedTag = '';
  String? _slipImagePath;

  CategoryItem? _selectedCategory;
  AccountItem? _selectedAccount;

  // 3 Tabs: 0: รายจ่าย, 1: รายรับ, 2: บัตรเครดิต
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();

    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _calcInput = widget.initialAmount == widget.initialAmount!.roundToDouble()
          ? widget.initialAmount!.toInt().toString()
          : widget.initialAmount!.toStringAsFixed(2);
    }
    if (widget.initialNote != null && widget.initialNote!.isNotEmpty) {
      _note = widget.initialNote!;
    }

    if (widget.initialType == TransactionType.income) {
      _currentTab = 1;
      _selectedType = TransactionType.income;
    } else {
      _currentTab = 0;
      _selectedType = TransactionType.expense;
    }

    if (widget.controller.accounts.isNotEmpty) {
      _selectedAccount = widget.controller.accounts.first;
    }

    _setDefaultCategory();
  }

  void _setDefaultCategory() {
    final list = _selectedType == TransactionType.income
        ? widget.controller.incomeCategories
        : widget.controller.expenseCategories;
    if (list.isNotEmpty) {
      _selectedCategory = list.first;
    }
  }

  void _switchTab(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentTab = index;
      if (index == 0) {
        _selectedType = TransactionType.expense;
      } else if (index == 1) {
        _selectedType = TransactionType.income;
      } else if (index == 2) {
        _selectedType = TransactionType.expense; // บัตรเครดิต
      }
      _setDefaultCategory();
    });
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final picked = await MeowWheelDatePicker.showWheelDateTimePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
      isEnglish: widget.controller.isEnglish,
      isDarkMode: widget.controller.isDarkMode,
      title: widget.controller.isEnglish ? 'Select Date & Time' : 'เลือกวันและเวลาทำรายการ',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showAccountPicker() {
    HapticFeedback.selectionClick();
    final currentTheme = widget.controller.currentTheme;
    final isEn = widget.controller.isEnglish;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          // All available bank templates that aren't yet added
          final allSupported = ThaiBankDetector.supportedBanks;
          final existingBankCodes = widget.controller.accounts.map((a) => a.bankCode.toUpperCase()).toSet();
          final otherBanks = allSupported.where((b) => !existingBankCodes.contains(b.code)).toList();

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.80,
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: currentTheme.cardBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEn ? 'Select Wallet / Bank' : 'เลือกบัญชี / ธนาคาร',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: currentTheme.textColor,
                      ),
                    ),
                    TactileButton(
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AccountManagementScreen(controller: widget.controller),
                          ),
                        ).then((_) {
                          if (mounted) setState(() {});
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: currentTheme.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: currentTheme.primaryColor.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.settings_outlined, size: 14, color: currentTheme.primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              isEn ? 'Manage' : 'จัดการบัญชี',
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
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Section 1: บัญชีของคุณที่เปิดใช้งานอยู่ (My Accounts)
                      Text(
                        isEn ? 'My Accounts (${widget.controller.accounts.length})' : 'บัญชีของคุณ (${widget.controller.accounts.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: currentTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.controller.accounts.map((acc) {
                        final isSel = _selectedAccount?.id == acc.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSel ? currentTheme.primaryColor.withValues(alpha: 0.12) : currentTheme.surfaceBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSel ? currentTheme.primaryColor : currentTheme.borderColor,
                              width: isSel ? 1.5 : 1,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: BankBadge(bankCode: acc.bankCode, size: 36),
                            title: Text(
                              widget.controller.trAccount(acc.name),
                              style: TextStyle(
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                color: currentTheme.textColor,
                              ),
                            ),
                            subtitle: Text(
                              '฿${FormatUtils.formatCurrency(acc.balance)}  •  ${acc.accountNumber}',
                              style: TextStyle(
                                color: currentTheme.textSecondaryColor,
                                fontSize: 11.5,
                              ),
                            ),
                            trailing: isSel
                                ? Icon(Icons.check_circle_rounded, color: currentTheme.primaryColor, size: 22)
                                : null,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedAccount = acc);
                              Navigator.pop(ctx);
                            },
                          ),
                        );
                      }),

                      // Section 2: ธนาคารทั้งหมด (All Banks - Quick Select & Auto Add)
                      if (otherBanks.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Text(
                              isEn ? 'All Other Banks & Wallets (${otherBanks.length})' : 'ธนาคารและกระเป๋าเงินอื่นๆ (${otherBanks.length})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: currentTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...otherBanks.map((bank) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: currentTheme.surfaceBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: currentTheme.borderColor),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: BankBadge(bankCode: bank.code, size: 36),
                              title: Text(
                                bank.nameTh,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: currentTheme.textColor,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                '${bank.shortName}  •  ${bank.nameEn}',
                                style: TextStyle(
                                  color: currentTheme.textSecondaryColor,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: currentTheme.primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isEn ? 'Select' : 'เลือก',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: currentTheme.primaryColor,
                                  ),
                                ),
                              ),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                // Create and add account on the fly
                                final newAcc = AccountItem(
                                  id: 'acc_${bank.code.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
                                  name: bank.nameTh,
                                  bankCode: bank.code,
                                  accountNumber: bank.code == 'CASH' ? 'CASH-WALLET' : 'xxx-x-xxxxx-x',
                                  balance: 0.0,
                                  colorValue: bank.brandColor.toARGB32(),
                                  type: (bank.code == 'PAOTANG' || bank.code == 'TRUEMONEY')
                                      ? AccountType.eWallet
                                      : (bank.code == 'CASH' ? AccountType.cash : AccountType.bank),
                                  allowAutoDeduction: true,
                                );
                                widget.controller.addAccount(newAcc);
                                setState(() => _selectedAccount = newAcc);
                                Navigator.pop(ctx);
                              },
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showNoteModal() {
    HapticFeedback.selectionClick();
    final currentTheme = widget.controller.currentTheme;
    final isEn = widget.controller.isEnglish;
    final controller = TextEditingController(text: _note);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: BoxDecoration(
          color: currentTheme.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEn ? 'Transaction Memo / Note' : 'บันทึกช่วยจำ (Memo)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: currentTheme.textColor),
                ),
                if (_note.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    icon: const Icon(Icons.clear, size: 16, color: Color(0xFFEF4444)),
                    label: Text(isEn ? 'Clear' : 'ล้างโน้ต', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                    onPressed: () {
                      setState(() => _note = '');
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              autofocus: true,
              style: TextStyle(color: currentTheme.textColor, fontSize: 15),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: isEn ? 'Write a note or reminder...' : 'พิมพ์บันทึกช่วยจำ...',
                hintStyle: TextStyle(color: currentTheme.textSecondaryColor, fontSize: 13),
                filled: true,
                fillColor: currentTheme.surfaceBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: currentTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: currentTheme.borderColor),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _note = controller.text.trim());
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(isEn ? 'Done' : 'บันทึกโน้ต', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTagPicker() {
    HapticFeedback.selectionClick();
    final currentTheme = widget.controller.currentTheme;
    final isEn = widget.controller.isEnglish;
    final tagInputCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final tags = widget.controller.savedTags;

          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: currentTheme.cardBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEn ? 'Select #Tag' : '# เลือกแท็กกำกับรายการ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: currentTheme.textColor),
                    ),
                    if (_selectedTag.isNotEmpty)
                      TextButton.icon(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        icon: const Icon(Icons.clear, size: 16, color: Color(0xFFEF4444)),
                        label: Text(isEn ? 'Clear' : 'ล้างแท็ก', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                        onPressed: () {
                          setState(() => _selectedTag = '');
                          Navigator.pop(ctx);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // Add New Tag Input Field
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tagInputCtrl,
                        style: TextStyle(color: currentTheme.textColor, fontSize: 14),
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: isEn ? 'Type #tag (e.g. #coffee, #fuel)' : 'พิมพ์ #แท็ก เช่น #ข้าวมันไก่, #กาแฟ',
                          hintStyle: TextStyle(color: currentTheme.textSecondaryColor, fontSize: 13),
                          filled: true,
                          fillColor: currentTheme.surfaceBackground,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          prefixIcon: Icon(Icons.tag_rounded, color: currentTheme.primaryColor, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: currentTheme.borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: currentTheme.borderColor),
                          ),
                        ),
                        onSubmitted: (val) {
                          final clean = val.replaceAll('#', '').trim();
                          if (clean.isNotEmpty) {
                            widget.controller.saveTag(clean);
                            setState(() => _selectedTag = clean);
                            Navigator.pop(ctx);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () {
                        final clean = tagInputCtrl.text.replaceAll('#', '').trim();
                        if (clean.isNotEmpty) {
                          widget.controller.saveTag(clean);
                          setState(() => _selectedTag = clean);
                          Navigator.pop(ctx);
                        }
                      },
                      child: Text(
                        isEn ? 'Add' : 'ใส่แท็ก',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quick Tag Suggestions
                Text(
                  isEn ? 'Quick Suggestions:' : 'แท็กยอดนิยม แตะเพื่อเลือกทันที:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentTheme.textSecondaryColor),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    'มื้อเช้า', 'มื้อเที่ยง', 'มื้อเย็น', 'กาแฟ', 'ของกิน', 'ค่าน้ำมัน',
                    'ช้อปปิ้ง', 'ทำบุญ', 'ครอบครัว', 'ค่าห้อง', 'ยาและรักษา', 'ท่องเที่ยว'
                  ].map((suggested) {
                    final isSel = _selectedTag == suggested;
                    return ActionChip(
                      backgroundColor: isSel ? currentTheme.primaryColor : currentTheme.surfaceBackground,
                      side: BorderSide(color: isSel ? currentTheme.primaryDark : currentTheme.borderColor),
                      label: Text(
                        '#$suggested',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          color: isSel ? Colors.white : currentTheme.textColor,
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        widget.controller.saveTag(suggested);
                        setState(() => _selectedTag = isSel ? '' : suggested);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),
                if (tags.isNotEmpty) ...[
                  Text(
                    isEn
                        ? 'Saved Tags (${tags.length}) - Tap to use:'
                        : 'แท็กที่จดจำไว้ (${tags.length} แท็ก) - แตะเพื่อเลือก:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentTheme.textSecondaryColor),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tags.map((tag) {
                          final isSel = _selectedTag == tag;
                          return Container(
                            decoration: BoxDecoration(
                              color: isSel ? currentTheme.primaryColor : currentTheme.surfaceBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSel ? currentTheme.primaryDark : currentTheme.borderColor,
                                width: isSel ? 1.5 : 1,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                setState(() => _selectedTag = isSel ? '' : tag);
                                Navigator.pop(ctx);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '#$tag',
                                      style: TextStyle(
                                        color: isSel ? Colors.white : currentTheme.textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        widget.controller.deleteSavedTag(tag);
                                        if (_selectedTag == tag) {
                                          setState(() => _selectedTag = '');
                                        }
                                        setSheetState(() {});
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: isSel ? Colors.black26 : Colors.grey.withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickSlipImage() async {
    HapticFeedback.selectionClick();

    if (!widget.controller.canImportMoreSlips) {
      final monthlyUsed = widget.controller.currentMonthSlipCount;
      final monthlyMax = widget.controller.maxFreeSlipsPerMonth;
      final isEn = widget.controller.isEnglish;
      MeowPaywallModal.show(
        context,
        controller: widget.controller,
        reason: isEn
            ? 'Monthly slip quota reached ($monthlyUsed/$monthlyMax slips). Watch short ad for +2 free slips or upgrade to VIP for unlimited slips!'
            : 'โควต้าสลิปฟรีเดือนนี้ครบแล้ว ($monthlyUsed/$monthlyMax สลิป) 🎬 ดูคลิปสั้นรับฟรี +2 สลิปได้ทันที หรือสมัคร VIP สแกนไม่อั้นตลอดชีพ 👑',
      );
      return;
    }

    await NativeBridgeService.requestAppPermissions();
    final path = await NativeGalleryService.pickImageFromGallery();
    if (path != null && path.isNotEmpty) {
      final savedPath = await SlipStorageService.persistSlipImage(path);
      setState(() => _slipImagePath = savedPath);

      // Auto extract amount from slip and fill into calculator on the "+" screen!
      try {
        final mlResult = await NativeBridgeService.processSlipImage(savedPath);
        final qrPayload = mlResult['qrPayload'] as String? ?? '';
        final rawOcrText = mlResult['ocrText'] as String? ?? '';

        double detectedAmount = 0.0;
        if (qrPayload.trim().isNotEmpty) {
          final qrResult = QrSlipParserService.parseQrCodePayload(qrPayload);
          if (qrResult.success && qrResult.amount > 0) {
            detectedAmount = qrResult.amount;
          }
        }
        if (detectedAmount <= 0 && rawOcrText.trim().isNotEmpty) {
          final ocrParsed = widget.controller.parseSlip(rawOcrText, fileName: path, filePath: savedPath);
          if (ocrParsed.amount > 0) {
            detectedAmount = ocrParsed.amount;
          } else {
            detectedAmount = OcrEngineService.extractAmountFromText(rawOcrText);
          }
        }
        if (detectedAmount <= 0 && rawOcrText.trim().isNotEmpty) {
          detectedAmount = EasyOcrTesseractFusionService.extractAmount(rawOcrText);
        }

        if (detectedAmount > 0 && mounted) {
          setState(() {
            _calcInput = detectedAmount == detectedAmount.roundToDouble()
                ? detectedAmount.toInt().toString()
                : detectedAmount.toStringAsFixed(2);
          });
          HapticFeedback.mediumImpact();
        }

        final detectedDate = OcrEngineService.extractDateTimeFromText(
          rawOcrText,
          fileName: path,
        );
        if (mounted) {
          setState(() {
            _selectedDate = detectedDate;
          });
        }
      } catch (e) {
        debugPrint('Slip extraction error on entry screen: $e');
      }
    }
  }

  Widget _buildSlipThumbnail(AppThemeModel currentTheme, bool isEn) {
    final hasSlip = _slipImagePath != null && _slipImagePath!.isNotEmpty;
    final fileExists = hasSlip && File(_slipImagePath!).existsSync();

    if (hasSlip) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          // Directly open Full Slip Viewer on tap!
          SlipImageViewerDialog.show(
            context,
            _slipImagePath!,
            title: _selectedCategory?.name ?? (isEn ? 'Slip Receipt' : 'รูปสลิป'),
            onReplace: () {
              Navigator.pop(context);
              _pickSlipImage();
            },
            onDelete: () {
              Navigator.pop(context);
              setState(() => _slipImagePath = null);
            },
          );
        },
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF10B981), width: 1.8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.25),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (fileExists)
                  Image.file(
                    File(_slipImagePath!),
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    color: currentTheme.surfaceBackground,
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 22),
                  ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.zoom_in_rounded, size: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _pickSlipImage,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: currentTheme.surfaceBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: currentTheme.borderColor,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_rounded,
              size: 20,
              color: currentTheme.primaryColor,
            ),
            const SizedBox(height: 2),
            Text(
              isEn ? '+Slip' : '+สลิป',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: currentTheme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    final evaluated = CalculatorNumpad.evaluateExpression(_calcInput);
    final amount = evaluated ?? 0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.isEnglish ? 'Please enter amount greater than 0' : 'กรุณาระบุจำนวนเงินที่มากกว่า 0'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.isEnglish ? 'Please select a category' : 'กรุณาเลือกหมวดหมู่รายการ'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    final acc = _selectedAccount ?? (widget.controller.accounts.isNotEmpty ? widget.controller.accounts.first : null);
    if (acc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.controller.isEnglish ? 'No wallet account found' : 'ไม่พบบัญชีกระเป๋าเงิน')),
      );
      return;
    }

    final title = _selectedCategory?.name ?? 'รายการทั่วไป';

    final hasSlip = _slipImagePath != null && _slipImagePath!.isNotEmpty;
    if (hasSlip && !widget.controller.canImportMoreSlips) {
      final monthlyUsed = widget.controller.currentMonthSlipCount;
      final monthlyMax = widget.controller.maxFreeSlipsPerMonth;
      final isEn = widget.controller.isEnglish;
      MeowPaywallModal.show(
        context,
        controller: widget.controller,
        reason: isEn
            ? 'Monthly slip quota reached ($monthlyUsed/$monthlyMax slips). Watch short ad for +2 free slips or upgrade to VIP for unlimited slips!'
            : 'โควต้าสลิปฟรีเดือนนี้ครบแล้ว ($monthlyUsed/$monthlyMax สลิป) 🎬 ดูคลิปสั้นรับฟรี +2 สลิปได้ทันที หรือสมัคร VIP สแกนไม่อั้นตลอดชีพ 👑',
      );
      return;
    }

    final persistentSlipPath = hasSlip
        ? await SlipStorageService.persistSlipImage(_slipImagePath!)
        : _slipImagePath;

    final item = TransactionItem(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      amount: amount,
      type: _selectedType,
      date: _selectedDate,
      accountId: acc.id,
      categoryId: _selectedCategory?.id ?? 'cat_other',
      categoryName: _selectedCategory?.name ?? 'ทั่วไป',
      note: _note.isNotEmpty ? _note : null,
      tags: _selectedTag.isNotEmpty ? [_selectedTag] : [],
      slipImageUrl: persistentSlipPath,
    );

    if (_selectedTag.isNotEmpty) {
      widget.controller.saveTag(_selectedTag);
    }
    widget.controller.addTransaction(item);
    if (hasSlip) {
      await widget.controller.recordSlipImported(slipDate: item.date);
    }
    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.controller.isEnglish
              ? 'Recorded "${item.title}" ฿${FormatUtils.formatCurrency(amount)} successfully!'
              : 'บันทึกรายการ "${item.title}" ฿${FormatUtils.formatCurrency(amount)} สำเร็จแล้ว!',
        ),
        backgroundColor: widget.controller.currentTheme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = widget.controller.currentTheme;
    final isEn = widget.controller.isEnglish;
    final categories = _selectedType == TransactionType.income
        ? widget.controller.incomeCategories
        : widget.controller.expenseCategories;

    final accName = _selectedAccount?.name ?? (isEn ? 'Wallet' : 'บัญชีธนาคาร');
    final accBalance = _selectedAccount?.balance ?? 0.0;

    // Formatted Thai Date for prominent date button
    final months = isEn
        ? ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
        : ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year && _selectedDate.month == now.month && _selectedDate.day == now.day;
    final datePrefix = isToday ? (isEn ? 'Today ' : 'วันนี้ ') : '';
    final timeStr = '${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}';
    final dateLabel = '$datePrefix${_selectedDate.day} ${months[_selectedDate.month - 1]} ($timeStr)';

    return Scaffold(
      backgroundColor: currentTheme.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top 3 Tabs & Close button (รายจ่าย, รายรับ, บัตรเครดิต)
            Container(
              color: currentTheme.surfaceBackground,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _buildTopTabItem(
                          widget.controller.tr('expense'),
                          Icons.arrow_upward_rounded,
                          0,
                          currentTheme,
                        ),
                        const SizedBox(width: 5),
                        _buildTopTabItem(
                          widget.controller.tr('income'),
                          Icons.arrow_downward_rounded,
                          1,
                          currentTheme,
                        ),
                        const SizedBox(width: 5),
                        _buildTopTabItem(
                          widget.controller.appLanguage == 'ms'
                              ? 'كد كريديت'
                              : (isEn ? 'Credit Card' : 'บัตรเครดิต'),
                          Icons.credit_card_rounded,
                          2,
                          currentTheme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: currentTheme.textColor, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Wallet / Account selector pill & Manage categories
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _showAccountPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: currentTheme.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: currentTheme.borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.account_balance_rounded, size: 16, color: currentTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            '฿${FormatUtils.formatCurrency(accBalance)} ${widget.controller.trAccount(accName)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: currentTheme.textColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: currentTheme.textSecondaryColor),
                        ],
                      ),
                    ),
                  ),
                  // Manage categories button
                  TactileButton(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryManagementScreen(controller: widget.controller),
                        ),
                      ).then((_) => setState(() {}));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: currentTheme.surfaceBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: currentTheme.borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.tune_rounded, size: 16, color: currentTheme.primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            isEn ? 'Categories' : 'จัดการหมวด',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 10,
                ),
                itemCount: categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == categories.length) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryManagementScreen(controller: widget.controller),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: currentTheme.surfaceBackground,
                              shape: BoxShape.circle,
                              border: Border.all(color: currentTheme.borderColor),
                            ),
                            child: Icon(Icons.add, color: currentTheme.textSecondaryColor, size: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isEn ? 'Add' : 'เพิ่มหมวด',
                            style: TextStyle(fontSize: 11, color: currentTheme.textSecondaryColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }

                  final cat = categories[index];
                  final isSelected = _selectedCategory?.id == cat.id;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory = cat);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected ? currentTheme.primaryColor : currentTheme.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? currentTheme.primaryDark : currentTheme.borderColor,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            cat.icon,
                            color: isSelected ? Colors.white : Color(cat.colorValue),
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.controller.trCategory(cat.name),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: currentTheme.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Quick Action Tools Bar (Large Date & Time Button, FX Currency, Clear Amount)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: currentTheme.surfaceBackground,
              child: Row(
                children: [
                  // 1. Large & Easy-to-tap Date & Time Picker Button
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: currentTheme.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: currentTheme.primaryColor.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: currentTheme.primaryColor.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 16, color: currentTheme.primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            dateLabel,
                            style: TextStyle(color: currentTheme.textColor, fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 3),
                          Icon(Icons.arrow_drop_down_rounded, size: 18, color: currentTheme.textSecondaryColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 2. Currency Converter FX Button
                  InkWell(
                    onTap: () {
                      CurrencyQuickConvertSheet.show(
                        context: context,
                        isDark: currentTheme.isDark,
                        onConverted: (res) {
                          setState(() {
                            _calcInput = res.thbAmount.toStringAsFixed(2);
                            if (_note.isEmpty) {
                              _note = res.noteTag;
                            } else if (!_note.contains(res.noteTag)) {
                              _note = '$_note | ${res.noteTag}';
                            }
                          });
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: currentTheme.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: currentTheme.borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('💱', style: TextStyle(fontSize: 11.5)),
                          const SizedBox(width: 4),
                          Text(
                            isEn ? 'FX' : 'แปลงค่าเงิน',
                            style: TextStyle(color: currentTheme.textColor, fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),

                  // 3. Clear Amount Button
                  if (_calcInput != '0')
                    GestureDetector(
                      onTap: () => setState(() => _calcInput = '0'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isEn ? 'Clear' : 'ล้างยอด',
                          style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Grand Amount & Math Formula Display Card (พร้อมรูปสลิปจิ๋วทางซ้าย)
            Builder(builder: (context) {
              final isMathFormula = _calcInput.contains('+') || _calcInput.contains('-') || _calcInput.contains('×') || _calcInput.contains('÷');
              final liveTotal = isMathFormula ? CalculatorNumpad.evaluateExpression(_calcInput) : null;

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: currentTheme.cardBackground,
                  border: Border(
                    top: BorderSide(color: currentTheme.borderColor),
                    bottom: BorderSide(color: currentTheme.borderColor),
                  ),
                ),
                child: Row(
                  children: [
                    // 1. Slip Thumbnail / Attach Button (รูปสลิปเล็กๆ ด้านซ้ายของช่องใส่ยอด)
                    _buildSlipThumbnail(currentTheme, isEn),
                    const SizedBox(width: 8),

                    // 2. Currency Badge (฿)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: currentTheme.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: currentTheme.primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '฿',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: currentTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 3. Scrollable Big Amount / Math Expression
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _calcInput,
                              style: TextStyle(
                                fontSize: isMathFormula ? 28 : 34,
                                fontWeight: FontWeight.w900,
                                color: currentTheme.textColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (liveTotal != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  '= ฿${liveTotal.toStringAsFixed(liveTotal == liveTotal.roundToDouble() ? 0 : 2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Tag & Memo Section
            Container(
              color: currentTheme.surfaceBackground,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. #Tag Box (กล่อง #แท็ก อยู่ก่อนหน้าช่องเพิ่มบันทึกช่วยจำ)
                  TactileButton(
                    onTap: _showTagPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: currentTheme.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedTag.isNotEmpty ? currentTheme.primaryColor : currentTheme.borderColor,
                          width: _selectedTag.isNotEmpty ? 1.2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tag_rounded,
                            size: 18,
                            color: _selectedTag.isNotEmpty ? currentTheme.primaryColor : currentTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedTag.isNotEmpty ? '#$_selectedTag' : (isEn ? 'Select #Tag...' : '# เลือกแท็กกำกับรายการ...'),
                              style: TextStyle(
                                color: _selectedTag.isNotEmpty ? currentTheme.primaryDark : currentTheme.textSecondaryColor,
                                fontSize: 13,
                                fontWeight: _selectedTag.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_selectedTag.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedTag = '');
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded, size: 14, color: Colors.grey),
                              ),
                            )
                          else
                            Icon(
                              Icons.keyboard_arrow_right_rounded,
                              size: 18,
                              color: currentTheme.textSecondaryColor.withValues(alpha: 0.6),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 2. Memo / Note Box (กล่องเพิ่มบันทึกช่วยจำ)
                  TactileButton(
                    onTap: _showNoteModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: currentTheme.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _note.isNotEmpty ? currentTheme.primaryColor : currentTheme.borderColor,
                          width: _note.isNotEmpty ? 1.2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            size: 19,
                            color: _note.isNotEmpty ? currentTheme.primaryColor : currentTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _note.isNotEmpty ? _note : (isEn ? 'Add memo note / reminder...' : 'เพิ่มบันทึกช่วยจำ...'),
                              style: TextStyle(
                                color: _note.isNotEmpty ? currentTheme.textColor : currentTheme.textSecondaryColor,
                                fontSize: 13,
                                fontWeight: _note.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_note.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _note = '');
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded, size: 14, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Full Calculator Numpad with Save Button
            CalculatorNumpad(
              rawInput: _calcInput,
              currentTheme: currentTheme,
              saveButtonText: isEn ? 'Save Transaction' : 'บันทึกรายการ',
              onInputChanged: (val) {
                setState(() => _calcInput = val);
              },
              onSave: _saveTransaction,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTabItem(String label, IconData icon, int index, AppThemeModel theme) {
    final isSelected = _currentTab == index;
    Color activeColor;
    if (index == 0) {
      activeColor = const Color(0xFFEF4444); // Expense
    } else if (index == 1) {
      activeColor = const Color(0xFF10B981); // Income
    } else {
      activeColor = const Color(0xFF3B82F6); // Credit Card
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : theme.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? activeColor : theme.borderColor,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : theme.textColor,
              ),
              const SizedBox(width: 3),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : theme.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
