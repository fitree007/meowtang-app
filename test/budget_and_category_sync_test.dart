import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_expense_tracker/state/expense_controller.dart';
import 'package:ai_expense_tracker/services/storage_service.dart';
import 'package:ai_expense_tracker/models/transaction_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late ExpenseController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
    await storage.init();
    controller = ExpenseController(storage);
  });

  group('Budget Planning & Category Two-Way Synchronization Tests', () {
    test('1. Setting a new budget category automatically creates it in expenseCategories', () async {
      // Add a custom category budget: ค่าฟิตเนส
      await controller.setCategoryBudgets({
        'ค่าอาหาร': 5000.0,
        'ค่าฟิตเนส': 1500.0,
      });

      // Verify that ค่าฟิตเนส was auto-added to expense categories
      expect(controller.expenseCategories.any((c) => c.name == 'ค่าฟิตเนส'), isTrue);
      expect(controller.categoryBudgets.containsKey('ค่าฟิตเนส'), isTrue);
      expect(controller.categoryBudgets['ค่าฟิตเนส'], equals(1500.0));
    });

    test('2. Adding expense transaction immediately links with category budget in real-time', () async {
      // 1. Set budget for ค่าน้ำมัน = 2000 THB
      await controller.setCategoryBudgets({
        'ค่าน้ำมัน': 2000.0,
      });

      // 2. Add an expense transaction under ค่าน้ำมัน = 600 THB
      final tx = TransactionItem(
        id: 'tx_fuel_1',
        title: 'ค่าน้ำมัน',
        amount: 600.0,
        type: TransactionType.expense,
        date: DateTime.now(),
        accountId: 'acc_cash',
        categoryId: 'cat_fuel',
        categoryName: 'ค่าน้ำมัน',
      );
      controller.addTransaction(tx);

      // 3. Verify spent calculation
      final spent = controller.getSpentForCategoryThisMonth('ค่าน้ำมัน');
      expect(spent, equals(600.0));

      final remaining = controller.categoryBudgets['ค่าน้ำมัน']! - spent;
      expect(remaining, equals(1400.0));
    });

    test('3. Overbudget is accurately flagged when expenses exceed category budget', () async {
      await controller.setCategoryBudgets({
        'ค่าช้อปปิ้ง': 1000.0,
      });

      final tx = TransactionItem(
        id: 'tx_shop_1',
        title: 'ซื้อเสื้อผ้า',
        amount: 1500.0,
        type: TransactionType.expense,
        date: DateTime.now(),
        accountId: 'acc_cash',
        categoryId: 'cat_shop',
        categoryName: 'ค่าช้อปปิ้ง',
      );
      controller.addTransaction(tx);

      final spent = controller.getSpentForCategoryThisMonth('ค่าช้อปปิ้ง');
      final limit = controller.categoryBudgets['ค่าช้อปปิ้ง']!;
      expect(spent > limit, isTrue);
      expect(spent - limit, equals(500.0));
    });
  });
}
