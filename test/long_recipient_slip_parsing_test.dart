import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/services/easyocr_tesseract_fusion_service.dart';
import 'package:ai_expense_tracker/services/ocr_engine_service.dart';

void main() {
  test('Case 1: Standard long recipient with newline after amount label', () {
    const text = '''
โอนเงินสำเร็จ
12 มี.ค. 68 10:15
จาก
นาย สมชาย สุขใจ
x-1234
ไปยัง
บริษัท ซีพี ออลล์ จำกัด (มหาชน)
สาขาที่ 12345 สีลมคอมเพล็กซ์
เลขประจำตัวผู้เสียภาษี 0107542000011
PromptPay 0107542000011
บช. 123-4-56789-0
จำนวนเงิน
1,500.00
ค่าธรรมเนียม
0.00
รหัสอ้างอิง
20260312123456789
''';
    final amt = EasyOcrTesseractFusionService.extractAmount(text);
    print('CASE 1 AMT: ' + amt.toString());
    expect(amt, 1500.00);
  });

  test('Case 2: Column split where labels appear first, then values', () {
    const text = '''
โอนเงินสำเร็จ
จาก
ไปยัง
จำนวนเงิน
ค่าธรรมเนียม
นาย สมชาย สุขใจ
บริษัท สยามพารากอน รีเทล จำกัด
สำนักงานใหญ่
เลขประจำตัวผู้เสียภาษี 0105537012345
พร้อมเพย์ 0105537012345
บช. xxx-x-x1234-x
3,450.50
0.00
''';
    final amt = EasyOcrTesseractFusionService.extractAmount(text);
    print('CASE 2 AMT: ' + amt.toString());
    expect(amt, 3450.50);
  });

  test('Case 3: Recipient name has numbers or decimals in address / biller info', () {
    const text = '''
รายการสำเร็จ
20 ม.ค. 2568 18:22 น.
จาก นาย กิตติศักดิ์
ไปยัง
บมจ. โทรคมนาคมแห่งชาติ
สาขา 00012
Biller ID: 0107546000229
Ref 1: 0812345678
Ref 2: 9876543210
จำนวนเงิน (THB)
850.75
ค่าธรรมเนียม 0.00 บาท
''';
    final amt = EasyOcrTesseractFusionService.extractAmount(text);
    print('CASE 3 AMT: ' + amt.toString());
    expect(amt, 850.75);
  });

  test('Case 4: K PLUS style with long recipient merchant and amount label separated', () {
    const text = '''
k plus
โอนเงินสำเร็จ
15 ก.พ. 68 12:45
นาย สมหวัง รวยดี
xxx-2-34567-x
ไปยัง
ร้าน ป้าณี ก๋วยเตี๋ยวเรืออยุธยา (สาขา 2)
เลขผู้เสียภาษี 3100501234567
พร้อมเพย์ 0891234567
กสิกรไทย xxx-1-23456-x
จำนวน:
55.00 บาท
ค่าธรรมเนียม:
0.00 บาท
''';
    final amt = EasyOcrTesseractFusionService.extractAmount(text);
    print('CASE 4 AMT: ' + amt.toString());
    expect(amt, 55.00);
  });

  test('Case 5: Recipient with ร้านค้าสวัสดิการ and จำนวนเงิน (บาท) on next line', () {
    const text = '''
โอนเงินสำเร็จ
10 มี.ค. 68 14:20 น.
จาก: นาย สมบูรณ์ ทรัพย์เจริญ
xxx-x-x1234-x
ไปยัง:
ร้านค้าสวัสดิการกองบิน 4
สำนักงานสวัสดิการ
เลขประจำตัวผู้เสียภาษี 0107535000071
บช. 001-2-34567-8
ธนาคารกรุงเทพ
จำนวนเงิน (บาท)
1,250.00
ค่าธรรมเนียม (บาท)
0.00
''';
    final amt = EasyOcrTesseractFusionService.extractAmount(text);
    print('CASE 5 AMT: ' + amt.toString());
    expect(amt, 1250.00);
  });

  test('Case 6: 4-5 line recipient with whole baht amount without decimals', () {
    const text = '''
โอนเงินสำเร็จ
จาก นาย สมใจ นึก
xxx-1-23456-x
ไปยัง
ห้างหุ้นส่วนจำกัด โชคอนันต์วัสดุก่อสร้าง
สาขา 3 ปากเกร็ด นนทบุรี
เลขประจำตัว 0123567890123
ธนาคารกรุงศรีอยุธยา xxx-4-56789-x
พร้อมเพย์ 0123567890123
จำนวนเงิน:
500 บาท
ค่าธรรมเนียม:
0.00 บาท
''';
    final amt = EasyOcrTesseractFusionService.extractAmount(text);
    print('CASE 6 AMT: ' + amt.toString());
    expect(amt, 500.00);
  });
}

