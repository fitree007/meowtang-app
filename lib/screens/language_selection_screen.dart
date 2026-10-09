import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../widgets/tactile_button.dart';
import '../widgets/app_logo_widget.dart';
import '../widgets/onboarding_step_header.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final ExpenseController controller;
  final VoidCallback onCompleted;

  const LanguageSelectionScreen({
    super.key,
    required this.controller,
    required this.onCompleted,
  });

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLang = 'th';

  @override
  void initState() {
    super.initState();
    _selectedLang = widget.controller.appLanguage;
  }

  void _onConfirm() async {
    HapticFeedback.mediumImpact();
    await widget.controller.completeLanguageSelection(_selectedLang);
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final isEn = _selectedLang == 'en';
    final theme = widget.controller.currentTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: Column(
        children: [
          OnboardingStepHeader(
            controller: widget.controller,
            currentStep: 1,
            title: isEn ? 'Select Language' : 'เลือกภาษาการใช้งาน',
            subtitle: isEn
                ? 'Welcome to MeowTang. Pick a language to begin'
                : 'ยินดีต้อนรับสู่เหมียวตังค์ เลือกภาษาเพื่อเริ่มต้น',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.cardBackground,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
                    ),
                    child: const AppLogoWidget(size: 72, borderRadius: 18, withBorder: false, withShadow: false),
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                  child: Text(
                    isEn ? 'Language' : 'ภาษา',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textColor),
                  ),
                ),
                _buildModernLangCard(
                  langCode: 'th',
                  flag: '🇹🇭',
                  title: 'ภาษาไทย',
                  subtitle: 'ระบบบันทึกรายรับรายจ่าย AI อัจฉริยะ',
                  isSelected: _selectedLang == 'th',
                ),
                const SizedBox(height: 10),
                _buildModernLangCard(
                  langCode: 'en',
                  flag: '🇬🇧',
                  title: 'English',
                  subtitle: 'Smart AI Expense & Income Tracker',
                  isSelected: _selectedLang == 'en',
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    isEn ? 'You can change this later in Menu › Language.' : 'เปลี่ยนภาษาได้ภายหลังที่ เมนู › ภาษา',
                    style: TextStyle(fontSize: 12.5, color: theme.textSecondaryColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: OnboardingBottomBar(
        controller: widget.controller,
        nextLabel: isEn ? 'Next: choose a mascot' : 'ถัดไป: เลือกคู่หู',
        onNext: _onConfirm,
      ),
    );
  }

  Widget _buildModernLangCard({
    required String langCode,
    required String flag,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    final theme = widget.controller.currentTheme;
    final isDark = widget.controller.isDarkMode;
    final accentColor = theme.primaryColor;
    final accentText = isDark ? Color.lerp(accentColor, Colors.white, 0.55)! : accentColor;
    return TactileButton(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedLang = langCode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? Color.alphaBlend(accentColor.withValues(alpha: isDark ? 0.18 : 0.06), theme.cardBackground)
              : theme.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? accentColor : theme.borderColor.withValues(alpha: 0.6),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.scaffoldBackground,
                shape: BoxShape.circle,
                border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
              ),
              child: Center(
                child: Text(flag, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? accentText : theme.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: theme.textSecondaryColor, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accentColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? accentColor : theme.textSecondaryColor.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
