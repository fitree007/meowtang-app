import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/transaction_item.dart';
import '../state/expense_controller.dart';
import '../services/pdf_statement_service.dart';
import '../services/excel_export_service.dart';
import '../widgets/export_success_modal.dart';
import '../widgets/meow_fx.dart';
import '../widgets/meow_paywall_modal.dart';
import '../utils/format_utils.dart';

class ExportReportScreen extends StatefulWidget {
  final ExpenseController controller;

  const ExportReportScreen({super.key, required this.controller});

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  // Format: 0 = Excel (.csv, opens in Excel/Sheets), 2 = PDF (A4)
  int _selectedFormatIndex = 0;

  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  int _preset = 0; // 0 this month, 1 last month, 2 last 3 months, 3 this year, -1 custom

  String? _selectedAccountId;
  final bool _sortAscending = false; // เรียงจากล่าสุดไปเก่าสุดเป็นค่าเริ่มต้น

  bool _isExporting = false;

  static final _nf = NumberFormat('#,##0', 'en_US');

  List<TransactionItem> get _filteredTransactions {
    // Whole calendar days: from 00:00 of the start day up to (not including) 00:00 after the end day.
    final from = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final until = DateTime(_endDate.year, _endDate.month, _endDate.day + 1);
    final list = widget.controller.allTransactions.where((t) {
      if (t.date.isBefore(from) || !t.date.isBefore(until)) return false;
      if (_selectedAccountId != null && t.accountId != _selectedAccountId) return false;
      return true;
    }).toList();

    list.sort((a, b) => _sortAscending ? a.date.compareTo(b.date) : b.date.compareTo(a.date));
    return list;
  }

  double _sum(List<TransactionItem> items, TransactionType type) =>
      items.where((t) => t.type == type).fold(0.0, (sum, t) => sum + t.amount);

  double get _totalIncome => _sum(_filteredTransactions, TransactionType.income);
  double get _totalExpense => _sum(_filteredTransactions, TransactionType.expense);

