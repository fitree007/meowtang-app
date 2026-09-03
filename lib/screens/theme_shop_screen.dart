import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/app_theme_model.dart';
import '../widgets/tactile_button.dart';

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

  @override
  Widget build(BuildContext context) {
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
          // Light / Dark Mode Toggle button in AppBar
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
          // 1. Tab Bar for 3 streamlined categories
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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

        return TactileButton(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.controller.setTheme(theme.id);
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
                        color: theme.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        theme.seasonBadge ?? 'ธีม',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
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
                      ),
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
