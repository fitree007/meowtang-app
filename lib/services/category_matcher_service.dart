import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/category_item.dart';
import '../state/expense_controller.dart';
import 'storage_service.dart';

class KeywordRule {
  final String id;
  final String keyword;
  final String categoryName;
  final bool isDefault;

  const KeywordRule({
    required this.id,
    required this.keyword,
    required this.categoryName,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'keyword': keyword,
        'categoryName': categoryName,
        'isDefault': isDefault,
      };

  factory KeywordRule.fromJson(Map<String, dynamic> json) => KeywordRule(
        id: json['id'] as String,
        keyword: json['keyword'] as String,
        categoryName: json['categoryName'] as String,
        isDefault: json['isDefault'] as bool? ?? false,
      );
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

    // Food & Dining
    KeywordRule(id: 'def_7', keyword: 'cp all', categoryName: 'อาหาร & เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_8', keyword: '7-eleven', categoryName: 'อาหาร & เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_9', keyword: 'เซเว่น', categoryName: 'อาหาร & เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_10', keyword: 'grabfood', categoryName: 'อาหาร & เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_11', keyword: 'lineman', categoryName: 'อาหาร & เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_12', keyword: 'foodpanda', categoryName: 'อาหาร & เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_13', keyword: 'kfc', categoryName: 'อาหาร & เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_14', keyword: 'amazon cafe', categoryName: 'อาหาร & เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_15', keyword: 'starbucks', categoryName: 'อาหาร & เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_16', keyword: 'สุกี้ตี๋น้อย', categoryName: 'อาหาร & เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_16_1', keyword: 'ค่าข้าว', categoryName: 'อาหาร & เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_16_2', keyword: 'ค่าอาหาร', categoryName: 'อาหาร & เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_16_3', keyword: 'กาแฟ', categoryName: 'อาหาร & เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_16_4', keyword: 'ชาบู', categoryName: 'อาหาร & เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_16_5', keyword: 'หมูกระทะ', categoryName: 'อาหาร & เครื่องดื่ม', isDefault: true),

    // Transport & Gas
    KeywordRule(id: 'def_17', keyword: 'ptt', categoryName: 'เดินทาง & น้ำมัน', isDefault: true),
    KeywordRule(id: 'def_18', keyword: 'ปตท', categoryName: 'เดินทาง & น้ำมัน', isDefault: true),
    KeywordRule(id: 'def_19', keyword: 'bangchak', categoryName: 'เดินทาง & น้ำมัน', isDefault: true),
    KeywordRule(id: 'def_20', keyword: 'บางจาก', categoryName: 'เดินทาง & น้ำมัน', isDefault: true),
    KeywordRule(id: 'def_21', keyword: 'shell', categoryName: 'เดินทาง & น้ำมัน', isDefault: true),
    KeywordRule(id: 'def_22', keyword: 'caltex', categoryName: 'เดินทาง & น้ำมัน', isDefault: true),
    KeywordRule(id: 'def_23', keyword: 'pt station', categoryName: 'เดินทาง & น้ำมัน', isDefault: true),
    KeywordRule(id: 'def_24', keyword: 'ทางด่วน', categoryName: 'เดินทาง & น้ำมัน', isDefault: true),
    KeywordRule(id: 'def_25', keyword: 'bts', categoryName: 'เดินทาง & น้ำมัน', isDefault: true),
    KeywordRule(id: 'def_26', keyword: 'mrt', categoryName: 'เดินทาง & น้ำมัน', isDefault: true),
    KeywordRule(id: 'def_26_1', keyword: 'ค่าน้ำมัน', categoryName: 'เดินทาง & น้ำมัน', isDefault: true),
    KeywordRule(id: 'def_26_2', keyword: 'ค่ารถ', categoryName: 'เดินทาง & น้ำมัน', isDefault: true),

    // Bills & Utilities
    KeywordRule(id: 'def_27', keyword: 'การไฟฟ้านครหลวง', categoryName: 'บิลค่าน้ำค่าไฟ & ค่าเน็ต', isDefault: true),
    KeywordRule(id: 'def_28', keyword: 'การไฟฟ้าส่วนภูมิภาค', categoryName: 'บิลค่าน้ำค่าไฟ & ค่าเน็ต', isDefault: true),
    KeywordRule(id: 'def_29', keyword: 'การประปา', categoryName: 'บิลค่าน้ำค่าไฟ & ค่าเน็ต', isDefault: true),
    KeywordRule(id: 'def_30', keyword: 'ais', categoryName: 'บิลค่าน้ำค่าไฟ & ค่าเน็ต', isDefault: true),
    KeywordRule(id: 'def_31', keyword: 'true corporation', categoryName: 'บิลค่าน้ำค่าไฟ & ค่าเน็ต', isDefault: true),
    KeywordRule(id: 'def_32', keyword: 'dtac', categoryName: 'บิลค่าน้ำค่าไฟ & ค่าเน็ต', isDefault: true),
    KeywordRule(id: 'def_33', keyword: '3bb', categoryName: 'บิลค่าน้ำค่าไฟ & ค่าเน็ต', isDefault: true),
    KeywordRule(id: 'def_33_1', keyword: 'ค่าไฟ', categoryName: 'บิลค่าน้ำค่าไฟ & ค่าเน็ต', isDefault: true),
    KeywordRule(id: 'def_33_2', keyword: 'ค่าน้ำ', categoryName: 'บิลค่าน้ำค่าไฟ & ค่าเน็ต', isDefault: true),
    KeywordRule(id: 'def_33_3', keyword: 'ค่าเน็ต', categoryName: 'บิลค่าน้ำค่าไฟ & ค่าเน็ต', isDefault: true),

    // Charity / Zakat
    KeywordRule(id: 'def_34', keyword: 'บริจาค', categoryName: 'บริจาค & ทำบุญ (เศาะดะเกาะฮ์)', isDefault: true),
    KeywordRule(id: 'def_35', keyword: 'มัสยิด', categoryName: 'บริจาค & ทำบุญ (เศาะดะเกาะฮ์)', isDefault: true),
    KeywordRule(id: 'def_36', keyword: 'มูลนิธิ', categoryName: 'บริจาค & ทำบุญ (เศาะดะเกาะฮ์)', isDefault: true),
    KeywordRule(id: 'def_37', keyword: 'ซะกาต', categoryName: 'บริจาค & ทำบุญ (เศาะดะเกาะฮ์)', isDefault: true),
    KeywordRule(id: 'def_38', keyword: 'เศาะดะเกาะฮ์', categoryName: 'บริจาค & ทำบุญ (เศาะดะเกาะฮ์)', isDefault: true),
    KeywordRule(id: 'def_39', keyword: 'ทำบุญ', categoryName: 'บริจาค & ทำบุญ (เศาะดะเกาะฮ์)', isDefault: true),

    // Housing / Rent
    KeywordRule(id: 'def_40', keyword: 'ค่าห้อง', categoryName: 'ที่พัก & ค่าเช่า', isDefault: true),
    KeywordRule(id: 'def_41', keyword: 'ค่าหอ', categoryName: 'ที่พัก & ค่าเช่า', isDefault: true),
    KeywordRule(id: 'def_42', keyword: 'ค่าเช่า', categoryName: 'ที่พัก & ค่าเช่า', isDefault: true),

    // Education
    KeywordRule(id: 'def_43', keyword: 'ค่าเทอม', categoryName: 'การศึกษา & ความรู้', isDefault: true),
    KeywordRule(id: 'def_44', keyword: 'ค่าเรียน', categoryName: 'การศึกษา & ความรู้', isDefault: true),

    // Health
    KeywordRule(id: 'def_45', keyword: 'ค่ายา', categoryName: 'สุขภาพ & ยารักษา', isDefault: true),
    KeywordRule(id: 'def_46', keyword: 'คลินิก', categoryName: 'สุขภาพ & ยารักษา', isDefault: true),
    KeywordRule(id: 'def_47', keyword: 'โรงพยาบาล', categoryName: 'สุขภาพ & ยารักษา', isDefault: true),

    // Government Aid & Welfare (ไทยช่วยไทย / เป๋าตัง)
    KeywordRule(id: 'def_48', keyword: 'ไทยช่วยไทย', categoryName: 'รายรับอื่นๆ', isDefault: true),
    KeywordRule(id: 'def_49', keyword: 'คนละครึ่ง', categoryName: 'อาหาร & เครื่องดื่ม', isDefault: true),
    KeywordRule(id: 'def_50', keyword: 'เราชนะ', categoryName: 'ช้อปปิ้ง & ของใช้', isDefault: true),
    KeywordRule(id: 'def_51', keyword: 'สวัสดิการแห่งรัฐ', categoryName: 'รายรับอื่นๆ', isDefault: true),
    KeywordRule(id: 'def_52', keyword: 'เงินช่วยเหลือ', categoryName: 'รายรับอื่นๆ', isDefault: true),
  ];

