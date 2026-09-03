import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../utils/format_utils.dart';
import '../services/currency_exchange_service.dart';

enum ZakatCategory {
  wealth, // เงินออม & ธุรกิจ
  gold, // ทองคำ
  agriculture, // ผลผลิตการเกษตร
  livestock, // ปศุสัตว์
}

enum IrrigationType {
  irrigated, // ชลประทาน/มีต้นทุนสูบน้ำ (5%)
  rainfed, // น้ำฝน/ธรรมชาติ (10%)
}

enum LivestockType {
  cattle, // วัว, ควาย (นิศอบ 30 ตัว)
  goat, // แพะ, แกะ (นิศอบ 40 ตัว)
  camel, // อูฐ (นิศอบ 5 ตัว)
}

class ZakatCalculatorScreen extends StatefulWidget {
  final ExpenseController controller;

  const ZakatCalculatorScreen({super.key, required this.controller});

  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> {
  ZakatCategory _selectedCategory = ZakatCategory.wealth;

  // Live Thai Gold API states
  bool _isLoadingGold = false;
  bool _isGoldBar = true; // true = ทองคำแท่ง, false = ทองรูปพรรณ
  double _liveGoldBarPrice = 70150.0;
  double _liveGoldOrnamentPrice = 70950.0;
  String _goldLastUpdatedText = '';

  // 1. Wealth & Savings Inputs
  final TextEditingController _cashInHandCtrl = TextEditingController();
  final TextEditingController _bankDepositsCtrl = TextEditingController();
  final TextEditingController _businessAssetsCtrl = TextEditingController();
  final TextEditingController _investmentsCtrl = TextEditingController();
  final TextEditingController _deductibleDebtsCtrl = TextEditingController();
  bool _hasPassedHaul = true;

  // 2. Gold Inputs
  bool _isGoldUnitBaht = true; // true = บาททอง, false = กรัม
  final TextEditingController _goldWeightCtrl = TextEditingController();
  final TextEditingController _goldPriceCtrl = TextEditingController(text: '70150');

  // 3. Agriculture Inputs
  final TextEditingController _cropWeightCtrl = TextEditingController();
  final TextEditingController _cropPricePerKgCtrl = TextEditingController();
  IrrigationType _irrigationType = IrrigationType.irrigated;

  // 4. Livestock Inputs
  LivestockType _livestockType = LivestockType.cattle;
  final TextEditingController _animalCountCtrl = TextEditingController(text: '30');

  @override
  void initState() {
    super.initState();
    _fetchLiveGoldPrice();
  }

  @override
  void dispose() {
    _cashInHandCtrl.dispose();
    _bankDepositsCtrl.dispose();
    _businessAssetsCtrl.dispose();
    _investmentsCtrl.dispose();
    _deductibleDebtsCtrl.dispose();
    _goldWeightCtrl.dispose();
    _goldPriceCtrl.dispose();
    _cropWeightCtrl.dispose();
    _cropPricePerKgCtrl.dispose();
    _animalCountCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveGoldPrice() async {
    if (_isLoadingGold) return;
    setState(() => _isLoadingGold = true);

    try {
      await CurrencyExchangeService.fetchThaiGoldPrices();
      final barPrice = CurrencyExchangeService.getGoldBarSellPrice();
      final ornamentPrice = CurrencyExchangeService.getGoldOrnamentSellPrice();
      final updateText = CurrencyExchangeService.getGoldLastUpdatedText();

      if (mounted) {
        setState(() {
          _liveGoldBarPrice = barPrice;
          _liveGoldOrnamentPrice = ornamentPrice;
          _goldLastUpdatedText = updateText;
          final activePrice = _isGoldBar ? _liveGoldBarPrice : _liveGoldOrnamentPrice;
          _goldPriceCtrl.text = _isGoldUnitBaht
              ? activePrice.toStringAsFixed(0)
              : (activePrice / 15.244).toStringAsFixed(0);
        });
      }
    } catch (_) {
      try {
        await CurrencyExchangeService.fetchLatestRates();
        final goldFromApi = CurrencyExchangeService.getGoldPricePerBahtWeight();
        if (goldFromApi > 0 && mounted) {
          setState(() {
            _liveGoldBarPrice = goldFromApi;
            _liveGoldOrnamentPrice = goldFromApi + 800;
            _goldPriceCtrl.text = _isGoldUnitBaht
                ? goldFromApi.toStringAsFixed(0)
                : (goldFromApi / 15.244).toStringAsFixed(0);
            _goldLastUpdatedText = CurrencyExchangeService.getGoldLastUpdatedText();
          });
        }
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _isLoadingGold = false);
    }
  }

  void _importAppBalance() {
    HapticFeedback.mediumImpact();
    final netWorth = widget.controller.totalNetWorth;
    setState(() {
      _bankDepositsCtrl.text = netWorth > 0 ? netWorth.toStringAsFixed(0) : '0';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ดึงยอดเงินในบัญชีจากแอพ ฿${FormatUtils.formatCurrency(netWorth)} เรียบร้อย!'),
        backgroundColor: MeowTheme.incomeGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  double _parse(TextEditingController ctrl) {
    final clean = ctrl.text.replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  // --- 1. Wealth & Savings Calculations ---
  double get _cashInHand => _parse(_cashInHandCtrl);
  double get _bankDeposits => _parse(_bankDepositsCtrl);
  double get _totalLiquidSavings => _cashInHand + _bankDeposits;

  double get _netWealthGross =>
      _totalLiquidSavings + _parse(_businessAssetsCtrl) + _parse(_investmentsCtrl);
  double get _netWealthTotal =>
      (_netWealthGross - _parse(_deductibleDebtsCtrl)).clamp(0.0, double.infinity);

  double get _wealthNisabThreshold {
    final goldBarPrice = _isGoldUnitBaht
        ? _parse(_goldPriceCtrl)
        : (_parse(_goldPriceCtrl) * 15.244);
    final price = goldBarPrice > 0 ? goldBarPrice : _liveGoldBarPrice;
    return (85.0 / 15.244) * price;
  }

  bool get _isWealthNisabReached => _netWealthTotal >= _wealthNisabThreshold && _wealthNisabThreshold > 0;
  double get _wealthZakatAmount =>
      (_isWealthNisabReached && _hasPassedHaul) ? _netWealthTotal * 0.025 : 0.0;

  // --- 2. Gold Calculations ---
  double get _goldWeightInGrams {
    final w = _parse(_goldWeightCtrl);
    return _isGoldUnitBaht ? w * 15.244 : w;
  }

  double get _goldTotalValue {
    final w = _parse(_goldWeightCtrl);
    final price = _parse(_goldPriceCtrl);
    return w * price;
  }

  bool get _isGoldNisabReached => _goldWeightInGrams >= 85.0;
  double get _goldZakatAmount => _isGoldNisabReached ? _goldTotalValue * 0.025 : 0.0;

  // --- 3. Agriculture Calculations ---
  double get _cropWeight => _parse(_cropWeightCtrl);
  double get _cropPricePerKg => _parse(_cropPricePerKgCtrl);
  bool get _isCropNisabReached => _cropWeight >= 653.0;

  double get _cropZakatRate => _irrigationType == IrrigationType.rainfed ? 0.10 : 0.05;
  double get _cropZakatKg => _isCropNisabReached ? _cropWeight * _cropZakatRate : 0.0;
  double get _cropZakatBaht => _cropZakatKg * _cropPricePerKg;

  // --- 4. Livestock Calculations ---
  String _calculateLivestockZakat() {
    final count = _parse(_animalCountCtrl).toInt();
    if (count <= 0) return 'ระบุจำนวนสัตว์เลี้ยง';

    switch (_livestockType) {
      case LivestockType.cattle:
        if (count < 30) return 'ยังไม่ถึงเกณฑ์นิศอบ (ขั้นต่ำ 30 ตัว)';
        if (count < 40) return 'วัวอายุ 1 ปี (ตะบีอ์) 1 ตัว';
        if (count < 60) return 'วัวอายุ 2 ปี (มุสินนะฮ์) 1 ตัว';
        if (count < 70) return 'วัวอายุ 1 ปี 2 ตัว';
        if (count < 80) return 'วัวอายุ 1 ปี 1 ตัว และอายุ 2 ปี 1 ตัว';
        final tabee = count ~/ 30;
        return 'วัวอายุ 1 ปี $tabee ตัว หรือตามสัดส่วนฝูง';

      case LivestockType.goat:
        if (count < 40) return 'ยังไม่ถึงเกณฑ์นิศอบ (ขั้นต่ำ 40 ตัว)';
        if (count <= 120) return 'แพะหรือแกะ 1 ตัว';
        if (count <= 200) return 'แพะหรือแกะ 2 ตัว';
        if (count <= 399) return 'แพะหรือแกะ 3 ตัว';
        final n = count ~/ 100;
        return 'แพะหรือแกะ $n ตัว (1 ตัวต่อ 100 ตัว)';

      case LivestockType.camel:
        if (count < 5) return 'ยังไม่ถึงเกณฑ์นิศอบ (ขั้นต่ำ 5 ตัว)';
        if (count <= 9) return 'แกะหรือแพะ 1 ตัว';
        if (count <= 14) return 'แกะหรือแพะ 2 ตัว';
        if (count <= 19) return 'แกะหรือแพะ 3 ตัว';
        if (count <= 24) return 'แกะหรือแพะ 4 ตัว';
        if (count <= 35) return 'ลูกอูฐเพศเมียอายุ 1 ปี 1 ตัว';
        return 'ลูกอูฐตามพิกัดเกณฑ์ศาสนา';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = widget.controller.currentTheme;
    final isDark = widget.controller.isDarkMode;

    return Scaffold(
      backgroundColor: currentTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: currentTheme.textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'คำนวณซากาต (Zakat Calculator)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: currentTheme.textColor),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Gold Banner Card
            _buildLiveGoldPriceBar(currentTheme, isDark),
            const SizedBox(height: 12),

            // Category Selection Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryTab(ZakatCategory.wealth, 'เงินออม & ธุรกิจ', Icons.savings_rounded, currentTheme),
                  _buildCategoryTab(ZakatCategory.gold, 'ทองคำ (Gold)', Icons.monetization_on_rounded, currentTheme),
                  _buildCategoryTab(ZakatCategory.agriculture, 'ผลผลิตเกษตร', Icons.grass_rounded, currentTheme),
                  _buildCategoryTab(ZakatCategory.livestock, 'ปศุสัตว์', Icons.pets_rounded, currentTheme),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Active Category Card
            if (_selectedCategory == ZakatCategory.wealth)
              _buildWealthCard(currentTheme, isDark)
            else if (_selectedCategory == ZakatCategory.gold)
              _buildGoldCard(currentTheme, isDark)
            else if (_selectedCategory == ZakatCategory.agriculture)
              _buildAgricultureCard(currentTheme, isDark)
            else if (_selectedCategory == ZakatCategory.livestock)
              _buildLivestockCard(currentTheme, isDark),

            const SizedBox(height: 14),

            // Result Summary Card
            _buildResultSummaryCard(currentTheme, isDark),

            const SizedBox(height: 14),

            // Reference Footnote Card
            _buildReferenceCard(currentTheme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveGoldPriceBar(dynamic currentTheme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.show_chart_rounded, color: Color(0xFFB45309), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🥇 ทองแท่ง: ', style: TextStyle(fontSize: 11.5, color: Color(0xFFB45309))),
                        Text(
                          '฿${FormatUtils.formatCurrency(_liveGoldBarPrice)}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📿 รูปพรรณ: ', style: TextStyle(fontSize: 11.5, color: Color(0xFFD97706))),
                        Text(
                          '฿${FormatUtils.formatCurrency(_liveGoldOrnamentPrice)}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _goldLastUpdatedText.isNotEmpty
                      ? _goldLastUpdatedText
                      : 'สมาคมค้าทองคำแห่งประเทศไทย (เรียลไทม์)',
                  style: TextStyle(fontSize: 10.5, color: currentTheme.textSecondaryColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _fetchLiveGoldPrice,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: currentTheme.surfaceBackground,
                shape: BoxShape.circle,
                border: Border.all(color: currentTheme.borderColor),
              ),
              child: _isLoadingGold
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.refresh_rounded, size: 16, color: currentTheme.textColor),
            ),
          ),
        ],
      ),
    );
  }

  // --- Category Tabs ---
  Widget _buildCategoryTab(ZakatCategory cat, String label, IconData icon, dynamic currentTheme) {
    final isSel = _selectedCategory == cat;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedCategory = cat);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSel ? currentTheme.primaryColor : currentTheme.surfaceBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSel ? currentTheme.primaryColor : currentTheme.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSel
                  ? Colors.white
                  : currentTheme.textSecondaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                color: isSel
                  ? Colors.white
                  : currentTheme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. Wealth Card ---
  Widget _buildWealthCard(dynamic currentTheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: currentTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: currentTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'ซากาตเงินออม & ธุรกิจ',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                ),
              ),
              GestureDetector(
                onTap: _importAppBalance,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: currentTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download_rounded, size: 14, color: currentTheme.primaryColor),
                      const SizedBox(width: 4),
                      Text('ดึงยอดในแอพ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: currentTheme.primaryColor)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildSimpleInput(
                  controller: _cashInHandCtrl,
                  label: '💵 เงินสดในมือ (บาท)',
                  hint: '0.00',
                  currentTheme: currentTheme,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSimpleInput(
                  controller: _bankDepositsCtrl,
                  label: '🏦 เงินในบัญชี (บาท)',
                  hint: '0.00',
                  currentTheme: currentTheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildSimpleInput(
                  controller: _businessAssetsCtrl,
                  label: '📦 สินค้าเพื่อการค้า (บาท)',
                  hint: '0.00',
                  currentTheme: currentTheme,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSimpleInput(
                  controller: _investmentsCtrl,
                  label: '📈 หุ้น/เงินลงทุน (บาท)',
                  hint: '0.00',
                  currentTheme: currentTheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          _buildSimpleInput(
            controller: _deductibleDebtsCtrl,
            label: '💳 หักหนี้สินระยะสั้นที่ถึงกำหนดชำระ (บาท)',
            hint: '0.00',
            currentTheme: currentTheme,
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Checkbox(
                value: _hasPassedHaul,
                activeColor: currentTheme.primaryColor,
                onChanged: (v) => setState(() => _hasPassedHaul = v ?? true),
              ),
              Expanded(
                child: Text('ทรัพย์สินครอบครองครบรอบ 1 ปีจันทรคติ (ฮอล)', style: TextStyle(fontSize: 12, color: currentTheme.textColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 2. Gold Card ---
  Widget _buildGoldCard(dynamic currentTheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: currentTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: currentTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'ซากาตทองคำ (Zakat on Gold)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChoiceChip(
                    label: const Text('บาททอง', style: TextStyle(fontSize: 10.5)),
                    selected: _isGoldUnitBaht,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    visualDensity: VisualDensity.compact,
                    onSelected: (v) {
                      setState(() {
                        _isGoldUnitBaht = true;
                        final p = _isGoldBar ? _liveGoldBarPrice : _liveGoldOrnamentPrice;
                        _goldPriceCtrl.text = p.toStringAsFixed(0);
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  ChoiceChip(
                    label: const Text('กรัม', style: TextStyle(fontSize: 10.5)),
                    selected: !_isGoldUnitBaht,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    visualDensity: VisualDensity.compact,
                    onSelected: (v) {
                      setState(() {
                        _isGoldUnitBaht = false;
                        final p = (_isGoldBar ? _liveGoldBarPrice : _liveGoldOrnamentPrice) / 15.244;
                        _goldPriceCtrl.text = p.toStringAsFixed(0);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Selector: ทองคำแท่ง 96.5% vs ทองรูปพรรณ 96.5%
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: currentTheme.surfaceBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: currentTheme.borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isGoldBar = true;
                        _goldPriceCtrl.text = _isGoldUnitBaht
                            ? _liveGoldBarPrice.toStringAsFixed(0)
                            : (_liveGoldBarPrice / 15.244).toStringAsFixed(0);
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isGoldBar ? currentTheme.primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '🥇 ทองคำแท่ง (฿${FormatUtils.formatCurrency(_liveGoldBarPrice)})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _isGoldBar
                                  ? Colors.white
                                  : currentTheme.textSecondaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isGoldBar = false;
                        _goldPriceCtrl.text = _isGoldUnitBaht
                            ? _liveGoldOrnamentPrice.toStringAsFixed(0)
                            : (_liveGoldOrnamentPrice / 15.244).toStringAsFixed(0);
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isGoldBar ? currentTheme.primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '📿 ทองรูปพรรณ (฿${FormatUtils.formatCurrency(_liveGoldOrnamentPrice)})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: !_isGoldBar
                                  ? Colors.white
                                  : currentTheme.textSecondaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _buildSimpleInput(
            controller: _goldWeightCtrl,
            label: _isGoldUnitBaht ? 'น้ำหนักทองคำรวม (บาททอง)' : 'น้ำหนักทองคำรวม (กรัม)',
            hint: _isGoldUnitBaht ? 'เช่น 5.6' : 'เช่น 85',
            currentTheme: currentTheme,
          ),
          const SizedBox(height: 10),

          _buildSimpleInput(
            controller: _goldPriceCtrl,
            label: _isGoldUnitBaht
                ? (_isGoldBar ? 'ราคาทองคำแท่งต่อบาท (บาท)' : 'ราคาทองรูปพรรณต่อบาท (บาท)')
                : (_isGoldBar ? 'ราคาทองคำแท่งต่อกรัม (บาท)' : 'ราคาทองรูปพรรณต่อกรัม (บาท)'),
            hint: '70150',
            currentTheme: currentTheme,
          ),
        ],
      ),
    );
  }

  // --- 3. Agriculture Card ---
  Widget _buildAgricultureCard(dynamic currentTheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: currentTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: currentTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ซากาตผลผลิตการเกษตร (Zakat on Crops)',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: currentTheme.textColor),
          ),
          const SizedBox(height: 3),
          Text(
            'นิศอบ 5 วะสัก (ประมาณ 653 กิโลกรัม) จ่ายเมื่อเก็บเกี่ยว',
            style: TextStyle(fontSize: 11.5, color: currentTheme.textSecondaryColor),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildSimpleInput(
                  controller: _cropWeightCtrl,
                  label: 'น้ำหนักผลผลิต (กก.)',
                  hint: 'เช่น 1000',
                  currentTheme: currentTheme,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSimpleInput(
                  controller: _cropPricePerKgCtrl,
                  label: 'ราคาเฉลี่ยต่อ กก. (บาท)',
                  hint: 'เช่น 20',
                  currentTheme: currentTheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            'รูปแบบการให้น้ำ / ชลประทาน:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentTheme.textSecondaryColor),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: const Text('ชลประทาน/มีต้นทุน (5%)', style: TextStyle(fontSize: 11.5)),
                selected: _irrigationType == IrrigationType.irrigated,
                onSelected: (v) => setState(() => _irrigationType = IrrigationType.irrigated),
              ),
              ChoiceChip(
                label: const Text('น้ำฝนธรรมชาติ (10%)', style: TextStyle(fontSize: 11.5)),
                selected: _irrigationType == IrrigationType.rainfed,
                onSelected: (v) => setState(() => _irrigationType = IrrigationType.rainfed),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 4. Livestock Card ---
  Widget _buildLivestockCard(dynamic currentTheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: currentTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: currentTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ซากาตปศุสัตว์ (Zakat on Livestock)',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: currentTheme.textColor),
          ),
          const SizedBox(height: 3),
          Text(
            'เลี้ยงปล่อยกินหญ้าตามธรรมชาติ ครบรอบ 1 ปี (ฮอล)',
            style: TextStyle(fontSize: 11.5, color: currentTheme.textSecondaryColor),
          ),
          const SizedBox(height: 12),

          Text('ชนิดของสัตว์เลี้ยง:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentTheme.textSecondaryColor)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: const Text('วัว / ควาย (ขั้นต่ำ 30)', style: TextStyle(fontSize: 11.5)),
                selected: _livestockType == LivestockType.cattle,
                onSelected: (v) => setState(() => _livestockType = LivestockType.cattle),
              ),
              ChoiceChip(
                label: const Text('แพะ / แกะ (ขั้นต่ำ 40)', style: TextStyle(fontSize: 11.5)),
                selected: _livestockType == LivestockType.goat,
                onSelected: (v) => setState(() => _livestockType = LivestockType.goat),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildSimpleInput(
            controller: _animalCountCtrl,
            label: 'จำนวนสัตว์เลี้ยงทั้งหมด (ตัว)',
            hint: '30',
            currentTheme: currentTheme,
          ),
        ],
      ),
    );
  }

  // --- Result Summary Card ---
  Widget _buildResultSummaryCard(dynamic currentTheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: currentTheme.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: currentTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_rounded, color: currentTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'สรุปผลการคำนวณซากาต',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: currentTheme.textColor),
              ),
            ],
          ),
          const Divider(height: 20),

          if (_selectedCategory == ZakatCategory.wealth) ...[
            if (_cashInHand > 0)
              _buildResultRow('• เงินสดในมือ:', '฿${FormatUtils.formatCurrency(_cashInHand)}', currentTheme),
            if (_bankDeposits > 0)
              _buildResultRow('• เงินในบัญชีธนาคาร:', '฿${FormatUtils.formatCurrency(_bankDeposits)}', currentTheme),
            _buildResultRow('รวมเงินออมสุทธิ:', '฿${FormatUtils.formatCurrency(_netWealthTotal)}', currentTheme),
            _buildResultRow('เกณฑ์นิศอบ (ทอง 85g):', '฿${FormatUtils.formatCurrency(_wealthNisabThreshold)}', currentTheme),
            _buildResultRow(
              'สถานะนิศอบ & ฮอล:',
              (_isWealthNisabReached && _hasPassedHaul) ? 'วาญิบออกซากาต (ถึงเกณฑ์)' : 'ยังไม่ถึงเกณฑ์',
              currentTheme,
              isHighlight: _isWealthNisabReached && _hasPassedHaul,
            ),
            const Divider(height: 16),
            _buildHighlightTotalRow('ยอดซากาตที่ต้องจ่าย (2.5%)', _wealthZakatAmount, currentTheme),
          ] else if (_selectedCategory == ZakatCategory.gold) ...[
            _buildResultRow('น้ำหนักทองคำรวม:', '${_goldWeightInGrams.toStringAsFixed(1)} กรัม', currentTheme),
            _buildResultRow('เกณฑ์นิศอบ (85 กรัม):', _isGoldNisabReached ? 'ถึงเกณฑ์ (วาญิบออกซากาต)' : 'ยังไม่ถึงเกณฑ์', currentTheme, isHighlight: _isGoldNisabReached),
            _buildResultRow('มูลค่าทองคำรวม:', '฿${FormatUtils.formatCurrency(_goldTotalValue)}', currentTheme),
            const Divider(height: 16),
            _buildHighlightTotalRow('ยอดซากาตทองคำที่ต้องจ่าย (2.5%)', _goldZakatAmount, currentTheme),
          ] else if (_selectedCategory == ZakatCategory.agriculture) ...[
            _buildResultRow('น้ำหนักผลผลิต:', '${FormatUtils.formatCurrency(_cropWeight)} กก.', currentTheme),
            _buildResultRow('เกณฑ์นิศอบ (653 กก.):', _isCropNisabReached ? 'ถึงเกณฑ์ (วาญิบออกซากาต)' : 'ยังไม่ถึงเกณฑ์', currentTheme, isHighlight: _isCropNisabReached),
            _buildResultRow('ผลผลิตที่ต้องจ่าย (${(_cropZakatRate * 100).toInt()}%):', '${FormatUtils.formatCurrency(_cropZakatKg)} กก.', currentTheme),
            if (_cropPricePerKg > 0) ...[
              const Divider(height: 16),
              _buildHighlightTotalRow('หรือคิดเป็นเงินประมาณ', _cropZakatBaht, currentTheme),
            ],
          ] else if (_selectedCategory == ZakatCategory.livestock) ...[
            _buildResultRow('ประเภทสัตว์เลี้ยง:', _livestockType == LivestockType.cattle ? 'วัว/ควาย' : (_livestockType == LivestockType.goat ? 'แพะ/แกะ' : 'อูฐ'), currentTheme),
            _buildResultRow('จำนวนในครอบครอง:', '${_parse(_animalCountCtrl).toInt()} ตัว', currentTheme),
            const Divider(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text('ซากาตที่ต้องจ่าย:', style: TextStyle(fontSize: 13, color: currentTheme.textSecondaryColor)),
                ),
                Flexible(
                  child: Text(
                    _calculateLivestockZakat(),
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: currentTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- Reference Card ---
  Widget _buildReferenceCard(dynamic currentTheme, bool isDark) {
    String referenceText = '';
    switch (_selectedCategory) {
      case ZakatCategory.wealth:
        referenceText =
            '• อ้างอิงเกณฑ์เทียบเคียงนิศอบทองคำ 85 กรัม เมื่อมีเงินสดในมือ บัญชีเงินฝาก สินค้าคงคลัง และเงินลงทุนรวมกันหลังหักหนี้สินถึงเกณฑ์และครบรอบ 1 ปีจันทรคติ (ฮอล) ต้องจ่าย 2.5%\n'
            '• ดำริตามมติสภาอุลามะอ์และสำนักจุฬาราชมนตรี';
        break;
      case ZakatCategory.gold:
        referenceText =
            '• อ้างอิงเกณฑ์นิศอบทองคำ 20 ดีนาร (ประมาณ 85 กรัม หรือราว 5.575 บาททอง) อัตราซากาต 2.5% (1/40) ตามมติสภาฟิกฮ์อิสลามและสำนักจุฬาราชมนตรี\n'
            '• ราคาทองคำดึงสดจากสมาคมค้าทองคำแห่งประเทศไทย';
        break;
      case ZakatCategory.agriculture:
        referenceText =
            '• อ้างอิงฮะดีษซอฮีฮฺ: "ในสิ่งที่รดด้วยน้ำฝน น้ำตา และน้ำซับ จ่ายหนึ่งในสิบ (10%) และในสิ่งที่รดด้วยการทดน้ำ จ่ายครึ่งหนึ่งของหนึ่งในสิบ (5%)" [บันทึกโดยอัลบุคอรีย์]\n'
            '• นิศอบ 5 วะสัก = ประมาณ 653 กิโลกรัม';
        break;
      case ZakatCategory.livestock:
        referenceText =
            '• อ้างอิงเกณฑ์การจ่ายซากาตปศุสัตว์ตามจดหมายของท่านอบูบักร อัศศิดดีก (ร.ฎ.) ที่บันทึกไว้ในศอฮีฮฺอัลบุคอรีย์\n'
            '• สำหรับสัตว์ที่เลี้ยงแบบปล่อยตามทุ่งหญ้าธรรมชาติเพื่อการขยายพันธุ์หรือเอาน้ำนม ครบรอบ 1 ปี (ฮอล)';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: currentTheme.surfaceBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: currentTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, size: 16, color: currentTheme.primaryColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'แหล่งอ้างอิงหลักการศาสนา (Islamic Reference):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            referenceText,
            style: TextStyle(fontSize: 11.5, height: 1.45, color: currentTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, dynamic currentTheme, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 12.5, color: currentTheme.textSecondaryColor)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isHighlight ? const Color(0xFF10B981) : currentTheme.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightTotalRow(String label, double amount, dynamic currentTheme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: currentTheme.textColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '฿${FormatUtils.formatCurrency(amount)}',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: amount > 0 ? currentTheme.primaryColor : currentTheme.textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required dynamic currentTheme,
    Widget? prefix,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: currentTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: currentTheme.textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: currentTheme.textSecondaryColor.withValues(alpha: 0.5)),
            prefixIcon: prefix,
            suffixIcon: suffix,
            filled: true,
            fillColor: currentTheme.surfaceBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: currentTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: currentTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: currentTheme.primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
