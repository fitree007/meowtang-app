import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../widgets/meow_mascot_widget.dart';
import '../widgets/tactile_button.dart';
import '../widgets/onboarding_step_header.dart';
import 'main_navigation_screen.dart';
import 'theme_onboarding_screen.dart';

class FeatureHighlightItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String badgeText;

  const FeatureHighlightItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.badgeText,
  });
}

class AppFeaturesShowcaseScreen extends StatelessWidget {
  final ExpenseController controller;
  final VoidCallback? onCompleted;
  final bool isFromOverview;

  const AppFeaturesShowcaseScreen({
    super.key,
    required this.controller,
    this.onCompleted,
    this.isFromOverview = false,
  });

  List<FeatureHighlightItem> _getItems(bool isEn) {
    if (isEn) {
      return [
        const FeatureHighlightItem(
          icon: Icons.shield_rounded,
          title: '100% Offline Vault',
          description: 'Maximum security. All data stays strictly on your phone. No cloud sync, no tracking, zero risk.',
          color: Color(0xFF059669),
          badgeText: 'Top Security',
        ),
        const FeatureHighlightItem(
          icon: Icons.receipt_long_rounded,
          title: '22 Banks Slip Auto-Sync',
          description: 'Automatically scans & imports slips from 22 Thai banks & e-Wallets with 100% duplicate prevention.',
          color: Color(0xFF2563EB),
          badgeText: 'Auto Scan',
        ),
        const FeatureHighlightItem(
          icon: Icons.mic_rounded,
          title: 'Thai Voice AI Recording',
          description: 'Speak in natural Thai e.g. "Dinner 60 Baht" to automatically record & categorize in 1 second.',
          color: Color(0xFF06B6D4),
          badgeText: 'Voice AI',
        ),
        const FeatureHighlightItem(
          icon: Icons.track_changes_rounded,
          title: 'Financial Planning & Budgets',
          description: 'Set monthly budget limits, manage project finances, track saving goals, and visualize gauge meters.',
          color: Color(0xFF10B981),
          badgeText: 'Smart Budget',
        ),
        const FeatureHighlightItem(
          icon: Icons.currency_exchange_rounded,
          title: 'Live Global Currency Converter',
          description: 'Instant multi-currency exchange conversion with real-time exchange rates and gold price tracker.',
          color: Color(0xFF06B6D4),
          badgeText: 'Live Rates',
        ),
        const FeatureHighlightItem(
          icon: Icons.widgets_rounded,
          title: 'Home Screen Widget & Privacy Eye',
          description: 'One-tap voice shortcut widget on your home screen and privacy eye button to hide balances in public.',
          color: Color(0xFF8B5CF6),
          badgeText: 'Shortcut',
        ),
        const FeatureHighlightItem(
          icon: Icons.file_download_rounded,
          title: 'Export CSV & A4 PDF Reports',
          description: 'Generate clean Excel/CSV spreadsheets and professional A4 PDF financial statements instantly.',
          color: Color(0xFFD97706),
          badgeText: 'Reports',
        ),
        const FeatureHighlightItem(
          icon: Icons.palette_rounded,
          title: 'Themes & Custom Photo Avatar',
          description: 'Choose from 18 bespoke color themes and set your own personal photo or favorite cat as profile.',
          color: Color(0xFFEC4899),
          badgeText: 'Personalize',
        ),
        const FeatureHighlightItem(
          icon: Icons.auto_awesome_rounded,
          title: 'Zakat & Islamic Inheritance Suite',
          description: 'Dedicated Zakat calculator, Faraid inheritance distribution calculator, and Barakat charity logs.',
          color: Color(0xFFF59E0B),
          badgeText: 'Islamic Suite',
        ),
      ];
    }

    return [
      const FeatureHighlightItem(
        icon: Icons.shield_rounded,
        title: '100% Offline Vault',
        description: 'ความปลอดภัยสูงสุด ข้อมูลอยู่ในเครื่องของคุณเท่านั้น ไม่แอบส่งขึ้น Cloud ไม่ดูดเงิน ปลอดภัย 100%',
        color: Color(0xFF059669),
        badgeText: 'ปลอดภัยสูงสุด',
      ),
      const FeatureHighlightItem(
        icon: Icons.receipt_long_rounded,
        title: 'สแกนสลิปอัตโนมัติ 22 ธนาคาร',
        description: 'ตรวจจับและดึงยอด วันที่ เวลา ปลายทางจากสลิป 22 ธนาคาร & e-Wallet ชั้นนำ พร้อมระบบกันสลิปซ้ำ 100%',
        color: Color(0xFF2563EB),
        badgeText: 'ระบบ AI 0.3s',
      ),
      const FeatureHighlightItem(
        icon: Icons.mic_rounded,
        title: 'บันทึกด้วยเสียง AI พูดไทย',
        description: 'พูดภาษาไทย เช่น "กินข้าว 60 บาท" หรือ "เติมน้ำมัน 800" ระบบแยกยอดและจัดหมวดหมู่อัตโนมัติใน 1 วิ',
        color: Color(0xFF06B6D4),
        badgeText: 'จดด้วยเสียง',
      ),
      const FeatureHighlightItem(
        icon: Icons.track_changes_rounded,
        title: 'วางแผนการเงิน & ตั้งงบประมาณ',
        description: 'กำหนดงบรายจ่าย แยกโปรเจกต์งาน ตั้งเป้าหมายเงินออม พร้อมหลอดวัดความคุ้มครองการใช้เงิน',
        color: Color(0xFF10B981),
        badgeText: 'Financial Plan',
      ),
      const FeatureHighlightItem(
        icon: Icons.currency_exchange_rounded,
        title: 'แปลงค่าเงินโลกสดอัตโนมัติ',
        description: 'อัปเดตอัตราแลกเปลี่ยนเงินตราต่างประเทศและราคาทองคำแท่ง/รูปพรรณแบบเรียลไทม์ คำนวณข้ามสกุลเงินทันที',
        color: Color(0xFF0284C7),
        badgeText: 'Live Rates',
      ),
      const FeatureHighlightItem(
        icon: Icons.widgets_rounded,
        title: 'วิดเจ็ตหน้าจอโฮม & ปุ่มตาซ่อนยอด',
        description: 'แตะไอคอนหน้าจอเพื่อบันทึกเสียงทันที และกดปุ่มตาบนการ์ดเพื่อซ่อนยอดเงินเมื่ออยู่ในที่สาธารณะ',
        color: Color(0xFF8B5CF6),
        badgeText: 'ลูกเล่นฉลาด',
      ),
      const FeatureHighlightItem(
        icon: Icons.file_download_rounded,
        title: 'ส่งออกข้อมูล CSV & รายงาน PDF A4',
        description: 'ส่งออกข้อมูลเป็นไฟล์ Excel (CSV) และสร้างรายงานสเตทเมนต์ PDF ขนาด A4 พิมพ์หรือส่งต่อได้ทันที',
        color: Color(0xFFD97706),
        badgeText: 'Export รายงาน',
      ),
      const FeatureHighlightItem(
        icon: Icons.palette_rounded,
        title: 'ปรับแต่งธีม & ใส่รูปตัวเองได้',
        description: 'เลือกชุดสีธีมได้ 18 สไตล์ และสามารถอัปโหลดรูปตัวเองหรือรูปแมวตัวโปรดเป็นรูปโปรไฟล์ได้อิสระ',
        color: Color(0xFFEC4899),
        badgeText: 'ปรับแต่งอิสระ',
      ),
      const FeatureHighlightItem(
        icon: Icons.auto_awesome_rounded,
        title: 'ซะกาต & คำนวณมรดกอิสลามิก',
        description: 'คำนวณซะกาตทองคำ/เงินออม, คำนวณแบ่งกองมรดกตามหลักการอิสลามิก (ฟะรออิด), กีร็อต และบันทึกริสกีบารอกัต',
        color: Color(0xFFF59E0B),
        badgeText: 'Islamic Suite',
      ),
    ];
  }

