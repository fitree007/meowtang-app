import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/services/ocr_engine_service.dart';
import 'package:ai_expense_tracker/services/thai_bank_detector.dart';
import 'package:ai_expense_tracker/models/transaction_item.dart';

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

    test('Accept exact real user MyMo top-up slip', () {
      final realUserMymoSlip = '''
รายการเติมเงินสำเร็จ
จำนวนเงิน
42.00
0.00 ค่าธรรมเนียม
รหัสอ้างอิง: 6274080955791000008B9790
1 ต.ค. 2569 08:05
จาก
นาย กูรีดวน บินอูมา
ธนาคารออมสิน
0202xxxx1320
ถึง
น.ส. นุรฮายาตี ลือแบซา
เติมเงินพร้อมเพย์
004999xxxxx2840
QR Code
สแกน QR เพื่อตรวจสอบ
รายละเอียดของรายการ
mymo by GSB
''';
      final isSlip = OcrEngineService.isBankSlip(
        realUserMymoSlip,
        fileName: 'Screenshot_20261001-080512.jpg',
        filePath: '/storage/emulated/0/Picture/Screenshot_20261001-080512.jpg',
      );
      expect(isSlip, isTrue, reason: 'Exact user MyMo top-up screenshot must be accepted');

      final amt = OcrEngineService.extractAmountFromText(realUserMymoSlip);
      expect(amt, equals(42.0), reason: 'Amount must be exactly 42.00');

      final parties = OcrEngineService.extractSenderAndReceiver(realUserMymoSlip, realUserMymoSlip.split('\n'));
      expect(parties['sender'], contains('กูรีดวน'));
      expect(parties['receiver'], contains('นุรฮายาตี'));

      final bankIdent = ThaiBankDetector.identifySlipBank(rawOcrText: realUserMymoSlip);
      expect(bankIdent.bankCode, equals('GSB'));
    });

    test('Strict rejection of solitary titles and OCR gibberish noise', () {
      expect(OcrEngineService.isValidPersonOrShopName('น.ส.'), isFalse);
      expect(OcrEngineService.isValidPersonOrShopName('นาย'), isFalse);
      expect(OcrEngineService.isValidPersonOrShopName('คุณ'), isFalse);
      expect(OcrEngineService.isValidPersonOrShopName('น.ส. asdflkjsd'), isFalse);
      expect(OcrEngineService.isValidPersonOrShopName('นาย qwrtyp'), isFalse);
      expect(OcrEngineService.isValidPersonOrShopName('น.ส. นุรฮายาตี ลือแบซา'), isTrue);
      expect(OcrEngineService.isValidPersonOrShopName('นาย กูรีดวน บินอูมา'), isTrue);
    });

    test('TransactionItem slipTransferDescription rejects OCR noise and cleans promptpay topup', () {
      final itemNoise = TransactionItem(
        id: '1',
        title: 'โอนเงิน',
        amount: 50.0,
        type: TransactionType.expense,
        date: DateTime.now(),
        accountId: 'acc1',
        categoryId: 'cat1',
        categoryName: 'ทั่วไป',
        senderName: 'น.ส. asdfghjk',
        receiverName: null,
      );
      expect(itemNoise.slipTransferDescription, isNull, reason: 'Must not show gibberish name');

      final itemTopup = TransactionItem(
        id: '2',
        title: 'โอนเงิน',
        amount: 42.0,
        type: TransactionType.expense,
        date: DateTime.now(),
        accountId: 'acc1',
        categoryId: 'cat1',
        categoryName: 'ทั่วไป',
        senderName: 'นาย กูรีดวน บินอูมา',
        receiverName: 'น.ส. นุรฮายาตี ลือแบซา เติมเงินพร้อมเพย์',
      );
      expect(itemTopup.slipTransferDescription, equals('โอนจาก นาย กูรีดวน บินอูมา ➔ น.ส. นุรฮายาตี ลือแบซา'));

      // Expense with valid sender but no receiver must NOT show "โอนโดย..."
      final itemExpenseNoReceiver = TransactionItem(
        id: '3',
        title: 'โอนเงิน',
        amount: 100.0,
        type: TransactionType.expense,
        date: DateTime.now(),
        accountId: 'acc1',
        categoryId: 'cat1',
        categoryName: 'ทั่วไป',
        senderName: 'นาย กูรีดวน บินอูมา',
        receiverName: null,
      );
      expect(itemExpenseNoReceiver.slipTransferDescription, isNull, reason: 'Expense without receiver should stay clean');

      // Income with sender shows "รับโอนจาก..."
      final itemIncome = TransactionItem(
        id: '4',
        title: 'เงินเข้า',
        amount: 500.0,
        type: TransactionType.income,
        date: DateTime.now(),
        accountId: 'acc1',
        categoryId: 'cat1',
        categoryName: 'ทั่วไป',
        senderName: 'นาย กูรีดวน บินอูมา',
        receiverName: null,
      );
      expect(itemIncome.slipTransferDescription, equals('รับโอนจาก นาย กูรีดวน บินอูมา'));
    });

    test('TrueMoney Wallet slip with PromptPay QR containing 025 (Krungsri) is correctly identified as TRUEMONEY', () {
      final tmnOcrText = '''
truemoney
฿ 1,840.00
กูรีดวน บิน****
บัญชีทรูมันนี่ ***_***-1742
จากวอลเล็ท
นายกูรีดวน บิน****
06*-***-1742
พร้อมเพย์
วันที่ทำรายการ 5 ก.ค. 2569 23:00:22
เลขที่อ้างอิง 50055856197973
สถานที่ทำรายการ Chang Wat Pattani, ประเทศไทย
สแกนคิวอาร์โค้ดนี้ เพื่อตรวจสอบรายการ
''';

      // QR payload contains 0103025 (BAY Krungsri receiving code)
      final qrPayloadWithBay = '00020101021230670016A00000067701011401140103025020261001123456';

      final bankIdent = ThaiBankDetector.identifySlipBank(
        rawOcrText: tmnOcrText,
        qrPayload: qrPayloadWithBay,
        qrSenderBankCode: '025',
        filePath: '/storage/emulated/0/Pictures/Screenshots/Screenshot_2026-07-05.jpg',
      );

      expect(bankIdent.bankCode, equals('TRUEMONEY'), reason: 'TrueMoney wallet preemption must override recipient bank 025');
      expect(bankIdent.cleanBank, equals('ทรูมันนี่'));
      expect(bankIdent.bankName, equals('TrueMoney Wallet'));
    });

    test('Krungthai NEXT slip with spaced "ไป ยัง" successfully extracts receiver', () {
      final ktbOcrText = '''
ธนาคารกรุงไทย
โอนเงินสำเร็จ
1 ต.ค. 2569 14:00
จาก นายสมชาย ใจดี
กรุงไทย xxx-x-xxxxx-x
ไป ยัง น.ส. สมใจ หมายมั่น
พร้อมเพย์ 081-xxx-xxxx
จำนวนเงิน 500.00 บาท
รหัสอ้างอิง 2026100114001234
''';

      final parties = OcrEngineService.extractSenderAndReceiver(ktbOcrText, ktbOcrText.split('\n'));
      expect(parties['sender'], contains('สมชาย'));
      expect(parties['receiver'], contains('สมใจ'));
    });
  });
}

