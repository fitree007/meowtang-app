import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/faraid_engine.dart';
import '../state/expense_controller.dart';
import '../theme/app_theme_model.dart';
import '../theme/meow_theme.dart';
import '../utils/format_utils.dart';
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

class IslamicInheritanceScreen extends StatefulWidget {
  final ExpenseController controller;

  const IslamicInheritanceScreen({super.key, required this.controller});

  @override
  State<IslamicInheritanceScreen> createState() => _IslamicInheritanceScreenState();
}

class _IslamicInheritanceScreenState extends State<IslamicInheritanceScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  final TextEditingController _grossCtrl = TextEditingController();
  bool _detailedAssets = false;
  static const _assetTypes = [
    ('land', '🏞️ ที่ดิน / สวน / ไร่นา'),
    ('house', '🏠 บ้าน / อาคาร / ห้องชุด'),
    ('deposit', '🏦 เงินฝาก / เงินสด'),
    ('car', '🚗 รถยนต์ / รถกระบะ'),
    ('motorcycle', '🛵 รถจักรยานยนต์'),
    ('gold', '💎 ทอง / เครื่องประดับ'),
    ('investment', '📈 หุ้น / กองทุน / สลาก'),
    ('business', '🏪 กิจการ / สินค้าในร้าน'),
    ('livestock', '🐄 วัว แพะ / ปศุสัตว์'),
    ('receivable', '🤝 เงินที่คนอื่นค้างผู้ตาย'),
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
      laterDeaths: _hasUncertain ? const [] : later,
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
          summary: FaraidEstateSummary(gross: _gross, funeral: _funeral, debts: _debts, wasiyyah: _wasiyyah, net: _net),
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
      _grossCtrl.text = netWorth > 0 ? netWorth.toStringAsFixed(0) : '0';
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
      _detailedAssets = false;
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
      _grossCtrl.text = '1200000';
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
          ..ownAssetsCtrl.text = t.ownAssets.toStringAsFixed(0);
        d.heirs.addAll(t.heirs);
        _together.add(d);
      }
    });
    _tabs.animateTo(0);
    _snack('ใส่ข้อมูลกรณี "${c.title}" แล้ว กด "ดูผลการแบ่งมรดก" ด้านล่างได้เลย');
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = widget.controller.currentTheme;
    final isDark = widget.controller.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text('แบ่งมรดกอิสลาม',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: theme.textColor)),
            Text('علم الفرائض', style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'ล้างข้อมูลทั้งหมด',
            icon: Icon(Icons.restart_alt_rounded, color: theme.textSecondaryColor),
            onPressed: _resetAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: theme.primaryColor,
          indicatorWeight: 3,
          labelColor: theme.primaryColor,
          unselectedLabelColor: theme.textSecondaryColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'คำนวณ'),
            Tab(text: 'กรณีศึกษา'),
            Tab(text: 'ความรู้'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildCalculatorTab(theme, isDark),
          _buildCasesTab(theme),
          _buildKnowledgeTab(theme),
        ],
      ),
    );
  }

  Widget _buildCalculatorTab(AppThemeModel theme, bool isDark) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              _StepCard(
                number: 1,
                title: 'ผู้เสียชีวิต',
                ar: 'المتوفى',
                subtitle: 'เลือกเพศของผู้ที่เสียชีวิต (เจ้าของมรดก)',
                theme: theme,
                child: Row(
                  children: [
                    Expanded(child: _genderTile(true, theme)),
                    const SizedBox(width: 10),
                    Expanded(child: _genderTile(false, theme)),
                  ],
                ),
              ),
              _StepCard(
                number: 2,
                title: 'ทรัพย์สินและหนี้สิน',
                ar: 'التركة',
                subtitle: 'ต้องหักค่าจัดการศพ หนี้ และพินัยกรรม ก่อนนำมาแบ่ง',
                theme: theme,
                child: _buildEstateInputs(theme),
              ),
              _StepCard(
                number: 3,
                title: 'ทายาทที่มีชีวิตอยู่ ณ วันที่เสียชีวิต',
                ar: 'الورثة',
                subtitle: 'แตะ + เพื่อเพิ่มจำนวน ใส่เฉพาะคนที่ยังมีชีวิตตอนเจ้าของมรดกเสียชีวิต',
                theme: theme,
                child: _HeirEditor(
                  deceasedMale: _deceasedMale,
                  heirs: _heirs,
                  theme: theme,
                  onChanged: (t, v) => setState(() => v == 0 ? _heirs.remove(t) : _heirs[t] = v),
                ),
              ),
              _StepCard(
                number: 4,
                title: 'มีทายาทที่ยังไม่แน่นอนไหม?',
                ar: 'الحمل والمفقود',
                subtitle: 'ทารกในครรภ์ที่จะเป็นทายาท หรือทายาทที่หายสาบสูญ — ระบบจะกันส่วนไว้ให้ถูกต้อง (ถ้าไม่มี ข้ามขั้นนี้ได้)',
                theme: theme,
                child: _buildUncertain(theme, isDark),
              ),
              _StepCard(
                number: 5,
                title: 'มีทายาทเสียชีวิตก่อนแบ่งมรดกไหม?',
                ar: 'المناسخات',
                subtitle:
                    'เช่น พ่อเสียชีวิต ยังไม่ได้แบ่ง แล้วลูกชายเสียชีวิตตามไป — ส่วนของลูกชายจะถูกแบ่งต่อให้ทายาทของลูกชาย (ถ้าไม่มี ข้ามขั้นนี้ได้)',
                theme: theme,
                child: _hasUncertain
                    ? Text(
                        '⏳ ระหว่างรอทารกคลอดหรือรอศาลตัดสินเรื่องผู้สูญหาย ยังแบ่งต่อเป็นทอด ๆ ไม่ได้ เพราะส่วนของแต่ละคนยังไม่แน่นอน — เมื่อทราบผลแล้วให้ปิดขั้นที่ 4 ใส่ทายาทตามจริง แล้วค่อยใส่ขั้นนี้',
                        style: TextStyle(fontSize: 12, height: 1.45, color: theme.textSecondaryColor),
                      )
                    : _buildLaterDeaths(theme, isDark),
              ),
              _StepCard(
                number: 6,
                title: 'มีคนเสียชีวิตพร้อมกันไหม?',
                ar: 'الغرقى والهدمى',
                subtitle: 'เช่น อุบัติเหตุ ไฟไหม้ จมน้ำ โดยไม่รู้ว่าใครเสียชีวิตก่อน — ไม่รับมรดกจากกัน ระบบจะแบ่งทรัพย์สินของแต่ละคนให้ทายาทของคนนั้นแยกกัน (ถ้าไม่มี ข้ามขั้นนี้ได้)',
                theme: theme,
                child: _buildTogether(theme, isDark),
              ),
            ],
          ),
        ),
        _buildBottomBar(theme),
      ],
    );
  }

  Widget _genderTile(bool male, AppThemeModel theme) {
    final sel = _deceasedMale == male;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _deceasedMale = male;
          _heirs.remove(male ? HeirType.husband : HeirType.wife);
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: sel ? theme.primaryColor.withValues(alpha: 0.12) : theme.surfaceBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: sel ? theme.primaryColor : theme.borderColor, width: sel ? 2 : 1),
        ),
        child: Column(
          children: [
            Text(male ? '👨' : '👩', style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(male ? 'ผู้ชาย' : 'ผู้หญิง',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: sel ? theme.primaryColor : theme.textColor)),
            Text(male ? 'ذكر' : 'أنثى', style: TextStyle(fontSize: 11.5, color: theme.textSecondaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildEstateInputs(AppThemeModel theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_detailedAssets)
          _MoneyField(
            controller: _grossCtrl,
            label: 'มูลค่าทรัพย์สินทั้งหมด',
            hint: 'เช่น 1,000,000',
            theme: theme,
            big: true,
            onChanged: () => setState(() {}),
          )
        else ...[
          for (var i = 0; i < _assetTypes.length; i += 2)
            _pairFields(
              _assetCtrls[_assetTypes[i].$1]!,
              _assetTypes[i].$2,
              _assetCtrls[_assetTypes[i + 1].$1]!,
              _assetTypes[i + 1].$2,
              theme,
            ),
          for (var i = 0; i < _customAssets.length; i++) _buildCustomAsset(i, theme),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _customAssets.add(_CustomAsset()));
              },
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: const Text(
                'เพิ่มทรัพย์สินอื่น (เช่น เรือ เครื่องจักร)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: theme.surfaceBackground, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'รวมทรัพย์สินทั้งหมด',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textColor),
                  ),
                ),
                Text(
                  _money(_itemisedTotal),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: theme.textColor),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ActionChip(
              avatar: Icon(_detailedAssets ? Icons.unfold_less_rounded : Icons.list_alt_rounded, size: 16),
              label: Text(_detailedAssets ? 'กรอกยอดรวมอย่างเดียว' : 'แยกตามประเภททรัพย์สิน',
                  style: const TextStyle(fontSize: 12)),
              onPressed: () => setState(() => _detailedAssets = !_detailedAssets),
            ),
            ActionChip(
              avatar: const Icon(Icons.download_rounded, size: 16),
              label: const Text('ดึงยอดเงินในแอพ', style: TextStyle(fontSize: 12)),
              onPressed: _importAppBalance,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('หักก่อนแบ่งมรดก (ตามลำดับ)',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: theme.textSecondaryColor)),
        const SizedBox(height: 8),
        _pairFields(_funeralCtrl, '⚰️ ค่าจัดการศพ (التجهيز)', _debtsCtrl, '💳 หนี้สิน (الدين)', theme),
        _MoneyField(
          controller: _wasiyyahCtrl,
          label: '📜 พินัยกรรม (الوصية) ให้คนที่ไม่ใช่ทายาท',
          hint: 'ไม่เกิน ${_money(_maxWasiyyah)}',
          theme: theme,
          onChanged: () => setState(() {}),
        ),
        if (_wasiyyahOver)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '⚠️ พินัยกรรมทำได้ไม่เกิน 1/3 ของทรัพย์หลังหักหนี้ ระบบจะใช้ ${_money(_maxWasiyyah)} (ส่วนเกินต้องได้รับความยินยอมจากทายาท)',
              style: const TextStyle(fontSize: 11.5, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
            ),
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF059669), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('มรดกสุทธิที่นำมาแบ่ง',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textColor)),
              ),
              Text(_money(_net),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF059669))),
            ],
          ),
        ),
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
        children: [
          Expanded(child: _MoneyField(controller: a, label: la, hint: '0', theme: theme, onChanged: () => setState(() {}))),
          const SizedBox(width: 10),
          Expanded(child: _MoneyField(controller: b, label: lb, hint: '0', theme: theme, onChanged: () => setState(() {}))),
        ],
      ),
    );
  }

  Widget _buildCustomAsset(int i, AppThemeModel theme) {
    final a = _customAssets[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📦 ชื่อทรัพย์สิน',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textSecondaryColor),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: a.nameCtrl,
                  style: TextStyle(fontSize: 14, color: theme.textColor),
                  decoration: _inputDecoration(theme).copyWith(hintText: 'เช่น เรือประมง'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MoneyField(
              controller: a.valueCtrl,
              label: 'มูลค่า',
              hint: '0',
              theme: theme,
              onChanged: () => setState(() {}),
            ),
          ),
          IconButton(
            tooltip: 'ลบรายการ',
            icon: const Icon(Icons.close_rounded, color: Color(0xFFEF4444)),
            onPressed: () => setState(() => _customAssets.removeAt(i).dispose()),
          ),
        ],
      ),
    );
  }

  Widget _buildUncertain(AppThemeModel theme, bool isDark) {
    final rel = _fetusRelations[_fetusRelation];
    Widget toggle(String title, String ar, IconData icon, Color color, bool value, ValueChanged<bool> onChanged) {
      return Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: theme.textColor),
                ),
                Text(
                  ar,
                  style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: theme.primaryColor,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => onChanged(v));
            },
          ),
        ],
      );
    }

    Widget stepper(String label, int value, int min, int max, ValueChanged<int> onChanged) {
      return Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 12.5, color: theme.textColor)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_circle_outline_rounded),
            color: theme.primaryColor,
            onPressed: value > min ? () => setState(() => onChanged(value - 1)) : null,
          ),
          Text(
            '$value',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.textColor),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: theme.primaryColor,
            onPressed: value < max ? () => setState(() => onChanged(value + 1)) : null,
          ),
        ],
      );
    }

    Widget panel(Color color, List<Widget> children) => Container(
      margin: const EdgeInsets.only(top: 6, bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );

    const pink = Color(0xFFEC4899);
    const slate = Color(0xFF64748B);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        toggle(
          'มีทารกในครรภ์ที่จะเป็นทายาท',
          'ميراث الحمل',
          Icons.pregnant_woman_rounded,
          pink,
          _fetusOn,
          (v) => _fetusOn = v,
        ),
        if (_fetusOn)
          panel(pink, [
            Text(
              'ทารกจะเป็นอะไรกับผู้ตาย?',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: theme.textSecondaryColor),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<int>(
              initialValue: _fetusRelation,
              isExpanded: true,
              decoration: _inputDecoration(theme),
              items: [
                for (var i = 0; i < _fetusRelations.length; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(
                      _fetusRelations[i].$1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _fetusRelation = v ?? 0),
            ),
            const SizedBox(height: 4),
            stepper('กันไว้สำหรับทารกได้สูงสุด (คน)', _fetusMax, 1, 4, (v) => _fetusMax = v),
            Text(
              'ระบบคิดทุกกรณี: เสียชีวิตก่อนคลอด, เป็น${rel.$2.th}, เป็น${rel.$3.th}, แฝด ฯลฯ แล้วให้ทายาทคนอื่นรับส่วนที่น้อยที่สุดไปก่อน '
              'ส่วนที่เหลือกันไว้จนคลอด (มัซฮับชาฟิอีย์ไม่กำหนดจำนวนทารกตายตัว ถ้าอาจเป็นแฝดมากกว่านี้ให้เพิ่มจำนวน) — ไม่ต้องนับทารกในขั้นที่ 3',
              style: TextStyle(fontSize: 11.5, height: 1.4, color: theme.textSecondaryColor),
            ),
          ]),
        toggle(
          'มีทายาทที่หายสาบสูญ',
          'ميراث المفقود',
          Icons.person_search_rounded,
          slate,
          _missingOn,
          (v) => _missingOn = v,
        ),
        if (_missingOn)
          panel(slate, [
            Text(
              'ผู้ที่สูญหายเป็นอะไรกับผู้ตาย?',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: theme.textSecondaryColor),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<HeirType>(
              key: ValueKey('missing_$_deceasedMale'),
              initialValue: _missingTypes.contains(_missingType) ? _missingType : HeirType.son,
              isExpanded: true,
              decoration: _inputDecoration(theme),
              items: [
                for (final t in _missingTypes)
                  DropdownMenuItem(
                    value: t,
                    child: Text(t.th, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                  ),
              ],
              onChanged: (v) => setState(() {
                _missingType = v ?? HeirType.son;
                _missingCount = _missingCount.clamp(1, _missingType.maxCount);
              }),
            ),
            if (_missingType.maxCount > 1)
              stepper('จำนวนที่สูญหาย (คน)', _missingCount, 1, 3, (v) => _missingCount = v),
            const SizedBox(height: 4),
            Text(
              'คิดทั้งกรณียังมีชีวิตและเสียชีวิตแล้ว ทายาทคนอื่นรับส่วนที่น้อยกว่าไปก่อน ส่วนที่เหลือกันไว้จนกว่าผู้สูญหายกลับมา หรือศาล/ดาโต๊ะยุติธรรมตัดสินว่าเสียชีวิต '
              '— ใส่เฉพาะทายาทที่อยู่จริงในขั้นที่ 3 ไม่ต้องนับคนที่สูญหาย',
              style: TextStyle(fontSize: 11.5, height: 1.4, color: theme.textSecondaryColor),
            ),
          ]),
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
          icon: const Icon(Icons.group_add_rounded, size: 18),
          label: Text(
            _together.isEmpty ? 'เพิ่มผู้ที่เสียชีวิตพร้อมกัน' : 'เพิ่มอีกคน',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '💡 ห้ามใส่ผู้ที่เสียชีวิตพร้อมกันเป็นทายาทในขั้นที่ 3 และห้ามใส่ผู้ตายคนแรกเป็นทายาทของเขา เพราะทั้งสองไม่รับมรดกจากกัน '
          '(ถ้ารู้แน่ว่าใครเสียชีวิตก่อน ให้ใช้ขั้นที่ 5 แทน)',
          style: TextStyle(fontSize: 11.5, height: 1.4, color: theme.textSecondaryColor),
        ),
      ],
    );
  }

  Widget _buildTogetherCard(int i, AppThemeModel theme, bool isDark) {
    final d = _together[i];
    const red = Color(0xFFEF4444);
    final name = d.nameCtrl.text.trim().isEmpty ? 'ผู้ตายคนนี้' : d.nameCtrl.text.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: red.withValues(alpha: isDark ? 0.12 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.car_crash_rounded, color: red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ผู้เสียชีวิตพร้อมกัน คนที่ ${i + 1}',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: theme.textColor),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'ลบ',
                icon: const Icon(Icons.delete_outline_rounded, color: red),
                onPressed: () => setState(() => _together.removeAt(i).dispose()),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: d.nameCtrl,
            onChanged: (_) => setState(() {}),
            style: TextStyle(fontSize: 14, color: theme.textColor),
            decoration: _inputDecoration(theme).copyWith(labelText: 'เป็นใคร (เช่น ลูกชาย, ภรรยา)'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final male in [true, false]) ...[
                ChoiceChip(
                  label: Text(male ? '👨 ผู้ชาย' : '👩 ผู้หญิง'),
                  selected: d.male == male,
                  onSelected: (_) => setState(() {
                    d.male = male;
                    d.heirs.remove(male ? HeirType.husband : HeirType.wife);
                  }),
                ),
                const SizedBox(width: 8),
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
          Text(
            'ทายาทของ$name ที่ยังมีชีวิตอยู่',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textColor),
          ),
          const SizedBox(height: 6),
          _HeirEditor(
            deceasedMale: d.male,
            heirs: d.heirs,
            theme: theme,
            compact: true,
            onChanged: (t, v) => setState(() => v == 0 ? d.heirs.remove(t) : d.heirs[t] = v),
          ),
        ],
      ),
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
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
          label: Text(_later.isEmpty ? 'เพิ่มทายาทที่เสียชีวิตตามมา' : 'เพิ่มอีกคน',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '💡 ถ้าเสียชีวิตพร้อมกันและไม่รู้ว่าใครเสียก่อน (เช่น อุบัติเหตุ) จะไม่รับมรดกจากกัน — ใช้ขั้นที่ 6 แทน',
          style: TextStyle(fontSize: 11.5, height: 1.4, color: theme.textSecondaryColor),
        ),
      ],
    );
  }

  Widget _buildLaterDeathCard(int i, AppThemeModel theme, bool isDark) {
    final d = _later[i];
    final options = _optionsFor(i);
    final selectedKey = d.heirType == null ? null : '${d.fromDraft}|${d.heirType!.name}|${d.heirIndex}';
    final hasSelected = options.any((o) => o.key == selectedKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('ขั้นที่ ${i + 2}',
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('ผู้เสียชีวิตตามมา',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: theme.textColor)),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'ลบ',
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                onPressed: () => setState(() {
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
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('ใครเสียชีวิต?',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: theme.textSecondaryColor)),
          const SizedBox(height: 4),
          if (options.isEmpty && !hasSelected)
            Text('ยังไม่มีทายาทที่ได้รับมรดก — เลือกทายาทในขั้นที่ 3 ก่อน',
                style: TextStyle(fontSize: 12, color: theme.textSecondaryColor))
          else
            DropdownButtonFormField<String>(
              key: ValueKey('later_${i}_${options.length}'),
              initialValue: hasSelected ? selectedKey : null,
              isExpanded: true,
              hint: const Text('แตะเพื่อเลือกทายาท'),
              decoration: _inputDecoration(theme),
              items: [
                for (final o in options)
                  DropdownMenuItem(
                    value: o.key,
                    child: Text(o.label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
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
              style: TextStyle(fontSize: 11.5, height: 1.35, color: theme.textSecondaryColor),
            ),
            const SizedBox(height: 6),
            _HeirEditor(
              deceasedMale: d.heirType!.isMale,
              heirs: d.heirs,
              theme: theme,
              compact: true,
              onChanged: (t, v) => setState(() => v == 0 ? d.heirs.remove(t) : d.heirs[t] = v),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(AppThemeModel theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(top: BorderSide(color: theme.borderColor)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('มรดกสุทธิ', style: TextStyle(fontSize: 11.5, color: theme.textSecondaryColor)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _money(_net),
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: theme.textColor),
                  ),
                ),
                Text(
                  'ทายาท $_heirTotal คน${_later.isNotEmpty && !_hasUncertain ? ' • ${_later.length} ขั้นต่อ' : ''}'
                  '${_hasUncertain ? ' • มีส่วนที่กันไว้' : ''}${_together.isNotEmpty ? ' • พร้อมกัน ${_together.length}' : ''}',
                  style: TextStyle(fontSize: 11, color: theme.textSecondaryColor),
                ),
                Text('ทายาท $_heirTotal คน${_later.isNotEmpty ? ' • ${_later.length} ขั้นต่อ' : ''}',
                    style: TextStyle(fontSize: 11, color: theme.textSecondaryColor)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _openResult,
            icon: const Icon(Icons.calculate_rounded),
            label: const Text('ดูผลการแบ่งมรดก', style: TextStyle(fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2: case studies
  // ---------------------------------------------------------------------------
  Widget _buildCasesTab(AppThemeModel theme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
      children: [
        Text('แตะ "ลองคำนวณ" เพื่อใส่ข้อมูลกรณีนั้นลงในหน้าคำนวณอัตโนมัติ',
            style: TextStyle(fontSize: 12.5, color: theme.textSecondaryColor)),
        const SizedBox(height: 12),
        for (final c in _caseStudies) _buildCaseCard(c, theme),
        const SizedBox(height: 6),
        Text(
          'กรณีพิเศษ: ทายาทไม่แน่นอน / เสียชีวิตพร้อมกัน',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.textColor),
        ),
        const SizedBox(height: 10),
        for (final c in _infoCases) _buildCaseCard(c, theme),
      ],
    );
  }

  Widget _buildCaseCard(_CaseStudy c, AppThemeModel theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: c.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                child: Icon(c.icon, color: c.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textColor)),
                    Text(c.ar, style: TextStyle(fontSize: 12, color: c.color, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('สถานการณ์', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textColor)),
          const SizedBox(height: 2),
          Text(c.situation, style: TextStyle(fontSize: 12.5, height: 1.45, color: theme.textSecondaryColor)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: c.color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
            child: Text(c.ruling, style: TextStyle(fontSize: 12.5, height: 1.45, color: theme.textColor)),
          ),
          ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _loadCase(c),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('ลองคำนวณ', style: TextStyle(fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: c.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 3: knowledge
  // ---------------------------------------------------------------------------
  Widget _buildKnowledgeTab(AppThemeModel theme) {
    Widget card(String title, String ar, IconData icon, Color color, List<(String, String)> items) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: theme.textColor)),
                ),
                Text(ar, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            for (final it in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(it.$1, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textColor)),
                    const SizedBox(height: 2),
                    Text(it.$2, style: TextStyle(fontSize: 12, height: 1.45, color: theme.textSecondaryColor)),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
      children: [
        card('สิ่งที่ต้องทำก่อนแบ่งมรดก', 'الحقوق المتعلقة بالتركة', Icons.format_list_numbered_rounded,
            const Color(0xFF10B981), const [
          ('1. ค่าจัดการศพ — التجهيز (ตัจญ์ฮีซ)', 'อาบน้ำ ห่อกะฝั่น ฝังศพ อย่างพอประมาณ ไม่ฟุ่มเฟือย'),
          ('2. ชำระหนี้ — الدين (อัด-ดัยน์)', 'หนี้ต่อมนุษย์ และหนี้ต่ออัลลอฮ์ เช่น ซากาตที่ค้าง'),
          ('3. พินัยกรรม — الوصية (อัล-วะศียะฮ์)', 'ไม่เกิน 1/3 และห้ามทำให้ทายาทที่มีสิทธิ์รับมรดกอยู่แล้ว'),
          ('4. แบ่งมรดก — قسمة التركة', 'ส่วนที่เหลือแบ่งให้ทายาทตามหลักฟะรออิฎ'),
        ]),
        card('ประเภทของทายาท', 'أنواع الورثة', Icons.people_alt_rounded, const Color(0xFF3B82F6), const [
          ('อัศหาบุลฟุรูฎ — أصحاب الفروض', 'ผู้มีส่วนแบ่งตายตัวในอัลกุรอาน เช่น คู่สมรส พ่อ แม่ ลูกสาว'),
          ('อะศอบะฮ์ — العصبة', 'ผู้รับส่วนที่เหลือ เช่น ลูกชาย พี่น้องชาย ลุง'),
          ('ซะวิลอัรฮาม — ذوو الأرحام', 'ญาติที่ไม่มีส่วนตายตัวและไม่ใช่อะศอบะฮ์ เช่น ลูกของลูกสาว ได้รับเมื่อไม่มีสองกลุ่มแรก'),
        ]),
        card('ส่วนแบ่งตายตัว 6 อัตรา', 'الفروض المقدرة', Icons.pie_chart_rounded, const Color(0xFFF59E0B), const [
          ('1/2 — النصف', 'สามี (ไม่มีลูก), ลูกสาวคนเดียว, หลานสาวคนเดียว, พี่น้องสาวคนเดียว'),
          ('1/4 — الربع', 'สามี (มีลูก), ภรรยา (ไม่มีลูก)'),
          ('1/8 — الثمن', 'ภรรยา (มีลูก)'),
          ('2/3 — الثلثان', 'ลูกสาว/หลานสาว/พี่น้องสาว ตั้งแต่ 2 คน'),
          ('1/3 — الثلث', 'แม่ (ไม่มีลูก และพี่น้องไม่ถึง 2 คน), พี่น้องร่วมแม่ตั้งแต่ 2 คน'),
          ('1/6 — السدس', 'พ่อ/แม่ (มีลูก), ปู่, ย่า/ยาย, พี่น้องร่วมแม่คนเดียว, หลานสาว/พี่น้องสาวร่วมพ่อ (เติมให้ครบ 2/3)'),
        ]),
        card('คำศัพท์ที่ใช้ในผลการคำนวณ', 'المصطلحات', Icons.translate_rounded, const Color(0xFF8B5CF6), const [
          ('อัล-หัจญ์บ — الحجب', 'การกันสิทธิ์ ทายาทที่ใกล้ชิดกว่าทำให้คนที่ห่างกว่าไม่ได้รับ (คนที่ถูกกันเรียกว่า มะห์ญูบ محجوب)'),
          ('อัศลุลมัสอะละฮ์ — أصل المسألة', 'ฐานของโจทย์ คือจำนวนส่วนที่ตั้งกองมรดกไว้ก่อนแบ่ง'),
          ('อัล-เอาล์ — العول', 'เมื่อส่วนแบ่งตายตัวรวมกันเกิน 100% ให้เพิ่มฐาน ทุกคนลดลงตามสัดส่วน'),
          ('อัร-ร็อด — الرد', 'เมื่อแบ่งแล้วยังเหลือและไม่มีอะศอบะฮ์ ให้เฉลี่ยคืนแก่ทายาทฟัรฎ์ (ยกเว้นคู่สมรส)'),
          ('อัต-ตัศฮีห์ — التصحيح', 'ปรับฐานให้ทุกคนได้จำนวนส่วนเป็นจำนวนเต็ม'),
          ('อัล-มุนาสะคาต — المناسخات', 'ทายาทเสียชีวิตก่อนแบ่งมรดก ต้องแบ่งต่อเป็นทอด ๆ'),
          ('อัล-มุกอซะมะฮ์ — المقاسمة', 'ปู่แบ่งร่วมกับพี่น้องเหมือนเป็นพี่น้องชายอีกคน'),
        ]),
        card('ผู้ที่ไม่มีสิทธิ์รับมรดก', 'موانع الإرث', Icons.gpp_bad_rounded, const Color(0xFFEF4444), const [
          ('ฆ่าเจ้าของมรดก — القتل', 'ผู้ที่ฆ่าเจ้าของมรดกโดยมิชอบ ไม่มีสิทธิ์รับมรดก'),
          ('ต่างศาสนา — اختلاف الدين', 'มุสลิมไม่รับมรดกจากผู้ไม่ใช่มุสลิม และกลับกัน'),
          ('เป็นทาส — الرق', 'ปัจจุบันไม่พบแล้ว'),
        ]),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.surfaceBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.borderColor),
          ),
          child: Text(
            'อ้างอิง: อัลกุรอาน ซูเราะฮ์อัน-นิสาอ์ 4:11, 4:12, 4:176 • ศอฮีหฺอัล-บุคอรีย์ และมุสลิม • ตำราฟะรออิฎมัซฮับชาฟิอีย์ (เช่น อัร-เราะฮะบียะฮ์) '
            '• พ.ร.บ.ว่าด้วยการใช้กฎหมายอิสลามในเขตจังหวัดปัตตานี นราธิวาส ยะลา และสตูล พ.ศ. 2489',
            style: TextStyle(fontSize: 12, height: 1.5, color: theme.textSecondaryColor),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(AppThemeModel theme) => InputDecoration(
        filled: true,
        fillColor: theme.cardBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.borderColor)),
        enabledBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.borderColor)),
      );
}

// =============================================================================
// Widgets
// =============================================================================
class _StepCard extends StatelessWidget {
  final int number;
  final String title;
  final String ar;
  final String subtitle;
  final AppThemeModel theme;
  final Widget child;

  const _StepCard({
    required this.number,
    required this.title,
    required this.ar,
    required this.subtitle,
    required this.theme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle),
                child: Text('$number',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.textColor)),
                        ),
                        Text(ar, style: TextStyle(fontSize: 13, color: theme.primaryColor, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, height: 1.4, color: theme.textSecondaryColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final AppThemeModel theme;
  final VoidCallback onChanged;
  final bool big;

  const _MoneyField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.theme,
    required this.onChanged,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textSecondaryColor)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          onChanged: (_) => onChanged(),
          style: TextStyle(fontSize: big ? 18 : 14, fontWeight: FontWeight.bold, color: theme.textColor),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: '฿ ',
            hintStyle: TextStyle(color: theme.textSecondaryColor.withValues(alpha: 0.5), fontWeight: FontWeight.normal),
            filled: true,
            fillColor: theme.surfaceBackground,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: big ? 14 : 11),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.borderColor)),
            enabledBorder:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.borderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.primaryColor, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

/// Heir counters grouped by family branch.
class _HeirEditor extends StatelessWidget {
  final bool deceasedMale;
  final Map<HeirType, int> heirs;
  final AppThemeModel theme;
  final void Function(HeirType type, int value) onChanged;
  final bool compact;

  const _HeirEditor({
    required this.deceasedMale,
    required this.heirs,
    required this.theme,
    required this.onChanged,
    this.compact = false,
  });

  static const _groups = [
    (HeirGroup.spouse, 'คู่สมรส', 'الزوجية', Icons.favorite_rounded, true),
    (HeirGroup.descendant, 'ลูกและหลาน', 'الفروع', Icons.child_care_rounded, true),
    (HeirGroup.ascendant, 'พ่อแม่ ปู่ ย่า ยาย', 'الأصول', Icons.elderly_rounded, true),
    (HeirGroup.sibling, 'พี่น้อง', 'الإخوة والأخوات', Icons.diversity_3_rounded, false),
    (HeirGroup.distant, 'ญาติผู้ชายสายพ่อ (หลาน ลุง อา)', 'العصبات', Icons.groups_2_rounded, false),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final g in _groups) _buildGroup(context, g.$1, g.$2, g.$3, g.$4, g.$5),
      ],
    );
  }

  Widget _buildGroup(BuildContext context, HeirGroup group, String title, String ar, IconData icon, bool openByDefault) {
    final types = HeirType.values.where((t) {
      if (t.group != group) return false;
      if (t == HeirType.husband && deceasedMale) return false;
      if (t == HeirType.wife && !deceasedMale) return false;
      return true;
    }).toList();
    final selected = types.fold<int>(0, (a, t) => a + (heirs[t] ?? 0));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.surfaceBackground,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected > 0 ? theme.primaryColor.withValues(alpha: 0.4) : theme.borderColor),
        ),
        child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: openByDefault || selected > 0,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
          leading: Icon(icon, color: theme.primaryColor, size: 20),
          title: Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: theme.textColor)),
          subtitle: Text(selected > 0 ? 'เลือกแล้ว $selected คน • $ar' : ar,
              style: TextStyle(fontSize: 11.5, color: selected > 0 ? theme.primaryColor : theme.textSecondaryColor)),
          children: [for (final t in types) _HeirCounter(type: t, value: heirs[t] ?? 0, theme: theme, onChanged: onChanged)],
        ),
        ),
      ),
    );
  }
}

