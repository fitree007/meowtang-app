import 'package:flutter/material.dart';
import '../models/project_budget.dart';

class BudgetProgressBar extends StatelessWidget {
  final ProjectBudget project;
  final bool showDetails;

  const BudgetProgressBar({
    super.key,
    required this.project,
    this.showDetails = true,
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
    final percent = (project.spentAmount / (project.budgetCap > 0 ? project.budgetCap : 1.0)).clamp(0.0, 1.0);
    final percentText = (project.spentAmount / (project.budgetCap > 0 ? project.budgetCap : 1.0) * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDetails) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
                  Text(
                    project.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Text(
                '$percentText%',
                style: TextStyle(
                  color: barColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
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
                color: Colors.white.withOpacity(0.08),
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
                      color: barColor.withOpacity(0.4),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ใช้ไป ฿${project.spentAmount.toStringAsFixed(0)}',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
              ),
              Text(
                'คงเหลือ ฿${project.remainingBudget.clamp(0.0, double.infinity).toStringAsFixed(0)} / เพดาน ฿${project.budgetCap.toStringAsFixed(0)}',
                style: TextStyle(
                  color: project.isOverBudget ? const Color(0xFFEF4444) : Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: project.isOverBudget ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
