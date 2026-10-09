import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/category_item.dart';
import '../services/category_matcher_service.dart';
import '../state/expense_controller.dart';
import '../widgets/meow_fx.dart';

class KeywordRulesScreen extends StatefulWidget {
 final ExpenseController controller;

 const KeywordRulesScreen({super.key, required this.controller});

 @override
 State<KeywordRulesScreen> createState() => _KeywordRulesScreenState();
}

class _KeywordRulesScreenState extends State<KeywordRulesScreen> {
 final List<KeywordRule> _userRules = [];
 final TextEditingController _searchCtrl = TextEditingController();
 final TextEditingController _testCtrl = TextEditingController();
 bool _showDefaults = false;
 int _defaultsShown = 6;

 @override
 void dispose() {
  _searchCtrl.dispose();
  _testCtrl.dispose();
  super.dispose();
 }

 /// Current category (rules store a copy of the name, which goes stale after a rename).
 CategoryItem? _cat(KeywordRule rule) {
  for (final c in widget.controller.categories) {
   if (c.id == rule.categoryId) return c;
  }
  for (final c in widget.controller.categories) {
   if (c.name == rule.categoryName) return c;
  }
  return null;
 }

 String _catName(KeywordRule rule) => _cat(rule)?.name ?? rule.categoryName;

 bool _matches(String keyword, String cat, [String? tag]) {
  final q = _searchCtrl.text.trim().toLowerCase();
  return q.isEmpty ||
    keyword.toLowerCase().contains(q) ||
    cat.toLowerCase().contains(q) ||
    (tag != null && '#${tag.toLowerCase()}'.contains(q));
 }

 void _deleteRule(KeywordRule rule) {
  final index = _userRules.indexOf(rule);
  setState(() {
   _userRules.removeAt(index);
   _saveCustomRules();
  });
  _calmToast(
   context,
   'ลบกฎ “${rule.keyword}” แล้ว',
   actionLabel: 'เลิกทำ',
   onAction: () {
    if (!mounted) return;
    setState(() {
     _userRules.insert(index.clamp(0, _userRules.length), rule);
     _saveCustomRules();
    });
   },
  );
 }

 @override
 void initState() {
  super.initState();
  _loadCustomRules();
 }

 void _loadCustomRules() {
  final rawRules = widget.controller.storage.getKeywordRules();
  setState(() {
   _userRules.clear();
   for (final r in rawRules) {
    _userRules.add(KeywordRule.fromJson(r));
   }
  });
 }

 void _saveCustomRules() {
  final list = _userRules.map((e) => e.toJson()).toList();
  widget.controller.storage.saveKeywordRules(list);
 }

