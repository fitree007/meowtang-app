import 'package:flutter/material.dart';
import '../models/category_item.dart';
import '../services/category_matcher_service.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';

class KeywordRulesScreen extends StatefulWidget {
 final ExpenseController controller;

 const KeywordRulesScreen({super.key, required this.controller});

 @override
 State<KeywordRulesScreen> createState() => _KeywordRulesScreenState();
}

class _KeywordRulesScreenState extends State<KeywordRulesScreen> {
 final List<KeywordRule> _userRules = [];
 final TextEditingController _searchCtrl = TextEditingController();
 bool _showDefaults = false;

 @override
 void dispose() {
  _searchCtrl.dispose();
  super.dispose();
 }

 /// Current category name (rules store a copy of the name, which goes stale after a rename).
 String _catName(KeywordRule rule) {
  for (final c in widget.controller.categories) {
   if (c.id == rule.categoryId) return c.name;
  }
  return rule.categoryName;
 }

 bool _matches(String keyword, String cat) {
  final q = _searchCtrl.text.trim().toLowerCase();
  return q.isEmpty || keyword.toLowerCase().contains(q) || cat.toLowerCase().contains(q);
 }

 void _snack(String msg, {SnackBarAction? action, bool isError = false}) {
  ScaffoldMessenger.of(context)
   ..hideCurrentSnackBar()
   ..showSnackBar(SnackBar(
    content: Text(msg),
    behavior: SnackBarBehavior.floating,
    backgroundColor: isError ? MeowTheme.expenseRed : null,
    action: action,
   ));
 }

