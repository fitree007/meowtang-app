import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_expense_tracker/screens/islamic_inheritance_screen.dart';
import 'package:ai_expense_tracker/services/storage_service.dart';
import 'package:ai_expense_tracker/state/expense_controller.dart';
import 'package:ai_expense_tracker/utils/format_utils.dart';

String _baht(double v) => '฿${FormatUtils.formatCurrency(v)}';

Future<void> _pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 12000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final storage = StorageService();
  await storage.init();
  final controller = ExpenseController(storage);
  await tester.pumpWidget(MaterialApp(home: IslamicInheritanceScreen(controller: controller)));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Finder _fieldUnder(String label) => find.descendant(
      of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
      matching: find.byType(TextField),
    );

/// Loads a case study by its title and opens the result screen.
Future<void> _runCase(WidgetTester tester, String title) async {
  await _tap(tester, find.text('กรณีศึกษา'));
  final card = find.ancestor(of: find.text(title), matching: find.byType(Container)).first;
  await _tap(tester, find.descendant(of: card, matching: find.text('ลองคำนวณ')));
  await tester.pump(const Duration(seconds: 3)); // let the snack bar go
  await tester.pumpAndSettle();
  await _tap(tester, find.text('ดูผลการแบ่งมรดก'));
}

void main() {
  testWidgets('assets can be itemised, including motorcycles and custom items', (tester) async {
    await _pumpScreen(tester);
    await _tap(tester, find.text('แยกตามประเภททรัพย์สิน'));
    expect(find.text('🛵 รถจักรยานยนต์'), findsOneWidget);

    await tester.enterText(_fieldUnder('🏞️ ที่ดิน / สวน / ไร่นา'), '600000');
    await tester.enterText(_fieldUnder('🛵 รถจักรยานยนต์'), '50000');
    await _tap(tester, find.text('เพิ่มทรัพย์สินอื่น (เช่น เรือ เครื่องจักร)'));
    await tester.enterText(_fieldUnder('📦 ชื่อทรัพย์สิน'), 'เรือประมง');
    await tester.enterText(_fieldUnder('มูลค่า'), '100000');
    await tester.pumpAndSettle();

    // itemised total, net estate and bottom bar
    expect(find.text(_baht(750000)), findsNWidgets(3));
  });

  testWidgets('al-Haml case holds back the possible share of the unborn child', (tester) async {
    await _pumpScreen(tester);
    await _runCase(tester, 'ทายาทยังเป็นทารกในครรภ์');

    expect(find.text('ขั้นที่ 1: แบ่งเฉพาะส่วนที่แน่นอนก่อน'), findsOneWidget);
    // estate 1,200,000: wife 1/9, mother & father 4/27 each, 16/27 held back
    expect(find.text(_baht(1200000 / 9)), findsOneWidget);
    expect(find.text(_baht(1200000 * 4 / 27)), findsNWidgets(2));
    expect(find.text(_baht(1200000 * 16 / 27)), findsOneWidget);
    expect(find.text('ทารกเสียชีวิตก่อนคลอด'), findsOneWidget);
    expect(find.text('คลอด 2 คน (1 ชาย + 1 หญิง)'), findsOneWidget);
  });

  testWidgets('al-Mafqud case holds back the missing son\'s share', (tester) async {
    await _pumpScreen(tester);
    await _runCase(tester, 'ทายาทสูญหาย');

    // wife 1/8 = 150,000; son 7/20 = 420,000; daughter 7/40 = 210,000; held back 7/20 = 420,000
    expect(find.text(_baht(150000)), findsOneWidget);
    expect(find.text(_baht(420000)), findsNWidgets(2));
    expect(find.text(_baht(210000)), findsOneWidget);
    expect(find.text('ลูกชายที่สูญหาย ยังมีชีวิต'), findsOneWidget);
  });

  testWidgets('al-Gharqa case divides each estate separately', (tester) async {
    await _pumpScreen(tester);
    await _runCase(tester, 'เสียชีวิตพร้อมกัน');

    expect(find.text('ขั้นที่ 2: ลูกชาย (เสียชีวิตพร้อมกัน)'), findsOneWidget);
    expect(find.textContaining('ไม่รับมรดกจากผู้ตายคนแรก'), findsOneWidget);
    // son's own 300,000: wife 3/13, mother 4/13, full sister 6/13 (aul 12 -> 13)
    expect(find.text(_baht(300000 * 3 / 13)), findsWidgets);
    expect(find.text(_baht(300000 * 6 / 13)), findsWidgets);
  });

  testWidgets('ordinary result screen shows the step-by-step card', (tester) async {
    await _pumpScreen(tester);
    await _runCase(tester, 'คดีท่านอุมัร (คู่สมรส + พ่อ + แม่)');

    // wife 1/4, mother 1/3 of the rest = 1/4, father 1/2
    expect(find.text(_baht(300000)), findsWidgets);
    expect(find.text(_baht(600000)), findsWidgets);
    expect(find.text('วิธีคิดทีละขั้นตอน'), findsOneWidget);
  });
}
