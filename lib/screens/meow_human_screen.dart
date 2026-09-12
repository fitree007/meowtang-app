import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../widgets/meow_mascot_widget.dart';
import '../widgets/tactile_button.dart';
import '../services/native_bridge_service.dart';
import 'category_management_screen.dart';
import 'account_management_screen.dart';
import 'permission_onboarding_screen.dart';
import 'keyword_rules_screen.dart';
import 'export_report_screen.dart';
import 'character_customization_screen.dart';
import 'app_guide_screen.dart';
import 'app_features_showcase_screen.dart';
import 'theme_shop_screen.dart';
import 'data_backup_restore_screen.dart';
import 'salary_auto_record_screen.dart';
import '../widgets/custom_photo_avatar_dialog.dart';
import '../utils/format_utils.dart';
import '../widgets/meow_paywall_modal.dart';

class MeowHumanScreen extends StatefulWidget {
 final ExpenseController controller;

 const MeowHumanScreen({super.key, required this.controller});

 @override
 State<MeowHumanScreen> createState() => _MeowHumanScreenState();
}

class _MeowHumanScreenState extends State<MeowHumanScreen> {
 void _showLanguagePicker() {
  HapticFeedback.selectionClick();
  final isDark = widget.controller.isDarkMode;
  final currentLang = widget.controller.appLanguage;

  showModalBottomSheet(
   context: context,
   backgroundColor: Colors.transparent,
   builder: (ctx) => Container(
    decoration: BoxDecoration(
     color: isDark ? MeowTheme.navySurface : Colors.white,
     borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
     border: Border.all(color: isDark ? MeowTheme.borderColor : const Color(0xFFE2E8F0)),
    ),
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
    child: Column(
     mainAxisSize: MainAxisSize.min,
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
      Center(
       child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
         color: Colors.grey.withOpacity(0.4),
         borderRadius: BorderRadius.circular(2),
        ),
       ),
      ),
      const SizedBox(height: 16),
      Row(
       children: [
        const Icon(Icons.language_rounded, color: MeowTheme.actionBlue, size: 22),
        const SizedBox(width: 8),
        Text(
         widget.controller.tr('language_modal_title'),
         style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontSize: 17,
          fontWeight: FontWeight.bold,
         ),
        ),
       ],
      ),
      const SizedBox(height: 16),
      _buildLanguageOption(
       code: 'th',
       flag: '🇹🇭',
       name: widget.controller.tr('lang_th'),
       sub: widget.controller.tr('lang_th_sub'),
       isSelected: currentLang == 'th',
       isDark: isDark,
       onSelect: () async {
        Navigator.pop(ctx);
        await widget.controller.setAppLanguage('th');
       },
      ),
      const SizedBox(height: 10),
      _buildLanguageOption(
       code: 'en',
       flag: '🇬🇧',
       name: widget.controller.tr('lang_en'),
       sub: widget.controller.tr('lang_en_sub'),
       isSelected: currentLang == 'en',
       isDark: isDark,
       onSelect: () async {
        Navigator.pop(ctx);
        await widget.controller.setAppLanguage('en');
       },
      ),
     ],
    ),
   ),
  );
 }

 Widget _buildLanguageOption({
  required String code,
  required String flag,
  required String name,
  required String sub,
  required bool isSelected,
  required bool isDark,
  required VoidCallback onSelect,
 }) {
  return TactileButton(
   onTap: onSelect,
   child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
     color: isSelected
       ? (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF))
       : (isDark ? MeowTheme.navyCard : const Color(0xFFF8FAFC)),
     borderRadius: BorderRadius.circular(16),
     border: Border.all(
      color: isSelected ? MeowTheme.actionBlue : (isDark ? MeowTheme.borderColor : const Color(0xFFE2E8F0)),
      width: isSelected ? 2 : 1,
     ),
    ),
    child: Row(
     children: [
      Text(flag, style: const TextStyle(fontSize: 26)),
      const SizedBox(width: 14),
      Expanded(
       child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Text(
          name,
          style: TextStyle(
           color: isDark ? Colors.white : const Color(0xFF0F172A),
           fontSize: 15,
           fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
         ),
         const SizedBox(height: 2),
         Text(
          sub,
          style: TextStyle(
           color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
           fontSize: 12,
          ),
         ),
        ],
       ),
      ),
      if (isSelected)
       const Icon(Icons.check_circle_rounded, color: MeowTheme.actionBlue, size: 22),
     ],
    ),
   ),
  );
 }

 void _showThemePicker() {
  showModalBottomSheet(
   context: context,
   backgroundColor: widget.controller.isDarkMode ? MeowTheme.navySurface : Colors.white,
   shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
   ),
   builder: (ctx) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
     mainAxisSize: MainAxisSize.min,
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
      Text(
       ' ${widget.controller.tr('theme_picker_title')}',
       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      ListTile(
       leading: const Icon(Icons.dark_mode, color: MeowTheme.mustardYellow),
       title: Text(widget.controller.tr('theme_dark'), style: const TextStyle(fontWeight: FontWeight.bold)),
       trailing: widget.controller.isDarkMode ? const Icon(Icons.check, color: MeowTheme.mustardYellow) : null,
       onTap: () {
        widget.controller.toggleThemeMode(true);
        Navigator.pop(ctx);
       },
      ),
      const Divider(),
      ListTile(
       leading: const Icon(Icons.light_mode, color: MeowTheme.actionBlue),
       title: Text(widget.controller.tr('theme_light'), style: const TextStyle(fontWeight: FontWeight.bold)),
       trailing: !widget.controller.isDarkMode ? const Icon(Icons.check, color: MeowTheme.actionBlue) : null,
       onTap: () {
        widget.controller.toggleThemeMode(false);
        Navigator.pop(ctx);
       },
      ),
      const SizedBox(height: 12),
     ],
    ),
   ),
  );
 }

 @override
 Widget build(BuildContext context) {
  final currentTheme = widget.controller.currentTheme;
  final isDark = widget.controller.isDarkMode;
  final isEn = widget.controller.isEnglish;
  final bgColor = currentTheme.scaffoldBackground;
  final cardColor = currentTheme.cardBackground;
  final borderColor = currentTheme.borderColor;

  return Scaffold(
   backgroundColor: bgColor,
   body: ListView(
    padding: EdgeInsets.zero,
    children: [
     // Dynamic Theme Header
     Container(
      decoration: BoxDecoration(
       gradient: currentTheme.heroGradient,
      ),
      padding: EdgeInsets.only(
       top: MediaQuery.of(context).padding.top + 16,
       left: 20,
       right: 20,
       bottom: 20,
      ),
      child: Row(
       children: [
        Expanded(
         child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Text(
            isEn ? 'Management & Settings' : 'จัดการ & ตั้งค่าระบบ',
            style: const TextStyle(
             color: Colors.white,
             fontSize: 22,
             fontWeight: FontWeight.bold,
            ),
           ),
           const SizedBox(height: 4),
           Text(
            isEn
              ? 'Manage accounts, categories, rules & customize'
              : 'ศูนย์รวมการจัดการบัญชี หมวดหมู่ และปรับแต่ง',
            style: const TextStyle(
             color: Colors.white70,
             fontSize: 13,
             height: 1.3,
            ),
           ),
          ],
         ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            CustomPhotoAvatarDialog.show(
              context,
              widget.controller,
              onSaved: (_) => setState(() {}),
            );
          },
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              MeowMascotWidget(
                size: 78,
                mascotId: widget.controller.selectedMascotId,
                accessory: widget.controller.selectedMascotAccessory,
                customPhotoPath: widget.controller.customAvatarPath,
                isCustomPhoto: widget.controller.isCustomAvatarEnabled,
                withPen: true,
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
              ),
            ],
          ),
        ),
       ],
      ),
     ),

     Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
        // Quick Net Worth Summary Card
        Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
           BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
           ),
          ],
         ),
         child: Row(
          children: [
           MeowMascotWidget(
            size: 44,
            mascotId: widget.controller.selectedMascotId,
            accessory: widget.controller.selectedMascotAccessory,
            isHeadOnly: true,
           ),
           const SizedBox(width: 12),
           Expanded(
            child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
              Text(
               isEn ? 'Total Net Worth' : 'ยอดเงินคงเหลือรวมทั้งหมด',
               style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
               ),
              ),
              const SizedBox(height: 2),
              Text(
               '฿${FormatUtils.formatCurrency(widget.controller.totalNetWorth)}',
               style: const TextStyle(
                color: MeowTheme.incomeGreen,
                fontSize: 20,
                fontWeight: FontWeight.bold,
               ),
              ),
             ],
            ),
           ),
           TactileButton(
            onTap: () {
             Navigator.push(
              context,
              MaterialPageRoute(
               builder: (_) => AccountManagementScreen(controller: widget.controller),
              ),
             );
            },
            child: Container(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
             decoration: BoxDecoration(
              color: MeowTheme.actionBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: MeowTheme.actionBlue.withOpacity(0.3)),
             ),
             child: Text(
              isEn ? 'Manage' : 'จัดการบัญชี',
              style: const TextStyle(
               color: MeowTheme.actionBlue,
               fontSize: 12,
               fontWeight: FontWeight.bold,
              ),
             ),
            ),
           ),
          ],
         ),
        ),

         // VIP Upgrade / Status Banner (Prominent purchase entry)
         if (!widget.controller.isPremium) ...[
           const SizedBox(height: 14),
           InkWell(
             onTap: () {
               MeowPaywallModal.show(
                 context,
                 controller: widget.controller,
                 reason: 'สั่งซื้อแพ็กเกจ VIP พรีเมี่ยม เพื่อปลดล็อคทุกฟีเจอร์แบบไร้ขีดจำกัด 👑',
               );
             },
             borderRadius: BorderRadius.circular(18),
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
               decoration: BoxDecoration(
                 gradient: const LinearGradient(
                   colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                   begin: Alignment.topLeft,
                   end: Alignment.bottomRight,
                 ),
                 borderRadius: BorderRadius.circular(18),
                 border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.45), width: 1.2),
                 boxShadow: [
                   BoxShadow(
                     color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                     blurRadius: 10,
                     offset: const Offset(0, 3),
                   ),
                 ],
               ),
               child: Row(
                 children: [
                   Container(
                     width: 42,
                     height: 42,
                     decoration: BoxDecoration(
                       gradient: const LinearGradient(
                         colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                         begin: Alignment.topLeft,
                         end: Alignment.bottomRight,
                       ),
                       borderRadius: BorderRadius.circular(13),
                     ),
                     child: const Center(
                       child: Text('👑', style: TextStyle(fontSize: 22)),
                     ),
                   ),
                   const SizedBox(width: 14),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Row(
                           children: [
                             Text(
                               isEn ? 'Upgrade to VIP Premium' : 'สั่งซื้อแพ็กเกจพรีเมี่ยม VIP',
                               style: const TextStyle(
                                 color: Colors.white,
                                 fontSize: 14.5,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                             const SizedBox(width: 6),
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                               decoration: BoxDecoration(
                                 color: const Color(0xFFF59E0B),
                                 borderRadius: BorderRadius.circular(6),
                               ),
                               child: const Text(
                                 'HOT ✨',
                                 style: TextStyle(
                                   color: Colors.black,
                                   fontSize: 9.5,
                                   fontWeight: FontWeight.w900,
                                 ),
                               ),
                             ),
                           ],
                         ),
                         const SizedBox(height: 3),
                         Text(
                           isEn
                               ? 'Unlock all features • Unlimited slips • No ads'
                               : 'ปลดล็อคทุกฟีเจอร์ • สลิปไม่จำกัด • ไร้โฆษณาคั่น',
                           style: TextStyle(
                             color: Colors.white.withValues(alpha: 0.8),
                             fontSize: 11.5,
                           ),
                         ),
                       ],
                     ),
                   ),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                     decoration: BoxDecoration(
                       color: const Color(0xFFF59E0B),
                       borderRadius: BorderRadius.circular(10),
                     ),
                     child: Text(
                       isEn ? 'Buy' : 'สั่งซื้อ',
                       style: const TextStyle(
                         color: Colors.black,
                         fontSize: 12.5,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                   ),
                 ],
               ),
             ),
           ),
         ] else ...[
           const SizedBox(height: 14),
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
             decoration: BoxDecoration(
               color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
               borderRadius: BorderRadius.circular(14),
               border: Border.all(
                 color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
               ),
             ),
             child: Row(
               children: [
                 const Text('👑', style: TextStyle(fontSize: 18)),
                 const SizedBox(width: 10),
                 Expanded(
                   child: Text(
                     isEn ? 'Lifetime VIP Member (All Unlocked)' : 'สมาชิก VIP พรีเมี่ยม (ปลดล็อคครบทุกฟีเจอร์)',
                     style: TextStyle(
                       color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                       fontSize: 12.5,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                 ),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                   decoration: BoxDecoration(
                     color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child: Text(
                     isEn ? 'ACTIVE' : 'ใช้งานอยู่',
                     style: TextStyle(
                       color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                       fontSize: 10,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                 ),
               ],
             ),
           ),
         ],
         const SizedBox(height: 20),

        // ==========================================
        // หมวดที่ 1: การเงินและบัญชี (Financial & Accounts)
        // ==========================================
        _buildSectionHeader(
         title: isEn ? 'Financial & Accounts' : 'การเงินและบัญชี',
         icon: Icons.account_balance_wallet_rounded,
         iconColor: const Color(0xFF3B82F6),
         isDark: isDark,
        ),
        _buildGroupContainer(
         isDark: isDark,
         cardColor: cardColor,
         borderColor: borderColor,
         children: [
          _buildMenuItem(
           icon: Icons.account_balance_wallet_rounded,
           iconBgColor: const Color(0xFF3B82F6),
           title: isEn ? 'Accounts & Wallets' : 'จัดการบัญชี & กระเป๋าเงิน',
           trailingBadge: '${widget.controller.accounts.length} ${isEn ? "acc" : "บัญชี"}',
           isDark: isDark,
           onTap: () {
            Navigator.push(
             context,
             MaterialPageRoute(
              builder: (_) => AccountManagementScreen(controller: widget.controller),
             ),
            );
           },
          ),
          const Divider(height: 1),
          _buildMenuItem(
           icon: Icons.grid_view_rounded,
           iconBgColor: const Color(0xFFF59E0B),
           title: isEn ? 'Categories & Icons' : 'จัดการหมวดหมู่รายรับ-รายจ่าย',
           trailingBadge: '${widget.controller.categories.length} ${isEn ? "cats" : "หมวด"}',
           isDark: isDark,
           onTap: () {
            Navigator.push(
             context,
             MaterialPageRoute(
              builder: (_) => CategoryManagementScreen(controller: widget.controller),
             ),
            );
           },
          ),
          const Divider(height: 1),
          _buildMenuItem(
           icon: Icons.alarm_on_rounded,
           iconBgColor: const Color(0xFF10B981),
           title: isEn ? 'Auto-Record Salary' : 'บันทึกเงินเดือนอัตโนมัติ',
           trailingBadge: widget.controller.salaryConfig.isEnabled
               ? (widget.controller.salaryConfig.isLastDayOfMonth
                   ? (isEn ? 'End of month' : 'วันสิ้นเดือน')
                   : (isEn ? 'Day ${widget.controller.salaryConfig.dayOfMonth}' : 'ทุกวันที่ ${widget.controller.salaryConfig.dayOfMonth}'))
               : (isEn ? 'Off' : 'ปิด'),
           badgeColor: widget.controller.salaryConfig.isEnabled ? const Color(0xFF10B981) : null,
           isDark: isDark,
           onTap: () {
            Navigator.push(
             context,
             MaterialPageRoute(
              builder: (_) => SalaryAutoRecordScreen(controller: widget.controller),
             ),
            );
           },
          ),
         ],
        ),
        const SizedBox(height: 20),

        // ==========================================
        // หมวดที่ 2: ระบบอัจฉริยะ & ข้อมูล (AI & Data)
        // ==========================================
        _buildSectionHeader(
         title: isEn ? 'Smart AI & Data' : 'ระบบอัจฉริยะ & ข้อมูล',
         icon: Icons.auto_awesome_rounded,
         iconColor: const Color(0xFFF59E0B),
         isDark: isDark,
        ),
        _buildGroupContainer(
         isDark: isDark,
         cardColor: cardColor,
         borderColor: borderColor,
         children: [
          _buildMenuItem(
           icon: Icons.auto_awesome_rounded,
           iconBgColor: const Color(0xFFF59E0B),
           title: isEn ? 'Slip AI Keyword Rules' : 'กฎคีย์เวิร์ดสลิปอัตโนมัติ',
           isDark: isDark,
           onTap: () {
            Navigator.push(
             context,
             MaterialPageRoute(
              builder: (_) => KeywordRulesScreen(controller: widget.controller),
             ),
            );
           },
          ),
          const Divider(height: 1),
          _buildMenuItem(
           icon: Icons.file_upload_outlined,
           iconBgColor: const Color(0xFF06B6D4),
           title: isEn ? 'Export Report (Excel / CSV)' : 'ส่งออกรายงานบัญชี (Excel / CSV)',
           trailingBadge: widget.controller.isPremium ? 'VIP 👑' : '🔒 VIP',
           badgeColor: widget.controller.isPremium ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
           isDark: isDark,
           onTap: () {
            Navigator.push(
             context,
             MaterialPageRoute(
              builder: (_) => ExportReportScreen(controller: widget.controller),
             ),
            );
           },
          ),
          const Divider(height: 1),
          _buildMenuItem(
           icon: Icons.settings_backup_restore_rounded,
           iconBgColor: const Color(0xFF6366F1),
           title: isEn ? 'Backup & Migrate Data' : 'สำรอง & ย้ายข้อมูลข้ามเครื่อง (ฟรี)',
           trailingBadge: '100% Free 🛡️',
           isDark: isDark,
           onTap: () {
            Navigator.push(
             context,
             MaterialPageRoute(
              builder: (_) => DataBackupRestoreScreen(controller: widget.controller),
             ),
            );
           },
          ),
         ],
        ),
        const SizedBox(height: 20),

        // ==========================================
        // หมวดที่ 3: ปรับแต่งแอพ & รูปลักษณ์ (Customization)
        // ==========================================
        _buildSectionHeader(
         title: isEn ? 'App Customization' : 'ปรับแต่งแอพ & ตัวละคร',
         icon: Icons.palette_outlined,
         iconColor: const Color(0xFFEC4899),
         isDark: isDark,
        ),
        // โหมดสว่าง & โหมดมืด (ชัดเจน ใช้งานง่าย ไม่มินิมอล)
        Container(
         padding: const EdgeInsets.all(12),
         decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
           BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
           ),
          ],
         ),
         child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Row(
            children: [
             Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              size: 18,
              color: isDark ? const Color(0xFF818CF8) : const Color(0xFFF59E0B),
             ),
             const SizedBox(width: 8),
             Text(
              isEn ? 'Appearance Mode' : 'โหมดการแสดงผล (สว่าง / มืด)',
              style: TextStyle(
               fontSize: 13.5,
               fontWeight: FontWeight.bold,
               color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
             ),
            ],
           ),
           const SizedBox(height: 10),
           Row(
            children: [
             // ปุ่มโหมดสว่าง (Light Mode)
             Expanded(
              child: GestureDetector(
               onTap: () {
                HapticFeedback.mediumImpact();
                widget.controller.toggleThemeMode(false);
               },
               child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                 color: !isDark ? const Color(0xFFFFFBEB) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                 borderRadius: BorderRadius.circular(14),
                 border: Border.all(
                  color: !isDark ? const Color(0xFFF59E0B) : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  width: !isDark ? 2.2 : 1.0,
                 ),
                 boxShadow: !isDark
                   ? [
                     BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                     ),
                    ]
                   : null,
                ),
                child: Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                  const Icon(Icons.wb_sunny_rounded, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 6),
                  Text(
                   isEn ? 'Light' : 'โหมดสว่าง ☀️',
                   style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: !isDark ? const Color(0xFFB45309) : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                   ),
                  ),
                  if (!isDark) ...[
                   const SizedBox(width: 4),
                   const Icon(Icons.check_circle_rounded, color: Color(0xFFF59E0B), size: 16),
                  ],
                 ],
                ),
               ),
              ),
             ),
             const SizedBox(width: 10),
             // ปุ่มโหมดมืด (Dark Mode)
             Expanded(
              child: GestureDetector(
               onTap: () {
                HapticFeedback.mediumImpact();
                widget.controller.toggleThemeMode(true);
               },
               child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                 color: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFF1F5F9),
                 borderRadius: BorderRadius.circular(14),
                 border: Border.all(
                  color: isDark ? const Color(0xFF818CF8) : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  width: isDark ? 2.2 : 1.0,
                 ),
                 boxShadow: isDark
                   ? [
                     BoxShadow(
                      color: const Color(0xFF818CF8).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                     ),
                    ]
                   : null,
                ),
                child: Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                  const Icon(Icons.nightlight_round, color: Color(0xFF818CF8), size: 20),
                  const SizedBox(width: 6),
                  Text(
                   isEn ? 'Dark' : 'โหมดมืด 🌙',
                   style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFC7D2FE) : const Color(0xFF475569),
                   ),
                  ),
                  if (isDark) ...[
                   const SizedBox(width: 4),
                   const Icon(Icons.check_circle_rounded, color: Color(0xFF818CF8), size: 16),
                  ],
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
        const SizedBox(height: 12),
        _buildGroupContainer(
         isDark: isDark,
         cardColor: cardColor,
         borderColor: borderColor,
         children: [
          _buildMenuItem(
           icon: Icons.camera_alt_rounded,
           iconBgColor: const Color(0xFF2563EB),
           title: isEn ? 'Change Profile Photo' : 'ใส่รูปตัวเอง / เปลี่ยนรูปโปรไฟล์',
           trailingBadge: widget.controller.isCustomAvatarEnabled ? (isEn ? 'Active' : 'ใช้งานอยู่') : (isEn ? 'Choose' : 'เลือกรูป'),
           isDark: isDark,
           onTap: () {
            CustomPhotoAvatarDialog.show(
              context,
              widget.controller,
              onSaved: (_) => setState(() {}),
            );
           },
          ),
          const Divider(height: 1),
          _buildMenuItem(
           icon: Icons.face_retouching_natural_rounded,
           iconBgColor: const Color(0xFF6366F1),
           title: isEn ? 'Character & Mascot' : 'ตัวละคร & มาสคอตประจำตัว',
           trailingBadge: widget.controller.isCustomAvatarEnabled
               ? (isEn ? 'Custom Photo' : 'รูปถ่าย')
               : MascotCatalog.characters.firstWhere(
                   (m) => m.id == widget.controller.selectedMascotId,
                   orElse: () => MascotCatalog.characters.first,
                 ).name.split('(').first.trim(),
           isDark: isDark,
           onTap: () {
            Navigator.push(
             context,
             MaterialPageRoute(
              builder: (_) => CharacterCustomizationScreen(controller: widget.controller),
             ),
            );
           },
          ),
          const Divider(height: 1),
          _buildMenuItem(
           icon: Icons.palette_outlined,
           iconBgColor: const Color(0xFFEC4899),
           title: isEn ? 'Theme Shop & Palettes' : 'ร้านค้าธีม & พื้นหลังน่ารัก',
           trailingBadge: widget.controller.currentTheme.name,
           isDark: isDark,
           onTap: () {
            Navigator.push(
             context,
             MaterialPageRoute(
              builder: (_) =>            ThemeShopScreen(controller: widget.controller),
              ),
             );
            },
           ),
           const Divider(height: 1),
           _buildMenuItem(
            icon: Icons.language_rounded,
            iconBgColor: const Color(0xFF14B8A6),
            title: isEn ? 'App Language' : 'ภาษาของแอพ (Language)',
            trailingBadge: isEn ? 'English' : 'ภาษาไทย',
            isDark: isDark,
            onTap: _showLanguagePicker,
           ),
          ],
         ),
         const SizedBox(height: 20),

         // ==========================================
         // หมวดที่ 4: ช่วยเหลือ & ความปลอดภัย (Help & System)
         // ==========================================
         _buildSectionHeader(
          title: isEn ? 'Help & Security' : 'ช่วยเหลือ & ความปลอดภัย',
          icon: Icons.help_outline_rounded,
          iconColor: const Color(0xFF10B981),
          isDark: isDark,
         ),
         _buildGroupContainer(
          isDark: isDark,
          cardColor: cardColor,
          borderColor: borderColor,
          children: [
           _buildMenuItem(
            icon: Icons.auto_awesome_rounded,
            iconBgColor: const Color(0xFF3B82F6),
            title: isEn ? 'App Superpowers & Features' : 'สรุปฟีเจอร์ความสุดยอดของแอพ',
            trailingBadge: 'PRO ⚡',
            isDark: isDark,
            onTap: () {
             Navigator.push(
              context,
              MaterialPageRoute(
               builder: (_) => AppFeaturesShowcaseScreen(controller: widget.controller),
              ),
             );
            },
           ),
           const Divider(height: 1),
           _buildMenuItem(
            icon: Icons.menu_book_rounded,
            iconBgColor: const Color(0xFF10B981),
            title: isEn ? 'App User Guide' : 'คู่มือการใช้งานแอพ',
            isDark: isDark,
            onTap: () {
             Navigator.push(
              context,
              MaterialPageRoute(
               builder: (_) => AppGuideScreen(controller: widget.controller),
              ),
             );
            },
           ),
           const Divider(height: 1),
           _buildMenuItem(
            icon: Icons.notifications_active_rounded,
            iconBgColor: const Color(0xFF10B981),
            title: isEn ? 'Auto-Capture Bank Notifications' : 'ดึงรายรับอัตโนมัติจากแจ้งเตือนธนาคาร',
            trailingBadge: 'Auto ⚡',
            isDark: isDark,
            onTap: () async {
             final granted = await NativeBridgeService.isNotificationListenerGranted();
             if (!mounted) return;
             if (granted) {
              ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                content: Text(
                 isEn
                   ? 'Notification Listener is active and capturing bank income!'
                   : 'ระบบดึงรายรับจากแจ้งเตือนธนาคารเปิดใช้งานอยู่แล้ว!',
                ),
                backgroundColor: MeowTheme.incomeGreen,
               ),
              );
             } else {
              showDialog(
               context: context,
               builder: (ctx) => AlertDialog(
                backgroundColor: isDark ? MeowTheme.navySurface : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                 children: [
                  const Icon(Icons.notifications_active_rounded, color: MeowTheme.incomeGreen),
                  const SizedBox(width: 8),
                  Text(
                   isEn ? 'Bank Notification Access' : 'เปิดระบบอ่านแจ้งเตือนเงินเข้า',
                   style: TextStyle(
                    color: isDark ? Colors.white : MeowTheme.textDarkPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                   ),
                  ),
                 ],
                ),
                content: Text(
                 isEn
                   ? 'Allow MeowTang to read bank notifications (K PLUS, SCB EASY, Krungthai, etc.) to automatically record incoming money when you forget.'
                   : 'อนุญาตให้เหมียวตังค์อ่านการแจ้งเตือนจากแอพธนาคาร (เช่น K PLUS, SCB EASY, Krungthai NEXT) เพื่อบันทึกรายรับเข้าให้อัตโนมัติเมื่อคุณรีบจนลืมจด',
                 style: TextStyle(color: isDark ? Colors.white70 : MeowTheme.textDarkSecondary, fontSize: 13),
                ),
                actions: [
                 TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(isEn ? 'Cancel' : 'ยกเลิก', style: const TextStyle(color: Colors.grey)),
                 ),
                 ElevatedButton(
                  style: ElevatedButton.styleFrom(
                   backgroundColor: MeowTheme.incomeGreen,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                   Navigator.pop(ctx);
                   NativeBridgeService.openNotificationListenerSettings();
                  },
                  child: Text(
                   isEn ? 'Open Settings' : 'ไปที่การตั้งค่า',
                   style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                 ),
                ],
               ),
              );
             }
            },
           ),
           const Divider(height: 1),
           _buildMenuItem(
            icon: Icons.security_rounded,
            iconBgColor: const Color(0xFFEF4444),
            title: isEn ? 'Device Permissions' : 'สิทธิ์การเข้าถึงอุปกรณ์',
            isDark: isDark,
            onTap: () {
             Navigator.push(
              context,
              MaterialPageRoute(
               builder: (_) => PermissionOnboardingScreen(
                controller: widget.controller,
                onFinish: () => Navigator.pop(context),
               ),
              ),
             );
            },
           ),
          ],
         ),
         const SizedBox(height: 28),

         // Footer & Service Credit
         Center(
          child: Column(
           children: [
            Text(
             isEn ? 'MeowTang (เหมียวตังค์)' : 'เหมียวตังค์ (MeowTang)',
             style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF334155),
              fontSize: 14,
              fontWeight: FontWeight.bold,
             ),
            ),
            const SizedBox(height: 4),
            Text(
             widget.controller.tr('credit_service'),
             style: const TextStyle(
              color: MeowTheme.mustardYellow,
              fontSize: 13,
              fontWeight: FontWeight.bold,
             ),
            ),
            const SizedBox(height: 4),
               Text(
                isEn ? 'Version ${ExpenseController.appVersion} (Latest Release)' : 'เวอร์ชัน ${ExpenseController.appVersion} (ล่าสุด)',
                style: TextStyle(
                 color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                 fontSize: 11,
                ),
               ),
           const SizedBox(height: 24),
          ],
         ),
        ),
       ],
      ),
     ),
    ],
   ),
  );
 }

 Widget _buildSectionHeader({
  required String title,
  required IconData icon,
  required Color iconColor,
  required bool isDark,
 }) {
  return Padding(
   padding: const EdgeInsets.only(left: 4, bottom: 8),
   child: Row(
    children: [
     Icon(icon, size: 18, color: iconColor),
     const SizedBox(width: 8),
     Text(
      title,
      style: TextStyle(
       color: isDark ? Colors.white : const Color(0xFF0F172A),
       fontSize: 15,
       fontWeight: FontWeight.bold,
      ),
     ),
    ],
   ),
  );
 }

 Widget _buildGroupContainer({
  required bool isDark,
  required Color cardColor,
  required Color borderColor,
  required List<Widget> children,
 }) {
  return Container(
   decoration: BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: borderColor),
    boxShadow: [
     BoxShadow(
      color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
     ),
    ],
   ),
   child: ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: Column(
     children: children,
    ),
   ),
  );
 }

  Widget _buildMenuItem({
   required IconData icon,
   required Color iconBgColor,
   required String title,
   String? subtitle,
   String? trailingBadge,
   Color? badgeColor,
   required bool isDark,
   required VoidCallback onTap,
  }) {
   final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

   return Material(
    color: Colors.transparent,
    child: InkWell(
     onTap: () {
      HapticFeedback.selectionClick();
      onTap();
     },
     child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
       children: [
        Container(
         width: 38,
         height: 38,
         decoration: BoxDecoration(
          color: iconBgColor.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
         ),
         child: Icon(icon, color: iconBgColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
         child: Text(
          title,
          style: TextStyle(
           color: textColor,
           fontSize: 14.5,
           fontWeight: FontWeight.w600,
           letterSpacing: -0.2,
          ),
         ),
        ),
        if (trailingBadge != null) ...[
         const SizedBox(width: 8),
         Container(
          constraints: const BoxConstraints(maxWidth: 130),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
           color: (badgeColor ?? MeowTheme.actionBlue).withValues(alpha: 0.12),
           borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
           trailingBadge,
           maxLines: 1,
           overflow: TextOverflow.ellipsis,
           style: TextStyle(
            color: badgeColor ?? MeowTheme.actionBlue,
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
           ),
          ),
         ),
        ],
        const SizedBox(width: 6),
        Icon(
         Icons.chevron_right_rounded,
         color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
         size: 20,
        ),
       ],
      ),
     ),
    ),
   );
  }
}
