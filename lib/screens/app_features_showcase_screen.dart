import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../widgets/meow_mascot_widget.dart';
import '../widgets/tactile_button.dart';
import '../widgets/onboarding_step_header.dart';

class FeatureMiniCard {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color iconBgColor;

  const FeatureMiniCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.iconBgColor,
  });
}

class FeatureCategorySection {
  final String title;
  final Color headerColor;
  final Color headerBgColor;
  final List<FeatureMiniCard> items;

  const FeatureCategorySection({
    required this.title,
    required this.headerColor,
    required this.headerBgColor,
    required this.items,
  });
}

class AppFeaturesShowcaseScreen extends StatelessWidget {
  final ExpenseController controller;
  final VoidCallback? onCompleted;
  final bool isFromOverview;
  final bool isFromMenu;

  const AppFeaturesShowcaseScreen({
    super.key,
    required this.controller,
    this.onCompleted,
    this.isFromOverview = false,
    this.isFromMenu = false,
  });

  bool get _isStandalone => isFromOverview || isFromMenu;

  List<FeatureCategorySection> _getCategories(bool isEn) {
    if (isEn) {
      return [
        FeatureCategorySection(
          title: '🟠 Effortless & Automatic',
          headerColor: const Color(0xFFC2410C),
          headerBgColor: const Color(0xFFFFEDD5),
          items: const [
            FeatureMiniCard(
              icon: Icons.receipt_long_rounded,
              title: 'Auto Slip Scan',
              subtitle: 'Anti-Duplicate',
              iconColor: Color(0xFFEA580C),
              iconBgColor: Color(0xFFFFEDD5),
            ),
            FeatureMiniCard(
              icon: Icons.account_balance_rounded,
              title: '22+ Thai Banks',
              subtitle: '& PaoTang',
              iconColor: Color(0xFFEA580C),
              iconBgColor: Color(0xFFFFEDD5),
            ),
            FeatureMiniCard(
              icon: Icons.mic_rounded,
              title: 'Speak & Record',
              subtitle: 'AI Powered',
              iconColor: Color(0xFFEA580C),
              iconBgColor: Color(0xFFFFEDD5),
            ),
            FeatureMiniCard(
              icon: Icons.calculate_rounded,
              title: 'Calculator',
              subtitle: 'Built-in',
              iconColor: Color(0xFFEA580C),
              iconBgColor: Color(0xFFFFEDD5),
            ),
            FeatureMiniCard(
              icon: Icons.notifications_active_rounded,
              title: 'Auto Income',
              subtitle: 'From Notifs',
              iconColor: Color(0xFFEA580C),
              iconBgColor: Color(0xFFFFEDD5),
            ),
            FeatureMiniCard(
              icon: Icons.credit_card_rounded,
              title: 'Multi-Account',
              subtitle: '& Cards',
              iconColor: Color(0xFFEA580C),
              iconBgColor: Color(0xFFFFEDD5),
            ),
          ],
        ),
        FeatureCategorySection(
          title: '🔵 Insights & Planning',
          headerColor: const Color(0xFF1D4ED8),
          headerBgColor: const Color(0xFFDBEAFE),
          items: const [
            FeatureMiniCard(
              icon: Icons.bar_chart_rounded,
              title: 'Stats & Charts',
              subtitle: 'Deep Analysis',
              iconColor: Color(0xFF2563EB),
              iconBgColor: Color(0xFFDBEAFE),
            ),
            FeatureMiniCard(
              icon: Icons.calendar_month_rounded,
              title: 'Calendar',
              subtitle: 'Cash Flow',
              iconColor: Color(0xFF2563EB),
              iconBgColor: Color(0xFFDBEAFE),
            ),
            FeatureMiniCard(
              icon: Icons.compare_arrows_rounded,
              title: 'Compare',
              subtitle: '2 Months Trend',
              iconColor: Color(0xFF2563EB),
              iconBgColor: Color(0xFFDBEAFE),
            ),
            FeatureMiniCard(
              icon: Icons.flag_rounded,
              title: 'Savings Goal',
              subtitle: 'AI Predict Date',
              iconColor: Color(0xFF2563EB),
              iconBgColor: Color(0xFFDBEAFE),
            ),
            FeatureMiniCard(
              icon: Icons.pie_chart_rounded,
              title: 'Budget Plan',
              subtitle: 'Monthly Limit',
              iconColor: Color(0xFF2563EB),
              iconBgColor: Color(0xFFDBEAFE),
            ),
            FeatureMiniCard(
              icon: Icons.folder_special_rounded,
              title: 'Project Budget',
              subtitle: '& Grants',
              iconColor: Color(0xFF2563EB),
              iconBgColor: Color(0xFFDBEAFE),
            ),
          ],
        ),
        FeatureCategorySection(
          title: '🟢 Smart Tools & Islamic Suite',
          headerColor: const Color(0xFF15803D),
          headerBgColor: const Color(0xFFDCFCE7),
          items: const [
            FeatureMiniCard(
              icon: Icons.autorenew_rounded,
              title: 'Subscriptions',
              subtitle: 'Bill Tracker',
              iconColor: Color(0xFF16A34A),
              iconBgColor: Color(0xFFDCFCE7),
            ),
            FeatureMiniCard(
              icon: Icons.currency_exchange_rounded,
              title: 'Currency FX',
              subtitle: '150+ Rates',
              iconColor: Color(0xFF16A34A),
              iconBgColor: Color(0xFFDCFCE7),
            ),
            FeatureMiniCard(
              icon: Icons.monetization_on_rounded,
              title: 'Gold & Silver',
              subtitle: 'Live Prices',
              iconColor: Color(0xFF16A34A),
              iconBgColor: Color(0xFFDCFCE7),
            ),
            FeatureMiniCard(
              icon: Icons.volunteer_activism_rounded,
              title: 'Calculate',
              subtitle: 'Zakat Nisab',
              iconColor: Color(0xFF16A34A),
              iconBgColor: Color(0xFFDCFCE7),
            ),
            FeatureMiniCard(
              icon: Icons.balance_rounded,
              title: 'Inheritance',
              subtitle: 'Islamic Faraid',
              iconColor: Color(0xFF16A34A),
              iconBgColor: Color(0xFFDCFCE7),
            ),
            FeatureMiniCard(
              icon: Icons.child_care_rounded,
              title: 'Baby Hair',
              subtitle: 'Weight Charity',
              iconColor: Color(0xFF16A34A),
              iconBgColor: Color(0xFFDCFCE7),
            ),
          ],
        ),
        FeatureCategorySection(
          title: '🔴 Personalize Your Way',
          headerColor: const Color(0xFFBE123C),
          headerBgColor: const Color(0xFFFFE4E6),
          items: const [
            FeatureMiniCard(
              icon: Icons.pets_rounded,
              title: '21 Mascot Cats',
              subtitle: 'Choose Companion',
              iconColor: Color(0xFFE11D48),
              iconBgColor: Color(0xFFFFE4E6),
            ),
            FeatureMiniCard(
              icon: Icons.face_rounded,
              title: 'Custom Photo',
              subtitle: 'Set Own Avatar',
              iconColor: Color(0xFFE11D48),
              iconBgColor: Color(0xFFFFE4E6),
            ),
            FeatureMiniCard(
              icon: Icons.palette_rounded,
              title: '18 Themes',
              subtitle: 'Handcrafted',
              iconColor: Color(0xFFE11D48),
              iconBgColor: Color(0xFFFFE4E6),
            ),
            FeatureMiniCard(
              icon: Icons.brightness_medium_rounded,
              title: 'Dark / Light',
              subtitle: 'Auto Switch',
              iconColor: Color(0xFFE11D48),
              iconBgColor: Color(0xFFFFE4E6),
            ),
            FeatureMiniCard(
              icon: Icons.widgets_rounded,
              title: 'Widget',
              subtitle: 'Home Screen',
              iconColor: Color(0xFFE11D48),
              iconBgColor: Color(0xFFFFE4E6),
            ),
            FeatureMiniCard(
              icon: Icons.label_rounded,
              title: 'Categories',
              subtitle: '& Custom Tags',
              iconColor: Color(0xFFE11D48),
              iconBgColor: Color(0xFFFFE4E6),
            ),
          ],
        ),
      ];
    }

    return [
      FeatureCategorySection(
        title: '🟠 จดง่าย อัตโนมัติ',
        headerColor: const Color(0xFFC2410C),
        headerBgColor: const Color(0xFFFFEDD5),
        items: const [
          FeatureMiniCard(
            icon: Icons.receipt_long_rounded,
            title: 'สลิปเข้าเอง',
            subtitle: 'กันยอดซ้ำ',
            iconColor: Color(0xFFEA580C),
            iconBgColor: Color(0xFFFFEDD5),
          ),
          FeatureMiniCard(
            icon: Icons.account_balance_rounded,
            title: '22+ ธนาคาร',
            subtitle: '& เป๋าตัง',
            iconColor: Color(0xFFEA580C),
            iconBgColor: Color(0xFFFFEDD5),
          ),
          FeatureMiniCard(
            icon: Icons.mic_rounded,
            title: 'พูดแล้วจด',
            subtitle: 'ด้วย AI',
            iconColor: Color(0xFFEA580C),
            iconBgColor: Color(0xFFFFEDD5),
          ),
          FeatureMiniCard(
            icon: Icons.calculate_rounded,
            title: 'เครื่องคิดเลข',
            subtitle: 'ในตัว',
            iconColor: Color(0xFFEA580C),
            iconBgColor: Color(0xFFFFEDD5),
          ),
          FeatureMiniCard(
            icon: Icons.notifications_active_rounded,
            title: 'ดึงรายรับ',
            subtitle: 'จากแจ้งเตือน',
            iconColor: Color(0xFFEA580C),
            iconBgColor: Color(0xFFFFEDD5),
          ),
          FeatureMiniCard(
            icon: Icons.credit_card_rounded,
            title: 'หลายบัญชี',
            subtitle: '& บัตรเครดิต',
            iconColor: Color(0xFFEA580C),
            iconBgColor: Color(0xFFFFEDD5),
          ),
        ],
      ),
      FeatureCategorySection(
        title: '🔵 วิเคราะห์ & วางแผน',
        headerColor: const Color(0xFF1D4ED8),
        headerBgColor: const Color(0xFFDBEAFE),
        items: const [
          FeatureMiniCard(
            icon: Icons.bar_chart_rounded,
            title: 'สถิติ & กราฟ',
            subtitle: 'วิเคราะห์เชิงลึก',
            iconColor: Color(0xFF2563EB),
            iconBgColor: Color(0xFFDBEAFE),
          ),
          FeatureMiniCard(
            icon: Icons.calendar_month_rounded,
            title: 'ปฏิทิน',
            subtitle: 'รายรับ–รายจ่าย',
            iconColor: Color(0xFF2563EB),
            iconBgColor: Color(0xFFDBEAFE),
          ),
          FeatureMiniCard(
            icon: Icons.compare_arrows_rounded,
            title: 'เทียบ 2 เดือน',
            subtitle: 'ดูแนวโน้ม',
            iconColor: Color(0xFF2563EB),
            iconBgColor: Color(0xFFDBEAFE),
          ),
          FeatureMiniCard(
            icon: Icons.flag_rounded,
            title: 'เป้าหมายออม',
            subtitle: 'AI คาดวันครบ',
            iconColor: Color(0xFF2563EB),
            iconBgColor: Color(0xFFDBEAFE),
          ),
          FeatureMiniCard(
            icon: Icons.pie_chart_rounded,
            title: 'วางแผน',
            subtitle: 'งบประมาณ',
            iconColor: Color(0xFF2563EB),
            iconBgColor: Color(0xFFDBEAFE),
          ),
          FeatureMiniCard(
            icon: Icons.folder_special_rounded,
            title: 'งบโปรเจกต์',
            subtitle: '& ทุนวิจัย',
            iconColor: Color(0xFF2563EB),
            iconBgColor: Color(0xFFDBEAFE),
          ),
        ],
      ),
      FeatureCategorySection(
        title: '🟢 เครื่องมือการเงิน & อิสลาม',
        headerColor: const Color(0xFF15803D),
        headerBgColor: const Color(0xFFDCFCE7),
        items: const [
          FeatureMiniCard(
            icon: Icons.autorenew_rounded,
            title: 'คุมค่า',
            subtitle: 'Subscription',
            iconColor: Color(0xFF16A34A),
            iconBgColor: Color(0xFFDCFCE7),
          ),
          FeatureMiniCard(
            icon: Icons.currency_exchange_rounded,
            title: 'แปลงค่าเงิน',
            subtitle: '150+ สกุล',
            iconColor: Color(0xFF16A34A),
            iconBgColor: Color(0xFFDCFCE7),
          ),
          FeatureMiniCard(
            icon: Icons.monetization_on_rounded,
            title: 'ราคาทอง',
            subtitle: '& แร่เงิน',
            iconColor: Color(0xFF16A34A),
            iconBgColor: Color(0xFFDCFCE7),
          ),
          FeatureMiniCard(
            icon: Icons.volunteer_activism_rounded,
            title: 'คำนวณ',
            subtitle: 'ซากาต',
            iconColor: Color(0xFF16A34A),
            iconBgColor: Color(0xFFDCFCE7),
          ),
          FeatureMiniCard(
            icon: Icons.balance_rounded,
            title: 'แบ่งมรดก',
            subtitle: 'อิสลาม',
            iconColor: Color(0xFF16A34A),
            iconBgColor: Color(0xFFDCFCE7),
          ),
          FeatureMiniCard(
            icon: Icons.child_care_rounded,
            title: 'ทานน้ำหนัก',
            subtitle: 'ผมทารก',
            iconColor: Color(0xFF16A34A),
            iconBgColor: Color(0xFFDCFCE7),
          ),
        ],
      ),
      FeatureCategorySection(
        title: '🔴 ปรับแต่งในแบบคุณ',
        headerColor: const Color(0xFFBE123C),
        headerBgColor: const Color(0xFFFFE4E6),
        items: const [
          FeatureMiniCard(
            icon: Icons.pets_rounded,
            title: 'น้องแมว',
            subtitle: '21 ตัว',
            iconColor: Color(0xFFE11D48),
            iconBgColor: Color(0xFFFFE4E6),
          ),
          FeatureMiniCard(
            icon: Icons.face_rounded,
            title: 'ใส่รูป',
            subtitle: 'ตัวเองได้',
            iconColor: Color(0xFFE11D48),
            iconBgColor: Color(0xFFFFE4E6),
          ),
          FeatureMiniCard(
            icon: Icons.palette_rounded,
            title: 'ธีมสวย',
            subtitle: '18 แบบ',
            iconColor: Color(0xFFE11D48),
            iconBgColor: Color(0xFFFFE4E6),
          ),
          FeatureMiniCard(
            icon: Icons.brightness_medium_rounded,
            title: 'โหมดมืด',
            subtitle: '/ สว่าง',
            iconColor: Color(0xFFE11D48),
            iconBgColor: Color(0xFFFFE4E6),
          ),
          FeatureMiniCard(
            icon: Icons.widgets_rounded,
            title: 'วิดเจ็ต',
            subtitle: 'หน้าจอ',
            iconColor: Color(0xFFE11D48),
            iconBgColor: Color(0xFFFFE4E6),
          ),
          FeatureMiniCard(
            icon: Icons.label_rounded,
            title: 'จัดหมวด',
            subtitle: '& แท็ก',
            iconColor: Color(0xFFE11D48),
            iconBgColor: Color(0xFFFFE4E6),
          ),
        ],
      ),
    ];
  }

