import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction_item.dart';
import '../models/category_item.dart';
import '../state/expense_controller.dart';
import '../widgets/analytics_carousel_chart_card.dart';
import '../widgets/meow_fx.dart';
import '../widgets/meow_wheel_date_picker.dart';
import '../utils/format_utils.dart';
import 'category_management_screen.dart';
import 'compare_analytics_screen.dart';
import '../widgets/transaction_detail_sheet.dart';
import '../services/slip_auto_sync_service.dart';
import '../widgets/meow_mascot_widget.dart';

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
  static const Color _compareB = Color(0xFF38BDF8);

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

  String _baht(double v) => '฿${FormatUtils.formatCurrency(v, trimZero: true)}';
  String _pct(double v) => '${v.toStringAsFixed(1)}%';

  // ---------------------------------------------------------------------------
  // Shared UI pieces
  // ---------------------------------------------------------------------------
  BoxDecoration get _cardDeco => BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      );

  Widget _cardBox({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) =>
      Container(padding: padding, decoration: _cardDeco, child: child);

  /// Two or more options in a grey track; the selected one is a white pill.
  Widget _segmented<T>({
    required List<(T, String)> options,
    required T value,
    required ValueChanged<T> onChanged,
    Color? selectedText,
    double height = 40,
    double fontSize = 13,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: _seg, borderRadius: BorderRadius.circular(12)),
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
                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 3, offset: const Offset(0, 1))]
                        : null,
                  ),
                  child: Text(
                    o.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: o.$1 == value ? FontWeight.w700 : FontWeight.w500,
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
          onChangedExtra?.call();
        }),
      );

  /// Small rounded chip that shows a change, e.g. "▼ ฿2,650 (12.6%)".
  Widget _deltaChip(String text, {bool? good}) {
    final color = good == null ? _sub : (good ? _income : _expense);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(7)),
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _categoryTile(CategoryItem cat, {double size = 40}) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(size * 0.3)),
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
    final theme = _c.currentTheme;
    final heroText = theme.heroTextColor(_isDark);
    final heroMuted = theme.heroTextMutedColor(_isDark);
    final subtitle = switch (_activeTab) {
      AnalyticsMainTab.overview => '${_isEn ? 'Financial summary' : 'สรุปวิเคราะห์การเงิน'} • ${_formatPeriodTitle()}',
      AnalyticsMainTab.categoryTags => _isEn ? 'Categories & sub-tags' : 'หมวดหมู่ & #แท็กย่อย',
      AnalyticsMainTab.comparison => _isEn ? 'Compare your money' : 'เปรียบเทียบการเงิน',
    };
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: theme.heroGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isEn ? 'Statistics' : 'สถิติ', style: TextStyle(color: heroText, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        subtitle,
                        key: ValueKey(subtitle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: heroMuted, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              MeowMascotWidget(
                size: 44,
                mascotId: _c.selectedMascotId,
                accessory: _c.selectedMascotAccessory,
                customPhotoPath: _c.customAvatarPath,
                isCustomPhoto: _c.isCustomAvatarEnabled,
                withPen: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: heroText.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                _headerTab(AnalyticsMainTab.overview, _isEn ? 'Overview' : 'ภาพรวม'),
                _headerTab(AnalyticsMainTab.categoryTags, _isEn ? 'Categories & #tags' : 'หมวดหมู่ & #แท็ก'),
                _headerTab(AnalyticsMainTab.comparison, _isEn ? 'Compare' : 'เทียบเดือน'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerTab(AnalyticsMainTab tab, String label) {
    final selected = _activeTab == tab;
    final heroText = _c.currentTheme.heroTextColor(_isDark);
    return Expanded(
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
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? _accent : heroText.withValues(alpha: 0.85),
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
            height: 40,
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
        const SizedBox(height: 12),
        FxFadeUp(index: i++, child: _buildSummaryCard(stats)),
        const SizedBox(height: 12),
        FxFadeUp(index: i++, child: _typeSegment(categories: false)),
        const SizedBox(height: 10),
        FxFadeUp(index: i++, child: _buildChartCard(txs, stats)),
        const SizedBox(height: 12),
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
        );
      }
    }
    final days = _daysForAverage(_rangeOf(_periodType, _currentAnchorDate));
    final perDay = (s.expense / days).roundToDouble();
    final used = s.income > 0 ? (s.expense / s.income).clamp(0.0, 1.0) : (s.expense > 0 ? 1.0 : 0.0);

    Widget column(String label, double amount, Color color, String foot, {String prefix = ''}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: _countUp(amount, TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color), prefix: prefix),
              ),
              const SizedBox(height: 2),
              Text(foot, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: _sub)),
            ],
          ),
        );
    Widget divider() => Container(width: 1, height: 52, margin: const EdgeInsets.symmetric(horizontal: 10), color: _line);

    final netColor = s.net >= 0 ? _accent : _expense;
    final items = _isEn ? 'items' : 'รายการ';
    return _cardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_summaryTitle,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _text)),
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              column(_isEn ? 'Income' : 'รายรับ', s.income, _income, '${s.incomeCount} $items'),
              divider(),
              column(_isEn ? 'Expense' : 'รายจ่าย', s.expense, _expense, '${s.expenseCount} $items'),
              divider(),
              column(
                _isEn ? 'Left over' : 'คงเหลือ',
                s.net.abs(),
                netColor,
                s.income > 0 ? '${_isEn ? 'Saved' : 'ออม'} ${_pct(s.savingsRate)}' : '—',
                prefix: s.net >= 0 ? '+' : '-',
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: FxProgress(
                value: used,
                builder: (_, v) => Row(
                  children: [
                    Expanded(flex: (v * 1000).round(), child: Container(color: _expense)),
                    Expanded(flex: ((1 - v) * 1000).round(), child: Container(color: s.income > 0 ? _income : _track)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  s.income > 0
                      ? (_isEn ? 'Spent ${_pct(s.expense / s.income * 100)} of income' : 'ใช้ไป ${(s.expense / s.income * 100).toStringAsFixed(0)}% ของรายรับ')
                      : (_isEn ? 'No income in this period' : 'ยังไม่มีรายรับในช่วงนี้'),
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
    final items = txs.where((t) => t.type == _selectedType).toList();
    final total = _selectedType == TransactionType.expense ? s.expense : s.income;
    return AnalyticsCarouselChartCard(
      transactions: items,
      selectedType: _selectedType,
      totalAmount: total,
      periodTypeStr: _periodType.name,
      anchorDate: _currentAnchorDate,
      isDark: _isDark,
      isEnglish: _isEn,
      allCategories: _c.categories,
      isProcessingSlips: _c.isProcessingSlips,
      isInitialScan: !_c.storage.isInitialDeviceScanCompleted(),
      hasNoTransactionsAtAll: _c.allTransactions.isEmpty,
      onTriggerScan: () => SlipAutoSyncService.scanAndAutoImportNewSlips(_c),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
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
                  style: TextStyle(color: _sub, fontSize: 11.5),
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
              first: k == 0,
            ),
          if (sorted.length > 5)
            Center(
              child: TextButton(
                onPressed: () => setState(() => _showAllCategories = !_showAllCategories),
                child: Text(
                  _showAllCategories
                      ? (_isEn ? 'Show less' : 'แสดงน้อยลง')
                      : (_isEn ? 'Show all ${sorted.length} categories' : 'ดูทั้งหมด ${sorted.length} หมวด'),
                  style: TextStyle(color: _accent, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            )
          else
            const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _categoryRow(CategoryItem cat, double amount, int count, double share, {bool first = false}) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedDrillCategoryId = cat.id;
          _expandedTag = null;
          _activeTab = AnalyticsMainTab.categoryTags;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: _line.withValues(alpha: 0.6)))),
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
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _text, fontSize: 14.5, fontWeight: FontWeight.w600)),
                      ),
                      Text(_baht(amount), style: TextStyle(color: _text, fontSize: 14.5, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  FxBar(value: share, color: cat.color, track: _track, height: 6),
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
            Icon(Icons.chevron_right_rounded, size: 20, color: _sub),
          ],
        ),
      ),
    );
  }

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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: _line)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _showPeriodSheet,
                    child: SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(Icons.calendar_today_outlined, size: 16, color: _accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _periodType == PeriodFilterType.month || _periodType == PeriodFilterType.allTime
                                  ? _formatPeriodTitle()
                                  : '$_periodTypeLabel • ${_formatPeriodTitle()}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700),
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
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accent,
                    side: BorderSide(color: _line),
                    backgroundColor: _card,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CategoryManagementScreen(controller: _c)),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(_isEn ? 'Manage' : 'จัดการหมวด', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FxFadeUp(index: i++, child: _typeSegment(categories: true)),
        const SizedBox(height: 16),
        if (selected == null)
          _emptyCard(_isEn ? 'No categories yet' : 'ยังไม่มีหมวดหมู่')
        else ...[
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              _isEn ? 'Choose a category (${used.length})' : 'เลือกหมวดหมู่ (${used.length} หมวด)',
              style: TextStyle(color: _sub, fontSize: 13, fontWeight: FontWeight.w600),
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
          const SizedBox(height: 12),
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
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  decoration: BoxDecoration(
                    color: cat.id == selected.id ? cat.color.withValues(alpha: _isDark ? 0.18 : 0.08) : _card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cat.id == selected.id ? cat.color : _line, width: cat.id == selected.id ? 1.6 : 1),
                  ),
                  child: Column(
                    children: [
                      Icon(cat.icon, color: cat.color, size: 24),
                      const SizedBox(height: 6),
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
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: onHero.withValues(alpha: 0.85), fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: onHero, fontSize: 14, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: onHero.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(13)),
                child: Icon(cat.icon, color: onHero, size: 24),
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
                      style: TextStyle(color: onHero.withValues(alpha: 0.85), fontSize: 12),
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
            child: _countUp(total, TextStyle(color: onHero, fontSize: 30, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              tile(_isEn ? 'Share of total' : 'สัดส่วนจากทั้งหมด', periodTotal > 0 ? _pct(total / periodTotal * 100) : '—'),
              if (compare != null) ...[
                const SizedBox(width: 8),
                tile(_isEn ? 'vs $_previousLabel' : 'เทียบ $_previousLabel', compare),
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

    return Column(
      children: [
        _cardBox(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
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
                  if (rows.isNotEmpty) Text(_isEn ? 'Tap to see items' : 'แตะเพื่อดูรายการ', style: TextStyle(color: _sub, fontSize: 11.5)),
                ],
              ),
              const SizedBox(height: 6),
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
                      setState(() => _expandedTag = _expandedTag == rows[k].$1 ? null : rows[k].$1);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(border: k == 0 ? null : Border(top: BorderSide(color: _line.withValues(alpha: 0.6)))),
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
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Text(_baht(rows[k].$3), style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                FxBar(
                                  value: total > 0 ? rows[k].$3 / total : 0,
                                  color: rows[k].$1 == _untaggedKey ? _sub.withValues(alpha: 0.4) : cat.color,
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
                            turns: _expandedTag == rows[k].$1 ? 0.25 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: Icon(Icons.chevron_right_rounded, size: 20, color: _sub),
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
          child: _expandedTag == null || !rows.any((r) => r.$1 == _expandedTag)
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _tagItemsCard(
                    rows.firstWhere((r) => r.$1 == _expandedTag).$2,
                    txsFor(_expandedTag!),
                    cat.color,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _tagItemsCard(String title, List<TransactionItem> txs, Color color) {
    final total = txs.fold(0.0, (a, t) => a + t.amount);
    const maxShown = 50;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20), border: Border.all(color: color, width: 1.4)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$title (${txs.length} ${_isEn ? 'items' : 'รายการ'})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _text, fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
              ),
              Text(_baht(total), style: TextStyle(color: _text, fontSize: 14.5, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          for (var k = 0; k < txs.length && k < maxShown; k++) _txRow(txs[k], first: k == 0),
          if (txs.length > maxShown)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                _isEn ? '+${txs.length - maxShown} more' : 'และอีก ${txs.length - maxShown} รายการ',
                style: TextStyle(color: _sub, fontSize: 12),
              ),
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
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: _line.withValues(alpha: 0.6)))),
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: _accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(_isEn ? 'slip' : 'สลิป', style: TextStyle(color: _accent, fontSize: 10.5, fontWeight: FontWeight.w700)),
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
            Text('${isInc ? '+' : (isExp ? '-' : '')}${_baht(tx.amount)}', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: COMPARE
  // ---------------------------------------------------------------------------
  DateTimeRange get _rangeA => _compareYears
      ? DateTimeRange(start: DateTime(_compareYearA), end: DateTime(_compareYearA + 1))
      : DateTimeRange(start: DateTime(_compareMonthA.year, _compareMonthA.month), end: DateTime(_compareMonthA.year, _compareMonthA.month + 1));

  DateTimeRange get _rangeB => _compareYears
      ? DateTimeRange(start: DateTime(_compareYearB), end: DateTime(_compareYearB + 1))
      : DateTimeRange(start: DateTime(_compareMonthB.year, _compareMonthB.month), end: DateTime(_compareMonthB.year, _compareMonthB.month + 1));

  String get _labelA => _compareYears ? (_isEn ? '$_compareYearA' : 'ปี ${_compareYearA + 543}') : _monthYearLong(_compareMonthA);
  String get _labelB => _compareYears ? (_isEn ? '$_compareYearB' : 'ปี ${_compareYearB + 543}') : _monthYearLong(_compareMonthB);
  String get _shortA => _compareYears ? _yearStr(_compareYearA) : _monthShort(_compareMonthA.month);
  String get _shortB => _compareYears ? _yearStr(_compareYearB) : _monthShort(_compareMonthB.month);

  /// Running total of spending: per day for months, per month for years.
  List<double> _cumulative(List<TransactionItem> txs, DateTimeRange r) {
    final buckets = _compareYears ? 12 : r.end.difference(r.start).inHours ~/ 24;
    final now = DateTime.now();
    var last = buckets;
    if (r.start.isBefore(now) && r.end.isAfter(now)) {
      last = _compareYears ? now.month : now.day;
    }
    final perBucket = List<double>.filled(buckets, 0);
    for (final t in txs) {
      if (t.type != TransactionType.expense) continue;
      final idx = _compareYears ? t.date.month - 1 : t.date.day - 1;
      if (idx >= 0 && idx < buckets) perBucket[idx] += t.amount;
    }
    final out = <double>[];
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
            options: [(false, _isEn ? 'Compare 2 months' : 'เทียบ 2 เดือน'), (true, _isEn ? 'Compare 2 years' : 'เทียบ 2 ปี')],
            value: _compareYears,
            onChanged: (v) => setState(() => _compareYears = v),
          ),
        ),
        const SizedBox(height: 12),
        FxFadeUp(index: i++, child: _comparePickers()),
        const SizedBox(height: 12),
        if (a.count == 0 && b.count == 0)
          FxFadeUp(index: i++, child: _emptyCard(_isEn ? 'No transactions in either period yet' : 'ทั้งสองช่วงยังไม่มีรายการให้เทียบ'))
        else ...[
          FxFadeUp(index: i++, child: _verdictCard(a, b)),
          const SizedBox(height: 12),
          FxFadeUp(index: i++, child: _metricsTable(a, b)),
          const SizedBox(height: 12),
          FxFadeUp(index: i++, child: _cumulativeCard(_cumulative(txA, _rangeA), _cumulative(txB, _rangeB), a, b)),
          const SizedBox(height: 12),
          ..._highlightsAndCategories(a, b, i),
        ],
      ],
    );
  }

  Widget _comparePickers() {
    Widget box(bool isA) {
      final color = isA ? _accent : _compareB;
      return Expanded(
        child: Material(
          color: _card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color, width: 1.6)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _pickCompare(isA),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isA ? (_isEn ? 'A • main' : 'A • ช่วงหลัก') : (_isEn ? 'B • compare with' : 'B • เปรียบเทียบ'),
                      style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(isA ? _labelA : _labelB,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(_isEn ? 'Tap to change' : 'แตะเพื่อเปลี่ยน', style: TextStyle(color: _sub, fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        box(true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _navButton(Icons.swap_horiz_rounded, () {
            HapticFeedback.selectionClick();
            setState(() {
              final m = _compareMonthA;
              _compareMonthA = _compareMonthB;
              _compareMonthB = m;
              final y = _compareYearA;
              _compareYearA = _compareYearB;
              _compareYearB = y;
            });
          }),
        ),
        box(false),
      ],
    );
  }

  Widget _verdictCard(_PeriodStats a, _PeriodStats b) {
    final better = a.net >= b.net;
    final expDelta = a.expense - b.expense;
    final netDelta = a.net - b.net;
    final title = better
        ? (_isEn ? '$_shortA managed money better' : '$_shortA บริหารเงินได้ดีกว่า $_shortB')
        : (_isEn ? '$_shortA kept less than $_shortB' : '$_shortA เหลือเงินน้อยกว่า $_shortB');
    final parts = <String>[];
    if (b.expense > 0) {
      final p = (expDelta.abs() / b.expense * 100).toStringAsFixed(1);
      parts.add(expDelta <= 0
          ? (_isEn ? 'Spent ${_baht(expDelta.abs())} less ($p%)' : 'ใช้จ่ายน้อยลง ${_baht(expDelta.abs())} ($p%)')
          : (_isEn ? 'Spent ${_baht(expDelta)} more ($p%)' : 'ใช้จ่ายมากขึ้น ${_baht(expDelta)} ($p%)'));
    }
    parts.add(netDelta >= 0
        ? (_isEn ? 'savings up ${_baht(netDelta)}' : 'เงินออมสุทธิเพิ่มขึ้น ${_baht(netDelta)}')
        : (_isEn ? 'savings down ${_baht(netDelta.abs())}' : 'เงินออมสุทธิลดลง ${_baht(netDelta.abs())}'));
    final color = better ? _income : _expense;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(better ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontSize: 14.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(parts.join(' • '), style: TextStyle(color: _text, fontSize: 12.5, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricsTable(_PeriodStats a, _PeriodStats b) {
    final daysA = _daysForAverage(_rangeA);
    final daysB = _daysForAverage(_rangeB);
    final avgA = (a.expense / daysA).roundToDouble();
    final avgB = (b.expense / daysB).roundToDouble();
    final items = _isEn ? 'items' : 'รายการ';

    String money(double d) => '${d <= 0 ? '▼' : '▲'} ${_baht(d.abs())}';
    String moneyPct(double d, double base) => base > 0 ? '${money(d)} (${(d.abs() / base * 100).toStringAsFixed(1)}%)' : money(d);

    Widget row(String label, String va, String vb, String chip, bool? good, {bool first = false}) => Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: _line.withValues(alpha: 0.6)))),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(color: _text, fontSize: 13.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    _deltaChip(chip, good: good),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(va, textAlign: TextAlign.right, maxLines: 1, style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              Expanded(
                flex: 3,
                child: Text(vb, textAlign: TextAlign.right, maxLines: 1, style: TextStyle(color: _sub, fontSize: 13.5)),
              ),
            ],
          ),
        );

    final expD = a.expense - b.expense;
    final incD = a.income - b.income;
    final netD = a.net - b.net;
    final rateD = a.savingsRate - b.savingsRate;
    final avgD = avgA - avgB;
    final cntD = a.count - b.count;
    return _cardBox(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(flex: 5, child: Text(_isEn ? 'Metric' : 'ตัวชี้วัด', style: TextStyle(color: _sub, fontSize: 12))),
              Expanded(flex: 3, child: Text('A', textAlign: TextAlign.right, style: TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w700))),
              Expanded(flex: 3, child: Text('B', textAlign: TextAlign.right, style: TextStyle(color: _compareB, fontSize: 12, fontWeight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 4),
          row(_isEn ? 'Total expense' : 'รายจ่ายรวม', _baht(a.expense), _baht(b.expense), moneyPct(expD, b.expense), expD == 0 ? null : expD < 0, first: true),
          row(_isEn ? 'Total income' : 'รายรับรวม', _baht(a.income), _baht(b.income), moneyPct(incD, b.income), incD == 0 ? null : incD > 0),
          row(_isEn ? 'Net savings' : 'เงินออมสุทธิ', _baht(a.net), _baht(b.net), money(netD), netD == 0 ? null : netD > 0),
          row(
            _isEn ? 'Savings rate' : 'อัตราการออม',
            _pct(a.savingsRate),
            _pct(b.savingsRate),
            '${rateD <= 0 ? '▼' : '▲'} ${rateD.abs().toStringAsFixed(1)} ${_isEn ? 'pts' : 'จุด'}',
            rateD == 0 ? null : rateD > 0,
          ),
          row(_isEn ? 'Avg spend/day' : 'เฉลี่ยจ่าย/วัน', _baht(avgA), _baht(avgB), '${money(avgD)}${_isEn ? '/day' : '/วัน'}', avgD == 0 ? null : avgD < 0),
          row(_isEn ? 'Transactions' : 'จำนวนรายการ', '${a.count} $items', '${b.count} $items', '${cntD <= 0 ? '▼' : '▲'} ${cntD.abs()} $items', null),
        ],
      ),
    );
  }

  Widget _cumulativeCard(List<double> sa, List<double> sb, _PeriodStats a, _PeriodStats b) {
    final unit = _compareYears ? (_isEn ? 'month' : 'เดือน') : (_isEn ? 'day' : 'วันที่');
    final buckets = _compareYears ? 12 : 31;
    return _cardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_compareYears ? (_isEn ? 'Cumulative spending by month' : 'ใช้จ่ายสะสมรายเดือน') : (_isEn ? 'Cumulative daily spending' : 'ใช้จ่ายสะสมรายวัน'),
              style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
            _isEn ? 'Lower line = slower spending' : 'เส้นต่ำกว่า = ใช้จ่ายช้ากว่า • ดูได้ว่าช่วงไหนเงินไหลออกเร็ว',
            style: TextStyle(color: _sub, fontSize: 12),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: FxProgress(
              key: ValueKey('$_labelA|$_labelB|${sa.length}|${sb.length}'),
              value: 1,
              duration: const Duration(milliseconds: 900),
              builder: (_, t) => CustomPaint(
                size: Size.infinite,
                painter: _CumulativePainter(a: sa, b: sb, buckets: buckets, colorA: _accent, colorB: _compareB, grid: _line, progress: t),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(_compareYears ? (_isEn ? 'Jan' : 'ม.ค.') : '$unit 1', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _sub, fontSize: 11))),
              Flexible(child: Text(_compareYears ? (_isEn ? 'Jun' : 'มิ.ย.') : '$unit 15', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _sub, fontSize: 11))),
              Flexible(child: Text(_compareYears ? (_isEn ? 'Dec' : 'ธ.ค.') : (_isEn ? 'month end' : 'สิ้นเดือน'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _sub, fontSize: 11))),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _legend(_accent, 'A $_shortA • ${_baht(a.expense)}', dashed: false),
              _legend(_compareB, 'B $_shortB • ${_baht(b.expense)}', dashed: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String text, {required bool dashed}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 3,
            child: dashed
                ? Row(children: [
                    Expanded(child: Container(color: color)),
                    const SizedBox(width: 3),
                    Expanded(child: Container(color: color)),
                  ])
                : Container(color: color),
          ),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: _text, fontSize: 12)),
        ],
      );

  List<Widget> _highlightsAndCategories(_PeriodStats a, _PeriodStats b, int startIndex) {
    var i = startIndex;
    final ids = {...a.expenseByCat.keys, ...b.expenseByCat.keys};
    final rows = [
      for (final id in ids) (id, a.expenseByCat[id] ?? 0.0, b.expenseByCat[id] ?? 0.0),
    ]..sort((x, y) => (y.$2 - y.$3).abs().compareTo((x.$2 - x.$3).abs()));

    final names = <String, String>{};
    for (final t in [..._inRange(_rangeA), ..._inRange(_rangeB)]) {
      names[t.categoryId] = t.categoryName;
    }
    CategoryItem cat(String id) => _categoryOf(id, fallbackName: names[id]);

    (String, double)? saved;
    (String, double)? spike;
    for (final r in rows) {
      final d = r.$2 - r.$3;
      if (d < 0 && (saved == null || d < saved.$2)) saved = (r.$1, d);
      if (d > 0 && (spike == null || d > spike.$2)) spike = (r.$1, d);
    }

    Widget highlight(String label, IconData icon, (String, double) item, bool good) {
      final c = good ? _income : _expense;
      final ci = cat(item.$1);
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: c.withValues(alpha: _isDark ? 0.12 : 0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: c.withValues(alpha: 0.25))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 15, color: c),
                const SizedBox(width: 4),
                Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Icon(ci.icon, size: 18, color: ci.color),
                const SizedBox(width: 6),
                Expanded(child: Text(ci.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 2),
              Text('${item.$2 < 0 ? '-' : '+'}${_baht(item.$2.abs())}', style: TextStyle(color: c, fontSize: 13.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
    }

    return [
      if (saved != null || spike != null) ...[
        FxFadeUp(
          index: i++,
          child: Row(
            children: [
              if (saved != null) highlight(_isEn ? 'Saved the most' : 'ประหยัดมากสุด', Icons.thumb_up_alt_outlined, saved, true),
              if (saved != null && spike != null) const SizedBox(width: 10),
              if (spike != null) highlight(_isEn ? 'Spending went up' : 'รายจ่ายพุ่งขึ้น', Icons.trending_up_rounded, spike, false),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
      FxFadeUp(
        index: i++,
        child: _cardBox(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(_isEn ? 'By category' : 'เจาะลึกรายหมวดหมู่', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w700))),
                  Text(_isEn ? 'Sorted by difference' : 'เรียงตามส่วนต่าง', style: TextStyle(color: _sub, fontSize: 11.5)),
                ],
              ),
              const SizedBox(height: 4),
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text(_isEn ? 'No spending to compare' : 'ไม่มีรายจ่ายให้เปรียบเทียบ', style: TextStyle(color: _sub, fontSize: 13))),
                )
              else
                for (var k = 0; k < rows.length; k++) _compareCategoryRow(cat(rows[k].$1), rows[k].$2, rows[k].$3, first: k == 0),
              if (!_compareYears)
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CompareAnalyticsScreen(controller: _c))),
                    child: Text(_isEn ? 'Open detailed report' : 'เปิดรายงานละเอียด', style: TextStyle(color: _accent, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _compareCategoryRow(CategoryItem cat, double amtA, double amtB, {bool first = false}) {
    final delta = amtA - amtB;
    final maxAmt = [amtA, amtB, 1.0].reduce((x, y) => x > y ? x : y);
    final pct = amtB > 0 ? ' (${(delta.abs() / amtB * 100).toStringAsFixed(1)}%)' : '';
    Widget bar(String label, Color color, double v) => Row(
          children: [
            SizedBox(width: 18, child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700))),
            Expanded(child: FxBar(value: v / maxAmt, color: color, track: _track, height: 7)),
            SizedBox(
              width: 82,
              child: Text(_baht(v), textAlign: TextAlign.right, maxLines: 1, style: TextStyle(color: label == 'A' ? _text : _sub, fontSize: 12.5, fontWeight: label == 'A' ? FontWeight.w700 : FontWeight.w500)),
            ),
          ],
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: _line.withValues(alpha: 0.6)))),
      child: Column(
        children: [
          Row(
            children: [
              Icon(cat.icon, size: 20, color: cat.color),
              const SizedBox(width: 8),
              Expanded(child: Text(cat.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600))),
              const SizedBox(width: 6),
              Flexible(
               child: _deltaChip(
                delta == 0
                    ? (_isEn ? 'Same' : 'เท่าเดิม')
                    : delta < 0
                        ? '${_isEn ? 'Down' : 'ลดลง'} -${_baht(delta.abs())}$pct'
                        : '${_isEn ? 'Up' : 'เพิ่มขึ้น'} +${_baht(delta)}$pct',
                good: delta == 0 ? null : delta < 0,
               ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          bar('A', _accent, amtA),
          const SizedBox(height: 5),
          bar('B', _compareB, amtB),
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
    for (var k = 0; k < 3; k++) {
      final y = size.height * k / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final maxV = [...a, ...b, 1.0].reduce((x, y) => x > y ? x : y);
    final steps = (buckets - 1).clamp(1, 1000);

    Path pathOf(List<double> s) {
      final p = Path();
      for (var k = 0; k < s.length; k++) {
        final pt = Offset(size.width * k / steps, size.height - size.height * (s[k] / maxV) * 0.95);
        k == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
      }
      return p;
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, -4, size.width * progress, size.height + 8));
    if (b.length > 1) {
      final paintB = Paint()
        ..color = colorB
        ..strokeWidth = 2.2
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
          ..strokeWidth = 2.6
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
