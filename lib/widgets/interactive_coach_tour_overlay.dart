import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/meow_theme.dart';
import '../widgets/tactile_button.dart';

enum CoachTargetType {
  headerMascot,
  quickAnalytics,
  voiceButton,
  slipButton,
  transactionList,
  fabButton,
}

class CoachTourStepData {
  final String title;
  final String description;
  final IconData icon;
  final CoachTargetType targetType;

  const CoachTourStepData({
    required this.title,
    required this.description,
    required this.icon,
    required this.targetType,
  });
}

class InteractiveCoachTourOverlay extends StatefulWidget {
  final VoidCallback onFinish;

  const InteractiveCoachTourOverlay({
    super.key,
    required this.onFinish,
  });

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return InteractiveCoachTourOverlay(
          onFinish: () => Navigator.pop(context),
        );
      },
    );
  }

  @override
  State<InteractiveCoachTourOverlay> createState() => _InteractiveCoachTourOverlayState();
}

class _InteractiveCoachTourOverlayState extends State<InteractiveCoachTourOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStepIndex = 0;
  late AnimationController _animCtrl;
  late Animation<double> _pulseAnim;

  final List<CoachTourStepData> _steps = const [
    CoachTourStepData(
      title: 'สรุปภาพรวม & มาสคอตประจำตัว',
      description: 'แสดงยอดคงเหลือรายเดือน และมาสคอตคู่หู แตะที่มาสคอตเพื่อทักทายหรือเลือกดูปฏิทิน',
      icon: Icons.pets_rounded,
      targetType: CoachTargetType.headerMascot,
    ),
    CoachTourStepData(
      title: 'กราฟสรุป & คุมงบประมาณ',
      description: 'วิเคราะห์รายรับ-รายจ่ายรายวัน แจกแจงตามหมวดหมู่เพื่อช่วยวางแผนการเงิน',
      icon: Icons.pie_chart_outline_rounded,
      targetType: CoachTargetType.quickAnalytics,
    ),
    CoachTourStepData(
      title: 'พูดเพื่อจด (Voice AI)',
      description: 'แตะปุ่มนี้แล้วพูด เช่น "ข้าวผัด 60 บาท" ระบบจะแยกยอดเงินและบันทึกบัญชีให้อัตโนมัติ',
      icon: Icons.mic_rounded,
      targetType: CoachTargetType.voiceButton,
    ),
    CoachTourStepData(
      title: 'ดึงสลิปอัตโนมัติ (EasyOCR)',
      description: 'สแกนหารูปสลิปโอนเงินล่าสุดในเครื่อง พร้อมดึงยอดเงิน ผู้โอน ผู้รับ และโน้ตให้ทันที',
      icon: Icons.sync_rounded,
      targetType: CoachTargetType.slipButton,
    ),
    CoachTourStepData(
      title: 'การจัดการรายการ & สลิป',
      description: 'ปัดรายการไปทางซ้ายเพื่อลบด่วน หรือแตะที่รายการเพื่อดูรูปสลิปและรายละเอียดเต็มจอ',
      icon: Icons.swipe_left_rounded,
      targetType: CoachTargetType.transactionList,
    ),
    CoachTourStepData(
      title: 'ปุ่มจดรายการด่วน (+)',
      description: 'แตะปุ่มบวกเพื่อเพิ่มรายรับ-รายจ่ายด่วน พร้อมเครื่องคิดเลขในตัว',
      icon: Icons.add_rounded,
      targetType: CoachTargetType.fabButton,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.98, end: 1.03).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticFeedback.selectionClick();
    if (_currentStepIndex < _steps.length - 1) {
      setState(() => _currentStepIndex++);
    } else {
      _finishTour();
    }
  }

  void _prevStep() {
    HapticFeedback.selectionClick();
    if (_currentStepIndex > 0) {
      setState(() => _currentStepIndex--);
    }
  }

  void _finishTour() {
    HapticFeedback.mediumImpact();
    widget.onFinish();
  }

  /// Dynamically computes responsive target geometry based on device screen size and insets
  Rect _calculateTargetRect(CoachTargetType targetType, Size screenSize, EdgeInsets insets) {
    final sw = screenSize.width;
    final sh = screenSize.height;
    final top = insets.top;
    final bottom = insets.bottom;

    switch (targetType) {
      case CoachTargetType.headerMascot:
        return Rect.fromCenter(
          center: Offset(sw * 0.5, top + 75),
          width: (sw - 32).clamp(280.0, 440.0),
          height: 130.0,
        );

      case CoachTargetType.quickAnalytics:
        return Rect.fromCenter(
          center: Offset(sw * 0.5, top + 185),
          width: (sw - 32).clamp(280.0, 440.0),
          height: 64.0,
        );

      case CoachTargetType.voiceButton:
        return Rect.fromCenter(
          center: Offset(sw * 0.28, top + 270),
          width: (sw * 0.42).clamp(120.0, 180.0),
          height: 75.0,
        );

      case CoachTargetType.slipButton:
        return Rect.fromCenter(
          center: Offset(sw * 0.72, top + 270),
          width: (sw * 0.42).clamp(120.0, 180.0),
          height: 75.0,
        );

      case CoachTargetType.transactionList:
        return Rect.fromCenter(
          center: Offset(sw * 0.5, top + 380),
          width: (sw - 32).clamp(280.0, 440.0),
          height: 85.0,
        );

      case CoachTargetType.fabButton:
        return Rect.fromCenter(
          center: Offset(sw * 0.5, sh - bottom - 42),
          width: 170.0,
          height: 56.0,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final insets = mediaQuery.padding;

    final step = _steps[_currentStepIndex];
    final isLastStep = _currentStepIndex == _steps.length - 1;

    final targetRect = _calculateTargetRect(step.targetType, screenSize, insets);
    final isTargetInBottomHalf = targetRect.center.dy > (screenSize.height * 0.5);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Cutout Spotlight Overlay (Adaptive dynamic center, never skews)
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) {
              return CustomPaint(
                size: screenSize,
                painter: _SpotlightCutoutPainter(
                  targetRect: targetRect,
                  borderRadius: step.targetType == CoachTargetType.fabButton ? 28 : 20,
                  pulseScale: _pulseAnim.value,
                ),
              );
            },
          ),

          // 2. Interactive Floating UI Layer
          SafeArea(
            child: Stack(
              children: [
                // Top Progress Dots & Skip Button
                Positioned(
                  top: 10,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: List.generate(_steps.length, (index) {
                            final isActive = index == _currentStepIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: isActive ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isActive ? MeowTheme.mustardYellow : const Color(0xFFCBD5E1),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                      ),

                      GestureDetector(
                        onTap: _finishTour,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'ข้าม',
                            style: TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Responsive Floating Tooltip Card (Positioned dynamically above or below the target)
                Positioned(
                  left: 20,
                  right: 20,
                  top: isTargetInBottomHalf ? null : (targetRect.bottom + 16).clamp(70.0, screenSize.height - 240.0),
                  bottom: isTargetInBottomHalf ? ((screenSize.height - targetRect.top) + 16).clamp(20.0, screenSize.height - 220.0) : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.14),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: MeowTheme.mustardYellow.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    step.icon,
                                    color: const Color(0xFFB45309),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    step.title,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Description
                            Text(
                              step.description,
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 13.5,
                                height: 1.45,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Navigation Buttons
                            Row(
                              children: [
                                if (_currentStepIndex > 0) ...[
                                  GestureDetector(
                                    onTap: _prevStep,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        color: Color(0xFF475569),
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],

                                Expanded(
                                  child: TactileButton(
                                    onTap: _nextStep,
                                    child: Container(
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: MeowTheme.mustardYellow,
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: MeowTheme.mustardYellow.withValues(alpha: 0.35),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          isLastStep ? 'เริ่มต้นใช้งาน' : 'ถัดไป',
                                          style: const TextStyle(
                                            color: Color(0xFF451A03),
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _SpotlightCutoutPainter extends CustomPainter {
  final Rect targetRect;
  final double borderRadius;
  final double pulseScale;

  _SpotlightCutoutPainter({
    required this.targetRect,
    required this.borderRadius,
    required this.pulseScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final screenRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final scaledTargetRect = Rect.fromCenter(
      center: targetRect.center,
      width: targetRect.width * pulseScale,
      height: targetRect.height * pulseScale,
    );

    final screenPath = Path()..addRect(screenRect);
    final targetPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        scaledTargetRect,
        Radius.circular(borderRadius),
      ));

    final cutoutPath = Path.combine(PathOperation.difference, screenPath, targetPath);

    final dimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.38)
      ..style = PaintingStyle.fill;
    canvas.drawPath(cutoutPath, dimPaint);

    final haloPaint = Paint()
      ..color = MeowTheme.mustardYellow.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(scaledTargetRect, Radius.circular(borderRadius)),
      haloPaint,
    );

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(scaledTargetRect, Radius.circular(borderRadius)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightCutoutPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.pulseScale != pulseScale ||
        oldDelegate.borderRadius != borderRadius;
  }
}
