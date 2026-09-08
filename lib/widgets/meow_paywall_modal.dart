import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../config/app_config.dart';
import 'tactile_button.dart';
import 'meow_mascot_widget.dart';

class MeowPaywallModal extends StatefulWidget {
  final ExpenseController controller;
  final String? initialReason;

  const MeowPaywallModal({
    super.key,
    required this.controller,
    this.initialReason,
  });

  static Future<bool?> show(
    BuildContext context, {
    required ExpenseController controller,
    String? reason,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MeowPaywallModal(
        controller: controller,
        initialReason: reason,
      ),
    );
  }

  @override
  State<MeowPaywallModal> createState() => _MeowPaywallModalState();
}

class _MeowPaywallModalState extends State<MeowPaywallModal> {
  int _selectedTierIndex = 2; // Default to Lifetime (Index 2: Most Value)
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.controller.currentTheme;
    final isEn = widget.controller.isEnglish;
    final isDark = widget.controller.isDarkMode;

    final cardBg = theme.cardBackground;
    final textColor = theme.textColor;
    final subColor = theme.textSecondaryColor;
    final primary = theme.primaryColor;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                physics: const BouncingScrollPhysics(),
                children: [
                  // 1. Header with Mascot
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        MeowMascotWidget(
                          size: 72,
                          mascotId: widget.controller.selectedMascotId,
                          accessory: 'crown',
                          customPhotoPath: widget.controller.customAvatarPath,
                          isCustomPhoto: widget.controller.isCustomAvatarEnabled,
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.stars_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Center(
                    child: Text(
                      isEn ? 'MeowTang VIP Suite 👑' : 'เหมียวตังค์ VIP Suite 👑',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      isEn
                          ? 'Unlock unlimited slips, export reports & all themes'
                          : 'สแกนสลิปไม่จำกัด, ส่งออกรายงาน และปลดล็อคทุกธีม',
                      style: TextStyle(fontSize: 13, color: subColor),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Optional Reason Banner (e.g. Quota reached or Export clicked)
                  if (widget.initialReason != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.initialReason!,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // 2. Value Features List
                  _buildFeatureRow(
                    icon: Icons.qr_code_scanner_rounded,
                    color: const Color(0xFF10B981),
                    title: isEn ? 'Unlimited Slip Auto-Scanning' : 'ดึงสลิปอัตโนมัติไม่จำกัด',
                    subtitle: isEn ? 'Free tier limited to 15 slips/mo' : 'ผู้ใช้ฟรีจำกัด ${AppConfig.freeSlipsPerMonth} สลิป/เดือน',
                    textColor: textColor,
                    subColor: subColor,
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureRow(
                    icon: Icons.picture_as_pdf_rounded,
                    color: const Color(0xFFEF4444),
                    title: isEn ? 'Export PDF & Excel/CSV' : 'ส่งออกไฟล์ PDF Statement & Excel',
                    subtitle: isEn ? 'Formal financial reports for work' : 'รายงานการเงินมาตรฐานพร้อมแชร์ทันที',
                    textColor: textColor,
                    subColor: subColor,
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureRow(
                    icon: Icons.palette_rounded,
                    color: const Color(0xFF8B5CF6),
                    title: isEn ? 'Unlock All 18 Themes & Icons' : 'ปลดล็อคครบทั้ง 18 ธีมและไอคอนพิเศษ',
                    subtitle: isEn ? 'Save 29฿ per theme purchase' : 'ประหยัด 29 บาทต่อธีม ใช้ได้ฟรีทุกตัว',
                    textColor: textColor,
                    subColor: subColor,
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureRow(
                    icon: Icons.auto_awesome_rounded,
                    color: const Color(0xFFF59E0B),
                    title: isEn ? 'Live Exchange Rates & Research Budget' : 'เรททอง/เงินสด & งบวิจัยและโปรเจกต์',
                    subtitle: isEn ? 'Full financial intelligence tools' : 'ศูนย์รวมเครื่องมือคำนวณขั้นสูงครบวงจร',
                    textColor: textColor,
                    subColor: subColor,
                  ),

                  const SizedBox(height: 22),

                  // 3. Pricing Cards Selection
                  Text(
                    isEn ? 'Choose Your Plan' : 'เลือกแพ็กเกจที่เหมาะกับคุณ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Card 1: Monthly (39 THB/mo)
                  _buildTierCard(
                    index: 0,
                    title: isEn ? 'Monthly Subscription' : 'รายเดือน',
                    price: '฿${AppConfig.monthlySubPriceThb}',
                    period: isEn ? '/month' : '/เดือน',
                    badge: null,
                    badgeColor: null,
                    theme: theme,
                    textColor: textColor,
                    subColor: subColor,
                  ),
                  const SizedBox(height: 8),

                  // Card 2: Yearly (199 THB/yr)
                  _buildTierCard(
                    index: 1,
                    title: isEn ? 'Yearly Subscription' : 'รายปี',
                    price: '฿${AppConfig.yearlySubPriceThb}',
                    period: isEn ? '/year' : '/ปี (ตกเดือนละ 16฿)',
                    badge: isEn ? 'SAVE 57%' : 'ประหยัด 57% ⭐',
                    badgeColor: const Color(0xFF059669),
                    theme: theme,
                    textColor: textColor,
                    subColor: subColor,
                  ),
                  const SizedBox(height: 8),

                  // Card 3: Lifetime (390 THB Once)
                  _buildTierCard(
                    index: 2,
                    title: isEn ? 'Lifetime VIP' : 'ซื้อขาดตลอดชีพ',
                    price: '฿${AppConfig.lifetimePriceThb}',
                    period: isEn ? 'pay once, own forever' : 'จ่ายครั้งเดียว ใช้ได้ตลอดชีพ',
                    badge: isEn ? 'MOST POPULAR 👑' : 'คุ้มค่าที่สุด 👑',
                    badgeColor: const Color(0xFFD97706),
                    theme: theme,
                    textColor: textColor,
                    subColor: subColor,
                  ),

                  const SizedBox(height: 22),

                  // 4. Action CTA Button
                  TactileButton(
                    onTap: _isProcessing ? null : _handleSubscribe,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryLight,
                            theme.primaryDark,
                          ],
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
                        child: _isProcessing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getCtaText(isEn),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 5. Restore Purchases & Terms
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _handleRestore,
                        child: Text(
                          isEn ? 'Restore Purchases' : 'กู้คืนการซื้อ (Restore)',
                          style: TextStyle(
                            color: subColor,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Text(' • ', style: TextStyle(color: subColor)),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          isEn ? 'Maybe Later' : 'ไว้คราวหน้า',
                          style: TextStyle(color: subColor, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCtaText(bool isEn) {
    if (_selectedTierIndex == 0) {
      return isEn ? 'Subscribe ฿${AppConfig.monthlySubPriceThb}/mo' : 'สมัครรายเดือน ฿${AppConfig.monthlySubPriceThb}';
    } else if (_selectedTierIndex == 1) {
      return isEn ? 'Subscribe ฿${AppConfig.yearlySubPriceThb}/yr' : 'สมัครรายปี ฿${AppConfig.yearlySubPriceThb}';
    } else {
      return isEn ? 'Unlock Lifetime VIP ฿${AppConfig.lifetimePriceThb}' : 'ปลดล็อคตลอดชีพ ฿${AppConfig.lifetimePriceThb}';
    }
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(color: subColor, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTierCard({
    required int index,
    required String title,
    required String price,
    required String period,
    required String? badge,
    required Color? badgeColor,
    required dynamic theme,
    required Color textColor,
    required Color subColor,
  }) {
    final isSelected = _selectedTierIndex == index;

    return TactileButton(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTierIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor.withValues(alpha: 0.08) : theme.surfaceBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.borderColor,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? theme.primaryColor : subColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor?.withValues(alpha: 0.15) ?? Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: badgeColor ?? Colors.transparent, width: 0.8),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: badgeColor,
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
                    period,
                    style: TextStyle(color: subColor, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: isSelected ? theme.primaryColor : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubscribe() async {
    HapticFeedback.mediumImpact();
    setState(() => _isProcessing = true);

    await Future.delayed(const Duration(milliseconds: 500));

    // Simulated In-App Purchase execution (Pre-wired for Play Store Billing)
    final tier = _selectedTierIndex == 0
        ? 'monthly'
        : (_selectedTierIndex == 1 ? 'yearly' : 'lifetime');
    final expiry = _selectedTierIndex == 0
        ? DateTime.now().add(const Duration(days: 30))
        : (_selectedTierIndex == 1 ? DateTime.now().add(const Duration(days: 365)) : null);

    await widget.controller.setPremiumStatus(true, tier: tier, expiry: expiry);

    if (!mounted) return;
    setState(() => _isProcessing = false);
    Navigator.pop(context, true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('ยินดีต้อนรับสู่ MeowTang VIP สำเร็จแล้ว! 🎉'),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRestore() async {
    HapticFeedback.selectionClick();
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isProcessing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0284C7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Text('ตรวจสอบสิทธิ์การซื้อเรียบร้อยแล้ว'),
      ),
    );
  }
}
