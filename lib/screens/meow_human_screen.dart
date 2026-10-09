import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../services/native_bridge_service.dart';
import '../services/category_matcher_service.dart';
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
import '../widgets/meow_page_header.dart';
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

  void _showLanguagePicker() {
  HapticFeedback.selectionClick();
  final c = _MenuColors.of(widget.controller);
  var pending = widget.controller.appLanguage == 'en' ? 'en' : 'th';

  showModalBottomSheet(
   context: context,
   backgroundColor: c.card,
   isScrollControlled: true,
   shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
   builder: (ctx) => StatefulBuilder(
    builder: (ctx, setSheet) {
     final th = pending == 'th';
     return SafeArea(
      child: SingleChildScrollView(
       padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
       child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
         Center(
          child: Container(width: 36, height: 4, decoration: BoxDecoration(color: c.faint, borderRadius: BorderRadius.circular(2))),
         ),
         const SizedBox(height: 12),
         Text(th ? 'เลือกภาษา' : 'Choose language', style: TextStyle(color: c.text, fontSize: 17, fontWeight: FontWeight.w700)),
         Text(th ? 'Choose language' : 'เลือกภาษา', style: TextStyle(color: c.sub, fontSize: 12.5)),
         const SizedBox(height: 12),
         Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: c.line)),
          clipBehavior: Clip.antiAlias,
          child: Material(
           color: Colors.transparent,
           child: Column(
            children: [
             _buildLanguageOption(
              code: 'th',
              flag: '🇹🇭',
              name: 'ภาษาไทย',
              sub: 'Thai',
              isSelected: th,
              isDark: widget.controller.isDarkMode,
              onSelect: () => setSheet(() => pending = 'th'),
             ),
             _buildLanguageOption(
              code: 'en',
              flag: '🇬🇧',
              name: 'English',
              sub: 'ภาษาอังกฤษ',
              isSelected: !th,
              isDark: widget.controller.isDarkMode,
              onSelect: () => setSheet(() => pending = 'en'),
             ),
            ],
           ),
          ),
         ),
         const SizedBox(height: 12),
         Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Icon(Icons.info_outline_rounded, size: 18, color: c.sub),
           const SizedBox(width: 10),
           Expanded(
            child: Text(
             th ? 'คู่มือและคำแนะนำในแอปจะแสดงตามภาษาที่เลือก' : 'The guide and in-app tips follow the language you choose',
             style: TextStyle(color: c.sub, fontSize: 12.5, height: 1.5),
            ),
           ),
          ],
         ),
         const SizedBox(height: 12),
         SizedBox(
          height: 52,
          child: ElevatedButton(
           style: ElevatedButton.styleFrom(
            backgroundColor: c.accent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
           ),
           onPressed: () async {
            HapticFeedback.mediumImpact();
            Navigator.pop(ctx);
            await widget.controller.setAppLanguage(pending);
            await widget.controller.setGuideLanguage(pending);
           },
           child: Text(th ? 'ใช้ภาษาไทย' : 'Use English', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
         ),
        ],
       ),
      ),
     );
    },
   ),
  );
 }

 /// One radio row of the language sheet (flag is content, not a UI icon).
 Widget _buildLanguageOption({
  required String code,
  required String flag,
  required String name,
  required String sub,
  required bool isSelected,
  required bool isDark,
  required VoidCallback onSelect,
 }) {
  final c = _MenuColors.of(widget.controller);
  final ring = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
  return Semantics(
   inMutuallyExclusiveGroup: true,
   checked: isSelected,
   child: InkWell(
    onTap: () {
     HapticFeedback.selectionClick();
     onSelect();
    },
    child: Container(
     constraints: const BoxConstraints(minHeight: 60),
     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
     decoration: BoxDecoration(border: code == 'th' ? null : Border(top: BorderSide(color: c.border))),
     child: Row(
      children: [
       Text(flag, style: const TextStyle(fontSize: 22)),
       const SizedBox(width: 14),
       Expanded(
        child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
          Text(name, style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w600)),
          Text(sub, style: TextStyle(color: c.sub, fontSize: 12.5)),
         ],
        ),
       ),
       AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
         shape: BoxShape.circle,
         color: c.card,
         border: Border.all(color: isSelected ? c.link : ring, width: isSelected ? 6 : 2),
        ),
       ),
      ],
     ),
    ),
   ),
  );
 }

 @override
 Widget build(BuildContext context) {
  final c = _MenuColors.of(widget.controller);
  final isEn = widget.controller.isEnglish;
  final ctl = widget.controller;

  return Scaffold(
   backgroundColor: ctl.currentTheme.scaffoldBackground,
   body: Column(
    children: [
     // Same coloured top bar as the stats and premium tabs; the mascot opens the photo picker.
     MeowPageHeader(
      controller: ctl,
      title: isEn ? 'Menu' : 'เมนู',
      subtitle: isEn ? 'Your account, settings & help' : 'บัญชีของคุณ การตั้งค่า และความช่วยเหลือ',
      onMascotTap: () {
       HapticFeedback.selectionClick();
       CustomPhotoAvatarDialog.show(context, ctl, onSaved: (_) => setState(() {}));
      },
     ),
     Expanded(
    child: ListView(
     padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
     children: [
      _buildProfileCard(c, isEn),
      const SizedBox(height: 16),
      _buildMoneyCard(c, isEn),
      const SizedBox(height: 22),

      // Automations sit together.
      _buildSectionHeader(c, isEn ? 'Auto-record' : 'บันทึกอัตโนมัติ'),
      _buildCard(c, [
       _buildRow(
        c,
        icon: Icons.notifications_none_rounded,
        title: isEn ? 'Income from bank notifications' : 'ดึงรายรับจากแจ้งเตือนธนาคาร',
        subtitle: _notifGranted == true
            ? (isEn ? 'On • K PLUS, SCB EASY, Krungthai' : 'เปิดอยู่ • K PLUS, SCB EASY, กรุงไทย')
            : (isEn ? 'Off • tap to turn on' : 'ปิดอยู่ • แตะเพื่อเปิด'),
        first: true,
        chevron: false,
        trailing: Switch(
         value: _notifGranted ?? false,
         activeThumbColor: Colors.white,
         activeTrackColor: c.accent,
         onChanged: (_) => _openBankNotificationAccess(isDark: ctl.isDarkMode, isEn: isEn),
        ),
        onTap: () => _openBankNotificationAccess(isDark: ctl.isDarkMode, isEn: isEn),
       ),
       _buildRow(
        c,
        icon: Icons.work_outline_rounded,
        title: isEn ? 'Auto-record salary' : 'บันทึกเงินเดือนอัตโนมัติ',
        subtitle: _salarySubtitle(isEn),
        trailing: Text(
         ctl.salaryConfig.isEnabled ? (isEn ? 'On' : 'เปิดอยู่') : (isEn ? 'Off' : 'ปิดอยู่'),
         style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: ctl.salaryConfig.isEnabled ? c.ok : c.sub),
        ),
        onTap: () => _push(SalaryAutoRecordScreen(controller: ctl)),
       ),
       _buildRow(
        c,
        icon: Icons.sell_outlined,
        title: isEn ? 'Keyword category rules' : 'กฎคีย์เวิร์ดจัดหมวด',
        subtitle: isEn
            ? 'Yours: ${ctl.storage.getKeywordRules().length} • Built-in: ${CategoryMatcherService.defaultRules.length}'
            : 'กฎของคุณ ${ctl.storage.getKeywordRules().length} ข้อ • มาตรฐาน ${CategoryMatcherService.defaultRules.length} ข้อ',
        onTap: () => _push(KeywordRulesScreen(controller: ctl)),
       ),
      ]),
      const SizedBox(height: 22),

      _buildSectionHeader(c, isEn ? 'Customise' : 'ปรับแต่งแอป'),
      _buildCard(c, [
       _buildAppearance(c, isEn),
       _buildRow(
        c,
        icon: Icons.sentiment_satisfied_outlined,
        title: isEn ? 'Mascot & accessories' : 'ตัวละคร & มาสคอต',
        subtitle: ctl.isCustomAvatarEnabled
            ? (isEn ? 'Using your own photo' : 'ใช้รูปของคุณอยู่')
            : (isEn ? 'Change your companion and accessory' : 'เปลี่ยนตัวละครและอุปกรณ์คู่กาย'),
        onTap: () => _push(CharacterCustomizationScreen(controller: ctl)),
       ),
       _buildRow(
        c,
        icon: Icons.palette_outlined,
        title: isEn ? 'Theme shop' : 'ร้านค้าธีม',
        subtitle: isEn ? 'In use: ${ctl.currentTheme.nameEn}' : 'ใช้อยู่: ${ctl.currentTheme.name}',
        onTap: () => _push(ThemeShopScreen(controller: ctl)),
       ),
       _buildRow(
        c,
        icon: Icons.language_rounded,
        title: isEn ? 'Language' : 'ภาษา',
        subtitle: isEn ? 'App language' : 'ภาษาที่ใช้ในแอป',
        trailing: Text(ctl.appLanguage == 'en' ? 'English' : 'ไทย', style: TextStyle(fontSize: 13, color: c.sub)),
        onTap: _showLanguagePicker,
       ),
      ]),
      const SizedBox(height: 22),

      _buildSectionHeader(c, isEn ? 'Help' : 'ช่วยเหลือ'),
      _buildCard(c, [
       _buildRow(
        c,
        icon: Icons.menu_book_outlined,
        title: isEn ? 'Guide & features' : 'คู่มือ & ฟีเจอร์เด่น',
        subtitle: isEn ? '12 topics with step-by-step how-tos' : '12 หัวข้อ พร้อมวิธีใช้ทีละขั้น',
        first: true,
        onTap: () => _showGuideChooser(isDark: ctl.isDarkMode, isEn: isEn),
       ),
       _buildRow(
        c,
        icon: Icons.shield_outlined,
        title: isEn ? 'Device permissions' : 'สิทธิ์การเข้าถึงอุปกรณ์',
        subtitle: isEn ? 'Photos • Camera • Mic • Notifications' : 'รูปภาพ • กล้อง • ไมค์ • แจ้งเตือน',
        trailing: _permGranted == null
            ? null
            : Text(isEn ? 'Allowed $_permGranted/4' : 'อนุญาต $_permGranted/4', style: TextStyle(fontSize: 13, color: c.sub)),
        onTap: () => _push(PermissionOnboardingScreen(
         controller: ctl,
         fromMenu: true,
         onFinish: () => Navigator.pop(context),
        )),
       ),
       _buildRow(
        c,
        icon: Icons.mail_outline_rounded,
        title: isEn ? 'Contact us' : 'ติดต่อทีมงาน',
        subtitle: _contactEmail,
        chevron: false,
        trailing: Text(isEn ? 'Copy' : 'คัดลอก', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.link)),
        onTap: () {
         Clipboard.setData(const ClipboardData(text: _contactEmail));
         _snack(isEn ? 'Email copied' : 'คัดลอกอีเมลแล้ว');
        },
       ),
      ]),
      const SizedBox(height: 22),
      Center(
       child: Text(
        isEn ? 'MeowTang • version ${ExpenseController.appVersion}' : 'เหมียวตังค์ • เวอร์ชัน ${ExpenseController.appVersion}',
        style: TextStyle(fontSize: 12.5, color: c.sub),
       ),
      ),
     ],
    ),
     ),
    ],
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

 Future<void> _openBankNotificationAccess({required bool isDark, required bool isEn}) async {
  final granted = await NativeBridgeService.isNotificationListenerGranted();
  if (!mounted) return;
  setState(() => _notifGranted = granted);
  final c = _MenuColors.of(widget.controller);
  final ring = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
  final body = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
  const banks = ['K PLUS', 'SCB EASY', 'Krungthai NEXT', 'MyMo', 'ttb touch', 'Bualuang mBanking', 'KMA'];
  final how = isEn
      ? ['Your bank sends a “money in” notification to this phone', 'MeowTang reads the amount and sender from it', 'It is recorded as income in that account (you can edit it later)']
      : ['ธนาคารส่งแจ้งเตือน “เงินเข้า” มาที่เครื่อง', 'เหมียวตังค์อ่านยอดเงินและชื่อผู้โอนจากแจ้งเตือน', 'บันทึกเป็นรายรับเข้าบัญชีนั้นให้อัตโนมัติ (แก้ไขทีหลังได้)'];
  Widget label(String t) => Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.sub));

  showModalBottomSheet(
   context: context,
   backgroundColor: c.card,
   isScrollControlled: true,
   shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
   builder: (ctx) => SafeArea(
    child: SingleChildScrollView(
     padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
     child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
       Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: c.faint, borderRadius: BorderRadius.circular(2)))),
       const SizedBox(height: 14),
       Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.notifications_none_rounded, size: 22, color: c.icon)),
         const SizedBox(width: 12),
         Expanded(
          child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
            Text(isEn ? 'Income from bank notifications' : 'ดึงรายรับจากแจ้งเตือนธนาคาร',
             style: TextStyle(color: c.text, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(isEn ? 'When money comes in, it is recorded as income for you' : 'เงินเข้าเมื่อไร บันทึกเป็นรายรับให้เอง ไม่ต้องจดเอง',
             style: TextStyle(color: c.sub, fontSize: 12.5, height: 1.45)),
           ],
          ),
         ),
        ],
       ),
       const SizedBox(height: 14),
       Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: c.line)),
        child: Row(
         children: [
          Expanded(child: Text(isEn ? 'Status' : 'สถานะ', style: TextStyle(fontSize: 14, color: body))),
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: granted ? c.link : c.faint)),
          const SizedBox(width: 6),
          Text(granted ? (isEn ? 'On' : 'เปิดอยู่') : (isEn ? 'Off' : 'ปิดอยู่'),
           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: granted ? c.link : c.sub)),
         ],
        ),
       ),
       const SizedBox(height: 14),
       label(isEn ? 'Supported bank apps' : 'แอปธนาคารที่รองรับ'),
       const SizedBox(height: 8),
       Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
         for (final b in [...banks, isEn ? 'and more' : 'และอื่นๆ'])
          Container(
           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
           decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: c.line)),
           child: Text(b, style: TextStyle(fontSize: 12.5, color: body)),
          ),
        ],
       ),
       const SizedBox(height: 14),
       label(isEn ? 'How it works' : 'ทำงานอย่างไร'),
       for (var i = 0; i < how.length; i++)
        Padding(
         padding: const EdgeInsets.only(top: 8),
         child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ring)),
            child: Text('${i + 1}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: body)),
           ),
           const SizedBox(width: 12),
           Expanded(child: Text(how[i], style: TextStyle(fontSize: 13.5, height: 1.5, color: body))),
          ],
         ),
        ),
       const SizedBox(height: 14),
       Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Icon(Icons.lock_outline_rounded, size: 18, color: c.sub),
         const SizedBox(width: 10),
         Expanded(
          child: Text(
           granted
               ? (isEn
                   ? 'Only bank-app notifications are read, on this phone. To turn this off, switch MeowTang off in Notification access settings.'
                   : 'อ่านเฉพาะแจ้งเตือนจากแอปธนาคาร ประมวลผลในเครื่อง ไม่ส่งออกภายนอก • ถ้าต้องการปิด ให้ปิดเหมียวตังค์ในหน้า “การเข้าถึงการแจ้งเตือน”')
               : (isEn
                   ? 'Only bank-app notifications are read, processed on this phone and never sent out.'
                   : 'อ่านเฉพาะแจ้งเตือนจากแอปธนาคาร ประมวลผลในเครื่อง ไม่ส่งออกภายนอก'),
           style: TextStyle(color: c.sub, fontSize: 12.5, height: 1.5),
          ),
         ),
        ],
       ),
       const SizedBox(height: 16),
       Row(
        children: [
         Expanded(
          flex: 14,
          child: SizedBox(
           height: 52,
           child: ElevatedButton(
            style: ElevatedButton.styleFrom(
             backgroundColor: c.accent,
             foregroundColor: Colors.white,
             elevation: 0,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () async {
             Navigator.pop(ctx);
             await NativeBridgeService.openNotificationListenerSettings();
            },
            child: Text(isEn ? 'Open Settings' : 'ไปที่การตั้งค่า', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
           ),
          ),
         ),
         const SizedBox(width: 10),
         Expanded(
          flex: 10,
          child: SizedBox(
           height: 52,
           child: OutlinedButton(
            style: OutlinedButton.styleFrom(
             foregroundColor: body,
             side: BorderSide(color: c.line),
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(isEn ? 'Close' : 'ปิด', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
           ),
          ),
         ),
        ],
       ),
      ],
     ),
    ),
   ),
  );
 }

 void _showGuideChooser({required bool isDark, required bool isEn}) {
  HapticFeedback.selectionClick();
  final c = _MenuColors.of(widget.controller);
  final ring = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
  final badgeFg = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
  Widget option(IconData icon, String title, String badge, String desc, Widget screen) => Padding(
       padding: const EdgeInsets.only(bottom: 12),
       child: Material(
        color: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: c.line)),
        child: InkWell(
         borderRadius: BorderRadius.circular(14),
         onTap: () {
          Navigator.pop(context);
          _push(screen);
         },
         child: Container(
          constraints: const BoxConstraints(minHeight: 84),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
           children: [
            Icon(icon, size: 22, color: c.icon),
            const SizedBox(width: 14),
            Expanded(
             child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               Wrap(
                spacing: 6,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                 Text(title, style: TextStyle(color: c.text, fontWeight: FontWeight.w600, fontSize: 15)),
                 Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: ring)),
                  child: Text(badge, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: badgeFg)),
                 ),
                ],
               ),
               const SizedBox(height: 2),
               Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.sub, fontSize: 12.5, height: 1.45)),
              ],
             ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 20, color: c.faint),
           ],
          ),
         ),
        ),
       ),
      );
  showModalBottomSheet(
   context: context,
   backgroundColor: c.card,
   isScrollControlled: true,
   shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
   builder: (_) => SafeArea(
    child: SingleChildScrollView(
     padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
     child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
       Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: c.faint, borderRadius: BorderRadius.circular(2)))),
       const SizedBox(height: 12),
       Text(isEn ? 'Guide & features' : 'คู่มือ & ฟีเจอร์เด่น', style: TextStyle(color: c.text, fontSize: 17, fontWeight: FontWeight.w700)),
       Text(isEn ? 'How would you like to look?' : 'อยากดูแบบไหน?', style: TextStyle(color: c.sub, fontSize: 12.5)),
       const SizedBox(height: 12),
       option(
        Icons.menu_book_outlined,
        isEn ? 'How to use, step by step' : 'วิธีใช้งานทีละขั้น',
        isEn ? '12 topics' : '12 หัวข้อ',
        isEn
            ? 'Auto slip import from 22 banks, slip check, voice entry, export & backup …'
            : 'ดึงสลิปอัตโนมัติ 22 ธนาคาร, ตรวจสลิปแท้, พูดจดด้วยเสียง, ส่งออก & สำรองข้อมูล …',
        AppGuideScreen(controller: widget.controller),
       ),
       option(
        Icons.auto_awesome_outlined,
        isEn ? 'All features' : 'ฟีเจอร์ทั้งหมดของแอป',
        isEn ? 'Everything' : 'รวมทุกอย่าง',
        isEn
            ? '150+ currencies & gold, Islamic finance & zakat, 22 characters, 18 themes …'
            : 'แปลงเงิน 150+ สกุลเงิน & ทอง, การเงินอิสลาม & ซากาต, 22 ตัวละคร, 18 ธีม …',
        AppFeaturesShowcaseScreen(controller: widget.controller, isFromMenu: true),
       ),
       SizedBox(
        height: 48,
        child: OutlinedButton(
         style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          side: BorderSide(color: c.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
         ),
         onPressed: () => Navigator.pop(context),
         child: Text(isEn ? 'Close' : 'ปิด', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
       ),
      ],
     ),
    ),
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
     _snack(isEn ? 'Reward earned! +2 slips added!' : 'ยินดีด้วย! คุณได้รับสิทธิ์เพิ่ม +2 สลิปแล้ว');
    }
   },
  );
 }

 // ---------------------------------------------------------------------------
 // Cards and rows (calm style: line icons, 1px borders, no tinted tiles)
 // ---------------------------------------------------------------------------
 Widget _buildProfileCard(_MenuColors c, bool isEn) {
  final ctl = widget.controller;
  final vip = ctl.isPremium;
  final used = ctl.currentMonthSlipCount;
  final max = ctl.maxFreeSlipsPerMonth;
  final adsLeft = (ctl.maxMonthlyRewardedAds - ctl.currentMonthAdWatchesCount).clamp(0, ctl.maxMonthlyRewardedAds);

  return Container(
   decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.line)),
   child: Column(
    children: [
     Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      child: Row(
       children: [
        Expanded(
         child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Row(
            children: [
             Flexible(
              child: Text(
               vip ? (isEn ? 'VIP member' : 'สมาชิก VIP') : (isEn ? 'Free plan' : 'ผู้ใช้ฟรี'),
               maxLines: 1,
               overflow: TextOverflow.ellipsis,
               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.text),
              ),
             ),
             if (vip) ...[const SizedBox(width: 8), _vipBadge(c)],
            ],
           ),
           const SizedBox(height: 3),
           Text(
            vip
                ? (isEn ? 'Unlimited slips • no ads' : 'สลิปไม่จำกัด • ไม่มีโฆษณา')
                : (isEn ? 'Upgrade for unlimited slips and no ads' : 'อัปเกรดเพื่อดึงสลิปไม่จำกัดและไม่มีโฆษณา'),
            style: TextStyle(fontSize: 12.5, height: 1.35, color: c.sub),
           ),
          ],
         ),
        ),
        if (!vip)
         OutlinedButton(
          onPressed: () => MeowPaywallModal.show(
           context,
           controller: ctl,
           reason: isEn ? 'Upgrade to VIP to unlock every feature' : 'อัปเกรดเป็น VIP เพื่อปลดล็อคทุกฟีเจอร์',
          ),
          style: OutlinedButton.styleFrom(
           foregroundColor: c.link,
           side: BorderSide(color: c.link.withValues(alpha: 0.35)),
           minimumSize: const Size(64, 40),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(isEn ? 'Upgrade' : 'อัปเกรด', style: const TextStyle(fontWeight: FontWeight.w600)),
         ),
        // Developer-only shortcut to test the free tier; never shown in release builds.
        if (vip && kDebugMode)
         TextButton(
          onPressed: () async {
           await ctl.resetToFreeMode();
           if (mounted) _snack('สลับเข้าสู่โหมดผู้ใช้ฟรี (ทดสอบ)');
          },
          child: const Text('ทดสอบโหมดฟรี', style: TextStyle(fontSize: 12)),
         ),
       ],
      ),
     ),
     if (!vip) ...[
      Divider(height: 1, thickness: 1, color: c.border),
      Padding(
       padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
       child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Row(
          children: [
           Expanded(child: Text(isEn ? 'Free slips this month' : 'สลิปฟรีเดือนนี้', style: TextStyle(fontSize: 13, color: c.sub))),
           Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text.rich(TextSpan(children: [
             TextSpan(text: '$used', style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
             TextSpan(text: ' / $max', style: TextStyle(color: c.sub)),
            ]), style: const TextStyle(fontSize: 13)),
           ),
          ],
         ),
         const SizedBox(height: 8),
         Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ClipRRect(
           borderRadius: BorderRadius.circular(3),
           child: LinearProgressIndicator(
            value: max > 0 ? (used / max).clamp(0.0, 1.0) : 0.0,
            minHeight: 6,
            backgroundColor: c.seg,
            valueColor: AlwaysStoppedAnimation<Color>(c.text),
           ),
          ),
         ),
         Row(
          children: [
           Expanded(
            child: Text(
             isEn ? 'Ad rewards left: $adsLeft' : 'ดูโฆษณารับเพิ่มได้อีก $adsLeft ครั้ง',
             style: TextStyle(fontSize: 12, color: c.sub),
            ),
           ),
           TextButton(
            onPressed: ctl.canWatchRewardedAd ? () => _watchAd(isEn) : null,
            style: TextButton.styleFrom(foregroundColor: c.link, minimumSize: const Size(44, 40)),
            child: Text(
             ctl.canWatchRewardedAd ? (isEn ? 'Watch ad +2 slips' : 'ดูโฆษณา +2 สลิป') : (isEn ? 'Used up this month' : 'ครบแล้วเดือนนี้'),
             style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
           ),
          ],
         ),
        ],
       ),
      ),
     ],
    ],
   ),
  );
 }

 Widget _buildMoneyCard(_MenuColors c, bool isEn) {
  final ctl = widget.controller;
  return Container(
   decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.line)),
   clipBehavior: Clip.antiAlias,
   child: Material(
    color: Colors.transparent,
    child: Column(
     children: [
      InkWell(
       onTap: () {
        HapticFeedback.selectionClick();
        _push(AccountManagementScreen(controller: ctl));
       },
       child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
         children: [
          Expanded(
           child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             Text(isEn ? 'Total balance' : 'ยอดเงินคงเหลือรวม', style: TextStyle(fontSize: 12.5, color: c.sub)),
             const SizedBox(height: 2),
             FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
               '฿${FormatUtils.formatCurrency(ctl.totalNetWorth)}',
               style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: c.text, fontFeatures: const [FontFeature.tabularFigures()]),
              ),
             ),
            ],
           ),
          ),
          Text(isEn ? '${ctl.accounts.length} accounts' : '${ctl.accounts.length} บัญชี', style: TextStyle(fontSize: 13, color: c.sub)),
          Icon(Icons.chevron_right_rounded, color: c.faint),
         ],
        ),
       ),
      ),
      Divider(height: 1, thickness: 1, color: c.border),
      Padding(
       padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
       child: Row(
        children: [
         _shortcut(c, Icons.account_balance_wallet_outlined, isEn ? 'Accounts' : 'บัญชี',
          () => _push(AccountManagementScreen(controller: ctl))),
         _shortcut(c, Icons.grid_view_outlined, isEn ? 'Categories' : 'หมวดหมู่',
          () => _push(CategoryManagementScreen(controller: ctl))),
         _shortcut(c, Icons.cloud_upload_outlined, isEn ? 'Backup' : 'สำรองข้อมูล',
          () => _push(DataBackupRestoreScreen(controller: ctl))),
         _shortcut(c, Icons.file_download_outlined, isEn ? 'Export' : 'ส่งออก',
          () => _push(ExportReportScreen(controller: ctl)), vip: !ctl.isPremium),
        ],
       ),
      ),
     ],
    ),
   ),
  );
 }

 Widget _shortcut(_MenuColors c, IconData icon, String label, VoidCallback onTap, {bool vip = false}) {
  return Expanded(
   child: InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () {
     HapticFeedback.selectionClick();
     onTap();
    },
    child: Padding(
     padding: const EdgeInsets.symmetric(vertical: 8),
     child: Column(
      children: [
       Stack(
        clipBehavior: Clip.none,
        children: [
         Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.line)),
          child: Icon(icon, size: 22, color: c.icon),
         ),
         if (vip) Positioned(top: -6, right: -16, child: _vipBadge(c)),
        ],
       ),
       const SizedBox(height: 8),
       Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: c.text)),
      ],
     ),
    ),
   ),
  );
 }

 Widget _vipBadge(_MenuColors c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), border: Border.all(color: c.vipLine)),
      child: Text('VIP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: c.vip)),
     );

 Widget _buildAppearance(_MenuColors c, bool isEn) {
  final isDark = widget.controller.isDarkMode;
  Widget option(bool dark, IconData icon, String label) {
   final selected = isDark == dark;
   return Expanded(
    child: Material(
     color: selected ? c.card : Colors.transparent,
     borderRadius: BorderRadius.circular(9),
     elevation: selected ? 0.5 : 0,
     child: InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: () {
       HapticFeedback.selectionClick();
       widget.controller.toggleThemeMode(dark);
      },
      child: SizedBox(
       height: 40,
       child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
         Icon(icon, size: 18, color: selected ? c.text : c.sub),
         const SizedBox(width: 8),
         Text(label,
          style: TextStyle(fontSize: 13.5, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? c.text : c.sub)),
        ],
       ),
      ),
     ),
    ),
   );
  }

  return Padding(
   padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
   child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
     Row(
      children: [
       Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined, size: 22, color: c.icon),
       const SizedBox(width: 14),
       Text(isEn ? 'Appearance' : 'โหมดการแสดงผล', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.text)),
      ],
     ),
     const SizedBox(height: 10),
     Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.seg, borderRadius: BorderRadius.circular(12)),
      child: Row(
       children: [
        option(false, Icons.light_mode_outlined, isEn ? 'Light' : 'สว่าง'),
        const SizedBox(width: 4),
        option(true, Icons.dark_mode_outlined, isEn ? 'Dark' : 'มืด'),
       ],
      ),
     ),
    ],
   ),
  );
 }

 Widget _buildSectionHeader(_MenuColors c, String title) => Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: TextStyle(color: c.sub, fontSize: 13, fontWeight: FontWeight.w600)),
     );

 Widget _buildCard(_MenuColors c, List<Widget> children) => Container(
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.line)),
      clipBehavior: Clip.antiAlias,
      child: Material(color: Colors.transparent, child: Column(children: children)),
     );

 /// One menu row: line icon, title + status line, optional trailing value; inset divider above unless [first].
 Widget _buildRow(
  _MenuColors c, {
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
  Widget? trailing,
  bool first = false,
  bool chevron = true,
 }) {
  return InkWell(
   onTap: () {
    HapticFeedback.selectionClick();
    onTap();
   },
   child: Padding(
    padding: const EdgeInsets.only(left: 16, right: 12),
    child: Row(
     children: [
      Icon(icon, size: 22, color: c.icon),
      const SizedBox(width: 14),
      Expanded(
       child: Container(
        constraints: const BoxConstraints(minHeight: 62),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: c.border))),
        child: Row(
         children: [
          Expanded(
           child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
             Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.text)),
             const SizedBox(height: 2),
             Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, height: 1.35, color: c.sub)),
            ],
           ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
          if (chevron) Icon(Icons.chevron_right_rounded, size: 20, color: c.faint),
         ],
        ),
       ),
      ),
     ],
    ),
   ),
  );
 }
}

