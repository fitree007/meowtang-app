import '../models/category_item.dart';
import '../state/expense_controller.dart';

class KeywordRule {
  final String id;
  final String keyword;
  final String categoryName;
  final String? categoryId;
  final String? tag;
  final bool isDefault;

  const KeywordRule({
    required this.id,
    required this.keyword,
    required this.categoryName,
    this.categoryId,
    this.tag,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'keyword': keyword,
        'categoryName': categoryName,
        if (categoryId != null) 'categoryId': categoryId,
        if (tag != null) 'tag': tag,
        'isDefault': isDefault,
      };

  factory KeywordRule.fromJson(Map<String, dynamic> json) => KeywordRule(
        id: json['id'] as String? ?? 'rule_${DateTime.now().millisecondsSinceEpoch}',
        keyword: json['keyword'] as String? ?? '',
        categoryName: json['categoryName'] as String? ?? 'ทั่วไป',
        categoryId: json['categoryId'] as String?,
        tag: json['tag'] as String?,
        isDefault: json['isDefault'] as bool? ?? false,
      );
}

class CategoryMatchResult {
  final CategoryItem category;
  final String? tag;
  final KeywordRule? matchedRule;

  const CategoryMatchResult({
    required this.category,
    this.tag,
    this.matchedRule,
  });
}

class CategoryMatcherService {
  static const List<KeywordRule> defaultRules = [
    // Shopping & E-Commerce
    KeywordRule(id: 'def_1', keyword: 'shopee', categoryName: 'ช้อปปิ้ง & ของใช้', isDefault: true),
    KeywordRule(id: 'def_2', keyword: 'lazada', categoryName: 'ช้อปปิ้ง & ของใช้', isDefault: true),
    KeywordRule(id: 'def_3', keyword: 'tiktok shop', categoryName: 'ช้อปปิ้ง & ของใช้', isDefault: true),
    KeywordRule(id: 'def_4', keyword: 'big c', categoryName: 'ช้อปปิ้ง & ของใช้', isDefault: true),
    KeywordRule(id: 'def_5', keyword: 'lotus', categoryName: 'ช้อปปิ้ง & ของใช้', isDefault: true),
    KeywordRule(id: 'def_6', keyword: 'cj express', categoryName: 'ช้อปปิ้ง & ของใช้', isDefault: true),
    KeywordRule(id: 'def_6_1', keyword: 'สั่งของ', categoryName: 'ช้อปปิ้ง & ของใช้', isDefault: true),
    KeywordRule(id: 'def_6_2', keyword: 'ของใช้', categoryName: 'ช้อปปิ้ง & ของใช้', isDefault: true),

    // Drinks & Beverage (เครื่องดื่ม / นม / กาแฟ / ชา)
    KeywordRule(id: 'def_drink_1', keyword: 'นม', categoryName: 'เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_drink_2', keyword: 'ชานม', categoryName: 'เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_drink_3', keyword: 'กาแฟ', categoryName: 'เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_drink_4', keyword: 'ชา', categoryName: 'เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_drink_5', keyword: 'น้ำเปล่า', categoryName: 'เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_drink_6', keyword: 'น้ำดื่ม', categoryName: 'เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_drink_7', keyword: 'น้ำอัดลม', categoryName: 'เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_drink_8', keyword: 'โกโก้', categoryName: 'เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_drink_9', keyword: 'น้ำผลไม้', categoryName: 'เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_drink_10', keyword: 'ชาตรามือ', categoryName: 'เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_drink_11', keyword: 'cafe amazon', categoryName: 'เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_drink_12', keyword: 'amazon cafe', categoryName: 'เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_drink_13', keyword: 'starbucks', categoryName: 'เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_drink_14', keyword: 'เต่าบิน', categoryName: 'เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_drink_15', keyword: 'all cafe', categoryName: 'เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_drink_16', keyword: 'ค่าน้ำดื่ม', categoryName: 'เครื่องดื่ม', isDefault: true),

    // Food & Dining
    KeywordRule(id: 'def_7', keyword: 'cp all', categoryName: 'อาหาร', isDefault: true),
    KeywordRule(id: 'def_8', keyword: '7-eleven', categoryName: 'อาหาร', isDefault: true),
    KeywordRule(id: 'def_9', keyword: 'เซเว่น', categoryName: 'อาหาร', isDefault: true),
    KeywordRule(id: 'def_10', keyword: 'grabfood', categoryName: 'อาหาร', isDefault: true),
    KeywordRule(id: 'def_11', keyword: 'lineman', categoryName: 'อาหาร', isDefault: true),
    KeywordRule(id: 'def_12', keyword: 'foodpanda', categoryName: 'อาหาร', isDefault: true),
    KeywordRule(id: 'def_13', keyword: 'kfc', categoryName: 'อาหาร', isDefault: true),
    KeywordRule(id: 'def_16', keyword: 'สุกี้ตี๋น้อย', categoryName: 'อาหาร', isDefault: true),
    KeywordRule(id: 'def_16_1', keyword: 'ค่าข้าว', categoryName: 'อาหาร', isDefault: true),
    KeywordRule(id: 'def_16_2', keyword: 'ค่าอาหาร', categoryName: 'อาหาร', isDefault: true),
    KeywordRule(id: 'def_16_4', keyword: 'ชาบู', categoryName: 'อาหาร', isDefault: true),
    KeywordRule(id: 'def_16_5', keyword: 'หมูกระทะ', categoryName: 'อาหาร', isDefault: true),
    KeywordRule(id: 'def_16_6', keyword: 'ข้าวแกง', categoryName: 'อาหาร', isDefault: true),
    KeywordRule(id: 'def_16_7', keyword: 'ก๋วยเตี๋ยว', categoryName: 'อาหาร', isDefault: true),

    // Transport & Gas
    KeywordRule(id: 'def_17', keyword: 'ptt', categoryName: 'ค่าน้ำมัน', isDefault: true),
    KeywordRule(id: 'def_18', keyword: 'ปตท', categoryName: 'ค่าน้ำมัน', isDefault: true),
    KeywordRule(id: 'def_19', keyword: 'bangchak', categoryName: 'ค่าน้ำมัน', isDefault: true),
    KeywordRule(id: 'def_20', keyword: 'บางจาก', categoryName: 'ค่าน้ำมัน', isDefault: true),
    KeywordRule(id: 'def_21', keyword: 'shell', categoryName: 'ค่าน้ำมัน', isDefault: true),
    KeywordRule(id: 'def_22', keyword: 'caltex', categoryName: 'ค่าน้ำมัน', isDefault: true),
    KeywordRule(id: 'def_23', keyword: 'pt station', categoryName: 'ค่าน้ำมัน', isDefault: true),
    KeywordRule(id: 'def_24', keyword: 'ทางด่วน', categoryName: 'ค่าเดินทาง', isDefault: true),
    KeywordRule(id: 'def_25', keyword: 'bts', categoryName: 'ค่าเดินทาง', isDefault: true),
    KeywordRule(id: 'def_26', keyword: 'mrt', categoryName: 'ค่าเดินทาง', isDefault: true),
    KeywordRule(id: 'def_26_1', keyword: 'ค่าน้ำมัน', categoryName: 'ค่าน้ำมัน', isDefault: true),
    KeywordRule(id: 'def_26_2', keyword: 'ค่ารถ', categoryName: 'ค่าเดินทาง', isDefault: true),

    // Bills & Utilities
    KeywordRule(id: 'def_27', keyword: 'การไฟฟ้านครหลวง', categoryName: 'ค่าไฟ', isDefault: true),
    KeywordRule(id: 'def_28', keyword: 'การไฟฟ้าส่วนภูมิภาค', categoryName: 'ค่าไฟ', isDefault: true),
    KeywordRule(id: 'def_29', keyword: 'การประปา', categoryName: 'ค่าน้ำ', isDefault: true),
    KeywordRule(id: 'def_30', keyword: 'ais', categoryName: 'ค่าเน็ต', isDefault: true),
    KeywordRule(id: 'def_31', keyword: 'true corporation', categoryName: 'ค่าเน็ต', isDefault: true),
    KeywordRule(id: 'def_32', keyword: 'dtac', categoryName: 'ค่าเน็ต', isDefault: true),
    KeywordRule(id: 'def_33', keyword: '3bb', categoryName: 'ค่าเน็ต', isDefault: true),
    KeywordRule(id: 'def_33_1', keyword: 'ค่าไฟ', categoryName: 'ค่าไฟ', isDefault: true),
    KeywordRule(id: 'def_33_2', keyword: 'ค่าน้ำ', categoryName: 'ค่าน้ำ', isDefault: true),
    KeywordRule(id: 'def_33_3', keyword: 'ค่าเน็ต', categoryName: 'ค่าเน็ต', isDefault: true),

    // Charity / Zakat
    KeywordRule(id: 'def_34', keyword: 'บริจาค', categoryName: 'บริจาค & ทำบุญ (เศาะดะเกาะฮ์)', isDefault: true),
    KeywordRule(id: 'def_35', keyword: 'มัสยิด', categoryName: 'บริจาค & ทำบุญ (เศาะดะเกาะฮ์)', isDefault: true),
    KeywordRule(id: 'def_36', keyword: 'มูลนิธิ', categoryName: 'บริจาค & ทำบุญ (เศาะดะเกาะฮ์)', isDefault: true),
    KeywordRule(id: 'def_37', keyword: 'ซะกาต', categoryName: 'บริจาค & ทำบุญ (เศาะดะเกาะฮ์)', isDefault: true),
    KeywordRule(id: 'def_38', keyword: 'เศาะดะเกาะฮ์', categoryName: 'บริจาค & ทำบุญ (เศาะดะเกาะฮ์)', isDefault: true),
    KeywordRule(id: 'def_39', keyword: 'ทำบุญ', categoryName: 'บริจาค & ทำบุญ (เศาะดะเกาะฮ์)', isDefault: true),

    // Housing / Rent
    KeywordRule(id: 'def_40', keyword: 'ค่าห้อง', categoryName: 'ค่าเช่า', isDefault: true),
    KeywordRule(id: 'def_41', keyword: 'ค่าหอ', categoryName: 'ค่าเช่า', isDefault: true),
    KeywordRule(id: 'def_42', keyword: 'ค่าเช่า', categoryName: 'ค่าเช่า', isDefault: true),

    // Education
    KeywordRule(id: 'def_43', keyword: 'ค่าเทอม', categoryName: 'การศึกษา', isDefault: true),
    KeywordRule(id: 'def_44', keyword: 'ค่าเรียน', categoryName: 'การศึกษา', isDefault: true),

    // Health
    KeywordRule(id: 'def_45', keyword: 'ค่ายา', categoryName: 'สุขภาพ & ยารักษา', isDefault: true),
    KeywordRule(id: 'def_46', keyword: 'คลินิก', categoryName: 'สุขภาพ & ยารักษา', isDefault: true),
    KeywordRule(id: 'def_47', keyword: 'โรงพยาบาล', categoryName: 'สุขภาพ & ยารักษา', isDefault: true),

    // Government Aid & Welfare
    KeywordRule(id: 'def_48', keyword: 'ไทยช่วยไทย', categoryName: 'รายรับอื่นๆ', isDefault: true),
    KeywordRule(id: 'def_49', keyword: 'คนละครึ่ง', categoryName: 'อาหาร', isDefault: true),
    KeywordRule(id: 'def_50', keyword: 'เราชนะ', categoryName: 'ช้อปปิ้ง & ของใช้', isDefault: true),
    KeywordRule(id: 'def_51', keyword: 'สวัสดิการแห่งรัฐ', categoryName: 'รายรับอื่นๆ', isDefault: true),
    KeywordRule(id: 'def_52', keyword: 'เงินช่วยเหลือ', categoryName: 'รายรับอื่นๆ', isDefault: true),
  ];