class _HeirCounter extends StatelessWidget {
  final HeirType type;
  final int value;
  final AppThemeModel theme;
  final void Function(HeirType type, int value) onChanged;

  const _HeirCounter({required this.type, required this.value, required this.theme, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final single = type.maxCount == 1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.th,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: value > 0 ? FontWeight.bold : FontWeight.w500,
                        color: theme.textColor)),
                Text('${type.ar} • ${type.arLatin}', style: TextStyle(fontSize: 11, color: theme.textSecondaryColor)),
              ],
            ),
          ),
          if (single)
            Switch(
              value: value > 0,
              activeThumbColor: theme.primaryColor,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                onChanged(type, v ? 1 : 0);
              },
            )
          else
            Container(
              decoration: BoxDecoration(
                color: theme.cardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _roundBtn(Icons.remove_rounded, value > 0 ? () => onChanged(type, value - 1) : null),
                  SizedBox(
                    width: 30,
                    child: Text('$value',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: value > 0 ? theme.primaryColor : theme.textSecondaryColor)),
                  ),
                  _roundBtn(Icons.add_rounded, value < type.maxCount ? () => onChanged(type, value + 1) : null),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap();
            },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 20, color: onTap == null ? theme.borderColor : theme.primaryColor),
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

class _CaseStudy {
  final String title;
  final String ar;
  final String situation;
  final String ruling;
  final IconData icon;
  final Color color;
  final bool deceasedMale;
  final Map<HeirType, int> heirs;
  final List<_CaseLater> later;
  final int fetusMax; // > 0: an unborn child of the deceased
  final HeirType? missing; // one missing heir of this type
  final List<_CaseTogether> together;

