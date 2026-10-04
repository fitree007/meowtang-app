import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../widgets/meow_mascot_widget.dart';
import '../widgets/tactile_button.dart';
import '../widgets/custom_photo_avatar_dialog.dart';
import '../widgets/meow_paywall_modal.dart';
import '../widgets/onboarding_step_header.dart';
import '../config/app_config.dart';

class MascotOnboardingScreen extends StatefulWidget {
  final ExpenseController controller;
  final VoidCallback onCompleted;

  const MascotOnboardingScreen({
    super.key,
    required this.controller,
    required this.onCompleted,
  });

  @override
  State<MascotOnboardingScreen> createState() => _MascotOnboardingScreenState();
}

class _MascotOnboardingScreenState extends State<MascotOnboardingScreen> {
  late String _selectedMascotId;
  late String _selectedAccessory;
  late String _selectedOutfit;

  // Active tab: 0 = มาสคอต 22, 1 = อุปกรณ์ 36
  int _activeTabIndex = 0;

  // Filter chips
  String _mascotCategoryFilter = 'all'; // 'all', 'cat', 'friend', 'ai'
  String _accCategoryFilter = 'all'; // 'all', 'acc', 'outfit'

  @override
  void initState() {
    super.initState();
    _selectedMascotId = widget.controller.selectedMascotId;
    _selectedAccessory = widget.controller.selectedMascotAccessory;
    _selectedOutfit = widget.controller.selectedMascotOutfit;

    // If initial accessory is empty, auto-equip signature accessory
    final initialMascot = MascotCatalog.characters.firstWhere(
      (m) => m.id == _selectedMascotId,
      orElse: () => MascotCatalog.characters.first,
    );
    if (_selectedAccessory.isEmpty || _selectedAccessory == 'pen') {
      _selectedAccessory = initialMascot.signatureAccessory;
    }
    if (_selectedOutfit.isEmpty || _selectedOutfit == 'none') {
      _selectedOutfit = initialMascot.signatureOutfit;
    }
  }

  void _onFinish() async {
    HapticFeedback.heavyImpact();
    await widget.controller.completeMascotOnboarding(
      _selectedMascotId,
      _selectedAccessory,
      outfit: _selectedOutfit,
    );
    widget.onCompleted();
  }

  void _openCustomPhotoDialog() {
    HapticFeedback.selectionClick();
    CustomPhotoAvatarDialog.show(
      context,
      widget.controller,
      onSaved: (path) {
        setState(() {});
      },
    );
  }

  void _resetToSignature() {
    HapticFeedback.selectionClick();
    final current = MascotCatalog.characters.firstWhere(
      (m) => m.id == _selectedMascotId,
      orElse: () => MascotCatalog.characters.first,
    );
    setState(() {
      _selectedAccessory = current.signatureAccessory;
      _selectedOutfit = current.signatureOutfit;
    });
  }

