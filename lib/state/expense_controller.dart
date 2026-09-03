import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction_item.dart';
import '../models/account_item.dart';
import '../models/category_item.dart';
import '../models/project_budget.dart';
import '../models/tax_profile.dart';
import '../models/slip_extract_result.dart';
import '../models/saving_goal_item.dart';
import '../services/storage_service.dart';
import '../services/ocr_engine_service.dart';
import '../services/nlp_parser_service.dart';
import '../services/excel_export_service.dart';
import '../services/cashflow_forecast_service.dart';
import '../services/native_bridge_service.dart';
import '../services/duplicate_slip_checker.dart';
import '../services/slip_storage_service.dart';
import '../localization/app_strings.dart';
import '../theme/app_theme_model.dart';

enum MascotMood {
 happy,
 normal,
 warning,
}

class ExpenseController extends ChangeNotifier {
 final StorageService _storage;
 final OcrEngineService _ocrEngine = OcrEngineService();
 final NlpParserService _nlpParser = NlpParserService();
 final CashflowForecastService _forecastService = CashflowForecastService();

 static const MethodChannel _widgetChannel = MethodChannel('com.afitree.rizqi/widget');

 List<TransactionItem> _transactions = [];
 List<AccountItem> _accounts = [];
 List<CategoryItem> _categories = [];
 List<SavingGoalItem> _savingGoals = [];
 final List<ProjectBudget> _projects = [];
 TaxProfile _taxProfile = TaxProfile();

 // Filter & Search
 String _searchQuery = '';
 TransactionType? _filterType;
 String? _filterCategoryId;
 String? _filterAccountId;
 DateTimeRange? _filterDateRange;

 bool _isLoading = false;

 ExpenseController(this._storage) {
  loadData();
  NativeBridgeService.setDataReloadListener(() {
   loadData();
  });
 }

 // Getters
 StorageService get storage => _storage;
 bool get isLoading => _isLoading;
 List<AccountItem> get accounts => _accounts;
 List<CategoryItem> get categories => _categories;
 List<TransactionItem> get allTransactions => _transactions;
 List<SavingGoalItem> get savingGoals => _savingGoals;
 int get streakDays => _storage.getStreakDays();
 List<String> get unlockedAccessories => _storage.getUnlockedAccessories();

 MascotMood get mascotMood {
  if (isBudgetPlanEnabled) {
   final quota = getDailyFoodBudgetQuota();
   final todayFood = getTodayFoodExpense();
   if (quota > 0 && todayFood > quota) {
    return MascotMood.warning;
   }
  }
  if (streakDays >= 3 || _savingGoals.any((g) => g.isCompleted)) {
   return MascotMood.happy;
  }
  return MascotMood.normal;
 }

 List<ProjectBudget> get projects => _projects;
 TaxProfile get taxProfile => _taxProfile;
 String get searchQuery => _searchQuery;
 TransactionType? get filterType => _filterType;
 String? get filterCategoryId => _filterCategoryId;
 String? get filterAccountId => _filterAccountId;
 DateTimeRange? get filterDateRange => _filterDateRange;

 CashflowForecastResult get cashflowForecast =>
   _forecastService.generateForecast(
    accounts: _accounts,
    historyTransactions: _transactions,
   );

 Future<void> addProject(ProjectBudget project) async {
  _projects.add(project);
  notifyListeners();
 }

 Future<void> deleteProject(String id) async {
  _projects.removeWhere((p) => p.id == id);
  notifyListeners();
 }

 ProjectBudget? getProjectById(String id) {
  try {
   return _projects.firstWhere((p) => p.id == id);
  } catch (_) {
   return null;
  }
 }

 void updateTaxProfile(TaxProfile profile) {
  _taxProfile = profile;
  notifyListeners();
 }

 void autoSyncTaxProfileFromTransactions() {
  notifyListeners();
 }

 bool get isPermissionConfigured => _storage.isPermissionConfigured();
 bool get isBankAlbumAllowed => _storage.isBankAlbumAllowed();
 bool get isInstalledAppsAllowed => _storage.isInstalledAppsAllowed();
 bool get isMainAlbumAllowed => _storage.isMainAlbumAllowed();
 bool get hasChosenMascot => _storage.hasChosenMascot();
 bool get hasSeenAppGuide => _storage.hasSeenAppGuide();
 String get guideLanguage => _storage.getGuideLanguage();
 String get selectedMascotId => _storage.getMascotId();
 String get selectedMascotAccessory => _storage.getMascotAccessory();

 // CUSTOM PHOTO AVATAR
 String? get customAvatarPath => _storage.getCustomAvatarPath();
 bool get isCustomAvatarEnabled => _storage.isCustomAvatarEnabled() && customAvatarPath != null;

 Future<void> setCustomAvatar(String? path) async {
  await _storage.saveCustomAvatarPath(path);
  await _storage.setCustomAvatarEnabled(path != null);
  notifyListeners();
 }

 Future<void> toggleCustomAvatar(bool enabled) async {
  await _storage.setCustomAvatarEnabled(enabled);
  notifyListeners();
 }

 Future<void> setCustomAvatarEnabled(bool enabled) async {
  await _storage.setCustomAvatarEnabled(enabled);
  notifyListeners();
 }

 // SALARY & CATEGORY BUDGET ENVELOPES (OPTIONAL & FLEXIBLE CYCLES)
 bool get isBudgetPlanEnabled => _storage.isBudgetPlanEnabled();

 Future<void> setBudgetPlanEnabled(bool enabled) async {
  await _storage.setBudgetPlanEnabled(enabled);
  notifyListeners();
 }

 String get budgetCycle => _storage.getBudgetCycle();

 Future<void> setBudgetCycle(String cycle) async {
  await _storage.setBudgetCycle(cycle);
  notifyListeners();
 }

 double get monthlySalary => _storage.getMonthlySalary();

 Future<void> setMonthlySalary(double salary) async {
  await _storage.saveMonthlySalary(salary);
  notifyListeners();
 }

 Map<String, double> get categoryBudgets => _storage.getCategoryBudgets();

 Map<String, double> getCategoryBudgetsForScope(String scopeKey) {
    return _storage.getCategoryBudgetsForScope(scopeKey);
  }

  Future<void> saveCategoryBudgetsForScope(String scopeKey, Map<String, double> budgets) async {
    await _storage.saveCategoryBudgetsForScope(scopeKey, budgets);
    for (final catName in budgets.keys) {
      await ensureCategoryExistsForBudget(catName);
    }
    notifyListeners();
  }

  double getTotalBudgetForScope(String scopeKey) {
    return _storage.getTotalBudgetForScope(scopeKey);
  }

  Future<void> saveTotalBudgetForScope(String scopeKey, double total) async {
    await _storage.saveTotalBudgetForScope(scopeKey, total);
    notifyListeners();
  }

  Map<String, double> getCategoryBudgetsForDate(DateTime date) {
    final monthKey = 'month_${date.year}_${date.month.toString().padLeft(2, '0')}';
    final monthBudgets = getCategoryBudgetsForScope(monthKey);
    if (monthBudgets.isNotEmpty) return monthBudgets;

    final yearKey = 'year_${date.year}';
    final yearBudgets = getCategoryBudgetsForScope(yearKey);
    if (yearBudgets.isNotEmpty) return yearBudgets;

    return {};
  }
 
