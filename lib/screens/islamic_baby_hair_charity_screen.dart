import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../models/transaction_item.dart';
import '../models/category_item.dart';
import '../services/currency_exchange_service.dart';
import '../theme/meow_theme.dart';
import '../utils/format_utils.dart';

class IslamicBabyHairCharityScreen extends StatefulWidget {
  final ExpenseController controller;

  const IslamicBabyHairCharityScreen({super.key, required this.controller});

  @override
  State<IslamicBabyHairCharityScreen> createState() => _IslamicBabyHairCharityScreenState();
}

class _IslamicBabyHairCharityScreenState extends State<IslamicBabyHairCharityScreen> {
  final TextEditingController _weightCtrl = TextEditingController(text: '1.2');
  final TextEditingController _pricePerGramCtrl = TextEditingController();
  final TextEditingController _babyNameCtrl = TextEditingController();

  String _gender = 'boy'; // 'boy' or 'girl'
  DateTime _birthDate = DateTime.now().subtract(const Duration(days: 6)); // default to day 7 today
  String _metalType = 'silver'; // 'silver' (Sunnah) or 'gold'
  double _calculatedCharity = 0.0;

  @override
  void initState() {
    super.initState();
    _updateMetalPrice();
    _recalculate();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _pricePerGramCtrl.dispose();
    _babyNameCtrl.dispose();
    super.dispose();
  }

  void _updateMetalPrice() {
    if (_metalType == 'silver') {
      final silverPricePerGram = CurrencyExchangeService.getSilverPricePerGram();
      _pricePerGramCtrl.text = silverPricePerGram.toStringAsFixed(2);
    } else {
      final goldBarPrice = CurrencyExchangeService.getGoldBarSellPrice();
      final goldPerGram = goldBarPrice / 15.244;
      _pricePerGramCtrl.text = goldPerGram.toStringAsFixed(2);
    }
  }

  void _recalculate() {
    final weight = double.tryParse(_weightCtrl.text.trim()) ?? 0.0;
    final pricePerGram = double.tryParse(_pricePerGramCtrl.text.trim()) ?? 0.0;
    setState(() {
      _calculatedCharity = weight * pricePerGram;
    });
  }