 void _showAddKeywordDialog({KeywordRule? editing, String initialKeyword = ''}) {
  final c = _C.of(widget.controller);
  final keywordCtrl = TextEditingController(text: editing?.keyword ?? initialKeyword);
  final tagCtrl = TextEditingController(text: editing?.tag ?? '');
  final cats = widget.controller.categories;
  CategoryItem? selectedCat = cats.isNotEmpty ? cats.first : null;
  if (editing != null) {
   selectedCat = _cat(editing) ?? selectedCat;
  }
  var touched = false;

  _showCalmSheet<void>(
   context,
   c,
   title: editing == null ? 'เพิ่มคีย์เวิร์ด' : 'แก้ไขคีย์เวิร์ด',
   subtitle: 'ชื่อร้านหรือคำในบันทึกช่วยจำที่มีคำนี้ จะได้หมวดที่เลือก',
   builder: (ctx, setSheet) {
    final kw = keywordCtrl.text.trim();
    final duplicate = _userRules.any((r) => r != editing && r.keyword.toLowerCase() == kw.toLowerCase());
    final kwErr = (touched && kw.isEmpty) || duplicate;
    final canSave = kw.isNotEmpty && !duplicate && selectedCat != null;

    Widget catChip(CategoryItem cat) {
     final sel = selectedCat?.id == cat.id;
     return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
       borderRadius: BorderRadius.circular(12),
       onTap: () {
        HapticFeedback.selectionClick();
        setSheet(() => selectedCat = cat);
       },
       child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
         borderRadius: BorderRadius.circular(12),
         border: Border.all(color: sel ? c.accent : c.line, width: sel ? 1.5 : 1),
        ),
        child: Row(
         mainAxisSize: MainAxisSize.min,
         children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Flexible(
           child: Text(cat.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13.5, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? c.link : c.icon)),
          ),
         ],
        ),
       ),
      ),
     );
    }

    Widget group(String label, CategoryType type) => Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
        Text(label, style: TextStyle(fontSize: 12.5, color: c.sub)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final cat in cats.where((x) => x.type == type)) catChip(cat)]),
       ],
      );

    return Column(
     crossAxisAlignment: CrossAxisAlignment.stretch,
     children: [
      _fieldLabel(c, 'คีย์เวิร์ด'),
      TextField(
       controller: keywordCtrl,
       onChanged: (_) => setSheet(() => touched = true),
       style: TextStyle(color: c.text, fontSize: 15),
       decoration: _inputDeco(c, hint: 'เช่น 7-eleven, ชาตรามือ, Netflix', error: kwErr),
      ),
      if (kwErr)
       Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(duplicate ? 'มีคีย์เวิร์ดนี้อยู่แล้ว' : 'กรุณาใส่คีย์เวิร์ด', style: TextStyle(fontSize: 12.5, color: c.danger)),
       ),
      const SizedBox(height: 14),
      Text.rich(TextSpan(children: [
       TextSpan(text: 'หมวดหมู่', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text)),
       if (selectedCat != null)
        TextSpan(
         text: ' — เลือกแล้ว: ${selectedCat!.type == CategoryType.income ? 'รายรับ' : 'รายจ่าย'} › ${selectedCat!.name}',
         style: TextStyle(fontSize: 13, color: c.sub),
        ),
      ])),
      const SizedBox(height: 8),
      group('รายจ่าย', CategoryType.expense),
      const SizedBox(height: 10),
      group('รายรับ', CategoryType.income),
      const SizedBox(height: 14),
      _fieldLabel(c, '#แท็ก', hint: '(ไม่บังคับ)'),
      TextField(
       controller: tagCtrl,
       style: TextStyle(color: c.text, fontSize: 15),
       decoration: _inputDeco(c, prefix: '#  ', hint: 'เช่น ชานม, กาแฟเช้า'),
      ),
      const SizedBox(height: 18),
      _primaryButton(
       c,
       editing == null ? 'เพิ่มคีย์เวิร์ด' : 'บันทึกการแก้ไข',
       () {
        // Read the field now (not the last build) so a fast tap right after typing still saves.
        final kw = keywordCtrl.text.trim();
        final dup = _userRules.any((r) => r != editing && r.keyword.toLowerCase() == kw.toLowerCase());
        if (kw.isEmpty || dup || selectedCat == null) {
         setSheet(() => touched = true);
         return;
        }
        final tagRaw = tagCtrl.text.trim().replaceAll('#', '').replaceAll(RegExp(r'\s+'), '');
        final rule = KeywordRule(
         id: editing?.id ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
         keyword: kw,
         categoryName: selectedCat!.name,
         categoryId: selectedCat!.id,
         tag: tagRaw.isNotEmpty ? tagRaw : null,
        );
        setState(() {
         final i = editing == null ? -1 : _userRules.indexOf(editing);
         if (i >= 0) {
          _userRules[i] = rule;
         } else {
          _userRules.add(rule);
         }
         _saveCustomRules();
         _searchCtrl.clear();
        });
        Navigator.pop(ctx);
        _calmToast(context, '${editing == null ? 'เพิ่ม' : 'บันทึก'} “$kw” → ${selectedCat!.name} แล้ว');
       },
       color: canSave ? null : c.disabled,
      ),
      if (editing != null) ...[
       const SizedBox(height: 6),
       SizedBox(
        height: 48,
        child: TextButton.icon(
         onPressed: () {
          Navigator.pop(ctx);
          _deleteRule(editing);
         },
         icon: Icon(Icons.delete_outline_rounded, size: 20, color: c.danger),
         label: Text('ลบกฎนี้', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: c.danger)),
        ),
       ),
      ],
     ],
    );
   },
  );
 }

 @override
 Widget build(BuildContext context) {
  return ListenableBuilder(
   listenable: widget.controller,
   builder: (context, _) {
    final c = _C.of(widget.controller);
    final q = _searchCtrl.text.trim();
    final mine = _userRules.where((r) => _matches(r.keyword, _catName(r), r.tag)).toList();
    final defaults = CategoryMatcherService.defaultRules.where((r) => _matches(r.keyword, r.categoryName)).toList();
    final total = CategoryMatcherService.defaultRules.length;
    final defaultsOpen = q.isNotEmpty ? defaults.isNotEmpty : _showDefaults;
    final noResult = q.isNotEmpty && mine.isEmpty && defaults.isEmpty;
    var fx = 0;

    return Scaffold(
     backgroundColor: c.page,
     appBar: _calmAppBar(context, c, 'กฎคีย์เวิร์ดจัดหมวดอัตโนมัติ', subtitle: 'เจอชื่อร้านที่ตั้งไว้ แอปเลือกหมวดให้เอง'),
     bottomNavigationBar: _calmBottomBar(
      c,
      SizedBox(
       width: double.infinity,
       height: 52,
       // FilledButton (not ElevatedButton) so the sheet's own "เพิ่มคีย์เวิร์ด" button stays unique.
       child: FilledButton.icon(
        onPressed: () => _showAddKeywordDialog(),
        style: FilledButton.styleFrom(
         backgroundColor: c.accent,
         foregroundColor: Colors.white,
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('เพิ่มคีย์เวิร์ด', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
       ),
      ),
     ),
     body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
       // Explanation
       Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
          Icon(Icons.info_outline_rounded, size: 18, color: c.sub),
          const SizedBox(width: 10),
          Expanded(
           child: Text(
            'เมื่อระบบตรวจพบชื่อร้าน หรือบันทึกช่วยจำที่ตรงกับคีย์เวิร์ด จะเลือกหมวดหมู่นั้นให้อัตโนมัติทันที กฎของคุณจะถูกใช้ก่อนคีย์เวิร์ดมาตรฐาน',
            style: TextStyle(fontSize: 12.5, height: 1.5, color: c.sub),
           ),
          ),
         ],
        ),
       ),
       const SizedBox(height: 14),
       // Search
       TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() => _defaultsShown = 6),
        style: TextStyle(color: c.text, fontSize: 15),
        decoration: _inputDeco(
         c,
         hint: 'ค้นหาคีย์เวิร์ด หมวด หรือ #แท็ก',
         prefixIcon: Icon(Icons.search_rounded, size: 22, color: c.sub),
         suffixIcon: _searchCtrl.text.isEmpty
           ? null
           : IconButton(
            tooltip: 'ล้างคำค้นหา',
            icon: Icon(Icons.close_rounded, color: c.sub),
            onPressed: () => setState(() {
             _searchCtrl.clear();
             _defaultsShown = 6;
            }),
           ),
        ),
       ),
       const SizedBox(height: 14),
       // Try it
       FxFadeUp(index: fx++, child: _tester(c)),
       const SizedBox(height: 18),

       if (_userRules.isEmpty && q.isEmpty) ...[
        FxFadeUp(
         index: fx++,
         child: _calmCard(
          c,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
           children: [
            Text('ยังไม่มีคีย์เวิร์ดของคุณ', style: c.title),
            const SizedBox(height: 4),
            Text('ตัวอย่าง: “ชาตรามือ” → หมวดอาหาร • “PTT” → หมวดเดินทาง', textAlign: TextAlign.center, style: c.subtitle),
            const SizedBox(height: 12),
            _outlineButton(c, 'เพิ่มคีย์เวิร์ดแรก', () => _showAddKeywordDialog(), icon: Icons.add_rounded),
           ],
          ),
         ),
        ),
        const SizedBox(height: 18),
       ],

       // User rules
       if (_userRules.isNotEmpty && !noResult) ...[
        _sectionLabel(
         c,
         q.isEmpty ? 'คีย์เวิร์ดที่คุณกำหนดเอง (${_userRules.length})' : 'คีย์เวิร์ดที่คุณกำหนดเอง (พบ ${mine.length} จาก ${_userRules.length})',
         trailing: 'แตะเพื่อแก้ไข',
        ),
        FxFadeUp(
         index: fx++,
         child: _calmCard(
          c,
          child: mine.isEmpty
            ? Padding(padding: const EdgeInsets.all(16), child: Text('ไม่มีในกฎของคุณ แต่พบในคีย์เวิร์ดมาตรฐานด้านล่าง', style: c.subtitle))
            : Column(children: [for (var i = 0; i < mine.length; i++) _ruleRow(c, mine[i], i == 0)]),
         ),
        ),
        const SizedBox(height: 18),
       ],

       if (noResult)
        FxFadeUp(
         index: fx++,
         child: _calmCard(
          c,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
           children: [
            Icon(Icons.search_off_rounded, size: 30, color: c.sub),
            const SizedBox(height: 8),
            Text('ไม่พบ “$q”', style: c.title),
            Text('ทั้งในกฎของคุณและคีย์เวิร์ดมาตรฐาน', style: c.subtitle),
            const SizedBox(height: 12),
            _outlineButton(c, 'เพิ่ม “$q” เป็นคีย์เวิร์ด', () => _showAddKeywordDialog(initialKeyword: q), icon: Icons.add_rounded),
           ],
          ),
         ),
        )
       else ...[
        // Built-in default rules (collapsed unless searching)
        _sectionLabel(c, q.isEmpty ? 'คีย์เวิร์ดมาตรฐานในระบบ ($total)' : 'คีย์เวิร์ดมาตรฐานในระบบ (พบ ${defaults.length})'),
        FxFadeUp(
         index: fx++,
         child: _calmCard(
          c,
          child: Column(
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
            InkWell(
             onTap: () => setState(() {
              if (q.isNotEmpty && defaultsOpen) _searchCtrl.clear();
              _showDefaults = !defaultsOpen;
              _defaultsShown = 6;
             }),
             child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
               children: [
                Icon(Icons.lock_outline_rounded, size: 22, color: c.icon),
                const SizedBox(width: 16),
                Expanded(
                 child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                   Text(defaultsOpen ? 'ซ่อนรายการ' : 'แสดงคีย์เวิร์ดมาตรฐาน ${q.isEmpty ? total : defaults.length} รายการ', style: c.title),
                   Text('ค่าเริ่มต้นของแอป ใช้ได้ทันที แก้ไขไม่ได้', style: c.subtitle),
                  ],
                 ),
                ),
                AnimatedRotation(
                 turns: defaultsOpen ? 0.5 : 0,
                 duration: const Duration(milliseconds: 200),
                 child: Icon(Icons.keyboard_arrow_down_rounded, size: 24, color: c.sub),
                ),
               ],
              ),
             ),
            ),
            if (defaultsOpen) ...[
             for (final rule in defaults.take(_defaultsShown))
              Container(
               margin: const EdgeInsets.only(left: 54),
               padding: const EdgeInsets.fromLTRB(0, 11, 16, 11),
               decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
               child: Row(
                children: [
                 Expanded(
                  child: Text.rich(TextSpan(children: [
                   TextSpan(text: rule.keyword, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
                   TextSpan(text: '  → ${rule.categoryName}', style: TextStyle(fontSize: 13, color: c.sub)),
                  ])),
                 ),
                 _pill(c, 'ค่าเริ่มต้น'),
                ],
               ),
              ),
             if (defaults.length > _defaultsShown)
              Container(
               decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
               child: SizedBox(
                height: 48,
                child: TextButton(
                 onPressed: () => setState(() => _defaultsShown += 10),
                 child: Text(
                  'แสดงเพิ่มอีก ${(defaults.length - _defaultsShown).clamp(0, 10)} รายการ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.link),
                 ),
                ),
               ),
              ),
            ],
           ],
          ),
         ),
        ),
       ],
      ],
     ),
    );
   },
  );
 }

 Widget _tester(_C c) {
  final text = _testCtrl.text.trim();
  CategoryMatchResult? result;
  if (text.isNotEmpty) {
   result = CategoryMatcherService.matchCategoryWithResult(
    text: text,
    availableCategories: widget.controller.categories,
    customRules: _userRules,
   );
  }
  final rule = result?.matchedRule;
  return _calmCard(
   c,
   padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
   child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
     Text('ทดลองพิมพ์ชื่อร้าน', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.sub)),
     const SizedBox(height: 8),
     TextField(
      controller: _testCtrl,
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: c.text, fontSize: 15),
      decoration: _inputDeco(c, hint: 'เช่น ชาตรามือ สาขาสยาม'),
     ),
     if (result != null && rule != null) ...[
      const SizedBox(height: 12),
      Row(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
        Padding(padding: const EdgeInsets.only(top: 2), child: Text('จะได้หมวด', style: TextStyle(fontSize: 12.5, color: c.sub))),
        const SizedBox(width: 12),
        Padding(
         padding: const EdgeInsets.only(top: 7),
         child: Container(width: 8, height: 8, decoration: BoxDecoration(color: result.category.color, shape: BoxShape.circle)),
        ),
        const SizedBox(width: 8),
        Expanded(
         child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Text('${result.category.name}${result.tag != null ? '  #${result.tag}' : ''}',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: c.text)),
           Text(
            rule.isDefault ? 'ตรงกับคีย์เวิร์ดมาตรฐาน: “${rule.keyword}”' : 'ตรงกับกฎของคุณ: “${rule.keyword}”',
            style: c.subtitle,
           ),
          ],
         ),
        ),
       ],
      ),
     ] else if (text.isNotEmpty) ...[
      const SizedBox(height: 10),
      Text('ไม่ตรงกับกฎไหน ตอนจดรายการคุณเลือกหมวดเองได้', style: c.subtitle),
      Align(
       alignment: Alignment.centerLeft,
       child: TextButton(
        style: TextButton.styleFrom(minimumSize: const Size(44, 44), padding: EdgeInsets.zero),
        onPressed: () => _showAddKeywordDialog(initialKeyword: text),
        child: Text('สร้างกฎจากชื่อนี้', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.link)),
       ),
      ),
     ],
    ],
   ),
  );
 }

 Widget _ruleRow(_C c, KeywordRule rule, bool first) {
  final cat = _cat(rule);
  final isIncome = cat?.type == CategoryType.income;
  final tag = rule.tag?.trim();
  return InkWell(
   onTap: () {
    HapticFeedback.selectionClick();
    _showAddKeywordDialog(editing: rule);
   },
   child: Padding(
    padding: const EdgeInsets.only(left: 18, right: 12),
    child: Row(
     children: [
      Container(width: 9, height: 9, decoration: BoxDecoration(color: cat?.color ?? c.faint, shape: BoxShape.circle)),
      const SizedBox(width: 14),
      Expanded(
       child: Container(
        constraints: const BoxConstraints(minHeight: 62),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: c.border))),
        child: Row(
         children: [
          Expanded(
           child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
             Text(rule.keyword, maxLines: 1, overflow: TextOverflow.ellipsis, style: c.title),
             Text(
              '${isIncome ? 'รายรับ › ' : ''}${_catName(rule)}${tag != null && tag.isNotEmpty ? ' • #$tag' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: c.subtitle,
             ),
            ],
           ),
          ),
          Icon(Icons.chevron_right_rounded, size: 22, color: c.faint),
         ],
        ),
       ),
      ),
     ],
    ),
   ),
  );
 }
}

