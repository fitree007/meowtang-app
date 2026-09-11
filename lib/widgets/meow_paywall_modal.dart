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
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Minimal Header (Mascot + Title + Close Button)
                    Row(
                      children: [
                        MeowMascotWidget(
                          size: 40,
                          mascotId: widget.controller.selectedMascotId,
                          accessory: 'crown',
                          customPhotoPath: widget.controller.customAvatarPath,
                          isCustomPhoto: widget.controller.isCustomAvatarEnabled,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    isEn ? 'MeowTang VIP' : 'เหมียวตังค์ VIP',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('👑', style: TextStyle(fontSize: 15)),
                                ],
                              ),
                              const SizedBox(height: 1),
                              Text(
                                isEn
                                    ? 'Unlock all features unlimited • Less than 1฿/day ✨'
                                    : 'ปลดล็อคทุกฟีเจอร์ในแอป ไร้ขีดจำกัด เพียงวันละไม่ถึง 1฿ ✨',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: subColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: subColor, size: 20),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    // 2. Rewarded Ad Bar (Placed BEFORE perks box as agreed)
                    if (!widget.controller.isPremium) ...[
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final adWatches = widget.controller.currentMonthAdWatchesCount;
                          final maxAds = widget.controller.maxMonthlyRewardedAds;
                          final canWatch = widget.controller.canWatchRewardedAd;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: canWatch
                                  ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4))
                                  : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: canWatch
                                    ? const Color(0xFF10B981).withValues(alpha: 0.35)
                                    : subColor.withValues(alpha: 0.2),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: canWatch ? const Color(0xFF10B981) : subColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isEn ? 'FREE' : 'ทางเลือกฟรี 🎁',
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF059669),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            isEn ? 'Watch ad for +2 slips' : 'ดูคลิปรับฟรี +2 สลิป',
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        canWatch
                                            ? (isEn
                                                ? 'Used $adWatches/$maxAds this month • Resets 1st'
                                                : 'ดูไปแล้ว $adWatches/$maxAds ครั้งเดือนนี้ • รีเซ็ตทุกวันที่ 1')
                                            : (isEn
                                                ? 'Reached quota ($maxAds/$maxAds) • Resets next month'
                                                : 'ครบโควต้า $maxAds/$maxAds ครั้งเดือนนี้แล้ว • รอรีเซ็ตเดือนถัดไป'),
                                        style: TextStyle(
                                          color: canWatch ? subColor : const Color(0xFFEF4444),
                                          fontSize: 9,
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
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                    minimumSize: const Size(54, 26),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    canWatch ? (isEn ? 'Watch' : 'ชมคลิป') : (isEn ? 'Full' : 'ครบ'),
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],

                    // Optional Non-slip Reason Notice (if any)
                    if (widget.initialReason != null && !widget.initialReason!.contains('โควต้าสลิปฟรี')) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primary.withValues(alpha: 0.25), width: 0.8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: primary, size: 14),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                widget.initialReason!,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // 3. VIP Benefits Vertical List (Minimalist Clean White/Soft Background with Checkmarks)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildBenefitRow(
                            icon: Icons.qr_code_scanner_rounded,
                            text: isEn ? 'Unlimited AI auto slip scan (22 banks)' : '⚡ สแกนสลิปอัตโนมัติไม่จำกัด 22 ธนาคาร',
                            iconColor: const Color(0xFFF59E0B),
                            textColor: textColor,
                            isDark: isDark,
                          ),
                          _buildBenefitRow(
                            icon: Icons.picture_as_pdf_rounded,
                            text: isEn ? 'Export PDF and Excel reports' : '📄 ส่งออกรายงาน PDF และ Excel',
                            iconColor: const Color(0xFFF59E0B),
                            textColor: textColor,
                            isDark: isDark,
                          ),
                          _buildBenefitRow(
                            icon: Icons.track_changes_rounded,
                            text: isEn ? 'Budget planning & saving goals' : '🎯 วางแผนงบและตั้งเป้าหมายการออม',
                            iconColor: const Color(0xFFF59E0B),
                            textColor: textColor,
                            isDark: isDark,
                          ),
                          _buildBenefitRow(
                            icon: Icons.calculate_rounded,
                            text: isEn ? 'Savings goal time calculator' : '🧮 คำนวณเวลาเก็บออม',
                            iconColor: const Color(0xFFF59E0B),
                            textColor: textColor,
                            isDark: isDark,
                          ),
                          _buildBenefitRow(
                            icon: Icons.currency_exchange_rounded,
                            text: isEn ? 'Real-time global rates & gold price' : '💱 เรทเงินโลกและราคาทองคำเรียลไทม์',
                            iconColor: const Color(0xFFF59E0B),
                            textColor: textColor,
                            isDark: isDark,
                          ),
                          _buildBenefitRow(
                            icon: Icons.mosque_rounded,
                            text: isEn ? 'Zakat & Islamic inheritance (Faraid)' : '🕌 คำนวณซะกาตและแบ่งมรดก',
                            iconColor: const Color(0xFFF59E0B),
                            textColor: textColor,
                            isDark: isDark,
                          ),
                          _buildBenefitRow(
                            icon: Icons.palette_rounded,
                            text: isEn ? 'Unlock all themes & custom profile' : '🎨 ปลดล็อคธีมและรูปโปรไฟล์ทั้งหมด',
                            iconColor: const Color(0xFFF59E0B),
                            textColor: textColor,
                            isDark: isDark,
                          ),
                          _buildBenefitRow(
                            icon: Icons.auto_awesome_rounded,
                            text: isEn ? 'And all future features' : '✨ และฟีเจอร์อื่น ๆ ในอนาคต',
                            iconColor: const Color(0xFFF59E0B),
                            textColor: textColor,
                            isDark: isDark,
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 5),

                    // Subtle Trust & Security Tag
                    Center(
                      child: Text(
                        isEn
                            ? '🚫 100% Ad-Free • 🔒 100% Offline Vault Security'
                            : '🚫 ไร้โฆษณากวนใจ 100% • 🔒 ข้อมูลออฟไลน์ ปลอดภัย ไม่เสี่ยงดูดเงิน',
                        style: TextStyle(fontSize: 9.5, color: subColor, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 4. Side-by-Side Minimal Pricing Cards Selection
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

                    const SizedBox(height: 10),

                    // 5. Action CTA Button
                    TactileButton(
                      onTap: _isProcessing ? null : _handleSubscribe,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.primaryLight,
                              theme.primaryDark,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 17),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getCtaText(isEn),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // 6. Restore Purchases & Dismiss
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _handleRestore,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  Widget _buildBenefitRow({
    required IconData icon,
    required String text,
    required Color iconColor,
    required Color textColor,
    required bool isDark,
    bool showDivider = true,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.5),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF10B981),
                  size: 12,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.6,
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          ),
      ],
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