    Future<void> ensureCategoryExistsForBudget(String categoryName) async {
    final cleanName = categoryName.trim();
    if (cleanName.isEmpty) return;

    final exists = _categories.any((c) =>
        c.name.trim().toLowerCase() == cleanName.toLowerCase());

    if (!exists) {
      String iconKey = 'category';
      int colorValue = 0xFFF59E0B;

      final lower = cleanName.toLowerCase();
      if (lower.contains('อาหาร') || lower.contains('กิน') || lower.contains('กาแฟ') || lower.contains('food') || lower.contains('coffee')) {
        iconKey = 'restaurant';
        colorValue = 0xFFF59E0B;
      } else if (lower.contains('เดินทาง') || lower.contains('น้ำมัน') || lower.contains('รถ') || lower.contains('transport') || lower.contains('fuel')) {
        iconKey = 'directions_car';
        colorValue = 0xFF3B82F6;
      } else if (lower.contains('ช้อป') || lower.contains('ของใช้') || lower.contains('shop')) {
        iconKey = 'shopping_bag';
        colorValue = 0xFFEC4899;
      } else if (lower.contains('บิล') || lower.contains('น้ำไฟ') || lower.contains('เน็ต') || lower.contains('bill')) {
        iconKey = 'receipt_long';
        colorValue = 0xFF8B5CF6;
      } else if (lower.contains('สุขภาพ') || lower.contains('ยา') || lower.contains('รักษา') || lower.contains('health')) {
        iconKey = 'medical_services';
        colorValue = 0xFF10B981;
      } else if (lower.contains('ห้อง') || lower.contains('บ้าน') || lower.contains('ที่พัก') || lower.contains('rent') || lower.contains('home')) {
        iconKey = 'home';
        colorValue = 0xFF06B6D4;
      } else if (lower.contains('เที่ยว') || lower.contains('บันเทิง') || lower.contains('travel')) {
        iconKey = 'flight';
        colorValue = 0xFFF97316;
      } else if (lower.contains('บุญ') || lower.contains('บริจาค') || lower.contains('donate')) {
        iconKey = 'volunteer_activism';
        colorValue = 0xFF14B8A6;
      }

      final newCat = CategoryItem(
        id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
        name: cleanName,
        iconKey: iconKey,
        colorValue: colorValue,
        type: CategoryType.expense,
      );
      _categories.add(newCat);
      await _storage.saveCategories(_categories);
      notifyListeners();
    }
  }

  Future<void> setCategoryBudgets(Map<String, double> budgets) async {
  await _storage.saveCategoryBudgets(budgets);
  for (final catName in budgets.keys) {
    await ensureCategoryExistsForBudget(catName);
  }
  notifyListeners();
 }

 Future<void> setCategoryBudget(String categoryName, double amount) async {
    await updateCategoryBudget(categoryName, amount);
  }

  Future<void> updateCategoryBudget(String categoryName, double amount) async {
  final map = Map<String, double>.from(categoryBudgets);
  map[categoryName] = amount;
  await setCategoryBudgets(map);
 }

 Future<void> removeCategoryBudget(String categoryName) async {
  final map = Map<String, double>.from(categoryBudgets);
  map.remove(categoryName);
  await setCategoryBudgets(map);
 }

 double getSpentForCategoryThisMonth(String categoryName) {
  final now = DateTime.now();
  return _transactions
    .where((t) =>
      t.date.year == now.year &&
      t.date.month == now.month &&
      t.type == TransactionType.expense &&
      (t.categoryName.toLowerCase().contains(categoryName.toLowerCase()) ||
        categoryName.toLowerCase().contains(t.categoryName.toLowerCase())))
    .fold(0.0, (sum, t) => sum + t.amount);
 }

 double getSpentForCategoryThisYear(String categoryName) {
  final now = DateTime.now();
  return _transactions
    .where((t) =>
      t.date.year == now.year &&
      t.type == TransactionType.expense &&
      (t.categoryName.toLowerCase().contains(categoryName.toLowerCase()) ||
        categoryName.toLowerCase().contains(t.categoryName.toLowerCase())))
    .fold(0.0, (sum, t) => sum + t.amount);
 }

 double getSpentForCategoryToday(String categoryName) {
  final now = DateTime.now();
  return _transactions
    .where((t) =>
      t.date.year == now.year &&
      t.date.month == now.month &&
      t.date.day == now.day &&
      t.type == TransactionType.expense &&
      (t.categoryName.toLowerCase().contains(categoryName.toLowerCase()) ||
        categoryName.toLowerCase().contains(t.categoryName.toLowerCase())))
    .fold(0.0, (sum, t) => sum + t.amount);
 }

 int get remainingDaysInMonth {
  final now = DateTime.now();
  final lastDay = DateTime(now.year, now.month + 1, 0).day;
  final remaining = (lastDay - now.day) + 1;
  return remaining > 0 ? remaining : 1;
 }

 int get remainingDaysInYear {
  final now = DateTime.now();
  final lastDayOfYear = DateTime(now.year, 12, 31);
  final remaining = lastDayOfYear.difference(now).inDays + 1;
  return remaining > 0 ? remaining : 1;
 }

 double getDailyFoodBudgetQuota() {
  final budgets = categoryBudgets;
  final foodBudget = budgets['อาหาร & เครื่องดื่ม'] ?? budgets['อาหาร'] ?? (monthlySalary > 0 ? monthlySalary * 0.25 : 6000.0);
  final spentFood = getSpentForCategoryThisMonth('อาหาร');
  final remainingFood = foodBudget - spentFood;
  final days = remainingDaysInMonth;
  return remainingFood > 0 ? (remainingFood / days) : 0.0;
 }

 double getTodayFoodExpense() {
  final now = DateTime.now();
  return _transactions
    .where((t) =>
      t.date.year == now.year &&
      t.date.month == now.month &&
      t.date.day == now.day &&
      t.type == TransactionType.expense &&
      t.categoryName.toLowerCase().contains('อาหาร'))
    .fold(0.0, (sum, t) => sum + t.amount);
 }

 double getTodayTotalExpense() {
  final now = DateTime.now();
  return _transactions
    .where((t) =>
      t.date.year == now.year &&
      t.date.month == now.month &&
      t.date.day == now.day &&
      t.type == TransactionType.expense)
    .fold(0.0, (sum, t) => sum + t.amount);
 }

 double getThisMonthTotalExpense() {
  final now = DateTime.now();
  return _transactions
    .where((t) =>
      t.date.year == now.year &&
      t.date.month == now.month &&
      t.type == TransactionType.expense)
    .fold(0.0, (sum, t) => sum + t.amount);
 }

 double getThisYearTotalExpense() {
  final now = DateTime.now();
  return _transactions
    .where((t) =>
      t.date.year == now.year &&
      t.type == TransactionType.expense)
    .fold(0.0, (sum, t) => sum + t.amount);
 }

 double get totalExpenseThisYear => getThisYearTotalExpense();

