import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../widgets/meow_mascot_widget.dart';
import '../widgets/meow_fx.dart';
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
  int _activeTabIndex = 0; // 0 = มาสคอต, 1 = อุปกรณ์
  String _mascotCategoryFilter = 'all'; // 'all', 'cat', 'friend', 'ai'

  @override
  void initState() {
    super.initState();
    _selectedMascotId = widget.controller.selectedMascotId;
    _selectedAccessory = widget.controller.selectedMascotAccessory;
    _usePhoto = widget.controller.isCustomAvatarEnabled;
  }

  bool get _dirty =>
      _selectedMascotId != widget.controller.selectedMascotId ||
      _selectedAccessory != widget.controller.selectedMascotAccessory ||
      _usePhoto != widget.controller.isCustomAvatarEnabled;

  void _revert() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedMascotId = widget.controller.selectedMascotId;
      _selectedAccessory = widget.controller.selectedMascotAccessory;
      _usePhoto = widget.controller.isCustomAvatarEnabled;
    });
  }

  void _saveMascot() async {
    HapticFeedback.mediumImpact();
    if (!_usePhoto && widget.controller.customAvatarPath != null) {
      // Saving a mascot replaces the uploaded photo, which is removed.
      await widget.controller.removeCustomAvatar();
    } else if (_usePhoto != widget.controller.isCustomAvatarEnabled) {
      await widget.controller.setCustomAvatarEnabled(_usePhoto);
    }
    await widget.controller.updateMascot(
      _selectedMascotId,
      _selectedAccessory,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.controller.isEnglish
              ? 'Saved — this character is now used across the app'
              : 'บันทึกแล้ว — ใช้ตัวละครนี้ทั่วทั้งแอป',
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

  void _onPhotoTile() {
    // A saved photo can be previewed first; tapping again (or with no photo yet) opens the picker.
    if (!_usePhoto && widget.controller.customAvatarPath != null) {
      HapticFeedback.selectionClick();
      setState(() => _usePhoto = true);
    } else {
      _openCustomPhotoDialog();
    }
  }

  static String _group(String id) {
    if (id.startsWith('cat_')) return 'cat';
    if (id == 'robot_ai') return 'ai';
    return 'friend';
  }

  String _groupLabel(String group, bool isEn) => switch (group) {
        'cat' => isEn ? 'Cat' : 'แมว',
        'ai' => 'AI',
        'photo' => isEn ? 'My photo' : 'รูปของฉัน',
        _ => isEn ? 'Animal friend' : 'เพื่อนสัตว์',
      };

  /// "เหมี่ยวส้มจอมวางแผน (Ginger Tabby)" -> ("เหมี่ยวส้มจอมวางแผน", "Ginger Tabby").
  static (String, String) _splitName(String name) {
    final m = RegExp(r'^(.*?)\s*\((.*?)\)$').firstMatch(name);
    if (m == null) return (name, '');
    return (m.group(1)?.trim() ?? name, m.group(2)?.trim() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final isEn = widget.controller.isEnglish;
    final p = _Pal.of(widget.controller);
    final chars = MascotCatalog.characters;
    final accs = MascotCatalog.accessories;
    final dirty = _dirty;

    final current = chars.firstWhere((m) => m.id == _selectedMascotId, orElse: () => chars.first);
    final index = chars.indexWhere((m) => m.id == current.id);
    final (thName, enName) = _splitName(current.name);
    // Accessories are for mascots only; the user's photo is shown as it is.
    final acc = _usePhoto ? null : accs.where((a) => a.id == _selectedAccessory).firstOrNull;
    final accName = acc?.name;

    final dropsPhoto = dirty && !_usePhoto && widget.controller.customAvatarPath != null;
    final footNote = dropsPhoto
        ? (isEn ? 'Saving uses $thName and removes your photo' : 'บันทึกแล้วจะใช้ $thName และลบรูปของคุณออก')
        : dirty
        ? (isEn
            ? 'Tap Save to use ${_usePhoto ? 'your photo' : (enName.isEmpty ? thName : enName)}${accName == null ? '' : ' + $accName'}'
            : 'กดบันทึกเพื่อใช้ ${_usePhoto ? 'รูปของฉัน' : thName}${accName == null ? '' : ' + $accName'}')
        : (isEn ? 'No changes yet' : 'ยังไม่มีการเปลี่ยนแปลง');

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          _AppBarPlain(
            pal: p,
            title: isEn ? 'Mascot & accessories' : 'ตัวละคร & มาสคอต',
            subtitle: isEn
                ? '${chars.length} characters • ${accs.length} accessories'
                : '${chars.length} ตัวละคร • ${accs.length} อุปกรณ์คู่กาย',
            backLabel: isEn ? 'Back' : 'ย้อนกลับ',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              children: [
                FxFadeUp(index: 0, child: _buildHero(p, isEn, current, index, thName, enName, acc, dirty)),
                const SizedBox(height: 14),
                FxFadeUp(index: 1, child: _buildTabs(p, isEn, chars.length, accs.length)),
                const SizedBox(height: 14),
                FxFadeUp(
                  index: 2,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: p.line),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _activeTabIndex == 0
                          ? KeyedSubtree(key: const ValueKey('m'), child: _buildMascotPanel(p, isEn))
                          : KeyedSubtree(key: const ValueKey('a'), child: _buildAccessoryPanel(p, isEn)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: p.card, border: Border(top: BorderSide(color: p.line))),
            padding: EdgeInsets.fromLTRB(16, 10, 16, 14 + MediaQuery.of(context).padding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(footNote,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: p.sub)),
                const SizedBox(height: 6),
                _PrimaryButton(
                  pal: p,
                  label: isEn ? 'Save' : 'บันทึก',
                  enabled: dirty,
                  onTap: _saveMascot,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(_Pal p, bool isEn, MascotInfo current, int index, String thName, String enName, AccessoryInfo? acc,
      bool dirty) {
    final photo = _usePhoto;
    final group = photo ? 'photo' : _group(current.id);
    final title = photo ? (isEn ? 'My photo' : 'รูปของฉัน') : thName;
    final line2 = photo
        ? (isEn ? 'From your phone' : 'รูปจากเครื่องของคุณ')
        : '${enName.isEmpty ? '' : '$enName • '}${isEn ? 'No. ${index + 1} of ${MascotCatalog.characters.length}' : 'ตัวที่ ${index + 1} จาก ${MascotCatalog.characters.length}'}';
    final accLine = photo
        ? (isEn ? 'Accessories are for mascots only' : 'อุปกรณ์คู่กายใช้ได้เฉพาะมาสคอต')
        : acc == null
            ? (isEn ? 'No accessory' : 'ไม่ได้ใส่อุปกรณ์คู่กาย')
            : (isEn ? 'Accessory: ${acc.name}' : 'อุปกรณ์คู่กาย: ${acc.name}');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.line)),
      child: Column(
        children: [
          SizedBox(
            width: 132,
            height: 142,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(color: p.seg, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(a), child: child),
                    ),
                    child: MeowMascotWidget(
                      key: ValueKey('$photo/${current.id}/$_selectedAccessory'),
                      size: 92,
                      mascotId: current.id,
                      accessory: _selectedAccessory,
                      customPhotoPath: widget.controller.customAvatarPath,
                      isCustomPhoto: photo,
                      animate: true,
                    ),
                  ),
                ),
                if (acc != null)
                  Positioned(
                    right: 2,
                    top: 4,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Container(
                        key: ValueKey(acc.id),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: p.card,
                          shape: BoxShape.circle,
                          border: Border.all(color: p.line),
                        ),
                        child: Icon(acc.icon, size: 22, color: p.icon),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: p.line),
                    ),
                    child: Text(_groupLabel(group, isEn),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: p.sub)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: p.text)),
          const SizedBox(height: 1),
          Text(line2, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: p.sub)),
          const SizedBox(height: 4),
          Text(accLine, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: p.sub)),
          if (photo) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _openCustomPhotoDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: p.link,
                side: BorderSide(color: p.line),
                minimumSize: const Size(44, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text(isEn ? 'Change photo' : 'เปลี่ยนรูป',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            ),
          ],
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: dirty
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                      decoration: BoxDecoration(
                        color: p.seg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: p.line),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 18, color: p.icon),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(
                              TextSpan(children: [
                                TextSpan(
                                    text: isEn ? 'Not saved' : 'ยังไม่บันทึก',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                TextSpan(text: isEn ? ' — this is only a preview' : ' — ตอนนี้เป็นแค่ตัวอย่าง'),
                              ]),
                              style: TextStyle(fontSize: 13, color: p.text),
                            ),
                          ),
                          TextButton(
                            onPressed: _revert,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(44, 44),
                              foregroundColor: p.link,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: Text(isEn ? 'Undo' : 'ยกเลิก',
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(_Pal p, bool isEn, int nChars, int nAccs) {
    return _Segmented(
      pal: p,
      selected: _activeTabIndex,
      labels: [
        isEn ? 'Mascots ($nChars)' : 'มาสคอต ($nChars)',
        isEn ? 'Accessories ($nAccs)' : 'อุปกรณ์ ($nAccs)',
      ],
      onSelect: (i) {
        HapticFeedback.selectionClick();
        setState(() => _activeTabIndex = i);
      },
    );
  }

  Widget _buildMascotPanel(_Pal p, bool isEn) {
    final chars = MascotCatalog.characters;
    int count(String g) => chars.where((m) => _group(m.id) == g).length;
    final names = {
      'all': isEn ? 'All' : 'ทั้งหมด',
      'cat': isEn ? 'Cats' : 'แมว',
      'friend': isEn ? 'Animals' : 'เพื่อนสัตว์',
      'ai': 'AI',
    };
    final filtered = chars.where((m) => _mascotCategoryFilter == 'all' || _group(m.id) == _mascotCategoryFilter).toList();
    final hint = isEn
        ? 'Tap to preview above • ${names[_mascotCategoryFilter]} ${filtered.length} + your own photo'
        : 'แตะเพื่อดูตัวอย่างด้านบน • ${names[_mascotCategoryFilter]} ${filtered.length} ตัว + รูปของคุณเอง';

    final tiles = <Widget>[
      _Tile(
        pal: p,
        selected: _usePhoto,
        dashed: !_usePhoto,
        label: isEn ? 'My photo' : 'รูปของฉัน',
        art: Icon(Icons.photo_camera_outlined, size: 28, color: p.icon),
        onTap: _onPhotoTile,
      ),
      for (final m in filtered)
        _Tile(
          pal: p,
          selected: !_usePhoto && _selectedMascotId == m.id,
          label: _splitName(m.name).$1,
          art: MeowMascotWidget(size: 40, mascotId: m.id, isHeadOnly: true, animate: false),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _usePhoto = false;
              // The accessory stays as the user chose it.
              _selectedMascotId = m.id;
            });
          },
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final id in ['all', 'cat', 'friend', 'ai'])
              _Chip(
                pal: p,
                label: '${names[id]} ${id == 'all' ? chars.length : count(id)}',
                selected: _mascotCategoryFilter == id,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _mascotCategoryFilter = id);
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(hint, style: TextStyle(fontSize: 12.5, color: p.sub)),
        ),
        const SizedBox(height: 12),
        _grid(tiles, 4),
      ],
    );
  }

  Widget _buildAccessoryPanel(_Pal p, bool isEn) {
    if (_usePhoto) {
      // Accessories only fit the mascot pictures, not the user's own photo.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Column(
          children: [
            Icon(Icons.checkroom_rounded, size: 34, color: p.sub),
            const SizedBox(height: 10),
            Text(
              isEn ? 'Accessories are for mascots only' : 'อุปกรณ์คู่กายใช้ได้เฉพาะมาสคอต',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.text),
            ),
            const SizedBox(height: 4),
            Text(
              isEn ? 'Choose a mascot to try them on' : 'เลือกมาสคอตก่อน แล้วค่อยลองใส่อุปกรณ์',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: p.sub),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _activeTabIndex = 0);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: p.link,
                side: BorderSide(color: p.line),
                minimumSize: const Size(44, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isEn ? 'Choose a mascot' : 'เลือกมาสคอต',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }
    final tiles = <Widget>[
      _Tile(
        pal: p,
        selected: _selectedAccessory == 'none',
        label: isEn ? 'None' : 'ไม่ใส่',
        muted: true,
        art: Icon(Icons.block_rounded, size: 28, color: p.sub),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedAccessory = 'none');
        },
      ),
      for (final a in MascotCatalog.accessories)
        _Tile(
          pal: p,
          selected: _selectedAccessory == a.id,
          label: a.name,
          art: Icon(a.icon, size: 28, color: p.icon),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedAccessory = a.id);
          },
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            isEn ? 'Tap to try it on • choose "None" to take it off' : 'แตะเพื่อลองใส่ • เลือก "ไม่ใส่" เพื่อถอดออก',
            style: TextStyle(fontSize: 12.5, color: p.sub),
          ),
        ),
        const SizedBox(height: 12),
        _grid(tiles, 3),
      ],
    );
  }

  /// Rows of equal-width tiles; each row is as tall as its tallest tile.
  Widget _grid(List<Widget> tiles, int cols) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += cols) {
      final cells = <Widget>[];
      for (var j = 0; j < cols; j++) {
        if (j > 0) cells.add(const SizedBox(width: 8));
        cells.add(Expanded(child: i + j < tiles.length ? tiles[i + j] : const SizedBox()));
      }
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
      rows.add(IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cells)));
    }
    return Column(children: rows);
  }
}

