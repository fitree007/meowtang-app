import 'package:flutter/material.dart';
import '../services/thai_bank_detector.dart';
import '../state/expense_controller.dart';
import '../models/account_item.dart';
import '../theme/meow_theme.dart';
import '../widgets/bank_badge.dart';
import '../widgets/tactile_button.dart';

class AccountManagementScreen extends StatefulWidget {
  final ExpenseController controller;

  const AccountManagementScreen({super.key, required this.controller});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  void _showEditBalanceDialog(BuildContext context, AccountItem account) {
    final balanceCtrl = TextEditingController(text: account.balance.toStringAsFixed(2));
    final isDark = widget.controller.isDarkMode;
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
          title: Row(
            children: [
              BankBadge(bankCode: account.bankCode, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'แก้ไขยอด: ${account.name}',
                  style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ตั้งค่ายอดเงินคงเหลือเริ่มต้นหรือปรับยอดเงินปัจจุบัน:', style: TextStyle(color: textSecondary, fontSize: 13)),
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
                widget.controller.updateAccountBalance(account.id, newBal);
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

  void _showDeleteConfirmDialog(BuildContext context, AccountItem account) {
    final isDark = widget.controller.isDarkMode;
    final dialogBg = isDark ? MeowTheme.navySurface : Colors.white;
    final textPrimary = isDark ? MeowTheme.textLightPrimary : const Color(0xFF0F172A);
    final textSecondary = isDark ? MeowTheme.textLightSecondary : const Color(0xFF64748B);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'ลบบัญชี "${account.name}" ?',
            style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'คุณต้องการลบบัญชีนี้ออกจากระบบใช่หรือไม่? (รายการสลิปที่บันทึกไปแล้วจะยังคงอยู่)',
            style: TextStyle(color: textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('ยกเลิก', style: TextStyle(color: textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                widget.controller.deleteAccount(account.id);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MeowTheme.expenseRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('ลบบัญชี', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showAddAccountDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final numberCtrl = TextEditingController();
    final balanceCtrl = TextEditingController(text: '0.00');

    // Default to Islamic Bank or KBank
    String selectedBank = 'IBANK';
    final initialBank = ThaiBankDetector.getBankByCode(selectedBank);
    nameCtrl.text = initialBank.nameTh;

    final isDark = widget.controller.isDarkMode;
    final modalBg = isDark ? MeowTheme.navySurface : Colors.white;
    final inputBg = isDark ? const Color(0xFF0F1E36) : const Color(0xFFF1F5F9);
    final textPrimary = isDark ? MeowTheme.textLightPrimary : const Color(0xFF0F172A);
    final textSecondary = isDark ? MeowTheme.textLightSecondary : const Color(0xFF64748B);
    final borderColor = isDark ? MeowTheme.borderColor : const Color(0xFFE2E8F0);

    // Split banks into Bank accounts & e-Wallets
    final bankList = ThaiBankDetector.supportedBanks.where((b) =>
      b.code != 'CASH' &&
      b.code != 'TRUEMONEY' &&
      b.code != 'SHOPEEPAY' &&
      b.code != 'RABBITLINEPAY' &&
      b.code != 'PAOTANG' &&
      b.code != 'AIRPAY' &&
      b.code != 'BLUECONNECT' &&
      b.code != 'PROMPTPAY'
    ).toList();

    final walletList = ThaiBankDetector.supportedBanks.where((b) =>
      b.code == 'PAOTANG' ||
      b.code == 'TRUEMONEY' ||
      b.code == 'SHOPEEPAY' ||
      b.code == 'RABBITLINEPAY' ||
      b.code == 'AIRPAY' ||
      b.code == 'BLUECONNECT' ||
      b.code == 'CASH'
    ).toList();

    int selectedTab = 0; // 0 = Banks, 1 = e-Wallets

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: modalBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentList = selectedTab == 0 ? bankList : walletList;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'เพิ่มบัญชีธนาคาร / กระเป๋าเงิน',
                          style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Type Selector Tabs (ธนาคาร vs กระเป๋าเงิน)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedTab = 0;
                                  selectedBank = 'IBANK';
                                  nameCtrl.text = ThaiBankDetector.getBankByCode(selectedBank).nameTh;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: selectedTab == 0 ? MeowTheme.mustardYellow : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '🏦 บัญชีธนาคาร (16)',
                                    style: TextStyle(
                                      color: selectedTab == 0 ? MeowTheme.textDarkPrimary : textSecondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedTab = 1;
                                  selectedBank = 'PAOTANG';
                                  nameCtrl.text = ThaiBankDetector.getBankByCode(selectedBank).nameTh;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: selectedTab == 1 ? MeowTheme.mustardYellow : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '📱 กระเป๋าเงิน / e-Wallet',
                                    style: TextStyle(
                                      color: selectedTab == 1 ? MeowTheme.textDarkPrimary : textSecondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Bank Horizontal Grid / Scrollable Badges
                    Text(
                      'เลือกสถาบันการเงิน / ผู้ให้บริการ:',
                      style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 88,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: currentList.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final bank = currentList[index];
                          final isSelected = selectedBank == bank.code;

                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedBank = bank.code;
                                nameCtrl.text = bank.nameTh;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 84,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? bank.brandColor.withOpacity(0.18) : inputBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? bank.brandColor : borderColor,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  BankBadge(bankCode: bank.code, size: 30),
                                  const SizedBox(height: 4),
                                  Text(
                                    bank.shortName,
                                    style: TextStyle(
                                      color: isSelected ? textPrimary : textSecondary,
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Account Name Input
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'ชื่อเรียกบัญชี',
                        hintText: 'เช่น ธนาคารอิสลาม (บัญชีเงินเดือน)',
                        labelStyle: TextStyle(color: textSecondary),
                        filled: true,
                        fillColor: inputBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Account Number Input (Optional)
                    TextField(
                      controller: numberCtrl,
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'เลขที่บัญชี (ไม่บังคับ)',
                        hintText: 'xxx-x-xxxxx-x',
                        labelStyle: TextStyle(color: textSecondary),
                        filled: true,
                        fillColor: inputBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Initial Balance Input
                    TextField(
                      controller: balanceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'ยอดเงินคงเหลือเริ่มต้น',
                        prefixText: '฿ ',
                        prefixStyle: const TextStyle(color: MeowTheme.incomeGreen, fontWeight: FontWeight.bold),
                        labelStyle: TextStyle(color: textSecondary),
                        filled: true,
                        fillColor: inputBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Helpful Auto-Sync Note
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.flash_on_rounded, color: Color(0xFF10B981), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'เมื่อคุณสแกนสลิปจากธนาคารนี้ ระบบจะบันทึกและปรับยอดเข้าบัญชีนี้ให้อัตโนมัติทันที ⚡',
                              style: TextStyle(color: textPrimary, fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    TactileButton(
                      onTap: () {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;

                        final meta = ThaiBankDetector.getBankByCode(selectedBank);
                        final isWallet = selectedTab == 1;
                        final balance = double.tryParse(balanceCtrl.text.trim()) ?? 0.0;

                        final newAcc = AccountItem(
                          id: 'acc_${selectedBank.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          bankCode: selectedBank,
                          accountNumber: numberCtrl.text.trim().isNotEmpty ? numberCtrl.text.trim() : 'xxx-x-xxxxx-x',
                          balance: balance,
                          colorValue: meta.brandColor.value,
                          type: isWallet ? AccountType.eWallet : AccountType.bank,
                          allowAutoDeduction: true,
                        );

                        widget.controller.addAccount(newAcc);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: MeowTheme.buttonGradient,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: MeowTheme.mustardYellow.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'บันทึกและเปิดใช้งานบัญชี',
                            style: TextStyle(color: MeowTheme.textDarkPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
      animation: widget.controller,
      builder: (context, child) {
        final accounts = widget.controller.accounts;
        final isDark = widget.controller.isDarkMode;
        final bgColor = isDark ? MeowTheme.navyBackground : const Color(0xFFF8FAFC);
        final cardBg = isDark ? MeowTheme.navySurface : Colors.white;
        final textPrimary = isDark ? MeowTheme.textLightPrimary : const Color(0xFF0F172A);
        final textSecondary = isDark ? MeowTheme.textLightSecondary : const Color(0xFF64748B);
        final borderColor = isDark ? MeowTheme.borderColor : const Color(0xFFE2E8F0);

        // Group accounts by type
        final bankAccounts = accounts.where((a) => a.type == AccountType.bank).toList();
        final walletAccounts = accounts.where((a) => a.type == AccountType.eWallet).toList();
        final cashAccounts = accounts.where((a) => a.type == AccountType.cash).toList();

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
                child: Column(
                  children: [
                    Row(
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
                              '฿${widget.controller.totalNetWorth.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: MeowTheme.textDarkPrimary,
                                fontSize: 26,
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
                            '${accounts.length} บัญชีที่เปิดใช้',
                            style: const TextStyle(color: MeowTheme.incomeGreen, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 16, color: Color(0xFFD97706)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'สลิปที่ดึงเข้ามาจะถูกบันทึกและปรับยอดเข้าบัญชีธนาคารนั้นๆ โดยตรง ⚡',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // SECTION 1: BANK ACCOUNTS
              if (bankAccounts.isNotEmpty) ...[
                _buildSectionHeader('🏦 บัญชีธนาคาร', '${bankAccounts.length} บัญชี', textPrimary, textSecondary),
                ...bankAccounts.map((acc) => _buildAccountCard(acc, cardBg, textPrimary, textSecondary, borderColor, isDark)),
                const SizedBox(height: 16),
              ],

              // SECTION 2: E-WALLETS
              if (walletAccounts.isNotEmpty) ...[
                _buildSectionHeader('📱 กระเป๋าเงินดิจิทัล & e-Wallet', '${walletAccounts.length} บัญชี', textPrimary, textSecondary),
                ...walletAccounts.map((acc) => _buildAccountCard(acc, cardBg, textPrimary, textSecondary, borderColor, isDark)),
                const SizedBox(height: 16),
              ],

              // SECTION 3: CASH
              if (cashAccounts.isNotEmpty) ...[
                _buildSectionHeader('💵 บัญชีเงินสด', '${cashAccounts.length} บัญชี', textPrimary, textSecondary),
                ...cashAccounts.map((acc) => _buildAccountCard(acc, cardBg, textPrimary, textSecondary, borderColor, isDark)),
                const SizedBox(height: 16),
              ],

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

  Widget _buildSectionHeader(String title, String count, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            count,
            style: TextStyle(
              color: textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(
    AccountItem acc,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: acc.isDefault
              ? MeowTheme.mustardYellow
              : (acc.allowAutoDeduction ? borderColor : borderColor.withOpacity(0.5)),
          width: acc.isDefault ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              BankBadge(bankCode: acc.bankCode, size: 38),
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
                              color: MeowTheme.mustardYellow.withOpacity(0.2),
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
                        color: MeowTheme.actionBlue.withOpacity(0.12),
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
          Divider(height: 1, color: borderColor.withOpacity(0.6)),
          const SizedBox(height: 8),

          // Control Bar: Allow Auto Deduction Switch + Set Default + Delete
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
                        widget.controller.toggleAccountAutoDeduction(acc.id, val);
                      },
                    ),
                  ),
                  Text(
                    acc.allowAutoDeduction ? 'บันทึกสลิปเข้าบัญชีนี้' : 'งดบันทึกสลิปเข้าบัญชีนี้',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: acc.allowAutoDeduction ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),

              Row(
                children: [
                  // Set as Default Account
                  if (!acc.isDefault)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        widget.controller.setDefaultAccount(acc.id);
                      },
                      child: const Text('ตั้งเป็นหลัก', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),

                  // Delete Account (only if not default and more than 1 account exists)
                  if (!acc.isDefault && widget.controller.accounts.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                      tooltip: 'ลบบัญชีนี้',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showDeleteConfirmDialog(context, acc),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
