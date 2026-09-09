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
    await widget.controller.updateMascot(_selectedMascotId, _selectedAccessory);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              widget.controller.isEnglish
                  ? 'Mascot character updated successfully!'
                  : 'ปรับแต่งตัวละครมาสคอตเรียบร้อยแล้ว!',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: MeowTheme.textDarkPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEn ? 'Dressing & Accessories' : 'แต่งตัวมาสคอต & อุปกรณ์คู่กาย',
          style: const TextStyle(
            color: MeowTheme.textDarkPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP SECTION: Fixed Live Mascot Stage (No vertical scrolling needed!)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: MeowTheme.mustardYellow.withValues(alpha: isDark ? 0.4 : 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: MeowTheme.mustardYellow.withValues(alpha: 0.15),
                    blurRadius: 14,
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
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.08),
                            boxShadow: [
                              BoxShadow(
                                color: currentMascot.primaryColor.withValues(alpha: 0.3),
                                blurRadius: 14,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: MeowMascotWidget(
                              size: 88,
                              mascotId: _selectedMascotId,
                              accessory: _selectedAccessory,
                              customPhotoPath: customPhoto,
                              isCustomPhoto: isCustomPhoto,
                              withPen: true,
                              animate: true,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Mascot & Accessory Status
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
                                    : currentMascot.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark ? Colors.white : MeowTheme.textDarkPrimary,
                                  fontSize: 16,
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
                                  style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isCustomPhoto
                              ? (isEn ? 'Custom user avatar active' : 'ใช้งานรูปโปรไฟล์ส่วนตัว')
                              : currentMascot.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : MeowTheme.textDarkSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: MeowTheme.mustardYellow.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(currentAcc.icon, size: 12, color: MeowTheme.mustardYellowDark),
                                  const SizedBox(width: 4),
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
                            const Spacer(),
                            // Quick button to pick custom photo
                            InkWell(
                              onTap: _openCustomPhotoDialog,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      isEn ? 'Use My Photo' : 'ใส่รูปตัวเอง 📷',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. MIDDLE SECTION: Segmented Tab Bar (Characters vs Accessories)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: MeowTheme.mustardYellow,
                  borderRadius: BorderRadius.circular(12),
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
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.pets, size: 16),
                        const SizedBox(width: 6),
                        Text(isEn ? '1. Mascot Characters' : '1. เลือกตัวละคร (${MascotCatalog.characters.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flare, size: 16),
                        const SizedBox(width: 6),
                        Text(isEn ? '2. Accessories' : '2. อุปกรณ์คู่กาย (${MascotCatalog.accessories.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. TAB VIEW CONTENT (Fixed Viewport, Super Convenient Grid Selection without scrolling page)
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Mascot Characters Grid
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.96,
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
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF))
                                  : cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? MeowTheme.actionBlue : borderColor,
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? MeowTheme.actionBlue.withValues(alpha: 0.25)
                                      : Colors.black.withValues(alpha: 0.03),
                                  blurRadius: isSelected ? 8 : 3,
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
                                    isHeadOnly: true,
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
                                    fontSize: 11,
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

                  // Tab 2: Accessories Grid
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.05,
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
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF))
                                  : cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? MeowTheme.actionBlue : borderColor,
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? MeowTheme.actionBlue.withValues(alpha: 0.25)
                                      : Colors.black.withValues(alpha: 0.03),
                                  blurRadius: isSelected ? 8 : 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  acc.icon,
                                  color: isSelected ? MeowTheme.actionBlue : const Color(0xFFF59E0B),
                                  size: 24,
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
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
                      const Icon(Icons.check_circle_rounded, color: MeowTheme.textDarkPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isEn ? 'Save Mascot Style' : 'บันทึกสไตล์มาสคอต',
                        style: const TextStyle(
                          color: MeowTheme.textDarkPrimary,
                          fontSize: 15.5,
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
