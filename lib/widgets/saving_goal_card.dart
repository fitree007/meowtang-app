import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/saving_goal_item.dart';
import '../utils/format_utils.dart';
import '../theme/meow_theme.dart';

class SavingGoalCard extends StatelessWidget {
 final SavingGoalItem goal;
 final bool isDark;
 final bool isEnglish;
 final VoidCallback? onDeposit;
 final VoidCallback? onWithdraw;
 final VoidCallback? onEdit;
 final VoidCallback? onDelete;

 const SavingGoalCard({
  super.key,
  required this.goal,
  required this.isDark,
  this.isEnglish = false,
  this.onDeposit,
  this.onWithdraw,
  this.onEdit,
  this.onDelete,
 });

 @override
 Widget build(BuildContext context) {
  final progress = goal.progressRatio;
  final percent = goal.progressPercentage;
  final isDone = goal.isCompleted || percent >= 100.0;
  final goalColor = Color(goal.colorHex);

  final cardBg = isDark ? MeowTheme.navySurface : Colors.white;
  final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
  final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  return Container(
   margin: const EdgeInsets.only(bottom: 16),
   decoration: BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
     color: isDone
       ? const Color(0xFF10B981)
       : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
     width: isDone ? 1.8 : 1.0,
    ),
    boxShadow: [
     BoxShadow(
      color: isDark
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
     ),
    ],
   ),
   child: ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: Column(
     children: [
      // Top Header: Emoji + Title + Menu
      Padding(
       padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
       child: Row(
        children: [
         Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
           color: goalColor.withOpacity(0.15),
           shape: BoxShape.circle,
          ),
          child: Text(
           goal.categoryEmoji,
           style: const TextStyle(fontSize: 22),
          ),
         ),
         const SizedBox(width: 12),
         Expanded(
          child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
            Row(
             children: [
              Flexible(
               child: Text(
                goal.title,
                style: TextStyle(
                 color: textColor,
                 fontSize: 16,
                 fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
               ),
              ),
              if (isDone) ...[
               const SizedBox(width: 6),
               Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                 color: const Color(0xFF10B981).withOpacity(0.15),
                 borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                 isEnglish ? 'ACHIEVED' : 'สำเร็จแล้ว ',
                 style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                 ),
                ),
               ),
              ],
             ],
            ),
            const SizedBox(height: 2),
            Text(
             isDone
               ? (isEnglish ? 'Goal fully achieved!' : 'ออมสำเร็จตามเป้าหมายแล้ว!')
               : '${isEnglish ? "Remaining" : "ขาดอีก"} ${CurrencyFormat.format(goal.remainingAmount)} ฿',
             style: TextStyle(
              color: subTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
             ),
            ),
           ],
          ),
         ),
         PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: subTextColor, size: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: isDark ? MeowTheme.navySurface : Colors.white,
          onSelected: (val) {
           if (val == 'edit') onEdit?.call();
           if (val == 'withdraw') onWithdraw?.call();
           if (val == 'delete') onDelete?.call();
          },
          itemBuilder: (context) => [
           PopupMenuItem(
            value: 'withdraw',
            child: Row(
             children: [
              const Icon(Icons.remove_circle_outline, size: 18, color: Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Text(isEnglish ? 'Withdraw' : 'ถอนเงินออม'),
             ],
            ),
           ),
           PopupMenuItem(
            value: 'edit',
            child: Row(
             children: [
              const Icon(Icons.edit_outlined, size: 18),
              const SizedBox(width: 8),
              Text(isEnglish ? 'Edit Goal' : 'แก้ไขเป้าหมาย'),
             ],
            ),
           ),
           PopupMenuItem(
            value: 'delete',
            child: Row(
             children: [
              const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Text(isEnglish ? 'Delete' : 'ลบเป้าหมาย', style: const TextStyle(color: Color(0xFFEF4444))),
             ],
            ),
           ),
          ],
         ),
        ],
       ),
      ),

      // Amount Comparison & Progress Bar
      Padding(
       padding: const EdgeInsets.symmetric(horizontal: 16),
       child: Column(
        children: [
         Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
           Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
             Text(
              '${CurrencyFormat.format(goal.currentAmount)} ฿',
              style: TextStyle(
               color: textColor,
               fontSize: 20,
               fontWeight: FontWeight.w900,
              ),
             ),
             const SizedBox(width: 4),
             Text(
              '/ ${CurrencyFormat.format(goal.targetAmount)} ฿',
              style: TextStyle(
               color: subTextColor,
               fontSize: 13,
               fontWeight: FontWeight.w500,
              ),
             ),
            ],
           ),
           Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
             color: goalColor.withOpacity(0.12),
             borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
             '${percent.toStringAsFixed(1)}%',
             style: TextStyle(
              color: goalColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
             ),
            ),
           ),
          ],
         ),
         const SizedBox(height: 10),
         // Animated Liquid Progress Bar
         Stack(
          children: [
           Container(
            height: 10,
            decoration: BoxDecoration(
             color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
             borderRadius: BorderRadius.circular(5),
            ),
           ),
           FractionallySizedBox(
            widthFactor: progress,
            child: Container(
             height: 10,
             decoration: BoxDecoration(
              gradient: LinearGradient(
               colors: isDone
                 ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                 : [goalColor, goalColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
               BoxShadow(
                color: (isDone ? const Color(0xFF10B981) : goalColor).withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
               ),
              ],
             ),
            ),
           ),
          ],
         ),
        ],
       ),
      ),

      const SizedBox(height: 12),

      // Bottom Footer: Daily recommendation or Days remaining + Quick Deposit Button
      Container(
       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
       decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : const Color(0xFFF8FAFC),
        border: Border(
         top: BorderSide(
          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
         ),
        ),
       ),
       child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
         // Days / Daily quota needed
         Expanded(
          child: Builder(
           builder: (context) {
            final days = goal.remainingDays;
            final perDay = goal.requiredSavingsPerDay;

            if (isDone) {
             return Row(
              children: [
               const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 16),
               const SizedBox(width: 4),
               Text(
                isEnglish ? 'Goal Completed!' : 'เป้าหมายสำเร็จแล้ว!',
                style: const TextStyle(
                 color: Color(0xFFF59E0B),
                 fontSize: 12,
                 fontWeight: FontWeight.bold,
                ),
               ),
              ],
             );
            }

            if (days != null && perDay != null) {
             return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               Text(
                '${isEnglish ? "Days left" : "เหลือเวลา"}: $days ${isEnglish ? "days" : "วัน"}',
                style: TextStyle(
                 color: subTextColor,
                 fontSize: 11,
                 fontWeight: FontWeight.w600,
                ),
               ),
               Text(
                '${isEnglish ? "Save/day" : "ควรออมวันละ"}: ~${CurrencyFormat.format(perDay)} ฿',
                style: TextStyle(
                 color: textColor,
                 fontSize: 12,
                 fontWeight: FontWeight.bold,
                ),
               ),
              ],
             );
            }

            return Text(
             isEnglish ? 'Continuous Savings' : 'ออมสะสมเรื่อยๆ ไม่มีกำหนดวัน',
             style: TextStyle(
              color: subTextColor,
              fontSize: 12,
             ),
            );
           },
          ),
         ),
         // Quick Deposit Button
         ElevatedButton.icon(
          onPressed: () {
           HapticFeedback.lightImpact();
           onDeposit?.call();
          },
          icon: const Icon(Icons.add_circle_outline, size: 16),
          label: Text(
           isEnglish ? 'Deposit' : 'เพิ่มเงินออม',
           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
           backgroundColor: isDone ? const Color(0xFF10B981) : goalColor,
           foregroundColor: Colors.white,
           elevation: 0,
           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
           shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
           ),
          ),
         ),
        ],
       ),
      ),
     ],
    ),
   ),
  );
 }
}
