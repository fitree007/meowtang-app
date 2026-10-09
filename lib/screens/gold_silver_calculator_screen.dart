import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/app_theme_model.dart';
import '../services/currency_exchange_service.dart';
import '../utils/format_utils.dart';
import '../widgets/meow_fx.dart';
import '../models/transaction_item.dart';
import 'add_transaction_screen.dart';

class GoldSilverCalculatorScreen extends StatefulWidget {
  final ExpenseController controller;

  const GoldSilverCalculatorScreen({
    super.key,
    required this.controller,
  });

  @override
  State<GoldSilverCalculatorScreen> createState() => _GoldSilverCalculatorScreenState();
}

class _GoldSilverCalculatorScreenState extends State<GoldSilverCalculatorScreen> {
  // 0: Gold (ทองคำ 96.5%), 1: Silver (แร่เงิน 99.9%)
  int _selectedAsset = 0;

  // Gold options: 0 = Gold Bar (ทองคำแท่ง), 1 = Gold Ornament (ทองรูปพรรณ)
  int _goldType = 0;

  // Weight input controller
  final TextEditingController _weightController = TextEditingController(text: '1.0');
  double _weightValue = 1.0;

  // Unit mode: 0 = Baht weight (บาททอง), 1 = Grams (กรัม)
  int _unitMode = 0;

  // Optional Crafting fee (ค่ากำเหน็จ สำหรับทองรูปพรรณ)
  final TextEditingController _craftingFeeController = TextEditingController(text: '800');
  double _craftingFee = 800.0;

  // Chart Timeframe: 7, 15, 30, 90 days
  int _chartDays = 7;

  // Scrubber index on the interactive trend chart (-1 = not scrubbing, shows latest)
  int _scrubbedIndex = -1;

