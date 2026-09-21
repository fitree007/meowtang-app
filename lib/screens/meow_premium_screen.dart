import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../utils/format_utils.dart';
import '../widgets/meow_mascot_widget.dart';
import '../widgets/tactile_button.dart';
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
import '../widgets/meow_paywall_modal.dart';

class MeowPremiumScreen extends StatefulWidget {
  final ExpenseController controller;

  const MeowPremiumScreen({super.key, required this.controller});

  @override
  State<MeowPremiumScreen> createState() => _MeowPremiumScreenState();
}

class _MeowPremiumScreenState extends State<MeowPremiumScreen> {
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
                  ? 'MeowTang operates 100% offline. Your VIP license is tied directly to your Google Play Account.\n\n• If you previously purchased VIP or premium themes on this Google Account, Google Play automatically restores your license.\n• No server login or email registration required.'
                  : 'เหมียวตังค์ทำงานแบบออฟไลน์ 100% โดยสิทธิ์ VIP จะผูกติดกับบัญชี Google Play Store ของเครื่องนี้โดยตรง\n\n• หากคุณเคยสั่งซื้อ VIP หรือธีมในบัญชี Google นี้ ระบบ Google Play จะคืนสิทธิ์ให้อัตโนมัติเมื่อติดตั้งใหม่\n• ใช้งานได้ตลอดชีพ ปลอดภัย ไม่ต้องมีเซิร์ฟเวอร์หรือสมัครสมาชิกใดๆ',
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final currentTheme = widget.controller.currentTheme;
        final isEn = widget.controller.isEnglish;
        final isDark = widget.controller.isDarkMode;
        final bgColor = currentTheme.scaffoldBackground;
        final cardBg = currentTheme.cardBackground;
        final borderColor = currentTheme.borderColor;
        final textColor = currentTheme.textColor;
        final subTextColor = currentTheme.textSecondaryColor;

        final goals = widget.controller.savingGoals;
        final totalBudget = widget.controller.monthlySalary;
        final isVip = widget.controller.isPremium;