  /// Smart Category Finder that maps targetName / targetId into availableCategories
  static CategoryItem? _findCategory(
    String targetName,
    List<CategoryItem> availableCategories, {
    String? targetId,
  }) {
    if (availableCategories.isEmpty) return null;

    // 1. By ID exact match
    if (targetId != null && targetId.isNotEmpty) {
      final byId = availableCategories.where((c) => c.id == targetId);
      if (byId.isNotEmpty) return byId.first;
    }

    final targetLower = targetName.trim().toLowerCase();
    if (targetLower.isEmpty) return null;

    // 2. Exact Name match
    for (final c in availableCategories) {
      if (c.name.trim().toLowerCase() == targetLower) return c;
    }

    // 3. Specialized semantic mappings for common defaults
    // Drink
    if (targetLower.contains('เครื่องดื่ม') || targetLower == 'นม' || targetLower == 'กาแฟ' || targetLower == 'ชา') {
      final drink = availableCategories.where((c) => c.name.toLowerCase().contains('เครื่องดื่ม'));
      if (drink.isNotEmpty) return drink.first;
      final foodAndDrink = availableCategories.where((c) => c.name.toLowerCase().contains('อาหาร & เครื่องดื่ม'));
      if (foodAndDrink.isNotEmpty) return foodAndDrink.first;
      final food = availableCategories.where((c) => c.name.toLowerCase().contains('อาหาร'));
      if (food.isNotEmpty) return food.first;
    }
    // Food
    if (targetLower.contains('อาหาร')) {
      final food = availableCategories.where((c) => c.name.toLowerCase().contains('อาหาร'));
      if (food.isNotEmpty) return food.first;
    }
    // Transport & Gas
    if (targetLower.contains('น้ำมัน') || targetLower.contains('เดินทาง')) {
      final gas = availableCategories.where((c) => c.name.toLowerCase().contains('น้ำมัน'));
      if (gas.isNotEmpty) return gas.first;
      final commute = availableCategories.where((c) => c.name.toLowerCase().contains('เดินทาง') || c.name.toLowerCase().contains('รถ'));
      if (commute.isNotEmpty) return commute.first;
    }
    // Utilities / Bills
    if (targetLower.contains('ค่าไฟ') || targetLower.contains('ไฟฟ้า')) {
      final elec = availableCategories.where((c) => c.name.toLowerCase().contains('ไฟ'));
      if (elec.isNotEmpty) return elec.first;
    }
    if (targetLower.contains('ค่าน้ำ') || targetLower.contains('ประปา')) {
      final water = availableCategories.where((c) => c.name.toLowerCase().contains('น้ำ') && !c.name.toLowerCase().contains('มัน'));
      if (water.isNotEmpty) return water.first;
    }
    if (targetLower.contains('เน็ต') || targetLower.contains('โทรศัพท์')) {
      final net = availableCategories.where((c) => c.name.toLowerCase().contains('เน็ต') || c.name.toLowerCase().contains('โทร'));
      if (net.isNotEmpty) return net.first;
    }
    // Rent / Housing
    if (targetLower.contains('เช่า') || targetLower.contains('หอ') || targetLower.contains('ห้อง')) {
      final rent = availableCategories.where((c) => c.name.toLowerCase().contains('เช่า') || c.name.toLowerCase().contains('หอ'));
      if (rent.isNotEmpty) return rent.first;
    }

    // 4. Substring match (bidirectional)
    for (final c in availableCategories) {
      final cLower = c.name.trim().toLowerCase();
      if (cLower.contains(targetLower) || targetLower.contains(cLower)) {
        return c;
      }
    }

    return null;
  }

