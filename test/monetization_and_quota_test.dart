import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_expense_tracker/services/storage_service.dart';
import 'package:ai_expense_tracker/state/expense_controller.dart';
import 'package:ai_expense_tracker/config/app_config.dart';
import 'package:ai_expense_tracker/models/transaction_item.dart';
import 'package:ai_expense_tracker/services/slip_auto_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Monetization, Quota & Theme Test Drive Tests', () {
    late StorageService storage;
    late ExpenseController controller;

    setUp(() async {
      AppConfig.overrideEdition = 'playstore';
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
      await storage.init();
      controller = ExpenseController(storage);
    });

    tearDown(() {
      AppConfig.overrideEdition = null;
    });

    test('1. AppConfig pricing and quota constants are valid', () {
      expect(AppConfig.welcomeBonusSlips, 100);
      expect(AppConfig.freeSlipsPerMonth, 15);
      expect(AppConfig.themePriceThb, 29);
      expect(AppConfig.iconPriceThb, 10);
      expect(AppConfig.monthlySubPriceThb, 39);
      expect(AppConfig.yearlySubPriceThb, 199);
      expect(AppConfig.lifetimePriceThb, 390);
      expect(AppConfig.themeTrialSeconds, 30);
    });

    test('2. Default free themes are always unlocked for any user', () {
      expect(controller.isThemeUnlocked('default_light'), isTrue);
      expect(controller.isThemeUnlocked('executive_navy'), isTrue);
      expect(controller.isThemeUnlocked('emerald_wealth'), isTrue);
    });

    test('3. Theme 30-Second Test Drive activation, preview, and cancellation', () {
      expect(controller.isThemeInTestDrive, isFalse);
      expect(controller.testDriveRemainingSeconds, 0);

      const testThemeId = 'cyber_neon';
      controller.startThemeTestDrive(testThemeId);

      expect(controller.isThemeInTestDrive, isTrue);
      expect(controller.testDriveThemeId, testThemeId);
      expect(controller.testDriveRemainingSeconds, 30);
      expect(controller.currentThemeId, testThemeId);
      expect(controller.isThemeUnlocked(testThemeId), isTrue);

      // Cancel test drive
      controller.cancelThemeTestDrive();
      expect(controller.isThemeInTestDrive, isFalse);
      expect(controller.testDriveThemeId, isNull);
      expect(controller.testDriveRemainingSeconds, 0);
    });

    test('4. Purchasing a theme permanently unlocks it', () async {
      const themeId = 'sakura_bloom';
      await controller.purchaseTheme(themeId);

      final purchased = storage.getPurchasedThemes();
      expect(purchased.contains(themeId), isTrue);
      expect(controller.isThemeUnlocked(themeId), isTrue);
    });

    test('5. Purchasing an icon permanently unlocks it', () async {
      const iconId = 'fox_smart';
      await controller.purchaseIcon(iconId);

      final purchased = storage.getPurchasedIcons();
      expect(purchased.contains(iconId), isTrue);
      expect(controller.isMascotUnlocked(iconId), isTrue);
    });

    test('6. Initial device slips import (current & previous month) is quota-exempt (stays 0/15), future slips consume quota', () async {
      expect(controller.currentMonthSlipCount, 0);
      expect(controller.canImportMoreSlips, isTrue);

      final now = DateTime.now();
      final prevMonthDate = DateTime(now.year, now.month - 1, 15);

      // 1. Initial device scan imports historical slips (both current & previous month)
      // These are quota-exempt (isInitialImport: true)
      await controller.recordSlipImported(slipDate: prevMonthDate, isInitialImport: true);
      await controller.recordSlipImported(slipDate: now, isInitialImport: true);
      await controller.recordSlipImported(slipDate: now, isInitialImport: true);

      // Monthly quota remains untouched at 0/15!
      expect(controller.currentMonthSlipCount, 0);
      expect(controller.canImportMoreSlips, isTrue);

      // 2. Incoming new / future slips (isInitialImport: false) now consume the 0/15 quota
      for (int i = 0; i < 15; i++) {
        expect(controller.canImportMoreSlips, isTrue);
        await controller.recordSlipImported(slipDate: now, isInitialImport: false);
      }

      // Quota is now full (15/15)
      expect(controller.currentMonthSlipCount, 15);
      expect(controller.canImportMoreSlips, isFalse);

      // 3. A slip dated in previous month does NOT affect current month's quota
      final prevCountBefore = controller.currentMonthSlipCount;
      await controller.recordSlipImported(slipDate: prevMonthDate, isInitialImport: false);
      expect(controller.currentMonthSlipCount, prevCountBefore);
    });

    test('7. SlipAutoSyncService only scans current month and previous month', () {
      final now = DateTime.now();
      final startOfPrevMonth = SlipAutoSyncService.getStartOfPreviousMonth(now);

      // Current month slip -> Allowed
      expect(SlipAutoSyncService.isWithinCurrentOrPreviousMonth(now, now), isTrue);

      // Previous month slip -> Allowed
      expect(SlipAutoSyncService.isWithinCurrentOrPreviousMonth(startOfPrevMonth, now), isTrue);

      // 1 millisecond before previous month -> Rejected!
      final justBeforePrevMonth = startOfPrevMonth.subtract(const Duration(milliseconds: 1));
      expect(SlipAutoSyncService.isWithinCurrentOrPreviousMonth(justBeforePrevMonth, now), isFalse);

      // Two months ago slip -> Rejected!
      final twoMonthsAgo = DateTime(now.year, now.month - 2, 15);
      expect(SlipAutoSyncService.isWithinCurrentOrPreviousMonth(twoMonthsAgo, now), isFalse);
    });

    test('8. VIP subscription status grants unlimited access', () async {
      await controller.setPremiumStatus(true, tier: 'lifetime');
      expect(controller.isPremium, isTrue);
      expect(controller.canImportMoreSlips, isTrue);
      expect(controller.isThemeUnlocked('any_premium_theme_id'), isTrue);
      expect(controller.isMascotUnlocked('any_mascot_id'), isTrue);
    });

    test('9. Undo (restoreTransaction) successfully restores deleted slip transaction', () async {
      final now = DateTime.now();
      final sampleSlipTx = TransactionItem(
        id: 'tx_slip_123',
        title: 'โอนเงินสลิปทดสอบ',
        amount: 500.0,
        date: now,
        type: TransactionType.expense,
        accountId: 'acc_cash',
        categoryId: 'cat_food',
        categoryName: 'อาหาร',
        slipImageUrl: '/path/to/slip_test.jpg',
        slipRefId: 'REF-TEST-999',
      );

      // 1. Add transaction
      final added = await controller.addTransaction(sampleSlipTx);
      expect(added, isTrue);
      expect(controller.transactions.any((t) => t.id == 'tx_slip_123'), isTrue);

      // Also simulate registering it in importedSlipIdentifiers
      await storage.addImportedSlipIdentifiers(['REF-TEST-999', 'slip_test.jpg']);

      // 2. Delete transaction (user swipe or tap delete)
      await controller.deleteTransaction('tx_slip_123');
      expect(controller.transactions.any((t) => t.id == 'tx_slip_123'), isFalse);

      // 3. User taps "Undo (เลิกทำ)" -> restoreTransaction must succeed
      await controller.restoreTransaction(sampleSlipTx);
      expect(controller.transactions.any((t) => t.id == 'tx_slip_123'), isTrue);
      expect(controller.transactions.firstWhere((t) => t.id == 'tx_slip_123').amount, 500.0);
    });

    test('10. Monthly slip quota is strictly 15/month and consumed when manual slip is recorded', () async {
      expect(controller.currentMonthSlipCount, 0);
      expect(controller.maxFreeSlipsPerMonth, 15);
      expect(controller.canImportMoreSlips, isTrue);

      // Simulate recording a slip import via '+' button or manual entry
      final slipDate = DateTime.now();
      await controller.recordSlipImported(slipDate: slipDate);
      expect(controller.currentMonthSlipCount, 1);
      expect(controller.canImportMoreSlips, isTrue);

      // Simulate consuming until 15 slips
      for (int i = 2; i <= 15; i++) {
        await controller.recordSlipImported(slipDate: slipDate);
      }
      expect(controller.currentMonthSlipCount, 15);
      expect(controller.canImportMoreSlips, isFalse);

      // Attempting to record beyond 15 does not increment
      await controller.recordSlipImported(slipDate: slipDate);
      expect(controller.currentMonthSlipCount, 15);
    });

    test('11. Yearly income & expense calculates strictly per calendar year and resets naturally in next year', () async {
      // Add transactions in 2026
      await controller.addTransaction(TransactionItem(
        id: 'tx_2026_income',
        title: 'เงินเดือน 2569',
        amount: 35000.0,
        date: DateTime(2026, 6, 1),
        type: TransactionType.income,
        accountId: 'acc_cash',
        categoryId: 'cat_salary',
        categoryName: 'เงินเดือน',
      ));

      await controller.addTransaction(TransactionItem(
        id: 'tx_2026_expense',
        title: 'ค่าเช่าห้อง 2569',
        amount: 8000.0,
        date: DateTime(2026, 6, 5),
        type: TransactionType.expense,
        accountId: 'acc_cash',
        categoryId: 'cat_rent',
        categoryName: 'ค่าที่พัก',
      ));

      expect(controller.getYearlyIncome(2026), 35000.0);
      expect(controller.getYearlyExpense(2026), 8000.0);

      // In year 2027 (Next Year): Should start cleanly from 0.00
      expect(controller.getYearlyIncome(2027), 0.0);
      expect(controller.getYearlyExpense(2027), 0.0);

      // When adding transaction in 2027
      await controller.addTransaction(TransactionItem(
        id: 'tx_2027_income',
        title: 'เงินเดือน 2570',
        amount: 40000.0,
        date: DateTime(2027, 1, 1),
        type: TransactionType.income,
        accountId: 'acc_cash',
        categoryId: 'cat_salary',
        categoryName: 'เงินเดือน',
      ));

      expect(controller.getYearlyIncome(2027), 40000.0);
      expect(controller.getYearlyExpense(2027), 0.0);
      // 2026 remains unchanged
      expect(controller.getYearlyIncome(2026), 35000.0);
    });
  });
}
