import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_expense_tracker/services/storage_service.dart';
import 'package:ai_expense_tracker/state/expense_controller.dart';
import 'package:ai_expense_tracker/theme/app_theme_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Themes & 3 Streamlined Categories Tests', () {
    late StorageService storage;
    
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
      await storage.init();
          });

    test('1. Has 18 themes across 3 categories (6 Classic, 6 Minimal & Liquid Glass, 6 Cute & Pastel)', () {
      final classicThemes = AppThemePresets.getThemesByCategory(ThemeCategory.classic);
      expect(classicThemes.length, 6);

      final minimalThemes = AppThemePresets.getThemesByCategory(ThemeCategory.minimal);
      expect(minimalThemes.length, 6);

      // Verify Liquid Glass themes are in minimal and marked isGlass
      final glassCrystal = AppThemePresets.getById('liquid_glass_crystal');
      expect(glassCrystal.category, ThemeCategory.minimal);
      expect(glassCrystal.isGlass, isTrue);

      final cuteThemes = AppThemePresets.getThemesByCategory(ThemeCategory.cute);
      expect(cuteThemes.length, 6);

      expect(AppThemePresets.allThemes.length, 18);
    });

    test('2. Every theme supports both Light and Dark mode seamlessly', () {
      for (final theme in AppThemePresets.allThemes) {
        final light = theme.copyWithMode(false);
        expect(light.isDark, isFalse);
        expect(light.scaffoldBackground, equals(theme.lightScaffoldBackground));

        final dark = theme.copyWithMode(true);
        expect(dark.isDark, isTrue);
        expect(dark.scaffoldBackground, equals(theme.darkScaffoldBackground));
      }
    });
  });
}