// ---------------------------------------------------------------------------
// Calm monochrome menu-page kit (same look as the menu home). Private copy so
// this screen stays self-contained.
// ---------------------------------------------------------------------------

class _C {
 final Color page, text, sub, icon, faint, card, line, border, seg, accent, link, ok, okText, danger, dangerText, vip, vipLine, disabled;
 final bool dark;

 const _C({
  required this.page,
  required this.text,
  required this.sub,
  required this.icon,
  required this.faint,
  required this.card,
  required this.line,
  required this.border,
  required this.seg,
  required this.accent,
  required this.link,
  required this.ok,
  required this.okText,
  required this.danger,
  required this.dangerText,
  required this.vip,
  required this.vipLine,
  required this.disabled,
  required this.dark,
 });

 factory _C.of(ExpenseController ctl) {
  final t = ctl.currentTheme;
  final dark = ctl.isDarkMode;
  return _C(
   page: t.scaffoldBackground,
   text: t.textColor,
   sub: t.textSecondaryColor,
   icon: dark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
   faint: dark ? Colors.white24 : const Color(0xFFB6BECB),
   card: t.cardBackground,
   line: t.borderColor,
   border: dark ? Colors.white10 : const Color(0xFFEEF0F4),
   seg: dark ? const Color(0xFF0F172A) : const Color(0xFFF1F3F8),
   accent: t.primaryColor,
   link: dark ? const Color(0xFF93C5FD) : t.primaryColor,
   ok: dark ? const Color(0xFF34D399) : const Color(0xFF059669),
   okText: dark ? const Color(0xFF34D399) : const Color(0xFF047857),
   danger: dark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
   dangerText: dark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
   vip: dark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
   vipLine: dark ? const Color(0xFF6B5A1E) : const Color(0xFFE9C98B),
   disabled: dark ? Colors.white12 : const Color(0xFFA5B4CF),
   dark: dark,
  );
 }

