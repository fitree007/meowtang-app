import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction_item.dart';
import '../services/slip_storage_service.dart';
import '../state/expense_controller.dart';
import '../utils/format_utils.dart';
import '../screens/edit_transaction_screen.dart';
import 'slip_image_viewer_dialog.dart';
import 'bank_badge.dart';
import '../services/thai_bank_detector.dart';

class TransactionDetailSheet extends StatelessWidget {
 final ExpenseController controller;
 final TransactionItem transaction;
 final void Function(TransactionItem tx)? onDelete;

 const TransactionDetailSheet({
  super.key,
  required this.controller,
  required this.transaction,
  this.onDelete,
 });

 static void show(
   BuildContext context,
   ExpenseController controller,
   TransactionItem transaction, {
   void Function(TransactionItem tx)? onDelete,
 }) {
  HapticFeedback.selectionClick();
  showModalBottomSheet(
   context: context,
   isScrollControlled: true,
   backgroundColor: Colors.transparent,
   builder: (_) => TransactionDetailSheet(
    controller: controller,
    transaction: transaction,
    onDelete: onDelete,
   ),
  );
 }

 @override
 Widget build(BuildContext context) {
  final currentTheme = controller.currentTheme;
  final isDark = controller.isDarkMode;
  final isExp = transaction.type == TransactionType.expense;
  final isInc = transaction.type == TransactionType.income;
  final isTrf = transaction.type == TransactionType.transfer;

  final Color typeColor = isInc
    ? const Color(0xFF10B981)
    : isExp
      ? const Color(0xFFEF4444)
      : const Color(0xFF3B82F6);

  final String typeSign = isInc ? '+' : isExp ? '-' : '⇄ ';

  final resolvedSlipFile = SlipStorageService.resolveSlipFile(transaction.slipImageUrl);
  final hasSlip = resolvedSlipFile != null ||
      (transaction.slipImageUrl != null &&
      transaction.slipImageUrl!.isNotEmpty &&
      (File(transaction.slipImageUrl!).existsSync() || transaction.slipImageUrl!.startsWith('content://')));

  final account = controller.accounts.firstWhere(
   (a) => a.id == transaction.accountId,
   orElse: () => controller.accounts.isNotEmpty ? controller.accounts.first : controller.accounts.first,
  );

  return Container(
   padding: const EdgeInsets.all(20),
   decoration: BoxDecoration(
    color: currentTheme.cardBackground,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    border: Border.all(color: currentTheme.borderColor),
   ),
   child: SafeArea(
    child: SingleChildScrollView(
     child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       // Drag Handle
       Center(
        child: Container(
         width: 40,
         height: 4,
         decoration: BoxDecoration(
          color: isDark ? Colors.white24 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
         ),
        ),
       ),
       const SizedBox(height: 16),

       // Title & Category Header
       Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
           color: typeColor.withValues(alpha: 0.15),
           borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
           isInc
             ? Icons.account_balance_wallet_rounded
             : isExp
               ? Icons.shopping_bag_rounded
               : Icons.swap_horiz_rounded,
           color: typeColor,
           size: 24,
          ),
         ),
         const SizedBox(width: 12),
         Expanded(
          child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
            Text(
             transaction.title,
             style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: currentTheme.textColor,
             ),
            ),
            const SizedBox(height: 3),
            Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
             decoration: BoxDecoration(
              color: currentTheme.surfaceBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: currentTheme.borderColor),
             ),
             child: Text(
              ' หมวดหมู่: ${transaction.categoryName}',
              style: TextStyle(
               fontSize: 11.5,
               fontWeight: FontWeight.bold,
               color: currentTheme.textSecondaryColor,
              ),
             ),
            ),
           ],
          ),
         ),
         IconButton(
          icon: Icon(Icons.close, color: currentTheme.textSecondaryColor),
          onPressed: () => Navigator.pop(context),
         ),
        ],
       ),
       const SizedBox(height: 16),

       // Big Amount Card
       Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        decoration: BoxDecoration(
         color: typeColor.withValues(alpha: 0.08),
         borderRadius: BorderRadius.circular(18),
         border: Border.all(color: typeColor.withValues(alpha: 0.3)),
        ),
        child: Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
          Text(
           isInc ? 'รายรับ' : isExp ? 'รายจ่าย' : 'โอนเงิน',
           style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: typeColor,
           ),
          ),
          Text(
           '$typeSign฿${FormatUtils.formatCurrency(transaction.amount)}',
           style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: typeColor,
           ),
          ),
         ],
        ),
       ),
       const SizedBox(height: 16),

       // Hashtags Section
       if (transaction.tags.isNotEmpty) ...[
        Text(
         '# แท็ก (Hashtags)',
         style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentTheme.textSecondaryColor),
        ),
        const SizedBox(height: 6),
        Wrap(
         spacing: 6,
         runSpacing: 6,
         children: transaction.tags.map((t) {
          final cleanTag = t.replaceAll('#', '');
          return Container(
           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
           decoration: BoxDecoration(
            color: currentTheme.primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: currentTheme.primaryDark.withValues(alpha: 0.4)),
           ),
           child: Text(
            '#$cleanTag',
            style: TextStyle(
             fontSize: 12,
             fontWeight: FontWeight.bold,
             color: currentTheme.primaryDark,
            ),
           ),
          );
         }).toList(),
        ),
        const SizedBox(height: 14),
       ],

       // Details Meta List
       Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
         color: currentTheme.surfaceBackground,
         borderRadius: BorderRadius.circular(16),
         border: Border.all(color: currentTheme.borderColor),
        ),
        child: Column(
         children: [
          _buildMetaRow(
           icon: Icons.calendar_today_rounded,
           label: 'วันและเวลา',
           value: '${transaction.date.day}/${transaction.date.month}/${transaction.date.year + 543} ${transaction.date.hour.toString().padLeft(2, '0')}:${transaction.date.minute.toString().padLeft(2, '0')} น.',
           currentTheme: currentTheme,
          ),
          const Divider(height: 16),
          _buildMetaRow(
           icon: Icons.account_balance_rounded,
           label: 'บัญชี / กระเป๋าเงิน',
           value: account.name,
           currentTheme: currentTheme,
          ),
          if (transaction.note != null && transaction.note!.isNotEmpty) ...[
           const Divider(height: 16),
           _buildMetaRow(
            icon: Icons.notes_rounded,
            label: 'บันทึกช่วยจำ',
            value: transaction.note!,
            currentTheme: currentTheme,
           ),
          ],
         ],
        ),
       ),
       const SizedBox(height: 16),

       // Slip Image Section (If Attached)
       if (hasSlip) ...[
        Text(
         ' รูปภาพสลิปที่เกี่ยวข้อง (Slip Image)',
         style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: currentTheme.textSecondaryColor),
        ),
        const SizedBox(height: 8),
        GestureDetector(
         onTap: () {
          SlipImageViewerDialog.show(
           context,
           transaction.slipImageUrl!,
           title: transaction.title,
          );
         },
         child: Container(
          decoration: BoxDecoration(
           borderRadius: BorderRadius.circular(16),
           border: Border.all(color: currentTheme.primaryColor.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Stack(
           alignment: Alignment.bottomRight,
           children: [
            ClipRRect(
             borderRadius: BorderRadius.circular(15),
             child: Container(
              height: 160,
              width: double.infinity,
              color: Colors.black,
              child: Image.file(
               resolvedSlipFile ?? File(transaction.slipImageUrl!),
               fit: BoxFit.cover,
               errorBuilder: (context, error, stackTrace) => Center(
                child: Icon(Icons.broken_image_rounded, color: currentTheme.primaryDark, size: 40),
               ),
              ),
             ),
            ),
            Container(
             margin: const EdgeInsets.all(10),
             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
             decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(20),
             ),
             child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
               Icon(Icons.zoom_in, color: Colors.white, size: 16),
               SizedBox(width: 4),
               Text(
                'กดดูสลิปเต็มจอ & ซูม',
                style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
               ),
              ],
             ),
            ),
           ],
          ),
         ),
        ),
        const SizedBox(height: 18),
       ],

       // Actions (Edit & Delete)
       Row(
        children: [
         Expanded(
          child: OutlinedButton.icon(
           style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: BorderSide(color: currentTheme.borderColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
           ),
           icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
           label: const Text('ลบรายการ', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
           onPressed: () {
              Navigator.pop(context);
              if (onDelete != null) {
                onDelete!(transaction);
              } else {
                controller.deleteTransaction(transaction.id);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ลบ "${transaction.title}" เรียบร้อย',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF1E293B),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 85),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    duration: const Duration(milliseconds: 3500),
                    action: SnackBarAction(
                      label: 'เลิกทำ',
                      textColor: const Color(0xFFFFD166),
                      onPressed: () {
                        controller.restoreTransaction(transaction);
                      },
                    ),
                  ),
                );
              }
            },
          ),
         ),
         const SizedBox(width: 12),
         Expanded(
          child: ElevatedButton.icon(
           style: ElevatedButton.styleFrom(
            backgroundColor: currentTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
           ),
           icon: const Icon(Icons.edit_rounded, size: 18),
           label: const Text('แก้ไขรายการ', style: TextStyle(fontWeight: FontWeight.bold)),
           onPressed: () {
            Navigator.pop(context);
            Navigator.push(
             context,
             MaterialPageRoute(
              builder: (_) => EditTransactionScreen(
               controller: controller,
               transaction: transaction,
              ),
             ),
            );
           },
          ),
         ),
        ],
       ),
       const SizedBox(height: 10),
      ],
     ),
    ),
   ),
  );
 }

 Widget _buildMetaRow({
  required IconData icon,
  required String label,
  required String value,
  required dynamic currentTheme,
 }) {
  return Row(
   crossAxisAlignment: CrossAxisAlignment.start,
   children: [
    Icon(icon, size: 16, color: currentTheme.primaryDark),
    const SizedBox(width: 8),
    Text(
     label,
     style: TextStyle(fontSize: 12.5, color: currentTheme.textSecondaryColor),
    ),
    const Spacer(),
    Flexible(
     child: Text(
      value,
      textAlign: TextAlign.right,
      style: TextStyle(
       fontSize: 12.5,
       fontWeight: FontWeight.bold,
       color: currentTheme.textColor,
      ),
     ),
    ),
   ],
  );
 }
}
