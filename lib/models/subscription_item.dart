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
  final bool enableReminder; // toggle push & in-app reminder
  final String? accountId; // linked account ID
  final String? accountName; // linked account name e.g. KBank, SCB, etc.
  final bool autoRecordExpense; // auto-create expense on billing due date
  final DateTime? lastAutoRecordedDate; // prevents duplicate recording in same cycle
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
    this.enableReminder = true,
    this.accountId,
    this.accountName,
    this.autoRecordExpense = false,
    this.lastAutoRecordedDate,
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
    bool? enableReminder,
    String? accountId,
    String? accountName,
    bool? autoRecordExpense,
    DateTime? lastAutoRecordedDate,
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
      enableReminder: enableReminder ?? this.enableReminder,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      autoRecordExpense: autoRecordExpense ?? this.autoRecordExpense,
      lastAutoRecordedDate: lastAutoRecordedDate ?? this.lastAutoRecordedDate,
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
      'enableReminder': enableReminder,
      'accountId': accountId,
      'accountName': accountName,
      'autoRecordExpense': autoRecordExpense,
      'lastAutoRecordedDate': lastAutoRecordedDate?.toIso8601String(),
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
      enableReminder: json['enableReminder'] as bool? ?? true,
      accountId: json['accountId'] as String?,
      accountName: json['accountName'] as String?,
      autoRecordExpense: json['autoRecordExpense'] as bool? ?? false,
      lastAutoRecordedDate: json['lastAutoRecordedDate'] != null ? DateTime.parse(json['lastAutoRecordedDate'] as String) : null,
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

    // Additional Global AI & Creative Services
    SubscriptionPreset(
      name: 'Google Gemini Advanced',
      category: 'AI & ซอฟต์แวร์',
      defaultPrice: 750.0,
      logoAssetPath: 'assets/icons/subscriptions/gemini.png',
      brandColor: Color(0xFF1E88E5),
    ),
    SubscriptionPreset(
      name: 'Perplexity Pro',
      category: 'AI & ซอฟต์แวร์',
      defaultPrice: 20.0,
      currency: 'USD',
      logoAssetPath: 'assets/icons/subscriptions/perplexity.png',
      brandColor: Color(0xFF22B8CD),
    ),
    SubscriptionPreset(
      name: 'Cursor Pro',
      category: 'AI & ซอฟต์แวร์',
      defaultPrice: 20.0,
      currency: 'USD',
      logoAssetPath: 'assets/icons/subscriptions/cursor.png',
      brandColor: Color(0xFF000000),
    ),
    SubscriptionPreset(
      name: 'CapCut Pro',
      category: 'กราฟิก & ตัดต่อวิดีโอ',
      defaultPrice: 249.0,
      logoAssetPath: 'assets/icons/subscriptions/capcut.png',
      brandColor: Color(0xFF000000),
    ),
    SubscriptionPreset(
      name: 'DeepL Pro',
      category: 'AI & การแปลภาษา',
      defaultPrice: 8.74,
      currency: 'USD',
      logoAssetPath: 'assets/icons/subscriptions/deepl.png',
      brandColor: Color(0xFF0F2B46),
    ),
    SubscriptionPreset(
      name: 'ElevenLabs',
      category: 'AI & เสียงสังเคราะห์',
      defaultPrice: 5.0,
      currency: 'USD',
      logoAssetPath: 'assets/icons/subscriptions/elevenlabs.png',
      brandColor: Color(0xFF000000),
    ),
    SubscriptionPreset(
      name: 'Poe AI',
      category: 'AI & ซอฟต์แวร์',
      defaultPrice: 19.99,
      currency: 'USD',
      logoAssetPath: 'assets/icons/subscriptions/poe.png',
      brandColor: Color(0xFF5B34EA),
    ),
    SubscriptionPreset(
      name: 'Suno AI',
      category: 'AI & ดนตรี',
      defaultPrice: 10.0,
      currency: 'USD',
      logoAssetPath: 'assets/icons/subscriptions/suno.png',
      brandColor: Color(0xFF000000),
    ),
    SubscriptionPreset(
      name: 'Runway ML',
      category: 'AI & ตัดต่อวิดีโอ',
      defaultPrice: 15.0,
      currency: 'USD',
      logoAssetPath: 'assets/icons/subscriptions/runway.png',
      brandColor: Color(0xFF000000),
    ),

    SubscriptionPreset(
      name: 'Higgsfield AI',
      category: 'AI & ตัดต่อวิดีโอ',
      defaultPrice: 15.0,
      currency: 'USD',
      logoAssetPath: 'assets/icons/subscriptions/higgsfield.png',
      brandColor: Color(0xFF000000),
    ),
    SubscriptionPreset(
      name: 'Kling AI',
      category: 'AI & ตัดต่อวิดีโอ',
      defaultPrice: 10.0,
      currency: 'USD',
      logoAssetPath: 'assets/icons/subscriptions/kling.png',
      brandColor: Color(0xFF1E88E5),
    ),

    // Thai Popular Entertainment & Sports
    SubscriptionPreset(
      name: 'TrueID / TrueVisions Now',
      category: 'สตรีมมิ่ง & กีฬา',
      defaultPrice: 249.0,
      logoAssetPath: 'assets/icons/subscriptions/trueid.png',
      brandColor: Color(0xFFED1C24),
    ),
    SubscriptionPreset(
      name: 'AIS PLAY',
      category: 'สตรีมมิ่ง & กีฬา',
      defaultPrice: 199.0,
      logoAssetPath: 'assets/icons/subscriptions/aisplay.png',
      brandColor: Color(0xFF83C326),
    ),
    SubscriptionPreset(
      name: 'beIN SPORTS',
      category: 'กีฬา & ฟุตบอล',
      defaultPrice: 149.0,
      logoAssetPath: 'assets/icons/subscriptions/beinsports.png',
      brandColor: Color(0xFF672A99),
    ),
    SubscriptionPreset(
      name: 'Bilibili Premium',
      category: 'อนิเมะ & วิดีโอ',
      defaultPrice: 99.0,
      logoAssetPath: 'assets/icons/subscriptions/bilibili.png',
      brandColor: Color(0xFF00AEEC),
    ),
    SubscriptionPreset(
      name: 'CH3 Plus Premium',
      category: 'สตรีมมิ่ง & ละคร',
      defaultPrice: 99.0,
      logoAssetPath: 'assets/icons/subscriptions/ch3plus.png',
      brandColor: Color(0xFF003F87),
    ),
    SubscriptionPreset(
      name: 'pandapro (Foodpanda)',
      category: 'ส่งอาหาร & เดินทาง',
      defaultPrice: 19.0,
      logoAssetPath: 'assets/icons/subscriptions/pandapro.png',
      brandColor: Color(0xFFD70F64),
    ),
    SubscriptionPreset(
      name: 'Easy Pass / M-Flow',
      category: 'สาธารณูปโภค & ทางด่วน',
      defaultPrice: 500.0,
      logoAssetPath: 'assets/icons/subscriptions/mflow.png',
      brandColor: Color(0xFF003893),
    ),
  ];

  static final Map<String, List<String>> _aliasMap = {
    'Netflix': ['netflix', 'เน็ตฟลิก', 'เนตฟลิก'],
    'YouTube Premium': ['youtube', 'yt', 'ยูทูป', 'ยูทูบ'],
    'Spotify': ['spotify', 'สปอติฟาย'],
    'Disney+ Hotstar': ['disney', 'ดิสนีย์', 'hotstar'],
    'Apple TV+ / One': ['apple', 'แอปเปิ้ล', 'apple tv', 'apple music', 'apple one', 'itunes'],
    'Amazon Prime': ['prime', 'amazon prime', 'อเมซอน', 'ไพรม์'],
    'HBO Max': ['hbo', 'hbomax', 'max'],
    'Viu Premium': ['viu', 'วิว'],
    'WeTV VIP': ['wetv', 'วีทีวี'],
    'iQIYI VIP': ['iqiyi', 'อ้ายฉีอี้'],
    'Monomax': ['monomax', 'โมโนแมกซ์'],
    'Bilibili Premium': ['bilibili', 'บิลิบิลิ'],
    'TrueID / TrueVisions Now': ['trueid', 'ทรูไอดี', 'truevisions', 'ทรูวิชั่น'],
    'AIS PLAY': ['ais play', 'aisplay', 'เอไอเอสเพลย์'],
    'beIN SPORTS': ['bein', 'beinsports', 'บีอิน'],
    'CH3 Plus Premium': ['ch3', '3plus', 'ช่อง3', 'ch3plus'],
    'ChatGPT Plus': ['chatgpt', 'gpt', 'openai', 'แชทจีพีที'],
    'Claude Pro': ['claude', 'cloud ai', 'cloud', 'clou', 'anthropic', 'โคลด', 'คลาวด์', 'คลาว'],
    'Google Gemini Advanced': ['gemini', 'google gemini', 'bard', 'เจมินาย', 'กูเกิล'],
    'Perplexity Pro': ['perplexity', 'pplx', 'เพอร์เพล็กซิตี้'],
    'Cursor Pro': ['cursor', 'เคอร์เซอร์'],
    'Canva Pro': ['canva', 'แคนวา'],
    'Midjourney': ['midjourney', 'mj', 'มิดเจอร์นีย์'],
    'Adobe Creative Cloud': ['adobe', 'photoshop', 'illustrator', 'อะโดบี'],
    'CapCut Pro': ['capcut', 'แคปคัท'],
    'DeepL Pro': ['deepl', 'ดีพแอล'],
    'ElevenLabs': ['elevenlabs', '11labs', 'อีเลฟเวนแล็บ'],
    'Poe AI': ['poe', 'โพ'],
    'Suno AI': ['suno', 'ซูโน'],
    'Runway ML': ['runway', 'รันเวย์'],
    'Higgsfield AI': ['higgsfield', 'higgs', 'higg', 'ฮิกส์ฟิลด์', 'ฮิกส์'],
    'Kling AI': ['kling', 'kling ai', 'klin', 'kli', 'คลิง', 'klingai'],
    'Microsoft 365': ['microsoft', 'office', 'm365', 'ไมโครซอฟท์', 'word', 'excel'],
    'Google One': ['google one', 'gsuite', 'google drive'],
    'iCloud+': ['icloud', 'ไอคลาวด์'],
    'Notion Plus': ['notion', 'โนชั่น'],
    'GitHub Copilot': ['github', 'copilot', 'กิตฮับ'],
    'Dropbox': ['dropbox', 'ดรอปบ็อกซ์'],
    'AIS รายเดือน/ไฟเบอร์': ['ais', 'เอไอเอส', 'ais fibre', 'เน็ต ais'],
    'True 5G / TrueOnline': ['true', 'ทรู', 'trueonline', 'เน็ตทรู', 'true 5g'],
    'dtac รายเดือน': ['dtac', 'ดีแทค'],
    '3BB Fibre': ['3bb', 'ทรีบีบี', 'สามบีบี'],
    'NT Broadband': ['nt', 'nt broadband', 'ทีโอที', 'tot', 'cat'],
    'กฟน. การไฟฟ้านครหลวง': ['mea', 'กฟน', 'ไฟฟ้านครหลวง', 'ค่าไฟ กฟน'],
    'กฟภ. การไฟฟ้าส่วนภูมิภาค': ['pea', 'กฟภ', 'ไฟฟ้าส่วนภูมิภาค', 'ค่าไฟ กฟภ'],
    'กปน. การประปานครหลวง': ['mwa', 'กปน', 'การประปา', 'ค่าน้ำ'],
    'Easy Pass / M-Flow': ['easypass', 'easy pass', 'mflow', 'm-flow', 'm flow', 'ทางด่วน', 'เอ็มโฟลว์'],
    'PlayStation Plus': ['playstation', 'ps plus', 'psn', 'เพลย์สเตชัน'],
    'Nintendo Switch Online': ['nintendo', 'switch online', 'นินเทนโด'],
    'Steam': ['steam', 'สตีม'],
    'Discord Nitro': ['discord', 'ดิสคอร์ด'],
    'GrabUnlimited': ['grab', 'แกร็บ', 'grabunlimited'],
    'LINE MAN สมาชิก': ['lineman', 'ไลน์แมน', 'line man'],
    'pandapro (Foodpanda)': ['pandapro', 'foodpanda', 'ฟู้ดแพนด้า', 'แพนด้าโปร'],
    'Shopee VIP / สมาชิก': ['shopee', 'ช้อปปี้', 'spaylater'],
  };

  /// Intelligently matches user typing to an authentic preset
  /// Supports prefix/near-matching (e.g. typing 3+ characters when almost complete)
  static SubscriptionPreset? findMatchingPreset(String input) {
    final clean = input.trim().toLowerCase();
    if (clean.length < 2) return null;

    // 1. Direct exact name match
    for (final p in popularPresets) {
      if (p.name.toLowerCase() == clean) {
        return p;
      }
    }

    // 2. Exact alias match
    for (final entry in _aliasMap.entries) {
      for (final alias in entry.value) {
        if (clean == alias) {
          return popularPresets.firstWhere((p) => p.name == entry.key, orElse: () => popularPresets.first);
        }
      }
    }

    // 3. Alias prefix / startsWith match (e.g. "higg" matching "higgsfield", "klin" matching "kling")
    for (final entry in _aliasMap.entries) {
      for (final alias in entry.value) {
        if (alias.startsWith(clean)) {
          return popularPresets.firstWhere((p) => p.name == entry.key, orElse: () => popularPresets.first);
        }
      }
    }

    // 4. Name startsWith / contains match
    for (final p in popularPresets) {
      final pName = p.name.toLowerCase();
      if (pName.startsWith(clean)) {
        return p;
      }
    }

    // 5. Clean startsWith alias
    for (final entry in _aliasMap.entries) {
      for (final alias in entry.value) {
        if (clean.startsWith(alias) || clean.contains(alias)) {
          return popularPresets.firstWhere((p) => p.name == entry.key, orElse: () => popularPresets.first);
        }
      }
    }

    return null;
  }

  /// Autocomplete suggestions for Google-like search dropdown
  static List<SubscriptionPreset> searchPresets(String query, {int limit = 6}) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    final results = <SubscriptionPreset>[];
    final addedNames = <String>{};

    void addPreset(SubscriptionPreset p) {
      if (!addedNames.contains(p.name)) {
        addedNames.add(p.name);
        results.add(p);
      }
    }

    // 1. Check direct prefix/contains
    for (final p in popularPresets) {
      final pName = p.name.toLowerCase();
      if (pName.startsWith(clean) || pName.contains(clean)) {
        addPreset(p);
        if (results.length >= limit) return results;
      }
    }

    // 2. Check aliases
    for (final entry in _aliasMap.entries) {
      for (final alias in entry.value) {
        if (alias.startsWith(clean) || clean.startsWith(alias) || alias.contains(clean)) {
          final found = popularPresets.firstWhere((p) => p.name == entry.key, orElse: () => popularPresets.first);
          addPreset(found);
          if (results.length >= limit) return results;
          break;
        }
      }
    }

    return results;
  }
}