  List<FeatureMiniCard> _getSecurityItems(bool isEn) {
    if (isEn) {
      return const [
        FeatureMiniCard(
          icon: Icons.shield_rounded,
          title: '100% Offline Vault',
          subtitle: 'Never Sent to Cloud',
          iconColor: Color(0xFF38BDF8),
          iconBgColor: Color(0xFF0F172A),
        ),
        FeatureMiniCard(
          icon: Icons.save_rounded,
          title: 'Secure Backup',
          subtitle: 'Own .rizqi Local File',
          iconColor: Color(0xFFFBBF24),
          iconBgColor: Color(0xFF0F172A),
        ),
        FeatureMiniCard(
          icon: Icons.qr_code_2_rounded,
          title: 'Easy Migration',
          subtitle: 'Direct QR Code / LINE',
          iconColor: Color(0xFF34D399),
          iconBgColor: Color(0xFF0F172A),
        ),
        FeatureMiniCard(
          icon: Icons.file_download_rounded,
          title: 'Export Reports',
          subtitle: 'Excel · CSV · PDF A4',
          iconColor: Color(0xFFFB7185),
          iconBgColor: Color(0xFF0F172A),
        ),
      ];
    }
    return const [
      FeatureMiniCard(
        icon: Icons.shield_rounded,
        title: 'ข้อมูลอยู่ในเครื่อง 100%',
        subtitle: 'ไม่ส่งขึ้น Cloud',
        iconColor: Color(0xFF38BDF8),
        iconBgColor: Color(0xFF0F172A),
      ),
      FeatureMiniCard(
        icon: Icons.save_rounded,
        title: 'สำรองข้อมูล',
        subtitle: 'ไฟล์ .rizqi เก็บเอง',
        iconColor: Color(0xFFFBBF24),
        iconBgColor: Color(0xFF0F172A),
      ),
      FeatureMiniCard(
        icon: Icons.qr_code_2_rounded,
        title: 'ย้ายเครื่องง่าย',
        subtitle: 'ด้วย QR Code / LINE',
        iconColor: Color(0xFF34D399),
        iconBgColor: Color(0xFF0F172A),
      ),
      FeatureMiniCard(
        icon: Icons.file_download_rounded,
        title: 'ส่งออกรายงาน',
        subtitle: 'Excel · CSV · PDF',
        iconColor: Color(0xFFFB7185),
        iconBgColor: Color(0xFF0F172A),
      ),
    ];
  }

