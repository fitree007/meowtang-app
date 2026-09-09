import '../services/excel_export_service.dart';
import '../widgets/export_success_modal.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction_item.dart';
import '../models/category_item.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../widgets/analytics_carousel_chart_card.dart';
import '../widgets/tactile_button.dart';
import '../widgets/meow_wheel_date_picker.dart';
import '../utils/format_utils.dart';
import '../services/pdf_statement_service.dart';
import 'saving_goals_screen.dart';
import 'category_management_screen.dart';
import 'budget_management_screen.dart';
import 'compare_analytics_screen.dart';
import '../widgets/transaction_detail_sheet.dart';
import '../widgets/slip_image_viewer_dialog.dart';
import '../services/slip_auto_sync_service.dart';

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

enum CustomRangeUnit {
 days,
 months,
 years,
}

class MeowAnalyticsScreen extends StatefulWidget {
 final ExpenseController controller;

 const MeowAnalyticsScreen({super.key, required this.controller});

 @override
 State<MeowAnalyticsScreen> createState() => _MeowAnalyticsScreenState();
}

class _MeowAnalyticsScreenState extends State<MeowAnalyticsScreen> with SingleTickerProviderStateMixin {
 AnalyticsMainTab _activeTab = AnalyticsMainTab.overview;

 // Period filter states (Overview & Category Tags)
 PeriodFilterType _periodType = PeriodFilterType.month;
 CustomRangeUnit _rangeUnit = CustomRangeUnit.days;
 DateTime _currentAnchorDate = DateTime.now();
 DateTimeRange _customDateRange = DateTimeRange(
  start: DateTime.now().subtract(const Duration(days: 30)),
  end: DateTime.now(),
 );

 // Chart settings
 TransactionType _selectedType = TransactionType.expense;

 // Category & #Tag Drilldown state
 String? _selectedDrillCategoryId;

 // 2-Month Comparison state
 DateTime _compareMonthA = DateTime.now();
 DateTime _compareMonthB = DateTime(DateTime.now().year, DateTime.now().month == 1 ? 12 : DateTime.now().month - 1);