 double get totalIncomeThisYear {
  final now = DateTime.now();
  return _transactions
    .where((t) =>
      t.date.year == now.year &&
      t.type == TransactionType.income)
    .fold(0.0, (sum, t) => sum + t.amount);
 }

 // APP LOCALIZATION (TH / EN)
 bool get hasSelectedInitialLanguage => _storage.hasSelectedInitialLanguage();
 String get appLanguage {
  final lang = _storage.getAppLanguage();
  if (lang == 'ms' || lang == 'jawi') return 'th';
  return lang;
 }
 bool get isEnglish => appLanguage == 'en';

 Future<void> completeLanguageSelection(String lang) async {
  await _storage.saveAppLanguage(lang);
  await _storage.setGuideLanguage(lang);
  await _storage.setHasSelectedInitialLanguage(true);
  notifyListeners();
 }

 Future<void> setAppLanguage(String lang) async {
  await _storage.saveAppLanguage(lang);
  notifyListeners();
 }

 String tr(String key) => AppStrings.get(key, appLanguage);
 String trCategory(String rawName) => AppStrings.getCategoryName(rawName, appLanguage);
 String trAccount(String rawName) => AppStrings.getAccountName(rawName, appLanguage);

 bool get hasSeenSpotlightTour => _storage.hasSeenSpotlightTour();

 Future<void> setHasSeenSpotlightTour(bool val) async {
  await _storage.setHasSeenSpotlightTour(val);
  notifyListeners();
 }

 Future<void> completeAppGuide() async {
  await _storage.setHasSeenAppGuide(true);
  notifyListeners();
 }

 Future<void> setGuideLanguage(String lang) async {
  await _storage.setGuideLanguage(lang);
  notifyListeners();
 }

 Future<void> completeMascotOnboarding(String id, String accessory) async {
  await _storage.saveMascotId(id);
  await _storage.saveMascotAccessory(accessory);
  await _storage.setHasChosenMascot(true);
  notifyListeners();
 }

 Future<void> updateMascot(String id, String accessory) async {
  await _storage.saveMascotId(id);
  await _storage.saveMascotAccessory(accessory);
  notifyListeners();
 }

 // THEME MANAGEMENT
 String get currentThemeId => _storage.getCurrentThemeId();
 bool get isDarkMode => _storage.getIsDarkMode();
 AppThemeModel get currentTheme => AppThemePresets.getById(currentThemeId, isDark: isDarkMode);
 List<String> get unlockedThemes => _storage.getUnlockedThemes();

 Future<void> setTheme(String themeId) async {
  await _storage.saveCurrentThemeId(themeId);
  notifyListeners();
 }

 Future<void> setDarkMode(bool isDark) async {
  await _storage.saveThemeMode(isDark);
  notifyListeners();
 }

 bool get isSeasonalEffectEnabled => _storage.isSeasonalEffectEnabled();

 Future<void> setSeasonalEffectEnabled(bool val) async {
  await _storage.setSeasonalEffectEnabled(val);
  notifyListeners();
 }

 Future<void> unlockAndSetTheme(String themeId) async {
  await _storage.unlockTheme(themeId);
  await setTheme(themeId);
 }

 bool get hasChosenTheme => _storage.hasChosenTheme();
 bool get hasCompletedShowcase => _storage.hasCompletedShowcase();

 Future<void> completeThemeOnboarding(String themeId, bool isDark) async {
  await _storage.saveCurrentThemeId(themeId);
  await _storage.saveThemeMode(isDark);
  await _storage.setHasChosenTheme(true);
  notifyListeners();
 }

 Future<void> completeShowcase() async {
  await _storage.setHasCompletedShowcase(true);
  notifyListeners();
 }

 Future<void> toggleThemeMode(bool isDark) async {
  await setDarkMode(isDark);
 }
 // HASHTAGS MEMORY
 List<String> get savedTags => _storage.getSavedTags();

 Future<void> saveTag(String tag) async {
  await _storage.saveTag(tag);
  notifyListeners();
 }

 Future<void> deleteSavedTag(String tag) async {
  await _storage.deleteSavedTag(tag);
  notifyListeners();
 }

 // CALENDAR AGGREGATIONS FOR A GIVEN MONTH
 Map<int, double> getDailyExpensesForMonth(int year, int month) {
  final Map<int, double> map = {};
  for (final tx in _transactions) {
   if (tx.date.year == year && tx.date.month == month && tx.type == TransactionType.expense) {
    map[tx.date.day] = (map[tx.date.day] ?? 0.0) + tx.amount;
   }
  }
  return map;
 }

 Map<int, double> getDailyIncomesForMonth(int year, int month) {
  final Map<int, double> map = {};
  for (final tx in _transactions) {
   if (tx.date.year == year && tx.date.month == month && tx.type == TransactionType.income) {
    map[tx.date.day] = (map[tx.date.day] ?? 0.0) + tx.amount;
   }
  }
  return map;
 }

 List<TransactionItem> getTransactionsForDate(DateTime date) {
  return _transactions.where((tx) =>
   tx.date.year == date.year &&
   tx.date.month == date.month &&
   tx.date.day == date.day
  ).toList();
 }

 double getMonthlyExpenseTotal(int year, int month) {
  return _transactions
    .where((t) => t.date.year == year && t.date.month == month && t.type == TransactionType.expense)
    .fold(0.0, (sum, t) => sum + t.amount);
 }

 double getMonthlyIncomeTotal(int year, int month) {
  return _transactions
    .where((t) => t.date.year == year && t.date.month == month && t.type == TransactionType.income)
    .fold(0.0, (sum, t) => sum + t.amount);
 }

 Future<void> savePermissions({
  required bool bankAlbum,
  required bool installedApps,
  required bool mainAlbum,
 }) async {
  await _storage.setBankAlbumAllowed(bankAlbum);
  await _storage.setInstalledAppsAllowed(installedApps);
  await _storage.setMainAlbumAllowed(mainAlbum);
  await _storage.setPermissionConfigured(true);
  notifyListeners();
 }

 List<CategoryItem> get expenseCategories =>
   _categories.where((c) => c.type == CategoryType.expense).toList();

 List<CategoryItem> get incomeCategories =>
   _categories.where((c) => c.type == CategoryType.income).toList();

 double get totalNetWorth => _accounts.fold(0.0, (sum, acc) => sum + acc.balance);

 double get totalIncomeAll => _transactions
   .where((t) => t.type == TransactionType.income)
   .fold(0.0, (sum, t) => sum + t.amount);

 double get totalExpenseAll => _transactions
   .where((t) => t.type == TransactionType.expense)
   .fold(0.0, (sum, t) => sum + t.amount);

 double get totalIncomeThisMonth {
  final now = DateTime.now();
  return _transactions
    .where((t) =>
      t.type == TransactionType.income &&
      t.date.year == now.year &&
      t.date.month == now.month)
    .fold(0.0, (sum, t) => sum + t.amount);
 }

 double get totalExpenseThisMonth {
  final now = DateTime.now();
  return _transactions
    .where((t) =>
      t.type == TransactionType.expense &&
      t.date.year == now.year &&
      t.date.month == now.month)
    .fold(0.0, (sum, t) => sum + t.amount);
 }