/// Neutral palette for the menu, derived from the active theme.
class _MenuColors {
 final Color text, sub, icon, faint, card, line, border, seg, accent, link, ok, vip, vipLine;

 const _MenuColors({
  required this.text,
  required this.sub,
  required this.icon,
  required this.faint,
  required this.card,
  required this.line,
  required this.border,
  required this.seg,
  required this.accent,
  required this.link,
  required this.ok,
  required this.vip,
  required this.vipLine,
 });

 factory _MenuColors.of(ExpenseController ctl) {
  final t = ctl.currentTheme;
  final dark = ctl.isDarkMode;
  return _MenuColors(
   text: t.textColor,
   sub: t.textSecondaryColor,
   icon: dark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
   faint: dark ? Colors.white24 : const Color(0xFFB6BECB),
   card: t.cardBackground,
   line: t.borderColor,
   border: dark ? Colors.white10 : const Color(0xFFEEF0F4),
   seg: dark ? const Color(0xFF0F172A) : const Color(0xFFF1F3F8),
   accent: t.primaryColor,
   link: dark ? const Color(0xFF93C5FD) : t.primaryColor,
   ok: dark ? const Color(0xFF34D399) : const Color(0xFF047857),
   vip: dark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
   vipLine: dark ? const Color(0xFF6B5A1E) : const Color(0xFFE9C98B),
  );
 }
}
