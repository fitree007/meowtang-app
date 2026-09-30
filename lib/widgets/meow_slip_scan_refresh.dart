import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'meow_mascot_widget.dart';

/// A custom pull-to-refresh indicator featuring an animated Cat reading & inspecting a money slip
/// with laser scanning beam, paw-held receipt, and speech bubble status.
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
  static const double _triggerDistance = 75.0;
  static const double _refreshingHeight = 98.0;
  static const double _maxDragDisplacement = 135.0;

  double _dragOffset = 0.0;
  bool _isDragging = false;
  bool _isRefreshing = false;
  bool _isCompleted = false;
  bool _hasHapticed = false;

  late AnimationController _springBackController;
  late Animation<double> _springBackAnimation;

  late AnimationController _catBobController;
  late AnimationController _slipLaserController;
  late AnimationController _slipScrollController;

  @override
  void initState() {
    super.initState();

    _springBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _catBobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _slipLaserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _slipScrollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
  }

  @override
  void dispose() {
    _springBackController.dispose();
    _catBobController.dispose();
    _slipLaserController.dispose();
    _slipScrollController.dispose();
    super.dispose();
  }

  void _startScanningAnimations() {
    if (!_catBobController.isAnimating) {
      _catBobController.repeat(reverse: true);
    }
    if (!_slipLaserController.isAnimating) {
      _slipLaserController.repeat(reverse: true);
    }
    if (!_slipScrollController.isAnimating) {
      _slipScrollController.repeat();
    }
  }

  void _stopScanningAnimations() {
    _catBobController.stop();
    _slipLaserController.stop();
    _slipScrollController.stop();
  }

  void _updateDrag(double rawOffset) {
    if (_isRefreshing) return;

    const resistance = 0.58;
    final newOffset = (rawOffset * resistance).clamp(0.0, _maxDragDisplacement);

    setState(() {
      _dragOffset = newOffset;
    });

    if (_dragOffset >= _triggerDistance) {
      if (!_hasHapticed) {
        HapticFeedback.mediumImpact();
        _hasHapticed = true;
      }
      _startScanningAnimations();
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

      _startScanningAnimations();
      _animateTo(_refreshingHeight, durationMs: 220);

      try {
        await widget.onRefresh();
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        _isCompleted = true;
      });
      HapticFeedback.lightImpact();

      await Future.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;

      _animateTo(0.0, durationMs: 260, onDone: () {
        if (mounted) {
          setState(() {
            _isRefreshing = false;
            _isCompleted = false;
            _dragOffset = 0.0;
            _hasHapticed = false;
          });
          _stopScanningAnimations();
        }
      });
    } else {
      _animateTo(0.0, durationMs: 250, onDone: () {
        if (mounted) {
          setState(() {
            _dragOffset = 0.0;
            _hasHapticed = false;
          });
          _stopScanningAnimations();
        }
      });
    }
  }

  void _animateTo(double target, {int durationMs = 250, VoidCallback? onDone}) {
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
          // Content translated smoothly with pull distance
          Transform.translate(
            offset: Offset(0, visibleHeight),
            child: widget.child,
          ),

          // Cat Reading Slip Refresh Header
          if (visibleHeight > 6.0)
            Positioned(
              top: topSafe + 8,
              left: 14,
              right: 14,
              child: Opacity(
                opacity: (visibleHeight / 30.0).clamp(0.0, 1.0),
                child: _buildCatReadingScannerCard(progress),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCatReadingScannerCard(double progress) {
    final isDark = widget.isDark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = _isCompleted
        ? const Color(0xFF10B981)
        : (_isRefreshing || progress >= 1.0
            ? const Color(0xFF10B981).withValues(alpha: 0.6)
            : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)));

    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          if (_isRefreshing || progress >= 1.0)
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.18),
              blurRadius: 12,
              spreadRadius: 1,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          children: [
            // Soft gradient background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                        : [const Color(0xFFF8FAFC), const Color(0xFFEFF6FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // Main Content: [Cat with Slip] on Left + [Speech Bubble & Status] on Right
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // 1. Animated Reading Cat & Paw-held Slip
                  _buildCatWithSlip(progress),

                  const SizedBox(width: 14),

                  // 2. Interactive Speech Bubble & Status Info
                  Expanded(
                    child: _buildStatusBubble(progress),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatWithSlip(double progress) {
    return AnimatedBuilder(
      animation: _catBobController,
      builder: (context, child) {
        // Cat gently tilts head and bobs up and down when reading
        final bobY = _isRefreshing ? (math.sin(_catBobController.value * math.pi) * 3.0) : 0.0;
        final tiltAngle = _isRefreshing
            ? (math.sin(_catBobController.value * math.pi * 2) * 0.05)
            : 0.0;

        return Transform.translate(
          offset: Offset(0, bobY),
          child: Transform.rotate(
            angle: tiltAngle,
            child: SizedBox(
              width: 104,
              height: 74,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  // Cat Mascot Head
                  Positioned(
                    left: 2,
                    top: 2,
                    child: MeowMascotWidget(
                      size: 54,
                      isHeadOnly: true,
                      mascotId: widget.mascotId ?? 'cat_quill',
                      accessory: widget.mascotAccessory ?? 'none',
                      outfit: widget.mascotOutfit ?? 'none',
                      customPhotoPath: widget.customAvatarPath,
                      isCustomPhoto: widget.isCustomAvatarEnabled,
                    ),
                  ),

                  // Receipt Slip held in front of the Cat
                  Positioned(
                    left: 44,
                    top: 4,
                    child: _buildHeldSlip(),
                  ),

                  // Cat's Cute Paws holding the slip edges
                  Positioned(
                    left: 36,
                    top: 22,
                    child: _buildPaw(),
                  ),
                  Positioned(
                    left: 88,
                    top: 24,
                    child: _buildPaw(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeldSlip() {
    final isDark = widget.isDark;
    return Container(
      width: 52,
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Slip Header Band (Green KBank / SCB style)
                Container(
                  height: 12,
                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.centerLeft,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'KBank ฿',
                        style: TextStyle(
                          fontSize: 6.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      Icon(Icons.receipt_long_rounded, size: 8, color: Color(0xFF10B981)),
                    ],
                  ),
                ),

                // Slip Body with Amount & Skeleton lines
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '+฿ 500.00',
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10B981),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 28,
                          height: 2,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 18,
                          height: 2,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const Spacer(),
                        // Mini Barcode at bottom of slip
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(6, (index) {
                            return Container(
                              width: (index % 2 == 0) ? 1.5 : 2.5,
                              height: 6,
                              color: isDark ? Colors.white30 : Colors.black26,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),

                // Jagged bottom edge
                CustomPaint(
                  size: const Size(double.infinity, 3),
                  painter: _ZigZagEdgePainter(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  ),
                ),
              ],
            ),

            // Laser Beam Scanning down the Slip
            if (_isRefreshing || _dragOffset >= _triggerDistance * 0.7)
              AnimatedBuilder(
                animation: _slipLaserController,
                builder: (context, child) {
                  final laserY = _slipLaserController.value * 52.0 + 8.0;
                  return Positioned(
                    top: laserY,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2.2,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFF38BDF8),
                            Color(0xFF10B981),
                            Color(0xFF38BDF8),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.9),
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaw() {
    return Container(
      width: 13,
      height: 11,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 5,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFFDA4AF), // Pink paw pad
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBubble(double progress) {
    final isDark = widget.isDark;

    String title;
    String subtitle;
    Color accentColor;
    IconData icon;

    if (_isCompleted) {
      title = widget.isEnglish ? 'Scan Complete! ✨' : 'ตรวจสลิปเรียบร้อยแล้วเหมียว! ✨';
      subtitle = widget.isEnglish ? 'Transactions up to date' : 'ข้อมูลการเงินเป็นปัจจุบันแล้ว';
      accentColor = const Color(0xFF10B981);
      icon = Icons.check_circle_rounded;
    } else if (_isRefreshing) {
      title = widget.isEnglish ? 'Cat is checking slip... 🔍' : 'เหมียวกำลังตรวจสลิปอยู่นะ... 🔍';
      subtitle = widget.isEnglish ? 'Auditing numbers & syncing' : 'กำลังอ่านยอดเงิน & รีเฟรชข้อมูล';
      accentColor = const Color(0xFF06B6D4);
      icon = Icons.manage_search_rounded;
    } else if (progress >= 1.0) {
      title = widget.isEnglish ? 'Release for cat to read!' : 'ปล่อยให้เหมียวอ่านสลิปเลย!';
      subtitle = widget.isEnglish ? 'Release screen to start' : 'ปล่อยมือเพื่อเริ่มสแกนสลิป';
      accentColor = const Color(0xFF10B981);
      icon = Icons.touch_app_rounded;
    } else {
      title = widget.isEnglish ? 'Pull down for cat to read' : 'ดึงลงให้เหมียวอ่านสลิป 🐾';
      subtitle = widget.isEnglish ? 'Pull a bit more to scan' : 'ดึงลงอีกนิดเพื่อตรวจสลิป';
      accentColor = widget.primaryColor;
      icon = Icons.arrow_downward_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // AI Pill
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isRefreshing || progress >= 1.0 ? 'AI AUDITING' : 'CAT SCANNER',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, size: 14, color: accentColor),
          ],
        ),

        const SizedBox(height: 5),

        // Title
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _isCompleted ? const Color(0xFF10B981) : (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),

        const SizedBox(height: 2),

        // Subtitle
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _ZigZagEdgePainter extends CustomPainter {
  final Color color;

  _ZigZagEdgePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const toothWidth = 4.0;
    const toothHeight = 3.0;
    int count = (size.width / toothWidth).ceil();

    path.moveTo(0, 0);
    for (int i = 0; i < count; i++) {
      path.lineTo((i * toothWidth) + (toothWidth / 2), toothHeight);
      path.lineTo((i + 1) * toothWidth, 0);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ZigZagEdgePainter oldDelegate) => oldDelegate.color != color;
}