  static CategoryItem matchCategory({
    required String text,
    required List<CategoryItem> availableCategories,
    List<KeywordRule> customRules = const [],
    CategoryItem? fallbackCategory,
  }) {
    final lower = text.toLowerCase();

    // 1. Check custom user rules first
    for (final rule in customRules) {
      if (lower.contains(rule.keyword.toLowerCase())) {
        final found = availableCategories.firstWhere(
          (c) => c.name.toLowerCase().contains(rule.categoryName.toLowerCase()),
          orElse: () => fallbackCategory ?? availableCategories.first,
        );
        return found;
      }
    }

    // 2. Check default built-in rules
    for (final rule in defaultRules) {
      if (lower.contains(rule.keyword.toLowerCase())) {
        final found = availableCategories.firstWhere(
          (c) => c.name.toLowerCase().contains(rule.categoryName.toLowerCase()),
          orElse: () => fallbackCategory ?? availableCategories.first,
        );
        return found;
      }
    }

    // 3. Direct category name partial match
    for (final cat in availableCategories) {
      final catNameClean = cat.name.replaceAll(RegExp(r'[^\u0E00-\u0E7Fa-zA-Z0-9]'), '').toLowerCase();
      if (catNameClean.length >= 3 && lower.contains(catNameClean)) {
        return cat;
      }
    }

    // 4. Fallback
    return fallbackCategory ?? (availableCategories.isNotEmpty ? availableCategories.first : CategoryItem(
      id: 'cat_other',
      name: 'ทั่วไป',
      iconKey: 'category',
      colorValue: 0xFFF59E0B,
      type: CategoryType.expense,
    ));
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
