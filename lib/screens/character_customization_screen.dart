import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../widgets/meow_mascot_widget.dart';
import '../widgets/tactile_button.dart';
import '../widgets/custom_photo_avatar_dialog.dart';

class CharacterCustomizationScreen extends StatefulWidget {
  final ExpenseController controller;

  const CharacterCustomizationScreen({super.key, required this.controller});

  @override
  State<CharacterCustomizationScreen> createState() => _CharacterCustomizationScreenState();
}

class _CharacterCustomizationScreenState extends State<CharacterCustomizationScreen> with SingleTickerProviderStateMixin {
  late String _selectedMascotId;
  late String _selectedAccessory;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _selectedMascotId = widget.controller.selectedMascotId;
    _selectedAccessory = widget.controller.selectedMascotAccessory;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _saveMascot() async {
    HapticFeedback.mediumImpact();
    await widget.controller.updateMascot(
      _selectedMascotId,
      _selectedAccessory,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              widget.controller.isEnglish
                  ? 'Mascot updated successfully!'
                  : 'บันทึกมาสคอตและอุปกรณ์เรียบร้อยแล้ว!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: MeowTheme.incomeGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final isDark = widget.controller.isDarkMode;
    final isEn = widget.controller.isEnglish;
    final bgColor = isDark ? MeowTheme.navyBackground : const Color(0xFFF8FAFC);
    final cardBg = isDark ? MeowTheme.navySurface : Colors.white;
    final textPrimary = isDark ? MeowTheme.textLightPrimary : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? MeowTheme.borderColor : const Color(0xFFE2E8F0);

    final isCustomPhoto = widget.controller.isCustomAvatarEnabled;
    final customPhoto = widget.controller.customAvatarPath;

    final currentMascot = MascotCatalog.characters.firstWhere(
      (m) => m.id == _selectedMascotId,
      orElse: () => MascotCatalog.characters.first,
    );

    final currentAcc = MascotCatalog.accessories.firstWhere(
      (a) => a.id == _selectedAccessory,
      orElse: () => MascotCatalog.accessories.first,
    );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: MeowTheme.mustardYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: MeowTheme.textDarkPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEn ? 'Dressing & Accessories' : 'แต่งตัวมาสคอต & อุปกรณ์คู่กาย',
          style: const TextStyle(
            color: MeowTheme.textDarkPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP FIXED STAGE: Mascot Avatar + Real-time Preview (Never scrolls away)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: MeowTheme.mustardYellow.withValues(alpha: isDark ? 0.4 : 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: MeowTheme.mustardYellow.withValues(alpha: 0.14),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Live Mascot Avatar Stage
                  GestureDetector(
                    onTap: _openCustomPhotoDialog,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.08),
                            boxShadow: [
                              BoxShadow(
                                color: currentMascot.primaryColor.withValues(alpha: 0.28),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: MeowMascotWidget(
                              size: 80,
                              mascotId: _selectedMascotId,
                              accessory: _selectedAccessory,
                              customPhotoPath: customPhoto,
                              isCustomPhoto: isCustomPhoto,
                              withPen: false,
                              animate: true,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Mascot & Customization Summary
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                isCustomPhoto
                                    ? (isEn ? 'My Custom Avatar' : 'รูปถ่ายของฉัน')
                                    : currentMascot.name.split('(').first.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark ? Colors.white : MeowTheme.textDarkPrimary,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isCustomPhoto)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: MeowTheme.actionBlue,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isEn ? 'Photo' : 'รูปถ่าย',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isCustomPhoto
                              ? (isEn ? 'Tap photo to change avatar' : 'แตะรูปเพื่อเปลี่ยนภาพโปรไฟล์')
                              : currentMascot.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : MeowTheme.textDarkSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Active Accessory Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: MeowTheme.mustardYellow.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: MeowTheme.mustardYellowDark.withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AccessoryVisualWidget(accessoryId: _selectedAccessory, size: 13, color: MeowTheme.mustardYellowDark),
                              const SizedBox(width: 5),
                              Text(
                                currentAcc.name,
                                style: const TextStyle(
                                  color: MeowTheme.mustardYellowDark,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. SEGMENTED TAB BAR (3 Tabs: Characters, Outfits, Accessories)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: MeowTheme.mustardYellow,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: MeowTheme.mustardYellow.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: MeowTheme.textDarkPrimary,
                unselectedLabelColor: textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.pets_rounded, size: 15),
                        const SizedBox(width: 4),
                        Text(isEn ? 'Characters' : 'ตัวละคร (${MascotCatalog.characters.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.stars_rounded, size: 15),
                        const SizedBox(width: 4),
                        Text(isEn ? 'Accessories' : 'อุปกรณ์ (${MascotCatalog.accessories.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. TAB VIEWS CONTENT (Smooth Scrolling & Responsive Grid)
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Mascot Characters Grid
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.88,
                      ),
                      itemCount: MascotCatalog.characters.length,
                      itemBuilder: (context, index) {
                        final character = MascotCatalog.characters[index];
                        final isSelected = !isCustomPhoto && _selectedMascotId == character.id;

                        return TactileButton(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            widget.controller.setCustomAvatarEnabled(false);
                            setState(() {
                              _selectedMascotId = character.id;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF))
                                  : cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? MeowTheme.actionBlue : borderColor,
                                width: isSelected ? 2.0 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? MeowTheme.actionBlue.withValues(alpha: 0.2)
                                      : Colors.black.withValues(alpha: 0.03),
                                  blurRadius: isSelected ? 8 : 2,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: MeowMascotWidget(
                                    size: 44,
                                    mascotId: character.id,
                                    isHeadOnly: false,
                                    withPen: false,
                                    animate: isSelected,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  character.name.split('(').first.trim(),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected ? MeowTheme.actionBlue : textPrimary,
                                    fontSize: 10.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Tab 2: Accessories Grid (อุปกรณ์คู่กาย)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.88,
                      ),
                      itemCount: MascotCatalog.accessories.length,
                      itemBuilder: (context, index) {
                        final acc = MascotCatalog.accessories[index];
                        final isSelected = _selectedAccessory == acc.id;

                        return TactileButton(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedAccessory = acc.id;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF))
                                  : cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? MeowTheme.actionBlue : borderColor,
                                width: isSelected ? 2.0 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? MeowTheme.actionBlue.withValues(alpha: 0.2)
                                      : Colors.black.withValues(alpha: 0.03),
                                  blurRadius: isSelected ? 8 : 2,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 38,
                                  height: 38,
                                  child: Center(
                                    child: AccessoryVisualWidget(
                                      accessoryId: acc.id,
                                      size: 30,
                                      color: isSelected ? MeowTheme.actionBlue : const Color(0xFFF59E0B),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  acc.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected ? MeowTheme.actionBlue : textPrimary,
                                    fontSize: 10.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 4. BOTTOM ACTION BAR (Pinned Save Button)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(top: BorderSide(color: borderColor, width: 0.8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: TactileButton(
                onTap: _saveMascot,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: MeowTheme.mustardYellow,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: MeowTheme.mustardYellow.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: MeowTheme.textDarkPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isEn ? 'Save Mascot Style' : 'บันทึกสไตล์มาสคอต',
                        style: const TextStyle(
                          color: MeowTheme.textDarkPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
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
    );
  }
}