 double get netSavingsThisMonth => totalIncomeThisMonth - totalExpenseThisMonth;

 List<TransactionItem> get filteredTransactions {
  return _transactions.where((tx) {
   if (_searchQuery.isNotEmpty) {
    final q = _searchQuery.toLowerCase();
    final matchTitle = tx.title.toLowerCase().contains(q);
    final matchNote = tx.note?.toLowerCase().contains(q) ?? false;
    final matchCategory = tx.categoryName.toLowerCase().contains(q);
    if (!matchTitle && !matchNote && !matchCategory) {
     return false;
    }
   }
   if (_filterType != null && tx.type != _filterType) return false;
   if (_filterCategoryId != null && tx.categoryId != _filterCategoryId) return false;
   if (_filterAccountId != null && tx.accountId != _filterAccountId) return false;
   if (_filterDateRange != null) {
    if (tx.date.isBefore(_filterDateRange!.start) ||
      tx.date.isAfter(_filterDateRange!.end.add(const Duration(days: 1)))) {
     return false;
    }
   }
   return true;
  }).toList();
 }

 // Category distribution for summary charts
 Map<String, double> get expenseCategoryBreakdown {
  final map = <String, double>{};
  for (final tx in _transactions) {
   if (tx.type == TransactionType.expense) {
    map[tx.categoryName] = (map[tx.categoryName] ?? 0.0) + tx.amount;
   }
  }
  return map;
 }

 Map<String, double> get incomeCategoryBreakdown {
  final map = <String, double>{};
  for (final tx in _transactions) {
   if (tx.type == TransactionType.income) {
    map[tx.categoryName] = (map[tx.categoryName] ?? 0.0) + tx.amount;
   }
  }
  return map;
 }

 void loadData() {
  _isLoading = true;
  notifyListeners();

  _transactions = _storage.getTransactions();
  _accounts = _storage.getAccounts();
  _categories = _storage.getCategories();
  _savingGoals = _storage.getSavingGoals();

  _deduplicateInMemoryTransactions();

  _isLoading = false;
  notifyListeners();
  syncAndroidWidget();

  // Background migration for slips (prevents missing slips when user cleans gallery)
  Future.microtask(() {
   SlipStorageService.autoBackupExistingSlips(_transactions, (updated) async {
    final idx = _transactions.indexWhere((t) => t.id == updated.id);
    if (idx != -1) {
     _transactions[idx] = updated;
     await _storage.saveTransactions(_transactions);
    }
   });
  });
 }

 /// Forces a complete fresh reload from persistent storage (e.g. after Widget adds a transaction)
 Future<void> reloadFromStorage() async {
  _transactions = _storage.getTransactions();
  _accounts = _storage.getAccounts();
  _categories = _storage.getCategories();
  _savingGoals = _storage.getSavingGoals();
  notifyListeners();
  await syncAndroidWidget();
 }

 // ACCOUNT MANAGEMENT (Set/Edit Balances)
 Future<void> updateAccountBalance(String accountId, double newBalance) async {
  final idx = _accounts.indexWhere((a) => a.id == accountId);
  if (idx != -1) {
   _accounts[idx] = _accounts[idx].copyWith(balance: newBalance);
   await _storage.saveAccounts(_accounts);
   notifyListeners();
  }
 }

 Future<void> addAccount(AccountItem acc) async {
  _accounts.add(acc);
  await _storage.saveAccounts(_accounts);
  notifyListeners();
 }

 Future<void> updateAccount(AccountItem acc) async {
  final idx = _accounts.indexWhere((a) => a.id == acc.id);
  if (idx != -1) {
   _accounts[idx] = acc;
   await _storage.saveAccounts(_accounts);
   notifyListeners();
  }
 }

 Future<void> deleteAccount(String id) async {
  _accounts.removeWhere((a) => a.id == id);
  await _storage.saveAccounts(_accounts);
  notifyListeners();
 }

 Future<void> toggleAccountAutoDeduction(String accountId, bool allow) async {
  final idx = _accounts.indexWhere((a) => a.id == accountId);
  if (idx != -1) {
   _accounts[idx] = _accounts[idx].copyWith(allowAutoDeduction: allow);
   await _storage.saveAccounts(_accounts);
   notifyListeners();
  }
 }

 Future<void> setDefaultAccount(String accountId) async {
  for (int i = 0; i < _accounts.length; i++) {
   _accounts[i] = _accounts[i].copyWith(isDefault: _accounts[i].id == accountId);
  }
  await _storage.saveAccounts(_accounts);
  notifyListeners();
 }

 // CATEGORY MANAGEMENT (Add / Edit / Delete / Reorder / Reset)
 Future<void> addCategory(CategoryItem cat) async {
  _categories.add(cat);
  await _storage.saveCategories(_categories);
  notifyListeners();
 }

 Future<void> updateCategory(CategoryItem cat) async {
  final idx = _categories.indexWhere((c) => c.id == cat.id);
  if (idx != -1) {
   _categories[idx] = cat;
   await _storage.saveCategories(_categories);
   notifyListeners();
  }
 }

 Future<void> deleteCategory(String id) async {
  _categories.removeWhere((c) => c.id == id);
  await _storage.saveCategories(_categories);
  notifyListeners();
 }

 Future<void> reorderCategories(CategoryType type, int oldIndex, int newIndex) async {
  final subList = _categories.where((c) => c.type == type).toList();
  if (oldIndex < 0 || oldIndex >= subList.length) return;
  if (oldIndex < newIndex) {
   newIndex -= 1;
  }
  if (newIndex < 0 || newIndex >= subList.length) return;

  final item = subList.removeAt(oldIndex);
  subList.insert(newIndex, item);

  final otherList = _categories.where((c) => c.type != type).toList();
  _categories = type == CategoryType.expense ? [...subList, ...otherList] : [...otherList, ...subList];
  await _storage.saveCategories(_categories);
  notifyListeners();
 }

 Future<void> resetCategoriesToDefault() async {
  _categories = _storage.getDefaultCategoriesList();
  await _storage.saveCategories(_categories);
  notifyListeners();
 }

 CategoryItem ensureCategoryExists(String name, CategoryType type) {
  final clean = name.trim();
  final match = _categories.firstWhere(
   (c) => c.name.toLowerCase() == clean.toLowerCase() && c.type == type,
   orElse: () {
    final newCat = CategoryItem(
     id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
     name: clean,
     iconKey: type == CategoryType.income ? 'payments' : 'category',
     colorValue: type == CategoryType.income ? 0xFF10B981 : 0xFFF59E0B,
     type: type,
    );
    _categories.add(newCat);
    _storage.saveCategories(_categories);
    return newCat;
   },
  );
  return match;
 }

