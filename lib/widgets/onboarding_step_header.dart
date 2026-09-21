import 'package:flutter/material.dart';

/// A minimalist, unified header used across all 4 onboarding steps
/// (Language -> Mascot -> Theme -> Features Showcase).
/// Ensures identical top coordinate anchoring, badge typography, and padding
/// so the screen transitions without jumping or shifting.
class OnboardingStepHeader extends StatelessWidget {
  final String badgeText;
  final IconData stepIcon;
  final String title;
  final String subtitle;
  final Color primaryColor;
  final Color textColor;
  final Color subtitleColor;
  final Widget? trailing;

  const OnboardingStepHeader({
    super.key,
    required this.badgeText,
    required this.stepIcon,
    required this.title,
    required this.subtitle,
    required this.primaryColor,
    required this.textColor,
    required this.subtitleColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Minimalist Pill Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.28),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(stepIcon, color: primaryColor, size: 12),
                      const SizedBox(width: 4.5),
                      Text(
                        badgeText,
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
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
                const SizedBox(height: 2),
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
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