  const _CaseStudy({
    required this.title,
    required this.ar,
    required this.situation,
    required this.ruling,
    required this.icon,
    required this.color,
    this.deceasedMale = true,
    this.heirs = const {},
    this.later = const [],
    this.fetusMax = 0,
    this.missing,
    this.together = const [],
  });
}

const _caseStudies = [
  _CaseStudy(
    title: 'มรดกซ้อนมรดก',
    ar: 'المناسخات',
    situation:
        'พ่อเสียชีวิต เหลือภรรยา ลูกชาย 2 คน ลูกสาว 1 คน ยังไม่ทันแบ่งมรดก ลูกชายคนโตก็เสียชีวิตตามไป ทิ้งภรรยาและลูกสาว 1 คน ไว้ (แม่และพี่น้องของเขายังมีชีวิต)',
    ruling:
        'แบ่งมรดกของพ่อก่อน แล้วนำส่วนของลูกชายคนโตไปแบ่งต่อให้ทายาทของเขาเอง (ภรรยา ลูกสาว แม่ พี่น้อง) ทายาทจึงไม่เสียสิทธิ์',
    icon: Icons.layers_rounded,
    color: Color(0xFF3B82F6),
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
    title: 'คดีท่านอุมัร (คู่สมรส + พ่อ + แม่)',
    ar: 'العمريتان',
    situation: 'ผู้ตายไม่มีลูก เหลือภรรยา พ่อ และแม่ ถ้าคิดตรง ๆ แม่จะได้ 1/3 ของทั้งหมด ซึ่งมากกว่าพ่อ',
    ruling: 'ท่านอุมัรตัดสินให้หักส่วนภรรยาก่อน แม่ได้ 1/3 ของที่เหลือ พ่อได้ที่เหลือ ทำให้พ่อได้เป็น 2 เท่าของแม่',
    icon: Icons.gavel_rounded,
    color: Color(0xFFF59E0B),
    heirs: {HeirType.wife: 1, HeirType.father: 1, HeirType.mother: 1},
  ),
  _CaseStudy(
    title: 'ส่วนแบ่งเกิน 100% (คดีบนมิมบัร)',
    ar: 'المنبرية — العول',
    situation: 'ผู้ตายเหลือภรรยา ลูกสาว 2 คน พ่อ และแม่ ส่วนแบ่งตายตัวรวมกันได้ 27/24 เกินกองมรดก',
    ruling: 'ท่านอะลีตอบบนมิมบัรว่า "ส่วน 1/8 ของภรรยากลายเป็น 1/9" คือเพิ่มฐานจาก 24 เป็น 27 ทุกคนลดลงตามสัดส่วน',
    icon: Icons.unfold_more_double_rounded,
    color: Color(0xFFEF4444),
    heirs: {HeirType.wife: 1, HeirType.daughter: 2, HeirType.father: 1, HeirType.mother: 1},
  ),
  _CaseStudy(
    title: 'เงินเหลือแต่ไม่มีผู้รับส่วนที่เหลือ',
    ar: 'الرد',
    situation: 'ผู้ตาย (หญิง) เหลือสามี แม่ และลูกสาว 1 คน แบ่งตามส่วนตายตัวแล้วยังเหลือเงิน',
    ruling: 'สามีได้ 1/4 ตายตัว ที่เหลือเฉลี่ยคืนให้แม่และลูกสาวตามสัดส่วน 1 : 3 (คู่สมรสไม่ได้รับร็อด)',
    icon: Icons.replay_circle_filled_rounded,
    color: Color(0xFF10B981),
    deceasedMale: false,
    heirs: {HeirType.husband: 1, HeirType.mother: 1, HeirType.daughter: 1},
  ),
  _CaseStudy(
    title: 'คดีหินโยนทะเล',
    ar: 'المشتركة — الحمارية',
    situation:
        'ผู้ตาย (หญิง) เหลือสามี แม่ พี่น้องร่วมแม่ 2 คน และพี่น้องชายร่วมพ่อแม่ 2 คน แบ่งแล้วเงินหมดพอดี พี่น้องร่วมพ่อแม่ไม่ได้อะไรเลย',
    ruling:
        'พี่น้องร่วมพ่อแม่ร้องว่า "ถือว่าพ่อเราเป็นหินที่โยนทะเลไปเถิด เราก็แม่เดียวกัน" ท่านอุมัรจึงให้ร่วมแบ่ง 1/3 กับพี่น้องร่วมแม่ รายหัวเท่ากัน (มัซฮับชาฟิอีย์ใช้ตามนี้)',
    icon: Icons.waves_rounded,
    color: Color(0xFF06B6D4),
    deceasedMale: false,
    heirs: {HeirType.husband: 1, HeirType.mother: 1, HeirType.maternalBrother: 2, HeirType.fullBrother: 2},
  ),
  _CaseStudy(
    title: 'ปู่กับพี่สาว',
    ar: 'الأكدرية',
    situation: 'ผู้ตาย (หญิง) เหลือสามี แม่ ปู่ และพี่น้องสาวร่วมพ่อแม่ 1 คน',
    ruling: 'ให้พี่สาวได้ 1/2 ปู่ได้ 1/6 (เอาล์เป็น 9) แล้วรวมส่วนของปู่กับพี่สาวแบ่งใหม่ ชาย 2 : หญิง 1 ได้ฐานสุดท้าย 27',
    icon: Icons.elderly_rounded,
    color: Color(0xFF8B5CF6),
    deceasedMale: false,
    heirs: {HeirType.husband: 1, HeirType.mother: 1, HeirType.grandfather: 1, HeirType.fullSister: 1},
  ),
  _CaseStudy(
    title: 'ปู่แบ่งกับพี่น้อง',
    ar: 'الجد والإخوة — المعادّة',
    situation: 'ผู้ตายเหลือแม่ ปู่ พี่น้องสาวร่วมพ่อแม่ 1 คน และพี่น้องชายร่วมพ่อ 1 คน',
    ruling:
        'ปู่เลือกทางที่ได้มากที่สุดระหว่างแบ่งเหมือนพี่น้อง, 1/3 ของที่เหลือ หรือ 1/6 จากนั้นพี่น้องร่วมพ่อที่ถูกนับรวมไว้ต้องคืนส่วนให้พี่สาวร่วมพ่อแม่จนครบ 1/2',
    icon: Icons.account_tree_rounded,
    color: Color(0xFF6366F1),
    heirs: {HeirType.mother: 1, HeirType.grandfather: 1, HeirType.fullSister: 1, HeirType.paternalBrother: 1},
  ),
];

