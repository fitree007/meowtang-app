import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/faraid_engine.dart';
import '../state/expense_controller.dart';
import '../theme/app_theme_model.dart';
import '../theme/meow_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/meow_fx.dart';
import 'faraid_result_screen.dart';

/// A later death (Al-Munasakhat) being edited on screen.
class _LaterDeathDraft {
  /// -1 = an heir of the first deceased, otherwise the index of an earlier draft.
  int fromDraft = -1;
  HeirType? heirType;
  int heirIndex = 1;
  final Map<HeirType, int> heirs = {};
  final TextEditingController ownAssetsCtrl = TextEditingController();

  void dispose() => ownAssetsCtrl.dispose();
}

/// Someone who died together with the first deceased (Al-Gharqa), edited on screen.
class _SimultaneousDraft {
  final TextEditingController nameCtrl = TextEditingController();
  bool male = true;
  final Map<HeirType, int> heirs = {};
  final TextEditingController ownAssetsCtrl = TextEditingController();

  void dispose() {
    nameCtrl.dispose();
    ownAssetsCtrl.dispose();
  }
}

/// A free-form asset line (e.g. a fishing boat) in the itemised estate.
class _CustomAsset {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController valueCtrl = TextEditingController();

  void dispose() {
    nameCtrl.dispose();
    valueCtrl.dispose();
  }
}

class _HeirOption {
  final int fromDraft;
  final int stageIndex;
  final HeirType type;
  final int index;
  final String label;

  const _HeirOption(this.fromDraft, this.stageIndex, this.type, this.index, this.label);

  String get key => '$fromDraft|${type.name}|$index';
}

/// The "unexpected events" of step 4.
enum _Special { haml, mafqud, muna, gharqa, mani, talaq }

class IslamicInheritanceScreen extends StatefulWidget {
  final ExpenseController controller;

  const IslamicInheritanceScreen({super.key, required this.controller});

  @override
  State<IslamicInheritanceScreen> createState() => _IslamicInheritanceScreenState();
}

