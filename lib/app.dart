import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'state/expense_controller.dart';
import 'theme/meow_theme.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/permission_onboarding_screen.dart';
import 'widgets/seasonal_effect_overlay.dart';

import 'screens/language_selection_screen.dart';
import 'screens/mascot_onboarding_screen.dart';
import 'screens/theme_onboarding_screen.dart';
import 'screens/app_features_showcase_screen.dart';
import 'screens/app_guide_screen.dart';

class AiExpenseTrackerApp extends StatelessWidget {
  final ExpenseController controller;

  const AiExpenseTrackerApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final currentTheme = controller.currentTheme;
        final isDark = controller.isDarkMode;
        final baseTheme = currentTheme.toThemeData();

        return MaterialApp(
          title: controller.tr('app_name'),
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: baseTheme.copyWith(
            textTheme: GoogleFonts.promptTextTheme(
              baseTheme.textTheme.apply(
                bodyColor: currentTheme.textColor,
                displayColor: currentTheme.textColor,
              ),
            ),
          ),
          darkTheme: baseTheme.copyWith(
            textTheme: GoogleFonts.promptTextTheme(
              baseTheme.textTheme.apply(
                bodyColor: currentTheme.textColor,
                displayColor: currentTheme.textColor,
              ),
            ),
          ),
          builder: (context, child) {
            return SeasonalEffectOverlay(
              controller: controller,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: !controller.hasSelectedInitialLanguage
              ? LanguageSelectionScreen(
                  controller: controller,
                  onCompleted: () {},
                )
              : !controller.hasChosenMascot
                  ? MascotOnboardingScreen(
                      controller: controller,
                      onCompleted: () {},
                    )
                  : !controller.hasChosenTheme
                      ? ThemeOnboardingScreen(
                          controller: controller,
                          onCompleted: () {},
                        )
                      : !controller.hasCompletedShowcase
                          ? AppFeaturesShowcaseScreen(
                              controller: controller,
                              onCompleted: () {},
                            )
                          : MainNavigationScreen(controller: controller),
        );
      },
    );
  }
}
