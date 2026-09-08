import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/transaction_item.dart';
import '../state/expense_controller.dart';
import '../services/pdf_statement_service.dart';
import '../services/excel_export_service.dart';
import '../widgets/export_success_modal.dart';
import '../widgets/meow_paywall_modal.dart';
import '../utils/format_utils.dart';

class ExportReportScreen extends StatefulWidget {
  final ExpenseController controller;

  const ExportReportScreen({super.key, required this.controller});

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  // Format tab: 0 = Excel (.csv), 1 = CSV, 2 = PDF (A4)
  int _selectedFormatIndex = 0;

  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  String? _selectedAccountId;
  bool _sortAscending = false; // เรียงจากล่าสุดไปเก่าสุดเป็นค่าเริ่มต้น

  bool _isExporting = false;

  List<TransactionItem> get _filteredTransactions {
    final list = widget.controller.allTransactions.where((t) {
      final isAfterStart = t.date.isAfter(_startDate.subtract(const Duration(days: 1)));
      final isBeforeEnd = t.date.isBefore(_endDate.add(const Duration(days: 1)));
      if (!isAfterStart || !isBeforeEnd) return false;
      if (_selectedAccountId != null && t.accountId != _selectedAccountId) return false;
      return true;
    }).toList();

    list.sort((a, b) => _sortAscending ? a.date.compareTo(b.date) : b.date.compareTo(a.date));
    return list;
  }

