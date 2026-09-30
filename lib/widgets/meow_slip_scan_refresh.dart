import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A charming, polished pull-to-refresh indicator featuring the user's authentic
/// 3D clay/chibi mascot cat with independently animated head and raised right arm,
/// synchronized 1:1 with passing money slips that receive a cute pink paw stamp (🐾)
/// upon being patted!
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
  // Effortless single-pull trigger distance (38px)
  static const double _triggerDistance = 38.0;
  static const double _refreshingHeight = 80.0;
  static const double _maxDragDisplacement = 98.0;

  double _dragOffset = 0.0;
  double _pointerStartY = 0.0;
  bool _isPointerTracking = false;
  bool _canRefresh = false;
  bool _isRefreshing = false;
  bool _isCompleted = false;

  ScrollMetrics? _lastScrollMetrics;

  late AnimationController _springBackController;
  late Animation<double> _springBackAnimation;

  // Slip conveyor & swatting cadence controller (steady ~2100ms per 3-slip loop, 700ms/slip)
  late AnimationController _conveyorController;
  // Gentle head tilt & bobbing breathing controller (~2200ms per loop)
  late AnimationController _idleCatController;

  @override
  void initState() {
    super.initState();

    _springBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    _conveyorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    );

    _idleCatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _idleCatController.repeat();
  }

  @override
  void dispose() {
    _springBackController.dispose();
    _conveyorController.dispose();
    _idleCatController.dispose();
    super.dispose();
  }

  void _startSwipeLoop() {
    if (!_conveyorController.isAnimating) {
      _conveyorController.repeat();
    }
  }

  void _stopSwipeLoop() {
    _conveyorController.stop();
  }

  void _updateDrag(double rawOffset) {
    if (_isRefreshing) return;

    const resistance = 0.88;
    final newOffset = (rawOffset * resistance).clamp(0.0, _maxDragDisplacement);

    setState(() {
      _dragOffset = newOffset;
    });

    if (_dragOffset >= _triggerDistance) {
      if (!_canRefresh) {
        _canRefresh = true;
        HapticFeedback.mediumImpact();
      }
      _startSwipeLoop();
    } else if (_dragOffset <= 4.0) {
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

      // Lock and hold refresh screen firmly for at least 3.2 seconds
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

  @override
  Widget build(BuildContext context) {
    final double topSafe = MediaQuery.of(context).padding.top;
    final double visibleHeight = _isRefreshing ? math.max(_dragOffset, _refreshingHeight) : _dragOffset;
    final double progress = (_dragOffset / _triggerDistance).clamp(0.0, 1.0);

    return Listener(
      // Direct Pointer Event tracking: intercepts single downward drag from the top
      onPointerDown: (e) {
        if (_isRefreshing) return;
        final pixels = _lastScrollMetrics?.pixels ?? 0.0;
        if (pixels <= 0.0) {
          _pointerStartY = e.position.dy;
          _isPointerTracking = true;
        }
      },
      onPointerMove: (e) {
        if (_isRefreshing || !_isPointerTracking) return;
        final dy = e.position.dy - _pointerStartY;
        if (dy > 0) {
          _updateDrag(dy);
        }
      },
      onPointerUp: (e) {
        if (_isPointerTracking) {
          _isPointerTracking = false;
          _handleRelease();
        }
      },
      onPointerCancel: (e) {
        if (_isPointerTracking) {
          _isPointerTracking = false;
          _handleRelease();
        }
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          _lastScrollMetrics = notification.metrics;
          if (notification is ScrollEndNotification) {
            if (_isPointerTracking) {
              _isPointerTracking = false;
              _handleRelease();
            }
          }
          return false;
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Content translated smoothly down by pull distance
            Transform.translate(
              offset: Offset(0, visibleHeight),
              child: widget.child,
            ),

            // Frameless, balanced 3D refresh stage
            if (visibleHeight > 3.0)
              Positioned(
                top: topSafe + 2,
                left: 0,
                right: 0,
                height: visibleHeight,
                child: ClipRect(
                  child: Opacity(
                    opacity: (visibleHeight / 16.0).clamp(0.0, 1.0),
                    child: _buildRefreshStage(progress),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshStage(double progress) {
    return AnimatedBuilder(
      animation: Listenable.merge([_conveyorController, _idleCatController]),
      builder: (context, child) {
        final swipeT = _isRefreshing ? _conveyorController.value : (progress * 0.4);

        return Center(
          child: SizedBox(
            width: 290,
            height: 76,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Slip Conveyor Stream: Positioned closely adjacent to the cat
                Positioned(
                  left: 14,
                  top: 10,
                  child: SizedBox(
                    width: 195,
                    height: 52,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildSingleConveyorSlip(swipeT),
                        _buildSingleConveyorSlip((swipeT + 0.3333) % 1.0),
                        _buildSingleConveyorSlip((swipeT + 0.6667) % 1.0),

                        // Subtle scanner laser beam
                        Positioned(
                          left: 78,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFF38BDF8).withValues(alpha: 0.8),
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. The User's Authentic 3D Chibi Mascot Cat with Synchronized Arm & Head
                Positioned(
                  right: 20,
                  bottom: 10,
                  child: _build3DAnimatedCat(swipeT),
                ),

                // 3. Status Badge / Completion Pill at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _isCompleted
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(color: Color(0x5510B981), blurRadius: 6),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_rounded, color: Colors.white, size: 10),
                                const SizedBox(width: 3.5),
                                Text(
                                  widget.isEnglish ? 'Done!' : 'เรียบร้อย!',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                widget.isEnglish ? 'Scanning slips...' : 'กำลังสแกนสลิป...',
                                style: TextStyle(
                                  color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// The user's authentic 3D clay/chibi mascot cat with:
  /// - Independently animated head (tilting & nodding with breathing rhythm)
  /// - Independently animated raised right arm with 1:1 synchronized swatting
  /// - Solid base body with blue fabric collar and golden bell
  Widget _build3DAnimatedCat(double swipeT) {
    const double catSize = 66.0;

    // Head animation: gentle playful tilt around neck
    final double headT = _idleCatController.value;
    final double headAngle = math.sin(headT * math.pi * 2) * 0.052;
    final double headBobY = math.cos(headT * math.pi * 2) * 1.2;

    // 1:1 Synchronized Swatting Cadence:
    // Subphase 0.0 to 1.0 matches each passing slip
    final double subPhase = (swipeT * 3.0) % 1.0;
    double armAngle;
    if (subPhase < 0.35) {
      final p = subPhase / 0.35;
      armAngle = math.sin(p * math.pi * 0.5) * 0.16; // Prepares & lifts paw back (+9°)
    } else if (subPhase < 0.50) {
      final p = (subPhase - 0.35) / 0.15;
      armAngle = 0.16 - (p * 0.58); // STRIKES down onto the slip (-24°) at impact (0.50)!
    } else if (subPhase < 0.75) {
      final p = (subPhase - 0.50) / 0.25;
      armAngle = -0.42 + (p * 0.28); // Sweeps slip leftwards
    } else {
      final p = (subPhase - 0.75) / 0.25;
      armAngle = -0.14 * (1.0 - p); // Smoothly returns to ready
    }

    return SizedBox(
      width: catSize,
      height: catSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Cat Body Layer (Base, blue collar & golden bell)
          Positioned.fill(
            child: Image.asset(
              'assets/icons/mascot_3d/cat_3d_body.png',
              width: catSize,
              height: catSize,
              fit: BoxFit.contain,
              errorBuilder: (_, error, stack) => const SizedBox.shrink(),
            ),
          ),

          // 2. Cat Arm Layer (Raised paw with pink pads, rotating around shoulder pivot)
          Positioned.fill(
            child: Transform(
              alignment: const Alignment(-0.28, 0.78), // Shoulder joint pivot
              transform: Matrix4.identity()..rotateZ(armAngle),
              child: Image.asset(
                'assets/icons/mascot_3d/cat_3d_arm.png',
                width: catSize,
                height: catSize,
                fit: BoxFit.contain,
                errorBuilder: (_, error, stack) => const SizedBox.shrink(),
              ),
            ),
          ),

          // 3. Cat Head Layer (Tilting & bobbing around neck pivot)
          Positioned.fill(
            child: Transform(
              alignment: const Alignment(0.12, 0.46), // Neck joint pivot
              transform: Matrix4.identity()
                ..setTranslationRaw(0.0, headBobY, 0.0)
                ..rotateZ(headAngle),
              child: Image.asset(
                'assets/icons/mascot_3d/cat_3d_head.png',
                width: catSize,
                height: catSize,
                fit: BoxFit.contain,
                errorBuilder: (_, error, stack) => Image.asset(
                  'assets/icons/mascot_3d/cat_3d_transparent.png',
                  width: catSize,
                  height: catSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleConveyorSlip(double u) {
    // Slips glide from 155 (right, under cat paw) to -35 (left)
    final double posX = 155.0 - (u * 190.0);
    final double dip = math.sin(u * math.pi) * 3.2;
    final double tilt = math.sin(u * math.pi) * -0.06;

    // Has paw stamp been printed?
    // At u >= 0.22, the slip has passed under the cat's striking paw and received the paw stamp!
    final bool hasStamp = u >= 0.22 && u <= 0.95;

    // Smooth opacity fade on entry and exit
    double opacity = 1.0;
    if (u < 0.10) {
      opacity = (u / 0.10).clamp(0.0, 1.0);
    } else if (u > 0.88) {
      opacity = ((1.0 - u) / 0.12).clamp(0.0, 1.0);
    }

    return Positioned(
      left: posX,
      top: 3 + dip,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: tilt,
          child: _buildDarkGraySlip(hasStamp: hasStamp),
        ),
      ),
    );
  }

  /// Minimalist Dark-Gray Money Slip with Cute Pink Paw Stamp 🐾
  Widget _buildDarkGraySlip({required bool hasStamp}) {
    return Container(
      width: 35,
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark slate gray base
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: hasStamp ? const Color(0xFF64748B) : const Color(0xFF475569),
          width: 0.9,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x35000000),
            blurRadius: 4,
            offset: Offset(0, 1.5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dark Gray Top Band (Neutral, no bank name)
              Container(
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF334155),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 10,
                      height: 1.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF94A3B8),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const Icon(Icons.receipt_rounded, size: 5.5, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),

              // Slip Body: Neutral Gray Lines & Currency Placeholder
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Text(
                        '฿ •••••',
                        style: TextStyle(
                          fontSize: 5.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFCBD5E1),
                          letterSpacing: -0.2,
                          height: 1,
                        ),
                      ),
                      Container(
                        width: 16,
                        height: 1.2,
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      Container(
                        width: 10,
                        height: 1.2,
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      // Bottom barcode dashes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(4, (i) => Container(
                          width: 1.2,
                          height: 3,
                          color: const Color(0xFF475569),
                        )),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Cute Pink Paw Stamp Overlay (🐾)
          if (hasStamp)
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
                  child: const Icon(
                    Icons.pets_rounded,
                    color: Color(0xFFF472B6), // Cute pink stamp
                    size: 15,
                    shadows: [
                      Shadow(color: Color(0x88F472B6), blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
