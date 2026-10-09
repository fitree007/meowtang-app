import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/currency_exchange_service.dart';
import '../services/zakat_engine.dart';
import '../state/expense_controller.dart';
import '../theme/app_theme_model.dart';
import '../theme/meow_theme.dart';
import '../utils/format_utils.dart';
import '../models/transaction_item.dart';
import '../widgets/meow_fx.dart';
import 'add_transaction_screen.dart';

enum ZakatCategory { wealth, gold, agriculture, livestock }

enum IrrigationType { irrigated, rainfed, mixed }

/// Verdict shown in the status chip of the result card.
enum _ZStatus { due, wait, no, free }

/// Everything the result card and the bottom bar show for the selected category.
class _ZView {
  final _ZStatus status;
  final String amountLabel;
  final String amountText;

  /// Animated count-up target, or null when the amount is not a number (livestock).
  final double? amountValue;
  final String Function(double)? amountFormat;
  final String? sub;
  final double have;
  final double need;
  final String barLeft;
  final String barRight;
  final List<(String, String)> steps;

  const _ZView({
    required this.status,
    required this.amountLabel,
    required this.amountText,
    this.amountValue,
    this.amountFormat,
    this.sub,
    required this.have,
    required this.need,
    required this.barLeft,
    required this.barRight,
    required this.steps,
  });
}

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
  final _bankCtrl = TextEditingController(); // cash + bank balances
  final _tradeCtrl = TextEditingController();
  final _investCtrl = TextEditingController();
  final _receivableCtrl = TextEditingController();
  final _debtCtrl = TextEditingController();
  bool _hawlPassed = true;
  bool _silverNisab = false;

  // Gold & silver
  bool _silverMetal = false;
  bool _goldUnitBaht = true;
  bool _goldBar = true;
  bool _jewelry = false; // worn jewellery: no zakat in the Shafi'i school
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

  /// Accent for text and icons on cards (lighter in dark mode so it stays readable).
  Color get _ink {
    final t = widget.controller.currentTheme;
    return widget.controller.isDarkMode ? Color.lerp(t.primaryColor, Colors.white, 0.45)! : t.primaryColor;
  }

  double _p(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '').trim()) ?? 0.0;
  String _money(double v) => '฿${FormatUtils.formatCurrency(v)}';
  String _num(double v, [int digits = 2]) {
    final s = FormatUtils.formatCurrency(v);
    if (digits == 0) return s.split('.').first;
    return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
  }

  // ---------------- Wealth ----------------
  double get _goldPricePerGram => _goldBarPrice / ZakatEngine.gramsPerBahtGold;
  double get _wealthGross => _p(_bankCtrl) + _p(_tradeCtrl) + _p(_investCtrl) + _p(_receivableCtrl);
  double get _wealthNet => (_wealthGross - _p(_debtCtrl)).clamp(0.0, double.infinity);
  double get _wealthNisab => _silverNisab
      ? ZakatEngine.silverNisabGrams * _silverPerGram
      : ZakatEngine.goldNisabGrams * _goldPricePerGram;
  bool get _wealthNisabReached => _wealthNet >= _wealthNisab && _wealthNisab > 0;
  bool get _wealthDue => _wealthNisabReached && _hawlPassed;
  double get _wealthZakat => _wealthDue ? _wealthNet * ZakatEngine.wealthRate : 0;

  // ---------------- Gold & silver ----------------
  bool get _weighInBaht => _goldUnitBaht && !_silverMetal;
  double get _goldGrams => _weighInBaht ? _p(_goldWeightCtrl) * ZakatEngine.gramsPerBahtGold : _p(_goldWeightCtrl);
  double get _goldPricePerBaht => _goldBar ? _goldBarPrice : _goldOrnamentPrice;
  double get _metalNisabGrams => _silverMetal ? ZakatEngine.silverNisabGrams : ZakatEngine.goldNisabGrams;
  double get _goldValue => _silverMetal
      ? _goldGrams * _silverPerGram
      : _goldGrams / ZakatEngine.gramsPerBahtGold * _goldPricePerBaht;
  bool get _goldNisabReached => _goldGrams >= _metalNisabGrams;
  bool get _goldDue => _goldNisabReached && _hawlPassed && !_jewelry;
  double get _goldZakat => _goldDue ? _goldValue * ZakatEngine.wealthRate : 0;

  // ---------------- Crops ----------------
  double get _cropKg => _p(_cropKgCtrl);
  double get _cropRate => switch (_irrigation) {
        IrrigationType.rainfed => 0.10,
        IrrigationType.irrigated => 0.05,
        IrrigationType.mixed => 0.075,
      };
  bool get _cropDue => _cropKg >= ZakatEngine.cropNisabKg;
  double get _cropZakatKg => _cropDue ? _cropKg * _cropRate : 0;

  // ---------------- Livestock ----------------
  static const _livestockNisab = {LivestockKind.goat: 40, LivestockKind.cattle: 30, LivestockKind.camel: 5};

  void _importAppBalance() {
    HapticFeedback.mediumImpact();
    final netWorth = widget.controller.totalNetWorth;
    setState(() => _bankCtrl.text = netWorth > 0 ? netWorth.toStringAsFixed(0) : '0');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('ดึงยอดเงินในแอพ ${_money(netWorth)} มาใส่ช่อง "เงินสด + เงินในบัญชี" แล้ว'),
      backgroundColor: MeowTheme.incomeGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  // ---------------------------------------------------------------------------
  // Result model
  // ---------------------------------------------------------------------------
  _ZView get _view {
    switch (_category) {
      case ZakatCategory.wealth:
        final ok = _wealthNisabReached;
        return _ZView(
          status: ok ? (_hawlPassed ? _ZStatus.due : _ZStatus.wait) : _ZStatus.no,
          amountLabel: 'ยอดซากาตที่ต้องจ่าย',
          amountText: _money(_wealthZakat),
          amountValue: _wealthZakat,
          amountFormat: _money,
          have: _wealthNet,
          need: _wealthNisab,
          barLeft: 'มี ${_money(_wealthNet)}',
          barRight: 'นิศอบ ${_money(_wealthNisab)}',
          steps: [
            (
              'รวมทรัพย์สุทธิ',
              '${_money(_p(_bankCtrl))} + ${_money(_p(_tradeCtrl))} + ${_money(_p(_investCtrl))} + ${_money(_p(_receivableCtrl))}'
                  ' − หนี้ ${_money(_p(_debtCtrl))} = ${_money(_wealthNet)}'
            ),
            _silverNisab
                ? ('นิศอบ = แร่เงิน 595 กรัม', '595 × ${_money(_silverPerGram)} = ${_money(_wealthNisab)}')
                : ('นิศอบ = ทองคำ 85 กรัม', '85 ÷ 15.244 × ${_money(_goldBarPrice)} = ${_money(_wealthNisab)}'),
            ok
                ? (
                    _hawlPassed ? 'ถึงนิศอบ และครบปี' : 'ถึงนิศอบ แต่ยังไม่ครบปี',
                    _hawlPassed
                        ? '${_money(_wealthNet)} × 2.5% = ${_money(_wealthZakat)}'
                        : 'รอให้ครบ 1 ปีจันทรคติ แล้วคิดใหม่ด้วยยอดตอนนั้น'
                  )
                : ('ยังไม่ถึงนิศอบ', 'ขาดอีก ${_money(_wealthNisab - _wealthNet)}'),
          ],
        );
      case ZakatCategory.gold:
        final metal = _silverMetal ? 'เงิน' : 'ทอง';
        final ok = _goldNisabReached;
        final needG = _metalNisabGrams;
        return _ZView(
          status: _jewelry ? _ZStatus.free : ok ? (_hawlPassed ? _ZStatus.due : _ZStatus.wait) : _ZStatus.no,
          amountLabel: 'ยอดซากาตที่ต้องจ่าย',
          amountText: _money(_goldZakat),
          amountValue: _goldZakat,
          amountFormat: _money,
          sub: _goldDue ? 'หรือจ่ายเป็นเนื้อ$metal ${(_goldGrams * ZakatEngine.wealthRate).toStringAsFixed(2)} กรัม' : null,
          have: _goldGrams,
          need: needG,
          barLeft: 'มี ${_goldGrams.toStringAsFixed(1)} กรัม',
          barRight: 'นิศอบ ${needG.toStringAsFixed(0)} กรัม',
          steps: [
            (
              'แปลงเป็นกรัม',
              _weighInBaht
                  ? '${_num(_p(_goldWeightCtrl))} บาท × 15.244 = ${_num(_goldGrams)} กรัม'
                  : '${_num(_goldGrams)} กรัม'
            ),
            (
              'เทียบนิศอบ ${needG.toStringAsFixed(0)} กรัม',
              ok
                  ? 'ถึงนิศอบ (มูลค่า ${_money(_goldValue)})'
                  : 'ยังไม่ถึง ขาดอีก ${(needG - _goldGrams).toStringAsFixed(1)} กรัม'
            ),
            _jewelry
                ? (
                    'เครื่องประดับที่สวมใส่ปกติ',
                    'มัซฮับชาฟิอีย์ไม่ต้องออกซากาต (ถ้าเก็บไว้ ไม่ได้ใส่ หรือมากเกินปกติ ต้องออก)'
                  )
                : (
                    'คูณ 2.5%',
                    _goldDue
                        ? '${_money(_goldValue)} × 2.5% = ${_money(_goldZakat)}'
                        : ok
                            ? 'รอให้ครบ 1 ปีจันทรคติ'
                            : 'ยังไม่ต้องจ่าย'
                  ),
          ],
        );
      case ZakatCategory.agriculture:
        final price = _p(_cropPriceCtrl);
        String kg(double v) => '${FormatUtils.formatCurrency(v)} กก.';
        return _ZView(
          status: _cropDue ? _ZStatus.due : _ZStatus.no,
          amountLabel: 'ซากาตที่ต้องจ่าย (เป็นผลผลิต)',
          amountText: kg(_cropZakatKg),
          amountValue: _cropZakatKg,
          amountFormat: kg,
          sub: _cropDue && price > 0 ? 'คิดเป็นเงินประมาณ ${_money(_cropZakatKg * price)}' : null,
          have: _cropKg,
          need: ZakatEngine.cropNisabKg,
          barLeft: 'มี ${_num(_cropKg, 0)} กก.',
          barRight: 'นิศอบ ${_num(ZakatEngine.cropNisabKg, 0)} กก.',
          steps: [
            (
              'นิศอบ = 5 วะสัก ≈ 653 กก.',
              _cropDue
                  ? 'ผลผลิต ${_num(_cropKg, 0)} กก. ถึงนิศอบ'
                  : 'ผลผลิต ${_num(_cropKg, 0)} กก. ยังไม่ถึง ขาดอีก ${_num(ZakatEngine.cropNisabKg - _cropKg, 0)} กก.'
            ),
            (
              'อัตราตามการให้น้ำ',
              switch (_irrigation) {
                IrrigationType.rainfed => 'น้ำฝน/น้ำธรรมชาติ 10% (العشر)',
                IrrigationType.irrigated => 'ลงทุนรดน้ำเอง 5% (نصف العشر)',
                IrrigationType.mixed => 'ผสมกันพอ ๆ กัน 7.5%',
              }
            ),
            (
              'จ่ายทันทีเมื่อเก็บเกี่ยว (ไม่ต้องรอครบปี)',
              _cropDue
                  ? '${_num(_cropKg, 0)} × ${(_cropRate * 100).toStringAsFixed(_irrigation == IrrigationType.mixed ? 1 : 0)}% = ${kg(_cropZakatKg)}'
                  : 'ยังไม่ต้องจ่าย'
            ),
          ],
        );
      case ZakatCategory.livestock:
        final n = _p(_animalCtrl).toInt();
        final r = ZakatEngine.livestock(_livestock, n);
        final min = _livestockNisab[_livestock]!;
        final due = r.due && _hawlPassed;
        return _ZView(
          status: r.due ? (_hawlPassed ? _ZStatus.due : _ZStatus.wait) : _ZStatus.no,
          amountLabel: 'ซากาตที่ต้องจ่าย (เป็นตัวสัตว์)',
          amountText: due ? r.summary : 'ไม่ต้องจ่าย',
          have: n.toDouble(),
          need: min.toDouble(),
          barLeft: 'มี $n ตัว',
          barRight: 'นิศอบ $min ตัว',
          steps: [
            ('นิศอบเริ่มที่ $min ตัว', 'มี $n ตัว${n >= min ? ' — ถึงนิศอบ' : ' — ยังไม่ถึง'}'),
            ('ตามตารางในหะดีษ', r.detail),
            ('เงื่อนไข', 'เลี้ยงปล่อยกินหญ้าเกือบทั้งปี ไม่ได้ใช้งาน และครบ 1 ปี${_hawlPassed ? ' ✓' : ' (ยังไม่ครบ)'}'),
          ],
        );
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = widget.controller.currentTheme;
    final isDark = widget.controller.isDarkMode;
    final view = _view;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      bottomNavigationBar: _buildBottomBar(theme, view),
      body: Column(
        children: [
          _buildHeader(theme),
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  FxFadeUp(index: 2, child: _buildCategorySection(theme, isDark)),
                  const SizedBox(height: 14),
                  FxFadeUp(index: 0, child: _buildFormSection(theme, isDark)),
                  const SizedBox(height: 14),
                  FxFadeUp(index: 1, child: _buildResult(theme, isDark, view)),
                  const SizedBox(height: 14),
                  _buildPriceNote(theme),
                  const SizedBox(height: 14),
                  FxFadeUp(index: 3, child: _buildRecipientsCard(theme, isDark)),
                  const SizedBox(height: 14),
                  FxFadeUp(index: 4, child: _buildGlossary(theme, isDark)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppThemeModel theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 10, 8, 10),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(bottom: BorderSide(color: theme.borderColor)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              tooltip: 'ย้อนกลับ',
              icon: Icon(Icons.chevron_left_rounded, color: theme.textColor, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('คำนวณซากาต', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textColor)),
                Text('ตามมัซฮับชาฟิอีย์', style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text('الزكاة',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _ink)),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDeco(AppThemeModel theme, bool isDark, {double radius = 20}) => BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(radius),
        border: isDark ? Border.all(color: theme.borderColor) : null,
        boxShadow: isDark ? null : const [BoxShadow(color: Color(0x0F0B2A27), blurRadius: 14, offset: Offset(0, 4))],
      );

  Color _tint(AppThemeModel theme, double a) => Color.alphaBlend(theme.primaryColor.withValues(alpha: a), theme.cardBackground);

  Widget _heading(int n, String text, AppThemeModel theme, {Color? circle, Color? numColor, Color? textColor}) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: circle ?? theme.primaryColor, shape: BoxShape.circle),
          child: Text('$n',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: numColor ?? Colors.white)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor ?? theme.textColor)),
        ),
      ],
    );
  }

  // ---------------- Section 1: category ----------------
  Widget _buildCategorySection(AppThemeModel theme, bool isDark) {
    const items = [
      (ZakatCategory.wealth, '💰', 'เงินออม & ธุรกิจ', 'زكاة المال • 2.5%', Color(0xFFDDF1EC), Color(0xFF10B981)),
      (ZakatCategory.gold, '🪙', 'ทองคำ & แร่เงิน', 'زكاة الذهب والفضة', Color(0xFFFEF3C7), Color(0xFFF59E0B)),
      (ZakatCategory.agriculture, '🌾', 'ผลผลิตเกษตร', 'زكاة الزروع • 5–10%', Color(0xFFECFCCB), Color(0xFF84CC16)),
      (ZakatCategory.livestock, '🐄', 'ปศุสัตว์', 'زكاة الأنعام', Color(0xFFEDE9FE), Color(0xFF8B5CF6)),
    ];
    Widget tile(int i) {
      final it = items[i];
      final sel = _category == it.$1;
      return Semantics(
        button: true,
        selected: sel,
        child: FxPress(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _category = it.$1);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 104),
            padding: EdgeInsets.all(sel ? 11 : 12),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: sel ? _ink : theme.borderColor, width: sel ? 2 : 1),
              boxShadow: sel && !isDark
                  ? [BoxShadow(color: theme.primaryColor.withValues(alpha: 0.14), blurRadius: 16, offset: const Offset(0, 6))]
                  : null,
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark ? it.$6.withValues(alpha: 0.2) : it.$5,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(it.$2, style: const TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(height: 6),
                    Text(it.$3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textColor)),
                    const SizedBox(height: 2),
                    Text(it.$4,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
                  ],
                ),
                if (sel)
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(1, 'จะคำนวณซากาตอะไร?', theme),
        const SizedBox(height: 10),
        for (var r = 0; r < 2; r++) ...[
          if (r > 0) const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tile(r * 2)),
                const SizedBox(width: 10),
                Expanded(child: tile(r * 2 + 1)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ---------------- Section 2: inputs ----------------
  String get _formTitle => switch (_category) {
        ZakatCategory.wealth => 'กรอกทรัพย์สินที่มีตอนนี้',
        ZakatCategory.gold => _silverMetal ? 'แร่เงินที่เก็บไว้' : 'ทองคำที่เก็บไว้',
        ZakatCategory.agriculture => 'ผลผลิตรอบนี้',
        ZakatCategory.livestock => 'ปศุสัตว์ที่เลี้ยงไว้',
      };

  Widget _buildFormSection(AppThemeModel theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(theme, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading(2, _formTitle, theme),
          const SizedBox(height: 14),
          _buildInputs(theme, isDark),
          if (_category != ZakatCategory.agriculture) ...[
            const SizedBox(height: 14),
            _haulToggle(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildInputs(AppThemeModel theme, bool isDark) {
    final red = isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
    switch (_category) {
      case ZakatCategory.wealth:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(
              _bankCtrl,
              '💵 เงินสด + เงินในบัญชี',
              theme,
              big: true,
              trailing: _softButton(theme, 'ดึงยอดในแอพ', _importAppBalance),
            ),
            const SizedBox(height: 12),
            _pair(
              _field(_tradeCtrl, '🏪 สินค้า/ทุนธุรกิจ', theme),
              _field(_receivableCtrl, '🤝 เงินที่คนอื่นค้างเรา', theme),
            ),
            const SizedBox(height: 12),
            _field(_investCtrl, '📈 หุ้น/กองทุน', theme),
            const SizedBox(height: 12),
            _field(_debtCtrl, '➖ หนี้ที่ถึงกำหนดต้องจ่าย', theme,
                labelColor: red, borderColor: red.withValues(alpha: isDark ? 0.45 : 0.25)),
            const SizedBox(height: 12),
            Text('เทียบนิศอบกับ',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: theme.textColor)),
            const SizedBox(height: 6),
            _segmented(theme, [
              ('ทองคำ 85 กรัม', !_silverNisab, () => setState(() => _silverNisab = false)),
              ('แร่เงิน 595 กรัม', _silverNisab, () => setState(() => _silverNisab = true)),
            ]),
          ],
        );
      case ZakatCategory.gold:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _segmented(theme, [
              ('🥇 ทองคำ', !_silverMetal, () => setState(() => _silverMetal = false)),
              ('🥈 แร่เงิน', _silverMetal, () => setState(() => _silverMetal = true)),
            ]),
            if (!_silverMetal) ...[
              const SizedBox(height: 8),
              _segmented(theme, [
                ('ทองคำแท่ง', _goldBar, () => setState(() => _goldBar = true)),
                ('ทองรูปพรรณ', !_goldBar, () => setState(() => _goldBar = false)),
              ], height: 38),
            ],
            const SizedBox(height: 12),
            _field(
              _goldWeightCtrl,
              'น้ำหนักที่เก็บไว้',
              theme,
              big: true,
              suffix: _weighInBaht ? 'บาท' : 'กรัม',
              hint: _silverMetal ? 'เช่น 600' : (_goldUnitBaht ? 'เช่น 6' : 'เช่น 90'),
              trailing: _silverMetal
                  ? null
                  : _miniSegmented(theme, [
                      ('บาท', _goldUnitBaht, () => setState(() => _goldUnitBaht = true)),
                      ('กรัม', !_goldUnitBaht, () => setState(() => _goldUnitBaht = false)),
                    ]),
            ),
            const SizedBox(height: 12),
            _quickChips(
              theme,
              _goldWeightCtrl,
              _silverMetal ? const [100, 300, 595, 1000] : (_goldUnitBaht ? const [1, 2, 5, 6, 10] : const [10, 50, 85, 100]),
              _weighInBaht ? 'บาท' : 'กรัม',
            ),
            const SizedBox(height: 12),
            _checkRow(
              theme,
              title: 'เป็นเครื่องประดับที่สวมใส่ตามปกติ',
              subtitle: 'มัซฮับชาฟิอีย์: เครื่องประดับที่ใช้สวมใส่ (ไม่มากเกินปกติ) ไม่ต้องออกซากาต',
              value: _jewelry,
              onChanged: (v) => setState(() => _jewelry = v),
            ),
            const SizedBox(height: 12),
            Text(
              _silverMetal
                  ? 'นิศอบแร่เงิน 595 กรัม ≈ ${_money(ZakatEngine.silverNisabGrams * _silverPerGram)}'
                  : 'นิศอบทองคำ 85 กรัม ≈ 5.58 บาททอง ≈ ${_money(ZakatEngine.goldNisabGrams / ZakatEngine.gramsPerBahtGold * _goldPricePerBaht)}',
              style: TextStyle(fontSize: 12, color: theme.textSecondaryColor),
            ),
          ],
        );
      case ZakatCategory.agriculture:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(_cropKgCtrl, '🌾 ผลผลิตที่เก็บเกี่ยวได้ (ข้าว ข้าวโพด ฯลฯ)', theme,
                big: true, suffix: 'กิโลกรัม', hint: 'เช่น 1,000'),
            const SizedBox(height: 12),
            _quickChips(theme, _cropKgCtrl, const [700, 1000, 2000, 5000], 'กก.'),
            const SizedBox(height: 12),
            Text('การให้น้ำ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: theme.textColor)),
            const SizedBox(height: 6),
            for (final w in const [
              (IrrigationType.rainfed, 'น้ำฝน / น้ำธรรมชาติ', 'ไม่มีต้นทุนการให้น้ำ', '10%'),
              (IrrigationType.irrigated, 'ลงทุนรดน้ำเอง', 'สูบน้ำ จ้างคน ซื้อน้ำ', '5%'),
              (IrrigationType.mixed, 'ผสมกันพอ ๆ กัน', 'ครึ่งน้ำฝน ครึ่งลงทุน', '7.5%'),
            ])
              _radioTile(theme, w.$2, w.$3, w.$4, _irrigation == w.$1, () => setState(() => _irrigation = w.$1)),
            const SizedBox(height: 6),
            _field(_cropPriceCtrl, 'ราคาขายต่อกิโลกรัม (ถ้าจะจ่ายเป็นเงิน)', theme, hint: 'เช่น 12'),
          ],
        );
      case ZakatCategory.livestock:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _segmented(theme, [
              ('🐐 แพะ/แกะ', _livestock == LivestockKind.goat, () => setState(() => _livestock = LivestockKind.goat)),
              ('🐃 วัว/ควาย', _livestock == LivestockKind.cattle, () => setState(() => _livestock = LivestockKind.cattle)),
              ('🐪 อูฐ', _livestock == LivestockKind.camel, () => setState(() => _livestock = LivestockKind.camel)),
            ], height: 46),
            const SizedBox(height: 12),
            Text('จำนวนที่เลี้ยงไว้ (ปล่อยกินหญ้าตามธรรมชาติ)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textColor)),
            const SizedBox(height: 6),
            Row(
              children: [
                _stepButton(theme, Icons.remove_rounded, false, () => _stepAnimals(-1), 'ลด'),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: TextField(
                      controller: _animalCtrl,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textColor),
                      decoration: _inputDeco(theme, radius: 16, vertical: 14).copyWith(hintText: '0'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _stepButton(theme, Icons.add_rounded, true, () => _stepAnimals(1), 'เพิ่ม'),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              switch (_livestock) {
                LivestockKind.goat => 'นิศอบ 40 ตัว • 40–120 ตัว จ่าย 1 ตัว',
                LivestockKind.cattle => 'นิศอบ 30 ตัว • ทุก 30 ตัวจ่ายตะบีอ์ ทุก 40 ตัวจ่ายมุสินนะฮ์',
                LivestockKind.camel => 'นิศอบ 5 ตัว • 5–24 ตัว จ่ายแพะ 1 ตัวต่ออูฐ 5 ตัว',
              },
              style: TextStyle(fontSize: 12, color: theme.textSecondaryColor),
            ),
          ],
        );
    }
  }

  Widget _haulToggle(AppThemeModel theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _hawlPassed = !_hawlPassed),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
        decoration: BoxDecoration(
          color: theme.scaffoldBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ครอบครองครบ 1 ปีจันทรคติแล้ว',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: theme.textColor)),
                  const SizedBox(height: 2),
                  Text('เฮาล์ (حول) ประมาณ 354 วัน นับจากวันที่ถึงนิศอบ',
                      style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
                ],
              ),
            ),
            Switch(
              value: _hawlPassed,
              activeThumbColor: Colors.white,
              activeTrackColor: theme.primaryColor,
              onChanged: (v) => setState(() => _hawlPassed = v),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Section 3: result ----------------
  Widget _buildResult(AppThemeModel theme, bool isDark, _ZView v) {
    final heroText = theme.heroTextColor(isDark);
    final heroMuted = theme.heroTextMutedColor(isDark);
    final heroLight = theme.isHeroLight(isDark);
    final amountColor = !heroLight && theme.primaryDark.computeLuminance() < 0.12 ? const Color(0xFFFDE68A) : heroText;
    final overlay = heroLight ? Colors.black : Colors.white;

    final (chipText, chipIcon, chipBg, chipFg) = switch (v.status) {
      _ZStatus.due => ('ถึงเกณฑ์ — วาญิบต้องออกซากาต', Icons.check_rounded, const Color(0xFFA7F3D0), const Color(0xFF064E3B)),
      _ZStatus.wait => ('ถึงนิศอบแล้ว แต่ยังไม่ครบปี', Icons.hourglass_bottom_rounded, const Color(0xFFFDE68A), const Color(0xFF78350F)),
      _ZStatus.no => ('ยังไม่ถึงนิศอบ — ยังไม่ต้องจ่าย', null, overlay.withValues(alpha: 0.18), heroText),
      _ZStatus.free => ('ไม่ต้องออกซากาต', null, overlay.withValues(alpha: 0.18), heroText),
    };
    final long = v.amountText.length > 16;
    final amountStyle = TextStyle(fontSize: long ? 20 : 34, height: 1.2, fontWeight: FontWeight.bold, color: amountColor);
    final reached = v.need > 0 && v.have >= v.need;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: theme.heroGradient, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(3, 'ผลการคำนวณ', theme,
              circle: heroText, numColor: heroLight ? Colors.white : theme.primaryDark, textColor: heroText),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (chipIcon != null) ...[Icon(chipIcon, size: 14, color: chipFg), const SizedBox(width: 6)],
                Flexible(
                  child: Text(chipText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: chipFg)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(v.amountLabel, style: TextStyle(fontSize: 12.5, color: heroMuted)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: v.amountValue == null
                ? Text(v.amountText, style: amountStyle)
                : FxProgress(
                    value: v.amountValue!,
                    builder: (_, x) => Text(v.amountFormat!(x), style: amountStyle),
                  ),
          ),
          if (v.sub != null) ...[
            const SizedBox(height: 2),
            Text(v.sub!, style: TextStyle(fontSize: 12.5, color: heroMuted)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text(v.barLeft, style: TextStyle(fontSize: 12, color: heroMuted))),
              const SizedBox(width: 8),
              Text(v.barRight, style: TextStyle(fontSize: 12, color: heroMuted)),
            ],
          ),
          const SizedBox(height: 6),
          FxBar(
            value: v.need > 0 ? v.have / v.need : 0,
            height: 10,
            color: reached ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
            track: overlay.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: overlay.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('วิธีคิดทีละขั้น', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: heroText)),
                for (var i = 0; i < v.steps.length; i++) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: overlay.withValues(alpha: 0.18), shape: BoxShape.circle),
                        child: Text('${i + 1}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: heroText)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.steps[i].$1,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: heroText)),
                            const SizedBox(height: 1),
                            Text(v.steps[i].$2, style: TextStyle(fontSize: 12, height: 1.4, color: heroMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceNote(AppThemeModel theme) {
    final style = TextStyle(fontSize: 12, height: 1.45, color: theme.textSecondaryColor);
    return Column(
      children: [
        Text(
          'ราคาอ้างอิง: ทองคำแท่ง ${_money(_goldBarPrice)}/บาท • ทองรูปพรรณ ${_money(_goldOrnamentPrice)}/บาท • แร่เงิน ${_money(_silverPerGram)}/กรัม',
          textAlign: TextAlign.center,
          style: style,
        ),
        if (_goldUpdated.isNotEmpty) Text(_goldUpdated, textAlign: TextAlign.center, style: style),
        TextButton.icon(
          onPressed: _loadingPrices ? null : _fetchPrices,
          style: TextButton.styleFrom(minimumSize: const Size(44, 44), foregroundColor: _ink),
          icon: _loadingPrices
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('อัปเดตราคา', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildRecipientsCard(AppThemeModel theme, bool isDark) {
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
    return Container(
      decoration: _cardDeco(theme, isDark),
      clipBehavior: Clip.antiAlias,
      // ExpansionTile needs a Material between it and the coloured card for its ink.
      child: Material(
        type: MaterialType.transparency,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Icon(Icons.volunteer_activism_outlined, color: _ink),
            title: Text('ผู้มีสิทธิ์รับซากาต 8 กลุ่ม',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textColor)),
            subtitle: Text('الأصناف الثمانية • อัต-เตาบะฮ์ 9:60',
                style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
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
                            Text(groups[i].$3, style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlossary(AppThemeModel theme, bool isDark) {
    const words = [
      ('นิศอบ', 'نصاب', 'ปริมาณขั้นต่ำที่ทำให้ต้องจ่ายซากาต'),
      ('เฮาล์', 'حول', 'ครบรอบ 1 ปีจันทรคติ (ฮิจญ์เราะฮ์)'),
      ('รุบุอุลอุชร', 'ربع العشر', '1 ใน 40 = 2.5%'),
      ('อัล-อุชร', 'العشر', '1 ใน 10 = 10% (ผลผลิตน้ำฝน)'),
      ('วาญิบ', 'واجب', 'จำเป็นต้องปฏิบัติ'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(theme, isDark),
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
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: _ink)),
                TextSpan(text: w.$3, style: TextStyle(fontSize: 12.5, color: theme.textSecondaryColor)),
              ])),
            ),
          const SizedBox(height: 4),
          Text(
            'อ้างอิง: อัล-บะเกาะเราะฮ์ 2:267, อัต-เตาบะฮ์ 9:60 • หะดีษอัล-บุคอรีย์ว่าด้วยซากาตผลผลิตและปศุสัตว์ (จดหมายของท่านอบูบักร) • ใช้เพื่อประมาณการเบื้องต้น ควรสอบถามอิหม่ามหรือคณะกรรมการอิสลามในพื้นที่',
            style: TextStyle(fontSize: 12, height: 1.45, color: theme.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  /// Amount to record as an expense, or null when the zakat is paid in kind.
  (bool due, String label, double? amount, String note) get _payment {
    switch (_category) {
      case ZakatCategory.wealth:
        return (_wealthDue, _money(_wealthZakat), _wealthZakat, 'จ่ายซากาตทรัพย์สิน (زكاة المال)');
      case ZakatCategory.gold:
        final metal = _silverMetal ? 'แร่เงิน' : 'ทองคำ';
        return (_goldDue, _money(_goldZakat), _goldZakat, 'จ่ายซากาต$metal ${_goldGrams.toStringAsFixed(2)} กรัม');
      case ZakatCategory.agriculture:
        final price = _p(_cropPriceCtrl);
        final kg = '${FormatUtils.formatCurrency(_cropZakatKg)} กก.';
        return (_cropDue, kg, price > 0 ? _cropZakatKg * price : null, 'จ่ายซากาตผลผลิต $kg');
      case ZakatCategory.livestock:
        final r = ZakatEngine.livestock(_livestock, _p(_animalCtrl).toInt());
        final due = r.due && _hawlPassed;
        return (due, due ? r.summary : 'ไม่ต้องจ่าย', null, 'จ่ายซากาตปศุสัตว์: ${r.summary}');
    }
  }

  void _recordPayment() {
    final pay = _payment;
    if (!pay.$1) return;
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          controller: widget.controller,
          initialAmount: pay.$3,
          initialNote: pay.$4,
          initialType: TransactionType.expense,
        ),
      ),
    );
  }

  Widget _buildBottomBar(AppThemeModel theme, _ZView view) {
    final pay = _payment;
    final money = _category == ZakatCategory.wealth || _category == ZakatCategory.gold;
    final label = pay.$1 ? (money ? 'บันทึกเป็นรายจ่าย' : 'บันทึกการจ่ายซากาต') : 'ยังไม่ต้องจ่าย';
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(top: BorderSide(color: theme.borderColor)),
      ),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ซากาตที่ต้องจ่าย', style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(view.amountText,
                      maxLines: 1,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _ink)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: pay.$1 ? _recordPayment : null,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: theme.borderColor,
                  disabledForegroundColor: theme.textSecondaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Text(label, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _stepAnimals(int d) {
    HapticFeedback.selectionClick();
    final n = (_p(_animalCtrl).toInt() + d).clamp(0, 100000);
    setState(() => _animalCtrl.text = '$n');
  }

  Widget _stepButton(AppThemeModel theme, IconData icon, bool primary, VoidCallback onTap, String label) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: primary ? theme.primaryColor : _tint(theme, 0.12),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(icon, size: 28, color: primary ? Colors.white : _ink),
          ),
        ),
      ),
    );
  }

  Widget _softButton(AppThemeModel theme, String label, VoidCallback onTap) {
    return Material(
      color: _tint(theme, 0.14),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36, minWidth: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _ink)),
          ),
        ),
      ),
    );
  }

  Widget _quickChips(AppThemeModel theme, TextEditingController c, List<num> values, String unit) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          Builder(builder: (context) {
            final on = _p(c) == v;
            return Material(
              color: on ? theme.primaryColor : theme.cardBackground,
              shape: StadiumBorder(side: on ? BorderSide.none : BorderSide(color: theme.borderColor)),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => c.text = '$v');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(
                    '${FormatUtils.formatCurrency(v.toDouble()).replaceAll('.00', '')} $unit',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                      color: on ? Colors.white : theme.textSecondaryColor,
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _radioTile(AppThemeModel theme, String title, String sub, String trailing, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 48),
          padding: EdgeInsets.symmetric(horizontal: selected ? 11 : 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _tint(theme, 0.06) : theme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? _ink : theme.borderColor, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? theme.primaryColor : theme.cardBackground,
                  border: Border.all(color: _ink, width: 2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textColor)),
                    Text(sub, style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
                  ],
                ),
              ),
              Text(trailing, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _ink)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _checkRow(
    AppThemeModel theme, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onChanged(!value),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value ? _tint(theme, 0.08) : theme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: value ? theme.primaryColor : theme.cardBackground,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _ink, width: 2),
              ),
              child: value ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textColor)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, height: 1.35, color: theme.textSecondaryColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Small widgets ----------------
  Widget _pair(Widget a, Widget b) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: a),
        const SizedBox(width: 10),
        Expanded(child: b),
      ]);

  InputDecoration _inputDeco(AppThemeModel theme, {double radius = 12, double vertical = 13, Color? border}) {
    final b = border ?? theme.borderColor;
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: theme.cardBackground,
      hintStyle: TextStyle(color: theme.textSecondaryColor.withValues(alpha: 0.5), fontWeight: FontWeight.normal),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: vertical),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide(color: b, width: 1.5)),
      enabledBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide(color: b, width: 1.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius), borderSide: BorderSide(color: _ink, width: 1.5)),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    AppThemeModel theme, {
    String hint = '0',
    bool big = false,
    String? suffix,
    Widget? trailing,
    Color? labelColor,
    Color? borderColor,
  }) {
    final labelText = Text(label,
        style: TextStyle(
            fontSize: big ? 13 : 12.5, fontWeight: FontWeight.w600, color: labelColor ?? theme.textColor));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (trailing == null)
          labelText
        else
          Row(children: [Expanded(child: labelText), const SizedBox(width: 8), trailing]),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')), _GroupedNumberFormatter()],
          onChanged: (_) => setState(() {}),
          style: TextStyle(
            fontSize: big ? (suffix != null ? 22 : 20) : 16,
            fontWeight: big ? FontWeight.bold : FontWeight.w600,
            color: theme.textColor,
          ),
          decoration: _inputDeco(theme, radius: big ? 14 : 12, vertical: big ? 14 : 13, border: borderColor).copyWith(
            hintText: hint,
            suffixText: suffix,
            suffixStyle: TextStyle(fontSize: 14, color: theme.textSecondaryColor),
          ),
        ),
      ],
    );
  }

  Widget _segmented(AppThemeModel theme, List<(String, bool, VoidCallback)> options, {double height = 42}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: _tint(theme, 0.08), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  options[i].$3();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  constraints: BoxConstraints(minHeight: height),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: options[i].$2 ? theme.cardBackground : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: options[i].$2
                        ? const [BoxShadow(color: Color(0x240B2A27), blurRadius: 4, offset: Offset(0, 1))]
                        : null,
                  ),
                  child: Text(
                    options[i].$1,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: options[i].$2 ? FontWeight.w600 : FontWeight.w400,
                      color: options[i].$2 ? _ink : theme.textSecondaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniSegmented(AppThemeModel theme, List<(String, bool, VoidCallback)> options) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: _tint(theme, 0.08), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final o in options)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                o.$3();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                constraints: const BoxConstraints(minHeight: 36, minWidth: 44),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: o.$2 ? theme.cardBackground : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow:
                      o.$2 ? const [BoxShadow(color: Color(0x240B2A27), blurRadius: 4, offset: Offset(0, 1))] : null,
                ),
                child: Text(o.$1,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: o.$2 ? FontWeight.w600 : FontWeight.w400,
                      color: o.$2 ? _ink : theme.textSecondaryColor,
                    )),
              ),
            ),
        ],
      ),
    );
  }
}

/// Adds thousands separators while typing (1200000 -> 1,200,000); decimals are kept.
class _GroupedNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text.replaceAll(',', '');
    if (raw.isEmpty) return newValue.copyWith(text: '');
    final dot = raw.indexOf('.');
    final intPart = dot < 0 ? raw : raw.substring(0, dot);
    final rest = dot < 0 ? '' : raw.substring(dot).replaceAll(',', '');
    final b = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) b.write(',');
      b.write(intPart[i]);
    }
    final text = '$b$rest';
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
