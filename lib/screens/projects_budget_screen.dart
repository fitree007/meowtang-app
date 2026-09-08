import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../models/project_budget.dart';
import '../models/transaction_item.dart';
import '../theme/meow_theme.dart';
import '../widgets/budget_progress_bar.dart';
import '../widgets/transaction_tile.dart';
import '../utils/format_utils.dart';

class ProjectsBudgetScreen extends StatefulWidget {
  final ExpenseController controller;

  const ProjectsBudgetScreen({super.key, required this.controller});

  @override
  State<ProjectsBudgetScreen> createState() => _ProjectsBudgetScreenState();
}

class _ProjectsBudgetScreenState extends State<ProjectsBudgetScreen> {
  String? _selectedProjectId;
  String _activeFilter = 'all'; // 'all', 'projects', 'grants'

  double _getProjectSpent(String projectId) {
    return widget.controller.allTransactions
        .where((t) => t.projectId == projectId && t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  ProjectBudget _getLiveProject(ProjectBudget proj) {
    final liveSpent = _getProjectSpent(proj.id);
    return proj.copyWith(spentAmount: liveSpent);
  }

  void _showAddProjectDialog() {
    HapticFeedback.selectionClick();
    final isDark = widget.controller.isDarkMode;
    final isEn = widget.controller.isEnglish;

    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    final agencyCtrl = TextEditingController();
    bool isGrant = false;
    int selectedColor = 0xFF6366F1;

    final templates = [
      {
        'title': isEn ? 'Research Grant' : 'ทุนวิจัย สกสว./วช.',
        'icon': '🔬',
        'isGrant': true,
        'agency': 'สกสว. / วช.',
        'name': isEn ? 'AI & Innovation Research' : 'โครงการวิจัยและนวัตกรรม',
        'budget': '500,000',
        'desc': isEn ? 'Research operations and equipment' : 'คุมงบค่าตอบแทน ค่าใช้สอย และอุปกรณ์วิจัย',
        'color': 0xFF6366F1,
      },
      {
        'title': isEn ? 'Travel Trip' : 'ทริปท่องเที่ยว',
        'icon': '✈️',
        'isGrant': false,
        'agency': '',
        'name': isEn ? 'Annual Vacation Trip' : 'ทริปท่องเที่ยวประจำปี',
        'budget': '30,000',
        'desc': isEn ? 'Flights, hotels, food & shopping' : 'งบตั๋วเครื่องบิน ที่พัก อาหาร และของฝาก',
        'color': 0xFF0284C7,
      },
      {
        'title': isEn ? 'Home Renovation' : 'รีโนเวทบ้าน',
        'icon': '🏡',
        'isGrant': false,
        'agency': '',
        'name': isEn ? 'Home Decoration' : 'รีโนเวทและตกแต่งบ้าน',
        'budget': '120,000',
        'desc': isEn ? 'Contractor, materials & furniture' : 'ค่าช่าง วัสดุก่อสร้าง และเฟอร์นิเจอร์',
        'color': 0xFF10B981,
      },
      {
        'title': isEn ? 'Freelance Client' : 'งานฟรีแลนซ์',
        'icon': '💼',
        'isGrant': false,
        'agency': '',
        'name': isEn ? 'Client Project Delivery' : 'โปรเจกต์งานว่าจ้างลูกค้า',
        'budget': '60,000',
        'desc': isEn ? 'Project costs and outsourced work' : 'ต้นทุนพัฒนาและค่าจ้างภายนอก',
        'color': 0xFFF59E0B,
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? MeowTheme.navySurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
            final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
            final fieldBg = isDark ? const Color(0xFF0F1E36) : const Color(0xFFF8FAFC);
            final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            isEn ? 'Create Project / Research Grant' : 'สร้างโปรเจกต์ / ทุนวิจัยใหม่',
                            style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(Icons.close_rounded, color: subTextColor),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick Template Chips
                    Text(
                      isEn ? '⚡ Quick Templates (Tap to fill):' : '⚡ เทมเพลตด่วน (แตะเพื่อกรอกอัตโนมัติ):',
                      style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: templates.map((tmpl) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setModalState(() {
                                  nameCtrl.text = tmpl['name'] as String;
                                  budgetCtrl.text = tmpl['budget'] as String;
                                  descCtrl.text = tmpl['desc'] as String;
                                  isGrant = tmpl['isGrant'] as bool;
                                  agencyCtrl.text = tmpl['agency'] as String;
                                  selectedColor = tmpl['color'] as int;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Color(tmpl['color'] as int).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Color(tmpl['color'] as int).withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(tmpl['icon'] as String, style: const TextStyle(fontSize: 14)),
                                    const SizedBox(width: 5),
                                    Text(
                                      tmpl['title'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(tmpl['color'] as int),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: textColor, fontSize: 14.5, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: isEn ? 'Project / Grant Name' : 'ชื่อโครงการ / โปรเจกต์',
                        labelStyle: TextStyle(color: subTextColor, fontSize: 13),
                        hintText: isEn ? 'e.g. AI Research, Travel Trip' : 'เช่น วิจัย AI ภาคสนาม, ทริปญี่ปุ่น, รีโนเวทห้อง',
                        hintStyle: TextStyle(color: subTextColor.withValues(alpha: 0.5), fontSize: 13),
                        filled: true,
                        fillColor: fieldBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: budgetCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: textColor, fontSize: 15.5, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: isEn ? 'Budget Cap (฿)' : 'วงเงินงบประมาณเพดาน (Budget Cap ฿)',
                        labelStyle: TextStyle(color: subTextColor, fontSize: 13),
                        hintText: '0.00',
                        prefixText: '฿ ',
                        prefixStyle: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: fieldBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        color: fieldBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          isEn ? 'Special Grant / Research Project' : 'เป็นทุนวิจัย / เงินก้อนเฉพาะกิจ (Grant)',
                          style: TextStyle(color: textColor, fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          isEn ? 'For university grants, research funds' : 'สำหรับโครงการวิจัย, ทุน สกสว., บพข., วช. หรือเงินอุดหนุน',
                          style: TextStyle(color: subTextColor, fontSize: 11),
                        ),
                        value: isGrant,
                        activeColor: const Color(0xFF6366F1),
                        onChanged: (val) {
                          setModalState(() {
                            isGrant = val;
                            if (val) selectedColor = 0xFF6366F1;
                          });
                        },
                      ),
                    ),

                    if (isGrant) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: agencyCtrl,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: isEn ? 'Granting Agency' : 'หน่วยงานผู้ให้ทุน',
                          labelStyle: TextStyle(color: subTextColor, fontSize: 13),
                          hintText: isEn ? 'e.g. Research Agency' : 'เช่น วช., บพข., สกสว., กองทุนวิจัย',
                          hintStyle: TextStyle(color: subTextColor.withValues(alpha: 0.5), fontSize: 13),
                          filled: true,
                          fillColor: fieldBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      style: TextStyle(color: textColor, fontSize: 13.5),
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: isEn ? 'Project Description / Objective' : 'คำอธิบายโครงการ / วัตถุประสงค์ (ถ้ามี)',
                        labelStyle: TextStyle(color: subTextColor, fontSize: 13),
                        hintText: isEn ? 'e.g. Track travel expenses and receipts' : 'เช่น คุมงบเดินทางและเบิกจ่ายค่าอุปกรณ์',
                        hintStyle: TextStyle(color: subTextColor.withValues(alpha: 0.5), fontSize: 13),
                        filled: true,
                        fillColor: fieldBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                      ),
                    ),

                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameCtrl.text.trim();
                          final budget = double.tryParse(budgetCtrl.text.replaceAll(',', '').trim()) ?? 0.0;
                          if (name.isEmpty || budget <= 0) return;

                          final newProj = ProjectBudget(
                            id: 'proj_${DateTime.now().millisecondsSinceEpoch}',
                            name: name,
                            description: descCtrl.text.trim(),
                            budgetCap: budget,
                            spentAmount: 0.0,
                            startDate: DateTime.now(),
                            endDate: DateTime.now().add(const Duration(days: 90)),
                            colorValue: selectedColor,
                            isGrant: isGrant,
                            grantAgency: isGrant ? agencyCtrl.text.trim() : null,
                          );

                          widget.controller.addProject(newProj);
                          setState(() {
                            _selectedProjectId = newProj.id;
                          });
                          Navigator.pop(ctx);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEn ? 'Project "${newProj.name}" created successfully!' : 'สร้างโครงการ "${newProj.name}" สำเร็จแล้ว!',
                              ),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(selectedColor),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text(
                          isEn ? 'Save Project' : 'บันทึกโครงการ',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddExpenseToProjectDialog(ProjectBudget proj) {
    HapticFeedback.lightImpact();
    final isDark = widget.controller.isDarkMode;
    final isEn = widget.controller.isEnglish;

    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    var selectedAcc = widget.controller.accounts.isNotEmpty ? widget.controller.accounts.first : null;
    var selectedCat = widget.controller.expenseCategories.isNotEmpty
        ? widget.controller.expenseCategories.first
        : (widget.controller.categories.isNotEmpty ? widget.controller.categories.first : null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? MeowTheme.navySurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
            final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
            final fieldBg = isDark ? const Color(0xFF0F1E36) : const Color(0xFFF8FAFC);
            final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEn ? 'Add Expense to Project' : 'บันทึกค่าใช้จ่ายเข้าโครงการ',
                                style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                proj.name,
                                style: TextStyle(color: proj.color, fontSize: 12.5, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(Icons.close_rounded, color: subTextColor),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: isEn ? 'Expense Amount (฿)' : 'จำนวนเงินที่ใช้จ่าย (฿)',
                        labelStyle: TextStyle(color: subTextColor, fontSize: 13),
                        hintText: '0.00',
                        prefixText: '฿ ',
                        prefixStyle: const TextStyle(color: Color(0xFFEF4444), fontSize: 20, fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: fieldBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: noteCtrl,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: isEn ? 'Description / Item name' : 'รายละเอียด / ชื่อรายการ',
                        labelStyle: TextStyle(color: subTextColor, fontSize: 13),
                        hintText: isEn ? 'e.g. Travel tickets, Research materials' : 'เช่น ค่าเบี้ยเลี้ยง, ค่าอุปกรณ์แล็บ, ค่าที่พัก',
                        hintStyle: TextStyle(color: subTextColor.withValues(alpha: 0.5), fontSize: 13),
                        filled: true,
                        fillColor: fieldBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Account Selector
                    Text(
                      isEn ? 'Wallet / Account:' : 'หักจากกระเป๋าเงิน / บัญชี:',
                      style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: widget.controller.accounts.map((acc) {
                          final isSel = selectedAcc?.id == acc.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(widget.controller.trAccount(acc.name)),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel ? Colors.white : textColor,
                              ),
                              selected: isSel,
                              selectedColor: Color(acc.colorValue),
                              backgroundColor: fieldBg,
                              onSelected: (_) {
                                setSheetState(() => selectedAcc = acc);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category Selector
                    Text(
                      isEn ? 'Category:' : 'หมวดหมู่ค่าใช้จ่าย:',
                      style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: (widget.controller.expenseCategories.isNotEmpty
                                ? widget.controller.expenseCategories
                                : widget.controller.categories)
                            .map((cat) {
                          final isSel = selectedCat?.id == cat.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              avatar: Icon(cat.icon, size: 14, color: isSel ? Colors.white : textColor),
                              label: Text(cat.name),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel ? Colors.white : textColor,
                              ),
                              selected: isSel,
                              selectedColor: const Color(0xFF6366F1),
                              backgroundColor: fieldBg,
                              onSelected: (_) {
                                setSheetState(() => selectedCat = cat);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_rounded, size: 20),
                        label: Text(
                          isEn ? 'Record Expense to Project' : 'บันทึกค่าใช้จ่ายในโครงการนี้',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          final amount = double.tryParse(amountCtrl.text.replaceAll(',', '').trim()) ?? 0.0;
                          if (amount <= 0) return;

                          final acc = selectedAcc ?? widget.controller.accounts.first;
                          final cat = selectedCat ?? widget.controller.categories.first;
                          final title = noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : cat.name;

                          final tx = TransactionItem(
                            id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
                            title: title,
                            amount: amount,
                            type: TransactionType.expense,
                            date: DateTime.now(),
                            accountId: acc.id,
                            categoryId: cat.id,
                            categoryName: cat.name,
                            note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
                            projectId: proj.id,
                          );

                          widget.controller.addTransaction(tx);
                          setState(() {});
                          Navigator.pop(ctx);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEn
                                    ? 'Added ฿${FormatUtils.formatCurrency(amount)} to "${proj.name}"'
                                    : 'บันทึก ฿${FormatUtils.formatCurrency(amount)} เข้าโครงการ "${proj.name}" สำเร็จ',
                              ),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _copyProjectSummary(ProjectBudget proj, List<TransactionItem> txList, double spent) {
    HapticFeedback.lightImpact();
    final isEn = widget.controller.isEnglish;
    final remaining = proj.budgetCap - spent;
    final percent = proj.budgetCap > 0 ? (spent / proj.budgetCap * 100).toStringAsFixed(1) : '0';
    final withSlip = txList.where((t) => t.slipImageUrl != null && t.slipImageUrl!.isNotEmpty).length;

    final summary = StringBuffer();
    summary.writeln('📊 สรุปงบประมาณโครงการ: ${proj.name}');
    if (proj.isGrant && proj.grantAgency != null && proj.grantAgency!.isNotEmpty) {
      summary.writeln('🏛️ หน่วยงานผู้ให้ทุน: ${proj.grantAgency}');
    }
    if (proj.description.isNotEmpty) {
      summary.writeln('📝 วัตถุประสงค์: ${proj.description}');
    }
    summary.writeln('💰 วงเงินงบประมาณเพดาน: ฿${FormatUtils.formatCurrency(proj.budgetCap)}');
    summary.writeln('💸 เบิกจ่ายแล้วทั้งหมด: ฿${FormatUtils.formatCurrency(spent)} ($percent%)');
    summary.writeln('💵 งบคงเหลือเบิกได้: ฿${FormatUtils.formatCurrency(remaining > 0 ? remaining : 0)}');
    summary.writeln('🧾 รายการใช้จ่ายทั้งหมด: ${txList.length} รายการ (มีสลิป/หลักฐาน $withSlip รายการ)');

    Clipboard.setData(ClipboardData(text: summary.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEn ? 'Copied project summary report to clipboard!' : 'คัดลอกรายงานสรุปยอดโครงการไปยังคลิปบอร์ดแล้ว!'),
        backgroundColor: const Color(0xFF6366F1),
      ),
    );
  }

  void _confirmDeleteProject(ProjectBudget proj) {
    HapticFeedback.lightImpact();
    final isDark = widget.controller.isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? MeowTheme.navySurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ยืนยันการลบโครงการ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          'คุณต้องการลบโครงการ "${proj.name}" ใช่หรือไม่?\n\n(รายการใช้จ่ายเดิมจะไม่ถูกลบ เพียงแต่จะถูกยกเลิกการผูกกับโครงการนี้)',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              widget.controller.deleteProject(proj.id);
              if (_selectedProjectId == proj.id) {
                setState(() {
                  _selectedProjectId = null;
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('ลบโครงการ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.controller.isDarkMode;
    final isEn = widget.controller.isEnglish;
    final bg = isDark ? MeowTheme.navyBackground : const Color(0xFFF8FAFC);
    final cardBg = isDark ? MeowTheme.navySurface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    final rawProjects = widget.controller.projects;
    final filteredProjects = rawProjects.where((p) {
      if (_activeFilter == 'grants') return p.isGrant;
      if (_activeFilter == 'projects') return !p.isGrant;
      return true;
    }).toList();

    final activeProject = _selectedProjectId != null
        ? widget.controller.getProjectById(_selectedProjectId!)
        : (filteredProjects.isNotEmpty ? filteredProjects.first : null);

    final projectTransactions = activeProject != null
        ? widget.controller.filteredTransactions.where((t) => t.projectId == activeProject.id).toList()
        : <TransactionItem>[];

    final totalBudgetCap = rawProjects.fold(0.0, (sum, p) => sum + p.budgetCap);
    final totalSpent = rawProjects.fold(0.0, (sum, p) => sum + _getProjectSpent(p.id));
    final totalRemaining = (totalBudgetCap - totalSpent).clamp(0.0, double.infinity);
    final totalPercent = totalBudgetCap > 0 ? (totalSpent / totalBudgetCap * 100).toStringAsFixed(0) : '0';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? MeowTheme.navySurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text('📁 ', style: TextStyle(fontSize: 18)),
            Expanded(
              child: Text(
                isEn ? 'Project & Research Budgets' : 'งบโปรเจกต์ & ทุนวิจัย',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 17),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showAddProjectDialog,
            icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF6366F1), size: 26),
            tooltip: isEn ? 'Create Project' : 'สร้างโปรเจกต์ใหม่',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // TOP FINANCIAL KPI SUMMARY
            // ==========================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.analytics_rounded, color: Color(0xFF6366F1), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEn ? 'Overall Portfolio Budget' : 'ภาพรวมงบประมาณทุกโครงการ',
                              style: TextStyle(color: textColor, fontSize: 13.5, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              isEn
                                  ? '${rawProjects.length} projects (${rawProjects.where((p) => p.isGrant).length} grants)'
                                  : '${rawProjects.length} โครงการ (${rawProjects.where((p) => p.isGrant).length} ทุนวิจัย)',
                              style: TextStyle(color: subTextColor, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$totalPercent% ใช้แล้ว',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F1E36) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isEn ? 'Budget Cap' : 'งบเพดานรวม', style: TextStyle(color: subTextColor, fontSize: 10.5)),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '฿${FormatUtils.formatCurrency(totalBudgetCap)}',
                                  style: const TextStyle(color: Color(0xFF0284C7), fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F1E36) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isEn ? 'Disbursed' : 'เบิกจ่ายแล้ว', style: TextStyle(color: subTextColor, fontSize: 10.5)),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '฿${FormatUtils.formatCurrency(totalSpent)}',
                                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F1E36) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isEn ? 'Remaining' : 'คงเหลือเบิกได้', style: TextStyle(color: subTextColor, fontSize: 10.5)),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '฿${FormatUtils.formatCurrency(totalRemaining)}',
                                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 15, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 16),

            // ==========================================
            // FILTER SEGMENTED BUTTONS
            // ==========================================
            Row(
              children: [
                _buildFilterChip(
                  title: isEn ? 'All (${rawProjects.length})' : 'ทั้งหมด (${rawProjects.length})',
                  key: 'all',
                  isDark: isDark,
                  textColor: textColor,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  title: isEn ? 'Projects' : '📁 โปรเจกต์ทั่วไป',
                  key: 'projects',
                  isDark: isDark,
                  textColor: textColor,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  title: isEn ? 'Research Grants' : '🔬 ทุนวิจัย',
                  key: 'grants',
                  isDark: isDark,
                  textColor: textColor,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ==========================================
            // PROJECTS LIST
            // ==========================================
            if (filteredProjects.isEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.folder_special_rounded, color: Color(0xFF6366F1), size: 36),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isEn ? 'No projects found' : 'ยังไม่มีโครงการหรืองบประมาณวิจัย',
                      style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isEn
                          ? 'Create a research grant, home renovation, or travel trip project.'
                          : 'เริ่มสร้างโปรเจกต์ คุมงบทริปท่องเที่ยว หรืองบงานวิจัยได้ทันที',
                      style: TextStyle(color: subTextColor, fontSize: 12.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showAddProjectDialog,
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: Text(isEn ? 'Create First Project' : 'สร้างโครงการแรก'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...filteredProjects.map((proj) {
                final isSelected = activeProject?.id == proj.id;
                final liveProject = _getLiveProject(proj);
                final spent = liveProject.spentAmount;
                final remaining = (proj.budgetCap - spent).clamp(0.0, double.infinity);
                final txList = widget.controller.allTransactions.where((t) => t.projectId == proj.id).toList();
                final withSlip = txList.where((t) => t.slipImageUrl != null && t.slipImageUrl!.isNotEmpty).length;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedProjectId = proj.id;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? proj.color : borderColor,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: proj.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                proj.isGrant ? Icons.science_rounded : Icons.folder_special_rounded,
                                color: proj.color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          proj.name,
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (proj.isGrant && proj.grantAgency != null && proj.grantAgency!.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6366F1).withValues(alpha: 0.14),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            proj.grantAgency!,
                                            style: const TextStyle(
                                              color: Color(0xFF818CF8),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (proj.description.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      proj.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: subTextColor, fontSize: 11.5),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline_rounded, color: isDark ? Colors.white38 : Colors.grey, size: 20),
                              tooltip: isEn ? 'Delete project' : 'ลบโครงการนี้',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _confirmDeleteProject(proj),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Progress bar with live spent amount
                        BudgetProgressBar(
                          project: liveProject,
                          showDetails: true,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),

                        if (liveProject.isOverBudget) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 16),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'แจ้งเตือน: ค่าใช้จ่ายเกินเพดานงบประมาณที่กำหนดไว้!',
                                    style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),
                        // Quick Stats & Slip Audit Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F1E36) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.receipt_long_rounded, size: 15, color: Color(0xFF10B981)),
                                  const SizedBox(width: 5),
                                  Text(
                                    isEn ? 'Slips: $withSlip/${txList.length}' : 'มีสลิป: $withSlip/${txList.length} รายการ',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: withSlip == txList.length && txList.isNotEmpty
                                          ? const Color(0xFF10B981)
                                          : subTextColor,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                isEn
                                    ? 'Rem: ฿${FormatUtils.formatCurrency(remaining)}'
                                    : 'คงเหลือ: ฿${FormatUtils.formatCurrency(remaining)}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: remaining <= 0 ? const Color(0xFFEF4444) : textColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),
                        // Action Bar: Add Expense + Copy Summary
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showAddExpenseToProjectDialog(proj),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: Text(
                                  isEn ? '+ Add Expense' : '+ บันทึกค่าใช้จ่าย',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: proj.color,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _copyProjectSummary(proj, txList, spent),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F1E36) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor),
                                ),
                                child: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF6366F1)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 16),

            // ==========================================
            // PROJECT TRANSACTIONS LOGS
            // ==========================================
            if (activeProject != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      isEn
                          ? 'Expenses in: ${activeProject.name}'
                          : 'รายการใช้จ่ายในโครงการ: ${activeProject.name}',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: activeProject.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${projectTransactions.length} รายการ',
                      style: TextStyle(color: activeProject.color, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (projectTransactions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, color: subTextColor.withValues(alpha: 0.4), size: 36),
                      const SizedBox(height: 8),
                      Text(
                        isEn ? 'No expenses recorded for this project yet.' : 'ยังไม่มีรายการใช้จ่ายที่ผูกกับโครงการนี้',
                        style: TextStyle(color: subTextColor, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () => _showAddExpenseToProjectDialog(activeProject),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(isEn ? 'Add first expense' : 'บันทึกรายการแรกเข้าโครงการ'),
                        style: TextButton.styleFrom(foregroundColor: activeProject.color),
                      ),
                    ],
                  ),
                )
              else
                ...projectTransactions.map((tx) {
                  final acc = widget.controller.getAccountById(tx.accountId);
                  return TransactionTile(
                    transaction: tx,
                    account: acc,
                    project: activeProject,
                    onDelete: () {
                      widget.controller.deleteTransaction(tx.id);
                      setState(() {});
                    },
                  );
                }),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String title,
    required String key,
    required bool isDark,
    required Color textColor,
  }) {
    final isSelected = _activeFilter == key;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _activeFilter = key;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1)
              : (isDark ? const Color(0xFF0F1E36) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : textColor,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
