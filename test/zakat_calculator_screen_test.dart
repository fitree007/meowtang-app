import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_expense_tracker/screens/zakat_calculator_screen.dart';
import 'package:ai_expense_tracker/services/storage_service.dart';
import 'package:ai_expense_tracker/state/expense_controller.dart';
import 'package:ai_expense_tracker/utils/format_utils.dart';

String _baht(double v) => '฿${FormatUtils.formatCurrency(v)}';

Future<void> _pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final storage = StorageService();
  await storage.init();
  final controller = ExpenseController(storage);
  await tester.pumpWidget(MaterialApp(home: ZakatCalculatorScreen(controller: controller)));
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

void main() {
  testWidgets('gold: quick chip, worn jewellery is exempt, and the year must pass', (tester) async {
    await _pumpScreen(tester);
    await _tap(tester, find.text('ทองคำ & แร่เงิน'));
    await _tap(tester, find.text('6 บาท'));

    // 6 baht-weight of gold bar at the fallback price ฿70,150
    final zakat = 6 * 70150 * 0.025;
    expect(find.text(_baht(zakat)), findsNWidgets(2)); // result card + bottom bar
    expect(find.text('บันทึกเป็นรายจ่าย'), findsOneWidget);

    await _tap(tester, find.text('เป็นเครื่องประดับที่สวมใส่ตามปกติ'));
    expect(find.text('ไม่ต้องออกซากาต'), findsOneWidget);
    expect(find.text('ยังไม่ต้องจ่าย'), findsOneWidget);

    await _tap(tester, find.text('เป็นเครื่องประดับที่สวมใส่ตามปกติ'));
    await _tap(tester, find.byType(Switch).first);
    expect(find.text('ถึงนิศอบแล้ว แต่ยังไม่ครบปี'), findsOneWidget);
  });

  testWidgets('silver uses the 595 g nisab', (tester) async {
    await _pumpScreen(tester);
    await _tap(tester, find.text('ทองคำ & แร่เงิน'));
    await _tap(tester, find.text('🥈 แร่เงิน'));
    await _tap(tester, find.text('300 กรัม'));
    expect(find.text('ยังไม่ถึงนิศอบ — ยังไม่ต้องจ่าย'), findsOneWidget);
    await _tap(tester, find.text('1,000 กรัม'));
    expect(find.text('ถึงเกณฑ์ — วาญิบต้องออกซากาต'), findsOneWidget);
  });

  testWidgets('crops: mixed watering is 7.5%', (tester) async {
    await _pumpScreen(tester);
    await _tap(tester, find.text('ผลผลิตเกษตร'));
    await tester.enterText(_fieldUnder('🌾 ผลผลิตที่เก็บเกี่ยวได้ (ข้าว ข้าวโพด ฯลฯ)'), '1000');
    await _tap(tester, find.text('ผสมกันพอ ๆ กัน'));
    expect(find.text('${FormatUtils.formatCurrency(75)} กก.'), findsNWidgets(2));
  });

  testWidgets('livestock: plus button reaches the goat nisab', (tester) async {
    await _pumpScreen(tester);
    await _tap(tester, find.text('ปศุสัตว์'));
    await tester.enterText(find.byType(TextField).first, '39');
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่ถึงนิศอบ — ยังไม่ต้องจ่าย'), findsOneWidget);
    await _tap(tester, find.byIcon(Icons.add_rounded));
    expect(find.text('แพะหรือแกะ 1 ตัว'), findsNWidgets(2));
  });
}
