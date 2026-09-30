import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// A playful pull-to-refresh indicator featuring a cat peeking up from the right
/// and continuously swiping dark-gray money slips to the left in a curved semi-circular arc.
class MeowSlipScanRefreshIndicator extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Color primaryColor;
  final bool isDark;
  final bool isEnglish;
  final String? mascotId;
  final String? mascotAccessory;
  final String? mascotOutfit;
  final String? customAvatarPath;
  final bool isCustomAvatarEnabled;

  const MeowSlipScanRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    required this.primaryColor,
    required this.isDark,
    required this.isEnglish,
    this.mascotId,
    this.mascotAccessory,
    this.mascotOutfit,
    this.customAvatarPath,
    this.isCustomAvatarEnabled = false,
  });

  @override
  State<MeowSlipScanRefreshIndicator> createState() => _MeowSlipScanRefreshIndicatorState();
}

class _MeowSlipScanRefreshIndicatorState extends State<MeowSlipScanRefreshIndicator>
    with TickerProviderStateMixin {
  // Short, effortless pull distance (46px)
  static const double _triggerDistance = 46.0;
  static const double _refreshingHeight = 68.0;
  static const double _maxDragDisplacement = 86.0;

  double _dragOffset = 0.0;
  bool _isDragging = false;
  bool _canRefresh = false;
  bool _isRefreshing = false;
  bool _isCompleted = false;

  late AnimationController _springBackController;
  late Animation<double> _springBackAnimation;

  // Arc swiping controller: drives the curved semi-circular swipe to the left
  late AnimationController _arcSwipeController;
  // Subtle blinking & ear twitch controller
  late AnimationController _idleCatController;

  @override
  void initState() {
    super.initState();

    _springBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    // Continuous 360-degree slip orbit loop (~1600ms per full revolution)
    _arcSwipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _idleCatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void dispose() {
    _springBackController.dispose();
    _arcSwipeController.dispose();
    _idleCatController.dispose();
    super.dispose();
  }

  void _startSwipeLoop() {
    if (!_arcSwipeController.isAnimating) {
      _arcSwipeController.repeat();
    }
    if (!_idleCatController.isAnimating) {
      _idleCatController.repeat();
    }
  }

  void _stopSwipeLoop() {
    _arcSwipeController.stop();
    _idleCatController.stop();
  }

  void _updateDrag(double rawOffset) {
    if (_isRefreshing) return;

    // Responsive 1:0.85 touch ratio
    const resistance = 0.85;
    final newOffset = (rawOffset * resistance).clamp(0.0, _maxDragDisplacement);

    setState(() {
      _dragOffset = newOffset;
    });

    if (_dragOffset >= _triggerDistance) {
      if (!_canRefresh) {
        _canRefresh = true;
        HapticFeedback.lightImpact();
      }
      _startSwipeLoop();
    } else if (_dragOffset <= 6.0) {
      _canRefresh = false;
    }
  }

  Future<void> _handleRelease() async {
    if (_isRefreshing) return;

    if (_canRefresh || _dragOffset >= _triggerDistance) {
      _canRefresh = false;
      setState(() {
        _isRefreshing = true;
        _isCompleted = false;
      });

      _startSwipeLoop();
      _animateTo(_refreshingHeight, durationMs: 160);

      // Hold refresh screen firmly for at least 3.2 seconds
      try {
        await Future.wait([
          widget.onRefresh(),
          Future.delayed(const Duration(milliseconds: 3200)),
        ]);
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        _isCompleted = true;
      });
      HapticFeedback.lightImpact();

      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;

      _animateTo(0.0, durationMs: 240, onDone: () {
        if (mounted) {
          setState(() {
            _isRefreshing = false;
            _isCompleted = false;
            _dragOffset = 0.0;
            _canRefresh = false;
          });
          _stopSwipeLoop();
        }
      });
    } else {
      _animateTo(0.0, durationMs: 200, onDone: () {
        if (mounted) {
          setState(() {
            _dragOffset = 0.0;
            _canRefresh = false;
          });
          _stopSwipeLoop();
        }
      });
    }
  }

  void _animateTo(double target, {int durationMs = 200, VoidCallback? onDone}) {
    _springBackAnimation = Tween<double>(
      begin: _dragOffset,
      end: target,
    ).animate(CurvedAnimation(
      parent: _springBackController,
      curve: Curves.easeOutCubic,
    ))..addListener(() {
      setState(() {
        _dragOffset = _springBackAnimation.value;
      });
    });

    _springBackController.duration = Duration(milliseconds: durationMs);
    _springBackController.forward(from: 0.0).then((_) {
      onDone?.call();
    });
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (_isRefreshing) return false;

    if (notification is ScrollStartNotification) {
      if (notification.metrics.extentBefore == 0) {
        _isDragging = true;
      }
    } else if (notification is ScrollUpdateNotification) {
      if (_isDragging && !_isRefreshing) {
        if (notification.metrics.pixels < 0) {
          _updateDrag(-notification.metrics.pixels);
        } else if (_dragOffset > 0 && notification.scrollDelta != null && notification.scrollDelta! > 0) {
          if (!_canRefresh) {
            _updateDrag(_dragOffset - notification.scrollDelta!);
          }
        }
      }
    } else if (notification is OverscrollNotification) {
      if (!_isRefreshing && notification.overscroll < 0) {
        _updateDrag(_dragOffset + (-notification.overscroll));
      }
    } else if (notification is ScrollEndNotification) {
      if (_isDragging) {
        _isDragging = false;
        _handleRelease();
      }
    } else if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.idle && _isDragging) {
        _isDragging = false;
        _handleRelease();
      }
    }
    return false;
  }

  Color _getMascotColor() {
    final id = widget.mascotId ?? 'cat_quill';
    if (id.contains('white')) return const Color(0xFFF1F5F9);
    if (id.contains('black')) return const Color(0xFF334155);
    if (id.contains('calico')) return const Color(0xFFE2E8F0);
    if (id.contains('pink')) return const Color(0xFFF472B6);
    return const Color(0xFFF59E0B); // Default orange ginger tabby
  }

  Color _getEarColor() {
    final id = widget.mascotId ?? 'cat_quill';
    if (id.contains('white')) return const Color(0xFFFDA4AF);
    if (id.contains('black')) return const Color(0xFF1E293B);
    return const Color(0xFFD97706);
  }

  @override
  Widget build(BuildContext context) {
    final double topSafe = MediaQuery.of(context).padding.top;
    final double visibleHeight = _isRefreshing ? math.max(_dragOffset, _refreshingHeight) : _dragOffset;
    final double progress = (_dragOffset / _triggerDistance).clamp(0.0, 1.0);

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Content translated smoothly down by pull distance
          Transform.translate(
            offset: Offset(0, visibleHeight),
            child: widget.child,
          ),

          // Frameless, Open Scene: Cat swiping dark-gray slips in an arc to the left
          if (visibleHeight > 3.0)
            Positioned(
              top: topSafe + 4,
              left: 0,
              right: 0,
              height: visibleHeight,
              child: ClipRect(
                child: Opacity(
                  opacity: (visibleHeight / 18.0).clamp(0.0, 1.0),
                  child: _buildArcSwipingScene(progress),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArcSwipingScene(double progress) {
    final catColor = _getMascotColor();
    final earColor = _getEarColor();

    return AnimatedBuilder(
      animation: Listenable.merge([_arcSwipeController, _idleCatController]),
      builder: (context, child) {
        // Swipe value loops 0.0 -> 1.0
        final swipeT = _isRefreshing ? _arcSwipeController.value : (progress * 0.4);

        return Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              width: 250,
              height: 64,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Dark-Gray Money Slips swiping in a semi-circular arc to the left
                  _buildSwipingSlips(swipeT),

                  // 2. The Cat on the right peeking up and swiping paw in an arc
                  Positioned(
                    right: 18,
                    bottom: 0,
                    child: _buildCatWithArcPaw(catColor, earColor, swipeT),
                  ),

                  // 3. Completed Checkmark Pill
                  if (_isCompleted)
                    Positioned(
                      left: 35,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(color: Color(0x6610B981), blurRadius: 8),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded, color: Colors.white, size: 10),
                            SizedBox(width: 3.5),
                            Text(
                              'เรียบร้อย!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSwipingSlips(double swipeT) {
    // 3 dark-gray money slips circulating in an endless 360-degree closed orbit
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildSingleOrbitSlip(swipeT),
        _buildSingleOrbitSlip((swipeT + 0.3333) % 1.0),
        _buildSingleOrbitSlip((swipeT + 0.6667) % 1.0),
      ],
    );
  }

  Widget _buildSingleOrbitSlip(double u) {
    // 360-degree continuous closed orbit:
    // u in [0.00, 0.45]: Cat swats slip forward across the lower front track
    // u in [0.45, 0.55]: Slip rounds the left apex turn
    // u in [0.55, 0.90]: Slip cruises smoothly back to the right along upper track
    // u in [0.90, 1.00]: Slip swoops down into swat zone ready to be batted again
    double posX;
    double posY;
    double tiltAngle;
    double scale;
    double opacity;

    if (u < 0.45) {
      final p = u / 0.45;
      posX = 138.0 - (p * 122.0); // 138 -> 16
      posY = 14.0 - (math.sin(p * math.pi) * 10.0); // dips in front
      tiltAngle = -0.22 - (math.sin(p * math.pi) * 0.45);
      scale = 1.0;
      opacity = 1.0;
    } else if (u < 0.55) {
      final p = (u - 0.45) / 0.10;
      posX = 16.0 - (math.sin(p * math.pi) * 6.0);
      posY = 14.0 + (p * 18.0); // 14 -> 32
      tiltAngle = -0.45 + (p * 0.45);
      scale = 1.0 - (p * 0.15);
      opacity = 1.0 - (p * 0.15);
    } else if (u < 0.90) {
      final p = (u - 0.55) / 0.35;
      posX = 16.0 + (p * 122.0); // 16 -> 138
      posY = 32.0 - (math.sin(p * math.pi) * 5.0);
      tiltAngle = 0.05 - (p * 0.15);
      scale = 0.85;
      opacity = 0.85;
    } else {
      final p = (u - 0.90) / 0.10;
      posX = 138.0 + (math.sin(p * math.pi) * 6.0);
      posY = 32.0 - (p * 18.0); // 32 -> 14
      tiltAngle = -0.10 - (p * 0.12);
      scale = 0.85 + (p * 0.15);
      opacity = 0.85 + (p * 0.15);
    }

    return Positioned(
      left: posX,
      bottom: posY,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: tiltAngle,
            alignment: Alignment.center,
            child: _buildDarkGraySlip(),
          ),
        ),
      ),
    );
  }

  /// Minimalist Dark-Gray Money Slip (Neutral slate/dark gray only, no bank branding)
  Widget _buildDarkGraySlip() {
    return Container(
      width: 40,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark slate gray base
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF475569), // Muted slate gray border
          width: 0.9,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 4,
            offset: Offset(0, 1.5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dark Gray Top Band (Neutral, no bank name)
          Container(
            height: 9,
            decoration: const BoxDecoration(
              color: Color(0xFF334155), // Mid slate gray
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 3),
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 14,
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFF94A3B8),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const Icon(Icons.receipt_rounded, size: 6, color: Color(0xFF94A3B8)),
              ],
            ),
          ),

          // Slip Body: Neutral Gray Lines & Currency Placeholder
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text(
                    '฿ •••••',
                    style: TextStyle(
                      fontSize: 6.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFCBD5E1), // Soft light gray
                      letterSpacing: -0.2,
                      height: 1,
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 1.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  Container(
                    width: 13,
                    height: 1.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  // Bottom mini barcode lines (all neutral gray)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (i) => Container(
                      width: 1.5,
                      height: 4,
                      color: const Color(0xFF475569),
                    )),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cat with a realistic, fixed-length forearm rotating from shoulder and authentic feline face
  Widget _buildCatWithArcPaw(Color catColor, Color earColor, double swipeT) {
    final bool isBlinking = _idleCatController.value > 0.94;
    final double earTwitch = math.sin(_idleCatController.value * math.pi * 4) * 0.08;

    // The swat cadence synchronizes with the 3 passing slips
    final double swatPhase = (swipeT * 3.0) % 1.0;

    // CONSTANT ARM LENGTH: Exactly 23.0 pixels! Rotates around shoulder, NEVER stretches!
    const double armLength = 23.0;
    const Offset shoulder = Offset(62.0, 36.0);

    double armAngle;
    if (swatPhase < 0.45) {
      // Swatting forward and downward
      final double s = swatPhase / 0.45;
      final double ease = math.sin(s * math.pi * 0.5);
      armAngle = 2.65 + (ease * 0.65); // from 2.65 rad (~151°) to 3.30 rad (~189°)
    } else {
      // Returning back to ready pose
      final double r = (swatPhase - 0.45) / 0.55;
      final double ease = (1.0 - math.cos(r * math.pi)) * 0.5;
      armAngle = 3.30 - (ease * 0.65);
    }

    final double pawCenterX = shoulder.dx + math.cos(armAngle) * armLength;
    final double pawCenterY = shoulder.dy + math.sin(armAngle) * armLength;
    final double pawRotation = armAngle - math.pi * 0.5;

    return SizedBox(
      width: 114,
      height: 62,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Forearm connecting cat's shoulder to wrist (CONSTANT LENGTH, NEVER STRETCHES)
          CustomPaint(
            size: const Size(114, 62),
            painter: _CatFixedArmPainter(
              armColor: catColor,
              shoulder: shoulder,
              wrist: Offset(pawCenterX, pawCenterY),
            ),
          ),

          // 2. Swatting Front Paw with toe beans & heart pad
          Positioned(
            left: pawCenterX - 11.0,
            top: pawCenterY - 6.5,
            child: Transform.rotate(
              angle: pawRotation,
              alignment: Alignment.center,
              child: _buildSwipingPaw(catColor),
            ),
          ),

          // 3. Realistic, Adorable Peeking Cat Head & Upper Body
          Positioned(
            right: 0,
            bottom: -2,
            child: _buildRealisticCat(catColor, earColor, isBlinking, earTwitch),
          ),

          // 4. Resting Left Paw on the front edge
          Positioned(
            right: 44,
            bottom: 0,
            child: _buildRestingPaw(catColor),
          ),
        ],
      ),
    );
  }

  Widget _buildRealisticCat(Color catColor, Color earColor, bool isBlinking, double earTwitch) {
    return SizedBox(
      width: 56,
      height: 48,
      child: CustomPaint(
        painter: _RealCatFacePainter(
          catColor: catColor,
          earColor: earColor,
          isBlinking: isBlinking,
          isCompleted: _isCompleted,
          earTwitch: earTwitch,
        ),
      ),
    );
  }

  Widget _buildRestingPaw(Color catColor) {
    return Container(
      width: 13,
      height: 9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.5),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        boxShadow: const [
          BoxShadow(color: Color(0x25000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (i) => Container(
          width: 2.2,
          height: 3.5,
          decoration: BoxDecoration(
            color: const Color(0xFFFDA4AF),
            borderRadius: BorderRadius.circular(1.2),
          ),
        )),
      ),
    );
  }

  Widget _buildSwipingPaw(Color catColor) {
    return Container(
      width: 22,
      height: 13,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.5),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x25000000),
            blurRadius: 3,
            offset: Offset(-1, 1.5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 4 pink toe beans across top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (i) => Container(
                width: 2.8,
                height: 4.2,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDA4AF),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              )),
            ),
          ),
          // Heart-shaped palm pad (metacarpal pad)
          Positioned(
            bottom: 0,
            child: Container(
              width: 6,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFFDA4AF),
                borderRadius: BorderRadius.circular(2.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter for fixed-length forearm rotating around shoulder joint
class _CatFixedArmPainter extends CustomPainter {
  final Color armColor;
  final Offset shoulder;
  final Offset wrist;

  _CatFixedArmPainter({
    required this.armColor,
    required this.shoulder,
    required this.wrist,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dx = wrist.dx - shoulder.dx;
    final dy = wrist.dy - shoulder.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 2.0) return;

    final nx = -dy / dist;
    final ny = dx / dist;

    // Fixed anatomical arm: shoulder ~6.5px, wrist ~4.8px
    const double rShoulder = 6.5;
    const double rWrist = 4.8;

    final path = Path()
      ..moveTo(shoulder.dx + nx * rShoulder, shoulder.dy + ny * rShoulder)
      ..lineTo(wrist.dx + nx * rWrist, wrist.dy + ny * rWrist)
      ..lineTo(wrist.dx - nx * rWrist, wrist.dy - ny * rWrist)
      ..lineTo(shoulder.dx - nx * rShoulder, shoulder.dy - ny * rShoulder)
      ..close();

    final shadowPaint = Paint()
      ..color = const Color(0x20000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    final armPaint = Paint()
      ..color = armColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, armPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CatFixedArmPainter oldDelegate) =>
      oldDelegate.wrist != wrist ||
      oldDelegate.shoulder != shoulder ||
      oldDelegate.armColor != armColor;
}

/// Detailed, authentic, adorable cat face painter
class _RealCatFacePainter extends CustomPainter {
  final Color catColor;
  final Color earColor;
  final bool isBlinking;
  final bool isCompleted;
  final double earTwitch;

  _RealCatFacePainter({
    required this.catColor,
    required this.earColor,
    required this.isBlinking,
    required this.isCompleted,
    required this.earTwitch,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Cat Ears
    // Left ear (with twitch)
    canvas.save();
    canvas.translate(size.width * 0.22, size.height * 0.22);
    canvas.rotate(earTwitch - 0.12);
    _drawCatEar(canvas, const Size(15, 18), catColor, earColor, isLeft: true);
    canvas.restore();

    // Right ear
    canvas.save();
    canvas.translate(size.width * 0.78, size.height * 0.22);
    canvas.rotate(0.12);
    _drawCatEar(canvas, const Size(15, 18), catColor, earColor, isLeft: false);
    canvas.restore();

    // 2. Head Silhouette with Fluffy Cheeks
    final headPath = Path();
    headPath.moveTo(size.width * 0.28, size.height * 0.22);
    // Top head curve
    headPath.quadraticBezierTo(size.width * 0.5, size.height * 0.18, size.width * 0.72, size.height * 0.22);
    // Right cheek slope
    headPath.quadraticBezierTo(size.width * 0.88, size.height * 0.38, size.width * 0.96, size.height * 0.56);
    // Right cheek tuft
    headPath.lineTo(size.width * 0.98, size.height * 0.64);
    headPath.lineTo(size.width * 0.90, size.height * 0.70);
    // Chin curve
    headPath.quadraticBezierTo(size.width * 0.5, size.height * 0.98, size.width * 0.10, size.height * 0.70);
    // Left cheek tuft
    headPath.lineTo(size.width * 0.02, size.height * 0.64);
    headPath.lineTo(size.width * 0.04, size.height * 0.56);
    // Left cheek slope
    headPath.quadraticBezierTo(size.width * 0.12, size.height * 0.38, size.width * 0.28, size.height * 0.22);
    headPath.close();

    // Shadow
    canvas.drawPath(headPath, Paint()
      ..color = const Color(0x25000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5));

    // Head Fill
    canvas.drawPath(headPath, Paint()..color = catColor);
    // Head Outline
    canvas.drawPath(headPath, Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9);

    // 3. Tabby Forehead Markings
    final stripePaint = Paint()
      ..color = earColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.6;

    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.22), Offset(size.width * 0.5, size.height * 0.32), stripePaint);
    canvas.drawLine(Offset(size.width * 0.42, size.height * 0.24), Offset(size.width * 0.44, size.height * 0.32), stripePaint);
    canvas.drawLine(Offset(size.width * 0.58, size.height * 0.24), Offset(size.width * 0.56, size.height * 0.32), stripePaint);

    // 4. Eyes (Almond Cat Eyes)
    final eyeLeft = Offset(size.width * 0.32, size.height * 0.48);
    final eyeRight = Offset(size.width * 0.68, size.height * 0.48);

    if (isCompleted) {
      _drawHappyEye(canvas, eyeLeft);
      _drawHappyEye(canvas, eyeRight);
    } else if (isBlinking) {
      _drawBlinkEye(canvas, eyeLeft);
      _drawBlinkEye(canvas, eyeRight);
    } else {
      _drawAlmondEye(canvas, eyeLeft, isLeft: true);
      _drawAlmondEye(canvas, eyeRight, isLeft: false);
    }

    // 5. Whisker Pads (Puffy ω Muzzle)
    final muzzleCenter = Offset(size.width * 0.5, size.height * 0.70);
    final padPaint = Paint()..color = Colors.white;
    final padBorder = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    // Left pad
    canvas.drawOval(Rect.fromCenter(center: Offset(muzzleCenter.dx - 5.5, muzzleCenter.dy), width: 13, height: 9.5), padPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(muzzleCenter.dx - 5.5, muzzleCenter.dy), width: 13, height: 9.5), padBorder);
    // Right pad
    canvas.drawOval(Rect.fromCenter(center: Offset(muzzleCenter.dx + 5.5, muzzleCenter.dy), width: 13, height: 9.5), padPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(muzzleCenter.dx + 5.5, muzzleCenter.dy), width: 13, height: 9.5), padBorder);

    // Whisker follicle dots (3 dots each)
    final dotPaint = Paint()..color = const Color(0xFF94A3B8);
    for (final off in [
      Offset(muzzleCenter.dx - 8, muzzleCenter.dy - 1.5),
      Offset(muzzleCenter.dx - 5, muzzleCenter.dy + 1.0),
      Offset(muzzleCenter.dx - 8.5, muzzleCenter.dy + 2.0),
      Offset(muzzleCenter.dx + 8, muzzleCenter.dy - 1.5),
      Offset(muzzleCenter.dx + 5, muzzleCenter.dy + 1.0),
      Offset(muzzleCenter.dx + 8.5, muzzleCenter.dy + 2.0),
    ]) {
      canvas.drawCircle(off, 0.7, dotPaint);
    }

    // 6. Inverted Triangle Baby Pink Nose
    final noseTop = muzzleCenter.dy - 4.5;
    final nosePath = Path()
      ..moveTo(muzzleCenter.dx - 3.2, noseTop)
      ..lineTo(muzzleCenter.dx + 3.2, noseTop)
      ..lineTo(muzzleCenter.dx, noseTop + 4.2)
      ..close();
    canvas.drawPath(nosePath, Paint()..color = const Color(0xFFFB7185));

    // Mouth lines descending into ω curves
    final mouthPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.9;

    final mouthPath = Path()
      ..moveTo(muzzleCenter.dx, noseTop + 4.0)
      ..lineTo(muzzleCenter.dx, muzzleCenter.dy + 1.5)
      ..moveTo(muzzleCenter.dx, muzzleCenter.dy + 1.5)
      ..quadraticBezierTo(muzzleCenter.dx - 3.5, muzzleCenter.dy + 4.0, muzzleCenter.dx - 6.5, muzzleCenter.dy + 2.2)
      ..moveTo(muzzleCenter.dx, muzzleCenter.dy + 1.5)
      ..quadraticBezierTo(muzzleCenter.dx + 3.5, muzzleCenter.dy + 4.0, muzzleCenter.dx + 6.5, muzzleCenter.dy + 2.2);
    canvas.drawPath(mouthPath, mouthPaint);

    // 7. Whiskers (3 elegant curved whiskers on each side)
    final whiskerPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.85;

    // Left Whiskers
    final wLeftY = muzzleCenter.dy;
    final wL1 = Path()
      ..moveTo(muzzleCenter.dx - 9, wLeftY - 1.5)
      ..quadraticBezierTo(size.width * 0.1, wLeftY - 6.0, -10.0, wLeftY - 5.0);
    final wL2 = Path()
      ..moveTo(muzzleCenter.dx - 10, wLeftY + 0.5)
      ..quadraticBezierTo(size.width * 0.1, wLeftY + 1.0, -12.0, wLeftY + 2.5);
    final wL3 = Path()
      ..moveTo(muzzleCenter.dx - 9, wLeftY + 2.5)
      ..quadraticBezierTo(size.width * 0.12, wLeftY + 7.0, -8.0, wLeftY + 10.0);

    canvas.drawPath(wL1, whiskerPaint);
    canvas.drawPath(wL2, whiskerPaint);
    canvas.drawPath(wL3, whiskerPaint);

    // Right Whiskers
    final wRightY = muzzleCenter.dy;
    final wR1 = Path()
      ..moveTo(muzzleCenter.dx + 9, wRightY - 1.5)
      ..quadraticBezierTo(size.width * 0.9, wRightY - 6.0, size.width + 10.0, wRightY - 5.0);
    final wR2 = Path()
      ..moveTo(muzzleCenter.dx + 10, wRightY + 0.5)
      ..quadraticBezierTo(size.width * 0.9, wRightY + 1.0, size.width + 12.0, wRightY + 2.5);
    final wR3 = Path()
      ..moveTo(muzzleCenter.dx + 9, wRightY + 2.5)
      ..quadraticBezierTo(size.width * 0.88, wRightY + 7.0, size.width + 8.0, wRightY + 10.0);

    canvas.drawPath(wR1, whiskerPaint);
    canvas.drawPath(wR2, whiskerPaint);
    canvas.drawPath(wR3, whiskerPaint);
  }

  void _drawCatEar(Canvas canvas, Size earSize, Color outerColor, Color innerColor, {required bool isLeft}) {
    final earPath = Path()
      ..moveTo(-earSize.width * 0.5, 0)
      ..lineTo(0, -earSize.height)
      ..lineTo(earSize.width * 0.5, 0)
      ..close();

    canvas.drawPath(earPath, Paint()..color = outerColor);
    canvas.drawPath(earPath, Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);

    // Inner pink ear
    final innerEarPath = Path()
      ..moveTo(-earSize.width * 0.32, -1)
      ..lineTo(0, -earSize.height * 0.78)
      ..lineTo(earSize.width * 0.32, -1)
      ..close();
    canvas.drawPath(innerEarPath, Paint()..color = innerColor);

    // Fluffy ear furnishings (white tufts)
    final tuftPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(isLeft ? 2 : -2, -3), Offset(isLeft ? -3 : 3, -9), tuftPaint);
    canvas.drawLine(Offset(isLeft ? 1 : -1, -5), Offset(isLeft ? -4 : 4, -12), tuftPaint);
  }

  void _drawAlmondEye(Canvas canvas, Offset center, {required bool isLeft}) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(isLeft ? 0.08 : -0.08);

    const double w = 10.5;
    const double h = 9.0;

    final eyePath = Path();
    eyePath.moveTo(-w * 0.5, 0);
    eyePath.quadraticBezierTo(0, -h * 0.65, w * 0.5, 0);
    eyePath.quadraticBezierTo(0, h * 0.65, -w * 0.5, 0);
    eyePath.close();

    // Iris fill
    canvas.drawPath(eyePath, Paint()..color = const Color(0xFF0F172A));

    // Big pupil
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 7.0, height: 7.8), Paint()..color = const Color(0xFF020617));

    // Specular Catchlights
    canvas.drawCircle(const Offset(1.5, -1.8), 1.7, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(-1.5, 1.8), 0.9, Paint()..color = Colors.white.withValues(alpha: 0.9));

    // Upper cat eyeliner with wing
    final linerPath = Path()
      ..moveTo(-w * 0.5, 0)
      ..quadraticBezierTo(0, -h * 0.65, w * 0.5, 0)
      ..lineTo(isLeft ? -w * 0.58 : w * 0.58, -1.5);
    canvas.drawPath(linerPath, Paint()
      ..color = const Color(0xFF020617)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.3);

    canvas.restore();
  }

  void _drawHappyEye(Canvas canvas, Offset center) {
    final path = Path()
      ..moveTo(center.dx - 4.5, center.dy + 1.5)
      ..quadraticBezierTo(center.dx, center.dy - 3.5, center.dx + 4.5, center.dy + 1.5);
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.6);
  }

  void _drawBlinkEye(Canvas canvas, Offset center) {
    canvas.drawLine(
      Offset(center.dx - 4.0, center.dy),
      Offset(center.dx + 4.0, center.dy),
      Paint()
        ..color = const Color(0xFF0F172A)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _RealCatFacePainter oldDelegate) =>
      oldDelegate.isBlinking != isBlinking ||
      oldDelegate.isCompleted != isCompleted ||
      oldDelegate.earTwitch != earTwitch ||
      oldDelegate.catColor != catColor ||
      oldDelegate.earColor != earColor;
}
