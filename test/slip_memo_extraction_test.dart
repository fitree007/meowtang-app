import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/services/easyocr_tesseract_fusion_service.dart';
import 'package:ai_expense_tracker/services/category_matcher_service.dart';
import 'package:ai_expense_tracker/models/category_item.dart';

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

    test('5. Extracts short memo "นม" on separate line even with blank lines', () {
      const slipText = 'ธนาคารกสิกรไทย\nโอนเงินสำเร็จ\nจำนวนเงิน 45.00 บาท\nบันทึกช่วยจำ\n\nนม\n\nรหัสอ้างอิง: 20260913998877';

      final memo = EasyOcrTesseractFusionService.extractMemo(slipText);
      expect(memo, 'นม');
    });

    test('6. CategoryMatcherService matches "นม" to "เครื่องดื่ม"', () {
      final userCategories = <CategoryItem>[
        CategoryItem(id: 'cat_food', name: 'อาหาร', colorValue: 0xFF000000, type: CategoryType.expense),
        CategoryItem(id: 'cat_drinks', name: 'เครื่องดื่ม', colorValue: 0xFF000000, type: CategoryType.expense),
        CategoryItem(id: 'cat_travel', name: 'ค่าเดินทาง', colorValue: 0xFF000000, type: CategoryType.expense),
      ];

      final result = CategoryMatcherService.matchCategoryWithResult(
        text: 'โอนเงิน 45 บาท บันทึกช่วยจำ นม',
        availableCategories: userCategories,
      );

      expect(result.category.name, 'เครื่องดื่ม');
    });

    test('7. CategoryMatcherService matches custom keyword rule with custom category and tag', () {
      final userCategories = <CategoryItem>[
        CategoryItem(id: 'cat_food', name: 'อาหาร', colorValue: 0xFF000000, type: CategoryType.expense),
        CategoryItem(id: 'cat_drinks', name: 'เครื่องดื่ม', colorValue: 0xFF000000, type: CategoryType.expense),
        CategoryItem(id: 'cat_market', name: 'ของกินของใช้', colorValue: 0xFF000000, type: CategoryType.expense),
      ];

      final customRules = [
        const KeywordRule(
          id: 'rule_1',
          keyword: '7-Eleven',
          categoryName: 'ของกินของใช้',
          categoryId: 'cat_market',
          tag: 'เซเว่น',
        ),
      ];

      final result = CategoryMatcherService.matchCategoryWithResult(
        text: 'โอนชำระเงิน CP ALL 7-Eleven สาขา 1234',
        availableCategories: userCategories,
        customRules: customRules,
      );

      expect(result.category.name, 'ของกินของใช้');
      expect(result.tag, 'เซเว่น');
    });
  });
}
