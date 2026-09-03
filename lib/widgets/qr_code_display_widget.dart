import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

class QrCodeDisplayWidget extends StatelessWidget {
  final String data;
  final double size;
  final Color foregroundColor;
  final Color backgroundColor;
  final Widget? embeddedLogo;

  const QrCodeDisplayWidget({
    super.key,
    required this.data,
    this.size = 200,
    this.foregroundColor = const Color(0xFF0F172A),
    this.backgroundColor = Colors.white,
    this.embeddedLogo,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: const Center(child: Text('No QR Data')),
      );
    }

    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size - 28, size - 28),
            painter: _QrCanvasPainter(
              qrImage: qrImage,
              foregroundColor: foregroundColor,
            ),
          ),
          if (embeddedLogo != null)
            Container(
              width: (size - 28) * 0.24,
              height: (size - 28) * 0.24,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 6,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: Center(child: embeddedLogo),
            ),
        ],
      ),
    );
  }
}

class _QrCanvasPainter extends CustomPainter {
  final QrImage qrImage;
  final Color foregroundColor;

  _QrCanvasPainter({
    required this.qrImage,
    required this.foregroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.fill;

    final moduleCount = qrImage.moduleCount;
    final moduleSize = size.width / moduleCount;

    for (int x = 0; x < moduleCount; x++) {
      for (int y = 0; y < moduleCount; y++) {
        if (qrImage.isDark(y, x)) {
          final rect = Rect.fromLTWH(
            x * moduleSize,
            y * moduleSize,
            moduleSize + 0.35,
            moduleSize + 0.35,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(moduleSize * 0.3)),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrCanvasPainter oldDelegate) =>
      oldDelegate.qrImage != qrImage || oldDelegate.foregroundColor != foregroundColor;
}