  void _deduplicateInMemoryTransactions() {
    if (_transactions.length <= 1) return;
    final cleanList = <TransactionItem>[];
    final seenSlips = <String>{};

    for (final tx in _transactions) {
      if (tx.slipImageUrl != null && tx.slipImageUrl!.isNotEmpty) {
        final bName = DuplicateSlipChecker.extractBasename(tx.slipImageUrl);
        if (bName.isNotEmpty) {
          if (seenSlips.contains(bName)) {
            continue;
          }
          seenSlips.add(bName);
        }
      }

      final isDup = DuplicateSlipChecker.isDuplicate(
        existingTransactions: cleanList,
        filePath: tx.slipImageUrl,
        fileName: tx.slipImageUrl != null ? DuplicateSlipChecker.extractBasename(tx.slipImageUrl) : null,
        refId: tx.slipRefId,
        amount: tx.amount,
        date: tx.date,
        bankName: tx.bankName,
      );

      if (!isDup) {
        cleanList.add(tx);
      }
    }

    if (cleanList.length != _transactions.length) {
      _transactions = cleanList;
      _storage.saveTransactions(_transactions);
    }
  }

  /// Batch adds multiple slip / imported transactions with 1 single storage write & 1 notifyListeners
  Future<void> addTransactionsBatch(List<TransactionItem> items) async {
    if (items.isEmpty) return;

    final List<TransactionItem> toAdd = [];
    final deletedSlips = _storage.getDeletedSlips();

    for (final item in items) {
      if (item.slipImageUrl != null || (item.slipRefId != null && !item.slipRefId!.startsWith('SLIP-'))) {
        final isDup = DuplicateSlipChecker.isDuplicate(
          existingTransactions: _transactions,
          deletedSlipIdentifiers: deletedSlips,
          filePath: item.slipImageUrl,
          fileName: item.slipImageUrl != null ? DuplicateSlipChecker.extractBasename(item.slipImageUrl) : null,
          refId: item.slipRefId,
          amount: item.amount,
          date: item.date,
          bankName: item.bankName,
        );
        if (isDup) continue;
      }

      toAdd.add(item);

      // Update account balance in memory
      final accIndex = _accounts.indexWhere((a) => a.id == item.accountId);
      if (accIndex != -1) {
        final acc = _accounts[accIndex];
        if (item.type == TransactionType.expense) {
          _accounts[accIndex] = acc.copyWith(balance: acc.balance - item.amount);
        } else if (item.type == TransactionType.income) {
          _accounts[accIndex] = acc.copyWith(balance: acc.balance + item.amount);
        } else if (item.type == TransactionType.transfer && item.targetAccountId != null) {
          _accounts[accIndex] = acc.copyWith(balance: acc.balance - item.amount);
          final targetIdx = _accounts.indexWhere((a) => a.id == item.targetAccountId);
          if (targetIdx != -1) {
            _accounts[targetIdx] = _accounts[targetIdx].copyWith(balance: _accounts[targetIdx].balance + item.amount);
          }
        }
      }
    }

    if (toAdd.isEmpty) return;

    _transactions.insertAll(0, toAdd);

    // Single write to disk
    await _storage.saveTransactions(_transactions);
    await _storage.saveAccounts(_accounts);
    if (toAdd.isNotEmpty) {
      await _checkAndUpdateStreakOnNewTransaction(toAdd.first.date);
    }
    await syncAndroidWidget();
    notifyListeners();
  }

  // TRANSACTION ACTIONS
  Future<void> addTransaction(TransactionItem item) async {
    // Duplicate & Deleted Protection Guard
    if (item.slipImageUrl != null || (item.slipRefId != null && !item.slipRefId!.startsWith('SLIP-'))) {
      final isDup = DuplicateSlipChecker.isDuplicate(
        existingTransactions: _transactions,
        deletedSlipIdentifiers: _storage.getDeletedSlips(),
        filePath: item.slipImageUrl,
        fileName: item.slipImageUrl != null ? DuplicateSlipChecker.extractBasename(item.slipImageUrl) : null,
        refId: item.slipRefId,
        amount: item.amount,
        date: item.date,
        bankName: item.bankName,
      );
      if (isDup) {
        return;
      }
    }

   _transactions.insert(0, item);

  // Update account balance
  final accIndex = _accounts.indexWhere((a) => a.id == item.accountId);
  if (accIndex != -1) {
   final acc = _accounts[accIndex];
   if (item.type == TransactionType.expense) {
    _accounts[accIndex] = acc.copyWith(balance: acc.balance - item.amount);
   } else if (item.type == TransactionType.income) {
    _accounts[accIndex] = acc.copyWith(balance: acc.balance + item.amount);
   } else if (item.type == TransactionType.transfer && item.targetAccountId != null) {
    _accounts[accIndex] = acc.copyWith(balance: acc.balance - item.amount);
    final targetIdx = _accounts.indexWhere((a) => a.id == item.targetAccountId);
    if (targetIdx != -1) {
     _accounts[targetIdx] = _accounts[targetIdx].copyWith(balance: _accounts[targetIdx].balance + item.amount);
    }
   }
  }

  await _storage.saveTransactions(_transactions);
  await _storage.saveAccounts(_accounts);
  await _checkAndUpdateStreakOnNewTransaction(item.date);
  await syncAndroidWidget();
  notifyListeners();
 }

  /// Updates an existing transaction in-place without triggering slip blacklisting
  Future<void> updateTransaction(TransactionItem updated) async {
    final idx = _transactions.indexWhere((t) => t.id == updated.id);
    if (idx == -1) {
      await addTransaction(updated);
      return;
    }

    final old = _transactions[idx];

    // Revert old balance
    final oldAccIdx = _accounts.indexWhere((a) => a.id == old.accountId);
    if (oldAccIdx != -1) {
      final acc = _accounts[oldAccIdx];
      if (old.type == TransactionType.expense) {
        _accounts[oldAccIdx] = acc.copyWith(balance: acc.balance + old.amount);
      } else if (old.type == TransactionType.income) {
        _accounts[oldAccIdx] = acc.copyWith(balance: acc.balance - old.amount);
      }
    }

    // Apply new balance
    final newAccIdx = _accounts.indexWhere((a) => a.id == updated.accountId);
    if (newAccIdx != -1) {
      final acc = _accounts[newAccIdx];
      if (updated.type == TransactionType.expense) {
        _accounts[newAccIdx] = acc.copyWith(balance: acc.balance - updated.amount);
      } else if (updated.type == TransactionType.income) {
        _accounts[newAccIdx] = acc.copyWith(balance: acc.balance + updated.amount);
      }
    }

    _transactions[idx] = updated;
    await _storage.saveTransactions(_transactions);
    await _storage.saveAccounts(_accounts);
    await syncAndroidWidget();
    notifyListeners();
  }

  /// Restores a previously deleted transaction and removes its slip from the blacklist
  Future<void> restoreTransaction(TransactionItem item) async {
    // Remove from blacklist so user can keep it
    final identifiers = <String>[];
    if (item.slipImageUrl != null && item.slipImageUrl!.isNotEmpty) {
      identifiers.add(item.slipImageUrl!);
      final bName = DuplicateSlipChecker.extractBasename(item.slipImageUrl!);
      if (bName.isNotEmpty) identifiers.add(bName);
    }
    if (item.slipRefId != null && item.slipRefId!.isNotEmpty && !item.slipRefId!.startsWith('SLIP-')) {
      identifiers.add(item.slipRefId!);
    }
    if (item.amount > 0) {
      final d = item.date;
      identifiers.add('fp_${item.amount}_${d.year}_${d.month}_${d.day}_${d.hour}_${d.minute}');
    }
    await _storage.removeDeletedSlipIdentifiers(identifiers);

    await addTransaction(item);
  }

