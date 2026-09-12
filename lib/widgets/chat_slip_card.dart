import 'package:flutter/material.dart';
import '../models/transaction_item.dart';
import '../models/account_item.dart';
import 'bank_badge.dart';
import '../utils/format_utils.dart';

class ChatSlipCard extends StatelessWidget {
  final TransactionItem transaction;
  final AccountItem? account;
  final VoidCallback? onDelete;

  const ChatSlipCard({
    super.key,
    required this.transaction,
    this.account,
    this.onDelete,
  });

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} น.';
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final isSlip = transaction.slipRefId != null && transaction.slipRefId!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFF181E29),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isIncome
              ? const Color(0xFF10B981).withOpacity(0.3)
              : Colors.white.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header: Type Pill & Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isIncome
                          ? const Color(0xFF10B981).withOpacity(0.15)
                          : const Color(0xFFEF4444).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          size: 12,
                          color: isIncome ? const Color(0xFF34D399) : const Color(0xFFF87171),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isIncome ? 'รายรับริซกี' : 'รายจ่าย',
                          style: TextStyle(
                            color: isIncome ? const Color(0xFF34D399) : const Color(0xFFF87171),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSlip) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_rounded, size: 10, color: Color(0xFF38BDF8)),
                          SizedBox(width: 3),
                          Text(
                            'สลิป AI',
                            style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  Text(
                    _formatTime(transaction.date),
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Icon(Icons.close, size: 15, color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Title & Amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  transaction.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${isIncome ? "+" : "-"}฿${FormatUtils.formatCurrency(transaction.amount)}',
                style: TextStyle(
                  color: isIncome ? const Color(0xFF34D399) : const Color(0xFFF87171),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Bottom Meta: Hashtag Tag & Account Info
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Tag Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F141C),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Text(
                  '#${transaction.categoryDisplayName}',
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              if (account != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F141C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BankBadge(bankCode: account!.bankCode, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        account!.name,
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],

              if (transaction.note != null && transaction.note!.isNotEmpty && !isSlip) ...[
                Text(
                  '• ${transaction.note}',
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
