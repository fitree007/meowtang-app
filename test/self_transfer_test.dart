import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/services/ocr_engine_service.dart';

void main() {
  group('Self-Transfer Detection Tests', () {
    test('Identifies exact matching sender and receiver names', () {
      expect(
        OcrEngineService.isSelfTransfer('สมชาย ใจดี', 'สมชาย ใจดี'),
        isTrue,
      );
    });

    test('Identifies names with titles removed (นาย/นางสาว)', () {
      expect(
        OcrEngineService.isSelfTransfer('นาย สมชาย ใจดี', 'สมชาย ใจดี'),
        isTrue,
      );
      expect(
        OcrEngineService.isSelfTransfer('นางสาว วิไลวรรณ สุขใจ', 'วิไลวรรณ สุขใจ'),
        isTrue,
      );
    });

    test('Identifies names with initials (สมชาย ใจดี vs สมชาย ใ.)', () {
      expect(
        OcrEngineService.isSelfTransfer('สมชาย ใจดี', 'สมชาย ใ.'),
        isTrue,
      );
    });

    test('Identifies explicit keywords in slip text', () {
      expect(
        OcrEngineService.isSelfTransfer('ไม่ระบุ', 'ไม่ระบุ', rawText: 'โอนเงินระหว่างบัญชีตนเอง สำเร็จ 500 บาท'),
        isTrue,
      );
      expect(
        OcrEngineService.isSelfTransfer('ไม่ระบุ', 'ไม่ระบุ', rawText: 'โอนเข้าบัญชีตนเอง'),
        isTrue,
      );
    });

    test('Does NOT mark different people as self-transfer', () {
      expect(
        OcrEngineService.isSelfTransfer('สมชาย ใจดี', 'ร้านสะดวกซื้อ 7-11'),
        isFalse,
      );
      expect(
        OcrEngineService.isSelfTransfer('สมชาย ใจดี', 'สมบัติ มีทรัพย์'),
        isFalse,
      );
    });
  });
}
