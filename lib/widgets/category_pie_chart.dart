import 'dart:math';
import 'package:flutter/material.dart';

class CategorySliceData {
  final String label;
  final double amount;
  final Color color;

  CategorySliceData({
    required this.label,
    required this.amount,
    required this.color,
  });
}

class CategoryPieChart extends StatelessWidget {
  final List<CategorySliceData> slices;
  final String centerTitle;
  final String centerSubtitle;

  const CategoryPieChart({
    super.key,
    required this.slices,
    this.centerTitle = 'รวม',
    this.centerSubtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: Text('ไม่มีข้อมูลสถิติ', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    final total = slices.fold(0.0, (sum, s) => sum + s.amount);

    return Column(
      children: [
        SizedBox(
          height: 180,
          width: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(180, 180),
                painter: _DonutChartPainter(slices: slices, total: total),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerTitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '฿${total >= 1000000 ? "${(total / 1000000).toStringAsFixed(1)}M" : total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Legend Wrap
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: slices.map((s) {
            final pct = total > 0 ? (s.amount / total * 100).toStringAsFixed(0) : '0';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: s.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${s.label} ($pct%)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<CategorySliceData> slices;
  final double total;

  _DonutChartPainter({required this.slices, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 20.0;

    double startAngle = -pi / 2;

    for (final slice in slices) {
      final sweepAngle = (slice.amount / total) * 2 * pi;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + 0.03,
        sweepAngle - 0.06 > 0 ? sweepAngle - 0.06 : sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}