  List<DailyPricePoint> _dailyHistoryPoints = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshRates();
    _loadHistoryData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _craftingFeeController.dispose();
    super.dispose();
  }

  String get _currentAssetKey {
    if (_selectedAsset == 1) return 'silver';
    return _goldType == 1 ? 'gold_ornament' : 'gold_bar';
  }

  Future<void> _loadHistoryData() async {
    final points = await CurrencyExchangeService.getDailyAssetHistory(_currentAssetKey, _chartDays);
    if (mounted) {
      setState(() {
        _dailyHistoryPoints = points;
      });
    }
  }

  Future<void> _refreshRates() async {
    setState(() => _isLoading = true);
    await CurrencyExchangeService.fetchLatestRates();
    await _loadHistoryData();
    if (mounted) setState(() => _isLoading = false);
  }

  void _onAmountChanged(String val) {
    final parsed = double.tryParse(val.replaceAll(',', '')) ?? 0.0;
    setState(() => _weightValue = parsed);
  }

  void _onCraftingFeeChanged(String val) {
    final parsed = double.tryParse(val.replaceAll(',', '')) ?? 0.0;
    setState(() => _craftingFee = parsed);
  }

  // Preset gold weights (in Baht or grams)
  void _setGoldPreset(double bahtAmount) {
    HapticFeedback.selectionClick();
    setState(() {
      _unitMode = 0;
      _weightValue = bahtAmount;
      _weightController.text = bahtAmount.toString().replaceAll(RegExp(r'\.0$'), '');
    });
  }

  // Preset silver weights (in grams)
  void _setSilverPreset(double gramAmount) {
    HapticFeedback.selectionClick();
    setState(() {
      _unitMode = 1; // grams
      _weightValue = gramAmount;
      _weightController.text = gramAmount.toString().replaceAll(RegExp(r'\.0$'), '');
    });
  }

  /// Generate realistic historical trend data points based on live price
  List<double> _getTrendDataPoints(double currentPrice, int days) {
    // Seeded deterministically based on date and price
    final points = <double>[];
    final random = math.Random(currentPrice.toInt() + days);

    double walk = currentPrice * (days == 7 ? 0.985 : 0.965);
    points.add(walk);

    final step = days == 7 ? 7 : 15;
    for (int i = 1; i < step - 1; i++) {
      final change = (random.nextDouble() - 0.44) * (currentPrice * 0.009);
      walk += change;
      points.add(walk);
    }
    points.add(currentPrice); // End on current live price
    return points;
  }

  // ---- palette (gold / silver are semantic colours, page & cards follow the theme) ----
  bool get _isGold => _selectedAsset == 0;

  /// Deep colour used for the price hero card.
  Color get _heroColor => _isGold ? const Color(0xFF92400E) : const Color(0xFF475569);

  /// Accent for buttons, chips and borders.
  Color get _accent => _isGold ? const Color(0xFFB45309) : const Color(0xFF475569);

  /// Accent for text (lighter in dark mode so it stays readable).
  Color get _accentText {
    final dark = widget.controller.isDarkMode;
    if (_isGold) return dark ? const Color(0xFFF59E0B) : const Color(0xFF92400E);
    return dark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
  }

  String _baht(double v, {int decimals = 0}) {
    if (decimals == 0) return '฿${CurrencyFormat.format(v.roundToDouble(), trimZero: true)}';
    return '฿${CurrencyFormat.format(v)}';
  }

  String get _weightUnitLabel => _unitMode == 0 ? 'บาททอง' : 'กรัม';

  static const _thaiMonths = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
  ];

  String _shortDate(DateTime d) => '${d.day} ${_thaiMonths[d.month - 1]}';

  void _selectGoldType(int type) {
    HapticFeedback.selectionClick();
    setState(() => _goldType = type);
    _loadHistoryData();
  }

  void _selectAsset(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedAsset = index;
      _unitMode = index == 0 ? 0 : 1;
      _weightValue = index == 0 ? 1.0 : 100.0;
      _weightController.text = _weightValue.toString().replaceAll(RegExp(r'\.0$'), '');
      _scrubbedIndex = -1;
    });
    _loadHistoryData();
  }

  void _selectChartDays(int days) {
    HapticFeedback.selectionClick();
    setState(() {
      _chartDays = days;
      _scrubbedIndex = -1;
    });
    _loadHistoryData();
  }

  void _recordPurchase(double totalSellPrice) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          controller: widget.controller,
          initialAmount: totalSellPrice,
          initialNote: _isGold
              ? 'ซื้อทองคำ (${_weightController.text} ${_unitMode == 0 ? 'บาท' : 'กรัม'})'
              : 'ซื้อแร่เงิน (${_weightController.text} กรัม)',
          initialType: TransactionType.expense,
        ),
      ),
    );
  }

  void _copyTotal(double totalSellPrice) {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: totalSellPrice.toStringAsFixed(2)));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('คัดลอกยอด ฿${FormatUtils.formatCurrency(totalSellPrice)} แล้ว'),
        backgroundColor: const Color(0xFF047857),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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
    final track = Color.alphaBlend(_accent.withValues(alpha: isDark ? 0.22 : 0.12), cardBg);
    final softTile = Color.alphaBlend(textSecondary.withValues(alpha: isDark ? 0.14 : 0.08), cardBg);
    final warmTile = Color.alphaBlend(_accent.withValues(alpha: isDark ? 0.2 : 0.09), cardBg);

    // Live Prices
    final goldBarSell = CurrencyExchangeService.getGoldBarSellPrice();
    final goldBarBuy = CurrencyExchangeService.getGoldBarBuyPrice();
    final goldOrnamentSell = CurrencyExchangeService.getGoldOrnamentSellPrice();
    final goldOrnamentBuy = CurrencyExchangeService.getGoldOrnamentBuyPrice();
    final silverPricePerGram = CurrencyExchangeService.getSilverPricePerGram();

    // Active Asset calculation parameters
    final bool isGold = _selectedAsset == 0;
    final double baseSellPrice = isGold
        ? (_goldType == 0 ? goldBarSell : goldOrnamentSell)
        : silverPricePerGram;
    final double baseBuyPrice = isGold
        ? (_goldType == 0 ? goldBarBuy : goldOrnamentBuy)
        : (silverPricePerGram * 0.94); // Estimated silver scrap buyback

    // Convert weight into standard calculation units
    double effectiveWeightInStandardUnit;
    if (isGold) {
      if (_unitMode == 0) {
        effectiveWeightInStandardUnit = _weightValue; // in Baht
      } else {
        effectiveWeightInStandardUnit = _weightValue / 15.244; // grams to Baht
      }
    } else {
      if (_unitMode == 0) {
        effectiveWeightInStandardUnit = _weightValue * 15.244; // Baht to grams
      } else {
        effectiveWeightInStandardUnit = _weightValue; // in grams
      }
    }

    final double totalSellPrice = (effectiveWeightInStandardUnit * baseSellPrice) +
        (isGold && _goldType == 1 ? (_craftingFee * effectiveWeightInStandardUnit) : 0.0);
    final double totalBuyPrice = effectiveWeightInStandardUnit * baseBuyPrice;
    final double spread = totalSellPrice - totalBuyPrice;

    // Chart trend series from daily history points
    final List<double> trendPoints = _dailyHistoryPoints.isNotEmpty
        ? _dailyHistoryPoints.map((p) => p.sellPrice).toList()
        : _getTrendDataPoints(baseSellPrice, _chartDays);
    final minPrice = trendPoints.reduce(math.min);
    final maxPrice = trendPoints.reduce(math.max);
    final firstPrice = trendPoints.first;
    final lastPrice = trendPoints.last;
    final double priceDiff = lastPrice - firstPrice;
    final double percentChange = firstPrice > 0 ? (priceDiff / firstPrice) * 100.0 : 0.0;
    final bool isUpTrend = percentChange >= 0;

    final displayScrubbedPrice = (_scrubbedIndex >= 0 && _scrubbedIndex < trendPoints.length)
        ? trendPoints[_scrubbedIndex]
        : lastPrice;

    final DailyPricePoint? scrubbedPoint = (_scrubbedIndex >= 0 && _scrubbedIndex < _dailyHistoryPoints.length)
        ? _dailyHistoryPoints[_scrubbedIndex]
        : null;

    final String scrubbedDateText;
    if (scrubbedPoint != null) {
      scrubbedDateText = '${scrubbedPoint.date.day} ${_thaiMonths[scrubbedPoint.date.month - 1]} ${scrubbedPoint.date.year + 543}';
    } else {
      scrubbedDateText = isEn ? 'Today (Live)' : 'วันนี้ (ล่าสุด)';
    }

    final chartDecimals = isGold ? 0 : 2;
    final rangeName = const {7: '7 วัน', 15: '15 วัน', 30: '1 เดือน', 90: '3 เดือน'}[_chartDays] ?? '$_chartDays วัน';
    final assetName = isGold ? (_goldType == 0 ? 'ทองคำแท่ง' : 'ทองรูปพรรณ') : 'แร่เงิน 99.9%';
    final chartUnit = isGold ? '$assetName ขายออก/บาท • $rangeName' : '$assetName /กรัม • $rangeName';
    final changeColor = isUpTrend
        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF047857))
        : (isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C));
    final changeText =
        '${isUpTrend ? '▲' : '▼'} ${_baht(priceDiff.abs(), decimals: chartDecimals)} (${isUpTrend ? '+' : '−'}${percentChange.abs().toStringAsFixed(1)}%)';

    final List<String> dateLabels;
    if (_dailyHistoryPoints.length >= 2) {
      final pts = _dailyHistoryPoints;
      dateLabels = [_shortDate(pts.first.date), _shortDate(pts[pts.length ~/ 2].date), 'วันนี้'];
    } else {
      dateLabels = ['$rangeNameก่อน', '', 'วันนี้'];
    }

    final updateMatch = RegExp(r'(\d{1,2}[:.]\d{2})').firstMatch(CurrencyExchangeService.getGoldLastUpdatedText());
    final updateTime = updateMatch != null ? '${updateMatch.group(1)} น.' : '';

    final bottomLabel = isGold
        ? '${_goldType == 0 ? 'ทองแท่ง' : 'ทองรูปพรรณ'} ${_weightController.text} ${_unitMode == 0 ? 'บาท' : 'กรัม'}'
        : 'แร่เงิน ${_weightController.text} ${_unitMode == 0 ? 'บาท' : 'กรัม'}';

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 10, 8, 10),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left_rounded, color: textPrimary, size: 28),
                  tooltip: 'ย้อนกลับ',
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    isEn ? 'Gold & Silver Calculator' : 'คำนวณแร่ทอง & แร่เงิน',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.history_rounded, color: textPrimary, size: 22),
                  tooltip: isEn ? 'Daily Price History' : 'ประวัติราคารายวัน',
                  onPressed: () => _showHistorySheet(context),
                ),
                IconButton(
                  icon: _isLoading
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _accentText))
                      : Icon(Icons.refresh_rounded, color: textPrimary, size: 22),
                  tooltip: isEn ? 'Refresh Live Rates' : 'อัปเดตราคาล่าสุด',
                  onPressed: _isLoading ? null : _refreshRates,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // 1. Asset segmented control
                _Segmented(
                  labels: [isEn ? 'Gold 96.5%' : 'ทองคำ 96.5%', isEn ? 'Silver 99.9%' : 'แร่เงิน 99.9%'],
                  selected: _selectedAsset,
                  onSelect: _selectAsset,
                  track: track,
                  thumb: cardBg,
                  activeText: _accentText,
                  inactiveText: textSecondary,
                  height: 42,
                  fontSize: 14,
                  radius: 14,
                  expand: true,
                ),
                const SizedBox(height: 16),

                // 2. Today's price hero
                FxFadeUp(
                  index: 0,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: _heroColor, borderRadius: BorderRadius.circular(22)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                isGold ? 'ราคาวันนี้ • สมาคมค้าทองคำ' : 'ราคาวันนี้ • แร่เงิน 99.9%',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ),
                            if (updateTime.isNotEmpty)
                              Text(updateTime, style: TextStyle(fontSize: 12, color: isGold ? const Color(0xFFFDE7C2) : const Color(0xFFE2E8F0))),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (isGold)
                          Row(
                            children: [
                              Expanded(
                                child: _HeroPriceTile(
                                  title: 'ทองคำแท่ง',
                                  sell: _baht(goldBarSell),
                                  buy: _baht(goldBarBuy),
                                  selected: _goldType == 0,
                                  onTap: () => _selectGoldType(0),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _HeroPriceTile(
                                  title: 'ทองรูปพรรณ',
                                  sell: _baht(goldOrnamentSell),
                                  buy: _baht(goldOrnamentBuy),
                                  selected: _goldType == 1,
                                  onTap: () => _selectGoldType(1),
                                ),
                              ),
                            ],
                          )
                        else
                          _HeroPriceTile(
                            title: 'โลหะเงินบริสุทธิ์ /กรัม',
                            sell: _baht(silverPricePerGram, decimals: 2),
                            buy: _baht(silverPricePerGram * 0.94, decimals: 2),
                            buyLabel: 'รับซื้อ (ประมาณ)',
                            mutedColor: const Color(0xFFE2E8F0),
                            selected: true,
                            onTap: null,
                          ),
                        if (isGold) ...[
                          const SizedBox(height: 10),
                          const Text(
                            'แตะการ์ดเพื่อเลือกชนิดทองที่ใช้คำนวณ',
                            style: TextStyle(fontSize: 12, color: Color(0xFFFDE7C2)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Weight card
                FxFadeUp(
                  index: 1,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(cardBg, borderColor, isDark),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'ระบุน้ำหนัก',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                              ),
                            ),
                            _Segmented(
                              labels: const ['บาททอง', 'กรัม'],
                              selected: _unitMode,
                              onSelect: (i) {
                                HapticFeedback.selectionClick();
                                setState(() => _unitMode = i);
                              },
                              track: softTile,
                              thumb: cardBg,
                              activeText: _accentText,
                              inactiveText: textSecondary,
                              height: 38,
                              fontSize: 12.5,
                              radius: 10,
                              expand: false,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          constraints: const BoxConstraints(minHeight: 56),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _accent, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _weightController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    hintText: '1.0',
                                    hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
                                  ),
                                  onChanged: _onAmountChanged,
                                ),
                              ),
                              Text(_weightUnitLabel, style: TextStyle(fontSize: 14, color: textSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: isGold
                              ? [
                                  for (final p in const [
                                    ['1 สลึง', 0.25],
                                    ['2 สลึง', 0.50],
                                    ['1 บาท', 1.0],
                                    ['2 บาท', 2.0],
                                    ['5 บาท', 5.0],
                                    ['10 บาท', 10.0],
                                  ])
                                    _PresetChip(
                                      label: p[0] as String,
                                      selected: _unitMode == 0 && _weightValue == (p[1] as double),
                                      accent: _accent,
                                      theme: theme,
                                      onTap: () => _setGoldPreset(p[1] as double),
                                    ),
                                ]
                              : [
                                  for (final p in const [
                                    ['10 กรัม', 10.0],
                                    ['50 กรัม', 50.0],
                                    ['100 กรัม', 100.0],
                                    ['500 กรัม', 500.0],
                                    ['1 กิโลกรัม', 1000.0],
                                  ])
                                    _PresetChip(
                                      label: p[0] as String,
                                      selected: _unitMode == 1 && _weightValue == (p[1] as double),
                                      accent: _accent,
                                      theme: theme,
                                      onTap: () => _setSilverPreset(p[1] as double),
                                    ),
                                  _PresetChip(
                                    label: '1 บาท (15.24 ก.)',
                                    selected: _unitMode == 1 && (_weightValue - 15.244).abs() < 0.01,
                                    accent: _accent,
                                    theme: theme,
                                    onTap: () => _setSilverPreset(15.244),
                                  ),
                                ],
                        ),
                        if (isGold && _goldType == 1) ...[
                          const SizedBox(height: 12),
                          Container(
                            constraints: const BoxConstraints(minHeight: 48),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Text('ค่ากำเหน็จ/บาท', style: TextStyle(fontSize: 13, color: textSecondary)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _craftingFeeController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      hintText: '800',
                                    ),
                                    onChanged: _onCraftingFeeChanged,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text('บาท', style: TextStyle(fontSize: 13, color: textSecondary)),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _ResultTile(
                                label: isGold ? 'ซื้อ$assetName' : 'ซื้อแร่เงิน',
                                value: totalSellPrice,
                                format: (v) => _baht(v, decimals: isGold ? 0 : 2),
                                background: warmTile,
                                labelColor: _accentText,
                                valueColor: isDark ? _accentText : (isGold ? const Color(0xFF7A2E0B) : const Color(0xFF1E293B)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ResultTile(
                                label: 'ขายคืนร้าน',
                                value: totalBuyPrice,
                                format: (v) => _baht(v, decimals: isGold ? 0 : 2),
                                background: softTile,
                                labelColor: textSecondary,
                                valueColor: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ส่วนต่างซื้อ–ขายคืน ${_baht(spread.abs(), decimals: isGold ? 0 : 2)}',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                        if (isGold && _goldType == 0)
                          Text(
                            'ทองรูปพรรณ: ระบุค่ากำเหน็จต่อบาทเพิ่มได้',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Price chart card
                FxFadeUp(
                  index: 2,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(cardBg, borderColor, isDark),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'กราฟราคา',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: _accentText,
                                minimumSize: const Size(44, 44),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onPressed: () => _showHistorySheet(context),
                              icon: const Icon(Icons.history_rounded, size: 18),
                              label: Text(
                                isEn ? 'History' : 'ประวัติรายวัน',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _Segmented(
                          labels: const ['7 วัน', '15 วัน', '1 เดือน', '3 เดือน'],
                          selected: const [7, 15, 30, 90].indexOf(_chartDays),
                          onSelect: (i) => _selectChartDays(const [7, 15, 30, 90][i]),
                          track: softTile,
                          thumb: cardBg,
                          activeText: _accentText,
                          inactiveText: textSecondary,
                          height: 40,
                          fontSize: 12.5,
                          radius: 12,
                          expand: true,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _scrubbedIndex >= 0 ? scrubbedDateText : chartUnit,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: textSecondary),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _baht(displayScrubbedPrice, decimals: chartDecimals),
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                changeText,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: changeColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: LayoutBuilder(
                            builder: (context, box) => GestureDetector(
                              onPanDown: (details) => _handleScrub(details.localPosition.dx, box.maxWidth, trendPoints.length),
                              onPanUpdate: (details) => _handleScrub(details.localPosition.dx, box.maxWidth, trendPoints.length),
                              onPanEnd: (_) => setState(() => _scrubbedIndex = -1),
                              onPanCancel: () => setState(() => _scrubbedIndex = -1),
                              child: FxProgress(
                                key: ValueKey('$_currentAssetKey-$_chartDays'),
                                value: 1,
                                duration: const Duration(milliseconds: 1000),
                                builder: (_, t) => CustomPaint(
                                  size: Size(box.maxWidth, 120),
                                  painter: _InteractiveTrendPainter(
                                    points: trendPoints,
                                    lineColor: isUpTrend ? _accent : const Color(0xFFB91C1C),
                                    dotColor: isDark && isUpTrend ? _accentText : (isUpTrend ? _accent : const Color(0xFFB91C1C)),
                                    gridColor: borderColor,
                                    selectedIndex: _scrubbedIndex,
                                    progress: t,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (final l in dateLabels) Text(l, style: TextStyle(fontSize: 12, color: textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _MinMaxTile(label: 'ต่ำสุดช่วงนี้', value: _baht(minPrice, decimals: chartDecimals), background: softTile, theme: theme)),
                            const SizedBox(width: 8),
                            Expanded(child: _MinMaxTile(label: 'สูงสุดช่วงนี้', value: _baht(maxPrice, decimals: chartDecimals), background: softTile, theme: theme)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isEn
                              ? 'Tap or drag on chart to inspect daily price history'
                              : 'แตะหรือลากนิ้วบนกราฟเพื่อดูราคาย้อนหลังรายวัน',
                          style: TextStyle(fontSize: 12, color: textSecondary),
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
                      Text(
                        bottomLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: FxProgress(
                          value: totalSellPrice,
                          builder: (_, v) => Text(
                            _baht(v, decimals: isGold ? 0 : 2),
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: isDark ? _accentText : (isGold ? const Color(0xFF7A2E0B) : const Color(0xFF1E293B)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'คัดลอกยอด',
                  onPressed: () => _copyTotal(totalSellPrice),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(Icons.copy_rounded, size: 20, color: textPrimary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FxPress(
                    onTap: () => _recordPurchase(totalSellPrice),
                    child: Container(
                      height: 56,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(18)),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isEn ? 'Record purchase' : 'บันทึกรายการซื้อ',
                          style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w600),
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

  BoxDecoration _cardDecoration(Color cardBg, Color borderColor, bool isDark) {
    return BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(20),
      border: isDark ? Border.all(color: borderColor) : null,
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1F1A10).withValues(alpha: isDark ? 0.2 : 0.06),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  void _handleScrub(double localX, double totalWidth, int pointsCount) {
    if (totalWidth <= 0 || pointsCount < 2) return;

    final stepX = totalWidth / (pointsCount - 1);
    final index = (localX / stepX).round().clamp(0, pointsCount - 1);

    if (index != _scrubbedIndex) {
      HapticFeedback.selectionClick();
      setState(() => _scrubbedIndex = index);
    }
  }

  void _showHistorySheet(BuildContext context) {
    HapticFeedback.lightImpact();
    final isDark = widget.controller.isDarkMode;
    final isEn = widget.controller.isEnglish;
    final textPrimary = widget.controller.currentTheme.textColor;
    final textSecondary = widget.controller.currentTheme.textSecondaryColor;
    final cardBg = widget.controller.currentTheme.cardBackground;
    final isGold = _selectedAsset == 0;

    final String assetName = isGold
        ? (_goldType == 0 ? 'ทองคำแท่ง 96.5%' : 'ทองรูปพรรณ 96.5%')
        : 'แร่เงิน 99.9%';

    final reversedList = _dailyHistoryPoints.reversed.toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.72,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn ? 'Daily Price History' : 'ประวัติราคาปิดรายวัน',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        assetName,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      isEn ? 'Date' : 'วันที่',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textSecondary),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      isEn ? 'Sell Price' : 'ราคาขายออก',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textSecondary),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      isEn ? 'Buy Price' : 'ราคารับซื้อ',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            // Daily rows
            Expanded(
              child: reversedList.isEmpty
                  ? Center(
                      child: Text(
                        isEn ? 'No daily history recorded yet' : 'ยังไม่มีข้อมูลประวัติรายวัน',
                        style: TextStyle(color: textSecondary, fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      itemCount: reversedList.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                      ),
                      itemBuilder: (context, idx) {
                        final item = reversedList[idx];
                        final isToday = idx == 0;
                        const thaiMonths = [
                          'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
                          'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
                        ];
                        final dateStr = '${item.date.day} ${thaiMonths[item.date.month - 1]} ${item.date.year + 543}';

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                                        color: isToday
                                            ? (isGold ? const Color(0xFFD97706) : const Color(0xFF0284C7))
                                            : textPrimary,
                                      ),
                                    ),
                                    if (isToday) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'วันนี้',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  '฿${FormatUtils.formatCurrency(item.sellPrice)}',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isGold ? const Color(0xFFD97706) : const Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  '฿${FormatUtils.formatCurrency(item.buyPrice)}',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill segmented control (track + raised white thumb), as on the board.
class _Segmented extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;
  final Color track;
  final Color thumb;
  final Color activeText;
  final Color inactiveText;
  final double height;
  final double fontSize;
  final double radius;
  final bool expand;

  const _Segmented({
    required this.labels,
    required this.selected,
    required this.onSelect,
    required this.track,
    required this.thumb,
    required this.activeText,
    required this.inactiveText,
    required this.height,
    required this.fontSize,
    required this.radius,
    required this.expand,
  });

  @override
  Widget build(BuildContext context) {
    Widget seg(int i) {
      final on = i == selected;
      final child = Semantics(
        button: true,
        selected: on,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: height,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: expand ? 2 : 12),
            decoration: BoxDecoration(
              color: on ? thumb : Colors.transparent,
              borderRadius: BorderRadius.circular(radius - 3),
              boxShadow: on
                  ? [BoxShadow(color: const Color(0xFF1F1A10).withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 1))]
                  : null,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                labels[i],
                maxLines: 1,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                  color: on ? activeText : inactiveText,
                ),
              ),
            ),
          ),
        ),
      );
      return expand ? Expanded(child: child) : child;
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(radius)),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (int i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            seg(i),
          ],
        ],
      ),
    );
  }
}

class _HeroPriceTile extends StatelessWidget {
  final String title;
  final String sell;
  final String buy;
  final String buyLabel;
  final bool selected;
  final VoidCallback? onTap;

  const _HeroPriceTile({
    required this.title,
    required this.sell,
    required this.buy,
    required this.selected,
    required this.onTap,
    this.buyLabel = 'รับซื้อ',
    this.mutedColor = const Color(0xFFFDE7C2),
  });

  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(fontSize: 12, color: mutedColor);
    const strong = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white);
    Widget line(String l, String v) => Row(
          children: [
            Text(l, style: muted, maxLines: 1),
            const SizedBox(width: 6),
            Expanded(
              child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(v, style: strong)),
            ),
          ],
        );
    return Semantics(
      button: onTap != null,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: selected && onTap != null ? 0.22 : 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected && onTap != null ? Colors.white.withValues(alpha: 0.7) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 4),
              line('ขายออก', sell),
              const SizedBox(height: 4),
              line(buyLabel, buy),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final AppThemeModel theme;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FxPress(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? accent : theme.cardBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? accent : theme.borderColor),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? Colors.white : theme.textSecondaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final String label;
  final double value;
  final String Function(double) format;
  final Color background;
  final Color labelColor;
  final Color valueColor;

  const _ResultTile({
    required this.label,
    required this.value,
    required this.format,
    required this.background,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: labelColor)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: FxProgress(
              value: value,
              builder: (_, v) => Text(
                format(v),
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: valueColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MinMaxTile extends StatelessWidget {
  final String label;
  final String value;
  final Color background;
  final AppThemeModel theme;

  const _MinMaxTile({required this.label, required this.value, required this.background, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: theme.textColor)),
          ),
        ],
      ),
    );
  }
}

/// Line + area chart with 3 grid lines; [progress] 0..1 draws the line in (fx-draw).
class _InteractiveTrendPainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;
  final Color dotColor;
  final Color gridColor;
  final int selectedIndex;
  final double progress;

  _InteractiveTrendPainter({
    required this.points,
    required this.lineColor,
    required this.dotColor,
    required this.gridColor,
    required this.selectedIndex,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const top = 10.0;
    final bottom = size.height - 10;

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final y in [top, (top + bottom) / 2, bottom]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    if (points.length < 2) return;

    final minVal = points.reduce(math.min);
    final maxVal = points.reduce(math.max);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);
    final left = 4.0;
    final width = size.width - 10;
    final stepX = width / (points.length - 1);

    final offsets = <Offset>[
      for (int i = 0; i < points.length; i++)
        Offset(left + i * stepX, bottom - (points[i] - minVal) / range * (bottom - top)),
    ];

    final line = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final o in offsets.skip(1)) {
      line.lineTo(o.dx, o.dy);
    }

    final area = Path.from(line)
      ..lineTo(offsets.last.dx, bottom)
      ..lineTo(offsets.first.dx, bottom)
      ..close();
    canvas.drawPath(area, Paint()..color = lineColor.withValues(alpha: 0.12 * progress));

    final metric = line.computeMetrics().first;
    final drawn = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(
      drawn,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (progress < 1) return;

    final activeIndex = selectedIndex >= 0 ? selectedIndex : (offsets.length - 1);
    final target = offsets[activeIndex];
    if (selectedIndex >= 0) {
      canvas.drawLine(
        Offset(target.dx, 0),
        Offset(target.dx, size.height),
        Paint()
          ..color = lineColor.withValues(alpha: 0.5)
          ..strokeWidth = 1.2,
      );
    }
    canvas.drawCircle(target, 4.5, Paint()..color = dotColor);
  }

  @override
  bool shouldRepaint(covariant _InteractiveTrendPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.progress != progress ||
        oldDelegate.gridColor != gridColor;
  }
}