 TextStyle get title => TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: text);
 TextStyle get subtitle => TextStyle(fontSize: 12.5, height: 1.35, color: sub);
}

/// White app bar: 44px back chevron, 18/700 title, optional 12px subtitle, optional [bottom] (e.g. a segmented control), 1px bottom line.
PreferredSizeWidget _calmAppBar(BuildContext context, _C c, String title,
  {String? subtitle, List<Widget> actions = const [], Widget? bottom, double bottomHeight = 0}) {
 return PreferredSize(
  preferredSize: Size.fromHeight(61 + bottomHeight),
  child: Material(
   color: c.card,
   child: SafeArea(
    bottom: false,
    child: Container(
     decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
     child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
       SizedBox(
        height: 60,
        child: Padding(
         padding: const EdgeInsets.only(left: 6, right: 8),
         child: Row(
          children: [
           SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
             tooltip: 'ย้อนกลับ',
             padding: EdgeInsets.zero,
             icon: Icon(Icons.chevron_left_rounded, size: 28, color: c.text),
             onPressed: () => Navigator.maybePop(context),
            ),
           ),
           const SizedBox(width: 6),
           Expanded(
            child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text)),
              if (subtitle != null)
               Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.sub)),
             ],
            ),
           ),
           ...actions,
          ],
         ),
        ),
       ),
       if (bottom != null) SizedBox(height: bottomHeight, child: bottom),
      ],
     ),
    ),
   ),
  ),
 );
}

