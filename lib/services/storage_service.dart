import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_item.dart';
import '../models/account_item.dart';
import '../models/category_item.dart';
import '../models/saving_goal_item.dart';
import '../models/salary_auto_record_config.dart';
import '../config/app_config.dart';

class StorageService {
  static const String _keyTransactions = 'rizqi_transactions_v2';
  static const String _keyAccounts = 'rizqi_accounts_v2';
  static const String _keyCategories = 'rizqi_categories_v2';
  static const String _keyKeywordRules = 'rizqi_keyword_rules_v2';
  static const String _keyIsDarkMode = 'rizqi_is_dark_mode';
  static const String _keyPermissionConfigured = 'rizqi_perm_configured';
  static const String _keyBankAlbum = 'rizqi_perm_bank_album';
  static const String _keyInstalledApps = 'rizqi_perm_installed_apps';
  static const String _keyMainAlbum = 'rizqi_perm_main_album';
  static const String _keyMascotId = 'rizqi_mascot_id';
  static const String _keyMascotAccessory = 'rizqi_mascot_accessory';
  static const String _keyHasChosenMascot = 'rizqi_has_chosen_mascot';
  static const String _keyHasSeenAppGuide = 'rizqi_has_seen_app_guide';
  static const String _keyAppGuideLanguage = 'rizqi_guide_language';
  static const String _keyHasSeenSpotlightTour = 'rizqi_has_seen_spotlight_tour';
  static const String _keyAppLanguage = 'rizqi_app_language';
  static const String _keyHasSelectedInitialLanguage = 'rizqi_has_selected_initial_lang';
  static const String _keyMonthlySalary = 'rizqi_monthly_salary';
  static const String _keyCategoryBudgets = 'rizqi_category_budgets_json';
  static const String _keyIsBudgetPlanEnabled = 'rizqi_budget_plan_enabled';
  static const String _keyBudgetCycle = 'rizqi_budget_cycle';
  static const String _keyCustomAvatarPath = 'rizqi_custom_avatar_path';
  static const String _keyIsCustomAvatarEnabled = 'rizqi_custom_avatar_enabled';
  static const String _keySavingGoals = 'rizqi_saving_goals_v1';
  static const String _keyStreakDays = 'rizqi_streak_days';
  static const String _keyLastRecordedDate = 'rizqi_last_recorded_date';
  static const String _keyUnlockedAccessories = 'rizqi_unlocked_accessories';
  static const String _keyCurrentThemeId = 'rizqi_theme_id_v2';
  static const String _keyUnlockedThemes = 'rizqi_unlocked_themes_v2';
  static const String _keyHasChosenTheme = 'rizqi_has_chosen_theme_v1';
  static const String _keyHasCompletedShowcase = 'rizqi_has_completed_showcase_v1';
  static const String _keySeasonalEffects = 'rizqi_seasonal_effects_enabled_v1';
  static const String _keySavedTags = 'rizqi_saved_hashtags_v1';
  static const String _keyDeletedSlips = 'rizqi_deleted_slips_blacklist_v1';
  static const String _keyImportedSlips = 'rizqi_imported_slips_registry_v1';
  static const String _keyIsPremium = 'meow_is_premium_v1';
  static const String _keyPremiumTier = 'meow_premium_tier_v1';
  static const String _keyPremiumExpiry = 'meow_premium_expiry_v1';
  static const String _keyPurchasedThemes = 'meow_purchased_themes_v1';
  static const String _keyPurchasedIcons = 'meow_purchased_icons_v1';
  static const String _keySlipQuotaMonth = 'meow_slip_quota_month_v1';
  static const String _keySlipQuotaCount = 'meow_slip_quota_count_v1';
  static const String _keyWelcomeBonusSlips = 'meow_welcome_bonus_slips_v1';
  static const String _keyInitialDeviceScanCompleted = 'meow_initial_device_scan_completed_v2';
  static const String _keySalaryAutoRecordConfig = 'meow_salary_auto_record_config_v1';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // INITIAL LANGUAGE SELECTION ON FIRST LAUNCH
  bool hasSelectedInitialLanguage() {
    return _prefs.getBool(_keyHasSelectedInitialLanguage) ?? false;
  }

  Future<void> setHasSelectedInitialLanguage(bool val) async {
    await _prefs.setBool(_keyHasSelectedInitialLanguage, val);
  }

  // APP LANGUAGE (TH / EN)
  String getAppLanguage() {
    return _prefs.getString(_keyAppLanguage) ?? 'th';
  }

  Future<void> saveAppLanguage(String lang) async {
    await _prefs.setString(_keyAppLanguage, lang);
  }

  // SPOTLIGHT COACH TOUR
  bool hasSeenSpotlightTour() {
    return _prefs.getBool(_keyHasSeenSpotlightTour) ?? false;
  }

  Future<void> setHasSeenSpotlightTour(bool val) async {
    await _prefs.setBool(_keyHasSeenSpotlightTour, val);
  }

  // APP FEATURE GUIDE
  bool hasSeenAppGuide() {
    return _prefs.getBool(_keyHasSeenAppGuide) ?? false;
  }

  Future<void> setHasSeenAppGuide(bool val) async {
    await _prefs.setBool(_keyHasSeenAppGuide, val);
  }

