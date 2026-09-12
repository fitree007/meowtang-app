import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../widgets/bank_badge.dart';
import '../widgets/meow_mascot_widget.dart';
import '../widgets/tactile_button.dart';
import '../utils/format_utils.dart';

class SalaryAutoRecordScreen extends StatefulWidget {
  final ExpenseController controller;

  const SalaryAutoRecordScreen({super.key, required this.controller});

  @override
  State<SalaryAutoRecordScreen> createState() => _SalaryAutoRecordScreenState();
}

class _SalaryAutoRecordScreenState extends State<SalaryAutoRecordScreen> {
  late bool _isEnabled;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late int _dayOfMonth;
  late bool _isLastDayOfMonth;
  late String _selectedAccountId;
  late String _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final cfg = widget.controller.salaryConfig;
    _isEnabled = cfg.isEnabled;
    _amountController = TextEditingController(
      text: cfg.amount > 0 ? CurrencyFormat.format(cfg.amount, trimZero: true) : '',
    );
    _noteController = TextEditingController(text: cfg.note);
    _dayOfMonth = cfg.dayOfMonth;
    _isLastDayOfMonth = cfg.isLastDayOfMonth;

    // Check if account exists
    if (widget.controller.accounts.any((a) => a.id == cfg.accountId)) {
      _selectedAccountId = cfg.accountId;
    } else if (widget.controller.accounts.isNotEmpty) {
      _selectedAccountId = widget.controller.accounts.first.id;
    } else {
      _selectedAccountId = 'acc_cash';
    }