/// Sticky bottom action bar (white, top border).
Widget _calmBottomBar(_C c, Widget child) => Container(
      decoration: BoxDecoration(color: c.card, border: Border(top: BorderSide(color: c.line))),
      child: SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), child: child)),
     );

/// Full-width 52px accent button; null [onTap] shows the disabled look.
Widget _primaryButton(_C c, String label, VoidCallback? onTap, {IconData? icon, Color? color, bool busy = false}) {
 final bg = onTap == null ? c.disabled : (color ?? c.accent);
 return SizedBox(
  width: double.infinity,
  height: 52,
  child: ElevatedButton(
   onPressed: busy ? null : onTap,
   style: ElevatedButton.styleFrom(
    backgroundColor: bg,
    disabledBackgroundColor: busy ? bg : c.disabled,
    foregroundColor: Colors.white,
    disabledForegroundColor: Colors.white.withValues(alpha: 0.9),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
   ),
   child: busy
       ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
       : Row(
           mainAxisSize: MainAxisSize.min,
           children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
           ],
          ),
  ),
 );
}

/// Outlined secondary button (44px+).
Widget _outlineButton(_C c, String label, VoidCallback? onTap, {IconData? icon, Color? color, double height = 48}) {
 final fg = color ?? c.text;
 return SizedBox(
  height: height,
  child: OutlinedButton(
   onPressed: onTap,
   style: OutlinedButton.styleFrom(
    foregroundColor: fg,
    side: BorderSide(color: c.line),
    backgroundColor: c.card,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
   ),
   child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
     if (icon != null) ...[Icon(icon, size: 19, color: fg), const SizedBox(width: 8)],
     Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg))),
    ],
   ),
  ),
 );
}

