import 'dart:convert';
import 'package:flutter/material.dart';

class SubscriptionItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final String currency; // 'THB', 'USD', 'JPY', 'EUR', etc.
  final String billingCycle; // 'monthly', 'yearly', 'weekly', 'quarterly'
  final DateTime firstChargeDate;
  final DateTime nextBillingDate;
  final bool hasTrial;
  final DateTime? trialEndDate;
  final String paymentMethod; // e.g., 'KBank ••1234', 'บัตรเครดิต', 'TrueMoney'
  final String? logoAssetPath; // e.g. 'assets/icons/subscriptions/netflix.png'
  final String? logoUrl;
  final int reminderDaysBefore; // default 3 days
  final String? notes;
  final bool isActive;
  final Color? customColor;

  SubscriptionItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.currency = 'THB',
    this.billingCycle = 'monthly',
    required this.firstChargeDate,
    required this.nextBillingDate,
    this.hasTrial = false,
    this.trialEndDate,
    this.paymentMethod = 'บัตรเครดิต/เดบิต',
    this.logoAssetPath,
    this.logoUrl,
    this.reminderDaysBefore = 3,
    this.notes,
    this.isActive = true,
    this.customColor,
  });

  /// Normalize cost to monthly amount
  double get monthlyCost {
    switch (billingCycle) {
      case 'yearly':
        return price / 12.0;
      case 'weekly':
        return price * 4.333;
      case 'quarterly':
        return price / 3.0;
      case 'monthly':
      default:
        return price;
    }
  }

  /// Normalize cost to annual amount
  double get yearlyCost {
    switch (billingCycle) {
      case 'yearly':
        return price;
      case 'weekly':
        return price * 52.0;
      case 'quarterly':
        return price * 4.0;
      case 'monthly':
      default:
        return price * 12.0;
    }
  }

  int get daysUntilNextBilling {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(nextBillingDate.year, nextBillingDate.month, nextBillingDate.day);
    return target.difference(today).inDays;
  }

  int? get daysUntilTrialEnds {
    if (!hasTrial || trialEndDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(trialEndDate!.year, trialEndDate!.month, trialEndDate!.day);
    return target.difference(today).inDays;
  }

  bool get isTrialExpiringSoon {
    final days = daysUntilTrialEnds;
    return days != null && days >= 0 && days <= 3;
  }

  bool get isDueSoon {
    final days = daysUntilNextBilling;
    return days >= 0 && days <= 3;
  }

  SubscriptionItem copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    String? currency,
    String? billingCycle,
    DateTime? firstChargeDate,
    DateTime? nextBillingDate,
    bool? hasTrial,
    DateTime? trialEndDate,
    String? paymentMethod,
    String? logoAssetPath,
    String? logoUrl,
    int? reminderDaysBefore,
    String? notes,
    bool? isActive,
    Color? customColor,
  }) {
    return SubscriptionItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      billingCycle: billingCycle ?? this.billingCycle,
      firstChargeDate: firstChargeDate ?? this.firstChargeDate,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      hasTrial: hasTrial ?? this.hasTrial,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      logoAssetPath: logoAssetPath ?? this.logoAssetPath,
      logoUrl: logoUrl ?? this.logoUrl,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      customColor: customColor ?? this.customColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'currency': currency,
      'billingCycle': billingCycle,
      'firstChargeDate': firstChargeDate.toIso8601String(),
      'nextBillingDate': nextBillingDate.toIso8601String(),
      'hasTrial': hasTrial,
      'trialEndDate': trialEndDate?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'logoAssetPath': logoAssetPath,
      'logoUrl': logoUrl,
      'reminderDaysBefore': reminderDaysBefore,
      'notes': notes,
      'isActive': isActive,
      'customColor': customColor?.value,
    };
  }

  factory SubscriptionItem.fromJson(Map<String, dynamic> json) {
    return SubscriptionItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'สตรีมมิ่ง',
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'THB',
      billingCycle: json['billingCycle'] as String? ?? 'monthly',
      firstChargeDate: DateTime.parse(json['firstChargeDate'] as String),
      nextBillingDate: DateTime.parse(json['nextBillingDate'] as String),
      hasTrial: json['hasTrial'] as bool? ?? false,
      trialEndDate: json['trialEndDate'] != null ? DateTime.parse(json['trialEndDate'] as String) : null,
      paymentMethod: json['paymentMethod'] as String? ?? 'บัตรเครดิต/เดบิต',
      logoAssetPath: json['logoAssetPath'] as String?,
      logoUrl: json['logoUrl'] as String?,
      reminderDaysBefore: json['reminderDaysBefore'] as int? ?? 3,
      notes: json['notes'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      customColor: json['customColor'] != null ? Color(json['customColor'] as int) : null,
    );
  }

  static String encodeList(List<SubscriptionItem> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<SubscriptionItem> decodeList(String jsonStr) {
    if (jsonStr.isEmpty) return [];
    try {
      final decoded = jsonDecode(jsonStr) as List<dynamic>;
      return decoded.map((e) => SubscriptionItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}

/// Authentic preset subscriptions with real brand logos and typical default pricing
class SubscriptionPreset {
  final String name;
  final String category;
  final double defaultPrice;
  final String currency;
  final String billingCycle;
  final String logoAssetPath;
  final Color brandColor;

  const SubscriptionPreset({
    required this.name,
    required this.category,
    required this.defaultPrice,
    this.currency = 'THB',
    this.billingCycle = 'monthly',
    required this.logoAssetPath,
    required this.brandColor,
  });

  static const List<SubscriptionPreset> popularPresets = [
    // Streaming & Entertainment
    SubscriptionPreset(
      name: 'Netflix',
      category: 'สตรีมมิ่ง & ดูหนัง',
      defaultPrice: 169.0,
      logoAssetPath: 'assets/icons/subscriptions/netflix.png',
      brandColor: Color(0xFFE50914),
    ),
    SubscriptionPreset(
      name: 'YouTube Premium',
      category: 'สตรีมมิ่ง & ดูหนัง',
      defaultPrice: 179.0,
      logoAssetPath: 'assets/icons/subscriptions/youtube.png',
      brandColor: Color(0xFFFF0000),
    ),
    SubscriptionPreset(
      name: 'Spotify',
      category: 'เพลง & พอดแคสต์',
      defaultPrice: 139.0,
      logoAssetPath: 'assets/icons/subscriptions/spotify.png',
      brandColor: Color(0xFF1DB954),
    ),
    SubscriptionPreset(
      name: 'Disney+ Hotstar',
      category: 'สตรีมมิ่ง & ดูหนัง',
      defaultPrice: 289.0,
      logoAssetPath: 'assets/icons/subscriptions/disney_plus.png',
      brandColor: Color(0xFF113CCF),
    ),
    SubscriptionPreset(
      name: 'Apple TV+ / One',
      category: 'สตรีมมิ่ง & ดูหนัง',
      defaultPrice: 249.0,
      logoAssetPath: 'assets/icons/subscriptions/apple.png',
      brandColor: Color(0xFF1E1E1E),
    ),
    SubscriptionPreset(
      name: 'Amazon Prime',
      category: 'สตรีมมิ่ง & ดูหนัง',
      defaultPrice: 149.0,
      logoAssetPath: 'assets/icons/subscriptions/prime_video.png',
      brandColor: Color(0xFF00A8E1),
    ),
    SubscriptionPreset(
      name: 'HBO Max',
      category: 'สตรีมมิ่ง & ดูหนัง',
      defaultPrice: 199.0,
      logoAssetPath: 'assets/icons/subscriptions/hbo.png',
      brandColor: Color(0xFF5822B4),
    ),
    SubscriptionPreset(
      name: 'Viu Premium',
      category: 'สตรีมมิ่ง & ซีรีส์',
      defaultPrice: 149.0,
      logoAssetPath: 'assets/icons/subscriptions/viu.png',
      brandColor: Color(0xFFFBBA00),
    ),
    SubscriptionPreset(
      name: 'WeTV VIP',
      category: 'สตรีมมิ่ง & ซีรีส์',
      defaultPrice: 119.0,
      logoAssetPath: 'assets/icons/subscriptions/wetv.png',
      brandColor: Color(0xFF00C774),
    ),
    SubscriptionPreset(
      name: 'iQIYI VIP',
      category: 'สตรีมมิ่ง & ซีรีส์',
      defaultPrice: 119.0,
      logoAssetPath: 'assets/icons/subscriptions/iqiyi.png',
      brandColor: Color(0xFF00C864),
    ),
    SubscriptionPreset(
      name: 'Monomax',
      category: 'สตรีมมิ่ง & ดูหนัง',
      defaultPrice: 139.0,
      logoAssetPath: 'assets/icons/subscriptions/monomax.png',
      brandColor: Color(0xFFE81123),
    ),

    // AI & Productivity
    SubscriptionPreset(
      name: 'ChatGPT Plus',
      category: 'AI & ซอฟต์แวร์',
      defaultPrice: 20.0,
      currency: 'USD',
      logoAssetPath: 'assets/icons/subscriptions/chatgpt.png',
      brandColor: Color(0xFF10A37F),
    ),
    SubscriptionPreset(
      name: 'Claude Pro',
      category: 'AI & ซอฟต์แวร์',
      defaultPrice: 20.0,
      currency: 'USD',
      logoAssetPath: 'assets/icons/subscriptions/claude.png',
      brandColor: Color(0xFFD97706),
    ),
    SubscriptionPreset(
      name: 'Canva Pro',
      category: 'กราฟิก & ออกแบบ',
      defaultPrice: 185.0,
      logoAssetPath: 'assets/icons/subscriptions/canva.png',
      brandColor: Color(0xFF00C4CC),
    ),
    SubscriptionPreset(
      name: 'Midjourney',
      category: 'AI & ซอฟต์แวร์',
      defaultPrice: 10.0,
      currency: 'USD',
      logoAssetPath: 'assets/icons/subscriptions/midjourney.png',
      brandColor: Color(0xFF2C3E50),
    ),
    SubscriptionPreset(
      name: 'Adobe Creative Cloud',
      category: 'กราฟิก & ออกแบบ',
      defaultPrice: 1150.0,
      logoAssetPath: 'assets/icons/subscriptions/adobe.png',
      brandColor: Color(0xFFFA0F00),
    ),
    SubscriptionPreset(
      name: 'Microsoft 365',
      category: 'เอกสาร & พื้นที่จัดเก็บ',
      defaultPrice: 219.0,
      logoAssetPath: 'assets/icons/subscriptions/microsoft365.png',
      brandColor: Color(0xFFD83B01),
    ),
    SubscriptionPreset(
      name: 'Google One',
      category: 'พื้นที่จัดเก็บคลาวด์',
      defaultPrice: 70.0,
      logoAssetPath: 'assets/icons/subscriptions/google_one.png',
      brandColor: Color(0xFF4285F4),
    ),
    SubscriptionPreset(
      name: 'iCloud+',
      category: 'พื้นที่จัดเก็บคลาวด์',
      defaultPrice: 35.0,
      logoAssetPath: 'assets/icons/subscriptions/icloud.png',
      brandColor: Color(0xFF3897F0),
    ),
    SubscriptionPreset(
      name: 'Notion Plus',
      category: 'จัดการงาน & โน้ต',
      defaultPrice: 10.0,
      currency: 'USD',
      logoAssetPath: 'assets/icons/subscriptions/notion.png',
      brandColor: Color(0xFF000000),
    ),
    SubscriptionPreset(
      name: 'GitHub Copilot',
      category: 'AI & ซอฟต์แวร์',
      defaultPrice: 10.0,
      currency: 'USD',
      logoAssetPath: 'assets/icons/subscriptions/github_copilot.png',
      brandColor: Color(0xFF24292E),
    ),

    // Telco & Utilities
    SubscriptionPreset(
      name: 'AIS รายเดือน/ไฟเบอร์',
      category: 'มือถือ & เน็ตบ้าน',
      defaultPrice: 499.0,
      logoAssetPath: 'assets/icons/subscriptions/ais.png',
      brandColor: Color(0xFF83C326),
    ),
    SubscriptionPreset(
      name: 'True 5G / TrueOnline',
      category: 'มือถือ & เน็ตบ้าน',
      defaultPrice: 499.0,
      logoAssetPath: 'assets/icons/subscriptions/true.png',
      brandColor: Color(0xFFED1C24),
    ),
    SubscriptionPreset(
      name: 'dtac รายเดือน',
      category: 'มือถือ & เน็ตบ้าน',
      defaultPrice: 399.0,
      logoAssetPath: 'assets/icons/subscriptions/dtac.png',
      brandColor: Color(0xFF00B0FF),
    ),
    SubscriptionPreset(
      name: '3BB Fibre',
      category: 'มือถือ & เน็ตบ้าน',
      defaultPrice: 590.0,
      logoAssetPath: 'assets/icons/subscriptions/three_bb.png',
      brandColor: Color(0xFFEF5323),
    ),
    SubscriptionPreset(
      name: 'NT Broadband',
      category: 'มือถือ & เน็ตบ้าน',
      defaultPrice: 390.0,
      logoAssetPath: 'assets/icons/subscriptions/nt.png',
      brandColor: Color(0xFF0083CA),
    ),
    SubscriptionPreset(
      name: 'กฟน. การไฟฟ้านครหลวง',
      category: 'สาธารณูปโภค',
      defaultPrice: 1200.0,
      logoAssetPath: 'assets/icons/subscriptions/mea.png',
      brandColor: Color(0xFFE65100),
    ),
    SubscriptionPreset(
      name: 'กฟภ. การไฟฟ้าส่วนภูมิภาค',
      category: 'สาธารณูปโภค',
      defaultPrice: 1200.0,
      logoAssetPath: 'assets/icons/subscriptions/pea.png',
      brandColor: Color(0xFF6A1B9A),
    ),
    SubscriptionPreset(
      name: 'กปน. การประปานครหลวง',
      category: 'สาธารณูปโภค',
      defaultPrice: 250.0,
      logoAssetPath: 'assets/icons/subscriptions/mwa.png',
      brandColor: Color(0xFF0288D1),
    ),

    // Gaming & Lifestyle
    SubscriptionPreset(
      name: 'PlayStation Plus',
      category: 'เกม & บันเทิง',
      defaultPrice: 210.0,
      logoAssetPath: 'assets/icons/subscriptions/playstation.png',
      brandColor: Color(0xFF003791),
    ),
    SubscriptionPreset(
      name: 'Nintendo Switch Online',
      category: 'เกม & บันเทิง',
      defaultPrice: 150.0,
      logoAssetPath: 'assets/icons/subscriptions/nintendo.png',
      brandColor: Color(0xFFE60012),
    ),
    SubscriptionPreset(
      name: 'Discord Nitro',
      category: 'โซเชียล & สื่อสาร',
      defaultPrice: 9.99,
      currency: 'USD',
      logoAssetPath: 'assets/icons/subscriptions/discord.png',
      brandColor: Color(0xFF5865F2),
    ),
    SubscriptionPreset(
      name: 'GrabUnlimited',
      category: 'ส่งอาหาร & เดินทาง',
      defaultPrice: 19.0,
      logoAssetPath: 'assets/icons/subscriptions/grab.png',
      brandColor: Color(0xFF00B14F),
    ),
    SubscriptionPreset(
      name: 'LINE MAN สมาชิก',
      category: 'ส่งอาหาร & เดินทาง',
      defaultPrice: 29.0,
      logoAssetPath: 'assets/icons/subscriptions/lineman.png',
      brandColor: Color(0xFF06C755),
    ),
    SubscriptionPreset(
      name: 'Shopee VIP / สมาชิก',
      category: 'ช้อปปิ้งออนไลน์',
      defaultPrice: 49.0,
      logoAssetPath: 'assets/icons/subscriptions/shopee.png',
      brandColor: Color(0xFFEE4D2D),
    ),
  ];
}
