import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// A playful pull-to-refresh indicator inspired by the cat motion video.
/// Features a seamless frameless design, a gentle short pull distance,
/// and an animated cat peeking up and rapidly swatting/patting a floating money slip.
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
  // Short effortless pull distance (46px instead of 75+px)
  static const double _triggerDistance = 46.0;
  static const double _refreshingHeight = 68.0;
  static const double _maxDragDisplacement = 88.0;

  double _dragOffset = 0.0;
  bool _isDragging = false;
  bool _isRefreshing = false;
  bool _isCompleted = false;
  bool _hasHapticed = false;

  late AnimationController _springBackController;
  late Animation<double> _springBackAnimation;

  // Paw swatting animation (rapid, playful tap ~340ms)
  late AnimationController _swatController;
  // Eye blinking / head bob animation
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();

    _springBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    _swatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void dispose() {
    _springBackController.dispose();
    _swatController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  void _startCatPlay() {
    if (!_swatController.isAnimating) {
      _swatController.repeat(reverse: true);
    }
    if (!_blinkController.isAnimating) {
      _blinkController.repeat();
    }
  }

  void _stopCatPlay() {
    _swatController.stop();
    _blinkController.stop();
  }

  void _updateDrag(double rawOffset) {
    if (_isRefreshing) return;

    // Responsive 1:0.82 touch ratio
    const resistance = 0.82;
    final newOffset = (rawOffset * resistance).clamp(0.0, _maxDragDisplacement);

    setState(() {
      _dragOffset = newOffset;
    });

    if (_dragOffset >= _triggerDistance) {
      if (!_hasHapticed) {
        HapticFeedback.lightImpact();
        _hasHapticed = true;
      }
      _startCatPlay();
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

      _startCatPlay();
      _animateTo(_refreshingHeight, durationMs: 180);

      try {
        await widget.onRefresh();
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        _isCompleted = true;
      });
      HapticFeedback.lightImpact();

      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;

      _animateTo(0.0, durationMs: 220, onDone: () {
        if (mounted) {
          setState(() {
            _isRefreshing = false;
            _isCompleted = false;
            _dragOffset = 0.0;
            _hasHapticed = false;
          });
          _stopCatPlay();
        }
      });
    } else {
      _animateTo(0.0, durationMs: 200, onDone: () {
        if (mounted) {
          setState(() {
            _dragOffset = 0.0;
            _hasHapticed = false;
          });
          _stopCatPlay();
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

  Color _getMascotPrimaryColor() {
    final id = widget.mascotId ?? 'cat_quill';
    if (id.contains('white')) return const Color(0xFFF1F5F9);
    if (id.contains('black')) return const Color(0xFF334155);
    if (id.contains('calico')) return const Color(0xFFE2E8F0);
    if (id.contains('pink')) return const Color(0xFFF472B6);
    if (id.contains('blue') || id.contains('cyber')) return const Color(0xFF0EA5E9);
    return const Color(0xFFF59E0B); // Default warm ginger/orange tabby
  }

  Color _getMascotEarColor() {
    final id = widget.mascotId ?? 'cat_quill';
    if (id.contains('white')) return const Color(0xFFFDA4AF);
    if (id.contains('black')) return const Color(0xFF1E293B);
    if (id.contains('calico')) return const Color(0xFFD97706);
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

          // Open, Frameless Cat Playing with Slip (Seamlessly revealed behind content)
          if (visibleHeight > 3.0)
            Positioned(
              top: topSafe + 6,
              left: 0,
              right: 0,
              height: visibleHeight,
              child: ClipRect(
                child: Opacity(
                  opacity: (visibleHeight / 20.0).clamp(0.0, 1.0),
                  child: _buildPlayfulCatScene(progress),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayfulCatScene(double progress) {
    final catColor = _getMascotPrimaryColor();
    final earColor = _getMascotEarColor();

    return AnimatedBuilder(
      animation: Listenable.merge([_swatController, _blinkController]),
      builder: (context, child) {
        final swatVal = _swatController.value;
        // Slip gently swings when the cat swats it
        final slipTilt = _isRefreshing ? (math.sin(swatVal * math.pi) * 0.12) : (progress * 0.04);
        final slipBounceY = _isRefreshing ? (math.sin(swatVal * math.pi) * 3.0) : 0.0;

        return Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Center Canvas: Cat on Right, Money Slip on Left/Center
            SizedBox(
              width: 220,
              height: 64,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. The Floating Money Slip (Being audited & patted)
                  Positioned(
                    left: 28,
                    bottom: 4 + slipBounceY,
                    child: Transform.rotate(
                      angle: -0.05 + slipTilt,
                      alignment: Alignment.topCenter,
                      child: _buildFloatingSlip(),
                    ),
                  ),

                  // 2. The Cat peeking up from the bottom edge
                  Positioned(
                    right: 28,
                    bottom: 0,
                    child: _buildPeekingCat(catColor, earColor, swatVal),
                  ),

                  // 3. Status Sparkle / Checkmark when completed
                  if (_isCompleted)
                    Positioned(
                      left: 48,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                            SizedBox(width: 3),
                            Text(
                              'เรียบร้อย!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
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

  Widget _buildFloatingSlip() {
    final isDark = widget.isDark;
    return Container(
      width: 44,
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header band
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.25),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 3),
            alignment: Alignment.centerLeft,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'KBank ฿',
                  style: TextStyle(
                    fontSize: 5.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981),
                  ),
                ),
                Icon(Icons.receipt_rounded, size: 6.5, color: Color(0xFF10B981)),
              ],
            ),
          ),

          // Body lines
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text(
                    '+฿ 500',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10B981),
                      letterSpacing: -0.2,
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 1.5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  Container(
                    width: 14,
                    height: 1.5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  // Dotted tear line at bottom
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (i) => Container(
                      width: 2,
                      height: 1,
                      color: isDark ? Colors.white24 : Colors.black26,
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

  Widget _buildPeekingCat(Color catColor, Color earColor, double swatVal) {
    final bool isBlinking = _blinkController.value > 0.94;
    // Paw reaches forward and taps down onto the slip
    final pawReachX = -12.0 - (swatVal * 16.0);
    final pawReachY = -18.0 - (math.sin(swatVal * math.pi) * 12.0);
    final pawRotation = -0.3 + (swatVal * 0.45);

    return SizedBox(
      width: 74,
      height: 58,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          // 1. Swatting Front Paw (Reaches out from cat's chest to bat the slip)
          Positioned(
            left: 20 + pawReachX,
            bottom: 22 + pawReachY,
            child: Transform.rotate(
              angle: pawRotation,
              alignment: Alignment.bottomRight,
              child: _buildSwattingPaw(catColor),
            ),
          ),

          // 2. Cat Body & Head Peeking Up
          Positioned(
            right: 4,
            bottom: -4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ears
                SizedBox(
                  width: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left Ear
                      CustomPaint(
                        size: const Size(12, 14),
                        painter: _EarPainter(outerColor: catColor, innerColor: earColor),
                      ),
                      // Right Ear
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
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

                      // Snout, Pink Nose & Mouth
                      Positioned(
                        bottom: 8,
                        child: Column(
                          children: [
                            // Pink nose
                            Container(
                              width: 5,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDA4AF),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 1),
                            // Muzzle smile (w)
                            CustomPaint(
                              size: const Size(10, 4),
                              painter: _MouthPainter(),
                            ),
                          ],
                        ),
                      ),

                      // Cute Cheeks
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

          // 3. Second resting paw resting at the edge
          Positioned(
            right: 38,
            bottom: 0,
            child: Container(
              width: 11,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwattingPaw(Color catColor) {
    return Container(
      width: 22,
      height: 13,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(-1, 2),
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
      // Happy curved closed eye (^•^)
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
      // Blinking eye line
      return Container(
        width: 7,
        height: 2,
        color: const Color(0xFF0F172A),
      );
    }

    // Wide open focused eye with white sparkle highlight
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
