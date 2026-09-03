import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/services/ocr_engine_service.dart';
import 'package:ai_expense_tracker/services/easyocr_tesseract_fusion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('iBank Islamic Bank Slip OCR Parsing Tests', () {
    test('1. Extracts exact 130.00 THB from iBank merchant/biller slip without picking IDs or fees', () {
      const rawSlipText = '''
ชำระเงินสำเร็จ ibank
2 ธ.ค. 68 11:36
นาย กูรีดวน บินอูมา
บัญชีไอแบงก์ *** ***476 8
THE YALA PROVINCIAL CO.,LTD.
รหัสผู้รับเงิน: *** ******** 7403
หมายเลขร้านค้า: *** ******** 9374
เลขที่อ้างอิง2: 4501384612409144203
รหัสอ้างอิง 3: 45013846
จำนวนเงิน 130.00 บาท
ค่าธรรมเนียม 0.00 บาท
รหัสอ้างอิง 25336BX173617838567DGKG09
''';

      final amount = OcrEngineService.extractAmountFromText(rawSlipText);
      expect(amount, 130.00);

      final date = OcrEngineService.extractDateTimeFromText(rawSlipText);
      expect(date.day, 2);
      expect(date.month, 12);
      expect(date.year, 2025);
      expect(date.hour, 11);
      expect(date.minute, 36);

      final ref = EasyOcrTesseractFusionService.extractRefId(rawSlipText);
      expect(ref, '25336BX173617838567DGKG09');

      final bank = EasyOcrTesseractFusionService.detectBankName(rawSlipText);
      expect(bank, 'iBank (อิสลามแห่งประเทศไทย)');
    });

    test('2. Multi-line column split OCR layout for iBank', () {
      const splitSlipText = '''
ชำระเงินสำเร็จ
ibank
2 ธ.ค. 68 11:36
นาย กูรีดวน บินอูมา
บัญชีไอแบงก์ *** ***476 8
THE YALA PROVINCIAL CO.,LTD.
รหัสผู้รับเงิน: *** ******** 7403
หมายเลขร้านค้า: *** ******** 9374
เลขที่อ้างอิง2: 4501384612409144203
รหัสอ้างอิง 3: 45013846
จำนวนเงิน
ค่าธรรมเนียม
130.00 บาท
0.00 บาท
รหัสอ้างอิง
25336BX173617838567DGKG09
''';

      final amount = OcrEngineService.extractAmountFromText(splitSlipText);
      expect(amount, 130.00);
    });
  });
}