  double get _totalIncome => _filteredTransactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalExpense => _filteredTransactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  String _formatThaiDate(DateTime d) {
    const months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year + 543}';
  }

  Future<void> _pickDateRange() async {
    HapticFeedback.selectionClick();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        final currentTheme = widget.controller.currentTheme;
        return Theme(
          data: currentTheme.toThemeData(),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _performExport() async {
    HapticFeedback.mediumImpact();

    if (!widget.controller.isPremium) {
      MeowPaywallModal.show(
        context,
        controller: widget.controller,
        reason: 'ฟีเจอร์ส่งออกรายงาน Statement PDF และ Excel สำหรับสมาชิก VIP เท่านั้น 👑',
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final items = _filteredTransactions;
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่มีรายการข้อมูลในช่วงเวลาที่เลือก')),
        );
        setState(() => _isExporting = false);
        return;
      }

      final nowStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String? savedPath;
      String fileName;
      String formatTypeName;

      if (_selectedFormatIndex == 2) {
        // PDF Export
        formatTypeName = 'PDF';
        fileName = 'meowtang_statement_$nowStr.pdf';
        final pdfBytes = await PdfStatementService.generateMonthlyStatementPdf(
          transactions: items,
          accounts: widget.controller.accounts,
          selectedMonth: _startDate,
          startDate: _startDate,
          endDate: _endDate,
          reportTitle: 'รายงานสรุปการเงินเหมียวตังค์ (${_formatThaiDate(_startDate)} - ${_formatThaiDate(_endDate)})',
          isEnglish: widget.controller.isEnglish,
        );

        savedPath = await PdfStatementService.exportPdfToDownloads(
          bytes: pdfBytes,
          fileName: fileName,
        );
      } else {
        // Excel / CSV Export
        formatTypeName = _selectedFormatIndex == 0 ? 'Excel' : 'CSV';
        fileName = 'meowtang_export_$nowStr.csv';
        final csvContent = ExcelExportService.generateExcelCsv(
          transactions: items,
          accounts: widget.controller.accounts,
          reportTitle: 'รายงานสรุปการเงินเหมียวตังค์ (${_formatThaiDate(_startDate)} - ${_formatThaiDate(_endDate)})',
          startDate: _startDate,
          endDate: _endDate,
        );

        savedPath = await ExcelExportService.exportCsvToDownloads(
          csvContent: csvContent,
          fileName: fileName,
        );
      }

      if (!mounted) return;
      setState(() => _isExporting = false);

      if (savedPath != null) {
        ExportSuccessModal.show(
          context: context,
          title: 'รายงานการเงินช่วง ${_formatThaiDate(_startDate)} ถึง ${_formatThaiDate(_endDate)}',
          fileName: fileName,
          filePath: savedPath,
          formatType: formatTypeName,
          totalCount: items.length,
          totalIncome: _totalIncome,
          totalExpense: _totalExpense,
          currentTheme: widget.controller.currentTheme,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถบันทึกไฟล์ได้ กรุณาลองใหม่อีกครั้ง')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการส่งออก: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = widget.controller.currentTheme;
    final items = _filteredTransactions;

    return Scaffold(
      backgroundColor: currentTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: currentTheme.textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ส่งออกรายงานการเงิน',
          style: TextStyle(color: currentTheme.textColor, fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // 1. Format Selector (Excel / CSV / PDF)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: currentTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: currentTheme.borderColor),
            ),
            child: Row(
              children: [
                _buildFormatTabItem(0, 'Excel (.csv)', Icons.table_chart_rounded, currentTheme),
                _buildFormatTabItem(1, 'CSV ทั่วไป', Icons.description_rounded, currentTheme),
                _buildFormatTabItem(2, 'PDF (A4)', Icons.picture_as_pdf_rounded, currentTheme),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Date Range Picker Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: currentTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: currentTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ช่วงเวลาของรายงาน',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentTheme.textSecondaryColor),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDateRange,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: currentTheme.surfaceBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: currentTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.date_range_rounded, size: 18, color: currentTheme.primaryColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${_formatThaiDate(_startDate)}  ถึง  ${_formatThaiDate(_endDate)}',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: currentTheme.textColor,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down_rounded, color: currentTheme.textSecondaryColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Quick Date Preset Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPresetChip('เดือนนี้', () {
                        final now = DateTime.now();
                        setState(() {
                          _startDate = DateTime(now.year, now.month, 1);
                          _endDate = now;
                        });
                      }, currentTheme),
                      _buildPresetChip('เดือนที่แล้ว', () {
                        final now = DateTime.now();
                        final prevMonth = DateTime(now.year, now.month - 1, 1);
                        final lastDay = DateTime(now.year, now.month, 0);
                        setState(() {
                          _startDate = prevMonth;
                          _endDate = lastDay;
                        });
                      }, currentTheme),
                      _buildPresetChip('3 เดือนล่าสุด', () {
                        final now = DateTime.now();
                        setState(() {
                          _startDate = DateTime(now.year, now.month - 2, 1);
                          _endDate = now;
                        });
                      }, currentTheme),
                      _buildPresetChip('ปีนี้ (${DateTime.now().year + 543})', () {
                        final now = DateTime.now();
                        setState(() {
                          _startDate = DateTime(now.year, 1, 1);
                          _endDate = now;
                        });
                      }, currentTheme),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Summary Overview Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: currentTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: currentTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ข้อมูลที่จะถูกส่งออก',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentTheme.textSecondaryColor),
                    ),
                    Text(
                      '${items.length} รายการ',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentTheme.primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('รายรับรวม', style: TextStyle(fontSize: 11, color: currentTheme.textSecondaryColor)),
                          const SizedBox(height: 2),
                          Text(
                            '+฿${FormatUtils.formatCurrency(_totalIncome)}',
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('รายจ่ายรวม', style: TextStyle(fontSize: 11, color: currentTheme.textSecondaryColor)),
                          const SizedBox(height: 2),
                          Text(
                            '-฿${FormatUtils.formatCurrency(_totalExpense)}',
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Export Action Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _performExport,
              style: ElevatedButton.styleFrom(
                backgroundColor: currentTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: _isExporting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(_selectedFormatIndex == 2 ? Icons.picture_as_pdf_rounded : Icons.download_rounded, size: 20),
              label: Text(
                _isExporting
                    ? 'กำลังสร้างและส่งออกไฟล์...'
                    : 'ส่งออกไฟล์ ${_selectedFormatIndex == 0 ? "Excel (.csv)" : _selectedFormatIndex == 1 ? "CSV" : "PDF (A4)"}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFormatTabItem(int index, String title, IconData icon, dynamic currentTheme) {
    final isSelected = _selectedFormatIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedFormatIndex = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? currentTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : currentTheme.textSecondaryColor),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : currentTheme.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap, dynamic currentTheme) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: currentTheme.surfaceBackground,
        side: BorderSide(color: currentTheme.borderColor),
        label: Text(label, style: TextStyle(fontSize: 11, color: currentTheme.textColor)),
        onPressed: () {
          HapticFeedback.selectionClick();
          onTap();
        },
      ),
    );
  }
}
