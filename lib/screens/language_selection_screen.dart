import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../widgets/tactile_button.dart';
import '../widgets/app_logo_widget.dart';

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
    const bgColor = Color(0xFFF8FAFC);
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Modern Minimalist Logo with Glow
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const AppLogoWidget(
                    size: 80,
                    borderRadius: 20,
                    withBorder: false,
                    withShadow: false,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Step Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                ),
                child: Text(
                  isEn ? 'Step 1 of 4 • Select Language' : 'ขั้นตอนที่ 1/4 • เลือกภาษาการใช้งาน',
                  style: const TextStyle(
                    color: Color(0xFF0284C7),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Title & Subtitle (Clean & Minimalist Modern)
              Text(
                isEn ? 'Select Language' : 'เลือกภาษาการใช้งาน',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isEn
                    ? 'Choose your preferred language for MeowTang'
                    : 'ยินดีต้อนรับสู่เหมียวตังค์ กรุณาเลือกภาษาเพื่อเริ่มต้น',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),

              const Spacer(flex: 2),

              // Language Option 1: ภาษาไทย (Thai)
              _buildModernLangCard(
                langCode: 'th',
                flag: '🇹🇭',
                title: 'ภาษาไทย',
                subtitle: 'ระบบบันทึกรายรับรายจ่าย AI อัจฉริยะ',
                isSelected: _selectedLang == 'th',
                accentColor: const Color(0xFF0284C7),
              ),
              const SizedBox(height: 14),

              // Language Option 2: English
              _buildModernLangCard(
                langCode: 'en',
                flag: '🇬🇧',
                title: 'English',
                subtitle: 'Smart AI Expense & Income Tracker',
                isSelected: _selectedLang == 'en',
                accentColor: const Color(0xFF6366F1),
              ),

              const Spacer(flex: 3),

              // Modern Bottom Confirm Button
              TactileButton(
                onTap: _onConfirm,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isEn ? 'Continue →' : 'ดำเนินการต่อ →',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernLangCard({
    required String langCode,
    required String flag,
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color accentColor,
  }) {
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2.2 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: isSelected ? 16 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Flag Icon in circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? accentColor.withValues(alpha: 0.1) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? accentColor.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Center(
                child: Text(flag, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),

            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? accentColor : const Color(0xFF0F172A),
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Radio Indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accentColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? accentColor : const Color(0xFF94A3B8),
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
