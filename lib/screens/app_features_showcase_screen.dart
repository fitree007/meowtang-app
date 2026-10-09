import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../widgets/meow_fx.dart';
import 'app_guide_screen.dart';
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
          title: 'Effortless & Automatic',
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
          title: 'Insights & Planning',
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
          title: 'Smart Tools & Islamic Suite',
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
          title: 'Personalize Your Way',
          headerColor: const Color(0xFFBE123C),
          headerBgColor: const Color(0xFFFFE4E6),
          items: const [
            FeatureMiniCard(
              icon: Icons.pets_rounded,
              title: '22 Characters',
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
        title: 'จดง่าย อัตโนมัติ',
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
        title: 'วิเคราะห์ & วางแผน',
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
        title: 'เครื่องมือการเงิน & อิสลาม',
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
        title: 'ปรับแต่งในแบบคุณ',
        headerColor: const Color(0xFFBE123C),
        headerBgColor: const Color(0xFFFFE4E6),
        items: const [
          FeatureMiniCard(
            icon: Icons.pets_rounded,
            title: 'ตัวละคร',
            subtitle: '22 ตัว',
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
    final isEn = controller.isEnglish;
    final p = _Pal.of(controller);
    final categories = _getCategories(isEn);
    final securityItems = _getSecurityItems(isEn);
    final count = categories.fold<int>(0, (n, c) => n + c.items.length) + securityItems.length;

    final sections = <Widget>[
      _buildHero(p, isEn, count),
      for (final category in categories) _buildSection(p, category.title, category.items),
      _buildSection(p, isEn ? 'Safe & portable data' : 'ปลอดภัย & ย้ายข้อมูลได้เอง', securityItems),
    ];

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          if (_isStandalone)
            _AppBarPlain(
              pal: p,
              title: isEn ? 'All app features' : 'ฟีเจอร์ทั้งหมดของแอป',
              subtitle: isEn ? 'Everything MeowTang can do, in one place' : 'ดูภาพรวมว่าเหมียวตังค์ทำอะไรได้บ้าง',
              backLabel: isEn ? 'Back' : 'ย้อนกลับ',
            )
          else
            OnboardingStepHeader(
              controller: controller,
              currentStep: 4,
              title: isEn ? 'MeowTang Highlights' : 'จุดเด่นของเหมียวตังค์',
              subtitle: isEn
                  ? 'Smart features to take control of your finances'
                  : 'ฟีเจอร์อัจฉริยะที่จะช่วยให้คุณคุมเงินได้ง่ายขึ้น',
              onBack: controller.revertToThemeOnboarding,
              trailing: OnboardingSkipButton(controller: controller, onTap: () => _onFinish(context)),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              children: [
                for (var i = 0; i < sections.length; i++) ...[
                  if (i > 0) const SizedBox(height: 18),
                  FxFadeUp(index: i, child: sections[i]),
                ],
              ],
            ),
          ),
          if (_isStandalone)
            Container(
              decoration: BoxDecoration(color: p.card, border: Border(top: BorderSide(color: p.line))),
              padding: EdgeInsets.fromLTRB(16, 12, 16, 14 + MediaQuery.of(context).padding.bottom),
              child: _PrimaryButton(
                pal: p,
                label: isEn ? 'See step-by-step how-tos' : 'ดูวิธีใช้งานทีละขั้น',
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (_) => AppGuideScreen(controller: controller)));
                },
              ),
            )
          else
            OnboardingBottomBar(
              controller: controller,
              nextLabel: isEn ? 'Get started' : 'เริ่มใช้งานเหมียวตังค์',
              onNext: () => _onFinish(context),
              onBack: controller.revertToThemeOnboarding,
            ),
        ],
      ),
    );
  }

  Widget _buildHero(_Pal p, bool isEn, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.line)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.auto_awesome_outlined, size: 22, color: p.icon)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEn ? 'All-in-one money app' : 'ครบจบ ในแอปเดียว',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.text)),
                const SizedBox(height: 2),
                Text(
                  isEn
                      ? 'Every feature you need to manage your money in one place • $count highlights'
                      : 'ทุกฟีเจอร์ที่ต้องใช้คุมเงิน รวมไว้ในที่เดียว • $count ฟีเจอร์เด่น',
                  style: TextStyle(fontSize: 12.5, height: 1.45, color: p.sub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section label + a bordered card with two features per row.
  Widget _buildSection(_Pal p, String title, List<FeatureMiniCard> items) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildItem(p, items[i], top: i > 0, left: false)),
            Expanded(child: i + 1 < items.length ? _buildItem(p, items[i + 1], top: i > 0, left: true) : const SizedBox()),
          ],
        ),
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.sub)),
        ),
        Container(
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.line)),
          clipBehavior: Clip.antiAlias,
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _buildItem(_Pal p, FeatureMiniCard item, {required bool top, required bool left}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: top ? BorderSide(color: p.divider) : BorderSide.none,
          left: left ? BorderSide(color: p.divider) : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 22, color: p.icon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.text)),
                Text(item.subtitle, style: TextStyle(fontSize: 12.5, color: p.sub)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final _Pal pal;
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({required this.pal, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: FxPress(
          onTap: onTap,
          child: Container(
            height: 52,
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: pal.accent, borderRadius: BorderRadius.circular(16)),
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      );
}

/// White app bar: 44px back chevron, left-aligned title and a one-line subtitle.
class _AppBarPlain extends StatelessWidget {
  final _Pal pal;
  final String title;
  final String subtitle;
  final String backLabel;

  const _AppBarPlain({required this.pal, required this.title, required this.subtitle, required this.backLabel});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    return Container(
      decoration: BoxDecoration(color: p.card, border: Border(bottom: BorderSide(color: p.line))),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                tooltip: backLabel,
                icon: Icon(Icons.chevron_left_rounded, size: 30, color: p.text),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.text)),
                    const SizedBox(height: 1),
                    Text(subtitle,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: p.sub)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Neutral palette derived from the active theme (same mapping as the menu).
class _Pal {
  final Color bg, card, text, sub, icon, line, divider, accent, link;

  const _Pal({
    required this.bg,
    required this.card,
    required this.text,
    required this.sub,
    required this.icon,
    required this.line,
    required this.divider,
    required this.accent,
    required this.link,
  });

  factory _Pal.of(ExpenseController ctl) {
    final t = ctl.currentTheme;
    final dark = ctl.isDarkMode;
    return _Pal(
      bg: t.scaffoldBackground,
      card: t.cardBackground,
      text: t.textColor,
      sub: t.textSecondaryColor,
      icon: dark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
      line: t.borderColor,
      divider: dark ? Colors.white10 : const Color(0xFFEEF0F4),
      accent: t.primaryColor,
      link: dark ? const Color(0xFF93C5FD) : t.primaryColor,
    );
  }
}