  static const _months = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];

  String _formatThaiDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year + 543}';

  /// Short label for the chosen range, e.g. "ก.ย. 2569" or "ก.ค.–ก.ย. 2569".
  String get _shortRange {
    final s = _startDate, e = _endDate;
    if (s.year == e.year && s.month == e.month) return '${_months[s.month - 1]} ${s.year + 543}';
    if (s.year == e.year) return '${_months[s.month - 1]}–${_months[e.month - 1]} ${e.year + 543}';
    return '${_months[s.month - 1]} ${s.year + 543}–${_months[e.month - 1]} ${e.year + 543}';
  }

  String _baht(double v) => '฿${FormatUtils.formatCurrency(v, trimZero: true)}';

  void _applyPreset(int i) {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    setState(() {
      _preset = i;
      switch (i) {
        case 0:
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
        case 1:
          _startDate = DateTime(now.year, now.month - 1, 1);
          _endDate = DateTime(now.year, now.month, 0);
        case 2:
          _startDate = DateTime(now.year, now.month - 2, 1);
          _endDate = now;
        case 3:
          _startDate = DateTime(now.year, 1, 1);
          _endDate = now;
      }
    });
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
        _preset = -1;
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
        formatTypeName = 'Excel';
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

  // --------------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = _C.of(widget.controller);
        final ctl = widget.controller;
        final items = _filteredTransactions;
        final income = _sum(items, TransactionType.income);
        final expense = _sum(items, TransactionType.expense);
        final has = items.isNotEmpty;
        final csv = _selectedFormatIndex != 2;
        final vip = ctl.isPremium;
        String accName = 'ทุกบัญชี';
        if (_selectedAccountId != null) {
          for (final a in ctl.accounts) {
            if (a.id == _selectedAccountId) accName = a.name;
          }
        }
        var i = 0;

        return Scaffold(
          backgroundColor: c.page,
          appBar: _calmAppBar(context, c, 'ส่งออกรายงานการเงิน', subtitle: 'Excel / PDF • บันทึกลงเครื่องหรือแชร์ต่อ'),
          bottomNavigationBar: _calmBottomBar(
            c,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  has ? '${_nf.format(items.length)} รายการ • $_shortRange • ${csv ? 'Excel' : 'PDF'}' : 'ไม่มีรายการให้ส่งออกในช่วงที่เลือก',
                  style: TextStyle(fontSize: 12.5, color: c.sub),
                ),
                const SizedBox(height: 8),
                _primaryButton(
                  c,
                  _isExporting
                      ? 'กำลังสร้างและส่งออกไฟล์...'
                      : !has
                          ? 'ไม่มีรายการให้ส่งออก'
                          : vip
                              ? 'ส่งออกไฟล์ ${csv ? "Excel (.csv)" : "PDF (A4)"}'
                              : 'อัปเกรด VIP เพื่อส่งออก',
                  has ? _performExport : null,
                  icon: has && vip ? (csv ? Icons.file_download_outlined : Icons.picture_as_pdf_outlined) : null,
                  busy: _isExporting,
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (!vip) ...[
                FxFadeUp(index: i++, child: _vipBanner(c)),
                const SizedBox(height: 18),
              ],
              // 1. Format
              FxFadeUp(
                index: i++,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionLabel(c, '1. รูปแบบไฟล์'),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _formatCard(c, 0, Icons.table_chart_outlined, 'Excel (.csv)', 'เปิดใน Excel / Google Sheets ได้'),
                          const SizedBox(width: 10),
                          _formatCard(c, 2, Icons.description_outlined, 'PDF (A4)', 'สรุปพร้อมพิมพ์ มีกราฟและตาราง'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // 2. Range
              FxFadeUp(
                index: i++,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionLabel(c, '2. ช่วงเวลาของรายงาน'),
                    _calmCard(
                      c,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: c.seg, borderRadius: BorderRadius.circular(12)),
                            child: Column(children: [
                              Row(children: [_presetSeg(c, 0, 'เดือนนี้'), _presetSeg(c, 1, 'เดือนที่แล้ว')]),
                              Row(children: [_presetSeg(c, 2, '3 เดือนล่าสุด'), _presetSeg(c, 3, 'ปีนี้ (${DateTime.now().year + 543})')]),
                            ]),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: _pickDateRange,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 20, color: c.icon),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('ตั้งแต่ – ถึง', style: TextStyle(fontSize: 12.5, color: c.sub)),
                                        Text('${_formatThaiDate(_startDate)} ถึง ${_formatThaiDate(_endDate)}',
                                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: c.text)),
                                      ],
                                    ),
                                  ),
                                  Text('เลือกวันเอง', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: c.link)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // 3. Account
              FxFadeUp(
                index: i++,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionLabel(c, '3. บัญชี (ไม่บังคับ)'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _accChip(c, null, 'ทุกบัญชี'),
                        for (final a in ctl.accounts) _accChip(c, a.id, a.name),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Summary
              FxFadeUp(
                index: i++,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionLabel(c, 'ข้อมูลที่จะถูกส่งออก'),
                    _calmCard(
                      c,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text.rich(TextSpan(children: [
                                TextSpan(
                                  text: _nf.format(items.length),
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: has ? c.text : c.faint),
                                ),
                                TextSpan(text: ' รายการ', style: TextStyle(fontSize: 13.5, color: c.sub)),
                              ])),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Text('$_shortRange • $accName',
                                      textAlign: TextAlign.right,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12.5, color: c.sub)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (has) ...[
                            _sumRow(c, 'รายรับรวม', _baht(income), c.ok),
                            _sumRow(c, 'รายจ่ายรวม', _baht(expense), c.danger),
                            _sumRow(c, 'คงเหลือสุทธิ', '${income - expense >= 0 ? '+' : '−'}${_baht((income - expense).abs())}',
                                income - expense >= 0 ? c.ok : c.danger,
                                muted: true),
                          ] else
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
                              child: Row(children: [
                                Icon(Icons.inbox_outlined, size: 22, color: c.sub),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('ไม่มีรายการในช่วงนี้', style: c.title.copyWith(fontSize: 14.5)),
                                    Text('ลองเลือกช่วงเวลาหรือบัญชีอื่น', style: c.subtitle),
                                  ]),
                                ),
                              ]),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // File preview
              FxFadeUp(
                index: i++,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionLabel(c, 'ตัวอย่างไฟล์ (ดูได้ฟรี)'),
                    _calmCard(c, padding: const EdgeInsets.all(14), child: _preview(c, items, income, expense, csv)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _vipBanner(_C c) => _calmCard(
        c,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 1),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), border: Border.all(color: c.line)),
              child: Text('VIP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: c.icon)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ส่งออกได้เมื่อเป็นสมาชิก VIP — ดูตัวอย่างฟรี', style: c.title.copyWith(fontSize: 14.5)),
                  const SizedBox(height: 2),
                  Text('เลือกรูปแบบ ช่วงเวลา และดูตัวอย่างไฟล์ได้เลย ก่อนตัดสินใจอัปเกรด', style: c.subtitle),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _formatCard(_C c, int index, IconData icon, String title, String sub) {
    final sel = _selectedFormatIndex == index;
    return Expanded(
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedFormatIndex = index);
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sel ? c.accent : c.line, width: sel ? 2 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 24, color: c.icon),
                    const Spacer(),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.card,
                        border: Border.all(color: sel ? c.accent : c.faint, width: sel ? 6 : 2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(title, style: c.title),
                const SizedBox(height: 2),
                Text(sub, style: c.subtitle),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _presetSeg(_C c, int i, String label) {
    final sel = _preset == i;
    return Expanded(
      child: Material(
        color: sel ? c.card : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: () => _applyPreset(i),
          child: SizedBox(
            height: 44,
            child: Center(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? c.link : c.sub)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _accChip(_C c, String? id, String name) {
    final sel = _selectedAccountId == id;
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedAccountId = id);
        },
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: sel ? c.accent : c.line, width: sel ? 1.5 : 1),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(name,
                style: TextStyle(fontSize: 14, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? c.link : c.icon)),
          ),
        ),
      ),
    );
  }

  Widget _sumRow(_C c, String label, String value, Color color, {bool muted = false}) => Container(
        height: 41,
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
        child: Row(children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: muted ? c.sub : c.text))),
          Text(value, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: color, fontFeatures: const [FontFeature.tabularFigures()])),
        ]),
      );

  Widget _preview(_C c, List<TransactionItem> items, double income, double expense, bool csv) {
    final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
    final name = csv ? 'meowtang_export_$stamp.csv' : 'meowtang_statement_$stamp.pdf';
    final meta = csv ? 'ไฟล์ตาราง • ${_nf.format(items.length)} แถว' : 'เอกสาร A4 • ประมาณ ${(items.length / 40).ceil() + 1} หน้า';
    final rows = items.where((t) => t.type != TransactionType.transfer).take(3).toList();
    final head = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.sub);
    final cell = TextStyle(fontSize: 12.5, color: c.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Icon(csv ? Icons.table_chart_outlined : Icons.description_outlined, size: 22, color: c.icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: c.title.copyWith(fontSize: 14.5)),
              Text(meta, style: c.subtitle),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        if (csv) ...[
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: c.line)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  color: c.seg,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(children: [
                    SizedBox(width: 44, child: Text('วันที่', style: head)),
                    Expanded(flex: 5, child: Text('รายการ', style: head)),
                    Expanded(flex: 3, child: Text('หมวด', style: head)),
                    Expanded(flex: 3, child: Text('จำนวน', textAlign: TextAlign.right, style: head)),
                  ]),
                ),
                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('ยังไม่มีรายการในช่วงที่เลือก', style: TextStyle(fontSize: 12.5, color: c.sub)),
                  ),
                for (final t in rows)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
                    child: Row(children: [
                      SizedBox(width: 44, child: Text('${t.date.day}/${t.date.month}', style: cell)),
                      Expanded(flex: 5, child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: cell)),
                      Expanded(flex: 3, child: Text(t.categoryName, maxLines: 1, overflow: TextOverflow.ellipsis, style: cell)),
                      Expanded(
                        flex: 3,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${t.type == TransactionType.income ? '+' : '−'}${_baht(t.amount)}',
                            style: cell.copyWith(fontWeight: FontWeight.w600, color: t.type == TransactionType.income ? c.ok : c.danger),
                          ),
                        ),
                      ),
                    ]),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('คอลัมน์ในไฟล์: ลำดับ • วันที่ • เวลา • ชื่อรายการ • ประเภท • หมวดหมู่ • บัญชี • จำนวนเงิน • บันทึกช่วยจำ',
              style: TextStyle(fontSize: 12.5, height: 1.45, color: c.sub)),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: c.line)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('รายงานการเงิน • $_shortRange', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.text)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('รายรับ', style: TextStyle(fontSize: 12.5, color: c.sub)),
                      Text(_baht(income), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.ok)),
                    ]),
                  ),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('รายจ่าย', style: TextStyle(fontSize: 12.5, color: c.sub)),
                      Text(_baht(expense), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.danger)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 10),
                FxBar(value: income + expense > 0 ? income / (income + expense) : 0, color: c.ok, track: c.danger.withValues(alpha: 0.35), height: 6),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('ในไฟล์มี: สรุปรายรับ-รายจ่าย • กราฟสัดส่วนตามหมวดหมู่ • ยอดแยกตามบัญชี • ตารางรายการทั้งหมด (ขนาด A4 พร้อมพิมพ์)',
              style: TextStyle(fontSize: 12.5, height: 1.45, color: c.sub)),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Calm monochrome menu-page kit (same look as the menu home). Private copy so
