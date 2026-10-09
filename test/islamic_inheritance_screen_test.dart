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


/// Loads a case study by its title and opens the result screen.
Future<void> _runCase(WidgetTester tester, String title) async {
  await _tap(tester, find.text('7 กรณีศึกษา'));
  final card = find.ancestor(of: find.text(title), matching: find.byType(Container)).first;
  await _tap(tester, find.descendant(of: card, matching: find.text('ลองคำนวณ')));
  await tester.pump(const Duration(seconds: 3)); // let the snack bar go
  await tester.pumpAndSettle();
  await _tap(tester, find.text('ดูผลการแบ่งมรดก'));
}

/// The amount field on the preset asset row labelled [name].
Finder _amountIn(String name) => find
    .descendant(
      of: find.ancestor(of: find.text(name), matching: find.byType(Row)).first,
      matching: find.byType(TextField),
    )
    .last;

void main() {
  testWidgets('asset breakdown (default mode) sums into the read-only total', (tester) async {
    await _pumpScreen(tester);
    expect(find.text('ใช้ราคาตลาด ณ วันที่เสียชีวิต'), findsOneWidget);

    await tester.enterText(_amountIn('บ้าน/ที่ดิน'), '1000000');
    await tester.enterText(_amountIn('รถยนต์'), '200000');
    await tester.pumpAndSettle();
    expect(find.text('1,200,000'), findsOneWidget); // read-only total
    expect(find.text(_baht(1200000)), findsOneWidget); // net estate

    // a custom row adds to the total and can be deleted
    await _tap(tester, find.text('+ เพิ่มรายการอื่น ๆ'));
    await tester.enterText(find.widgetWithText(TextField, 'ชื่อรายการ เช่น เรือประมง'), 'เรือประมง');
    await tester.enterText(
        find
            .descendant(
              of: find.ancestor(of: find.byTooltip('ลบรายการ'), matching: find.byType(Row)).first,
              matching: find.byType(TextField),
            )
            .last,
        '100000');
    await tester.pumpAndSettle();
    expect(find.text('1,300,000'), findsOneWidget);
    await _tap(tester, find.byTooltip('ลบรายการ'));
    expect(find.text('1,200,000'), findsOneWidget);

    // "กรอกยอดรวม" carries the sum over as an editable manual value
    await _tap(tester, find.text('กรอกยอดรวม'));
    final total = find.widgetWithText(TextField, '1,200,000');
    expect(total, findsOneWidget);
    expect(find.text('บ้าน/ที่ดิน'), findsNothing);
    await tester.enterText(total, '900000');
    await tester.pumpAndSettle();
    expect(find.text(_baht(900000)), findsOneWidget);

    // switching back keeps the rows the user entered
    await _tap(tester, find.text('แยกรายการ'));
    expect(find.text('1,200,000'), findsOneWidget);
  });

  testWidgets('al-Haml case holds back the possible share of the unborn child', (tester) async {
    await _pumpScreen(tester);
    await _runCase(tester, 'ทายาทเป็นทารกในครรภ์ (อัล-ฮัมล์)');

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
    await _runCase(tester, 'ทายาทสูญหาย (อัล-มัฟกูด)');

    // wife 1/8 = 150,000; son 7/20 = 420,000; daughter 7/40 = 210,000; held back 7/20 = 420,000
    expect(find.text(_baht(150000)), findsOneWidget);
    expect(find.text(_baht(420000)), findsNWidgets(2));
    expect(find.text(_baht(210000)), findsOneWidget);
    expect(find.text('ลูกชายที่สูญหาย ยังมีชีวิต'), findsOneWidget);
  });

  testWidgets('al-Gharqa case divides each estate separately', (tester) async {
    await _pumpScreen(tester);
    await _runCase(tester, 'เสียชีวิตพร้อมกันในอุบัติเหตุ (อัล-ฆอร็อก)');

    expect(find.text('ขั้นที่ 2: ลูกชาย (เสียชีวิตพร้อมกัน)'), findsOneWidget);
    expect(find.textContaining('ไม่รับมรดกจากผู้ตายคนแรก'), findsOneWidget);
    // son's own 300,000: wife 3/13, mother 4/13, full sister 6/13 (aul 12 -> 13)
    expect(find.text(_baht(300000 * 3 / 13)), findsWidgets);
    expect(find.text(_baht(300000 * 6 / 13)), findsWidgets);
  });

  testWidgets('ordinary result screen shows the step-by-step card', (tester) async {
    await _pumpScreen(tester);
    await _runCase(tester, 'คดีท่านอุมัร (อัล-เฆาะรอวัยน์)');

    // wife 1/4, mother 1/3 of the rest = 1/4, father 1/2
    expect(find.text(_baht(300000)), findsWidgets);
    expect(find.text(_baht(600000)), findsWidgets);
    expect(find.text('วิธีคิดทีละขั้น'), findsOneWidget);
  });
}