  String getGuideLanguage() {
    return _prefs.getString(_keyAppGuideLanguage) ?? 'th';
  }

  Future<void> setGuideLanguage(String lang) async {
    await _prefs.setString(_keyAppGuideLanguage, lang);
  }

  // MASCOT CUSTOMIZATION
  bool hasChosenMascot() {
    return _prefs.getBool(_keyHasChosenMascot) ?? false;
  }

  Future<void> setHasChosenMascot(bool val) async {
    await _prefs.setBool(_keyHasChosenMascot, val);
  }

  String getMascotId() {
    return _prefs.getString(_keyMascotId) ?? 'cat_quill';
  }

  Future<void> saveMascotId(String id) async {
    await _prefs.setString(_keyMascotId, id);
  }

  String getMascotAccessory() {
    return _prefs.getString(_keyMascotAccessory) ?? 'pen';
  }

  Future<void> saveMascotAccessory(String acc) async {
    await _prefs.setString(_keyMascotAccessory, acc);
  }

  // CUSTOM PHOTO AVATAR
  String? getCustomAvatarPath() {
    return _prefs.getString(_keyCustomAvatarPath);
  }

  Future<void> saveCustomAvatarPath(String? path) async {
    if (path == null || path.isEmpty) {
      await _prefs.remove(_keyCustomAvatarPath);
    } else {
      await _prefs.setString(_keyCustomAvatarPath, path);
    }
  }

  bool isCustomAvatarEnabled() {
    return _prefs.getBool(_keyIsCustomAvatarEnabled) ?? false;
  }

  Future<void> setCustomAvatarEnabled(bool enabled) async {
    await _prefs.setBool(_keyIsCustomAvatarEnabled, enabled);
  }

  // SALARY & BUDGET ENVELOPES
  bool isBudgetPlanEnabled() {
    return _prefs.getBool(_keyIsBudgetPlanEnabled) ?? false;
  }

  Future<void> setBudgetPlanEnabled(bool enabled) async {
    await _prefs.setBool(_keyIsBudgetPlanEnabled, enabled);
  }

  String getBudgetCycle() {
    return _prefs.getString(_keyBudgetCycle) ?? 'monthly';
  }

  Future<void> setBudgetCycle(String cycle) async {
    await _prefs.setString(_keyBudgetCycle, cycle);
  }

  double getMonthlySalary() {
    return _prefs.getDouble(_keyMonthlySalary) ?? 0.0;
  }

  Future<void> saveMonthlySalary(double salary) async {
    await _prefs.setDouble(_keyMonthlySalary, salary);
  }

  // SALARY AUTO-RECORD CONFIG
  SalaryAutoRecordConfig getSalaryAutoRecordConfig() {
    final raw = _prefs.getString(_keySalaryAutoRecordConfig);
    if (raw == null || raw.isEmpty) {
      final monthlySalary = getMonthlySalary();
      return SalaryAutoRecordConfig(amount: monthlySalary);
    }
    return SalaryAutoRecordConfig.fromJson(raw);
  }

  Future<void> saveSalaryAutoRecordConfig(SalaryAutoRecordConfig config) async {
    await _prefs.setString(_keySalaryAutoRecordConfig, config.toJson());
    if (config.amount > 0) {
      await saveMonthlySalary(config.amount);
    }
  }

  Map<String, double> getCategoryBudgets() {
    final raw = _prefs.getString(_keyCategoryBudgets);
    if (raw == null || raw.isEmpty) {
      return {
        'ค่าอาหาร': 0.0,
      };
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final result = <String, double>{};
      map.forEach((k, v) {
        if (v is num) result[k] = v.toDouble();
      });
      if (result.isEmpty) {
        result['ค่าอาหาร'] = 0.0;
      }
      return result;
    } catch (_) {
      return {'ค่าอาหาร': 0.0};
    }
  }

