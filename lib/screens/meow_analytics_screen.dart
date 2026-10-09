import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction_item.dart';
import '../models/category_item.dart';
import '../state/expense_controller.dart';
import '../widgets/meow_fx.dart';
import '../widgets/meow_wheel_date_picker.dart';
import '../utils/format_utils.dart';
import 'category_management_screen.dart';
import 'compare_analytics_screen.dart';
import '../widgets/transaction_detail_sheet.dart';
import '../services/slip_auto_sync_service.dart';
import '../widgets/meow_page_header.dart';

enum AnalyticsMainTab {
  overview,
  categoryTags,
  comparison,
}

enum PeriodFilterType {
  day,
  month,
  year,
  customRange,
  allTime,
}

/// Income/expense totals for one set of transactions (transfers are ignored).
class _PeriodStats {
  double income = 0;
  double expense = 0;
  int incomeCount = 0;
  int expenseCount = 0;
  final Map<String, double> expenseByCat = {};

  _PeriodStats(Iterable<TransactionItem> txs) {
    for (final t in txs) {
      if (t.type == TransactionType.income) {
        income += t.amount;
        incomeCount++;
      } else if (t.type == TransactionType.expense) {
        expense += t.amount;
        expenseCount++;
        expenseByCat[t.categoryId] = (expenseByCat[t.categoryId] ?? 0) + t.amount;
      }
    }
  }

  double get net => income - expense;
  int get count => incomeCount + expenseCount;
  double get savingsRate => income > 0 ? net / income * 100 : 0;
}

class MeowAnalyticsScreen extends StatefulWidget {
  final ExpenseController controller;

  const MeowAnalyticsScreen({super.key, required this.controller});

  @override
  State<MeowAnalyticsScreen> createState() => _MeowAnalyticsScreenState();
}

class _MeowAnalyticsScreenState extends State<MeowAnalyticsScreen> {
  AnalyticsMainTab _activeTab = AnalyticsMainTab.overview;

  // Period filter (overview and categories share it)
  PeriodFilterType _periodType = PeriodFilterType.month;
  DateTime _currentAnchorDate = DateTime.now();
  DateTimeRange _customDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  TransactionType _selectedType = TransactionType.expense;
  bool _showAllCategories = false;
  bool _showEmptyCategories = false;

  // Categories tab
  String? _selectedDrillCategoryId;
  String? _expandedTag;
  bool _tagsCollapsed = false; // user closed the auto-opened first tag
  bool _showAllTagTx = false;
  static const String _untaggedKey = '\u0000untagged';

  // Compare tab
  bool _compareYears = false;
  DateTime _compareMonthA = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _compareMonthB = DateTime(DateTime.now().year, DateTime.now().month - 1);
  int _compareYearA = DateTime.now().year;
  int _compareYearB = DateTime.now().year - 1;

