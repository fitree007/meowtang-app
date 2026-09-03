import '../models/transaction_item.dart';
import '../models/category_item.dart';

class ParsedNlpTransaction {
  final String rawInput;
  final String title;
  final double amount;
  final TransactionType type;
  final String? categoryId;
  final String categoryName;
  final bool isNewCategory;
  final String? bankNameKeyword;
  final double confidence;

  ParsedNlpTransaction({
    required this.rawInput,
    required this.title,
    required this.amount,
    required this.type,
    this.categoryId,
    required this.categoryName,
    this.isNewCategory = false,
    this.bankNameKeyword,
    this.confidence = 0.96,
  });
}

class ThaiSpokenExtractResult {
  final double amount;
  final String matchedExpression;

  const ThaiSpokenExtractResult({required this.amount, required this.matchedExpression});
}

class NlpParserService {
  ParsedNlpTransaction parseThaiSentence(String text, List<CategoryItem> existingCategories) {
    final clean = text.trim();
    final lower = clean.toLowerCase();

    // 1. Amount extraction with Smart Thai Spoken Units & Full Math Expression Support
    final extractResult = _extractThaiSpokenAmount(clean);
    final amount = extractResult.amount;
    final matchedNumberExpression = extractResult.matchedExpression;

    // 2. Comprehensive Type Detection (Income vs Expense)
    TransactionType type = TransactionType.expense;

    final strongIncomeKeywords = [
      'ได้รับเงินเดือน', 'ได้เงินเดือน', 'รับเงินเดือน', 'เงินเดือนออก', 'เงินเดือน',
      'ได้รับเงิน', 'ได้เงิน', 'รับเงิน', 'เงินเข้า', 'เงินโอนเข้า', 'โอนเข้า',
      'ได้ตังค์', 'รับตังค์', 'แม่ให้', 'พ่อให้', 'ยายให้', 'ตาให้', 'พี่ให้', 'แฟนให้',
      'ขายของได้', 'ขายได้', 'ยอดขาย', 'กำไร', 'เงินปันผล', 'ปันผล',
      'โบนัส', 'คืนเงิน', 'ได้รับคืน', 'เบิกเงินได้', 'เบิกงบ',
      'ได้ค่า', 'รับค่า', 'ค่าคอม', 'คอมมิชชั่น', 'ทุน', 'ค่าจ้าง', 'ฟรีแลนซ์',
      'ริซกี', 'รายรับ', 'รายได้', 'รับจ้าง', 'ทิป', 'ถูกรางวัล', 'ถูกหวย', 'เงินคืน'
    ];

    final strongExpenseKeywords = [
      'จ่ายค่า', 'จ่ายเงิน', 'จ่าย', 'ซื้อ', 'ค่า', 'โอนเงินให้', 'โอนให้', 'โอนไป',
      'กิน', 'เติมเงิน', 'เติม', 'ชำระ', 'เสียเงิน', 'เสียค่า', 'หมดไป',
      'บริจาค', 'ทำบุญ', 'ซอดาเกาะฮ์', 'ค่าไฟ', 'ค่าน้ำ', 'ค่าเช่า', 'ค่าเน็ต', 'รายจ่าย'
    ];

    // Check income first
    for (final kw in strongIncomeKeywords) {
      if (lower.contains(kw)) {
        type = TransactionType.income;
        break;
      }
    }

    // If both contain keywords, check which keyword appears first in the sentence
    if (type == TransactionType.income) {
      int firstIncomeIdx = 9999;
      for (final kw in strongIncomeKeywords) {
        final idx = lower.indexOf(kw);
        if (idx != -1 && idx < firstIncomeIdx) firstIncomeIdx = idx;
      }

      int firstExpenseIdx = 9999;
      for (final kw in strongExpenseKeywords) {
        final idx = lower.indexOf(kw);
        if (idx != -1 && idx < firstExpenseIdx) firstExpenseIdx = idx;
      }

      if (firstExpenseIdx < firstIncomeIdx && !lower.contains('เงินเดือน')) {
        type = TransactionType.expense;
      }
    }

    // 3. Match with Existing Categories or Auto-Detect New Category Name
    String? matchedCatId;
    String matchedCatName = type == TransactionType.income ? 'รับเงินโอน / รายได้' : 'รายจ่ายทั่วไป';
    bool isNewCategory = false;

    final targetType = type == TransactionType.income ? CategoryType.income : CategoryType.expense;
    final typeCategories = existingCategories.where((c) => c.type == targetType).toList();

    // Prioritize salary if mentions เงินเดือน
    if (lower.contains('เงินเดือน')) {
      final salaryCat = typeCategories.firstWhere(
        (c) => c.name.contains('เงินเดือน') || c.name.contains('รายได้'),
        orElse: () => CategoryItem(id: 'cat_salary', name: 'เงินเดือน', iconKey: 'payments', colorValue: 0xFF10B981, type: CategoryType.income),
      );
      matchedCatId = salaryCat.id;
      matchedCatName = salaryCat.name;
    } else {
      for (final cat in typeCategories) {
        final catKeywords = cat.name.split(RegExp(r'[\s/&]+'));
        for (final kw in catKeywords) {
          if (kw.length >= 2 && lower.contains(kw.toLowerCase())) {
            matchedCatId = cat.id;
            matchedCatName = cat.name;
            break;
          }
        }
        if (matchedCatId != null) break;
      }
    }

    // If no existing category matched, smartly extract category name from speech
    if (matchedCatId == null) {
      final pattern = RegExp(r'(?:ค่า|ซื้อ|จ่ายค่า|ได้ค่า|รับค่า|ได้รับค่า)\s*([^\s0-9]+)');
      final match = pattern.firstMatch(clean);
      if (match != null && match.group(1) != null) {
        final extracted = match.group(1)!.trim();
        if (extracted.isNotEmpty && extracted.length >= 2) {
          matchedCatName = extracted;
          isNewCategory = true;
        }
      }
    }

    // 4. Bank Account Keyword Detection
    String? bankNameKeyword;
    if (lower.contains('kbank') || lower.contains('กสิกร') || lower.contains('kplus') || lower.contains('k+')) {
      bankNameKeyword = 'KBANK';
    } else if (lower.contains('scb') || lower.contains('ไทยพาณิชย์')) {
      bankNameKeyword = 'SCB';
    } else if (lower.contains('ktb') || lower.contains('กรุงไทย')) {
      bankNameKeyword = 'KTB';
    } else if (lower.contains('paotang') || lower.contains('เป๋าตัง')) {
      bankNameKeyword = 'PAOTANG';
    } else if (lower.contains('truemoney') || lower.contains('ทรูมันนี่')) {
      bankNameKeyword = 'TRUEMONEY';
    } else if (lower.contains('เงินสด') || lower.contains('cash')) {
      bankNameKeyword = 'CASH';
    }

    // 5. Clean Title generation (strip amount and trailing currency terms from title)
    String cleanTitle = clean;
    if (matchedNumberExpression.isNotEmpty) {
      cleanTitle = cleanTitle.replaceAll(matchedNumberExpression, '');
    }
    cleanTitle = cleanTitle
        .replaceAll(RegExp(r'\s*(?:บาท|บ\.|thb)\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*(?:จำนวน|ยอด|เป็นเงิน|ราคา)\s*', caseSensitive: false), '')
        .trim();

    if (cleanTitle.isEmpty) {
      cleanTitle = matchedCatName;
    }

    return ParsedNlpTransaction(
      rawInput: clean,
      title: cleanTitle,
      amount: amount,
      type: type,
      categoryId: matchedCatId,
      categoryName: matchedCatName,
      isNewCategory: isNewCategory,
      bankNameKeyword: bankNameKeyword,
      confidence: 0.96,
    );
  }

