import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/meow_theme.dart';
import '../utils/format_utils.dart';

class MeowDonutChart extends StatelessWidget {
  final double totalAmount;
  final String centerTitle;
  final String centerSubtitle;
  final Map<String, double> categoryAmounts;
  final Map<String, Color> categoryColors;
  final double size;

  const MeowDonutChart({
    super.key,
    required this.totalAmount,
    required this.centerTitle,
    required this.centerSubtitle,
    required this.categoryAmounts,
    required this.categoryColors,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutChartPainter(
              totalAmount: totalAmount,
              categoryAmounts: categoryAmounts,
              categoryColors: categoryColors,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerTitle,
                style: const TextStyle(
                  color: MeowTheme.textLightSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                centerSubtitle,
                style: const TextStyle(
                  color: MeowTheme.textLightMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${FormatUtils.formatCurrency(totalAmount, trimZero: true)} ฿',
                style: const TextStyle(
                  color: MeowTheme.textLightPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double totalAmount;
  final Map<String, double> categoryAmounts;
  final Map<String, Color> categoryColors;

  _DonutChartPainter({
    required this.totalAmount,
    required this.categoryAmounts,
    required this.categoryColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 24.0;

    // Background track ring
    final bgPaint = Paint()
      ..color = const Color(0xFF1B2E48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (totalAmount <= 0 || categoryAmounts.isEmpty) {
      return;
    }

    double startAngle = -math.pi / 2;

    for (final entry in categoryAmounts.entries) {
      final catName = entry.key;
      final amount = entry.value;
      if (amount <= 0) continue;

      final sweepAngle = (amount / totalAmount) * 2 * math.pi;
      final color = categoryColors[catName] ?? MeowTheme.actionBlue;

      final arcPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        arcPaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
