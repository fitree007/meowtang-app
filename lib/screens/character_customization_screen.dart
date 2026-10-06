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

class _CharacterCustomizationScreenState extends State<CharacterCustomizationScreen> {
  late String _selectedMascotId;
  late String _selectedAccessory;
  // Kept local until "บันทึก", so backing out changes nothing.
  late bool _usePhoto;
  bool _accessoryPicked = false; // user chose an accessory in this visit
  int _activeTabIndex = 0; // 0 = มาสคอต, 1 = อุปกรณ์
  String _mascotCategoryFilter = 'all'; // 'all', 'cat', 'friend', 'ai'

  @override
  void initState() {
    super.initState();
    _selectedMascotId = widget.controller.selectedMascotId;
    _selectedAccessory = widget.controller.selectedMascotAccessory;
    _usePhoto = widget.controller.isCustomAvatarEnabled;
  }

  void _saveMascot() async {
    HapticFeedback.mediumImpact();
    if (_usePhoto != widget.controller.isCustomAvatarEnabled) {
      await widget.controller.setCustomAvatarEnabled(_usePhoto);
    }
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
        setState(() => _usePhoto = widget.controller.isCustomAvatarEnabled);
      },
    );
  }

  String _getCategoryTag(String id) {
    if (id.startsWith('cat_')) return 'แมว';
    if (id == 'robot_ai') return 'AI';
    return 'เพื่อนสัตว์';
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

  @override
  Widget build(BuildContext context) {
    final isDark = widget.controller.isDarkMode;
    final isEn = widget.controller.isEnglish;
    const bgColor = Color(0xFFFDFBF7);
    const cardBg = Colors.white;
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);

    final isCustomPhoto = _usePhoto;
    final customPhoto = widget.controller.customAvatarPath;

    final currentMascot = MascotCatalog.characters.firstWhere(
      (m) => m.id == _selectedMascotId,
      orElse: () => MascotCatalog.characters.first,
    );

    final currentMascotIndex = MascotCatalog.characters.indexWhere((m) => m.id == _selectedMascotId);

    String thaiName = currentMascot.name;
    String enName = '';
    final parenMatch = RegExp(r'^(.*?)\s*\((.*?)\)$').firstMatch(currentMascot.name);
    if (parenMatch != null) {
      thaiName = parenMatch.group(1)?.trim() ?? currentMascot.name;
      enName = parenMatch.group(2)?.trim() ?? '';
    }

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
          isEn ? 'Mascot & Companion Accessories' : 'ตัวละครและมาสคอต & อุปกรณ์คู่กาย',
          style: const TextStyle(
            color: MeowTheme.textDarkPrimary,
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. FIXED Hero Mascot Showcase Card (สไตล์แบบขั้นตอนที่ 2 ไม่มีมุมเล็กๆ)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: cardBg,
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
                  // Mascot Avatar in circular warm backdrop (No corner badge!)
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
                      customPhotoPath: customPhoto,
                      isCustomPhoto: isCustomPhoto,
                      animate: true,
                    ),
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
                    const SizedBox(height: 1),
                    Text(
                      enName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 2. SEGMENTED TAB SWITCHER (มาสคอต & อุปกรณ์ - ไม่มีชุด)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                height: 46,
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1ECE1),
                  borderRadius: BorderRadius.circular(23),
                ),
                child: Row(
                  children: [
                    // Tab 1: มาสคอต
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
                                isEn ? 'Mascot' : 'มาสคอต',
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

                    // Tab 2: อุปกรณ์
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
                                isEn ? 'Accessories' : '✨ อุปกรณ์',
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

            // 3. SCROLLABLE GRID
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    if (_activeTabIndex == 0) ...[
                      // Mascot Filters
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildFilterChip('all', isEn ? 'All' : 'ทั้งหมด', _mascotCategoryFilter, (val) {
                              setState(() => _mascotCategoryFilter = val);
                            }),
                            const SizedBox(width: 6),
                            _buildFilterChip('cat', isEn ? 'Cats' : 'แมว', _mascotCategoryFilter, (val) {
                              setState(() => _mascotCategoryFilter = val);
                            }),
                            const SizedBox(width: 6),
                            _buildFilterChip('friend', isEn ? 'Animals' : 'เพื่อนสัตว์', _mascotCategoryFilter, (val) {
                              setState(() => _mascotCategoryFilter = val);
                            }),
                            const SizedBox(width: 6),
                            _buildFilterChip('ai', isEn ? 'AI' : 'AI', _mascotCategoryFilter, (val) {
                              setState(() => _mascotCategoryFilter = val);
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 4-Column Mascot Grid
                      _buildMascotGrid(),
                    ] else ...[
                      // 4-Column Accessories Grid (ชุดถูกเอาออก)
                      _buildAccessoriesGrid(),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // 4. BOTTOM ACTION BAR (เฉพาะปุ่มบันทึกปุ่มเดียว)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.04))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: TactileButton(
                  onTap: _saveMascot,
                  child: Container(
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
                          isEn ? 'Save Mascot' : 'บันทึก',
                          style: const TextStyle(
                            color: MeowTheme.textDarkPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
        final isSelected = !_usePhoto && _selectedMascotId == character.id;

        String shortName = character.name;
        final paren = character.name.indexOf('(');
        if (paren > 0) {
          shortName = character.name.substring(0, paren).replaceAll('เหมี่ยว', '').replaceAll('แมว', '').trim();
        }

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _usePhoto = false;
              _selectedMascotId = character.id;
              // Keep an accessory the user already picked; otherwise show the mascot's own.
              if (!_accessoryPicked) {
                final cur = MascotCatalog.characters.firstWhere(
                  (m) => m.id == character.id,
                  orElse: () => character,
                );
                _selectedAccessory = cur.signatureAccessory;
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

  Widget _buildAccessoriesGrid() {
    final items = MascotCatalog.accessories;

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
        final String itemId = item.id;
        final String itemName = item.name;
        final IconData itemIcon = item.icon;

        final bool isSelected = _selectedAccessory == itemId;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedAccessory = itemId;
              _accessoryPicked = true;
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
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F6F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(itemIcon, size: 24, color: const Color(0xFFD97706)),
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
}
