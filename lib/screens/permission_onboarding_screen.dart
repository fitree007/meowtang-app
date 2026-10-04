import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../widgets/meow_mascot_widget.dart';
import '../services/native_bridge_service.dart';
import '../widgets/tactile_button.dart';

class PermissionOnboardingScreen extends StatefulWidget {
  final ExpenseController controller;
  final VoidCallback onFinish;

  const PermissionOnboardingScreen({
    super.key,
    required this.controller,
    required this.onFinish,
  });

  @override
  State<PermissionOnboardingScreen> createState() => _PermissionOnboardingScreenState();
}

class _PermissionOnboardingScreenState extends State<PermissionOnboardingScreen> {
  bool _storageAllowed = true;
  bool _audioAllowed = true;
  bool _notificationAllowed = true;
  bool _cameraAllowed = true;

  Future<void> _onConfirmAll() async {
    HapticFeedback.mediumImpact();
    await NativeBridgeService.requestAppPermissions();
    await widget.controller.savePermissions(
      bankAlbum: _storageAllowed,
      installedApps: true,
      mainAlbum: _storageAllowed,
    );
    widget.onFinish();
  }

  Future<void> _onSkip() async {
    HapticFeedback.selectionClick();
    await widget.controller.savePermissions(
      bankAlbum: false,
      installedApps: false,
      mainAlbum: false,
    );
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final isEn = widget.controller.isEnglish;
    final isDark = widget.controller.isDarkMode;
    final bgColor = isDark ? MeowTheme.navyBackground : const Color(0xFFFDFBF7);
    final cardColor = isDark ? MeowTheme.navySurface : Colors.white;
    final textPrimary = isDark ? MeowTheme.textLightPrimary : const Color(0xFF0F172A);
    final textSecondary = isDark ? MeowTheme.textLightSecondary : const Color(0xFF64748B);
    final borderColor = isDark ? MeowTheme.borderColor : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            children: [
              // Top Bar: Back & Skip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (Navigator.canPop(context))
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: textPrimary,
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: isEn ? 'Back' : 'ย้อนกลับ',
                      onPressed: () => Navigator.pop(context),
                    )
                  else
                    const SizedBox(width: 18),
                  TextButton(
                    onPressed: _onSkip,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      isEn ? 'Skip' : 'ข้ามไปก่อน',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Header: Mascot + Title (Compact & Crisp)
              Row(
                children: [
                  MeowMascotWidget(
                    size: 52,
                    mascotId: widget.controller.selectedMascotId,
                    accessory: widget.controller.selectedMascotAccessory,
                    isHeadOnly: true,
                    animate: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn ? 'Convenience Permissions 🐾' : 'อนุญาตสิทธิ์เพื่อความสะดวก 🐾',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEn
                              ? 'Allow permissions for automatic slip scanning & smart alerts'
                              : 'เปิดสิทธิ์เพื่อให้เหมียวสแกนสลิปและแจ้งเตือนให้อัตโนมัติ',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4 Compact Permission Tiles (No Scrolling Needed)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 1. Photos & Media
                    _buildCompactTile(
                      icon: Icons.photo_library_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: isEn ? 'Photos & Bank Slips' : 'คลังรูปภาพและสลิปธนาคาร',
                      desc: isEn ? 'Auto-scan slips from K PLUS, SCB, KTB, etc.' : 'สแกนสลิปโอนเงินเข้าแอพและจดบัญชีอัตโนมัติ',
                      badge: isEn ? 'RECOMMENDED' : 'แนะนำ',
                      value: _storageAllowed,
                      onChanged: (v) => setState(() => _storageAllowed = v),
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),

                    // 2. Microphone (Voice AI)
                    _buildCompactTile(
                      icon: Icons.mic_rounded,
                      iconColor: const Color(0xFF0EA5E9),
                      title: isEn ? 'Microphone (Voice AI)' : 'ไมโครโฟน (พูดบันทึกด้วยเสียง AI)',
                      desc: isEn ? 'Speak e.g. "Coffee 60 baht" to log instantly' : 'พูดจดรายการ เช่น "กาแฟ 60 บาท" ไม่ต้องพิมพ์',
                      value: _audioAllowed,
                      onChanged: (v) => setState(() => _audioAllowed = v),
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),

                    // 3. Notifications
                    _buildCompactTile(
                      icon: Icons.notifications_active_rounded,
                      iconColor: const Color(0xFF6366F1),
                      title: isEn ? 'Notifications & Alerts' : 'การแจ้งเตือนสลิป & ตัดรอบบิล',
                      desc: isEn ? 'Instant alerts on new slips & bill due dates' : 'แจ้งเตือนเมื่อพบสลิปใหม่และเตือนครบกำหนดบิล',
                      value: _notificationAllowed,
                      onChanged: (v) => setState(() => _notificationAllowed = v),
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),

                    // 4. Camera
                    _buildCompactTile(
                      icon: Icons.camera_alt_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      title: isEn ? 'Camera (Paper Receipts)' : 'กล้องถ่ายรูป (สแกนสลิปสด/ใบเสร็จ)',
                      desc: isEn ? 'Snap paper receipts or physical bills instantly' : 'ถ่ายรูปสลิปหรือใบเสร็จกระดาษหน้าร้านได้ทันที',
                      value: _cameraAllowed,
                      onChanged: (v) => setState(() => _cameraAllowed = v),
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Offline Privacy Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEn
                            ? '100% Private & Offline: Slips processed locally on your phone.'
                            : 'ปลอดภัย 100%: รูปสลิปและข้อมูลทั้งหมดประมวลผลในเครื่อง ไม่ส่งออกภายนอก',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Confirm Button (Full Width, Compact & Tactile)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TactileButton(
                  onTap: _onConfirmAll,
                  child: Container(
                    decoration: BoxDecoration(
                      color: MeowTheme.actionBlue,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: MeowTheme.actionBlue.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          isEn ? 'Allow & Get Started 🐾' : 'อนุญาตและเริ่มต้นใช้งาน 🐾',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    String? badge,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? iconColor.withValues(alpha: 0.35) : borderColor,
          width: value ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: iconColor,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeColor: iconColor,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