/// 1px-bordered card, radius 16.
Widget _calmCard(_C c, {required Widget child, EdgeInsetsGeometry? padding}) => Container(
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.line)),
      clipBehavior: Clip.antiAlias,
      child: Material(color: Colors.transparent, child: padding == null ? child : Padding(padding: padding, child: child)),
     );

/// 13px/600 grey label above a card group, with an optional right-hand value.
Widget _sectionLabel(_C c, String title, {String? trailing, Widget? trailingWidget}) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
       children: [
        Expanded(child: Text(title, style: TextStyle(color: c.sub, fontSize: 13, fontWeight: FontWeight.w600))),
        if (trailing != null) Text(trailing, style: TextStyle(color: c.sub, fontSize: 13, fontFeatures: const [FontFeature.tabularFigures()])),
        ?trailingWidget,
       ],
      ),
     );

/// Small outlined pill used for neutral status ("บัญชีหลัก", "VIP", "เปิดอยู่").
Widget _pill(_C c, String text, {Color? color, Color? border}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: border ?? c.line)),
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color ?? c.sub)),
     );

/// Label above an input: 13/600, optional grey suffix like "(ไม่บังคับ)".
Widget _fieldLabel(_C c, String label, {String? hint}) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(TextSpan(children: [
       TextSpan(text: label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text)),
       if (hint != null) TextSpan(text: ' $hint', style: TextStyle(fontSize: 13, color: c.sub)),
      ])),
     );

