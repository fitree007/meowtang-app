import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../widgets/meow_mascot_widget.dart';
import '../widgets/tactile_button.dart';
import '../widgets/custom_photo_avatar_dialog.dart';

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

class _MascotOnboardingScreenState extends State<MascotOnboardingScreen> with SingleTickerProviderStateMixin {
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

  void _onFinish() async {
    HapticFeedback.heavyImpact();
    await widget.controller.completeMascotOnboarding(_selectedMascotId, _selectedAccessory);
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

  @override
  Widget build(BuildContext context) {
    final isEn = widget.controller.isEnglish;
    final isCustomPhoto = widget.controller.isCustomAvatarEnabled;
    final customPhoto = widget.controller.customAvatarPath;

    const bgColor = Color(0xFFF8FAFC);
    const cardBg = Colors.white;
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);
    const borderColor = Color(0xFFE2E8F0);

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
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header Bar with Step Badge
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: MeowTheme.mustardYellow.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: MeowTheme.mustardYellow.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.stars_rounded, color: MeowTheme.mustardYellowDark, size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    isEn ? 'Step 2/4 • Mascot' : 'ขั้นตอนที่ 2/4 • เลือกคู่หู',
                                    style: const TextStyle(
                                      color: MeowTheme.mustardYellowDark,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEn ? 'Choose Your Mascot' : 'เลือกคู่หูมาสคอตประจำตัว',
                          style: const TextStyle(
                            color: textPrimary,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          isEn ? 'Pick a character & customize outfit' : 'เลือกตัวละครและอุปกรณ์คู่กายได้ตามใจชอบ',
                          style: const TextStyle(color: textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Interactive Live Mascot Stage (No text overflow)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFFBEB),
                    Color(0xFFFEF3C7),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: MeowTheme.mustardYellow.withValues(alpha: 0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: MeowTheme.mustardYellow.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.08),
                      boxShadow: [
                        BoxShadow(
                          color: currentMascot.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: MeowMascotWidget(
                        size: 72,
                        mascotId: _selectedMascotId,
                        accessory: _selectedAccessory,
                        customPhotoPath: customPhoto,
                        isCustomPhoto: isCustomPhoto,
                        withPen: true,
                        animate: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                                style: const TextStyle(
                                  color: textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isCustomPhoto)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
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
                              ? (isEn ? 'Custom avatar is active' : 'ใช้งานรูปถ่ายส่วนตัว')
                              : currentMascot.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: textSecondary, fontSize: 11),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: MeowTheme.mustardYellow.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(currentAcc.icon, size: 11, color: MeowTheme.mustardYellowDark),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        currentAcc.name,
                                        style: const TextStyle(
                                          color: MeowTheme.mustardYellowDark,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _openCustomPhotoDialog,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add_a_photo, size: 11, color: textPrimary),
                                    const SizedBox(width: 3),
                                    Text(
                                      isEn ? 'Use Photo' : 'ใส่รูปเอง',
                                      style: const TextStyle(color: textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
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

            // 3. Segmented Tab Bar (Characters & Accessories)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
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
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: MeowTheme.textDarkPrimary,
                unselectedLabelColor: textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.pets, size: 14),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            isEn ? '1. Mascot (${MascotCatalog.characters.length})' : '1. ตัวละคร (${MascotCatalog.characters.length})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flare, size: 14),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            isEn ? '2. Items (${MascotCatalog.accessories.length})' : '2. อุปกรณ์ (${MascotCatalog.accessories.length})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 4. Tab View with smooth grids
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Characters Grid
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.98,
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
                              color: isSelected ? const Color(0xFFEFF6FF) : cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? MeowTheme.actionBlue : borderColor,
                                width: isSelected ? 2.2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? MeowTheme.actionBlue.withValues(alpha: 0.22)
                                      : Colors.black.withValues(alpha: 0.02),
                                  blurRadius: isSelected ? 6 : 2,
                                  offset: const Offset(0, 1.5),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: MeowMascotWidget(
                                    size: 42,
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

                  // Tab 2: Accessories Grid
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
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
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEFF6FF) : cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? MeowTheme.actionBlue : borderColor,
                                width: isSelected ? 2.2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? MeowTheme.actionBlue.withValues(alpha: 0.22)
                                      : Colors.black.withValues(alpha: 0.02),
                                  blurRadius: isSelected ? 6 : 2,
                                  offset: const Offset(0, 1.5),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  acc.icon,
                                  color: isSelected ? MeowTheme.actionBlue : const Color(0xFFF59E0B),
                                  size: 22,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  acc.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected ? MeowTheme.actionBlue : textPrimary,
                                    fontSize: 10,
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

            // 5. Pinned Finish Button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: const BoxDecoration(
                color: cardBg,
                border: Border(top: BorderSide(color: borderColor, width: 0.8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: TactileButton(
                onTap: _onFinish,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isEn ? 'Next: Choose Theme (3/4) →' : 'ขั้นตอนถัดไป: เลือกธีมแอพ (3/4) →',
                        style: const TextStyle(
                          color: Colors.white,
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