// this screen stays self-contained.
// ---------------------------------------------------------------------------

class _C {
 final Color page, text, sub, icon, faint, card, line, border, seg, accent, link, ok, okText, danger, dangerText, vip, vipLine, disabled;
 final bool dark;

 const _C({
  required this.page,
  required this.text,
  required this.sub,
  required this.icon,
  required this.faint,
  required this.card,
  required this.line,
  required this.border,
  required this.seg,
  required this.accent,
  required this.link,
  required this.ok,
  required this.okText,
  required this.danger,
  required this.dangerText,
  required this.vip,
  required this.vipLine,
  required this.disabled,
  required this.dark,
 });

 factory _C.of(ExpenseController ctl) {
  final t = ctl.currentTheme;
  final dark = ctl.isDarkMode;
  return _C(
   page: t.scaffoldBackground,
   text: t.textColor,
   sub: t.textSecondaryColor,
   icon: dark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
   faint: dark ? Colors.white24 : const Color(0xFFB6BECB),
   card: t.cardBackground,
   line: t.borderColor,
   border: dark ? Colors.white10 : const Color(0xFFEEF0F4),
   seg: dark ? const Color(0xFF0F172A) : const Color(0xFFF1F3F8),
   accent: t.primaryColor,
   link: dark ? const Color(0xFF93C5FD) : t.primaryColor,
   ok: dark ? const Color(0xFF34D399) : const Color(0xFF059669),
   okText: dark ? const Color(0xFF34D399) : const Color(0xFF047857),
   danger: dark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
   dangerText: dark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
   vip: dark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
   vipLine: dark ? const Color(0xFF6B5A1E) : const Color(0xFFE9C98B),
   disabled: dark ? Colors.white12 : const Color(0xFFA5B4CF),
   dark: dark,
  );
 }

