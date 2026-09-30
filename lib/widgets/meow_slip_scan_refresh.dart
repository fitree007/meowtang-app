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

      // Hold refresh screen for at least 3.2 seconds for full animation enjoyment
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

  /// Cat with a visible forearm connected directly to its shoulder and body
  Widget _buildCatWithArcPaw(Color catColor, Color earColor, double swipeT) {
    final bool isBlinking = _idleCatController.value > 0.94;

    // The swat cadence synchronizes with the 3 passing slips
    final double swatPhase = (swipeT * 3.0) % 1.0;
    double pawX;
    double pawY;
    double pawRotation;

    if (swatPhase < 0.45) {
      // Swatting forward
      final double s = swatPhase / 0.45;
      final double ease = math.sin(s * math.pi * 0.5);
      pawX = 46.0 - (ease * 38.0); // 46 -> 8
      pawY = 34.0 + (math.sin(s * math.pi) * 8.0);
      pawRotation = -0.15 - (ease * 0.65);
    } else {
      // Returning to ready position
      final double r = (swatPhase - 0.45) / 0.55;
      final double ease = (1.0 - math.cos(r * math.pi)) * 0.5;
      pawX = 8.0 + (ease * 38.0); // 8 -> 46
      pawY = 34.0;
      pawRotation = -0.80 + (ease * 0.65);
    }

    const Offset shoulder = Offset(68.0, 36.0);
    final Offset wrist = Offset(pawX + 11.0, pawY + 6.0);

    return SizedBox(
      width: 108,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Forearm connecting cat's shoulder to the swiping paw
          CustomPaint(
            size: const Size(108, 60),
            painter: _CatArmPainter(
              armColor: catColor,
              shoulder: shoulder,
              wrist: wrist,
            ),
          ),

          // 2. Swatting Front Paw with toe beans
          Positioned(
            left: pawX,
            top: pawY,
            child: Transform.rotate(
              angle: pawRotation,
              alignment: Alignment.centerRight,
              child: _buildSwipingPaw(catColor),
            ),
          ),

          // 3. Peeking Cat Head & Upper Body with Kawaii features
          Positioned(
            right: 0,
            bottom: -2,
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
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
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
                      // Sparkling Anime Eyes
                      Positioned(
                        top: 9,
                        left: 9,
                        right: 9,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildKawaiiEye(isBlinking),
                            _buildKawaiiEye(isBlinking),
                          ],
                        ),
                      ),

                      // Cute White Muzzle, Pink Heart Nose & :3 Mouth
                      Positioned(
                        bottom: 6,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Soft white muzzle area with heart nose
                            Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                Container(
                                  width: 18,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(5),
                                    boxShadow: const [
                                      BoxShadow(color: Color(0x15000000), blurRadius: 1),
                                    ],
                                  ),
                                ),
                                // Tiny Pink Heart Nose
                                Positioned(
                                  top: -1,
                                  child: CustomPaint(
                                    size: const Size(5, 4),
                                    painter: _HeartNosePainter(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            // Sweet :3 Mouth
                            CustomPaint(
                              size: const Size(11, 4),
                              painter: _MouthPainter(),
                            ),
                          ],
                        ),
                      ),

                      // Rosy Blushing Cheeks with subtle blush slashes
                      Positioned(
                        bottom: 10,
                        left: 5,
                        child: _buildBlushCheek(isLeft: true),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 5,
                        child: _buildBlushCheek(isLeft: false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. Resting Left Paw on the front edge
          Positioned(
            right: 36,
            bottom: 0,
            child: Container(
              width: 12,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 0.7),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 2),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(2, (i) => Container(
                  width: 2,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDA4AF),
                    borderRadius: BorderRadius.circular(1),
                  ),
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlushCheek({required bool isLeft}) {
    return Container(
      width: 7,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFFDA4AF).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Text(
          isLeft ? '//' : '\\\\',
          style: const TextStyle(
            fontSize: 4,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF43F5E),
            height: 0.8,
          ),
        ),
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

  /// Big, expressive, sparkling anime/kawaii cat eyes
  Widget _buildKawaiiEye(bool isBlinking) {
    if (_isCompleted) {
      // Cheerful happy closed eye ^
      return SizedBox(
        width: 10,
        height: 7,
        child: CustomPaint(
          painter: _HappyEyePainter(),
        ),
      );
    }

    if (isBlinking) {
      // Cute blinking closed eye ‿
      return Container(
        width: 8,
        height: 2,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(1),
        ),
      );
    }

    // Sparkly anime eye with twin catchlights
    return Container(
      width: 9.5,
      height: 10.5,
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Stack(
        children: [
          // Primary big sparkle at top-right
          Positioned(
            top: 1.5,
            right: 1.5,
            child: Container(
              width: 3.5,
              height: 3.5,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Secondary twinkle sparkle at bottom-left
          Positioned(
            bottom: 2.0,
            left: 1.8,
            child: Container(
              width: 1.8,
              height: 1.8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter that connects the cat's shoulder to the swiping paw
class _CatArmPainter extends CustomPainter {
  final Color armColor;
  final Offset shoulder;
  final Offset wrist;

  _CatArmPainter({
    required this.armColor,
    required this.shoulder,
    required this.wrist,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dx = wrist.dx - shoulder.dx;
    final dy = wrist.dy - shoulder.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 4.0) return;

    final nx = -dy / dist;
    final ny = dx / dist;

    const double rShoulder = 6.5;
    const double rWrist = 4.8;

    final midX = (shoulder.dx + wrist.dx) * 0.5 + (nx * 3.5);
    final midY = (shoulder.dy + wrist.dy) * 0.5 + (ny * 3.5);

    final path = Path()
      ..moveTo(shoulder.dx + nx * rShoulder, shoulder.dy + ny * rShoulder)
      ..quadraticBezierTo(midX + nx * 4.5, midY + ny * 4.5, wrist.dx + nx * rWrist, wrist.dy + ny * rWrist)
      ..lineTo(wrist.dx - nx * rWrist, wrist.dy - ny * rWrist)
      ..quadraticBezierTo(midX - nx * 4.5, midY - ny * 4.5, shoulder.dx - nx * rShoulder, shoulder.dy - ny * rShoulder)
      ..close();

    final shadowPaint = Paint()
      ..color = const Color(0x22000000)
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
  bool shouldRepaint(covariant _CatArmPainter oldDelegate) =>
      oldDelegate.wrist != wrist ||
      oldDelegate.shoulder != shoulder ||
      oldDelegate.armColor != armColor;
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
      ..color = const Color(0xFF334155)
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

class _HeartNosePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFB7185)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.5, size.height);
    path.cubicTo(
      0, size.height * 0.5,
      0, 0,
      size.width * 0.5, size.height * 0.3,
    );
    path.cubicTo(
      size.width, 0,
      size.width, size.height * 0.5,
      size.width * 0.5, size.height,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HappyEyePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width * 0.5, 0, size.width, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
