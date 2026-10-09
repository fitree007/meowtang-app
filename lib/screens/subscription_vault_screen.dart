import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/subscription_item.dart';
import '../models/transaction_item.dart';
import '../models/category_item.dart';
import '../state/expense_controller.dart';
import '../services/currency_exchange_service.dart';
import '../theme/app_theme_model.dart';
import '../utils/format_utils.dart';
import '../widgets/meow_fx.dart';
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
                note: isEn ? 'Paid via: $accName' : 'ชำระผ่าน: $accName',
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
                                : 'บันทึกรายจ่ายค่า ${item.name} เรียบร้อยแล้ว',
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

  // ---------------------------------------------------------------------------
  // Trial banner actions
  // ---------------------------------------------------------------------------
  Future<void> _trialCancelled(SubscriptionItem item) async {
    HapticFeedback.mediumImpact();
    final theme = widget.controller.currentTheme;
    final isEn = widget.controller.isEnglish;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEn ? 'Cancelled "${item.name}"?' : 'ยกเลิก "${item.name}" แล้ว?',
            style: TextStyle(color: theme.textColor, fontSize: 17)),
        content: Text(
          isEn
              ? 'The service will be switched off and no longer counted in your totals. You can turn it back on from its page.'
              : 'จะปิดบริการนี้และไม่นับรวมในยอดที่ต้องจ่าย เปิดใช้ใหม่ได้จากหน้ารายละเอียด',
          style: TextStyle(color: theme.textSecondaryColor, fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isEn ? 'Back' : 'กลับ')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB45309)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isEn ? 'Yes, cancelled' : 'ยกเลิกแล้ว'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.controller.toggleSubscriptionActive(item.id);
    _toast(isEn ? '${item.name} switched off' : 'ปิด ${item.name} แล้ว');
  }

  Future<void> _trialKeep(SubscriptionItem item) async {
    HapticFeedback.lightImpact();
    await widget.controller.updateSubscription(item.copyWith(hasTrial: false));
    _toast(widget.controller.isEnglish ? 'Keeping ${item.name}' : 'ใช้ ${item.name} ต่อแล้ว');
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ---------------------------------------------------------------------------
  // Logos
  // ---------------------------------------------------------------------------
  Widget _logoContent(SubscriptionItem item, double iconSize) {
    final fallbackColor = item.customColor ?? widget.controller.currentTheme.primaryColor;
    if (item.logoAssetPath != null && item.logoAssetPath!.isNotEmpty) {
      return Image.asset(
        item.logoAssetPath!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(Icons.subscriptions_outlined, size: iconSize, color: fallbackColor),
      );
    } else if (item.logoUrl != null && item.logoUrl!.isNotEmpty) {
      return Image.network(
        item.logoUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(Icons.language_rounded, size: iconSize, color: fallbackColor),
      );
    }
    return Icon(Icons.subscriptions_outlined, size: iconSize, color: fallbackColor);
  }

  bool _hasLogo(SubscriptionItem item) =>
      (item.logoAssetPath?.isNotEmpty ?? false) || (item.logoUrl?.isNotEmpty ?? false);

  Widget _buildBrandLogo(SubscriptionItem item) {
    final theme = widget.controller.currentTheme;
    final hasLogo = _hasLogo(item);
    return Container(
      width: 48,
      height: 48,
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(hasLogo ? 6 : 0),
      decoration: BoxDecoration(
        color: hasLogo
            ? Colors.white
            : (item.customColor ?? theme.primaryColor).withValues(alpha: widget.controller.isDarkMode ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
      ),
      child: Center(child: _logoContent(item, 26)),
    );
  }

  Widget _avatar(SubscriptionItem item, double size, Color ring) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(_hasLogo(item) ? size * 0.14 : 0),
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: ring, width: 2)),
      child: Center(child: _logoContent(item, size * 0.55)),
    );
  }

  // ---------------------------------------------------------------------------
  // Page
  // ---------------------------------------------------------------------------
  static const _filterCategories = [
    'สตรีมมิ่ง',
    'AI & ซอฟต์แวร์',
    'มือถือ & เน็ตบ้าน',
    'สาธารณูปโภค',
    'เกม & บันเทิง',
    'พื้นที่จัดเก็บ',
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: widget.controller, builder: (context, _) => _buildPage(context));
  }

  Widget _buildPage(BuildContext context) {
    final theme = widget.controller.currentTheme;
    final isEn = widget.controller.isEnglish;
    final isDark = widget.controller.isDarkMode;

    final allSubs = widget.controller.subscriptions;
    final activeSubs = allSubs.where((s) => s.isActive).toList();

    // Summary calculations converted to THB
    double yearlyTotalThb = 0.0;
    double dueThisMonthThb = 0.0;
    final now = DateTime.now();

    for (final s in activeSubs) {
      yearlyTotalThb += _convertToThb(s.yearlyCost, s.currency);
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

    // The next charge gets the expanded card (as in the draft), as do charges due within 3 days.
    final upcoming = activeSubs.where((s) => !s.hasEnded && s.daysUntilNextBilling >= 0).toList()
      ..sort((a, b) => a.daysUntilNextBilling.compareTo(b.daysUntilNextBilling));
    final nextId = upcoming.isEmpty ? null : upcoming.first.id;

    // Expiring trials
    final expiringTrials = activeSubs.where((s) => s.isTrialExpiringSoon).toList();
    var fx = 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _header(theme, isDark, isEn, activeSubs, dueThisMonthThb, yearlyTotalThb, now),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final t in expiringTrials) ...[
                        FxFadeUp(index: fx++, child: _trialCard(t, isDark, isEn)),
                        const SizedBox(height: 16),
                      ],
                      _filterChips(theme, allSubs, isEn),
                      const SizedBox(height: 16),
                      FxFadeUp(
                        index: fx++,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _listHeader(theme, isEn),
                            const SizedBox(height: 10),
                            if (filtered.isEmpty)
                              _emptyState(theme, isDark, isEn, allSubs.isEmpty)
                            else
                              for (final item in filtered) ...[
                                _subCard(item, theme, isDark, isEn,
                                    expanded: item.id == nextId ||
                                        (item.isActive && !item.hasEnded && item.daysUntilNextBilling <= 3)),
                                if (item != filtered.last) const SizedBox(height: 10),
                              ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _bottomBar(theme, isEn),
        ],
      ),
    );
  }

  Widget _header(AppThemeModel theme, bool isDark, bool isEn, List<SubscriptionItem> activeSubs, double dueThisMonth,
      double yearly, DateTime now) {
    final heroText = theme.heroTextColor(isDark);
    final heroMuted = theme.heroTextMutedColor(isDark);
    final ringColor = theme.primaryDark;
    final monthLabel = isEn ? DateFormat('MMM yyyy').format(now) : _thaiMonthShortYear(now);
    final stack = activeSubs.take(4).toList();

    return Container(
      decoration: BoxDecoration(
        gradient: theme.heroGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: isEn ? 'Back' : 'ย้อนกลับ',
                    constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.chevron_left_rounded, color: heroText, size: 28),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text('Subscription',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: heroText)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isEn ? 'Due this month ($monthLabel)' : 'ยอดที่ต้องจ่ายเดือนนี้ ($monthLabel)',
                              style: TextStyle(fontSize: 12.5, color: heroMuted)),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: FxProgress(
                              value: dueThisMonth,
                              builder: (_, v) => Text(
                                '฿${FormatUtils.formatMoney(v == dueThisMonth ? v : v.roundToDouble(), trimZero: true)}',
                                maxLines: 1,
                                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, height: 1.15, color: heroText),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEn
                                ? 'About ฿${FormatUtils.formatMoney(yearly, trimZero: true)} a year • ${activeSubs.length} services'
                                : 'ทั้งปีประมาณ ฿${FormatUtils.formatMoney(yearly, trimZero: true)} • ${activeSubs.length} บริการ',
                            style: TextStyle(fontSize: 12.5, color: heroMuted),
                          ),
                        ],
                      ),
                    ),
                    if (stack.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 12),
                        child: SizedBox(
                          width: 34.0 + 24 * (stack.length - 1),
                          height: 34,
                          child: Stack(
                            children: [
                              for (var k = 0; k < stack.length; k++)
                                Positioned(left: 24.0 * k, child: _avatar(stack[k], 34, ringColor)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (activeSubs.isNotEmpty) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _calendar(theme, isDark, isEn, activeSubs, now),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// "ปฏิทินตัดเงินเดือนนี้": a line for the month with today's dot and each charge's logo on its day.
  Widget _calendar(AppThemeModel theme, bool isDark, bool isEn, List<SubscriptionItem> activeSubs, DateTime now) {
    final heroText = theme.heroTextColor(isDark);
    final heroMuted = theme.heroTextMutedColor(isDark);
    const amber = Color(0xFFFCD34D);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    double pos(int day) => (day - 1) / (daysInMonth - 1);
    final charges = activeSubs
        .where((s) =>
            !s.hasEnded &&
            s.nextBillingDate.year == now.year &&
            s.nextBillingDate.month == now.month &&
            s.nextBillingDate.day >= now.day)
        .toList()
      ..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
    final monthShort = isEn ? DateFormat('MMM').format(now) : _thaiMonths[now.month - 1];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: heroText.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(isEn ? 'Charges this month' : 'ปฏิทินตัดเงินเดือนนี้',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: heroText)),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: LayoutBuilder(builder: (context, box) {
              final w = box.maxWidth;
              final today = pos(now.day);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 19,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                          color: heroText.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    width: w,
                    top: 19,
                    child: FxBar(value: today, color: amber, track: Colors.transparent, height: 3),
                  ),
                  Positioned(
                    left: (w * today - 7).clamp(0.0, w - 14),
                    top: 13,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Color(0x99FCD34D), spreadRadius: 3)],
                      ),
                    ),
                  ),
                  for (var k = 0; k < charges.length; k++)
                    Positioned(
                      left: (w * pos(charges[k].nextBillingDate.day) - 14).clamp(0.0, w - 28),
                      top: 6,
                      child: Tooltip(
                        message: '${charges[k].name} ${charges[k].nextBillingDate.day} $monthShort',
                        child: _avatar(charges[k], 28, k == 0 ? amber : Colors.white),
                      ),
                    ),
                ],
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('1 $monthShort', style: TextStyle(fontSize: 12, color: heroMuted)),
              const Spacer(),
              Text(isEn ? 'Today ${now.day}' : 'วันนี้ ${now.day}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: heroText)),
              const Spacer(),
              Text('$daysInMonth $monthShort', style: TextStyle(fontSize: 12, color: heroMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trialCard(SubscriptionItem t, bool isDark, bool isEn) {
    final bg = isDark ? const Color(0xFF3A2A0A) : const Color(0xFFFFFBEB);
    final title = isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F);
    final sub = isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E);
    final days = t.daysUntilTrialEnds ?? 0;
    final end = t.trialEndDate!;
    final endLabel = isEn ? DateFormat('d MMM').format(end) : '${end.day} ${_thaiMonths[end.month - 1]}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(width: 44, height: 44, child: FittedBox(child: _buildBrandLogo(t))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEn ? 'Free trial ending soon' : 'ทดลองใช้ฟรีใกล้หมด',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: title)),
                    const SizedBox(height: 2),
                    Text(
                      isEn
                          ? '${t.name} • ends $endLabel (${days == 0 ? 'today' : 'in $days days'})'
                          : '${t.name} • หมดอายุ $endLabel (${days == 0 ? 'วันนี้' : 'อีก $days วัน'})',
                      style: TextStyle(fontSize: 12.5, color: sub),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _trialCancelled(t),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: sub,
                    backgroundColor: isDark ? Colors.transparent : Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isEn ? 'Cancelled' : 'ยกเลิกแล้ว',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => _trialKeep(t),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB45309),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isEn ? 'Keep it' : 'ใช้ต่อ', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChips(AppThemeModel theme, List<SubscriptionItem> allSubs, bool isEn) {
    int count(String cat) => allSubs.where((s) => s.category.contains(cat)).length;
    final cats = [
      'ทั้งหมด',
      for (final c in _filterCategories)
        if (count(c) > 0 || _selectedCategoryFilter == c) c,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final cat in cats)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Chip(
                theme: theme,
                label: '${cat == 'ทั้งหมด' && isEn ? 'All' : cat} ${cat == 'ทั้งหมด' ? allSubs.length : count(cat)}',
                selected: _selectedCategoryFilter == cat,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCategoryFilter = cat);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _listHeader(AppThemeModel theme, bool isEn) {
    final title = switch (_sortBy) {
      'price' => isEn ? 'Sorted by price' : 'เรียงตามราคา',
      'name' => isEn ? 'Sorted by name' : 'เรียงตามชื่อ',
      _ => isEn ? 'Sorted by charge date' : 'เรียงตามวันตัดเงิน',
    };
    PopupMenuItem<String> item(String value, IconData icon, String label) => PopupMenuItem(
          value: value,
          child: Row(
            children: [
              Icon(icon, size: 18, color: _sortBy == value ? theme.primaryColor : theme.textSecondaryColor),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(fontSize: 13.5, fontWeight: _sortBy == value ? FontWeight.w600 : FontWeight.w400)),
            ],
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textColor)),
          ),
          PopupMenuButton<String>(
            tooltip: isEn ? 'Change sorting' : 'เปลี่ยนการจัดเรียง',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: theme.cardBackground,
            onSelected: (val) {
              HapticFeedback.selectionClick();
              setState(() => _sortBy = val);
            },
            itemBuilder: (ctx) => [
              item('dueDate', Icons.event_outlined, isEn ? 'Next Due Date' : 'วันตัดเงิน'),
              item('price', Icons.payments_outlined, isEn ? 'Price (High to Low)' : 'ราคา (มากไปน้อย)'),
              item('name', Icons.sort_by_alpha_rounded, isEn ? 'Name (A-Z)' : 'ชื่อบริการ (ก-ฮ)'),
            ],
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.swap_vert_rounded, size: 22, color: theme.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(AppThemeModel theme, bool isDark, bool isEn, bool noneAtAll) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: _cardDecoration(theme, isDark),
      child: Column(
        children: [
          Icon(Icons.subscriptions_outlined, size: 40, color: theme.textSecondaryColor),
          const SizedBox(height: 12),
          Text(
            noneAtAll
                ? (isEn ? 'No Subscriptions Added Yet' : 'ยังไม่มีรายการ Subscription')
                : (isEn ? 'Nothing in this category' : 'ไม่มีบริการในหมวดนี้'),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: theme.textColor),
          ),
          const SizedBox(height: 6),
          Text(
            noneAtAll
                ? (isEn
                    ? 'Tap "Add Subscription" below to add Netflix, YouTube, ChatGPT, AIS, or any recurring bills.'
                    : 'แตะ "เพิ่ม Subscription" ด้านล่างเพื่อเพิ่ม Netflix, YouTube, ChatGPT, ค่าเน็ต, ค่าน้ำไฟ พร้อมโลโก้ของจริงได้เลย')
                : (isEn ? 'Pick another category above.' : 'ลองเลือกหมวดอื่นด้านบน'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: theme.textSecondaryColor, height: 1.4),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(AppThemeModel theme, bool isDark) => BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: isDark ? Border.all(color: theme.borderColor) : null,
        boxShadow: isDark ? null : const [BoxShadow(color: Color(0x0F0F172A), blurRadius: 14, offset: Offset(0, 4))],
      );

  Widget _subCard(SubscriptionItem item, AppThemeModel theme, bool isDark, bool isEn, {required bool expanded}) {
    final daysLeft = item.daysUntilNextBilling;
    final priceInThb = _convertToThb(item.price, item.currency);
    final sub = theme.textSecondaryColor;
    final warn = isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
    final d = item.nextBillingDate;
    final dateLabel = isEn ? DateFormat('d MMM').format(d) : '${d.day} ${_thaiMonths[d.month - 1]}';

    String dueText;
    Color dueColor = sub;
    if (!item.isActive) {
      dueText = isEn ? 'Switched off' : 'ปิดใช้งานอยู่';
    } else if (item.hasEnded) {
      dueText = isEn ? 'Ended' : 'ครบกำหนดแล้ว';
    } else if (daysLeft < 0) {
      dueText = isEn ? 'Charge $dateLabel • ${-daysLeft}d overdue' : 'ตัดเงิน $dateLabel • เลยกำหนด ${-daysLeft} วัน';
      dueColor = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
    } else if (daysLeft == 0) {
      dueText = isEn ? 'Charged today' : 'ตัดเงินวันนี้';
      dueColor = warn;
    } else {
      dueText = isEn ? 'Charge $dateLabel • in $daysLeft days' : 'ตัดเงิน $dateLabel • อีก $daysLeft วัน';
      if (expanded) dueColor = warn;
    }

    final extras = <String>[
      if (item.endRuleType == 'fixedCycles' && item.totalCycles != null && !item.hasEnded)
        isEn ? 'Cycle ${item.completedCycles}/${item.totalCycles}' : 'รอบ ${item.completedCycles}/${item.totalCycles}',
      if (item.endRuleType == 'untilDate' && item.endDate != null && !item.hasEnded)
        '${isEn ? 'Until' : 'ถึง'} ${FormatUtils.formatDate(item.endDate!, isEnglish: isEn, shortYear: true)}',
    ];
    final detail = [item.category, item.accountName ?? item.paymentMethod, ...extras].where((s) => s.isNotEmpty).join(' • ');

    final priceText = item.currency == 'THB'
        ? '฿${FormatUtils.formatMoney(item.price, trimZero: true)}'
        : (item.currency == 'BTC'
            ? '₿ ${item.price.toStringAsFixed(item.price < 0.01 ? 6 : 4)}'
            : '${item.currency} ${item.price.toStringAsFixed(2)}');
    final cycle = switch (item.billingCycle) {
      'yearly' => isEn ? '/year' : '/ปี',
      'weekly' => isEn ? '/week' : '/สัปดาห์',
      'quarterly' => isEn ? '/quarter' : '/ไตรมาส',
      _ => isEn ? '/month' : '/เดือน',
    };

    final top = Row(
      children: [
        _buildBrandLogo(item),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textColor)),
                  ),
                  if (item.hasTrial) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(isEn ? 'TRIAL' : 'ทดลอง',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: warn)),
                    ),
                  ],
                  if (!item.enableReminder) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.notifications_off_outlined, size: 14, color: sub),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                expanded ? detail : dueText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: expanded ? sub : dueColor),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(priceText, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textColor)),
            if (item.currency != 'THB')
              Text('≈ ฿${FormatUtils.formatMoney(priceInThb, trimZero: true)}', style: TextStyle(fontSize: 12, color: sub)),
            Text(cycle, style: TextStyle(fontSize: 12, color: sub)),
          ],
        ),
      ],
    );

    return Opacity(
      opacity: item.isActive ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: _cardDecoration(theme, isDark),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _openEditSubscription(item),
            onLongPress: () => _recordToExpenses(item),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: !expanded
                  ? top
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        top,
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: dueColor == sub ? sub : const Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(dueText,
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: dueColor)),
                            ),
                            const SizedBox(width: 10),
                            FilledButton(
                              onPressed: () => _recordToExpenses(item),
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.primaryColor.withValues(alpha: isDark ? 0.24 : 0.1),
                                foregroundColor: isDark ? theme.textColor : theme.primaryColor,
                                elevation: 0,
                                minimumSize: const Size(0, 44),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(isEn ? 'Record Expense' : 'ลงรายจ่าย',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(AppThemeModel theme, bool isEn) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(top: BorderSide(color: theme.borderColor)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: FilledButton.icon(
            onPressed: _openAddSubscription,
            style: FilledButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            icon: const Icon(Icons.add_rounded, size: 22),
            label: Text(isEn ? 'Add Subscription' : 'เพิ่ม Subscription',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

const _thaiMonths = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];

String _thaiMonthShortYear(DateTime d) => '${_thaiMonths[d.month - 1]} ${d.year + 543}';

class _Chip extends StatelessWidget {
  final AppThemeModel theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.theme, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? theme.textColor : theme.cardBackground,
      shape: StadiumBorder(side: selected ? BorderSide.none : BorderSide(color: theme.borderColor)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? theme.cardBackground : theme.textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
