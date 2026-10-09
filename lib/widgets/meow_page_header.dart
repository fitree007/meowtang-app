import 'package:flutter/material.dart';
import '../state/expense_controller.dart';
import 'meow_mascot_widget.dart';

/// The coloured top bar shared by the main tabs (stats, premium, menu):
/// large title, one-line subtitle, the mascot on the right and an optional
/// [bottom] row (e.g. tabs) inside the bar.
class MeowPageHeader extends StatelessWidget {
  final ExpenseController controller;
  final String title;
  final String subtitle;
  final Widget? bottom;

  /// When set, the mascot is tappable and shows a small camera badge.
  final VoidCallback? onMascotTap;

  const MeowPageHeader({
    super.key,
    required this.controller,
    required this.title,
    required this.subtitle,
    this.bottom,
    this.onMascotTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = controller.currentTheme;
    final isDark = controller.isDarkMode;
    final heroText = theme.heroTextColor(isDark);
    final heroMuted = theme.heroTextMutedColor(isDark);

    // Mascot face in a soft round chip, as in the drafts.
    Widget mascot = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: heroText.withValues(alpha: 0.18), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: MeowMascotWidget(
        size: 34,
        mascotId: controller.selectedMascotId,
        accessory: controller.selectedMascotAccessory,
        customPhotoPath: controller.customAvatarPath,
        isCustomPhoto: controller.isCustomAvatarEnabled,
        isHeadOnly: true,
      ),
    );
    if (onMascotTap != null) {
      mascot = GestureDetector(
        onTap: onMascotTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            mascot,
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: theme.cardBackground,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.borderColor),
                ),
                child: Icon(Icons.photo_camera_outlined, size: 13, color: theme.textSecondaryColor),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: theme.heroGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: heroText, fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        subtitle,
                        key: ValueKey(subtitle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: heroMuted, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              mascot,
            ],
          ),
          if (bottom != null) ...[
            const SizedBox(height: 14),
            bottom!,
          ],
        ],
      ),
    );
  }
}