 void _deleteRule(KeywordRule rule) {
  final index = _userRules.indexOf(rule);
  setState(() {
   _userRules.removeAt(index);
   _saveCustomRules();
  });
  _snack(
   'ลบคีย์เวิร์ด "${rule.keyword}" แล้ว',
   action: SnackBarAction(
    label: 'เลิกทำ',
    onPressed: () {
     if (!mounted) return;
     setState(() {
      _userRules.insert(index.clamp(0, _userRules.length), rule);
      _saveCustomRules();
     });
    },
   ),
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

 void _showAddKeywordDialog({KeywordRule? editing}) {
  final keywordCtrl = TextEditingController(text: editing?.keyword ?? '');
  final tagCtrl = TextEditingController(text: editing?.tag == null ? '' : '#${editing!.tag}');
  final cats = widget.controller.categories;
  CategoryItem? selectedCat = cats.isNotEmpty ? cats.first : null;
  if (editing != null) {
   for (final c in cats) {
    if (c.id == editing.categoryId) selectedCat = c;
   }
  }

  showDialog(
   context: context,
   builder: (ctx) => StatefulBuilder(
    builder: (context, setDialogState) => AlertDialog(
     backgroundColor: widget.controller.isDarkMode ? MeowTheme.navySurface : Colors.white,
     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
     title: Row(
      children: [
       const Icon(Icons.auto_awesome, color: MeowTheme.mustardYellow),
       const SizedBox(width: 8),
       Expanded(
        child: Text(editing == null ? 'เพิ่มคีย์เวิร์ดจัดหมวดหมู่อัตโนมัติ' : 'แก้ไขคีย์เวิร์ด',
         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
       ),
      ],
     ),
     content: SingleChildScrollView(
      child: Column(
       mainAxisSize: MainAxisSize.min,
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
        const Text('คำสำคัญ (Keyword / ชื่อร้าน / บันทึกช่วยจำ):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
         controller: keywordCtrl,
         decoration: InputDecoration(
          hintText: 'เช่น 7-eleven, นม, ชาตรามือ, Netflix',
          filled: true,
          fillColor: widget.controller.isDarkMode ? MeowTheme.navyCard : const Color(0xFFF1F5F9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
         ),
        ),
        const SizedBox(height: 14),
        const Text('ให้จัดเข้าหมวดหมู่:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        DropdownButtonFormField<CategoryItem>(
         value: selectedCat,
         dropdownColor: widget.controller.isDarkMode ? MeowTheme.navyCard : Colors.white,
         decoration: InputDecoration(
          filled: true,
          fillColor: widget.controller.isDarkMode ? MeowTheme.navyCard : const Color(0xFFF1F5F9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
         ),
         items: [
          ...cats.where((c) => c.type != CategoryType.income),
          ...cats.where((c) => c.type == CategoryType.income),
         ].map((c) {
          return DropdownMenuItem(
           value: c,
           child: Row(
            children: [
             Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
               color: Color(c.colorValue),
               shape: BoxShape.circle,
              ),
             ),
             const SizedBox(width: 8),
             Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
             const SizedBox(width: 6),
             Text(
              c.type == CategoryType.income ? '(รายรับ)' : '(รายจ่าย)',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
             ),
            ],
           ),
          );
         }).toList(),
         onChanged: (val) {
          if (val != null) setDialogState(() => selectedCat = val);
         },
        ),
        const SizedBox(height: 14),
        const Text('แท็กเสริม (#Tag) เช่น #ของกิน, #มื้อเช้า (ไม่บังคับ):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
         controller: tagCtrl,
         decoration: InputDecoration(
          hintText: 'เช่น #ของกินเล่น, #กาแฟเช้า',
          filled: true,
          fillColor: widget.controller.isDarkMode ? MeowTheme.navyCard : const Color(0xFFF1F5F9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
         ),
        ),
       ],
      ),
     ),
     actions: [
      TextButton(
       onPressed: () => Navigator.pop(ctx),
       child: const Text('ยกเลิก'),
      ),
      ElevatedButton(
       style: ElevatedButton.styleFrom(backgroundColor: MeowTheme.mustardYellow),
       onPressed: () {
        final kw = keywordCtrl.text.trim();
        if (kw.isEmpty || selectedCat == null) {
         _snack('กรุณาใส่คำสำคัญ เช่น ชื่อร้าน', isError: true);
         return;
        }
        final duplicate = _userRules.any((r) => r != editing && r.keyword.toLowerCase() == kw.toLowerCase());
        if (duplicate) {
         _snack('มีคีย์เวิร์ด "$kw" อยู่แล้ว แตะที่รายการเพื่อแก้ไขแทน', isError: true);
         return;
        }
        final tagRaw = tagCtrl.text.trim().replaceAll('#', '');
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
        });
        Navigator.pop(ctx);
        _snack(editing == null ? 'เพิ่มคีย์เวิร์ด "$kw" แล้ว' : 'บันทึกการแก้ไขแล้ว');
       },
       child: Text(editing == null ? 'เพิ่มคีย์เวิร์ด' : 'บันทึก',
        style: const TextStyle(color: MeowTheme.textDarkPrimary, fontWeight: FontWeight.bold)),
      ),
     ],
    ),
   ),
  );
 }

 @override
 Widget build(BuildContext context) {
  final isDark = widget.controller.isDarkMode;
  final bgColor = isDark ? MeowTheme.navyBackground : const Color(0xFFF8FAFC);
  final cardBg = isDark ? MeowTheme.navySurface : Colors.white;
  final textPrimary = isDark ? MeowTheme.textLightPrimary : const Color(0xFF0F172A);
  final borderColor = isDark ? MeowTheme.borderColor : const Color(0xFFE2E8F0);

  return Scaffold(
   backgroundColor: bgColor,
   appBar: AppBar(
    backgroundColor: MeowTheme.mustardYellow,
    leading: IconButton(
     icon: const Icon(Icons.arrow_back_ios_new, color: MeowTheme.textDarkPrimary),
     onPressed: () => Navigator.pop(context),
    ),
    title: const Text(
     'คีย์เวิร์ดจัดหมวดหมู่อัตโนมัติ',
     style: TextStyle(color: MeowTheme.textDarkPrimary, fontSize: 18, fontWeight: FontWeight.bold),
    ),
   ),
   body: ListView(
    padding: const EdgeInsets.all(18),
    children: [
     // Banner
     Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
       color: isDark ? const Color(0xFF132845) : const Color(0xFFEFF6FF),
       borderRadius: BorderRadius.circular(16),
       border: Border.all(color: MeowTheme.actionBlue.withOpacity(0.3)),
      ),
      child: Row(
       children: [
        const Icon(Icons.auto_awesome, color: MeowTheme.mustardYellow, size: 24),
        const SizedBox(width: 12),
        Expanded(
         child: Text(
          'เมื่อระบบตรวจพบชื่อร้าน หรือบันทึกช่วยจำที่ตรงกับคีย์เวิร์ด จะเลือกหมวดหมู่นั้นให้อัตโนมัติทันที',
          style: TextStyle(color: textPrimary, fontSize: 13, height: 1.4),
         ),
        ),
       ],
      ),
     ),
     const SizedBox(height: 14),
     TextField(
      controller: _searchCtrl,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
       hintText: 'ค้นหาคีย์เวิร์ดหรือหมวดหมู่',
       prefixIcon: const Icon(Icons.search_rounded),
       suffixIcon: _searchCtrl.text.isEmpty
         ? null
         : IconButton(
          tooltip: 'ล้างคำค้นหา',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => setState(_searchCtrl.clear),
         ),
       filled: true,
       fillColor: cardBg,
       border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
       enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
      ),
     ),
     const SizedBox(height: 16),

     if (_userRules.isEmpty && _searchCtrl.text.isEmpty) ...[
      Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
       ),
       child: Column(
        children: [
         Text('ยังไม่มีคีย์เวิร์ดของคุณ', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
         const SizedBox(height: 4),
         const Text('ตัวอย่าง: "ชาตรามือ" → หมวดอาหาร • "PTT" → หมวดเดินทาง',
          textAlign: TextAlign.center, style: TextStyle(color: MeowTheme.textLightMuted, fontSize: 12.5)),
         const SizedBox(height: 10),
         FilledButton.icon(
          onPressed: _showAddKeywordDialog,
          icon: const Icon(Icons.add),
          label: const Text('เพิ่มคีย์เวิร์ดแรก'),
          style: FilledButton.styleFrom(backgroundColor: MeowTheme.mustardYellow, foregroundColor: MeowTheme.textDarkPrimary),
         ),
        ],
       ),
      ),
      const SizedBox(height: 20),
     ],

     // User Custom Keywords Section
     if (_userRules.isNotEmpty) ...[
      Text('คีย์เวิร์ดที่คุณกำหนดเอง (${_userRules.length}) • แตะเพื่อแก้ไข', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 10),
      ..._userRules.where((r) => _matches(r.keyword, _catName(r))).map((rule) {
       return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showAddKeywordDialog(editing: rule),
        child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
         color: cardBg,
         borderRadius: BorderRadius.circular(14),
         border: Border.all(color: borderColor),
        ),
        child: Row(
         children: [
          Container(
           padding: const EdgeInsets.all(8),
           decoration: BoxDecoration(
            color: MeowTheme.mustardYellow.withOpacity(0.18),
            borderRadius: BorderRadius.circular(10),
           ),
           child: const Icon(Icons.auto_awesome, color: MeowTheme.mustardYellow, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
           child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             Text(rule.keyword, style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
             const SizedBox(height: 4),
             Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
               Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                 color: MeowTheme.actionBlue.withOpacity(0.12),
                 borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                 '📁 ${_catName(rule)}',
                 style: const TextStyle(color: MeowTheme.actionBlue, fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
               ),
               if (rule.tag != null && rule.tag!.trim().isNotEmpty)
                Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                 decoration: BoxDecoration(
                  color: MeowTheme.incomeGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                 ),
                 child: Text(
                  '#${rule.tag!.trim()}',
                  style: const TextStyle(color: MeowTheme.incomeGreen, fontSize: 11.5, fontWeight: FontWeight.bold),
                 ),
                ),
              ],
             ),
            ],
           ),
          ),
          IconButton(
           tooltip: 'ลบคีย์เวิร์ดนี้',
           icon: const Icon(Icons.delete_outline, color: MeowTheme.expenseRed, size: 22),
           onPressed: () => _deleteRule(rule),
          ),
         ],
        ),
        ),
       );
      }),
      const SizedBox(height: 20),
     ],

     // Built-in Default Rules (collapsed unless searching)
     InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _showDefaults = !_showDefaults),
      child: Padding(
       padding: const EdgeInsets.symmetric(vertical: 10),
       child: Row(
        children: [
         Expanded(
          child: Text('คีย์เวิร์ดมาตรฐานในระบบ (${CategoryMatcherService.defaultRules.length})',
           style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
         ),
         Icon(_showDefaults || _searchCtrl.text.isNotEmpty ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          color: MeowTheme.textLightMuted),
        ],
       ),
      ),
     ),
     const SizedBox(height: 4),
     if (_showDefaults || _searchCtrl.text.isNotEmpty)
     ...CategoryMatcherService.defaultRules.where((r) => _matches(r.keyword, r.categoryName)).map((rule) {
      return Container(
       margin: const EdgeInsets.only(bottom: 8),
       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
       decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
       ),
       child: Row(
        children: [
         const Icon(Icons.check_circle, color: MeowTheme.incomeGreen, size: 18),
         const SizedBox(width: 10),
         Expanded(
          child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
            Text(rule.keyword, style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 3),
            Text('📁 หมวด: ${rule.categoryName}', style: const TextStyle(color: MeowTheme.textLightMuted, fontSize: 12)),
           ],
          ),
         ),
         Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
           color: isDark ? MeowTheme.navyCard : const Color(0xFFF1F5F9),
           borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('ค่าเริ่มต้น', style: TextStyle(color: MeowTheme.textLightMuted, fontSize: 10)),
         ),
        ],
       ),
      );
     }),
     const SizedBox(height: 80),
    ],
   ),
   floatingActionButton: FloatingActionButton.extended(
    backgroundColor: MeowTheme.mustardYellow,
    foregroundColor: MeowTheme.textDarkPrimary,
    icon: const Icon(Icons.add),
    label: const Text('เพิ่มคีย์เวิร์ด', style: TextStyle(fontWeight: FontWeight.bold)),
    onPressed: _showAddKeywordDialog,
   ),
  );
 }
}
