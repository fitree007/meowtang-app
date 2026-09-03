import 'package:flutter/material.dart';

enum ThemeCategory { classic, minimal, cute }

enum SeasonalEffect {
  none,
  sakura,
  snow,
  autumnLeaves,
  summerSparkle,
  cozyRain,
  stars,
}

class AppThemeModel {
  final String id;
  final String name;
  final String nameEn;
  final String description;
  final String descriptionEn;
  final String priceText;
  final bool isFree;
  final bool isDark;
  final bool isGlass;
  final ThemeCategory category;
  final SeasonalEffect seasonalEffect;
  final String? seasonBadge;

  // Primary branding
  final Color primaryColor;
  final Color primaryLight;
  final Color primaryDark;
  final Color secondaryColor;

  // Light Palette
  final Color lightScaffoldBackground;
  final Color lightCardBackground;
  final Color lightSurfaceBackground;
  final Color lightTextColor;
  final Color lightTextSecondaryColor;
  final Color lightBorderColor;
  final Color lightExpenseColor;
  final Color lightIncomeColor;

  // Dark Palette
  final Color darkScaffoldBackground;
  final Color darkCardBackground;
  final Color darkSurfaceBackground;
  final Color darkTextColor;
  final Color darkTextSecondaryColor;
  final Color darkBorderColor;
  final Color darkExpenseColor;
  final Color darkIncomeColor;

  // Visual Palette preview dots
  final List<Color> previewDots;

  const AppThemeModel({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.description,
    required this.descriptionEn,
    required this.priceText,
    this.isFree = true,
    this.isDark = false,
    this.isGlass = false,
    required this.category,
    this.seasonalEffect = SeasonalEffect.none,
    this.seasonBadge,
    required this.primaryColor,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondaryColor,
    required this.lightScaffoldBackground,
    required this.lightCardBackground,
    required this.lightSurfaceBackground,
    required this.lightTextColor,
    required this.lightTextSecondaryColor,
    required this.lightBorderColor,
    required this.lightExpenseColor,
    required this.lightIncomeColor,
    required this.darkScaffoldBackground,
    required this.darkCardBackground,
    required this.darkSurfaceBackground,
    required this.darkTextColor,
    required this.darkTextSecondaryColor,
    required this.darkBorderColor,
    required this.darkExpenseColor,
    required this.darkIncomeColor,
    required this.previewDots,
  });

  // Dynamic getters based on isDark parameter
  Color get scaffoldBackground => isDark ? darkScaffoldBackground : lightScaffoldBackground;
  Color get cardBackground => isDark ? darkCardBackground : lightCardBackground;
  Color get surfaceBackground => isDark ? darkSurfaceBackground : lightSurfaceBackground;
  Color get textColor => isDark ? darkTextColor : lightTextColor;
  Color get textSecondaryColor => isDark ? darkTextSecondaryColor : lightTextSecondaryColor;
  Color get borderColor => isDark ? darkBorderColor : lightBorderColor;
  Color get expenseColor => isDark ? darkExpenseColor : lightExpenseColor;
  Color get incomeColor => isDark ? darkIncomeColor : lightIncomeColor;

  AppThemeModel copyWithMode(bool darkMode) {
    return AppThemeModel(
      id: id,
      name: name,
      nameEn: nameEn,
      description: description,
      descriptionEn: descriptionEn,
      priceText: priceText,
      isFree: isFree,
      isDark: darkMode,
      isGlass: isGlass,
      category: category,
      seasonalEffect: seasonalEffect,
      seasonBadge: seasonBadge,
      primaryColor: primaryColor,
      primaryLight: primaryLight,
      primaryDark: primaryDark,
      secondaryColor: secondaryColor,
      lightScaffoldBackground: lightScaffoldBackground,
      lightCardBackground: lightCardBackground,
      lightSurfaceBackground: lightSurfaceBackground,
      lightTextColor: lightTextColor,
      lightTextSecondaryColor: lightTextSecondaryColor,
      lightBorderColor: lightBorderColor,
      lightExpenseColor: lightExpenseColor,
      lightIncomeColor: lightIncomeColor,
      darkScaffoldBackground: darkScaffoldBackground,
      darkCardBackground: darkCardBackground,
      darkSurfaceBackground: darkSurfaceBackground,
      darkTextColor: darkTextColor,
      darkTextSecondaryColor: darkTextSecondaryColor,
      darkBorderColor: darkBorderColor,
      darkExpenseColor: darkExpenseColor,
      darkIncomeColor: darkIncomeColor,
      previewDots: previewDots,
    );
  }