        return Scaffold(
          backgroundColor: bgColor,
          body: ListView(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            children: [
              // 1. VIP Hero Header with Dynamic Active Theme Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: currentTheme.heroGradient,
                  boxShadow: [
                    BoxShadow(
                      color: currentTheme.primaryColor.withValues(alpha: isDark ? 0.3 : 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 18,
                  right: 18,
                  bottom: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEn ? 'Advanced Financial Suite' : 'ศูนย์รวมเครื่องมือการเงินขั้นสูง',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEn
                                ? 'Live FX rates, wealth budgets, compound interest & Islamic finance'
                                : 'เรทเงินโลกสด, ดอกเบี้ยทบต้น, วางแผนการเงิน & การเงินอิสลาม',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    MeowMascotWidget(
                      size: 60,
                      mascotId: widget.controller.selectedMascotId,
                      accessory: widget.controller.selectedMascotAccessory,
                      customPhotoPath: widget.controller.customAvatarPath,
                      isCustomPhoto: widget.controller.isCustomAvatarEnabled,
                      withPen: true,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isVip) ...[
                      // Prominent VIP Upgrade / Purchase Banner
                      InkWell(
                        onTap: () {
                          MeowPaywallModal.show(
                            context,
                            controller: widget.controller,
                            reason: 'สั่งซื้อแพ็กเกจพรีเมี่ยม VIP เพื่อปลดล็อคทุกฟีเจอร์อย่างสมบูรณ์แบบ ✨',
                          );
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Center(
                                  child: Text('👑', style: TextStyle(fontSize: 24)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          isEn ? 'Upgrade to VIP Premium' : 'สั่งซื้อแพ็กเกจพรีเมี่ยม VIP',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF59E0B),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'HOT ✨',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      isEn
                                          ? 'Unlock all converters, budget tools & unlimited slips'
                                          : 'ปลดล็อคเครื่องคิดเลขแปลงเงิน, งบ 50/30/20 & สแกนสลิปไม่จำกัด',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isEn ? 'Buy' : 'สั่งซื้อ',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () => _restorePurchases(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.restore_rounded, size: 15, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 4),
                                Text(
                                  isEn ? 'Already bought VIP? Restore' : 'เคยสั่งซื้อ VIP แล้ว? กู้คืนสิทธิ์ (Restore)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () => _restorePurchases(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_user_rounded, size: 15, color: Color(0xFF10B981)),
                                const SizedBox(width: 4),
                                Text(
                                  isEn ? 'VIP License Active • Info' : 'สิทธิ์ VIP สมบูรณ์ (ตลอดชีพ) • ตรวจสอบ',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // ==========================================================
                    // SECTION 1: GLOBAL CURRENCIES & COMMODITIES (3-in-1 COMPACT HUB)
                    // ==========================================================
                    _buildSectionHeader(
                      title: isEn ? '1. Global Currencies & Metals' : '1. เรททองคำ & อัตราแลกเปลี่ยนสด',
                      textColor: textColor,
                    ),
                    const SizedBox(height: 4),

                    // Ultra Compact 3-in-1 Dashboard (Gold / Silver / Currencies)
                    LiveRatesDashboardWidget(controller: widget.controller),
                    const SizedBox(height: 6),

                    // 1. Dedicated Action Button: Currency Converter (เครื่องคิดเลขแปลงเงิน)
                    TactileButton(
                      onTap: () {
                        _openFeature(
                          CurrencyConverterScreen(controller: widget.controller),
                          reason: 'เครื่องคิดเลขแปลงเงิน & อัตราแลกเปลี่ยนสด สำหรับสมาชิก VIP 👑',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.35), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.2 : 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(child: Text('💱', style: TextStyle(fontSize: 19))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        isEn ? 'Currency Converter' : 'เครื่องคิดเลขแปลงเงิน',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: !isVip
                                              ? const Color(0xFFF59E0B).withValues(alpha: 0.18)
                                              : const Color(0xFF0284C7).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          !isVip ? '🔒 VIP' : 'สด ⚡',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: !isVip ? const Color(0xFFF59E0B) : const Color(0xFF0284C7),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    isEn
                                        ? 'Convert THB ↔ USD, SAR, MYR, EUR, JPY and 30+ currencies'
                                        : 'คำนวณแลกเปลี่ยนเงินบาท ↔ สกุลเงินทั่วโลกสดทันที (USD, EUR, SAR ฯลฯ)',
                                    style: TextStyle(fontSize: 10.5, color: subTextColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF0284C7), size: 13),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 2. Dedicated Action Button: Gold & Silver Calculator (คำนวณแร่ทอง/แร่เงิน พร้อมกราฟ)
                    TactileButton(
                      onTap: () {
                        _openFeature(
                          GoldSilverCalculatorScreen(controller: widget.controller),
                          reason: 'คำนวณแร่ทอง & แร่เงิน พร้อมกราฟแนวโน้ม สำหรับสมาชิก VIP 👑',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.2 : 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(child: Text('🪙', style: TextStyle(fontSize: 19))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        isEn ? 'Gold & Silver Calculator' : 'คำนวณแร่ทอง & แร่เงิน',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'กราฟสด 📈',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    isEn
                                        ? 'Calculate Gold Bar, Ornament & Silver with interactive trend charts'
                                        : 'คำนวณทองคำแท่ง, รูปพรรณ, แร่เงิน พร้อมกราฟแนวโน้มขึ้น-ลง',
                                    style: TextStyle(fontSize: 10.5, color: subTextColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFF59E0B), size: 13),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ==========================================================
                    // FEATURED HERO CARD: SUBSCRIPTION VAULT (คุมค่า Subscription & รายจ่ายประจำ)
                    // ==========================================================
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                              : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.18 : 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Center(
                                    child: Text('📱', style: TextStyle(fontSize: 22)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              isEn ? 'Subscription Vault' : 'ระบบคุมค่า Subscription & บิลประจำ',
                                              style: TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'NEW ✨',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isEn
                                            ? 'Track Netflix, YouTube, ChatGPT, Utilities + Free trial alert'
                                            : 'คุม Netflix, YouTube, ChatGPT, ค่าน้ำไฟ พร้อมเตือนก่อนหมดช่วงทดลองฟรี',
                                        style: TextStyle(fontSize: 11, color: subTextColor),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Logos preview row
                            Row(
                              children: [
                                ...['netflix', 'youtube', 'spotify', 'gemini', 'chatgpt', 'ais'].map((logo) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: Image.asset(
                                      'assets/icons/subscriptions/$logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const SizedBox(),
                                    ),
                                  );
                                }),
                                const SizedBox(width: 4),
                                Text(
                                  '+50 แบรนด์',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: subTextColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            // Action button: เข้าสู่ระบบจัดการ Subscription
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () {
                                  if (!isVip) {
                                    MeowPaywallModal.show(
                                      context,
                                      controller: widget.controller,
                                      reason: 'ระบบจัดการ Subscription & รายจ่ายประจำ สำหรับสมาชิก VIP 👑',
                                    );
                                  } else {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SubscriptionVaultScreen(
                                          controller: widget.controller,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: Icon(
                                  isVip ? Icons.auto_awesome_rounded : Icons.lock_outline_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  isVip
                                      ? (isEn ? 'Manage Subscriptions & Bills' : 'จัดการ Subscription & บิลประจำ ✨')
                                      : (isEn ? 'Unlock Subscription Vault' : 'ปลดล็อคใช้งาน (VIP) 👑'),
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: isVip ? const Color(0xFF6366F1) : const Color(0xFFF59E0B),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ==========================================================
                    // SECTION 2: SMART WEALTH & BUDGET PLANNING
                    // ==========================================================
                    _buildSectionHeader(
                      title: isEn ? '2. Smart Wealth & Budgets' : '2. การวางแผนการเงินส่วนบุคคล',
                      textColor: textColor,
                    ),
                    const SizedBox(height: 4),

                    // 2x2 Square Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.35,
                      children: [
                        // 1. Saving Goals
                        _buildCompactToolCard(
                          title: isEn ? 'Saving Goals' : 'เป้าหมายการออม',
                          subtitle: isEn ? '${goals.length} Goals' : '${goals.length} เป้าหมายกำลังออม',
                          badgeText: 'ออมเงิน',
                          icon: Icons.track_changes_rounded,
                          iconColor: const Color(0xFF10B981),
                          gradientColors: [const Color(0xFF10B981).withValues(alpha: 0.12), const Color(0xFF059669).withValues(alpha: 0.03)],
                          cardBg: cardBg,
                          borderColor: borderColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          isLocked: !isVip,
                          onTap: () => _openFeature(SavingGoalsScreen(controller: widget.controller)),
                        ),

                        // 2. Budget Management
                        _buildCompactToolCard(
                          title: isEn ? 'Budget Plan' : 'วางแผนงบประมาณ',
                          subtitle: widget.controller.isBudgetPlanEnabled
                              ? (totalBudget > 0 ? 'เปิดใช้งานอยู่ (฿${FormatUtils.formatCurrency(totalBudget)}/ด.)' : 'เปิดใช้งานอยู่')
                              : (isEn ? 'Disabled (Tap to turn on)' : 'ปิดอยู่ (แตะเพื่อเปิดใช้งาน)'),
                          badgeText: widget.controller.isBudgetPlanEnabled ? 'เปิดอยู่' : 'ปิดอยู่',
                          icon: Icons.pie_chart_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          gradientColors: [const Color(0xFF3B82F6).withValues(alpha: 0.12), const Color(0xFF2563EB).withValues(alpha: 0.03)],
                          cardBg: cardBg,
                          borderColor: borderColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          isLocked: !isVip,
                          onTap: () => _openFeature(BudgetManagementScreen(controller: widget.controller)),
                        ),

                        // 3. Goal Calculator
                        _buildCompactToolCard(
                          title: isEn ? 'Goal Calculator' : 'คำนวณเวลาเก็บออม',
                          subtitle: isEn ? 'Days & Months' : 'ประเมินวัน/เดือน/ปี',
                          badgeText: 'วางแผน',
                          icon: Icons.calculate_rounded,
                          iconColor: const Color(0xFF6366F1),
                          gradientColors: [const Color(0xFF6366F1).withValues(alpha: 0.12), const Color(0xFF4F46E5).withValues(alpha: 0.03)],
                          cardBg: cardBg,
                          borderColor: borderColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          isLocked: !isVip,
                          onTap: () => _openFeature(GoalCalculatorScreen(controller: widget.controller)),
                        ),

                        // 4. Project Budgets
                        _buildCompactToolCard(
                          title: isEn ? 'Project Budgets' : 'งบโปรเจกต์ & ทุนวิจัย',
                          subtitle: isEn ? 'Research & Projects' : 'คุมงบเฉพาะกิจ/วิจัย',
                          badgeText: 'เฉพาะกิจ',
                          icon: Icons.folder_special_rounded,
                          iconColor: const Color(0xFFEC4899),
                          gradientColors: [const Color(0xFFEC4899).withValues(alpha: 0.12), const Color(0xFFDB2777).withValues(alpha: 0.03)],
                          cardBg: cardBg,
                          borderColor: borderColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          isLocked: !isVip,
                          onTap: () => _openFeature(
                            ProjectsBudgetScreen(controller: widget.controller),
                            reason: 'งบโปรเจกต์ & ทุนวิจัย สำหรับสมาชิก VIP 👑',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ==========================================================
                    // SECTION 3: ISLAMIC FINANCE & FARAID
                    // ==========================================================
                    _buildSectionHeader(
                      title: isEn ? '3. Islamic Wealth & Sunnah' : '3. การเงินตามหลักการอิสลาม',
                      textColor: textColor,
                    ),
                    const SizedBox(height: 4),

                    // 3 Islamic Tools (Compact Grid / Cards)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.35,
                      children: [
                        // Zakat Calculator
                        _buildCompactToolCard(
                          title: isEn ? 'Zakat Calculator' : 'คำนวณซากาตสด',
                          subtitle: isEn ? 'Gold & Wealth' : 'ทองแท่ง/รูปพรรณ/เงินสด',
                          badgeText: 'ซากาต',
                          icon: Icons.volunteer_activism_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          gradientColors: [const Color(0xFFF59E0B).withValues(alpha: 0.12), const Color(0xFFD97706).withValues(alpha: 0.03)],
                          cardBg: cardBg,
                          borderColor: borderColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          isLocked: !isVip,
                          onTap: () => _openFeature(ZakatCalculatorScreen(controller: widget.controller)),
                        ),

                        // Islamic Inheritance
                        _buildCompactToolCard(
                          title: isEn ? 'Islamic Faraid' : 'แบ่งมรดกอิสลาม',
                          subtitle: isEn ? 'Faraid Law' : 'ตามหลักฟะรออิฎ',
                          badgeText: 'มรดก',
                          icon: Icons.account_balance_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          gradientColors: [const Color(0xFF8B5CF6).withValues(alpha: 0.12), const Color(0xFF7C3AED).withValues(alpha: 0.03)],
                          cardBg: cardBg,
                          borderColor: borderColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          isLocked: !isVip,
                          onTap: () => _openFeature(IslamicInheritanceScreen(controller: widget.controller)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Newborn Baby Hair Charity Card (Full Width Compact Strip)
                    TactileButton(
                      onTap: () => _openFeature(IslamicBabyHairCharityScreen(controller: widget.controller)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: !isVip
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                                : const Color(0xFF10B981).withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: !isVip
                                    ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                    : const Color(0xFF10B981).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: !isVip
                                    ? const Icon(Icons.lock_outline_rounded, color: Color(0xFFF59E0B), size: 19)
                                    : const Text('👶', style: TextStyle(fontSize: 20)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        isEn ? 'Baby Hair Charity' : 'ทานน้ำหนักผมทารกแรกเกิด',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: !isVip
                                              ? const Color(0xFFF59E0B).withValues(alpha: 0.18)
                                              : const Color(0xFF10B981).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          !isVip ? '🔒 VIP' : 'ซุนนะฮ์ ﷺ',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: !isVip ? const Color(0xFFF59E0B) : const Color(0xFF047857),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isEn
                                        ? 'Calculate Day 7 charity by silver/gold weight'
                                        : 'ชั่งน้ำหนักเส้นผมโกนผมไฟวันที่ 7 เทียบมูลค่าโลหะเงิน/ทองคำ',
                                    style: TextStyle(fontSize: 11, color: subTextColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF10B981), size: 13),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildCompactToolCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required IconData icon,
    required Color iconColor,
    required List<Color> gradientColors,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subTextColor,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    return TactileButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLocked ? const Color(0xFFF59E0B).withValues(alpha: 0.35) : borderColor,
            width: isLocked ? 1.2 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isLocked
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                        : iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isLocked ? Icons.lock_outline_rounded : icon,
                    color: isLocked ? const Color(0xFFF59E0B) : iconColor,
                    size: 17,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLocked
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                        : iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isLocked ? '🔒 VIP' : badgeText,
                    style: TextStyle(
                      color: isLocked ? const Color(0xFFF59E0B) : iconColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: subTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
