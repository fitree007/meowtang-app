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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Compact Header (Mascot + Title + Dismiss Button)
                    Row(
                      children: [
                        MeowMascotWidget(
                          size: 48,
                          mascotId: widget.controller.selectedMascotId,
                          accessory: 'crown',
                          customPhotoPath: widget.controller.customAvatarPath,
                          isCustomPhoto: widget.controller.isCustomAvatarEnabled,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    isEn ? 'MeowTang VIP Suite' : 'เหมียวตังค์ VIP Suite',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('👑', style: TextStyle(fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEn
                                    ? 'Save 10+ hrs/month • Under 1฿ per day! ✨'
                                    : 'ประหยัดเวลาทำบัญชีกว่า 10 ชม./เดือน วันละไม่ถึง 1฿ ✨',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: subColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: subColor, size: 22),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    // Optional Reason Banner (e.g. Quota reached or Export clicked)
                    if (widget.initialReason != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: primary, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.initialReason!,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Rewarded Ad Option: Slim Strip
                    if (!widget.controller.isPremium) ...[
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final adWatches = widget.controller.currentMonthAdWatchesCount;
                          final maxAds = widget.controller.maxMonthlyRewardedAds;
                          final canWatch = widget.controller.canWatchRewardedAd;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                    : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF2563EB), size: 22),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isEn ? 'Watch Ad for +2 Slips ($adWatches/$maxAds)' : 'ดูโฆษณารับ +2 สลิป 🎬 ($adWatches/$maxAds)',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        canWatch
                                            ? (isEn ? 'Resets 1st of month' : 'รีเซ็ตทุกวันที่ 1 (ไม่สะสมข้ามเดือน)')
                                            : (isEn ? 'Monthly quota reached' : 'ครบโควต้าเดือนนี้แล้ว ($maxAds/$maxAds)'),
                                        style: TextStyle(
                                          color: canWatch ? subColor : const Color(0xFFEF4444),
                                          fontSize: 9.5,
                                          fontWeight: canWatch ? FontWeight.normal : FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                ElevatedButton(
                                  onPressed: (_isProcessing || !canWatch) ? null : _handleWatchAd,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    minimumSize: const Size(60, 30),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    canWatch ? (isEn ? 'Watch' : 'ชมคลิป') : (isEn ? 'Full' : 'ครบ'),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 10),

                    // 2. WOW Value Features (Compact 2-Column Pill Grid)
                    Row(
                      children: [
                        Expanded(
                          child: _buildPerkChip(
                            icon: Icons.qr_code_scanner_rounded,
                            color: const Color(0xFF10B981),
                            title: isEn ? 'Unlimited Slip Scan' : '⚡ สแกนสลิป 22 ธ. ไม่อั้น',
                            isDark: isDark,
                            textColor: textColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildPerkChip(
                            icon: Icons.shield_rounded,
                            color: const Color(0xFF059669),
                            title: isEn ? '100% Offline Vault' : '🔒 ออฟไลน์ 100% ไร้เสี่ยง',
                            isDark: isDark,
                            textColor: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPerkChip(
                            icon: Icons.picture_as_pdf_rounded,
                            color: const Color(0xFFEF4444),
                            title: isEn ? 'Export A4 PDF & Excel' : '📄 ส่งออก PDF & Excel',
                            isDark: isDark,
                            textColor: textColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildPerkChip(
                            icon: Icons.auto_awesome_rounded,
                            color: const Color(0xFFF59E0B),
                            title: isEn ? 'Multi-Project Budget' : '🌍 แปลงเงิน & งบโปรเจกต์',
                            isDark: isDark,
                            textColor: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildPerkChip(
                      icon: Icons.palette_rounded,
                      color: const Color(0xFF8B5CF6),
                      title: isEn ? 'Unlock All 18 Themes & Custom Avatar' : '🎨 ปลดล็อคครบ 18 ธีม & ใส่รูปโปรไฟล์ตัวเอง',
                      isDark: isDark,
                      textColor: textColor,
                    ),

                    const SizedBox(height: 12),

                    // 3. Side-by-Side Pricing Cards Selection
                    Row(
                      children: [
                        Text(
                          isEn ? 'Select Plan' : 'เลือกแพ็กเกจ',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          isEn ? 'Cancel anytime' : 'ยกเลิกได้ทุกเมื่อ',
                          style: TextStyle(fontSize: 11, color: subColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        // Card 1: Monthly
                        Expanded(
                          child: _buildCompactTierCard(
                            index: 0,
                            title: isEn ? 'Monthly' : 'รายเดือน',
                            price: '฿${AppConfig.monthlySubPriceThb}',
                            period: isEn ? '/month' : '/เดือน',
                            badge: null,
                            badgeColor: null,
                            theme: theme,
                            textColor: textColor,
                            subColor: subColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Card 2: Yearly (Recommended)
                        Expanded(
                          child: _buildCompactTierCard(
                            index: 1,
                            title: isEn ? 'Yearly' : 'รายปี',
                            price: '฿${AppConfig.yearlySubPriceThb}',
                            period: isEn ? '/yr (~25฿/mo)' : '/ปี (~25฿/ด.)',
                            badge: isEn ? 'SAVE 36% ⭐' : 'ประหยัด 36% ⭐',
                            badgeColor: const Color(0xFF059669),
                            theme: theme,
                            textColor: textColor,
                            subColor: subColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 4. Action CTA Button
                    TactileButton(
                      onTap: _isProcessing ? null : _handleSubscribe,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.primaryLight,
                              theme.primaryDark,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getCtaText(isEn),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // 5. Restore Purchases & Dismiss
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _handleRestore,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          child: Text(
                            isEn ? 'Restore Purchases' : 'กู้คืนสิทธิ์ (Restore)',
                            style: TextStyle(
                              color: subColor,
                              fontSize: 11,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(' • ', style: TextStyle(color: subColor, fontSize: 11)),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          child: Text(
                            isEn ? 'Maybe Later' : 'ไว้คราวหน้า',
                            style: TextStyle(color: subColor, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCtaText(bool isEn) {
    if (_selectedTierIndex == 0) {
      return isEn ? 'Subscribe Monthly ฿${AppConfig.monthlySubPriceThb}/mo' : 'สมัคร VIP รายเดือน ฿${AppConfig.monthlySubPriceThb}/เดือน';
    } else {
      return isEn ? 'Subscribe Yearly ฿${AppConfig.yearlySubPriceThb}/yr (Best ⭐)' : 'สมัคร VIP รายปี ฿${AppConfig.yearlySubPriceThb}/ปี (แนะนำ ⭐)';
    }
  }

  Widget _buildPerkChip({
    required IconData icon,
    required Color color,
    required String title,
    required bool isDark,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTierCard({
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor.withValues(alpha: 0.08) : theme.surfaceBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.borderColor,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: isSelected ? theme.primaryColor : subColor,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: badgeColor?.withValues(alpha: 0.15) ?? Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: badgeColor ?? Colors.transparent, width: 0.6),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: price,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isSelected ? theme.primaryColor : textColor,
                    ),
                  ),
                  TextSpan(
                    text: ' $period',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: subColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
