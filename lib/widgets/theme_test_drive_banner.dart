import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../config/app_config.dart';
import 'tactile_button.dart';

class ThemeTestDriveBanner extends StatelessWidget {
  final ExpenseController controller;

  const ThemeTestDriveBanner({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (!controller.isThemeInTestDrive) return const SizedBox.shrink();

    final remaining = controller.testDriveRemainingSeconds;
    final activeTheme = controller.currentTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: activeTheme.primaryColor.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: activeTheme.primaryColor,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: activeTheme.primaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$remaining',
              style: TextStyle(
                color: activeTheme.primaryLight,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'ทดลองใช้ธีม: ${activeTheme.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                Text(
                  'เหลือเวลา $remaining วินาที • ซื้อ ฿${AppConfig.themePriceThb} ใช้ตลอดชีพ',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Buy 29฿ Button
          TactileButton(
            onTap: () async {
              HapticFeedback.heavyImpact();
              final themeId = controller.testDriveThemeId;
              if (themeId != null) {
                await controller.purchaseTheme(themeId);
                controller.cancelThemeTestDrive();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF059669),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      content: Text('ปลดล็อคธีม "${activeTheme.name}" ถาวรสำเร็จแล้ว! 🎉'),
                    ),
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [activeTheme.primaryLight, activeTheme.primaryDark],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'ซื้อ ฿${AppConfig.themePriceThb}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Cancel Button
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              controller.cancelThemeTestDrive();
            },
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, color: Colors.white60, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
