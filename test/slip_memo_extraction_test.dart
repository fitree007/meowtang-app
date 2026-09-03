import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/services/easyocr_tesseract_fusion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Slip Memo OCR Extraction Tests', () {
    test('1. Extracts same-line memo from KBank / SCB slip text', () {
      const slipText = 'ธนาคารกสิกรไทย\nโอนเงินสำเร็จ\n25 ส.ค. 2569 12:30 น.\nจาก นายสมชาย\nไปยัง นางสมศรี\nจำนวนเงิน 150.00 บาท\nรหัสอ้างอิง: 2026082500112233\nบันทึกช่วยจำ: ค่าอาหารเที่ยงและเครื่องดื่ม\n';

      final memo = EasyOcrTesseractFusionService.extractMemo(slipText);
      expect(memo, 'ค่าอาหารเที่ยงและเครื่องดื่ม');
    });

    test('2. Extracts multi-line memo where label is on its own line', () {
      const slipText = 'ธนาคารไทยพาณิชย์\nโอนเงินสำเร็จ\n25 ส.ค. 2569 14:15 น.\nจำนวนเงิน 500.00 บาท\nบันทึกช่วยจำ\nค่าซ่อมคอมพิวเตอร์\nรหัสอ้างอิง: 2026082599887766\n';

      final memo = EasyOcrTesseractFusionService.extractMemo(slipText);
      expect(memo, 'ค่าซ่อมคอมพิวเตอร์');
    });

    test('3. Extracts English Memo / Note from slip', () {
      const slipText = 'Bangkok Bank\nTransfer Successful\nAmount: 1,200.00 THB\nMemo: Monthly Internet Bill\nRef: BBL20260825\n';

      final memo = EasyOcrTesseractFusionService.extractMemo(slipText);
      expect(memo, 'Monthly Internet Bill');
    });

    test('4. Extracts ข้อความช่วยจำ from Krungthai / PromptPay slip', () {
      const slipText = 'พร้อมเพย์\nโอนเงินสำเร็จ\nจำนวนเงิน 89.00 บาท\nข้อความช่วยจำ: กาแฟ Amazon\n';

      final memo = EasyOcrTesseractFusionService.extractMemo(slipText);
      expect(memo, 'กาแฟ Amazon');
    });
  });
}