  /// Matches text against custom and default rules, returning the category, optional tag, and matched rule
  static CategoryMatchResult matchCategoryWithResult({
    required String text,
    required List<CategoryItem> availableCategories,
    List<KeywordRule> customRules = const [],
    CategoryItem? fallbackCategory,
  }) {
    final lower = text.toLowerCase();

    // 1. Check custom user rules first
    for (final rule in customRules) {
      final kw = rule.keyword.trim().toLowerCase();
      if (kw.isNotEmpty && lower.contains(kw)) {
        final found = _findCategory(
          rule.categoryName,
          availableCategories,
          targetId: rule.categoryId,
        );
        if (found != null) {
          return CategoryMatchResult(
            category: found,
            tag: (rule.tag != null && rule.tag!.trim().isNotEmpty) ? rule.tag!.trim() : null,
            matchedRule: rule,
          );
        }
      }
    }

    // 2. Check default built-in rules
    for (final rule in defaultRules) {
      final kw = rule.keyword.trim().toLowerCase();
      if (kw.isNotEmpty && lower.contains(kw)) {
        final found = _findCategory(
          rule.categoryName,
          availableCategories,
          targetId: rule.categoryId,
        );
        if (found != null) {
          return CategoryMatchResult(
            category: found,
            matchedRule: rule,
          );
        }
      }
    }

    // 3. Direct category name match from text
    for (final cat in availableCategories) {
      final catNameClean = cat.name.replaceAll(RegExp(r'[^\u0E00-\u0E7Fa-zA-Z0-9]'), '').toLowerCase();
      if (catNameClean.length >= 2 && lower.contains(catNameClean)) {
        return CategoryMatchResult(category: cat);
      }
    }

    // 4. Fallback
    final fallback = fallbackCategory ?? (availableCategories.isNotEmpty ? availableCategories.first : CategoryItem(
      id: 'cat_other',
      name: 'ทั่วไป',
      iconKey: 'category',
      colorValue: 0xFFF59E0B,
      type: CategoryType.expense,
    ));

    return CategoryMatchResult(category: fallback);
  }

