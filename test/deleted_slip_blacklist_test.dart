import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_expense_tracker/models/transaction_item.dart';
import 'package:ai_expense_tracker/services/storage_service.dart';
import 'package:ai_expense_tracker/services/duplicate_slip_checker.dart';
import 'package:ai_expense_tracker/state/expense_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Deleted Slip Blacklist & Duplicate Prevention Tests', () {
    late StorageService storage;
    late ExpenseController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
      await storage.init();
      controller = ExpenseController(storage);
    });

    test('1. Deleting a slip transaction automatically adds its identifiers to deleted blacklist', () async {
      final tx = TransactionItem(
        id: 'tx_123',
        title: 'โอนเงิน กสิกรไทย',
        amount: 250.0,
        type: TransactionType.expense,
        date: DateTime(2026, 8, 31, 14, 30),
        accountId: 'acc_kbank',
        categoryId: 'cat_food',
        categoryName: 'อาหาร',
        slipImageUrl: '/storage/emulated/0/DCIM/Camera/1740948593482.jpg',
        slipRefId: 'KBANK0123456789',
        bankName: 'KBANK',
      );

      await controller.addTransaction(tx);
      expect(controller.allTransactions.length, 1);

      // Now delete the transaction
      await controller.deleteTransaction(tx.id);
      expect(controller.allTransactions.length, 0);

      // Verify blacklist contains the slip
      final deletedList = storage.getDeletedSlips();
      expect(deletedList.contains('/storage/emulated/0/dcim/camera/1740948593482.jpg'), isTrue);
      expect(deletedList.contains('1740948593482.jpg'), isTrue);
      expect(deletedList.contains('kbank0123456789'), isTrue);
    });

    test('2. DuplicateSlipChecker rejects deleted slip on pull-to-refresh / scan', () async {
      final deletedList = [
        '/storage/emulated/0/dcim/camera/1740948593482.jpg',
        '1740948593482.jpg',
        'kbank0123456789',
      ];

      // Even though existingTransactions is empty, isDuplicate must return TRUE
      final isDup1 = DuplicateSlipChecker.isDuplicate(
        existingTransactions: [],
        deletedSlipIdentifiers: deletedList,
        filePath: '/storage/emulated/0/DCIM/Camera/1740948593482.jpg',
        fileName: '1740948593482.jpg',
        refId: 'KBANK0123456789',
      );
      expect(isDup1, isTrue, reason: 'Must be blocked by deleted slip blacklist');

      // Another slip that is not deleted should return FALSE
      final isDup2 = DuplicateSlipChecker.isDuplicate(
        existingTransactions: [],
        deletedSlipIdentifiers: deletedList,
        filePath: '/storage/emulated/0/DCIM/Camera/9999999999999.jpg',
        fileName: '9999999999999.jpg',
        refId: 'SCB9999999999',
      );
      expect(isDup2, isFalse, reason: 'New slip should be allowed');
    });

    test('3. Restoring transaction via restoreTransaction removes it from blacklist', () async {
      final tx = TransactionItem(
        id: 'tx_restore_test',
        title: 'โอนเงิน เป๋าตัง',
        amount: 500.0,
        type: TransactionType.expense,
        date: DateTime(2026, 8, 31, 14, 30),
        accountId: 'acc_wallet',
        categoryId: 'cat_food',
        categoryName: 'อาหาร',
        slipImageUrl: '/storage/emulated/0/Pictures/PaoTang/paotang_01.jpg',
        slipRefId: 'PAOTANG12345',
        bankName: 'PaoTang',
      );

      await controller.addTransaction(tx);
      await controller.deleteTransaction(tx.id);
      expect(storage.getDeletedSlips().contains('paotang_01.jpg'), isTrue);

      // Now user presses Undo / Restore
      await controller.restoreTransaction(tx);
      expect(controller.allTransactions.length, 1);
      expect(storage.getDeletedSlips().contains('paotang_01.jpg'), isFalse);
    });

    test('4. Imported slip registry prevents duplicate slip from re-importing', () async {
      await storage.addImportedSlipIdentifiers([
        '/storage/emulated/0/pictures/paotang/slip_12.jpg',
        'slip_12.jpg',
      ]);

      final isDup = DuplicateSlipChecker.isDuplicate(
        existingTransactions: [],
        importedSlipIdentifiers: storage.getImportedSlipIdentifiers(),
        filePath: '/storage/emulated/0/Pictures/PaoTang/slip_12.jpg',
        fileName: 'slip_12.jpg',
      );
      expect(isDup, isTrue, reason: 'Must be blocked by imported slip registry');
    });

    test('5. Thai filename matches successfully even when stored with slip_HASH_ prefix', () async {
      final tx = TransactionItem(
        id: 'tx_thai_name',
        title: 'โอนเงิน กสิกรไทย',
        amount: 300.0,
        type: TransactionType.expense,
        date: DateTime(2026, 8, 31, 14, 30),
        accountId: 'acc_kbank',
        categoryId: 'cat_food',
        categoryName: 'อาหาร',
        slipImageUrl: '/data/user/0/com.afitree.rizqi/files/saved_slips/slip_123456_สลิป_โอนเงิน.jpg',
        slipRefId: 'SLIP-12345',
        bankName: 'KBANK',
      );

      final isDup = DuplicateSlipChecker.isDuplicate(
        existingTransactions: [tx],
        filePath: '/storage/emulated/0/DCIM/Camera/สลิป_โอนเงิน.jpg',
        fileName: 'สลิป_โอนเงิน.jpg',
      );
      expect(isDup, isTrue, reason: 'Must match Thai filename despite prefix');
    });
  });
}
