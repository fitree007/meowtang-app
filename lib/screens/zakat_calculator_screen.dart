import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/currency_exchange_service.dart';
import '../services/zakat_engine.dart';
import '../state/expense_controller.dart';
import '../theme/app_theme_model.dart';
import '../theme/meow_theme.dart';
import '../utils/format_utils.dart';

enum ZakatCategory { wealth, gold, agriculture, livestock }

enum IrrigationType { irrigated, rainfed }

class ZakatCalculatorScreen extends StatefulWidget {
  final ExpenseController controller;

  const ZakatCalculatorScreen({super.key, required this.controller});

  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> {
  ZakatCategory _category = ZakatCategory.wealth;

  // Live prices
  bool _loadingPrices = false;
  double _goldBarPrice = 70150.0; // per baht-weight
  double _goldOrnamentPrice = 70950.0;
  double _silverPerGram = 38.5;
  String _goldUpdated = '';

  // Wealth
  final _cashCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _tradeCtrl = TextEditingController();
  final _investCtrl = TextEditingController();
  final _receivableCtrl = TextEditingController();
  final _debtCtrl = TextEditingController();
  bool _hawlPassed = true;
  bool _silverNisab = false;

  // Gold
  bool _goldUnitBaht = true;
  bool _goldBar = true;
  final _goldWeightCtrl = TextEditingController();

  // Agriculture
  final _cropKgCtrl = TextEditingController();
  final _cropPriceCtrl = TextEditingController();
  IrrigationType _irrigation = IrrigationType.rainfed;

  // Livestock
  LivestockKind _livestock = LivestockKind.goat;
  final _animalCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPrices();
  }

