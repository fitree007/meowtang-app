import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/services/slip_storage_service.dart';
import 'package:ai_expense_tracker/models/transaction_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Slip Storage & Gallery Cleanup Preservation Tests', () {
    late Directory tempDir;
    late File testSlipFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('slip_test_');
      testSlipFile = File('${tempDir.path}/kplus_slip_sample.jpg');
      testSlipFile.writeAsStringSync('dummy-image-data-for-slip');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('1. Persisting a slip image copies it to internal sandbox storage', () async {
      final persistentPath = await SlipStorageService.persistSlipImage(testSlipFile.path);
      expect(persistentPath, isNotEmpty);
      final persistentFile = File(persistentPath);
      expect(persistentFile.existsSync(), isTrue);
      expect(persistentFile.readAsStringSync(), 'dummy-image-data-for-slip');
    });

    test('2. Resolves slip file accurately even if original path is queried', () async {
      final persistentPath = await SlipStorageService.persistSlipImage(testSlipFile.path);
      final resolved = SlipStorageService.resolveSlipFile(persistentPath);
      expect(resolved, isNotNull);
      expect(resolved!.existsSync(), isTrue);
    });

    test('3. Resolving null or empty path returns null gracefully', () {
      expect(SlipStorageService.resolveSlipFile(null), isNull);
      expect(SlipStorageService.resolveSlipFile(''), isNull);
      expect(SlipStorageService.resolveSlipFile('   '), isNull);
    });

    test('4. Auto backup migration runs over transactions with external slips', () async {
      final tx = TransactionItem(
        id: 'tx_mig_1',
        title: 'โอนเงิน',
        amount: 500.0,
        type: TransactionType.expense,
        date: DateTime.now(),
        accountId: 'acc_cash',
        categoryId: 'cat_food',
        categoryName: 'อาหาร',
        slipImageUrl: testSlipFile.path,
      );

      TransactionItem? updatedTx;
      await SlipStorageService.autoBackupExistingSlips([tx], (updated) async {
        updatedTx = updated;
      });

      expect(updatedTx, isNotNull);
      expect(updatedTx!.slipImageUrl, isNot(testSlipFile.path));
      expect(File(updatedTx!.slipImageUrl!).existsSync(), isTrue);
    });
  });
}