  /// Backward-compatible wrapper returning only CategoryItem
  static CategoryItem matchCategory({
    required String text,
    required List<CategoryItem> availableCategories,
    List<KeywordRule> customRules = const [],
    CategoryItem? fallbackCategory,
  }) {
    return matchCategoryWithResult(
      text: text,
      availableCategories: availableCategories,
      customRules: customRules,
      fallbackCategory: fallbackCategory,
    ).category;
  }

  /// Smartly analyzes note/memo and automatically creates a new CategoryItem if no matching category is found
  static Future<CategoryItem> matchOrAutoCreateCategory({
    required String noteOrMemo,
    required String recipientOrMerchant,
    required ExpenseController controller,
    required CategoryType type,
    CategoryItem? fallbackCategory,
  }) async {
    final availableCategories = controller.categories.where((c) => c.type == type).toList();
    final combinedText = '$noteOrMemo $recipientOrMerchant';

    final matched = matchCategory(
      text: combinedText,
      availableCategories: availableCategories,
      customRules: const [],
      fallbackCategory: fallbackCategory,
    );

    // If matched category is NOT generic fallback, return it directly
    if (matched != fallbackCategory) {
      return matched;
    }

    // If memo/note has a specific meaningful topic, auto-create a category!
    final cleanNote = noteOrMemo.trim().replaceAll(RegExp(r'^(?:บันทึกช่วยจำ|บันทึก|หมายเหตุ|Memo|Note)[:\s]*', caseSensitive: false), '');
    if (cleanNote.length >= 2 && cleanNote.length <= 25 && !cleanNote.contains('http') && !cleanNote.contains('ref:')) {
      final existingCat = availableCategories.firstWhere(
        (c) => c.name.trim().toLowerCase() == cleanNote.toLowerCase(),
        orElse: () => CategoryItem(id: '', name: '', iconKey: '', colorValue: 0, type: type),
      );

      if (existingCat.id.isNotEmpty) {
        return existingCat;
      }

      // Smart icon selection based on note
      String iconKey = 'category';
      int colorValue = type == CategoryType.income ? 0xFF10B981 : 0xFFF59E0B;
      final lowerNote = cleanNote.toLowerCase();

      if (lowerNote.contains('ข้าว') || lowerNote.contains('อาหาร') || lowerNote.contains('กิน') || lowerNote.contains('กาแฟ') || lowerNote.contains('ชา')) {
        iconKey = 'restaurant';
        colorValue = 0xFFF97316;
      } else if (lowerNote.contains('น้ำมัน') || lowerNote.contains('รถ') || lowerNote.contains('เดินทาง')) {
        iconKey = 'local_gas_station';
        colorValue = 0xFF3B82F6;
      } else if (lowerNote.contains('ซื้อ') || lowerNote.contains('ช้อป') || lowerNote.contains('ของใช้')) {
        iconKey = 'shopping_cart';
        colorValue = 0xFFEC4899;
      } else if (lowerNote.contains('หอ') || lowerNote.contains('ห้อง') || lowerNote.contains('บ้าน') || lowerNote.contains('เช่า')) {
        iconKey = 'home';
        colorValue = 0xFF8B5CF6;
      } else if (lowerNote.contains('ยา') || lowerNote.contains('หมอ') || lowerNote.contains('ตรวจ') || lowerNote.contains('รักษา')) {
        iconKey = 'medical_services';
        colorValue = 0xFFEF4444;
      } else if (lowerNote.contains('เรียน') || lowerNote.contains('เทอม') || lowerNote.contains('หนังสือ') || lowerNote.contains('สอบ')) {
        iconKey = 'school';
        colorValue = 0xFF6366F1;
      } else if (lowerNote.contains('แมว') || lowerNote.contains('หมา') || lowerNote.contains('สัตว์เลี้ยง')) {
        iconKey = 'pets';
        colorValue = 0xFF14B8A6;
      } else if (lowerNote.contains('ทำบุญ') || lowerNote.contains('บริจาค') || lowerNote.contains('ซะกาต')) {
        iconKey = 'volunteer_activism';
        colorValue = 0xFF10B981;
      }

      final newCat = CategoryItem(
        id: 'cat_auto_${DateTime.now().millisecondsSinceEpoch}',
        name: cleanNote,
        iconKey: iconKey,
        colorValue: colorValue,
        type: type,
      );

      await controller.addCategory(newCat);
      return newCat;
    }

    return fallbackCategory ?? matched;
  }
}