class _IslamicInheritanceScreenState extends State<IslamicInheritanceScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  final TextEditingController _grossCtrl = TextEditingController();
  /// true = "แยกรายการ" (itemised rows, the default), false = "กรอกยอดรวม" (one manual total).
  bool _detailedAssets = true;
  /// Preset rows of the optional asset breakdown ("แยกรายการทรัพย์สิน").
  static const _assetTypes = [
    ('cash', 'เงินสด/เงินฝาก', Icons.account_balance_wallet_outlined),
    ('home', 'บ้าน/ที่ดิน', Icons.home_outlined),
    ('car', 'รถยนต์', Icons.directions_car_outlined),
    ('gold', 'ทอง/เครื่องประดับ', Icons.diamond_outlined),
    ('invest', 'หุ้น/กองทุน/การลงทุน', Icons.show_chart),
    ('receivable', 'เงินที่ผู้อื่นติดค้างผู้ตาย', Icons.receipt_long_outlined),
  ];
  final Map<String, TextEditingController> _assetCtrls = {for (final a in _assetTypes) a.$1: TextEditingController()};
  final List<_CustomAsset> _customAssets = [];
  final TextEditingController _funeralCtrl = TextEditingController();
  final TextEditingController _debtsCtrl = TextEditingController();
  final TextEditingController _wasiyyahCtrl = TextEditingController();

  bool _deceasedMale = true;
  final Map<HeirType, int> _heirs = {};
  final List<_LaterDeathDraft> _later = [];
  final List<_SimultaneousDraft> _together = [];

  // Step 4 events that are switched on (later deaths / simultaneous deaths only count while on).
  bool _laterOn = false;
  bool _togetherOn = false;
  bool _maniOn = false;
  bool _talaqOn = false;
  bool _talaqBain = false;

  // Al-Haml: an unborn child who would be an heir.
  static const _fetusRelations = [
    ('ลูกของผู้ตาย (ภรรยาตั้งครรภ์)', HeirType.son, HeirType.daughter),
    ('หลาน (ลูกของลูกชายผู้ตาย)', HeirType.sonsSon, HeirType.sonsDaughter),
    ('พี่น้องร่วมพ่อแม่ (แม่ของผู้ตายตั้งครรภ์กับพ่อ)', HeirType.fullBrother, HeirType.fullSister),
    ('พี่น้องร่วมพ่อ (ภรรยาอื่นของพ่อตั้งครรภ์)', HeirType.paternalBrother, HeirType.paternalSister),
    ('พี่น้องร่วมแม่ (แม่ตั้งครรภ์กับสามีอื่น)', HeirType.maternalBrother, HeirType.maternalSister),
  ];
  bool _fetusOn = false;
  int _fetusRelation = 0;
  int _fetusMax = 2;

  // Al-Mafqud: heirs who are missing and may still be alive.
  bool _missingOn = false;
  HeirType _missingType = HeirType.son;
  int _missingCount = 1;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in [_grossCtrl, ..._assetCtrls.values, _funeralCtrl, _debtsCtrl, _wasiyyahCtrl]) {
      c.dispose();
    }
    for (final a in _customAssets) {
      a.dispose();
    }
    for (final d in _later) {
      d.dispose();
    }
    for (final d in _together) {
      d.dispose();
    }
    super.dispose();
  }

  AppThemeModel get _theme => widget.controller.currentTheme;
  bool get _isDark => widget.controller.isDarkMode;
  Color get _ink => FaraidStyle.ink(_theme, _isDark);

  // ---------------------------------------------------------------------------
  // Money
  // ---------------------------------------------------------------------------
  double _parse(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '').trim()) ?? 0.0;

  double get _itemisedTotal =>
      _assetCtrls.values.fold(0.0, (a, c) => a + _parse(c)) +
      _customAssets.fold(0.0, (a, x) => a + _parse(x.valueCtrl));

  double get _gross => _detailedAssets ? _itemisedTotal : _parse(_grossCtrl);
  double get _funeral => _parse(_funeralCtrl);
  double get _debts => _parse(_debtsCtrl);
  double get _afterDebts => (_gross - _funeral - _debts).clamp(0.0, double.infinity);
  double get _maxWasiyyah => _afterDebts / 3;
  bool get _wasiyyahOver => _parse(_wasiyyahCtrl) > _maxWasiyyah && _parse(_wasiyyahCtrl) > 0;
  double get _wasiyyah => _parse(_wasiyyahCtrl).clamp(0.0, _maxWasiyyah);
  double get _net => (_afterDebts - _wasiyyah).clamp(0.0, double.infinity);

  String _money(double v) => '฿${FormatUtils.formatCurrency(v)}';

  // ---------------------------------------------------------------------------
  // Calculation
  // ---------------------------------------------------------------------------
  /// Converts valid drafts to engine input; returns the draft index -> stage index map.
  (List<LaterDeath>, Map<int, int>) _laterDeathInputs() {
    final out = <LaterDeath>[];
    final stageOf = <int, int>{};
    for (var i = 0; i < _later.length; i++) {
      final d = _later[i];
      if (d.heirType == null) continue;
      final from = d.fromDraft < 0 ? 0 : stageOf[d.fromDraft];
      if (from == null) continue;
      out.add(LaterDeath(
        fromStage: from,
        heirType: d.heirType!,
        heirIndex: d.heirIndex,
        heirs: Map.of(d.heirs),
        ownAssets: _parse(d.ownAssetsCtrl),
      ));
      stageOf[i] = out.length; // stage 0 is the first deceased
    }
    return (out, stageOf);
  }

  bool get _hasUncertain => _fetusOn || _missingOn;

  /// Heir types that can be missing for the current deceased.
  List<HeirType> get _missingTypes => HeirType.values
      .where((t) => !(t == HeirType.husband && _deceasedMale) && !(t == HeirType.wife && !_deceasedMale))
      .toList();

  List<SimultaneousDeath> _simultaneousInputs() => [
        if (_togetherOn)
          for (final d in _together)
            SimultaneousDeath(
              label: d.nameCtrl.text.trim().isEmpty ? 'ผู้เสียชีวิตพร้อมกัน' : d.nameCtrl.text.trim(),
              isMale: d.male,
              heirs: Map.of(d.heirs),
              ownAssets: _parse(d.ownAssetsCtrl),
            ),
      ];

  MunasakhatResult _calculate() {
    final (later, _) = _laterDeathInputs();
    return FaraidEngine.calculateChain(
      estate: _net,
      root: FaraidInput(deceasedMale: _deceasedMale, heirs: Map.of(_heirs)),
      // A later death can only be divided once the uncertain heirs are settled.
      laterDeaths: _hasUncertain || !_laterOn ? const [] : later,
      simultaneous: _simultaneousInputs(),
    );
  }

  UncertainResult? _calculateUncertain() {
    if (!_hasUncertain) return null;
    final rel = _fetusRelations[_fetusRelation];
    return FaraidEngine.calculateUncertain(FaraidInput(deceasedMale: _deceasedMale, heirs: Map.of(_heirs)), [
      if (_fetusOn) FaraidEngine.fetusScenarios(rel.$2, rel.$3, _fetusMax),
      if (_missingOn) FaraidEngine.missingScenarios(_missingType, _missingCount),
    ]);
  }

  /// Heirs (individuals) that a later death at [draftIndex] may refer to.
  List<_HeirOption> _optionsFor(int draftIndex) {
    final (later, stageOf) = _laterDeathInputs();
    final chain = FaraidEngine.calculateChain(
      estate: _net,
      root: FaraidInput(deceasedMale: _deceasedMale, heirs: Map.of(_heirs)),
      laterDeaths: later,
    );
    final usedKeys = <String>{};
    for (var i = 0; i < _later.length; i++) {
      if (i == draftIndex || _later[i].heirType == null) continue;
      usedKeys.add('${_later[i].fromDraft}|${_later[i].heirType!.name}|${_later[i].heirIndex}');
    }
    final options = <_HeirOption>[];
    final sources = <int, int>{-1: 0};
    for (var i = 0; i < draftIndex; i++) {
      if (stageOf.containsKey(i)) sources[i] = stageOf[i]!;
    }
    sources.forEach((fromDraft, stageIndex) {
      if (stageIndex >= chain.stages.length) return;
      final stage = chain.stages[stageIndex];
      for (final s in stage.result.shares) {
        if (!s.share.isPositive) continue;
        for (var k = 1; k <= s.count; k++) {
          final o = _HeirOption(
            fromDraft,
            stageIndex,
            s.type,
            k,
            '${fromDraft < 0 ? 'ทายาทผู้ตายคนแรก' : 'ทายาทขั้นที่ ${stageIndex + 1}'} • ${s.type.th}${s.count > 1 ? ' คนที่ $k' : ''}',
          );
          if (!usedKeys.contains(o.key)) options.add(o);
        }
      }
    });
    return options;
  }

  int get _heirTotal => _heirs.values.fold(0, (a, b) => a + b);

  void _openResult() {
    FocusScope.of(context).unfocus();
    if (_net <= 0) {
      _snack('กรุณาใส่มูลค่าทรัพย์สินก่อน', isError: true);
      return;
    }
    if (_heirTotal == 0 && !_hasUncertain) {
      _snack('กรุณาเลือกทายาทอย่างน้อย 1 คน', isError: true);
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FaraidResultScreen(
          controller: widget.controller,
          chain: _calculate(),
          uncertain: _calculateUncertain(),
          summary: FaraidEstateSummary(
            gross: _gross,
            funeral: _funeral,
            debts: _debts,
            wasiyyah: _wasiyyah,
            net: _net,
            items: !_detailedAssets
                ? const []
                : [
                    for (final a in _assetTypes)
                      if (_parse(_assetCtrls[a.$1]!) > 0) (a.$2, _parse(_assetCtrls[a.$1]!)),
                    for (final c in _customAssets)
                      if (_parse(c.valueCtrl) > 0)
                        (c.nameCtrl.text.trim().isEmpty ? 'ทรัพย์สินอื่น' : c.nameCtrl.text.trim(), _parse(c.valueCtrl)),
                  ],
          ),
        ),
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? const Color(0xFFEF4444) : MeowTheme.incomeGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _importAppBalance() {
    HapticFeedback.mediumImpact();
    final netWorth = widget.controller.totalNetWorth;
    setState(() {
      _detailedAssets = false;
      _grossCtrl.text = netWorth > 0 ? _GroupedNumberFormatter.group(netWorth.toStringAsFixed(0)) : '0';
    });
    _snack('ดึงยอดเงินคงเหลือในแอพ ${_money(netWorth)} แล้ว');
  }

  void _resetAll() {
    HapticFeedback.lightImpact();
    setState(() {
      for (final c in [_grossCtrl, ..._assetCtrls.values, _funeralCtrl, _debtsCtrl, _wasiyyahCtrl]) {
        c.clear();
      }
      for (final a in _customAssets) {
        a.dispose();
      }
      _customAssets.clear();
      _detailedAssets = true;
      _deceasedMale = true;
      _heirs.clear();
      for (final d in _later) {
        d.dispose();
      }
      _later.clear();
      for (final d in _together) {
        d.dispose();
      }
      _together.clear();
      _laterOn = false;
      _togetherOn = false;
      _maniOn = false;
      _talaqOn = false;
      _talaqBain = false;
      _fetusOn = false;
      _fetusRelation = 0;
      _fetusMax = 2;
      _missingOn = false;
      _missingType = HeirType.son;
      _missingCount = 1;
    });
  }

  void _loadCase(_CaseStudy c) {
    _resetAll();
    setState(() {
      _detailedAssets = false;
      _grossCtrl.text = '1,200,000';
      _deceasedMale = c.deceasedMale;
      _heirs.addAll(c.heirs);
      for (final l in c.later) {
        final d = _LaterDeathDraft()
          ..fromDraft = -1
          ..heirType = l.heirType
          ..heirIndex = l.heirIndex;
        d.heirs.addAll(l.heirs);
        _later.add(d);
      }
      _laterOn = c.later.isNotEmpty;
      if (c.fetusMax > 0) {
        _fetusOn = true;
        _fetusRelation = 0;
        _fetusMax = c.fetusMax;
      }
      if (c.missing != null) {
        _missingOn = true;
        _missingType = c.missing!;
        _missingCount = 1;
      }
      for (final t in c.together) {
        final d = _SimultaneousDraft()
          ..male = t.male
          ..nameCtrl.text = t.name
          ..ownAssetsCtrl.text = _GroupedNumberFormatter.group(t.ownAssets.toStringAsFixed(0));
        d.heirs.addAll(t.heirs);
        _together.add(d);
      }
      _togetherOn = c.together.isNotEmpty;
    });
    _tabs.animateTo(0);
    _snack('ใส่ข้อมูลกรณี "${c.title}" แล้ว กด "ดูผลการแบ่งมรดก" ด้านล่างได้เลย');
  }

  /// "เสียชีวิตก่อนแบ่ง → คำนวณมรดกซ้อน" on a result row: opens a later-death draft for that heir.
  void _markDied(HeirShare s) {
    final used = {
      for (final d in _later)
        if (d.fromDraft < 0 && d.heirType == s.type) d.heirIndex,
    };
    final index = [for (var k = 1; k <= s.count; k++) k].where((k) => !used.contains(k)).firstOrNull;
    if (index == null) {
      _snack('${s.type.th}ทุกคนถูกเลือกในข้อ 4 แล้ว');
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      final d = _LaterDeathDraft()
        ..fromDraft = -1
        ..heirType = s.type
        ..heirIndex = index;
      _later.add(d);
      _laterOn = true;
    });
    _snack('เพิ่ม${s.type.th}${s.count > 1 ? ' คนที่ $index' : ''}ในข้อ 4 แล้ว — กรอกทายาทของผู้นี้');
  }

  bool _isOn(_Special s) => switch (s) {
        _Special.haml => _fetusOn,
        _Special.mafqud => _missingOn,
        _Special.muna => _laterOn,
        _Special.gharqa => _togetherOn,
        _Special.mani => _maniOn,
        _Special.talaq => _talaqOn,
      };

  void _toggle(_Special s) {
    HapticFeedback.selectionClick();
    setState(() {
      final v = !_isOn(s);
      switch (s) {
        case _Special.haml:
          _fetusOn = v;
        case _Special.mafqud:
          _missingOn = v;
        case _Special.muna:
          _laterOn = v;
          if (v && _later.isEmpty) _later.add(_LaterDeathDraft());
        case _Special.gharqa:
          _togetherOn = v;
          if (v && _together.isEmpty) _together.add(_SimultaneousDraft());
        case _Special.mani:
          _maniOn = v;
        case _Special.talaq:
          _talaqOn = v;
      }
    });
  }

  void _noSpecial() {
    HapticFeedback.selectionClick();
    setState(() {
      _fetusOn = _missingOn = _laterOn = _togetherOn = _maniOn = _talaqOn = false;
    });
  }

  void _addHeirs(Map<HeirType, int> add) {
    add.forEach((t, n) {
      final v = ((_heirs[t] ?? 0) + n).clamp(0, t.maxCount);
      if (v > 0) _heirs[t] = v;
    });
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = _theme;
    final isDark = _isDark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: Column(
        children: [
          FaraidHeader(
            theme: theme,
            isDark: isDark,
            title: 'แบ่งมรดกอิสลาม',
            bottom: _buildTabNav(theme, isDark),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildCalculatorTab(theme, isDark),
                _buildKnowledgeTab(theme, isDark),
                _buildCasesTab(theme, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabNav(AppThemeModel theme, bool isDark) {
    final heroText = theme.heroTextColor(isDark);
    final overlay = theme.isHeroLight(isDark) ? Colors.black : Colors.white;
    const labels = ['เครื่องคำนวณ', 'ความรู้เบื้องต้น', '7 กรณีศึกษา'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: overlay.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Semantics(
                button: true,
                selected: _tabs.index == i,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _tabs.animateTo(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: _tabs.index == i ? theme.cardBackground : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        labels[i],
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _tabs.index == i ? FontWeight.w600 : FontWeight.w400,
                          color: _tabs.index == i ? (isDark ? theme.textColor : theme.primaryDark) : heroText,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) => Container(
        width: double.infinity,
        padding: padding,
        decoration: FaraidStyle.card(_theme, _isDark),
        child: child,
      );

  // ---------------------------------------------------------------------------
  // Tab 1: calculator
  // ---------------------------------------------------------------------------
  Widget _buildCalculatorTab(AppThemeModel theme, bool isDark) {
    final uncertain = _calculateUncertain();
    final chain = _calculate();
    final stage0 = chain.stages.first;
    final blocked = uncertain != null ? const <HeirType, String>{} : {for (final b in stage0.result.blocked) b.type: b.reason};

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          FxFadeUp(index: 1, child: _card(child: _buildEstateInputs(theme, isDark))),
          const SizedBox(height: 14),
          FxFadeUp(index: 2, child: _card(child: _buildDeceased(theme, isDark))),
          const SizedBox(height: 14),
          FxFadeUp(
            index: 3,
            child: _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FaraidStyle.heading(theme, isDark, 'ทายาทที่ยังมีชีวิตขณะผู้ตายเสียชีวิต', number: 3),
                  const SizedBox(height: 4),
                  _HeirEditor(
                    deceasedMale: _deceasedMale,
                    heirs: _heirs,
                    theme: theme,
                    isDark: isDark,
                    blocked: blocked,
                    onChanged: (t, v) => setState(() => v == 0 ? _heirs.remove(t) : _heirs[t] = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FxFadeUp(index: 4, child: _card(child: _buildSpecials(theme, isDark))),
          const SizedBox(height: 14),
          FxFadeUp(index: 5, child: _card(child: _buildInlineResult(theme, isDark, chain, uncertain))),
          const SizedBox(height: 14),
          FaraidDisclaimer(
            theme: theme,
            text: 'ผลนี้คำนวณตามหลักมัซฮับชาฟิอีย์เพื่อเป็นแนวทางเบื้องต้น ก่อนแบ่งจริงควรยืนยันกับผู้รู้ '
                'หรือดะโต๊ะยุติธรรม / คณะกรรมการอิสลามประจำจังหวัด',
          ),
        ],
      ),
    );
  }

  Widget _buildEstateInputs(AppThemeModel theme, bool isDark) {
    final warn = FaraidStyle.warn(isDark);
    final red = isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: FaraidStyle.heading(theme, isDark, 'ทรัพย์สินและสิทธิก่อนแบ่ง', number: 1)),
            TextButton(
              onPressed: _resetAll,
              style: TextButton.styleFrom(minimumSize: const Size(44, 44), foregroundColor: _ink),
              child: const Text('ล้างค่า', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _buildModeSwitch(theme, isDark),
        const SizedBox(height: 12),
        if (!_detailedAssets)
          _MoneyField(
            controller: _grossCtrl,
            label: 'ทรัพย์สินรวมของผู้ตาย (บาท)',
            hint: 'เช่น 1,200,000',
            theme: theme,
            big: true,
            onChanged: () => setState(() {}),
          )
        else
          _buildItemisedTotal(theme),
        if (_detailedAssets) ...[
          const SizedBox(height: 6),
          Text('ใช้ราคาตลาด ณ วันที่เสียชีวิต', style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
          const SizedBox(height: 4),
          for (final a in _assetTypes) _assetRow(theme, a.$3, Text(a.$2, style: _assetNameStyle(theme)), _assetCtrls[a.$1]!),
          for (var i = 0; i < _customAssets.length; i++) _buildCustomAsset(i, theme),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _customAssets.add(_CustomAsset()));
              },
              style: TextButton.styleFrom(minimumSize: const Size(44, 44), foregroundColor: _ink),
              child: const Text('+ เพิ่มรายการอื่น ๆ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Align(alignment: Alignment.centerLeft, child: _softButton('ดึงยอดเงินในแอพ', _importAppBalance)),
        const SizedBox(height: 10),
        _pairFields(_funeralCtrl, '− ค่าจัดการศพ', _debtsCtrl, '− หนี้สิน', theme),
        _MoneyField(
          controller: _wasiyyahCtrl,
          label: '− พินัยกรรม (วะศียะฮ์) ',
          labelAccent: 'สูงสุด 1/3 = ${_money(_maxWasiyyah)}',
          accent: _ink,
          hint: '0',
          theme: theme,
          onChanged: () => setState(() {}),
        ),
        if (_wasiyyahOver)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'เกิน 1/3 ระบบใช้ ${_money(_maxWasiyyah)} (ส่วนเกินต้องได้รับความยินยอมจากทายาท)',
              style: TextStyle(fontSize: 12, color: warn),
            ),
          ),
        if (_gross > 0 && _funeral + _debts >= _gross)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'ค่าศพและหนี้เท่ากับหรือเกินทรัพย์สิน ทายาทไม่มีมรดกให้แบ่ง (ชำระหนี้ตามสัดส่วนเจ้าหนี้)',
              style: TextStyle(fontSize: 12, color: red),
            ),
          ),
        Divider(height: 24, color: theme.borderColor),
        Row(
          children: [
            Expanded(
              child: Text('มรดกสุทธิที่นำมาแบ่ง',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: theme.textColor)),
            ),
            FxProgress(
              value: _net,
              builder: (_, v) =>
                  Text(_money(v), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _ink)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _softButton(String label, VoidCallback onTap) {
    return Material(
      color: FaraidStyle.tint(_theme, _isDark ? 0.2 : 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40, minWidth: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _ink)),
          ),
        ),
      ),
    );
  }

  Widget _buildDeceased(AppThemeModel theme, bool isDark) {
    Widget option(bool male) {
      final sel = _deceasedMale == male;
      return Expanded(
        child: FxPress(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _deceasedMale = male;
              _heirs.remove(male ? HeirType.husband : HeirType.wife);
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: sel ? theme.primaryColor : theme.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: sel ? null : Border.all(color: theme.borderColor),
            ),
            child: Text(male ? 'ชาย' : 'หญิง',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                  color: sel ? Colors.white : theme.textColor,
                )),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FaraidStyle.heading(theme, isDark, 'ผู้เสียชีวิต', number: 2),
        const SizedBox(height: 10),
        Row(children: [option(true), const SizedBox(width: 8), option(false)]),
      ],
    );
  }

  Widget _pairFields(
    TextEditingController a,
    String la,
    TextEditingController b,
    String lb,
    AppThemeModel theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _MoneyField(controller: a, label: la, hint: '0', theme: theme, onChanged: () => setState(() {}))),
          const SizedBox(width: 8),
          Expanded(child: _MoneyField(controller: b, label: lb, hint: '0', theme: theme, onChanged: () => setState(() {}))),
        ],
      ),
    );
  }

  TextStyle _assetNameStyle(AppThemeModel theme) => TextStyle(fontSize: 13.5, color: theme.textColor);

  /// Switching to "กรอกยอดรวม" carries the current sum over as the manual value; the rows are kept.
  void _setBreakdown(bool on) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!on && _itemisedTotal > 0) {
        _grossCtrl.text = _GroupedNumberFormatter.group(_itemisedTotal.toStringAsFixed(_itemisedTotal % 1 == 0 ? 0 : 2));
      }
      _detailedAssets = on;
    });
  }

  /// "แยกรายการ" / "กรอกยอดรวม" segmented control under the section title.
  Widget _buildModeSwitch(AppThemeModel theme, bool isDark) {
    Widget seg(String label, bool on, VoidCallback onTap) => Expanded(
          child: Semantics(
            button: true,
            selected: on,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: on ? null : onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? theme.cardBackground : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: on && !isDark
                      ? const [BoxShadow(color: Color(0x2417142B), blurRadius: 4, offset: Offset(0, 1))]
                      : null,
                ),
                child: Text(label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                      color: on ? _ink : theme.textSecondaryColor,
                    )),
              ),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: FaraidStyle.tint(theme, isDark ? 0.16 : 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          seg('แยกรายการ', _detailedAssets, () => _setBreakdown(true)),
          const SizedBox(width: 4),
          seg('กรอกยอดรวม', !_detailedAssets, () => _setBreakdown(false)),
        ],
      ),
    );
  }

  /// Read-only total while the breakdown is on: the live sum of the rows.
  Widget _buildItemisedTotal(AppThemeModel theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('ทรัพย์สินรวมของผู้ตาย (บาท)', style: TextStyle(fontSize: 12.5, color: theme.textSecondaryColor)),
        const SizedBox(height: 4),
        Semantics(
          readOnly: true,
          label: 'ทรัพย์สินรวมของผู้ตาย',
          child: Container(
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.scaffoldBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.borderColor, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: FxProgress(
                    value: _itemisedTotal,
                    builder: (_, v) => Text(
                      _GroupedNumberFormatter.group(v.toStringAsFixed(_itemisedTotal % 1 == 0 ? 0 : 2)),
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: theme.textColor),
                    ),
                  ),
                ),
                Text('รวมอัตโนมัติ', style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _assetRow(AppThemeModel theme, IconData icon, Widget name, TextEditingController amount, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _ink),
          const SizedBox(width: 10),
          Expanded(child: name),
          const SizedBox(width: 8),
          SizedBox(
            width: 132,
            child: TextField(
              controller: amount,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')), _GroupedNumberFormatter()],
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: 15, color: theme.textColor),
              decoration: _inputDecoration(theme).copyWith(hintText: '0'),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildCustomAsset(int i, AppThemeModel theme) {
    final a = _customAssets[i];
    return _assetRow(
      theme,
      Icons.inventory_2_outlined,
      TextField(
        controller: a.nameCtrl,
        style: _assetNameStyle(theme),
        decoration: _inputDecoration(theme).copyWith(hintText: 'ชื่อรายการ เช่น เรือประมง'),
      ),
      a.valueCtrl,
      trailing: IconButton(
        tooltip: 'ลบรายการ',
        icon: Icon(Icons.close_rounded, color: theme.textSecondaryColor),
        onPressed: () => setState(() => _customAssets.removeAt(i).dispose()),
      ),
    );
  }

  // ---------------- Step 4: unexpected events ----------------
  Widget _buildSpecials(AppThemeModel theme, bool isDark) {
    const items = [
      (_Special.haml, 'ทารกในครรภ์'),
      (_Special.mafqud, 'ทายาทสูญหาย'),
      (_Special.muna, 'ทายาทเสียชีวิตก่อนแบ่ง'),
      (_Special.gharqa, 'เสียชีวิตพร้อมกัน'),
      (_Special.mani, 'ทายาทถูกตัดสิทธิ์'),
      (_Special.talaq, 'หย่าระหว่างอิดดะฮ์'),
    ];
    final none = items.every((i) => !_isOn(i.$1));
    final chips = <Widget>[
      _optionChip('ไม่มี', none, _noSpecial, expand: true),
      for (final it in items) _optionChip(it.$2, _isOn(it.$1), () => _toggle(it.$1), expand: true),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FaraidStyle.heading(theme, isDark, 'เหตุการณ์ที่ไม่คาดคิด', number: 4),
        const SizedBox(height: 2),
        Text('เลือกถ้ามีเหตุการณ์พิเศษ ระบบจะเปลี่ยนวิธีคำนวณให้ตามหลักมัซฮับชาฟิอีย์ (เลือกได้มากกว่า 1 ข้อ)',
            style: TextStyle(fontSize: 12, height: 1.45, color: theme.textSecondaryColor)),
        const SizedBox(height: 12),
        for (var i = 0; i < chips.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: chips[i]),
              const SizedBox(width: 6),
              Expanded(child: i + 1 < chips.length ? chips[i + 1] : const SizedBox.shrink()),
            ],
          ),
        ],
        if (_fetusOn) _hamlPanel(theme, isDark),
        if (_missingOn) _mafqudPanel(theme, isDark),
        if (_laterOn) _munaPanel(theme, isDark),
        if (_togetherOn) _gharqaPanel(theme, isDark),
        if (_maniOn) _maniPanel(theme, isDark),
        if (_talaqOn) _talaqPanel(theme, isDark),
      ],
    );
  }

  Widget _optionChip(String label, bool on, VoidCallback onTap, {bool expand = false, double radius = 12}) {
    final theme = _theme;
    return Material(
      color: on ? theme.primaryColor : theme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: on ? BorderSide.none : BorderSide(color: theme.borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          alignment: expand ? Alignment.center : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: on ? FontWeight.w600 : FontWeight.w400,
              color: on ? Colors.white : theme.textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _panel({
    required String title,
    required String arabic,
    required String desc,
    List<Widget> body = const [],
    List<String> steps = const [],
    String? resolveLabel,
    List<(String, VoidCallback)> actions = const [],
  }) {
    final theme = _theme;
    final isDark = _isDark;
    final ink = _ink;
    final text = TextStyle(fontSize: 12.5, height: 1.6, color: theme.textSecondaryColor);
    return FxFadeUp(
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: FaraidStyle.tint(theme, isDark ? 0.1 : 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ink.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(title,
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: theme.textColor)),
                ),
                const SizedBox(width: 8),
                Text(arabic,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ink)),
              ],
            ),
            const SizedBox(height: 8),
            Text(desc, style: text),
            for (final b in body) ...[const SizedBox(height: 12), b],
            if (steps.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('วิธีคำนวณ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: ink)),
              for (var i = 0; i < steps.length; i++) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: FaraidStyle.tint(theme, isDark ? 0.25 : 0.1), shape: BoxShape.circle),
                      child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ink)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(steps[i], style: text)),
                  ],
                ),
              ],
            ],
            if (resolveLabel != null) ...[
              Divider(height: 24, color: theme.borderColor),
              Text(resolveLabel, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: theme.textColor)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final a in actions)
                    FilledButton(
                      onPressed: a.$2,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(44, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(a.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chipGroup(String label, List<Widget> chips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _ink)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: chips),
      ],
    );
  }

  Widget _pill(String label, bool on, VoidCallback onTap) => _optionChip(label, on, onTap, radius: 22);

  Widget _hamlPanel(AppThemeModel theme, bool isDark) {
    final rel = _fetusRelations[_fetusRelation];
    final u = _calculateUncertain();
    void resolve(Map<HeirType, int> add, String label) {
      HapticFeedback.mediumImpact();
      setState(() {
        _addHeirs(add);
        _fetusOn = false;
      });
      _snack('บันทึกผลการคลอด ($label) ในข้อ 3 แล้ว คำนวณใหม่ให้แล้ว');
    }

    return _panel(
      title: 'ทารกในครรภ์ (อัล-ฮัมล์)',
      arabic: 'الحمل',
      desc: 'ทารกในครรภ์มีสิทธิ์รับมรดกถ้าคลอดออกมามีชีวิต แต่ยังไม่รู้ว่าเป็นชายหรือหญิง และกี่คน ไม่ต้องนับทารกในข้อ 3',
      body: [
        _chipGroup('ทารกจะเป็นอะไรกับผู้ตาย', [
          for (var i = 0; i < _fetusRelations.length; i++)
            _pill(_fetusRelations[i].$1, _fetusRelation == i, () => setState(() => _fetusRelation = i)),
        ]),
        _chipGroup('เผื่อจำนวนทารกสูงสุด', [
          for (final n in [1, 2, 3, 4]) _pill('$n คน', _fetusMax == n, () => setState(() => _fetusMax = n)),
        ]),
      ],
      steps: [
        'สร้างสถานการณ์ที่เป็นไปได้ทั้งหมด ${u?.outcomes.length ?? 0} แบบ (เสียชีวิตก่อนคลอด, เป็น${rel.$2.th}, เป็น${rel.$3.th}, แฝด ฯลฯ)',
        'คำนวณแต่ละสถานการณ์ตามหลักฟะรออิฎปกติ',
        'ให้ทายาทแต่ละคนรับส่วนที่น้อยที่สุดก่อน',
        'ส่วนที่เหลือกันไว้ (มัวกูฟ) จนกว่าทารกจะคลอด',
        'เมื่อทราบผลแน่นอน ให้กดปุ่มด้านล่าง ระบบจะใส่ทารกในข้อ 3 แล้วคำนวณใหม่ให้ครบ',
      ],
      resolveLabel: 'ทารกคลอดแล้ว เลือกผลจริง:',
      actions: [
        ('ชาย 1', () => resolve({rel.$2: 1}, 'ชาย 1')),
        ('หญิง 1', () => resolve({rel.$3: 1}, 'หญิง 1')),
        ('แฝดชาย 2', () => resolve({rel.$2: 2}, 'แฝดชาย 2')),
        ('แฝดหญิง 2', () => resolve({rel.$3: 2}, 'แฝดหญิง 2')),
        ('ชาย 1 หญิง 1', () => resolve({rel.$2: 1, rel.$3: 1}, 'ชาย 1 หญิง 1')),
        ('เสียชีวิตในครรภ์', () => resolve(const {}, 'เสียชีวิตในครรภ์')),
      ],
    );
  }

  Widget _mafqudPanel(AppThemeModel theme, bool isDark) {
    final types = _missingTypes;
    final common = [
      HeirType.son,
      HeirType.daughter,
      HeirType.fullBrother,
      HeirType.fullSister,
      HeirType.father,
      _deceasedMale ? HeirType.wife : HeirType.husband,
    ];
    final type = types.contains(_missingType) ? _missingType : HeirType.son;
    return _panel(
      title: 'ทายาทสูญหาย (อัล-มัฟกูด)',
      arabic: 'المفقود',
      desc: 'ทายาทหายสาบสูญโดยไม่รู้ว่ายังมีชีวิตหรือไม่ ไม่ต้องนับผู้สูญหายในข้อ 3 ให้เลือกที่นี่แทน',
      body: [
        _chipGroup('ผู้สูญหายคือ', [
          for (final t in common)
            _pill(t.th, type == t, () => setState(() {
                  _missingType = t;
                  _missingCount = _missingCount.clamp(1, t.maxCount);
                })),
        ]),
        DropdownButtonFormField<HeirType>(
          key: ValueKey('missing_${_deceasedMale}_$type'),
          initialValue: type,
          isExpanded: true,
          decoration: _inputDecoration(theme).copyWith(labelText: 'หรือเลือกญาติอื่น'),
          items: [
            for (final t in types)
              DropdownMenuItem(
                value: t,
                child: Text(t.th, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: theme.textColor)),
              ),
          ],
          onChanged: (v) => setState(() {
            _missingType = v ?? HeirType.son;
            _missingCount = _missingCount.clamp(1, _missingType.maxCount);
          }),
        ),
        if (type.maxCount > 1)
          _chipGroup('จำนวนผู้สูญหาย', [
            for (final n in [1, 2, 3]) _pill('$n คน', _missingCount == n, () => setState(() => _missingCount = n)),
          ]),
      ],
      steps: const [
        'คำนวณทั้งกรณีที่ผู้สูญหายยังมีชีวิตและเสียชีวิตแล้ว',
        'ทายาทคนอื่นรับส่วนที่น้อยกว่าไปก่อน',
        'ส่วนที่เหลือกันไว้ (มัวกูฟ) จนกว่าผู้สูญหายกลับมา หรือศาล/ดาโต๊ะยุติธรรมตัดสินว่าเสียชีวิต',
      ],
      resolveLabel: 'เมื่อทราบผล:',
      actions: [
        (
          'ผู้สูญหายกลับมา (มีชีวิต)',
          () {
            setState(() {
              _addHeirs({type: _missingCount});
              _missingOn = false;
            });
            _snack('เพิ่ม${type.th}ในข้อ 3 แล้ว คำนวณใหม่ให้แล้ว');
          }
        ),
        (
          'ศาลตัดสินว่าเสียชีวิต',
          () {
            setState(() => _missingOn = false);
            _snack('คำนวณใหม่โดยไม่นับผู้สูญหายแล้ว');
          }
        ),
      ],
    );
  }

  Widget _munaPanel(AppThemeModel theme, bool isDark) {
    return _panel(
      title: 'ทายาทเสียชีวิตก่อนแบ่ง (มุนาสะเคาะฮ์)',
      arabic: 'المناسخات',
      desc: 'ทายาทได้สิทธิ์ตั้งแต่ผู้ตายเสียชีวิต ถ้าเขาเสียชีวิตก่อนแบ่ง ส่วนของเขาต้องแบ่งต่อให้ทายาทของเขาเอง (มรดกชั้นที่ 2)',
      body: [
        if (_hasUncertain)
          Text(
            'ระหว่างรอทารกคลอดหรือรอศาลตัดสินเรื่องผู้สูญหาย ยังแบ่งต่อเป็นทอด ๆ ไม่ได้ เพราะส่วนของแต่ละคนยังไม่แน่นอน — เมื่อทราบผลแล้วจึงคำนวณขั้นนี้',
            style: TextStyle(fontSize: 12.5, height: 1.5, color: FaraidStyle.warn(isDark)),
          )
        else
          _buildLaterDeaths(theme, isDark),
      ],
      steps: const [
        'แบ่งมรดกชั้นที่ 1 ตามปกติ (ดูผลลัพธ์ในข้อ 5)',
        'เลือกทายาทที่เสียชีวิตก่อนแบ่ง ระบบจะนำส่วนของเขา 1 คนมาเป็นกองมรดกชั้นที่ 2',
        'กรอกทายาทที่ยังมีชีวิตของเขา (เช่น มารดา พี่น้อง ลูกของเขา)',
        'ถ้ามีคนเสียชีวิตต่ออีก เพิ่มได้ไม่จำกัดชั้น ดูผลทุกชั้นในหน้าผลการแบ่งมรดก',
      ],
    );
  }

  Widget _gharqaPanel(AppThemeModel theme, bool isDark) {
    return _panel(
      title: 'เสียชีวิตพร้อมกัน (อัล-ฆอร็อก)',
      arabic: 'الغرقى والهدمى',
      desc: 'ผู้ที่เสียชีวิตในเหตุการณ์เดียวกันโดยไม่รู้ว่าใครเสียชีวิตก่อน มัซฮับชาฟิอีย์ถือว่าไม่รับมรดกกันและกัน',
      body: [_buildTogether(theme, isDark)],
      steps: const [
        'ไม่นับผู้ที่เสียชีวิตพร้อมกันเป็นทายาทในข้อ 3',
        'แบ่งมรดกของผู้ตายคนแรกให้ทายาทที่ยังมีชีวิต (ผลลัพธ์ในข้อ 5)',
        'แบ่งทรัพย์สินของผู้ที่เสียชีวิตพร้อมกันแยกต่างหาก ให้ทายาทที่ยังมีชีวิตของเขาเท่านั้น โดยผู้ตายคนแรกไม่นับเป็นทายาทของเขาเช่นกัน',
      ],
    );
  }

  Widget _maniPanel(AppThemeModel theme, bool isDark) {
    return _panel(
      title: 'ทายาทถูกตัดสิทธิ์ (มะวานิอ์)',
      arabic: 'موانع الإرث',
      desc: 'ญาติที่ต่างศาสนากับผู้ตาย หรือเป็นผู้ฆ่าผู้ตาย ไม่มีสิทธิ์รับมรดก และไม่ถูกนับเพื่อกันหรือลดส่วนของใคร ไม่ต้องใส่เขาในข้อ 3',
      steps: const [
        'ผู้ที่ถูกตัดสิทธิ์ (ต่างศาสนา ฆ่าผู้ตาย หรือเป็นทาส) ถือเหมือนไม่มีตัวตนในการแบ่ง',
        'ไม่ลดส่วนผู้อื่น เช่น พี่น้องที่ต่างศาสนา 2 คน ไม่ทำให้มารดาลดจาก 1/3 เป็น 1/6',
        'ไม่กันสิทธิ์ผู้อื่น เช่น บุตรชายที่ฆ่าบิดา ไม่กันพี่น้องของผู้ตาย',
        'แบ่งมรดกให้ทายาทที่เหลือตามปกติ (ผลลัพธ์ในข้อ 5)',
      ],
    );
  }

  Widget _talaqPanel(AppThemeModel theme, bool isDark) {
    final spouse = _deceasedMale ? HeirType.wife : HeirType.husband;
    final sp = spouse.th;
    final has = (_heirs[spouse] ?? 0) > 0;
    return _panel(
      title: 'หย่าระหว่างอิดดะฮ์',
      arabic: 'الطلاق في العدة',
      desc: 'ถ้าผู้ตายหย่ากับคู่สมรสแล้วเสียชีวิตระหว่างอิดดะฮ์ สิทธิ์รับมรดกขึ้นกับประเภทการหย่า',
      body: [
        _chipGroup('ประเภทการหย่า', [
          _pill('ร็อจอีย์ (คืนดีได้)', !_talaqBain, () => setState(() => _talaqBain = false)),
          _pill('บาอิน (คืนดีไม่ได้)', _talaqBain, () => setState(() => _talaqBain = true)),
        ]),
      ],
      steps: _talaqBain
          ? [
              'หย่าแบบบาอิน (หย่าครั้งที่ 3 หรือคุลอ์) ความเป็นคู่สมรสสิ้นสุดทันที',
              'ตามทัศนะใหม่ (เกาวล์ญะดีด) ของอิมามชาฟิอีย์ $spไม่ได้รับมรดก แม้หย่าขณะผู้ตายป่วยหนัก',
              has ? 'ข้อ 3 ยังมี$sp อยู่ กดปุ่มด้านล่างเพื่อนำออก' : 'ไม่มี$spในข้อ 3 อยู่แล้ว',
            ]
          : [
              'หย่าแบบร็อจอีย์และยังอยู่ในอิดดะฮ์ ถือว่ายังเป็นคู่สมรส',
              '$spยังได้รับมรดกตามปกติ${has ? '' : ' (อย่าลืมใส่$spในข้อ 3)'}',
            ],
      resolveLabel: _talaqBain && has ? 'ขั้นต่อไป:' : null,
      actions: [
        if (_talaqBain && has) ('นำ$spออกจากข้อ 3', () => setState(() => _heirs.remove(spouse))),
      ],
    );
  }

  Widget _buildTogether(AppThemeModel theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _together.length; i++) _buildTogetherCard(i, theme, isDark),
        OutlinedButton.icon(
          onPressed: () {
            HapticFeedback.selectionClick();
            setState(() => _together.add(_SimultaneousDraft()));
          },
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(_together.isEmpty ? 'เพิ่มผู้ที่เสียชีวิตพร้อมกัน' : 'เพิ่มอีกคน',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          style: _outlinedStyle(theme),
        ),
      ],
    );
  }

  ButtonStyle _outlinedStyle(AppThemeModel theme) => OutlinedButton.styleFrom(
        minimumSize: const Size(44, 46),
        foregroundColor: _ink,
        side: BorderSide(color: _ink.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _subCard({required String badge, required String title, required VoidCallback onDelete, required List<Widget> children}) {
    final theme = _theme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 12),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(8)),
                child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: theme.textColor)),
              ),
              IconButton(
                tooltip: 'ลบ',
                icon: Icon(Icons.delete_outline_rounded, color: theme.textSecondaryColor),
                onPressed: onDelete,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTogetherCard(int i, AppThemeModel theme, bool isDark) {
    final d = _together[i];
    final name = d.nameCtrl.text.trim().isEmpty ? 'ผู้ตายคนนี้' : d.nameCtrl.text.trim();
    return _subCard(
      badge: 'คนที่ ${i + 1}',
      title: 'ผู้เสียชีวิตพร้อมกัน',
      onDelete: () => setState(() => _together.removeAt(i).dispose()),
      children: [
        const SizedBox(height: 4),
        TextField(
          controller: d.nameCtrl,
          onChanged: (_) => setState(() {}),
          style: TextStyle(fontSize: 15, color: theme.textColor),
          decoration: _inputDecoration(theme).copyWith(labelText: 'เป็นใคร (เช่น ลูกชาย, ภรรยา)'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final male in [true, false]) ...[
              Expanded(
                child: _optionChip(male ? 'ชาย' : 'หญิง', d.male == male, () => setState(() {
                      d.male = male;
                      d.heirs.remove(male ? HeirType.husband : HeirType.wife);
                    }), expand: true),
              ),
              if (male) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 10),
        _MoneyField(
          controller: d.ownAssetsCtrl,
          label: 'ทรัพย์สินสุทธิของ$name (หลังหักค่าศพ หนี้ พินัยกรรม)',
          hint: '0',
          theme: theme,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 10),
        Text('ทายาทของ$name ที่ยังมีชีวิตอยู่',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textColor)),
        _HeirEditor(
          deceasedMale: d.male,
          heirs: d.heirs,
          theme: theme,
          isDark: isDark,
          onChanged: (t, v) => setState(() => v == 0 ? d.heirs.remove(t) : d.heirs[t] = v),
        ),
      ],
    );
  }

  Widget _buildLaterDeaths(AppThemeModel theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _later.length; i++) _buildLaterDeathCard(i, theme, isDark),
        OutlinedButton.icon(
          onPressed: () {
            HapticFeedback.selectionClick();
            setState(() => _later.add(_LaterDeathDraft()));
          },
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(_later.isEmpty ? 'เพิ่มทายาทที่เสียชีวิตตามมา' : 'เพิ่มอีกคน',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          style: _outlinedStyle(theme),
        ),
      ],
    );
  }

  Widget _buildLaterDeathCard(int i, AppThemeModel theme, bool isDark) {
    final d = _later[i];
    final options = _optionsFor(i);
    final selectedKey = d.heirType == null ? null : '${d.fromDraft}|${d.heirType!.name}|${d.heirIndex}';
    final hasSelected = options.any((o) => o.key == selectedKey);

    return _subCard(
      badge: 'ชั้นที่ ${i + 2}',
      title: 'ผู้เสียชีวิตตามมา',
      onDelete: () => setState(() {
        final removed = _later.removeAt(i);
        removed.dispose();
        for (final x in _later) {
          if (x.fromDraft == i) {
            x.fromDraft = -1;
            x.heirType = null;
          } else if (x.fromDraft > i) {
            x.fromDraft -= 1;
          }
        }
      }),
      children: [
        Text('ใครเสียชีวิต?', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: theme.textSecondaryColor)),
        const SizedBox(height: 4),
        if (options.isEmpty && !hasSelected)
          Text('ยังไม่มีทายาทที่ได้รับมรดก — เลือกทายาทในข้อ 3 ก่อน',
              style: TextStyle(fontSize: 12, color: theme.textSecondaryColor))
        else
          DropdownButtonFormField<String>(
            key: ValueKey('later_${i}_${options.length}_$selectedKey'),
            initialValue: hasSelected ? selectedKey : null,
            isExpanded: true,
            hint: const Text('แตะเพื่อเลือกทายาท'),
            decoration: _inputDecoration(theme),
            items: [
              for (final o in options)
                DropdownMenuItem(
                  value: o.key,
                  child: Text(o.label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: theme.textColor)),
                ),
            ],
            onChanged: (key) {
              final o = options.firstWhere((x) => x.key == key);
              setState(() {
                d.fromDraft = o.fromDraft;
                d.heirType = o.type;
                d.heirIndex = o.index;
                d.heirs.remove(o.type.isMale ? HeirType.husband : HeirType.wife);
              });
            },
          ),
        if (d.heirType != null) ...[
          const SizedBox(height: 10),
          _MoneyField(
            controller: d.ownAssetsCtrl,
            label: 'ทรัพย์สินส่วนตัวของ${d.heirType!.th} (ถ้ามี)',
            hint: '0',
            theme: theme,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 10),
          Text('ทายาทของ${d.heirType!.th} ที่ยังมีชีวิตอยู่',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textColor)),
          Text(
            'นับเทียบกับ${d.heirType!.th}เป็นหลัก เช่น พี่น้องของผู้ตายคนแรกที่ยังมีชีวิต อาจเป็น "พี่น้อง" ของ${d.heirType!.th}ด้วย',
            style: TextStyle(fontSize: 12, height: 1.4, color: theme.textSecondaryColor),
          ),
          _HeirEditor(
            deceasedMale: d.heirType!.isMale,
            heirs: d.heirs,
            theme: theme,
            isDark: isDark,
            onChanged: (t, v) => setState(() => v == 0 ? d.heirs.remove(t) : d.heirs[t] = v),
          ),
        ],
      ],
    );
  }

  // ---------------- Step 5: result ----------------
  Widget _buildInlineResult(AppThemeModel theme, bool isDark, MunasakhatResult chain, UncertainResult? uncertain) {
    final hasHeirs = _heirTotal > 0 || uncertain != null;
    final ready = hasHeirs && _net > 0;
    final stages = chain.stages.length;
    final Widget body;
    if (!ready) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FaraidStyle.heading(theme, isDark, 'ผลการแบ่งมรดก', number: 5),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: theme.scaffoldBackground, borderRadius: BorderRadius.circular(12)),
            child: Text(
              !hasHeirs
                  ? 'เพิ่มทายาทอย่างน้อย 1 คนเพื่อเริ่มคำนวณ'
                  : 'มรดกสุทธิเป็น 0 (ใส่ทรัพย์สิน หรือหนี้และค่าใช้จ่ายเท่ากับหรือเกินทรัพย์สิน)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: theme.textSecondaryColor),
            ),
          ),
        ],
      );
    } else if (uncertain != null) {
      body = FaraidUncertainBreakdown(
        result: uncertain,
        estate: _net,
        theme: theme,
        isDark: isDark,
        title: 'ผลการแบ่งมรดก',
        number: 5,
      );
    } else {
      body = FaraidShareBreakdown(
        result: chain.stages.first.result,
        estate: chain.stages.first.estate,
        theme: theme,
        isDark: isDark,
        title: 'ผลการแบ่งมรดก',
        number: 5,
        passed: chain.passedOn(0),
        onDied: _markDied,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        const SizedBox(height: 14),
        if (stages > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('มีการแบ่งต่อทั้งหมด $stages ชั้น — ดูผลของทุกชั้นในหน้าผลการแบ่งมรดก',
                style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
          ),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _openResult,
            style: FilledButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('ดูผลการแบ่งมรดก', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2: knowledge
  // ---------------------------------------------------------------------------
  Widget _buildKnowledgeTab(AppThemeModel theme, bool isDark) {
    final body = TextStyle(fontSize: 12.5, height: 1.55, color: theme.textSecondaryColor);
    Widget item(String title, String text) => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.borderColor.withValues(alpha: 0.6)))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: theme.textColor)),
              const SizedBox(height: 2),
              Text(text, style: body),
            ],
          ),
        );
    Widget section(int n, String title, List<Widget> children) => _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FaraidStyle.heading(theme, isDark, title, number: n),
              const SizedBox(height: 10),
              ...children,
            ],
          ),
        );
    Widget fard(String frac, List<String> who) => Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.borderColor.withValues(alpha: 0.6)))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: FaraidStyle.tint(theme, isDark ? 0.22 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(frac, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _ink)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final w in who)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('•  ', style: TextStyle(fontSize: 12.5, height: 1.5, color: theme.textColor)),
                            Expanded(
                              child: Text(w, style: TextStyle(fontSize: 12.5, height: 1.5, color: theme.textColor)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );

    final sections = <Widget>[
      _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ฟะรออิฎ คืออะไร', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textColor)),
            const SizedBox(height: 8),
            Text(
              'วิชาว่าด้วยการแบ่งทรัพย์มรดกของผู้เสียชีวิตให้ทายาทตามสัดส่วนที่อัลลอฮ์ทรงกำหนดไว้ในอัลกุรอาน ซูเราะฮ์อันนิสาอ์ อายะฮ์ที่ 11, 12 และ 176 และตามซุนนะฮ์ของท่านนบี ﷺ',
              style: TextStyle(fontSize: 13, height: 1.65, color: theme.textColor),
            ),
            const SizedBox(height: 8),
            Text('แอปนี้ยึดหลักมัซฮับชาฟิอีย์ ซึ่งเป็นมัซฮับที่มุสลิมในประเทศไทยส่วนใหญ่ถือปฏิบัติ', style: body),
          ],
        ),
      ),
      section(1, 'หลักพื้นฐานของการรับมรดก', [
        item('เสาหลัก 3 ประการ', 'ผู้ตาย (มูวัรริษ) • ทายาท (วาริษ) • ทรัพย์มรดก (มีรอษ)'),
        item('เงื่อนไข 3 ประการ',
            'ผู้ตายเสียชีวิตจริงหรือศาลตัดสินว่าเสียชีวิต • ทายาทมีชีวิตอยู่ขณะผู้ตายเสียชีวิต (แม้เป็นทารกในครรภ์) • ทราบความสัมพันธ์ที่ทำให้ได้รับมรดก'),
        item('สาเหตุที่ได้รับมรดก', 'เครือญาติทางสายเลือด (นะซับ) • การสมรสที่ถูกต้อง (นิกาห์) • การปลดปล่อยทาส (วะลาอ์)'),
        item('สิ่งที่ตัดสิทธิ์การรับมรดก (มะวานิอ์)',
            'ต่างศาสนากัน • ทายาทเป็นผู้ฆ่าผู้ตาย • การเป็นทาส ผู้ที่ถูกตัดสิทธิ์จะไม่นับเป็นทายาท และไม่ลดส่วนของผู้อื่น'),
      ]),
      section(2, 'ลำดับสิทธิ 4 ประการก่อนแบ่งมรดก', [
        item('1. ค่าจัดการศพ (ตัจฮีซ)', 'จัดการศพอย่างสมเกียรติและพอประมาณ ไม่ฟุ่มเฟือย'),
        item('2. ชำระหนี้สิน (ดัยน์)', 'ทั้งหนี้ต่อมนุษย์ และหนี้ต่ออัลลอฮ์ เช่น ซะกาตที่ค้างจ่าย'),
        item('3. พินัยกรรม (วะศียะฮ์)', 'ไม่เกิน 1/3 ของทรัพย์ที่เหลือ และห้ามทำให้ทายาทผู้มีสิทธิ์ เว้นแต่ทายาทคนอื่นยินยอม'),
        item('4. แบ่งมรดกสุทธิ (ตะริกะฮ์)', 'ส่วนที่เหลือนำมาแบ่งตามหลักฟะรออิฎ'),
      ]),
      section(3, 'ประเภทของทายาท', [
        item('ทายาทฟุรูฎ (อัศฮาบุลฟุรูฎ)', 'ผู้มีสัดส่วนตายตัวในอัลกุรอาน เช่น สามี ภรรยา บิดา มารดา บุตรสาว ได้รับก่อนเสมอ'),
        item('อะศอบะฮ์ บินนัฟส์',
            'ญาติผู้ชายสายบิดา รับส่วนที่เหลือ เรียงตามลำดับ: บุตรชาย → หลานชาย → บิดา → ปู่ → พี่น้องชายแท้ → พี่น้องชายร่วมบิดา → ลูกชายของพี่น้องชาย → ลุง/อา → ลูกชายของลุง/อา'),
        item('อะศอบะฮ์ บิลเฆาะยร์', 'ผู้หญิงที่กลายเป็นอะศอบะฮ์เพราะมีพี่น้องชายระดับเดียวกัน แบ่งชาย 2 : หญิง 1 เช่น บุตรสาวกับบุตรชาย'),
        item('อะศอบะฮ์ มะอัลเฆาะยร์',
            'พี่น้องหญิงแท้หรือร่วมบิดา เมื่ออยู่ร่วมกับบุตรสาวหรือหลานสาว (ลูกของบุตรชาย) จะรับส่วนที่เหลือ'),
        item('ซะวิลอัรฮาม', 'ญาติที่ไม่ใช่ฟุรูฎและไม่ใช่อะศอบะฮ์ เช่น ลูกของบุตรสาว ลุงฝั่งแม่ จะได้รับเมื่อไม่มีสองกลุ่มแรก'),
      ]),
      section(4, 'สัดส่วนฟุรูฎ 6 สัดส่วนตามอัลกุรอาน', [
        fard('1/2', const [
          'สามี เมื่อผู้ตายไม่มีลูกหลาน',
          'บุตรสาวคนเดียว (ไม่มีบุตรชาย)',
          'หลานสาว (ลูกของบุตรชาย) คนเดียว เมื่อไม่มีบุตร',
          'พี่น้องหญิงแท้คนเดียว',
          'พี่น้องหญิงร่วมบิดาคนเดียว เมื่อไม่มีพี่น้องแท้',
        ]),
        fard('1/4', const ['สามี เมื่อผู้ตายมีลูกหลาน', 'ภรรยา (คนเดียวหรือหลายคนแบ่งกัน) เมื่อไม่มีลูกหลาน']),
        fard('1/8', const ['ภรรยา เมื่อผู้ตายมีลูกหลาน']),
        fard('2/3', const [
          'บุตรสาว 2 คนขึ้นไป',
          'หลานสาว (ลูกของบุตรชาย) 2 คนขึ้นไป เมื่อไม่มีบุตร',
          'พี่น้องหญิงแท้ 2 คนขึ้นไป',
          'พี่น้องหญิงร่วมบิดา 2 คนขึ้นไป',
        ]),
        fard('1/3', const [
          'มารดา เมื่อไม่มีลูกหลาน และพี่น้องไม่ถึง 2 คน',
          'พี่น้องร่วมมารดา 2 คนขึ้นไป (ชายหญิงเท่ากัน)',
          'ปู่ ในบางกรณีเมื่ออยู่ร่วมกับพี่น้อง',
        ]),
        fard('1/6', const [
          'บิดา หรือปู่ เมื่อผู้ตายมีลูกหลาน',
          'มารดา เมื่อมีลูกหลาน หรือพี่น้อง 2 คนขึ้นไป',
          'ย่า/ยาย (คนเดียวหรือแบ่งกัน)',
          'หลานสาว เมื่อมีบุตรสาวคนเดียว',
          'พี่น้องหญิงร่วมบิดา เมื่อมีพี่น้องหญิงแท้คนเดียว',
          'พี่น้องร่วมมารดาคนเดียว',
        ]),
      ]),
      section(5, 'การกันสิทธิ์ (ฮัจบ์)', [
        item('ฮัจบ์ ฮิรมาน: กันจนไม่ได้รับเลย',
            'ญาติที่ใกล้กว่ากันญาติที่ไกลกว่าในสายเดียวกัน เช่น บิดากันปู่ มารดากันย่าและยาย บุตรชายกันหลานและพี่น้องทุกคน'),
        item('ฮัจบ์ นุกศอน: ลดส่วนลง',
            'เช่น ลูกหลานลดส่วนสามีจาก 1/2 เป็น 1/4 • พี่น้อง 2 คนขึ้นไปลดส่วนมารดาจาก 1/3 เป็น 1/6 แม้พี่น้องนั้นจะถูกบิดากันสิทธิ์ก็ตาม'),
        item('6 ทายาทที่ไม่มีใครกันสิทธิ์ได้', 'สามี • ภรรยา • บิดา • มารดา • บุตรชาย • บุตรสาว'),
        item('ข้อควรรู้ของมัซฮับชาฟิอีย์',
            'ปู่ไม่กันพี่น้องแท้และพี่น้องร่วมบิดา แต่แบ่งร่วมกันตามทัศนะท่านเซด บิน ษาบิต • บิดากันย่า (มารดาของบิดา)'),
      ]),
      section(6, 'ขั้นตอนการคำนวณของเครื่องคำนวณ', [
        item('1. ฟุรูฎ', 'ให้ส่วนตายตัว 1/2, 1/4, 1/8, 2/3, 1/3, 1/6 แก่ทายาทผู้มีสิทธิ์ หาฐานร่วม (อัศล์) จาก 2, 3, 4, 6, 8, 12, 24'),
        item('2. เอาล์', 'ถ้าส่วนฟุรูฎรวมเกินกองมรดก ให้เพิ่มฐานแล้วลดส่วนของทุกคนตามสัดส่วน เช่น ฐาน 24 เป็น 27'),
        item('3. อะศอบะฮ์', 'ให้ส่วนที่เหลือแก่อะศอบะฮ์ที่ใกล้ที่สุด ชาย 2 : หญิง 1'),
        item('4. ร็อดด์',
            'ถ้าไม่มีอะศอบะฮ์และยังมีส่วนเหลือ เฉลี่ยคืนให้ทายาทฟุรูฎตามสัดส่วน ยกเว้นคู่สมรส (ทัศนะนักวิชาการชาฟิอีย์รุ่นหลัง เมื่อไม่มีบัยตุลมาลที่ดำเนินการถูกต้อง)'),
        item('5. ซะวิลอัรฮาม / บัยตุลมาล', 'ถ้าไม่มีทายาทข้างต้นรับต่อ ส่วนที่เหลือให้ญาติซะวิลอัรฮาม หากไม่มีจึงเข้ากองทุนสาธารณะ'),
        item('6. กรณีพิเศษ', 'ตรวจคดีอัล-เฆาะรอวัยน์ อัล-มุชตะเราะเกาะฮ์ อัล-อักดะรียะฮ์ และปู่ร่วมกับพี่น้อง โดยอัตโนมัติ'),
        item('7. ทายาทที่ยังไม่แน่นอน',
            'ทารกในครรภ์ / ผู้สูญหาย: คำนวณทุกสถานการณ์ ให้ทุกคนรับส่วนที่น้อยที่สุดก่อน แล้วกันส่วนที่เหลือไว้'),
      ]),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          FxFadeUp(index: i, child: sections[i]),
        ],
        const SizedBox(height: 14),
        FaraidDisclaimer(
          theme: theme,
          text: 'เนื้อหานี้เป็นความรู้เบื้องต้น ก่อนแบ่งจริงควรยืนยันกับผู้รู้ หรือดะโต๊ะยุติธรรม / คณะกรรมการอิสลามประจำจังหวัด\n'
              'อ้างอิง: อัลกุรอาน ซูเราะฮ์อัน-นิสาอ์ 4:11, 4:12, 4:176 • ศอฮีหฺอัล-บุคอรีย์ และมุสลิม • ตำราฟะรออิฎมัซฮับชาฟิอีย์ (เช่น อัร-เราะฮะบียะฮ์) '
              '• พ.ร.บ.ว่าด้วยการใช้กฎหมายอิสลามในเขตจังหวัดปัตตานี นราธิวาส ยะลา และสตูล พ.ศ. 2489',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 3: case studies
  // ---------------------------------------------------------------------------
  Widget _buildCasesTab(AppThemeModel theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        FxFadeUp(
          child: _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('7 กรณีศึกษาในประวัติศาสตร์อิสลาม',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textColor)),
                const SizedBox(height: 6),
                Text(
                  'ทุกตัวเลขคำนวณด้วยสูตรเดียวกับเครื่องคำนวณ ตามหลักมัซฮับชาฟิอีย์ ใช้กองมรดกตัวอย่าง ${_money(_CaseStudy.estate)}',
                  style: TextStyle(fontSize: 12.5, height: 1.6, color: theme.textSecondaryColor),
                ),
                TextButton(
                  onPressed: () => _tabs.animateTo(0),
                  style: TextButton.styleFrom(minimumSize: const Size(44, 44), padding: EdgeInsets.zero, foregroundColor: _ink),
                  child: const Text('กรอกกรณีของคุณในเครื่องคำนวณ ›', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
        for (var i = 0; i < _caseStudies.length; i++) ...[
          const SizedBox(height: 14),
          FxFadeUp(index: i + 1, child: _buildCaseCard(i + 1, _caseStudies[i], theme, isDark)),
        ],
        const SizedBox(height: 20),
        Text('กรณีศึกษาเพิ่มเติม', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.textColor)),
        for (var i = 0; i < _moreCases.length; i++) ...[
          const SizedBox(height: 14),
          _buildCaseCard(_caseStudies.length + i + 1, _moreCases[i], theme, isDark),
        ],
      ],
    );
  }

  Widget _buildCaseCard(int n, _CaseStudy c, AppThemeModel theme, bool isDark) {
    final tables = c.tables();
    final rowStyle = TextStyle(fontSize: 12.5, color: theme.textColor);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: FaraidStyle.card(theme, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(10)),
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: Center(
                    child: Text('$n', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.textColor)),
                    const SizedBox(height: 2),
                    Text(c.ar,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _ink)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(c.situation, style: TextStyle(fontSize: 12.5, height: 1.6, color: theme.textColor)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final chip in c.chips)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: FaraidStyle.tint(theme, isDark ? 0.2 : 0.09),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    child: Text(chip, style: TextStyle(fontSize: 12, color: theme.textColor)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: FaraidStyle.tint(theme, isDark ? 0.14 : 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'หลักการ: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: c.ruling),
                ]),
                style: TextStyle(fontSize: 12.5, height: 1.6, color: theme.textColor),
              ),
            ),
          ),
          for (final t in tables) ...[
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(color: theme.scaffoldBackground, borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (t.title != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(t.title!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _ink)),
                      ),
                    for (final r in t.rows)
                      DecoratedBox(
                        decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.borderColor.withValues(alpha: 0.6)))),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 34),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(r.$1,
                                    style: r.$4 ? rowStyle.copyWith(color: theme.textSecondaryColor) : rowStyle),
                              ),
                              SizedBox(
                                width: 54,
                                child: Text(r.$2, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: _ink)),
                              ),
                              SizedBox(
                                width: 104,
                                child: Text(_money(r.$3),
                                    textAlign: TextAlign.right,
                                    style: rowStyle.copyWith(
                                        fontWeight: FontWeight.w600, color: r.$4 ? theme.textSecondaryColor : null)),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (c.note != null) ...[
            const SizedBox(height: 10),
            Text(c.note!(tables), style: TextStyle(fontSize: 12, height: 1.6, color: theme.textSecondaryColor)),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _loadCase(c),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('ลองคำนวณ', style: TextStyle(fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(44, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(AppThemeModel theme) => InputDecoration(
        filled: true,
        fillColor: theme.cardBackground,
        isDense: true,
        labelStyle: TextStyle(fontSize: 13, color: theme.textSecondaryColor),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.borderColor, width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.borderColor, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.primaryColor, width: 1.5)),
      );
}

// =============================================================================
// Widgets
// =============================================================================
/// Adds thousands separators while typing (1200000 -> 1,200,000); decimals are kept.
class _GroupedNumberFormatter extends TextInputFormatter {
  static String group(String raw) {
    raw = raw.replaceAll(',', '');
    final dot = raw.indexOf('.');
    final intPart = dot < 0 ? raw : raw.substring(0, dot);
    final rest = dot < 0 ? '' : raw.substring(dot);
    final b = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) b.write(',');
      b.write(intPart[i]);
    }
    return '$b$rest';
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final text = group(newValue.text);
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

class _MoneyField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? labelAccent;
  final Color? accent;
  final String hint;
  final AppThemeModel theme;
  final VoidCallback onChanged;
  final bool big;

  const _MoneyField({
    required this.controller,
    required this.label,
    this.labelAccent,
    this.accent,
    required this.hint,
    required this.theme,
    required this.onChanged,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.borderColor, width: 1.5));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(text: label),
            if (labelAccent != null) TextSpan(text: labelAccent, style: TextStyle(color: accent)),
          ]),
          style: TextStyle(fontSize: 12.5, color: theme.textSecondaryColor),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')), _GroupedNumberFormatter()],
          onChanged: (_) => onChanged(),
          style: TextStyle(
            fontSize: big ? 17 : 15,
            fontWeight: big ? FontWeight.w600 : FontWeight.w400,
            color: theme.textColor,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(color: theme.textSecondaryColor.withValues(alpha: 0.5), fontWeight: FontWeight.normal),
            filled: true,
            fillColor: theme.cardBackground,
            contentPadding: EdgeInsets.symmetric(horizontal: big ? 14 : 12, vertical: big ? 14 : 12),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(borderSide: BorderSide(color: theme.primaryColor, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

/// Heir counters grouped like the draft: spouse, ascendants, descendants, siblings (+ distant relatives on demand).
class _HeirEditor extends StatefulWidget {
  final bool deceasedMale;
  final Map<HeirType, int> heirs;
  final AppThemeModel theme;
  final bool isDark;
  final Map<HeirType, String> blocked;
  final void Function(HeirType type, int value) onChanged;

  const _HeirEditor({
    required this.deceasedMale,
    required this.heirs,
    required this.theme,
    required this.isDark,
    required this.onChanged,
    this.blocked = const {},
  });

  @override
  State<_HeirEditor> createState() => _HeirEditorState();
}

class _HeirEditorState extends State<_HeirEditor> {
  late bool _showMore = HeirType.values.any((t) => t.group == HeirGroup.distant && (widget.heirs[t] ?? 0) > 0);

  static const _groups = [
    (HeirGroup.spouse, 'คู่สมรส'),
    (HeirGroup.ascendant, 'บุพการี'),
    (HeirGroup.descendant, 'ลูกหลาน'),
    (HeirGroup.sibling, 'พี่น้อง'),
  ];

  List<HeirType> _types(HeirGroup g) => HeirType.values.where((t) {
        if (t.group != g) return false;
        if (t == HeirType.husband && widget.deceasedMale) return false;
        if (t == HeirType.wife && !widget.deceasedMale) return false;
        return true;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final ink = FaraidStyle.ink(widget.theme, widget.isDark);
    Widget group(String title, List<HeirType> types) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 2),
              child: Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: ink)),
            ),
            for (final t in types) _row(t),
          ],
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final g in _groups) group(g.$2, _types(g.$1)),
        if (_showMore) group('ญาติลำดับถัดไป (อะศอบะฮ์)', _types(HeirGroup.distant)),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _showMore = !_showMore),
            style: TextButton.styleFrom(minimumSize: const Size(44, 44), padding: EdgeInsets.zero, foregroundColor: ink),
            child: Text(
              _showMore ? 'ซ่อนญาติลำดับถัดไป' : 'แสดงญาติลำดับถัดไป (ลูกชายของพี่น้อง ลุง/อา …)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(HeirType t) {
    final theme = widget.theme;
    final isDark = widget.isDark;
    final ink = FaraidStyle.ink(theme, isDark);
    final v = widget.heirs[t] ?? 0;
    final status = widget.blocked[t];
    final disabled = isDark ? theme.borderColor : const Color(0xFFB9B3CF);
    Widget btn(IconData icon, bool enabled, VoidCallback onTap, String label, {bool filled = false}) => Semantics(
          button: true,
          label: label,
          child: Material(
            color: filled ? FaraidStyle.tint(theme, isDark ? 0.22 : 0.1) : theme.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: filled ? BorderSide.none : BorderSide(color: theme.borderColor, width: 1.5),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: enabled
                  ? () {
                      HapticFeedback.selectionClick();
                      onTap();
                    }
                  : null,
              child: SizedBox(width: 44, height: 44, child: Icon(icon, size: 20, color: enabled ? ink : disabled)),
            ),
          ),
        );
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.borderColor.withValues(alpha: 0.5)))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.th,
                    style: TextStyle(
                        fontSize: 14, fontWeight: v > 0 ? FontWeight.w600 : FontWeight.w400, color: theme.textColor)),
                if (status != null && v > 0)
                  Text('ถูกกันสิทธิ์: $status',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: FaraidStyle.warn(isDark))),
              ],
            ),
          ),
          btn(Icons.remove_rounded, v > 0, () => widget.onChanged(t, v - 1), 'ลดจำนวน'),
          SizedBox(
            width: 30,
            child: Text('$v',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.textColor)),
          ),
          btn(Icons.add_rounded, v < t.maxCount, () => widget.onChanged(t, v + 1), 'เพิ่มจำนวน', filled: true),
        ],
      ),
    );
  }
}

