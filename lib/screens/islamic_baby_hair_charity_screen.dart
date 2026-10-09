import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../models/transaction_item.dart';
import '../models/category_item.dart';
import '../services/currency_exchange_service.dart';
import '../theme/meow_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/meow_fx.dart';

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

  bool _showTranslation = false;

  // Islamic green: semantic colour for this page, lighter text variants in dark mode.
  static const Color _deepGreen = Color(0xFF14532D);
  static const Color _green = Color(0xFF15803D);
  static const Color _mint = Color(0xFFBBF7D0);
  static const Color _mintMuted = Color(0xFFCFEFD9);

  Color get _greenText => widget.controller.isDarkMode ? const Color(0xFF86EFAC) : _deepGreen;

  void _selectMetal(String metal) {
    HapticFeedback.selectionClick();
    setState(() => _metalType = metal);
    _updateMetalPrice();
    _recalculate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.controller.currentTheme;
    final isDark = widget.controller.isDarkMode;
    final isEn = widget.controller.isEnglish;
    final cardBg = theme.cardBackground;
    final textPrimary = theme.textColor;
    final textSecondary = theme.textSecondaryColor;
    final borderColor = theme.borderColor;
    final selectedBg = Color.alphaBlend(_green.withValues(alpha: isDark ? 0.22 : 0.1), cardBg);
    final softBg = Color.alphaBlend(_green.withValues(alpha: isDark ? 0.1 : 0.05), cardBg);
    final headerColor = isDark ? const Color(0xFF0F3D22) : _deepGreen;
    final metalName = _metalType == 'silver' ? 'โลหะเงิน' : 'ทองคำ';

    final card = BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(20),
      border: isDark ? Border.all(color: borderColor) : null,
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0E2A18).withValues(alpha: isDark ? 0.2 : 0.06),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );

    InputDecoration field({String? hint, String? prefix, Widget? suffix, bool active = false}) {
      OutlineInputBorder b(Color c) => OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c, width: 1.5),
          );
      return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7)),
        prefixText: prefix,
        prefixStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
        suffixIcon: suffix,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: cardBg,
        border: b(borderColor),
        enabledBorder: b(active ? _green : borderColor),
        focusedBorder: b(_green),
      );
    }

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(text, style: TextStyle(fontSize: 13, color: textSecondary)),
        );

    Widget choice({
      required String title,
      String? subtitle,
      required bool selected,
      required VoidCallback onTap,
      double minHeight = 48,
    }) {
      return Semantics(
        button: true,
        selected: selected,
        child: FxPress(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: BoxConstraints(minHeight: minHeight),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? selectedBg : cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? _green : borderColor, width: selected ? 2 : 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? _greenText : textSecondary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: selected ? (isDark ? _greenText : _green) : textSecondary),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      // The title bar stays put; the hadith panel below scrolls in the same
      // colour, and clamping physics stop a pull-down from revealing a gap.
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: headerColor,
            padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 10, 8, 4),
            child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
                      tooltip: 'ย้อนกลับ',
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        isEn ? 'Newborn Hair Charity' : 'ทานน้ำหนักผมทารก',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 12, left: 8),
                      child: Text(
                        'صدقة الشعر',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(color: _mint, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
            ),
          ),
          Expanded(
           child: ListView(
            padding: EdgeInsets.zero,
            physics: const ClampingScrollPhysics(),
            children: [
          // Hadith panel, continuing the header colour
          Container(
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '« يَا فَاطِمَةُ احْلِقِي رَأْسَهُ، وَتَصَدَّقِي بِزِنَةِ شَعْرِهِ فِضَّةً »',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(fontSize: 16, height: 1.7, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => setState(() => _showTranslation = !_showTranslation),
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 44),
                          child: Row(
                            children: [
                              AnimatedRotation(
                                turns: _showTranslation ? 0.25 : 0,
                                duration: const Duration(milliseconds: 180),
                                child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'อ่านคำแปล & ที่มา',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.topCenter,
                        child: !_showTranslation
                            ? const SizedBox(width: double.infinity)
                            : const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '"โอ้ฟาฏิมะฮ์ จงโกนผมของเขา และจงบริจาคทานด้วยโลหะเงินตามน้ำหนักผมของเขา"',
                                    style: TextStyle(fontSize: 12.5, height: 1.6, color: _mintMuted),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'สุนันอัตติรมิซีย์ เลขที่ 1519 (หะซัน)',
                                    style: TextStyle(fontSize: 12, color: Color(0xFFA7D9B8)),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'ซุนนะฮ์ให้โกนผมทารกในวันที่ 7 และชั่งน้ำหนักเส้นผมเพื่อบริจาคทานเทียบเท่าน้ำหนักโลหะเงิน',
                                    style: TextStyle(fontSize: 12, height: 1.5, color: _mintMuted),
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

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Baby details
                FxFadeUp(
                  index: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        label('ชื่อทารก (ไม่ระบุก็ได้)'),
                        TextField(
                          controller: _babyNameCtrl,
                          style: TextStyle(fontSize: 15, color: textPrimary),
                          decoration: field(hint: 'ชื่อทารก'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: choice(
                                title: 'ลูกชาย',
                                selected: _gender == 'boy',
                                onTap: () => setState(() => _gender = 'boy'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: choice(
                                title: 'ลูกสาว',
                                selected: _gender == 'girl',
                                onTap: () => setState(() => _gender = 'girl'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Material(
                          color: softBg,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _pickBirthDate,
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 44),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 18, color: isDark ? _greenText : _green),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(children: [
                                        TextSpan(text: 'วันเกิด ${FormatUtils.formatDateThai(_birthDate)} → '),
                                        TextSpan(
                                          text: 'วันที่ 7: ${FormatUtils.formatDateThai(_day7Date)}',
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                      ]),
                                      style: TextStyle(fontSize: 13, color: textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'อะกีเกาะฮ์: ลูกชาย แพะ 2 ตัว • ลูกสาว แพะ 1 ตัว',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Metal & weight
                FxFadeUp(
                  index: 1,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        label('ชนิดโลหะที่ใช้เทียบ'),
                        Row(
                          children: [
                            Expanded(
                              child: choice(
                                title: 'โลหะเงิน 99.9%',
                                subtitle: 'ซุนนะฮ์หลัก',
                                selected: _metalType == 'silver',
                                minHeight: 60,
                                onTap: () => _selectMetal('silver'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: choice(
                                title: 'ทองคำ 96.5%',
                                subtitle: 'ทัศนะทางเลือก',
                                selected: _metalType == 'gold',
                                minHeight: 60,
                                onTap: () => _selectMetal('gold'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  label('น้ำหนักผม (กรัม)'),
                                  TextField(
                                    controller: _weightCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
                                    onChanged: (_) => _recalculate(),
                                    decoration: field(hint: '0.0', active: true),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  label('ราคา${_metalType == 'silver' ? 'เงิน' : 'ทอง'}/กรัม'),
                                  TextField(
                                    controller: _pricePerGramCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
                                    onChanged: (_) => _recalculate(),
                                    decoration: field(
                                      prefix: '฿',
                                      suffix: IconButton(
                                        icon: Icon(Icons.refresh_rounded, size: 18, color: textSecondary),
                                        tooltip: 'ใช้ราคาล่าสุด',
                                        onPressed: () {
                                          _updateMetalPrice();
                                          _recalculate();
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['0.5', '0.8', '1.0', '1.2', '1.5', '2.0'].map((w) {
                            final isSelected = _weightCtrl.text.trim() == w;
                            return FxPress(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _weightCtrl.text = w;
                                _recalculate();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: isSelected ? _green : cardBg,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: isSelected ? _green : borderColor),
                                ),
                                child: Center(
                                  widthFactor: 1,
                                  child: Text(
                                    '$w ก.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      color: isSelected ? Colors.white : textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Result
                FxFadeUp(
                  index: 2,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: headerColor,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ยอดเงินบริจาคทานที่ต้องจ่าย (ศอดะเกาะฮ์)',
                          style: TextStyle(color: _mintMuted, fontSize: 12.5),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: FxProgress(
                            value: _calculatedCharity,
                            builder: (_, v) => Text(
                              '฿${FormatUtils.formatCurrency(v)}',
                              style: const TextStyle(color: _mint, fontSize: 34, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_weightCtrl.text.trim()} กรัม × ฿${_pricePerGramCtrl.text.trim()}/กรัม ($metalName)',
                          style: const TextStyle(color: _mintMuted, fontSize: 12.5),
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
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardBg,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Row(
              children: [
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ยอดบริจาค', style: TextStyle(fontSize: 12, color: textSecondary)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: FxProgress(
                          value: _calculatedCharity,
                          builder: (_, v) => Text(
                            '฿${FormatUtils.formatCurrency(v)}',
                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: _greenText),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FxPress(
                    onTap: _saveToExpenseLedger,
                    child: Container(
                      height: 56,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(18)),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'บันทึกเป็นรายจ่ายบริจาค',
                          style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
