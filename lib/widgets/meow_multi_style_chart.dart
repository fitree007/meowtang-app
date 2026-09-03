import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/meow_theme.dart';
import '../utils/format_utils.dart';

enum ChartStyle {
  donut,
  bar,
  trend,
  ranking,
}

class MeowMultiStyleChart extends StatelessWidget {
  final ChartStyle style;
  final double totalAmount;
  final String centerTitle;
  final String centerSubtitle;
  final Map<String, double> categoryAmounts;
  final Map<String, Color> categoryColors;
  final List<MapEntry<DateTime, double>> timeTrendData;
  final bool isIncome;

  const MeowMultiStyleChart({
    super.key,
    required this.style,
    required this.totalAmount,
    required this.centerTitle,
    required this.centerSubtitle,
    required this.categoryAmounts,
    required this.categoryColors,
    this.timeTrendData = const [],
    this.isIncome = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? MeowTheme.textLightPrimary : const Color(0xFF0F172A);
    final textSecondary = isDark ? MeowTheme.textLightSecondary : const Color(0xFF475569);
    final textMuted = isDark ? MeowTheme.textLightMuted : const Color(0xFF94A3B8);
    final trackBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    if (totalAmount <= 0 && timeTrendData.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline_rounded, size: 48, color: textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'ยังไม่มีข้อมูลสถิติในช่วงเวลานี้',
              style: TextStyle(color: textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    switch (style) {
      case ChartStyle.donut:
        return _buildDonutChart(isDark, textPrimary, textSecondary, textMuted, trackBg);
      case ChartStyle.bar:
        return _buildBarChart(isDark, textPrimary, textSecondary, textMuted, trackBg);
      case ChartStyle.trend:
        return _buildTrendChart(isDark, textPrimary, textSecondary, textMuted, trackBg);
      case ChartStyle.ranking:
        return _buildRankingChart(isDark, textPrimary, textSecondary, textMuted, trackBg);
    }
  }

  // 1. DONUT CHART (With Scaled Centered Typography & Dynamic Theme Colors)
  Widget _buildDonutChart(bool isDark, Color textPrimary, Color textSecondary, Color textMuted, Color trackBg) {
    return SizedBox(
      height: 250,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(230, 230),
              painter: _DonutChartPainter(
                totalAmount: totalAmount,
                categoryAmounts: categoryAmounts,
                categoryColors: categoryColors,
                trackBgColor: trackBg,
              ),
            ),
            SizedBox(
              width: 136,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    centerTitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    centerSubtitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      CurrencyFormat.formatWithUnit(totalAmount),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
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

  // 2. COLUMN / BAR CHART (Fixed Layout with Proportional Bar Widths & Comma Support)
  Widget _buildBarChart(bool isDark, Color textPrimary, Color textSecondary, Color textMuted, Color trackBg) {
    final entries = categoryAmounts.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEntries = entries.take(6).toList();
    if (topEntries.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: Text('ไม่มีข้อมูลสำหรับกราฟแท่ง', style: TextStyle(color: textMuted)),
      );
    }

    final maxVal = topEntries.map((e) => e.value).reduce(math.max);
    final effectiveMax = maxVal > 0 ? maxVal : 1.0;
    const chartHeight = 160.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          SizedBox(
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: topEntries.map((entry) {
                final cat = entry.key;
                final val = entry.value;
                final color = categoryColors[cat] ?? (isIncome ? MeowTheme.incomeGreen : MeowTheme.actionBlue);
                final barH = ((val / effectiveMax) * (chartHeight - 44)).clamp(16.0, chartHeight - 44);

                return Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 54),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            val >= 1000 ? '${CurrencyFormat.format(val / 1000)}k' : '${CurrencyFormat.format(val)}฿',
                            maxLines: 1,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: barH,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                color,
                                color.withValues(alpha: 0.65),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 1.5, color: isDark ? MeowTheme.borderColor : const Color(0xFFE2E8F0)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: topEntries.map((entry) {
              final label = entry.key.replaceAll('และ', '&').split(' ').first;
              return Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 54),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 3. TREND / AREA LINE CHART (Smooth Bézier Curves & Safe Bounds)
  Widget _buildTrendChart(bool isDark, Color textPrimary, Color textSecondary, Color textMuted, Color trackBg) {
    if (timeTrendData.isEmpty) {
      return _buildBarChart(isDark, textPrimary, textSecondary, textMuted, trackBg);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      height: 240,
      child: CustomPaint(
        size: const Size(double.infinity, 220),
        painter: _TrendLineChartPainter(
          dataPoints: timeTrendData,
          lineColor: isIncome ? MeowTheme.incomeGreen : MeowTheme.actionBlue,
          gridColor: isDark ? const Color(0xFF334155).withValues(alpha: 0.4) : const Color(0xFFCBD5E1).withValues(alpha: 0.8),
          labelColor: textMuted,
        ),
      ),
    );
  }

  // 4. RANKING PROGRESS CHART (With Comma Format & Dark/Light colors)
  Widget _buildRankingChart(bool isDark, Color textPrimary, Color textSecondary, Color textMuted, Color trackBg) {
    final sortedEntries = categoryAmounts.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEntries = sortedEntries.take(5).toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: topEntries.asMap().entries.map((item) {
          final rank = item.key + 1;
          final entry = item.value;
          final cat = entry.key;
          final val = entry.value;
          final percent = totalAmount > 0 ? (val / totalAmount) * 100 : 0.0;
          final color = categoryColors[cat] ?? (isIncome ? MeowTheme.incomeGreen : MeowTheme.actionBlue);

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: rank == 1
                                ? const Color(0xFFF59E0B)
                                : rank == 2
                                    ? const Color(0xFF94A3B8)
                                    : rank == 3
                                        ? const Color(0xFFD97706)
                                        : (isDark ? const Color(0xFF334155) : const Color(0xFF64748B)),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$rank',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cat,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${CurrencyFormat.format(val)} ฿ (${percent.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (percent / 100).clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: trackBg,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double totalAmount;
  final Map<String, double> categoryAmounts;
  final Map<String, Color> categoryColors;
  final Color trackBgColor;

  _DonutChartPainter({
    required this.totalAmount,
    required this.categoryAmounts,
    required this.categoryColors,
    required this.trackBgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalAmount <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 14;
    const strokeWidth = 24.0;

    // Background track
    final bgPaint = Paint()
      ..color = trackBgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    double startAngle = -math.pi / 2;

    for (final entry in categoryAmounts.entries) {
      if (entry.value <= 0) continue;

      final sweepAngle = (entry.value / totalAmount) * 2 * math.pi;
      final color = categoryColors[entry.key] ?? MeowTheme.actionBlue;

      final arcPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.02,
        false,
        arcPaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _TrendLineChartPainter extends CustomPainter {
  final List<MapEntry<DateTime, double>> dataPoints;
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;

  _TrendLineChartPainter({
    required this.dataPoints,
    required this.lineColor,
    required this.gridColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final w = size.width;
    final h = size.height - 32;
    final maxVal = dataPoints.map((e) => e.value).reduce(math.max);
    final effectiveMax = maxVal > 0 ? maxVal * 1.15 : 1.0;

    // Draw background grid lines (0%, 50%, 100%)
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(0, h), Offset(w, h), gridPaint);
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), gridPaint);
    canvas.drawLine(Offset(0, 10), Offset(w, 10), gridPaint);

    if (dataPoints.length == 1) {
      final y = h - ((dataPoints.first.value / effectiveMax) * (h - 20));
      canvas.drawCircle(Offset(w / 2, y), 6.0, Paint()..color = lineColor);
      canvas.drawCircle(Offset(w / 2, y), 3.5, Paint()..color = Colors.white);
      _drawLabel(
        canvas,
        '${dataPoints.first.key.day}/${dataPoints.first.key.month}',
        Offset(w / 2 - 12, h + 10),
        TextStyle(color: labelColor, fontSize: 10),
      );
      return;
    }

    final points = <Offset>[];
    final stepX = w / (dataPoints.length - 1);

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * stepX;
      final val = dataPoints[i].value;
      final y = h - ((val / effectiveMax) * (h - 20));
      points.add(Offset(x, y.clamp(10.0, h)));
    }

    // Gradient Fill Area
    final fillPath = Path()..moveTo(points.first.dx, h);
    fillPath.lineTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cpX = (p0.dx + p1.dx) / 2;
      fillPath.cubicTo(cpX, p0.dy, cpX, p1.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(points.last.dx, h);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.4),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(fillPath, fillPaint);

    // Smooth Bézier Line
    final strokePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cpX = (p0.dx + p1.dx) / 2;
      strokePath.cubicTo(cpX, p0.dy, cpX, p1.dy, p1.dx, p1.dy);
    }

    final strokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(strokePath, strokePaint);

    // Draw Data Point Dots and Date Labels
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      canvas.drawCircle(pt, 4.5, Paint()..color = lineColor);
      canvas.drawCircle(pt, 2.5, Paint()..color = Colors.white);

      // Only draw some date labels to avoid clutter
      if (dataPoints.length <= 7 || i == 0 || i == points.length - 1 || i == points.length ~/ 2) {
        final d = dataPoints[i].key;
        _drawLabel(
          canvas,
          '${d.day}/${d.month}',
          Offset(pt.dx - 12, h + 8),
          TextStyle(color: labelColor, fontSize: 10, fontWeight: FontWeight.bold),
        );
      }
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
