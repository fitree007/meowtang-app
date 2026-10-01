import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/services/ocr_engine_service.dart';

void main() {
  group('MyMo by GSB Screenshot Shield Tests', () {
    test('Reject casual chat screenshot mentioning GSB without slip structure', () {
      final chatText = '''
10:30 AM
สมศรี: สวัสดีค่ะ บัญชีธนาคารออมสิน โอนเงินมาให้หรือยังคะ
ฉัน: โอนให้แล้วจ้า 150 บาท
สมศรี: โอเค ขอบคุณค่ะ
''';
      final isSlip = OcrEngineService.isBankSlip(
        chatText,
        fileName: 'Screenshot_2026-10-01-103000.png',
        filePath: '/storage/emulated/0/Pictures/Screenshots/Screenshot_2026-10-01-103000.png',
      );
      expect(isSlip, isFalse, reason: 'Casual chat must be rejected even if it mentions GSB and amount');
    });

    test('Reject non-GSB screenshot slip (e.g. KBank screenshot)', () {
      final kbankText = '''
โอนเงินสำเร็จ
ธนาคารกสิกรไทย
จำนวนเงิน 500.00 บาท
รหัสอ้างอิง 2026100112345678
''';
      final isSlip = OcrEngineService.isBankSlip(
        kbankText,
        fileName: 'Screenshot_2026-10-01-103500.png',
        filePath: '/storage/emulated/0/Pictures/Screenshots/Screenshot_2026-10-01-103500.png',
      );
      expect(isSlip, isFalse, reason: 'Non-GSB screenshot slips must be strictly rejected');
    });

    test('Accept genuine MyMo by GSB screenshot slip', () {
      final mymoSlipText = '''
MyMo by GSB
โอนเงินสำเร็จ
1 ต.ค. 69 10:20
จาก นายสมชาย x-1234
ไปยัง น.ส.สมหญิง x-5678
จำนวนเงิน 350.00 บาท
รหัสอ้างอิง: 202610019988776655
''';
      final isSlip = OcrEngineService.isBankSlip(
        mymoSlipText,
        fileName: 'Screenshot_2026-10-01-102000.png',
        filePath: '/storage/emulated/0/Pictures/Screenshots/Screenshot_2026-10-01-102000.png',
      );
      expect(isSlip, isTrue, reason: 'Genuine MyMo GSB slip screenshot must be accepted');
    });

    test('Accept MyMo screenshot slip with BOT ITMX QR code', () {
      final mymoWithQrText = '''
ธนาคารออมสิน
รายการสำเร็จ
จากบัญชี 123-4-56789-0
ไปยัง พร้อมเพย์ 081-234-5678
จำนวนเงิน 1,200.00 บาท
''';
      final isSlip = OcrEngineService.isBankSlip(
        mymoWithQrText,
        fileName: 'Screenshot_20261001_102015.jpg',
        filePath: '/storage/emulated/0/DCIM/Screenshots/Screenshot_20261001_102015.jpg',
        qrPayload: '00020101021230670016A0000006770101140114010303020261001123456',
      );
      expect(isSlip, isTrue, reason: 'MyMo slip with BOT 0103030 QR code must be accepted');
    });

    test('Accept MyMo screenshot slip with txn id and memo format', () {
      final mymoTxnText = '''
MyMo by GSB
โอนสำเร็จ
1 ต.ค. 2569 09:15
ไปยัง น.ส.มาลี สดใส
จำนวนเงิน 290.00 บาท
รหัสธุรกรรม 2026100109151234
บันทึกช่วยจำ ค่าอาหาร
''';
      final isSlip = OcrEngineService.isBankSlip(
        mymoTxnText,
        fileName: 'Screenshot_20261001-091522.png',
        filePath: '/storage/emulated/0/Pictures/Screenshots/Screenshot_20261001-091522.png',
      );
      expect(isSlip, isTrue, reason: 'MyMo slip with txn id and memo must be accepted');
    });
  });
}
