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

  /// Opened from เมนู: shows the real grant status and never resets saved choices.
  final bool fromMenu;

  const PermissionOnboardingScreen({
    super.key,
    required this.controller,
    required this.onFinish,
    this.fromMenu = false,
  });

  @override
  State<PermissionOnboardingScreen> createState() => _PermissionOnboardingScreenState();
}

class _PermissionOnboardingScreenState extends State<PermissionOnboardingScreen> {
  bool _storageAllowed = true;
  bool _audioAllowed = true;
  bool _notificationAllowed = true;
  bool _cameraAllowed = true;
  bool _busy = false;

  /// What the OS has actually granted ('storage', 'audio', 'notification', 'camera'); null until loaded.
  Map<String, bool>? _granted;

  static const _keys = ['storage', 'audio', 'notification', 'camera'];

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final res = await NativeBridgeService.checkAppPermissions();
    if (!mounted) return;
    setState(() {
      _granted = {
        for (final k in _keys)
          if (res[k] is bool) k: res[k] as bool,
      };
      // Already-granted permissions start switched on.
      if (_isGranted('storage')) _storageAllowed = true;
      if (_isGranted('audio')) _audioAllowed = true;
      if (_isGranted('notification')) _notificationAllowed = true;
      if (_isGranted('camera')) _cameraAllowed = true;
    });
  }

  bool _isGranted(String key) => _granted?[key] == true;

  bool _wanted(String key) => switch (key) {
        'storage' => _storageAllowed,
        'audio' => _audioAllowed,
        'notification' => _notificationAllowed,
        _ => _cameraAllowed,
      };

  Future<void> _onConfirmAll() async {
    if (_busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    // Ask only for what is switched on and not granted yet.
    final ask = [for (final k in _keys) if (_wanted(k) && !_isGranted(k)) k];
    var status = <String, dynamic>{};
    if (ask.isNotEmpty) {
      status = await NativeBridgeService.requestAppPermissions(only: ask);
    }
    final storageOk = status['storage'] is bool ? status['storage'] as bool : (_isGranted('storage') || _storageAllowed);
    await widget.controller.savePermissions(
      bankAlbum: storageOk,
      installedApps: true,
      mainAlbum: storageOk,
    );
    final denied = [for (final k in ask) if (status[k] == false) k];
    if (!mounted) return;
    setState(() => _busy = false);
    if (denied.isNotEmpty) {
      final isEn = widget.controller.isEnglish;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(isEn
            ? 'Some permissions were not allowed. You can turn them on in Settings.'
            : 'ยังไม่ได้อนุญาตบางสิทธิ์ เปิดเองได้ที่การตั้งค่าของเครื่อง'),
        action: SnackBarAction(
          label: isEn ? 'Settings' : 'เปิดการตั้งค่า',
          onPressed: NativeBridgeService.openAppSettings,
        ),
      ));
    }
    widget.onFinish();
  }

  Future<void> _onSkip() async {
    HapticFeedback.selectionClick();
    // From the menu, leaving must not wipe choices made earlier.
    if (!widget.fromMenu) {
      await widget.controller.savePermissions(
        bankAlbum: false,
        installedApps: false,
        mainAlbum: false,
      );
    }
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
                      iconSize: 20,
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      tooltip: isEn ? 'Back' : 'ย้อนกลับ',
                      onPressed: () => Navigator.pop(context),
                    )
                  else
                    const SizedBox(width: 44),
                  if (!widget.fromMenu)
                  TextButton(
                    onPressed: _onSkip,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(44, 44),
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
                          widget.fromMenu
                              ? (isEn ? 'Device Permissions' : 'สิทธิ์การเข้าถึงอุปกรณ์')
                              : (isEn ? 'Convenience Permissions 🐾' : 'อนุญาตสิทธิ์เพื่อความสะดวก 🐾'),
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.fromMenu
                              ? (isEn
                                  ? 'See what is allowed and turn on what you need'
                                  : 'ดูสถานะ แล้วเปิดสิทธิ์ที่ต้องการใช้')
                              : (isEn
                                  ? 'Allow permissions for automatic slip scanning & smart alerts'
                                  : 'เปิดสิทธิ์เพื่อให้เหมียวสแกนสลิปและแจ้งเตือนให้อัตโนมัติ'),
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
                      granted: _isGranted('storage'),
                      grantedLabel: isEn ? 'Allowed' : 'อนุญาตแล้ว',
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
                      granted: _isGranted('audio'),
                      grantedLabel: isEn ? 'Allowed' : 'อนุญาตแล้ว',
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
                      granted: _isGranted('notification'),
                      grantedLabel: isEn ? 'Allowed' : 'อนุญาตแล้ว',
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
                      granted: _isGranted('camera'),
                      grantedLabel: isEn ? 'Allowed' : 'อนุญาตแล้ว',
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
                          widget.fromMenu
                              ? (_keys.every(_isGranted)
                                  ? (isEn ? 'Done' : 'เรียบร้อย')
                                  : (isEn ? 'Allow selected' : 'ขอสิทธิ์ที่เลือก'))
                              : (isEn ? 'Allow & Get Started 🐾' : 'อนุญาตและเริ่มต้นใช้งาน 🐾'),
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
    bool granted = false,
    String grantedLabel = '',
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
                            fontSize: 10,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (granted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF059669)),
                  const SizedBox(width: 4),
                  Text(grantedLabel,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                ],
              ),
            )
          else
            Switch.adaptive(
              value: value,
              activeThumbColor: iconColor,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}