  Future<void> deleteTransaction(String id, {bool recordToDeletedBlacklist = true}) async {
   final idx = _transactions.indexWhere((t) => t.id == id);
   if (idx != -1) {
    final item = _transactions[idx];
    // Revert account balance
    final accIndex = _accounts.indexWhere((a) => a.id == item.accountId);
    if (accIndex != -1) {
     final acc = _accounts[accIndex];
     if (item.type == TransactionType.expense) {
      _accounts[accIndex] = acc.copyWith(balance: acc.balance + item.amount);
     } else if (item.type == TransactionType.income) {
      _accounts[accIndex] = acc.copyWith(balance: acc.balance - item.amount);
     }
    }

    // Permanently record slip identifiers to the blacklist so auto-sync/refresh never re-imports it
    if (recordToDeletedBlacklist) {
      final identifiers = <String>[];
      if (item.slipImageUrl != null && item.slipImageUrl!.isNotEmpty) {
        identifiers.add(item.slipImageUrl!);
        final bName = DuplicateSlipChecker.extractBasename(item.slipImageUrl!);
        if (bName.isNotEmpty) identifiers.add(bName);
      }
      if (item.slipRefId != null && item.slipRefId!.isNotEmpty && !item.slipRefId!.startsWith('SLIP-')) {
        identifiers.add(item.slipRefId!);
      }
      if (item.amount > 0) {
        final d = item.date;
        identifiers.add('fp_${item.amount}_${d.year}_${d.month}_${d.day}_${d.hour}_${d.minute}');
      }
      await _storage.addDeletedSlipIdentifiers(identifiers);
    }

    _transactions.removeAt(idx);
    await _storage.saveTransactions(_transactions);
    await _storage.saveAccounts(_accounts);
    await syncAndroidWidget();
    notifyListeners();
   }
  }

  /// Clears the deleted slips blacklist (allows re-scanning old deleted slips if desired)
  Future<void> clearDeletedSlipsBlacklist() async {
    await _storage.clearDeletedSlips();
  }

 // SAVING GOALS CRUD & OPERATIONS
 Future<void> addSavingGoal(SavingGoalItem goal) async {
  _savingGoals.insert(0, goal);
  await _storage.saveSavingGoals(_savingGoals);
  notifyListeners();
 }

 Future<void> updateSavingGoal(SavingGoalItem goal) async {
  final idx = _savingGoals.indexWhere((g) => g.id == goal.id);
  if (idx != -1) {
   _savingGoals[idx] = goal;
   await _storage.saveSavingGoals(_savingGoals);
   notifyListeners();
  }
 }

 Future<void> deleteSavingGoal(String id) async {
  _savingGoals.removeWhere((g) => g.id == id);
  await _storage.saveSavingGoals(_savingGoals);
  notifyListeners();
 }

 Future<void> depositToSavingGoal(String goalId, double amount, {String? note, String? accountId}) async {
  final idx = _savingGoals.indexWhere((g) => g.id == goalId);
  if (idx != -1) {
   final goal = _savingGoals[idx];
   goal.currentAmount += amount;
   goal.depositHistory.insert(
    0,
    GoalDepositLog(
     id: 'dep_${DateTime.now().millisecondsSinceEpoch}',
     date: DateTime.now(),
     amount: amount,
     note: note,
    ),
   );
   if (goal.currentAmount >= goal.targetAmount) {
    goal.isCompleted = true;
    // Unlock Trophy & Wings on goal completion
    await unlockAccessory('trophy');
    await unlockAccessory('wings');
   }
   await _storage.saveSavingGoals(_savingGoals);

   // If accountId is provided, deduct balance
   if (accountId != null && accountId.isNotEmpty) {
    final accIdx = _accounts.indexWhere((a) => a.id == accountId);
    if (accIdx != -1) {
     _accounts[accIdx] = _accounts[accIdx].copyWith(balance: _accounts[accIdx].balance - amount);
     await _storage.saveAccounts(_accounts);
    }
   }
   notifyListeners();
  }
 }

 Future<void> withdrawFromSavingGoal(String goalId, double amount, {String? note, String? accountId}) async {
  final idx = _savingGoals.indexWhere((g) => g.id == goalId);
  if (idx != -1) {
   final goal = _savingGoals[idx];
   goal.currentAmount = (goal.currentAmount - amount).clamp(0.0, double.infinity);
   if (goal.currentAmount < goal.targetAmount) {
    goal.isCompleted = false;
   }
   await _storage.saveSavingGoals(_savingGoals);

   if (accountId != null && accountId.isNotEmpty) {
    final accIdx = _accounts.indexWhere((a) => a.id == accountId);
    if (accIdx != -1) {
     _accounts[accIdx] = _accounts[accIdx].copyWith(balance: _accounts[accIdx].balance + amount);
     await _storage.saveAccounts(_accounts);
    }
   }
   notifyListeners();
  }
 }

 Future<void> _checkAndUpdateStreakOnNewTransaction(DateTime txDate) async {
  final lastDate = _storage.getLastRecordedDate();
  final now = DateTime.now();
  int streak = _storage.getStreakDays();

  if (lastDate == null) {
   streak = 1;
  } else {
   final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
   final today = DateTime(now.year, now.month, now.day);
   final diff = today.difference(lastDay).inDays;

   if (diff == 1) {
    streak++;
   } else if (diff > 1) {
    streak = 1;
   }
  }

  await _storage.saveStreak(streak, now);

  // Check Streak Milestones & Unlocks
  if (streak >= 3) {
   await unlockAccessory('gold_shades');
  }
  if (streak >= 7) {
   await unlockAccessory('crown');
  }
  if (_transactions.length >= 20) {
   await unlockAccessory('party_hat');
  }
 }

 Future<void> unlockAccessory(String id) async {
  await _storage.unlockAccessory(id);
  notifyListeners();
 }

 Future<void> syncAndroidWidget() async {
  try {
   final now = DateTime.now();
   double todayIncome = 0.0;
   double todayExpense = 0.0;

   for (final tx in _transactions) {
    if (tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day) {
     if (tx.type == TransactionType.income) {
      todayIncome += tx.amount;
     } else if (tx.type == TransactionType.expense) {
      todayExpense += tx.amount;
     }
    }
   }

   final quota = getDailyFoodBudgetQuota();
   final monthlyExpense = totalExpenseThisMonth;

   await _widgetChannel.invokeMethod('updateWidgets', {
    'todayIncome': todayIncome,
    'todayExpense': todayExpense,
    'todayNet': todayIncome - todayExpense,
    'dailyQuota': quota,
    'monthlyExpense': monthlyExpense,
   });
  } catch (_) {}
 }

 // OCR & NLP
 SlipExtractResult parseSlip(String rawText, {String? defaultBankCode, String? fileName, String? filePath}) {
  return _ocrEngine.parseSlipText(
   rawText,
   _categories,
   defaultBankCode: defaultBankCode,
   fileName: fileName,
   filePath: filePath,
  );
 }

 ParsedNlpTransaction parseNlpSpeech(String text) {
  return _nlpParser.parseThaiSentence(text, _categories);
 }

