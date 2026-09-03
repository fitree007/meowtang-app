import '../services/thai_bank_detector.dart';
import 'package:flutter/material.dart';
import '../state/expense_controller.dart';
import '../models/account_item.dart';
import '../theme/meow_theme.dart';
import '../widgets/bank_badge.dart';
import '../widgets/tactile_button.dart';

class AccountManagementScreen extends StatelessWidget {
  final ExpenseController controller;

  const AccountManagementScreen({super.key, required this.controller});

  void _showEditBalanceDialog(BuildContext context, AccountItem account) {
    final balanceCtrl = TextEditingController(text: account.balance.toStringAsFixed(2));
    final isDark = controller.isDarkMode;
    final dialogBg = isDark ? MeowTheme.navySurface : Colors.white;
    final inputBg = isDark ? const Color(0xFF0F1E36) : const Color(0xFFF1F5F9);
    final textPrimary = isDark ? MeowTheme.textLightPrimary : const Color(0xFF0F172A);
    final textSecondary = isDark ? MeowTheme.textLightSecondary : const Color(0xFF64748B);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'แก้ไขยอดเงิน: ${account.name}',
            style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ตั้งค่ายอดเงินคงเหลือเริ่มต้นหรือปรับยอดเงิน:', style: TextStyle(color: textSecondary, fontSize: 13)),
              const SizedBox(height: 14),
              TextField(
                controller: balanceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: '฿ ',
                  prefixStyle: const TextStyle(color: MeowTheme.incomeGreen, fontSize: 22, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('ยกเลิก', style: TextStyle(color: textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final newBal = double.tryParse(balanceCtrl.text.trim()) ?? 0.0;
                controller.updateAccountBalance(account.id, newBal);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MeowTheme.mustardYellow,
                foregroundColor: MeowTheme.textDarkPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('บันทึกยอดเงิน', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showAddAccountDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    String selectedBank = 'KBANK';
    final isDark = controller.isDarkMode;
    final modalBg = isDark ? MeowTheme.navySurface : Colors.white;
    final inputBg = isDark ? const Color(0xFF0F1E36) : const Color(0xFFF1F5F9);
    final textPrimary = isDark ? MeowTheme.textLightPrimary : const Color(0xFF0F172A);
    final textSecondary = isDark ? MeowTheme.textLightSecondary : const Color(0xFF64748B);

    final bankOptions = ThaiBankDetector.supportedBanks.map((b) => {
      'code': b.code,
      'name': b.nameTh,
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: modalBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('เพิ่มบัญชีธนาคาร / กระเป๋าเงินใหม่', style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: selectedBank,
                    dropdownColor: modalBg,
                    style: TextStyle(color: textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'เลือกธนาคาร / ผู้ให้บริการ',
                      labelStyle: TextStyle(color: textSecondary),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    items: bankOptions.map((b) {
                      return DropdownMenuItem(
                        value: b['code'],
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BankBadge(bankCode: b['code']!, size: 24),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                b['name']!,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setModalState(() {
                        selectedBank = val!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      labelText: 'ชื่อเรียกบัญชี (เช่น บัญชีเงินเดือน, เงินเก็บ, วอลเล็ต)',
                      labelStyle: TextStyle(color: textSecondary),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TactileButton(
                    onTap: () {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;

                      final newAcc = AccountItem(
                        id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        bankCode: selectedBank,
                        accountNumber: 'NEW',
                        balance: 0.00,
                        colorValue: 0xFF10B981,
                      );

                      controller.addAccount(newAcc);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: MeowTheme.buttonGradient,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Center(
                        child: Text('เพิ่มบัญชี (ยอดเริ่มต้น ฿0.00)', style: TextStyle(color: MeowTheme.textDarkPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
        final isDark = controller.isDarkMode;
        final bgColor = isDark ? MeowTheme.navyBackground : const Color(0xFFF8FAFC);
        final cardBg = isDark ? MeowTheme.navySurface : Colors.white;
        final textPrimary = isDark ? MeowTheme.textLightPrimary : const Color(0xFF0F172A);
        final textSecondary = isDark ? MeowTheme.textLightSecondary : const Color(0xFF64748B);
        final borderColor = isDark ? MeowTheme.borderColor : const Color(0xFFE2E8F0);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: MeowTheme.mustardYellow,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: MeowTheme.textDarkPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'บัญชีและการเงิน',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: MeowTheme.textDarkPrimary,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Banner Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1B2F4E), const Color(0xFF0F1E36)]
                        : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: MeowTheme.mustardYellow.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ยอดเงินรวมทุกบัญชี',
                          style: TextStyle(color: MeowTheme.textDarkSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '฿${controller.totalNetWorth.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: MeowTheme.textDarkPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: MeowTheme.incomeGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${accounts.length} บัญชี',
                        style: const TextStyle(color: MeowTheme.incomeGreen, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Account List Header
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'รายการบัญชีและการดึงเงินอัตโนมัติ',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'เลือกเปิด/ปิดอิสระ 🛡️',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Account List
              ...accounts.map((acc) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: acc.isDefault
                          ? MeowTheme.mustardYellow
                          : (acc.allowAutoDeduction ? borderColor : borderColor.withValues(alpha: 0.5)),
                      width: acc.isDefault ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          BankBadge(bankCode: acc.bankCode, size: 36),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        acc.name,
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (acc.isDefault) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: MeowTheme.mustardYellow.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          '⭐ บัญชีหลัก',
                                          style: TextStyle(
                                            color: Color(0xFFB45309),
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
                                  acc.bankDisplayName,
                                  style: TextStyle(color: textSecondary, fontSize: 11.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '฿${acc.balance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: MeowTheme.incomeGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TactileButton(
                                onTap: () => _showEditBalanceDialog(context, acc),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: MeowTheme.actionBlue.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'แก้ไขยอด',
                                    style: TextStyle(color: MeowTheme.actionBlue, fontSize: 10.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

                      // Control Bar: Allow Auto Deduction Switch + Set Default
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Auto Deduct Toggle
                          Row(
                            children: [
                              Transform.scale(
                                scale: 0.75,
                                child: Switch(
                                  value: acc.allowAutoDeduction,
                                  activeColor: const Color(0xFF10B981),
                                  onChanged: (val) {
                                    controller.toggleAccountAutoDeduction(acc.id, val);
                                  },
                                ),
                              ),
                              Text(
                                acc.allowAutoDeduction ? 'ดึงเงิน/สลิปอัตโนมัติ' : '⏸️ งดดึงเงินจากบัญชีนี้',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: acc.allowAutoDeduction ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),

                          // Set as Default Account
                          if (!acc.isDefault)
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                controller.setDefaultAccount(acc.id);
                              },
                              child: const Text('ตั้งเป็นบัญชีหลัก', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 80),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddAccountDialog(context),
            backgroundColor: MeowTheme.mustardYellow,
            foregroundColor: MeowTheme.textDarkPrimary,
            icon: const Icon(Icons.add_rounded),
            label: const Text('เพิ่มบัญชีใหม่', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        );
      },
    );
  }
}
