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
import '../widgets/live_rates_dashboard_widget.dart';
import '../widgets/meow_paywall_modal.dart';
import '../config/app_config.dart';

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
                          InkWell(
                            onTap: () {
                              if (!isVip) {
                                MeowPaywallModal.show(
                                  context,
                                  controller: widget.controller,
                                  reason: 'สมัคร VIP เพื่อปลดล็อคเครื่องมือพรีเมี่ยมทั้งหมด 👑',
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isVip ? Icons.stars_rounded : Icons.lock_outline_rounded,
                                    size: 13,
                                    color: const Color(0xFFFDE047),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isVip
                                        ? (isEn ? 'PREMIUM SUITE • VIP UNLOCKED 👑' : 'ศูนย์รวมเครื่องมือพรีเมี่ยม • สิทธิ์ VIP พรีเมี่ยม 👑')
                                        : (isEn ? 'PREMIUM SUITE • VIP ONLY 🔒' : 'ศูนย์รวมเครื่องมือพรีเมี่ยม • สำหรับสมาชิก VIP 🔒'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            isEn ? 'Smart Financial Hub' : 'พรีเมี่ยม & ปัญญาการเงิน',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEn
                                ? 'Live Exchange, Budgets & Islamic Tools'
                                : 'เรทเงินโลกสด, วางแผนการเงิน และหลักการอิสลาม',
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
                    // ==========================================================
                    // SECTION 1: GLOBAL CURRENCIES & COMMODITIES (3-in-1 COMPACT HUB)
                    // ==========================================================
                    _buildSectionHeader(
                      title: isEn ? 'Global Currencies & Metals' : '1. เรททองคำ & อัตราแลกเปลี่ยนสด 💱',
                      icon: Icons.currency_exchange_rounded,
                      iconColor: const Color(0xFF0284C7),
                      textColor: textColor,
                      trailing: InkWell(
                        onTap: () {
                          _openFeature(
                            CurrencyConverterScreen(controller: widget.controller),
                            reason: 'เครื่องคิดเลขแปลงเงิน & อัตราแลกเปลี่ยนสด สำหรับสมาชิก VIP 👑',
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'เครื่องคิดเลขแปลงเงิน',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                              ),
                              SizedBox(width: 2),
                              Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF0284C7)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Ultra Compact 3-in-1 Dashboard (Gold / Silver / Currencies)
                    LiveRatesDashboardWidget(controller: widget.controller),
                    const SizedBox(height: 8),

                    // Dedicated Action Button: Currency & Gold Converter Calculator
                    TactileButton(
                      onTap: () {
                        _openFeature(
                          CurrencyConverterScreen(controller: widget.controller),
                          reason: 'เครื่องคิดเลขแปลงเงิน & คำนวณทอง สำหรับสมาชิก VIP 👑',
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
                                        isEn ? 'Currency & Gold Calculator' : 'เครื่องคิดเลขแปลงเงิน & คำนวณทอง',
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
                                          color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'สด ⚡',
                                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    isEn
                                        ? 'Convert THB ↔ USD, SAR, MYR, Gold, Silver'
                                        : 'คำนวณแลกเปลี่ยนเงินบาท ↔ สกุลเงินทั่วโลก & คำนวณราคาทองคำ',
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
                    const SizedBox(height: 14),

                    // ==========================================================
                    // SECTION 2: SMART WEALTH & BUDGET PLANNING
                    // ==========================================================
                    _buildSectionHeader(
                      title: isEn ? 'Smart Wealth & Budgets' : '2. การวางแผนการเงินส่วนบุคคล 🎯',
                      icon: Icons.track_changes_rounded,
                      iconColor: const Color(0xFF10B981),
                      textColor: textColor,
                    ),
                    const SizedBox(height: 6),

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
                          onTap: () => _openFeature(
                            ProjectsBudgetScreen(controller: widget.controller),
                            reason: 'งบโปรเจกต์ & ทุนวิจัย สำหรับสมาชิก VIP 👑',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ==========================================================
                    // SECTION 3: ISLAMIC FINANCE & FARAID
                    // ==========================================================
                    _buildSectionHeader(
                      title: isEn ? 'Islamic Wealth & Sunnah' : '3. การเงินตามหลักการอิสลาม 🕌',
                      icon: Icons.mosque_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      textColor: textColor,
                    ),
                    const SizedBox(height: 6),

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
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 1.2),
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
                                color: const Color(0xFF10B981).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(child: Text('👶', style: TextStyle(fontSize: 20))),
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
                                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'ซุนนะฮ์ ﷺ',
                                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
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
    required IconData icon,
    required Color iconColor,
    required Color textColor,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        ?trailing,
      ],
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
  }) {
    return TactileButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
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
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 17),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: iconColor,
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
