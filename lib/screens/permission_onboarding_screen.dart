import 'package:flutter/material.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../widgets/meow_mascot_widget.dart';

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
 bool _bankAlbumAllowed = true;
 bool _installedAppsAllowed = true;
 bool _mainAlbumAllowed = true;
 late bool _isDark;

 @override
 void initState() {
  super.initState();
  _isDark = widget.controller.isDarkMode;
  _bankAlbumAllowed = widget.controller.isBankAlbumAllowed;
  _installedAppsAllowed = widget.controller.isInstalledAppsAllowed;
  _mainAlbumAllowed = widget.controller.isMainAlbumAllowed;
 }

 void _onConfirm() {
  widget.controller.toggleThemeMode(_isDark);
  widget.controller.savePermissions(
   bankAlbum: _bankAlbumAllowed,
   installedApps: _installedAppsAllowed,
   mainAlbum: _mainAlbumAllowed,
  );
  widget.onFinish();
 }

 @override
 Widget build(BuildContext context) {
  final bgColor = _isDark ? MeowTheme.navyBackground : const Color(0xFFF8FAFC);
  final cardColor = _isDark ? MeowTheme.navySurface : Colors.white;
  final textPrimary = _isDark ? MeowTheme.textLightPrimary : const Color(0xFF0F172A);
  final textSecondary = _isDark ? MeowTheme.textLightSecondary : const Color(0xFF64748B);
  final borderColor = _isDark ? MeowTheme.borderColor : const Color(0xFFE2E8F0);

  return Scaffold(
   backgroundColor: bgColor,
   body: SafeArea(
    child: ListView(
     padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
     children: [
      const SizedBox(height: 10),
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
         const SizedBox(height: 14),
         Text(
          widget.controller.isEnglish
            ? 'Welcome to MeowTang'
            : 'ยินดีต้อนรับสู่ เหมียวตังค์',
          style: TextStyle(
           color: textPrimary,
           fontSize: 22,
           fontWeight: FontWeight.bold,
          ),
         ),
         const SizedBox(height: 6),
         Text(
          widget.controller.isEnglish
            ? 'Configure slip permissions and display theme for seamless auto-tracking'
            : 'ตั้งค่าสิทธิ์การเข้าถึงและธีม เพื่อให้ระบบอ่านสลิปอัตโนมัติได้อย่างสมบูรณ์',
          textAlign: TextAlign.center,
          style: TextStyle(
           color: textSecondary,
           fontSize: 13,
           height: 1.4,
          ),
         ),
        ],
       ),
      ),
      const SizedBox(height: 24),

      // Theme Switcher Section (Dark / Light Mode)
      Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
       ),
       child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Row(
          children: [
           const Icon(Icons.palette_outlined, color: MeowTheme.mustardYellow, size: 20),
           const SizedBox(width: 8),
           Text(
            widget.controller.tr('theme_picker_title'),
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
           ),
          ],
         ),
         const SizedBox(height: 12),
         Row(
          children: [
           // Dark Mode Option
           Expanded(
            child: GestureDetector(
             onTap: () => setState(() => _isDark = true),
             child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
               color: _isDark ? const Color(0xFF0B1728) : (_isDark ? MeowTheme.navyCard : const Color(0xFFF1F5F9)),
               borderRadius: BorderRadius.circular(12),
               border: Border.all(
                color: _isDark ? MeowTheme.mustardYellow : Colors.transparent,
                width: 2,
               ),
              ),
              child: Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                Icon(Icons.dark_mode, size: 18, color: _isDark ? MeowTheme.mustardYellow : Colors.grey),
                const SizedBox(width: 8),
                Text(
                 widget.controller.tr('theme_dark'),
                 style: TextStyle(
                  color: _isDark ? Colors.white : Colors.grey[700],
                  fontWeight: _isDark ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                 ),
                ),
               ],
              ),
             ),
            ),
           ),
           const SizedBox(width: 10),
           // Light Mode Option
           Expanded(
            child: GestureDetector(
             onTap: () => setState(() => _isDark = false),
             child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
               color: !_isDark ? Colors.white : MeowTheme.navyCard,
               borderRadius: BorderRadius.circular(12),
               border: Border.all(
                color: !_isDark ? MeowTheme.actionBlue : Colors.transparent,
                width: 2,
               ),
              ),
              child: Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                Icon(Icons.light_mode, size: 18, color: !_isDark ? MeowTheme.actionBlue : Colors.grey),
                const SizedBox(width: 8),
                Text(
                 widget.controller.tr('theme_light'),
                 style: TextStyle(
                  color: !_isDark ? const Color(0xFF0F172A) : Colors.grey[400],
                  fontWeight: !_isDark ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                 ),
                ),
               ],
              ),
             ),
            ),
           ),
          ],
         ),
        ],
       ),
      ),
      const SizedBox(height: 18),

      // Permission Section Header
      Padding(
       padding: const EdgeInsets.only(left: 4, bottom: 8),
       child: Text(
        widget.controller.isEnglish ? 'Required Permissions' : 'สิทธิ์การเข้าถึงที่จำเป็น',
        style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
       ),
      ),

      // Permission 1: Bank Albums
      _buildPermissionCard(
       icon: Icons.account_balance_outlined,
       iconColor: MeowTheme.mustardYellow,
       title: widget.controller.isEnglish ? 'Bank Album Slip Photos' : 'รูปภาพสลิปในอัลบั้มธนาคารต่างๆ',
       subtitle: widget.controller.isEnglish
         ? 'Allow reading transfer slips in banking app folders (e.g. K PLUS, SCB Easy, Krungthai NEXT) for automatic recording'
         : 'อนุญาตให้อ่านเฉพาะรูปสลิปในโฟลเดอร์ของแอปธนาคาร (เช่น K PLUS, SCB Easy, Krungthai NEXT) เพื่อดึงยอดเงินและบันทึกอัตโนมัติ',
       value: _bankAlbumAllowed,
       onChanged: (val) => setState(() => _bankAlbumAllowed = val),
       cardColor: cardColor,
       borderColor: borderColor,
       textPrimary: textPrimary,
       textSecondary: textSecondary,
      ),
      const SizedBox(height: 12),

      // Permission 2: Installed Banking Apps
      _buildPermissionCard(
       icon: Icons.apps_outlined,
       iconColor: MeowTheme.actionBlue,
       title: widget.controller.isEnglish ? 'Banking App Identification' : 'อ่านรายการแอปการเงินที่ติดตั้ง',
       subtitle: widget.controller.isEnglish
         ? 'Detect installed banking apps to accurately map sender and receiver bank accounts'
         : 'ตรวจจับแอปธนาคารที่ติดตั้งในเครื่อง เพื่อช่วยจับคู่บัญชีธนาคารต้นทางและปลายทางได้อย่างแม่นยำ',
       value: _installedAppsAllowed,
       onChanged: (val) => setState(() => _installedAppsAllowed = val),
       cardColor: cardColor,
       borderColor: borderColor,
       textPrimary: textPrimary,
       textSecondary: textSecondary,
      ),
      const SizedBox(height: 12),

      // Permission 3: Main Photos Gallery
      _buildPermissionCard(
       icon: Icons.photo_library_outlined,
       iconColor: MeowTheme.incomeGreen,
       title: widget.controller.isEnglish ? 'Main Gallery Slip Photos' : 'อ่านสลิปในอัลบั้มกลาง (แกลเลอรี)',
       subtitle: widget.controller.isEnglish
         ? 'Allow accessing main gallery when slips or screenshots are saved in general photo folders'
         : 'อนุญาตให้เข้าถึงรูปภาพในอัลบั้มหลัก สำหรับกรณีที่บันทึกสลิปหรือแคปภาพหน้าจอลงในคลังภาพรวมของเครื่อง',
       value: _mainAlbumAllowed,
       onChanged: (val) => setState(() => _mainAlbumAllowed = val),
       cardColor: cardColor,
       borderColor: borderColor,
       textPrimary: textPrimary,
       textSecondary: textSecondary,
      ),
      const SizedBox(height: 16),

      // Security Notice
      Container(
       padding: const EdgeInsets.all(12),
       decoration: BoxDecoration(
        color: MeowTheme.incomeGreen.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MeowTheme.incomeGreen.withOpacity(0.3)),
       ),
       child: Row(
        children: [
         const Icon(Icons.shield_outlined, color: MeowTheme.incomeGreen, size: 20),
         const SizedBox(width: 10),
         Expanded(
          child: Text(
           widget.controller.isEnglish
             ? ' All financial data and slip images are processed and stored locally on your device only. 100% private and offline.'
             : ' ข้อมูลทางการเงินและรูปสลิปทั้งหมดจะถูกประมวลผลและเก็บไว้ภายในโทรศัพท์ของคุณเท่านั้น ไม่มีการส่งออกภายนอก ปลอดภัย 100%',
           style: const TextStyle(color: MeowTheme.incomeGreen, fontSize: 11, height: 1.3),
          ),
         ),
        ],
       ),
      ),
      const SizedBox(height: 24),

      // Confirm Button
      Container(
       width: double.infinity,
       height: 56,
       decoration: BoxDecoration(
        gradient: MeowTheme.blueButtonGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
         BoxShadow(
          color: MeowTheme.actionBlue.withOpacity(0.4),
          blurRadius: 16,
          offset: const Offset(0, 6),
         ),
        ],
       ),
       child: ElevatedButton(
        style: ElevatedButton.styleFrom(
         backgroundColor: Colors.transparent,
         shadowColor: Colors.transparent,
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        onPressed: _onConfirm,
        child: Text(
         widget.controller.isEnglish ? 'Save & Start Using ' : 'บันทึกสิทธิ์และเริ่มต้นใช้งาน ',
         style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.bold,
         ),
        ),
       ),
      ),
      const SizedBox(height: 20),
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
  required bool value,
  required ValueChanged<bool> onChanged,
  required Color cardColor,
  required Color borderColor,
  required Color textPrimary,
  required Color textSecondary,
 }) {
  return Container(
   padding: const EdgeInsets.all(16),
   decoration: BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: borderColor),
   ),
   child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
     Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
       color: iconColor.withOpacity(0.15),
       borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: iconColor, size: 24),
     ),
     const SizedBox(width: 14),
     Expanded(
      child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
        Text(
         title,
         style: TextStyle(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.bold,
         ),
        ),
        const SizedBox(height: 4),
        Text(
         subtitle,
         style: TextStyle(
          color: textSecondary,
          fontSize: 12,
          height: 1.4,
         ),
        ),
       ],
      ),
     ),
     const SizedBox(width: 8),
     Switch(
      value: value,
      activeColor: MeowTheme.mustardYellow,
      onChanged: onChanged,
     ),
    ],
   ),
  );
 }
}