  static const List<String> _thaiMonths = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
  ];
  static const List<String> _thaiMonthsShort = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
  ];
  static const List<String> _enMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  static const List<String> _enMonthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  ExpenseController get _c => widget.controller;
  bool get _isEn => _c.isEnglish;
  bool get _isDark => _c.isDarkMode;

  Color get _text => _c.currentTheme.textColor;
  Color get _sub => _c.currentTheme.textSecondaryColor;
  Color get _card => _c.currentTheme.cardBackground;
  Color get _line => _c.currentTheme.borderColor;
  Color get _track => _isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEEF0F4);
  Color get _seg => _isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F3F8);
  Color get _accent => _isDark ? const Color(0xFF93C5FD) : _c.currentTheme.primaryDark;
  Color get _income => _isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
  Color get _expense => _isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
  Color get _incomeLabel => _isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857);
  Color get _incomeValue => _isDark ? const Color(0xFF34D399) : const Color(0xFF065F46);
  Color get _expenseLabel => _isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);
  Color get _expenseValue => _isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B);
  Color get _body => _isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
  Color get _segDeep => _isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE8EBF2);
  static const Color _compareB = Color(0xFF38BDF8);
  Color get _compareBText => _isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0284C7);

  /// Good / bad / neutral chip colours from the drafts (fg, bg).
  (Color, Color) _tone(bool? good) {
    if (_isDark) {
      final c = good == null ? _sub : (good ? const Color(0xFF34D399) : const Color(0xFFF87171));
      return (c, c.withValues(alpha: 0.14));
    }
    if (good == null) return (const Color(0xFF475569), const Color(0xFFF1F3F8));
    return good ? (const Color(0xFF047857), const Color(0xFFECFDF5)) : (const Color(0xFFB91C1C), const Color(0xFFFEF2F2));
  }

  @override
  void initState() {
    super.initState();
    _c.addListener(_onControllerUpdate);
    // Auto-trigger slip scan if app has no transactions yet and is not currently scanning.
    // Skipped before the initial device scan: this screen is built at startup inside the IndexedStack,
    // and scanning before photo permission is granted finds nothing and wrongly marks the initial scan as done.
    if (_c.isInitialDeviceScanCompleted && _c.allTransactions.isEmpty && !_c.isProcessingSlips) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) SlipAutoSyncService.scanAndAutoImportNewSlips(_c);
      });
    }
  }

  @override
  void dispose() {
    _c.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Period helpers
  // ---------------------------------------------------------------------------
  String _yearStr(int y) => _isEn ? '$y' : '${y + 543}';
  String _monthLong(int m) => _isEn ? _enMonths[m - 1] : _thaiMonths[m - 1];
  String _monthShort(int m) => _isEn ? _enMonthsShort[m - 1] : _thaiMonthsShort[m - 1];
  String _monthYearLong(DateTime d) => '${_monthLong(d.month)} ${_yearStr(d.year)}';

  String _formatPeriodTitle() {
    final d = _currentAnchorDate;
    switch (_periodType) {
      case PeriodFilterType.day:
        return '${d.day} ${_monthLong(d.month)} ${_yearStr(d.year)}';
      case PeriodFilterType.month:
        return _monthYearLong(d);
      case PeriodFilterType.year:
        return _isEn ? 'Year ${d.year}' : 'ปี ${d.year + 543}';
      case PeriodFilterType.customRange:
        final s = _customDateRange.start;
        final e = _customDateRange.end;
        return '${s.day}/${s.month}/${_yearStr(s.year)} - ${e.day}/${e.month}/${_yearStr(e.year)}';
      case PeriodFilterType.allTime:
        return _isEn ? 'All time' : 'ทั้งหมด';
    }
  }

  String get _periodTypeLabel {
    switch (_periodType) {
      case PeriodFilterType.day:
        return _isEn ? 'Day' : 'รายวัน';
      case PeriodFilterType.month:
        return _isEn ? 'Month' : 'รายเดือน';
      case PeriodFilterType.year:
        return _isEn ? 'Year' : 'รายปี';
      case PeriodFilterType.customRange:
        return _isEn ? 'Range' : 'ช่วงเวลา';
      case PeriodFilterType.allTime:
        return _isEn ? 'All' : 'ทั้งหมด';
    }
  }

  /// "this month" / "this year" wording for the summary card title.
  String get _summaryTitle {
    final now = DateTime.now();
    final d = _currentAnchorDate;
    switch (_periodType) {
      case PeriodFilterType.day:
        final today = d.year == now.year && d.month == now.month && d.day == now.day;
        return today ? (_isEn ? 'Today' : 'สรุปวันนี้') : (_isEn ? 'Summary for the day' : 'สรุปวันที่ ${d.day} ${_monthShort(d.month)}');
      case PeriodFilterType.month:
        final cur = d.year == now.year && d.month == now.month;
        return cur ? (_isEn ? 'This month' : 'สรุปเดือนนี้') : (_isEn ? 'Summary for ${_monthYearLong(d)}' : 'สรุป${_monthYearLong(d)}');
      case PeriodFilterType.year:
        return d.year == now.year ? (_isEn ? 'This year' : 'สรุปปีนี้') : (_isEn ? 'Summary for ${d.year}' : 'สรุปปี ${d.year + 543}');
      case PeriodFilterType.customRange:
        return _isEn ? 'Selected range' : 'สรุปช่วงที่เลือก';
      case PeriodFilterType.allTime:
        return _isEn ? 'All time' : 'สรุปทั้งหมด';
    }
  }

  void _prevPeriod() => _shiftPeriod(-1);
  void _nextPeriod() => _shiftPeriod(1);

  void _shiftPeriod(int step) {
    HapticFeedback.selectionClick();
    setState(() {
      final d = _currentAnchorDate;
      if (_periodType == PeriodFilterType.day) {
        _currentAnchorDate = DateTime(d.year, d.month, d.day + step);
      } else if (_periodType == PeriodFilterType.month) {
        _currentAnchorDate = DateTime(d.year, d.month + step, 1);
      } else if (_periodType == PeriodFilterType.year) {
        _currentAnchorDate = DateTime(d.year + step, 1, 1);
      }
      _expandedTag = null;
          _tagsCollapsed = false;
          _showAllTagTx = false;
    });
  }

  Future<void> _pickDateOrRange() async {
    HapticFeedback.selectionClick();
    if (_periodType == PeriodFilterType.customRange) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2040),
        initialDateRange: _customDateRange,
        helpText: _isEn ? 'Select Date Range' : 'เลือกช่วงวันที่ต้องการดูสถิติ',
        saveText: _isEn ? 'Done' : 'เลือกช่วงนี้',
      );
      if (picked != null) setState(() => _customDateRange = picked);
    } else if (_periodType == PeriodFilterType.day) {
      final picked = await MeowWheelDatePicker.showWheelDatePicker(
        context: context,
        initialDate: _currentAnchorDate,
        isEnglish: _isEn,
        isDarkMode: _isDark,
      );
      if (picked != null) setState(() => _currentAnchorDate = picked);
    } else if (_periodType == PeriodFilterType.month) {
      final picked = await MeowWheelDatePicker.showWheelMonthYearPicker(
        context: context,
        initialDate: _currentAnchorDate,
        isEnglish: _isEn,
        isDarkMode: _isDark,
      );
      if (picked != null) setState(() => _currentAnchorDate = picked);
    } else if (_periodType == PeriodFilterType.year) {
      final picked = await MeowWheelDatePicker.showWheelYearPicker(
        context: context,
        initialYear: _currentAnchorDate.year,
        isEnglish: _isEn,
        isDarkMode: _isDark,
      );
      if (picked != null) setState(() => _currentAnchorDate = DateTime(picked, _currentAnchorDate.month, 1));
    }
  }

  /// [start, end) of the selected period, or null for "all time".
  DateTimeRange? _rangeOf(PeriodFilterType type, DateTime d) {
    switch (type) {
      case PeriodFilterType.day:
        return DateTimeRange(start: DateTime(d.year, d.month, d.day), end: DateTime(d.year, d.month, d.day + 1));
      case PeriodFilterType.month:
        return DateTimeRange(start: DateTime(d.year, d.month), end: DateTime(d.year, d.month + 1));
      case PeriodFilterType.year:
        return DateTimeRange(start: DateTime(d.year), end: DateTime(d.year + 1));
      case PeriodFilterType.customRange:
        final s = _customDateRange.start;
        final e = _customDateRange.end;
        return DateTimeRange(start: DateTime(s.year, s.month, s.day), end: DateTime(e.year, e.month, e.day + 1));
      case PeriodFilterType.allTime:
        return null;
    }
  }

  List<TransactionItem> _inRange(DateTimeRange? r) {
    final all = _c.allTransactions;
    if (r == null) return all;
    return all.where((t) => !t.date.isBefore(r.start) && t.date.isBefore(r.end)).toList();
  }

  List<TransactionItem> get _filteredTransactions => _inRange(_rangeOf(_periodType, _currentAnchorDate));

  /// The period right before the selected one (day/month/year only).
  DateTimeRange? get _previousRange {
    final d = _currentAnchorDate;
    switch (_periodType) {
      case PeriodFilterType.day:
        return _rangeOf(PeriodFilterType.day, DateTime(d.year, d.month, d.day - 1));
      case PeriodFilterType.month:
        return _rangeOf(PeriodFilterType.month, DateTime(d.year, d.month - 1));
      case PeriodFilterType.year:
        return _rangeOf(PeriodFilterType.year, DateTime(d.year - 1));
      case PeriodFilterType.customRange:
      case PeriodFilterType.allTime:
        return null;
    }
  }

  String get _previousLabel {
    final d = _currentAnchorDate;
    switch (_periodType) {
      case PeriodFilterType.day:
        return _isEn ? 'yesterday' : 'เมื่อวาน';
      case PeriodFilterType.month:
        return _monthShort(DateTime(d.year, d.month - 1).month);
      case PeriodFilterType.year:
        return _isEn ? '${d.year - 1}' : 'ปี ${d.year + 542}';
      default:
        return '';
    }
  }

  String get _previousLabelLong {
    final d = _currentAnchorDate;
    if (_periodType == PeriodFilterType.month) {
      final p = DateTime(d.year, d.month - 1);
      return '${_monthShort(p.month)} ${_yearStr(p.year)}';
    }
    return _previousLabel;
  }

  /// Days counted for "average per day": a period still in progress counts up to today.
  int _daysForAverage(DateTimeRange? r) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day + 1);
    DateTime start;
    DateTime end;
    if (r == null) {
      final all = _c.allTransactions;
      if (all.isEmpty) return 1;
      start = all.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b);
      start = DateTime(start.year, start.month, start.day);
      end = today;
    } else {
      start = r.start;
      end = r.end.isAfter(today) && r.start.isBefore(today) ? today : r.end;
    }
    final days = end.difference(start).inHours / 24;
    return days.round().clamp(1, 100000);
  }

  CategoryItem _categoryOf(String id, {String? fallbackName, TransactionType type = TransactionType.expense}) {
    for (final c in _c.categories) {
      if (c.id == id) return c;
    }
    return CategoryItem(
      id: id,
      name: fallbackName ?? (_isEn ? 'General' : 'ทั่วไป'),
      iconKey: 'category',
      colorValue: 0xFF64748B,
      type: type == TransactionType.income ? CategoryType.income : CategoryType.expense,
    );
  }

  String _baht(double v) => '฿${FormatUtils.formatCurrency((v * 100).round() / 100, trimZero: true)}';
  String _pct(double v) => '${v.toStringAsFixed(1)}%';

  // ---------------------------------------------------------------------------
  // Shared UI pieces
  // ---------------------------------------------------------------------------
  BoxDecoration _cardDeco([double radius = 20]) => BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(radius),
        border: _isDark ? Border.all(color: _line) : null,
        boxShadow: _isDark ? null : [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 4))],
      );

  Widget _cardBox({required Widget child, EdgeInsets padding = const EdgeInsets.all(16), double radius = 20}) =>
      Container(padding: padding, decoration: _cardDeco(radius), child: child);

  /// Two or more options in a grey track; the selected one is a white pill.
  Widget _segmented<T>({
    required List<(T, String)> options,
    required T value,
    required ValueChanged<T> onChanged,
    Color? selectedText,
    double height = 48,
    double fontSize = 13,
    bool deep = false,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: deep ? _segDeep : _seg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (o.$1 == value) return;
                  HapticFeedback.selectionClick();
                  onChanged(o.$1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: o.$1 == value ? _card : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: o.$1 == value && !_isDark
                        ? [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.14), blurRadius: 4, offset: const Offset(0, 1))]
                        : null,
                  ),
                  child: Text(
                    o.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: o.$1 == value ? FontWeight.w700 : FontWeight.w400,
                      color: o.$1 == value ? (selectedText ?? _accent) : _sub,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _typeSegment({VoidCallback? onChangedExtra, required bool categories}) => _segmented<TransactionType>(
        deep: categories,
        options: [
          (TransactionType.expense, categories ? (_isEn ? 'Expense categories' : 'หมวดหมู่รายจ่าย') : (_isEn ? 'Expense share' : 'สัดส่วนรายจ่าย')),
          (TransactionType.income, categories ? (_isEn ? 'Income categories' : 'หมวดหมู่รายรับ') : (_isEn ? 'Income share' : 'สัดส่วนรายรับ')),
        ],
        value: _selectedType,
        selectedText: _selectedType == TransactionType.expense ? _expense : _income,
        onChanged: (t) => setState(() {
          _selectedType = t;
          _showAllCategories = false;
          _selectedDrillCategoryId = null;
          _expandedTag = null;
          _tagsCollapsed = false;
          _showAllTagTx = false;
          onChangedExtra?.call();
        }),
      );

  /// Small rounded chip that shows a change, e.g. "▼ ฿2,650 (12.6%)".
  Widget _deltaChip(String text, {bool? good, double fontSize = 11}) {
    final (fg, bg) = _tone(good);
    // Shrinks instead of cutting the number off when space is tight.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
        child: Text(text, maxLines: 1, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: fg)),
      ),
    );
  }

  Widget _categoryTile(CategoryItem cat, {double size = 40}) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(12)),
        child: Icon(cat.icon, color: cat.color, size: size * 0.5),
      );

  /// Counts a number up from zero the first time it is shown.
  Widget _countUp(double value, TextStyle style, {String Function(double)? format, String prefix = ''}) => FxProgress(
        value: value,
        builder: (_, v) => Text('$prefix${(format ?? _baht)(v)}', style: style, maxLines: 1),
      );

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = _c.currentTheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildActiveTabContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final subtitle = switch (_activeTab) {
      AnalyticsMainTab.overview => '${_isEn ? 'Financial summary' : 'สรุปวิเคราะห์การเงิน'} • ${_formatPeriodTitle()}',
      AnalyticsMainTab.categoryTags => _isEn ? 'Categories & sub-tags' : 'หมวดหมู่ & #แท็กย่อย',
      AnalyticsMainTab.comparison => _isEn ? 'Compare your money ⚖️' : 'เปรียบเทียบการเงิน ⚖️',
    };
    return MeowPageHeader(
      controller: _c,
      title: _isEn ? 'Statistics' : 'สถิติ',
      subtitle: subtitle,
      bottom: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _c.currentTheme.heroTextColor(_isDark).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _headerTab(AnalyticsMainTab.overview, _isEn ? 'Overview' : 'ภาพรวม'),
            _headerTab(AnalyticsMainTab.categoryTags, _isEn ? 'Categories & #tags' : 'หมวดหมู่ & #แท็ก', flex: 27),
            _headerTab(AnalyticsMainTab.comparison, _isEn ? 'Compare' : 'เทียบเดือน'),
          ],
        ),
      ),
    );
  }

  Widget _headerTab(AnalyticsMainTab tab, String label, {int flex = 20}) {
    final selected = _activeTab == tab;
    final heroText = _c.currentTheme.heroTextColor(_isDark);
    return Expanded(
      flex: flex,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (selected) return;
          HapticFeedback.selectionClick();
          setState(() => _activeTab = tab);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _card : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? _accent : heroText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      child: KeyedSubtree(
        key: ValueKey(_activeTab),
        child: switch (_activeTab) {
          AnalyticsMainTab.overview => _buildOverviewTab(),
          AnalyticsMainTab.categoryTags => _buildCategoryTagsTab(),
          AnalyticsMainTab.comparison => _buildComparisonTab(),
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Period card (overview) and period sheet (categories)
  // ---------------------------------------------------------------------------
  Widget _buildPeriodCard({VoidCallback? afterChange}) {
    void changed() => afterChange?.call();
    return _cardBox(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          _segmented<PeriodFilterType>(
            height: 46,
            fontSize: 12.5,
            options: [
              (PeriodFilterType.day, _isEn ? 'Day' : 'รายวัน'),
              (PeriodFilterType.month, _isEn ? 'Month' : 'รายเดือน'),
              (PeriodFilterType.year, _isEn ? 'Year' : 'รายปี'),
              (PeriodFilterType.customRange, _isEn ? 'Range' : 'ช่วงเวลา'),
              (PeriodFilterType.allTime, _isEn ? 'All' : 'ทั้งหมด'),
            ],
            value: _periodType,
            onChanged: (t) {
              setState(() {
                _periodType = t;
                _expandedTag = null;
          _tagsCollapsed = false;
          _showAllTagTx = false;
              });
              changed();
            },
          ),
          if (_periodType != PeriodFilterType.allTime) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (_periodType != PeriodFilterType.customRange)
                  _navButton(Icons.chevron_left_rounded, () {
                    _prevPeriod();
                    changed();
                  }),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      await _pickDateOrRange();
                      changed();
                    },
                    child: SizedBox(
                      height: 44,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 16, color: _accent),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _formatPeriodTitle(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.expand_more_rounded, size: 18, color: _sub),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_periodType != PeriodFilterType.customRange)
                  _navButton(Icons.chevron_right_rounded, () {
                    _nextPeriod();
                    changed();
                  }),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) => Material(
        color: _seg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Icon(icon, color: _text, size: 22)),
        ),
      );

  void _showPeriodSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: _c.currentTheme.scaffoldBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _line, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 14),
                Text(_isEn ? 'Period' : 'ช่วงเวลาที่ดู', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _buildPeriodCard(afterChange: () {
                  if (ctx.mounted) setSheet(() {});
                }),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _c.currentTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(_isEn ? 'Done' : 'เสร็จ', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: OVERVIEW
  // ---------------------------------------------------------------------------
  Widget _buildOverviewTab() {
    final txs = _filteredTransactions;
    final stats = _PeriodStats(txs);
    var i = 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        FxFadeUp(index: i++, child: _buildPeriodCard()),
        const SizedBox(height: 14),
        FxFadeUp(index: i++, child: _buildSummaryCard(stats)),
        const SizedBox(height: 14),
        FxFadeUp(index: i++, child: _buildChartCard(txs, stats)),
        const SizedBox(height: 14),
        FxFadeUp(index: i++, child: _buildCategoryList(txs, stats)),
      ],
    );
  }

  Widget _buildSummaryCard(_PeriodStats s) {
    final prevRange = _previousRange;
    Widget? badge;
    if (prevRange != null) {
      final prev = _PeriodStats(_inRange(prevRange));
      if (prev.expense > 0) {
        final change = (s.expense - prev.expense) / prev.expense * 100;
        final down = change <= 0;
        badge = _deltaChip(
          '${down ? '▼' : '▲'} ${_pct(change.abs())} ${_isEn ? 'vs' : 'จาก'} $_previousLabel',
          good: down,
          fontSize: 11.5,
        );
      }
    }
    final days = _daysForAverage(_rangeOf(_periodType, _currentAnchorDate));
    final perDay = (s.expense / days).roundToDouble();
    final used = s.income > 0 ? (s.expense / s.income).clamp(0.0, 1.0) : (s.expense > 0 ? 1.0 : 0.0);

    Widget column(String label, Color labelColor, double amount, Color color, String foot, {String prefix = ''}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: labelColor)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: _countUp(amount, TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: color), prefix: prefix),
              ),
              const SizedBox(height: 2),
              Text(foot, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: _sub)),
            ],
          ),
        );
    Widget divider() => Container(width: 1, height: 58, margin: const EdgeInsets.symmetric(horizontal: 8), color: _line.withValues(alpha: 0.7));

    final netColor = s.net >= 0 ? _accent : _expense;
    final items = _isEn ? 'items' : 'รายการ';
    return _cardBox(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_summaryTitle,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _text)),
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              column(_isEn ? 'Income' : 'รายรับ', _incomeLabel, s.income, _incomeValue, '${s.incomeCount} $items'),
              divider(),
              column(_isEn ? 'Expense' : 'รายจ่าย', _expenseLabel, s.expense, _expenseValue, '${s.expenseCount} $items'),
              divider(),
              column(
                _isEn ? 'Left over' : 'คงเหลือ',
                _isDark ? _sub : const Color(0xFF475569),
                s.net.abs(),
                netColor,
                '${_isEn ? 'Saved' : 'ออม'} ${s.income > 0 ? _pct(s.savingsRate) : '–'}',
                prefix: s.net >= 0 ? '+' : '−',
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 8,
              color: _isDark ? _track : const Color(0xFFE2E8F0),
              child: FxProgress(
                value: used,
                builder: (_, v) => Row(
                  children: [
                    Expanded(flex: (v * 1000).round(), child: Container(color: const Color(0xFFEF4444))),
                    Expanded(flex: ((1 - v) * 1000).round(), child: Container(color: s.income > 0 ? const Color(0xFF10B981) : Colors.transparent)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  s.income <= 0
                      ? (_isEn ? 'No income in this period' : 'ยังไม่มีรายรับในช่วงนี้')
                      : s.expense <= s.income
                          ? (_isEn ? 'Spent ${(s.expense / s.income * 100).toStringAsFixed(0)}% of income' : 'ใช้ไป ${(s.expense / s.income * 100).toStringAsFixed(0)}% ของรายรับ')
                          : (_isEn
                              ? 'Over income by ${((s.expense - s.income) / s.income * 100).toStringAsFixed(0)}%'
                              : 'ใช้เกินรายรับ ${((s.expense - s.income) / s.income * 100).toStringAsFixed(0)}%'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: _sub),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: _isEn ? 'Avg ' : 'เฉลี่ยจ่าย '),
                    TextSpan(text: _baht(perDay), style: TextStyle(fontWeight: FontWeight.w700, color: _text)),
                    TextSpan(text: _isEn ? '/day' : '/วัน'),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: _sub),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(List<TransactionItem> txs, _PeriodStats s) {
    return _StatsChartCard(
      key: ValueKey('chart-${_periodType.name}'),
      controller: _c,
      periodType: _periodType,
      anchor: _currentAnchorDate,
      range: _rangeOf(_periodType, _currentAnchorDate),
      periodTxs: txs,
      type: _selectedType,
      decoration: _cardDeco(22),
      typeSwitch: _typeSegment(categories: false),
      categoryOf: (id, name) => _categoryOf(id, fallbackName: name, type: _selectedType),
    );
  }

  Widget _buildCategoryList(List<TransactionItem> txs, _PeriodStats s) {
    final items = txs.where((t) => t.type == _selectedType).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    final amounts = <String, double>{};
    final counts = <String, int>{};
    final names = <String, String>{};
    for (final tx in items) {
      amounts[tx.categoryId] = (amounts[tx.categoryId] ?? 0) + tx.amount;
      counts[tx.categoryId] = (counts[tx.categoryId] ?? 0) + 1;
      names[tx.categoryId] = tx.categoryName;
    }
    final total = _selectedType == TransactionType.expense ? s.expense : s.income;
    final sorted = amounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final visible = _showAllCategories ? sorted : sorted.take(5).toList();

    return _cardBox(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(_isEn ? 'By category' : 'แจกแจงตามหมวดหมู่',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isEn ? '${sorted.length} categories • tap for #tags' : '${sorted.length} หมวด • แตะเพื่อดู #แท็ก',
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _sub, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (var k = 0; k < visible.length; k++)
            _categoryRow(
              _categoryOf(visible[k].key, fallbackName: names[visible[k].key], type: _selectedType),
              visible[k].value,
              counts[visible[k].key] ?? 0,
              total > 0 ? visible[k].value / total : 0,
              barValue: sorted.first.value > 0 ? visible[k].value / sorted.first.value : 0,
              first: k == 0,
            ),
          if (sorted.length > 5)
            _moreButton(
              _showAllCategories
                  ? (_isEn ? 'Show less' : 'ย่อรายการ')
                  : (_isEn ? 'Show all ${sorted.length} categories' : 'ดูทั้งหมด ${sorted.length} หมวด'),
              () => setState(() => _showAllCategories = !_showAllCategories),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _categoryRow(CategoryItem cat, double amount, int count, double share, {required double barValue, bool first = false}) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedDrillCategoryId = cat.id;
          _expandedTag = null;
          _tagsCollapsed = false;
          _showAllTagTx = false;
          _activeTab = AnalyticsMainTab.categoryTags;
        });
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: _rowLine))),
        child: Row(
          children: [
            _categoryTile(cat),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(cat.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                      Text(_baht(amount), style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  FxBar(value: barValue, color: cat.color, track: _track, height: 6),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(child: Text('$count ${_isEn ? 'items' : 'รายการ'}', style: TextStyle(color: _sub, fontSize: 11.5))),
                      Text(_pct(share * 100), style: TextStyle(color: _sub, fontSize: 11.5)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 18, color: const Color(0xFF9AA3B2)),
          ],
        ),
      ),
    );
  }

  Color get _rowLine => _isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F3F8);

  /// Full-width text button under a list, separated by a hairline (draft "ดูทั้งหมด …").
  Widget _moreButton(String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border(top: BorderSide(color: _rowLine))),
          child: Text(label, style: TextStyle(color: _accent, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      );

  // ---------------------------------------------------------------------------
  // TAB 2: CATEGORIES & #TAGS
  // ---------------------------------------------------------------------------
  Widget _buildCategoryTagsTab() {
    final txs = _filteredTransactions.where((t) => t.type == _selectedType).toList();
    final available = _selectedType == TransactionType.income ? _c.incomeCategories : _c.expenseCategories;

    final totals = <String, double>{};
    final counts = <String, int>{};
    for (final t in txs) {
      totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amount;
      counts[t.categoryId] = (counts[t.categoryId] ?? 0) + 1;
    }
    // Categories with money first (largest first), then the empty ones.
    final cats = [...available]..sort((a, b) => (totals[b.id] ?? 0).compareTo(totals[a.id] ?? 0));
    for (final id in totals.keys) {
      if (!cats.any((c) => c.id == id)) {
        final name = txs.firstWhere((t) => t.categoryId == id).categoryName;
        cats.insert(0, _categoryOf(id, fallbackName: name, type: _selectedType));
      }
    }
    cats.sort((a, b) => (totals[b.id] ?? 0).compareTo(totals[a.id] ?? 0));
    // Only categories used in this period, unless there are none or the user asks for all.
    final used = cats.where((c) => (totals[c.id] ?? 0) > 0).toList();
    final emptyCount = cats.length - used.length;
    final shown = used.isEmpty || _showEmptyCategories ? cats : used;

    final periodTotal = totals.values.fold(0.0, (a, b) => a + b);
    CategoryItem? selected;
    if (cats.isNotEmpty) {
      selected = cats.firstWhere((c) => c.id == _selectedDrillCategoryId, orElse: () => cats.first);
    }

    var i = 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        FxFadeUp(
          index: i++,
          child: Row(
            children: [
              Expanded(
                child: Material(
                  color: _card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: _isDark ? _line : const Color(0xFFE2E8F0)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _showPeriodSheet,
                    child: SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(Icons.calendar_today_outlined, size: 16, color: _accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _periodType == PeriodFilterType.allTime ? _formatPeriodTitle() : '$_periodTypeLabel · ${_formatPeriodTitle()}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Icon(Icons.expand_more_rounded, size: 20, color: _sub),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: _isDark ? const Color(0xFFFCD34D) : const Color(0xFF7A5200),
                    backgroundColor: _isDark ? const Color(0xFFFCD34D).withValues(alpha: 0.14) : const Color(0xFFFFF4CC),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CategoryManagementScreen(controller: _c)),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(_isEn ? 'Manage' : 'จัดการหมวด', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FxFadeUp(index: i++, child: _typeSegment(categories: true)),
        const SizedBox(height: 14),
        if (selected == null)
          _emptyCard(_isEn ? 'No categories yet' : 'ยังไม่มีหมวดหมู่')
        else ...[
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              _isEn ? 'Choose a category (${used.length})' : 'เลือกหมวดหมู่ (${used.length} หมวด)',
              style: TextStyle(color: _body, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          FxFadeUp(index: i++, child: _categoryGrid(shown, totals, selected)),
          if (used.isNotEmpty && emptyCount > 0)
            Center(
              child: TextButton(
                onPressed: () => setState(() => _showEmptyCategories = !_showEmptyCategories),
                child: Text(
                  _showEmptyCategories
                      ? (_isEn ? 'Hide unused categories' : 'ซ่อนหมวดที่ยังไม่มีรายการ')
                      : (_isEn ? 'Show $emptyCount unused categories' : 'แสดงหมวดที่ยังไม่มีรายการ ($emptyCount)'),
                  style: TextStyle(color: _accent, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
          const SizedBox(height: 14),
          FxFadeUp(
            index: i++,
            child: _categoryHero(selected, totals[selected.id] ?? 0, counts[selected.id] ?? 0, periodTotal),
          ),
          const SizedBox(height: 14),
          FxFadeUp(index: i++, child: _tagsCard(selected, txs.where((t) => t.categoryId == selected!.id).toList())),
        ],
      ],
    );
  }

  Widget _emptyCard(String text) => _cardBox(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(text, style: TextStyle(color: _sub, fontSize: 13.5))),
      );

  Widget _categoryGrid(List<CategoryItem> cats, Map<String, double> totals, CategoryItem selected) {
    return LayoutBuilder(builder: (context, box) {
      const gap = 8.0;
      final w = (box.maxWidth - gap * 2) / 3;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final cat in cats)
            SizedBox(
              width: w,
              child: FxPress(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedDrillCategoryId = cat.id;
                    _expandedTag = null;
          _tagsCollapsed = false;
          _showAllTagTx = false;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  constraints: const BoxConstraints(minHeight: 84),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  decoration: BoxDecoration(
                    color: cat.id == selected.id ? cat.color.withValues(alpha: _isDark ? 0.18 : 0.08) : _card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cat.id == selected.id ? cat.color : (_isDark ? _line : const Color(0xFFE2E8F0)),
                      width: cat.id == selected.id ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(cat.icon, color: cat.color, size: 24),
                      const SizedBox(height: 4),
                      Text(cat.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _text, fontSize: 12.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        _baht(totals[cat.id] ?? 0),
                        maxLines: 1,
                        style: TextStyle(color: (totals[cat.id] ?? 0) > 0 ? _sub : _sub.withValues(alpha: 0.6), fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _categoryHero(CategoryItem cat, double total, int count, double periodTotal) {
    final base = cat.color;
    final onHero = base.computeLuminance() > 0.6 ? const Color(0xFF0F172A) : Colors.white;
    String? compare;
    final prevRange = _previousRange;
    if (prevRange != null) {
      final prev = _inRange(prevRange).where((t) => t.categoryId == cat.id && t.type == _selectedType).fold(0.0, (a, t) => a + t.amount);
      if (prev > 0) {
        final delta = total - prev;
        compare = '${delta <= 0 ? '▼' : '▲'} ${_baht(delta.abs())} (${(delta.abs() / prev * 100).toStringAsFixed(0)}%)';
      }
    }
    Widget tile(String label, String value) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: onHero.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: onHero.withValues(alpha: 0.9), fontSize: 11.5)),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: onHero, fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [base, base.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: onHero.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(14)),
                child: Icon(cat.icon, color: onHero, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: onHero, fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(
                      _isEn ? '$count items in ${_formatPeriodTitle()}' : '$count รายการ ใน ${_formatPeriodTitle()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: onHero.withValues(alpha: 0.9), fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: _countUp(total, TextStyle(color: onHero, fontSize: 30, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              tile(_isEn ? 'Share of total' : 'สัดส่วนจากทั้งหมด', periodTotal > 0 ? _pct(total / periodTotal * 100) : '—'),
              if (_previousRange != null) ...[
                const SizedBox(width: 8),
                tile(_isEn ? 'vs $_previousLabelLong' : 'เทียบ $_previousLabelLong', compare ?? (_isEn ? 'No data' : 'ไม่มีข้อมูล')),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _tagsCard(CategoryItem cat, List<TransactionItem> catTxs) {
    final total = catTxs.fold(0.0, (a, t) => a + t.amount);
    final amounts = <String, double>{};
    final counts = <String, int>{};
    double untagged = 0;
    int untaggedCount = 0;
    for (final tx in catTxs) {
      final tags = tx.tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toSet();
      if (tags.isEmpty) {
        untagged += tx.amount;
        untaggedCount++;
      } else {
        for (final t in tags) {
          amounts[t] = (amounts[t] ?? 0) + tx.amount;
          counts[t] = (counts[t] ?? 0) + 1;
        }
      }
    }
    final sorted = amounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final rows = <(String, String, double, int)>[
      for (final e in sorted) (e.key, '#${e.key}', e.value, counts[e.key] ?? 0),
      if (untagged > 0) (_untaggedKey, _isEn ? 'No #tag' : 'ไม่ได้ระบุ #แท็ก', untagged, untaggedCount),
    ];

    List<TransactionItem> txsFor(String key) {
      final list = key == _untaggedKey
          ? catTxs.where((t) => t.tags.every((x) => x.trim().isEmpty)).toList()
          : catTxs.where((t) => t.tags.any((x) => x.trim() == key)).toList();
      return list..sort((a, b) => b.date.compareTo(a.date));
    }

    // The first tag is open by default, as in the draft.
    final open = _expandedTag ?? (_tagsCollapsed || rows.isEmpty ? null : rows.first.$1);
    final maxTag = rows.fold(1.0, (m, r) => r.$3 > m ? r.$3 : m);

    return Column(
      children: [
        _cardBox(
          radius: 22,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEn ? '# Sub-tags in ${cat.name}' : '# แท็กย่อยใน${cat.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (rows.isNotEmpty) Text(_isEn ? 'Tap to see items' : 'แตะเพื่อดูรายการ', style: TextStyle(color: _sub, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(_isEn ? 'No items in this category yet' : 'ยังไม่มีรายการในหมวดนี้', style: TextStyle(color: _sub, fontSize: 13)),
                  ),
                )
              else
                for (var k = 0; k < rows.length; k++)
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _showAllTagTx = false;
                        if (open == rows[k].$1) {
                          _expandedTag = null;
                          _tagsCollapsed = true;
                        } else {
                          _expandedTag = rows[k].$1;
                          _tagsCollapsed = false;
                        }
                      });
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 60),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: _rowLine))),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        rows[k].$2,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: rows[k].$1 == _untaggedKey ? _sub : _text,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(_baht(rows[k].$3), style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                FxBar(
                                  value: rows[k].$3 / maxTag,
                                  color: rows[k].$1 == _untaggedKey ? const Color(0xFFCBD5E1) : cat.color,
                                  track: _track,
                                  height: 6,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(child: Text('${rows[k].$4} ${_isEn ? 'times' : 'ครั้ง'}', style: TextStyle(color: _sub, fontSize: 11.5))),
                                    Text(total > 0 ? _pct(rows[k].$3 / total * 100) : '', style: TextStyle(color: _sub, fontSize: 11.5)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: open == rows[k].$1 ? 0.25 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF9AA3B2)),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: open == null || !rows.any((r) => r.$1 == open)
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: _tagItemsCard(
                    open == _untaggedKey ? (_isEn ? 'Items without a #tag' : 'รายการที่ไม่ได้ระบุแท็ก') : rows.firstWhere((r) => r.$1 == open).$2,
                    txsFor(open),
                    cat.color,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _tagItemsCard(String title, List<TransactionItem> txs, Color color) {
    final total = txs.fold(0.0, (a, t) => a + t.amount);
    final maxShown = _showAllTagTx ? 200 : 4;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: _cardDeco(22).copyWith(border: Border.all(color: color, width: 2)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$title (${txs.length} ${_isEn ? 'items' : 'รายการ'})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              Text(_baht(total), style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          for (var k = 0; k < txs.length && k < maxShown; k++) _txRow(txs[k], first: k == 0),
          if (txs.length > maxShown)
            _moreButton(
              _isEn ? 'Show all ${txs.length} items' : 'ดูทั้งหมด ${txs.length} รายการ',
              () => setState(() => _showAllTagTx = true),
            ),
        ],
      ),
    );
  }

  Widget _txRow(TransactionItem tx, {bool first = false}) {
    final isInc = tx.type == TransactionType.income;
    final isExp = tx.type == TransactionType.expense;
    final color = isInc ? _income : (isExp ? _expense : _sub);
    final hasSlip = tx.slipImageUrl != null && tx.slipImageUrl!.isNotEmpty;
    final y = _isEn ? tx.date.year : tx.date.year + 543;
    return InkWell(
      onTap: () => TransactionDetailSheet.show(context, _c, tx),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: _rowLine))),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(tx.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _text, fontSize: 13.5, fontWeight: FontWeight.w600)),
                      ),
                      if (hasSlip) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _isDark ? const Color(0xFF0369A1).withValues(alpha: 0.3) : const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_isEn ? 'slip' : 'สลิป',
                              style: TextStyle(color: _isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1), fontSize: 10.5, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${tx.date.day}/${tx.date.month}/$y • ${tx.categoryName}',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _sub, fontSize: 11.5)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('${isInc ? '+' : (isExp ? '−' : '')}${_baht(tx.amount)}', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: COMPARE
  // ---------------------------------------------------------------------------
  /// Months compared when comparing years: if either year is this year, both years
  /// use the same Jan..this-month window so the comparison is fair (as in the draft).
  int get _yearMonths {
    final now = DateTime.now();
    return (_compareYearA == now.year || _compareYearB == now.year) ? now.month : 12;
  }

  DateTimeRange get _rangeA => _compareYears
      ? DateTimeRange(start: DateTime(_compareYearA), end: DateTime(_compareYearA, _yearMonths + 1))
      : DateTimeRange(start: DateTime(_compareMonthA.year, _compareMonthA.month), end: DateTime(_compareMonthA.year, _compareMonthA.month + 1));

  DateTimeRange get _rangeB => _compareYears
      ? DateTimeRange(start: DateTime(_compareYearB), end: DateTime(_compareYearB, _yearMonths + 1))
      : DateTimeRange(start: DateTime(_compareMonthB.year, _compareMonthB.month), end: DateTime(_compareMonthB.year, _compareMonthB.month + 1));

  String _yearLabel(int y) {
    final span = _yearMonths < 12 ? ' (${_monthShort(1)}–${_monthShort(_yearMonths)})' : '';
    return '${_isEn ? '$y' : 'ปี ${y + 543}'}$span';
  }

  String get _labelA => _compareYears ? _yearLabel(_compareYearA) : _monthYearLong(_compareMonthA);
  String get _labelB => _compareYears ? _yearLabel(_compareYearB) : _monthYearLong(_compareMonthB);
  String get _shortA => _compareYears ? _yearStr(_compareYearA) : _monthShort(_compareMonthA.month);
  String get _shortB => _compareYears ? _yearStr(_compareYearB) : _monthShort(_compareMonthB.month);

  /// Running total of spending (starting at 0): per day for months, per month for years.
  List<double> _cumulative(List<TransactionItem> txs, DateTimeRange r) {
    final buckets = _compareYears ? _yearMonths : DateTime(r.start.year, r.start.month + 1, 0).day;
    final now = DateTime.now();
    var last = buckets;
    if (!_compareYears && r.start.isBefore(now) && r.end.isAfter(now)) last = now.day;
    final perBucket = List<double>.filled(buckets, 0);
    for (final t in txs) {
      if (t.type != TransactionType.expense) continue;
      final idx = _compareYears ? t.date.month - 1 : t.date.day - 1;
      if (idx >= 0 && idx < buckets) perBucket[idx] += t.amount;
    }
    final out = <double>[0];
    var sum = 0.0;
    for (var k = 0; k < last; k++) {
      sum += perBucket[k];
      out.add(sum);
    }
    return out;
  }

  Future<void> _pickCompare(bool isA) async {
    HapticFeedback.selectionClick();
    if (_compareYears) {
      final picked = await MeowWheelDatePicker.showWheelYearPicker(
        context: context,
        initialYear: isA ? _compareYearA : _compareYearB,
        isEnglish: _isEn,
        isDarkMode: _isDark,
      );
      if (picked != null) setState(() => isA ? _compareYearA = picked : _compareYearB = picked);
    } else {
      final picked = await MeowWheelDatePicker.showWheelMonthYearPicker(
        context: context,
        initialDate: isA ? _compareMonthA : _compareMonthB,
        isEnglish: _isEn,
        isDarkMode: _isDark,
        title: isA
            ? (_isEn ? 'Select month A (main)' : 'เลือกเดือน A (ช่วงหลัก)')
            : (_isEn ? 'Select month B (compare)' : 'เลือกเดือน B (เปรียบเทียบ)'),
      );
      if (picked != null) {
        setState(() => isA ? _compareMonthA = DateTime(picked.year, picked.month) : _compareMonthB = DateTime(picked.year, picked.month));
      }
    }
  }

  Widget _buildComparisonTab() {
    final txA = _inRange(_rangeA);
    final txB = _inRange(_rangeB);
    final a = _PeriodStats(txA);
    final b = _PeriodStats(txB);
    var i = 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        FxFadeUp(
          index: i++,
          child: _segmented<bool>(
            deep: true,
            options: [(false, _isEn ? 'Compare 2 months' : 'เทียบ 2 เดือน'), (true, _isEn ? 'Compare 2 years' : 'เทียบ 2 ปี')],
            value: _compareYears,
            onChanged: (v) => setState(() => _compareYears = v),
          ),
        ),
        const SizedBox(height: 14),
        FxFadeUp(index: i++, child: _comparePickers()),
        const SizedBox(height: 14),
        if (a.count == 0 && b.count == 0)
          FxFadeUp(index: i++, child: _emptyCard(_isEn ? 'No transactions in either period yet' : 'ทั้งสองช่วงยังไม่มีรายการให้เทียบ'))
        else ...[
          FxFadeUp(index: i++, child: _verdictCard(a, b)),
          const SizedBox(height: 14),
          FxFadeUp(index: i++, child: _metricsTable(a, b)),
          const SizedBox(height: 14),
          FxFadeUp(index: i++, child: _cumulativeCard(_cumulative(txA, _rangeA), _cumulative(txB, _rangeB))),
          const SizedBox(height: 14),
          ..._highlightsAndCategories(a, b, i),
        ],
      ],
    );
  }

  Widget _comparePickers() {
    Widget box(bool isA) {
      final border = isA ? _accent : _compareB;
      final label = isA ? _accent : _compareBText;
      return Expanded(
        child: Material(
          color: _card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: border, width: 2)),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _pickCompare(isA),
            child: Container(
              constraints: const BoxConstraints(minHeight: 72),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isA ? (_isEn ? 'A • main' : 'A • ช่วงหลัก') : (_isEn ? 'B • compare with' : 'B • เปรียบเทียบ'),
                      style: TextStyle(color: label, fontSize: 11.5, fontWeight: FontWeight.w600)),
                  Text(isA ? _labelA : _labelB,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(_isEn ? 'Tap to change ▾' : 'แตะเพื่อเปลี่ยน ▾', style: TextStyle(color: _sub, fontSize: 11.5)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          box(true),
          const SizedBox(width: 8),
          Material(
            color: _segDeep,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  final m = _compareMonthA;
                  _compareMonthA = _compareMonthB;
                  _compareMonthB = m;
                  final y = _compareYearA;
                  _compareYearA = _compareYearB;
                  _compareYearB = y;
                });
              },
              child: SizedBox(width: 44, child: Icon(Icons.swap_horiz_rounded, color: _body, size: 20)),
            ),
          ),
          const SizedBox(width: 8),
          box(false),
        ],
      ),
    );
  }

  /// Category with the biggest drop (A − B most negative) and the biggest rise.
  ((String, double)?, (String, double)?) _bestWorst(_PeriodStats a, _PeriodStats b) {
    (String, double)? saved;
    (String, double)? spike;
    for (final id in {...a.expenseByCat.keys, ...b.expenseByCat.keys}) {
      final d = (a.expenseByCat[id] ?? 0) - (b.expenseByCat[id] ?? 0);
      if (d < 0 && (saved == null || d < saved.$2)) saved = (id, d);
      if (d > 0 && (spike == null || d > spike.$2)) spike = (id, d);
    }
    return (saved, spike);
  }

  Map<String, String> get _compareCatNames {
    final names = <String, String>{};
    for (final t in [..._inRange(_rangeA), ..._inRange(_rangeB)]) {
      names[t.categoryId] = t.categoryName;
    }
    return names;
  }

  Widget _verdictCard(_PeriodStats a, _PeriodStats b) {
    final eA = a.expense, eB = b.expense, nA = a.net, nB = b.net;
    String pct(double x, double y) => '${y != 0 ? ((x - y) / y * 100).abs().toStringAsFixed(1) : '0'}%';
    final (saved, spike) = _bestWorst(a, b);
    final names = _compareCatNames;
    String catName(String id) => _categoryOf(id, fallbackName: names[id]).name;

    final String icon;
    final List<Color> colors;
    final String title;
    final String body;
    if (eA < eB && nA > nB) {
      icon = '🎉';
      colors = const [Color(0xFF059669), Color(0xFF10B981)];
      title = _isEn ? 'Great discipline! $_shortA managed money better' : 'วินัยการเงินยอดเยี่ยม! $_shortA บริหารเงินได้ดีกว่า';
      body = (_isEn
              ? 'Spent ${_baht(eB - eA)} less (${pct(eA, eB)}) and net savings grew ${_baht(nA - nB)}'
              : 'ประหยัดรายจ่ายลง ${_baht(eB - eA)} (${pct(eA, eB)}) และมีเงินออมสุทธิเพิ่มขึ้น ${_baht(nA - nB)}') +
          (saved != null ? (_isEn ? ' • biggest cut: "${catName(saved.$1)}"' : ' • หมวดที่ลดได้มากสุดคือ "${catName(saved.$1)}"') : '');
    } else if (eA > eB && nA < nB) {
      icon = '⚠️';
      colors = const [Color(0xFFDC2626), Color(0xFFF87171)];
      title = _isEn ? '$_shortA spending went up' : '$_shortA มีการใช้จ่ายเพิ่มขึ้น';
      body = (_isEn ? 'Spending up ${_baht(eA - eB)} (+${pct(eA, eB)})' : 'รายจ่ายเพิ่มขึ้น ${_baht(eA - eB)} (+${pct(eA, eB)})') +
          (spike != null
              ? (_isEn ? ', mostly "${catName(spike.$1)}" — keep an eye on it' : ' โดยเฉพาะหมวด "${catName(spike.$1)}" ควรระมัดระวังการใช้จ่าย')
              : '');
    } else {
      icon = '📊';
      colors = const [Color(0xFF334155), Color(0xFF64748B)];
      title = _isEn ? 'Overall summary' : 'สรุปภาพรวมทางการเงิน';
      final inc = '${a.income >= b.income ? '+' : '−'}${_baht((a.income - b.income).abs())}';
      final exp = '${eA >= eB ? '+' : '−'}${_baht((eA - eB).abs())}';
      body = _isEn ? 'Income $inc, spending $exp, net ${_baht(nA)}' : 'รายรับ $inc, รายจ่าย $exp, เงินคงเหลือสุทธิ ${_baht(nA)}';
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28, height: 1)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontSize: 12.5, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricsTable(_PeriodStats a, _PeriodStats b) {
    final avgA = (a.expense / _daysForAverage(_rangeA)).roundToDouble();
    final avgB = (b.expense / _daysForAverage(_rangeB)).roundToDouble();
    final items = _isEn ? 'items' : 'รายการ';
    String pct(double x, double y) => '${y != 0 ? ((x - y) / y * 100).abs().toStringAsFixed(1) : '0'}%';

    // label, A, B, change text, good?(null = neutral)
    (String, String, String, String, bool?) metric(String label, double va, double vb, String Function(double) f, bool? lowerIsGood,
        String Function(double d) unit) {
      final d = va - vb;
      final good = lowerIsGood == null || d == 0 ? null : (d < 0) == lowerIsGood;
      return (label, f(va), f(vb), d == 0 ? (_isEn ? 'Same' : 'เท่าเดิม') : '${d > 0 ? '▲' : '▼'} ${unit(d.abs())}', good);
    }

    final rows = [
      metric(_isEn ? 'Total spent' : 'รายจ่ายรวม', a.expense, b.expense, _baht, true, (x) => '${_baht(x)} (${pct(a.expense, b.expense)})'),
      metric(_isEn ? 'Total income' : 'รายรับรวม', a.income, b.income, _baht, false, (x) => '${_baht(x)} (${pct(a.income, b.income)})'),
      metric(_isEn ? 'Net savings' : 'เงินออมสุทธิ', a.net, b.net, _baht, false, (x) => '${_baht(x)} (${pct(a.net, b.net)})'),
      metric(_isEn ? 'Savings rate' : 'อัตราการออม', a.savingsRate, b.savingsRate, (v) => _pct(v), false,
          (x) => '${x.toStringAsFixed(1)} ${_isEn ? 'pts' : 'จุด'}'),
      metric(_isEn ? 'Avg spend/day' : 'เฉลี่ยจ่าย/วัน', avgA, avgB, _baht, true, (x) => '${_baht(x)}${_isEn ? '/day' : '/วัน'}'),
      metric(_isEn ? 'Transactions' : 'จำนวนรายการ', a.count.toDouble(), b.count.toDouble(), (v) => '${v.round()} $items', null,
          (x) => '${x.round()} $items'),
    ];

    return _cardBox(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
            child: Row(
              children: [
                Expanded(flex: 12, child: Text(_isEn ? 'Metric' : 'ตัวชี้วัด', style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.w600))),
                Expanded(flex: 10, child: Text('A', textAlign: TextAlign.right, style: TextStyle(color: _accent, fontSize: 11.5, fontWeight: FontWeight.w600))),
                Expanded(flex: 10, child: Text('B', textAlign: TextAlign.right, style: TextStyle(color: _compareBText, fontSize: 11.5, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          for (final r in rows)
            Container(
              constraints: const BoxConstraints(minHeight: 58),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: _rowLine))),
              child: Row(
                children: [
                  Expanded(
                    flex: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.$1, style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        _deltaChip(r.$4, good: r.$5),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 10,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(r.$2, style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 10,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(r.$3, style: TextStyle(color: _isDark ? _sub : const Color(0xFF475569), fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cumulativeCard(List<double> sa, List<double> sb) {
    final months = _yearMonths;
    final title = _compareYears ? (_isEn ? 'Cumulative spending by month' : 'ใช้จ่ายสะสมรายเดือน') : (_isEn ? 'Cumulative daily spending' : 'ใช้จ่ายสะสมรายวัน');
    final sub = _compareYears
        ? (_isEn
            ? 'Same months of both years (${_monthShort(1)}–${_monthShort(months)})'
            : 'เทียบช่วงเดียวกัน ${_monthShort(1)}–${_monthShort(months)} ของทั้งสองปี')
        : (_isEn ? 'Lower line = slower spending • see when money flows out fastest' : 'เส้นต่ำกว่า = ใช้จ่ายช้ากว่า • ดูได้ว่าช่วงไหนของเดือนเงินไหลออกเร็ว');
    final labels = _compareYears
        ? [_monthShort(1), _monthShort(((months + 1) / 2).ceil()), _monthShort(months)]
        : [_isEn ? 'Day 1' : 'วันที่ 1', _isEn ? 'Day 15' : 'วันที่ 15', _isEn ? 'Month end' : 'สิ้นเดือน'];
    return _cardBox(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(color: _sub, fontSize: 12)),
          const SizedBox(height: 10),
          SizedBox(
            height: 160,
            child: FxProgress(
              key: ValueKey('$_labelA|$_labelB|${sa.length}|${sb.length}'),
              value: 1,
              duration: const Duration(milliseconds: 900),
              builder: (_, t) => CustomPaint(
                size: Size.infinite,
                painter: _CumulativePainter(
                  a: sa,
                  b: sb,
                  buckets: _compareYears ? months + 1 : 32,
                  colorA: _accent,
                  colorB: _compareB,
                  grid: _isDark ? Colors.white10 : const Color(0xFFEEF0F4),
                  progress: t,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [for (final l in labels) Flexible(child: Text(l, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _sub, fontSize: 11.5)))],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _legend(_accent, 'A $_shortA • ${_baht(sa.isEmpty ? 0 : sa.last)}'),
              _legend(_compareB, 'B $_shortB • ${_baht(sb.isEmpty ? 0 : sb.last)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 18, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _text, fontSize: 12))),
        ],
      );

  List<Widget> _highlightsAndCategories(_PeriodStats a, _PeriodStats b, int startIndex) {
    var i = startIndex;
    final ids = {...a.expenseByCat.keys, ...b.expenseByCat.keys};
    final rows = [
      for (final id in ids) (id, a.expenseByCat[id] ?? 0.0, b.expenseByCat[id] ?? 0.0),
    ]..sort((x, y) => (y.$2 - y.$3).abs().compareTo((x.$2 - x.$3).abs()));
    final names = _compareCatNames;
    CategoryItem cat(String id) => _categoryOf(id, fallbackName: names[id]);
    final (saved, spike) = _bestWorst(a, b);
    final top = rows.fold(1.0, (m, r) => [m, r.$2, r.$3].reduce((x, y) => x > y ? x : y));

    Widget highlight(String label, (String, double)? item, bool good, String none) {
      final (fg, bg) = _tone(good);
      final ci = item == null ? null : cat(item.$1);
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              if (ci != null)
                Row(children: [
                  Icon(ci.icon, size: 17, color: ci.color),
                  const SizedBox(width: 5),
                  Expanded(child: Text(ci.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700))),
                ])
              else
                Text('—', style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                item == null ? none : '${item.$2 < 0 ? '−' : '+'}${_baht(item.$2.abs())}',
                style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return [
      FxFadeUp(
        index: i++,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            highlight(_isEn ? '👍 Saved the most' : '👍 ประหยัดมากสุด', saved, true, _isEn ? 'No category went down' : 'ไม่มีหมวดที่ลดลง'),
            const SizedBox(width: 10),
            highlight(_isEn ? '📈 Spending went up' : '📈 รายจ่ายพุ่งขึ้น', spike, false, _isEn ? 'No category went up' : 'ไม่มีหมวดที่เพิ่มขึ้น'),
          ],
        ),
      ),
      const SizedBox(height: 14),
      FxFadeUp(
        index: i++,
        child: _cardBox(
          radius: 22,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(_isEn ? 'By category' : 'เจาะลึกรายหมวดหมู่', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w700))),
                  Text(_isEn ? 'Sorted by difference' : 'เรียงตามส่วนต่าง', style: TextStyle(color: _sub, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text(_isEn ? 'No spending to compare' : 'ไม่มีรายจ่ายให้เปรียบเทียบ', style: TextStyle(color: _sub, fontSize: 13))),
                )
              else
                for (final r in rows) _compareCategoryRow(cat(r.$1), r.$2, r.$3, top),
              if (!_compareYears)
                _moreButton(
                  _isEn ? 'Open detailed report' : 'เปิดรายงานละเอียด',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => CompareAnalyticsScreen(controller: _c))),
                ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _compareCategoryRow(CategoryItem cat, double amtA, double amtB, double top) {
    final delta = amtA - amtB;
    final pct = amtB > 0 ? ' (${(delta.abs() / amtB * 100).toStringAsFixed(1)}%)' : '';
    Widget bar(String label, Color labelColor, Color color, double v, bool strong) => Row(
          children: [
            SizedBox(width: 16, child: Text(label, style: TextStyle(color: labelColor, fontSize: 11.5, fontWeight: FontWeight.w700))),
            const SizedBox(width: 6),
            Expanded(child: FxBar(value: v / top, color: color, track: _track, height: 8)),
            const SizedBox(width: 6),
            SizedBox(
              width: 74,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(_baht(v),
                    style: TextStyle(color: strong ? _text : _sub, fontSize: 11.5, fontWeight: strong ? FontWeight.w700 : FontWeight.w400)),
              ),
            ),
          ],
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: _rowLine))),
      child: Column(
        children: [
          Row(
            children: [
              Icon(cat.icon, size: 18, color: cat.color),
              const SizedBox(width: 8),
              Expanded(child: Text(cat.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _text, fontSize: 13.5, fontWeight: FontWeight.w600))),
              const SizedBox(width: 6),
              Flexible(
                child: _deltaChip(
                  delta == 0
                      ? (_isEn ? 'Same' : 'เท่าเดิม')
                      : delta < 0
                          ? '${_isEn ? 'Down' : 'ลดลง'} −${_baht(delta.abs())}$pct'
                          : '${_isEn ? 'Up' : 'เพิ่มขึ้น'} +${_baht(delta)}$pct',
                  good: delta == 0 ? null : delta < 0,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          bar('A', _accent, _accent, amtA, true),
          const SizedBox(height: 6),
          bar('B', _compareBText, _compareB, amtB, false),
        ],
      ),
    );
  }
}

/// Two running-total lines (A solid, B dashed) drawn left to right as [progress] goes 0 → 1.
class _CumulativePainter extends CustomPainter {
  final List<double> a;
  final List<double> b;
  final int buckets;
  final Color colorA;
  final Color colorB;
  final Color grid;
  final double progress;

  _CumulativePainter({
    required this.a,
    required this.b,
    required this.buckets,
    required this.colorA,
    required this.colorB,
    required this.grid,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final f in [12 / 160, 76 / 160, 140 / 160]) {
      canvas.drawLine(Offset(0, size.height * f), Offset(size.width, size.height * f), gridPaint);
    }
    final maxV = [...a, ...b, 1.0].reduce((x, y) => x > y ? x : y);
    final steps = (buckets - 1).clamp(1, 1000);

    Path pathOf(List<double> s) {
      final p = Path();
      for (var k = 0; k < s.length; k++) {
        final pt = Offset(4 + (size.width - 8) * k / steps, size.height * 140 / 160 - size.height * 128 / 160 * (s[k] / (maxV * 1.05)));
        k == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
      }
      return p;
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, -4, size.width * progress, size.height + 8));
    if (b.length > 1) {
      final paintB = Paint()
        ..color = colorB
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (final metric in pathOf(b).computeMetrics()) {
        var d = 0.0;
        while (d < metric.length) {
          canvas.drawPath(metric.extractPath(d, d + 6), paintB);
          d += 10;
        }
      }
    }
    if (a.length > 1) {
      canvas.drawPath(
        pathOf(a),
        Paint()
          ..color = colorA
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CumulativePainter old) =>
      old.progress != progress || old.a != a || old.b != b || old.colorA != colorA || old.colorB != colorB;
}

/// The overview chart card from the draft: expense/income switch, three chart chips
/// (categories donut, period bars, 12-month line), swipe left/right between them,
/// page dots underneath. Every chart animates in lightly.
class _StatsChartCard extends StatefulWidget {
  final ExpenseController controller;
  final PeriodFilterType periodType;
  final DateTime anchor;
  final DateTimeRange? range;
  final List<TransactionItem> periodTxs;
  final TransactionType type;
  final BoxDecoration decoration;
  final Widget typeSwitch;
  final CategoryItem Function(String id, String? name) categoryOf;

  const _StatsChartCard({
    super.key,
    required this.controller,
    required this.periodType,
    required this.anchor,
    required this.range,
    required this.periodTxs,
    required this.type,
    required this.decoration,
    required this.typeSwitch,
    required this.categoryOf,
  });

  @override
  State<_StatsChartCard> createState() => _StatsChartCardState();
}

enum _ChartStyle { donut, bars, line }

class _StatsChartCardState extends State<_StatsChartCard> {
  _ChartStyle _style = _ChartStyle.donut;
  int _dir = 0;
  int? _lineMonth;

  ExpenseController get _c => widget.controller;
  bool get _isEn => _c.isEnglish;
  bool get _isDark => _c.isDarkMode;
  Color get _text => _c.currentTheme.textColor;
  Color get _sub => _c.currentTheme.textSecondaryColor;
  Color get _accent => _isDark ? const Color(0xFF93C5FD) : _c.currentTheme.primaryColor;
  Color get _soft => _isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F3F8);
  Color get _body => _isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
  bool get _expense => widget.type == TransactionType.expense;
  Color get _series => _expense ? const Color(0xFFEF4444) : const Color(0xFF10B981);

  static const _thShort = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
  static const _thLong = ['มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'];
  static const _enShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _enLong = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  String _mShort(int m) => _isEn ? _enShort[m - 1] : _thShort[m - 1];
  String _mLong(int m) => _isEn ? _enLong[m - 1] : _thLong[m - 1];
  String _y(int y) => _isEn ? '$y' : '${y + 543}';
  String _baht(double v) => '฿${FormatUtils.formatCurrency(v.roundToDouble(), trimZero: true)}';
  String _short(double n) => n >= 100000
      ? '฿${(n / 1000).toStringAsFixed(0)}k'
      : n >= 10000
          ? '฿${(n / 1000).toStringAsFixed(1)}k'
          : _baht(n);

  List<_ChartStyle> get _styles =>
      [_ChartStyle.donut, if (widget.periodType != PeriodFilterType.day) _ChartStyle.bars, _ChartStyle.line];

  String _label(_ChartStyle s) {
    switch (s) {
      case _ChartStyle.donut:
        return _isEn ? '🍩 Categories' : '🍩 หมวดหมู่';
      case _ChartStyle.bars:
        if (widget.periodType == PeriodFilterType.month) return _isEn ? '📊 Weekly' : '📊 รายสัปดาห์';
        if (widget.periodType == PeriodFilterType.allTime) return _isEn ? '📊 Yearly' : '📊 รายปี';
        return _isEn ? '📊 Monthly' : '📊 รายเดือน';
      case _ChartStyle.line:
        return _isEn ? '📈 12 months' : '📈 12 เดือน';
    }
  }

  void _go(int j) {
    final styles = _styles;
    final cur = styles.indexOf(_current);
    if (j < 0 || j >= styles.length || j == cur) return;
    HapticFeedback.selectionClick();
    setState(() {
      _dir = j > cur ? 1 : -1;
      _style = styles[j];
    });
  }

  _ChartStyle get _current => _styles.contains(_style) ? _style : _ChartStyle.donut;

  List<TransactionItem> get _typed => widget.periodTxs.where((t) => t.type == widget.type).toList();

  @override
  Widget build(BuildContext context) {
    final styles = _styles;
    final cur = styles.indexOf(_current);
    final Widget chart = switch (_current) {
      _ChartStyle.donut => _donut(),
      _ChartStyle.bars => _bars(),
      _ChartStyle.line => _line(),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: widget.decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          widget.typeSwitch,
          const SizedBox(height: 14),
          Row(
            children: [
              for (var j = 0; j < styles.length; j++) ...[
                if (j > 0) const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _go(j),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 40,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: j == cur ? _accent : _c.currentTheme.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: j == cur ? null : Border.all(color: _isDark ? _c.currentTheme.borderColor : const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        _label(styles[j]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: j == cur ? FontWeight.w600 : FontWeight.w400,
                          color: j == cur ? (_isDark ? const Color(0xFF0F172A) : Colors.white) : _body,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v.abs() < 150) return;
              _go(v < 0 ? cur + 1 : cur - 1);
            },
            child: ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: const Cubic(0.2, 0.7, 0.2, 1),
                  layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [?current]),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: Offset(0.09 * _dir, 0), end: Offset.zero).animate(anim),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(key: ValueKey('${_current.name}-${widget.type.name}'), child: chart),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var j = 0; j < styles.length; j++)
                GestureDetector(
                  onTap: () => _go(j),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: j == cur ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: j == cur ? _accent : (_isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _isEn ? 'Swipe left/right to switch chart' : 'ปัดซ้าย-ขวาเพื่อเปลี่ยนกราฟ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- donut -----------------------------------------------------------------
  Widget _donut() {
    final amounts = <String, double>{};
    final names = <String, String>{};
    for (final t in _typed) {
      amounts[t.categoryId] = (amounts[t.categoryId] ?? 0) + t.amount;
      names[t.categoryId] = t.categoryName;
    }
    final rows = amounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = rows.fold(0.0, (a, e) => a + e.value);
    final slices = [for (final e in rows) (widget.categoryOf(e.key, names[e.key]).color, total > 0 ? e.value / total : 0.0)];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: FxProgress(
            value: 1,
            duration: const Duration(milliseconds: 800),
            builder: (_, t) => Transform.scale(
              scale: 0.88 + 0.12 * t,
              child: Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: CustomPaint(
                  painter: _DonutPainter(
                    slices: slices,
                    progress: t,
                    empty: _isDark ? Colors.white12 : const Color(0xFFEEF0F4),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_expense ? (_isEn ? 'Total spent' : 'รายจ่ายรวม') : (_isEn ? 'Total income' : 'รายรับรวม'),
                            style: TextStyle(fontSize: 12, color: _sub)),
                        const SizedBox(height: 2),
                        Text(_baht(total), style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: _text)),
                        const SizedBox(height: 2),
                        Text('${_typed.length} ${_isEn ? 'items' : 'รายการ'}', style: TextStyle(fontSize: 11.5, color: _sub)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- bars ------------------------------------------------------------------
  Widget _bars() {
    final now = DateTime.now();
    final txs = _typed;
    final items = <(String, String, double)>[]; // label, sub, value
    var caption = '';
    var compact = false;
    final d = widget.anchor;
    switch (widget.periodType) {
      case PeriodFilterType.month:
        final days = DateTime(d.year, d.month + 1, 0).day;
        final weeks = (days / 7).ceil();
        for (var w = 0; w < weeks; w++) {
          final a = w * 7 + 1;
          final b = (a + 6).clamp(1, days);
          final v = txs.where((t) => t.date.day >= a && t.date.day <= b).fold(0.0, (s, t) => s + t.amount);
          items.add((_isEn ? 'Week ${w + 1}' : 'สัปดาห์ ${w + 1}', '$a–$b', v));
        }
        caption = _isEn
            ? 'Weekly totals for ${_mLong(d.month)} ($weeks ranges this month)'
            : 'รวมรายสัปดาห์ของ${_mLong(d.month)} (เดือนนี้มี $weeks ช่วง)';
        break;
      case PeriodFilterType.year:
        compact = true;
        for (var m = 1; m <= 12; m++) {
          final v = txs.where((t) => t.date.month == m).fold(0.0, (s, t) => s + t.amount);
          items.add((_mShort(m).replaceAll('.', ''), '', v));
        }
        final partial = d.year == now.year ? (_isEn ? ' (${_mShort(now.month)} not finished yet)' : ' (${_mShort(now.month)} ยังไม่ครบเดือน)') : '';
        caption = _isEn ? 'Monthly totals, ${d.year}$partial' : 'รวมรายเดือน ปี ${d.year + 543}$partial';
        break;
      case PeriodFilterType.customRange:
      case PeriodFilterType.day:
        final r = widget.range!;
        var m = DateTime(r.start.year, r.start.month);
        final months = <DateTime>[];
        while (m.isBefore(r.end) && months.length < 24) {
          months.add(m);
          m = DateTime(m.year, m.month + 1);
        }
        compact = months.length > 6;
        for (final mm in months) {
          final v = txs.where((t) => t.date.year == mm.year && t.date.month == mm.month).fold(0.0, (s, t) => s + t.amount);
          items.add((compact ? _mShort(mm.month).replaceAll('.', '') : _mLong(mm.month), '', v));
        }
        caption = _isEn ? 'Monthly totals in the selected range' : 'รวมรายเดือนในช่วงที่เลือก';
        break;
      case PeriodFilterType.allTime:
        final all = _c.allTransactions.where((t) => t.type == widget.type).toList();
        if (all.isNotEmpty) {
          final first = all.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b);
          for (var y = first.year; y <= now.year; y++) {
            final v = all.where((t) => t.date.year == y).fold(0.0, (s, t) => s + t.amount);
            final sub = y == first.year && first.month > 1
                ? '${_mShort(first.month)}–${_mShort(12)}'
                : y == now.year
                    ? (_isEn ? 'to ${_mShort(now.month)}' : 'ถึง ${_mShort(now.month)}')
                    : (_isEn ? 'full year' : 'ทั้งปี');
            items.add((_y(y), sub, v));
          }
        }
        caption = _isEn ? 'Yearly totals' : 'รวมรายปี';
        break;
    }
    final hi = items.fold(1.0, (a, e) => e.$3 > a ? e.$3 : a);
    final gap = compact ? 4.0 : 10.0;
    final n = items.length;
    final total = Duration(milliseconds: 550 + 45 * n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(caption, style: TextStyle(fontSize: 12.5, color: _sub)),
        const SizedBox(height: 8),
        Container(
          height: 170,
          padding: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _isDark ? Colors.white12 : const Color(0xFFE2E8F0)))),
          child: FxProgress(
            value: 1,
            duration: total,
            builder: (_, t) => Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var k = 0; k < n; k++) ...[
                  if (k > 0) SizedBox(width: gap),
                  Expanded(
                    child: Builder(builder: (_) {
                      final start = 45 * k / total.inMilliseconds;
                      final local = ((t - start) / (550 / total.inMilliseconds)).clamp(0.0, 1.0);
                      final h = (items[k].$3 / hi * 130).clamp(4.0, 130.0) * Curves.easeOutCubic.transform(local);
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!compact)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(items[k].$3 > 0 ? _short(items[k].$3) : '–',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _body)),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            constraints: const BoxConstraints(maxWidth: 44),
                            height: h,
                            decoration: BoxDecoration(
                              color: _series,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8), bottom: Radius.circular(3)),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var k = 0; k < n; k++) ...[
              if (k > 0) SizedBox(width: gap),
              Expanded(
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(items[k].$1,
                          maxLines: 1, style: TextStyle(fontSize: compact ? 10 : 11.5, fontWeight: FontWeight.w600, color: _body)),
                    ),
                    if (items[k].$2.isNotEmpty)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(items[k].$2, maxLines: 1, style: TextStyle(fontSize: compact ? 10 : 11.5, color: const Color(0xFF94A3B8))),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
        if (n == 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_isEn ? 'No data yet' : 'ยังไม่มีข้อมูล', style: TextStyle(fontSize: 12.5, color: _sub)),
          ),
      ],
    );
  }

  // ---- 12-month line -----------------------------------------------------------
  int get _lineYear {
    if (widget.periodType == PeriodFilterType.allTime) return DateTime.now().year;
    if (widget.periodType == PeriodFilterType.customRange) return widget.range!.end.subtract(const Duration(days: 1)).year;
    return widget.anchor.year;
  }

  Widget _line() {
    final now = DateTime.now();
    final year = _lineYear;
    final all = _c.allTransactions.where((t) => t.type == widget.type && t.date.year == year);
    final vals = List<double>.filled(12, 0);
    for (final t in all) {
      vals[t.date.month - 1] += t.amount;
    }
    final lastMonth = year < now.year ? 12 : (year == now.year ? now.month : 0); // months that have started
    final complete = year < now.year ? 12 : (year == now.year ? now.month - 1 : 0);
    final known = vals.sublist(0, (complete > 0 ? complete : lastMonth).clamp(0, 12));
    final avg = known.isEmpty ? 0.0 : known.reduce((a, b) => a + b) / known.length;
    var peakI = 0;
    for (var k = 0; k < known.length; k++) {
      if (known[k] > known[peakI]) peakI = k;
    }
    final defaultSel = widget.periodType == PeriodFilterType.month || widget.periodType == PeriodFilterType.day
        ? widget.anchor.month - 1
        : (lastMonth > 0 ? lastMonth - 1 : 0);
    final sel = (_lineMonth ?? defaultSel).clamp(0, (lastMonth > 0 ? lastMonth : 12) - 1);
    final yearTotal = vals.fold(0.0, (a, b) => a + b);
    final isCurrent = year == now.year && sel == now.month - 1;

    Widget chip(String text, Color fg, Color bg) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: _isDark ? fg.withValues(alpha: 0.16) : bg, borderRadius: BorderRadius.circular(8)),
          child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _isDark ? Colors.white : fg)),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            chip(_isEn ? '$year' : 'พ.ศ. ${year + 543}', const Color(0xFF3730A3), const Color(0xFFEEF2FF)),
            if (known.isNotEmpty && known[peakI] > 0)
              chip('🔥 ${_isEn ? 'Peak' : 'สูงสุด'}: ${_mLong(peakI + 1)} ${_short(known[peakI])}', const Color(0xFF9A3412), const Color(0xFFFFF1E6)),
            chip('${_isEn ? 'Avg' : 'เฉลี่ย'} ${_baht(avg)}/${_isEn ? 'month' : 'เดือน'}', const Color(0xFF334155), const Color(0xFFF1F3F8)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: FxProgress(
            value: 1,
            duration: const Duration(milliseconds: 900),
            builder: (_, t) => CustomPaint(
              painter: _YearLinePainter(
                values: vals.sublist(0, lastMonth.clamp(0, 12)),
                avg: avg,
                selected: sel,
                color: _series,
                grid: _isDark ? Colors.white10 : const Color(0xFFEEF0F4),
                dot: _c.currentTheme.cardBackground,
                progress: t,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var m = 0; m < 12; m++) ...[
              if (m > 0) const SizedBox(width: 2),
              Expanded(
                child: GestureDetector(
                  onTap: m < lastMonth
                      ? () {
                          HapticFeedback.selectionClick();
                          setState(() => _lineMonth = m);
                        }
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: m == sel ? _accent : (m < lastMonth ? _soft : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _mShort(m + 1).replaceAll('.', ''),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: m == sel ? FontWeight.w700 : FontWeight.w400,
                          color: m == sel
                              ? (_isDark ? const Color(0xFF0F172A) : Colors.white)
                              : (m < lastMonth ? _body : const Color(0xFFCBD5E1)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_mLong(sel + 1)} ${_y(year)}${isCurrent ? (_isEn ? ' (in progress)' : ' (ยังไม่ครบเดือน)') : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text),
                ),
              ),
              Text(
                '${_baht(vals[sel])}${vals[sel] > 0 && yearTotal > 0 ? ' • ${(vals[sel] / yearTotal * 100).round()}%' : ''}',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _series),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<(Color, double)> slices;
  final double progress;
  final Color empty;

  _DonutPainter({required this.slices, required this.progress, required this.empty});

  @override
  void paint(Canvas canvas, Size size) {
    const thickness = 36.0;
    final rect = Rect.fromLTWH(thickness / 2, thickness / 2, size.width - thickness, size.height - thickness);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    if (slices.isEmpty) {
      canvas.drawArc(rect, 0, 6.2832, false, paint..color = empty);
      return;
    }
    var start = -1.5708;
    final sweepTotal = 6.2832 * progress;
    var used = 0.0;
    for (final (color, share) in slices) {
      final sweep = 6.2832 * share;
      final visible = (sweepTotal - used).clamp(0.0, sweep);
      if (visible <= 0) break;
      canvas.drawArc(rect, start, visible, false, paint..color = color);
      start += sweep;
      used += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress || old.slices != slices || old.empty != empty;
}

/// Monthly totals for one year: soft area, dashed average, drawn line, selected-month marker.
class _YearLinePainter extends CustomPainter {
  final List<double> values;
  final double avg;
  final int selected;
  final Color color;
  final Color grid;
  final Color dot;
  final double progress;

  _YearLinePainter({
    required this.values,
    required this.avg,
    required this.selected,
    required this.color,
    required this.grid,
    required this.dot,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final top = size.height * 14 / 150;
    final base = size.height * 130 / 150;
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final y in [top, size.height * 72 / 150, base]) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }
    if (values.isEmpty) return;
    final hi = [...values, avg, 1.0].reduce((a, b) => a > b ? a : b) * 1.1;
    double x(int i) => 8 + i * (w - 16) / 11;
    double y(double v) => base - v / hi * (base - top * 0.2);
    final pts = [for (var i = 0; i < values.length; i++) Offset(x(i), y(values[i]))];

    // area fades in during the second half
    final area = Path()..moveTo(pts.first.dx, base);
    for (final p in pts) {
      area.lineTo(p.dx, p.dy);
    }
    area
      ..lineTo(pts.last.dx, base)
      ..close();
    canvas.drawPath(area, Paint()..color = color.withValues(alpha: 0.10 * ((progress - 0.4) / 0.6).clamp(0.0, 1.0)));

    // dashed average
    final avgY = y(avg);
    final dash = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.5;
    for (var d = 0.0; d < w; d += 10) {
      canvas.drawLine(Offset(d, avgY), Offset((d + 5).clamp(0, w), avgY), dash);
    }

    // line drawn left to right
    if (pts.length > 1) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, w * progress, size.height));
      final line = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        line.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        line,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.restore();
    }

    if (selected < pts.length && progress > 0.6) {
      final p = pts[selected];
      canvas.drawCircle(p, 6, Paint()..color = dot);
      canvas.drawCircle(
        p,
        6,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(_YearLinePainter old) =>
      old.progress != progress || old.selected != selected || old.values != values || old.color != color || old.avg != avg;
}
