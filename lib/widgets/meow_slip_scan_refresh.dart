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
  bool _isRefreshing = false;
  bool _isCompleted = false;
  bool _hasHapticed = false;

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

    // Continuous curved swiping loop (~580ms per swipe)
    _arcSwipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 580),
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
      if (!_hasHapticed) {
        HapticFeedback.lightImpact();
        _hasHapticed = true;
      }
      _startSwipeLoop();
    } else {
      _hasHapticed = false;
    }
  }

  Future<void> _handleRelease() async {
    if (_isRefreshing) return;

    if (_dragOffset >= _triggerDistance) {
      setState(() {
        _isRefreshing = true;
        _isCompleted = false;
      });

      _startSwipeLoop();
      _animateTo(_refreshingHeight, durationMs: 180);

      try {
        await widget.onRefresh();
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        _isCompleted = true;
      });
      HapticFeedback.lightImpact();

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      _animateTo(0.0, durationMs: 220, onDone: () {
        if (mounted) {
          setState(() {
            _isRefreshing = false;
            _isCompleted = false;
            _dragOffset = 0.0;
            _hasHapticed = false;
          });
          _stopSwipeLoop();
        }
      });
    } else {
      _animateTo(0.0, durationMs: 200, onDone: () {
        if (mounted) {
          setState(() {
            _dragOffset = 0.0;
            _hasHapticed = false;
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
    if (notification is ScrollStartNotification) {
      if (notification.metrics.extentBefore == 0) {
        _isDragging = true;
      }
    } else if (notification is ScrollUpdateNotification) {
      if (_isDragging && !_isRefreshing) {
        if (notification.metrics.pixels < 0) {
          _updateDrag(-notification.metrics.pixels);
        } else if (_dragOffset > 0 && notification.scrollDelta != null && notification.scrollDelta! > 0) {
          _updateDrag(_dragOffset - notification.scrollDelta!);
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
    final double visibleHeight = _dragOffset;
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
    // We render two slips staggered along the curved arc to the left
    // The arc starts in front of the cat (right) and swoops curved downwards and leftwards
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildSingleArcSlip(swipeT),
        // Staggered second slip following in the queue
        _buildSingleArcSlip((swipeT + 0.5) % 1.0),
      ],
    );
  }

  Widget _buildSingleArcSlip(double t) {
    // Semi-circular curved arc from right (x ~ 140) to left (x ~ 10)
    // Angle goes from 0 (right) to PI (left)
    final arcAngle = t * math.pi;

    // Center of the arc ellipse
    const double centerX = 80.0;
    const double radiusX = 65.0;
    const double radiusY = 22.0;

    // Curved semi-circular coordinates (swoop down and to the left)
    final posX = centerX + math.cos(arcAngle) * radiusX;
    final posY = 20.0 + math.sin(arcAngle) * radiusY;

    // Rotation tilting along the curved arc
    final tiltAngle = -0.4 + (math.sin(arcAngle) * 0.7) - (t * 0.5);

    // Fade out as it flings far to the left
    final opacity = (1.0 - (t * 0.65)).clamp(0.0, 1.0);

    return Positioned(
      left: posX,
      bottom: posY,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: tiltAngle,
          alignment: Alignment.center,
          child: _buildDarkGraySlip(),
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

  Widget _buildCatWithArcPaw(Color catColor, Color earColor, double swipeT) {
    final bool isBlinking = _idleCatController.value > 0.94;

    // Semi-circular arc trajectory for the swiping paw
    // The paw sweeps from right to left in a curved semi-circle
    final arcAngle = swipeT * math.pi;
    final pawArcX = -10.0 - (math.cos(arcAngle) * 24.0);
    final pawArcY = 16.0 - (math.sin(arcAngle) * 14.0);
    final pawRotation = -0.4 + (math.sin(arcAngle) * 0.7);

    return SizedBox(
      width: 78,
      height: 58,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          // 1. Swatting Front Paw following the curved arc to the left
          Positioned(
            left: pawArcX,
            bottom: pawArcY,
            child: Transform.rotate(
              angle: pawRotation,
              alignment: Alignment.bottomRight,
              child: _buildSwipingPaw(catColor),
            ),
          ),

          // 2. Peeking Cat Head & Upper Body
          Positioned(
            right: 0,
            bottom: -3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ears
                SizedBox(
                  width: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomPaint(
                        size: const Size(12, 14),
                        painter: _EarPainter(outerColor: catColor, innerColor: earColor),
                      ),
                      Transform.scale(
                        scaleX: -1,
                        child: CustomPaint(
                          size: const Size(12, 14),
                          painter: _EarPainter(outerColor: catColor, innerColor: earColor),
                        ),
                      ),
                    ],
                  ),
                ),

                // Head Round Shape
                Container(
                  width: 50,
                  height: 38,
                  decoration: BoxDecoration(
                    color: catColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Eyes
                      Positioned(
                        top: 10,
                        left: 10,
                        right: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildEye(isBlinking),
                            _buildEye(isBlinking),
                          ],
                        ),
                      ),

                      // Nose & Mouth (w)
                      Positioned(
                        bottom: 8,
                        child: Column(
                          children: [
                            Container(
                              width: 5,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDA4AF),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 1),
                            CustomPaint(
                              size: const Size(10, 4),
                              painter: _MouthPainter(),
                            ),
                          ],
                        ),
                      ),

                      // Cheeks
                      Positioned(
                        bottom: 11,
                        left: 6,
                        child: Container(
                          width: 6,
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDA4AF).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 11,
                        right: 6,
                        child: Container(
                          width: 6,
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDA4AF).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Resting Left Paw on the edge
          Positioned(
            right: 36,
            bottom: 0,
            child: Container(
              width: 11,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipingPaw(Color catColor) {
    return Container(
      width: 22,
      height: 13,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(-1, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            width: 3.5,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFFDA4AF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 4,
            height: 7,
            decoration: BoxDecoration(
              color: const Color(0xFFFDA4AF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 3.5,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFFDA4AF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEye(bool isBlinking) {
    if (_isCompleted) {
      return Container(
        width: 8,
        height: 4,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF0F172A), width: 2),
          ),
        ),
      );
    }

    if (isBlinking) {
      return Container(
        width: 7,
        height: 2,
        color: const Color(0xFF0F172A),
      );
    }

    return Container(
      width: 7.5,
      height: 7.5,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        shape: BoxShape.circle,
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Container(
          width: 2.5,
          height: 2.5,
          margin: const EdgeInsets.only(top: 1, right: 1),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _EarPainter extends CustomPainter {
  final Color outerColor;
  final Color innerColor;

  _EarPainter({required this.outerColor, required this.innerColor});

  @override
  void paint(Canvas canvas, Size size) {
    final outerPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.4, 0)
      ..lineTo(size.width, size.height)
      ..close();

    final innerPath = Path()
      ..moveTo(size.width * 0.25, size.height)
      ..lineTo(size.width * 0.45, size.height * 0.35)
      ..lineTo(size.width * 0.8, size.height)
      ..close();

    canvas.drawPath(outerPath, Paint()..color = outerColor);
    canvas.drawPath(innerPath, Paint()..color = innerColor);
  }

  @override
  bool shouldRepaint(covariant _EarPainter oldDelegate) =>
      oldDelegate.outerColor != outerColor || oldDelegate.innerColor != innerColor;
}

class _MouthPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.75, size.height, size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
