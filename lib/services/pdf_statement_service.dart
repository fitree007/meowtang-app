import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/transaction_item.dart';
import '../models/account_item.dart';
import '../utils/format_utils.dart';
import 'native_bridge_service.dart';

class PdfStatementService {
  static Future<Uint8List> generateMonthlyStatementPdf({
    required List<TransactionItem> transactions,
    required List<AccountItem> accounts,
    required DateTime selectedMonth,
    required bool isEnglish,
    String? userName,
    String? reportTitle,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();

    pw.Font thaiFontRegular;
    pw.Font thaiFontBold;

    try {
      final fontDataRegular = await rootBundle.load('assets/fonts/ThaiFont-Regular.ttf');
      final fontDataBold = await rootBundle.load('assets/fonts/ThaiFont-Bold.ttf');
      thaiFontRegular = pw.Font.ttf(fontDataRegular);
      thaiFontBold = pw.Font.ttf(fontDataBold);
    } catch (_) {
      thaiFontRegular = pw.Font.helvetica();
      thaiFontBold = pw.Font.helveticaBold();
    }

    final thaiTheme = pw.ThemeData.withFont(
      base: thaiFontRegular,
      bold: thaiFontBold,
    );

    final thaiMonths = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    final enMonths = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    String periodStr;
    if (startDate != null && endDate != null) {
      final sYear = isEnglish ? startDate.year : startDate.year + 543;
      final eYear = isEnglish ? endDate.year : endDate.year + 543;
      final sMonth = isEnglish ? enMonths[startDate.month - 1] : thaiMonths[startDate.month - 1];
      final eMonth = isEnglish ? enMonths[endDate.month - 1] : thaiMonths[endDate.month - 1];
      periodStr = '${startDate.day} $sMonth $sYear - ${endDate.day} $eMonth $eYear';
    } else {
      final yearNum = isEnglish ? selectedMonth.year : selectedMonth.year + 543;
      final monthName = isEnglish ? enMonths[selectedMonth.month - 1] : thaiMonths[selectedMonth.month - 1];
      periodStr = isEnglish ? '$monthName $yearNum' : 'ประจำเดือน $monthName พ.ศ. $yearNum';
    }

    final sortedTxs = List<TransactionItem>.from(transactions);
    sortedTxs.sort((a, b) => b.date.compareTo(a.date));

    double totalIncome = 0.0;
    double totalExpense = 0.0;
    final categoryTotals = <String, double>{};

    for (final tx in sortedTxs) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        totalExpense += tx.amount;
        final catName = tx.categoryDisplayName.isNotEmpty ? tx.categoryDisplayName : 'ทั่วไป';
        categoryTotals[catName] = (categoryTotals[catName] ?? 0.0) + tx.amount;
      }
    }

    final netSavings = totalIncome - totalExpense;
    final double savingsRate = totalIncome > 0 ? ((netSavings > 0 ? netSavings : 0.0) / totalIncome) * 100 : 0.0;

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final brandPrimary = PdfColor.fromHex('#10B981');
    final darkHeader = PdfColor.fromHex('#0F172A');
    final grayBg = PdfColor.fromHex('#F8FAFC');
    final incomeColor = PdfColor.fromHex('#10B981');
    final expenseColor = PdfColor.fromHex('#EF4444');
    final blueColor = PdfColor.fromHex('#3B82F6');