 TextStyle get title => TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: text);
 TextStyle get subtitle => TextStyle(fontSize: 12.5, height: 1.35, color: sub);
}

/// White app bar: 44px back chevron, 18/700 title, optional 12px subtitle, optional [bottom] (e.g. a segmented control), 1px bottom line.
PreferredSizeWidget _calmAppBar(BuildContext context, _C c, String title,
  {String? subtitle, List<Widget> actions = const [], Widget? bottom, double bottomHeight = 0}) {
 return PreferredSize(
  preferredSize: Size.fromHeight(61 + bottomHeight),
  child: Material(
   color: c.card,
   child: SafeArea(
    bottom: false,
    child: Container(
     decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
     child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
       SizedBox(
        height: 60,
        child: Padding(
         padding: const EdgeInsets.only(left: 6, right: 8),
         child: Row(
          children: [
           SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
             tooltip: 'ย้อนกลับ',
             padding: EdgeInsets.zero,
             icon: Icon(Icons.chevron_left_rounded, size: 28, color: c.text),
             onPressed: () => Navigator.maybePop(context),
            ),
           ),
           const SizedBox(width: 6),
           Expanded(
            child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text)),
              if (subtitle != null)
               Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.sub)),
             ],
            ),
           ),
           ...actions,
          ],
         ),
        ),
       ),
       if (bottom != null) SizedBox(height: bottomHeight, child: bottom),
      ],
     ),
    ),
   ),
  ),
 );
}

/// Sticky bottom action bar (white, top border).
Widget _calmBottomBar(_C c, Widget child) => Container(
      decoration: BoxDecoration(color: c.card, border: Border(top: BorderSide(color: c.line))),
      child: SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), child: child)),
     );

/// Full-width 52px accent button; null [onTap] shows the disabled look.
Widget _primaryButton(_C c, String label, VoidCallback? onTap, {IconData? icon, Color? color, bool busy = false}) {
 final bg = onTap == null ? c.disabled : (color ?? c.accent);
 return SizedBox(
  width: double.infinity,
  height: 52,
  child: ElevatedButton(
   onPressed: busy ? null : onTap,
   style: ElevatedButton.styleFrom(
    backgroundColor: bg,
    disabledBackgroundColor: busy ? bg : c.disabled,
    foregroundColor: Colors.white,
    disabledForegroundColor: Colors.white.withValues(alpha: 0.9),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
   ),
   child: busy
       ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
       : Row(
           mainAxisSize: MainAxisSize.min,
           children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
           ],
          ),
  ),
 );
}

/// 1px-bordered card, radius 16.
Widget _calmCard(_C c, {required Widget child, EdgeInsetsGeometry? padding}) => Container(
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.line)),
      clipBehavior: Clip.antiAlias,
      child: Material(color: Colors.transparent, child: padding == null ? child : Padding(padding: padding, child: child)),
     );

/// 13px/600 grey label above a card group, with an optional right-hand value.
Widget _sectionLabel(_C c, String title, {String? trailing, Widget? trailingWidget}) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
       children: [
        Expanded(child: Text(title, style: TextStyle(color: c.sub, fontSize: 13, fontWeight: FontWeight.w600))),
        if (trailing != null) Text(trailing, style: TextStyle(color: c.sub, fontSize: 13, fontFeatures: const [FontFeature.tabularFigures()])),
        ?trailingWidget,
       ],
      ),
     );
