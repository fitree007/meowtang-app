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

  @override
  void initState() {
    super.initState();
    _selectedMascotId = widget.controller.selectedMascotId;
    _selectedAccessory = widget.controller.selectedMascotAccessory;
    _selectedOutfit = widget.controller.selectedMascotOutfit;

    // Start with no accessory; the user picks one in the accessories tab.
    if (_selectedAccessory.isEmpty) _selectedAccessory = 'none';
    final initialMascot = MascotCatalog.characters.firstWhere(
      (m) => m.id == _selectedMascotId,
      orElse: () => MascotCatalog.characters.first,
    );
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

  void _showLockedIconOptions(MascotInfo character) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _text),
                        ),
                        Text(
                          character.subtitle,
                          style: TextStyle(color: _sub, fontSize: 12),
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


  // Theme-driven palette, so the step looks like the rest of the app.
  Color get _bg => widget.controller.currentTheme.scaffoldBackground;
  Color get _card => widget.controller.currentTheme.cardBackground;
  Color get _line => widget.controller.currentTheme.borderColor.withValues(alpha: 0.6);
  Color get _text => widget.controller.currentTheme.textColor;
  Color get _sub => widget.controller.currentTheme.textSecondaryColor;
  Color get _accent => widget.controller.currentTheme.primaryColor;
  Color get _accentText =>
      widget.controller.isDarkMode ? Color.lerp(_accent, Colors.white, 0.55)! : _accent;
  Color get _soft =>
      Color.alphaBlend(_accent.withValues(alpha: widget.controller.isDarkMode ? 0.18 : 0.07), _card);
  Color get _tile => widget.controller.isDarkMode ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF4F5F9);

  @override
  Widget build(BuildContext context) {
    final isEn = widget.controller.isEnglish;
    final isCustomPhoto = widget.controller.isCustomAvatarEnabled;
    final customPhoto = widget.controller.customAvatarPath;

    final currentMascot = MascotCatalog.characters.firstWhere(
      (m) => m.id == _selectedMascotId,
      orElse: () => MascotCatalog.characters.first,
    );
    final currentMascotIndex = MascotCatalog.characters.indexWhere((m) => m.id == _selectedMascotId);
    final accessoryName = MascotCatalog.accessories.where((a) => a.id == _selectedAccessory).firstOrNull?.name ??
        (isEn ? 'No accessory' : 'ไม่ใส่อุปกรณ์');

    // Split "ไทย (English)" names.
    String thaiName = currentMascot.name;
    String enName = '';
    final parenMatch = RegExp(r'^(.*?)\s*\((.*?)\)$').firstMatch(currentMascot.name);
    if (parenMatch != null) {
      thaiName = parenMatch.group(1)?.trim() ?? currentMascot.name;
      enName = parenMatch.group(2)?.trim() ?? '';
    }

    Widget smallChip({required String label, IconData? icon, bool strong = false, VoidCallback? onTap}) {
      final chip = Container(
        constraints: const BoxConstraints(minHeight: 30),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: strong ? _soft : _tile,
          borderRadius: BorderRadius.circular(10),
          border: strong ? Border.all(color: _accent.withValues(alpha: 0.5)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: strong ? _accentText : _sub),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: strong ? _accentText : _sub),
            ),
          ],
        ),
      );
      return onTap == null ? chip : TactileButton(onTap: onTap, child: chip);
    }

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          OnboardingStepHeader(
            controller: widget.controller,
            currentStep: 2,
            title: isEn ? 'Choose Your Mascot' : 'เลือกคู่หูประจำตัว',
            subtitle: isEn
                ? 'Your companion stays with you on the home screen. Change it any time.'
                : 'คู่หูจะอยู่กับคุณในหน้าหลัก เปลี่ยนตัวได้ทุกเมื่อในเมนูตัวละคร',
            onBack: widget.controller.revertToLanguageSelection,
          ),

          // Preview card (fixed)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _line),
            ),
            child: Row(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _soft),
                  alignment: Alignment.center,
                  child: MeowMascotWidget(
                    size: 64,
                    mascotId: currentMascot.id,
                    accessory: _selectedAccessory,
                    outfit: _selectedOutfit,
                    customPhotoPath: customPhoto,
                    isCustomPhoto: isCustomPhoto,
                    animate: true,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${currentMascotIndex >= 0 ? currentMascotIndex + 1 : 1} / ${MascotCatalog.characters.length} • ${_getCategoryTag(currentMascot.id)}',
                        style: TextStyle(fontSize: 12, color: _sub),
                      ),
                      Text(
                        thaiName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _text),
                      ),
                      Text(
                        enName.isNotEmpty ? enName : currentMascot.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: _sub),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (!isCustomPhoto)
                            smallChip(
                              label: accessoryName,
                              icon: Icons.checkroom_rounded,
                              strong: true,
                              onTap: () => setState(() => _activeTabIndex = 1),
                            ),
                          smallChip(
                            label: isCustomPhoto
                                ? (isEn ? 'Change photo' : 'เปลี่ยนรูป')
                                : (isEn ? 'My photo' : 'ใช้รูปของฉัน'),
                            icon: Icons.add_a_photo_outlined,
                            strong: isCustomPhoto,
                            onTap: _openCustomPhotoDialog,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Mascots | accessories switch (fixed)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _line),
              ),
              child: Row(
                children: [
                  _buildTab(0, isEn ? 'Mascots ${MascotCatalog.characters.length}' : 'มาสคอต ${MascotCatalog.characters.length}'),
                  _buildTab(1, isEn ? 'Accessories' : 'อุปกรณ์'),
                ],
              ),
            ),
          ),

          // Only the grid scrolls
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_activeTabIndex == 0) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final f in [
                            ('all', isEn ? 'All' : 'ทั้งหมด'),
                            ('cat', isEn ? 'Cats' : 'แมว'),
                            ('friend', isEn ? 'Animals' : 'เพื่อนสัตว์'),
                            ('ai', 'AI'),
                          ]) ...[
                            _buildFilterChip(f.$1, f.$2, _mascotCategoryFilter, (val) {
                              setState(() => _mascotCategoryFilter = val);
                            }),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildMascotGrid(),
                  ] else ...[
                    if (isCustomPhoto)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                        child: Text(
                          isEn
                              ? 'Accessories are for mascots only.\nChoose a mascot to try them on.'
                              : 'อุปกรณ์คู่กายใช้ได้เฉพาะมาสคอต\nเลือกมาสคอตก่อน แล้วค่อยลองใส่อุปกรณ์',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13.5, height: 1.5, color: _sub),
                        ),
                      )
                    else
                      _buildDressingGrid(isEn),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: OnboardingBottomBar(
        controller: widget.controller,
        nextLabel: _activeTabIndex == 0
            ? (isEn ? 'Choose $thaiName' : 'เลือก $thaiName')
            : (isEn ? 'Save & continue' : 'บันทึกการแต่งตัว'),
        onNext: _onFinish,
        onBack: widget.controller.revertToLanguageSelection,
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final selected = _activeTabIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (selected) return;
          HapticFeedback.selectionClick();
          setState(() => _activeTabIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _accent.withValues(alpha: widget.controller.isDarkMode ? 0.28 : 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? _accentText : _sub,
            ),
          ),
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
        constraints: const BoxConstraints(minHeight: 36),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? _accent : _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isSelected ? _accent : _line),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : _sub,
          ),
        ),
      ),
    );
  }

  /// One square cell of the 4-column pickers.
  Widget _gridCell({
    required bool selected,
    required bool locked,
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? _soft : _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? _accent : _line, width: selected ? 2 : 1),
        ),
        child: Stack(
          children: [
            if (selected || locked)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(color: selected ? _accent : _tile, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Icon(
                    selected ? Icons.check_rounded : Icons.lock_outline_rounded,
                    size: 12,
                    color: selected ? Colors.white : _sub,
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: _tile, borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: icon,
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                        color: selected ? _accentText : _text,
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
        final isUnlocked = widget.controller.isMascotUnlocked(character.id);

        String shortName = character.name;
        final paren = character.name.indexOf('(');
        if (paren > 0) {
          shortName = character.name.substring(0, paren).replaceAll('เหมี่ยว', '').replaceAll('แมว', '').trim();
        }

        return _gridCell(
          selected: _selectedMascotId == character.id,
          locked: !isUnlocked,
          icon: MeowMascotWidget(size: 34, mascotId: character.id, isHeadOnly: true, animate: false),
          label: shortName,
          onTap: () {
            HapticFeedback.selectionClick();
            if (!isUnlocked) {
              _showLockedIconOptions(character);
              return;
            }
            // Choosing a mascot replaces the uploaded photo, which is removed.
            if (widget.controller.customAvatarPath != null) {
              widget.controller.removeCustomAvatar();
            }
            setState(() {
              // The accessory stays as the user chose it (none by default).
              _selectedMascotId = character.id;
              _selectedOutfit = character.signatureOutfit;
            });
          },
        );
      },
    );
  }

  Widget _buildDressingGrid(bool isEn) {
    // First cell takes the accessory off.
    final List<AccessoryInfo> items = [
      AccessoryInfo(id: 'none', name: isEn ? 'None' : 'ไม่ใส่', icon: Icons.block_rounded),
      ...MascotCatalog.accessories,
    ];

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
        return _gridCell(
          selected: _selectedAccessory == item.id,
          locked: false,
          icon: Icon(item.icon, size: 22, color: _accentText),
          label: item.name,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedAccessory = item.id);
          },
        );
      },
    );
  }
}
