import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_expense_tracker/services/storage_service.dart';
import 'package:ai_expense_tracker/state/expense_controller.dart';
import 'package:ai_expense_tracker/models/salary_auto_record_config.dart';
import 'package:ai_expense_tracker/models/transaction_item.dart';
import 'package:ai_expense_tracker/models/category_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Recurring Salary & Borrowing Categories Tests', () {
    late StorageService storage;
    late ExpenseController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
      await storage.init();
      controller = ExpenseController(storage);
      // Wait for initial async tasks
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('1. SalaryAutoRecordConfig toMap and fromMap serialization', () {
      final config = SalaryAutoRecordConfig(
        isEnabled: true,
        amount: 35000,
        dayOfMonth: 25,
        isLastDayOfMonth: false,
        accountId: 'acc_kbank',
        categoryId: 'cat_salary',
        note: 'เงินเดือน บจก. เทค',
        lastRecordedMonth: '2026-08',
      );

      final jsonStr = config.toJson();
      final parsed = SalaryAutoRecordConfig.fromJson(jsonStr);

      expect(parsed.isEnabled, isTrue);
      expect(parsed.amount, 35000);
      expect(parsed.dayOfMonth, 25);
      expect(parsed.isLastDayOfMonth, isFalse);
      expect(parsed.accountId, 'acc_kbank');
      expect(parsed.note, 'เงินเดือน บจก. เทค');
      expect(parsed.lastRecordedMonth, '2026-08');
    });

    test('2. Default categories include Borrow and Repay Debt', () {
      final cats = controller.categories;
      final borrowCat = cats.firstWhere((c) => c.id == 'cat_borrow');
      expect(borrowCat, isNotNull);
      expect(borrowCat.type, CategoryType.income);
      expect(borrowCat.name, contains('ยืม'));

      final repayCat = cats.firstWhere((c) => c.id == 'cat_repay_debt');
      expect(repayCat, isNotNull);
      expect(repayCat.type, CategoryType.expense);
      expect(repayCat.name, contains('คืนเงินยืม'));
    });

    test('3. Does NOT trigger recurring salary if isEnabled is false', () async {
      await controller.updateSalaryAutoRecordConfig(
        SalaryAutoRecordConfig(
          isEnabled: false,
          amount: 35000,
          dayOfMonth: 25,
          accountId: controller.accounts.first.id,
        ),
      );

      final now = DateTime(2026, 9, 25);
      final recorded = await controller.checkAndProcessRecurringSalary(overrideNow: now);

      expect(recorded, isFalse);
      expect(controller.transactions.isEmpty, isTrue);
    });

    test('4. Does NOT trigger before scheduled day of the month', () async {
      await controller.updateSalaryAutoRecordConfig(
        SalaryAutoRecordConfig(
          isEnabled: true,
          amount: 35000,
          dayOfMonth: 25,
          accountId: controller.accounts.first.id,
        ),
      );

      // Today is September 24 (before 25)
      final now = DateTime(2026, 9, 24);
      final recorded = await controller.checkAndProcessRecurringSalary(overrideNow: now);

      expect(recorded, isFalse);
      expect(controller.transactions.isEmpty, isTrue);
    });

    test('5. Automatically records salary on or after scheduled day and increases account balance', () async {
      final acc = controller.accounts.first;
      final initialBalance = acc.balance;

      await controller.updateSalaryAutoRecordConfig(
        SalaryAutoRecordConfig(
          isEnabled: true,
          amount: 35000,
          dayOfMonth: 25,
          accountId: acc.id,
          note: 'เงินเดือนประจำเดือน',
        ),
      );

      // Today is September 25
      final now = DateTime(2026, 9, 25);
      final recorded = await controller.checkAndProcessRecurringSalary(overrideNow: now);

      expect(recorded, isTrue);
      expect(controller.transactions.length, 1);

      final tx = controller.transactions.first;
      expect(tx.amount, 35000);
      expect(tx.type, TransactionType.income);
      expect(tx.accountId, acc.id);
      expect(tx.title, contains('เงินเดือน'));

      // Check account balance updated
      final updatedAcc = controller.accounts.firstWhere((a) => a.id == acc.id);
      expect(updatedAcc.balance, initialBalance + 35000);

      // Check config recorded month updated
      expect(controller.salaryConfig.lastRecordedMonth, '2026-09');
      expect(controller.lastAutoSalaryRecordedNotice, isNotNull);
    });

    test('6. Prevents duplicate recording in the same month', () async {
      final acc = controller.accounts.first;
      await controller.updateSalaryAutoRecordConfig(
        SalaryAutoRecordConfig(
          isEnabled: true,
          amount: 35000,
          dayOfMonth: 25,
          accountId: acc.id,
        ),
      );

      final day25 = DateTime(2026, 9, 25);
      final firstRecord = await controller.checkAndProcessRecurringSalary(overrideNow: day25);
      expect(firstRecord, isTrue);
      expect(controller.transactions.length, 1);

      // Next day: September 26
      final day26 = DateTime(2026, 9, 26);
      final secondRecord = await controller.checkAndProcessRecurringSalary(overrideNow: day26);
      expect(secondRecord, isFalse);
      // Still 1 transaction, no duplicate
      expect(controller.transactions.length, 1);
    });

    test('7. Handles isLastDayOfMonth correctly (e.g. Feb 28, Apr 30, Aug 31)', () async {
      final acc = controller.accounts.first;
      await controller.updateSalaryAutoRecordConfig(
        SalaryAutoRecordConfig(
          isEnabled: true,
          amount: 30000,
          isLastDayOfMonth: true,
          accountId: acc.id,
        ),
      );

      // April 29 -> not end of month
      final apr29 = DateTime(2026, 4, 29);
      expect(await controller.checkAndProcessRecurringSalary(overrideNow: apr29), isFalse);

      // April 30 -> end of month -> triggers!
      final apr30 = DateTime(2026, 4, 30);
      expect(await controller.checkAndProcessRecurringSalary(overrideNow: apr30), isTrue);
      expect(controller.transactions.length, 1);
      expect(controller.salaryConfig.lastRecordedMonth, '2026-04');
    });

    test('8. triggerManualSalaryRecord creates transaction immediately', () async {
      final acc = controller.accounts.first;
      await controller.updateSalaryAutoRecordConfig(
        SalaryAutoRecordConfig(
          isEnabled: true,
          amount: 40000,
          dayOfMonth: 28,
          accountId: acc.id,
          note: 'เงินเดือนทดสอบ',
        ),
      );

      final manualSuccess = await controller.triggerManualSalaryRecord();
      expect(manualSuccess, isTrue);
      expect(controller.transactions.length, 1);
      expect(controller.transactions.first.amount, 40000);
      expect(controller.transactions.first.title, contains('เงินเดือน'));
    });
  });
}
