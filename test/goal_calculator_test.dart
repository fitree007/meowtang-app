import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_expense_tracker/models/saving_goal_item.dart';
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

      expect(find.text('คำนวณเวลาเก็บออม'), findsOneWidget);
      expect(find.text('⏳ ใช้เวลานานแค่ไหน?'), findsOneWidget);
      expect(find.text('💰 ต้องออมเท่าไหร่?'), findsOneWidget);
      expect(find.text('เดือน'), findsOneWidget);
      // 100,000 at 5,000/month from 0 => 20 months
      expect(find.text('1 ปี 8 เดือน'), findsOneWidget);
    });
  });

  group('GoalMath', () {
    test('simulate without returns', () {
      final r = GoalMath.simulate(target: 100000, start: 10000, perPeriod: 5000, period: SavePeriod.month);
      expect(r.periods, 18);
      expect(r.deposited, 90000);
    });

    test('simulate never reaches when saving nothing', () {
      final r = GoalMath.simulate(target: 1000, start: 0, perPeriod: 0, period: SavePeriod.day);
      expect(r.reachable, false);
    });

    test('required per period matches simulation, with and without returns', () {
      for (final pct in [0.0, 5.0]) {
        final need = GoalMath.requiredPerPeriod(
          target: 120000,
          start: 0,
          periods: 24,
          period: SavePeriod.month,
          annualPct: pct,
        );
        final r = GoalMath.simulate(
          target: 120000,
          start: 0,
          perPeriod: need + 0.01,
          period: SavePeriod.month,
          annualPct: pct,
        );
        expect(r.periods, 24);
      }
    });

    test('saving goal counts a started month as a whole month', () {
      final deadline = DateTime(2027, 10, 6);
      expect(SavingGoalItem.periodsBetween(DateTime(2026, 10, 6, 15, 30), deadline, 'month'), 12);
      expect(SavingGoalItem.periodsBetween(DateTime(2026, 10, 7, 9), deadline, 'month'), 12);
      expect(SavingGoalItem.periodsBetween(DateTime(2026, 11, 6), deadline, 'month'), 11);
      expect(SavingGoalItem.periodsBetween(DateTime(2027, 9, 30), deadline, 'week'), 1);
      expect(SavingGoalItem.dateAfterPeriods(DateTime(2026, 1, 31), 1, 'month'), DateTime(2026, 2, 28));
    });

    test('month arithmetic clamps to the last day of month', () {
      expect(GoalMath.dateAfter(DateTime(2026, 1, 31), SavePeriod.month, 1), DateTime(2026, 2, 28));
      expect(GoalMath.dateAfter(DateTime(2026, 11, 15), SavePeriod.month, 3), DateTime(2027, 2, 15));
    });
  });
}