// ---------------------------------------------------------------------------
// Small private building blocks (calm monochrome menu style)
// ---------------------------------------------------------------------------

class _Tile extends StatelessWidget {
  final _Pal pal;
  final bool selected;
  final bool dashed;
  final bool muted;
  final String label;
  final Widget art;
  final VoidCallback onTap;

  const _Tile({
    required this.pal,
    required this.selected,
    required this.label,
    required this.art,
    required this.onTap,
    this.dashed = false,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = pal;
    final body = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      constraints: const BoxConstraints(minHeight: 98),
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: dashed ? null : Border.all(color: selected ? p.link : p.line, width: selected ? 2 : 1),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 40, child: Center(child: art)),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, height: 1.3, fontWeight: FontWeight.w600, color: muted ? p.sub : p.text),
              ),
            ],
          ),
          Positioned(
            top: -6,
            right: -0,
            child: AnimatedScale(
              scale: selected ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: p.link, shape: BoxShape.circle),
                child: Icon(Icons.check_rounded, size: 13, color: p.card),
              ),
            ),
          ),
        ],
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: FxPress(
        onTap: onTap,
        child: dashed ? CustomPaint(foregroundPainter: _DashedBorder(color: p.dash, radius: 16), child: body) : body,
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  final Color color;
  final double radius;
  const _DashedBorder({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(0.75));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorder old) => old.color != color;
}

