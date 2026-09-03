import 'dart:math';
import 'package:flutter/material.dart';
import '../services/cashflow_forecast_service.dart';

class CashflowChart extends StatelessWidget {
  final List<ForecastDayPoint> timeline;
  final double currentBalance;

  const CashflowChart({
    super.key,
    required this.timeline,
    required this.currentBalance,
  });

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) {
      return const Center(child: Text('ไม่มีข้อมูลพยากรณ์', style: TextStyle(color: Colors.white54)));
    }

    final points = timeline.take(30).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 180,
          width: double.infinity,
          child: CustomPaint(
            painter: _CashflowPainter(points: points),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'วันนี้ (${timeline.first.date.day}/${timeline.first.date.month})',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
            ),
            Text(
              'อีก 15 วัน',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
            ),
            Text(
              'อีก 30 วัน (${timeline[min(29, timeline.length - 1)].date.day}/${timeline[min(29, timeline.length - 1)].date.month})',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class _CashflowPainter extends CustomPainter {
  final List<ForecastDayPoint> points;

  _CashflowPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    double minVal = points.first.projectedBalance;
    double maxVal = points.first.projectedBalance;

    for (final p in points) {
      if (p.projectedBalance < minVal) minVal = p.projectedBalance;
      if (p.projectedBalance > maxVal) maxVal = p.projectedBalance;
    }

    // Add margin
    minVal = (minVal * 0.9).clamp(0.0, double.infinity);
    maxVal = maxVal * 1.1;
    if (maxVal == minVal) maxVal += 1000;

    final double widthStep = size.width / (points.length - 1);

    final linePath = Path();
    final fillPath = Path();

    final List<Offset> offsets = [];

    for (int i = 0; i < points.length; i++) {
      final x = i * widthStep;
      final normalized = (points[i].projectedBalance - minVal) / (maxVal - minVal);
      final y = size.height - (normalized * (size.height - 20)) - 10;
      offsets.add(Offset(x, y));
    }

    // Build smooth bezier curve
    linePath.moveTo(offsets[0].dx, offsets[0].dy);
    fillPath.moveTo(offsets[0].dx, size.height);
    fillPath.lineTo(offsets[0].dx, offsets[0].dy);

    for (int i = 0; i < offsets.length - 1; i++) {
      final p0 = offsets[i];
      final p1 = offsets[i + 1];
      final cpX = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(cpX, p0.dy, cpX, p1.dy, p1.dx, p1.dy);
      fillPath.cubicTo(cpX, p0.dy, cpX, p1.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(offsets.last.dx, size.height);
    fillPath.close();

    // Draw Gradient Fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF6366F1).withOpacity(0.4),
          const Color(0xFF6366F1).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Draw Line
    final linePaint = Paint()
      ..color = const Color(0xFF818CF8)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, linePaint);

    // Draw Danger Zone / Alert Points
    final dotPaint = Paint()..color = const Color(0xFF38BDF8);
    final dangerPaint = Paint()..color = const Color(0xFFEF4444);

    for (int i = 0; i < offsets.length; i++) {
      final point = points[i];
      if (point.isDangerLow) {
        canvas.drawCircle(offsets[i], 5, dangerPaint);
      } else if (i == 0 || i == offsets.length - 1 || i == 14) {
        canvas.drawCircle(offsets[i], 4, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CashflowPainter oldDelegate) => true;
}
