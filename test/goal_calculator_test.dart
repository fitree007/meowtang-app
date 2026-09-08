import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_expense_tracker/screens/goal_calculator_screen.dart';
import 'package:ai_expense_tracker/state/expense_controller.dart';
import 'package:ai_expense_tracker/services/storage_service.dart';

void main() {
  group('Goal Savings Calculation tests', () {
    test('Calculate days needed: 300,000 THB with 100 THB/day', () {
      const target = 300000.0;
      const initial = 0.0;
      const savingPerDay = 100.0;
      final remaining = target - initial;
      final daysNeeded = (remaining / savingPerDay).ceil();

      expect(daysNeeded, 3000);

      final years = daysNeeded ~/ 365;
      final remainingDaysAfterYears = daysNeeded % 365;
      final months = remainingDaysAfterYears ~/ 30;
      final days = remainingDaysAfterYears % 30;

      expect(years, 8);
      expect(months, 2);
      expect(days, 20);
    });

    test('Calculate required daily savings for 100,000 THB within 365 days', () {
      const target = 100000.0;
      const initial = 0.0;
      const totalDays = 365;
      final remaining = target - initial;
      final neededDaily = remaining / totalDays;

      expect(neededDaily, closeTo(273.97, 0.01));
    });

    testWidgets('GoalCalculatorScreen renders title and frequency tabs correctly', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();
      final controller = ExpenseController(storage);

      await tester.pumpWidget(
        MaterialApp(
          home: GoalCalculatorScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('คำนวณเวลาเก็บออมอัจฉริยะ 🧮'), findsOneWidget);
      expect(find.text('ออมรายวัน'), findsOneWidget);
      expect(find.text('ออมรายเดือน'), findsOneWidget);
      expect(find.text('ออมรายปี'), findsOneWidget);
    });
  });
}
