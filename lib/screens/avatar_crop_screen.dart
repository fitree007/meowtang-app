import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Full-screen cropper for the user's own avatar photo.
///
/// The photo is moved and zoomed under a fixed circle; "Use photo" saves the
/// part inside the circle as a 512×512 PNG in the app's documents folder and
/// pops with its path (null when cancelled).
class AvatarCropScreen extends StatefulWidget {
  final String? imagePath;

  /// Image bytes instead of [imagePath] (used by tests).
  final Uint8List? bytes;

  final bool isEnglish;

  const AvatarCropScreen({super.key, this.imagePath, this.bytes, this.isEnglish = false});

  static Future<String?> open(BuildContext context, String imagePath, {bool isEnglish = false}) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => AvatarCropScreen(imagePath: imagePath, isEnglish: isEnglish)),
    );
  }

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  static const _outputSize = 512;

  /// Longest side kept in memory; phone photos are scaled down to this.
  static const _maxDecodeSide = 2048;
  static const _maxZoom = 5.0;

  ui.Image? _image;
  bool _failed = false;
  bool _saving = false;

  // Zoom on top of the scale that makes the photo just cover the circle,
  // and the photo centre's offset from the circle centre, in screen pixels.
  double _zoom = 1;
  Offset _offset = Offset.zero;
  double _startZoom = 1;
  Offset _startOffset = Offset.zero;
  Offset _startFocal = Offset.zero;

  double _circle = 280;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final bytes = widget.bytes ?? await File(widget.imagePath!).readAsBytes();
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final longSide = math.max(descriptor.width, descriptor.height);
      // Only the width is given so the decoder keeps the aspect ratio.
      final codec = await descriptor.instantiateCodec(
        targetWidth: longSide > _maxDecodeSide ? (descriptor.width * _maxDecodeSide / longSide).round() : null,
      );
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _image = frame.image);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  double get _baseScale {
    final img = _image!;
    return _circle / math.min(img.width, img.height);
  }

  Size get _shownSize {
    final img = _image!;
    final s = _baseScale * _zoom;
    return Size(img.width * s, img.height * s);
  }

  /// Keeps the circle fully on the photo.
  Offset _clamp(Offset o) {
    final shown = _shownSize;
    final maxX = (shown.width - _circle) / 2;
    final maxY = (shown.height - _circle) / 2;
    return Offset(o.dx.clamp(-maxX, maxX), o.dy.clamp(-maxY, maxY));
  }

  void _onScaleStart(ScaleStartDetails d) {
    _startZoom = _zoom;
    _startOffset = _offset;
    _startFocal = d.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails d, Offset center) {
    final zoom = (_startZoom * d.scale).clamp(1.0, _maxZoom);
    // Zoom around the fingers: the photo point under the focal point stays under it.
    final ratio = zoom / _startZoom;
    final fromCenter = _startFocal - center;
    final offset = fromCenter - (fromCenter - _startOffset) * ratio + (d.localFocalPoint - _startFocal);
    setState(() {
      _zoom = zoom;
      _offset = _clamp(offset);
    });
  }

  void _reset() {
    HapticFeedback.selectionClick();
    setState(() {
      _zoom = 1;
      _offset = Offset.zero;
    });
  }

  Future<void> _save() async {
    final img = _image;
    if (img == null || _saving) return;
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    try {
      // The circle in photo pixels.
      final s = _baseScale * _zoom;
      final side = _circle / s;
      final centre = Offset(img.width / 2, img.height / 2) - _offset / s;
      final src = Rect.fromCenter(center: centre, width: side, height: side);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(
        img,
        src,
        Rect.fromLTWH(0, 0, _outputSize.toDouble(), _outputSize.toDouble()),
        Paint()..filterQuality = FilterQuality.high,
      );
      final out = await recorder.endRecording().toImage(_outputSize, _outputSize);
      final png = await out.toByteData(format: ui.ImageByteFormat.png);
      out.dispose();
      if (png == null) throw StateError('encode failed');

      // Documents, not cache: Android may clear the cache and the photo would vanish.
      final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/avatars');
      await dir.create(recursive: true);
      final file = File('${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(png.buffer.asUint8List(), flush: true);
      if (mounted) Navigator.of(context).pop(file.path);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.isEnglish ? 'Could not save the photo' : 'บันทึกรูปไม่สำเร็จ ลองอีกครั้ง'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = widget.isEnglish;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(isEn ? 'Adjust photo' : 'ปรับรูป', style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (_image != null)
            TextButton(
              onPressed: _reset,
              style: TextButton.styleFrom(foregroundColor: Colors.white70, minimumSize: const Size(44, 44)),
              child: Text(isEn ? 'Reset' : 'รีเซ็ต'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(builder: (context, box) {
              _circle = math.min(math.min(box.maxWidth, box.maxHeight) - 48, 320).toDouble();
              final center = Offset(box.maxWidth / 2, box.maxHeight / 2);
              if (_failed) {
                return Center(
                  child: Text(isEn ? 'Could not open this photo' : 'เปิดรูปนี้ไม่ได้',
                      style: const TextStyle(color: Colors.white70)),
                );
              }
              final img = _image;
              if (img == null) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              // The layout may have changed since the last gesture.
              _offset = _clamp(_offset);
              final shown = _shownSize;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: _onScaleStart,
                onScaleUpdate: (d) => _onScaleUpdate(d, center),
                onDoubleTap: _reset,
                child: Stack(
                  children: [
                    Positioned(
                      left: center.dx + _offset.dx - shown.width / 2,
                      top: center.dy + _offset.dy - shown.height / 2,
                      width: shown.width,
                      height: shown.height,
                      child: RawImage(image: img, fit: BoxFit.fill, filterQuality: FilterQuality.medium),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(child: CustomPaint(painter: _CircleMaskPainter(center, _circle / 2))),
                    ),
                  ],
                ),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              isEn ? 'Pinch to zoom • drag to move' : 'ใช้สองนิ้วเพื่อซูม • ลากเพื่อเลื่อนให้อยู่ในวงกลม',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(isEn ? 'Cancel' : 'ยกเลิก', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: (_image == null || _saving) ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(isEn ? 'Use photo' : 'ใช้รูปนี้', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dims everything outside the crop circle and outlines it.
class _CircleMaskPainter extends CustomPainter {
  final Offset center;
  final double radius;

  _CircleMaskPainter(this.center, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(mask, Paint()..color = Colors.black.withValues(alpha: 0.62));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_CircleMaskPainter old) => old.center != center || old.radius != radius;
}
