import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/category_item.dart';
import '../state/expense_controller.dart';
import '../widgets/tactile_button.dart';
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

  @override
  Widget build(BuildContext context) {
    final currentTheme = widget.controller.currentTheme;
    final isDark = widget.controller.isDarkMode;
    final totalAllocated = _budgets.values.fold(0.0, (sum, val) => sum + val);
    final remainingBudget = (_totalBudget - totalAllocated).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: currentTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: currentTheme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: currentTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'วางแผนงบประมาณ',
          style: TextStyle(color: currentTheme.textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 0. Switch On/Off Card for Budget Planning
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: currentTheme.cardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isEnabled ? currentTheme.primaryColor.withValues(alpha: 0.4) : currentTheme.borderColor,
                  width: _isEnabled ? 1.2 : 1,
                ),
                boxShadow: [
                  if (_isEnabled)
                    BoxShadow(
                      color: currentTheme.primaryColor.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isEnabled
                              ? currentTheme.primaryColor.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: _isEnabled ? currentTheme.primaryColor : Colors.grey,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'เปิดใช้งานวางแผนงบประมาณ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: currentTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _isEnabled ? 'แสดงหลอดเกจในหน้าภาพรวม' : 'ปิดการแสดงผลในหน้าภาพรวม',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: _isEnabled ? currentTheme.primaryColor : currentTheme.textSecondaryColor,
                              fontWeight: _isEnabled ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Switch.adaptive(
                    value: _isEnabled,
                    activeColor: currentTheme.primaryColor,
                    onChanged: (val) {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _isEnabled = val;
                      });
                      widget.controller.setBudgetPlanEnabled(val);
                    },
                  ),
                ],
              ),
            ),

            // 1. Flexible Planning Scope Selector (รายเดือน / หลายเดือน / รายปี)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: currentTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: currentTheme.borderColor),
              ),
              child: Row(
                children: [
                  _buildScopeTabItem('รายเดือน', BudgetPlanScope.monthly, currentTheme),
                  _buildScopeTabItem('หลายเดือน', BudgetPlanScope.multiMonth, currentTheme),
                  _buildScopeTabItem('รายปี', BudgetPlanScope.yearly, currentTheme),
                ],
              ),
            ),

            // 2. Scope Date Range Controller Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: currentTheme.cardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: currentTheme.borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded, color: currentTheme.textColor),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (_selectedScope == BudgetPlanScope.monthly) {
                          _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
                        } else if (_selectedScope == BudgetPlanScope.multiMonth) {
                          _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 3, 1);
                          _multiMonthEnd = DateTime(_selectedMonth.year, _selectedMonth.month + 2, 1);
                        } else {
                          _selectedYear -= 1;
                        }
                      });
                      _loadBudgetsForCurrentScope();
                    },
                  ),
                  Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 16, color: currentTheme.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        _scopeTitleLabel,
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded, color: currentTheme.textColor),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (_selectedScope == BudgetPlanScope.monthly) {
                          _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
                        } else if (_selectedScope == BudgetPlanScope.multiMonth) {
                          _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 3, 1);
                          _multiMonthEnd = DateTime(_selectedMonth.year, _selectedMonth.month + 2, 1);
                        } else {
                          _selectedYear += 1;
                        }
                      });
                      _loadBudgetsForCurrentScope();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Main Total Budget Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: currentTheme.heroGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: currentTheme.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'งบประมาณรวม ($_scopeTitleLabel)',
                        style: TextStyle(
                          color: (currentTheme.primaryColor.computeLuminance() > 0.55) ? Colors.black87 : Colors.white70,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showEditTotalBudgetDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.edit, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text('ตั้งงบ', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _totalBudget > 0 ? '฿ ${FormatUtils.formatMoney(_totalBudget)}' : '฿ 0.00 (ยังไม่มียอด)',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'จัดสรรแล้ว',
                              style: TextStyle(
                                color: (currentTheme.primaryColor.computeLuminance() > 0.55) ? Colors.black54 : Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '฿ ${FormatUtils.formatMoney(totalAllocated)}',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'คงเหลือจัดสรร',
                              style: TextStyle(
                                color: (currentTheme.primaryColor.computeLuminance() > 0.55) ? Colors.black54 : Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '฿ ${FormatUtils.formatMoney(remainingBudget)}',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Category Allocation Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'จัดสรรงบประมาณรายหมวด (${_budgets.length})',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddOrEditCategoryDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 15),
                  label: const Text('เพิ่มหมวดงบ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 5. Category Budget Cards List
            if (_budgets.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                decoration: BoxDecoration(
                  color: currentTheme.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: currentTheme.borderColor),
                ),
                child: Column(
                  children: [
                    Icon(Icons.pie_chart_outline_rounded, size: 40, color: currentTheme.textSecondaryColor.withValues(alpha: 0.5)),
                    const SizedBox(height: 10),
                    Text(
                      'ยังไม่มีการจัดสรรหมวดหมู่งบประมาณใน$_scopeTitleLabel',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'แตะปุ่ม "เพิ่มหมวดงบ" เพื่อกำหนดงบประมาณตามใจคุณ',
                      style: TextStyle(fontSize: 11, color: currentTheme.textSecondaryColor),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _budgets.length,
                itemBuilder: (context, idx) {
                  final catName = _budgets.keys.elementAt(idx);
                  final budgetAmt = _budgets.values.elementAt(idx);
                  final spentAmt = widget.controller.getSpentForCategoryThisMonth(catName);
                  final isOver = spentAmt > budgetAmt && budgetAmt > 0;
                  final isNear = !isOver && spentAmt >= budgetAmt * 0.8 && budgetAmt > 0;
                  final progress = budgetAmt > 0 ? (spentAmt / budgetAmt).clamp(0.0, 1.0) : 0.0;
                  final catItem = _findCategoryItem(catName);
                  final catColor = Color(catItem.colorValue);

                  Color statusColor;
                  String statusLabel;
                  if (isOver) {
                    statusColor = const Color(0xFFEF4444);
                    statusLabel = '🚨 เกินงบ';
                  } else if (isNear) {
                    statusColor = const Color(0xFFF59E0B);
                    statusLabel = '⚠️ ใกล้เต็ม';
                  } else {
                    statusColor = const Color(0xFF10B981);
                    statusLabel = '🟢 ปกติ';
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: currentTheme.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isOver ? const Color(0xFFEF4444).withValues(alpha: 0.4) : currentTheme.borderColor,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(catItem.icon, size: 16, color: catColor),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  catName,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: statusColor),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _showAddOrEditCategoryDialog(existingName: catName, existingAmount: budgetAmt),
                                  child: Icon(Icons.edit_rounded, size: 16, color: currentTheme.textSecondaryColor),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => _removeCategoryBudget(catName),
                                  child: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ใช้ไป ฿${FormatUtils.formatMoney(spentAmt)}',
                              style: TextStyle(fontSize: 11.5, color: currentTheme.textSecondaryColor),
                            ),
                            Text(
                              'งบ ฿${FormatUtils.formatMoney(budgetAmt)}',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeTabItem(String label, BudgetPlanScope scope, dynamic currentTheme) {
    final isSel = _selectedScope == scope;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedScope = scope;
          });
          _loadBudgetsForCurrentScope();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? currentTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                color: isSel ? Colors.white : currentTheme.textSecondaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