  void _onFinish(BuildContext context) async {
    HapticFeedback.mediumImpact();
    if (isFromOverview) {
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
    final items = _getItems(isEn);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: isFromOverview
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.close_rounded, color: theme.textColor, size: 22),
                tooltip: isEn ? 'Close' : 'ปิด',
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                isEn ? 'MeowTang Features Guide' : 'คู่มือฟีเจอร์เด่นเหมียวตังค์',
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
            if (!isFromOverview)
              OnboardingStepHeader(
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Mascot Header Banner
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.cardBackground,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        MeowMascotWidget(
                          size: 64,
                          mascotId: controller.selectedMascotId,
                          accessory: 'star',
                          customPhotoPath: controller.customAvatarPath,
                          isCustomPhoto: controller.isCustomAvatarEnabled,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isEn ? '⭐ Smart Financial Companion' : '⭐ ผู้ช่วยการเงินอัจฉริยะส่วนตัว',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isEn ? 'Everything in One App' : 'ครบจบทุกฟังก์ชันในแอพเดียว',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEn
                                    ? 'Effortless budgeting, ultra-secure, and tailored for you.'
                                    : 'ช่วยคุมงบ จัดการเงินง่าย ปลอดภัยสูงสุด ออกแบบเพื่อคุณ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textSecondaryColor,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Minimal List of Highlights
                  ...items.map((item) => _buildMinimalFeatureCard(item, theme, isDark)),

                  const SizedBox(height: 16),
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
            child: isFromOverview
                ? TactileButton(
                    onTap: () => _onFinish(context),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          isEn ? 'Close Guide' : 'รับทราบและปิดหน้าต่าง',
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

  Widget _buildMinimalFeatureCard(FeatureHighlightItem item, dynamic theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: item.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textSecondaryColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