// =============================================================================
// Case studies
// =============================================================================
class _CaseLater {
  final HeirType heirType;
  final int heirIndex;
  final Map<HeirType, int> heirs;

  const _CaseLater(this.heirType, this.heirIndex, this.heirs);
}

class _CaseTogether {
  final String name;
  final bool male;
  final double ownAssets;
  final Map<HeirType, int> heirs;

  const _CaseTogether(this.name, this.male, this.ownAssets, this.heirs);
}

/// One result table on a case card: rows are (name, fraction, amount, muted).
class _CaseTable {
  final String? title;
  final List<(String, String, double, bool)> rows;

  const _CaseTable(this.title, this.rows);
}

class _CaseStudy {
  static const double estate = 1200000;

  final String title;
  final String ar;
  final String situation;
  final List<String> chips;
  final String ruling;
  final bool deceasedMale;
  final Map<HeirType, int> heirs;
  final List<_CaseLater> later;
  final int fetusMax; // > 0: an unborn child of the deceased
  final HeirType? missing; // one missing heir of this type
  final List<_CaseTogether> together;

  /// Second variant shown as its own table (label, deceased male, heirs).
  final (String, String, bool, Map<HeirType, int>)? variants;
  final String Function(List<_CaseTable>)? note;

  const _CaseStudy({
    required this.title,
    required this.ar,
    required this.situation,
    required this.chips,
    required this.ruling,
    this.deceasedMale = true,
    this.heirs = const {},
    this.later = const [],
    this.fetusMax = 0,
    this.missing,
    this.together = const [],
    this.variants,
    this.note,
  });

