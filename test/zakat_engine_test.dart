import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/services/zakat_engine.dart';

void main() {
  group('Livestock zakat (Shafi\'i)', () {
    test('goats', () {
      expect(ZakatEngine.livestock(LivestockKind.goat, 39).due, false);
      expect(ZakatEngine.livestock(LivestockKind.goat, 40).summary, contains('1 ตัว'));
      expect(ZakatEngine.livestock(LivestockKind.goat, 121).summary, contains('2 ตัว'));
      expect(ZakatEngine.livestock(LivestockKind.goat, 201).summary, contains('3 ตัว'));
      expect(ZakatEngine.livestock(LivestockKind.goat, 500).summary, contains('5 ตัว'));
    });

    test('cattle beyond 60 uses tabi\' (30) and musinnah (40)', () {
      expect(ZakatEngine.livestock(LivestockKind.cattle, 29).due, false);
      expect(ZakatEngine.livestock(LivestockKind.cattle, 35).summary, contains('1 ปี'));
      expect(ZakatEngine.livestock(LivestockKind.cattle, 45).summary, contains('2 ปี'));
      final c60 = ZakatEngine.livestock(LivestockKind.cattle, 60).summary;
      expect(c60, contains('(تبيع) 2 ตัว'));
      final c70 = ZakatEngine.livestock(LivestockKind.cattle, 70).summary;
      expect(c70, allOf(contains('(مسنة) 1 ตัว'), contains('(تبيع) 1 ตัว')));
      final c120 = ZakatEngine.livestock(LivestockKind.cattle, 125).summary;
      expect(c120, contains('(مسنة) 3 ตัว'));
    });

    test('camels', () {
      expect(ZakatEngine.livestock(LivestockKind.camel, 4).due, false);
      expect(ZakatEngine.livestock(LivestockKind.camel, 12).summary, contains('2 ตัว'));
      expect(ZakatEngine.livestock(LivestockKind.camel, 30).summary, contains('1 ปี'));
      expect(ZakatEngine.livestock(LivestockKind.camel, 100).summary, contains('3 ปี'));
      final c130 = ZakatEngine.livestock(LivestockKind.camel, 130).summary;
      expect(c130, allOf(contains('(حقة) 1 ตัว'), contains('(بنت لبون) 2 ตัว')));
      final c150 = ZakatEngine.livestock(LivestockKind.camel, 150).summary;
      expect(c150, contains('(حقة) 3 ตัว'));
    });
  });
}
