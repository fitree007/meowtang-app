import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_expense_tracker/config/app_config.dart';
import 'package:ai_expense_tracker/models/transaction_item.dart';
import 'package:ai_expense_tracker/screens/account_management_screen.dart';
import 'package:ai_expense_tracker/screens/export_report_screen.dart';
import 'package:ai_expense_tracker/screens/keyword_rules_screen.dart';
import 'package:ai_expense_tracker/screens/meow_human_screen.dart';
import 'package:ai_expense_tracker/screens/permission_onboarding_screen.dart';
import 'package:ai_expense_tracker/services/storage_service.dart';
import 'package:ai_expense_tracker/state/expense_controller.dart';

Future<ExpenseController> _controller() async {
  SharedPreferences.setMockInitialValues({});
  final storage = StorageService();
  await storage.init();
  return ExpenseController(storage);
}

Future<void> _pump(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(900, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  group('parseMoneyInput', () {
    test('accepts thousands separators and baht sign', () {
      expect(parseMoneyInput('1,000'), 1000);
      expect(parseMoneyInput(' ฿12,345.50 '), 12345.5);
      expect(parseMoneyInput(''), 0);
    });

    test('rejects text that is not a number', () {
      expect(parseMoneyInput('abc'), isNull);
      expect(parseMoneyInput('1.2.3'), isNull);
    });
  });

  tearDown(() => AppConfig.overrideEdition = null);

  testWidgets('menu groups automations together and shows status lines', (tester) async {
    AppConfig.overrideEdition = 'playstore'; // free user
    final c = await _controller();
    await _pump(tester, MeowHumanScreen(controller: c));

    for (final section in ['บันทึกอัตโนมัติ', 'บัญชี & หมวดหมู่', 'ข้อมูล & รายงาน', 'ปรับแต่งแอป', 'ช่วยเหลือ & ความเป็นส่วนตัว']) {
      expect(find.text(section), findsOneWidget, reason: section);
    }
    expect(find.text('ดึงรายรับจากแจ้งเตือนธนาคาร'), findsOneWidget);
    expect(find.textContaining('กฎของคุณ 0 ข้อ'), findsOneWidget);
    expect(find.text('🇹🇭 ไทย'), findsOneWidget);
    // Free plan: one combined quota card and a VIP badge on export.
    expect(find.text('📊 สลิปฟรีเดือนนี้'), findsOneWidget);
    expect(find.text('👑 VIP'), findsOneWidget);
    // Guide and features share one entry that offers both.
    await _tap(tester, find.text('คู่มือ & ฟีเจอร์เด่น'));
    expect(find.text('วิธีใช้งานทีละขั้น'), findsOneWidget);
    expect(find.text('ฟีเจอร์ทั้งหมดของแอป'), findsOneWidget);
  });

  testWidgets('VIP menu: slim status row, no quota card or VIP badge', (tester) async {
    AppConfig.overrideEdition = 'creator';
    final c = await _controller();
    await _pump(tester, MeowHumanScreen(controller: c));
    expect(find.text('สมาชิก VIP • สลิปไม่จำกัด • ไม่มีโฆษณา'), findsOneWidget);
    expect(find.text('📊 สลิปฟรีเดือนนี้'), findsNothing);
    expect(find.text('👑 VIP'), findsNothing);
  });

  testWidgets('keyword rule: add, edit by tapping, delete with undo', (tester) async {
    final c = await _controller();
    await _pump(tester, KeywordRulesScreen(controller: c));
    expect(find.text('ยังไม่มีคีย์เวิร์ดของคุณ'), findsOneWidget);

    await _tap(tester, find.text('เพิ่มคีย์เวิร์ดแรก'));
    await tester.enterText(find.byType(TextField).at(1), 'ชาตรามือ');
    await _tap(tester, find.widgetWithText(ElevatedButton, 'เพิ่มคีย์เวิร์ด'));
    expect(find.text('ชาตรามือ'), findsOneWidget);
    expect(c.storage.getKeywordRules().length, 1);

    // Tap the rule to edit it in place.
    await _tap(tester, find.text('ชาตรามือ'));
    expect(find.text('แก้ไขคีย์เวิร์ด'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), 'ชาไทย');
    await _tap(tester, find.widgetWithText(ElevatedButton, 'บันทึก'));
    expect(find.text('ชาไทย'), findsOneWidget);
    expect(c.storage.getKeywordRules().length, 1);

    // Delete, then undo from the snack bar.
    await _tap(tester, find.byTooltip('ลบคีย์เวิร์ดนี้'));
    expect(find.text('ชาไทย'), findsNothing);
    expect(c.storage.getKeywordRules(), isEmpty);
    await tester.tap(find.text('เลิกทำ'));
    await tester.pumpAndSettle();
    expect(find.text('ชาไทย'), findsOneWidget);
    expect(c.storage.getKeywordRules().length, 1);
  });

  testWidgets('permissions from the menu: no skip button, nothing reset on leaving', (tester) async {
    final c = await _controller();
    await c.savePermissions(bankAlbum: true, installedApps: true, mainAlbum: true);
    var finished = false;
    await _pump(
      tester,
      PermissionOnboardingScreen(controller: c, fromMenu: true, onFinish: () => finished = true),
    );
    expect(find.text('สิทธิ์การเข้าถึงอุปกรณ์'), findsOneWidget);
    expect(find.text('ข้ามไปก่อน'), findsNothing);
    expect(finished, isFalse);
  });

  testWidgets('export counts only the chosen days (not the evening before)', (tester) async {
    final c = await _controller();
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    TransactionItem tx(String id, DateTime d) => TransactionItem(
          id: id,
          title: 'กาแฟ',
          amount: 60,
          date: d,
          type: TransactionType.expense,
          categoryId: 'food',
          categoryName: 'อาหาร',
          accountId: c.accounts.first.id,
        );
    // 20:00 on the last day of last month used to slip into "this month".
    await tester.runAsync(() async {
      await c.addTransaction(tx('t_prev', firstOfMonth.subtract(const Duration(hours: 4))), allowManualOverride: true);
      await c.addTransaction(tx('t_in', firstOfMonth.add(const Duration(hours: 9))), allowManualOverride: true);
    });
    await _pump(tester, ExportReportScreen(controller: c));
    expect(find.text('1 รายการ'), findsOneWidget);
    // The two CSV options were the same file; only Excel / CSV and PDF remain.
    expect(find.text('CSV ทั่วไป'), findsNothing);
    expect(find.text('Excel / CSV'), findsOneWidget);
  });
}