    pdf.addPage(
      pw.MultiPage(
        theme: thaiTheme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Column(
              children: [
                pw.Divider(color: PdfColors.grey300, height: 1),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'เหมียวตังค์ (MeowTang) - บันทึกรายรับรายจ่าย วางแผนงบประมาณ & สแกนสลิปอัจฉริยะ',
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                    ),
                    pw.Text(
                      'หน้า ${context.pageNumber} / ${context.pagesCount}',
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // 1. Header Section
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 10),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1.5)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'เหมียวตังค์ (MeowTang)',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: darkHeader,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        reportTitle ?? (isEnglish ? 'Financial Statement Report' : 'รายงานสรุปบัญชีรายรับ-รายจ่ายทางการเงิน'),
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey700,
                        ),
                      ),
                      if (userName != null && userName.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'เจ้าของบัญชี: $userName',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                        ),
                      ],
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: brandPrimary,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Text(
                          periodStr,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'พิมพ์เมื่อ: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year + 543} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} น.',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // 2. Financial Metrics Summary Boxes (4 Columns)
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: grayBg,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('รายรับรวม (+)', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '฿${FormatUtils.formatCurrency(totalIncome)}',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: incomeColor),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: grayBg,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('รายจ่ายรวม (-)', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '฿${FormatUtils.formatCurrency(totalExpense)}',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: expenseColor),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: grayBg,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('คงเหลือสุทธิ', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '฿${FormatUtils.formatCurrency(netSavings)}',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: netSavings >= 0 ? incomeColor : expenseColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: grayBg,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('อัตราการออม', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '${savingsRate.toStringAsFixed(1)}%',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: blueColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // 3. Category Breakdown
            if (sortedCategories.isNotEmpty) ...[
              pw.Text(
                'สรุปสัดส่วนค่าใช้จ่ายรายหมวดหมู่',
                style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkHeader),
              ),
              pw.SizedBox(height: 4),
              pw.Wrap(
                spacing: 6,
                runSpacing: 4,
                children: sortedCategories.take(8).map((cat) {
                  final pct = totalExpense > 0 ? ((cat.value / totalExpense) * 100).toStringAsFixed(1) : '0';
                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: grayBg,
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Text(
                      '${cat.key}: ฿${FormatUtils.formatCurrency(cat.value)} ($pct%)',
                      style: const pw.TextStyle(fontSize: 7.5),
                    ),
                  );
                }).toList(),
              ),
              pw.SizedBox(height: 12),
            ],

            // 4. Transaction Ledger Table
            pw.Text(
              'รายการธุรกรรมทั้งหมด (${sortedTxs.length} รายการ)',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: darkHeader),
            ),
            pw.SizedBox(height: 6),

            if (sortedTxs.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: grayBg,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'ไม่มีรายการธุรกรรมในช่วงเวลานี้',
                  style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey600),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: [
                  'ลำดับ',
                  'วัน/เวลา',
                  'รายการ',
                  'หมวดหมู่',
                  'บัญชี/ช่องทาง',
                  'จำนวนเงิน (บาท)',
                ],
                data: List<List<String>>.generate(sortedTxs.length, (i) {
                  final tx = sortedTxs[i];
                  final dateStr = '${tx.date.day.toString().padLeft(2, '0')}/${tx.date.month.toString().padLeft(2, '0')}/${tx.date.year + 543}';
                  final timeStr = '${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')}';
                  final prefix = tx.type == TransactionType.income ? '+' : (tx.type == TransactionType.expense ? '-' : '');
                  
                  String accName = 'เงินสด';
                  for (final a in accounts) {
                    if (a.id == tx.accountId) {
                      accName = a.name;
                      break;
                    }
                  }

                  return [
                    '${i + 1}',
                    '$dateStr $timeStr',
                    tx.title.isNotEmpty ? tx.title : 'รายการ',
                    tx.categoryDisplayName.isNotEmpty ? tx.categoryDisplayName : 'ทั่วไป',
                    accName,
                    '$prefix฿${FormatUtils.formatCurrency(tx.amount)}',
                  ];
                }),
                headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkHeader),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellHeight: 18,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.centerLeft,
                  5: pw.Alignment.centerRight,
                },
              ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<String?> exportPdfToDownloads({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final path = await NativeBridgeService.saveExportFile(
      fileName: fileName,
      bytes: bytes,
      subDir: 'MeowTang',
    );

    if (path != null && path.isNotEmpty) {
      return path;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }
}
