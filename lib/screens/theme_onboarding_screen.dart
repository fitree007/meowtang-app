import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/app_theme_model.dart';
import 'app_features_showcase_screen.dart';

class ThemeOnboardingScreen extends StatefulWidget {
  final ExpenseController controller;
  final VoidCallback onCompleted;

  const ThemeOnboardingScreen({
    super.key,
    required this.controller,
    required this.onCompleted,
  });

  @override
  State<ThemeOnboardingScreen> createState() => _ThemeOnboardingScreenState();
}

class _ThemeOnboardingScreenState extends State<ThemeOnboardingScreen> {
  late String _selectedThemeId;
  late bool _isDark;
  ThemeCategory _selectedCategory = ThemeCategory.classic;

  @override
  void initState() {
    super.initState();
    _selectedThemeId = widget.controller.currentThemeId;
    _isDark = widget.controller.isDarkMode;
    final currentTheme = AppThemePresets.getById(_selectedThemeId);
    _selectedCategory = currentTheme.category;
  }

  void _onSelectTheme(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedThemeId = id;
    });
    widget.controller.setTheme(id);
  }

  void _onToggleMode(bool dark) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isDark = dark;
    });
    widget.controller.setDarkMode(dark);
  }

  void _onFinish() async {
    HapticFeedback.heavyImpact();
    await widget.controller.completeThemeOnboarding(_selectedThemeId, _isDark);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AppFeaturesShowcaseScreen(
          controller: widget.controller,
          onCompleted: widget.onCompleted,
        ),
      ),
    );
  }

  List<AppThemeModel> get _filteredThemes {
    return AppThemePresets.allThemes.where((t) => t.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isEn = widget.controller.isEnglish;
    final baseTheme = AppThemePresets.getById(_selectedThemeId);
    final activeTheme = baseTheme.copyWithMode(_isDark);

    return Scaffold(
      backgroundColor: activeTheme.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header Info with Step Badge & Skip
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: activeTheme.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: activeTheme.primaryColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.palette_rounded, color: activeTheme.primaryColor, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              isEn ? 'Step 3/4 • Theme' : 'ขั้นตอนที่ 3/4 • เลือกธีมแอพ',
                              style: TextStyle(
                                color: activeTheme.primaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEn ? 'Choose Your Style & Mode' : 'เลือกสไตล์และโหมดการแสดงผล',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: activeTheme.textColor,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _onFinish,
                    child: Text(
                      isEn ? 'Skip' : 'ข้าม',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: activeTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Light / Dark Mode Toggle Buttons (Dual Mode for all 18 themes)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onToggleMode(false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !_isDark ? activeTheme.cardBackground : activeTheme.surfaceBackground.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: !_isDark ? activeTheme.primaryColor : activeTheme.borderColor,
                            width: !_isDark ? 2.0 : 1.0,
                          ),
                          boxShadow: !_isDark
                              ? [
                                  BoxShadow(
                                    color: activeTheme.primaryColor.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.wb_sunny_rounded, color: Color(0xFFF59E0B), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              isEn ? 'Light Mode' : 'โหมดสว่าง ☀️',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: !_isDark ? activeTheme.textColor : activeTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onToggleMode(true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _isDark ? activeTheme.cardBackground : activeTheme.surfaceBackground.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isDark ? activeTheme.primaryColor : activeTheme.borderColor,
                            width: _isDark ? 2.0 : 1.0,
                          ),
                          boxShadow: _isDark
                              ? [
                                  BoxShadow(
                                    color: activeTheme.primaryColor.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.nightlight_round, color: Color(0xFF818CF8), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              isEn ? 'Dark Mode' : 'โหมดมืด 🌙',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _isDark ? activeTheme.textColor : activeTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // 3. Live Mini App Preview Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              child: _buildLiveMiniMockup(activeTheme, isEn),
            ),
            const SizedBox(height: 8),

            // 4. Category Selector Tabs (3 Categories: Classic, Minimal & Glass, Cute)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: activeTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: activeTheme.borderColor),
                ),
                child: Row(
                  children: [
                    _buildCategoryTab(ThemeCategory.classic, '🏛️ คลาสสิค', activeTheme),
                    _buildCategoryTab(ThemeCategory.minimal, '🪟 มินิมอล & Glass', activeTheme),
                    _buildCategoryTab(ThemeCategory.cute, '🐱 น่ารัก & พาสเทล', activeTheme),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 5. Themes Grid (6 themes per category, clean and easy to pick)
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.45,
                ),
                itemCount: _filteredThemes.length,
                itemBuilder: (context, idx) {
                  final theme = _filteredThemes[idx].copyWithMode(_isDark);
                  final isSelected = theme.id == _selectedThemeId;

                  return GestureDetector(
                    onTap: () => _onSelectTheme(theme.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.primaryColor.withValues(alpha: 0.15)
                            : activeTheme.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? theme.primaryColor : activeTheme.borderColor,
                          width: isSelected ? 2.0 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? theme.primaryColor.withValues(alpha: 0.22)
                                : Colors.black.withValues(alpha: 0.03),
                            blurRadius: isSelected ? 8 : 2,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top: Badge and Selection Tick
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  theme.seasonBadge ?? 'ธีม',
                                  style: TextStyle(
                                    fontSize: 9.5,
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
                                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                                ),
                            ],
                          ),

                          // Center: Theme Name
                          Text(
                            isEn ? theme.nameEn : theme.name,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? theme.primaryColor : activeTheme.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Bottom: Palette Color Dots
                          Row(
                            children: theme.previewDots.map((c) {
                              return Container(
                                margin: const EdgeInsets.only(right: 5),
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.2),
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
              ),
            ),

            // 6. Bottom Confirm Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _onFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  iconAlignment: IconAlignment.end,
                  label: Text(
                    isEn ? 'Confirm Theme & Continue' : 'ใช้ธีมนี้และไปต่อ (4/4)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTab(ThemeCategory category, String label, AppThemeModel activeTheme) {
    final isSelected = _selectedCategory == category;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedCategory = category);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : activeTheme.textSecondaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveMiniMockup(AppThemeModel theme, bool isEn) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.borderColor),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: theme.heroGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ตัวอย่างการแสดงผลจริง',
                      style: TextStyle(fontSize: 11, color: theme.textSecondaryColor),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.incomeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+฿12,500',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.incomeColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isEn ? theme.nameEn : theme.name,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textColor),
                ),
                Text(
                  isEn ? theme.descriptionEn : theme.description,
                  style: TextStyle(fontSize: 10, color: theme.textSecondaryColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
