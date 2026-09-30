import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'meow_mascot_widget.dart';

/// A charming, polished pull-to-refresh indicator featuring the authentic MeowTang
/// mascot cat playfully swatting dark-gray money slips along a smooth conveyor stream.
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
  static const double _refreshingHeight = 72.0;
  static const double _maxDragDisplacement = 88.0;

  double _dragOffset = 0.0;
  bool _isDragging = false;
  bool _canRefresh = false;
  bool _isRefreshing = false;
  bool _isCompleted = false;

  late AnimationController _springBackController;
  late Animation<double> _springBackAnimation;

  // Continuous conveyor swipe controller (~1600ms per loop)
  late AnimationController _conveyorController;
  // Subtle bobbing & breathing controller
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
    _conveyorController.dispose();
    _idleCatController.dispose();
    super.dispose();
  }

  void _startSwipeLoop() {
    if (!_conveyorController.isAnimating) {
      _conveyorController.repeat();
    }
    if (!_idleCatController.isAnimating) {
      _idleCatController.repeat();
    }
  }

  void _stopSwipeLoop() {
    _conveyorController.stop();
    _idleCatController.stop();
  }

  void _updateDrag(double rawOffset) {
    if (_isRefreshing) return;

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

          // Frameless, balanced refresh stage
          if (visibleHeight > 3.0)
            Positioned(
              top: topSafe + 2,
              left: 0,
              right: 0,
              height: visibleHeight,
              child: ClipRect(
                child: Opacity(
                  opacity: (visibleHeight / 18.0).clamp(0.0, 1.0),
                  child: _buildRefreshStage(progress),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRefreshStage(double progress) {
    return AnimatedBuilder(
      animation: Listenable.merge([_conveyorController, _idleCatController]),
      builder: (context, child) {
        final swipeT = _isRefreshing ? _conveyorController.value : (progress * 0.4);
        final catBob = math.sin(_idleCatController.value * math.pi * 2) * 1.5;

        return Center(
          child: SizedBox(
            width: 260,
            height: 68,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Slip Conveyor Stream (3 dark-gray slips moving smoothly leftwards)
                Positioned(
                  left: 12,
                  top: 6,
                  child: SizedBox(
                    width: 140,
                    height: 48,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildSingleConveyorSlip(swipeT),
                        _buildSingleConveyorSlip((swipeT + 0.3333) % 1.0),
                        _buildSingleConveyorSlip((swipeT + 0.6667) % 1.0),

                        // Subtle scanner laser beam
                        Positioned(
                          left: 54,
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
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Official MeowTang Mascot Cat (Round, Kawaii, Adorable)
                Positioned(
                  right: 14,
                  bottom: 12 + catBob,
                  child: MeowMascotWidget(
                    size: 52,
                    mascotId: widget.mascotId,
                    accessory: widget.mascotAccessory,
                    outfit: widget.mascotOutfit,
                    customPhotoPath: widget.customAvatarPath,
                    isCustomPhoto: widget.isCustomAvatarEnabled,
                    withPen: false,
                    isHeadOnly: true,
                  ),
                ),

                // 3. Cute Chubby Paw playfully swiping over the passing slips
                Positioned(
                  right: 50,
                  bottom: 18 + catBob,
                  child: _buildCuteChubbyPaw(swipeT),
                ),

                // 4. Status Badge / Completion Pill at bottom
                Positioned(
                  bottom: 1,
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

  Widget _buildSingleConveyorSlip(double u) {
    // Slips glide smoothly from right (120) to left (-10)
    final double posX = 120.0 - (u * 135.0);
    final double dip = math.sin(u * math.pi) * 4.0;
    final double tilt = math.sin(u * math.pi) * -0.08;

    // Smooth opacity fade on entry and exit
    double opacity = 1.0;
    if (u < 0.15) {
      opacity = (u / 0.15).clamp(0.0, 1.0);
    } else if (u > 0.85) {
      opacity = ((1.0 - u) / 0.15).clamp(0.0, 1.0);
    }

    return Positioned(
      left: posX,
      top: 2 + dip,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: tilt,
          child: _buildDarkGraySlip(),
        ),
      ),
    );
  }

  /// Minimalist Dark-Gray Money Slip (Neutral slate/dark gray only, no bank branding)
  Widget _buildDarkGraySlip() {
    return Container(
      width: 34,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark slate gray base
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: const Color(0xFF475569), // Muted slate gray border
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
      child: Column(
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
    );
  }

  /// Cute, chubby white kitten paw with pink toe beans and soft batting movement
  Widget _buildCuteChubbyPaw(double swipeT) {
    final double phase = (swipeT * 3.0) % 1.0;

    double dx;
    double dy;
    double angle;
    if (phase < 0.40) {
      final p = phase / 0.40;
      final ease = math.sin(p * math.pi);
      dx = -ease * 12.0;
      dy = -math.sin(p * math.pi * 0.5) * 3.0 + (p * 5.0);
      angle = -ease * 0.32;
    } else {
      final r = (phase - 0.40) / 0.60;
      final ease = (1.0 - math.cos(r * math.pi)) * 0.5;
      dx = -12.0 * (1.0 - ease);
      dy = 2.0 * (1.0 - ease);
      angle = -0.32 * (1.0 - ease);
    }

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: angle,
        alignment: Alignment.bottomRight,
        child: Container(
          width: 22,
          height: 17,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.5),
            border: Border.all(
              color: widget.isDark ? const Color(0xFF64748B) : const Color(0xFFFDBA74),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 3,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 1.5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 3 mini pink toe beans
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (i) => Container(
                  width: 2.8,
                  height: 3.2,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDA4AF),
                    borderRadius: BorderRadius.circular(1.2),
                  ),
                )),
              ),
              // Center heart/palm pad
              Container(
                width: 7.5,
                height: 5.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDA4AF),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
