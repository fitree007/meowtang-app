import 'package:flutter/material.dart';
import '../state/expense_controller.dart';
import '../models/transaction_item.dart';
import '../models/account_item.dart';
import '../widgets/chat_slip_card.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/bank_badge.dart';
import '../utils/format_utils.dart';

class MeowChatTimelineScreen extends StatefulWidget {
 final ExpenseController controller;

 const MeowChatTimelineScreen({super.key, required this.controller});

 @override
 State<MeowChatTimelineScreen> createState() => _MeowChatTimelineScreenState();
}

class _MeowChatTimelineScreenState extends State<MeowChatTimelineScreen> {
 final ScrollController _scrollController = ScrollController();

 void _showEditBalanceDialog(BuildContext context, AccountItem account) {
  final balanceCtrl = TextEditingController(text: account.balance.toStringAsFixed(2));

  showDialog(
   context: context,
   builder: (ctx) {
    return AlertDialog(
     backgroundColor: const Color(0xFF1E2433),
     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
     title: Row(
      children: [
       BankBadge(bankCode: account.bankCode, size: 24),
       const SizedBox(width: 8),
       Expanded(
        child: Text(
         'ตั้งค่ายอดเงิน: ${account.name}',
         style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
       ),
      ],
     ),
     content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       const Text('กำหนดยอดเงินคงเหลือเริ่มต้นหรือแก้ไขยอดปัจจุบัน:', style: TextStyle(color: Colors.white70, fontSize: 12)),
       const SizedBox(height: 12),
       TextField(
        controller: balanceCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autofocus: true,
        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
         prefixText: '฿ ',
         prefixStyle: const TextStyle(color: Color(0xFF10B981), fontSize: 22, fontWeight: FontWeight.bold),
         filled: true,
         fillColor: const Color(0xFF0F141C),
         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
       ),
      ],
     ),
     actions: [
      TextButton(
       onPressed: () => Navigator.pop(ctx),
       child: const Text('ยกเลิก', style: TextStyle(color: Colors.white54)),
      ),
      ElevatedButton(
       onPressed: () {
        final newBal = double.tryParse(balanceCtrl.text.trim()) ?? 0.0;
        widget.controller.updateAccountBalance(account.id, newBal);
        Navigator.pop(ctx);
       },
       style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF10B981),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
       ),
       child: const Text('บันทึกยอดเงิน', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
     ],
    );
   },
  );
 }

 Map<String, List<TransactionItem>> _groupByDate(List<TransactionItem> list) {
  final Map<String, List<TransactionItem>> grouped = {};
  final now = DateTime.now();

  for (final tx in list) {
   String dateKey;
   if (tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day) {
    dateKey = 'วันนี้';
   } else if (tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day - 1) {
    dateKey = 'เมื่อวานนี้';
   } else {
    dateKey = '${tx.date.day}/${tx.date.month}/${tx.date.year + 543}';
   }

   if (!grouped.containsKey(dateKey)) {
    grouped[dateKey] = [];
   }
   grouped[dateKey]!.add(tx);
  }
  return grouped;
 }

 @override
 Widget build(BuildContext context) {
  return AnimatedBuilder(
   animation: widget.controller,
   builder: (context, child) {
    final transactions = widget.controller.allTransactions;
    final grouped = _groupByDate(transactions);
    final defaultAccount = widget.controller.accounts.isNotEmpty ? widget.controller.accounts.first : null;

    return Scaffold(
     backgroundColor: const Color(0xFF0F141C),
     appBar: AppBar(
      backgroundColor: const Color(0xFF0F141C),
      elevation: 0,
      title: Row(
       children: [
        // Minimalist Islamic / Rizqi Brand Icon
        Container(
         width: 32,
         height: 32,
         decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
         ),
         child: const Icon(Icons.eco_rounded, color: Color(0xFF10B981), size: 18),
        ),
        const SizedBox(width: 10),
        const Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
          Text(
           'เหมียวตังค์',
           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
          ),
          Text(
           'สไตล์เหมียวจด • สลิป AI & เสียง',
           style: TextStyle(fontSize: 10, color: Colors.white54),
          ),
         ],
        ),
       ],
      ),
      actions: [
       // Top Net Balance Pill
       InkWell(
        onTap: () {
         if (defaultAccount != null) {
          _showEditBalanceDialog(context, defaultAccount);
         }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
         margin: const EdgeInsets.only(right: 12),
         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
         decoration: BoxDecoration(
          color: const Color(0xFF181E29),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
         ),
         child: Row(
          children: [
           const Text('ยอดคงเหลือ: ', style: TextStyle(color: Colors.white60, fontSize: 11)),
           Text(
            '฿${FormatUtils.formatCurrency(widget.controller.totalNetWorth)}',
            style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 12),
           ),
           const SizedBox(width: 4),
           const Icon(Icons.edit, size: 11, color: Color(0xFF10B981)),
          ],
         ),
        ),
       ),
      ],
     ),
     body: Column(
      children: [
       // Chat Timeline Messages Feed
       Expanded(
        child: transactions.isEmpty
          ? Center(
            child: Padding(
             padding: const EdgeInsets.all(24.0),
             child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
               Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                 color: const Color(0xFF181E29),
                 shape: BoxShape.circle,
                 border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: const Icon(Icons.forum_outlined, size: 36, color: Color(0xFF10B981)),
               ),
               const SizedBox(height: 14),
               const Text(
                'ยังไม่มีบันทึกรายการ',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
               ),
               const SizedBox(height: 6),
               Text(
                'เริ่มต้นบันทึกง่ายๆ สไตล์เหมียวจด:\n แตะปุ่มสลิปเพื่อโยนรูปสลิปจากเครื่อง\n แตะปุ่มไมค์เพื่อพูด เช่น "กินข้าว 60"\n หรือพิมพ์ข้อความในช่องด้านล่างได้เลย',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, height: 1.5),
               ),
              ],
             ),
            ),
           )
          : ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            itemCount: grouped.length,
            itemBuilder: (context, dateIndex) {
             final dateKey = grouped.keys.elementAt(dateIndex);
             final items = grouped[dateKey]!;

             // Calculate daily total
             double dailyExp = 0.0;
             double dailyInc = 0.0;
             for (final tx in items) {
              if (tx.type == TransactionType.expense) dailyExp += tx.amount;
              if (tx.type == TransactionType.income) dailyInc += tx.amount;
             }

             return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               // Date Header Pill
               Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                 children: [
                  Container(
                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                   decoration: BoxDecoration(
                    color: const Color(0xFF181E29),
                    borderRadius: BorderRadius.circular(10),
                   ),
                   child: Text(
                    dateKey,
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11),
                   ),
                  ),
                  const Spacer(),
                  if (dailyInc > 0)
                   Text('+฿${FormatUtils.formatCurrency(dailyInc)} ', style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold)),
                  if (dailyExp > 0)
                   Text('-฿${FormatUtils.formatCurrency(dailyExp)}', style: const TextStyle(color: Color(0xFFF87171), fontSize: 11, fontWeight: FontWeight.bold)),
                 ],
                ),
               ),

               // Items in this date
               ...items.map((tx) {
                final acc = widget.controller.getAccountById(tx.accountId);
                return ChatSlipCard(
                 transaction: tx,
                 account: acc,
                 onDelete: () => widget.controller.deleteTransaction(tx.id),
                );
               }),
              ],
             );
            },
           ),
       ),

       // Bottom MeowJod-style Input Bar (Slip / Voice / Text)
       ChatInputBar(controller: widget.controller),
      ],
     ),
    );
   },
  );
 }
}
