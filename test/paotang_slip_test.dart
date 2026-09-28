import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/services/ocr_engine_service.dart';
import 'package:ai_expense_tracker/models/category_item.dart';
import 'package:ai_expense_tracker/models/transaction_item.dart';
import 'package:ai_expense_tracker/services/thai_bank_detector.dart';
import 'package:ai_expense_tracker/services/easyocr_tesseract_fusion_service.dart';
import 'package:ai_expense_tracker/services/category_matcher_service.dart';

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

  test('Test 2: PaoTang government slip -> Extracts bottom-most paid amount as requested by user', () {
    const paotangSlip = '''
เป๋าตัง G-Wallet
คนละครึ่ง
รายการชำระเงินสำเร็จ
ร้าน ข้าวมันไก่ตอน
วันที่ 15 พ.ย. 2567 - 12:45 น.
ค่าสินค้า/บริการ 180.00 บาท
สิทธิคนละครึ่ง -90.00 บาท
จำนวนเงินที่ต้องชำระ 90.00 บาท
รหัสอ้างอิง 0143201948593482
''';

    final isSlip = OcrEngineService.isBankSlip(paotangSlip, filePath: '/storage/emulated/0/Pictures/PaoTang/1740948593482.jpg');
    expect(isSlip, isTrue);

    final parsed = OcrEngineService().parseSlipText(paotangSlip, testCategories, filePath: '/storage/emulated/0/Pictures/PaoTang/1740948593482.jpg');
    expect(parsed.amount, equals(90.0));
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

  test('Test 12: Pure Receive QR Codes (PromptPay My QR, QR รับเงิน) are rejected by isBankSlip', () {
    // 12A. Static PromptPay Receive QR (My QR)
    const receiveQrPayload = '00020101021129370016A000000677010111011300668123456785802TH53037646304ABCD';
    const receiveQrText = '''
QR รับเงิน
สแกนเพื่อจ่ายเงินให้ฉัน
นาย สมชาย ใจดี
พร้อมเพย์ 081-234-5678
''';
    final isSlip1 = OcrEngineService.isBankSlip(
      receiveQrText,
      qrPayload: receiveQrPayload,
      fileName: 'my_qr_code.jpg',
    );
    expect(isSlip1, isFalse);

    // 12B. Dynamic Merchant Receive QR with pre-filled amount
    const merchantQrPayload = '00020101021230570016A000000677010112011300400000000025405150.005802TH63049999';
    const merchantQrText = '''
สแกน QR เพื่อชำระเงิน
ร้านค้าของฉัน
จำนวนเงิน 150.00 บาท
''';
    final isSlip2 = OcrEngineService.isBankSlip(
      merchantQrText,
      qrPayload: merchantQrPayload,
      fileName: 'receive_qr_150.png',
    );
    expect(isSlip2, isFalse);
  });

  test('Test 13: PaoTang government project slip (คนละครึ่ง / ไทยช่วยไทย) without paid amount sets initial amount to 0.0', () {
    const govOcr = '''
คนละครึ่ง
ไทยช่วยไทย
15 ก.ย. 68 12:30
ร้านค้าประชารัฐ
สิทธิคงเหลือ 150.00 บาท
''';
    final parsed = OcrEngineService().parseSlipText(
      govOcr,
      testCategories,
      filePath: '/storage/emulated/0/Pictures/PaoTang/gov_slip.jpg',
    );
    // Government PaoTang slips without paid amount must be initialized to 0.0 per user instruction
    expect(parsed.amount, equals(0.0));
  });

  test('Test 14: CategoryMatcherService matches "shopee" to "ช้อปปิ้ง & ของใช้" via custom rule or default rule', () {
    final categories = [
      CategoryItem(id: 'cat_shop', name: 'ช้อปปิ้ง & ของใช้', iconKey: 'shopping_bag', colorValue: 0xFF3B82F6, type: CategoryType.expense),
      CategoryItem(id: 'cat_food', name: 'อาหาร', iconKey: 'restaurant', colorValue: 0xFFF59E0B, type: CategoryType.expense),
    ];

    // Case A: Default rule for shopee
    final resA = CategoryMatcherService.matchCategoryWithResult(
      text: 'โอนเงินชำระค่าสินค้า shopee order #12345',
      availableCategories: categories,
    );
    expect(resA.category.name, equals('ช้อปปิ้ง & ของใช้'));

    // Case B: Custom rule with target category "ช็อปออนไลน์" matching user's "ช้อปปิ้ง & ของใช้"
    final customRules = [
      const KeywordRule(id: 'c1', keyword: 'shopee', categoryName: 'ช็อปออนไลน์'),
    ];
    final resB = CategoryMatcherService.matchCategoryWithResult(
      text: 'shopee',
      availableCategories: categories,
      customRules: customRules,
    );
    expect(resB.category.name, equals('ช้อปปิ้ง & ของใช้'));
  });

  test('Test 15: Custom rule matches keyword found in slip memo', () {
    final categories = [
      CategoryItem(id: 'cat_gas', name: 'ค่าน้ำมัน', iconKey: 'local_gas_station', colorValue: 0xFFEF4444, type: CategoryType.expense),
      CategoryItem(id: 'cat_other', name: 'รายจ่ายอื่นๆ', iconKey: 'category', colorValue: 0xFF64748B, type: CategoryType.expense),
    ];
    final customRules = [
      const KeywordRule(id: 'c2', keyword: 'เติมน้ำมัน', categoryName: 'ค่าน้ำมัน'),
    ];

    const slipWithMemo = '''
โอนเงินสำเร็จ
18 ก.ย. 69
จาก นาย ก
ไปยัง ปั๊มบางจาก
บันทึกช่วยจำ: เติมน้ำมันรถยนต์
จำนวนเงิน 500.00 บาท
''';

    final parsed = OcrEngineService().parseSlipText(
      slipWithMemo,
      categories,
      customRules: customRules,
    );
    expect(parsed.suggestedCategoryName, equals('ค่าน้ำมัน'));
  });

  test('Test 16: PaoTang 4 Sample Slips from User accurately extract bottom-most user-paid amount', () {
    // Slip 1: คนละครึ่งพลัส (200 - 100 = 100)
    const slip1 = '''
คนละครึ่งพลัส
ค่าสินค้า/บริการ 200.00 บาท
สิทธิคนละครึ่งพลัส -100.00 บาท
จำนวนเงินที่ต้องชำระ 100.00 บาท
''';
    expect(EasyOcrTesseractFusionService.extractPaotangGovPaidAmount(slip1), equals(100.00));
    final p1 = OcrEngineService().parseSlipText(slip1, testCategories, filePath: '/storage/emulated/0/Pictures/PaoTang/slip1.png');
    expect(p1.amount, equals(100.00));

    // Slip 2: ไทยช่วยไทยพลัส ร้านขวดนม (85 - 51 = 34)
    const slip2 = '''
ไทยช่วยไทยพลัส
ร้านขวดนม
ค่าสินค้า/บริการ 85.00 บาท
สิทธิไทยช่วยไทยพลัส -51.00 บาท
จำนวนเงินที่ต้องชำระ 34.00 บาท
''';
    expect(EasyOcrTesseractFusionService.extractPaotangGovPaidAmount(slip2), equals(34.00));
    final p2 = OcrEngineService().parseSlipText(slip2, testCategories, filePath: '/storage/emulated/0/Pictures/PaoTang/slip2.jpg');
    expect(p2.amount, equals(34.00));

    // Slip 3: ไทยช่วยไทยพลัส ร้านบิงซูแพนด้า (39 - 23.40 = 15.60)
    const slip3 = '''
ไทยช่วยไทยพลัส
ร้านบิงซูแพนด้า
ค่าสินค้า/บริการ 39.00 บาท
สิทธิไทยช่วยไทยพลัส -23.40 บาท
จำนวนเงินที่ต้องชำระ 15.60 บาท
''';
    expect(EasyOcrTesseractFusionService.extractPaotangGovPaidAmount(slip3), equals(15.60));
    final p3 = OcrEngineService().parseSlipText(slip3, testCategories, filePath: '/storage/emulated/0/Pictures/PaoTang/slip3.jpg');
    expect(p3.amount, equals(15.60));

    // Slip 4: ไทยช่วยไทยพลัส โซเฟีย (58 - 34.80 = 23.20)
    const slip4 = '''
ไทยช่วยไทยพลัส
โซเฟีย
ค่าสินค้า/บริการ 58.00 บาท
สิทธิไทยช่วยไทยพลัส -34.80 บาท
จำนวนเงินที่ต้องชำระ 23.20 บาท
''';
    expect(EasyOcrTesseractFusionService.extractPaotangGovPaidAmount(slip4), equals(23.20));
    final p4 = OcrEngineService().parseSlipText(slip4, testCategories, filePath: '/storage/emulated/0/Pictures/PaoTang/slip4.jpg');
    expect(p4.amount, equals(23.20));
  });

  test('Test 17: User Slips - iBank inside Paotang folder must extract 6,000.00 and 2,000.00 (NOT Ref ID 26241 or 5)', () {
    // Exact text from user Image 2
    const ibankSlip6000 = '''
ทำรายการสำเร็จ ibank
29 ส.ค. 69 10:10
นาย อฟิตรี ยาแมเน๊าะ
บัญชีไอแบงก์ *** * **766 1
↓
นาย อฟิตรี ยาแมเน๊าะ
บัญชีกสิกรไทย *** * **249 1
จำนวนเงิน 6,000.00 บาท
ค่าธรรมเนียม 0.00 บาท
รหัสอ้างอิง
26241X0101033280705ZVJOBQ
ใช้นิ้วซูมเข้า-ออกดูสลิปเต็มจอ
''';

    // Must be identified as IBANK even if in Paotang folder!
    final ident6000 = ThaiBankDetector.identifySlipBank(
      rawOcrText: ibankSlip6000,
      filePath: '/storage/emulated/0/Pictures/Paotang/26241X0101033280705ZVJOBQ.jpg',
    );
    expect(ident6000.bankCode, equals('IBANK'));
    expect(ident6000.cleanBank, equals('ธนาคารอิสลาม'));

    final parsed6000 = OcrEngineService().parseSlipText(
      ibankSlip6000,
      testCategories,
      filePath: '/storage/emulated/0/Pictures/Paotang/26241X0101033280705ZVJOBQ.jpg',
    );
    expect(parsed6000.amount, equals(6000.00));
    expect(parsed6000.refId, equals('26241X0101033280705ZVJOBQ'));

    // Exact text from user Image 3
    const ibankSlip2000 = '''
ทำรายการสำเร็จ ibank
27 ก.ย. 69 17:00
นาย อฟิตรี ยาแมเน๊าะ
บัญชีไอแบงก์ *** * **766 1
↓
นาย อฟิตรี ยาแมเน๊าะ
บัญชีกสิกรไทย *** * **249 1
จำนวนเงิน 2,000.00 บาท
ค่าธรรมเนียม 0.00 บาท
รหัสอ้างอิง
26270X0170044432929XEXU5Q
ใช้นิ้วซูมเข้า-ออกดูสลิปเต็มจอ
''';

    final ident2000 = ThaiBankDetector.identifySlipBank(
      rawOcrText: ibankSlip2000,
      filePath: '/storage/emulated/0/Pictures/Paotang/26270X0170044432929XEXU5Q.jpg',
    );
    expect(ident2000.bankCode, equals('IBANK'));
    expect(ident2000.cleanBank, equals('ธนาคารอิสลาม'));

    final parsed2000 = OcrEngineService().parseSlipText(
      ibankSlip2000,
      testCategories,
      filePath: '/storage/emulated/0/Pictures/Paotang/26270X0170044432929XEXU5Q.jpg',
    );
    expect(parsed2000.amount, equals(2000.00));
    expect(parsed2000.refId, equals('26270X0170044432929XEXU5Q'));
  });

  test('Test 18: Other Banks transferring to iBank or G-Wallet never get corrupted', () {
    // KBank transfer to iBank
    const kbankToIBank = '''
K PLUS
โอนเงินสำเร็จ
20 ต.ค. 2568 14:30 น.
จาก: นาย อารีฟีน
บัญชีกสิกรไทย xxx-x-x1234
ไปยัง: นาย อฟิตรี
บัญชีไอแบงก์ xxx-x-x7661
จำนวนเงิน 1,500.00 บาท
ค่าธรรมเนียม 0.00 บาท
รหัสอ้างอิง KB202510209999
''';

    final identKToI = ThaiBankDetector.identifySlipBank(
      rawOcrText: kbankToIBank,
      qrSenderBankCode: '004',
      filePath: '/storage/emulated/0/Pictures/Paotang/kbank_to_ibank.jpg',
    );
    expect(identKToI.bankCode, equals('KBANK'));
    expect(identKToI.cleanBank, equals('กสิกรไทย'));

    final parsedKToI = OcrEngineService().parseSlipText(
      kbankToIBank,
      testCategories,
      filePath: '/storage/emulated/0/Pictures/Paotang/kbank_to_ibank.jpg',
    );
    expect(parsedKToI.amount, equals(1500.00));

    // KBank transfer / top-up to G-Wallet
    const kbankToGWallet = '''
K PLUS
เติมเงินสำเร็จ
18 ต.ค. 2568 11:20 น.
จาก: นาย อารีฟีน บัญชีกสิกรไทย
ไปยัง: G-Wallet (เป๋าตัง) 081-xxx-xxxx
จำนวนเงิน 500.00 บาท
รหัสอ้างอิง KB202510185555
''';
    final identKToG = ThaiBankDetector.identifySlipBank(
      rawOcrText: kbankToGWallet,
      qrSenderBankCode: '004',
      filePath: '/storage/emulated/0/Pictures/Paotang/kbank_to_gwallet.jpg',
    );
    expect(identKToG.bankCode, equals('KBANK'));

    final parsedKToG = OcrEngineService().parseSlipText(
      kbankToGWallet,
      testCategories,
      filePath: '/storage/emulated/0/Pictures/Paotang/kbank_to_gwallet.jpg',
    );
    expect(parsedKToG.amount, equals(500.00));
  });

  test('Test 19: New future Gov Project in Paotang without explicit name reads bottom-to-top safely', () {
    const futureGovSlip = '''
เป๋าตัง G-Wallet
ทำรายการสำเร็จ
ร้าน ค้าประชารัฐร่วมใจ
วันที่ 05 พ.ย. 68 12:30 น.
ค่าสินค้า 300.00 บาท
เงินสนับสนุนรัฐบาล -150.00 บาท
จำนวนเงินที่ต้องชำระ 150.00 บาท
รหัสอ้างอิง
26299X09999999999999ZZZZZ
ใช้นิ้วซูมเข้า-ออกดูสลิปเต็มจอ
''';

    final parsedFuture = OcrEngineService().parseSlipText(
      futureGovSlip,
      testCategories,
      filePath: '/storage/emulated/0/Pictures/Paotang/future_slip.jpg',
    );
    // Must extract 150.00 and NEVER touch Ref ID 26299X...
    expect(parsedFuture.amount, equals(150.00));
  });
}




