import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../config/app_config.dart';
import '../services/ad_service.dart';
import '../services/billing_service.dart';
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
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: (_isProcessing || !canWatch) ? null : _handleWatchAd,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                                decoration: BoxDecoration(
                                  color: canWatch
                                      ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5))
                                      : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: canWatch
                                        ? const Color(0xFF10B981).withValues(alpha: 0.55)
                                        : subColor.withValues(alpha: 0.2),
                                    width: 1.2,
                                  ),
                                  boxShadow: canWatch
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.08),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: canWatch
                                            ? const Color(0xFF10B981).withValues(alpha: 0.20)
                                            : subColor.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.play_circle_fill_rounded,
                                        color: canWatch ? const Color(0xFF10B981) : subColor,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 9),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: canWatch
                                                      ? const Color(0xFF10B981).withValues(alpha: 0.18)
                                                      : subColor.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(5),
                                                ),
                                                child: Text(
                                                  isEn ? 'FREE 🎁' : 'ทางเลือกฟรี 🎁',
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: canWatch ? const Color(0xFF059669) : subColor,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  isEn ? 'Watch Ad for +2 Slips' : 'ดูคลิปโฆษณารับฟรี +2 สลิป',
                                                  style: TextStyle(
                                                    color: textColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            canWatch
                                                ? (isEn
                                                    ? 'Used $adWatches/$maxAds times this month • Resets 1st'
                                                    : 'ดูไปแล้ว $adWatches/$maxAds ครั้งเดือนนี้ • รีเซ็ตทุกวันที่ 1')
                                                : (isEn
                                                    ? 'Monthly quota reached ($maxAds/$maxAds)'
                                                    : 'ครบโควต้า $maxAds/$maxAds ครั้งเดือนนี้แล้ว'),
                                            style: TextStyle(
                                              color: canWatch ? subColor : const Color(0xFFEF4444),
                                              fontSize: 9.5,
                                              fontWeight: canWatch ? FontWeight.normal : FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: (_isProcessing || !canWatch) ? null : _handleWatchAd,
                                      icon: Icon(
                                        canWatch ? Icons.play_arrow_rounded : Icons.lock_outline_rounded,
                                        size: 15,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        canWatch ? (isEn ? 'Watch (+2)' : 'ดูคลิป (+2)') : (isEn ? 'Full' : 'ครบ'),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                                        disabledForegroundColor: Colors.white70,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                        minimumSize: const Size(64, 32),
                                        visualDensity: VisualDensity.compact,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        elevation: canWatch ? 1 : 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                            emoji: '⚡',
                            text: isEn ? 'Unlimited AI auto slip scan (22 banks)' : 'สแกนสลิปอัตโนมัติไม่จำกัด 22 ธนาคาร',
                            textColor: textColor,
                            isDark: isDark,
                          ),
                          _buildBenefitRow(
                            emoji: '📄',
                            text: isEn ? 'Export PDF and Excel reports' : 'ส่งออกรายงาน PDF และ Excel',
                            textColor: textColor,
                            isDark: isDark,
                          ),
                          _buildBenefitRow(
                            emoji: '💱',
                            text: isEn ? 'Real-time global FX, gold & silver rates' : 'เรทเงินโลกและราคาแร่ทองแร่เงินเรียลไทม์',
                            textColor: textColor,
                            isDark: isDark,
                          ),
                          _buildBenefitRow(
                            emoji: '💳',
                            text: isEn ? 'Subscriptions & unpaid bills manager' : 'จัดการบริการรายเดือน & บิลค้างชำระ',
                            textColor: textColor,
                            isDark: isDark,
                          ),
                          _buildBenefitRow(
                            emoji: '🎯',
                            text: isEn ? 'Savings goals planning & tracking' : 'วางแผนเป้าหมายการออม',
                            textColor: textColor,
                            isDark: isDark,
                          ),
                          _buildBenefitRow(
                            emoji: '📊',
                            text: isEn ? 'Comprehensive budget planning' : 'วางแผนงบประมาณ',
                            textColor: textColor,
                            isDark: isDark,
                          ),
                          _buildBenefitRow(
                            emoji: '🧮',
                            text: isEn ? 'Savings goal duration & time calculator' : 'คำนวณเวลาเก็บออม',
                            textColor: textColor,
                            isDark: isDark,
                          ),
                          _buildBenefitRow(
                            emoji: '🔬',
                            text: isEn ? 'Project & research grant budget planner' : 'วางแผนงบโปรเจกต์ & ทุนวิจัย',
                            textColor: textColor,
                            isDark: isDark,
                          ),
                          _buildBenefitRow(
                            emoji: '🕌',
                            text: isEn ? 'Zakat & Islamic inheritance (Faraid)' : 'คำนวณซะกาตและการแบ่งมรดก',
                            textColor: textColor,
                            isDark: isDark,
                          ),
                          _buildBenefitRow(
                            emoji: '🎨',
                            text: isEn ? 'Unlock all premium themes & mascots' : 'ปลดล็อคธีมทั้งหมด',
                            textColor: textColor,
                            isDark: isDark,
                          ),
                          _buildBenefitRow(
                            emoji: '✨',
                            text: isEn ? 'And all future features' : 'และฟีเจอร์อื่น ๆ ในอนาคต',
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
                            price: _price(BillingService.monthlyId, AppConfig.monthlySubPriceThb),
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
                            price: _price(BillingService.yearlyId, AppConfig.yearlySubPriceThb),
                            period: isEn ? '/yr (~33฿/mo)' : '/ปี (~33฿/ด.)',
                            badge: isEn ? 'SAVE 32% ⭐' : 'ประหยัด 32% ⭐',
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

                    const SizedBox(height: 6),
                    // Google Play requires subscription terms next to the buy button.
                    Text(
                      isEn
                          ? 'Renews automatically until cancelled. Cancel anytime in Google Play › Subscriptions.'
                          : 'ต่ออายุอัตโนมัติจนกว่าจะยกเลิก ยกเลิกได้ทุกเมื่อที่ Google Play › การสมัครใช้บริการ',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: subColor, fontSize: 10.5, height: 1.35),
                    ),
                    const SizedBox(height: 2),

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

  /// Google's price for the product (it is set in Play Console), or the
  /// app's own price until the product details have loaded.
  String _price(String productId, int fallbackThb) =>
      BillingService.instance.products[productId]?.price ?? '฿$fallbackThb';

  String _getCtaText(bool isEn) {
    if (_selectedTierIndex == 0) {
      final p = _price(BillingService.monthlyId, AppConfig.monthlySubPriceThb);
      return isEn ? 'Subscribe Monthly $p/mo' : 'สมัคร VIP รายเดือน $p/เดือน';
    } else {
      final p = _price(BillingService.yearlyId, AppConfig.yearlySubPriceThb);
      return isEn ? 'Subscribe Yearly $p/yr (Best ⭐)' : 'สมัคร VIP รายปี $p/ปี (แนะนำ ⭐)';
    }
  }

  void _toast(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(text),
      ),
    );
  }

  Widget _buildBenefitRow({
    required String emoji,
    required String text,
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
              Container(
                width: 22,
                alignment: Alignment.centerLeft,
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 6),
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

    // Google Play shows its own payment sheet; VIP is granted by BillingService
    // only once Google reports the purchase.
    final productId = _selectedTierIndex == 0 ? BillingService.monthlyId : BillingService.yearlyId;
    final result = await BillingService.instance.buy(productId);

    if (!mounted) return;
    setState(() => _isProcessing = false);
    final isEn = widget.controller.isEnglish;
    switch (result) {
      case BuyResult.success:
        break;
      case BuyResult.cancelled:
        return;
      case BuyResult.pending:
        _toast(
          isEn
              ? 'Payment is pending. VIP turns on as soon as Google confirms it.'
              : 'รอการชำระเงิน VIP จะเปิดให้อัตโนมัติเมื่อ Google ยืนยันการจ่ายเงิน',
          const Color(0xFF0284C7),
        );
        return;
      case BuyResult.unavailable:
        _toast(
          isEn
              ? 'Google Play purchases are not available right now. Please try again later.'
              : 'ยังซื้อผ่าน Google Play ไม่ได้ในตอนนี้ ลองใหม่อีกครั้งภายหลัง',
          const Color(0xFFB45309),
        );
        return;
      case BuyResult.failed:
        _toast(
          isEn ? 'The purchase did not go through. You were not charged.' : 'การสมัครไม่สำเร็จ ยังไม่มีการตัดเงิน',
          const Color(0xFFB91C1C),
        );
        return;
    }
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

    await AdMobService.instance.showRewardedAd(
      onUserEarnedReward: () async {
        await widget.controller.watchRewardedAdForBonusSlips();
      },
    );

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
    // Asks Google for the subscriptions on this Google account (new phone, reinstall).
    final active = await BillingService.instance.syncEntitlement();

    if (!mounted) return;
    setState(() => _isProcessing = false);
    final isEn = widget.controller.isEnglish;
    if (active == true) {
      Navigator.pop(context, true);
      _toast(isEn ? 'VIP restored 🎉' : 'กู้คืนสิทธิ์ VIP เรียบร้อยแล้ว 🎉', const Color(0xFF059669));
    } else if (active == false) {
      _toast(
        isEn
            ? 'No active VIP subscription on this Google account'
            : 'ไม่พบการสมัคร VIP ที่ยังใช้งานอยู่ในบัญชี Google นี้',
        const Color(0xFF0284C7),
      );
    } else {
      _toast(
        isEn ? 'Could not reach Google Play. Please try again.' : 'เชื่อมต่อ Google Play ไม่ได้ ลองใหม่อีกครั้ง',
        const Color(0xFFB45309),
      );
    }
  }
}
