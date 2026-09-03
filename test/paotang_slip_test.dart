import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/services/ocr_engine_service.dart';
import 'package:ai_expense_tracker/models/category_item.dart';

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

    // iBank (Islamic Bank) in or out of PaoTang
    const ibankOcr = '''
ธนาคารอิสลามแห่งประเทศไทย
iBank
โอนเงินสำเร็จ
จำนวนเงิน 1,200.00 บาท
วันที่ 10 เม.ย. 2568
หมายเลขอ้างอิง IBANK123456
''';
    final isIBankSlip = OcrEngineService.isBankSlip(ibankOcr, filePath: '/storage/emulated/0/Pictures/PaoTang/ibank_slip.jpg');
    expect(isIBankSlip, isTrue);

    final ibankParsed = OcrEngineService().parseSlipText(ibankOcr, testCategories, filePath: '/storage/emulated/0/Pictures/PaoTang/ibank_slip.jpg');
    expect(ibankParsed.amount, equals(1200.00));
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
  });

  test('Test 3: PaoTang without "จำนวนเงินที่ชำระ" (No QR Code) -> Imports slip with amount 0.0 and prompt to fill manually', () {
    const paotangWithoutPaidText = '''
เป๋าตัง
โครงการรัฐ
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
    // Because "จำนวนเงินที่ชำระ" was not present, amount must be 0.0 for user to fill manually!
    expect(parsed.amount, equals(0.0));
    expect(parsed.memo, equals('สลิปไม่มี QR Code (แตะเพื่อระบุยอดเงิน)'));
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
}
