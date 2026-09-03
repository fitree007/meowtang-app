import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_expense_tracker/models/transaction_item.dart';
import 'package:ai_expense_tracker/services/storage_service.dart';
import 'package:ai_expense_tracker/state/expense_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Calendar & Dashboard 3.5s Undo Countdown and Deletion Tests', () {
    late StorageService storage;
    late ExpenseController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
      await storage.init();
      controller = ExpenseController(storage);
    });

    test('1. Adding, deleting and restoring transactions works consistently for Calendar & Dashboard', () async {
      final tx = TransactionItem(
        id: 'tx_cal_01',
        title: 'ซื้อของเซเว่น',
        amount: 85.0,
        type: TransactionType.expense,
        date: DateTime(2026, 8, 31, 10, 30),
        accountId: 'acc_cash',
        categoryId: 'cat_food',
        categoryName: 'อาหาร',
      );

      await controller.addTransaction(tx);
      expect(controller.allTransactions.length, 1);

      // Delete (simulating 3.5s countdown beginning)
      await controller.deleteTransaction(tx.id);
      expect(controller.allTransactions.length, 0);

      // Restore via Undo button
      await controller.restoreTransaction(tx);
      expect(controller.allTransactions.length, 1);
      expect(controller.allTransactions.first.title, 'ซื้อของเซเว่น');
    });
  });
}
