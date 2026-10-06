import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_expense_tracker/models/transaction_item.dart';
import 'package:ai_expense_tracker/screens/meow_analytics_screen.dart';
import 'package:ai_expense_tracker/services/storage_service.dart';
import 'package:ai_expense_tracker/state/expense_controller.dart';

Future<ExpenseController> _controller(WidgetTester tester, {bool withData = true}) async {
  SharedPreferences.setMockInitialValues({});
  final s = StorageService();
  await s.init();
  final c = ExpenseController(s);
  if (!withData) return c;
  await tester.runAsync(() async {
    final now = DateTime.now();
    final food = c.expenseCategories.first;
    final salary = c.incomeCategories.first;
    TransactionItem tx(String id, double amt, TransactionType type, String catId, String cat, DateTime d, [List<String> tags = const []]) =>
        TransactionItem(id: id, title: 'item $id', amount: amt, type: type, date: d, accountId: 'a', categoryId: catId, categoryName: cat, tags: tags);
    final thisMonth = DateTime(now.year, now.month, 1, 12);
    final lastMonth = DateTime(now.year, now.month - 1, 3, 12);
    await c.addTransactionsBatch([
      tx('1', 30000, TransactionType.income, salary.id, salary.name, thisMonth),
      tx('2', 600, TransactionType.expense, food.id, food.name, thisMonth, ['lunch']),
      tx('3', 400, TransactionType.expense, food.id, food.name, thisMonth),
      tx('4', 2000, TransactionType.expense, food.id, food.name, lastMonth),
    ]);
  });
  return c;
}

Future<void> _pump(WidgetTester tester, ExpenseController c) async {
  tester.view.physicalSize = const Size(900, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: MeowAnalyticsScreen(controller: c)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('overview: summary, change vs last month, category list', (tester) async {
    final c = await _controller(tester);
    await _pump(tester, c);
    expect(find.text('สรุปเดือนนี้'), findsOneWidget);
    expect(find.text('฿30,000'), findsOneWidget);
    expect(find.text('+฿29,000'), findsOneWidget);
    expect(find.textContaining('จาก'), findsOneWidget); // 50% less than last month
    expect(find.text('แจกแจงตามหมวดหมู่'), findsOneWidget);
  });

  testWidgets('tapping a category opens its #tags and the tag items', (tester) async {
    final c = await _controller(tester);
    await _pump(tester, c);
    final food = c.expenseCategories.first;
    await tester.tap(find.text(food.name).last);
    await tester.pumpAndSettle();
    expect(find.text('#lunch'), findsOneWidget);
    expect(find.text('ไม่ได้ระบุ #แท็ก'), findsOneWidget);
    await tester.tap(find.text('#lunch'));
    await tester.pumpAndSettle();
    expect(find.text('#lunch (1 รายการ)'), findsOneWidget);
  });

  testWidgets('compare: months and years both render', (tester) async {
    final c = await _controller(tester);
    await _pump(tester, c);
    await tester.tap(find.text('เทียบเดือน'));
    await tester.pumpAndSettle();
    expect(find.text('ใช้จ่ายสะสมรายวัน'), findsOneWidget);
    expect(find.text('ประหยัดมากสุด'), findsOneWidget);
    await tester.tap(find.text('เทียบ 2 ปี'));
    await tester.pumpAndSettle();
    expect(find.text('ใช้จ่ายสะสมรายเดือน'), findsOneWidget);
  });

  testWidgets('no transactions: every tab still renders', (tester) async {
    final c = await _controller(tester, withData: false);
    await _pump(tester, c);
    for (final t in ['หมวดหมู่ & #แท็ก', 'เทียบเดือน', 'ภาพรวม']) {
      await tester.tap(find.text(t));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
