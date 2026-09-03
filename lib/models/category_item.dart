import 'package:flutter/material.dart';

enum CategoryType {
  expense,
  income,
}

class CategoryIconMeta {
  final String key;
  final String label;
  final IconData icon;

  const CategoryIconMeta(this.key, this.label, this.icon);
}

class CategoryIconGroup {
  final String title;
  final String titleEn;
  final String emoji;
  final List<CategoryIconMeta> icons;

  const CategoryIconGroup({
    required this.title,
    required this.titleEn,
    required this.emoji,
    required this.icons,
  });
}

class CategoryCatalog {
  static const List<CategoryIconGroup> iconGroups = [
    CategoryIconGroup(
      title: 'อาหาร & เครื่องดื่ม',
      titleEn: 'Food & Drinks',
      emoji: '🍔',
      icons: [
        CategoryIconMeta('restaurant', 'อาหาร', Icons.restaurant_rounded),
        CategoryIconMeta('fastfood', 'ฟาสต์ฟู้ด', Icons.fastfood_rounded),
        CategoryIconMeta('local_cafe', 'กาแฟ/ชา', Icons.local_cafe_rounded),
        CategoryIconMeta('local_pizza', 'พิซซ่า', Icons.local_pizza_rounded),
        CategoryIconMeta('ramen_dining', 'ก๋วยเตี๋ยว/ราเมง', Icons.ramen_dining_rounded),
        CategoryIconMeta('lunch_dining', 'เบอร์เกอร์', Icons.lunch_dining_rounded),
        CategoryIconMeta('icecream', 'ไอศกรีม/ของหวาน', Icons.icecream_rounded),
        CategoryIconMeta('cake', 'เค้ก/เบเกอรี่', Icons.cake_rounded),
        CategoryIconMeta('bakery_dining', 'ขนมปัง', Icons.bakery_dining_rounded),
        CategoryIconMeta('local_bar', 'เครื่องดื่ม/ปาร์ตี้', Icons.local_bar_rounded),
        CategoryIconMeta('soup_kitchen', 'สตรีทฟู้ด/ต้มแกง', Icons.soup_kitchen_rounded),
        CategoryIconMeta('dinner_dining', 'มื้อค่ำ/ดินเนอร์', Icons.dinner_dining_rounded),
        CategoryIconMeta('emoji_food_beverage', 'ชานม/น้ำผลไม้', Icons.emoji_food_beverage_rounded),
        CategoryIconMeta('takeout_dining', 'เดลิเวอรี่/สั่งอาหาร', Icons.takeout_dining_rounded),
        CategoryIconMeta('set_meal', 'อาหารชุด/เซ็ต', Icons.set_meal_rounded),
        CategoryIconMeta('tapas', 'ของว่าง/ทานเล่น', Icons.tapas_rounded),
      ],
    ),
    CategoryIconGroup(
      title: 'ช้อปปิ้ง & ไลฟ์สไตล์',
      titleEn: 'Shopping & Lifestyle',
      emoji: '🛍️',
      icons: [
        CategoryIconMeta('shopping_cart', 'ซูเปอร์มาร์เก็ต', Icons.shopping_cart_rounded),
        CategoryIconMeta('shopping_bag', 'ช้อปปิ้งเสื้อผ้า', Icons.shopping_bag_rounded),
        CategoryIconMeta('local_grocery_store', 'ของสด/ตลาด', Icons.local_grocery_store_rounded),
        CategoryIconMeta('checkroom', 'เสื้อผ้า/แฟชั่น', Icons.checkroom_rounded),
        CategoryIconMeta('devices', 'ไอที/มือถือ', Icons.devices_rounded),
        CategoryIconMeta('watch', 'นาฬิกา/เครื่องประดับ', Icons.watch_rounded),
        CategoryIconMeta('storefront', 'ร้านค้าทั่วไป', Icons.storefront_rounded),
        CategoryIconMeta('diamond', 'ทองคำ/จิวเวลรี่', Icons.diamond_rounded),
        CategoryIconMeta('card_giftcard', 'ของขวัญ', Icons.card_giftcard_rounded),
        CategoryIconMeta('loyalty', 'คูปอง/ส่วนลด', Icons.loyalty_rounded),
        CategoryIconMeta('shopping_basket', 'ตะกร้าของใช้', Icons.shopping_basket_rounded),
        CategoryIconMeta('style', 'เครื่องแต่งกาย', Icons.style_rounded),
        CategoryIconMeta('dry_cleaning', 'ซักแห้ง/สปาผ้า', Icons.dry_cleaning_rounded),
        CategoryIconMeta('redeem', 'แลกของรางวัล', Icons.redeem_rounded),
      ],
    ),
    CategoryIconGroup(
      title: 'เดินทาง & ยานพาหนะ',
      titleEn: 'Transport & Travel',
      emoji: '🚗',
      icons: [
        CategoryIconMeta('local_gas_station', 'ค่าน้ำมัน/ปั๊มน้ำมัน', Icons.local_gas_station_rounded),
        CategoryIconMeta('directions_car', 'รถยนต์', Icons.directions_car_rounded),
        CategoryIconMeta('two_wheeler', 'มอเตอร์ไซค์', Icons.two_wheeler_rounded),
        CategoryIconMeta('ev_station', 'ชาร์จรถไฟฟ้า EV', Icons.ev_station_rounded),
        CategoryIconMeta('directions_bus', 'รถเมล์/รถตู้', Icons.directions_bus_rounded),
        CategoryIconMeta('train', 'BTS / MRT / รถไฟ', Icons.train_rounded),
        CategoryIconMeta('flight', 'ตั๋วเครื่องบิน/เดินทางไกล', Icons.flight_rounded),
        CategoryIconMeta('local_shipping', 'ขนส่ง/พัสดุ', Icons.local_shipping_rounded),
        CategoryIconMeta('commute', 'ค่าเดินทางประจำ', Icons.commute_rounded),
        CategoryIconMeta('pedal_bike', 'จักรยาน', Icons.pedal_bike_rounded),
        CategoryIconMeta('local_taxi', 'แท็กซี่ / Grab / Bolt', Icons.local_taxi_rounded),
        CategoryIconMeta('car_repair', 'ซ่อมรถ/เข้าศูนย์', Icons.car_repair_rounded),
        CategoryIconMeta('sailing', 'เรือ/ทางน้ำ', Icons.sailing_rounded),
        CategoryIconMeta('toll', 'ทางด่วน/ค่าผ่านทาง', Icons.toll_rounded),
      ],
    ),
    CategoryIconGroup(
      title: 'บ้าน & สาธารณูปโภค',
      titleEn: 'Housing & Utilities',
      emoji: '🏠',
      icons: [
        CategoryIconMeta('home', 'ที่พัก/บ้าน/คอนโด', Icons.home_rounded),
        CategoryIconMeta('water_drop', 'ค่าน้ำประปา', Icons.water_drop_rounded),
        CategoryIconMeta('bolt', 'ค่าไฟฟ้า', Icons.bolt_rounded),
        CategoryIconMeta('wifi', 'อินเทอร์เน็ตบ้าน', Icons.wifi_rounded),
        CategoryIconMeta('phone_android', 'ค่าโทรศัพท์/มือถือ', Icons.phone_android_rounded),
        CategoryIconMeta('receipt_long', 'บิล/ค่างวด/หนี้สิน', Icons.receipt_long_rounded),
        CategoryIconMeta('cleaning_services', 'ทำความสะอาด/แม่บ้าน', Icons.cleaning_services_rounded),
        CategoryIconMeta('handyman', 'ซ่อมแซมบ้าน', Icons.handyman_rounded),
        CategoryIconMeta('chair', 'เฟอร์นิเจอร์/แต่งบ้าน', Icons.chair_rounded),
        CategoryIconMeta('apartment', 'ค่าเช่าห้อง/หอพัก', Icons.apartment_rounded),
        CategoryIconMeta('tv', 'สมาร์ททีวี/เคเบิล', Icons.tv_rounded),
        CategoryIconMeta('ac_unit', 'แอร์/ล้างแอร์', Icons.ac_unit_rounded),
        CategoryIconMeta('kitchen', 'เครื่องใช้ไฟฟ้า', Icons.kitchen_rounded),
        CategoryIconMeta('solar_power', 'โซล่าเซลล์/พลังงาน', Icons.solar_power_rounded),
      ],
    ),
    CategoryIconGroup(
      title: 'สุขภาพ & ความงาม',
      titleEn: 'Health & Wellness',
      emoji: '💊',
      icons: [
        CategoryIconMeta('medical_services', 'ยารักษาโรค', Icons.medical_services_rounded),
        CategoryIconMeta('local_hospital', 'โรงพยาบาล/คลินิก', Icons.local_hospital_rounded),
        CategoryIconMeta('fitness_center', 'ฟิตเนส/ออกกำลังกาย', Icons.fitness_center_rounded),
        CategoryIconMeta('spa', 'สปา/นวด/ดูแลผิว', Icons.spa_rounded),
        CategoryIconMeta('shield', 'ประกันสุขภาพ/ชีวิต', Icons.shield_rounded),
        CategoryIconMeta('medication', 'วิตามิน/อาหารเสริม', Icons.medication_rounded),
        CategoryIconMeta('healing', 'ปฐมพยาบาล/ทำแผล', Icons.healing_rounded),
        CategoryIconMeta('health_and_safety', 'ดูแลสุขภาพ/อนามัย', Icons.health_and_safety_rounded),
        CategoryIconMeta('psychology', 'สุขภาพจิต/ปรึกษา', Icons.psychology_rounded),
        CategoryIconMeta('sports_soccer', 'กีฬา/อุปกรณ์กีฬา', Icons.sports_soccer_rounded),
        CategoryIconMeta('pool', 'ว่ายน้ำ', Icons.pool_rounded),
        CategoryIconMeta('self_improvement', 'โยคะ/สมาธิ', Icons.self_improvement_rounded),
      ],
    ),
    CategoryIconGroup(
      title: 'การศึกษา & การทำงาน',
      titleEn: 'Education & Career',
      emoji: '📚',
      icons: [
        CategoryIconMeta('school', 'การศึกษา/ค่าเทอม', Icons.school_rounded),
        CategoryIconMeta('menu_book', 'หนังสือ/ตำราเรียน', Icons.menu_book_rounded),
        CategoryIconMeta('laptop_mac', 'คอมพิวเตอร์/อุปกรณ์ทำงาน', Icons.laptop_mac_rounded),
        CategoryIconMeta('work', 'งานประจำ/ออฟฟิศ', Icons.work_rounded),
        CategoryIconMeta('business_center', 'ธุรกิจ/ติดต่องาน', Icons.business_center_rounded),
        CategoryIconMeta('science', 'วิจัย/การทดลอง', Icons.science_rounded),
        CategoryIconMeta('draw', 'อุปกรณ์วาดเขียน/เครื่องเขียน', Icons.draw_rounded),
        CategoryIconMeta('badge', 'ค่าธรรมเนียม/บัตร', Icons.badge_rounded),
        CategoryIconMeta('co_present', 'สัมมนา/อบรม', Icons.co_present_rounded),
        CategoryIconMeta('history_edu', 'ใบประกาศนียบัตร', Icons.history_edu_rounded),
      ],
    ),
    CategoryIconGroup(
      title: 'บันเทิง & ครอบครัว',
      titleEn: 'Entertainment & Family',
      emoji: '🎮',
      icons: [
        CategoryIconMeta('movie', 'ภาพยนตร์/สตรีมมิ่ง', Icons.movie_rounded),
        CategoryIconMeta('sports_esports', 'เกม/เติมเกม', Icons.sports_esports_rounded),
        CategoryIconMeta('pets', 'สัตว์เลี้ยง/อาหารสัตว์', Icons.pets_rounded),
        CategoryIconMeta('celebration', 'ปาร์ตี้/สังสรรค์', Icons.celebration_rounded),
        CategoryIconMeta('child_care', 'ของใช้เด็ก/ลูก', Icons.child_care_rounded),
        CategoryIconMeta('attractions', 'สวนสนุก/ท่องเที่ยว', Icons.attractions_rounded),
        CategoryIconMeta('music_note', 'ฟังเพลง/คอนเสิร์ต', Icons.music_note_rounded),
        CategoryIconMeta('camera_alt', 'กล้อง/ถ่ายรูป', Icons.camera_alt_rounded),
        CategoryIconMeta('theater_comedy', 'การแสดง/ละครเวที', Icons.theater_comedy_rounded),
        CategoryIconMeta('park', 'พักผ่อน/สวนสาธารณะ', Icons.park_rounded),
        CategoryIconMeta('stroller', 'รถเข็นเด็ก/แม่และเด็ก', Icons.stroller_rounded),
        CategoryIconMeta('sports_tennis', 'เทนนิส/แบดมินตัน', Icons.sports_tennis_rounded),
      ],
    ),
    CategoryIconGroup(
      title: 'รายได้, ริซกี & การเงิน',
      titleEn: 'Income, Rizqi & Finance',
      emoji: '💰',
      icons: [
        CategoryIconMeta('payments', 'รายได้หลัก/รับเงิน', Icons.payments_rounded),
        CategoryIconMeta('account_balance_wallet', 'กระเป๋าเงิน/เงินออม', Icons.account_balance_wallet_rounded),
        CategoryIconMeta('savings', 'เงินปันผล/ดอกเบี้ย', Icons.savings_rounded),
        CategoryIconMeta('trending_up', 'กำไร/ลงทุน/หุ้น', Icons.trending_up_rounded),
        CategoryIconMeta('currency_exchange', 'แลกเปลี่ยนเงิน/Forex', Icons.currency_exchange_rounded),
        CategoryIconMeta('auto_awesome', 'ริซกีฮาลาล/โบนัส', Icons.auto_awesome_rounded),
        CategoryIconMeta('monetization_on', 'เงินสด/เหรียญ', Icons.monetization_on_rounded),
        CategoryIconMeta('inventory_2', 'ขายของ/ธุรกิจส่วนตัว', Icons.inventory_2_rounded),
        CategoryIconMeta('price_check', 'เช็คเงินสด/เงินคืน', Icons.price_check_rounded),
        CategoryIconMeta('real_estate_agent', 'อสังหาริมทรัพย์/ค่าเช่ารับ', Icons.real_estate_agent_rounded),
        CategoryIconMeta('request_quote', 'ใบแจ้งหนี้/ค่าจ้าง', Icons.request_quote_rounded),
        CategoryIconMeta('credit_card', 'บัตรเครดิต/คืนเงิน', Icons.credit_card_rounded),
      ],
    ),
    CategoryIconGroup(
      title: 'ศาสนา, อิสลาม & ทำบุญ',
      titleEn: 'Religion, Charity & Zakat',
      emoji: '🌙',
      icons: [
        CategoryIconMeta('mosque', 'มัสยิด/ศาสนสถาน', Icons.mosque_rounded),
        CategoryIconMeta('volunteer_activism', 'บริจาค/ซะกาต/ซอดะเกาะฮ์', Icons.volunteer_activism_rounded),
        CategoryIconMeta('handshake', 'ช่วยเหลือผู้ยากไร้', Icons.handshake_rounded),
        CategoryIconMeta('favorite', 'ทำบุญด้วยใจ/การกุศล', Icons.favorite_rounded),
        CategoryIconMeta('diversity_1', 'ชุมชน/มูลนิธิ', Icons.diversity_1_rounded),
        CategoryIconMeta('temple_buddhist', 'วัด/ทำบุญ', Icons.temple_buddhist_rounded),
        CategoryIconMeta('church', 'โบสถ์/ศาสนา', Icons.church_rounded),
      ],
    ),
  ];

