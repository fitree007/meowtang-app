import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/category_item.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../widgets/tactile_button.dart';
import '../screens/budget_management_screen.dart';

class DailyBudgetQuotaCard extends StatelessWidget {
  final ExpenseController controller;
  final DateTime? targetDate;

  const DailyBudgetQuotaCard({
    super.key,
    required this.controller,
    this.targetDate,
  });

  CategoryItem _findCategoryItem(String name) {
    return controller.categories.firstWhere(
      (c) => c.name.trim().toLowerCase() == name.trim().toLowerCase(),
      orElse: () => CategoryItem(
        id: 'cat_custom',
        name: name,
        iconKey: 'category',
        colorValue: 0xFF10B981,
        type: CategoryType.expense,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Strictly hidden by default until the user enables it in Budget Management
    if (!controller.isBudgetPlanEnabled) {
      return const SizedBox.shrink();
    }

    final isDark = controller.isDarkMode;
    final currentTheme = controller.currentTheme;
    final cardBg = isDark ? MeowTheme.navySurface : Colors.white;
    final textPrimary = isDark ? MeowTheme.textLightPrimary : const Color(0xFF0F172A);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final date = targetDate ?? DateTime.now();
    final budgets = controller.getCategoryBudgetsForDate(date);

    if (budgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return TactileButton(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BudgetManagementScreen(controller: controller),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Header: Title "แผนงบประมาณ" + Setup Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: currentTheme.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.pie_chart_rounded, size: 16, color: currentTheme.primaryColor),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'แผนงบประมาณ',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: currentTheme.primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ตั้งค่างบ',
                        style: TextStyle(
                          color: currentTheme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 13, color: currentTheme.primaryColor),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Category Gauge Rows with exact real CategoryItem icons & colors
            ...budgets.entries.map((entry) {
              final catName = entry.key;
              final limit = entry.value;
              final spent = controller.getSpentForCategoryThisMonth(catName);
              final ratio = limit > 0 ? (spent / limit) : 0.0;
              final progress = ratio.clamp(0.0, 1.0);
              final isOver = spent > limit && limit > 0;
              final isNear = !isOver && spent >= limit * 0.8 && limit > 0;

              final catItem = _findCategoryItem(catName);
              final catColor = Color(catItem.colorValue);

              Color gaugeColor;
              if (isOver) {
                gaugeColor = const Color(0xFFEF4444); // Red
              } else if (isNear) {
                gaugeColor = const Color(0xFFF59E0B); // Amber/Orange
              } else {
                gaugeColor = const Color(0xFF10B981); // Green
              }

              final pctString = limit > 0 ? '${(ratio * 100).toInt()}%' : '0%';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Row: Real Category Icon + Name + Percentage / Overbudget Alert
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(catItem.icon, size: 14, color: catColor),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              catName,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        if (isOver)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('🚨', style: TextStyle(fontSize: 12)),
                              SizedBox(width: 4),
                              Text(
                                'เกินงบ',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            pctString,
                            style: TextStyle(
                              color: gaugeColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Progress Bar Track
                    Stack(
                      children: [
                        Container(
                          height: 7.5,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: isOver ? 1.0 : progress,
                          child: Container(
                            height: 7.5,
                            decoration: BoxDecoration(
                              color: gaugeColor,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: gaugeColor.withValues(alpha: 0.35),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