 // EXCEL / CSV EXPORT
 String exportToExcelCsv() {
  return ExcelExportService.generateExcelCsv(
   transactions: _transactions,
   accounts: _accounts,
   reportTitle: 'สรุปบัญชีเหมียวตังค์ (Rizqi Financial Report)',
  );
 }

 // FILTER ACTIONS
 void setSearchQuery(String q) {
  _searchQuery = q;
  notifyListeners();
 }

 void setFilterType(TransactionType? type) {
  _filterType = type;
  notifyListeners();
 }

 void setFilterCategoryId(String? catId) {
  _filterCategoryId = catId;
  notifyListeners();
 }

 void setFilterAccountId(String? accId) {
  _filterAccountId = accId;
  notifyListeners();
 }

 void setFilterDateRange(DateTimeRange? range) {
  _filterDateRange = range;
  notifyListeners();
 }

 void clearFilters() {
  _searchQuery = '';
  _filterType = null;
  _filterCategoryId = null;
  _filterAccountId = null;
  _filterDateRange = null;
  notifyListeners();
 }

 AccountItem? getAccountById(String id) {
  try {
   return _accounts.firstWhere((a) => a.id == id);
  } catch (_) {
   return null;
  }
 }

 // RECURRING TRANSACTIONS & SCHEDULING
 Future<void> addRecurringTransaction(
  TransactionItem template, {
  required String frequency, // 'daily', 'weekly', 'monthly', 'yearly'
  DateTime? untilDate,
  int repeatCount = 12,
 }) async {
  final recurringId = 'rec_${DateTime.now().millisecondsSinceEpoch}';
  final List<TransactionItem> generatedItems = [];

  DateTime curDate = template.date;
  final maxDate = untilDate ?? DateTime(curDate.year + 2, 12, 31);
  final limit = repeatCount.clamp(1, 365);

  for (int i = 0; i < limit; i++) {
   if (curDate.isAfter(maxDate)) break;

   final isFirst = i == 0;
   final item = template.copyWith(
    id: isFirst ? template.id : '${template.id}_rep_$i',
    date: curDate,
    isRecurring: true,
    recurrenceFrequency: frequency,
    recurrenceEndDate: untilDate,
    parentRecurringId: recurringId,
   );
   generatedItems.add(item);

   // Advance date
   if (frequency == 'daily') {
    curDate = curDate.add(const Duration(days: 1));
   } else if (frequency == 'weekly') {
    curDate = curDate.add(const Duration(days: 7));
   } else if (frequency == 'monthly') {
    final nextM = curDate.month == 12 ? 1 : curDate.month + 1;
    final nextY = curDate.month == 12 ? curDate.year + 1 : curDate.year;
    final maxD = DateTime(nextY, nextM + 1, 0).day;
    final nextDay = curDate.day > maxD ? maxD : curDate.day;
    curDate = DateTime(nextY, nextM, nextDay, curDate.hour, curDate.minute);
   } else if (frequency == 'yearly') {
    curDate = DateTime(curDate.year + 1, curDate.month, curDate.day, curDate.hour, curDate.minute);
   } else {
    break;
   }
  }

  // Insert all generated items
  for (final item in generatedItems) {
   _transactions.add(item);
  }
  // Sort descending by date
  _transactions.sort((a, b) => b.date.compareTo(a.date));

  // Update account balance with the first item
  final firstItem = generatedItems.first;
  final accIndex = _accounts.indexWhere((a) => a.id == firstItem.accountId);
  if (accIndex != -1) {
   final acc = _accounts[accIndex];
   if (firstItem.type == TransactionType.expense) {
    _accounts[accIndex] = acc.copyWith(balance: acc.balance - firstItem.amount);
   } else if (firstItem.type == TransactionType.income) {
    _accounts[accIndex] = acc.copyWith(balance: acc.balance + firstItem.amount);
   }
  }

  await _storage.saveTransactions(_transactions);
  await _storage.saveAccounts(_accounts);
  await _checkAndUpdateStreakOnNewTransaction(firstItem.date);
  await syncAndroidWidget();
  notifyListeners();
 }

 // FREQUENT TAGS
 List<String> getFrequentTagsForCategory(String categoryId, {TransactionType? type}) {
  final tagCounts = <String, int>{};
  for (final tx in _transactions) {
   if (tx.categoryId == categoryId && (type == null || tx.type == type)) {
    for (final tag in tx.tags) {
     final clean = tag.trim();
     if (clean.isNotEmpty) {
      tagCounts[clean] = (tagCounts[clean] ?? 0) + 1;
     }
    }
   }
  }
  final sorted = tagCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return sorted.map((e) => e.key).toList();
 }

 List<String> getAllUsedTags({TransactionType? type}) {
  final tagCounts = <String, int>{};
  for (final tx in _transactions) {
   if (type == null || tx.type == type) {
    for (final tag in tx.tags) {
     final clean = tag.trim();
     if (clean.isNotEmpty) {
      tagCounts[clean] = (tagCounts[clean] ?? 0) + 1;
     }
    }
   }
  }
  final sorted = tagCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return sorted.map((e) => e.key).toList();
 }

