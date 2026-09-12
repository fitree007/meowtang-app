import 'package:flutter/material.dart';
import '../models/project_budget.dart';
import '../utils/format_utils.dart';

class BudgetProgressBar extends StatelessWidget {
  final ProjectBudget project;
  final bool showDetails;
  final Color? textColor;
  final Color? subTextColor;

  const BudgetProgressBar({
    super.key,
    required this.project,
    this.showDetails = true,
    this.textColor,
    this.subTextColor,
  });

  Color get barColor {
    if (project.isOverBudget) {
      return const Color(0xFFEF4444); // Red Over-budget
    } else if (project.isNearLimit) {
      return const Color(0xFFF59E0B); // Amber Warning
    } else {
      return project.color;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = textColor ?? (isDark ? Colors.white : const Color(0xFF0F172A));
    final secondaryText = subTextColor ?? (isDark ? Colors.white.withValues(alpha: 0.65) : const Color(0xFF64748B));

    final percent = (project.spentAmount / (project.budgetCap > 0 ? project.budgetCap : 1.0)).clamp(0.0, 1.0);
    final percentText = (project.spentAmount / (project.budgetCap > 0 ? project.budgetCap : 1.0) * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDetails) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: project.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        project.name,
                        style: TextStyle(
                          color: primaryText,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$percentText%',
                  style: TextStyle(
                    color: barColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],

        // Progress Bar
        Stack(
          children: [
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percent,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: barColor.withValues(alpha: 0.35),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        if (showDetails) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'ใช้ไป ฿${FormatUtils.formatCurrency(project.spentAmount, trimZero: true)}',
                  style: TextStyle(color: secondaryText, fontSize: 11.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'คงเหลือ ฿${FormatUtils.formatCurrency(project.remainingBudget.clamp(0.0, double.infinity), trimZero: true)}',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: project.isOverBudget ? const Color(0xFFEF4444) : secondaryText,
                    fontSize: 11.5,
                    fontWeight: project.isOverBudget ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
