import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/app_theme_model.dart';
import '../widgets/onboarding_step_header.dart';

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
    widget.onCompleted();
  }

  List<AppThemeModel> get _filteredThemes {
    return AppThemePresets.allThemes.where((t) => t.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isEn = widget.controller.isEnglish;
    final baseTheme = AppThemePresets.getById(_selectedThemeId);
    final activeTheme = baseTheme.copyWithMode(_isDark);
    final line = activeTheme.borderColor.withValues(alpha: 0.6);

    Widget sectionTitle(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: activeTheme.textColor)),
        );

    Widget segment(List<(String, IconData?, bool, VoidCallback)> options) => Container(
          height: 46,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: activeTheme.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: line),
          ),
          child: Row(
            children: [
              for (final o in options)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: o.$4,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: o.$3 ? activeTheme.primaryColor.withValues(alpha: _isDark ? 0.28 : 0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (o.$2 != null) ...[
                            Icon(o.$2, size: 16, color: o.$3 ? _accentText(activeTheme) : activeTheme.textSecondaryColor),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              o.$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: o.$3 ? FontWeight.w700 : FontWeight.w400,
                                color: o.$3 ? _accentText(activeTheme) : activeTheme.textSecondaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: activeTheme.scaffoldBackground,
      body: Column(
        children: [
          OnboardingStepHeader(
            controller: widget.controller,
            currentStep: 3,
            title: isEn ? 'Choose Your Style' : 'เลือกสไตล์และโหมด',
            subtitle: isEn
                ? 'Pick colours you like. You can change them later in the theme shop.'
                : 'เลือกสีที่ชอบ เปลี่ยนได้ภายหลังที่ร้านค้าธีม',
            onBack: widget.controller.revertToMascotOnboarding,
            trailing: OnboardingSkipButton(controller: widget.controller, onTap: _onFinish),
          ),
          Expanded(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              children: [
                _buildLiveMiniMockup(activeTheme, isEn),
                const SizedBox(height: 22),
                sectionTitle(isEn ? 'Display mode' : 'โหมดการแสดงผล'),
                segment([
                  (isEn ? 'Light' : 'สว่าง', Icons.light_mode_outlined, !_isDark, () => _onToggleMode(false)),
                  (isEn ? 'Dark' : 'มืด', Icons.dark_mode_outlined, _isDark, () => _onToggleMode(true)),
                ]),
                const SizedBox(height: 22),
                sectionTitle(isEn ? 'Style' : 'สไตล์'),
                segment([
                  for (final c in [
                    (ThemeCategory.classic, isEn ? 'Classic' : 'คลาสสิก'),
                    (ThemeCategory.minimal, isEn ? 'Minimal' : 'มินิมอล'),
                    (ThemeCategory.cute, isEn ? 'Cute' : 'น่ารัก'),
                  ])
                    (c.$2, null, _selectedCategory == c.$1, () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory = c.$1);
                    }),
                ]),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: _filteredThemes.length,
                  itemBuilder: (context, idx) {
                    final theme = _filteredThemes[idx].copyWithMode(_isDark);
                    final isSelected = theme.id == _selectedThemeId;
                    return GestureDetector(
                      onTap: () => _onSelectTheme(theme.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Color.alphaBlend(theme.primaryColor.withValues(alpha: _isDark ? 0.2 : 0.08), activeTheme.cardBackground)
                              : activeTheme.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? theme.primaryColor : line, width: isSelected ? 2 : 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                for (final c in theme.previewDots)
                                  Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: c,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: line),
                                    ),
                                  ),
                                const Spacer(),
                                if (isSelected)
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle),
                                    child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                  ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEn ? theme.nameEn : theme.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: activeTheme.textColor),
                                ),
                                if (theme.seasonBadge != null)
                                  Text(
                                    theme.seasonBadge!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 11.5, color: activeTheme.textSecondaryColor),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: OnboardingBottomBar(
        controller: widget.controller,
        nextLabel: isEn ? 'Next: highlights' : 'ถัดไป: จุดเด่นของแอป',
        onNext: _onFinish,
        onBack: widget.controller.revertToMascotOnboarding,
      ),
    );
  }

  Color _accentText(AppThemeModel t) => _isDark ? Color.lerp(t.primaryColor, Colors.white, 0.55)! : t.primaryColor;

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