  static ThaiSpokenExtractResult _extractThaiSpokenAmount(String input) {
    final clean = input.trim();
    if (clean.isEmpty) return const ThaiSpokenExtractResult(amount: 0.0, matchedExpression: '');

    // 1. Full Math Expression Evaluation (e.g. 20-5, 20 - 5, 20 ลบ 5, 50+30, 100*2, 100/2, 50 บวก 30 ลบ 10)
    final mathResult = _evaluateMathInSentence(clean);
    if (mathResult != null && mathResult.amount > 0) {
      return mathResult;
    }

    // 2. Normalize Thai word digits to Arabic numbers
    final wordMap = {
      'ศูนย์': '0', 'หนึ่ง': '1', 'เอ็ด': '1', 'สอง': '2', 'ยี่': '2',
      'สาม': '3', 'สี่': '4', 'ห้า': '5', 'หก': '6', 'เจ็ด': '7', 'แปด': '8', 'เก้า': '9',
    };

    var normalized = clean;
    wordMap.forEach((w, d) {
      normalized = normalized.replaceAll(w, d);
    });

    // 3. Extract Thai spoken compound units (ล้าน, แสน, หมื่น, พัน, ร้อย, สิบ)
    final unitsRegex = RegExp(
      r'(?:([0-9]+)?\s*ล้าน)?\s*(?:([0-9]+)?\s*แสน)?\s*(?:([0-9]+)?\s*หมื่น)?\s*(?:([0-9]+)?\s*พัน)?\s*(?:([0-9]+)?\s*ร้อย)?\s*(?:([0-9]+)?\s*สิบ)?\s*([0-9]+)?\s*(?:บาท|บ\.|thb)?',
      caseSensitive: false,
    );

    for (final match in unitsRegex.allMatches(normalized)) {
      final fullMatchStr = match.group(0)?.trim() ?? '';
      if (fullMatchStr.isEmpty) continue;

      bool hasAnyUnit = false;
      double sum = 0.0;

      if (fullMatchStr.contains('ล้าน')) {
        final mult = double.tryParse(match.group(1) ?? '1') ?? 1.0;
        sum += mult * 1000000;
        hasAnyUnit = true;
      }
      if (fullMatchStr.contains('แสน')) {
        final mult = double.tryParse(match.group(2) ?? '1') ?? 1.0;
        sum += mult * 100000;
        hasAnyUnit = true;
      }
      if (fullMatchStr.contains('หมื่น')) {
        final mult = double.tryParse(match.group(3) ?? '1') ?? 1.0;
        sum += mult * 10000;
        hasAnyUnit = true;
      }
      if (fullMatchStr.contains('พัน')) {
        final mult = double.tryParse(match.group(4) ?? '1') ?? 1.0;
        sum += mult * 1000;
        hasAnyUnit = true;
      }
      if (fullMatchStr.contains('ร้อย')) {
        final mult = double.tryParse(match.group(5) ?? '1') ?? 1.0;
        sum += mult * 100;
        hasAnyUnit = true;
      }
      if (fullMatchStr.contains('สิบ')) {
        final mult = double.tryParse(match.group(6) ?? '1') ?? 1.0;
        sum += mult * 10;
        hasAnyUnit = true;
      }
      if (hasAnyUnit && match.group(7) != null) {
        final trail = double.tryParse(match.group(7)!) ?? 0.0;
        sum += trail;
      }

      if (hasAnyUnit && sum > 0) {
        return ThaiSpokenExtractResult(amount: sum, matchedExpression: fullMatchStr);
      }
    }

    // 4. Standard comma, decimal and plain numbers (e.g. 10,000 บาท, 10000.50, 60 บาท, 500)
    final standardRegexes = [
      RegExp(r'([0-9,]+(?:\.[0-9]{1,2})?)\s*(?:บาท|บ\.|thb)', caseSensitive: false),
      RegExp(r'(?:จำนวน|ยอด|เป็นเงิน|ราคา)\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
      RegExp(r'\b([0-9]{1,3}(?:,[0-9]{3})+(?:\.[0-9]{1,2})?)\b'),
      RegExp(r'\b([0-9]{1,7}(?:\.[0-9]{1,2})?)\b'),
    ];

    for (final reg in standardRegexes) {
      final match = reg.firstMatch(clean);
      if (match != null && match.group(1) != null) {
        final parsed = double.tryParse(match.group(1)!.replaceAll(',', '').trim());
        if (parsed != null && parsed > 0) {
          return ThaiSpokenExtractResult(amount: parsed, matchedExpression: match.group(0)!);
        }
      }
    }

    return const ThaiSpokenExtractResult(amount: 0.0, matchedExpression: '');
  }

  /// Evaluates arithmetic math expression inside sentence e.g. "20-5", "20 ลบ 5", "50+30", "100*2", "100/2"
  static ThaiSpokenExtractResult? _evaluateMathInSentence(String text) {
    var expr = text;
    // Replace Thai spoken operators with standard symbols
    expr = expr
        .replaceAll('บวก', '+')
        .replaceAll('รวมกับ', '+')
        .replaceAll('และ', '+')
        .replaceAll('ลบ', '-')
        .replaceAll('หัก', '-')
        .replaceAll('ลด', '-')
        .replaceAll('คูณ', '*')
        .replaceAll('หาร', '/');

    // Find contiguous math expression: e.g. 20-5, 20 - 5, 50 + 30 - 10, 100 * 2, 20.5 - 5
    final mathRegex = RegExp(r'([0-9]+(?:\.[0-9]{1,2})?)\s*([\+\-\*\/])\s*([0-9]+(?:\.[0-9]{1,2})?)(?:\s*([\+\-\*\/])\s*([0-9]+(?:\.[0-9]{1,2})?))*');
    final match = mathRegex.firstMatch(expr);
    if (match != null) {
      final matchedStr = match.group(0)!;
      try {
        final tokens = RegExp(r'([0-9]+(?:\.[0-9]{1,2})?|[\+\-\*\/])').allMatches(matchedStr).map((m) => m.group(0)!).toList();
        if (tokens.length >= 3) {
          double result = double.parse(tokens[0]);
          for (int i = 1; i < tokens.length; i += 2) {
            if (i + 1 >= tokens.length) break;
            final op = tokens[i];
            final nextVal = double.parse(tokens[i + 1]);
            if (op == '+') {
              result += nextVal;
            } else if (op == '-') {
              result -= nextVal;
            } else if (op == '*') {
              result *= nextVal;
            } else if (op == '/') {
              if (nextVal != 0) result /= nextVal;
            }
          }
          if (result > 0) {
            return ThaiSpokenExtractResult(amount: result, matchedExpression: match.group(0)!);
          }
        }
      } catch (_) {}
    }
    return null;
  }
}