  LinearGradient get heroGradient => LinearGradient(
        colors: isDark
            ? [primaryDark, darkSurfaceBackground]
            : [primaryColor, primaryDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get buttonGradient => LinearGradient(
        colors: [primaryLight, primaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  ThemeData toThemeData() {
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: scaffoldBackground,
      primaryColor: primaryColor,
      cardColor: cardBackground,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: primaryColor,
              secondary: secondaryColor,
              surface: surfaceBackground,
              error: expenseColor,
            )
          : ColorScheme.light(
              primary: primaryColor,
              secondary: secondaryColor,
              surface: surfaceBackground,
              error: expenseColor,
            ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? darkCardBackground : primaryColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : textColor,
        ),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      dividerColor: borderColor,
    );
  }
}

class AppThemePresets {
  // =========================================================================
  // 1. หมวดคลาสสิค (CLASSIC THEMES - 6 ธีม รองรับทั้ง Light และ Dark)
  // =========================================================================

  /// 1.1 เหมียวตังค์ โกลด์ (MeowTang Gold)
  static const AppThemeModel classicMeowGold = AppThemeModel(
    id: 'default_light',
    name: 'เหมียวตังค์ โกลด์',
    nameEn: 'MeowTang Gold',
    description: 'ธีมเอกลักษณ์ดั้งเดิมของเหมียวตังค์ โทนทองมัสตาร์ดตัดเนวี่บลู สวยหรูลงตัว',
    descriptionEn: 'The iconic signature MeowTang gold with rich navy accents',
    priceText: 'ฟรี',
    category: ThemeCategory.classic,
    seasonBadge: '⭐ ธีมตั้งต้น',
    primaryColor: Color(0xFFF59E0B),
    primaryLight: Color(0xFFFBBF24),
    primaryDark: Color(0xFFD97706),
    secondaryColor: Color(0xFF0F172A),
    lightScaffoldBackground: Color(0xFFFFFBEB),
    lightCardBackground: Color(0xFFFFFFFF),
    lightSurfaceBackground: Color(0xFFFEF3C7),
    lightTextColor: Color(0xFF0F172A),
    lightTextSecondaryColor: Color(0xFF78350F),
    lightBorderColor: Color(0xFFFDE68A),
    lightExpenseColor: Color(0xFFEF4444),
    lightIncomeColor: Color(0xFF10B981),
    darkScaffoldBackground: Color(0xFF0A0F1D),
    darkCardBackground: Color(0xFF141D30),
    darkSurfaceBackground: Color(0xFF1E2B45),
    darkTextColor: Color(0xFFF8FAFC),
    darkTextSecondaryColor: Color(0xFFCBD5E1),
    darkBorderColor: Color(0xFF2A3B5C),
    darkExpenseColor: Color(0xFFF87171),
    darkIncomeColor: Color(0xFF34D399),
    previewDots: [Color(0xFFF59E0B), Color(0xFF0F172A), Color(0xFFFEF3C7)],
  );

  /// 1.2 ผู้บริหารสุขุม (Executive Navy)
  static const AppThemeModel executiveNavy = AppThemeModel(
    id: 'executive_navy',
    name: 'ผู้บริหารสุขุม',
    nameEn: 'Executive Navy',
    description: 'สีกรมท่าลึกภูมิฐาน เรียบหรู เสริมความมั่นคงทางการเงิน',
    descriptionEn: 'Deep commanding navy with crisp contrast for business leaders',
    priceText: 'ฟรี',
    category: ThemeCategory.classic,
    seasonBadge: '🏛️ คลาสสิก',
    primaryColor: Color(0xFF1E3A8A),
    primaryLight: Color(0xFF3B82F6),
    primaryDark: Color(0xFF172554),
    secondaryColor: Color(0xFF0284C7),
    lightScaffoldBackground: Color(0xFFF8FAFC),
    lightCardBackground: Color(0xFFFFFFFF),
    lightSurfaceBackground: Color(0xFFF1F5F9),
    lightTextColor: Color(0xFF0F172A),
    lightTextSecondaryColor: Color(0xFF475569),
    lightBorderColor: Color(0xFFCBD5E1),
    lightExpenseColor: Color(0xFFDC2626),
    lightIncomeColor: Color(0xFF16A34A),
    darkScaffoldBackground: Color(0xFF080E1E),
    darkCardBackground: Color(0xFF0F1B36),
    darkSurfaceBackground: Color(0xFF182A52),
    darkTextColor: Color(0xFFF8FAFC),
    darkTextSecondaryColor: Color(0xFF94A3B8),
    darkBorderColor: Color(0xFF233B6E),
    darkExpenseColor: Color(0xFFF87171),
    darkIncomeColor: Color(0xFF34D399),
    previewDots: [Color(0xFF1E3A8A), Color(0xFF0284C7), Color(0xFFF8FAFC)],
  );

  /// 1.3 ฟินเทคเอมเมอรัลด์ (Fintech Emerald)
  static const AppThemeModel emeraldWealth = AppThemeModel(
    id: 'emerald_wealth',
    name: 'ฟินเทคเอมเมอรัลด์',
    nameEn: 'Fintech Emerald',
    description: 'สีเขียวเหนี่ยวทรัพย์ ความมั่งคั่งและพลังแห่งการเติบโต',
    descriptionEn: 'Prestigious emerald green representing financial growth & prosperity',
    priceText: 'ฟรี',
    category: ThemeCategory.classic,
    seasonBadge: '💰 เหนี่ยวทรัพย์',
    primaryColor: Color(0xFF059669),
    primaryLight: Color(0xFF10B981),
    primaryDark: Color(0xFF065F46),
    secondaryColor: Color(0xFF34D399),
    lightScaffoldBackground: Color(0xFFF0FDF4),
    lightCardBackground: Color(0xFFFFFFFF),
    lightSurfaceBackground: Color(0xFFDCFCE7),
    lightTextColor: Color(0xFF064E3B),
    lightTextSecondaryColor: Color(0xFF047857),
    lightBorderColor: Color(0xFFBBF7D0),
    lightExpenseColor: Color(0xFFDC2626),
    lightIncomeColor: Color(0xFF16A34A),
    darkScaffoldBackground: Color(0xFF061510),
    darkCardBackground: Color(0xFF0B241C),
    darkSurfaceBackground: Color(0xFF12382B),
    darkTextColor: Color(0xFFF0FDF4),
    darkTextSecondaryColor: Color(0xFF86EFAC),
    darkBorderColor: Color(0xFF1B4F3E),
    darkExpenseColor: Color(0xFFF87171),
    darkIncomeColor: Color(0xFF34D399),
    previewDots: [Color(0xFF059669), Color(0xFF10B981), Color(0xFFDCFCE7)],
  );

  /// 1.4 มิดไนท์แซฟไฟร์ (Midnight Sapphire)
  static const AppThemeModel midnightSapphire = AppThemeModel(
    id: 'midnight_sapphire',
    name: 'มิดไนท์แซฟไฟร์',
    nameEn: 'Midnight Sapphire',
    description: 'แซฟไฟร์น้ำเงินเข้มลึก สบายตา คมชัดระดับพรีเมียม',
    descriptionEn: 'Ultra deep dark sapphire blue tailored for night focus',
    priceText: 'ฟรี',
    category: ThemeCategory.classic,
    seasonBadge: '💎 แซฟไฟร์',
    primaryColor: Color(0xFF2563EB),
    primaryLight: Color(0xFF60A5FA),
    primaryDark: Color(0xFF1D4ED8),
    secondaryColor: Color(0xFF38BDF8),
    lightScaffoldBackground: Color(0xFFEFF6FF),
    lightCardBackground: Color(0xFFFFFFFF),
    lightSurfaceBackground: Color(0xFFDBEAFE),
    lightTextColor: Color(0xFF1E3A8A),
    lightTextSecondaryColor: Color(0xFF2563EB),
    lightBorderColor: Color(0xFFBFDBFE),
    lightExpenseColor: Color(0xFFDC2626),
    lightIncomeColor: Color(0xFF16A34A),
    darkScaffoldBackground: Color(0xFF0A1128),
    darkCardBackground: Color(0xFF121E3E),
    darkSurfaceBackground: Color(0xFF1B2C56),
    darkTextColor: Color(0xFFF8FAFC),
    darkTextSecondaryColor: Color(0xFF94A3B8),
    darkBorderColor: Color(0xFF253B6E),
    darkExpenseColor: Color(0xFFF87171),
    darkIncomeColor: Color(0xFF34D399),
    previewDots: [Color(0xFF2563EB), Color(0xFF121E3E), Color(0xFF0A1128)],
  );

  /// 1.5 เบอร์กันดีเพรสทีจ (Burgundy Prestige)
  static const AppThemeModel burgundyPrestige = AppThemeModel(
    id: 'burgundy_prestige',
    name: 'เบอร์กันดีเพรสทีจ',
    nameEn: 'Burgundy Prestige',
    description: 'สีแดงไวน์เบอร์กันดีคลาสสิก สง่างาม ให้ความรู้สึกพรีเมียมมีระดับ',
    descriptionEn: 'Regal burgundy wine red with elegant subtle contrasts',
    priceText: 'ฟรี',
    category: ThemeCategory.classic,
    seasonBadge: '🍷 พรีเมียม',
    primaryColor: Color(0xFF881337),
    primaryLight: Color(0xFFBE123C),
    primaryDark: Color(0xFF4C0519),
    secondaryColor: Color(0xFFFB7185),
    lightScaffoldBackground: Color(0xFFFFF1F2),
    lightCardBackground: Color(0xFFFFFFFF),
    lightSurfaceBackground: Color(0xFFFFE4E6),
    lightTextColor: Color(0xFF1C1917),
    lightTextSecondaryColor: Color(0xFF9F1239),
    lightBorderColor: Color(0xFFFECDD3),
    lightExpenseColor: Color(0xFFDC2626),
    lightIncomeColor: Color(0xFF16A34A),
    darkScaffoldBackground: Color(0xFF16060B),
    darkCardBackground: Color(0xFF270E16),
    darkSurfaceBackground: Color(0xFF3D1522),
    darkTextColor: Color(0xFFFFF1F2),
    darkTextSecondaryColor: Color(0xFFFDA4AF),
    darkBorderColor: Color(0xFF5A1E31),
    darkExpenseColor: Color(0xFFF87171),
    darkIncomeColor: Color(0xFF34D399),
    previewDots: [Color(0xFF881337), Color(0xFFBE123C), Color(0xFFFFE4E6)],
  );

  /// 1.6 โมโนโครมสตูดิโอ (Studio Monochrome)
  static const AppThemeModel monochromeStudio = AppThemeModel(
    id: 'monochrome_studio',
    name: 'โมโนโครมสตูดิโอ',
    nameEn: 'Studio Monochrome',
    description: 'โทนสเลทเข้ม ขาว-ดำ-เทา เหนือกาลเวลา เรียบเท่ คมชัดในทุกมุมมอง',
    descriptionEn: 'Timeless slate monochrome architecture with perfect clarity',
    priceText: 'ฟรี',
    category: ThemeCategory.classic,
    seasonBadge: '📐 ไทม์เลส',
    primaryColor: Color(0xFF334155),
    primaryLight: Color(0xFF475569),
    primaryDark: Color(0xFF1E293B),
    secondaryColor: Color(0xFF64748B),
    lightScaffoldBackground: Color(0xFFF1F5F9),
    lightCardBackground: Color(0xFFFFFFFF),
    lightSurfaceBackground: Color(0xFFE2E8F0),
    lightTextColor: Color(0xFF0F172A),
    lightTextSecondaryColor: Color(0xFF475569),
    lightBorderColor: Color(0xFFCBD5E1),
    lightExpenseColor: Color(0xFFDC2626),
    lightIncomeColor: Color(0xFF16A34A),
    darkScaffoldBackground: Color(0xFF0B0F17),
    darkCardBackground: Color(0xFF161D2B),
    darkSurfaceBackground: Color(0xFF232D40),
    darkTextColor: Color(0xFFF8FAFC),
    darkTextSecondaryColor: Color(0xFF94A3B8),
    darkBorderColor: Color(0xFF334155),
    darkExpenseColor: Color(0xFFF87171),
    darkIncomeColor: Color(0xFF34D399),
    previewDots: [Color(0xFF334155), Color(0xFF64748B), Color(0xFFF1F5F9)],
  );

  // =========================================================================
  // 2. หมวดมินิมอล & LIQUID GLASS (MINIMAL & REAL CLEAR GLASS - 6 ธีม)
  // =========================================================================

  /// 2.1 ลิควิดกลาส เพียวคริสตัล (Liquid Glass Pure Crystal) - กระจกใสฝ้าจริง ไร้สี สะท้อนแสงเงาหรูหรา
  static const AppThemeModel liquidGlassCrystal = AppThemeModel(
    id: 'liquid_glass_crystal',
    name: 'ลิควิดกลาส เพียวคริสตัล',
    nameEn: 'Liquid Glass Crystal',
    description: 'สไตล์กระจกใสฝ้า Frosted Glass ไร้สี โปร่งใส หรูหรา มีมิติแสงเงาสะท้อนระดับพรีเมียม',
    descriptionEn: 'Pure transparent frosted liquid glass with glossy reflections and clean specular edges',
    priceText: 'ฟรี',
    isGlass: true,
    category: ThemeCategory.minimal,
    seasonBadge: '🫧 Liquid Glass',
    primaryColor: Color(0xFF475569),
    primaryLight: Color(0xFF64748B),
    primaryDark: Color(0xFF1E293B),
    secondaryColor: Color(0xFF94A3B8),
    lightScaffoldBackground: Color(0xFFECEFF3),
    lightCardBackground: Color(0xFFFAFCFF),
    lightSurfaceBackground: Color(0xFFDFE4EA),
    lightTextColor: Color(0xFF0F172A),
    lightTextSecondaryColor: Color(0xFF475569),
    lightBorderColor: Color(0xFFCBD5E1),
    lightExpenseColor: Color(0xFFDC2626),
    lightIncomeColor: Color(0xFF16A34A),
    darkScaffoldBackground: Color(0xFF0A0D14),
    darkCardBackground: Color(0xFF141A26),
    darkSurfaceBackground: Color(0xFF1E2638),
    darkTextColor: Color(0xFFF8FAFC),
    darkTextSecondaryColor: Color(0xFF94A3B8),
    darkBorderColor: Color(0xFF2C384F),
    darkExpenseColor: Color(0xFFF87171),
    darkIncomeColor: Color(0xFF34D399),
    previewDots: [Color(0xFF475569), Color(0xFF94A3B8), Color(0xFFECEFF3)],
  );

  /// 2.2 ลิควิดกลาส ฟรอสต์ซิลเวอร์ (Liquid Glass Frost Silver)
  static const AppThemeModel liquidGlassSilver = AppThemeModel(
    id: 'liquid_glass_silver',
    name: 'ลิควิดกลาส ฟรอสต์ซิลเวอร์',
    nameEn: 'Liquid Glass Silver',
    description: 'กระจกใสฝ้าเนื้อเงิน เคลือบผิวสะท้อนแสง มินิมอลเรียบหรูระดับไฮเอนด์',
    descriptionEn: 'Frosted silver metallic glass with crystal clear specular contours',
    priceText: 'ฟรี',
    isGlass: true,
    category: ThemeCategory.minimal,
    seasonBadge: '🪞 Frost Silver',
    primaryColor: Color(0xFF52525B),
    primaryLight: Color(0xFF71717A),
    primaryDark: Color(0xFF27272A),
    secondaryColor: Color(0xFFA1A1AA),
    lightScaffoldBackground: Color(0xFFF0F2F5),
    lightCardBackground: Color(0xFFFFFFFF),
    lightSurfaceBackground: Color(0xFFE4E7EB),
    lightTextColor: Color(0xFF18181B),
    lightTextSecondaryColor: Color(0xFF52525B),
    lightBorderColor: Color(0xFFD4D4D8),
    lightExpenseColor: Color(0xFFDC2626),
    lightIncomeColor: Color(0xFF16A34A),
    darkScaffoldBackground: Color(0xFF0C0E12),
    darkCardBackground: Color(0xFF181B22),
    darkSurfaceBackground: Color(0xFF242934),
    darkTextColor: Color(0xFFFAFAFA),
    darkTextSecondaryColor: Color(0xFFA1A1AA),
    darkBorderColor: Color(0xFF323947),
    darkExpenseColor: Color(0xFFF87171),
    darkIncomeColor: Color(0xFF34D399),
    previewDots: [Color(0xFF52525B), Color(0xFFA1A1AA), Color(0xFFF0F2F5)],
  );

  /// 2.3 ลิควิดกลาส ไอซ์ทินท์ (Liquid Glass Ice Tint)
  static const AppThemeModel liquidGlassIce = AppThemeModel(
    id: 'liquid_glass_ice',
    name: 'ลิควิดกลาส ไอซ์ทินท์',
    nameEn: 'Liquid Glass Ice Tint',
    description: 'กระจกใสเหลือบฟ้าไอซ์บลูอ่อนๆ โปร่งสบายตา สไตล์ iOS 18 Glassmorphism',
    descriptionEn: 'Subtle icy tinted translucent glass with soothing minimal tones',
    priceText: 'ฟรี',
    isGlass: true,
    category: ThemeCategory.minimal,
    seasonBadge: '🧊 Ice Glass',
    primaryColor: Color(0xFF0284C7),
    primaryLight: Color(0xFF38BDF8),
    primaryDark: Color(0xFF0369A1),
    secondaryColor: Color(0xFF7DD3FC),
    lightScaffoldBackground: Color(0xFFEBF3FA),
    lightCardBackground: Color(0xFFF7FAFD),
    lightSurfaceBackground: Color(0xFFDFECF7),
    lightTextColor: Color(0xFF0F172A),
    lightTextSecondaryColor: Color(0xFF0369A1),
    lightBorderColor: Color(0xFFB9D7EE),
    lightExpenseColor: Color(0xFFDC2626),
    lightIncomeColor: Color(0xFF16A34A),
    darkScaffoldBackground: Color(0xFF08101A),
    darkCardBackground: Color(0xFF101E30),
    darkSurfaceBackground: Color(0xFF1A2E47),
    darkTextColor: Color(0xFFF0F9FF),
    darkTextSecondaryColor: Color(0xFF7DD3FC),
    darkBorderColor: Color(0xFF264263),
    darkExpenseColor: Color(0xFFF87171),
    darkIncomeColor: Color(0xFF34D399),
    previewDots: [Color(0xFF0284C7), Color(0xFF38BDF8), Color(0xFFEBF3FA)],
  );

  /// 2.4 มินิมอล ซีนไวท์ (Minimal Zen White)
  static const AppThemeModel minimalZenWhite = AppThemeModel(
    id: 'minimal_zen_white',
    name: 'มินิมอล ซีนไวท์',
    nameEn: 'Minimal Zen White',
    description: 'ขาวบริสุทธิ์สไตล์มูจิ คลีนตา ไร้สิ่งรบกวน โฟกัสตัวเลขการเงินได้เต็มที่',
    descriptionEn: 'Ultra clean Japanese Zen white minimalism for zero distraction',
    priceText: 'ฟรี',
    category: ThemeCategory.minimal,
    seasonBadge: '⚪ คลีนตา',
    primaryColor: Color(0xFF18181B),
    primaryLight: Color(0xFF27272A),
    primaryDark: Color(0xFF09090B),
    secondaryColor: Color(0xFF71717A),
    lightScaffoldBackground: Color(0xFFFAFAFA),
    lightCardBackground: Color(0xFFFFFFFF),
    lightSurfaceBackground: Color(0xFFF4F4F5),
    lightTextColor: Color(0xFF18181B),
    lightTextSecondaryColor: Color(0xFF71717A),
    lightBorderColor: Color(0xFFE4E4E7),
    lightExpenseColor: Color(0xFFEF4444),
    lightIncomeColor: Color(0xFF10B981),
    darkScaffoldBackground: Color(0xFF09090B),
    darkCardBackground: Color(0xFF18181B),
    darkSurfaceBackground: Color(0xFF27272A),
    darkTextColor: Color(0xFFFAFAFA),
    darkTextSecondaryColor: Color(0xFFA1A1AA),
    darkBorderColor: Color(0xFF3F3F46),
    darkExpenseColor: Color(0xFFF87171),
    darkIncomeColor: Color(0xFF34D399),
    previewDots: [Color(0xFF18181B), Color(0xFF71717A), Color(0xFFFAFAFA)],
  );

  /// 2.5 มินิมอล วอร์มเปเปอร์ (Warm Minimal Paper)
  static const AppThemeModel minimalWarmPaper = AppThemeModel(
    id: 'minimal_warm_paper',
    name: 'มินิมอล วอร์มเปเปอร์',
    nameEn: 'Warm Minimal Paper',
    description: 'โทนกระดาษถนอมสายตาสีงาช้าง อบอุ่น นุ่มนวลเหมือนสมุดจดเล่มโปรด',
    descriptionEn: 'Soothing warm ivory book paper aesthetic for effortless reading',
    priceText: 'ฟรี',
    category: ThemeCategory.minimal,
    seasonBadge: '📜 ถนอมสายตา',
    primaryColor: Color(0xFF78350F),
    primaryLight: Color(0xFF92400E),
    primaryDark: Color(0xFF451A03),
    secondaryColor: Color(0xFFB45309),
    lightScaffoldBackground: Color(0xFFFDFBF7),
    lightCardBackground: Color(0xFFFFFFFF),
    lightSurfaceBackground: Color(0xFFF7F3EB),
    lightTextColor: Color(0xFF292524),
    lightTextSecondaryColor: Color(0xFF78716C),
    lightBorderColor: Color(0xFFE7E0D3),
    lightExpenseColor: Color(0xFFDC2626),
    lightIncomeColor: Color(0xFF16A34A),
    darkScaffoldBackground: Color(0xFF14120E),
    darkCardBackground: Color(0xFF211D17),
    darkSurfaceBackground: Color(0xFF302B22),
    darkTextColor: Color(0xFFFDFBF7),
    darkTextSecondaryColor: Color(0xFFD6CEBF),
    darkBorderColor: Color(0xFF483F32),
    darkExpenseColor: Color(0xFFF87171),
    darkIncomeColor: Color(0xFF34D399),
    previewDots: [Color(0xFF78350F), Color(0xFFB45309), Color(0xFFF7F3EB)],
  );

  /// 2.6 มินิมอล แมตต์ไทเทเนียม (Matte Titanium)
  static const AppThemeModel minimalMatteTitanium = AppThemeModel(
    id: 'minimal_matte_titanium',
    name: 'มินิมอล ไทเทเนียม',
    nameEn: 'Matte Titanium',
    description: 'ไทเทเนียมเทาด้าน เรียบหรู สะอาดตา โมเดิร์นระดับแฟลกชิป',
    descriptionEn: 'Flagship matte titanium alloy tones with sleek modern clarity',
    priceText: 'ฟรี',
    category: ThemeCategory.minimal,
    seasonBadge: '🔘 ไทเทเนียม',
    primaryColor: Color(0xFF475569),
    primaryLight: Color(0xFF64748B),
    primaryDark: Color(0xFF334155),
    secondaryColor: Color(0xFF94A3B8),
    lightScaffoldBackground: Color(0xFFF4F6F8),
    lightCardBackground: Color(0xFFFFFFFF),
    lightSurfaceBackground: Color(0xFFE9ECEF),
    lightTextColor: Color(0xFF1E293B),
    lightTextSecondaryColor: Color(0xFF64748B),
    lightBorderColor: Color(0xFFD8DEE4),
    lightExpenseColor: Color(0xFFDC2626),
    lightIncomeColor: Color(0xFF16A34A),
    darkScaffoldBackground: Color(0xFF0F1318),
    darkCardBackground: Color(0xFF1C222B),
    darkSurfaceBackground: Color(0xFF28313E),
    darkTextColor: Color(0xFFF8FAFC),
    darkTextSecondaryColor: Color(0xFF94A3B8),
    darkBorderColor: Color(0xFF3A4759),
    darkExpenseColor: Color(0xFFF87171),
    darkIncomeColor: Color(0xFF34D399),
    previewDots: [Color(0xFF475569), Color(0xFF94A3B8), Color(0xFFF4F6F8)],
  );

  // =========================================================================
  // 3. หมวดน่ารัก & พาสเทล (CUTE & PASTEL THEMES - 6 ธีม รองรับ Light และ Dark)
  // =========================================================================

  /// 3.1 ซากุระพาสเทล (Sweet Sakura Blossom)
  static const AppThemeModel cuteSakuraPink = AppThemeModel(
    id: 'season_spring_sakura',
    name: 'ซากุระพาสเทล',
    nameEn: 'Sweet Sakura Blossom',
    description: 'ชมพูซากุระพาสเทลหวานละมุน น่ารัก สบายตา',
    descriptionEn: 'Sweet pastel cherry blossom with gentle warm tones',
    priceText: 'ฟรี',
    category: ThemeCategory.cute,
    seasonalEffect: SeasonalEffect.sakura,
    seasonBadge: '🌸 ซากุระ',
    primaryColor: Color(0xFFDB2777),
    primaryLight: Color(0xFFF472B6),
    primaryDark: Color(0xFF9D174D),
    secondaryColor: Color(0xFFFB7185),
    lightScaffoldBackground: Color(0xFFFFF1F2),
    lightCardBackground: Color(0xFFFFFFFF),
    lightSurfaceBackground: Color(0xFFFFE4E6),
    lightTextColor: Color(0xFF1C1917),
    lightTextSecondaryColor: Color(0xFF9D174D),
    lightBorderColor: Color(0xFFFECDD3),
    lightExpenseColor: Color(0xFFDC2626),
    lightIncomeColor: Color(0xFF16A34A),
    darkScaffoldBackground: Color(0xFF190610),
    darkCardBackground: Color(0xFF2B0E1D),
    darkSurfaceBackground: Color(0xFF40162D),
    darkTextColor: Color(0xFFFFF1F2),
    darkTextSecondaryColor: Color(0xFFF472B6),
    darkBorderColor: Color(0xFF5E2042),
    darkExpenseColor: Color(0xFFF87171),
    darkIncomeColor: Color(0xFF34D399),
    previewDots: [Color(0xFFDB2777), Color(0xFFF472B6), Color(0xFFFFE4E6)],
  );

  /// 3.2 มัทฉะลาเต้ (Creamy Matcha Green)
  static const AppThemeModel cuteMatchaLatte = AppThemeModel(
    id: 'cute_matcha_latte',
    name: 'มัทฉะลาเต้',
    nameEn: 'Creamy Matcha Green',
    description: 'สีเขียวมัทฉะนุ่มละมุน สบายตา ผ่อนคลายทุกครั้งที่เปิดบันทึก',
    descriptionEn: 'Soothing creamy matcha green milk latte aesthetic',
    priceText: 'ฟรี',
    category: ThemeCategory.cute,
    seasonBadge: '🍵 มัทฉะ',
    primaryColor: Color(0xFF16A34A),
    primaryLight: Color(0xFF4ADE80),
    primaryDark: Color(0xFF15803D),
    secondaryColor: Color(0xFF86EFAC),
    lightScaffoldBackground: Color(0xFFF0FDF4),
    lightCardBackground: Color(0xFFFFFFFF),
    lightSurfaceBackground: Color(0xFFDCFCE7),
    lightTextColor: Color(0xFF14532D),
    lightTextSecondaryColor: Color(0xFF166534),
    lightBorderColor: Color(0xFFBBF7D0),
    lightExpenseColor: Color(0xFFDC2626),
    lightIncomeColor: Color(0xFF16A34A),
    darkScaffoldBackground: Color(0xFF07170C),
    darkCardBackground: Color(0xFF0F2B17),
    darkSurfaceBackground: Color(0xFF183F23),
    darkTextColor: Color(0xFFF0FDF4),
    darkTextSecondaryColor: Color(0xFF86EFAC),
    darkBorderColor: Color(0xFF235C33),
    darkExpenseColor: Color(0xFFF87171),
    darkIncomeColor: Color(0xFF34D399),
    previewDots: [Color(0xFF16A34A), Color(0xFF4ADE80), Color(0xFFDCFCE7)],
  );

  /// 3.3 ฮันนี่เลมอน (Sunny Honey Lemon)
  static const AppThemeModel cuteHoneyLemon = AppThemeModel(
    id: 'cute_honey_lemon',
    name: 'ฮันนี่เลมอน',
    nameEn: 'Sunny Honey Lemon',
    description: 'สีเหลืองน้ำผึ้งสดใส ร่าเริง มีชีวิตชีวา เติมพลังบวกให้การออมเงิน',
    descriptionEn: 'Bright cheerful sunny honey lemon energizing your daily savings',
    priceText: 'ฟรี',
    category: ThemeCategory.cute,
    seasonBadge: '🍯 ฮันนี่',
    primaryColor: Color(0xFFD97706),
    primaryLight: Color(0xFFFBBF24),
    primaryDark: Color(0xFFB45309),
    secondaryColor: Color(0xFFFDE047),
    lightScaffoldBackground: Color(0xFFFFFBEB),
    lightCardBackground: Color(0xFFFFFFFF),
    lightSurfaceBackground: Color(0xFFFEF3C7),
    lightTextColor: Color(0xFF78350F),
    lightTextSecondaryColor: Color(0xFF92400E),
    lightBorderColor: Color(0xFFFDE68A),
    lightExpenseColor: Color(0xFFDC2626),
    lightIncomeColor: Color(0xFF16A34A),
    darkScaffoldBackground: Color(0xFF191205),
    darkCardBackground: Color(0xFF2C200B),
    darkSurfaceBackground: Color(0xFF423010),
    darkTextColor: Color(0xFFFFFBEB),
    darkTextSecondaryColor: Color(0xFFFDE047),
    darkBorderColor: Color(0xFF634818),
    darkExpenseColor: Color(0xFFF87171),
    darkIncomeColor: Color(0xFF34D399),
    previewDots: [Color(0xFFD97706), Color(0xFFFBBF24), Color(0xFFFEF3C7)],
  );

  /// 3.4 ลาเวนเดอร์ดรีม (Pastel Lavender Dream)
  static const AppThemeModel cuteLavenderDream = AppThemeModel(
    id: 'cute_lavender_dream',
    name: 'ลาเวนเดอร์ดรีม',
    nameEn: 'Pastel Lavender Dream',
    description: 'สีม่วงลาเวนเดอร์พาสเทลชวนฝัน อ่อนหวาน นุ่มนวล ละมุนใจ',
    descriptionEn: 'Dreamy pastel lavender purple with soft soothing gradients',
    priceText: 'ฟรี',
    category: ThemeCategory.cute,
    seasonBadge: '💜 ลาเวนเดอร์',
    primaryColor: Color(0xFF7C3AED),
    primaryLight: Color(0xFFA78BFA),
    primaryDark: Color(0xFF6D28D9),
    secondaryColor: Color(0xFFC4B5FD),
    lightScaffoldBackground: Color(0xFFF5F3FF),
    lightCardBackground: Color(0xFFFFFFFF),
    lightSurfaceBackground: Color(0xFFEDE9FE),
    lightTextColor: Color(0xFF4C1D95),
    lightTextSecondaryColor: Color(0xFF6D28D9),
    lightBorderColor: Color(0xFFDDD6FE),
    lightExpenseColor: Color(0xFFDC2626),
    lightIncomeColor: Color(0xFF16A34A),
    darkScaffoldBackground: Color(0xFF120824),
    darkCardBackground: Color(0xFF1F103B),
    darkSurfaceBackground: Color(0xFF2E1957),
    darkTextColor: Color(0xFFFAF5FF),
    darkTextSecondaryColor: Color(0xFFC4B5FD),
    darkBorderColor: Color(0xFF452680),
    darkExpenseColor: Color(0xFFF87171),
    darkIncomeColor: Color(0xFF34D399),
    previewDots: [Color(0xFF7C3AED), Color(0xFFA78BFA), Color(0xFFEDE9FE)],
  );

  /// 3.5 เบบี้บลูโอเชี่ยน (Fresh Baby Blue)
  static const AppThemeModel cuteBabyBlue = AppThemeModel(
    id: 'cute_baby_blue',
    name: 'เบบี้บลูโอเชี่ยน',
    nameEn: 'Fresh Baby Blue',
    description: 'สีฟ้าพาสเทลสดชื่น สดใส สบายตา เหมือนท้องฟ้าและน้ำทะเลใส',
    descriptionEn: 'Fresh oceanic baby blue pastel bringing cool clear vibes',
    priceText: 'ฟรี',
    category: ThemeCategory.cute,
    seasonBadge: '🌊 เบบี้บลู',
    primaryColor: Color(0xFF0284C7),
    primaryLight: Color(0xFF38BDF8),
    primaryDark: Color(0xFF0369A1),
    secondaryColor: Color(0xFF7DD3FC),
    lightScaffoldBackground: Color(0xFFF0F9FF),
    lightCardBackground: Color(0xFFFFFFFF),
    lightSurfaceBackground: Color(0xFFE0F2FE),
    lightTextColor: Color(0xFF0C4A6E),
    lightTextSecondaryColor: Color(0xFF0369A1),
    lightBorderColor: Color(0xFFBAE6FD),
    lightExpenseColor: Color(0xFFDC2626),
    lightIncomeColor: Color(0xFF16A34A),
    darkScaffoldBackground: Color(0xFF071421),
    darkCardBackground: Color(0xFF0E253B),
    darkSurfaceBackground: Color(0xFF163757),
    darkTextColor: Color(0xFFF0F9FF),
    darkTextSecondaryColor: Color(0xFF7DD3FC),
    darkBorderColor: Color(0xFF214E78),
    darkExpenseColor: Color(0xFFF87171),
    darkIncomeColor: Color(0xFF34D399),
    previewDots: [Color(0xFF0284C7), Color(0xFF38BDF8), Color(0xFFE0F2FE)],
  );

  /// 3.6 คอตตอนแคนดี้ (Sweet Cotton Candy)
  static const AppThemeModel cuteCottonCandy = AppThemeModel(
    id: 'cute_cotton_candy',
    name: 'คอตตอนแคนดี้',
    nameEn: 'Sweet Cotton Candy',
    description: 'ชมพูพีชตัดม่วงพาสเทล น่ารักฟรุ้งฟริ้ง เติมความสุขให้ทุกการบันทึก',
    descriptionEn: 'Sweet dual-tone cotton candy pink & lilac joyful pastel vibes',
    priceText: 'ฟรี',
    category: ThemeCategory.cute,
    seasonBadge: '🍬 คอตตอน',
    primaryColor: Color(0xFFE11D48),
    primaryLight: Color(0xFFFB7185),
    primaryDark: Color(0xFFBE123C),
    secondaryColor: Color(0xFFA855F7),
    lightScaffoldBackground: Color(0xFFFFF1F5),
    lightCardBackground: Color(0xFFFFFFFF),
    lightSurfaceBackground: Color(0xFFFFE4EC),
    lightTextColor: Color(0xFF1C1917),
    lightTextSecondaryColor: Color(0xFF9F1239),
    lightBorderColor: Color(0xFFFECDD6),
    lightExpenseColor: Color(0xFFDC2626),
    lightIncomeColor: Color(0xFF16A34A),
    darkScaffoldBackground: Color(0xFF1A060F),
    darkCardBackground: Color(0xFF2C0B1B),
    darkSurfaceBackground: Color(0xFF43132B),
    darkTextColor: Color(0xFFFFF1F5),
    darkTextSecondaryColor: Color(0xFFF472B6),
    darkBorderColor: Color(0xFF631D40),
    darkExpenseColor: Color(0xFFF87171),
    darkIncomeColor: Color(0xFF34D399),
    previewDots: [Color(0xFFE11D48), Color(0xFFA855F7), Color(0xFFFFE4EC)],
  );

  // =========================================================================
  // ALL 18 THEMES
  // =========================================================================
  static const List<AppThemeModel> allThemes = [
    // 1. Classic (6)
    classicMeowGold,
    executiveNavy,
    emeraldWealth,
    midnightSapphire,
    burgundyPrestige,
    monochromeStudio,

    // 2. Minimal & Liquid Glass (6)
    liquidGlassCrystal,
    liquidGlassSilver,
    liquidGlassIce,
    minimalZenWhite,
    minimalWarmPaper,
    minimalMatteTitanium,

    // 3. Cute & Pastel (6)
    cuteSakuraPink,
    cuteMatchaLatte,
    cuteHoneyLemon,
    cuteLavenderDream,
    cuteBabyBlue,
    cuteCottonCandy,
  ];

  static List<AppThemeModel> getThemesByCategory(ThemeCategory category) {
    return allThemes.where((t) => t.category == category).toList();
  }

  static AppThemeModel getById(String id, {bool? isDark}) {
    final theme = allThemes.firstWhere(
      (t) => t.id == id,
      orElse: () => executiveNavy,
    );
    if (isDark != null) {
      return theme.copyWithMode(isDark);
    }
    return theme;
  }
}
