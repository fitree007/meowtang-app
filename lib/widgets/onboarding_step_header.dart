import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import 'meow_fx.dart';

/// Header shared by the 4 first-launch steps (Language → Mascot → Theme →
/// Features). It uses the same coloured top bar as the app's main tabs:
/// back chevron, a 4-segment progress bar with "ขั้นที่ X จาก 4", an optional
/// trailing action (e.g. Skip), then a large title and one-line subtitle.
///
/// It pads itself for the status bar, so callers should not wrap it in a
/// SafeArea.
class OnboardingStepHeader extends StatelessWidget {
  final ExpenseController controller;
  final int currentStep;
  final int totalSteps;
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  const OnboardingStepHeader({
    super.key,
    required this.controller,
    required this.currentStep,
    this.totalSteps = 4,
    required this.title,
    required this.subtitle,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = controller.currentTheme;
    final isDark = controller.isDarkMode;
    final heroText = theme.heroTextColor(isDark);
    final heroMuted = theme.heroTextMutedColor(isDark);
    final isEn = controller.isEnglish;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: theme.heroGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 6, 8, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: onBack == null
                      ? null
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: Icon(Icons.chevron_left_rounded, color: heroText, size: 28),
                            tooltip: isEn ? 'Back' : 'ย้อนกลับ',
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              onBack!();
                            },
                          ),
                        ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(totalSteps, (i) {
                          final reached = i < currentStep;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == currentStep - 1 ? 28 : 18,
                            height: 6,
                            decoration: BoxDecoration(
                              color: reached ? heroText : heroText.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        isEn ? 'Step $currentStep of $totalSteps' : 'ขั้นที่ $currentStep จาก $totalSteps',
                        style: TextStyle(color: heroMuted, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: trailing == null ? null : Align(alignment: Alignment.centerRight, child: trailing),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: heroText, fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: heroMuted, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Skip" text button for the header's trailing slot, in the header's text colour.
class OnboardingSkipButton extends StatelessWidget {
  final ExpenseController controller;
  final VoidCallback onTap;

  const OnboardingSkipButton({super.key, required this.controller, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final heroText = controller.currentTheme.heroTextColor(controller.isDarkMode);
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        foregroundColor: heroText,
      ),
      child: Text(
        controller.isEnglish ? 'Skip' : 'ข้าม',
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Bottom bar shared by the first-launch steps: an optional outlined "Back"
/// and a solid primary button, on a card strip with a hairline top border.
class OnboardingBottomBar extends StatelessWidget {
  final ExpenseController controller;
  final String nextLabel;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const OnboardingBottomBar({
    super.key,
    required this.controller,
    required this.nextLabel,
    required this.onNext,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = controller.currentTheme;
    final isEn = controller.isEnglish;

    final next = Semantics(
      button: true,
      child: FxPress(
        onTap: () {
          HapticFeedback.mediumImpact();
          onNext();
        },
        child: Container(
          height: 52,
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(16)),
          child: Text(
            nextLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(top: BorderSide(color: theme.borderColor)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 14 + MediaQuery.of(context).padding.bottom),
      child: onBack == null
          ? next
          : Row(
              children: [
                Expanded(
                  flex: 35,
                  child: Material(
                    color: theme.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.borderColor),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onBack!();
                      },
                      child: SizedBox(
                        height: 52,
                        child: Center(
                          child: Text(
                            isEn ? 'Back' : 'ย้อนกลับ',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(flex: 65, child: next),
              ],
            ),
    );
  }
}
