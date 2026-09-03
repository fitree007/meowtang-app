import 'package:flutter/material.dart';
import '../models/transaction_item.dart';
import '../models/account_item.dart';
import '../utils/format_utils.dart';
import 'bank_badge.dart';

class TransactionTile extends StatelessWidget {
  final TransactionItem transaction;
  final AccountItem? account;
  final dynamic project;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.account,
    this.project,
    this.onTap,
    this.onDelete,
  });

  String? get detectedBankCode {
    if (account != null) {
      final name = '${account!.name} ${account!.type}'.toUpperCase();
      if (name.contains('KBANK') || name.contains('กสิกร')) return 'KBANK';
      if (name.contains('SCB') || name.contains('ไทยพาณิชย์')) return 'SCB';
      if (name.contains('KTB') || name.contains('กรุงไทย')) return 'KTB';
      if (name.contains('BBL') || name.contains('กรุงเทพ')) return 'BBL';
      if (name.contains('TTB') || name.contains('ทหารไทย') || name.contains('ทีทีบี')) return 'TTB';
      if (name.contains('GSB') || name.contains('ออมสิน')) return 'GSB';
      if (name.contains('BAY') || name.contains('กรุงศรี')) return 'BAY';
      if (name.contains('IBANK') || name.contains('อิสลาม')) return 'IBANK';
      if (name.contains('TRUE') || name.contains('ทรู')) return 'TRUEMONEY';
      if (name.contains('SHOPEE') || name.contains('ช้อปปี้')) return 'SHOPEEPAY';
      if (name.contains('CASH') || name.contains('เงินสด')) return 'CASH';
      if (name.contains('PROMPT') || name.contains('พร้อมเพย์')) return 'PROMPTPAY';
    }
    final combined = '${transaction.title} ${transaction.note ?? ""}'.toUpperCase();
    if (combined.contains('KBANK') || combined.contains('กสิกร')) return 'KBANK';
    if (combined.contains('SCB') || combined.contains('ไทยพาณิชย์')) return 'SCB';
    if (combined.contains('KTB') || combined.contains('กรุงไทย')) return 'KTB';
    if (combined.contains('BBL') || combined.contains('กรุงเทพ')) return 'BBL';
    if (combined.contains('TTB') || combined.contains('ทหารไทย') || combined.contains('ทีทีบี')) return 'TTB';
    if (combined.contains('GSB') || combined.contains('ออมสิน')) return 'GSB';
    if (combined.contains('BAY') || combined.contains('กรุงศรี')) return 'BAY';
    if (combined.contains('IBANK') || combined.contains('อิสลาม')) return 'IBANK';
    if (combined.contains('TRUEMONEY') || combined.contains('ทรูมันนี่')) return 'TRUEMONEY';
    if (combined.contains('SHOPEEPAY') || combined.contains('SHOPEE')) return 'SHOPEEPAY';
    if (combined.contains('พร้อมเพย์') || combined.contains('PROMPTPAY')) return 'PROMPTPAY';
    return null;
  }

  Color get iconColor {
    if (transaction.type == TransactionType.income) {
      return const Color(0xFF10B981);
    } else if (transaction.type == TransactionType.expense) {
      return const Color(0xFFEF4444);
    } else {
      return const Color(0xFF3B82F6);
    }
  }

  IconData get defaultIcon {
    if (transaction.type == TransactionType.income) {
      return Icons.arrow_downward_rounded;
    } else if (transaction.type == TransactionType.expense) {
      return Icons.arrow_upward_rounded;
    } else {
      return Icons.swap_horiz_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return 'วันนี้ ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} น.';
    }
    return '${date.day}/${date.month}/${date.year + 543} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    final bankCode = detectedBankCode;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFF181E29),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: Row(
              children: [
                // Real Bank Logo or Transaction Icon
                bankCode != null && bankCode != 'CASH' && bankCode != 'OTHER'
                    ? BankBadge(bankCode: bankCode, size: 42)
                    : Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(defaultIcon, color: iconColor, size: 20),
                      ),
                const SizedBox(width: 12),

                // Title, Category, and Account
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              transaction.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                            ),
                          ),
                          if (bankCode != null) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                bankCode,
                                style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (transaction.note != null && transaction.note!.trim().isNotEmpty) ...[
                            Flexible(
                              child: Text(
                                transaction.note!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ] else if (transaction.title != transaction.categoryDisplayName) ...[
                            Flexible(
                              child: Text(
                                transaction.categoryDisplayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          if (account != null) ...[
                            Text(' • ', style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                            Flexible(
                              child: Text(
                                account!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                          Text(' • ', style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                          Text(
                            _formatDate(transaction.date),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Amount formatted with comma and bounded
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${isIncome ? "+" : isTransfer ? "" : "-"}฿${CurrencyFormat.format(transaction.amount)}',
                      style: TextStyle(
                        color: isIncome
                            ? const Color(0xFF34D399)
                            : isTransfer
                                ? const Color(0xFF60A5FA)
                                : const Color(0xFFF87171),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                if (onDelete != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.close, size: 16, color: Colors.white.withValues(alpha: 0.3)),
                    onPressed: onDelete,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