  DateTime get _day7Date => _birthDate.add(const Duration(days: 6));

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: widget.controller.isDarkMode ? ThemeData.dark() : ThemeData.light(),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  void _saveToExpenseLedger() {
    HapticFeedback.mediumImpact();
    if (_calculatedCharity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาระบุน้ำหนักผมและราคาที่ถูกต้อง'),
          backgroundColor: MeowTheme.expenseRed,
        ),
      );
      return;
    }

    final cat = widget.controller.ensureCategoryExists('บริจาค & ทำบุญ (เศาะดะเกาะฮ์)', CategoryType.expense);
    final babyName = _babyNameCtrl.text.trim();
    final metalName = _metalType == 'silver' ? 'โลหะเงิน' : 'ทองคำ';
    final weight = _weightCtrl.text.trim();

    final title = babyName.isNotEmpty
        ? 'ซอดะเกาะฮ์โกนผมไฟ ($babyName)'
        : 'ซอดะเกาะฮ์น้ำหนักผมลูกแรกเกิด ($metalName)';

    final note = 'ซอดะเกาะฮ์เทียบเท่าน้ำหนักผมทารกแรกเกิด: $weight กรัม ($metalName) ตามแบบฉบับซุนนะฮ์ท่านนบี ﷺ';

    // Find default allowed account
    final targetAcc = widget.controller.accounts.firstWhere(
      (a) => a.isDefault && a.allowAutoDeduction,
      orElse: () => widget.controller.accounts.firstWhere(
        (a) => a.allowAutoDeduction,
        orElse: () => widget.controller.accounts.first,
      ),
    );

    final item = TransactionItem(
      id: 'tx_baby_hair_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      amount: _calculatedCharity,
      type: TransactionType.expense,
      date: DateTime.now(),
      accountId: targetAcc.id,
      categoryId: cat.id,
      categoryName: cat.name,
      note: note,
    );

    widget.controller.addTransaction(item);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('✨ บันทึก "$title" ฿${FormatUtils.formatCurrency(_calculatedCharity)} เข้าบัญชีเรียบร้อยแล้ว')),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = widget.controller.currentTheme;
    final isDark = widget.controller.isDarkMode;
    final isEn = widget.controller.isEnglish;

    return Scaffold(
      backgroundColor: currentTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: currentTheme.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: currentTheme.textColor, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEn ? 'Newborn Hair Charity (Sunnah)' : 'ทานน้ำหนักผมทารกแรกเกิด',
          style: TextStyle(
            color: currentTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 32),
        physics: const BouncingScrollPhysics(),
        children: [
          // 1. Hero Info Card (Compact & Minimal)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0F2E28), const Color(0xFF0F172A)]
                    : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('👶', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ซุนนะฮ์โกนผมไฟ (ตะฮ์ลีกุรร็ออ์ส)',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF047857),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ซุนนะฮ์ให้โกนผมทารกในวันที่ 7 และชั่งน้ำหนักเส้นผมเพื่อบริจาคทานเทียบเท่าน้ำหนักโลหะเงิน',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF065F46),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2. Baby Details & Day 7 Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: currentTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: currentTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baby Name Field
                TextField(
                  controller: _babyNameCtrl,
                  style: TextStyle(fontSize: 13, color: currentTheme.textColor),
                  decoration: InputDecoration(
                    labelText: 'ชื่อทารก (ไม่ระบุก็ได้)',
                    labelStyle: TextStyle(fontSize: 11.5, color: currentTheme.textSecondaryColor),
                    prefixIcon: const Icon(Icons.badge_outlined, size: 16),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),

                // Gender Selector Row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _gender = 'boy'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _gender == 'boy'
                                ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _gender == 'boy' ? const Color(0xFF0284C7) : currentTheme.borderColor,
                              width: _gender == 'boy' ? 1.5 : 1.0,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('👦', style: TextStyle(fontSize: 15)),
                              SizedBox(width: 4),
                              Text('ลูกชาย (แพะ 2 ตัว)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _gender = 'girl'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _gender == 'girl'
                                ? const Color(0xFFEC4899).withValues(alpha: 0.15)
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _gender == 'girl' ? const Color(0xFFEC4899) : currentTheme.borderColor,
                              width: _gender == 'girl' ? 1.5 : 1.0,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('👧', style: TextStyle(fontSize: 15)),
                              SizedBox(width: 4),
                              Text('ลูกสาว (แพะ 1 ตัว)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Birth Date & Day 7 Selector
                GestureDetector(
                  onTap: _pickBirthDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: currentTheme.borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF10B981)),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('วันเกิด', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                Text(
                                  FormatUtils.formatDateThai(_birthDate),
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'วันที่ 7: ${FormatUtils.formatDateThai(_day7Date)}',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3. Weight & Metal Standard Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: currentTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: currentTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hair Weight Input
                TextField(
                  controller: _weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                  onChanged: (_) => _recalculate(),
                  decoration: InputDecoration(
                    labelText: 'น้ำหนักเส้นผมที่โกนได้ (กรัม)',
                    labelStyle: TextStyle(fontSize: 11.5, color: currentTheme.textSecondaryColor),
                    suffixText: 'กรัม (g)',
                    prefixIcon: const Icon(Icons.scale_rounded, size: 18, color: Color(0xFF0284C7)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 6),

                // Quick Weight Chips
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: ['0.5', '0.8', '1.0', '1.2', '1.5', '2.0'].map((w) {
                    final isSelected = _weightCtrl.text.trim() == w;
                    return InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _weightCtrl.text = w;
                        _recalculate();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0284C7)
                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$w g',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : currentTheme.textColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),

                // Metal Choice Selector (Silver vs Gold)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _metalType = 'silver');
                          _updateMetalPrice();
                          _recalculate();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _metalType == 'silver'
                                ? const Color(0xFF64748B).withValues(alpha: 0.15)
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _metalType == 'silver' ? const Color(0xFF64748B) : currentTheme.borderColor,
                              width: _metalType == 'silver' ? 1.5 : 1.0,
                            ),
                          ),
                          child: const Column(
                            children: [
                              Text('🥈 โลหะเงิน 99.9%', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                              SizedBox(height: 1),
                              Text('(ซุนนะฮ์หลัก ﷺ)', style: TextStyle(fontSize: 9.5, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _metalType = 'gold');
                          _updateMetalPrice();
                          _recalculate();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _metalType == 'gold'
                                ? const Color(0xFFD97706).withValues(alpha: 0.15)
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _metalType == 'gold' ? const Color(0xFFD97706) : currentTheme.borderColor,
                              width: _metalType == 'gold' ? 1.5 : 1.0,
                            ),
                          ),
                          child: const Column(
                            children: [
                              Text('🥇 ทองคำ 96.5%', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                              SizedBox(height: 1),
                              Text('(ทัศนะทางเลือก)', style: TextStyle(fontSize: 9.5, color: Color(0xFFD97706))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Metal Price Field
                TextField(
                  controller: _pricePerGramCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: 13, color: currentTheme.textColor),
                  onChanged: (_) => _recalculate(),
                  decoration: InputDecoration(
                    labelText: 'ราคา ${_metalType == 'silver' ? 'โลหะเงิน' : 'ทองคำ'} ต่อกรัม',
                    labelStyle: TextStyle(fontSize: 11, color: currentTheme.textSecondaryColor),
                    prefixText: '฿ ',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      onPressed: () {
                        _updateMetalPrice();
                        _recalculate();
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4. Result Card (Compact & Glowing)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF047857), Color(0xFF065F46)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF047857).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'ยอดเงินบริจาคทานที่ต้องจ่าย (ศอดะเกาะฮ์)',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '฿${FormatUtils.formatCurrency(_calculatedCharity)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_weightCtrl.text.trim()} กรัม × ฿${_pricePerGramCtrl.text.trim()}/g (${_metalType == 'silver' ? 'โลหะเงิน' : 'ทองคำ'})',
                  style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 5. Action Button: Record to Expense Ledger
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            icon: const Icon(Icons.bookmark_add_rounded, size: 18),
            label: const Text(
              'บันทึกเป็นรายจ่ายบริจาคทานทันที',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            onPressed: _saveToExpenseLedger,
          ),
          const SizedBox(height: 12),

          // 6. Islamic Knowledge & References (Compact)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: currentTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: currentTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.menu_book_rounded, size: 15, color: Color(0xFF10B981)),
                    SizedBox(width: 6),
                    Text('หลักฐาน & ซุนนะฮ์ตามแบบฉบับอิสลาม', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '« يَا فَاطِمَةُ احْلِقِي رَأْسَهُ، وَتَصَدَّقِي بِزِنَةِ شَعْرِهِ فِضَّةً »\n"โอ้ฟาฏิมะฮ์ จงโกนผมของเขา และจงบริจาคทานด้วยโลหะเงินตามน้ำหนักผมของเขา"',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857), height: 1.3),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '📚 อ้างอิง: สุนันอัตติรมิซีย์ (เลขที่ 1519, เกรดหะซัน)',
                  style: TextStyle(fontSize: 10, color: currentTheme.textSecondaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
