import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/subscription_item.dart';
import '../models/transaction_item.dart';
import '../models/category_item.dart';
import '../state/expense_controller.dart';
import '../services/currency_exchange_service.dart';
import '../utils/format_utils.dart';
import 'add_edit_subscription_screen.dart';

class SubscriptionVaultScreen extends StatefulWidget {
  final ExpenseController controller;

  const SubscriptionVaultScreen({
    super.key,
    required this.controller,
  });

  @override
  State<SubscriptionVaultScreen> createState() => _SubscriptionVaultScreenState();
}

class _SubscriptionVaultScreenState extends State<SubscriptionVaultScreen> {
  String _selectedCategoryFilter = 'ทั้งหมด';
  String _sortBy = 'dueDate'; // 'dueDate', 'price', 'name'

  double _convertToThb(double amount, String currency) {
    if (currency == 'THB') return amount;
    return CurrencyExchangeService.convertToThb(amount, currency);
  }

  void _openAddSubscription() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditSubscriptionScreen(controller: widget.controller),
      ),
    ).then((_) => setState(() {}));
  }

  void _openEditSubscription(SubscriptionItem item) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditSubscriptionScreen(
          controller: widget.controller,
          existingItem: item,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _recordToExpenses(SubscriptionItem item) {
    HapticFeedback.mediumImpact();
    final theme = widget.controller.currentTheme;
    final isEn = widget.controller.isEnglish;
    final priceInThb = _convertToThb(item.price, item.currency);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: theme.cardBackground,
        title: Row(
          children: [
            const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(
              isEn ? 'Record as Expense?' : 'บันทึกลงรายจ่ายทันที?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textColor),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEn
                  ? 'Record "${item.name}" (฿${FormatUtils.formatCurrency(priceInThb)}) into today\'s expenses in MeowTang?'
                  : 'บันทึกบิล "${item.name}" จำนวน ฿${FormatUtils.formatCurrency(priceInThb)} ลงในสมุดรายรับ-รายจ่ายของวันนี้?',
              style: TextStyle(fontSize: 13, color: theme.textSecondaryColor, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isEn ? 'Cancel' : 'ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () async {
              Navigator.pop(ctx);
              // Find matching or default category & account
              final categories = widget.controller.categories;
              final accounts = widget.controller.accounts;
              final cat = categories.firstWhere(
                (c) => c.name.toLowerCase().contains('บันเทิง') || c.name.toLowerCase().contains('บิล') || c.type == CategoryType.expense,
                orElse: () => categories.first,
              );
              final acc = accounts.isNotEmpty
                  ? ((item.accountId != null && item.accountId!.isNotEmpty)
                      ? accounts.firstWhere((a) => a.id == item.accountId, orElse: () => accounts.first)
                      : accounts.firstWhere((a) => a.name == item.paymentMethod, orElse: () => accounts.first))
                  : null;
              final accId = acc?.id ?? 'cash';
              final accName = acc?.name ?? item.paymentMethod;

              final tx = TransactionItem(
                id: 'sub_tx_${DateTime.now().millisecondsSinceEpoch}',
                title: 'จ่ายค่าบริการ ${item.name}',
                amount: priceInThb,
                type: TransactionType.expense,
                categoryId: cat.id,
                categoryName: cat.name,
                accountId: accId,
                date: DateTime.now(),
                note: 'ชำระบริการ ${item.name} ด้วยบัญชี $accName',
              );

              await widget.controller.addTransaction(tx, allowManualOverride: true);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isEn
                                ? 'Expense recorded for ${item.name}!'
                                : 'บันทึกรายจ่ายค่า ${item.name} เรียบร้อยแล้ว! ✨',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
            child: Text(isEn ? 'Record Now' : 'บันทึกทันที'),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandLogo(SubscriptionItem item) {
    if (item.logoAssetPath != null && item.logoAssetPath!.isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: Image.asset(
          item.logoAssetPath!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.subscriptions_rounded, size: 28, color: Color(0xFF64748B)),
        ),
      );
    } else if (item.logoUrl != null && item.logoUrl!.isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: Image.network(
          item.logoUrl!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.language_rounded, size: 28, color: Color(0xFF64748B)),
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: (item.customColor ?? widget.controller.currentTheme.primaryColor).withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Icon(
          Icons.subscriptions_rounded,
          size: 26,
          color: item.customColor ?? widget.controller.currentTheme.primaryColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.controller.currentTheme;
    final isEn = widget.controller.isEnglish;
    final isDark = widget.controller.isDarkMode;
    final cardBg = theme.cardBackground;
    final textColor = theme.textColor;
    final subColor = theme.textSecondaryColor;
    final borderColor = theme.borderColor;

    final allSubs = widget.controller.subscriptions;
    final activeSubs = allSubs.where((s) => s.isActive).toList();

    // Summary calculations converted to THB
    double monthlyAverageThb = 0.0;
    double yearlyTotalThb = 0.0;
    double dueThisMonthThb = 0.0;
    final now = DateTime.now();

    for (final s in activeSubs) {
      final thbMonthly = _convertToThb(s.monthlyCost, s.currency);
      monthlyAverageThb += thbMonthly;

      final thbYearly = _convertToThb(s.yearlyCost, s.currency);
      yearlyTotalThb += thbYearly;

      if (s.nextBillingDate.year == now.year && s.nextBillingDate.month == now.month) {
        dueThisMonthThb += _convertToThb(s.price, s.currency);
      }
    }

    // Filter by Category
    var filtered = allSubs;
    if (_selectedCategoryFilter != 'ทั้งหมด') {
      filtered = filtered.where((s) => s.category.contains(_selectedCategoryFilter)).toList();
    }

    // Sort
    filtered = List.from(filtered);
    if (_sortBy == 'dueDate') {
      filtered.sort((a, b) => a.daysUntilNextBilling.compareTo(b.daysUntilNextBilling));
    } else if (_sortBy == 'price') {
      filtered.sort((a, b) => _convertToThb(b.monthlyCost, b.currency).compareTo(_convertToThb(a.monthlyCost, a.currency)));
    } else {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    }

    // Expiring trials
    final expiringTrials = activeSubs.where((s) => s.isTrialExpiringSoon).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEn ? 'Subscription Vault' : 'คุมค่า Subscription & รายจ่ายประจำ',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'จัดเรียง',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (val) {
              HapticFeedback.selectionClick();
              setState(() => _sortBy = val);
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'dueDate',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 16, color: _sortBy == 'dueDate' ? theme.primaryColor : subColor),
                    const SizedBox(width: 8),
                    Text(
                      isEn ? 'Next Due Date' : 'วันครบกำหนด',
                      style: TextStyle(fontSize: 13, fontWeight: _sortBy == 'dueDate' ? FontWeight.bold : FontWeight.normal),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'price',
                child: Row(
                  children: [
                    Icon(Icons.payments_rounded, size: 16, color: _sortBy == 'price' ? theme.primaryColor : subColor),
                    const SizedBox(width: 8),
                    Text(
                      isEn ? 'Price (High to Low)' : 'ราคา (มากไปน้อย)',
                      style: TextStyle(fontSize: 13, fontWeight: _sortBy == 'price' ? FontWeight.bold : FontWeight.normal),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha_rounded, size: 16, color: _sortBy == 'name' ? theme.primaryColor : subColor),
                    const SizedBox(width: 8),
                    Text(
                      isEn ? 'Name (A-Z)' : 'ชื่อบริการ (ก-ฮ)',
                      style: TextStyle(fontSize: 13, fontWeight: _sortBy == 'name' ? FontWeight.bold : FontWeight.normal),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_vert_rounded, size: 16, color: theme.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    _sortBy == 'price' ? 'เรียง: ราคา' : (_sortBy == 'name' ? 'เรียง: ชื่อ' : 'เรียง: วันครบ'),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: subColor),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [


          // EXPIRING FREE TRIAL COUNTDOWN WARNING (If any)
          if (expiringTrials.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn ? 'Free Trial Expiring Soon! ⏰' : 'เตือนความจำ: กำลังจะหมดช่วงทดลองใช้! ⏰',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          expiringTrials.map((e) => '${e.name} (อีก ${e.daysUntilTrialEnds ?? 0} วัน)').join(', '),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEn ? 'Cancel now if you don\'t want to be charged!' : 'อย่าลืมกดยกเลิกหากไม่ต้องการต่ออายุเพื่อไม่ให้โดนตัดเงินน้า',
                          style: const TextStyle(fontSize: 10, color: Color(0xFFB45309)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // HERO METRICS DASHBOARD (Billbau-style 3 Core Cards)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [theme.primaryColor.withOpacity(0.08), theme.primaryColor.withOpacity(0.02)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEn ? 'OVERVIEW METRICS' : 'ภาพรวมค่าบริการทั้งหมด',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: theme.primaryColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, size: 12, color: theme.primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            isEn ? '${activeSubs.length} Active' : '${activeSubs.length} บริการที่เปิดอยู่',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.primaryColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Due This Month Hero Number
                Text(
                  '฿${FormatUtils.formatCurrency(dueThisMonthThb)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEn ? 'Due this month (${DateFormat('MMMM yyyy').format(now)})' : 'ยอดที่ต้องจ่ายในเดือนนี้ (${FormatUtils.formatMonthYearThai(now)})',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),
                // Monthly Average vs Annual Total
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_view_month_rounded, size: 14, color: Color(0xFF3B82F6)),
                              const SizedBox(width: 4),
                              Text(
                                isEn ? 'Monthly Average' : 'เฉลี่ยต่อเดือน',
                                style: TextStyle(fontSize: 11, color: subColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '฿${FormatUtils.formatCurrency(monthlyAverageThb)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 32, color: borderColor.withOpacity(0.5)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF10B981)),
                              const SizedBox(width: 4),
                              Text(
                                isEn ? 'Annual Estimate' : 'ประมาณการทั้งปี',
                                style: TextStyle(fontSize: 11, color: subColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '฿${FormatUtils.formatCurrency(yearlyTotalThb)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // CATEGORY FILTER CHIPS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                'ทั้งหมด',
                'สตรีมมิ่ง',
                'AI & ซอฟต์แวร์',
                'มือถือ & เน็ตบ้าน',
                'สาธารณูปโภค',
                'เกม & บันเทิง',
                'พื้นที่จัดเก็บ',
              ].map((cat) {
                final isSelected = _selectedCategoryFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: theme.primaryColor.withOpacity(0.18),
                    backgroundColor: cardBg,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? theme.primaryColor : subColor,
                    ),
                    side: BorderSide(
                      color: isSelected ? theme.primaryColor : borderColor.withOpacity(0.5),
                    ),
                    onSelected: (val) {
                      setState(() => _selectedCategoryFilter = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // EMPTY STATE OR LIST
          if (filtered.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.subscriptions_outlined, size: 54, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 12),
                  Text(
                    isEn ? 'No Subscriptions Added Yet' : 'ยังไม่มีรายการ Subscription',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isEn
                        ? 'Tap the + button below to add Netflix, YouTube, ChatGPT, AIS, or any recurring bills!'
                        : 'แตะปุ่ม + ด้านล่างเพื่อเพิ่ม Netflix, YouTube, ChatGPT, ค่าเน็ต, ค่าน้ำไฟ พร้อมโลโก้ของจริงได้เลย!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: subColor, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _openAddSubscription,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(isEn ? 'Add Your First Service' : 'เพิ่มบริการแรกของคุณ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // SUBSCRIPTION TILES
            ...filtered.map((item) {
              final daysLeft = item.daysUntilNextBilling;
              final priceInThb = _convertToThb(item.price, item.currency);

              Color dueBadgeColor = const Color(0xFF10B981);
              String dueText = 'อีก $daysLeft วัน';
              if (daysLeft < 0) {
                dueBadgeColor = Colors.redAccent;
                dueText = 'เลยกำหนด ${-daysLeft} วัน';
              } else if (daysLeft == 0) {
                dueBadgeColor = const Color(0xFFF59E0B);
                dueText = 'ตัดเงินวันนี้!';
              } else if (daysLeft <= 3) {
                dueBadgeColor = const Color(0xFFF59E0B);
                dueText = 'อีก $daysLeft วัน (ใกล้ถึง)';
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: item.isDueSoon ? const Color(0xFFF59E0B).withOpacity(0.5) : borderColor.withOpacity(0.6),
                    width: item.isDueSoon ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _openEditSubscription(item),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildBrandLogo(item),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                        ),
                                        if (item.hasTrial)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            margin: const EdgeInsets.only(right: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'TRIAL',
                                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Text(
                                          item.category,
                                          style: TextStyle(fontSize: 11, color: subColor),
                                        ),
                                        Text(' • ', style: TextStyle(fontSize: 11, color: subColor)),
                                        Icon(Icons.account_balance_wallet_outlined, size: 11, color: subColor),
                                        const SizedBox(width: 3),
                                        Flexible(
                                          child: Text(
                                            item.accountName ?? item.paymentMethod,
                                            style: TextStyle(fontSize: 11, color: subColor, fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Price Column
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    item.currency == 'THB'
                                        ? '฿${FormatUtils.formatCurrency(item.price)}'
                                        : '${item.currency} ${item.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                  if (item.currency != 'THB')
                                    Text(
                                      '≈ ฿${FormatUtils.formatCurrency(priceInThb)}',
                                      style: TextStyle(fontSize: 10, color: subColor),
                                    ),
                                  Text(
                                    item.billingCycle == 'yearly'
                                        ? '/ปี'
                                        : (item.billingCycle == 'weekly' ? '/สัปดาห์' : '/เดือน'),
                                    style: TextStyle(fontSize: 10, color: subColor),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          // Bottom row: Next due badge + Log expense button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: dueBadgeColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.event_rounded, size: 12, color: dueBadgeColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          dueText,
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: dueBadgeColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('d MMM').format(item.nextBillingDate),
                                    style: TextStyle(fontSize: 11, color: subColor),
                                  ),
                                  if (item.autoRecordExpense) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.bolt_rounded, size: 10, color: Color(0xFF10B981)),
                                          SizedBox(width: 2),
                                          Text('ออโต้', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (!item.enableReminder) ...[
                                    const SizedBox(width: 6),
                                    Icon(Icons.notifications_off_outlined, size: 12, color: subColor.withOpacity(0.6)),
                                  ],
                                ],
                              ),
                              // Quick action: record as expense into MeowTang
                              InkWell(
                                onTap: () => _recordToExpenses(item),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.add_task_rounded, size: 14, color: Color(0xFF10B981)),
                                      const SizedBox(width: 4),
                                      Text(
                                        isEn ? 'Record Expense' : 'ลงรายจ่าย',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF10B981),
                                        ),
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
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSubscription,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: Text(
          isEn ? 'Add Service' : 'เพิ่ม Subscription',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }
}