  static _CaseTable _table(String? title, FaraidResult r, double estate) => _CaseTable(title, [
        for (final s in r.shares)
          if (s.share.isPositive)
            (
              '${s.type.th}${s.count > 1 ? ' ${s.count} คน' : ''}',
              '${(s.share * Frac(r.tashih)).toDouble().round()}/${r.tashih}',
              s.share.toDouble() * estate,
              false,
            ),
        if (r.unallocated.isPositive) ('บัยตุลมาล / ซะวิลอัรฮาม', '${r.unallocated}', r.unallocated.toDouble() * estate, true),
      ]);

  /// Tables computed with the same engine as the calculator.
  List<_CaseTable> tables() {
    final root = FaraidInput(deceasedMale: deceasedMale, heirs: heirs);
    if (fetusMax > 0 || missing != null) {
      final u = FaraidEngine.calculateUncertain(root, [
        if (fetusMax > 0) FaraidEngine.fetusScenarios(HeirType.son, HeirType.daughter, fetusMax),
        if (missing != null) FaraidEngine.missingScenarios(missing!, 1),
      ]);
      return [
        _CaseTable(fetusMax > 0 ? 'ให้ก่อนคลอด' : 'ให้ก่อนทราบผล', [
          for (final e in u.known.entries)
            ('${e.key.th}${e.value > 1 ? ' ${e.value} คน' : ''}', '${u.paidNow(e.key)}', u.paidNow(e.key).toDouble() * estate, false),
          ('กันไว้ก่อน (มัวกูฟ)', '', u.reserved.toDouble() * estate, true),
        ]),
      ];
    }
    if (later.isNotEmpty || together.isNotEmpty) {
      final chain = FaraidEngine.calculateChain(
        estate: estate,
        root: root,
        laterDeaths: [
          for (final l in later) LaterDeath(fromStage: 0, heirType: l.heirType, heirIndex: l.heirIndex, heirs: l.heirs),
        ],
        simultaneous: [
          for (final t in together) SimultaneousDeath(label: t.name, isMale: t.male, heirs: t.heirs, ownAssets: t.ownAssets),
        ],
      );
      return [
        for (final s in chain.stages)
          _table(
            s.index == 0
                ? '${together.isNotEmpty ? 'มรดกของผู้ตายคนแรก' : 'ชั้นที่ 1: ผู้ตายคนแรก'} (${'฿${FormatUtils.formatCurrency(s.estate)}'})'
                : '${s.simultaneous ? 'มรดกของ' : 'ชั้นที่ ${s.index + 1}: '}${s.title} (฿${FormatUtils.formatCurrency(s.estate)})',
            s.result,
            s.estate,
          ),
      ];
    }
    final v = variants;
    return [
      _table(v?.$1, FaraidEngine.calculate(root), estate),
      if (v != null) _table(v.$2, FaraidEngine.calculate(FaraidInput(deceasedMale: v.$3, heirs: v.$4)), estate),
    ];
  }
}

