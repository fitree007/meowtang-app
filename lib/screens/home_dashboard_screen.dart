import 'package:flutter/material.dart';
import '../state/expense_controller.dart';
import '../models/account_item.dart';
import '../widgets/bank_badge.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/quick_voice_widget.dart';
import 'upload_slip_screen.dart';
import 'voice_chat_entry_screen.dart';
import 'summary_report_screen.dart';
import 'category_management_screen.dart';
import 'account_management_screen.dart';
import 'add_transaction_screen.dart';

class HomeDashboardScreen extends StatelessWidget {
  final ExpenseController controller;

  const HomeDashboardScreen({super.key, required this.controller});

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
              Text(
                'แก้ไขยอดเงิน: ${account.name}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: '฿ ',
                  prefixStyle: const TextStyle(color: Color(0xFF10B981), fontSize: 20, fontWeight: FontWeight.bold),
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
                controller.updateAccountBalance(account.id, newBal);
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final accounts = controller.accounts;
        final transactions = controller.filteredTransactions;

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
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.6)),
                  ),
                  child: const Icon(Icons.eco_rounded, color: Color(0xFF10B981), size: 18),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เหมียวตังค์',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Rizqi Financial Tracker',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'จัดการบัญชี',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AccountManagementScreen(controller: controller),
                    ),
                  );
                },
                icon: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF10B981)),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async => controller.loadData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Minimalist Net Worth Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181E29),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ยอดเงินรวมทั้งหมด (Net Balance)',
                              style: TextStyle(color: Colors.white60, fontSize: 13),
                            ),
                            InkWell(
                              onTap: () {
                                if (accounts.isNotEmpty) {
                                  _showEditBalanceDialog(context, accounts.first);
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.edit, color: Color(0xFF10B981), size: 12),
                                    SizedBox(width: 4),
                                    Text('แก้ไขยอด', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '฿${controller.totalNetWorth.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.arrow_downward, color: Color(0xFF34D399), size: 14),
                                  const SizedBox(width: 6),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('รายรับเดือนนี้', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                                      Text(
                                        '+฿${controller.totalIncomeThisMonth.toStringAsFixed(2)}',
                                        style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 28, color: Colors.white12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 12.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.arrow_upward, color: Color(0xFFF87171), size: 14),
                                    const SizedBox(width: 6),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('รายจ่ายเดือนนี้', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                                        Text(
                                          '-฿${controller.totalExpenseThisMonth.toStringAsFixed(2)}',
                                          style: const TextStyle(color: Color(0xFFF87171), fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ],
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

                  const SizedBox(height: 14),

                  // Circular Quick Voice Recording Card
                  QuickVoiceWidget(controller: controller),

                  const SizedBox(height: 14),

                  // 4 Minimal Quick Actions
                  Row(
                    children: [
                      _buildActionItem(
                        icon: Icons.upload_file_rounded,
                        label: 'อัพโหลดสลิป',
                        color: const Color(0xFF38BDF8),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => UploadSlipScreen(controller: controller)),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildActionItem(
                        icon: Icons.mic_rounded,
                        label: 'สั่งด้วยเสียง',
                        color: const Color(0xFF10B981),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => VoiceChatEntryScreen(controller: controller)),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildActionItem(
                        icon: Icons.bar_chart_rounded,
                        label: 'สรุป & Excel',
                        color: const Color(0xFFF59E0B),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SummaryReportScreen(controller: controller)),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildActionItem(
                        icon: Icons.category_rounded,
                        label: 'หมวดหมู่',
                        color: const Color(0xFFA855F7),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CategoryManagementScreen(controller: controller)),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Accounts Horizontal Carousel with Tap to Edit Balance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'บัญชี & กระเป๋าเงิน (แตะเพื่อแก้ไขยอด):',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AccountManagementScreen(controller: controller)),
                          );
                        },
                        child: const Text(
                          '+ เพิ่มบัญชี',
                          style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: accounts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final acc = accounts[idx];
                        return InkWell(
                          onTap: () => _showEditBalanceDialog(context, acc),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 140,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF181E29),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.06)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    BankBadge(bankCode: acc.bankCode, size: 20),
                                    const Icon(Icons.edit, size: 12, color: Colors.white38),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      acc.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '฿${acc.balance.toStringAsFixed(2)}',
                                      style: const TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Recent Transactions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'รายการล่าสุด (Recent Activity):',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        '${transactions.length} รายการ',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Transactions List
                  if (transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF181E29).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.04)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 40, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 10),
                          const Text(
                            'ยังไม่มีรายการบันทึก',
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'แตะปุ่ม "เพิ่มรายการ" ด้านล่าง หรืออัพโหลดสลิปเพื่อเริ่มเหมียวตังค์',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                          ),
                        ],
                      ),
                    )
                  else
                    ...transactions.take(15).map((tx) {
                      final acc = controller.getAccountById(tx.accountId);
                      return TransactionTile(
                        transaction: tx,
                        account: acc,
                        onDelete: () => controller.deleteTransaction(tx.id),
                      );
                    }),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddTransactionScreen(controller: controller)),
              );
            },
            backgroundColor: const Color(0xFF10B981),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('เพิ่มรายการ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF181E29),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
