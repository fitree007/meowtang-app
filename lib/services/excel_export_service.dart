import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/transaction_item.dart';
import '../models/account_item.dart';
import 'native_bridge_service.dart';

class ExcelExportService {
  /// Generates UTF-8 CSV content with BOM for Microsoft Excel compatibility in Thai
  static String generateExcelCsv({
    required List<TransactionItem> transactions,
    required List<AccountItem> accounts,
    String reportTitle = 'รายงานสรุปการเงิน - เหมียวตังค์ (MeowTang)',
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final buffer = StringBuffer();

    // UTF-8 BOM so Excel opens Thai characters without garbling
    buffer.write('\uFEFF');

    // Title and Export Date Header
    final now = DateTime.now();
    buffer.writeln('"$reportTitle"');
    if (startDate != null && endDate != null) {
      buffer.writeln('"ช่วงเวลาข้อมูล","${startDate.day}/${startDate.month}/${startDate.year + 543} ถึง ${endDate.day}/${endDate.month}/${endDate.year + 543}"');
    }
    buffer.writeln('"วันที่พิมพ์รายงาน","${now.day}/${now.month}/${now.year + 543} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} น."');
    buffer.writeln('');

    // Summary Section
    double totalIncome = 0.0;
    double totalExpense = 0.0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        totalExpense += tx.amount;
      }
    }

    final netSavings = totalIncome - totalExpense;
    final savingsRate = totalIncome > 0 ? ((netSavings > 0 ? netSavings : 0.0) / totalIncome) * 100 : 0.0;

    buffer.writeln('"สรุปภาพรวมทางการเงิน"');
    buffer.writeln('"รายรับรวม (บาท)","${totalIncome.toStringAsFixed(2)}"');
    buffer.writeln('"รายจ่ายรวม (บาท)","${totalExpense.toStringAsFixed(2)}"');
    buffer.writeln('"คงเหลือสุทธิ (บาท)","${netSavings.toStringAsFixed(2)}"');
    buffer.writeln('"อัตราการออม (%)","${savingsRate.toStringAsFixed(1)}%"');
    buffer.writeln('"จำนวนรายการทั้งหมด","${transactions.length} รายการ"');
    buffer.writeln('');

    // Column Headers
    buffer.writeln('"ลำดับ","วันที่","เวลา","ชื่อรายการ","ประเภท","หมวดหมู่","บัญชีธนาคาร/กระเป๋าเงิน","จำนวนเงิน (บาท)","บันทึกช่วยจำ / หมายเหตุ"');

    // Data Rows
    for (int i = 0; i < transactions.length; i++) {
      final tx = transactions[i];
      final index = i + 1;

      final dateStr = '${tx.date.day.toString().padLeft(2, '0')}/${tx.date.month.toString().padLeft(2, '0')}/${tx.date.year + 543}';
      final timeStr = '${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')}';

      String typeStr;
      String amountPrefix = '';
      if (tx.type == TransactionType.income) {
        typeStr = 'รายรับ';
        amountPrefix = '+';
      } else if (tx.type == TransactionType.expense) {
        typeStr = 'รายจ่าย';
        amountPrefix = '-';
      } else {
        typeStr = 'โอนเงินข้ามบัญชี';
      }

      final accountName = accounts.firstWhere(
        (a) => a.id == tx.accountId,
        orElse: () => AccountItem(id: '', name: 'บัญชีทั่วไป', bankCode: 'CASH', accountNumber: '', colorValue: 0),
      ).name;

      final title = _escapeCsv(tx.title);
      final category = _escapeCsv(tx.categoryDisplayName);
      final note = _escapeCsv(tx.note ?? tx.slipRefId ?? '');

      buffer.writeln('$index,"$dateStr","$timeStr","$title","$typeStr","$category","$accountName","$amountPrefix${tx.amount.toStringAsFixed(2)}","$note"');
    }

    return buffer.toString();
  }

  /// Exports CSV to user's public Downloads/MeowTang folder
  static Future<String?> exportCsvToDownloads({
    required String csvContent,
    required String fileName,
  }) async {
    final path = await NativeBridgeService.saveExportFile(
      fileName: fileName,
      content: csvContent,
      subDir: 'MeowTang',
    );

    if (path != null && path.isNotEmpty) {
      return path;
    }

    // Fallback: app documents directory
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csvContent, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  static String _escapeCsv(String value) {
    if (value.contains('"') || value.contains(',') || value.contains('\n')) {
      return value.replaceAll('"', '""');
    }
    return value;
  }
}
