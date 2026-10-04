import 'package:flutter/material.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../widgets/meow_mascot_widget.dart';
import '../services/native_bridge_service.dart';

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
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _isDark = widget.controller.isDarkMode;
  }

  Future<void> _onConfirmAll() async {
    widget.controller.toggleThemeMode(_isDark);
    // Request actual OS permissions for device first before triggering state update & navigation
    await NativeBridgeService.requestAppPermissions();
    await widget.controller.savePermissions(
      bankAlbum: _storageAllowed,
      installedApps: true,
      mainAlbum: _storageAllowed,
    );
    widget.onFinish();
  }

  Future<void> _onSkip() async {
    widget.controller.toggleThemeMode(_isDark);
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
    final bgColor = _isDark ? MeowTheme.navyBackground : const Color(0xFFF8FAFC);
    final cardColor = _isDark ? MeowTheme.navySurface : Colors.white;
    final textPrimary = _isDark ? MeowTheme.textLightPrimary : const Color(0xFF0F172A);
    final textSecondary = _isDark ? MeowTheme.textLightSecondary : const Color(0xFF64748B);
    final borderColor = _isDark ? MeowTheme.borderColor : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Top Navigation / Back Button (if push navigation)
            Row(
              children: [
                if (Navigator.canPop(context))
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: textPrimary,
                    iconSize: 20,
                    tooltip: isEn ? 'Back' : 'ย้อนกลับ',
                    onPressed: () => Navigator.pop(context),
                  )
                else
                  const SizedBox(height: 38),
                const Spacer(),
                TextButton(
                  onPressed: _onSkip,
                  child: Text(
                    isEn ? 'Skip for now' : 'ข้ามไปก่อน',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Header with Mascot
            Center(
              child: Column(
                children: [
                  MeowMascotWidget(
                    size: 80,
                    mascotId: widget.controller.selectedMascotId,
                    accessory: widget.controller.selectedMascotAccessory,
                    withPen: true,
                    animate: true,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isEn ? 'Permissions & Privacy' : 'อนุญาตสิทธิ์เพื่อความสะดวก 🐾',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isEn
                        ? 'MeowTang needs these device permissions to automatically read slips and record expenses for you'
                        : 'เพื่อให้เหมียวตังค์ช่วยดูดสลิปและบันทึกรายรับ-รายจ่ายให้อัตโนมัติ โปรดให้สิทธิ์ตามรายการด้านล่างนี้ครับ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Theme Switcher Section (Dark / Light Mode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.palette_outlined, color: MeowTheme.mustardYellow, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.controller.tr('theme_picker_title'),
                      style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                  ),
                  Row(
                    children: [
                      // Light Mode
                      GestureDetector(
                        onTap: () => setState(() => _isDark = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: !_isDark ? MeowTheme.actionBlue.withOpacity(0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: !_isDark ? MeowTheme.actionBlue : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.light_mode, size: 14, color: !_isDark ? MeowTheme.actionBlue : Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                widget.controller.tr('theme_light'),
                                style: TextStyle(
                                  color: !_isDark ? MeowTheme.actionBlue : Colors.grey,
                                  fontWeight: !_isDark ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Dark Mode
                      GestureDetector(
                        onTap: () => setState(() => _isDark = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isDark ? MeowTheme.mustardYellow.withOpacity(0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isDark ? MeowTheme.mustardYellow : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.dark_mode, size: 14, color: _isDark ? MeowTheme.mustardYellow : Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                widget.controller.tr('theme_dark'),
                                style: TextStyle(
                                  color: _isDark ? MeowTheme.mustardYellow : Colors.grey,
                                  fontWeight: _isDark ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Permission Section Header
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                isEn ? 'Permissions Needed' : 'สิทธิ์ที่จำเป็นในการใช้งาน',
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),

            // Permission 1: Storage / Bank Slips (Most Important!)
            _buildPermissionCard(
              icon: Icons.photo_library_rounded,
              iconColor: const Color(0xFF10B981),
              title: isEn ? 'Photos & Media (Bank Slips)' : 'คลังรูปภาพและสลิปธนาคาร 📸',
              subtitle: isEn
                  ? 'Required to scan and auto-import bank transfer slips from PaoTang, K PLUS, SCB, Krungthai, etc.'
                  : 'จำเป็นอย่างยิ่ง: ใช้อ่านสลิปโอนเงินจาก เป๋าตัง, K PLUS, SCB, Krungthai, etc. เข้าแอพทันที',
              badge: isEn ? 'CRITICAL' : 'สำคัญที่สุด',
              badgeColor: const Color(0xFF10B981),
              value: _storageAllowed,
              onChanged: (val) => setState(() => _storageAllowed = val),
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 10),

            // Permission 2: Microphone (Voice AI)
            _buildPermissionCard(
              icon: Icons.mic_rounded,
              iconColor: const Color(0xFF0EA5E9),
              title: isEn ? 'Microphone (Voice AI)' : 'ไมโครโฟน (บันทึกด้วยเสียง AI) 🎙️',
              subtitle: isEn
                  ? 'Allows speaking transactions e.g. "Lunch 65 baht" without typing'
                  : 'ใช้รับเสียงพูดภาษาไทย เช่น "ข้าวกะเพรา 60 บาท" เพื่อจดบันทึกให้ทันทีโดยไม่ต้องพิมพ์',
              badge: isEn ? 'RECOMMENDED' : 'แนะนำ',
              badgeColor: const Color(0xFF0EA5E9),
              value: _audioAllowed,
              onChanged: (val) => setState(() => _audioAllowed = val),
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 10),

            // Permission 3: Notifications
            _buildPermissionCard(
              icon: Icons.notifications_active_rounded,
              iconColor: const Color(0xFF6366F1),
              title: isEn ? 'Notifications' : 'การแจ้งเตือนสลิป & ตัดรอบบิล 🔔',
              subtitle: isEn
                  ? 'Notifies you immediately when a new slip is detected or when a bill is due'
                  : 'แจ้งเตือนสรุปทันทีเมื่อตรวจพบสลิปใหม่ และเตือนก่อนถึงวันตัดรอบบิลรายเดือน',
              value: _notificationAllowed,
              onChanged: (val) => setState(() => _notificationAllowed = val),
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 10),

            // Permission 4: Camera
            _buildPermissionCard(
              icon: Icons.camera_alt_rounded,
              iconColor: const Color(0xFFF59E0B),
              title: isEn ? 'Camera' : 'กล้องถ่ายรูป (สแกนบิลสด) 📷',
              subtitle: isEn
                  ? 'Allows taking photos of paper receipts and physical transfer slips'
                  : 'ใช้สำหรับถ่ายรูปใบเสร็จกระดาษหรือสลิปสดๆ จากหน้าร้านค้า',
              value: _cameraAllowed,
              onChanged: (val) => setState(() => _cameraAllowed = val),
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 14),

            // Privacy & Offline Security Assurance
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEn
                          ? '100% Private & Offline: All slips and financial records are processed locally on your phone. No data is ever uploaded.'
                          : 'ปลอดภัย 100%: รูปสลิปและข้อมูลการเงินทั้งหมดถูกอ่านและประมวลผลภายในมือถือของคุณเท่านั้น ไม่มีการส่งรูปภาพออกสู่เซิร์ฟเวอร์ภายนอก',
                      style: TextStyle(
                        color: _isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Primary Confirm Button
            Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: MeowTheme.blueButtonGradient,
                borderRadius: BorderRadius.circular(27),
                boxShadow: [
                  BoxShadow(
                    color: MeowTheme.actionBlue.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                ),
                onPressed: _onConfirmAll,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isEn ? 'Allow All Permissions & Start 🐾' : 'อนุญาตสิทธิ์ทั้งหมด & เริ่มต้นใช้งาน 🐾',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badge,
    Color? badgeColor,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? iconColor.withOpacity(0.3) : borderColor,
          width: value ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (badge != null && badgeColor != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Switch(
            value: value,
            activeColor: iconColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
