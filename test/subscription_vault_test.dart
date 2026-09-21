import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_expense_tracker/models/subscription_item.dart';
import 'package:ai_expense_tracker/models/transaction_item.dart';
import 'package:ai_expense_tracker/utils/format_utils.dart';
import 'package:ai_expense_tracker/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubscriptionItem Tests', () {
    test('Calculates monthly and yearly costs accurately across cycles', () {
      final monthly = SubscriptionItem(
        id: 'sub_1',
        name: 'Netflix',
        category: 'สตรีมมิ่ง & ดูหนัง',
        price: 169.0,
        billingCycle: 'monthly',
        firstChargeDate: DateTime(2026, 1, 1),
        nextBillingDate: DateTime(2026, 2, 1),
      );

      expect(monthly.monthlyCost, equals(169.0));
      expect(monthly.yearlyCost, equals(169.0 * 12.0));

      final yearly = SubscriptionItem(
        id: 'sub_2',
        name: 'Disney+ Yearly',
        category: 'สตรีมมิ่ง & ดูหนัง',
        price: 1200.0,
        billingCycle: 'yearly',
        firstChargeDate: DateTime(2026, 1, 1),
        nextBillingDate: DateTime(2027, 1, 1),
      );

      expect(yearly.monthlyCost, equals(100.0));
      expect(yearly.yearlyCost, equals(1200.0));
    });

    test('Serializes and deserializes correctly', () {
      final original = SubscriptionItem(
        id: 'sub_test',
        name: 'ChatGPT Plus',
        category: 'AI & ซอฟต์แวร์',
        price: 20.0,
        currency: 'USD',
        billingCycle: 'monthly',
        firstChargeDate: DateTime(2026, 3, 1),
        nextBillingDate: DateTime(2026, 4, 1),
        hasTrial: true,
        trialEndDate: DateTime(2026, 3, 8),
        paymentMethod: 'KBank ••1234',
        logoAssetPath: 'assets/icons/subscriptions/chatgpt.png',
        notes: 'Personal account',
        reminderDaysBefore: 3,
        isActive: true,
        enableReminder: true,
        accountId: 'acc_kbank_1',
        accountName: 'KBank ออมทรัพย์',
        autoRecordExpense: true,
        lastAutoRecordedDate: DateTime(2026, 3, 1),
      );

      final json = original.toJson();
      final restored = SubscriptionItem.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.category, equals(original.category));
      expect(restored.price, equals(original.price));
      expect(restored.currency, equals(original.currency));
      expect(restored.hasTrial, isTrue);
      expect(restored.logoAssetPath, equals(original.logoAssetPath));
      expect(restored.notes, equals('Personal account'));
      expect(restored.enableReminder, isTrue);
      expect(restored.accountId, equals('acc_kbank_1'));
      expect(restored.accountName, equals('KBank ออมทรัพย์'));
      expect(restored.autoRecordExpense, isTrue);
      expect(restored.lastAutoRecordedDate, equals(DateTime(2026, 3, 1)));
    });

    test('Encodes and decodes list correctly', () {
      final list = [
        SubscriptionItem(
          id: 'sub_1',
          name: 'Netflix',
          category: 'สตรีมมิ่ง',
          price: 169.0,
          firstChargeDate: DateTime(2026, 1, 1),
          nextBillingDate: DateTime(2026, 2, 1),
        ),
        SubscriptionItem(
          id: 'sub_2',
          name: 'Spotify',
          category: 'เพลง',
          price: 139.0,
          firstChargeDate: DateTime(2026, 1, 1),
          nextBillingDate: DateTime(2026, 2, 1),
        ),
      ];

      final encoded = SubscriptionItem.encodeList(list);
      final decoded = SubscriptionItem.decodeList(encoded);

      expect(decoded.length, equals(2));
      expect(decoded[0].name, equals('Netflix'));
      expect(decoded[1].name, equals('Spotify'));
    });

    test('Verifies presets collection has authentic entries', () {
      expect(SubscriptionPreset.popularPresets.isNotEmpty, isTrue);
      for (final p in SubscriptionPreset.popularPresets) {
        expect(p.name.isNotEmpty, isTrue);
        expect(p.logoAssetPath.startsWith('assets/icons/subscriptions/'), isTrue);
        expect(p.defaultPrice, greaterThan(0));
      }
    });

    test('StorageService persists and retrieves subscriptions', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();

      expect(storage.getSubscriptions(), isEmpty);

      final item = SubscriptionItem(
        id: 'sub_storage_1',
        name: 'AIS Fibre',
        category: 'มือถือ & เน็ตบ้าน',
        price: 599.0,
        firstChargeDate: DateTime(2026, 1, 1),
        nextBillingDate: DateTime(2026, 2, 1),
      );

      await storage.saveSubscriptions([item]);
      final loaded = storage.getSubscriptions();

      expect(loaded.length, equals(1));
      expect(loaded.first.name, equals('AIS Fibre'));
      expect(loaded.first.price, equals(599.0));
    });

    test('Auto-matches brand logos for AI and popular Thai services correctly', () {
      // AI Services
      expect(SubscriptionPreset.findMatchingPreset('Gemini Advanced')?.name, equals('Google Gemini Advanced'));
      expect(SubscriptionPreset.findMatchingPreset('perplexity pro')?.name, equals('Perplexity Pro'));
      expect(SubscriptionPreset.findMatchingPreset('cursor ide')?.name, equals('Cursor Pro'));
      expect(SubscriptionPreset.findMatchingPreset('deepl pro')?.name, equals('DeepL Pro'));
      expect(SubscriptionPreset.findMatchingPreset('capcut pro')?.name, equals('CapCut Pro'));
      expect(SubscriptionPreset.findMatchingPreset('elevenlabs voice')?.name, equals('ElevenLabs'));
      expect(SubscriptionPreset.findMatchingPreset('suno ai')?.name, equals('Suno AI'));

      // New AI Services & Near-Match Detection
      expect(SubscriptionPreset.findMatchingPreset('Higgsfield AI')?.name, equals('Higgsfield AI'));
      expect(SubscriptionPreset.findMatchingPreset('higg')?.name, equals('Higgsfield AI'));
      expect(SubscriptionPreset.findMatchingPreset('Kling AI')?.name, equals('Kling AI'));
      expect(SubscriptionPreset.findMatchingPreset('klin')?.name, equals('Kling AI'));
      expect(SubscriptionPreset.findMatchingPreset('cloud ai')?.name, equals('Claude Pro'));
      expect(SubscriptionPreset.findMatchingPreset('clou')?.name, equals('Claude Pro'));

      // Thai Services
      expect(SubscriptionPreset.findMatchingPreset('TrueID')?.name, equals('TrueID / TrueVisions Now'));
      expect(SubscriptionPreset.findMatchingPreset('ais play')?.name, equals('AIS PLAY'));
      expect(SubscriptionPreset.findMatchingPreset('bilibili')?.name, equals('Bilibili Premium'));
      expect(SubscriptionPreset.findMatchingPreset('ch3plus')?.name, equals('CH3 Plus Premium'));
      expect(SubscriptionPreset.findMatchingPreset('pandapro')?.name, equals('pandapro (Foodpanda)'));
      expect(SubscriptionPreset.findMatchingPreset('m flow')?.name, equals('Easy Pass / M-Flow'));

      // Global Streaming & Services
      expect(SubscriptionPreset.findMatchingPreset('netflix 4k')?.name, equals('Netflix'));
      expect(SubscriptionPreset.findMatchingPreset('yt premium')?.name, equals('YouTube Premium'));
    });

    test('SearchPresets autocomplete returns matching suggestions for Google-like dropdown', () {
      final klingResults = SubscriptionPreset.searchPresets('kli');
      expect(klingResults.any((p) => p.name == 'Kling AI'), isTrue);

      final higgsResults = SubscriptionPreset.searchPresets('hig');
      expect(higgsResults.any((p) => p.name == 'Higgsfield AI'), isTrue);

      final cloudResults = SubscriptionPreset.searchPresets('clou');
      expect(cloudResults.any((p) => p.name == 'Claude Pro'), isTrue);

      final netflixResults = SubscriptionPreset.searchPresets('netf');
      expect(netflixResults.any((p) => p.name == 'Netflix'), isTrue);
    });

    test('SubscriptionItem duration rules, cycles, and overview display work accurately', () {
      // 1. Ongoing / Never ends
      final ongoing = SubscriptionItem(
        id: 'sub_never',
        name: 'Ongoing Sub',
        category: 'อื่นๆ',
        price: 100.0,
        billingCycle: 'monthly',
        firstChargeDate: DateTime(2026, 1, 1),
        nextBillingDate: DateTime(2026, 2, 1),
        showInOverview: false,
        endRuleType: 'never',
      );
      expect(ongoing.showInOverview, isFalse);
      expect(ongoing.hasEnded, isFalse);
      expect(ongoing.remainingCycles, isNull);

      // 2. Fixed cycles
      final fixed = SubscriptionItem(
        id: 'sub_cycles',
        name: 'Installment Sub',
        category: 'อื่นๆ',
        price: 500.0,
        billingCycle: 'monthly',
        firstChargeDate: DateTime(2026, 1, 1),
        nextBillingDate: DateTime(2026, 4, 1),
        showInOverview: true,
        endRuleType: 'fixedCycles',
        totalCycles: 6,
        completedCycles: 4,
      );
      expect(fixed.showInOverview, isTrue);
      expect(fixed.remainingCycles, equals(2));
      expect(fixed.hasEnded, isFalse);

      final completedFixed = fixed.copyWith(completedCycles: 6);
      expect(completedFixed.remainingCycles, equals(0));
      expect(completedFixed.hasEnded, isTrue);

      // 3. Until date
      final futureDateSub = SubscriptionItem(
        id: 'sub_future',
        name: 'Future End Sub',
        category: 'อื่นๆ',
        price: 200.0,
        billingCycle: 'monthly',
        firstChargeDate: DateTime(2026, 1, 1),
        nextBillingDate: DateTime(2026, 5, 1),
        endRuleType: 'untilDate',
        endDate: DateTime(2026, 12, 31),
      );
      expect(futureDateSub.hasEnded, isFalse);

      final pastDateSub = futureDateSub.copyWith(endDate: DateTime(2025, 12, 31));
      expect(pastDateSub.hasEnded, isTrue);
    });

    test('Localizes dates properly and simplifies subscription notes', () {
      final date = DateTime(2026, 9, 21);
      // Thai format
      final thFull = FormatUtils.formatDate(date, isEnglish: false);
      expect(thFull, equals('21 ก.ย. 2569'));
      final thShort = FormatUtils.formatDate(date, isEnglish: false, shortYear: true);
      expect(thShort, equals('21 ก.ย. 69'));
      final thNoYear = FormatUtils.formatDate(date, isEnglish: false, showYear: false);
      expect(thNoYear, equals('21 ก.ย.'));

      // English format
      final enFull = FormatUtils.formatDate(date, isEnglish: true);
      expect(enFull, equals('21 Sep 2026'));
      final enShort = FormatUtils.formatDate(date, isEnglish: true, shortYear: true);
      expect(enShort, equals('21 Sep 26'));
      final enNoYear = FormatUtils.formatDate(date, isEnglish: true, showYear: false);
      expect(enNoYear, equals('21 Sep'));

      // Legacy subscription note parsing
      final tx = TransactionItem(
        id: 'tx_sub_1',
        title: 'จ่ายค่าบริการ YouTube Premium',
        amount: 1000.0,
        type: TransactionType.expense,
        categoryId: 'food',
        categoryName: 'อาหาร',
        accountId: 'cash',
        date: date,
        note: 'ชำระบริการ YouTube Premium ด้วยบัญชี เงินสด (Cash)',
      );
      expect(tx.cleanNote, equals('ชำระผ่าน: เงินสด (Cash)'));

      final txDirect = TransactionItem(
        id: 'tx_sub_2',
        title: 'จ่ายค่าบริการ Netflix',
        amount: 419.0,
        type: TransactionType.expense,
        categoryId: 'ent',
        categoryName: 'บันเทิง',
        accountId: 'credit',
        date: date,
        note: 'ชำระผ่าน: บัตรเครดิต',
      );
      expect(txDirect.cleanNote, equals('ชำระผ่าน: บัตรเครดิต'));
    });
  });
}
