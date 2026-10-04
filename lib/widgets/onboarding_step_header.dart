import 'package:flutter/material.dart';
import 'tactile_button.dart';

/// A modern, unified header used across all 4 onboarding steps
/// (Language -> Mascot -> Theme -> Features Showcase).
/// Displays a 4-segment progress bar and "ขั้นที่ X จาก 4" indicator (รูปแนบ 2)
/// with unified typography and back/trailing controls.
class OnboardingStepHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String title;
  final String subtitle;
  final Color primaryColor;
  final Color textColor;
  final Color subtitleColor;
  final VoidCallback? onBack;
  final Widget? leading;
  final Widget? trailing;
  final String? badgeText;
  final IconData? stepIcon;

  const OnboardingStepHeader({
    super.key,
    this.currentStep = 1,
    this.totalSteps = 4,
    required this.title,
    required this.subtitle,
    required this.primaryColor,
    required this.textColor,
    required this.subtitleColor,
    this.onBack,
    this.leading,
    this.trailing,
    this.badgeText,
    this.stepIcon,
  });

  static int extractStepFromBadge(String? text) {
    if (text == null) return 1;
    final match = RegExp(r'(\d+)\s*/\s*(\d+)').firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '1') ?? 1;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn = badgeText?.toLowerCase().contains('step') ?? false;
    final int step = currentStep > 0 ? currentStep : extractStepFromBadge(badgeText);
    final String stepLabel = isEn
        ? 'Step $step of $totalSteps'
        : 'ขั้นที่ $step จาก $totalSteps';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Control Row: Leading (Back button), Centered 4-Segment Bars (รูปแนบ 2), Trailing
          Row(
            children: [
              // Leading / Back button
              if (leading != null)
                leading!
              else if (onBack != null)
                TactileButton(
                  onTap: onBack!,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 15,
                      color: Color(0xFF334155),
                    ),
                  ),
                )
              else
                const SizedBox(width: 36),

              // Centered Segmented Step Indicator (รูปแนบ 2)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 4 Horizontal pill bars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(totalSteps, (index) {
                        final bool isCompleted = index < step - 1;
                        final bool isActive = index == step - 1;
                        final Color barColor = isCompleted
                            ? const Color(0xFF0F172A)
                            : (isActive
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFE5DFD3));

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3.5),
                          width: 32,
                          height: 7,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      stepLabel,
                      style: const TextStyle(
                        color: Color(0xFF574B38),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing
              if (trailing != null)
                trailing!
              else
                const SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 18.5,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),

          // Subtitle
          Text(
            subtitle,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 12,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