  static List<CategoryIconMeta> get availableIcons {
    final list = <CategoryIconMeta>[];
    for (final group in iconGroups) {
      list.addAll(group.icons);
    }
    return list;
  }
}

class CategoryItem {
  final String id;
  final String name;
  final String iconKey;
  final int colorValue;
  final CategoryType type;
  final bool isDefault;

  CategoryItem({
    required this.id,
    required this.name,
    this.iconKey = 'category',
    required this.colorValue,
    required this.type,
    this.isDefault = false,
    int? iconCodePoint,
  });

  Color get color => Color(colorValue);

  static IconData resolveIcon(String iconKey, {CategoryType? type}) {
    for (final item in CategoryCatalog.availableIcons) {
      if (item.key == iconKey) {
        return item.icon;
      }
    }
    // Backward compatibility fallbacks
    switch (iconKey) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.local_gas_station;
      case 'shopping':
        return Icons.shopping_bag;
      case 'bills':
        return Icons.receipt_long;
      case 'housing':
        return Icons.home;
      case 'charity':
        return Icons.volunteer_activism;
      case 'business':
        return Icons.inventory_2;
      case 'salary':
        return Icons.work;
      case 'freelance':
        return Icons.laptop_mac;
      case 'online_sales':
        return Icons.storefront;
      case 'affiliate':
        return Icons.auto_awesome;
      default:
        return type == CategoryType.income ? Icons.payments_rounded : Icons.category_rounded;
    }
  }

  IconData get icon {
    return resolveIcon(iconKey, type: type);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconKey': iconKey,
      'colorValue': colorValue,
      'type': type.name,
      'isDefault': isDefault,
    };
  }

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      iconKey: json['iconKey'] as String? ?? 'category',
      colorValue: json['colorValue'] as int? ?? 0xFF10B981,
      type: json['type'] != null
          ? CategoryType.values.byName(json['type'] as String)
          : CategoryType.expense,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  CategoryItem copyWith({
    String? id,
    String? name,
    String? iconKey,
    int? colorValue,
    CategoryType? type,
    bool? isDefault,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
