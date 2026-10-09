import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../models/project_budget.dart';
import '../models/transaction_item.dart';
import '../theme/app_theme_model.dart';
import '../widgets/meow_fx.dart';
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
        'icon': Icons.science_outlined,
        'isGrant': true,
        'agency': 'สกสว. / วช.',
        'name': isEn ? 'AI & Innovation Research' : 'โครงการวิจัยและนวัตกรรม',
        'budget': '500,000',
        'desc': isEn ? 'Research operations and equipment' : 'คุมงบค่าตอบแทน ค่าใช้สอย และอุปกรณ์วิจัย',
        'color': 0xFF6366F1,
      },
      {
        'title': isEn ? 'Travel Trip' : 'ทริปท่องเที่ยว',
        'icon': Icons.flight_takeoff_rounded,
        'isGrant': false,
        'agency': '',
        'name': isEn ? 'Annual Vacation Trip' : 'ทริปท่องเที่ยวประจำปี',
        'budget': '30,000',
        'desc': isEn ? 'Flights, hotels, food & shopping' : 'งบตั๋วเครื่องบิน ที่พัก อาหาร และของฝาก',
        'color': 0xFF0284C7,
      },
      {
        'title': isEn ? 'Home Renovation' : 'รีโนเวทบ้าน',
        'icon': Icons.home_outlined,
        'isGrant': false,
        'agency': '',
        'name': isEn ? 'Home Decoration' : 'รีโนเวทและตกแต่งบ้าน',
        'budget': '120,000',
        'desc': isEn ? 'Contractor, materials & furniture' : 'ค่าช่าง วัสดุก่อสร้าง และเฟอร์นิเจอร์',
        'color': 0xFF10B981,
      },
      {
        'title': isEn ? 'Freelance Client' : 'งานฟรีแลนซ์',
        'icon': Icons.work_outline_rounded,
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
      backgroundColor: widget.controller.currentTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final textColor = widget.controller.currentTheme.textColor;
            final subTextColor = widget.controller.currentTheme.textSecondaryColor;
            final fieldBg = widget.controller.currentTheme.surfaceBackground;
            final borderColor = widget.controller.currentTheme.borderColor;

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
                      isEn ? 'Quick Templates (Tap to fill):' : 'เทมเพลตด่วน (แตะเพื่อกรอกอัตโนมัติ):',
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
                                    Icon(tmpl['icon'] as IconData, size: 16, color: Color(tmpl['color'] as int)),
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
                        activeThumbColor: const Color(0xFF6366F1),
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
      backgroundColor: widget.controller.currentTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final textColor = widget.controller.currentTheme.textColor;
            final subTextColor = widget.controller.currentTheme.textSecondaryColor;
            final fieldBg = widget.controller.currentTheme.surfaceBackground;
            final borderColor = widget.controller.currentTheme.borderColor;

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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.controller.currentTheme.cardBackground,
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
    return ListenableBuilder(listenable: widget.controller, builder: (context, _) => _buildPage(context));
  }

  Widget _buildPage(BuildContext context) {
    final theme = widget.controller.currentTheme;
    final isDark = widget.controller.isDarkMode;
    final isEn = widget.controller.isEnglish;

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
    var fx = 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: Column(
        children: [
          _header(theme, isEn),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              physics: const BouncingScrollPhysics(),
              children: [
                FxFadeUp(
                  index: fx++,
                  child: _hero(theme, isDark, isEn, rawProjects, totalBudgetCap, totalSpent, totalRemaining),
                ),
                const SizedBox(height: 16),
                _filters(theme, isEn, rawProjects.length),
                const SizedBox(height: 16),
                if (filteredProjects.isEmpty)
                  FxFadeUp(index: fx++, child: _emptyProjects(theme, isDark, isEn))
                else
                  for (final proj in filteredProjects) ...[
                    FxFadeUp(
                      index: fx++,
                      child: _projectCard(proj, theme, isDark, isEn,
                          selected: activeProject?.id == proj.id && filteredProjects.length > 1),
                    ),
                    const SizedBox(height: 16),
                  ],
                if (activeProject != null) ..._transactionLog(activeProject, projectTransactions, theme, isDark, isEn),
              ],
            ),
          ),
          _bottomBar(theme, isEn),
        ],
      ),
    );
  }

  Widget _header(AppThemeModel theme, bool isEn) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(bottom: BorderSide(color: theme.borderColor)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              IconButton(
                tooltip: isEn ? 'Back' : 'ย้อนกลับ',
                constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                padding: EdgeInsets.zero,
                icon: Icon(Icons.chevron_left_rounded, color: theme.textColor, size: 28),
                onPressed: () => Navigator.maybePop(context),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  isEn ? 'Project & Research Budgets' : 'งบโปรเจกต์ & ทุนวิจัย',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(AppThemeModel theme, bool isDark, bool isEn, List<ProjectBudget> all, double cap, double spent,
      double remaining) {
    final heroText = theme.heroTextColor(isDark);
    final heroMuted = theme.heroTextMutedColor(isDark);
    final ratio = cap > 0 ? spent / cap : 0.0;
    final grants = all.where((p) => p.isGrant).length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: theme.heroGradient, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(isEn ? 'Overall Portfolio Budget' : 'ภาพรวมงบประมาณทุกโครงการ',
                    style: TextStyle(fontSize: 12.5, color: heroMuted)),
              ),
              Text(
                isEn ? '${all.length} projects ($grants grants)' : '${all.length} โครงการ ($grants ทุนวิจัย)',
                style: TextStyle(fontSize: 12, color: heroMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(isEn ? 'Remaining' : 'คงเหลือเบิกได้', style: TextStyle(fontSize: 12.5, color: heroMuted)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: FxProgress(
              value: remaining,
              builder: (_, v) => Text(_baht(v == remaining ? v : v.roundToDouble()),
                  maxLines: 1, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: heroText)),
            ),
          ),
          const SizedBox(height: 14),
          FxBar(value: ratio, color: ratio > 1 ? const Color(0xFFFCA5A5) : heroText, track: heroText.withValues(alpha: 0.22)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  isEn
                      ? 'Used ${_baht(spent)} (${(ratio * 100).round()}%)'
                      : 'ใช้แล้ว ${_baht(spent)} (${(ratio * 100).round()}%)',
                  style: TextStyle(fontSize: 12.5, color: heroMuted),
                ),
              ),
              Flexible(
                child: Text(
                  isEn ? 'Total cap ${_baht(cap)}' : 'งบเพดานรวม ${_baht(cap)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 12.5, color: heroMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filters(AppThemeModel theme, bool isEn, int total) {
    final items = [
      ('all', isEn ? 'All ($total)' : 'ทั้งหมด ($total)'),
      ('grants', isEn ? 'Research Grants' : 'ทุนวิจัย'),
      ('projects', isEn ? 'Projects' : 'โปรเจกต์ทั่วไป'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final it in items)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(theme: theme, title: it.$2, key: it.$1),
            ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(AppThemeModel theme, bool isDark, {Color? selectedColor}) => BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: selectedColor != null
            ? Border.all(color: selectedColor, width: 2)
            : (isDark ? Border.all(color: theme.borderColor) : null),
        boxShadow: isDark ? null : const [BoxShadow(color: Color(0x0F0F172A), blurRadius: 14, offset: Offset(0, 4))],
      );

  Widget _emptyProjects(AppThemeModel theme, bool isDark, bool isEn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: _cardDecoration(theme, isDark),
      child: Column(
        children: [
          Icon(Icons.folder_open_outlined, size: 40, color: theme.textSecondaryColor),
          const SizedBox(height: 12),
          Text(
            isEn ? 'No projects found' : 'ยังไม่มีโครงการหรืองบประมาณวิจัย',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.textColor, fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            isEn
                ? 'Create a research grant, home renovation, or travel trip project.'
                : 'เริ่มสร้างโปรเจกต์ คุมงบทริปท่องเที่ยว หรืองบงานวิจัยได้ทันที',
            style: TextStyle(color: theme.textSecondaryColor, fontSize: 12.5, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(text,
            maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
      );

  Widget _projectCard(ProjectBudget proj, AppThemeModel theme, bool isDark, bool isEn, {required bool selected}) {
    final liveProject = _getLiveProject(proj);
    final spent = liveProject.spentAmount;
    final ratio = proj.budgetCap > 0 ? spent / proj.budgetCap : 0.0;
    final txList = widget.controller.allTransactions.where((t) => t.projectId == proj.id).toList();
    final withSlip = txList.where((t) => t.slipImageUrl != null && t.slipImageUrl!.isNotEmpty).length;
    final tint = proj.color.withValues(alpha: isDark ? 0.22 : 0.12);
    final tagFg = isDark ? Color.lerp(proj.color, Colors.white, 0.35)! : proj.color;
    final over = liveProject.isOverBudget;
    final danger = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
    final okGreen = isDark ? const Color(0xFF34D399) : const Color(0xFF047857);

    final tagText = proj.isGrant
        ? [isEn ? 'Research grant' : 'ทุนวิจัย', if (proj.grantAgency?.isNotEmpty ?? false) proj.grantAgency!].join(' ')
        : (isEn ? 'Project' : 'โปรเจกต์');

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedProjectId = proj.id;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(theme, isDark, selectedColor: selected ? proj.color : null),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)),
                  child: Icon(proj.isGrant ? Icons.science_outlined : Icons.folder_outlined, color: tagFg, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tag(tagText, tagFg, tint),
                      const SizedBox(height: 4),
                      Text(proj.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600, fontSize: 15)),
                      if (proj.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(proj.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: theme.textSecondaryColor, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isEn ? 'Delete project' : 'ลบโครงการนี้',
                  constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.delete_outline_rounded, color: theme.textSecondaryColor, size: 20),
                  onPressed: () => _confirmDeleteProject(proj),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: _baht(spent)),
                      TextSpan(
                        text: ' / ${_baht(proj.budgetCap)}',
                        style: TextStyle(fontWeight: FontWeight.w400, color: theme.textSecondaryColor),
                      ),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textColor),
                  ),
                ),
                Text(
                  isEn ? '${(ratio * 100).round()}% used' : '${(ratio * 100).round()}% ใช้แล้ว',
                  style: TextStyle(fontSize: 13, color: over ? danger : theme.textSecondaryColor),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FxBar(
              value: ratio,
              color: over ? const Color(0xFFEF4444) : proj.color,
              track: isDark ? theme.borderColor : const Color(0xFFE9EDF3),
            ),
            if (over) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: danger, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isEn
                          ? 'Over the budget cap by ${_baht(spent - proj.budgetCap)}'
                          : 'เกินเพดานงบประมาณ ${_baht(spent - proj.budgetCap)}',
                      style: TextStyle(color: danger, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _pill(isEn ? '${txList.length} items' : '${txList.length} รายการ', theme.textSecondaryColor,
                    theme.surfaceBackground),
                _pill(
                  isEn ? 'Slips $withSlip/${txList.length}' : 'มีสลิป $withSlip/${txList.length}',
                  withSlip == txList.length && txList.isNotEmpty ? okGreen : theme.textSecondaryColor,
                  withSlip == txList.length && txList.isNotEmpty
                      ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.18 : 0.12)
                      : theme.surfaceBackground,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _showAddExpenseToProjectDialog(proj),
                    style: FilledButton.styleFrom(
                      backgroundColor: proj.color,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isEn ? '+ Add Expense' : '+ บันทึกค่าใช้จ่าย',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: isEn ? 'Copy summary report' : 'คัดลอกรายงานสรุป',
                  child: OutlinedButton(
                    onPressed: () => _copyProjectSummary(proj, txList, spent),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.textColor,
                      minimumSize: const Size(48, 44),
                      padding: EdgeInsets.zero,
                      side: BorderSide(color: theme.borderColor, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Icon(Icons.copy_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: TextStyle(fontSize: 12, color: fg)),
      );

  List<Widget> _transactionLog(
      ProjectBudget activeProject, List<TransactionItem> txs, AppThemeModel theme, bool isDark, bool isEn) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text.rich(
          TextSpan(children: [
            TextSpan(text: isEn ? 'Expenses in ${activeProject.name} ' : 'รายการใช้จ่าย: ${activeProject.name} '),
            TextSpan(
              text: '· ${txs.length}',
              style: TextStyle(fontWeight: FontWeight.w500, color: theme.textSecondaryColor),
            ),
          ]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      const SizedBox(height: 10),
      if (txs.isEmpty)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(theme, isDark),
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, color: theme.textSecondaryColor, size: 32),
              const SizedBox(height: 8),
              Text(
                isEn ? 'No expenses recorded for this project yet.' : 'ยังไม่มีรายการใช้จ่ายที่ผูกกับโครงการนี้',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.textSecondaryColor, fontSize: 13),
              ),
            ],
          ),
        )
      else
        ...txs.map((tx) {
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
    ];
  }

  Widget _bottomBar(AppThemeModel theme, bool isEn) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(top: BorderSide(color: theme.borderColor)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: SafeArea(
        top: false,
        child: FilledButton.icon(
          onPressed: _showAddProjectDialog,
          style: FilledButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          icon: const Icon(Icons.add_rounded, size: 22),
          label: Text(isEn ? 'Create Project' : 'สร้างโครงการใหม่',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildFilterChip({required AppThemeModel theme, required String title, required String key}) {
    final isSelected = _activeFilter == key;
    return Material(
      color: isSelected ? theme.primaryColor : theme.cardBackground,
      shape: StadiumBorder(side: isSelected ? BorderSide.none : BorderSide(color: theme.borderColor)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _activeFilter = key;
          });
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              widthFactor: 1,
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : theme.textColor,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _baht(double v) => '฿${FormatUtils.formatMoney(v, trimZero: true)}';
