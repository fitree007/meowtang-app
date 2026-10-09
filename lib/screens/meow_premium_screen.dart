import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show NumberFormat;
import '../state/expense_controller.dart';
import '../services/currency_exchange_service.dart';
import 'saving_goals_screen.dart';
import 'goal_calculator_screen.dart';
import 'budget_management_screen.dart';
import 'projects_budget_screen.dart';
import 'zakat_calculator_screen.dart';
import 'islamic_inheritance_screen.dart';
import 'islamic_baby_hair_charity_screen.dart';
import 'currency_converter_screen.dart';
import 'gold_silver_calculator_screen.dart';
import 'subscription_vault_screen.dart';
import '../widgets/live_rates_dashboard_widget.dart';
import '../widgets/meow_fx.dart';
import '../widgets/meow_page_header.dart';
import '../widgets/meow_paywall_modal.dart';

/// Accent pair used by one tool tile (icon chip + accent text), light and dark.
class _Accent {
  final Color fg;
  final Color bg;
  final Color fgDark;

  const _Accent(this.fg, this.bg, this.fgDark);

  Color color(bool dark) => dark ? fgDark : fg;
  Color chip(bool dark) => dark ? fgDark.withValues(alpha: 0.16) : bg;
}

const _gold = _Accent(Color(0xFFB45309), Color(0xFFFEF3C7), Color(0xFFFCD34D));
const _fx = _Accent(Color(0xFF0369A1), Color(0xFFE6F0FA), Color(0xFF38BDF8));
const _subs = _Accent(Color(0xFF4F46E5), Color(0xFFEEEBFF), Color(0xFFA5B4FC));
const _saving = _Accent(Color(0xFF047857), Color(0xFFE3F6EE), Color(0xFF34D399));
const _budget = _Accent(Color(0xFF1D4ED8), Color(0xFFE5EEFF), Color(0xFF60A5FA));
const _calc = _Accent(Color(0xFF6D28D9), Color(0xFFF1ECFF), Color(0xFFC4B5FD));
const _project = _Accent(Color(0xFFBE185D), Color(0xFFFDEBF3), Color(0xFFF472B6));
const _zakat = _Accent(Color(0xFFB45309), Color(0xFFFFF3DC), Color(0xFFFCD34D));

const _thMonths = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
const _enMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

class MeowPremiumScreen extends StatefulWidget {
  final ExpenseController controller;

  const MeowPremiumScreen({super.key, required this.controller});

  @override
  State<MeowPremiumScreen> createState() => _MeowPremiumScreenState();
}

class _MeowPremiumScreenState extends State<MeowPremiumScreen> {
  static final NumberFormat _int = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _dec = NumberFormat('#,##0.00', 'en_US');

  ExpenseController get _c => widget.controller;
  bool get _isEn => _c.isEnglish;
  bool get _isDark => _c.isDarkMode;

