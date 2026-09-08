import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/app_theme_model.dart';
import '../widgets/tactile_button.dart';
import '../widgets/theme_test_drive_banner.dart';
import '../widgets/meow_paywall_modal.dart';
import '../config/app_config.dart';

class ThemeShopScreen extends StatefulWidget {
  final ExpenseController controller;

  const ThemeShopScreen({super.key, required this.controller});

  @override
  State<ThemeShopScreen> createState() => _ThemeShopScreenState();
}

class _ThemeShopScreenState extends State<ThemeShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showTestDriveExpiredDialog(AppThemeModel theme) {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.controller.currentTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.timer_off_rounded, color: Color(0xFFF59E0B), size: 24),
            SizedBox(width: 8),
            Text('หมดเวลาทดลองใช้ 30 วิ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'ชอบธีม "${theme.name}" ไหมน้า? ซื้อธีมนี้เพียง ฿${AppConfig.themePriceThb} ใช้ได้ตลอดชีพ หรืออัปเกรดเป็น VIP เพื่อปลดล็อคทุกธีมและดึงสลิปไม่จำกัด!',
          style: TextStyle(fontSize: 13, color: widget.controller.currentTheme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ไว้คราวหน้า'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.controller.purchaseTheme(theme.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF059669),
                    content: Text('ปลดล็อคธีม "${theme.name}" ถาวรสำเร็จ! 🎉'),
                  ),
                );
              }
            },
            child: Text('ซื้อ ฿${AppConfig.themePriceThb}', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLockedThemeOptions(AppThemeModel theme) {
    HapticFeedback.selectionClick();
    final currentTheme = widget.controller.currentTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: currentTheme.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: currentTheme.textSecondaryColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.palette_rounded, color: theme.primaryColor, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          theme.name,
                          style: TextStyle(
                            color: currentTheme.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          theme.description,
                          style: TextStyle(color: currentTheme.textSecondaryColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Option 1: 30-Second Test Drive
              TactileButton(
                onTap: () {
                  Navigator.pop(ctx);
                  widget.controller.startThemeTestDrive(
                    theme.id,
                    onExpired: () => _showTestDriveExpiredDialog(theme),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.timer_rounded, color: Colors.amber, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ทดลองใช้งาน 30 วินาที (ฟรี)',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'สัมผัสธีมจริงในเครื่องก่อนตัดสินใจซื้อ',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Option 2: Buy this theme (29 THB)
              TactileButton(
                onTap: () async {
                  Navigator.pop(ctx);
                  await widget.controller.purchaseTheme(theme.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF059669),
                        content: Text('ซื้อธีม "${theme.name}" สำเร็จแล้ว! ใช้งานได้ตลอดชีพ 🎉'),
                      ),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: currentTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: currentTheme.primaryColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shopping_bag_rounded, color: currentTheme.primaryColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ซื้อเฉพาะธีมนี้ ฿${AppConfig.themePriceThb}',
                              style: TextStyle(
                                color: currentTheme.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'จ่ายครั้งเดียว ปลดล็อคธีมนี้ตลอดชีพ',
                              style: TextStyle(color: currentTheme.textSecondaryColor, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '฿${AppConfig.themePriceThb}',
                        style: TextStyle(
                          color: currentTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Option 3: Meow VIP (Unlock All)
              TactileButton(
                onTap: () {
                  Navigator.pop(ctx);
                  MeowPaywallModal.show(
                    context,
                    controller: widget.controller,
                    reason: 'สมัคร VIP เพื่อปลดล็อคทุกธีมและดึงสลิปไม่จำกัด',
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [currentTheme.primaryLight, currentTheme.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'อัปเกรด VIP (ปลดล็อคครบทุก 18 ธีมฟรี!)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final currentTheme = widget.controller.currentTheme;
        final isEn = widget.controller.isEnglish;
        final isDark = widget.controller.isDarkMode;

        return Scaffold(
          backgroundColor: currentTheme.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: currentTheme.scaffoldBackground,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: currentTheme.textColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              isEn ? 'Theme Shop (18 Themes)' : 'ศูนย์รวมธีม (18 ธีม)',
              style: TextStyle(
                color: currentTheme.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded, color: currentTheme.primaryColor),
                tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  widget.controller.setDarkMode(!isDark);
                },
              ),
            ],
            centerTitle: false,
          ),
          body: Column(
            children: [
              // 0. Active 30-Second Test Drive Banner
              ThemeTestDriveBanner(controller: widget.controller),

              // 1. Tab Bar for 3 streamlined categories
              Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                decoration: BoxDecoration(
                  color: currentTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: currentTheme.borderColor),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: currentTheme.textSecondaryColor,
                  indicator: BoxDecoration(
                    color: currentTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  padding: const EdgeInsets.all(4),
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  tabs: const [
                    Tab(text: '🏛️ คลาสสิค'),
                    Tab(text: '🪟 มินิมอล & Glass'),
                    Tab(text: '🐱 น่ารัก'),
                  ],
                ),
              ),

              // 2. Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildThemeGrid(ThemeCategory.classic, currentTheme, isEn, isDark),
                    _buildThemeGrid(ThemeCategory.minimal, currentTheme, isEn, isDark),
                    _buildThemeGrid(ThemeCategory.cute, currentTheme, isEn, isDark),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeGrid(ThemeCategory category, AppThemeModel currentTheme, bool isEn, bool isDark) {
    final themes = AppThemePresets.getThemesByCategory(category);

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: themes.length,
      itemBuilder: (context, idx) {
        final theme = themes[idx].copyWithMode(isDark);
        final isSelected = theme.id == widget.controller.currentThemeId;
        final isUnlocked = widget.controller.isThemeUnlocked(theme.id);

        return TactileButton(
          onTap: () {
            if (isUnlocked) {
              HapticFeedback.selectionClick();
              widget.controller.setTheme(theme.id);
            } else {
              _showLockedThemeOptions(theme);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? theme.primaryColor.withValues(alpha: 0.15) : currentTheme.cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? theme.primaryColor : currentTheme.borderColor,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? theme.primaryColor.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? theme.primaryColor.withValues(alpha: 0.15)
                            : Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isUnlocked ? (theme.seasonBadge ?? 'ธีม') : '🔒 ฿${AppConfig.themePriceThb}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? theme.primaryColor : Colors.orange.shade800,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 14, color: Colors.white),
                      )
                    else if (!isUnlocked)
                      const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.orange),
                  ],
                ),
                Text(
                  isEn ? theme.nameEn : theme.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? theme.primaryColor : currentTheme.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isEn ? theme.descriptionEn : theme.description,
                  style: TextStyle(
                    fontSize: 10,
                    color: currentTheme.textSecondaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: theme.previewDots.map((c) {
                    return Container(
                      margin: const EdgeInsets.only(right: 5),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
