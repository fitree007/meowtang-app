import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/app_theme_model.dart';
import '../theme/meow_theme.dart';
import '../services/currency_exchange_service.dart';
import '../utils/format_utils.dart';
import '../screens/currency_converter_screen.dart';

/// Custom Painter that draws a smooth cubic Bezier sparkline chart with gradient area
class SparklineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color lineColor;
  final bool isPositive;
  final bool showDots;

  SparklineChartPainter({
    required this.dataPoints,
    required this.lineColor,
    this.isPositive = true,
    this.showDots = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.length < 2) return;

    final minVal = dataPoints.reduce(math.min);
    final maxVal = dataPoints.reduce(math.max);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final double paddingY = size.height * 0.15;
    final double drawHeight = size.height - (paddingY * 2);
    final double stepX = size.width / (dataPoints.length - 1);

    final points = <Offset>[];
    for (int i = 0; i < dataPoints.length; i++) {
      final normY = (dataPoints[i] - minVal) / range;
      final x = i * stepX;
      final y = size.height - paddingY - (normY * drawHeight);
      points.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
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
          lineColor.withValues(alpha: 0.25),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    if (showDots) {
      final lastPoint = points.last;
      final dotBgPaint = Paint()..color = Colors.white;
      final dotPaint = Paint()..color = lineColor;

      canvas.drawCircle(lastPoint, 3.0, dotBgPaint);
      canvas.drawCircle(lastPoint, 1.8, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SparklineChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints || oldDelegate.lineColor != lineColor;
  }
}

/// A sleek Sparkline chart widget
class SparklineChartWidget extends StatelessWidget {
  final List<double> dataPoints;
  final Color color;
  final double height;
  final double width;

  const SparklineChartWidget({
    super.key,
    required this.dataPoints,
    required this.color,
    this.height = 24,
    this.width = 54,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: CustomPaint(
        painter: SparklineChartPainter(
          dataPoints: dataPoints,
          lineColor: color,
        ),
      ),
    );
  }
}

/// The Minimal Compact 3-in-1 Rates Dashboard for MeowPremiumScreen
class LiveRatesDashboardWidget extends StatefulWidget {
  final ExpenseController controller;

  const LiveRatesDashboardWidget({super.key, required this.controller});

  @override
  State<LiveRatesDashboardWidget> createState() => _LiveRatesDashboardWidgetState();
}

class _LiveRatesDashboardWidgetState extends State<LiveRatesDashboardWidget>
    with SingleTickerProviderStateMixin {
  int _activeSegment = 0; // 0: Gold 96.5%, 1: Silver 99.9%, 2: Currencies
  List<String> _selectedWatchlistKeys = ['usd', 'sar', 'kwd', 'myr', 'jpy', 'eur', 'sgd', 'cny', 'krw', 'aed'];
  bool _isLoading = false;
  late AnimationController _refreshAnimCtrl;

  @override
  void initState() {
    super.initState();
    _refreshAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _loadUserWatchlist();
  }

  @override
  void dispose() {
    _refreshAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserWatchlist() async {
    final keys = await CurrencyExchangeService.getUserWatchlist();
    if (mounted) {
      setState(() {
        _selectedWatchlistKeys = keys.where((k) => k != 'gold_bar' && k != 'gold_ornament' && k != 'silver').toList();
        if (_selectedWatchlistKeys.isEmpty) {
          _selectedWatchlistKeys = ['usd', 'sar', 'kwd', 'myr', 'jpy', 'eur', 'sgd'];
        }
      });
    }
  }

  Future<void> _refreshRates() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    _refreshAnimCtrl.repeat();

    await CurrencyExchangeService.fetchLatestRates();

    if (mounted) {
      _refreshAnimCtrl.stop();
      _refreshAnimCtrl.reset();
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('อัปเดตเรทเงินและราคาทองคำล่าสุดเรียบร้อย!'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showCustomizeDialog() {
    HapticFeedback.selectionClick();
    final isDark = widget.controller.isDarkMode;
    final currentTheme = widget.controller.currentTheme;
    final tempSelected = List<String>.from(_selectedWatchlistKeys);
    String searchQuery = '';

    final allCurrencies = CurrencyExchangeService.supportedCurrencies.values
        .where((c) => c.code != 'xau' && c.code != 'xag' && c.code != 'btc')
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = allCurrencies.where((c) {
              if (searchQuery.trim().isEmpty) return true;
              final q = searchQuery.toLowerCase().trim();
              return c.code.toLowerCase().contains(q) ||
                  c.nameTh.toLowerCase().contains(q) ||
                  c.nameEn.toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'เลือกสกุลเงินที่ต้องการแสดง',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: currentTheme.textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'เลือกแล้ว ${tempSelected.length} สกุลเงิน (รวมเรทไทย THB 🇹🇭)',
                              style: TextStyle(fontSize: 12, color: currentTheme.textSecondaryColor),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: TextField(
                      onChanged: (val) {
                        setModalState(() => searchQuery = val);
                      },
                      style: TextStyle(color: currentTheme.textColor, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'ค้นหาชื่อสกุลเงิน เช่น USD, SAR, ริงกิต, เยน...',
                        hintStyle: TextStyle(color: currentTheme.textSecondaryColor, fontSize: 12.5),
                        prefixIcon: Icon(Icons.search_rounded, color: currentTheme.textSecondaryColor, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: currentTheme.borderColor.withValues(alpha: 0.4)),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isSelected = tempSelected.contains(item.code);
                        final rateThb = CurrencyExchangeService.getRateToThb(item.code);

                        return CheckboxListTile(
                          dense: true,
                          activeColor: const Color(0xFF0284C7),
                          value: isSelected,
                          onChanged: (checked) {
                            HapticFeedback.selectionClick();
                            setModalState(() {
                              if (checked == true) {
                                if (!tempSelected.contains(item.code)) tempSelected.add(item.code);
                              } else {
                                if (tempSelected.length > 1) tempSelected.remove(item.code);
                              }
                            });
                          },
                          title: Row(
                            children: [
                              Text(item.flag, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Text(
                                item.code.toUpperCase(),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                              ),
                              const SizedBox(width: 4),
                              Text('(${item.nameTh})', style: TextStyle(fontSize: 11, color: currentTheme.textSecondaryColor)),
                            ],
                          ),
                          secondary: Text(
                            item.code == 'thb' ? '1.00 ฿' : '฿${rateThb > 0 ? FormatUtils.formatCurrency(rateThb) : '-'}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      border: Border(top: BorderSide(color: currentTheme.borderColor)),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        await CurrencyExchangeService.saveUserWatchlist(tempSelected);
                        if (mounted) {
                          setState(() {
                            _selectedWatchlistKeys = List.from(tempSelected);
                          });
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('บันทึกการปรับแต่ง', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.controller.isDarkMode;
    final currentTheme = widget.controller.currentTheme;

    // Gold Data
    final goldBarSell = CurrencyExchangeService.getGoldBarSellPrice();
    final goldBarBuy = CurrencyExchangeService.getGoldBarBuyPrice();
    final goldOrnamentSell = CurrencyExchangeService.getGoldOrnamentSellPrice();
    final goldOrnamentBuy = CurrencyExchangeService.getGoldOrnamentBuyPrice();

    // Silver Data
    final silverGramPrice = CurrencyExchangeService.getSilverPricePerGram();
    final silverBahtWeightPrice = silverGramPrice * 15.244;

    return Container(
      decoration: BoxDecoration(
        color: currentTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: currentTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Segmented Selector Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildSegmentTab(0, '🥇 ทอง 96.5%'),
                        _buildSegmentTab(1, '🥈 เงิน 99.9%'),
                        _buildSegmentTab(2, '💱 สกุลเงิน'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_activeSegment == 2) ...[
                  InkWell(
                    onTap: _showCustomizeDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.tune_rounded, size: 16, color: currentTheme.textColor),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                InkWell(
                  onTap: _isLoading ? null : _refreshRates,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: RotationTransition(
                      turns: _refreshAnimCtrl,
                      child: Icon(Icons.refresh_rounded, size: 16, color: currentTheme.textColor),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Tab Content Panel
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _buildActiveTabContent(
              goldBarSell: goldBarSell,
              goldBarBuy: goldBarBuy,
              goldOrnamentSell: goldOrnamentSell,
              goldOrnamentBuy: goldOrnamentBuy,
              silverGramPrice: silverGramPrice,
              silverBahtWeightPrice: silverBahtWeightPrice,
              isDark: isDark,
              currentTheme: currentTheme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTab(int index, String title) {
    final isSelected = _activeSegment == index;
    final currentTheme = widget.controller.currentTheme;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _activeSegment = index);
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? currentTheme.cardBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? currentTheme.textColor : currentTheme.textSecondaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent({
    required double goldBarSell,
    required double goldBarBuy,
    required double goldOrnamentSell,
    required double goldOrnamentBuy,
    required double silverGramPrice,
    required double silverBahtWeightPrice,
    required bool isDark,
    required AppThemeModel currentTheme,
  }) {
    if (_activeSegment == 0) {
      // 🥇 GOLD CONTENT: Compact 2-column side-by-side
      final trend1 = [goldBarSell * 0.99, goldBarSell * 0.995, goldBarSell * 0.998, goldBarSell];
      final trend2 = [goldOrnamentSell * 0.99, goldOrnamentSell * 0.994, goldOrnamentSell * 0.997, goldOrnamentSell];

      return Row(
        children: [
          // Gold Bar
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ทองคำแท่ง',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                      ),
                      SparklineChartWidget(
                        dataPoints: trend1,
                        color: const Color(0xFFD97706),
                        height: 18,
                        width: 42,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ขายออก', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                      Text(
                        '฿${FormatUtils.formatCurrency(goldBarSell)}',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFFD97706)),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('รับซื้อ', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                      Text(
                        '฿${FormatUtils.formatCurrency(goldBarBuy)}',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: currentTheme.textColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Gold Ornament
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ทองรูปพรรณ',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                      ),
                      SparklineChartWidget(
                        dataPoints: trend2,
                        color: const Color(0xFFD97706),
                        height: 18,
                        width: 42,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ขายออก', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                      Text(
                        '฿${FormatUtils.formatCurrency(goldOrnamentSell)}',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFFD97706)),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('รับซื้อ', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                      Text(
                        '฿${FormatUtils.formatCurrency(goldOrnamentBuy)}',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: currentTheme.textColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (_activeSegment == 1) {
      // 🥈 SILVER CONTENT: Compact 2 columns
      return Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF64748B).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ราคาต่อกรัม (g)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  Text(
                    '฿${silverGramPrice.toStringAsFixed(2)} / g',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF475569)),
                  ),
                  const Text('อิงตลาดโลก Real-time', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF64748B).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ต่อน้ำหนัก 1 บาททอง', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  Text(
                    '฿${FormatUtils.formatCurrency(silverBahtWeightPrice)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF475569)),
                  ),
                  const Text('น้ำหนัก 15.244 กรัม', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // 💱 CURRENCIES CONTENT: Compact horizontal cards including THB
      return SizedBox(
        height: 62,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _selectedWatchlistKeys.length + 1, // +1 for THB base
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            if (index == 0) {
              // Base THB Card
              return Container(
                width: 96,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text('🇹🇭', style: TextStyle(fontSize: 13)),
                        SizedBox(width: 4),
                        Text('THB', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text('1.00 ฿ (ฐาน)', style: TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }

            final code = _selectedWatchlistKeys[index - 1];
            final item = CurrencyExchangeService.supportedCurrencies[code];
            final rate = CurrencyExchangeService.getRateToThb(code);

            return Container(
              width: 102,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: currentTheme.borderColor.withValues(alpha: 0.6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(item?.flag ?? '🌐', style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(code.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rate > 0 ? '฿${FormatUtils.formatCurrency(rate)}' : '-',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
  }
}
