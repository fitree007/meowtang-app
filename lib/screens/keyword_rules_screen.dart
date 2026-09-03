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

 void _showAddKeywordDialog() {
  final keywordCtrl = TextEditingController();
  CategoryItem? selectedCat = widget.controller.categories.isNotEmpty
    ? widget.controller.categories.first
    : null;

  showDialog(
   context: context,
   builder: (ctx) => StatefulBuilder(
    builder: (context, setDialogState) => AlertDialog(
     backgroundColor: widget.controller.isDarkMode ? MeowTheme.navySurface : Colors.white,
     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
     title: const Row(
      children: [
       Icon(Icons.auto_awesome, color: MeowTheme.mustardYellow),
       SizedBox(width: 8),
       Text('เพิ่มคีย์เวิร์ดจัดหมวดหมู่อัตโนมัติ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
     ),
     content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       const Text('คำสำคัญ (Keyword / ชื่อร้าน / ผู้รับโอน):', style: TextStyle(fontSize: 12)),
       const SizedBox(height: 6),
       TextField(
        controller: keywordCtrl,
        decoration: InputDecoration(
         hintText: 'เช่น ชาตรามือ, ข้าวแกงป้าพร, Netflix',
         filled: true,
         fillColor: widget.controller.isDarkMode ? MeowTheme.navyCard : const Color(0xFFF1F5F9),
         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
       ),
       const SizedBox(height: 14),
       const Text('ให้จัดเข้าหมวดหมู่:', style: TextStyle(fontSize: 12)),
       const SizedBox(height: 6),
       DropdownButtonFormField<CategoryItem>(
        value: selectedCat,
        dropdownColor: widget.controller.isDarkMode ? MeowTheme.navyCard : Colors.white,
        decoration: InputDecoration(
         filled: true,
         fillColor: widget.controller.isDarkMode ? MeowTheme.navyCard : const Color(0xFFF1F5F9),
         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: widget.controller.categories.map((c) {
         return DropdownMenuItem(
          value: c,
          child: Text('#${c.name}'),
         );
        }).toList(),
        onChanged: (val) {
         if (val != null) setDialogState(() => selectedCat = val);
        },
       ),
      ],
     ),
     actions: [
      TextButton(
       onPressed: () => Navigator.pop(ctx),
       child: const Text('ยกเลิก'),
      ),
      ElevatedButton(
       style: ElevatedButton.styleFrom(backgroundColor: MeowTheme.mustardYellow),
       onPressed: () {
        if (keywordCtrl.text.trim().isNotEmpty && selectedCat != null) {
         setState(() {
          _userRules.add(
           KeywordRule(
            id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
            keyword: keywordCtrl.text.trim(),
            categoryName: selectedCat!.name,
           ),
          );
          _saveCustomRules();
         });
         Navigator.pop(ctx);
        }
       },
       child: const Text('เพิ่มคีย์เวิร์ด', style: TextStyle(color: MeowTheme.textDarkPrimary, fontWeight: FontWeight.bold)),
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
    actions: [
     IconButton(
      icon: const Icon(Icons.add, color: MeowTheme.textDarkPrimary, size: 28),
      onPressed: _showAddKeywordDialog,
     ),
    ],
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
     const SizedBox(height: 20),

     // User Custom Keywords Section
     if (_userRules.isNotEmpty) ...[
      Text('คีย์เวิร์ดที่คุณกำหนดเอง (${_userRules.length})', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 10),
      ..._userRules.map((rule) {
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
          const Icon(Icons.tag, color: MeowTheme.actionBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(
           child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             Text(rule.keyword, style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
             const SizedBox(height: 2),
             Text(' จัดเข้าหมวด: #${rule.categoryName}', style: const TextStyle(color: MeowTheme.mustardYellow, fontSize: 12)),
            ],
           ),
          ),
          IconButton(
           icon: const Icon(Icons.delete_outline, color: MeowTheme.expenseRed, size: 20),
           onPressed: () {
            setState(() {
             _userRules.remove(rule);
             _saveCustomRules();
            });
           },
          ),
         ],
        ),
       );
      }),
      const SizedBox(height: 20),
     ],

     // Built-in Default Rules
     Text('คีย์เวิร์ดมาตรฐานในระบบ (${CategoryMatcherService.defaultRules.length})', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
     const SizedBox(height: 10),
     ...CategoryMatcherService.defaultRules.map((rule) {
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
            const SizedBox(height: 2),
            Text(' หมวด: #${rule.categoryName}', style: const TextStyle(color: MeowTheme.textLightMuted, fontSize: 12)),
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
