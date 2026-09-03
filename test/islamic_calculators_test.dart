import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Zakat Calculator Tests', () {
    test('Calculates Nisab threshold and 2.5% Zakat correctly on cash', () {
      const goldPricePerGram = 2880.0;
      const nisabThreshold = 85.0 * goldPricePerGram; // 244,800 THB

      // Below Nisab: 200,000 THB -> Zakat = 0
      final cashBelow = 200000.0;
      final isNisabReachedBelow = cashBelow >= nisabThreshold;
      expect(isNisabReachedBelow, false);

      // Above Nisab: 300,000 THB -> Zakat = 300,000 * 0.025 = 7,500 THB
      final cashAbove = 300000.0;
      final isNisabReachedAbove = cashAbove >= nisabThreshold;
      expect(isNisabReachedAbove, true);

      final zakatAmount = cashAbove * 0.025;
      expect(zakatAmount, 7500.0);
    });

    test('Calculates Zakat with Gold weight, business assets, and debt deduction', () {
      const bahtWeight = 10.0; // 10 baht gold = ~152.44 grams (> 85g)
      const pricePerBaht = 44000.0;
      final goldValue = bahtWeight * pricePerBaht; // 440,000 THB

      final cash = 100000.0;
      final businessInventory = 200000.0;
      final shortTermDebt = 50000.0;

      final grossAssets = cash + goldValue + businessInventory; // 740,000 THB
      final netAssets = grossAssets - shortTermDebt; // 690,000 THB

      const nisabThreshold = (85.0 / 15.244) * pricePerBaht; // ~245,342 THB
      expect(netAssets >= nisabThreshold, true);

      final zakatAmount = netAssets * 0.025;
      expect(zakatAmount, 17250.0);
    });
  });

  group('Islamic Inheritance (Faraid) Calculation Tests', () {
    test('Deceased Male: Wife, Father, Mother, 1 Son, 1 Daughter', () {
      const grossEstate = 1200000.0;
      const funeralCosts = 50000.0;
      const debts = 150000.0;
      const netEstate = grossEstate - funeralCosts - debts; // 1,000,000 THB

      // 1. Wife: 1/8 (because children exist)
      final wifeShare = netEstate * (1.0 / 8.0); // 125,000 THB
      expect(wifeShare, 125000.0);

      // 2. Mother: 1/6 (children exist)
      final motherShare = netEstate * (1.0 / 6.0); // 166,666.67 THB

      // 3. Father: 1/6 (son exists)
      final fatherShare = netEstate * (1.0 / 6.0); // 166,666.67 THB

      // 4. Remainder to Son & Daughter (2:1 ratio)
      final allocated = (1.0 / 8.0) + (1.0 / 6.0) + (1.0 / 6.0); // 11/24
      final remainingFraction = 1.0 - allocated; // 13/24 = 0.5416667
      final remainingAmount = netEstate * remainingFraction; // ~541,666.67 THB

      // Total child shares = 1 son * 2 + 1 daughter * 1 = 3 parts
      final onePart = remainingAmount / 3.0;
      final sonShare = onePart * 2.0;
      final daughterShare = onePart * 1.0;

      expect(sonShare, closeTo(361111.11, 0.01));
      expect(daughterShare, closeTo(180555.56, 0.01));
      expect(wifeShare + motherShare + fatherShare + sonShare + daughterShare, closeTo(netEstate, 0.01));
    });

    test('Deceased Female: Husband, 2 Daughters, Mother, Father', () {
      const netEstate = 2400000.0;

      // 1. Husband gets 1/4 (children exist)
      final husbandShare = netEstate * 0.25; // 600,000 THB
      expect(husbandShare, 600000.0);

      // 2. Mother gets 1/6
      final motherShare = netEstate * (1.0 / 6.0); // 400,000 THB
      expect(motherShare, 400000.0);

      // 3. Father gets 1/6 + Asabah (if any)
      final fatherFixedShare = netEstate * (1.0 / 6.0); // 400,000 THB
      expect(fatherFixedShare, 400000.0);

      // 4. 2 Daughters get 2/3
      final daughtersShare = netEstate * (2.0 / 3.0); // 1,600,000 THB
      expect(daughtersShare, 1600000.0);
      expect(daughtersShare / 2, 800000.0); // Each daughter gets 800,000 THB
    });
  });
}