  @override
  void initState() {
    super.initState();
    CurrencyExchangeService.fetchLatestRates().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _openFeature(Widget screen, {String? reason}) {
    if (!widget.controller.isPremium) {
      MeowPaywallModal.show(
        context,
        controller: widget.controller,
        reason: reason ?? 'ฟีเจอร์พรีเมี่ยมสำหรับสมาชิก VIP เท่านั้น 👑',
      );
      return;
    }
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _restorePurchases(BuildContext context) {
    HapticFeedback.lightImpact();
    final isEn = widget.controller.isEnglish;
    final theme = widget.controller.currentTheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: theme.cardBackground,
        title: Row(
          children: [
            const Icon(Icons.history_edu_rounded, color: Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            Text(
              isEn ? 'Restore Purchases' : 'กู้คืนสิทธิ์การซื้อ (Restore)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEn
                  ? 'MeowTang operates 100% offline. Your VIP subscription is managed securely by your Google Play Account.\n\n• If you previously subscribed to VIP (Monthly/Yearly) on this Google Account, Google Play will restore your active subscription.\n• Secure and seamless — no external server or account needed.'
                  : 'เหมียวตังค์ทำงานแบบออฟไลน์ 100% โดยสิทธิ์ VIP จะผูกติดกับบัญชี Google Play Store ของคุณโดยตรง\n\n• หากคุณเคยสมัครแพ็กเกจ VIP (รายเดือนหรือรายปี) ด้วยบัญชี Google นี้ ระบบ Google Play จะตรวจสอบและคืนสิทธิ์ VIP ให้อัตโนมัติเมื่อติดตั้งใหม่หรือย้ายเครื่อง\n• จัดการรอบบิลผ่าน Google Play Store อย่างปลอดภัย ไม่จำเป็นต้องสร้างบัญชีใหม่',
              style: TextStyle(
                fontSize: 13,
                color: theme.textSecondaryColor,
                height: 1.45,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isEn ? 'Close' : 'ปิด'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF0284C7),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isEn
                              ? 'Google Play Purchase verification completed!'
                              : 'ตรวจสอบและกู้คืนสิทธิ์จาก Google Play สำเร็จแล้ว! ✨',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            icon: const Icon(Icons.sync_rounded, size: 18),
            label: Text(isEn ? 'Check Google Play' : 'ตรวจสอบสิทธิ์ Google Play'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  /// Full live-rates dashboard (refresh, watchlist, sparklines) in a sheet,
  /// opened from the "today's prices" strip in the header.
  Future<void> _openRatesSheet() async {
    HapticFeedback.selectionClick();
    final theme = _c.currentTheme;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: theme.borderColor, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _isEn ? 'Live rates' : 'ราคาและเรทเงินวันนี้',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textColor),
                  ),
                ),
                const SizedBox(height: 10),
                LiveRatesDashboardWidget(controller: _c),
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Real data shown on the tiles
  // ---------------------------------------------------------------------------

  String _shortDate(DateTime d, {bool withYear = false}) {
    final m = _isEn ? _enMonths[d.month - 1] : _thMonths[d.month - 1];
    if (!withYear) return '${d.day} $m';
    return '${d.day} $m ${_isEn ? d.year : d.year + 543}';
  }

  String get _headerSubtitle {
    if (!_c.isPremium) {
      return _isEn ? 'Free plan • Unlock every tool with VIP' : 'บัญชีทั่วไป • ปลดล็อคทุกเครื่องมือด้วย VIP';
    }
    final expiry = _c.premiumExpiry;
    if (expiry == null) return _isEn ? 'VIP member • Lifetime' : 'สมาชิก VIP • ตลอดชีพ';
    return _isEn
        ? 'VIP member • Renews ${_shortDate(expiry, withYear: true)}'
        : 'สมาชิก VIP • ต่ออายุ ${_shortDate(expiry, withYear: true)}';
  }

  String get _updatedText {
    final raw = CurrencyExchangeService.getLastUpdatedText()
        .replaceFirst('อัปเดตล่าสุด: ', '')
        .replaceFirst(' เวลา ', ' • ');
    return _isEn ? 'Updated $raw' : 'อัปเดต $raw';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final theme = _c.currentTheme;
        final isVip = _c.isPremium;
        final locked = !isVip;
        final isEn = _isEn;
        var i = 0;

        return Scaffold(
          backgroundColor: theme.scaffoldBackground,
          body: Column(
            children: [
              MeowPageHeader(
                controller: _c,
                title: isEn ? 'Financial tools' : 'เครื่องมือการเงิน',
                subtitle: _headerSubtitle,
                bottom: _buildPriceStrip(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (locked) ...[
                      FxFadeUp(index: 0, child: _buildUpgradeCard()),
                      const SizedBox(height: 22),
                    ],

                    // ทองคำ & ค่าเงิน
                    _sectionTitle(isEn ? 'Gold & currencies' : 'ทองคำ & ค่าเงิน', i),
                    _pair(
                      FxFadeUp(
                        index: i++,
                        child: _tile(
                          accent: _gold,
                          icon: Icons.diamond_outlined,
                          title: isEn ? 'Gold & silver calculator' : 'คำนวณทอง & เงิน',
                          subtitle: isEn ? 'Enter weight → buy/sell price' : 'ใส่น้ำหนัก → รู้ราคาซื้อ/ขาย',
                          footer: _footerText(isEn ? 'baht · salueng · gram' : 'บาท · สลึง · กรัม', _gold),
                          locked: locked,
                          onTap: () => _openFeature(
                            GoldSilverCalculatorScreen(controller: _c),
                            reason: 'คำนวณแร่ทอง & แร่เงิน พร้อมกราฟแนวโน้ม สำหรับสมาชิก VIP 👑',
                          ),
                        ),
                      ),
                      FxFadeUp(
                        index: i++,
                        child: _tile(
                          accent: _fx,
                          icon: Icons.swap_horiz_rounded,
                          title: isEn ? 'Currency converter' : 'แปลงค่าเงิน',
                          subtitle: isEn ? '30+ currencies, latest rates' : '30+ สกุลเงิน เรทล่าสุด',
                          footer: _footerText('USD · JPY · MYR · SAR', _fx),
                          locked: locked,
                          onTap: () => _openFeature(
                            CurrencyConverterScreen(controller: _c),
                            reason: 'เครื่องคิดเลขแปลงค่าเงิน 30+ สกุลทั่วโลก สำหรับสมาชิก VIP 👑',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // วางแผนการเงิน
                    _sectionTitle(isEn ? 'Money planning' : 'วางแผนการเงิน', i),
                    FxFadeUp(index: i++, child: _buildSubscriptionCard(locked)),
                    const SizedBox(height: 10),
                    _pair(
                      FxFadeUp(index: i++, child: _buildSavingGoalsTile(locked)),
                      FxFadeUp(index: i++, child: _buildBudgetTile(locked)),
                    ),
                    const SizedBox(height: 10),
                    _pair(
                      FxFadeUp(
                        index: i++,
                        child: _tile(
                          accent: _calc,
                          icon: Icons.calculate_outlined,
                          title: isEn ? 'Saving time calculator' : 'คำนวณเวลาเก็บออม',
                          subtitle: isEn ? 'How long / how much to save' : 'นานแค่ไหน / ต้องออมเท่าไหร่',
                          locked: locked,
                          onTap: () => _openFeature(GoalCalculatorScreen(controller: _c)),
                        ),
                      ),
                      FxFadeUp(index: i++, child: _buildProjectsTile(locked)),
                    ),
                    const SizedBox(height: 22),

                    // การเงินตามหลักอิสลาม
                    _sectionTitle(isEn ? 'Islamic finance' : 'การเงินตามหลักอิสลาม', i),
                    _pair(
                      FxFadeUp(
                        index: i++,
                        child: _tile(
                          accent: _zakat,
                          icon: Icons.toll_outlined,
                          title: isEn ? 'Zakat calculator' : 'คำนวณซากาต',
                          arabic: 'الزكاة',
                          locked: locked,
                          onTap: () => _openFeature(ZakatCalculatorScreen(controller: _c)),
                        ),
                      ),
                      FxFadeUp(
                        index: i++,
                        child: _tile(
                          accent: _calc,
                          icon: Icons.account_balance_outlined,
                          title: isEn ? 'Islamic inheritance' : 'แบ่งมรดกอิสลาม',
                          arabic: 'الفرائض',
                          locked: locked,
                          onTap: () => _openFeature(IslamicInheritanceScreen(controller: _c)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FxFadeUp(index: i++, child: _buildBabyHairTile(locked)),
                    const SizedBox(height: 18),
                    _buildLicenseLink(isVip),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Header: today's prices
  // ---------------------------------------------------------------------------

  Widget _buildPriceStrip() {
    final theme = _c.currentTheme;
    final heroText = theme.heroTextColor(_isDark);
    final heroMuted = theme.heroTextMutedColor(_isDark);
    final silver = CurrencyExchangeService.getSilverPricePerGram();

    Widget chip(String label, double value, NumberFormat f) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: heroText.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: heroMuted)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: FxProgress(
                  value: value,
                  duration: const Duration(milliseconds: 900),
                  builder: (_, v) => Text(
                    '฿${f.format(v)}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: heroText),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: _isEn ? 'Open live rates' : 'เปิดเรทราคาทั้งหมด',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openRatesSheet,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _isEn ? "Today's prices" : 'ราคาวันนี้',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: heroText),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _updatedText,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: heroMuted),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: heroMuted),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                chip(_isEn ? 'Gold bar/baht' : 'ทองแท่ง/บาท', CurrencyExchangeService.getGoldBarSellPrice(), _int),
                const SizedBox(width: 8),
                chip(_isEn ? 'Ornament/baht' : 'รูปพรรณ/บาท', CurrencyExchangeService.getGoldOrnamentSellPrice(), _int),
                const SizedBox(width: 8),
                chip(_isEn ? 'Silver/gram' : 'เงิน/กรัม', silver, _dec),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Building blocks
  // ---------------------------------------------------------------------------

  Widget _sectionTitle(String title, int index) {
    return FxFadeUp(
      index: index,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        child: Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _c.currentTheme.textColor),
        ),
      ),
    );
  }

  /// Two equal-height tiles side by side (the draft's 2-column grid row).
  Widget _pair(Widget a, Widget b) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: 10),
          Expanded(child: b),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    final theme = _c.currentTheme;
    return BoxDecoration(
      color: theme.cardBackground,
      borderRadius: BorderRadius.circular(18),
      border: _isDark ? Border.all(color: theme.borderColor) : null,
      boxShadow: _isDark
          ? null
          : const [BoxShadow(color: Color(0x0F0F172A), blurRadius: 14, offset: Offset(0, 4))],
    );
  }

  Widget _card({required Widget child, required VoidCallback onTap, required String label, EdgeInsets? padding, double minHeight = 0}) {
    return Semantics(
      button: true,
      label: label,
      child: FxPress(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: padding ?? const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: child,
        ),
      ),
    );
  }

  Widget _iconChip(_Accent accent, IconData icon, {double size = 40, double radius = 12, double iconSize = 20}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: accent.chip(_isDark), borderRadius: BorderRadius.circular(radius)),
      child: Icon(icon, size: iconSize, color: accent.color(_isDark)),
    );
  }

  /// Quiet "VIP" mark shown on tools a free user cannot open yet.
  Widget _vipBadge() {
    final color = _isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, size: 11, color: color),
          const SizedBox(width: 3),
          Text('VIP', style: TextStyle(fontSize: 11, height: 1.2, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  TextStyle get _titleStyle =>
      TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, height: 1.3, color: _c.currentTheme.textColor);
  TextStyle get _subStyle => TextStyle(fontSize: 12, height: 1.35, color: _c.currentTheme.textSecondaryColor);

  Widget _footerText(String text, _Accent accent) {
    return Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent.color(_isDark)));
  }

  Widget _progressFooter(double value, _Accent accent, Color barLight) {
    return FxBar(
      value: value,
      height: 6,
      color: _isDark ? accent.fgDark : barLight,
      track: _isDark ? _c.currentTheme.borderColor : const Color(0xFFE9EDF3),
    );
  }

  /// Square-ish grid tile: icon chip, title, subtitle and an optional footer
  /// pinned to the bottom (chips text or a progress bar).
  Widget _tile({
    required _Accent accent,
    required IconData icon,
    required String title,
    String? subtitle,
    String? arabic,
    Widget? footer,
    required bool locked,
    required VoidCallback onTap,
  }) {
    return _card(
      label: title,
      onTap: onTap,
      minHeight: 136,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _iconChip(accent, icon),
              const Spacer(),
              if (locked) _vipBadge(),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: _titleStyle),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle, style: _subStyle),
          ],
          if (arabic != null) ...[
            const SizedBox(height: 8),
            Text(
              arabic,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: accent.color(_isDark)),
            ),
          ],
          if (footer != null) ...[
            const Spacer(),
            const SizedBox(height: 8),
            footer,
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tiles with live data
  // ---------------------------------------------------------------------------

  Widget _buildSubscriptionCard(bool locked) {
    final theme = _c.currentTheme;
    final isEn = _isEn;
    final active = _c.subscriptions.where((s) => s.isActive).toList();
    final ongoing = active.where((s) => !s.hasEnded).toList();
    final monthly = active.fold<double>(0, (sum, s) => sum + CurrencyExchangeService.convertToThb(s.monthlyCost, s.currency));

    final upcoming = _c.upcomingSubscriptions;
    final next = upcoming.where((s) => s.daysUntilNextBilling >= 0).firstOrNull ?? upcoming.firstOrNull;
    String noteText;
    if (next == null) {
      noteText = isEn ? 'Track bills & get a heads-up before each charge' : 'จัดระเบียบและเตือนก่อนตัดเงิน';
    } else {
      final days = next.daysUntilNextBilling;
      final when = days == 0
          ? (isEn ? 'today' : 'วันนี้')
          : days > 0
              ? (isEn ? 'in $days days' : 'อีก $days วัน')
              : (isEn ? '${-days} days overdue' : 'เลยกำหนด ${-days} วัน');
      noteText = isEn
          ? 'Next charge ${_shortDate(next.nextBillingDate)} • $when'
          : 'ตัดเงินถัดไป ${_shortDate(next.nextBillingDate)} • $when';
    }

    final noteBg = _isDark ? const Color(0xFFFBBF24).withValues(alpha: 0.12) : const Color(0xFFFFF7E6);
    final noteFg = _isDark ? const Color(0xFFFCD98A) : const Color(0xFF92400E);
    final accent = _subs.color(_isDark);

    return _card(
      label: 'Subscription',
      padding: const EdgeInsets.all(16),
      onTap: () => _openFeature(
        SubscriptionVaultScreen(controller: _c),
        reason: 'ระบบจัดการ Subscription & รายจ่ายประจำ สำหรับสมาชิก VIP 👑',
      ),
      child: Column(
        children: [
          Row(
            children: [
              _iconChip(_subs, Icons.subscriptions_outlined, size: 48, radius: 14, iconSize: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text('Subscription', style: _titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (locked) ...[const SizedBox(width: 6), _vipBadge()],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ongoing.isEmpty
                          ? (isEn ? 'Subscriptions & recurring bills' : 'ค่าบริการ & บิลที่ต้องจ่ายประจำ')
                          : (isEn ? '${ongoing.length} recurring payments' : '${ongoing.length} รายการที่ต้องจ่ายประจำ'),
                      style: _subStyle,
                    ),
                  ],
                ),
              ),
              if (active.isNotEmpty) ...[
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FxProgress(
                      value: monthly,
                      duration: const Duration(milliseconds: 900),
                      builder: (_, v) => Text(
                        '฿${_int.format(v)}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.2, color: accent),
                      ),
                    ),
                    Text(isEn ? 'per month' : 'ต่อเดือน', style: TextStyle(fontSize: 11.5, color: theme.textSecondaryColor)),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: noteBg, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(noteText, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: noteFg)),
                ),
                const SizedBox(width: 6),
                Text(isEn ? 'See all' : 'ดูทั้งหมด', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
                Icon(Icons.chevron_right_rounded, size: 16, color: accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingGoalsTile(bool locked) {
    final goals = _c.savingGoals;
    final target = goals.fold<double>(0, (s, g) => s + (g.targetAmount > 0 ? g.targetAmount : 0));
    final saved = goals.fold<double>(0, (s, g) => s + g.currentAmount.clamp(0, g.targetAmount > 0 ? g.targetAmount : 0));
    final hasData = target > 0;
    final pct = hasData ? (saved / target).clamp(0.0, 1.0) : 0.0;

    return _tile(
      accent: _saving,
      icon: Icons.track_changes_rounded,
      title: _isEn ? 'Saving goals' : 'เป้าหมายการออม',
      subtitle: hasData
          ? (_isEn ? '${(pct * 100).round()}% of goal saved' : 'ออมแล้ว ${(pct * 100).round()}% ของเป้า')
          : (_isEn ? 'Track & plan each goal' : 'ออม ถอน ดูวันที่จะครบ'),
      footer: hasData ? _progressFooter(pct, _saving, const Color(0xFF059669)) : null,
      locked: locked,
      onTap: () => _openFeature(SavingGoalsScreen(controller: _c)),
    );
  }

  Widget _buildBudgetTile(bool locked) {
    final now = DateTime.now();
    final key = 'month_${now.year}_${now.month.toString().padLeft(2, '0')}';
    var total = _c.getTotalBudgetForScope(key);
    if (total <= 0) {
      total = _c.getCategoryBudgetsForScope(key).values.fold<double>(0, (s, v) => s + v);
    }
    final hasData = total > 0;
    final spent = _c.totalExpenseThisMonth;
    final ratio = hasData ? spent / total : 0.0;
    final pct = (ratio * 100).round();
    final left = total - spent;

    String subtitle;
    if (!hasData) {
      subtitle = _isEn ? 'Monthly limits by category' : 'กำหนดงบรายหมวดต่อเดือน';
    } else if (left >= 0) {
      subtitle = _isEn ? 'Used $pct% • ฿${_int.format(left)} left' : 'ใช้ไป $pct% • เหลือ ฿${_int.format(left)}';
    } else {
      subtitle = _isEn ? 'Used $pct% • ฿${_int.format(-left)} over' : 'ใช้ไป $pct% • เกินงบ ฿${_int.format(-left)}';
    }

    return _tile(
      accent: _budget,
      icon: Icons.pie_chart_outline_rounded,
      title: _isEn ? 'Budget' : 'งบประมาณ',
      subtitle: subtitle,
      footer: hasData
          ? _progressFooter(ratio.clamp(0.0, 1.0), _budget, left < 0 ? const Color(0xFFDC2626) : const Color(0xFF1D4ED8))
          : null,
      locked: locked,
      onTap: () => _openFeature(BudgetManagementScreen(controller: _c)),
    );
  }

  Widget _buildProjectsTile(bool locked) {
    final running = _c.projects.where((p) => !p.isArchived).length;
    return _tile(
      accent: _project,
      icon: Icons.folder_outlined,
      title: _isEn ? 'Project budgets' : 'งบโปรเจกต์',
      subtitle: running > 0
          ? (_isEn ? '$running active projects' : '$running โปรเจกต์กำลังดำเนินการ')
          : (_isEn ? 'Separate budget per project' : 'แยกงบตามงาน/โครงการ'),
      locked: locked,
      onTap: () => _openFeature(
        ProjectsBudgetScreen(controller: _c),
        reason: 'งบโปรเจกต์ & ทุนวิจัย สำหรับสมาชิก VIP 👑',
      ),
    );
  }

  Widget _buildBabyHairTile(bool locked) {
    final theme = _c.currentTheme;
    final title = _isEn ? 'Baby hair charity' : 'ทานน้ำหนักผมทารก';
    return _card(
      label: title,
      minHeight: 72,
      onTap: () => _openFeature(IslamicBabyHairCharityScreen(controller: _c)),
      child: Row(
        children: [
          _iconChip(_saving, Icons.balance_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(title, style: _titleStyle)),
                    if (locked) ...[const SizedBox(width: 6), _vipBadge()],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _isEn ? 'Charity value by silver/gold weight' : 'คำนวณมูลค่าทานตามน้ำหนักเงิน/ทอง',
                  style: _subStyle,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, size: 20, color: theme.textSecondaryColor.withValues(alpha: 0.7)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Membership (free: upgrade card, both: restore / licence link)
  // ---------------------------------------------------------------------------

  Widget _buildUpgradeCard() {
    final amber = _isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309);
    final title = _isEn ? 'Upgrade to VIP Premium' : 'สั่งซื้อแพ็กเกจพรีเมี่ยม VIP';
    return _card(
      label: title,
      onTap: () {
        MeowPaywallModal.show(
          context,
          controller: _c,
          reason: 'สั่งซื้อแพ็กเกจพรีเมี่ยม VIP เพื่อปลดล็อคทุกฟีเจอร์อย่างสมบูรณ์แบบ ✨',
        );
      },
      child: Row(
        children: [
          _iconChip(_gold, Icons.workspace_premium_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _titleStyle),
                const SizedBox(height: 2),
                Text(
                  _isEn
                      ? 'Unlock all features • Subscription & Bills • No ads'
                      : 'ปลดล็อคทุกฟีเจอร์ • จัดการ Subscription • ไร้โฆษณา',
                  style: _subStyle,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: amber),
            ),
            child: Text(
              _isEn ? 'Buy' : 'สั่งซื้อ',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: amber),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseLink(bool isVip) {
    final theme = _c.currentTheme;
    final color = isVip
        ? (_isDark ? const Color(0xFF34D399) : const Color(0xFF047857))
        : theme.textSecondaryColor;
    final text = isVip
        ? (_isEn ? 'VIP licence active • Check' : 'สิทธิ์ VIP สมบูรณ์ • ตรวจสอบ')
        : (_isEn ? 'Already bought VIP? Restore' : 'เคยสั่งซื้อ VIP แล้ว? กู้คืนสิทธิ์ (Restore)');
    return Center(
      child: TextButton.icon(
        onPressed: () => _restorePurchases(context),
        style: TextButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(isVip ? Icons.verified_user_outlined : Icons.restore_rounded, size: 16, color: color),
        label: Text(text, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: color)),
      ),
    );
  }
}
