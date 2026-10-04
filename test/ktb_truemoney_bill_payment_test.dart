import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/services/ocr_engine_service.dart';
import 'package:ai_expense_tracker/services/thai_bank_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KTB to TrueMoney Bill Payment & Top-up Tests', () {
    const ktbToTrueMoneySlip = '''
Krungthai กรุงไทย
จ่ายบิลสำเร็จ
รหัสอ้างอิง 20261002956031154
อพิตรี ย * * *
กรุงไทย
XXX-X-XX056-3
ทรูมันนี่ (24358)
เบอร์โทรศัพท์ลูกค้า 0908823798
หมายเลขการทำรายการ 26100219554484040 641
จำนวนเงิน 200.00 บาท
ค่าธรรมเนียม 0.00 บาท
วันที่ทำรายการ 02 ต.ค. 2569 - 19:56
บันทึกช่วยจำ ยืม
''';

    test('1. Identifies issuing bank as KTB (Krungthai), NOT TrueMoney', () {
      final bankIdent = ThaiBankDetector.identifySlipBank(
        rawOcrText: ktbToTrueMoneySlip,
      );

      expect(bankIdent.bankCode, 'KTB');
      expect(bankIdent.cleanBank, 'กรุงไทย');
      expect(bankIdent.bankName, contains('กรุงไทย'));
    });

    test('2. Extracts sender as อพิตรี ย and receiver as ทรูมันนี่', () {
      final lines = ktbToTrueMoneySlip.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      final names = OcrEngineService.extractSenderAndReceiver(ktbToTrueMoneySlip, lines);

      expect(names['sender'], contains('อพิตรี ย'));
      expect(names['receiver'], contains('ทรูมันนี่'));
    });

    test('3. Extracts exact amount 200.00 and memo ยืม', () {
      final amount = OcrEngineService.extractAmountFromText(ktbToTrueMoneySlip);
      expect(amount, 200.00);

      final memo = OcrEngineService.extractMemo(ktbToTrueMoneySlip);
      expect(memo, 'ยืม');
    });

    test('4. Genuine TrueMoney Wallet transfer slip is still correctly detected as TRUEMONEY', () {
      const genuineTrueMoneySlip = '''
TrueMoney Wallet
โอนเงินสำเร็จ
จากวอลเล็ท 081-xxx-1234
นาย สมชาย สุขสบาย
ไปยัง บัญชีธนาคาร
กสิกรไทย 123-x-xxxxx-9
นาย ประหยัด รวยจริง
จำนวนเงิน 500.00 บาท
วันที่ 01 ต.ค. 2569 12:00
''';

      final bankIdent = ThaiBankDetector.identifySlipBank(
        rawOcrText: genuineTrueMoneySlip,
        qrSenderBankCode: '025', // Partner settlement code in QR should not hijack TrueMoney
      );

      expect(bankIdent.bankCode, 'TRUEMONEY');
      expect(bankIdent.cleanBank, 'ทรูมันนี่');
    });
  });
}
