import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_item.dart';
import '../models/account_item.dart';
import '../models/category_item.dart';
import '../models/saving_goal_item.dart';

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
      return list.map((e) => CategoryItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return _getDefaultCategories();
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
}