  Map<String, double> getCategoryBudgetsForScope(String scopeKey) {
    final raw = _prefs.getString('budget_scope_cats_$scopeKey');
    if (raw == null || raw.isEmpty) {
      return {};
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final result = <String, double>{};
      map.forEach((k, v) {
        if (v is num) result[k] = v.toDouble();
      });
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveCategoryBudgetsForScope(String scopeKey, Map<String, double> budgets) async {
    await _prefs.setString('budget_scope_cats_$scopeKey', jsonEncode(budgets));
  }

  double getTotalBudgetForScope(String scopeKey) {
    return _prefs.getDouble('budget_scope_total_$scopeKey') ?? 0.0;
  }

  Future<void> saveTotalBudgetForScope(String scopeKey, double total) async {
    await _prefs.setDouble('budget_scope_total_$scopeKey', total);
  }

  Future<void> saveCategoryBudgets(Map<String, double> budgets) async {
    await _prefs.setString(_keyCategoryBudgets, jsonEncode(budgets));
  }

  // THEME MODE & PALETTES
  bool getIsDarkMode() {
    return _prefs.getBool(_keyIsDarkMode) ?? false;
  }

  Future<void> saveThemeMode(bool isDark) async {
    await _prefs.setBool(_keyIsDarkMode, isDark);
  }

  String getCurrentThemeId() {
    return _prefs.getString(_keyCurrentThemeId) ?? 'executive_navy';
  }

  Future<void> saveCurrentThemeId(String themeId) async {
    await _prefs.setString(_keyCurrentThemeId, themeId);
  }

  bool hasChosenTheme() {
    return _prefs.getBool(_keyHasChosenTheme) ?? false;
  }

  Future<void> setHasChosenTheme(bool val) async {
    await _prefs.setBool(_keyHasChosenTheme, val);
  }

  bool hasCompletedShowcase() {
    return _prefs.getBool(_keyHasCompletedShowcase) ?? false;
  }

  Future<void> setHasCompletedShowcase(bool val) async {
    await _prefs.setBool(_keyHasCompletedShowcase, val);
  }

  List<String> getUnlockedThemes() {
    return _prefs.getStringList(_keyUnlockedThemes) ?? ['executive_navy', 'default_light'];
  }

  Future<void> unlockTheme(String themeId) async {
    final list = getUnlockedThemes().toSet();
    list.add(themeId);
    await _prefs.setStringList(_keyUnlockedThemes, list.toList());
  }

  bool isSeasonalEffectEnabled() {
    return _prefs.getBool(_keySeasonalEffects) ?? true;
  }

  Future<void> setSeasonalEffectEnabled(bool val) async {
    await _prefs.setBool(_keySeasonalEffects, val);
  }

  // HASHTAGS MEMORY
  List<String> getSavedTags() {
    final list = _prefs.getStringList(_keySavedTags);
    if (list != null && list.isNotEmpty) return list;
    return ['ของกิน', 'งานเลี้ยง', 'ช้อปปิ้ง', 'จำเป็น', 'เที่ยว', 'ค่าเดินทาง', 'ครอบครัว', 'ฟุ่มเฟือย', 'ของใช้', 'กาแฟ'];
  }

  Future<void> saveTag(String tag) async {
    final clean = tag.replaceAll('#', '').trim();
    if (clean.isEmpty) return;
    final tags = getSavedTags().toSet();
    tags.add(clean);
    await _prefs.setStringList(_keySavedTags, tags.toList());
  }

  Future<void> deleteSavedTag(String tag) async {
    final clean = tag.replaceAll('#', '').trim();
    final tags = getSavedTags().toSet();
    tags.remove(clean);
    await _prefs.setStringList(_keySavedTags, tags.toList());
  }

  // PERMISSION FLAGS
  bool isPermissionConfigured() {
    return _prefs.getBool(_keyPermissionConfigured) ?? false;
  }

  Future<void> setPermissionConfigured(bool val) async {
    await _prefs.setBool(_keyPermissionConfigured, val);
  }

  bool isBankAlbumAllowed() {
    return _prefs.getBool(_keyBankAlbum) ?? true;
  }

  Future<void> setBankAlbumAllowed(bool val) async {
    await _prefs.setBool(_keyBankAlbum, val);
  }

  bool isInstalledAppsAllowed() {
    return _prefs.getBool(_keyInstalledApps) ?? true;
  }

  Future<void> setInstalledAppsAllowed(bool val) async {
    await _prefs.setBool(_keyInstalledApps, val);
  }

  bool isMainAlbumAllowed() {
    return _prefs.getBool(_keyMainAlbum) ?? true;
  }

  Future<void> setMainAlbumAllowed(bool val) async {
    await _prefs.setBool(_keyMainAlbum, val);
  }

  // TRANSACTIONS (Starts with empty clean list)
  List<TransactionItem> getTransactions() {
    final raw = _prefs.getString(_keyTransactions);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => TransactionItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveTransactions(List<TransactionItem> items) async {
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyTransactions, raw);
  }

  // ACCOUNTS (Starts with 0.00 THB balances)
  List<AccountItem> getAccounts() {
    final raw = _prefs.getString(_keyAccounts);
    if (raw == null || raw.isEmpty) {
      return _getDefaultAccounts();
    }
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => AccountItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return _getDefaultAccounts();
    }
  }

  Future<void> saveAccounts(List<AccountItem> accounts) async {
    final raw = jsonEncode(accounts.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyAccounts, raw);
  }

  // CATEGORIES
  List<CategoryItem> getCategories() {
    final raw = _prefs.getString(_keyCategories);
    if (raw == null || raw.isEmpty) {
      return _getDefaultCategories();
    }
    try {
      final List<dynamic> list = jsonDecode(raw);
      final cats = list.map((e) => CategoryItem.fromJson(e as Map<String, dynamic>)).toList();
      _ensureStandardCategories(cats);
      return cats;
    } catch (e) {
      return _getDefaultCategories();
    }
  }

  void _ensureStandardCategories(List<CategoryItem> cats) {
    if (!cats.any((c) => c.type == CategoryType.income && (c.name.contains('ยืม') || c.name.contains('กู้') || c.id == 'cat_borrow'))) {
      cats.add(CategoryItem(
        id: 'cat_borrow',
        name: 'เงินกู้ยืม / ยืมเงิน',
        iconKey: 'payments',
        colorValue: 0xFF06B6D4,
        type: CategoryType.income,
        isDefault: true,
      ));
    }
    if (!cats.any((c) => c.type == CategoryType.expense && (c.name.contains('คืนเงิน') || c.name.contains('ชำระหนี้') || c.id == 'cat_repay_debt'))) {
      final otherExpIdx = cats.indexWhere((c) => c.id == 'cat_other_exp');
      final newItem = CategoryItem(
        id: 'cat_repay_debt',
        name: 'คืนเงินยืม / ชำระหนี้',
        iconKey: 'receipt_long',
        colorValue: 0xFFEC4899,
        type: CategoryType.expense,
        isDefault: true,
      );
      if (otherExpIdx != -1) {
        cats.insert(otherExpIdx, newItem);
      } else {
        cats.add(newItem);
      }
    }
  }

  Future<void> saveCategories(List<CategoryItem> categories) async {
    final raw = jsonEncode(categories.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyCategories, raw);
  }

  // KEYWORD RULES
  List<Map<String, dynamic>> getKeywordRules() {
    final raw = _prefs.getString(_keyKeywordRules);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveKeywordRules(List<Map<String, dynamic>> rules) async {
    final raw = jsonEncode(rules);
    await _prefs.setString(_keyKeywordRules, raw);
  }

  // Default accounts with 0.00 THB balance
  List<AccountItem> _getDefaultAccounts() {
    return [
      AccountItem(
        id: 'acc_cash',
        name: 'เงินสด (Cash)',
        bankCode: 'CASH',
        accountNumber: 'CASH-WALLET',
        balance: 0.00,
        colorValue: 0xFF10B981,
        type: AccountType.cash,
        isDefault: true,
      ),
      AccountItem(
        id: 'acc_ibank',
        name: 'ธนาคารอิสลาม (iBank)',
        bankCode: 'IBANK',
        accountNumber: 'xxx-x-xxxxx-x',
        balance: 0.00,
        colorValue: 0xFF108A44,
        type: AccountType.bank,
      ),
      AccountItem(
        id: 'acc_kbank',
        name: 'กสิกรไทย (KBank)',
        bankCode: 'KBANK',
        accountNumber: 'xxx-x-xxxxx-x',
        balance: 0.00,
        colorValue: 0xFF00A950,
        type: AccountType.bank,
      ),
      AccountItem(
        id: 'acc_scb',
        name: 'ไทยพาณิชย์ (SCB)',
        bankCode: 'SCB',
        accountNumber: 'xxx-x-xxxxx-x',
        balance: 0.00,
        colorValue: 0xFF4E2A84,
        type: AccountType.bank,
      ),
      AccountItem(
        id: 'acc_ktb',
        name: 'กรุงไทย (Krungthai)',
        bankCode: 'KTB',
        accountNumber: 'xxx-x-xxxxx-x',
        balance: 0.00,
        colorValue: 0xFF00A6E6,
        type: AccountType.bank,
      ),
      AccountItem(
        id: 'acc_bbl',
        name: 'กรุงเทพ (BBL)',
        bankCode: 'BBL',
        accountNumber: 'xxx-x-xxxxx-x',
        balance: 0.00,
        colorValue: 0xFF1E3A8A,
        type: AccountType.bank,
      ),
      AccountItem(
        id: 'acc_gsb',
        name: 'ออมสิน (GSB)',
        bankCode: 'GSB',
        accountNumber: 'xxx-x-xxxxx-x',
        balance: 0.00,
        colorValue: 0xFFEB198B,
        type: AccountType.bank,
      ),
      AccountItem(
        id: 'acc_bay',
        name: 'กรุงศรี (BAY)',
        bankCode: 'BAY',
        accountNumber: 'xxx-x-xxxxx-x',
        balance: 0.00,
        colorValue: 0xFFFEC400,
        type: AccountType.bank,
      ),
      AccountItem(
        id: 'acc_ttb',
        name: 'ทีทีบี (ttb)',
        bankCode: 'TTB',
        accountNumber: 'xxx-x-xxxxx-x',
        balance: 0.00,
        colorValue: 0xFF002D63,
        type: AccountType.bank,
      ),
      AccountItem(
        id: 'acc_paotang',
        name: 'เป๋าตัง (PaoTang)',
        bankCode: 'PAOTANG',
        accountNumber: 'xxx-x-xxxxx-x',
        balance: 0.00,
        colorValue: 0xFF009EE0,
        type: AccountType.eWallet,
      ),
      AccountItem(
        id: 'acc_truemoney',
        name: 'TrueMoney Wallet',
        bankCode: 'TRUEMONEY',
        accountNumber: '08x-xxx-xxxx',
        balance: 0.00,
        colorValue: 0xFFFF6C00,
        type: AccountType.eWallet,
      ),
    ];
  }

  // Default clean categories (19 Default Expenses + Incomes)
  List<CategoryItem> _getDefaultCategories() {
    return [
      // 19 Default Expenses
      CategoryItem(
        id: 'cat_food',
        name: 'อาหาร',
        iconKey: 'restaurant',
        colorValue: 0xFFEF4444,
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryItem(
        id: 'cat_drinks',
        name: 'เครื่องดื่ม',
        iconKey: 'local_cafe',
        colorValue: 0xFFF59E0B,
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryItem(
        id: 'cat_fuel',
        name: 'ค่านํ้ามัน',
        iconKey: 'local_gas_station',
        colorValue: 0xFFF97316,
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryItem(
        id: 'cat_electricity',
        name: 'ค่าไฟ',
        iconKey: 'bolt',
        colorValue: 0xFFEAB308,
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryItem(
        id: 'cat_rent',
        name: 'ค่าเช่า',
        iconKey: 'home',
        colorValue: 0xFF6366F1,
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryItem(
        id: 'cat_commute',
        name: 'ค่าเดินทาง',
        iconKey: 'directions_bus',
        colorValue: 0xFF3B82F6,
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryItem(
        id: 'cat_taxi',
        name: 'แท็กซี่',
        iconKey: 'directions_car',
        colorValue: 0xFF06B6D4,
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryItem(
        id: 'cat_online_shopping',
        name: 'ช็อปออนไลน์',
        iconKey: 'shopping_bag',
        colorValue: 0xFFEC4899,
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryItem(
        id: 'cat_internet',
        name: 'เน็ต',
        iconKey: 'wifi',
        colorValue: 0xFF14B8A6,
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryItem(
        id: 'cat_phone',
        name: 'ค่าโทรศัพท์',
        iconKey: 'phone_android',
        colorValue: 0xFF8B5CF6,
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryItem(
        id: 'cat_car_installment',
        name: 'ผ่อนรถ',
        iconKey: 'two_wheeler',
        colorValue: 0xFFD97706,
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryItem(
        id: 'cat_repairs',
        name: 'ซ่อมแซม',
        iconKey: 'handyman',
        colorValue: 0xFF78716C,
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryItem(
        id: 'cat_home',
        name: 'บ้าน',
        iconKey: 'home',
        colorValue: 0xFF10B981,
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryItem(
        id: 'cat_social',
        name: 'สังคม',
        iconKey: 'celebration',
        colorValue: 0xFFF43F5E,
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryItem(
        id: 'cat_vacation',
        name: 'ท่องเที่ยว',
        iconKey: 'flight',
        colorValue: 0xFF0284C7,
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryItem(
        id: 'cat_health',
        name: 'สุขภาพ',
        iconKey: 'medical_services',
        colorValue: 0xFF059669,
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryItem(
        id: 'cat_kids',
        name: 'ลูก',
        iconKey: 'child_care',
        colorValue: 0xFFA855F7,
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryItem(
        id: 'cat_charity',
        name: 'บริจาก',
        iconKey: 'volunteer_activism',
        colorValue: 0xFF10B981,
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryItem(
        id: 'cat_repay_debt',
        name: 'คืนเงินยืม / ชำระหนี้',
        iconKey: 'receipt_long',
        colorValue: 0xFFEC4899,
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryItem(
        id: 'cat_other_exp',
        name: 'รายจ่ายอื่นๆ',
        iconKey: 'category',
        colorValue: 0xFF94A3B8,
        type: CategoryType.expense,
        isDefault: true,
      ),

      // Default Incomes
      CategoryItem(
        id: 'cat_salary',
        name: 'เงินเดือน & ค่าจ้าง',
        iconKey: 'salary',
        colorValue: 0xFF10B981,
        type: CategoryType.income,
        isDefault: true,
      ),
      CategoryItem(
        id: 'cat_borrow',
        name: 'เงินกู้ยืม / ยืมเงิน',
        iconKey: 'payments',
        colorValue: 0xFF06B6D4,
        type: CategoryType.income,
        isDefault: true,
      ),
      CategoryItem(
        id: 'cat_freelance',
        name: 'รายได้เสริม & ฟรีแลนซ์',
        iconKey: 'freelance',
        colorValue: 0xFF38BDF8,
        type: CategoryType.income,
        isDefault: true,
      ),
      CategoryItem(
        id: 'cat_online_sales',
        name: 'ค้าขาย & ธุรกิจส่วนตัว',
        iconKey: 'online_sales',
        colorValue: 0xFFF59E0B,
        type: CategoryType.income,
        isDefault: true,
      ),
      CategoryItem(
        id: 'cat_investment',
        name: 'กำไรลงทุน & ปันผล',
        iconKey: 'trending_up',
        colorValue: 0xFFA855F7,
        type: CategoryType.income,
        isDefault: true,
      ),
      CategoryItem(
        id: 'cat_other_inc',
        name: 'รายรับริซกีอื่นๆ',
        iconKey: 'payments',
        colorValue: 0xFF14B8A6,
        type: CategoryType.income,
        isDefault: true,
      ),
    ];
  }

  List<CategoryItem> getDefaultCategoriesList() => _getDefaultCategories();

  // SAVING GOALS
  List<SavingGoalItem> getSavingGoals() {
    final raw = _prefs.getString(_keySavingGoals);
    if (raw == null || raw.isEmpty) return [];
    return SavingGoalItem.decodeList(raw);
  }

  Future<void> saveSavingGoals(List<SavingGoalItem> goals) async {
    await _prefs.setString(_keySavingGoals, SavingGoalItem.encodeList(goals));
  }

  // RECORDING STREAK
  int getStreakDays() {
    return _prefs.getInt(_keyStreakDays) ?? 0;
  }

  DateTime? getLastRecordedDate() {
    final raw = _prefs.getString(_keyLastRecordedDate);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> saveStreak(int days, DateTime lastDate) async {
    await _prefs.setInt(_keyStreakDays, days);
    await _prefs.setString(_keyLastRecordedDate, lastDate.toIso8601String());
  }

  // UNLOCKED ACCESSORIES (For Gamification)
  List<String> getUnlockedAccessories() {
    final list = _prefs.getStringList(_keyUnlockedAccessories);
    if (list != null) return list;
    // Default unlocked items
    return ['pen', 'coin', 'calculator'];
  }

  Future<void> unlockAccessory(String accessoryId) async {
    final current = getUnlockedAccessories().toSet();
    current.add(accessoryId);
    await _prefs.setStringList(_keyUnlockedAccessories, current.toList());
  }

  // ==========================================================
  // ==========================================================
  // FULL DATA EXPORT & IMPORT (สำรองและกู้คืนข้อมูลครบ 100%)
  // ==========================================================
  Map<String, dynamic> exportAllDataAsMap() {
    final transactions = getTransactions();
    final accounts = getAccounts();
    final categories = getCategories();
    final savingGoals = getSavingGoals();
    final keywordRules = getKeywordRules();
    final categoryBudgets = getCategoryBudgets();
    final savedTags = getSavedTags();
    final unlockedThemes = getUnlockedThemes();
    final unlockedAccessories = getUnlockedAccessories();

    return {
      'app': 'เหมียวตังค์ (Rizqi)',
      'backupVersion': '1.18',
      'exportedAt': DateTime.now().toIso8601String(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'accounts': accounts.map((a) => a.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'savingGoals': savingGoals.map((g) => g.toJson()).toList(),
      'keywordRules': keywordRules,
      'categoryBudgets': categoryBudgets,
      'isBudgetPlanEnabled': isBudgetPlanEnabled(),
      'budgetCycle': getBudgetCycle(),
      'monthlySalary': getMonthlySalary(),
      'savedTags': savedTags,
      'themeId': getCurrentThemeId(),
      'isDarkMode': getIsDarkMode(),
      'mascotId': getMascotId(),
      'mascotAccessory': getMascotAccessory(),
      'unlockedThemes': unlockedThemes,
      'unlockedAccessories': unlockedAccessories,
      'streakDays': getStreakDays(),
      'lastRecordedDate': getLastRecordedDate()?.toIso8601String(),
      'appLanguage': getAppLanguage(),
    };
  }

  Future<bool> importAllDataFromMap(Map<String, dynamic> data, {bool replaceAll = true}) async {
    try {
      // 1. Transactions
      if (data.containsKey('transactions') && data['transactions'] is List) {
        final List<TransactionItem> importedTxs = (data['transactions'] as List)
            .map((item) => TransactionItem.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();

        if (replaceAll) {
          await saveTransactions(importedTxs);
        } else {
          final existing = getTransactions();
          final existingIds = existing.map((t) => t.id).toSet();
          final newTxs = importedTxs.where((t) => !existingIds.contains(t.id)).toList();
          existing.addAll(newTxs);
          await saveTransactions(existing);
        }
      }

      // 2. Accounts
      if (data.containsKey('accounts') && data['accounts'] is List) {
        final List<AccountItem> importedAccs = (data['accounts'] as List)
            .map((item) => AccountItem.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();

        if (replaceAll) {
          await saveAccounts(importedAccs);
        } else {
          final existing = getAccounts();
          final existingIds = existing.map((a) => a.id).toSet();
          for (final acc in importedAccs) {
            if (!existingIds.contains(acc.id)) {
              existing.add(acc);
            }
          }
          await saveAccounts(existing);
        }
      }

      // 3. Categories
      if (data.containsKey('categories') && data['categories'] is List) {
        final List<CategoryItem> importedCats = (data['categories'] as List)
            .map((item) => CategoryItem.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();

        if (replaceAll) {
          await saveCategories(importedCats);
        } else {
          final existing = getCategories();
          final existingNames = existing.map((c) => c.name.trim()).toSet();
          for (final cat in importedCats) {
            if (!existingNames.contains(cat.name.trim())) {
              existing.add(cat);
            }
          }
          await saveCategories(existing);
        }
      }

      // 4. Saving Goals
      if (data.containsKey('savingGoals') && data['savingGoals'] is List) {
        final List<SavingGoalItem> importedGoals = (data['savingGoals'] as List)
            .map((item) => SavingGoalItem.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();

        if (replaceAll) {
          await saveSavingGoals(importedGoals);
        } else {
          final existing = getSavingGoals();
          final existingIds = existing.map((g) => g.id).toSet();
          for (final g in importedGoals) {
            if (!existingIds.contains(g.id)) {
              existing.add(g);
            }
          }
          await saveSavingGoals(existing);
        }
      }

      // 5. Keyword Rules
      if (data.containsKey('keywordRules') && data['keywordRules'] is List) {
        final List<Map<String, dynamic>> rules = (data['keywordRules'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (replaceAll) {
          await saveKeywordRules(rules);
        } else {
          final existing = getKeywordRules();
          existing.addAll(rules);
          await saveKeywordRules(existing);
        }
      }

      // 6. Category Budgets & Settings
      if (data.containsKey('categoryBudgets') && data['categoryBudgets'] is Map) {
        final budgets = Map<String, double>.from(
          (data['categoryBudgets'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
        );
        await saveCategoryBudgets(budgets);
      }

      if (data.containsKey('isBudgetPlanEnabled')) {
        await setBudgetPlanEnabled(data['isBudgetPlanEnabled'] == true);
      }
      if (data.containsKey('budgetCycle') && data['budgetCycle'] != null) {
        await setBudgetCycle(data['budgetCycle'].toString());
      }
      if (data.containsKey('monthlySalary') && data['monthlySalary'] != null) {
        await saveMonthlySalary((data['monthlySalary'] as num).toDouble());
      }

      // 7. Tags, Themes, Gamification
      if (data.containsKey('savedTags') && data['savedTags'] is List) {
        final tags = (data['savedTags'] as List).map((e) => e.toString()).toList();
        await _prefs.setStringList(_keySavedTags, tags);
      }
      if (data.containsKey('themeId') && data['themeId'] != null) {
        await saveCurrentThemeId(data['themeId'].toString());
      }
      if (data.containsKey('isDarkMode')) {
        await saveThemeMode(data['isDarkMode'] == true);
      }
      if (data.containsKey('mascotId') && data['mascotId'] != null) {
        await saveMascotId(data['mascotId'].toString());
      }
      if (data.containsKey('mascotAccessory') && data['mascotAccessory'] != null) {
        await saveMascotAccessory(data['mascotAccessory'].toString());
      }
      if (data.containsKey('unlockedThemes') && data['unlockedThemes'] is List) {
        final themes = (data['unlockedThemes'] as List).map((e) => e.toString()).toList();
        for (final t in themes) {
          await unlockTheme(t);
        }
      }
      if (data.containsKey('unlockedAccessories') && data['unlockedAccessories'] is List) {
        final accs = (data['unlockedAccessories'] as List).map((e) => e.toString()).toList();
        for (final a in accs) {
          await unlockAccessory(a);
        }
      }
      if (data.containsKey('streakDays') && data['streakDays'] is int) {
        final streak = data['streakDays'] as int;
        final lastDateStr = data['lastRecordedDate'] as String?;
        final lastDate = lastDateStr != null ? DateTime.tryParse(lastDateStr) ?? DateTime.now() : DateTime.now();
        await saveStreak(streak, lastDate);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // DELETED SLIPS BLACKLIST / PERSISTENT IGNORED SLIPS
  List<String> getDeletedSlips() {
    return _prefs.getStringList(_keyDeletedSlips) ?? [];
  }

  Future<void> addDeletedSlipIdentifiers(Iterable<String> identifiers) async {
    final current = getDeletedSlips().toSet();
    for (final id in identifiers) {
      final clean = id.trim().toLowerCase();
      if (clean.isNotEmpty) {
        current.add(clean);
      }
    }
    await _prefs.setStringList(_keyDeletedSlips, current.toList());
  }

  Future<void> removeDeletedSlipIdentifiers(Iterable<String> identifiers) async {
    final current = getDeletedSlips().toSet();
    for (final id in identifiers) {
      final clean = id.trim().toLowerCase();
      if (clean.isNotEmpty) {
        current.remove(clean);
      }
    }
    await _prefs.setStringList(_keyDeletedSlips, current.toList());
  }

  Future<void> clearDeletedSlips() async {
    await _prefs.remove(_keyDeletedSlips);
  }

  // IMPORTED SLIPS REGISTRY / PERSISTENT SCANNED SLIPS
  List<String> getImportedSlipIdentifiers() {
    return _prefs.getStringList(_keyImportedSlips) ?? [];
  }

  Future<void> addImportedSlipIdentifiers(Iterable<String> identifiers) async {
    final current = getImportedSlipIdentifiers().toSet();
    for (final id in identifiers) {
      final clean = id.trim().toLowerCase();
      if (clean.isNotEmpty) {
        current.add(clean);
      }
    }
    await _prefs.setStringList(_keyImportedSlips, current.toList());
  }

  Future<void> removeImportedSlipIdentifiers(Iterable<String> identifiers) async {
    final current = getImportedSlipIdentifiers().toSet();
    for (final id in identifiers) {
      final clean = id.trim().toLowerCase();
      if (clean.isNotEmpty) {
        current.remove(clean);
      }
    }
    await _prefs.setStringList(_keyImportedSlips, current.toList());
  }

  Future<void> clearImportedSlips() async {
    await _prefs.remove(_keyImportedSlips);
  }

  // ==========================================
  // MONETIZATION & PREMIUM SUBSCRIPTION STORAGE
  // ==========================================

  bool isPremium() {
    final isPrem = _prefs.getBool(_keyIsPremium) ?? false;
    if (!isPrem) return false;

    // Check expiry if set (for monthly/yearly subscriptions)
    final expiryStr = _prefs.getString(_keyPremiumExpiry);
    if (expiryStr != null && expiryStr.isNotEmpty) {
      final expiry = DateTime.tryParse(expiryStr);
      if (expiry != null && DateTime.now().isAfter(expiry)) {
        return false;
      }
    }
    return true;
  }

  Future<void> setPremium(bool val, {String tier = 'lifetime', DateTime? expiry}) async {
    await _prefs.setBool(_keyIsPremium, val);
    await _prefs.setString(_keyPremiumTier, tier);
    if (expiry != null) {
      await _prefs.setString(_keyPremiumExpiry, expiry.toIso8601String());
    } else {
      await _prefs.remove(_keyPremiumExpiry);
    }
  }

  String getPremiumTier() {
    return _prefs.getString(_keyPremiumTier) ?? 'none';
  }

  DateTime? getPremiumExpiry() {
    final str = _prefs.getString(_keyPremiumExpiry);
    if (str == null || str.isEmpty) return null;
    return DateTime.tryParse(str);
  }

  // PURCHASED THEMES (29 THB each)
  List<String> getPurchasedThemes() {
    return _prefs.getStringList(_keyPurchasedThemes) ?? [];
  }

  Future<void> addPurchasedTheme(String themeId) async {
    final list = getPurchasedThemes().toSet();
    list.add(themeId);
    await _prefs.setStringList(_keyPurchasedThemes, list.toList());
  }

  // PURCHASED ICONS / ACCESSORIES (10 THB each)
  List<String> getPurchasedIcons() {
    return _prefs.getStringList(_keyPurchasedIcons) ?? [];
  }

  Future<void> addPurchasedIcon(String iconId) async {
    final list = getPurchasedIcons().toSet();
    list.add(iconId);
    await _prefs.setStringList(_keyPurchasedIcons, list.toList());
  }

  // MONTHLY SLIP QUOTA (15 slips/month for Free users)
  int getSlipQuotaCountForMonth(String monthKey) {
    final count = _prefs.getInt('${_keySlipQuotaCount}_$monthKey');
    if (count != null) return count;
    // Fallback for legacy single-key storage
    final savedMonth = _prefs.getString(_keySlipQuotaMonth);
    if (savedMonth == monthKey) {
      return _prefs.getInt(_keySlipQuotaCount) ?? 0;
    }
    return 0;
  }

  Future<int> incrementSlipQuotaCount(String monthKey) async {
    final current = getSlipQuotaCountForMonth(monthKey);
    final updated = current + 1;
    await _prefs.setInt('${_keySlipQuotaCount}_$monthKey', updated);
    // Also update legacy keys for backward compatibility
    await _prefs.setString(_keySlipQuotaMonth, monthKey);
    await _prefs.setInt(_keySlipQuotaCount, updated);
    return updated;
  }

  Future<void> resetSlipQuotaCount(String monthKey) async {
    await _prefs.setInt('${_keySlipQuotaCount}_$monthKey', 0);
    await _prefs.setString(_keySlipQuotaMonth, monthKey);
    await _prefs.setInt(_keySlipQuotaCount, 0);
  }

  // REWARDED AD BONUS SLIPS (Valid only for the calendar month watched, resets to 0 next month)
  int getAdBonusSlipsForMonth(String monthKey) {
    return _prefs.getInt('meow_ad_bonus_slips_v1_$monthKey') ?? 0;
  }

  Future<int> addAdBonusSlipsForMonth(String monthKey, int bonusCount) async {
    final current = getAdBonusSlipsForMonth(monthKey);
    final updated = current + bonusCount;
    await _prefs.setInt('meow_ad_bonus_slips_v1_$monthKey', updated);
    return updated;
  }

  // REWARDED AD WATCH COUNT (Max 10 per calendar month, resets to 0/10 every month, zero rollover)
  int getMonthlyAdWatchCount(String monthKey) {
    return _prefs.getInt('meow_ad_watch_count_v1_$monthKey') ?? 0;
  }

  Future<int> incrementMonthlyAdWatchCount(String monthKey) async {
    final current = getMonthlyAdWatchCount(monthKey);
    final updated = current + 1;
    await _prefs.setInt('meow_ad_watch_count_v1_$monthKey', updated);
    return updated;
  }

  // PRIVACY EYE (Hide/Show Balances in Overview)
  static const String _keyHideBalance = 'meow_privacy_hide_balance_v1';
  bool isHideBalance() {
    return _prefs.getBool(_keyHideBalance) ?? false;
  }

  Future<void> setHideBalance(bool hide) async {
    await _prefs.setBool(_keyHideBalance, hide);
  }

  // WELCOME BONUS SLIPS (100 free slips for first-time install)
  int getWelcomeBonusSlipsRemaining() {
    return _prefs.getInt(_keyWelcomeBonusSlips) ?? AppConfig.welcomeBonusSlips;
  }

  Future<int> deductWelcomeBonusSlip() async {
    final current = getWelcomeBonusSlipsRemaining();
    if (current <= 0) return 0;
    final updated = current - 1;
    await _prefs.setInt(_keyWelcomeBonusSlips, updated);
    return updated;
  }

  Future<void> setWelcomeBonusSlips(int count) async {
    await _prefs.setInt(_keyWelcomeBonusSlips, count);
  }

  // INITIAL DEVICE SLIP SCAN
  bool isInitialDeviceScanCompleted() {
    return _prefs.getBool(_keyInitialDeviceScanCompleted) ?? false;
  }

  Future<void> setInitialDeviceScanCompleted(bool completed) async {
    await _prefs.setBool(_keyInitialDeviceScanCompleted, completed);
  }
}

