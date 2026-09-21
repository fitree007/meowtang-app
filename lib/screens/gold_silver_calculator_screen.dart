import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../services/currency_exchange_service.dart';
import '../utils/format_utils.dart';
import '../widgets/tactile_button.dart';
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

  @override
  Widget build(BuildContext context) {
    final isDark = widget.controller.isDarkMode;
    final isEn = widget.controller.isEnglish;

    final bgColor = isDark ? MeowTheme.navyBackground : const Color(0xFFF8FAFC);
    final cardBg = isDark ? MeowTheme.navySurface : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? MeowTheme.borderColor : const Color(0xFFE2E8F0);

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
      const thaiMonths = [
        'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
        'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
      ];
      scrubbedDateText = '${scrubbedPoint.date.day} ${thaiMonths[scrubbedPoint.date.month - 1]} ${scrubbedPoint.date.year + 543}';
    } else {
      scrubbedDateText = isEn ? 'Today (Live)' : 'วันนี้ (ล่าสุด)';
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEn ? 'Gold & Silver Calculator' : 'คำนวณแร่ทอง & แร่เงิน',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart_outlined, color: Color(0xFFF59E0B)),
            tooltip: isEn ? 'Daily Price History' : 'ประวัติราคารายวัน',
            onPressed: () => _showHistorySheet(context),
          ),
          IconButton(
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded, color: Color(0xFFF59E0B)),
            tooltip: isEn ? 'Refresh Live Rates' : 'อัปเดตราคาล่าสุด',
            onPressed: _isLoading ? null : _refreshRates,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Asset Switcher
            Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildAssetTab(
                      index: 0,
                      title: isEn ? '🥇 Gold 96.5%' : '🥇 ทองคำ 96.5%',
                      isSelected: _selectedAsset == 0,
                      activeColor: const Color(0xFFF59E0B),
                      cardBg: cardBg,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                  Expanded(
                    child: _buildAssetTab(
                      index: 1,
                      title: isEn ? '🥈 Silver 99.9%' : '🥈 แร่เงิน 99.9%',
                      isSelected: _selectedAsset == 1,
                      activeColor: const Color(0xFF0284C7),
                      cardBg: cardBg,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Interactive Price Trend Chart Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isGold
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                      : const Color(0xFF0284C7).withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isGold ? const Color(0xFFF59E0B) : const Color(0xFF0284C7))
                        .withValues(alpha: isDark ? 0.15 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isGold
                                    ? (_goldType == 0 ? 'ราคาทองคำแท่ง' : 'ราคาทองรูปพรรณ')
                                    : 'ราคาแร่เงินบริสุทธิ์',
                                style: TextStyle(fontSize: 12.5, color: textSecondary, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (_scrubbedIndex >= 0)
                                      ? (isDark ? Colors.white12 : const Color(0xFFE2E8F0))
                                      : (isUpTrend
                                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                          : const Color(0xFFEF4444).withValues(alpha: 0.15)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  (_scrubbedIndex >= 0)
                                      ? '📅 $scrubbedDateText'
                                      : '${isUpTrend ? '+' : ''}${percentChange.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: (_scrubbedIndex >= 0)
                                        ? textPrimary
                                        : (isUpTrend ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '฿${FormatUtils.formatCurrency(displayScrubbedPrice)}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: isGold ? const Color(0xFFD97706) : const Color(0xFF0284C7),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isGold ? '/ บาททอง' : '/ กรัม',
                                style: TextStyle(fontSize: 11.5, color: textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        height: 30,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            _buildTimeframeBtn(7, '7D'),
                            _buildTimeframeBtn(15, '15D'),
                            _buildTimeframeBtn(30, '1M'),
                            _buildTimeframeBtn(90, '3M'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'ต่ำสุด: ฿${FormatUtils.formatCurrency(minPrice)}',
                            style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'สูงสุด: ฿${FormatUtils.formatCurrency(maxPrice)}',
                            style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => _showHistorySheet(context),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history_rounded, size: 12, color: isGold ? const Color(0xFFD97706) : const Color(0xFF0284C7)),
                              const SizedBox(width: 2),
                              Text(
                                isEn ? 'History' : 'ประวัติรายวัน',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: isGold ? const Color(0xFFD97706) : const Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: GestureDetector(
                      onPanDown: (details) => _handleScrub(details.localPosition.dx, context, trendPoints.length),
                      onPanUpdate: (details) => _handleScrub(details.localPosition.dx, context, trendPoints.length),
                      onPanEnd: (_) => setState(() => _scrubbedIndex = -1),
                      child: CustomPaint(
                        painter: _InteractiveTrendPainter(
                          points: trendPoints,
                          lineColor: isUpTrend
                              ? (isGold ? const Color(0xFFD97706) : const Color(0xFF0284C7))
                              : const Color(0xFFEF4444),
                          selectedIndex: _scrubbedIndex,
                          isUpTrend: isUpTrend,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      isEn
                          ? 'Tap or drag on chart to inspect daily price history'
                          : 'แตะหรือลากนิ้วบนกราฟเพื่อดูราคาย้อนหลังรายวัน',
                      style: TextStyle(fontSize: 10, color: textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Controls
            if (isGold) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildTypeRadio(
                      title: isEn ? 'Gold Bar' : 'ทองคำแท่ง 96.5%',
                      isSelected: _goldType == 0,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _goldType = 0);
                        _loadHistoryData();
                      },
                      activeColor: const Color(0xFFF59E0B),
                      cardBg: cardBg,
                      textPrimary: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTypeRadio(
                      title: isEn ? 'Gold Ornament' : 'ทองรูปพรรณ 96.5%',
                      isSelected: _goldType == 1,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _goldType = 1);
                        _loadHistoryData();
                      },
                      activeColor: const Color(0xFFF59E0B),
                      cardBg: cardBg,
                      textPrimary: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            Text(
              isGold
                  ? (isEn ? 'Quick Gold Weights' : 'น้ำหนักมาตรฐานไทย (เลือกด่วน)')
                  : (isEn ? 'Quick Silver Weights' : 'น้ำหนักแร่เงิน (เลือกด่วน)'),
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: isGold
                  ? [
                      _buildPresetChip('1 สลึง', 0.25, isSelected: _unitMode == 0 && _weightValue == 0.25),
                      _buildPresetChip('2 สลึง (50 สต.)', 0.50, isSelected: _unitMode == 0 && _weightValue == 0.50),
                      _buildPresetChip('1 บาททอง', 1.0, isSelected: _unitMode == 0 && _weightValue == 1.0),
                      _buildPresetChip('2 บาททอง', 2.0, isSelected: _unitMode == 0 && _weightValue == 2.0),
                      _buildPresetChip('5 บาททอง', 5.0, isSelected: _unitMode == 0 && _weightValue == 5.0),
                      _buildPresetChip('10 บาททอง', 10.0, isSelected: _unitMode == 0 && _weightValue == 10.0),
                    ]
                  : [
                      _buildSilverPresetChip('10 กรัม', 10.0, isSelected: _unitMode == 1 && _weightValue == 10.0),
                      _buildSilverPresetChip('50 กรัม', 50.0, isSelected: _unitMode == 1 && _weightValue == 50.0),
                      _buildSilverPresetChip('100 กรัม', 100.0, isSelected: _unitMode == 1 && _weightValue == 100.0),
                      _buildSilverPresetChip('500 กรัม', 500.0, isSelected: _unitMode == 1 && _weightValue == 500.0),
                      _buildSilverPresetChip('1 กิโลกรัม (1,000g)', 1000.0, isSelected: _unitMode == 1 && _weightValue == 1000.0),
                      _buildSilverPresetChip('1 บาทน้ำหนัก (15.24g)', 15.244, isSelected: _unitMode == 1 && (_weightValue - 15.244).abs() < 0.01),
                    ],
            ),
            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: TextField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: isEn ? 'Weight / Amount' : 'ระบุน้ำหนักที่ต้องการคำนวณ',
                        labelStyle: TextStyle(fontSize: 12, color: textSecondary),
                        hintText: '1.0',
                      ),
                      onChanged: _onAmountChanged,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 58,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _unitMode = 0);
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _unitMode == 0 ? cardBg : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Text(
                                'บาท',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: _unitMode == 0 ? FontWeight.bold : FontWeight.w500,
                                  color: _unitMode == 0 ? textPrimary : textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _unitMode = 1);
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _unitMode == 1 ? cardBg : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Text(
                                'กรัม',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: _unitMode == 1 ? FontWeight.bold : FontWeight.w500,
                                  color: _unitMode == 1 ? textPrimary : textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (isGold && _goldType == 1) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: TextField(
                  controller: _craftingFeeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: textPrimary),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    labelText: isEn ? 'Crafting Fee (THB/Baht weight)' : 'ค่ากำเหน็จต่อบาททอง (บาท)',
                    labelStyle: TextStyle(fontSize: 12, color: textSecondary),
                    hintText: '800',
                  ),
                  onChanged: _onCraftingFeeChanged,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // 4. Results Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isGold
                      ? [
                          const Color(0xFFFFFBEB),
                          isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
                        ]
                      : [
                          const Color(0xFFF0F9FF),
                          isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE),
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isGold
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                      : const Color(0xFF0284C7).withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEn ? 'Estimated Market Value' : 'มูลค่าขายออก (ซื้อทอง/เงิน)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isGold ? const Color(0xFFB45309) : const Color(0xFF0369A1),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isGold ? const Color(0xFFF59E0B) : const Color(0xFF0284C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isGold ? 'ทอง 96.5%' : 'เงิน 99.9%',
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '฿${FormatUtils.formatCurrency(totalSellPrice)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isGold ? const Color(0xFFD97706) : const Color(0xFF0284C7),
                      ),
                    ),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ราคารับซื้อคืน (ขายคืนร้าน)', style: TextStyle(fontSize: 11.5, color: textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            '฿${FormatUtils.formatCurrency(totalBuyPrice)}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('ส่วนต่างราคา (Spread)', style: TextStyle(fontSize: 11.5, color: textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            '฿${FormatUtils.formatCurrency(spread.abs())}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.amberAccent : const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Action Buttons
            Row(
              children: [
                Expanded(
                  child: TactileButton(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddTransactionScreen(
                            controller: widget.controller,
                            initialAmount: totalSellPrice,
                            initialNote: isGold
                                ? 'ซื้อทองคำ (${_weightController.text} ${_unitMode == 0 ? 'บาท' : 'กรัม'})'
                                : 'ซื้อแร่เงิน (${_weightController.text} กรัม)',
                            initialType: TransactionType.expense,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isGold ? const Color(0xFFF59E0B) : const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (isGold ? const Color(0xFFF59E0B) : const Color(0xFF0284C7))
                                .withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            isEn ? 'Record Asset Expense' : 'บันทึกเป็นรายการซื้อ',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TactileButton(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Clipboard.setData(ClipboardData(text: totalSellPrice.toStringAsFixed(2)));
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('คัดลอกยอด ฿${FormatUtils.formatCurrency(totalSellPrice)} แล้ว!'),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Icon(Icons.copy_rounded, color: textPrimary, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleScrub(double localX, BuildContext context, int pointsCount) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final totalWidth = box.size.width - 32;
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
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? MeowTheme.navySurface : Colors.white;
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

  Widget _buildAssetTab({
    required int index,
    required String title,
    required bool isSelected,
    required Color activeColor,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedAsset = index;
          _unitMode = index == 0 ? 0 : 1;
          _weightValue = index == 0 ? 1.0 : 100.0;
          _weightController.text = _weightValue.toString().replaceAll(RegExp(r'\.0$'), '');
          _scrubbedIndex = -1;
        });
        _loadHistoryData();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? cardBg : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? activeColor : textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeframeBtn(int days, String label) {
    final isSelected = _chartDays == days;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _chartDays = days;
          _scrubbedIndex = -1;
        });
        _loadHistoryData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF59E0B) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeRadio({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required Color activeColor,
    required Color cardBg,
    required Color textPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? activeColor : Colors.grey,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, double bahtAmount, {required bool isSelected}) {
    return GestureDetector(
      onTap: () => _setGoldPreset(bahtAmount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFF59E0B).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: isSelected ? 1.0 : 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFFB45309),
          ),
        ),
      ),
    );
  }

  Widget _buildSilverPresetChip(String label, double gramAmount, {required bool isSelected}) {
    return GestureDetector(
      onTap: () => _setSilverPreset(gramAmount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF0284C7).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: isSelected ? 1.0 : 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF0369A1),
          ),
        ),
      ),
    );
  }
}

class _InteractiveTrendPainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;
  final int selectedIndex;
  final bool isUpTrend;

  _InteractiveTrendPainter({
    required this.points,
    required this.lineColor,
    required this.selectedIndex,
    required this.isUpTrend,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final minVal = points.reduce(math.min);
    final maxVal = points.reduce(math.max);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final double paddingY = size.height * 0.12;
    final double drawHeight = size.height - (paddingY * 2);
    final double stepX = size.width / (points.length - 1);

    final offsets = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final normY = (points[i] - minVal) / range;
      final x = i * stepX;
      final y = size.height - paddingY - (normY * drawHeight);
      offsets.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(offsets[0].dx, offsets[0].dy);

    for (int i = 0; i < offsets.length - 1; i++) {
      final p0 = offsets[i];
      final p1 = offsets[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.28),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    final activeIndex = selectedIndex >= 0 ? selectedIndex : (offsets.length - 1);
    final targetPoint = offsets[activeIndex];

    canvas.drawCircle(
      targetPoint,
      6.0,
      Paint()..color = lineColor.withValues(alpha: 0.35),
    );
    canvas.drawCircle(targetPoint, 4.0, Paint()..color = Colors.white);
    canvas.drawCircle(targetPoint, 2.4, Paint()..color = lineColor);

    if (selectedIndex >= 0) {
      final guidePaint = Paint()
        ..color = lineColor.withValues(alpha: 0.5)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(targetPoint.dx, 0), Offset(targetPoint.dx, size.height), guidePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _InteractiveTrendPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.lineColor != lineColor;
  }
}
