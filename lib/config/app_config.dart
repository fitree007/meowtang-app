/// Global App Configuration and Edition Management
///
/// Compile-time flags:
/// - APP_EDITION=creator : Full unlocked 100% Lifetime VIP for author/creator
/// - APP_EDITION=playstore : Freemium edition with Google Play IAP, 20-slip monthly quota, and feature locks
class AppConfig {
  /// Raw edition string from compile-time environment
  static const String _rawEdition = String.fromEnvironment(
    'APP_EDITION',
    defaultValue: 'creator',
  );

  /// Optional runtime override (primarily for unit tests)
  static String? overrideEdition;

  /// True if building for the author/creator (Full Unlimited VIP)
  static bool get isCreatorEdition => (overrideEdition ?? _rawEdition).toLowerCase() == 'creator';

  /// True if building for Google Play Store (Freemium with In-App Purchases)
  static bool get isPlayStoreEdition => !isCreatorEdition;

  /// Welcome bonus free slip scans granted upon first app install
  static const int welcomeBonusSlips = 100;

  /// Free slip scan quota per calendar month for non-VIP users
  static const int freeSlipsPerMonth = 15;

  /// Pricing display constants (in Thai Baht)
  static const int themePriceThb = 29;
  static const int iconPriceThb = 10;
  static const int monthlySubPriceThb = 39;
  static const int yearlySubPriceThb = 199;
  static const int lifetimePriceThb = 390;

  /// 30-Second theme trial duration
  static const int themeTrialSeconds = 30;

  /// Built-in Free Theme IDs that never require payment
  static const Set<String> defaultFreeThemeIds = {
    'default_light',
    'executive_navy',
    'emerald_wealth',
  };

  /// Built-in Free Mascot / Character IDs
  static const Set<String> defaultFreeMascotIds = {
    'cat_quill',
    'cat_black',
    'cat_calico',
    'cat_muslim',
  };
}