class _Chip extends StatelessWidget {
  final _Pal pal;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.pal, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: IntrinsicWidth(child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? p.link : p.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? p.link : p.line),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: selected ? p.card : p.text)),
          )),
        ),
      ),
    );
  }
}

/// Grey track with a white sliding pill (animated) — the draft's segmented control.
class _Segmented extends StatelessWidget {
  final _Pal pal;
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  const _Segmented({required this.pal, required this.labels, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: p.seg, borderRadius: BorderRadius.circular(14)),
      child: LayoutBuilder(builder: (context, c) {
        final w = (c.maxWidth - 4 * (labels.length - 1)) / labels.length;
        return SizedBox(
          height: 44,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: selected * (w + 4),
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: const [BoxShadow(color: Color(0x140F172A), blurRadius: 2, offset: Offset(0, 1))],
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    SizedBox(
                      width: w,
                      child: Semantics(
                        button: true,
                        selected: i == selected,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onSelect(i),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 180),
                              style: TextStyle(
                                fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                                fontSize: 14,
                                fontWeight: i == selected ? FontWeight.w600 : FontWeight.w500,
                                color: i == selected ? p.link : p.sub,
                              ),
                              child: Text(labels[i], maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final _Pal pal;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _PrimaryButton({required this.pal, required this.label, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    return Semantics(
      button: true,
      enabled: enabled,
      child: FxPress(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: enabled ? p.accent : p.seg, borderRadius: BorderRadius.circular(16)),
          child: Text(label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: enabled ? Colors.white : p.disabled)),
        ),
      ),
    );
  }
}

/// White app bar: 44px back chevron, left-aligned title and a one-line subtitle.
class _AppBarPlain extends StatelessWidget {
  final _Pal pal;
  final String title;
  final String subtitle;
  final String backLabel;

  const _AppBarPlain({required this.pal, required this.title, required this.subtitle, required this.backLabel});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    return Container(
      decoration: BoxDecoration(color: p.card, border: Border(bottom: BorderSide(color: p.line))),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                tooltip: backLabel,
                icon: Icon(Icons.chevron_left_rounded, size: 30, color: p.text),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.text)),
                    const SizedBox(height: 1),
                    Text(subtitle,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: p.sub)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Neutral palette derived from the active theme (same mapping as the menu).
class _Pal {
  final Color bg, card, text, sub, icon, line, seg, accent, link, dash, disabled;

  const _Pal({
    required this.bg,
    required this.card,
    required this.text,
    required this.sub,
    required this.icon,
    required this.line,
    required this.seg,
    required this.accent,
    required this.link,
    required this.dash,
    required this.disabled,
  });

  factory _Pal.of(ExpenseController ctl) {
    final t = ctl.currentTheme;
    final dark = ctl.isDarkMode;
    return _Pal(
      bg: t.scaffoldBackground,
      card: t.cardBackground,
      text: t.textColor,
      sub: t.textSecondaryColor,
      icon: dark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
      line: t.borderColor,
      seg: dark ? const Color(0xFF0F172A) : const Color(0xFFF1F3F8),
      accent: t.primaryColor,
      link: dark ? const Color(0xFF93C5FD) : t.primaryColor,
      dash: dark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
      disabled: dark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
    );
  }
}
