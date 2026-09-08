import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/state/expense_controller.dart';
import 'package:ai_expense_tracker/services/storage_service.dart';
import 'package:ai_expense_tracker/services/thai_bank_detector.dart';
import 'package:ai_expense_tracker/models/account_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Account Separation Test: getOrCreateAccountForBank automatically finds or creates bank account', () async {
    final storage = StorageService();
    await storage.init();
    final controller = ExpenseController(storage);
    controller.loadData();

    // 1. Initially has default accounts (including IBANK)
    final ibankAcc = controller.getOrCreateAccountForBank('IBANK', bankName: 'ธนาคารอิสลามแห่งประเทศไทย');
    expect(ibankAcc.bankCode, equals('IBANK'));
    expect(ibankAcc.name, contains('อิสลาม'));

    // 2. Test auto-creating an account for another bank not yet created (e.g. UOB)
    final uobAcc = controller.getOrCreateAccountForBank('UOB', bankName: 'ธนาคารยูโอบี');
    expect(uobAcc.bankCode, equals('UOB'));
    expect(controller.accounts.any((a) => a.bankCode == 'UOB'), isTrue);

    // 3. Test ThaiBankDetector.detectCodeFromBankName
    expect(ThaiBankDetector.detectCodeFromBankName('ธนาคารอิสลามแห่งประเทศไทย'), equals('IBANK'));
    expect(ThaiBankDetector.detectCodeFromBankName('กสิกรไทย (K PLUS)'), equals('KBANK'));
    expect(ThaiBankDetector.detectCodeFromBankName('กรุงไทย NEXT'), equals('KTB'));
    expect(ThaiBankDetector.detectCodeFromBankName('เป๋าตัง (PaoTang)'), equals('PAOTANG'));
  });
}