InputDecoration _inputDeco(_C c, {String? hint, String? prefix, bool error = false, Widget? prefixIcon, Widget? suffixIcon}) {
 OutlineInputBorder b(Color col, [double w = 1]) => OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: col, width: w));
 return InputDecoration(
  isDense: true,
  hintText: hint,
  hintStyle: TextStyle(color: c.sub.withValues(alpha: 0.8), fontSize: 14.5, fontWeight: FontWeight.w400),
  // Shown as an icon so the prefix (e.g. ฿) stays visible while the field is empty.
  prefixIcon: prefixIcon ??
    (prefix == null
      ? null
      : Padding(
        padding: const EdgeInsets.only(left: 14, right: 8),
        child: Text(prefix.trim(), style: TextStyle(color: c.sub, fontSize: 16, fontWeight: FontWeight.w600)),
       )),
  prefixIconConstraints: prefix != null && prefixIcon == null ? const BoxConstraints(minWidth: 0, minHeight: 0) : null,
  suffixIcon: suffixIcon,
  filled: true,
  fillColor: c.card,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  enabledBorder: b(error ? c.danger : c.line),
  focusedBorder: b(error ? c.danger : c.accent, 1.5),
  border: b(c.line),
 );
}

/// Bottom sheet frame: grab handle, 18/700 title, optional subtitle, close button.
Future<T?> _showCalmSheet<T>(BuildContext context, _C c, {required String title, String? subtitle, required Widget Function(BuildContext ctx, StateSetter setSheet) builder}) {
 return showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  backgroundColor: c.card,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
  builder: (ctx) => StatefulBuilder(
   builder: (ctx, setSheet) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
    child: SafeArea(
     top: false,
     child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.9),
      child: SingleChildScrollView(
       padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
       child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
         Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(2)))),
         const SizedBox(height: 10),
         Row(
          children: [
           Expanded(
            child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text)),
              if (subtitle != null) Text(subtitle, style: TextStyle(fontSize: 12.5, color: c.sub)),
             ],
            ),
           ),
           SizedBox(
            width: 44,
            height: 44,
            child: IconButton(tooltip: 'ปิด', icon: Icon(Icons.close_rounded, size: 22, color: c.sub), onPressed: () => Navigator.pop(ctx)),
           ),
          ],
         ),
         const SizedBox(height: 12),
         builder(ctx, setSheet),
        ],
       ),
      ),
     ),
    ),
   ),
  ),
 );
}

/// Dark floating toast with an optional action (e.g. เลิกทำ).
void _calmToast(BuildContext context, String msg, {bool error = false, String? actionLabel, VoidCallback? onAction}) {
 final m = ScaffoldMessenger.of(context);
 m.hideCurrentSnackBar();
 m.showSnackBar(SnackBar(
  content: Text(msg, style: const TextStyle(fontSize: 13.5, color: Colors.white)),
  behavior: SnackBarBehavior.floating,
  backgroundColor: error ? const Color(0xFFB91C1C) : const Color(0xFF0F172A),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  duration: Duration(seconds: actionLabel != null ? 5 : 3),
  action: actionLabel == null ? null : SnackBarAction(label: actionLabel, textColor: const Color(0xFF93C5FD), onPressed: onAction ?? () {}),
 ));
}
