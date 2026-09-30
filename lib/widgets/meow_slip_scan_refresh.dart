import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// A custom pull-to-refresh indicator that displays an animated
/// money slip scanner (horizontal scrolling receipts with laser scan effect).
class MeowSlipScanRefreshIndicator extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Color primaryColor;
  final bool isDark;
  final bool isEnglish;

  const MeowSlipScanRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    required this.primaryColor,
    required this.isDark,
    required this.isEnglish,
  });

  @override
  State<MeowSlipScanRefreshIndicator> createState() => _MeowSlipScanRefreshIndicatorState();
}

class _MeowSlipScanRefreshIndicatorState extends State<MeowSlipScanRefreshIndicator>
    with TickerProviderStateMixin {
  static const double _triggerDistance = 72.0;
  static const double _refreshingHeight = 84.0;
  static const double _maxDragDisplacement = 120.0;

  double _dragOffset = 0.0;
  bool _isDragging = false;
  bool _isRefreshing = false;
  bool _isCompleted = false;
  bool _hasHapticed = false;

  late AnimationController _springBackController;
  late Animation<double> _springBackAnimation;

  late AnimationController _conveyorController;
  late AnimationController _laserScanController;

  @override
  void initState() {
    super.initState();

    _springBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _conveyorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _laserScanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void dispose() {
    _springBackController.dispose();
    _conveyorController.dispose();
    _laserScanController.dispose();
    super.dispose();
  }

  void _startScanningAnimations() {
    if (!_conveyorController.isAnimating) {
      _conveyorController.repeat();
    }
    if (!_laserScanController.isAnimating) {
      _laserScanController.repeat(reverse: true);
    }
  }

  void _stopScanningAnimations() {
    _conveyorController.stop();
    _laserScanController.stop();
  }

  void _updateDrag(double rawOffset) {
    if (_isRefreshing) return;

    // Apply smooth rubber band resistance
    const resistance = 0.55;
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
      // Trigger refresh
      setState(() {
        _isRefreshing = true;
        _isCompleted = false;
      });

      _startScanningAnimations();

      // Animate to standard resting height during refresh
      _animateTo(_refreshingHeight, durationMs: 200);

      try {
        await widget.onRefresh();
      } catch (_) {}

      if (!mounted) return;

      // Show completed state briefly
      setState(() {
        _isCompleted = true;
      });
      HapticFeedback.lightImpact();

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      // Animate smoothly back to 0
      _animateTo(0.0, durationMs: 250, onDone: () {
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
      // Spring back to 0 without refreshing
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
          // 1. Content child translated smoothly by the pull distance
          Transform.translate(
            offset: Offset(0, visibleHeight),
            child: widget.child,
          ),

          // 2. Slip Scanner Refresh Header
          if (visibleHeight > 4.0)
            Positioned(
              top: topSafe + 8,
              left: 14,
              right: 14,
              child: Opacity(
                opacity: (visibleHeight / 24.0).clamp(0.0, 1.0),
                child: _buildScannerCard(progress),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerCard(double progress) {
    final isDark = widget.isDark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155).withValues(alpha: 0.9)
        : const Color(0xFFCBD5E1);

    String statusText;
    if (_isCompleted) {
      statusText = widget.isEnglish ? 'Scan complete • Updated!' : 'สแกนสำเร็จ • ข้อมูลเป็นปัจจุบัน';
    } else if (_isRefreshing) {
      statusText = widget.isEnglish ? 'Scanning slips & updating...' : 'กำลังสแกนสลิป & อัปเดตข้อมูล...';
    } else if (progress >= 1.0) {
      statusText = widget.isEnglish ? 'Release to scan' : 'ปล่อยเพื่อเริ่มสแกนสลิป';
    } else {
      statusText = widget.isEnglish ? 'Pull down to scan slips' : 'ดึงลงเพื่อสแกนสลิป & รีเฟรช';
    }

    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isRefreshing || progress >= 1.0
              ? const Color(0xFF10B981).withValues(alpha: 0.6)
              : borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          if (_isRefreshing || progress >= 1.0)
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Subtly shaded background
            Positioned.fill(
              child: Container(
                color: isDark
                    ? const Color(0xFF0F172A).withValues(alpha: 0.4)
                    : const Color(0xFFF8FAFC),
              ),
            ),

            // Top Status Bar: Title & Pill
            Positioned(
              top: 5,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.document_scanner_rounded,
                        size: 13,
                        color: _isCompleted
                            ? const Color(0xFF10B981)
                            : (_isRefreshing ? const Color(0xFF06B6D4) : widget.primaryColor),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: _isCompleted
                              ? const Color(0xFF10B981)
                              : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: _isRefreshing || progress >= 1.0
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _isRefreshing || progress >= 1.0
                            ? const Color(0xFF10B981).withValues(alpha: 0.4)
                            : Colors.transparent,
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
                            color: _isRefreshing || progress >= 1.0
                                ? const Color(0xFF10B981)
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 3.5),
                        Text(
                          'AI SCAN',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: _isRefreshing || progress >= 1.0
                                ? const Color(0xFF10B981)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Conveyor of Slips
            Positioned(
              left: 0,
              right: 0,
              bottom: 4,
              height: 48,
              child: AnimatedBuilder(
                animation: _conveyorController,
                builder: (context, child) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return _buildSlipConveyor(constraints.maxWidth);
                    },
                  );
                },
              ),
            ),

            // Laser Scanner Beam (Sweeping Horizontally across the slips)
            if (_isRefreshing || progress >= 0.7)
              Positioned(
                left: 0,
                right: 0,
                bottom: 4,
                height: 48,
                child: AnimatedBuilder(
                  animation: _laserScanController,
                  builder: (context, child) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final laserX = _laserScanController.value * (constraints.maxWidth - 20) + 10;
                        return Stack(
                          children: [
                            Positioned(
                              left: laserX - 10,
                              top: 0,
                              bottom: 0,
                              width: 20,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFF10B981).withValues(alpha: 0.35),
                                      const Color(0xFF06B6D4).withValues(alpha: 0.15),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: laserX - 1.5,
                              top: 2,
                              bottom: 2,
                              width: 3,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Color(0xFF38BDF8),
                                      Color(0xFF10B981),
                                      Color(0xFF38BDF8),
                                      Colors.transparent,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.8),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlipConveyor(double totalWidth) {
    const double slipWidth = 52.0;
    const double slipGap = 12.0;
    const double itemStride = slipWidth + slipGap;

    // Define 6 sample slips with diverse themes (Income, Expense, Bank transfers)
    final slipData = [
      _SlipData(title: '+฿500', color: const Color(0xFF10B981), isIncome: true, label: 'KBank'),
      _SlipData(title: '-฿65', color: const Color(0xFFEF4444), isIncome: false, label: 'อาหาร'),
      _SlipData(title: '฿1,200', color: const Color(0xFF6366F1), isIncome: true, label: 'SCB'),
      _SlipData(title: '-฿180', color: const Color(0xFFF59E0B), isIncome: false, label: 'ช้อปปิ้ง'),
      _SlipData(title: '+฿2,500', color: const Color(0xFF06B6D4), isIncome: true, label: 'เงินเดือน'),
      _SlipData(title: '-฿45', color: const Color(0xFFEC4899), isIncome: false, label: 'กาแฟ'),
    ];

    final double totalContentWidth = itemStride * slipData.length;
    // Calculate scroll offset based on animation controller (or drag offset if not refreshing)
    final double scrollOffset = _isRefreshing
        ? (_conveyorController.value * totalContentWidth)
        : (_dragOffset * 1.5) % totalContentWidth;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // We render cycles of the slip list to achieve smooth infinite scrolling
        for (int cycle = 0; cycle < 3; cycle++)
          for (int i = 0; i < slipData.length; i++)
            Positioned(
              left: (cycle * totalContentWidth + i * itemStride) - scrollOffset,
              top: 3,
              width: slipWidth,
              height: 42,
              child: _buildMiniSlipCard(slipData[i]),
            ),
      ],
    );
  }

  Widget _buildMiniSlipCard(_SlipData data) {
    final isDark = widget.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: data.color.withValues(alpha: isDark ? 0.4 : 0.35),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 3,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Colored Banner
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: isDark ? 0.3 : 0.18),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 3),
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data.label,
                  style: TextStyle(
                    fontSize: 6.5,
                    fontWeight: FontWeight.bold,
                    color: data.color,
                  ),
                ),
                Icon(Icons.receipt_rounded, size: 7, color: data.color),
              ],
            ),
          ),

          // Slip Body: Amount and Skeleton Lines
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: data.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Dotted / dashed placeholder line simulating receipt text
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 2,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Container(
                        width: 8,
                        height: 2,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom Dotted Border Effect
          CustomPaint(
            size: const Size(double.infinity, 3),
            painter: _DottedEdgePainter(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlipData {
  final String title;
  final Color color;
  final bool isIncome;
  final String label;

  _SlipData({
    required this.title,
    required this.color,
    required this.isIncome,
    required this.label,
  });
}

class _DottedEdgePainter extends CustomPainter {
  final Color color;

  _DottedEdgePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const double dotRadius = 1.2;
    const double gap = 4.0;
    double startX = 2.0;

    while (startX < size.width - 2.0) {
      canvas.drawCircle(Offset(startX, size.height / 2), dotRadius, paint);
      startX += gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedEdgePainter oldDelegate) => oldDelegate.color != color;
}