  void _onFinish(BuildContext context) async {
    HapticFeedback.mediumImpact();
    if (_isStandalone) {
      Navigator.pop(context);
      return;
    }
    await controller.completeShowcase();
    onCompleted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = controller.currentTheme;
    final isDark = controller.isDarkMode;
    final isEn = controller.isEnglish;
    final categories = _getCategories(isEn);
    final securityItems = _getSecurityItems(isEn);

    return Scaffold(
      backgroundColor: _isStandalone ? theme.scaffoldBackground : const Color(0xFFFDFBF7),
      appBar: _isStandalone
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.close_rounded, color: theme.textColor, size: 24),
                tooltip: isEn ? 'Close' : 'ปิด',
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                isEn ? 'Featured App Superpowers' : 'ฟีเจอร์เด่นของแอพ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              centerTitle: true,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            if (!_isStandalone)
              OnboardingStepHeader(
                currentStep: 4,
                totalSteps: 4,
                badgeText: isEn ? 'Step 4/4 • Features' : 'ขั้นตอนที่ 4/4 • จุดเด่นของแอพ',
                stepIcon: Icons.auto_awesome_rounded,
                title: isEn ? 'MeowTang Highlights' : 'จุดเด่นของเหมียวตังค์',
                subtitle: isEn
                    ? 'Smart features to take control of your finances'
                    : 'ฟีเจอร์อัจฉริยะที่จะช่วยให้คุณคุมเงินได้ง่ายขึ้น',
                primaryColor: theme.primaryColor,
                textColor: theme.textColor,
                subtitleColor: theme.textSecondaryColor,
                trailing: TextButton(
                  onPressed: () => _onFinish(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    isEn ? 'Skip' : 'ข้าม',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Hero Header Banner
                  _buildHeroHeader(theme, isDark, isEn),

                  const SizedBox(height: 16),

                  // 4 Main Feature Categories (3-column grid)
                  for (final category in categories) ...[
                    _buildCategorySection(category, theme, isDark),
                    const SizedBox(height: 14),
                  ],

                  // Security & Migration Dark Container
                  _buildSecuritySection(securityItems, isEn),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: theme.surfaceBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 50,
            child: _isStandalone
                ? TactileButton(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          isEn ? 'Close' : 'ปิดหน้าต่าง',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      // Back Button (35%)
                      Expanded(
                        flex: 35,
                        child: TactileButton(
                          onTap: () async {
                            HapticFeedback.selectionClick();
                            await controller.revertToThemeOnboarding();
                          },
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.borderColor),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_back_rounded, size: 16, color: theme.textColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    isEn ? 'Back' : 'ย้อนกลับ',
                                    style: TextStyle(
                                      color: theme.textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Finish Button (65%)
                      Expanded(
                        flex: 65,
                        child: TactileButton(
                          onTap: () => _onFinish(context),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [theme.primaryColor, theme.secondaryColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primaryColor.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isEn ? 'Get Started 🐱✨' : 'เริ่มใช้งานเหมียวตังค์ 🐱✨',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(dynamic theme, bool isDark, bool isEn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFFDE68A),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: isDark ? 0.05 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isEn ? 'All-in-One ' : 'ครบจบ ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: theme.textColor,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE047),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFCA8A04).withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: Text(
                  isEn ? 'Finance App' : 'ในแอปเดียว',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF854D0E),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isEn
                ? 'Every feature you need to manage your money in one place'
                : 'ทุกฟีเจอร์ที่ต้องใช้คุมเงิน รวมไว้ในที่เดียว',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: theme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(FeatureCategorySection section, dynamic theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? section.headerColor.withValues(alpha: 0.18) : section.headerBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: section.headerColor.withValues(alpha: isDark ? 0.35 : 0.2),
            ),
          ),
          child: Text(
            section.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? section.headerColor.withValues(alpha: 0.9) : section.headerColor,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // 3 Columns x 2 Rows Grid
        Row(
          children: [
            Expanded(child: _buildItemCard(section.items[0], theme, isDark)),
            const SizedBox(width: 8),
            Expanded(child: _buildItemCard(section.items[1], theme, isDark)),
            const SizedBox(width: 8),
            Expanded(child: _buildItemCard(section.items[2], theme, isDark)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildItemCard(section.items[3], theme, isDark)),
            const SizedBox(width: 8),
            Expanded(child: _buildItemCard(section.items[4], theme, isDark)),
            const SizedBox(width: 8),
            Expanded(child: _buildItemCard(section.items[5], theme, isDark)),
          ],
        ),
      ],
    );
  }

  Widget _buildItemCard(FeatureMiniCard item, dynamic theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? item.iconColor.withValues(alpha: 0.18) : item.iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, size: 20, color: item.iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            item.subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              color: theme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(List<FeatureMiniCard> items, bool isEn) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_rounded, size: 16, color: Color(0xFF38BDF8)),
              const SizedBox(width: 6),
              Text(
                isEn ? '🔒 Ultra Secure & Full Ownership' : '🔒 ปลอดภัย & ย้ายข้อมูลได้เอง',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF8FAFC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSecurityCard(items[0])),
              const SizedBox(width: 8),
              Expanded(child: _buildSecurityCard(items[1])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildSecurityCard(items[2])),
              const SizedBox(width: 8),
              Expanded(child: _buildSecurityCard(items[3])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(FeatureMiniCard item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, size: 18, color: item.iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.8,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            item.subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
