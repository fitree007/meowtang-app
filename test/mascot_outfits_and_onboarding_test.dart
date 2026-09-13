import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_expense_tracker/widgets/meow_mascot_widget.dart';
import 'package:ai_expense_tracker/state/expense_controller.dart';
import 'package:ai_expense_tracker/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StorageService storage;
  late ExpenseController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
    await storage.init();
    controller = ExpenseController(storage);
    await Future.delayed(const Duration(milliseconds: 50));
  });

  group('Mascot Outfits & Catalog Tests', () {
    test('1. MascotCatalog.outfits contains 7 wearable outfits including original', () {
      expect(MascotCatalog.outfits.length, greaterThanOrEqualTo(7));
      final ids = MascotCatalog.outfits.map((o) => o.id).toList();
      expect(ids, contains('none'));
      expect(ids, contains('outfit_hoodie'));
      expect(ids, contains('outfit_suit'));
      expect(ids, contains('outfit_tshirt'));
      expect(ids, contains('outfit_sweater'));
      expect(ids, contains('outfit_sport'));
      expect(ids, contains('outfit_overalls'));
    });

    test('2. MascotCatalog.accessories contains all accessories with updated accurate icons', () {
      expect(MascotCatalog.accessories.length, greaterThanOrEqualTo(24));
      final ids = MascotCatalog.accessories.map((a) => a.id).toList();
      expect(ids, contains('gold_shades'));
      expect(ids, contains('bowtie'));
      expect(ids, contains('wings'));
      expect(ids, contains('scarf'));
      expect(ids, contains('crown'));
      expect(ids, contains('pen'));
    });

    test('3. Controller saves and updates mascot outfit correctly', () async {
      expect(controller.selectedMascotOutfit, 'none');

      await controller.updateMascot('cat_black', 'bowtie', outfit: 'outfit_suit');
      expect(controller.selectedMascotId, 'cat_black');
      expect(controller.selectedMascotAccessory, 'bowtie');
      expect(controller.selectedMascotOutfit, 'outfit_suit');
    });

    test('4. Onboarding revert methods toggle flags correctly', () async {
      // Complete initial steps
      await controller.completeLanguageSelection('th');
      expect(controller.hasSelectedInitialLanguage, isTrue);

      await controller.completeMascotOnboarding('cat_quill', 'pen', outfit: 'outfit_hoodie');
      expect(controller.hasChosenMascot, isTrue);
      expect(controller.selectedMascotOutfit, 'outfit_hoodie');

      await controller.completeThemeOnboarding('executive_navy', false);
      expect(controller.hasChosenTheme, isTrue);

      // Revert step by step
      await controller.revertToThemeOnboarding();
      expect(controller.hasChosenTheme, isFalse);

      await controller.revertToMascotOnboarding();
      expect(controller.hasChosenMascot, isFalse);

      await controller.revertToLanguageSelection();
      expect(controller.hasSelectedInitialLanguage, isFalse);
    });
  });
}