 // 2-MONTH COMPARISON HELPER (ENRICHED & DETAILED)
 Map<String, dynamic> compareTwoMonths(DateTime monthA, DateTime monthB) {
  double incomeA = 0.0;
  double expenseA = 0.0;
  int txCountA = 0;
  final Map<String, double> catExpenseA = {};
  final Map<String, int> catTxCountA = {};
  final Map<String, double> catIncomeA = {};
  final Map<int, double> dailyExpenseA = {};

  double incomeB = 0.0;
  double expenseB = 0.0;
  int txCountB = 0;
  final Map<String, double> catExpenseB = {};
  final Map<String, int> catTxCountB = {};
  final Map<String, double> catIncomeB = {};
  final Map<int, double> dailyExpenseB = {};

  for (final tx in _transactions) {
   if (tx.date.year == monthA.year && tx.date.month == monthA.month) {
    txCountA++;
    if (tx.type == TransactionType.income) {
     incomeA += tx.amount;
     catIncomeA[tx.categoryId] = (catIncomeA[tx.categoryId] ?? 0.0) + tx.amount;
    } else if (tx.type == TransactionType.expense) {
     expenseA += tx.amount;
     catExpenseA[tx.categoryId] = (catExpenseA[tx.categoryId] ?? 0.0) + tx.amount;
     catTxCountA[tx.categoryId] = (catTxCountA[tx.categoryId] ?? 0) + 1;
     dailyExpenseA[tx.date.day] = (dailyExpenseA[tx.date.day] ?? 0.0) + tx.amount;
    }
   } else if (tx.date.year == monthB.year && tx.date.month == monthB.month) {
    txCountB++;
    if (tx.type == TransactionType.income) {
     incomeB += tx.amount;
     catIncomeB[tx.categoryId] = (catIncomeB[tx.categoryId] ?? 0.0) + tx.amount;
    } else if (tx.type == TransactionType.expense) {
     expenseB += tx.amount;
     catExpenseB[tx.categoryId] = (catExpenseB[tx.categoryId] ?? 0.0) + tx.amount;
     catTxCountB[tx.categoryId] = (catTxCountB[tx.categoryId] ?? 0) + 1;
     dailyExpenseB[tx.date.day] = (dailyExpenseB[tx.date.day] ?? 0.0) + tx.amount;
    }
   }
  }

  final double netA = incomeA - expenseA;
  final double netB = incomeB - expenseB;

  final double incomeDelta = incomeA - incomeB;
  final double incomeDeltaPct = incomeB > 0 ? (incomeDelta / incomeB) * 100 : (incomeA > 0 ? 100.0 : 0.0);

  final double expenseDelta = expenseA - expenseB;
  final double expenseDeltaPct = expenseB > 0 ? (expenseDelta / expenseB) * 100 : (expenseA > 0 ? 100.0 : 0.0);

  final double netDelta = netA - netB;

  final int daysInMonthA = DateTime(monthA.year, monthA.month + 1, 0).day;
  final int daysInMonthB = DateTime(monthB.year, monthB.month + 1, 0).day;

  final double dailyAvgExpenseA = daysInMonthA > 0 ? expenseA / daysInMonthA : 0.0;
  final double dailyAvgExpenseB = daysInMonthB > 0 ? expenseB / daysInMonthB : 0.0;
  final double dailyAvgExpenseDelta = dailyAvgExpenseA - dailyAvgExpenseB;

  final double savingsRateA = incomeA > 0 ? ((netA > 0 ? netA : 0.0) / incomeA) * 100 : 0.0;
  final double savingsRateB = incomeB > 0 ? ((netB > 0 ? netB : 0.0) / incomeB) * 100 : 0.0;
  final double savingsRateDelta = savingsRateA - savingsRateB;

  // Build category comparisons
  final allCategoryIds = {...catExpenseA.keys, ...catExpenseB.keys};
  final List<Map<String, dynamic>> categoryDeltas = [];

  for (final catId in allCategoryIds) {
   final amountA = catExpenseA[catId] ?? 0.0;
   final amountB = catExpenseB[catId] ?? 0.0;
   final countA = catTxCountA[catId] ?? 0;
   final countB = catTxCountB[catId] ?? 0;
   final diff = amountA - amountB;
   final diffPct = amountB > 0 ? (diff / amountB) * 100 : (amountA > 0 ? 100.0 : 0.0);

   final cat = _categories.firstWhere(
    (c) => c.id == catId,
    orElse: () => CategoryItem(
     id: catId,
     name: 'หมวดหมู่ทั่วไป',
     iconKey: 'category',
     colorValue: 0xFFF59E0B,
     type: CategoryType.expense,
    ),
   );

   categoryDeltas.add({
    'categoryId': catId,
    'name': cat.name,
    'iconKey': cat.iconKey,
    'colorValue': cat.colorValue,
    'amountA': amountA,
    'amountB': amountB,
    'countA': countA,
    'countB': countB,
    'delta': diff,
    'deltaPercent': diffPct,
    'isNew': amountB == 0 && amountA > 0,
   });
  }

  categoryDeltas.sort((a, b) => (b['amountA'] as double).compareTo(a['amountA'] as double));

  // Find Top Spike and Top Saved
  Map<String, dynamic>? topSpike;
  Map<String, dynamic>? topSaved;

  for (final c in categoryDeltas) {
   final d = c['delta'] as double;
   if (d > 0) {
    if (topSpike == null || d > (topSpike['delta'] as double)) {
     topSpike = c;
    }
   } else if (d < 0) {
    if (topSaved == null || d < (topSaved['delta'] as double)) {
     topSaved = c;
    }
   }
  }

  // Cumulative calculations
  final List<double> cumulativeA = [];
  double runningA = 0;
  for (int day = 1; day <= daysInMonthA; day++) {
   runningA += (dailyExpenseA[day] ?? 0.0);
   cumulativeA.add(runningA);
  }

  final List<double> cumulativeB = [];
  double runningB = 0;
  for (int day = 1; day <= daysInMonthB; day++) {
   runningB += (dailyExpenseB[day] ?? 0.0);
   cumulativeB.add(runningB);
  }

  // Smart Verdict
  String verdictTitle;
  String verdictDesc;
  bool verdictIsPositive;

  if (expenseDelta <= 0 && netDelta >= 0) {
   verdictIsPositive = true;
   verdictTitle = ' วินัยการเงินยอดเยี่ยม! เดือน A บริหารเงินได้ดีกว่า';
   verdictDesc = 'คุณประหยัดรายจ่ายลง ฿${expenseDelta.abs().toStringAsFixed(0)} (${expenseDeltaPct.abs().toStringAsFixed(1)}%) และมีเงินออมสุทธิเพิ่มขึ้น ฿${netDelta.abs().toStringAsFixed(0)}';
  } else if (expenseDelta > 0 && netDelta < 0) {
   verdictIsPositive = false;
   verdictTitle = ' เดือน A มีการใช้จ่ายเพิ่มขึ้น';
   final spikeName = topSpike != null ? ' โดยเฉพาะหมวด "${topSpike['name']}"' : '';
   verdictDesc = 'รายจ่ายเพิ่มขึ้น ฿${expenseDelta.toStringAsFixed(0)} (+${expenseDeltaPct.toStringAsFixed(1)}%)$spikeName ควรระมัดระวังการใช้จ่าย';
  } else {
   verdictIsPositive = netA >= 0;
   verdictTitle = ' สรุปภาพรวมทางการเงิน';
   verdictDesc = 'รายรับ ${incomeDelta >= 0 ? "+" : ""}${incomeDelta.toStringAsFixed(0)}฿, รายจ่าย ${expenseDelta >= 0 ? "+" : ""}${expenseDelta.toStringAsFixed(0)}฿, เงินคงเหลือสุทธิ ฿${netA.toStringAsFixed(0)}';
  }

  return {
   'incomeA': incomeA,
   'incomeB': incomeB,
   'incomeDelta': incomeDelta,
   'incomeDeltaPercent': incomeDeltaPct,
   'expenseA': expenseA,
   'expenseB': expenseB,
   'expenseDelta': expenseDelta,
   'expenseDeltaPercent': expenseDeltaPct,
   'netA': netA,
   'netB': netB,
   'netDelta': netDelta,
   'txCountA': txCountA,
   'txCountB': txCountB,
   'txCountDelta': txCountA - txCountB,
   'daysInMonthA': daysInMonthA,
   'daysInMonthB': daysInMonthB,
   'dailyAvgExpenseA': dailyAvgExpenseA,
   'dailyAvgExpenseB': dailyAvgExpenseB,
   'dailyAvgExpenseDelta': dailyAvgExpenseDelta,
   'savingsRateA': savingsRateA,
   'savingsRateB': savingsRateB,
   'savingsRateDelta': savingsRateDelta,
   'topSpike': topSpike,
   'topSaved': topSaved,
   'categoryDeltas': categoryDeltas,
   'cumulativeA': cumulativeA,
   'cumulativeB': cumulativeB,
   'verdictTitle': verdictTitle,
   'verdictDescription': verdictDesc,
   'verdictIsPositive': verdictIsPositive,
  };
 }
}