 // Thai Date Formatter Utilities
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
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
 ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
    if (widget.controller.expenseCategories.isNotEmpty) {
      _selectedDrillCategoryId = widget.controller.expenseCategories.first.id;
    }
    // Auto-trigger slip scan if app has no transactions yet and is not currently scanning
    if (widget.controller.allTransactions.isEmpty && !widget.controller.isProcessingSlips) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          SlipAutoSyncService.scanAndAutoImportNewSlips(widget.controller);
        }
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

 String _formatPeriodTitle() {
  final d = _currentAnchorDate;
  final isEn = widget.controller.isEnglish;
  final yearStr = isEn ? '${d.year}' : '${d.year + 543}';

  switch (_periodType) {
   case PeriodFilterType.day:
    final mStr = isEn ? _enMonths[d.month - 1] : _thaiMonths[d.month - 1];
    return '${d.day} $mStr $yearStr';
   case PeriodFilterType.month:
    final mStr = isEn ? _enMonths[d.month - 1] : _thaiMonths[d.month - 1];
    return '$mStr $yearStr';
   case PeriodFilterType.year:
    return isEn ? 'Year $yearStr' : 'ปี พ.ศ. $yearStr';
   case PeriodFilterType.customRange:
    final start = _customDateRange.start;
    final end = _customDateRange.end;
    final startY = isEn ? '${start.year}' : '${start.year + 543}';
    final endY = isEn ? '${end.year}' : '${end.year + 543}';
    return '${start.day}/${start.month}/$startY - ${end.day}/${end.month}/$endY';
   case PeriodFilterType.allTime:
    return isEn ? 'All Time Statistics' : 'สถิติตลอดเวลา (All Time)';
  }
 }

 String _formatMonthYear(DateTime d) {
  final isEn = widget.controller.isEnglish;
  final yearStr = isEn ? '${d.year}' : '${d.year + 543}';
  final mStr = isEn ? _enMonthsShort[d.month - 1] : _thaiMonthsShort[d.month - 1];
  return '$mStr $yearStr';
 }

 void _prevPeriod() {
  HapticFeedback.selectionClick();
  setState(() {
   if (_periodType == PeriodFilterType.day) {
    _currentAnchorDate = _currentAnchorDate.subtract(const Duration(days: 1));
   } else if (_periodType == PeriodFilterType.month) {
    _currentAnchorDate = DateTime(_currentAnchorDate.year, _currentAnchorDate.month - 1, 1);
   } else if (_periodType == PeriodFilterType.year) {
    _currentAnchorDate = DateTime(_currentAnchorDate.year - 1, 1, 1);
   }
  });
 }

 void _nextPeriod() {
  HapticFeedback.selectionClick();
  setState(() {
   if (_periodType == PeriodFilterType.day) {
    _currentAnchorDate = _currentAnchorDate.add(const Duration(days: 1));
   } else if (_periodType == PeriodFilterType.month) {
    _currentAnchorDate = DateTime(_currentAnchorDate.year, _currentAnchorDate.month + 1, 1);
   } else if (_periodType == PeriodFilterType.year) {
    _currentAnchorDate = DateTime(_currentAnchorDate.year + 1, 1, 1);
   }
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
    helpText: widget.controller.isEnglish ? 'Select Date Range' : 'เลือกช่วงวันที่ต้องการดูสถิติ',
    saveText: widget.controller.isEnglish ? 'Done' : 'เลือกช่วงนี้',
    builder: (context, child) => Theme(
     data: ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
       primary: MeowTheme.mustardYellow,
       onPrimary: MeowTheme.textDarkPrimary,
       surface: MeowTheme.navySurface,
      ),
     ),
     child: child!,
    ),
   );
   if (picked != null) {
    setState(() => _customDateRange = picked);
   }
  } else if (_periodType == PeriodFilterType.day) {
   final picked = await MeowWheelDatePicker.showWheelDatePicker(
    context: context,
    initialDate: _currentAnchorDate,
    isEnglish: widget.controller.isEnglish,
    isDarkMode: widget.controller.isDarkMode,
   );
   if (picked != null) {
    setState(() => _currentAnchorDate = picked);
   }
  } else if (_periodType == PeriodFilterType.month) {
   final picked = await MeowWheelDatePicker.showWheelMonthYearPicker(
    context: context,
    initialDate: _currentAnchorDate,
    isEnglish: widget.controller.isEnglish,
    isDarkMode: widget.controller.isDarkMode,
   );
   if (picked != null) {
    setState(() => _currentAnchorDate = picked);
   }
  } else if (_periodType == PeriodFilterType.year) {
   final picked = await MeowWheelDatePicker.showWheelYearPicker(
    context: context,
    initialYear: _currentAnchorDate.year,
    isEnglish: widget.controller.isEnglish,
    isDarkMode: widget.controller.isDarkMode,
   );
   if (picked != null) {
    setState(() => _currentAnchorDate = DateTime(picked, _currentAnchorDate.month, 1));
   }
  }
 }

 // Filtered Transactions for Current Period
 List<TransactionItem> get _filteredTransactions {
  final all = widget.controller.allTransactions;

  if (_periodType == PeriodFilterType.allTime) {
   return all;
  } else if (_periodType == PeriodFilterType.day) {
   return all.where((t) =>
     t.date.year == _currentAnchorDate.year &&
     t.date.month == _currentAnchorDate.month &&
     t.date.day == _currentAnchorDate.day).toList();
  } else if (_periodType == PeriodFilterType.month) {
   return all.where((t) =>
     t.date.year == _currentAnchorDate.year &&
     t.date.month == _currentAnchorDate.month).toList();
  } else if (_periodType == PeriodFilterType.year) {
   return all.where((t) => t.date.year == _currentAnchorDate.year).toList();
  } else {
   final start = _customDateRange.start;
   final end = _customDateRange.end.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
   return all.where((t) => t.date.isAfter(start.subtract(const Duration(seconds: 1))) && t.date.isBefore(end)).toList();
  }
 }

 double get _totalIncome => _filteredTransactions
   .where((t) => t.type == TransactionType.income)
   .fold(0.0, (sum, t) => sum + t.amount);

 double get _totalExpense => _filteredTransactions
   .where((t) => t.type == TransactionType.expense)
   .fold(0.0, (sum, t) => sum + t.amount);

 double get _netSavings => _totalIncome - _totalExpense;

 void _showExportOptionsModal() {
  final isDark = widget.controller.isDarkMode;
  final isEn = widget.controller.isEnglish;

  showModalBottomSheet(
   context: context,
   backgroundColor: isDark ? MeowTheme.navySurface : Colors.white,
   shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
   ),
   builder: (ctx) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
    child: Column(
     mainAxisSize: MainAxisSize.min,
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
      Center(
       child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
         color: Colors.grey.withOpacity(0.3),
         borderRadius: BorderRadius.circular(2),
        ),
       ),
      ),
      const SizedBox(height: 14),
      Row(
       children: [
        const Icon(Icons.file_download, color: MeowTheme.mustardYellow, size: 22),
        const SizedBox(width: 8),
        Text(
         isEn ? 'Export Financial Report' : 'ส่งออกรายงานสรุปบัญชี',
         style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontSize: 17,
          fontWeight: FontWeight.bold,
         ),
        ),
       ],
      ),
      const SizedBox(height: 16),
      ListTile(
       leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
         color: MeowTheme.expenseRed.withOpacity(0.12),
         borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.picture_as_pdf, color: MeowTheme.expenseRed, size: 24),
       ),
       title: Text(isEn ? 'Monthly PDF Financial Statement' : 'รายงานสรุปบัญชีรายเดือน PDF (A4)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
       subtitle: Text(isEn ? 'Professional PDF with breakdowns & tables' : 'เอกสารหัวบิลเหมียวตังค์ พร้อมตารางแจกแจงระดับมืออาชีพ', style: const TextStyle(fontSize: 12)),
       onTap: () {
        Navigator.pop(ctx);
        _exportPdfStatement();
       },
      ),
      const Divider(height: 14),
      ListTile(
       leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
         color: MeowTheme.incomeGreen.withOpacity(0.12),
         borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.table_chart, color: MeowTheme.incomeGreen, size: 24),
       ),
       title: Text(isEn ? 'Excel Spreadsheet (.csv UTF-8 BOM)' : 'ส่งออกไฟล์ Excel (.csv ภาษาไทย 100%)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
       subtitle: Text(isEn ? 'Open in Microsoft Excel or Google Sheets' : 'เปิดดูในโปรแกรม Excel ได้ทันที ภาษาไทยไม่เพี้ยน', style: const TextStyle(fontSize: 12)),
       onTap: () {
        Navigator.pop(ctx);
        _exportExcelCsv();
       },
      ),
     ],
    ),
   ),
  );
 }

 Future<void> _exportPdfStatement() async {
  try {
   final isEn = widget.controller.isEnglish;
   final pdfBytes = await PdfStatementService.generateMonthlyStatementPdf(
    transactions: widget.controller.allTransactions,
    accounts: widget.controller.accounts,
    selectedMonth: _currentAnchorDate,
    isEnglish: isEn,
   );

   final dir = await getApplicationDocumentsDirectory();
   final monthStr = '${_currentAnchorDate.year}_${_currentAnchorDate.month}';
   final file = File('${dir.path}/meowtang_statement_$monthStr.pdf');
   await file.writeAsBytes(pdfBytes);

   if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(
      content: Text(' ส่งออกรายงาน PDF สำเร็จแล้ว (${file.path.split(RegExp(r'[/\\]')).last})'),
      backgroundColor: MeowTheme.incomeGreen,
     ),
    );
   }
  } catch (e) {
   if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(content: Text('เกิดข้อผิดพลาดในการสร้าง PDF: $e'), backgroundColor: MeowTheme.expenseRed),
    );
   }
  }
 }

 Future<void> _exportExcelCsv() async {
  try {
   final csvContent = widget.controller.exportToExcelCsv();
   final dir = await getApplicationDocumentsDirectory();
   final monthStr = '${_currentAnchorDate.year}_${_currentAnchorDate.month}';
   final file = File('${dir.path}/rizqi_report_$monthStr.csv');
   await file.writeAsString(csvContent);

   if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(
      content: Text(' บันทึกไฟล์ Excel สำเร็จแล้ว (${file.path.split(RegExp(r'[/\\]')).last})'),
      backgroundColor: MeowTheme.incomeGreen,
     ),
    );
   }
  } catch (e) {
   if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(content: Text('เกิดข้อผิดพลาดในการส่งออก Excel: $e'), backgroundColor: MeowTheme.expenseRed),
    );
   }
  }
 }

 @override
 Widget build(BuildContext context) {
  final currentTheme = widget.controller.currentTheme;
  final isDark = widget.controller.isDarkMode;
  final isEn = widget.controller.isEnglish;

  return Scaffold(
   backgroundColor: currentTheme.scaffoldBackground,
   appBar: PreferredSize(
    preferredSize: const Size.fromHeight(105),
    child: Container(
     decoration: BoxDecoration(
      gradient: currentTheme.heroGradient,
     ),
     padding: EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + 6,
      left: 16,
      right: 16,
      bottom: 10,
     ),
     child: Column(
      children: [
       // Top Bar Header
       Row(
        children: [
         const Icon(Icons.analytics_rounded, color: Colors.white, size: 24),
         const SizedBox(width: 8),
         Text(
          isEn ? 'Financial Analytics' : 'สรุปวิเคราะห์การเงิน',
          style: const TextStyle(
           color: Colors.white,
           fontSize: 18,
           fontWeight: FontWeight.bold,
          ),
         ),
        ],
       ),
       const SizedBox(height: 6),
       // 3 Main Segmented Tabs
       Container(
        height: 38,
        decoration: BoxDecoration(
         color: Colors.black.withValues(alpha: 0.15),
         borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
         children: [
          _buildMainTabButton(AnalyticsMainTab.overview, isEn ? 'Overview' : 'ภาพรวม'),
          _buildMainTabButton(AnalyticsMainTab.categoryTags, isEn ? 'Categories & #Tags' : 'หมวดหมู่ & #แท็ก'),
          _buildMainTabButton(AnalyticsMainTab.comparison, isEn ? '2-Month Compare' : 'เทียบ 2 เดือน'),
         ],
        ),
       ),
      ],
     ),
    ),
   ),
   body: _buildActiveTabContent(),
  );
 }

 Widget _buildMainTabButton(AnalyticsMainTab tab, String label) {
  final isSelected = _activeTab == tab;
  return Expanded(
   child: GestureDetector(
    onTap: () {
     HapticFeedback.selectionClick();
     setState(() => _activeTab = tab);
    },
    child: Container(
     decoration: BoxDecoration(
      color: isSelected ? (widget.controller.isDarkMode ? MeowTheme.navyBackground : Colors.white) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      boxShadow: isSelected ? [
       BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))
      ] : [],
     ),
     alignment: Alignment.center,
     child: Text(
      label,
      style: TextStyle(
       color: isSelected ? (widget.controller.isDarkMode ? Colors.white : const Color(0xFF0F172A)) : Colors.white.withValues(alpha: 0.8),
       fontSize: 12,
       fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
      ),
     ),
    ),
   ),
  );
 }

 Widget _buildActiveTabContent() {
  switch (_activeTab) {
   case AnalyticsMainTab.overview:
    return _buildOverviewTab();
   case AnalyticsMainTab.categoryTags:
    return _buildCategoryTagsTab();
   case AnalyticsMainTab.comparison:
    return _buildComparisonTab();
  }
 }

 // ==========================================
 // TAB 1: OVERVIEW
 // ==========================================
 Widget _buildOverviewTab() {
  final isDark = widget.controller.isDarkMode;
  final isEn = widget.controller.isEnglish;
  final cardBg = isDark ? MeowTheme.navySurface : Colors.white;
  final borderColor = isDark ? MeowTheme.borderColor : const Color(0xFFE2E8F0);

  return ListView(
   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
   children: [
    // Period Filter Type Chips (วัน / เดือน / ปี / ช่วงเวลา / ทั้งหมด)
    SingleChildScrollView(
     scrollDirection: Axis.horizontal,
     child: Row(
      children: [
       _buildPeriodTypeChip(PeriodFilterType.day, isEn ? 'Day' : 'รายวัน'),
       const SizedBox(width: 8),
       _buildPeriodTypeChip(PeriodFilterType.month, isEn ? 'Month' : 'รายเดือน'),
       const SizedBox(width: 8),
       _buildPeriodTypeChip(PeriodFilterType.year, isEn ? 'Year' : 'รายปี'),
       const SizedBox(width: 8),
       _buildPeriodTypeChip(PeriodFilterType.customRange, isEn ? 'Custom Range' : 'ช่วงเวลา'),
       const SizedBox(width: 8),
       _buildPeriodTypeChip(PeriodFilterType.allTime, isEn ? 'All Time' : 'ตลอดเวลา'),
      ],
     ),
    ),
    const SizedBox(height: 12),

    // Period Navigator Bar (with Wheel Picker Trigger)
    if (_periodType != PeriodFilterType.allTime) ...[
     Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
       color: cardBg,
       borderRadius: BorderRadius.circular(16),
       border: Border.all(color: borderColor),
      ),
      child: Row(
       mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [
        IconButton(
         icon: const Icon(Icons.chevron_left, size: 24),
         onPressed: _prevPeriod,
         padding: EdgeInsets.zero,
         constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        Expanded(
         child: GestureDetector(
          onTap: _pickDateOrRange,
          child: Row(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
            const Icon(Icons.calendar_month, color: MeowTheme.actionBlue, size: 16),
            const SizedBox(width: 6),
            Flexible(
             child: Text(
              _formatPeriodTitle(),
              style: TextStyle(
               color: isDark ? Colors.white : const Color(0xFF0F172A),
               fontSize: 14,
               fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
             ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, color: MeowTheme.actionBlue, size: 18),
           ],
          ),
         ),
        ),
        IconButton(
         icon: const Icon(Icons.chevron_right, size: 24),
         onPressed: _nextPeriod,
         padding: EdgeInsets.zero,
         constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
       ],
      ),
     ),
     const SizedBox(height: 12),
    ],

    // 1. Type Segment (Expense vs Income Chart breakdown)
    Row(
     children: [
      Expanded(
       child: GestureDetector(
        onTap: () {
         HapticFeedback.selectionClick();
         setState(() => _selectedType = TransactionType.expense);
        },
        child: Container(
         padding: const EdgeInsets.symmetric(vertical: 9),
         decoration: BoxDecoration(
          color: _selectedType == TransactionType.expense ? MeowTheme.expenseRed : cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _selectedType == TransactionType.expense ? MeowTheme.expenseRed : borderColor),
         ),
         alignment: Alignment.center,
         child: Text(
          isEn ? 'Expense Breakdown' : 'สัดส่วนรายจ่าย',
          style: TextStyle(
           color: _selectedType == TransactionType.expense ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
           fontWeight: FontWeight.bold,
           fontSize: 13,
          ),
         ),
        ),
       ),
      ),
      const SizedBox(width: 10),
      Expanded(
       child: GestureDetector(
        onTap: () {
         HapticFeedback.selectionClick();
         setState(() => _selectedType = TransactionType.income);
        },
        child: Container(
         padding: const EdgeInsets.symmetric(vertical: 9),
         decoration: BoxDecoration(
          color: _selectedType == TransactionType.income ? MeowTheme.incomeGreen : cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _selectedType == TransactionType.income ? MeowTheme.incomeGreen : borderColor),
         ),
         alignment: Alignment.center,
         child: Text(
          isEn ? 'Income Breakdown' : 'สัดส่วนรายรับ',
          style: TextStyle(
           color: _selectedType == TransactionType.income ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
           fontWeight: FontWeight.bold,
           fontSize: 13,
          ),
         ),
        ),
       ),
      ),
     ],
    ),
    const SizedBox(height: 12),

    // 2. Visual Chart Card (กราฟวิเคราะห์ 3 รูปแบบ อยู่ด้านบนสุดทันที)
    _buildChartCard(),
    const SizedBox(height: 14),

    // 3. 3-Metric Summary Hero Card
    Container(
     padding: const EdgeInsets.all(16),
     decoration: BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor),
      boxShadow: isDark ? [] : [
       BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))
      ],
     ),
     child: Column(
      children: [
       Row(
        children: [
         // Income Box
         Expanded(
          child: Container(
           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
           decoration: BoxDecoration(
            color: MeowTheme.incomeGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
           ),
           child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             Row(
              children: [
               const Icon(Icons.arrow_downward, color: MeowTheme.incomeGreen, size: 15),
               const SizedBox(width: 4),
               Expanded(
                child: Text(
                 isEn ? 'Income' : 'รายรับ',
                 style: const TextStyle(color: MeowTheme.incomeGreen, fontSize: 12, fontWeight: FontWeight.bold),
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
                ),
               ),
              ],
             ),
             const SizedBox(height: 4),
             FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
               '฿${FormatUtils.formatCurrency(_totalIncome)}',
               style: const TextStyle(color: MeowTheme.incomeGreen, fontSize: 17, fontWeight: FontWeight.bold),
              ),
             ),
            ],
           ),
          ),
         ),
         const SizedBox(width: 10),
         // Expense Box
         Expanded(
          child: Container(
           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
           decoration: BoxDecoration(
            color: MeowTheme.expenseRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
           ),
           child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             Row(
              children: [
               const Icon(Icons.arrow_upward, color: MeowTheme.expenseRed, size: 15),
               const SizedBox(width: 4),
               Expanded(
                child: Text(
                 isEn ? 'Expense' : 'รายจ่าย',
                 style: const TextStyle(color: MeowTheme.expenseRed, fontSize: 12, fontWeight: FontWeight.bold),
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
                ),
               ),
              ],
             ),
             const SizedBox(height: 4),
             FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
               '฿${FormatUtils.formatCurrency(_totalExpense)}',
               style: const TextStyle(color: MeowTheme.expenseRed, fontSize: 17, fontWeight: FontWeight.bold),
              ),
             ),
            ],
           ),
          ),
         ),
        ],
       ),
       const SizedBox(height: 10),
       // Net Savings Bar
       Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
         color: _netSavings >= 0 ? MeowTheme.actionBlue.withOpacity(0.08) : Colors.red.withOpacity(0.08),
         borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
         children: [
          Expanded(
           child: Row(
            children: [
             Icon(
              _netSavings >= 0 ? Icons.account_balance_wallet_rounded : Icons.warning_amber_rounded,
              color: _netSavings >= 0 ? MeowTheme.actionBlue : Colors.red,
              size: 16,
             ),
             const SizedBox(width: 6),
             Expanded(
              child: Text(
               isEn ? 'Net Savings:' : 'เงินคงเหลือสุทธิ:',
               style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF334155),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
               ),
               maxLines: 1,
               overflow: TextOverflow.ellipsis,
              ),
             ),
            ],
           ),
          ),
          const SizedBox(width: 8),
          Flexible(
           child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
             '${_netSavings >= 0 ? "+" : ""}฿${FormatUtils.formatCurrency(_netSavings)}',
             style: TextStyle(
              color: _netSavings >= 0 ? MeowTheme.actionBlue : Colors.red,
              fontSize: 15,
              fontWeight: FontWeight.bold,
             ),
            ),
           ),
          ),
         ],
        ),
       ),
      ],
     ),
    ),
    // 4. Category Breakdown List
    _buildCategoryList(),
   ],
  );
 }

 Widget _buildPeriodTypeChip(PeriodFilterType type, String label) {
  final isSelected = _periodType == type;
  final isDark = widget.controller.isDarkMode;
  final currentTheme = widget.controller.currentTheme;

  return GestureDetector(
   onTap: () {
    HapticFeedback.selectionClick();
    setState(() => _periodType = type);
   },
   child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
     color: isSelected ? currentTheme.primaryColor : (isDark ? currentTheme.cardBackground : Colors.white),
     borderRadius: BorderRadius.circular(12),
     border: Border.all(
      color: isSelected ? currentTheme.primaryColor : currentTheme.borderColor,
     ),
    ),
    child: Text(
     label,
     style: TextStyle(
      color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
      fontSize: 12,
      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
     ),
    ),
   ),
  );
 }
 Widget _buildChartCard() {
  final items = _filteredTransactions.where((t) => t.type == _selectedType).toList();
  final total = _selectedType == TransactionType.expense ? _totalExpense : _totalIncome;

  return AnalyticsCarouselChartCard(
   transactions: items,
   selectedType: _selectedType,
   totalAmount: total,
   periodTypeStr: _periodType.name,
   anchorDate: _currentAnchorDate,
   isDark: widget.controller.isDarkMode,
   isEnglish: widget.controller.isEnglish,
   allCategories: widget.controller.categories,
   isProcessingSlips: widget.controller.isProcessingSlips,
   hasNoTransactionsAtAll: widget.controller.allTransactions.isEmpty,
   onTriggerScan: () {
     SlipAutoSyncService.scanAndAutoImportNewSlips(widget.controller);
   },
  );
 }

 Widget _buildCategoryList() {
  final isDark = widget.controller.isDarkMode;
  final isEn = widget.controller.isEnglish;
  final cardBg = isDark ? MeowTheme.navySurface : Colors.white;
  final borderColor = isDark ? MeowTheme.borderColor : const Color(0xFFE2E8F0);

  final items = _filteredTransactions.where((t) => t.type == _selectedType).toList();
  if (items.isEmpty) return const SizedBox.shrink();

  final catMap = <String, double>{};
  final catCountMap = <String, int>{};
  for (final tx in items) {
   catMap[tx.categoryId] = (catMap[tx.categoryId] ?? 0.0) + tx.amount;
   catCountMap[tx.categoryId] = (catCountMap[tx.categoryId] ?? 0) + 1;
  }

  final total = _selectedType == TransactionType.expense ? _totalExpense : _totalIncome;
  final sortedCats = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

  return Container(
   padding: const EdgeInsets.all(18),
   decoration: BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: borderColor),
   ),
   child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
     Text(
      isEn ? 'Category Breakdown' : 'แจกแจงตามหมวดหมู่',
      style: TextStyle(
       color: isDark ? Colors.white : const Color(0xFF0F172A),
       fontSize: 16,
       fontWeight: FontWeight.bold,
      ),
     ),
     const SizedBox(height: 14),
     ...sortedCats.map((e) {
      final cat = widget.controller.categories.firstWhere(
       (c) => c.id == e.key,
       orElse: () => CategoryItem(
        id: e.key,
        name: 'ทั่วไป',
        iconKey: 'category',
        colorValue: 0xFF3B82F6,
        type: _selectedType == TransactionType.income ? CategoryType.income : CategoryType.expense,
       ),
      );
      final pct = total > 0 ? (e.value / total) : 0.0;
      final count = catCountMap[e.key] ?? 1;

      return Padding(
       padding: const EdgeInsets.only(bottom: 14),
       child: Column(
        children: [
         Row(
          children: [
           Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
             color: Color(cat.colorValue).withOpacity(0.15),
             borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(cat.icon, color: Color(cat.colorValue), size: 18),
           ),
           const SizedBox(width: 12),
           Expanded(
            child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
              Text(
               cat.name,
               style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.bold,
               ),
              ),
              Text(
               '$count ${isEn ? "entries" : "รายการ"} (${(pct * 100).toStringAsFixed(1)}%)',
               style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 11),
              ),
             ],
            ),
           ),
           Text(
            '฿${FormatUtils.formatCurrency(e.value)}',
            style: TextStyle(
             color: isDark ? Colors.white : const Color(0xFF0F172A),
             fontSize: 15,
             fontWeight: FontWeight.bold,
            ),
           ),
          ],
         ),
         const SizedBox(height: 6),
         ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
           value: pct,
           backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
           valueColor: AlwaysStoppedAnimation<Color>(Color(cat.colorValue)),
           minHeight: 6,
          ),
         ),
        ],
       ),
      );
     }),
    ],
   ),
  );
 }

 // ==========================================
 // TAB 2: CATEGORY & #TAGS DRILLDOWN
 // ==========================================
 Widget _buildCategoryTagsTab() {
  final isDark = widget.controller.isDarkMode;
  final isEn = widget.controller.isEnglish;
  final cardBg = isDark ? MeowTheme.navySurface : Colors.white;
  final borderColor = isDark ? MeowTheme.borderColor : const Color(0xFFE2E8F0);

  final availableCats = _selectedType == TransactionType.income
    ? widget.controller.incomeCategories
    : widget.controller.expenseCategories;

  if (_selectedDrillCategoryId == null && availableCats.isNotEmpty) {
   _selectedDrillCategoryId = availableCats.first.id;
  }

  final selectedCat = widget.controller.categories.firstWhere(
   (c) => c.id == _selectedDrillCategoryId,
   orElse: () => availableCats.isNotEmpty ? availableCats.first : widget.controller.categories.first,
  );

  // Filter transactions by selected category in current period
  final categoryTxs = _filteredTransactions.where((t) => t.categoryId == selectedCat.id && t.type == _selectedType).toList();
  final catTotal = categoryTxs.fold(0.0, (sum, t) => sum + t.amount);

  // Extract tags under this category
  final Map<String, double> tagAmounts = {};
  final Map<String, int> tagCounts = {};
  double untaggedAmount = 0.0;
  int untaggedCount = 0;

  for (final tx in categoryTxs) {
   if (tx.tags.isNotEmpty) {
    for (final t in tx.tags) {
     final clean = t.trim();
     if (clean.isNotEmpty) {
      tagAmounts[clean] = (tagAmounts[clean] ?? 0.0) + tx.amount;
      tagCounts[clean] = (tagCounts[clean] ?? 0) + 1;
     }
    }
   } else {
    untaggedAmount += tx.amount;
    untaggedCount += 1;
   }
  }

  final sortedTags = tagAmounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

  // Calculate totals and counts for all categories in current period
  final Map<String, double> catPeriodTotals = {};
  final Map<String, int> catPeriodCounts = {};
  for (final cat in availableCats) {
   final txs = _filteredTransactions.where((t) => t.categoryId == cat.id && t.type == _selectedType);
   catPeriodTotals[cat.id] = txs.fold(0.0, (s, t) => s + t.amount);
   catPeriodCounts[cat.id] = txs.length;
  }

  return ListView(
   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
   children: [
    // Category Type Filter (รายจ่าย / รายรับ)
    Row(
     children: [
      Expanded(
       child: GestureDetector(
        onTap: () {
         HapticFeedback.selectionClick();
         setState(() {
          _selectedType = TransactionType.expense;
          if (widget.controller.expenseCategories.isNotEmpty) {
           _selectedDrillCategoryId = widget.controller.expenseCategories.first.id;
          }
         });
        },
        child: Container(
         padding: const EdgeInsets.symmetric(vertical: 8),
         decoration: BoxDecoration(
          color: _selectedType == TransactionType.expense ? MeowTheme.expenseRed : cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _selectedType == TransactionType.expense ? MeowTheme.expenseRed : borderColor),
         ),
         alignment: Alignment.center,
         child: Text(
          isEn ? 'Expense Categories' : 'หมวดหมู่รายจ่าย',
          style: TextStyle(
           color: _selectedType == TransactionType.expense ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
           fontWeight: FontWeight.bold,
           fontSize: 12,
          ),
         ),
        ),
       ),
      ),
      const SizedBox(width: 8),
      Expanded(
       child: GestureDetector(
        onTap: () {
         HapticFeedback.selectionClick();
         setState(() {
          _selectedType = TransactionType.income;
          if (widget.controller.incomeCategories.isNotEmpty) {
           _selectedDrillCategoryId = widget.controller.incomeCategories.first.id;
          }
         });
        },
        child: Container(
         padding: const EdgeInsets.symmetric(vertical: 8),
         decoration: BoxDecoration(
          color: _selectedType == TransactionType.income ? MeowTheme.incomeGreen : cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _selectedType == TransactionType.income ? MeowTheme.incomeGreen : borderColor),
         ),
         alignment: Alignment.center,
         child: Text(
          isEn ? 'Income Categories' : 'หมวดหมู่รายรับ',
          style: TextStyle(
           color: _selectedType == TransactionType.income ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
           fontWeight: FontWeight.bold,
           fontSize: 12,
          ),
         ),
        ),
       ),
      ),
     ],
    ),
    const SizedBox(height: 14),

    // Header with Category Count and Manage Categories Button
    Padding(
     padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
     child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
       Text(
        '${isEn ? "All Categories" : "เลือกดูหมวดหมู่"} (${availableCats.length} ${isEn ? "categories" : "หมวด"})',
        style: TextStyle(
         color: isDark ? Colors.white : const Color(0xFF0F172A),
         fontWeight: FontWeight.bold,
         fontSize: 14,
        ),
       ),
       TactileButton(
        onTap: () {
         HapticFeedback.selectionClick();
         Navigator.push(
          context,
          MaterialPageRoute(
           builder: (_) => CategoryManagementScreen(controller: widget.controller),
          ),
         );
        },
        child: Container(
         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
         decoration: BoxDecoration(
          color: MeowTheme.mustardYellow.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: MeowTheme.mustardYellow.withOpacity(0.35)),
         ),
         child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
           const Icon(Icons.tune_rounded, size: 14, color: MeowTheme.mustardYellow),
           const SizedBox(width: 4),
           Text(
            isEn ? 'Manage' : 'จัดการหมวดหมู่',
            style: const TextStyle(
             color: MeowTheme.mustardYellow,
             fontWeight: FontWeight.bold,
             fontSize: 12,
            ),
           ),
          ],
         ),
        ),
       ),
      ],
     ),
    ),
    const SizedBox(height: 8),

    // 2-Column Grid of Category Cards
    GridView.builder(
     shrinkWrap: true,
     physics: const NeverScrollableScrollPhysics(),
     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 2.1,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
     ),
     itemCount: availableCats.length,
     itemBuilder: (context, idx) {
      final cat = availableCats[idx];
      final isSelected = cat.id == selectedCat.id;
      final catTotalAmt = catPeriodTotals[cat.id] ?? 0.0;
      final catCount = catPeriodCounts[cat.id] ?? 0;

      return GestureDetector(
       onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedDrillCategoryId = cat.id);
       },
       child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
         color: isSelected
           ? Color(cat.colorValue).withOpacity(isDark ? 0.25 : 0.12)
           : cardBg,
         borderRadius: BorderRadius.circular(14),
         border: Border.all(
          color: isSelected
            ? Color(cat.colorValue)
            : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          width: isSelected ? 2 : 1,
         ),
         boxShadow: isSelected
           ? [
             BoxShadow(
              color: Color(cat.colorValue).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
             ),
            ]
           : null,
        ),
        child: Row(
         children: [
          Container(
           width: 36,
           height: 36,
           decoration: BoxDecoration(
            color: Color(cat.colorValue).withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
           ),
           child: Icon(cat.icon, color: Color(cat.colorValue), size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
           child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
             Text(
              cat.name,
              style: TextStyle(
               color: isDark ? Colors.white : const Color(0xFF0F172A),
               fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
               fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
             ),
             const SizedBox(height: 2),
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
               Text(
                '$catCount ${isEn ? "tx" : "รายการ"}',
                style: TextStyle(
                 color: isDark ? Colors.white54 : Colors.grey,
                 fontSize: 10,
                ),
               ),
               Flexible(
                child: Text(
                 '฿${FormatUtils.formatCurrency(catTotalAmt)}',
                 style: TextStyle(
                  color: Color(cat.colorValue),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                 ),
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
                ),
               ),
              ],
             ),
            ],
           ),
          ),
         ],
        ),
       ),
      );
     },
    ),
    const SizedBox(height: 14),

    // Category Hero Banner
    Container(
     padding: const EdgeInsets.all(16),
     decoration: BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor),
     ),
     child: Row(
      children: [
       Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
         color: Color(selectedCat.colorValue).withOpacity(0.15),
         shape: BoxShape.circle,
        ),
        child: Icon(selectedCat.icon, color: Color(selectedCat.colorValue), size: 26),
       ),
       const SizedBox(width: 12),
       Expanded(
        child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
          Text(
           '${isEn ? "Category" : "หมวดหมู่"}: ${selectedCat.name}',
           style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 15,
            fontWeight: FontWeight.bold,
           ),
           maxLines: 1,
           overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
           '${categoryTxs.length} ${isEn ? "transactions in" : "รายการใน"} ${_formatPeriodTitle()}',
           style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 11.5),
           maxLines: 1,
           overflow: TextOverflow.ellipsis,
          ),
         ],
        ),
       ),
       const SizedBox(width: 8),
       Flexible(
        child: FittedBox(
         fit: BoxFit.scaleDown,
         child: Text(
          '฿${FormatUtils.formatCurrency(catTotal)}',
          style: TextStyle(
           color: Color(selectedCat.colorValue),
           fontSize: 19,
           fontWeight: FontWeight.bold,
          ),
         ),
        ),
       ),
      ],
     ),
    ),
    const SizedBox(height: 14),

    // #Tags Breakdown Section
    Container(
     padding: const EdgeInsets.all(16),
     decoration: BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor),
     ),
     child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       Row(
        children: [
         const Icon(Icons.tag, color: MeowTheme.mustardYellow, size: 20),
         const SizedBox(width: 6),
         Expanded(
          child: Text(
           '# ${isEn ? "Sub-tags in" : "แท็กย่อยใน"} ${selectedCat.name}',
           style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 15,
            fontWeight: FontWeight.bold,
           ),
           maxLines: 1,
           overflow: TextOverflow.ellipsis,
          ),
         ),
        ],
       ),
       const SizedBox(height: 12),
       if (sortedTags.isEmpty && untaggedAmount == 0) ...[
        Padding(
         padding: const EdgeInsets.all(20),
         child: Center(
          child: Text(
           isEn ? 'No transactions found in this category' : 'ยังไม่มีรายการในหมวดหมู่นี้',
           style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
         ),
        ),
       ] else ...[
        ...sortedTags.map((e) {
         final pct = catTotal > 0 ? (e.value / catTotal) : 0.0;
         final count = tagCounts[e.key] ?? 1;
         final matchingTxs = categoryTxs.where((t) => t.tags.contains(e.key)).toList();

         return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
           _showTagDetailBottomSheet(
            context,
            e.key,
            matchingTxs,
            Color(selectedCat.colorValue),
           );
          },
          child: Padding(
           padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
           child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
               Expanded(
                child: Row(
                 children: [
                  Flexible(
                   child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                     color: Color(selectedCat.colorValue).withOpacity(0.15),
                     borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                     '#${e.key}',
                     style: TextStyle(color: Color(selectedCat.colorValue), fontWeight: FontWeight.bold, fontSize: 13),
                     maxLines: 1,
                     overflow: TextOverflow.ellipsis,
                    ),
                   ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                   '$count ${isEn ? "times" : "ครั้ง"}',
                   style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 14, color: isDark ? Colors.white38 : Colors.grey),
                 ],
                ),
               ),
               const SizedBox(width: 8),
               Flexible(
                child: FittedBox(
                 fit: BoxFit.scaleDown,
                 child: Text(
                  '฿${FormatUtils.formatCurrency(e.value)}',
                  style: TextStyle(
                   color: isDark ? Colors.white : const Color(0xFF0F172A),
                   fontSize: 14,
                   fontWeight: FontWeight.bold,
                  ),
                 ),
                ),
               ),
              ],
             ),
             const SizedBox(height: 6),
             ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
               value: pct,
               backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
               valueColor: AlwaysStoppedAnimation<Color>(Color(selectedCat.colorValue)),
               minHeight: 6,
              ),
             ),
            ],
           ),
          ),
         );
        }),
        if (untaggedAmount > 0) ...[
         InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
           final untaggedTxs = categoryTxs.where((t) => t.tags.isEmpty).toList();
           _showTagDetailBottomSheet(
            context,
            isEn ? 'Un-tagged' : 'ไม่ได้ระบุแท็ก',
            untaggedTxs,
            Color(selectedCat.colorValue),
           );
          },
          child: Padding(
           padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
           child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
             Expanded(
              child: Row(
               children: [
                Text(
                 isEn ? 'Other / Un-tagged items' : 'รายการที่ไม่ได้ระบุ #แท็ก',
                 style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 12),
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 14, color: isDark ? Colors.white38 : Colors.grey),
               ],
              ),
             ),
             const SizedBox(width: 8),
             Flexible(
              child: FittedBox(
               fit: BoxFit.scaleDown,
               child: Text(
                '฿${FormatUtils.formatCurrency(untaggedAmount)}',
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13),
               ),
              ),
             ),
            ],
           ),
          ),
         ),
        ],
       ],
      ],
     ),
    ),
   ],
  );
 }

 void _showTagDetailBottomSheet(
  BuildContext context,
  String tagName,
  List<TransactionItem> matchingTxs,
  Color themeColor,
 ) {
  final currentTheme = widget.controller.currentTheme;
  final isDark = widget.controller.isDarkMode;
  final isEn = widget.controller.isEnglish;
  final totalAmount = matchingTxs.fold<double>(0.0, (sum, t) => sum + t.amount);

  showModalBottomSheet(
   context: context,
   isScrollControlled: true,
   backgroundColor: Colors.transparent,
   builder: (ctx) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
     color: currentTheme.cardBackground,
     borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
     border: Border.all(color: currentTheme.borderColor),
    ),
    child: SafeArea(
     child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       Center(
        child: Container(
         width: 40,
         height: 4,
         decoration: BoxDecoration(
          color: isDark ? Colors.white24 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
         ),
        ),
       ),
       const SizedBox(height: 14),
       Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
         Expanded(
          child: Row(
           children: [
            Container(
             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
             decoration: BoxDecoration(
              color: themeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
             ),
             child: Text(
              tagName.startsWith('#') ? tagName : '#$tagName',
              style: TextStyle(
               color: themeColor,
               fontWeight: FontWeight.bold,
               fontSize: 16,
              ),
             ),
            ),
            const SizedBox(width: 8),
            Text(
             '(${matchingTxs.length} ${isEn ? "items" : "รายการ"})',
             style: TextStyle(color: currentTheme.textSecondaryColor, fontSize: 13),
            ),
           ],
          ),
         ),
         Text(
          '฿${FormatUtils.formatCurrency(totalAmount)}',
          style: TextStyle(
           fontSize: 17,
           fontWeight: FontWeight.bold,
           color: currentTheme.textColor,
          ),
         ),
        ],
       ),
       const SizedBox(height: 6),
       Text(
        isEn ? 'Tap any transaction to view full details and slip:' : 'แตะรายการเพื่อดูรายละเอียด หมวดหมู่ และรูปสลิป:',
        style: TextStyle(fontSize: 11.5, color: currentTheme.textSecondaryColor),
       ),
       const Divider(height: 20),
       ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
        child: matchingTxs.isEmpty
          ? Center(
            child: Text(
             isEn ? 'No transactions found' : 'ไม่พบรายการ',
             style: TextStyle(color: currentTheme.textSecondaryColor),
            ),
           )
          : ListView.separated(
            shrinkWrap: true,
            itemCount: matchingTxs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, idx) {
             final tx = matchingTxs[idx];
             final isExp = tx.type == TransactionType.expense;
             final isInc = tx.type == TransactionType.income;
             final color = isInc ? const Color(0xFF10B981) : (isExp ? const Color(0xFFEF4444) : const Color(0xFF3B82F6));
             final hasSlip = tx.slipImageUrl != null && tx.slipImageUrl!.isNotEmpty;

             return Material(
              color: Colors.transparent,
              child: InkWell(
               borderRadius: BorderRadius.circular(14),
               onTap: () {
                TransactionDetailSheet.show(context, widget.controller, tx);
               },
               child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                 color: currentTheme.surfaceBackground,
                 borderRadius: BorderRadius.circular(14),
                 border: Border.all(color: currentTheme.borderColor.withOpacity(0.5)),
                ),
                child: Row(
                 children: [
                  Container(
                   width: 36,
                   height: 36,
                   decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                   ),
                   child: Icon(
                    isInc ? Icons.arrow_downward_rounded : (isExp ? Icons.arrow_upward_rounded : Icons.swap_horiz_rounded),
                    color: color,
                    size: 18,
                   ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                   child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                     Row(
                      children: [
                       Flexible(
                        child: Text(
                         tx.title,
                         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: currentTheme.textColor),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                        ),
                       ),
                       if (hasSlip) ...[
                        const SizedBox(width: 4),
                        Container(
                         padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                         decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                         ),
                         child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                           Icon(Icons.receipt_rounded, size: 10, color: Color(0xFF10B981)),
                           SizedBox(width: 2),
                           Text('สลิป', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                          ],
                         ),
                        ),
                       ],
                      ],
                     ),
                     const SizedBox(height: 2),
                     Text(
                      '${tx.date.day}/${tx.date.month}/${tx.date.year + 543} • ${tx.categoryName}',
                      style: TextStyle(fontSize: 11, color: currentTheme.textSecondaryColor),
                     ),
                    ],
                   ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                   crossAxisAlignment: CrossAxisAlignment.end,
                   children: [
                    Text(
                     '${isInc ? "+" : (isExp ? "-" : "")}฿${FormatUtils.formatCurrency(tx.amount)}',
                     style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: color,
                     ),
                    ),
                   ],
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 16, color: currentTheme.textSecondaryColor),
                 ],
                ),
               ),
              ),
             );
            },
           ),
       ),
      ],
     ),
    ),
   ),
  );
 }

 // ==========================================
 // TAB 3: 2-MONTH COMPARISON
 // ==========================================
 Widget _buildComparisonTab() {
  final currentTheme = widget.controller.currentTheme;
  final isDark = widget.controller.isDarkMode;
  final isEn = widget.controller.isEnglish;
  final cardBg = currentTheme.cardBackground;
  final borderColor = currentTheme.borderColor;

  final comparisonData = widget.controller.compareTwoMonths(_compareMonthA, _compareMonthB);

  final double incomeA = comparisonData['incomeA'] as double;
  final double incomeB = comparisonData['incomeB'] as double;
  final double incomeDelta = comparisonData['incomeDelta'] as double;
  final double incomeDeltaPct = comparisonData['incomeDeltaPercent'] as double;

  final double expenseA = comparisonData['expenseA'] as double;
  final double expenseB = comparisonData['expenseB'] as double;
  final double expenseDelta = comparisonData['expenseDelta'] as double;
  final double expenseDeltaPct = comparisonData['expenseDeltaPercent'] as double;

  final double netA = comparisonData['netA'] as double;
  final double netB = comparisonData['netB'] as double;
  final double netDelta = comparisonData['netDelta'] as double;

  final int txCountA = comparisonData['txCountA'] as int? ?? 0;
  final int txCountB = comparisonData['txCountB'] as int? ?? 0;

  final double dailyAvgA = comparisonData['dailyAvgExpenseA'] as double? ?? 0.0;
  final double dailyAvgB = comparisonData['dailyAvgExpenseB'] as double? ?? 0.0;
  final double dailyAvgDelta = comparisonData['dailyAvgExpenseDelta'] as double? ?? 0.0;

  final Map<String, dynamic>? topSpike = comparisonData['topSpike'] as Map<String, dynamic>?;
  final Map<String, dynamic>? topSaved = comparisonData['topSaved'] as Map<String, dynamic>?;

  final List<Map<String, dynamic>> categoryDeltas = comparisonData['categoryDeltas'] as List<Map<String, dynamic>>;

  final String verdictTitle = comparisonData['verdictTitle'] as String? ?? 'สรุปการเปรียบเทียบ';
  final String verdictDesc = comparisonData['verdictDescription'] as String? ?? '';
  final bool verdictIsPositive = comparisonData['verdictIsPositive'] as bool? ?? true;

  return ListView(
   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
   children: [
    // Month Selector Cards (Month A vs Month B) with Swap Button
    Row(
     children: [
      // Month A Selector
      Expanded(
       child: GestureDetector(
        onTap: () async {
         HapticFeedback.selectionClick();
         final picked = await MeowWheelDatePicker.showWheelMonthYearPicker(
          context: context,
          initialDate: _compareMonthA,
          isEnglish: isEn,
          isDarkMode: isDark,
          title: isEn ? 'Select Month A (Current)' : 'เลือกเดือน A (เดือนหลัก)',
         );
         if (picked != null) {
          setState(() => _compareMonthA = picked);
         }
        },
        child: Container(
         padding: const EdgeInsets.all(12),
         decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: currentTheme.primaryColor, width: 2),
         ),
         child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Row(
            children: [
             Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
               color: currentTheme.primaryColor,
               borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
               'เดือน A',
               style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
               ),
              ),
             ),
             const Spacer(),
             Icon(Icons.edit_calendar_rounded, color: currentTheme.primaryColor, size: 16),
            ],
           ),
           const SizedBox(height: 6),
           Text(
            _formatMonthYear(_compareMonthA),
            style: TextStyle(
             color: currentTheme.textColor,
             fontSize: 15,
             fontWeight: FontWeight.bold,
            ),
           ),
          ],
         ),
        ),
       ),
      ),
      // Swap Button
      Padding(
       padding: const EdgeInsets.symmetric(horizontal: 6),
       child: GestureDetector(
        onTap: () {
         HapticFeedback.mediumImpact();
         setState(() {
          final temp = _compareMonthA;
          _compareMonthA = _compareMonthB;
          _compareMonthB = temp;
         });
        },
        child: Container(
         width: 32,
         height: 32,
         decoration: BoxDecoration(
          color: currentTheme.surfaceBackground,
          shape: BoxShape.circle,
          border: Border.all(color: currentTheme.borderColor),
         ),
         child: Icon(Icons.swap_horiz_rounded, size: 18, color: currentTheme.textColor),
        ),
       ),
      ),
      // Month B Selector
      Expanded(
       child: GestureDetector(
        onTap: () async {
         HapticFeedback.selectionClick();
         final picked = await MeowWheelDatePicker.showWheelMonthYearPicker(
          context: context,
          initialDate: _compareMonthB,
          isEnglish: isEn,
          isDarkMode: isDark,
          title: isEn ? 'Select Month B (Compare)' : 'เลือกเดือน B (เดือนเปรียบเทียบ)',
         );
         if (picked != null) {
          setState(() => _compareMonthB = picked);
         }
        },
        child: Container(
         padding: const EdgeInsets.all(12),
         decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
         ),
         child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Row(
            children: [
             Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
               color: const Color(0xFF38BDF8),
               borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('เดือน B', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
             ),
             const Spacer(),
             const Icon(Icons.edit_calendar_rounded, color: Color(0xFF38BDF8), size: 16),
            ],
           ),
           const SizedBox(height: 6),
           Text(
            _formatMonthYear(_compareMonthB),
            style: TextStyle(
             color: currentTheme.textColor,
             fontSize: 15,
             fontWeight: FontWeight.bold,
            ),
           ),
          ],
         ),
        ),
       ),
      ),
     ],
    ),
    const SizedBox(height: 14),

    // AI Verdict Banner
    Container(
     padding: const EdgeInsets.all(14),
     decoration: BoxDecoration(
      gradient: LinearGradient(
       colors: verdictIsPositive
         ? [const Color(0xFF10B981).withValues(alpha: 0.15), const Color(0xFF34D399).withValues(alpha: 0.08)]
         : [const Color(0xFFEF4444).withValues(alpha: 0.15), const Color(0xFFF87171).withValues(alpha: 0.08)],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
       color: verdictIsPositive ? const Color(0xFF10B981).withValues(alpha: 0.4) : const Color(0xFFEF4444).withValues(alpha: 0.4),
      ),
     ),
     child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       Text(
        verdictTitle,
        style: TextStyle(
         fontSize: 13.5,
         fontWeight: FontWeight.bold,
         color: verdictIsPositive ? const Color(0xFF059669) : const Color(0xFFDC2626),
        ),
       ),
       const SizedBox(height: 3),
       Text(
        verdictDesc,
        style: TextStyle(fontSize: 12, color: currentTheme.textColor, height: 1.3),
       ),
      ],
     ),
    ),
    const SizedBox(height: 12),

    // 1. Expense Comparison Card
    Container(
     padding: const EdgeInsets.all(16),
     decoration: BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: borderColor),
     ),
     child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
         Row(
          children: [
           const Icon(Icons.arrow_upward_rounded, color: Color(0xFFEF4444), size: 18),
           const SizedBox(width: 6),
           Text(
            isEn ? 'Expense Comparison' : 'เปรียบเทียบยอดรายจ่าย',
            style: TextStyle(color: currentTheme.textColor, fontWeight: FontWeight.bold, fontSize: 14),
           ),
          ],
         ),
         Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
           color: expenseDelta <= 0 ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFEF4444).withValues(alpha: 0.15),
           borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
           '${expenseDelta <= 0 ? "ประหยัดลง " : "เพิ่มขึ้น "}${expenseDelta.abs().toStringAsFixed(0)}฿ (${expenseDeltaPct.abs().toStringAsFixed(1)}%)',
           style: TextStyle(
            color: expenseDelta <= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            fontSize: 11,
            fontWeight: FontWeight.bold,
           ),
          ),
         ),
        ],
       ),
       const SizedBox(height: 12),
       Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
         Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Text('เดือน A (${_formatMonthYear(_compareMonthA)})', style: TextStyle(color: currentTheme.textSecondaryColor, fontSize: 11)),
           Text('฿${FormatUtils.formatCurrency(expenseA)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: currentTheme.textColor)),
          ],
         ),
         Icon(Icons.compare_arrows_rounded, color: currentTheme.textSecondaryColor, size: 22),
         Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
           Text('เดือน B (${_formatMonthYear(_compareMonthB)})', style: TextStyle(color: currentTheme.textSecondaryColor, fontSize: 11)),
           Text('฿${FormatUtils.formatCurrency(expenseB)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: currentTheme.textSecondaryColor)),
          ],
         ),
        ],
       ),
      ],
     ),
    ),
    const SizedBox(height: 10),

    // 2. Income Comparison Card
    Container(
     padding: const EdgeInsets.all(16),
     decoration: BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: borderColor),
     ),
     child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
         Row(
          children: [
           const Icon(Icons.arrow_downward_rounded, color: Color(0xFF10B981), size: 18),
           const SizedBox(width: 6),
           Text(
            isEn ? 'Income Comparison' : 'เปรียบเทียบยอดรายรับ',
            style: TextStyle(color: currentTheme.textColor, fontWeight: FontWeight.bold, fontSize: 14),
           ),
          ],
         ),
         Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
           color: incomeDelta >= 0 ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFF59E0B).withValues(alpha: 0.15),
           borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
           '${incomeDelta >= 0 ? "+ " : "- "}${incomeDelta.abs().toStringAsFixed(0)}฿ (${incomeDeltaPct.abs().toStringAsFixed(1)}%)',
           style: TextStyle(
            color: incomeDelta >= 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            fontSize: 11,
            fontWeight: FontWeight.bold,
           ),
          ),
         ),
        ],
       ),
       const SizedBox(height: 12),
       Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
         Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Text('เดือน A', style: TextStyle(color: currentTheme.textSecondaryColor, fontSize: 11)),
           Text('฿${FormatUtils.formatCurrency(incomeA)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: currentTheme.textColor)),
          ],
         ),
         Icon(Icons.compare_arrows_rounded, color: currentTheme.textSecondaryColor, size: 22),
         Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
           Text('เดือน B', style: TextStyle(color: currentTheme.textSecondaryColor, fontSize: 11)),
           Text('฿${FormatUtils.formatCurrency(incomeB)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: currentTheme.textSecondaryColor)),
          ],
         ),
        ],
       ),
      ],
     ),
    ),
    const SizedBox(height: 10),

    // 3-Tile Row: Net Savings, Daily Avg Rate, Transactions count
    Row(
     children: [
      Expanded(
       child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
         color: cardBg,
         borderRadius: BorderRadius.circular(14),
         border: Border.all(color: borderColor),
        ),
        child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
          Text('เงินออมสุทธิ', style: TextStyle(fontSize: 10.5, color: currentTheme.textSecondaryColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text('฿${netA.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: netA >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
          Text('B: ฿${netB.toStringAsFixed(0)}', style: TextStyle(fontSize: 9.5, color: currentTheme.textSecondaryColor)),
         ],
        ),
       ),
      ),
      const SizedBox(width: 8),
      Expanded(
       child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
         color: cardBg,
         borderRadius: BorderRadius.circular(14),
         border: Border.all(color: borderColor),
        ),
        child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
          Text('เฉลี่ยจ่าย/วัน', style: TextStyle(fontSize: 10.5, color: currentTheme.textSecondaryColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text('฿${dailyAvgA.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
          Text('${dailyAvgDelta <= 0 ? "ลด " : "เพิ่ม "}${dailyAvgDelta.abs().toStringAsFixed(0)}฿/วัน', style: TextStyle(fontSize: 9.5, color: dailyAvgDelta <= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontWeight: FontWeight.bold)),
         ],
        ),
       ),
      ),
      const SizedBox(width: 8),
      Expanded(
       child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
         color: cardBg,
         borderRadius: BorderRadius.circular(14),
         border: Border.all(color: borderColor),
        ),
        child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
          Text('จำนวนรายการ', style: TextStyle(fontSize: 10.5, color: currentTheme.textSecondaryColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text('$txCountA รายการ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
          Text('B: $txCountB รายการ', style: TextStyle(fontSize: 9.5, color: currentTheme.textSecondaryColor)),
         ],
        ),
       ),
      ),
     ],
    ),
    const SizedBox(height: 14),

    // Highlights (Top Saved & Top Spiked)
    if (topSaved != null || topSpike != null) ...[
     Row(
      children: [
       if (topSaved != null)
        Expanded(
         child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
           color: cardBg,
           borderRadius: BorderRadius.circular(14),
           border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
          ),
          child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
            const Row(
             children: [
              Icon(Icons.thumb_up_alt_rounded, color: Color(0xFF10B981), size: 14),
              SizedBox(width: 4),
              Text('ประหยัดมากสุด', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
             ],
            ),
            const SizedBox(height: 4),
            Text(topSaved['name'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentTheme.textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('-฿${(topSaved['delta'] as double).abs().toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
           ],
          ),
         ),
        ),
       if (topSaved != null && topSpike != null) const SizedBox(width: 8),
       if (topSpike != null)
        Expanded(
         child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
           color: cardBg,
           borderRadius: BorderRadius.circular(14),
           border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
          ),
          child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
            const Row(
             children: [
              Icon(Icons.trending_up_rounded, color: Color(0xFFEF4444), size: 14),
              SizedBox(width: 4),
              Text('รายจ่ายพุ่งขึ้น', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
             ],
            ),
            const SizedBox(height: 4),
            Text(topSpike['name'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentTheme.textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('+฿${(topSpike['delta'] as double).abs().toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
           ],
          ),
         ),
        ),
      ],
     ),
     const SizedBox(height: 14),
    ],

    // Category-by-Category Deltas
    Container(
     padding: const EdgeInsets.all(16),
     decoration: BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor),
     ),
     child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
         Text(
          isEn ? 'Category-by-Category' : 'เจาะลึกรายหมวดหมู่',
          style: TextStyle(
           color: currentTheme.textColor,
           fontSize: 15,
           fontWeight: FontWeight.bold,
          ),
         ),
         TextButton.icon(
          style: TextButton.styleFrom(
           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
           minimumSize: Size.zero,
          ),
          icon: Icon(Icons.fullscreen_rounded, size: 16, color: currentTheme.primaryDark),
          label: Text(
           'เปิดรายงานละเอียด',
           style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: currentTheme.primaryDark),
          ),
          onPressed: () {
           Navigator.push(
            context,
            MaterialPageRoute(
             builder: (_) => CompareAnalyticsScreen(controller: widget.controller),
            ),
           );
          },
         ),
        ],
       ),
       const SizedBox(height: 10),
       if (categoryDeltas.isEmpty) ...[
        Padding(
         padding: const EdgeInsets.all(20),
         child: Center(
          child: Text(
           isEn ? 'No category data to compare' : 'ไม่มีข้อมูลหมวดหมู่ให้เปรียบเทียบ',
           style: TextStyle(color: currentTheme.textSecondaryColor, fontSize: 13),
          ),
         ),
        ),
       ] else ...[
        ...categoryDeltas.map((catData) {
         final name = catData['name'] as String;
         final double amtA = catData['amountA'] as double;
         final double amtB = catData['amountB'] as double;
         final double delta = catData['delta'] as double;
         final double deltaPct = catData['deltaPercent'] as double;

         final bool isSaved = delta <= 0;
         final double maxAmt = amtA > amtB ? (amtA > 0 ? amtA : 1.0) : (amtB > 0 ? amtB : 1.0);
         final double barA = (amtA / maxAmt).clamp(0.05, 1.0);
         final double barB = (amtB / maxAmt).clamp(0.05, 1.0);

         return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
           padding: const EdgeInsets.all(12),
           decoration: BoxDecoration(
            color: currentTheme.surfaceBackground,
            borderRadius: BorderRadius.circular(14),
           ),
           child: Column(
            children: [
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
               Expanded(
                child: Text(
                 name,
                 style: TextStyle(
                  color: currentTheme.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                 ),
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
                ),
               ),
               const SizedBox(width: 8),
               Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                 color: isSaved ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFEF4444).withValues(alpha: 0.15),
                 borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                 '${isSaved ? "ลดลง -" : "เพิ่มขึ้น +"}${delta.abs().toStringAsFixed(0)}฿ (${deltaPct.abs().toStringAsFixed(0)}%)',
                 style: TextStyle(
                  color: isSaved ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                 ),
                ),
               ),
              ],
             ),
             const SizedBox(height: 8),
             // Mini Dual Progress Bars
             Row(
              children: [
               SizedBox(width: 45, child: Text('A: ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: currentTheme.primaryDark))),
               Expanded(
                child: Stack(
                 children: [
                  Container(height: 6, decoration: BoxDecoration(color: currentTheme.cardBackground, borderRadius: BorderRadius.circular(3))),
                  FractionallySizedBox(
                   widthFactor: barA,
                   child: Container(height: 6, decoration: BoxDecoration(color: currentTheme.primaryColor, borderRadius: BorderRadius.circular(3))),
                  ),
                 ],
                ),
               ),
               const SizedBox(width: 8),
               SizedBox(
                width: 65,
                child: Text('฿${FormatUtils.formatCurrency(amtA)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: currentTheme.textColor), textAlign: TextAlign.right),
               ),
              ],
             ),
             const SizedBox(height: 4),
             Row(
              children: [
               const SizedBox(width: 45, child: Text('B: ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)))),
               Expanded(
                child: Stack(
                 children: [
                  Container(height: 6, decoration: BoxDecoration(color: currentTheme.cardBackground, borderRadius: BorderRadius.circular(3))),
                  FractionallySizedBox(
                   widthFactor: barB,
                   child: Container(height: 6, decoration: BoxDecoration(color: const Color(0xFF38BDF8), borderRadius: BorderRadius.circular(3))),
                  ),
                 ],
                ),
               ),
               const SizedBox(width: 8),
               SizedBox(
                width: 65,
                child: Text('฿${FormatUtils.formatCurrency(amtB)}', style: TextStyle(fontSize: 11, color: currentTheme.textSecondaryColor), textAlign: TextAlign.right),
               ),
              ],
             ),
            ],
           ),
          ),
         );
        }),
       ],
      ],
     ),
    ),
    const SizedBox(height: 20),
   ],
  );
 }
}