  @override
  void dispose() {
    for (final c in [
      _cashCtrl,
      _bankCtrl,
      _tradeCtrl,
      _investCtrl,
      _receivableCtrl,
      _debtCtrl,
      _goldWeightCtrl,
      _cropKgCtrl,
      _cropPriceCtrl,
      _animalCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchPrices() async {
    if (_loadingPrices) return;
    setState(() => _loadingPrices = true);
    try {
      await CurrencyExchangeService.fetchThaiGoldPrices();
      _goldBarPrice = CurrencyExchangeService.getGoldBarSellPrice();
      _goldOrnamentPrice = CurrencyExchangeService.getGoldOrnamentSellPrice();
      _goldUpdated = CurrencyExchangeService.getGoldLastUpdatedText();
    } catch (_) {
      // keep fallback prices
    }
    try {
      await CurrencyExchangeService.fetchLatestRates();
      _silverPerGram = CurrencyExchangeService.getSilverPricePerGram();
      if (_goldUpdated.isEmpty) {
        final g = CurrencyExchangeService.getGoldPricePerBahtWeight();
        if (g > 0) {
          _goldBarPrice = g;
          _goldOrnamentPrice = g + 800;
        }
        _goldUpdated = CurrencyExchangeService.getGoldLastUpdatedText();
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingPrices = false);
  }

  double _p(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '').trim()) ?? 0.0;
  String _money(double v) => '฿${FormatUtils.formatCurrency(v)}';

  // ---------------- Wealth ----------------
  double get _goldPricePerGram => _goldBarPrice / ZakatEngine.gramsPerBahtGold;
  double get _wealthGross => _p(_cashCtrl) + _p(_bankCtrl) + _p(_tradeCtrl) + _p(_investCtrl) + _p(_receivableCtrl);
  double get _wealthNet => (_wealthGross - _p(_debtCtrl)).clamp(0.0, double.infinity);
  double get _wealthNisab => _silverNisab
      ? ZakatEngine.silverNisabGrams * _silverPerGram
      : ZakatEngine.goldNisabGrams * _goldPricePerGram;
  bool get _wealthNisabReached => _wealthNet >= _wealthNisab && _wealthNisab > 0;
  bool get _wealthDue => _wealthNisabReached && _hawlPassed;
  double get _wealthZakat => _wealthDue ? _wealthNet * ZakatEngine.wealthRate : 0;

  // ---------------- Gold ----------------
  double get _goldGrams => _goldUnitBaht ? _p(_goldWeightCtrl) * ZakatEngine.gramsPerBahtGold : _p(_goldWeightCtrl);
  double get _goldPricePerBaht => _goldBar ? _goldBarPrice : _goldOrnamentPrice;
  double get _goldValue => _goldGrams / ZakatEngine.gramsPerBahtGold * _goldPricePerBaht;
  bool get _goldDue => _goldGrams >= ZakatEngine.goldNisabGrams;
  double get _goldZakat => _goldDue ? _goldValue * ZakatEngine.wealthRate : 0;

  // ---------------- Crops ----------------
  double get _cropKg => _p(_cropKgCtrl);
  double get _cropRate => _irrigation == IrrigationType.rainfed ? 0.10 : 0.05;
  bool get _cropDue => _cropKg >= ZakatEngine.cropNisabKg;
  double get _cropZakatKg => _cropDue ? _cropKg * _cropRate : 0;

  void _importAppBalance() {
    HapticFeedback.mediumImpact();
    final netWorth = widget.controller.totalNetWorth;
    setState(() => _bankCtrl.text = netWorth > 0 ? netWorth.toStringAsFixed(0) : '0');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('ดึงยอดเงินในแอพ ${_money(netWorth)} มาใส่ช่อง "เงินในบัญชี" แล้ว'),
      backgroundColor: MeowTheme.incomeGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.controller.currentTheme;
    final isDark = widget.controller.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text('คำนวณซากาต', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: theme.textColor)),
            Text('الزكاة', style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
          ],
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
          children: [
            _buildPriceStrip(theme, isDark),
            const SizedBox(height: 14),
            _sectionLabel('1. เลือกประเภททรัพย์สิน', theme),
            const SizedBox(height: 8),
            _buildCategoryGrid(theme),
            const SizedBox(height: 16),
            _sectionLabel('2. กรอกข้อมูล', theme),
            const SizedBox(height: 8),
            _card(theme, child: _buildInputs(theme)),
            const SizedBox(height: 16),
            _sectionLabel('3. ผลการคำนวณ', theme),
            const SizedBox(height: 8),
            _buildResult(theme, isDark),
            const SizedBox(height: 16),
            _buildRecipientsCard(theme),
            const SizedBox(height: 12),
            _buildGlossary(theme),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, AppThemeModel theme) =>
      Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.textColor));

  Widget _card(AppThemeModel theme, {required Widget child, EdgeInsets padding = const EdgeInsets.all(14)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.borderColor),
      ),
      child: child,
    );
  }

  Widget _buildPriceStrip(AppThemeModel theme, bool isDark) {
    Widget item(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFFB45309))),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
              ),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.14 : 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              item('🥇 ทองแท่ง/บาท', _money(_goldBarPrice)),
              item('📿 รูปพรรณ/บาท', _money(_goldOrnamentPrice)),
              item('🥈 เงิน/กรัม', _money(_silverPerGram)),
              IconButton(
                tooltip: 'อัปเดตราคา',
                onPressed: _fetchPrices,
                icon: _loadingPrices
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded, color: Color(0xFFB45309)),
              ),
            ],
          ),
          if (_goldUpdated.isNotEmpty)
            Text(_goldUpdated,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: theme.textSecondaryColor)),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(AppThemeModel theme) {
    const items = [
      (ZakatCategory.wealth, 'เงินออม & ธุรกิจ', 'زكاة المال', Icons.savings_rounded, Color(0xFF10B981)),
      (ZakatCategory.gold, 'ทองคำ', 'زكاة الذهب', Icons.workspace_premium_rounded, Color(0xFFF59E0B)),
      (ZakatCategory.agriculture, 'ผลผลิตเกษตร', 'زكاة الزروع', Icons.grass_rounded, Color(0xFF84CC16)),
      (ZakatCategory.livestock, 'ปศุสัตว์', 'زكاة الأنعام', Icons.pets_rounded, Color(0xFF8B5CF6)),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.1,
      children: [
        for (final it in items)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _category = it.$1);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _category == it.$1 ? it.$5.withValues(alpha: 0.14) : theme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _category == it.$1 ? it.$5 : theme.borderColor,
                  width: _category == it.$1 ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(it.$4, color: it.$5, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: theme.textColor)),
                        Text(it.$3, style: TextStyle(fontSize: 11.5, color: theme.textSecondaryColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputs(AppThemeModel theme) {
    switch (_category) {
      case ZakatCategory.wealth:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('ทรัพย์สินที่มีอยู่ตอนนี้',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: theme.textColor)),
                ),
                ActionChip(
                  avatar: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('ดึงยอดในแอพ', style: TextStyle(fontSize: 12)),
                  onPressed: _importAppBalance,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _pair(_field(_cashCtrl, '💵 เงินสด', theme), _field(_bankCtrl, '🏦 เงินในบัญชี', theme)),
            _pair(_field(_tradeCtrl, '📦 สินค้าเพื่อขาย (ราคาตลาด)', theme), _field(_investCtrl, '📈 หุ้น/กองทุน', theme)),
            _field(_receivableCtrl, '🤝 เงินที่ให้คนอื่นยืมและคาดว่าจะได้คืน', theme),
            const SizedBox(height: 8),
            _field(_debtCtrl, '💳 หักหนี้ที่ต้องจ่ายตอนนี้', theme),
            const SizedBox(height: 10),
            _toggleRow(
              theme,
              title: 'ถือครองครบ 1 ปีจันทรคติ (حول เฮาล์)',
              subtitle: 'ทรัพย์สินอยู่เกินเกณฑ์นิศอบต่อเนื่องครบ 354 วัน',
              value: _hawlPassed,
              onChanged: (v) => setState(() => _hawlPassed = v),
            ),
            const SizedBox(height: 6),
            Text('เกณฑ์นิศอบที่ใช้ (نصاب)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: theme.textSecondaryColor)),
            const SizedBox(height: 6),
            _segmented(
              theme,
              [
                ('ทองคำ 85 กรัม', !_silverNisab, () => setState(() => _silverNisab = false)),
                ('เงิน 595 กรัม', _silverNisab, () => setState(() => _silverNisab = true)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _silverNisab
                  ? 'เกณฑ์เงินต่ำกว่า ทำให้คนจำนวนมากขึ้นต้องจ่าย เป็นประโยชน์ต่อผู้รับซากาต'
                  : 'ทองคำ 85 กรัม (20 มิษก็อล) ≈ ${(ZakatEngine.goldNisabGrams / ZakatEngine.gramsPerBahtGold).toStringAsFixed(2)} บาททอง',
              style: TextStyle(fontSize: 11.5, color: theme.textSecondaryColor),
            ),
          ],
        );
      case ZakatCategory.gold:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ทองคำที่เก็บไว้ (ไม่รวมที่สวมใส่ประจำในปริมาณปกติ ตามมัซฮับชาฟิอีย์)',
                style: TextStyle(fontSize: 12.5, height: 1.4, color: theme.textSecondaryColor)),
            const SizedBox(height: 10),
            _segmented(theme, [
              ('ทองคำแท่ง', _goldBar, () => setState(() => _goldBar = true)),
              ('ทองรูปพรรณ', !_goldBar, () => setState(() => _goldBar = false)),
            ]),
            const SizedBox(height: 10),
            _segmented(theme, [
              ('หน่วย: บาททอง', _goldUnitBaht, () => setState(() => _goldUnitBaht = true)),
              ('หน่วย: กรัม', !_goldUnitBaht, () => setState(() => _goldUnitBaht = false)),
            ]),
            const SizedBox(height: 10),
            _field(_goldWeightCtrl, _goldUnitBaht ? 'น้ำหนักทองรวม (บาททอง)' : 'น้ำหนักทองรวม (กรัม)', theme,
                prefix: '', hint: _goldUnitBaht ? 'เช่น 6' : 'เช่น 90'),
            const SizedBox(height: 6),
            Text('ใช้ราคาขายวันนี้ ${_money(_goldPricePerBaht)} ต่อบาททอง',
                style: TextStyle(fontSize: 11.5, color: theme.textSecondaryColor)),
          ],
        );
      case ZakatCategory.agriculture:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('จ่ายทุกครั้งที่เก็บเกี่ยว ไม่ต้องรอครบปี (นิศอบ 5 วะสัก ≈ 653 กก.)',
                style: TextStyle(fontSize: 12.5, height: 1.4, color: theme.textSecondaryColor)),
            const SizedBox(height: 10),
            _pair(
              _field(_cropKgCtrl, '🌾 ผลผลิตทั้งหมด (กก.)', theme, prefix: '', hint: 'เช่น 1000'),
              _field(_cropPriceCtrl, 'ราคาต่อ กก.', theme, hint: 'เช่น 15'),
            ),
            const SizedBox(height: 4),
            Text('การให้น้ำ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: theme.textSecondaryColor)),
            const SizedBox(height: 6),
            _segmented(theme, [
              ('น้ำฝน/ธรรมชาติ 10%', _irrigation == IrrigationType.rainfed,
                  () => setState(() => _irrigation = IrrigationType.rainfed)),
              ('ใช้แรง/ค่าใช้จ่ายรดน้ำ 5%', _irrigation == IrrigationType.irrigated,
                  () => setState(() => _irrigation = IrrigationType.irrigated)),
            ]),
          ],
        );
      case ZakatCategory.livestock:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('สัตว์ที่เลี้ยงปล่อยกินหญ้าตามธรรมชาติเกือบทั้งปี และครบ 1 ปี (حول)',
                style: TextStyle(fontSize: 12.5, height: 1.4, color: theme.textSecondaryColor)),
            const SizedBox(height: 10),
            _segmented(theme, [
              ('🐐 แพะ/แกะ', _livestock == LivestockKind.goat, () => setState(() => _livestock = LivestockKind.goat)),
              ('🐄 วัว/ควาย', _livestock == LivestockKind.cattle, () => setState(() => _livestock = LivestockKind.cattle)),
              ('🐪 อูฐ', _livestock == LivestockKind.camel, () => setState(() => _livestock = LivestockKind.camel)),
            ]),
            const SizedBox(height: 10),
            _field(_animalCtrl, 'จำนวนสัตว์ทั้งหมด (ตัว)', theme, prefix: '', hint: 'เช่น 45'),
          ],
        );
    }
  }

  Widget _buildResult(AppThemeModel theme, bool isDark) {
    late bool due;
    late String headline;
    late String amountText;
    String? subAmount;
    double? progress;
    String? progressLabel;
    final steps = <String>[];

    switch (_category) {
      case ZakatCategory.wealth:
        due = _wealthDue;
        amountText = _money(_wealthZakat);
        headline = _wealthDue
            ? 'ต้องจ่ายซากาต (วาญิบ)'
            : (_wealthNisabReached ? 'ถึงนิศอบแล้ว แต่ยังไม่ครบปี' : 'ยังไม่ถึงเกณฑ์นิศอบ');
        progress = _wealthNisab > 0 ? (_wealthNet / _wealthNisab) : 0;
        progressLabel = 'ทรัพย์สุทธิ ${(progress * 100).toStringAsFixed(0)}% ของนิศอบ';
        steps.addAll([
          'รวมทรัพย์สิน ${_money(_wealthGross)} − หนี้ ${_money(_p(_debtCtrl))} = ${_money(_wealthNet)}',
          _silverNisab
              ? 'นิศอบ = เงิน 595 กรัม × ${_money(_silverPerGram)} = ${_money(_wealthNisab)}'
              : 'นิศอบ = ทอง 85 กรัม × ${_money(_goldPricePerGram)}/กรัม = ${_money(_wealthNisab)}',
          _wealthNisabReached ? 'ทรัพย์สุทธิถึงนิศอบ ✓' : 'ทรัพย์สุทธิยังไม่ถึงนิศอบ จึงยังไม่ต้องจ่าย',
          _hawlPassed ? 'ถือครองครบ 1 ปีจันทรคติ ✓' : 'ยังไม่ครบ 1 ปี (เฮาล์) จึงยังไม่ต้องจ่าย',
          if (_wealthDue) '${_money(_wealthNet)} × 2.5% (ربع العشر หนึ่งในสี่สิบ) = ${_money(_wealthZakat)}',
        ]);
        break;
      case ZakatCategory.gold:
        due = _goldDue;
        amountText = _money(_goldZakat);
        headline = _goldDue ? 'ต้องจ่ายซากาตทองคำ (วาญิบ)' : 'ยังไม่ถึงเกณฑ์นิศอบ';
        progress = _goldGrams / ZakatEngine.goldNisabGrams;
        progressLabel = 'มีทอง ${_goldGrams.toStringAsFixed(1)} กรัม จากเกณฑ์ 85 กรัม';
        if (_goldDue) {
          subAmount = 'หรือจ่ายเป็นทองคำ ${(_goldGrams * ZakatEngine.wealthRate).toStringAsFixed(2)} กรัม';
        }
        steps.addAll([
          'น้ำหนักทอง ${_goldGrams.toStringAsFixed(2)} กรัม (1 บาททอง = 15.244 กรัม)',
          _goldDue ? 'ถึงนิศอบ 85 กรัม ✓' : 'ยังไม่ถึง 85 กรัม จึงยังไม่ต้องจ่าย',
          'มูลค่าทอง = ${_money(_goldValue)}',
          if (_goldDue) '${_money(_goldValue)} × 2.5% = ${_money(_goldZakat)}',
        ]);
        break;
      case ZakatCategory.agriculture:
        due = _cropDue;
        amountText = '${FormatUtils.formatCurrency(_cropZakatKg)} กก.';
        if (_cropDue && _p(_cropPriceCtrl) > 0) subAmount = 'คิดเป็นเงินประมาณ ${_money(_cropZakatKg * _p(_cropPriceCtrl))}';
        headline = _cropDue ? 'ต้องจ่ายซากาตผลผลิต (วาญิบ)' : 'ยังไม่ถึงเกณฑ์นิศอบ';
        progress = _cropKg / ZakatEngine.cropNisabKg;
        progressLabel = 'ผลผลิต ${FormatUtils.formatCurrency(_cropKg)} กก. จากเกณฑ์ 653 กก.';
        steps.addAll([
          _cropDue ? 'ผลผลิตถึงนิศอบ 5 วะสัก (≈653 กก.) ✓' : 'ผลผลิตยังไม่ถึง 653 กก.',
          _irrigation == IrrigationType.rainfed
              ? 'ใช้น้ำฝน/ธรรมชาติ อัตรา 10% (العشر อัล-อุชร)'
              : 'ใช้แรงหรือค่าใช้จ่ายรดน้ำ อัตรา 5% (نصف العشر นิศฟุลอุชร)',
          if (_cropDue) '${FormatUtils.formatCurrency(_cropKg)} × ${(_cropRate * 100).toInt()}% = ${FormatUtils.formatCurrency(_cropZakatKg)} กก.',
        ]);
        break;
      case ZakatCategory.livestock:
        final n = _p(_animalCtrl).toInt();
        final r = ZakatEngine.livestock(_livestock, n);
        due = r.due;
        amountText = r.due ? r.summary : 'ไม่ต้องจ่าย';
        headline = r.due ? 'ต้องจ่ายซากาตปศุสัตว์ (วาญิบ)' : 'ยังไม่ถึงเกณฑ์นิศอบ';
        steps.add(r.detail);
        break;
    }

    final color = due ? const Color(0xFF059669) : theme.textSecondaryColor;
    return _card(
      theme,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(due ? Icons.check_circle_rounded : Icons.info_rounded, size: 16, color: color),
                const SizedBox(width: 5),
                Text(headline, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('ยอดซากาตที่ต้องจ่าย', style: TextStyle(fontSize: 12.5, color: theme.textSecondaryColor)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(amountText,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: due ? theme.primaryColor : theme.textColor)),
          ),
          if (subAmount != null)
            Text(subAmount, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: theme.textSecondaryColor)),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation(progress >= 1 ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
              ),
            ),
            const SizedBox(height: 4),
            Text(progressLabel!, style: TextStyle(fontSize: 11.5, color: theme.textSecondaryColor)),
          ],
          const Divider(height: 24),
          Text('วิธีคิด', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textColor)),
          const SizedBox(height: 6),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: theme.primaryColor.withValues(alpha: 0.14), shape: BoxShape.circle),
                    child: Text('${i + 1}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(steps[i], style: TextStyle(fontSize: 12.5, height: 1.4, color: theme.textColor)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecipientsCard(AppThemeModel theme) {
    const groups = [
      ('คนยากจน', 'الفقراء', 'ไม่มีรายได้ หรือมีไม่ถึงครึ่งของที่จำเป็น'),
      ('คนขัดสน', 'المساكين', 'มีรายได้แต่ไม่พอใช้จ่ายจำเป็น'),
      ('ผู้จัดเก็บซากาต', 'العاملين عليها', 'เจ้าหน้าที่ที่ได้รับมอบหมายให้เก็บและแจกจ่าย'),
      ('ผู้ที่ควรโน้มน้าวใจ', 'المؤلفة قلوبهم', 'มุอัลลัฟ ผู้เข้ารับอิสลามใหม่'),
      ('ไถ่ทาส', 'في الرقاب', 'ปลดปล่อยผู้ที่ถูกกดขี่เป็นทาส'),
      ('ผู้มีหนี้สิน', 'الغارمين', 'มีหนี้จากเรื่องที่ชอบธรรมและไม่สามารถชำระได้'),
      ('ในหนทางของอัลลอฮ์', 'في سبيل الله', 'ผู้ที่ทำงานเพื่อศาสนา'),
      ('คนเดินทาง', 'ابن السبيل', 'ผู้เดินทางที่ขาดแคลนปัจจัยระหว่างทาง'),
    ];
    return _card(
      theme,
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.volunteer_activism_rounded, color: Color(0xFF10B981)),
          title: Text('ผู้มีสิทธิ์รับซากาต 8 กลุ่ม',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textColor)),
          subtitle: Text('الأصناف الثمانية • อัต-เตาบะฮ์ 9:60',
              style: TextStyle(fontSize: 11.5, color: theme.textSecondaryColor)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            for (var i = 0; i < groups.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${i + 1}.', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: theme.textColor)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${groups[i].$1}  (${groups[i].$2})',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: theme.textColor)),
                          Text(groups[i].$3, style: TextStyle(fontSize: 11.5, color: theme.textSecondaryColor)),
                        ],
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

  Widget _buildGlossary(AppThemeModel theme) {
    const words = [
      ('นิศอบ', 'نصاب', 'ปริมาณขั้นต่ำที่ทำให้ต้องจ่ายซากาต'),
      ('เฮาล์', 'حول', 'ครบรอบ 1 ปีจันทรคติ (ฮิจญ์เราะฮ์)'),
      ('รุบุอุลอุชร', 'ربع العشر', '1 ใน 40 = 2.5%'),
      ('อัล-อุชร', 'العشر', '1 ใน 10 = 10% (ผลผลิตน้ำฝน)'),
      ('วาญิบ', 'واجب', 'จำเป็นต้องปฏิบัติ'),
    ];
    return _card(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('คำศัพท์ที่ควรรู้', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textColor)),
          const SizedBox(height: 8),
          for (final w in words)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text.rich(TextSpan(children: [
                TextSpan(
                    text: '${w.$1} (${w.$2}) ',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                TextSpan(text: w.$3, style: TextStyle(fontSize: 12.5, color: theme.textSecondaryColor)),
              ])),
            ),
          const SizedBox(height: 4),
          Text(
            'อ้างอิง: อัล-บะเกาะเราะฮ์ 2:267, อัต-เตาบะฮ์ 9:60 • หะดีษอัล-บุคอรีย์ว่าด้วยซากาตผลผลิตและปศุสัตว์ (จดหมายของท่านอบูบักร) • ใช้เพื่อประมาณการเบื้องต้น ควรสอบถามอิหม่ามหรือคณะกรรมการอิสลามในพื้นที่',
            style: TextStyle(fontSize: 11.5, height: 1.45, color: theme.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  // ---------------- Small widgets ----------------
  Widget _pair(Widget a, Widget b) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: a),
          const SizedBox(width: 10),
          Expanded(child: b),
        ]),
      );

  Widget _field(TextEditingController c, String label, AppThemeModel theme, {String prefix = '฿ ', String hint = '0'}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textSecondaryColor)),
        const SizedBox(height: 4),
        TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          onChanged: (_) => setState(() {}),
          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: theme.textColor),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix.isEmpty ? null : prefix,
            hintStyle: TextStyle(color: theme.textSecondaryColor.withValues(alpha: 0.5), fontWeight: FontWeight.normal),
            filled: true,
            fillColor: theme.surfaceBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.borderColor)),
            enabledBorder:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.borderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.primaryColor, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _segmented(AppThemeModel theme, List<(String, bool, VoidCallback)> options) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.surfaceBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  o.$3();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(
                    color: o.$2 ? theme.primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    o.$1,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: o.$2 ? Colors.white : theme.textSecondaryColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _toggleRow(
    AppThemeModel theme, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textColor)),
              Text(subtitle, style: TextStyle(fontSize: 11.5, color: theme.textSecondaryColor)),
            ],
          ),
        ),
        Switch(value: value, activeThumbColor: theme.primaryColor, onChanged: onChanged),
      ],
    );
  }
}
