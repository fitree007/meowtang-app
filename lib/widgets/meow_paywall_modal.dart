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
  int _selectedTierIndex = 1; // Default to Yearly (Index 1: Most Value)
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
                          ? 'Save 10+ hours a month on bookkeeping • Less than 1฿ per day!'
                          : 'ประหยัดเวลาทำบัญชีได้กว่า 10 ชม./เดือน เพียงวันละไม่ถึง 1 บาท! ✨',
                      style: TextStyle(fontSize: 13, color: subColor, fontWeight: FontWeight.w500),
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

                  // Rewarded Ad Option: +2 slips for this calendar month (max 10 ads/mo, 0/10 reset every month)
                  if (!widget.controller.isPremium) ...[
                    const SizedBox(height: 14),
                    Builder(
                      builder: (context) {
                        final adWatches = widget.controller.currentMonthAdWatchesCount;
                        final maxAds = widget.controller.maxMonthlyRewardedAds;
                        final canWatch = widget.controller.canWatchRewardedAd;
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                  : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF2563EB), size: 26),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isEn ? 'Watch Ad to Get +2 Slips ($adWatches/$maxAds)' : 'ดูโฆษณาเพื่อรับเพิ่ม +2 สลิป 🎬 ($adWatches/$maxAds)',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      canWatch
                                          ? (isEn
                                              ? 'Used $adWatches/$maxAds ad watches this month • Resets 1st of month'
                                              : 'ดูไปแล้ว $adWatches/$maxAds ครั้งเดือนนี้ • รีเซ็ตทุกวันที่ 1 (ไม่สะสมข้ามเดือน)')
                                          : (isEn
                                              ? 'Monthly ad quota reached ($maxAds/$maxAds) • Resets next month'
                                              : 'ครบโควต้าดูโฆษณาเดือนนี้แล้ว ($maxAds/$maxAds) • รอรีเซ็ตเดือนถัดไป'),
                                      style: TextStyle(
                                        color: canWatch ? subColor : const Color(0xFFEF4444),
                                        fontSize: 10.5,
                                        fontWeight: canWatch ? FontWeight.normal : FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: (_isProcessing || !canWatch) ? null : _handleWatchAd,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 1,
                                ),
                                child: Text(
                                  canWatch ? (isEn ? 'Watch' : 'ชมคลิป') : (isEn ? 'Full' : 'ครบแล้ว'),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 18),

                  // 2. WOW Value Features List
                  _buildFeatureRow(
                    icon: Icons.qr_code_scanner_rounded,
                    color: const Color(0xFF10B981),
                    title: isEn ? 'Unlimited AI Slip Auto-Scanning' : '⚡ ดึงสลิปอัตโนมัติ 22 ธนาคาร ไม่อั้น',
                    subtitle: isEn
                        ? 'Zero manual typing! Instant AI detection on save, no monthly limits'
                        : 'ไม่ต้องนั่งพิมพ์เอง! AI อ่านสลิปและลงบัญชีทันทีที่เซฟรูป สแกนไม่อั้น',
                    textColor: textColor,
                    subColor: subColor,
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureRow(
                    icon: Icons.shield_rounded,
                    color: const Color(0xFF059669),
                    title: isEn ? '100% Offline Vault Security' : '🔒 ความปลอดภัยสูงสุด ออฟไลน์ 100%',
                    subtitle: isEn
                        ? 'Your data stays in your device only. Never on cloud, zero hack risk'
                        : 'ข้อมูลอยู่ในเครื่องคุณคนเดียว ไม่ส่งขึ้น Cloud ไม่เชื่อมบัญชี ไม่ดูดเงิน',
                    textColor: textColor,
                    subColor: subColor,
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureRow(
                    icon: Icons.picture_as_pdf_rounded,
                    color: const Color(0xFFEF4444),
                    title: isEn ? 'Instant A4 PDF & Excel Statement Reports' : '📄 ส่งออก Statement A4 PDF & Excel ทันที',
                    subtitle: isEn
                        ? 'Professional statement reports ready for taxes, loans, or business'
                        : 'สร้างเล่มรายงานรายรับ-รายจ่ายสวยหรู พร้อมยื่นภาษี สมัครสินเชื่อ หรือร้านค้า',
                    textColor: textColor,
                    subColor: subColor,
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureRow(
                    icon: Icons.auto_awesome_rounded,
                    color: const Color(0xFFF59E0B),
                    title: isEn ? 'Live Currencies & Multi-Project Budgets' : '🌍 แปลงค่าเงินโลกสด & วางแผนงบแยกโปรเจกต์',
                    subtitle: isEn
                        ? 'Real-time exchange rates, project budgeting, and Islamic tools'
                        : 'เรทเงินต่างประเทศเรียลไทม์, ตั้งงบรายโปรเจกต์, พร้อมซะกาต & มรดกอิสลามิก',
                    textColor: textColor,
                    subColor: subColor,
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureRow(
                    icon: Icons.palette_rounded,
                    color: const Color(0xFF8B5CF6),
                    title: isEn ? 'Unlock All 18 Themes & Custom Photo' : '🎨 ปลดล็อค 18 ธีมพรีเมี่ยม & ใส่รูปตัวเองได้',
                    subtitle: isEn
                        ? 'Unlimited theme styling, custom mascot avatar, and cool sound effects'
                        : 'เปลี่ยนสีสันธีมได้ไม่ซ้ำวัน พร้อมใส่รูปโปรไฟล์ตัวเองหรือรูปแมวตัวโปรดอิสระ',
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

                  // Card 2: Yearly (299 THB/yr)
                  _buildTierCard(
                    index: 1,
                    title: isEn ? 'Yearly Subscription' : 'รายปี',
                    price: '฿${AppConfig.yearlySubPriceThb}',
                    period: isEn ? '/year (~25฿/mo)' : '/ปี (ตกเดือนละ ~25฿)',
                    badge: isEn ? 'SAVE 36% ⭐' : 'ประหยัด 36% ⭐',
                    badgeColor: const Color(0xFF059669),
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
    } else {
      return isEn ? 'Subscribe ฿${AppConfig.yearlySubPriceThb}/yr' : 'สมัครรายปี ฿${AppConfig.yearlySubPriceThb}';
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
    final tier = _selectedTierIndex == 0 ? 'monthly' : 'yearly';
    final expiry = _selectedTierIndex == 0
        ? DateTime.now().add(const Duration(days: 30))
        : DateTime.now().add(const Duration(days: 365));

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

  Future<void> _handleWatchAd() async {
    HapticFeedback.mediumImpact();
    setState(() => _isProcessing = true);

    // Simulated Google AdMob Rewarded Video completion
    await Future.delayed(const Duration(milliseconds: 1000));

    await widget.controller.watchRewardedAdForBonusSlips();

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
            Text('ยินดีด้วย! คุณได้รับสิทธิ์เพิ่ม +2 สลิปสำหรับเดือนนี้แล้ว 🎬✨'),
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