const _caseStudies = [
  _CaseStudy(
    title: 'มรดกซ้อนมรดก (มุนาสะเคาะฮ์)',
    ar: 'المناسخات',
    situation:
        'ชายคนหนึ่งเสียชีวิต ทิ้งมรดก ฿1,200,000 ให้ภรรยา ลูกชาย 2 คน และลูกสาว 1 คน แต่ก่อนแบ่ง ลูกชายคนโตเสียชีวิตตามไป ทายาทของเขาคือ ภรรยาและลูกสาวของเขา แม่ (ภรรยาของผู้ตายคนแรก) พี่ชาย 1 และน้องสาว 1',
    chips: ['ภรรยา', 'ลูกชาย 2 (เสียชีวิต 1)', 'ลูกสาว 1'],
    ruling:
        'แบ่งมรดกชั้นแรกตามปกติ แล้วนำส่วนของทายาทที่เสียชีวิตไปแบ่งต่อให้ทายาทของเขาเองเป็นชั้นที่ 2 ทายาทที่อยู่ในทั้งสองชั้นจะได้รับทั้งสองส่วน',
    heirs: {HeirType.wife: 1, HeirType.son: 2, HeirType.daughter: 1},
    later: [
      _CaseLater(HeirType.son, 1, {
        HeirType.wife: 1,
        HeirType.daughter: 1,
        HeirType.mother: 1,
        HeirType.fullBrother: 1,
        HeirType.fullSister: 1,
      }),
    ],
  ),
  _CaseStudy(
    title: 'คดีท่านอุมัร (อัล-เฆาะรอวัยน์)',
    ar: 'الغرّاوان',
    situation: 'ผู้ตายไม่มีลูกหลานและพี่น้องไม่ถึง 2 คน มีทายาทเพียงคู่สมรส พ่อ และแม่',
    chips: ['คู่สมรส', 'พ่อ', 'แม่'],
    ruling:
        'ถ้าให้แม่ 1/3 ของกองมรดก แม่จะได้มากกว่าหรือเท่ากับพ่อ ท่านอุมัรจึงตัดสินให้แม่ได้ 1/3 ของส่วนที่เหลือหลังหักคู่สมรส เพื่อรักษาอัตราชาย 2 : หญิง 1 เศาะฮาบะฮ์ส่วนใหญ่และมัซฮับชาฟิอีย์ยึดตามนี้',
    heirs: {HeirType.wife: 1, HeirType.father: 1, HeirType.mother: 1},
    variants: (
      'แบบที่ 1: ผู้ตายเป็นชาย (ภรรยา พ่อ แม่)',
      'แบบที่ 2: ผู้ตายเป็นหญิง (สามี พ่อ แม่)',
      false,
      {HeirType.husband: 1, HeirType.father: 1, HeirType.mother: 1},
    ),
  ),
  _CaseStudy(
    title: 'คดีหินทิ้งทะเล (อัล-มุชตะเราะเกาะฮ์)',
    ar: 'المشتركة',
    situation:
        'หญิงคนหนึ่งเสียชีวิต ทิ้งสามี แม่ พี่น้องร่วมแม่ 2 คน และพี่น้องชายร่วมพ่อแม่ 2 คน ส่วนฟุรูฎรวมกันพอดีกองมรดก พี่น้องร่วมพ่อแม่ซึ่งเป็นอะศอบะฮ์จึงไม่เหลือส่วนเลย',
    chips: ['สามี', 'แม่', 'พี่น้องร่วมแม่ 2', 'พี่น้องชายร่วมพ่อแม่ 2'],
    ruling:
        'พี่น้องร่วมพ่อแม่กล่าวว่า "สมมติว่าพ่อของเราเป็นหินที่ถูกโยนทิ้งทะเล เราก็ยังเป็นลูกของแม่คนเดียวกัน" ท่านอุมัรจึงให้ร่วมรับ 1/3 กับพี่น้องร่วมแม่ ทุกคนได้เท่ากันไม่ว่าชายหรือหญิง มัซฮับชาฟิอีย์ยึดตามนี้',
    deceasedMale: false,
    heirs: {HeirType.husband: 1, HeirType.mother: 1, HeirType.maternalBrother: 2, HeirType.fullBrother: 2},
    note: _siblingsEachNote,
  ),
  _CaseStudy(
    title: 'คดีปู่ร่วมกับพี่สาวแท้ (อัล-อักดะรียะฮ์)',
    ar: 'الأكدرية',
    situation: 'หญิงคนหนึ่งเสียชีวิต ทิ้งสามี แม่ ปู่ และพี่น้องสาวร่วมพ่อแม่ 1 คน',
    chips: ['สามี', 'แม่', 'ปู่', 'พี่น้องสาวร่วมพ่อแม่ 1'],
    ruling:
        'สามี 1/2 แม่ 1/3 ปู่ 1/6 เหลือ 0 ตามปกติพี่น้องหญิงจะไม่ได้อะไร แต่กรณีนี้ให้เธอ 1/2 แล้วเอาล์ฐาน 6 เป็น 9 จากนั้นนำส่วนของปู่ (1) กับพี่น้องหญิง (3) มารวมกันเป็น 4 แบ่งใหม่แบบชาย 2 : หญิง 1 จึงปรับฐานเป็น 27',
    deceasedMale: false,
    heirs: {HeirType.husband: 1, HeirType.mother: 1, HeirType.grandfather: 1, HeirType.fullSister: 1},
  ),
  _CaseStudy(
    title: 'ทายาทเป็นทารกในครรภ์ (อัล-ฮัมล์)',
    ar: 'الحمل',
    situation: 'ชายคนหนึ่งเสียชีวิต ภรรยากำลังตั้งครรภ์ ทายาทที่มีชีวิตคือ ภรรยา พ่อ และแม่',
    chips: ['ภรรยา (ตั้งครรภ์)', 'พ่อ', 'แม่', 'ทารกในครรภ์'],
    ruling:
        'ทารกในครรภ์มีสิทธิ์รับมรดกถ้าคลอดออกมามีชีวิต จึงคำนวณทุกสถานการณ์ (ไม่มีทารก ชาย หญิง แฝด) แล้วให้ทายาทแต่ละคนรับส่วนที่น้อยที่สุดก่อน กันส่วนที่เหลือไว้จนคลอด แล้วจึงแบ่งตามผลจริง',
    heirs: {HeirType.wife: 1, HeirType.father: 1, HeirType.mother: 1},
    fetusMax: 2,
  ),
  _CaseStudy(
    title: 'เสียชีวิตพร้อมกันในอุบัติเหตุ (อัล-ฆอร็อก)',
    ar: 'الغرقى والهدمى',
    situation:
        'ชายคนหนึ่งกับลูกชายคนเดียวของเขาเสียชีวิตในอุบัติเหตุเดียวกัน ไม่ทราบว่าใครเสียชีวิตก่อน ฝ่ายพ่อมีทรัพย์ ฿1,200,000 ทิ้งภรรยา ลูกสาว และพี่ชาย ส่วนลูกชายมีทรัพย์ของตนเอง ฿300,000 ทิ้งภรรยา แม่ และพี่สาว',
    chips: ['ภรรยา', 'ลูกสาว', 'พี่ชาย', '(ลูกชายเสียชีวิตพร้อมกัน)'],
    ruling:
        'มัซฮับชาฟิอีย์ถือว่าผู้ที่เสียชีวิตพร้อมกันโดยไม่ทราบลำดับ ไม่รับมรดกกันและกัน มรดกของแต่ละคนแบ่งให้ทายาทที่ยังมีชีวิตของคนนั้นเท่านั้น',
    heirs: {HeirType.wife: 1, HeirType.daughter: 1, HeirType.fullBrother: 1},
    together: [
      _CaseTogether('ลูกชาย', true, 300000, {HeirType.wife: 1, HeirType.mother: 1, HeirType.fullSister: 1}),
    ],
  ),
  _CaseStudy(
    title: 'ทายาทสูญหาย (อัล-มัฟกูด)',
    ar: 'المفقود',
    situation:
        'ชายคนหนึ่งเสียชีวิต ทิ้งภรรยา ลูกชาย 2 คน และลูกสาว 1 คน แต่ลูกชายคนหนึ่งหายสาบสูญจากภัยพิบัติ ยังไม่ทราบว่ามีชีวิตหรือไม่',
    chips: ['ภรรยา', 'ลูกชาย 1 + หายสาบสูญ 1', 'ลูกสาว 1'],
    ruling:
        'คำนวณทั้งกรณีที่ผู้สูญหายยังมีชีวิตและเสียชีวิตแล้ว ให้ทายาทรับส่วนที่น้อยกว่าก่อน กันส่วนที่เหลือไว้จนผู้สูญหายกลับมา หรือศาลตัดสินว่าเสียชีวิต (หลังพ้นระยะเวลาที่คนรุ่นเดียวกันไม่น่าจะมีชีวิตอยู่)',
    heirs: {HeirType.wife: 1, HeirType.son: 1, HeirType.daughter: 1},
    missing: HeirType.son,
    note: _reservedNote,
  ),
];

