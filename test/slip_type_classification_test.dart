import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/models/transaction_item.dart';
import 'package:ai_expense_tracker/services/ocr_engine_service.dart';

void main() {
  group('Slip Transaction Type (Income vs Expense vs Transfer) Classification Tests', () {
    test('1. Standard KBank transfer slip with "เงินฝากออมทรัพย์" and "โอนเข้าบัญชี" is EXPENSE', () {
      const slipText = '''
ธนาคารกสิกรไทย
โอนเงินสำเร็จ
25 ส.ค. 2569 12:30 น.
จาก นายสมชาย ใจดี
บัญชีเงินฝากออมทรัพย์ xxx-x-x1234-x
ไปยัง นางสมศรี มีสุข
โอนเข้าบัญชี xxx-x-x5678-x
จำนวนเงิน 150.00 บาท
รหัสอ้างอิง: 2026082500112233
''';

      final type = OcrEngineService.detectSlipTransactionType(
        rawText: slipText,
        senderName: 'สมชาย ใจดี',
        receiverName: 'สมศรี มีสุข',
      );
      expect(type, TransactionType.expense);
    });

    test('2. SCB EASY slip with "เงินฝากออมทรัพย์" and "รายการสำเร็จ" is EXPENSE', () {
      const slipText = '''
SCB EASY
รายการสำเร็จ
26 ส.ค. 2569 14:00 น.
จาก บัญชีเงินฝากออมทรัพย์
ไปยัง บัญชีพร้อมเพย์ ร้านข้าวมันไก่
จำนวนเงิน 60.00 บาท
เลขที่อ้างอิง TXNCR99887766
''';

      final type = OcrEngineService.detectSlipTransactionType(
        rawText: slipText,
        senderName: 'สมชาย',
        receiverName: 'ร้านข้าวมันไก่',
      );
      expect(type, TransactionType.expense);
    });

    test('3. Credit Card Payment slip with "ชำระเงินสำเร็จ" and "บัตรเครดิต" is EXPENSE', () {
      const slipText = '''
ธนาคารกรุงไทย
ชำระเงินสำเร็จ
ชำระบิล บัตรเครดิต KTC
จำนวนเงิน 3,500.00 บาท
''';

      final type = OcrEngineService.detectSlipTransactionType(
        rawText: slipText,
      );
      expect(type, TransactionType.expense);
    });

    test('4. Bill payment / Top-up slip is EXPENSE', () {
      const slipText = '''
TrueMoney Wallet
เติมเงินสำเร็จ
จำนวนเงิน 200.00 บาท
''';

      final type = OcrEngineService.detectSlipTransactionType(
        rawText: slipText,
      );
      expect(type, TransactionType.expense);
    });

    test('5. Self-transfer slip between user accounts is TRANSFER', () {
      const slipText = '''
โอนเงินสำเร็จ
จาก นายสมชาย ใจดี
ไปยัง สมชาย ใจดี
จำนวนเงิน 1,000.00 บาท
''';

      final type = OcrEngineService.detectSlipTransactionType(
        rawText: slipText,
        senderName: 'นายสมชาย ใจดี',
        receiverName: 'สมชาย ใจดี',
      );
      expect(type, TransactionType.transfer);
    });

    test('6. Slip with explicit salary memo "เงินเดือน" is INCOME', () {
      const slipText = '''
โอนเงินสำเร็จ
จำนวนเงิน 35,000.00 บาท
บันทึกช่วยจำ: เงินเดือนประจำเดือนสิงหาคม
''';

      final type = OcrEngineService.detectSlipTransactionType(
        rawText: slipText,
        memo: 'เงินเดือนประจำเดือนสิงหาคม',
      );
      expect(type, TransactionType.income);
    });

    test('7. Explicit received money notification slip is INCOME', () {
      const slipText = '''
ท่านได้รับเงินโอน
จำนวนเงิน 500.00 บาท
จาก นายสมหวัง ร่ำรวย
''';

      final type = OcrEngineService.detectSlipTransactionType(
        rawText: slipText,
      );
      expect(type, TransactionType.income);
    });
  });
}
