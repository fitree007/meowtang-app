import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/services/ocr_engine_service.dart';
import 'package:ai_expense_tracker/models/category_item.dart';
import 'package:ai_expense_tracker/models/transaction_item.dart';
import 'package:ai_expense_tracker/services/thai_bank_detector.dart';
import 'package:ai_expense_tracker/services/easyocr_tesseract_fusion_service.dart';

void main() {
  final testCategories = [
    CategoryItem(
      id: 'cat_food',
      name: 'อาหาร & เครื่องดื่ม',
      iconKey: 'restaurant',
      colorValue: 0xFFF59E0B,
      type: CategoryType.expense,
    ),
    CategoryItem(
      id: 'cat_income',
      name: 'รับเงินโอน / รายได้',
      iconKey: 'payments',
      colorValue: 0xFF10B981,
      type: CategoryType.income,
    ),
  ];

  test('Test 1: Other Banks (e.g. KBank, SCB, KTB, iBank) remain untouched and parse amount normally', () {
    const kbankOcr = '''
K PLUS
โอนเงินสำเร็จ
วันที่ 12 มี.ค. 2568 10:15 น.
จาก นาย สมชาย
ไปยัง นาย สมศักดิ์
จำนวนเงิน 850.00 บาท
รหัสอ้างอิง 20250312999888
''';
    final isKBankSlip = OcrEngineService.isBankSlip(kbankOcr);
    expect(isKBankSlip, isTrue);

    final kbankParsed = OcrEngineService().parseSlipText(kbankOcr, testCategories, defaultBankCode: 'กสิกรไทย (K PLUS)');
    expect(kbankParsed.amount, equals(850.00));

    // iBank (Islamic Bank) in or out of PaoTang with "บัญชีไอแบงก์"
    const ibankOcr = '''
เป๋าตัง PaoTang
โอนเงินสำเร็จ
บัญชีไอแบงก์
ไปยัง นาย สมชาย
จำนวนเงิน 1,200.00 บาท
วันที่ 10 เม.ย. 2568
หมายเลขอ้างอิง IBANK123456
''';
    final isIBankSlip = OcrEngineService.isBankSlip(ibankOcr, filePath: '/storage/emulated/0/Pictures/PaoTang/ibank_slip.jpg');
    expect(isIBankSlip, isTrue);

    final ibankParsed = OcrEngineService().parseSlipText(ibankOcr, testCategories, filePath: '/storage/emulated/0/Pictures/PaoTang/ibank_slip.jpg');
    expect(ibankParsed.amount, equals(1200.00));
    expect(ibankParsed.memo, isNull);
  });

  test('Test 2: PaoTang without QR Code -> Always sets amount 0.0 as requested by user', () {
    const paotangWithoutQr = '''
เป๋าตัง G-Wallet
คนละครึ่ง
รายการชำระเงินสำเร็จ
ร้าน ข้าวมันไก่ตอน
วันที่ 15 พ.ย. 2567 - 12:45 น.
จำนวนเงินที่ชำระ 180.00 บาท
สิทธิคนละครึ่ง 90.00 บาท
เงินที่จ่ายจริง 90.00 บาท
รหัสอ้างอิง 0143201948593482
''';

    final isSlip = OcrEngineService.isBankSlip(paotangWithoutQr, filePath: '/storage/emulated/0/Pictures/PaoTang/1740948593482.jpg');
    expect(isSlip, isTrue);

    final parsed = OcrEngineService().parseSlipText(paotangWithoutQr, testCategories, filePath: '/storage/emulated/0/Pictures/PaoTang/1740948593482.jpg');
    expect(parsed.amount, equals(0.0));
    expect(parsed.memo, equals('โปรดระบุยอด'));
  });

  test('Test 3: PaoTang without "จำนวนเงินที่ชำระ" (No QR Code) -> Imports slip with amount 0.0 and prompt to fill manually', () {
    const paotangWithoutPaidText = '''
เป๋าตัง
ไทยช่วยไทย
ทำรายการสำเร็จ
ร้านค้า สวัสดิการชุมชน
วันที่ 20 พ.ย. 2567 - 14:00 น.
สิทธิคงเหลือ 500.00 บาท
รหัสอ้างอิง 998877665544
''';

    // Must be accepted as valid slip so user gets it imported!
    final isSlip = OcrEngineService.isBankSlip(paotangWithoutPaidText, filePath: '/storage/emulated/0/Pictures/PaoTang/random_pic.jpg');
    expect(isSlip, isTrue);

    final parsed = OcrEngineService().parseSlipText(paotangWithoutPaidText, testCategories, filePath: '/storage/emulated/0/Pictures/PaoTang/random_pic.jpg');
    // Amount must be 0.0 with short prompt to fill manually!
    expect(parsed.amount, equals(0.0));
    expect(parsed.memo, equals('โปรดระบุยอด'));
  });

  test('Test 4: Static Receive QR Code (PromptPay My QR, ร้านค้า) -> Rejected (Not a slip)', () {
    const receiveQrText = '''
พร้อมเพย์ PromptPay
สแกนเพื่อรับเงิน
นาย สมชาย ใจดี
081-234-5678
''';
    // Static promptpay QR starts with 000201010211...
    const staticReceiveQrPayload = '00020101021129370016A000000677010111011300668123456785802TH53037646304ABCD';

    final isSlip = OcrEngineService.isBankSlip(
      receiveQrText,
      filePath: '/storage/emulated/0/Pictures/MyQR/promptpay_qr.jpg',
      qrPayload: staticReceiveQrPayload,
    );
    expect(isSlip, isFalse);
  });

  test('Test 5: General non-slip image with random QR -> Rejected', () {
    const randomText = 'เมนูอาหาร ร้านอร่อย ซอย 5 สแกนดูเมนู';
    const randomUrlQr = 'https://restaurant.com/menu/today';

    final isSlip = OcrEngineService.isBankSlip(
      randomText,
      filePath: '/storage/emulated/0/DCIM/Camera/IMG_20260225.jpg',
      qrPayload: randomUrlQr,
    );
    expect(isSlip, isFalse);
  });

  test('Test 6: iBank slip in PaoTang folder with QR Code (Bank Code 066) -> Correctly recognized as Islamic Bank, accurate amount, NO no-QR note', () {
    const ibankInPaotangText = '''
เป๋าตัง PaoTang
โอนเงินสำเร็จ
ไปยัง นาย สมศักดิ์
จำนวนเงิน 350.00 บาท
วันที่ 5 ก.ย. 2568
หมายเลขอ้างอิง 20260905123456
''';
    // EMVCo QR code containing bank code 066 (Islamic Bank of Thailand)
    const ibankQrPayload = '0002010102120041A00000067701011201030660214202609051234565406350.005802TH6304ABCD';

    final isSlip = OcrEngineService.isBankSlip(
      ibankInPaotangText,
      filePath: '/storage/emulated/0/Pictures/PaoTang/PaoTang_20260905_001.jpg',
      qrPayload: ibankQrPayload,
    );
    expect(isSlip, isTrue);

    final parsed = OcrEngineService().parseSlipText(
      ibankInPaotangText,
      testCategories,
      filePath: '/storage/emulated/0/Pictures/PaoTang/PaoTang_20260905_001.jpg',
      qrPayload: ibankQrPayload,
    );

    expect(parsed.amount, equals(350.00));
    expect(parsed.senderBank, contains('อิสลาม'));
    expect(parsed.memo, isNot(contains('สลิปไม่มี QR Code')));
  });

  test('Test 7: Krungthai slip whose Ref ID contains 066 -> Correctly recognized as Krungthai (KTB), NEVER Islamic Bank', () {
    const ktbSlipText = '''
Krungthai กรุงไทย
โอนเงินสำเร็จ
รหัสอ้างอิง N006780661573049723827024
จาก อฟิตรี ย * * *
กรุงไทย
XXX-X-XX056-3
ไปยัง
นายอฟิตรี ยาแมเน๊าะ
กรุงไทย
XXX-X-XX349-9
จำนวนเงิน 100.00 บาท
ค่าธรรมเนียม 0.00 บาท
วันที่ทำรายการ 24 ส.ค. 2569 - 17:06
บันทึกช่วยจำ โอนคืน
''';
    // Krungthai slip QR containing Ref ID N006780661573049723827024 and sending bank code 006
    const ktbQrPayload = '0002010102120049A00000067701011201030060225N0067806615730497238270245406100.005802TH6304ABCD';

    final isSlip = OcrEngineService.isBankSlip(
      ktbSlipText,
      filePath: '/storage/emulated/0/DCIM/Camera/IMG_KTB.jpg',
      qrPayload: ktbQrPayload,
    );
    expect(isSlip, isTrue);

    final parsed = OcrEngineService().parseSlipText(
      ktbSlipText,
      testCategories,
      filePath: '/storage/emulated/0/DCIM/Camera/IMG_KTB.jpg',
      qrPayload: ktbQrPayload,
    );

    expect(parsed.amount, equals(100.00));
    expect(parsed.senderBank, contains('กรุงไทย'));
    expect(parsed.senderBank, isNot(contains('อิสลาม')));
    expect(parsed.memo, equals('โอนคืน'));
  });

  test('Test 8: ThaiBankDetector classifies iBank transaction from PaoTang directory as IBANK (NOT PAOTANG)', () {
    final ibankTx = TransactionItem(
      id: 'tx_ibank_1',
      title: 'โอนเงินผ่านธนาคารอิสลาม',
      amount: 500.0,
      type: TransactionType.expense,
      date: DateTime.now(),
      categoryId: 'cat_transfer',
      categoryName: 'โอนเงิน',
      accountId: 'acc_cash',
      slipImageUrl: '/storage/emulated/0/Pictures/PaoTang/PaoTang_20260906_123456.jpg',
    );

    final bankCode = ThaiBankDetector.detectBankCode(ibankTx, []);
    expect(bankCode, equals('IBANK'));
  });

  test('Test 9: iBank slip with recipient-based title in PaoTang folder is classified as IBANK via bankName', () {
    final ibankTx = TransactionItem(
      id: 'tx_ibank_2',
      title: 'สมชาย โอนให้ สมศักดิ์',
      bankName: 'ธนาคารอิสลามแห่งประเทศไทย',
      amount: 1500.0,
      type: TransactionType.expense,
      date: DateTime.now(),
      categoryId: 'cat_transfer',
      categoryName: 'โอนเงิน',
      accountId: 'acc_ibank',
      slipImageUrl: '/storage/emulated/0/Pictures/PaoTang/1740948593999.jpg',
    );

    final bankCode = ThaiBankDetector.detectBankCode(ibankTx, []);
    expect(bankCode, equals('IBANK'));
  });

  test('Test 10: KBank slip transferring to Islamic recipient (IBNUAUF ISLAMIC COOPERATIVE) -> Correctly recognized as KBank, NEVER Islamic Bank', () {
    const kbankToIslamicRecipientOcr = '''
K+
โอนเงินสำเร็จ
20 ม.ค. 68 14:20 น.
นาย อฟิตรี ย
ธ.กสิกรไทย
xxx-x-x1234-x
ไปยัง
สหกรณ์อิสลามอิบนูเอาฟ จำกัด
IBNUAUF ISLAMIC COOPERATIVE LTD.
xxx-x-x5678-x
จำนวนเงิน 5,000.00 บาท
ค่าธรรมเนียม 0.00 บาท
รหัสอ้างอิง: 20250120004123456789
''';

    // QR payload with senderBankCode 004 (KBank)
    const kbankQrPayload = '0002010102120041A000000677010112010300402142025012000412354065000.005802TH6304ABCD';

    final isSlip = OcrEngineService.isBankSlip(
      kbankToIslamicRecipientOcr,
      filePath: '/storage/emulated/0/Pictures/K PLUS/1737357600000.jpg',
      qrPayload: kbankQrPayload,
    );
    expect(isSlip, isTrue);

    final parsed = OcrEngineService().parseSlipText(
      kbankToIslamicRecipientOcr,
      testCategories,
      filePath: '/storage/emulated/0/Pictures/K PLUS/1737357600000.jpg',
      qrPayload: kbankQrPayload,
    );

    expect(parsed.amount, equals(5000.00));
    expect(parsed.senderBank, contains('กสิกรไทย'));
    expect(parsed.senderBank, isNot(contains('อิสลาม')));

    final detectedBankName = EasyOcrTesseractFusionService.detectBankName(
      kbankToIslamicRecipientOcr,
      filePath: '/storage/emulated/0/Pictures/K PLUS/1737357600000.jpg',
    );
    expect(detectedBankName, contains('กสิกรไทย'));
    expect(detectedBankName, isNot(contains('iBank')));
  });

  test('Test 11: ThaiBankDetector classifies KBank transaction with Islamic recipient as KBANK (NOT IBANK)', () {
    final kbankTx = TransactionItem(
      id: 'tx_kbank_1',
      title: 'นาย อฟิตรี ย โอนให้ IBNUAUF ISLAMIC COOPERATIVE LTD.',
      bankName: 'กสิกรไทย (K PLUS)',
      amount: 5000.0,
      type: TransactionType.expense,
      date: DateTime.now(),
      categoryId: 'cat_transfer',
      categoryName: 'โอนเงิน',
      accountId: 'acc_kbank',
      slipImageUrl: '/storage/emulated/0/Pictures/K PLUS/kplus_slip.jpg',
      rawOcrText: 'K PLUS นาย อฟิตรี ย ธ.กสิกรไทย สหกรณ์อิสลามอิบนูเอาฟ จำกัด IBNUAUF ISLAMIC COOPERATIVE LTD.',
    );

    final bankCode = ThaiBankDetector.detectBankCode(kbankTx, []);
    expect(bankCode, equals('KBANK'));
  });
}