const _infoCases = [
  _CaseStudy(
    title: 'ทายาทยังเป็นทารกในครรภ์',
    ar: 'ميراث الحمل',
    situation: 'เจ้าของมรดกเสียชีวิตขณะภรรยากำลังตั้งครรภ์ ยังไม่ทราบเพศหรือจำนวนเด็ก',
    ruling: 'คิดทุกกรณีที่เป็นไปได้ (เสียชีวิตก่อนคลอด, ชาย, หญิง, แฝด) ทายาทอื่นรับส่วนที่น้อยที่สุดในทุกกรณีไปก่อน ส่วนที่เหลือกันไว้ (الموقوف) เมื่อคลอดแล้วจึงแบ่งตามกรณีที่เกิดขึ้นจริง — ตัวอย่าง: ภรรยา พ่อ แม่ ภรรยาตั้งครรภ์',
    icon: Icons.pregnant_woman_rounded,
    color: Color(0xFFEC4899),
    heirs: {HeirType.wife: 1, HeirType.father: 1, HeirType.mother: 1},
    fetusMax: 2,
  ),
  _CaseStudy(
    title: 'เสียชีวิตพร้อมกัน',
    ar: 'الغرقى والهدمى',
    situation: 'คนในครอบครัวเสียชีวิตในอุบัติเหตุเดียวกัน โดยไม่รู้ว่าใครเสียชีวิตก่อน',
    ruling: 'ไม่รับมรดกจากกัน มรดกของแต่ละคนแบ่งให้เฉพาะทายาทที่ยังมีชีวิตของคนนั้น — ตัวอย่าง: พ่อกับลูกชายเสียชีวิตในอุบัติเหตุเดียวกัน พ่อเหลือภรรยา ลูกสาว และพี่ชาย ลูกชายเหลือภรรยา แม่ และพี่สาว',
    icon: Icons.car_crash_rounded,
    color: Color(0xFFEF4444),
    heirs: {HeirType.wife: 1, HeirType.daughter: 1, HeirType.fullBrother: 1},
    together: [
      _CaseTogether('ลูกชาย', true, 300000, {HeirType.wife: 1, HeirType.mother: 1, HeirType.fullSister: 1}),
    ],
  ),
  _CaseStudy(
    title: 'ทายาทสูญหาย',
    ar: 'ميراث المفقود',
    situation: 'ทายาทคนหนึ่งหายสาบสูญ ไม่ทราบว่ายังมีชีวิตหรือไม่',
    ruling: 'คิดทั้งกรณียังมีชีวิตและเสียชีวิต ทายาทอื่นรับส่วนที่น้อยกว่าไปก่อน กันส่วนที่เหลือไว้จนกว่าศาล/ดาโต๊ะยุติธรรมจะตัดสิน ถ้าตัดสินว่าเสียชีวิตแล้ว ให้นำส่วนนั้นกลับมาแบ่งให้ทายาทคนอื่น — ตัวอย่าง: ภรรยา ลูกชาย ลูกสาว และลูกชายอีกคนสูญหาย',
    icon: Icons.person_search_rounded,
    color: Color(0xFF64748B),
    heirs: {HeirType.wife: 1, HeirType.son: 1, HeirType.daughter: 1},
    missing: HeirType.son,
  ),
];
