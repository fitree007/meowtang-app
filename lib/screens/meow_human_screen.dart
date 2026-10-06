import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../widgets/meow_mascot_widget.dart';
import '../widgets/tactile_button.dart';
import '../services/native_bridge_service.dart';
import '../services/category_matcher_service.dart';
import '../models/account_item.dart';
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
import '../services/ad_service.dart';

class MeowHumanScreen extends StatefulWidget {
 final ExpenseController controller;

 const MeowHumanScreen({super.key, required this.controller});

 @override
 State<MeowHumanScreen> createState() => _MeowHumanScreenState();
}

class _MeowHumanScreenState extends State<MeowHumanScreen> {
  bool _isHeaderCollapsed = false;

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
   body: NotificationListener<ScrollNotification>(
    onNotification: (notification) {
     if (notification.metrics.axis == Axis.vertical) {
      final isScrolled = notification.metrics.pixels > 20.0;
      if (isScrolled != _isHeaderCollapsed) {
       setState(() {
        _isHeaderCollapsed = isScrolled;
       });
      }
     }
     return false;
    },
    child: Column(
     children: [
      // Dynamic Theme Collapsible Pinned Header (Status bar area)
      AnimatedContainer(
       duration: const Duration(milliseconds: 220),
       curve: Curves.easeInOut,
       width: double.infinity,
       decoration: BoxDecoration(
        gradient: currentTheme.heroGradient,
        boxShadow: [
         BoxShadow(
          color: currentTheme.primaryColor.withValues(alpha: isDark ? 0.3 : 0.15),
          blurRadius: 16,
          offset: const Offset(0, 4),
         ),
        ],
       ),
       padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + (_isHeaderCollapsed ? 11 : 14),
        left: 18,
        right: 18,
        bottom: _isHeaderCollapsed ? 8 : 12,
       ),
       child: Row(
        children: [
         Expanded(
          child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           mainAxisSize: MainAxisSize.min,
           children: [
            Text(
             _isHeaderCollapsed
                 ? (isEn ? 'Menu' : 'เมนู')
                 : (isEn ? 'Menu' : 'เมนู'),
             style: TextStyle(
              color: currentTheme.heroTextColor(isDark),
               fontSize: _isHeaderCollapsed ? 16.5 : 18,
              fontWeight: FontWeight.bold,
             ),
            ),
            AnimatedCrossFade(
             duration: const Duration(milliseconds: 200),
             crossFadeState: _isHeaderCollapsed
                 ? CrossFadeState.showSecond
                 : CrossFadeState.showFirst,
             firstChild: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
               widget.controller.isPremium
                 ? (isEn ? '👑 VIP member' : '👑 สมาชิก VIP')
                 : (isEn ? 'Free plan • settings & management' : 'ผู้ใช้ฟรี • ตั้งค่าและจัดการแอป'),
               style: TextStyle(
                 color: currentTheme.heroTextMutedColor(isDark),
                 fontSize: 11,
               ),
              ),
             ),
             secondChild: const SizedBox.shrink(),
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
                 size: _isHeaderCollapsed ? 38 : 52,
                 mascotId: widget.controller.selectedMascotId,
                 accessory: widget.controller.selectedMascotAccessory,
                 customPhotoPath: widget.controller.customAvatarPath,
                 isCustomPhoto: widget.controller.isCustomAvatarEnabled,
                 withPen: true,
               ),
               if (!_isHeaderCollapsed)
                 Container(
                   padding: const EdgeInsets.all(4),
                   decoration: BoxDecoration(
                     color: const Color(0xFF2563EB),
                     shape: BoxShape.circle,
                     border: Border.all(color: Colors.white, width: 1.5),
                     boxShadow: [
                       BoxShadow(
                         color: Colors.black.withValues(alpha: 0.3),
                         blurRadius: 4,
                         offset: const Offset(0, 1),
                       ),
                     ],
                   ),
                   child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 10),
                 ),
             ],
           ),
         ),
        ],
       ),
      ),

      // Scrollable Body
      Expanded(
       child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
         _buildNetWorthCard(isDark: isDark, isEn: isEn, cardColor: cardColor, borderColor: borderColor),
         const SizedBox(height: 14),
         if (!widget.controller.isPremium)
          _buildFreeQuotaCard(isDark: isDark, isEn: isEn, cardColor: cardColor, borderColor: borderColor)
         else
          _buildVipStatusRow(isDark: isDark, isEn: isEn),
         const SizedBox(height: 20),

         // 1. Automations sit together: bank notifications, salary, keyword rules
         _buildSectionHeader(title: isEn ? 'Auto-record' : 'บันทึกอัตโนมัติ', isDark: isDark),
         _buildGroupContainer(
          isDark: isDark,
          cardColor: cardColor,
          borderColor: borderColor,
          children: [
           _buildMenuItem(
            icon: Icons.notifications_active_rounded,
            iconBgColor: const Color(0xFF10B981),
            title: isEn ? 'Income from bank notifications' : 'ดึงรายรับจากแจ้งเตือนธนาคาร',
            subtitle: _notifGranted == true
                ? (isEn ? 'On • K PLUS, SCB EASY, Krungthai NEXT' : 'เปิดอยู่ • K PLUS, SCB EASY, Krungthai NEXT')
                : (isEn ? 'Off • tap to allow reading bank notifications' : 'ปิดอยู่ • แตะเพื่ออนุญาตให้อ่านแจ้งเตือนธนาคาร'),
            trailingBadge: _notifGranted == null ? null : (_notifGranted! ? (isEn ? 'On' : 'เปิดอยู่') : (isEn ? 'Off' : 'ปิดอยู่')),
            badgeColor: _notifGranted == true ? const Color(0xFF059669) : const Color(0xFF64748B),
            isDark: isDark,
            onTap: () => _openBankNotificationAccess(isDark: isDark, isEn: isEn),
           ),
           _divider(borderColor),
           _buildMenuItem(
            icon: Icons.alarm_on_rounded,
            iconBgColor: const Color(0xFF3B82F6),
            title: isEn ? 'Auto-record salary' : 'บันทึกเงินเดือนอัตโนมัติ',
            subtitle: _salarySubtitle(isEn),
            trailingBadge: widget.controller.salaryConfig.isEnabled ? (isEn ? 'On' : 'เปิดอยู่') : null,
            badgeColor: const Color(0xFF059669),
            isDark: isDark,
            onTap: () => _push(SalaryAutoRecordScreen(controller: widget.controller)),
           ),
           _divider(borderColor),
           _buildMenuItem(
            icon: Icons.auto_awesome_rounded,
            iconBgColor: const Color(0xFFF59E0B),
            title: isEn ? 'Keyword category rules' : 'กฎคีย์เวิร์ดจัดหมวดอัตโนมัติ',
            subtitle: isEn
                ? 'Yours: ${widget.controller.storage.getKeywordRules().length} • Built-in: ${CategoryMatcherService.defaultRules.length}'
                : 'กฎของคุณ ${widget.controller.storage.getKeywordRules().length} ข้อ • มาตรฐาน ${CategoryMatcherService.defaultRules.length} ข้อ',
            isDark: isDark,
            onTap: () => _push(KeywordRulesScreen(controller: widget.controller)),
           ),
          ],
         ),
         const SizedBox(height: 20),

         // 2. Accounts & categories
         _buildSectionHeader(title: isEn ? 'Accounts & categories' : 'บัญชี & หมวดหมู่', isDark: isDark),
         _buildGroupContainer(
          isDark: isDark,
          cardColor: cardColor,
          borderColor: borderColor,
          children: [
           _buildMenuItem(
            icon: Icons.account_balance_wallet_rounded,
            iconBgColor: const Color(0xFF3B82F6),
            title: isEn ? 'Accounts & wallets' : 'บัญชี & กระเป๋าเงิน',
            subtitle: _accountsSubtitle(isEn),
            isDark: isDark,
            onTap: () => _push(AccountManagementScreen(controller: widget.controller)),
           ),
           _divider(borderColor),
           _buildMenuItem(
            icon: Icons.grid_view_rounded,
            iconBgColor: const Color(0xFFF59E0B),
            title: isEn ? 'Income & expense categories' : 'หมวดหมู่รายรับ-รายจ่าย',
            subtitle: isEn
                ? 'Expense ${widget.controller.expenseCategories.length} • Income ${widget.controller.incomeCategories.length}'
                : 'รายจ่าย ${widget.controller.expenseCategories.length} หมวด • รายรับ ${widget.controller.incomeCategories.length} หมวด',
            isDark: isDark,
            onTap: () => _push(CategoryManagementScreen(controller: widget.controller)),
           ),
          ],
         ),
         const SizedBox(height: 20),

         // 3. Data & reports
         _buildSectionHeader(title: isEn ? 'Data & reports' : 'ข้อมูล & รายงาน', isDark: isDark),
         _buildGroupContainer(
          isDark: isDark,
          cardColor: cardColor,
          borderColor: borderColor,
          children: [
           _buildMenuItem(
            icon: Icons.file_upload_outlined,
            iconBgColor: const Color(0xFF06B6D4),
            title: isEn ? 'Export report (Excel / PDF)' : 'ส่งออกรายงาน Excel / PDF',
            subtitle: isEn ? 'Pick a date range • saved to your phone' : 'เลือกช่วงเวลา • บันทึกลงเครื่อง',
            trailingBadge: widget.controller.isPremium ? null : '👑 VIP',
            badgeColor: const Color(0xFFB45309),
            isDark: isDark,
            onTap: () => _push(ExportReportScreen(controller: widget.controller)),
           ),
           _divider(borderColor),
           _buildMenuItem(
            icon: Icons.settings_backup_restore_rounded,
            iconBgColor: const Color(0xFF6366F1),
            title: isEn ? 'Backup & move to a new phone' : 'สำรอง & ย้ายข้อมูลข้ามเครื่อง',
            subtitle: isEn ? 'Backup file or QR code over Wi-Fi • free' : 'ไฟล์สำรอง หรือ QR Code ผ่าน Wi-Fi • ฟรี',
            isDark: isDark,
            onTap: () => _push(DataBackupRestoreScreen(controller: widget.controller)),
           ),
          ],
         ),
         const SizedBox(height: 20),

         // 4. Customise
         _buildSectionHeader(title: isEn ? 'Customise' : 'ปรับแต่งแอป', isDark: isDark),
         _buildGroupContainer(
          isDark: isDark,
          cardColor: cardColor,
          borderColor: borderColor,
          children: [
           _buildAppearanceRow(isDark: isDark, isEn: isEn),
           _divider(borderColor),
           _buildMenuItem(
            icon: Icons.face_retouching_natural_rounded,
            iconBgColor: const Color(0xFF6366F1),
            title: isEn ? 'Mascot & accessories' : 'ตัวละคร & มาสคอต',
            subtitle: widget.controller.isCustomAvatarEnabled
                ? (isEn ? 'Using your own photo' : 'ใช้รูปของคุณอยู่')
                : (isEn ? 'Change your companion and accessory' : 'เปลี่ยนตัวละครและอุปกรณ์คู่กาย'),
            isDark: isDark,
            onTap: () => _push(CharacterCustomizationScreen(controller: widget.controller)),
           ),
           _divider(borderColor),
           _buildMenuItem(
            icon: Icons.palette_rounded,
            iconBgColor: const Color(0xFFEC4899),
            title: isEn ? 'Theme shop' : 'ร้านค้าธีม',
            subtitle: isEn
                ? 'In use: ${widget.controller.currentTheme.nameEn}'
                : 'ใช้อยู่: ${widget.controller.currentTheme.name}',
            isDark: isDark,
            onTap: () => _push(ThemeShopScreen(controller: widget.controller)),
           ),
           _divider(borderColor),
           _buildMenuItem(
            icon: Icons.language_rounded,
            iconBgColor: const Color(0xFF14B8A6),
            title: isEn ? 'Language' : 'ภาษา',
            subtitle: isEn ? 'App language' : 'ภาษาที่ใช้ในแอป',
            trailingText: widget.controller.appLanguage == 'en' ? '🇬🇧 English' : '🇹🇭 ไทย',
            isDark: isDark,
            onTap: _showLanguagePicker,
           ),
          ],
         ),
         const SizedBox(height: 20),

         // 5. Help & privacy
         _buildSectionHeader(title: isEn ? 'Help & privacy' : 'ช่วยเหลือ & ความเป็นส่วนตัว', isDark: isDark),
         _buildGroupContainer(
          isDark: isDark,
          cardColor: cardColor,
          borderColor: borderColor,
          children: [
           _buildMenuItem(
            icon: Icons.menu_book_rounded,
            iconBgColor: const Color(0xFF10B981),
            title: isEn ? 'Guide & features' : 'คู่มือ & ฟีเจอร์เด่น',
            subtitle: isEn ? 'Step-by-step how-tos and everything the app can do' : 'วิธีใช้ทีละขั้น และดูว่าแอปทำอะไรได้บ้าง',
            isDark: isDark,
            onTap: () => _showGuideChooser(isDark: isDark, isEn: isEn),
           ),
           _divider(borderColor),
           _buildMenuItem(
            icon: Icons.security_rounded,
            iconBgColor: const Color(0xFFEF4444),
            title: isEn ? 'Device permissions' : 'สิทธิ์การเข้าถึงอุปกรณ์',
            subtitle: isEn ? 'Photos • Camera • Microphone • Notifications' : 'รูปภาพ • กล้อง • ไมโครโฟน • แจ้งเตือน',
            trailingBadge: _permGranted == null ? null : (isEn ? 'Allowed $_permGranted/4' : 'อนุญาต $_permGranted/4'),
            badgeColor: _permGranted == 4 ? const Color(0xFF059669) : const Color(0xFFB45309),
            isDark: isDark,
            onTap: () => _push(PermissionOnboardingScreen(
             controller: widget.controller,
             fromMenu: true,
             onFinish: () => Navigator.pop(context),
            )),
           ),
           _divider(borderColor),
           _buildMenuItem(
            icon: Icons.mail_outline_rounded,
            iconBgColor: const Color(0xFF64748B),
            title: isEn ? 'Contact us' : 'ติดต่อทีมงาน',
            subtitle: _contactEmail,
            trailingText: isEn ? 'Copy' : 'คัดลอก',
            isDark: isDark,
            onTap: () {
             Clipboard.setData(const ClipboardData(text: _contactEmail));
             _snack(isEn ? 'Email copied' : 'คัดลอกอีเมลแล้ว');
            },
           ),
          ],
         ),
         const SizedBox(height: 28),

         // Footer
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
             isEn ? 'Version ${ExpenseController.appVersion}' : 'เวอร์ชัน ${ExpenseController.appVersion}',
             style: TextStyle(
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              fontSize: 12,
             ),
            ),
           ],
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

 static const _contactEmail = 'fitree.work24725@gmail.com';

 // ---------------------------------------------------------------------------
 // Status loading and navigation
 // ---------------------------------------------------------------------------
 bool? _notifGranted;
 int? _permGranted;

 @override
 void initState() {
  super.initState();
  _refreshStatus();
 }

 Future<void> _refreshStatus() async {
  final notif = await NativeBridgeService.isNotificationListenerGranted();
  final perms = await NativeBridgeService.checkAppPermissions();
  if (!mounted) return;
  const keys = ['storage', 'audio', 'notification', 'camera'];
  final known = keys.where((k) => perms[k] is bool).toList();
  setState(() {
   _notifGranted = notif;
   _permGranted = known.length == keys.length ? known.where((k) => perms[k] == true).length : null;
  });
 }

 Future<void> _push(Widget screen) async {
  await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  if (mounted) _refreshStatus();
 }

 void _snack(String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
   content: Text(msg),
   behavior: SnackBarBehavior.floating,
   backgroundColor: MeowTheme.incomeGreen,
  ));
 }

 String _salarySubtitle(bool isEn) {
  final c = widget.controller.salaryConfig;
  if (!c.isEnabled) return isEn ? 'Off • records your salary once a month' : 'ปิดอยู่ • ให้น้องแมวบันทึกเงินเดือนให้ทุกเดือน';
  final day = c.isLastDayOfMonth ? (isEn ? 'month end' : 'สิ้นเดือน') : (isEn ? 'day ${c.dayOfMonth}' : 'วันที่ ${c.dayOfMonth}');
  final amount = '฿${FormatUtils.formatCurrency(c.amount)}';
  return isEn ? 'Every $day • $amount' : 'ทุก$day • $amount';
 }

 String _accountsSubtitle(bool isEn) {
  final a = widget.controller.accounts;
  final bank = a.where((x) => x.type == AccountType.bank).length;
  final wallet = a.where((x) => x.type == AccountType.eWallet).length;
  final cash = a.where((x) => x.type == AccountType.cash).length;
  final parts = <String>[
   if (bank > 0) isEn ? 'Bank $bank' : 'ธนาคาร $bank',
   if (wallet > 0) 'e-Wallet $wallet',
   if (cash > 0) isEn ? 'Cash $cash' : 'เงินสด $cash',
  ];
  return parts.isEmpty ? (isEn ? 'No accounts yet' : 'ยังไม่มีบัญชี') : parts.join(' • ');
 }

 Future<void> _openBankNotificationAccess({required bool isDark, required bool isEn}) async {
  final granted = await NativeBridgeService.isNotificationListenerGranted();
  if (!mounted) return;
  setState(() => _notifGranted = granted);
  showDialog(
   context: context,
   builder: (ctx) => AlertDialog(
    backgroundColor: isDark ? MeowTheme.navySurface : Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: Text(
     granted
         ? (isEn ? 'Bank notifications: on' : 'ดึงรายรับจากแจ้งเตือน: เปิดอยู่')
         : (isEn ? 'Bank Notification Access' : 'เปิดระบบอ่านแจ้งเตือนเงินเข้า'),
     style: TextStyle(color: isDark ? Colors.white : MeowTheme.textDarkPrimary, fontSize: 16, fontWeight: FontWeight.bold),
    ),
    content: Text(
     granted
         ? (isEn
             ? 'MeowTang records incoming money from bank app notifications. To turn this off, switch MeowTang off in Notification access settings.'
             : 'เหมียวตังค์กำลังบันทึกรายรับจากแจ้งเตือนแอปธนาคารให้อัตโนมัติ ถ้าต้องการปิด ให้ปิดเหมียวตังค์ในหน้าการตั้งค่า "การเข้าถึงการแจ้งเตือน"')
         : (isEn
             ? 'Allow MeowTang to read bank notifications (K PLUS, SCB EASY, Krungthai, etc.) to automatically record incoming money when you forget.'
             : 'อนุญาตให้เหมียวตังค์อ่านการแจ้งเตือนจากแอพธนาคาร (เช่น K PLUS, SCB EASY, Krungthai NEXT) เพื่อบันทึกรายรับเข้าให้อัตโนมัติเมื่อคุณรีบจนลืมจด'),
     style: TextStyle(color: isDark ? Colors.white70 : MeowTheme.textDarkSecondary, fontSize: 13, height: 1.45),
    ),
    actions: [
     TextButton(
      onPressed: () => Navigator.pop(ctx),
      child: Text(granted ? (isEn ? 'Close' : 'ปิด') : (isEn ? 'Cancel' : 'ยกเลิก'), style: const TextStyle(color: Colors.grey)),
     ),
     ElevatedButton(
      style: ElevatedButton.styleFrom(
       backgroundColor: granted ? const Color(0xFF64748B) : MeowTheme.incomeGreen,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () async {
       Navigator.pop(ctx);
       await NativeBridgeService.openNotificationListenerSettings();
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

 void _showGuideChooser({required bool isDark, required bool isEn}) {
  HapticFeedback.selectionClick();
  final card = isDark ? MeowTheme.navySurface : Colors.white;
  final text = isDark ? Colors.white : const Color(0xFF0F172A);
  final sub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Widget option(IconData icon, Color color, String title, String desc, Widget screen) => ListTile(
       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
       leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color),
       ),
       title: Text(title, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 14.5)),
       subtitle: Text(desc, style: TextStyle(color: sub, fontSize: 12)),
       trailing: Icon(Icons.chevron_right_rounded, color: sub),
       onTap: () {
        Navigator.pop(context);
        _push(screen);
       },
      );
  showModalBottomSheet(
   context: context,
   backgroundColor: card,
   shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
   builder: (_) => SafeArea(
    child: Padding(
     padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
     child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
       Container(width: 40, height: 4, decoration: BoxDecoration(color: sub.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
       const SizedBox(height: 12),
       option(Icons.menu_book_rounded, const Color(0xFF10B981), isEn ? 'How to use, step by step' : 'วิธีใช้งานทีละขั้น',
        isEn ? '12 short topics with tips' : '12 หัวข้อ พร้อมเคล็ดลับ', AppGuideScreen(controller: widget.controller)),
       option(Icons.auto_awesome_rounded, const Color(0xFF3B82F6), isEn ? 'All features' : 'ฟีเจอร์ทั้งหมดของแอป',
        isEn ? 'See everything MeowTang can do' : 'ดูภาพรวมว่าเหมียวตังค์ทำอะไรได้บ้าง',
        AppFeaturesShowcaseScreen(controller: widget.controller, isFromMenu: true)),
      ],
     ),
    ),
   ),
  );
 }

 // ---------------------------------------------------------------------------
 // Cards
 // ---------------------------------------------------------------------------
 Widget _buildNetWorthCard({required bool isDark, required bool isEn, required Color cardColor, required Color borderColor}) {
  final count = widget.controller.accounts.length;
  return Material(
   color: cardColor,
   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: borderColor)),
   clipBehavior: Clip.antiAlias,
   child: InkWell(
    onTap: () {
     HapticFeedback.selectionClick();
     _push(AccountManagementScreen(controller: widget.controller));
    },
    child: Padding(
     padding: const EdgeInsets.all(16),
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
           isEn ? 'Total across all accounts' : 'ยอดเงินคงเหลือรวมทุกบัญชี',
           style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 2),
          FittedBox(
           fit: BoxFit.scaleDown,
           alignment: Alignment.centerLeft,
           child: Text(
            '฿${FormatUtils.formatCurrency(widget.controller.totalNetWorth)}',
            style: const TextStyle(color: MeowTheme.incomeGreen, fontSize: 21, fontWeight: FontWeight.bold),
           ),
          ),
         ],
        ),
       ),
       Text(
        isEn ? '$count accounts' : '$count บัญชี',
        style: TextStyle(color: widget.controller.currentTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.w600),
       ),
       Icon(Icons.chevron_right_rounded, color: widget.controller.currentTheme.primaryColor),
      ],
     ),
    ),
   ),
  );
 }

 /// Free users: slip quota, watch-an-ad and upgrade in one card.
 Widget _buildFreeQuotaCard({required bool isDark, required bool isEn, required Color cardColor, required Color borderColor}) {
  final c = widget.controller;
  final used = c.currentMonthSlipCount;
  final max = c.maxFreeSlipsPerMonth;
  final adsLeft = (c.maxMonthlyRewardedAds - c.currentMonthAdWatchesCount).clamp(0, c.maxMonthlyRewardedAds);
  final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
  return Container(
   padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
       Expanded(
        child: Text(
         isEn ? '📊 Free slips this month' : '📊 สลิปฟรีเดือนนี้',
         style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textColor),
        ),
       ),
       Text(
        '$used / $max ${isEn ? "slips" : "สลิป"}',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
       ),
      ],
     ),
     const SizedBox(height: 10),
     ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: LinearProgressIndicator(
       value: max > 0 ? (used / max).clamp(0.0, 1.0) : 0.0,
       backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
       valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
       minHeight: 8,
      ),
     ),
     const SizedBox(height: 12),
     Row(
      children: [
       Expanded(
        child: SizedBox(
         height: 44,
         child: ElevatedButton(
          onPressed: c.canWatchRewardedAd ? () => _watchAd(isEn) : null,
          style: ElevatedButton.styleFrom(
           backgroundColor: const Color(0xFF10B981),
           foregroundColor: Colors.white,
           elevation: 0,
           padding: const EdgeInsets.symmetric(horizontal: 8),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: FittedBox(
           child: Text(
            c.canWatchRewardedAd
                ? (isEn ? '🎬 Watch ad +2 slips' : '🎬 ดูโฆษณา +2 สลิป')
                : (isEn ? 'Ads used up this month' : 'ดูครบแล้วเดือนนี้'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
           ),
          ),
         ),
        ),
       ),
       const SizedBox(width: 8),
       Expanded(
        child: SizedBox(
         height: 44,
         child: ElevatedButton(
          onPressed: () => MeowPaywallModal.show(
           context,
           controller: c,
           reason: 'สั่งซื้อแพ็กเกจ VIP พรีเมี่ยม เพื่อปลดล็อคทุกฟีเจอร์แบบไร้ขีดจำกัด 👑',
          ),
          style: ElevatedButton.styleFrom(
           backgroundColor: const Color(0xFF1E293B),
           foregroundColor: const Color(0xFFFCD34D),
           elevation: 0,
           padding: const EdgeInsets.symmetric(horizontal: 8),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: FittedBox(
           child: Text(isEn ? '👑 Upgrade to VIP' : '👑 อัปเกรด VIP', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
         ),
        ),
       ),
      ],
     ),
     const SizedBox(height: 8),
     Text(
      isEn
          ? 'Ad watches left this month: $adsLeft/${c.maxMonthlyRewardedAds} • VIP: unlimited slips, no ads'
          : 'ดูโฆษณาได้อีก $adsLeft/${c.maxMonthlyRewardedAds} ครั้งเดือนนี้ • VIP สลิปไม่จำกัด ไม่มีโฆษณา',
      style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
     ),
    ],
   ),
  );
 }

 Future<void> _watchAd(bool isEn) async {
  HapticFeedback.mediumImpact();
  await AdMobService.instance.showRewardedAd(
   onUserEarnedReward: () async {
    await widget.controller.watchRewardedAdForBonusSlips();
    if (mounted) {
     setState(() {});
     _snack(isEn ? 'Reward earned! +2 slips added! 🎬✨' : 'ยินดีด้วย! คุณได้รับสิทธิ์เพิ่ม +2 สลิปแล้ว 🎬✨');
    }
   },
  );
 }

 Widget _buildVipStatusRow({required bool isDark, required bool isEn}) {
  return Container(
   padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
   decoration: BoxDecoration(
    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
   ),
   child: Row(
    children: [
     const Text('👑', style: TextStyle(fontSize: 18)),
     const SizedBox(width: 10),
     Expanded(
      child: Text(
       isEn ? 'VIP member • unlimited slips • no ads' : 'สมาชิก VIP • สลิปไม่จำกัด • ไม่มีโฆษณา',
       style: TextStyle(
        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
        fontSize: 13,
        fontWeight: FontWeight.bold,
       ),
      ),
     ),
     // Developer-only shortcut to test the free tier; never shown in release builds.
     if (kDebugMode)
      TextButton(
       onPressed: () async {
        await widget.controller.resetToFreeMode();
        if (mounted) _snack('🔄 สลับเข้าสู่โหมดผู้ใช้ฟรี (ทดสอบ)');
       },
       child: const Text('ทดสอบโหมดฟรี', style: TextStyle(fontSize: 12)),
      ),
    ],
   ),
  );
 }

 Widget _buildAppearanceRow({required bool isDark, required bool isEn}) {
  final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
  Widget option(bool dark, String label) {
   final selected = isDark == dark;
   return Expanded(
    child: Material(
     color: selected ? (isDark ? const Color(0xFF334155) : Colors.white) : Colors.transparent,
     borderRadius: BorderRadius.circular(10),
     elevation: selected ? 1 : 0,
     child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
       HapticFeedback.mediumImpact();
       widget.controller.toggleThemeMode(dark);
      },
      child: SizedBox(
       height: 40,
       child: Center(
        child: Text(
         label,
         style: TextStyle(
          color: selected ? textColor : (isDark ? Colors.white54 : const Color(0xFF64748B)),
          fontSize: 13,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
         ),
        ),
       ),
      ),
     ),
    ),
   );
  }

  return Padding(
   padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
   child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
     Row(
      children: [
       Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
         color: (isDark ? const Color(0xFF818CF8) : const Color(0xFFF59E0B)).withValues(alpha: 0.14),
         borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
         size: 20, color: isDark ? const Color(0xFF818CF8) : const Color(0xFFF59E0B)),
       ),
       const SizedBox(width: 12),
       Text(isEn ? 'Appearance' : 'โหมดการแสดงผล',
        style: TextStyle(color: textColor, fontSize: 14.5, fontWeight: FontWeight.w600)),
      ],
     ),
     const SizedBox(height: 10),
     Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
       color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F3F8),
       borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
       children: [
        option(false, isEn ? '☀️ Light' : '☀️ สว่าง'),
        const SizedBox(width: 4),
        option(true, isEn ? '🌙 Dark' : '🌙 มืด'),
       ],
      ),
     ),
    ],
   ),
  );
 }

 Widget _divider(Color color) => Divider(height: 1, thickness: 1, indent: 64, color: color);

 Widget _buildSectionHeader({required String title, required bool isDark}) {
  return Padding(
   padding: const EdgeInsets.only(left: 4, bottom: 8),
   child: Text(
    title,
    style: TextStyle(
     color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
     fontSize: 13,
     fontWeight: FontWeight.bold,
     letterSpacing: 0.2,
    ),
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
    String? trailingText,
    required bool isDark,
    required VoidCallback onTap,
   }) {
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Material(
     color: Colors.transparent,
     child: InkWell(
      onTap: () {
       HapticFeedback.selectionClick();
       onTap();
      },
      child: ConstrainedBox(
       constraints: const BoxConstraints(minHeight: 64),
       child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
         children: [
          Container(
           width: 38,
           height: 38,
           decoration: BoxDecoration(
            color: iconBgColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
           ),
           child: Icon(icon, color: iconBgColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
           child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
             Text(
              title,
              style: TextStyle(color: textColor, fontSize: 14.5, fontWeight: FontWeight.w600),
             ),
             if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
               subtitle,
               maxLines: 2,
               overflow: TextOverflow.ellipsis,
               style: TextStyle(color: subColor, fontSize: 12, height: 1.35),
              ),
             ],
            ],
           ),
          ),
          if (trailingBadge != null) ...[
           const SizedBox(width: 8),
           Container(
            constraints: const BoxConstraints(maxWidth: 120),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
             color: (badgeColor ?? MeowTheme.actionBlue).withValues(alpha: 0.12),
             borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
             trailingBadge,
             maxLines: 1,
             overflow: TextOverflow.ellipsis,
             style: TextStyle(color: badgeColor ?? MeowTheme.actionBlue, fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
           ),
          ],
          if (trailingText != null) ...[
           const SizedBox(width: 8),
           Text(trailingText, style: TextStyle(color: subColor, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(width: 4),
          Icon(
           Icons.chevron_right_rounded,
           color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
           size: 20,
          ),
         ],
        ),
       ),
      ),
     ),
    );
   }
}