    _selectedCategoryId = cfg.categoryId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double _parseAmount() {
    final clean = _amountController.text.replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  Future<void> _saveConfig() async {
    HapticFeedback.mediumImpact();
    final amount = _parseAmount();
    final currentCfg = widget.controller.salaryConfig;

    final updated = currentCfg.copyWith(
      isEnabled: _isEnabled,
      amount: amount,
      dayOfMonth: _dayOfMonth,
      isLastDayOfMonth: _isLastDayOfMonth,
      accountId: _selectedAccountId,
      categoryId: _selectedCategoryId,
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : 'เงินเดือนประจำเดือน',
    );

    await widget.controller.updateSalaryAutoRecordConfig(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: MeowTheme.incomeGreen,
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'บันทึกการตั้งค่าเงินเดือนอัตโนมัติสำเร็จแล้ว เหมียว~ 🐱',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _testRecordNow() async {
    final amount = _parseAmount();
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: Colors.orange.shade700,
          content: const Text('กรุณากรอกจำนวนเงินเดือนที่ถูกต้องก่อนทดสอบครับ'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = widget.controller.isDarkMode;
        return AlertDialog(
          backgroundColor: isDark ? MeowTheme.navySurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.auto_fix_high_rounded, color: MeowTheme.actionBlue),
              SizedBox(width: 8),
              Text('ทดสอบบันทึกทันที', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          content: Text(
            'ต้องการบันทึกยอดเงินเดือน ฿${CurrencyFormat.format(amount)} เข้าบัญชีที่เลือก ณ ตอนนี้เลยหรือไม่?',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MeowTheme.incomeGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('บันทึกตอนนี้'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final currentCfg = widget.controller.salaryConfig;
      final updated = currentCfg.copyWith(
        isEnabled: _isEnabled,
        amount: amount,
        dayOfMonth: _dayOfMonth,
        isLastDayOfMonth: _isLastDayOfMonth,
        accountId: _selectedAccountId,
        categoryId: _selectedCategoryId,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : 'เงินเดือนประจำเดือน',
      );
      await widget.controller.updateSalaryAutoRecordConfig(updated);
      final success = await widget.controller.triggerManualSalaryRecord();
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: MeowTheme.incomeGreen,
              content: Text(
                '🎉 บันทึกยอดเงินเดือน ฿${CurrencyFormat.format(amount)} เข้าบัญชีเรียบร้อยแล้ว!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
          setState(() {});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่สามารถบันทึกได้ กรุณาตรวจสอบข้อมูล')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.controller.isDarkMode;
    final currentTheme = widget.controller.currentTheme;
    final cardBg = currentTheme.cardBackground;
    final borderColor = currentTheme.borderColor;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final cfg = widget.controller.salaryConfig;

    return Scaffold(
      backgroundColor: currentTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'บันทึกเงินเดือนอัตโนมัติ',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded, color: MeowTheme.incomeGreen, size: 26),
            tooltip: 'บันทึกการตั้งค่า',
            onPressed: _saveConfig,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Mascot Banner / Guide Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF064E3B), const Color(0xFF065F46)]
                      : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: MeowTheme.incomeGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  MeowMascotWidget(
                    size: 48,
                    mascotId: widget.controller.selectedMascotId,
                    accessory: widget.controller.selectedMascotAccessory,
                    isHeadOnly: true,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ออฟไลน์ 100% ไม่ต้องต่อเน็ต 🔒',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'เมื่อถึงวันที่คุณกำหนด น้องแมวจะบันทึกเงินเดือนเข้าบัญชีให้เองอัตโนมัติ 1 ครั้งต่อเดือน หมดกังวลเรื่องลืมจด!',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF065F46),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Enable Switch Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isEnabled
                          ? MeowTheme.incomeGreen.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isEnabled ? Icons.alarm_on_rounded : Icons.alarm_off_rounded,
                      color: _isEnabled ? MeowTheme.incomeGreen : Colors.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'เปิดบันทึกเงินเดือนอัตโนมัติ',
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isEnabled ? 'ระบบเปิดทำงานพร้อมบันทึกทุกเดือน' : 'ปิดการบันทึกอัตโนมัติอยู่',
                          style: TextStyle(color: textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isEnabled,
                    activeColor: MeowTheme.incomeGreen,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isEnabled = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Amount Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.paid_rounded, color: MeowTheme.incomeGreen, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'จำนวนเงินเดือน (บาท)',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      prefixText: '฿ ',
                      prefixStyle: const TextStyle(
                        color: MeowTheme.incomeGreen,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      hintText: '0.00',
                      hintStyle: TextStyle(color: textSecondary.withOpacity(0.5)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: MeowTheme.incomeGreen, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Quick Amount Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [15000, 20000, 25000, 30000, 35000, 40000, 50000].map((val) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _amountController.text = CurrencyFormat.format(val.toDouble(), trimZero: true);
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: borderColor),
                              ),
                              child: Text(
                                '฿${CurrencyFormat.format(val.toDouble(), trimZero: true)}',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Date of Month Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: Color(0xFF3B82F6), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'วันที่เงินเข้าของทุกเดือน',
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _isLastDayOfMonth ? 'วันสิ้นเดือน' : 'ทุกวันที่ $_dayOfMonth',
                          style: const TextStyle(
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // End of month switch
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isLastDayOfMonth = !_isLastDayOfMonth;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _isLastDayOfMonth
                            ? const Color(0xFF3B82F6).withOpacity(0.15)
                            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isLastDayOfMonth ? const Color(0xFF3B82F6) : borderColor,
                          width: _isLastDayOfMonth ? 1.8 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isLastDayOfMonth ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: _isLastDayOfMonth ? const Color(0xFF3B82F6) : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'วันสิ้นเดือน (อัตโนมัติ 28, 30 หรือ 31 ของเดือนนั้นๆ)',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 13,
                                fontWeight: _isLastDayOfMonth ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (!_isLastDayOfMonth) ...[
                    const SizedBox(height: 14),
                    Text(
                      'หรือเลือกวันที่ยอดนิยม:',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [25, 26, 27, 28, 30, 1, 5, 10, 15].map((day) {
                        final isSel = !_isLastDayOfMonth && _dayOfMonth == day;
                        return ChoiceChip(
                          label: Text('วันที่ $day'),
                          selected: isSel,
                          selectedColor: const Color(0xFF3B82F6),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : textPrimary,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          onSelected: (selected) {
                            if (selected) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _isLastDayOfMonth = false;
                                _dayOfMonth = day;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    // Slider for custom day 1-31
                    Row(
                      children: [
                        const Text('1', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Expanded(
                          child: Slider(
                            value: _dayOfMonth.toDouble(),
                            min: 1,
                            max: 31,
                            divisions: 30,
                            activeColor: const Color(0xFF3B82F6),
                            onChanged: (val) {
                              setState(() {
                                _isLastDayOfMonth = false;
                                _dayOfMonth = val.round();
                              });
                            },
                          ),
                        ),
                        const Text('31', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Target Account Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF8B5CF6), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'เลือกบัญชีที่รับเงินเดือนเข้า',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...widget.controller.accounts.map((acc) {
                    final isSel = _selectedAccountId == acc.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedAccountId = acc.id;
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFF8B5CF6).withOpacity(0.12)
                                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSel ? const Color(0xFF8B5CF6) : borderColor,
                              width: isSel ? 1.8 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              BankBadge(bankCode: acc.bankCode, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      acc.name,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    Text(
                                      'คงเหลือ: ฿${CurrencyFormat.format(acc.balance)}',
                                      style: TextStyle(color: textSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSel)
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF8B5CF6), size: 20)
                              else
                                const Icon(Icons.radio_button_unchecked_rounded, color: Colors.grey, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 6. Note / Memo Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_note_rounded, color: Color(0xFFEC4899), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'บันทึกช่วยจำ (ข้อความบนรายการ)',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteController,
                    style: TextStyle(color: textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'เช่น เงินเดือนประจำเดือน',
                      hintStyle: TextStyle(color: textSecondary.withOpacity(0.6)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEC4899), width: 1.8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 7. Status & Record History Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_rounded, color: Color(0xFF10B981), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'สถานะการบันทึก',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('บันทึกล่าสุด:', style: TextStyle(color: textSecondary, fontSize: 13)),
                      Text(
                        cfg.lastRecordedMonth != null
                            ? 'เดือน ${cfg.lastRecordedMonth}'
                            : 'ยังไม่มีประวัติ',
                        style: TextStyle(
                          color: cfg.lastRecordedMonth != null ? MeowTheme.incomeGreen : textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('วันที่บันทึกล่าสุด:', style: TextStyle(color: textSecondary, fontSize: 13)),
                      Text(
                        cfg.lastRecordedDate != null
                            ? FormatUtils.formatDateThai(cfg.lastRecordedDate!)
                            : '-',
                        style: TextStyle(color: textPrimary, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 8. Test Button & Save Button
            Row(
              children: [
                Expanded(
                  child: TactileButton(
                    onTap: _testRecordNow,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.play_arrow_rounded, color: Color(0xFF3B82F6), size: 22),
                          SizedBox(width: 6),
                          Text(
                            'ทดสอบบันทึกตอนนี้',
                            style: TextStyle(
                              color: Color(0xFF3B82F6),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TactileButton(
                    onTap: _saveConfig,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_rounded, color: Colors.white, size: 22),
                          SizedBox(width: 6),
                          Text(
                            'บันทึกการตั้งค่า',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