  void _showLockedIconOptions(MascotInfo character) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  MeowMascotWidget(size: 44, mascotId: character.id, isHeadOnly: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          character.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          character.subtitle,
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TactileButton(
                onTap: () async {
                  Navigator.pop(ctx);
                  await widget.controller.purchaseIcon(character.id);
                  setState(() => _selectedMascotId = character.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF059669),
                        content: Text('ปลดล็อคไอคอน "${character.name}" สำเร็จ! ใช้งานได้ตลอดชีพ 🎉'),
                      ),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: MeowTheme.actionBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: MeowTheme.actionBlue.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_bag_rounded, color: MeowTheme.actionBlue, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'ซื้อเฉพาะไอคอนนี้ ฿${AppConfig.iconPriceThb}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      Text(
                        '฿${AppConfig.iconPriceThb}',
                        style: const TextStyle(color: MeowTheme.actionBlue, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TactileButton(
                onTap: () {
                  Navigator.pop(ctx);
                  MeowPaywallModal.show(
                    context,
                    controller: widget.controller,
                    reason: 'สมัคร VIP เพื่อปลดล็อคทุกไอคอนและทุกธีมฟรี 👑',
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'อัปเกรด VIP (ปลดล็อคครบทุกไอคอนฟรี!)',
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

  String _getCategoryTag(String id) {
    if (id.startsWith('cat_')) return 'แมว';
    if (id == 'robot_ai') return 'AI';
    return 'เพื่อนสัตว์';
  }

  @override
  Widget build(BuildContext context) {
    final isEn = widget.controller.isEnglish;
    final isCustomPhoto = widget.controller.isCustomAvatarEnabled;
    final customPhoto = widget.controller.customAvatarPath;

    const bgColor = Color(0xFFFDFBF7);
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);

    final currentMascot = MascotCatalog.characters.firstWhere(
      (m) => m.id == _selectedMascotId,
      orElse: () => MascotCatalog.characters.first,
    );

    final currentAcc = MascotCatalog.accessories.firstWhere(
      (a) => a.id == _selectedAccessory,
      orElse: () => MascotCatalog.accessories.first,
    );

    final currentMascotIndex = MascotCatalog.characters.indexWhere((m) => m.id == _selectedMascotId);

    // Parse English title if enclosed in parentheses
    String thaiName = currentMascot.name;
    String enName = '';
    final parenMatch = RegExp(r'^(.*?)\s*\((.*?)\)$').firstMatch(currentMascot.name);
    if (parenMatch != null) {
      thaiName = parenMatch.group(1)?.trim() ?? currentMascot.name;
      enName = parenMatch.group(2)?.trim() ?? '';
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header with 4-Segment Bar (รูปแนบ 2)
            OnboardingStepHeader(
              currentStep: 2,
              totalSteps: 4,
              badgeText: isEn ? 'Step 2/4 • Mascot' : 'ขั้นตอนที่ 2/4 • เลือกคู่หู',
              stepIcon: Icons.pets_rounded,
              title: isEn ? 'Choose Your Mascot' : 'เลือกคู่หูประจำตัว',
              subtitle: isEn
                  ? 'Your companion will stay with you on the main screen'
                  : 'คู่หูจะอยู่กับคุณในหน้าหลัก เปลี่ยนตัวได้ทุกเมื่อในเมนูตัวละคร',
              primaryColor: MeowTheme.mustardYellowDark,
              textColor: textPrimary,
              subtitleColor: textSecondary,
              onBack: () async {
                HapticFeedback.selectionClick();
                await widget.controller.revertToLanguageSelection();
              },
            ),

            // 2. FIXED Hero Mascot Showcase Card (รูปแนบ 3)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF1ECE1), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Top Row: Index Badge & [ เลือกรูปของฉัน ] & Category Tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F6F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${currentMascotIndex >= 0 ? currentMascotIndex + 1 : 1} / ${MascotCatalog.characters.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF786C59),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TactileButton(
                            onTap: _openCustomPhotoDialog,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: isCustomPhoto ? const Color(0xFFFEF3C7) : const Color(0xFFF8F6F0),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isCustomPhoto ? MeowTheme.mustardYellowDark : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_rounded,
                                    size: 11.5,
                                    color: isCustomPhoto ? const Color(0xFFB45309) : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isEn ? 'My Photo' : 'เลือกรูปของฉัน',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isCustomPhoto ? const Color(0xFFB45309) : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getCategoryTag(currentMascot.id),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Mascot Avatar in circular warm backdrop
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFEF3C7),
                          boxShadow: [
                            BoxShadow(
                              color: MeowTheme.mustardYellow.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: MeowMascotWidget(
                          size: 66,
                          mascotId: currentMascot.id,
                          accessory: _selectedAccessory,
                          outfit: _selectedOutfit,
                          customPhotoPath: customPhoto,
                          isCustomPhoto: isCustomPhoto,
                          animate: true,
                        ),
                      ),
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFF59E0B), width: 1.8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            currentAcc.icon,
                            size: 14,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    thaiName,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (enName.isNotEmpty) ...[
                    Text(
                      enName,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    currentMascot.subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, size: 12, color: Color(0xFFD97706)),
                        const SizedBox(width: 4),
                        Text(
                          'อุปกรณ์ประจำตัว: ${MascotCatalog.accessories.firstWhere((a) => a.id == currentMascot.signatureAccessory, orElse: () => MascotCatalog.accessories.first).name}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. FIXED SEGMENTED SWITCH: [ 🐾 มาสคอต 22 | ✨ อุปกรณ์ 36 ]
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EDE3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    // Tab 1: มาสคอต 22
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _activeTabIndex = 0);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _activeTabIndex == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _activeTabIndex == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pets_rounded,
                                size: 14,
                                color: _activeTabIndex == 0 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isEn ? 'Mascot 22' : 'มาสคอต 22',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: _activeTabIndex == 0 ? FontWeight.bold : FontWeight.w600,
                                  color: _activeTabIndex == 0 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Tab 2: อุปกรณ์ 36
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _activeTabIndex = 1);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _activeTabIndex == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _activeTabIndex == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 14,
                                color: _activeTabIndex == 1 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isEn ? 'Accessory 36' : '✨ อุปกรณ์ 36',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: _activeTabIndex == 1 ? FontWeight.bold : FontWeight.w600,
                                  color: _activeTabIndex == 1 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
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
            ),

            // 4. SCROLLABLE GRID ONLY (เฉพาะส่วนนี้ที่จะเลื่อน)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    if (_activeTabIndex == 0) ...[
                      // Mascot Filters: ทั้งหมด 21, แมว 13, เพื่อนสัตว์ 7, AI 1
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildFilterChip('all', isEn ? 'All 21' : 'ทั้งหมด 21', _mascotCategoryFilter, (val) {
                              setState(() => _mascotCategoryFilter = val);
                            }),
                            const SizedBox(width: 6),
                            _buildFilterChip('cat', isEn ? 'Cats 13' : 'แมว 13', _mascotCategoryFilter, (val) {
                              setState(() => _mascotCategoryFilter = val);
                            }),
                            const SizedBox(width: 6),
                            _buildFilterChip('friend', isEn ? 'Animals 7' : 'เพื่อนสัตว์ 7', _mascotCategoryFilter, (val) {
                              setState(() => _mascotCategoryFilter = val);
                            }),
                            const SizedBox(width: 6),
                            _buildFilterChip('ai', isEn ? 'AI 1' : 'AI 1', _mascotCategoryFilter, (val) {
                              setState(() => _mascotCategoryFilter = val);
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 4-Column Mascot Grid
                      _buildMascotGrid(),
                    ] else ...[
                      // Accessories Filters: ทั้งหมด 36, อุปกรณ์ 30, ชุด 6
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildFilterChip('all', isEn ? 'All 36' : 'ทั้งหมด 36', _accCategoryFilter, (val) {
                              setState(() => _accCategoryFilter = val);
                            }),
                            const SizedBox(width: 6),
                            _buildFilterChip('acc', isEn ? 'Items 30' : '✨ อุปกรณ์ 30', _accCategoryFilter, (val) {
                              setState(() => _accCategoryFilter = val);
                            }),
                            const SizedBox(width: 6),
                            _buildFilterChip('outfit', isEn ? 'Outfits 6' : '👗 ชุด 6', _accCategoryFilter, (val) {
                              setState(() => _accCategoryFilter = val);
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 4-Column Accessories & Outfits Grid
                      _buildDressingGrid(),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // 5. FIXED BOTTOM BAR WITH BACK & CONFIRM BUTTONS
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.04))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 50,
                    child: Row(
                      children: [
                        // Back Button (35%)
                        Expanded(
                          flex: 35,
                          child: TactileButton(
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              await widget.controller.revertToLanguageSelection();
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF334155)),
                                  const SizedBox(width: 4),
                                  Text(
                                    isEn ? 'Back' : 'ย้อนกลับ',
                                    style: const TextStyle(
                                      color: Color(0xFF334155),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Confirm Button (65%)
                        Expanded(
                          flex: 65,
                          child: TactileButton(
                            onTap: _onFinish,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: MeowTheme.mustardYellow,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: MeowTheme.mustardYellow.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _activeTabIndex == 0
                                          ? (isEn ? 'Select $thaiName ➔' : 'เลือก $thaiName ➔')
                                          : (isEn ? 'Save Dressing' : '✔ บันทึกการแต่งตัว'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
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
                  ),

                  // If in tab 1 (Dressing), show reset button below
                  if (_activeTabIndex == 1) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _resetToSignature,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.replay_rounded, size: 14, color: textSecondary),
                            const SizedBox(width: 5),
                            Text(
                              isEn ? 'Reset to signature accessory' : 'รีเซ็ตเป็นอุปกรณ์ประจำตัวดั้งเดิม',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, String currentSelected, ValueChanged<String> onSelected) {
    final bool isSelected = currentSelected == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onSelected(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildMascotGrid() {
    final filtered = MascotCatalog.characters.where((m) {
      if (_mascotCategoryFilter == 'cat') return m.id.startsWith('cat_');
      if (_mascotCategoryFilter == 'ai') return m.id == 'robot_ai';
      if (_mascotCategoryFilter == 'friend') return !m.id.startsWith('cat_') && m.id != 'robot_ai';
      return true;
    }).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.82,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final character = filtered[index];
        final isSelected = _selectedMascotId == character.id;
        final isUnlocked = widget.controller.isMascotUnlocked(character.id);

        String shortName = character.name;
        final paren = character.name.indexOf('(');
        if (paren > 0) {
          shortName = character.name.substring(0, paren).replaceAll('เหมี่ยว', '').replaceAll('แมว', '').trim();
        }

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            if (!isUnlocked) {
              _showLockedIconOptions(character);
              return;
            }
            setState(() {
              _selectedMascotId = character.id;
              // AUTO-EQUIP SIGNATURE ACCESSORY!
              _selectedAccessory = character.signatureAccessory;
              _selectedOutfit = character.signatureOutfit;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFFDF5) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFF1ECE1),
                width: isSelected ? 2.0 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? const Color(0xFFF59E0B).withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Selection Checkmark
                if (isSelected)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F172A),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.check, size: 10, color: Colors.white),
                    ),
                  ),

                // Lock icon if not unlocked
                if (!isUnlocked)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_rounded, size: 11, color: Colors.amber),
                    ),
                  ),

                // Mascot Icon & Name
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF4E7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: MeowMascotWidget(
                          size: 34,
                          mascotId: character.id,
                          isHeadOnly: true,
                          animate: false,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          shortName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDressingGrid() {
    final List<Map<String, dynamic>> items = [];

    // Add accessories
    if (_accCategoryFilter == 'all' || _accCategoryFilter == 'acc') {
      for (final a in MascotCatalog.accessories) {
        items.add({
          'id': a.id,
          'name': a.name,
          'icon': a.icon,
          'isAccessory': true,
        });
      }
    }

    // Add outfits (excluding 'none')
    if (_accCategoryFilter == 'all' || _accCategoryFilter == 'outfit') {
      for (final o in MascotCatalog.outfits) {
        if (o.id == 'none') continue;
        items.add({
          'id': o.id,
          'name': o.name,
          'icon': o.icon,
          'isAccessory': false,
        });
      }
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isAcc = item['isAccessory'] as bool;
        final String itemId = item['id'] as String;
        final String itemName = item['name'] as String;
        final IconData itemIcon = item['icon'] as IconData;

        final bool isSelected = isAcc
            ? _selectedAccessory == itemId
            : _selectedOutfit == itemId;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (isAcc) {
                _selectedAccessory = itemId;
              } else {
                _selectedOutfit = itemId;
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFFDF5) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFF1ECE1),
                width: isSelected ? 2.0 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? const Color(0xFFF59E0B).withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                if (isSelected)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F172A),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.check, size: 10, color: Colors.white),
                    ),
                  ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF4E7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          itemIcon,
                          size: 22,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          itemName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
