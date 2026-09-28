import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/services/ocr_engine_service.dart';
import 'package:ai_expense_tracker/services/easyocr_tesseract_fusion_service.dart';
import 'package:ai_expense_tracker/services/thai_bank_detector.dart';

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

    test('3. iBank slip paying to SCB Mae Manee recipient is recognized as IBANK, NOT SCB', () {
      const ibankSlipText = '''
โอนเงินสำเร็จ
ibank
18 ก.ย. 69 14:20
นาย ซูไฮมี มะแอ
บัญชีไอแบงก์ *** * **476 8
ไปยัง
SCB มณี SHOP
รหัสผู้รับเงิน 014123456789
จำนวนเงิน 85.00 บาท
ค่าธรรมเนียม 0.00 บาท
''';

      // Even if QR payload has 0103014 (SCB merchant code), identifySlipBank must return IBANK
      final bankInfo = ThaiBankDetector.identifySlipBank(
        rawOcrText: ibankSlipText,
        qrPayload: '00020101021130570016A000000677010111011300400000000020103014',
        qrSenderBankCode: '014',
      );
      expect(bankInfo.bankCode, 'IBANK');
      expect(bankInfo.cleanBank, 'ธนาคารอิสลาม');
    });

    test('4. KBank slip with attached Thai/latin text extracts 150.00 correctly', () {
      const kbankSlipText = '''
โอนเงินสำเร็จ
18 ก.ย. 69 08:49 น.
นาย ทดสอบ โอนเงิน
กสิกรไทย
xxx-x-x1234-x
ไปยัง
น.ส. ผู้รับ เงิน
พร้อมเพย์
xxx-xxx-5678
จำนวน:
150.00บาท
ค่าธรรมเนียม:
0.00บาท
''';

      final amount = OcrEngineService.extractAmountFromText(kbankSlipText);
      expect(amount, 150.00);
    });
  });
}
