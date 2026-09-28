import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/state/expense_controller.dart';
import 'package:ai_expense_tracker/services/storage_service.dart';
import 'package:ai_expense_tracker/services/thai_bank_detector.dart';
import 'package:ai_expense_tracker/models/account_item.dart';
import 'package:ai_expense_tracker/models/transaction_item.dart';
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
    // 4. Test ensureCreditCardAccountExists creates CREDIT account with credit card bankCode
    final ccAcc = controller.ensureCreditCardAccountExists();
    expect(ccAcc.bankCode, equals('CREDIT'));
    expect(ccAcc.name, equals('บัตรเครดิต'));
    expect(controller.accounts.any((a) => a.bankCode == 'CREDIT'), isTrue);

    // 5. Test detectBankCode detects CREDIT from credit card tags and names
    final txWithTag = TransactionItem(
      id: 'tx_cc_1',
      title: 'จ่ายค่าอาหาร',
      amount: 500,
      date: DateTime.now(),
      type: TransactionType.expense,
      categoryId: 'food',
      categoryName: 'อาหาร',
      accountId: 'acc_credit',
      tags: ['บัตรเครดิต'],
    );
    expect(ThaiBankDetector.detectBankCode(txWithTag, controller.accounts), equals('CREDIT'));

    final txWithName = TransactionItem(
      id: 'tx_cc_2',
      title: 'ชำระยอดบัตร',
      amount: 1500,
      date: DateTime.now(),
      type: TransactionType.expense,
      categoryId: 'shopping',
      categoryName: 'ช้อปปิ้ง',
      accountId: 'acc_credit',
      bankName: 'บัตรเครดิต',
    );
    expect(ThaiBankDetector.detectBankCode(txWithName, controller.accounts), equals('CREDIT'));
  });
}