String _siblingsEachNote(List<_CaseTable> t) {
  final r = FaraidEngine.calculate(const FaraidInput(
    deceasedMale: false,
    heirs: {HeirType.husband: 1, HeirType.mother: 1, HeirType.maternalBrother: 2, HeirType.fullBrother: 2},
  ));
  final s = r.shareOf(HeirType.maternalBrother);
  if (s == null) return '';
  return 'พี่น้องทั้ง 4 คนได้คนละ ฿${FormatUtils.formatCurrency(s.perPerson.toDouble() * _CaseStudy.estate)}';
}

String _reservedNote(List<_CaseTable> t) {
  final reserved = t.first.rows.last.$3;
  return 'ถ้าผู้สูญหายกลับมา เขารับส่วนที่กันไว้ ฿${FormatUtils.formatCurrency(reserved)} ถ้าศาลตัดสินว่าเสียชีวิต ส่วนนี้แบ่งคืนให้ทายาทที่เหลือ';
}

const _moreCases = [
  _CaseStudy(
    title: 'ส่วนแบ่งเกิน 100% (คดีบนมิมบัร)',
    ar: 'المنبرية — العول',
    situation: 'ผู้ตายเหลือภรรยา ลูกสาว 2 คน พ่อ และแม่ ส่วนแบ่งตายตัวรวมกันได้ 27/24 เกินกองมรดก',
    chips: ['ภรรยา', 'ลูกสาว 2', 'พ่อ', 'แม่'],
    ruling: 'ท่านอะลีตอบบนมิมบัรว่า "ส่วน 1/8 ของภรรยากลายเป็น 1/9" คือเพิ่มฐานจาก 24 เป็น 27 ทุกคนลดลงตามสัดส่วน',
    heirs: {HeirType.wife: 1, HeirType.daughter: 2, HeirType.father: 1, HeirType.mother: 1},
  ),
  _CaseStudy(
    title: 'เงินเหลือแต่ไม่มีผู้รับส่วนที่เหลือ (อัร-ร็อดด์)',
    ar: 'الرد',
    situation: 'ผู้ตาย (หญิง) เหลือสามี แม่ และลูกสาว 1 คน แบ่งตามส่วนตายตัวแล้วยังเหลือเงิน',
    chips: ['สามี', 'แม่', 'ลูกสาว 1'],
    ruling: 'สามีได้ 1/4 ตายตัว ที่เหลือเฉลี่ยคืนให้แม่และลูกสาวตามสัดส่วน 1 : 3 (คู่สมรสไม่ได้รับร็อดด์)',
    deceasedMale: false,
    heirs: {HeirType.husband: 1, HeirType.mother: 1, HeirType.daughter: 1},
  ),
  _CaseStudy(
    title: 'ปู่แบ่งกับพี่น้อง (อัล-มุอาดดะฮ์)',
    ar: 'الجد والإخوة — المعادّة',
    situation: 'ผู้ตายเหลือแม่ ปู่ พี่น้องสาวร่วมพ่อแม่ 1 คน และพี่น้องชายร่วมพ่อ 1 คน',
    chips: ['แม่', 'ปู่', 'พี่น้องสาวร่วมพ่อแม่ 1', 'พี่น้องชายร่วมพ่อ 1'],
    ruling:
        'ปู่เลือกทางที่ได้มากที่สุดระหว่างแบ่งเหมือนพี่น้อง, 1/3 ของที่เหลือ หรือ 1/6 จากนั้นพี่น้องร่วมพ่อที่ถูกนับรวมไว้ต้องคืนส่วนให้พี่สาวร่วมพ่อแม่จนครบ 1/2',
    heirs: {HeirType.mother: 1, HeirType.grandfather: 1, HeirType.fullSister: 1, HeirType.paternalBrother: 1},
  ),
];
