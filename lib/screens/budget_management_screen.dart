import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/category_item.dart';
import '../state/expense_controller.dart';
import '../models/transaction_item.dart';
import '../theme/app_theme_model.dart';
import '../widgets/meow_fx.dart';
import '../utils/format_utils.dart';

enum BudgetPlanScope { monthly, multiMonth, yearly }

class BudgetManagementScreen extends StatefulWidget {
  final ExpenseController controller;

  const BudgetManagementScreen({super.key, required this.controller});

  @override
  State<BudgetManagementScreen> createState() => _BudgetManagementScreenState();
}

class _BudgetManagementScreenState extends State<BudgetManagementScreen> {
  late bool _isEnabled;
  late double _totalBudget;
  late Map<String, double> _budgets;
  late DateTime _selectedMonth;
  late DateTime _multiMonthEnd;
  late int _selectedYear;
  BudgetPlanScope _selectedScope = BudgetPlanScope.monthly;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.controller.isBudgetPlanEnabled;
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    _multiMonthEnd = DateTime(now.year, (now.month + 2 > 12) ? 12 : now.month + 2, 1);
    _selectedYear = now.year;
    _loadBudgetsForCurrentScope();
  }

  String get _currentScopeKey {
    if (_selectedScope == BudgetPlanScope.monthly) {
      return 'month_${_selectedMonth.year}_${_selectedMonth.month.toString().padLeft(2, '0')}';
    } else if (_selectedScope == BudgetPlanScope.multiMonth) {
      return 'multi_${_selectedMonth.year}_${_selectedMonth.month.toString().padLeft(2, '0')}_${_multiMonthEnd.year}_${_multiMonthEnd.month.toString().padLeft(2, '0')}';
    } else {
      return 'year_$_selectedYear';
    }
  }

  void _loadBudgetsForCurrentScope() {
    final key = _currentScopeKey;
    final loadedBudgets = widget.controller.getCategoryBudgetsForScope(key);
    final loadedTotal = widget.controller.getTotalBudgetForScope(key);

    setState(() {
      _budgets = Map<String, double>.from(loadedBudgets);
      _totalBudget = loadedTotal;
    });
  }

  void _saveCurrentBudgets() {
    final key = _currentScopeKey;
    widget.controller.saveCategoryBudgetsForScope(key, _budgets);
    widget.controller.saveTotalBudgetForScope(key, _totalBudget);
  }

  String _formatThaiMonth(DateTime dt) {
    const months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    return '${months[dt.month - 1]} ${dt.year + 543}';
  }

  String _formatThaiMonthShort(DateTime dt) {
    const months = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
    return '${months[dt.month - 1]} ${dt.year + 543}';
  }

  CategoryItem _findCategoryItem(String name) {
    return widget.controller.categories.firstWhere(
      (c) => c.name.trim().toLowerCase() == name.trim().toLowerCase(),
      orElse: () => CategoryItem(
        id: 'cat_custom',
        name: name,
        iconKey: 'category',
        colorValue: 0xFF10B981,
        type: CategoryType.expense,
      ),
    );
  }

  void _showEditTotalBudgetDialog() {
    HapticFeedback.selectionClick();
    final currentTheme = widget.controller.currentTheme;
    final ctrl = TextEditingController(text: _totalBudget > 0 ? _totalBudget.toStringAsFixed(0) : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: currentTheme.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ตั้งค่างบประมาณรวม ($_scopeTitleLabel)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: currentTheme.textColor),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: TextStyle(color: currentTheme.textColor, fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'ระบุยอดงบประมาณ เช่น 15000',
                hintStyle: TextStyle(color: currentTheme.textSecondaryColor, fontSize: 14),
                prefixText: '฿ ',
                prefixStyle: TextStyle(color: currentTheme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: currentTheme.surfaceBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final val = double.tryParse(ctrl.text.replaceAll(',', '').trim()) ?? 0.0;
                  setState(() {
                    _totalBudget = val;
                  });
                  _saveCurrentBudgets();
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('บันทึกงบประมาณรวม', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _scopeTitleLabel {
    if (_selectedScope == BudgetPlanScope.monthly) {
      return _formatThaiMonth(_selectedMonth);
    } else if (_selectedScope == BudgetPlanScope.multiMonth) {
      return '${_formatThaiMonthShort(_selectedMonth)} - ${_formatThaiMonthShort(_multiMonthEnd)}';
    } else {
      return 'ประจำปี ${_selectedYear + 543}';
    }
  }

  void _showAddOrEditCategoryDialog({String? existingName, double? existingAmount}) {
    HapticFeedback.selectionClick();
    final currentTheme = widget.controller.currentTheme;
    final nameCtrl = TextEditingController(text: existingName ?? '');
    final amountCtrl = TextEditingController(text: existingAmount != null ? existingAmount.toStringAsFixed(0) : '');

    // Get exact expense categories from (+) button
    final expenseCategories = widget.controller.expenseCategories;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: currentTheme.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                existingName != null ? 'แก้ไขงบหมวดหมู่' : 'เลือกหมวดหมู่เพื่อตั้งงบ ($_scopeTitleLabel)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: currentTheme.textColor),
              ),
              const SizedBox(height: 12),

              // Categories Grid from (+) button with real icons
              if (existingName == null) ...[
                Text(
                  'หมวดหมู่จากหน้าเพิ่มรายจ่าย (แตะเพื่อเลือก):',
                  style: TextStyle(fontSize: 11.5, color: currentTheme.textSecondaryColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: expenseCategories.map((cat) {
                        final isSel = nameCtrl.text == cat.name;
                        final catColor = Color(cat.colorValue);
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setSheetState(() {
                              nameCtrl.text = cat.name;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? currentTheme.primaryColor : currentTheme.surfaceBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSel ? currentTheme.primaryColor : currentTheme.borderColor,
                                width: isSel ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isSel ? Colors.white.withValues(alpha: 0.2) : catColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    cat.icon,
                                    size: 14,
                                    color: isSel ? Colors.white : catColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  cat.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSel ? Colors.white : currentTheme.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Category Name Input
              TextField(
                controller: nameCtrl,
                enabled: existingName == null,
                style: TextStyle(color: currentTheme.textColor, fontSize: 14, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'ชื่อหมวดหมู่ (เลือกจากด้านบน หรือพิมพ์เพิ่มใหม่)',
                  labelStyle: TextStyle(color: currentTheme.textSecondaryColor, fontSize: 12.5),
                  filled: true,
                  fillColor: currentTheme.surfaceBackground,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
                ),
              ),
              const SizedBox(height: 10),

              // Amount Input
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                autofocus: existingName != null,
                style: TextStyle(color: currentTheme.textColor, fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'จำนวนเงินงบประมาณสำหรับหมวดนี้',
                  labelStyle: TextStyle(color: currentTheme.textSecondaryColor, fontSize: 13),
                  prefixText: '฿ ',
                  prefixStyle: TextStyle(color: currentTheme.primaryColor, fontSize: 16, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: currentTheme.surfaceBackground,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
                ),
              ),
              const SizedBox(height: 16),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final amt = double.tryParse(amountCtrl.text.replaceAll(',', '').trim()) ?? 0.0;
                    if (name.isNotEmpty && amt > 0) {
                      setState(() {
                        _budgets[name] = amt;
                      });
                      _saveCurrentBudgets();
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(existingName != null ? 'บันทึกการแก้ไข' : 'เพิ่มหมวดงบประมาณนี้', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              if (existingName != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton.icon(
                    onPressed: () async {
                      final ok = await _confirmRemove(existingName);
                      if (ok && ctx.mounted) Navigator.pop(ctx);
                    },
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('ลบงบหมวดนี้', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _removeCategoryBudget(String category) {
    HapticFeedback.mediumImpact();
    setState(() {
      _budgets.remove(category);
    });
    _saveCurrentBudgets();
  }

  Future<bool> _confirmRemove(String category) async {
    final theme = widget.controller.currentTheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('ลบงบหมวด "$category"?', style: TextStyle(color: theme.textColor, fontSize: 17)),
        content: Text('ยอดใช้จ่ายของหมวดนี้ยังอยู่ครบ แค่เลิกตั้งงบใน$_scopeTitleLabel',
            style: TextStyle(color: theme.textSecondaryColor, fontSize: 13.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (ok == true) {
      _removeCategoryBudget(category);
      return true;
    }
    return false;
  }

  /// First and last day (exclusive) of the selected planning scope.
  (DateTime, DateTime) get _scopeRange {
    if (_selectedScope == BudgetPlanScope.monthly) {
      return (_selectedMonth, DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1));
    } else if (_selectedScope == BudgetPlanScope.multiMonth) {
      return (_selectedMonth, DateTime(_multiMonthEnd.year, _multiMonthEnd.month + 1, 1));
    }
    return (DateTime(_selectedYear, 1, 1), DateTime(_selectedYear + 1, 1, 1));
  }

  double get _spentInScope {
    final (from, to) = _scopeRange;
    return widget.controller.transactions
        .where((t) => t.type == TransactionType.expense && !t.date.isBefore(from) && t.date.isBefore(to))
        .fold(0.0, (s, t) => s + t.amount);
  }

  String get _scopeName => switch (_selectedScope) {
        BudgetPlanScope.monthly => 'รายเดือน',
        BudgetPlanScope.multiMonth => 'หลายเดือน',
        BudgetPlanScope.yearly => 'รายปี',
      };

  void _shiftScope(int dir) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedScope == BudgetPlanScope.monthly) {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + dir, 1);
      } else if (_selectedScope == BudgetPlanScope.multiMonth) {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 3 * dir, 1);
        _multiMonthEnd = DateTime(_selectedMonth.year, _selectedMonth.month + 2, 1);
      } else {
        _selectedYear += dir;
      }
    });
    _loadBudgetsForCurrentScope();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.controller.currentTheme;
    final isDark = widget.controller.isDarkMode;
    var i = 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: Column(
        children: [
          _header(theme),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _scopeTabs(theme),
                const SizedBox(height: 16),
                _scopeNavigator(theme, isDark),
                const SizedBox(height: 16),
                FxFadeUp(key: ValueKey('hero$_currentScopeKey'), index: i++, child: _hero(theme, isDark)),
                const SizedBox(height: 16),
                FxFadeUp(key: ValueKey('list$_currentScopeKey'), index: i++, child: _categorySection(theme, isDark)),
                const SizedBox(height: 16),
                _overviewToggle(theme, isDark),
              ],
            ),
          ),
          _bottomBar(theme),
        ],
      ),
    );
  }

  Widget _header(AppThemeModel theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(bottom: BorderSide(color: theme.borderColor)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              IconButton(
                tooltip: 'ย้อนกลับ',
                constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                padding: EdgeInsets.zero,
                icon: Icon(Icons.chevron_left_rounded, color: theme.textColor, size: 28),
                onPressed: () => Navigator.maybePop(context),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text('วางแผนงบประมาณ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scopeTabs(AppThemeModel theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: theme.borderColor, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          _buildScopeTabItem('รายเดือน', BudgetPlanScope.monthly, theme),
          const SizedBox(width: 4),
          _buildScopeTabItem('หลายเดือน', BudgetPlanScope.multiMonth, theme),
          const SizedBox(width: 4),
          _buildScopeTabItem('รายปี', BudgetPlanScope.yearly, theme),
        ],
      ),
    );
  }

  Widget _navButton(AppThemeModel theme, IconData icon, String tip, VoidCallback onTap) {
    return Material(
      color: theme.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Tooltip(
          message: tip,
          child: SizedBox(width: 44, height: 44, child: Icon(icon, size: 24, color: theme.textColor)),
        ),
      ),
    );
  }

  Widget _scopeNavigator(AppThemeModel theme, bool isDark) {
    final unit = switch (_selectedScope) {
      BudgetPlanScope.monthly => 'เดือน',
      BudgetPlanScope.multiMonth => 'ช่วง',
      BudgetPlanScope.yearly => 'ปี',
    };
    return Row(
      children: [
        _navButton(theme, Icons.chevron_left_rounded, '$unitก่อนหน้า', () => _shiftScope(-1)),
        Expanded(
          child: Text(
            _scopeTitleLabel,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textColor),
          ),
        ),
        _navButton(theme, Icons.chevron_right_rounded, '$unitถัดไป', () => _shiftScope(1)),
      ],
    );
  }

  Widget _hero(AppThemeModel theme, bool isDark) {
    final heroText = theme.heroTextColor(isDark);
    final heroMuted = theme.heroTextMutedColor(isDark);
    final totalAllocated = _budgets.values.fold(0.0, (sum, val) => sum + val);
    final remainingAlloc = (_totalBudget - totalAllocated).clamp(0.0, double.infinity);
    final spent = _spentInScope;
    final left = _totalBudget - spent;
    final ratio = _totalBudget > 0 ? (spent / _totalBudget) : 0.0;

    Widget tile(String label, double value) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: heroText.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: heroMuted)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: _countUp(value, TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: heroText)),
                ),
              ],
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: theme.heroGradient, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: FxProgress(
                  value: ratio.clamp(0.0, 1.0),
                  duration: const Duration(milliseconds: 1000),
                  builder: (_, v) => CustomPaint(
                    painter: _RingPainter(
                      value: v,
                      track: heroText.withValues(alpha: 0.2),
                      color: ratio > 1 ? const Color(0xFFFCA5A5) : heroText,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${(ratio > 1 ? ratio * 100 : v * 100).round()}%',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: heroText, height: 1.2)),
                          Text('ใช้ไป', style: TextStyle(fontSize: 12, color: heroMuted, height: 1.2)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('งบประมาณรวม ($_scopeName)', style: TextStyle(fontSize: 12.5, color: heroMuted)),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: _totalBudget <= 0
                          ? Text('ยังไม่ได้ตั้งงบ',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: heroText))
                          : _countUp(left.abs(), TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: heroText),
                              prefix: left >= 0 ? 'เหลือ ' : 'เกินงบ '),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _totalBudget > 0 ? 'ใช้ไป ${_baht(spent)} จาก ${_baht(_totalBudget)}' : 'ใช้ไป ${_baht(spent)}',
                      style: TextStyle(fontSize: 13, color: heroMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(children: [tile('จัดสรรแล้ว', totalAllocated), const SizedBox(width: 8), tile('คงเหลือจัดสรร', remainingAlloc)]),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _showEditTotalBudgetDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: heroText,
              minimumSize: const Size.fromHeight(44),
              side: BorderSide(color: heroText.withValues(alpha: 0.4), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _totalBudget > 0 ? 'แก้ไขงบประมาณรวม ${_baht(_totalBudget)}' : 'ตั้งงบประมาณรวม',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(AppThemeModel theme, bool isDark, {double radius = 20}) => BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(radius),
        border: isDark ? Border.all(color: theme.borderColor) : null,
        boxShadow: isDark ? null : const [BoxShadow(color: Color(0x0F0F172A), blurRadius: 14, offset: Offset(0, 4))],
      );

  Widget _categorySection(AppThemeModel theme, bool isDark) {
    final entries = _budgets.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'จัดสรรงบรายหมวด '),
              TextSpan(
                text: '· ${entries.length}',
                style: TextStyle(fontWeight: FontWeight.w500, color: theme.textSecondaryColor),
              ),
            ]),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textColor),
          ),
        ),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: _cardDecoration(theme, isDark),
            child: Column(
              children: [
                Icon(Icons.pie_chart_outline_rounded, size: 36, color: theme.textSecondaryColor),
                const SizedBox(height: 10),
                Text(
                  'ยังไม่มีการจัดสรรหมวดหมู่งบประมาณใน$_scopeTitleLabel',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'แตะ "+ ตั้งงบหมวดใหม่" ด้านล่างเพื่อกำหนดงบตามใจคุณ',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: theme.textSecondaryColor),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: _cardDecoration(theme, isDark),
            child: Column(
              children: [
                for (var k = 0; k < entries.length; k++)
                  _categoryRow(entries[k].key, entries[k].value, theme, isDark, last: k == entries.length - 1),
              ],
            ),
          ),
      ],
    );
  }

  Widget _categoryRow(String catName, double budgetAmt, AppThemeModel theme, bool isDark, {required bool last}) {
    final spentAmt = widget.controller.getSpentForCategoryThisMonth(catName);
    final isOver = spentAmt > budgetAmt && budgetAmt > 0;
    final isNear = !isOver && spentAmt >= budgetAmt * 0.8 && budgetAmt > 0;
    final progress = budgetAmt > 0 ? (spentAmt / budgetAmt).clamp(0.0, 1.0) : 0.0;
    final catItem = _findCategoryItem(catName);
    final catColor = Color(catItem.colorValue);
    final warnColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
    final overColor = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
    final amountColor = isOver ? overColor : (isNear ? warnColor : theme.textSecondaryColor);
    final barColor = isOver ? const Color(0xFFEF4444) : (isNear ? const Color(0xFFF59E0B) : theme.primaryColor);

    return InkWell(
      onTap: () => _showAddOrEditCategoryDialog(existingName: catName, existingAmount: budgetAmt),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: theme.borderColor)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: isDark ? 0.22 : 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(catItem.icon, size: 20, color: catColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(catName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textColor)),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${_baht(spentAmt)} / ${_baht(budgetAmt)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: amountColor,
                              fontWeight: isOver || isNear ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  FxBar(
                    value: progress,
                    color: barColor,
                    track: isDark ? theme.borderColor : const Color(0xFFE9EDF3),
                    height: 6,
                  ),
                  if (isOver || isNear) ...[
                    const SizedBox(height: 6),
                    Text(
                      isOver
                          ? 'เกินงบ ${_baht(spentAmt - budgetAmt)} แล้ว'
                          : 'ใช้ไป ${(spentAmt / budgetAmt * 100).round()}% แล้ว • ระวังเกินงบ',
                      style: TextStyle(fontSize: 12, color: isOver ? overColor : warnColor),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overviewToggle(AppThemeModel theme, bool isDark) {
    return Material(
      color: theme.cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _setEnabled(!_isEnabled),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Checkbox(
                  value: !_isEnabled,
                  activeColor: theme.primaryColor,
                  side: BorderSide(color: theme.textSecondaryColor, width: 1.5),
                  onChanged: (v) => _setEnabled(!(v ?? false)),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('ปิดการแสดงผลในหน้าภาพรวม',
                      style: TextStyle(fontSize: 13.5, color: theme.textColor)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setEnabled(bool val) {
    HapticFeedback.lightImpact();
    setState(() {
      _isEnabled = val;
    });
    widget.controller.setBudgetPlanEnabled(val);
  }

  Widget _bottomBar(AppThemeModel theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(top: BorderSide(color: theme.borderColor)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: SafeArea(
        top: false,
        child: FilledButton(
          onPressed: () => _showAddOrEditCategoryDialog(),
          style: FilledButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: const Text('+ ตั้งงบหมวดใหม่', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _countUp(double value, TextStyle style, {String prefix = ''}) => FxProgress(
        value: value,
        builder: (_, v) => Text('$prefix${_baht(v == value ? v : v.roundToDouble())}', style: style, maxLines: 1),
      );

  Widget _buildScopeTabItem(String label, BudgetPlanScope scope, AppThemeModel theme) {
    final isSel = _selectedScope == scope;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedScope = scope;
          });
          _loadBudgetsForCurrentScope();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSel ? theme.cardBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSel ? const [BoxShadow(color: Color(0x1A0F172A), blurRadius: 4, offset: Offset(0, 1))] : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
              color: isSel ? (theme.isDark ? theme.textColor : theme.primaryColor) : theme.textSecondaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

String _baht(double v) => '฿${FormatUtils.formatMoney(v, trimZero: true)}';

class _RingPainter extends CustomPainter {
  final double value;
  final Color track;
  final Color color;

  _RingPainter({required this.value, required this.track, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.shortestSide / 2 - stroke / 2 - 3);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 6.2832, false, p..color = track);
    if (value > 0) canvas.drawArc(rect, -1.5708, 6.2832 * value.clamp(0.0, 1.0), false, p..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.color != color || old.track != track;
}
