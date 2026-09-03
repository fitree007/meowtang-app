import 'package:flutter/material.dart';

enum InsightType {
  tip,
  warning,
  success,
  tax,
}

class AiInsightCard extends StatelessWidget {
  final String title;
  final String message;
  final InsightType type;
  final VoidCallback? onAction;
  final String? actionText;

  const AiInsightCard({
    super.key,
    required this.title,
    required this.message,
    this.type = InsightType.tip,
    this.onAction,
    this.actionText,
  });

  Color get accentColor {
    switch (type) {
      case InsightType.warning:
        return const Color(0xFFEF4444);
      case InsightType.success:
        return const Color(0xFF10B981);
      case InsightType.tax:
        return const Color(0xFF8B5CF6);
      case InsightType.tip:
      default:
        return const Color(0xFF38BDF8);
    }
  }

  IconData get iconData {
    switch (type) {
      case InsightType.warning:
        return Icons.warning_amber_rounded;
      case InsightType.success:
        return Icons.check_circle_outline;
      case InsightType.tax:
        return Icons.calculate_outlined;
      case InsightType.tip:
      default:
        return Icons.auto_awesome;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.35),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                if (actionText != null && onAction != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onAction,
                    child: Text(
                      '$actionText →',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
