import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../models/project_budget.dart';
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

  void _showAddProjectDialog() {
    HapticFeedback.selectionClick();
    final isDark = widget.controller.isDarkMode;

    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    final agencyCtrl = TextEditingController();
    bool isGrant = false;

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
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'สร้างโปรเจกต์ / ทุนวิจัยใหม่',
                        style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close_rounded, color: subTextColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'ชื่อโครงการ / โปรเจกต์',
                      labelStyle: TextStyle(color: subTextColor, fontSize: 13),
                      hintText: 'เช่น วิจัย AI ภาคสนาม, ทริปท่องเที่ยว, ปรับปรุงบ้าน',
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
                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'วงเงินงบประมาณเพดาน (Budget Cap ฿)',
                      labelStyle: TextStyle(color: subTextColor, fontSize: 13),
                      hintText: '0.00',
                      prefixText: '฿ ',
                      prefixStyle: const TextStyle(color: MeowTheme.actionBlue, fontWeight: FontWeight.bold),
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
                        'เป็นทุนวิจัย / เงินก้อนเฉพาะกิจ (Grant)',
                        style: TextStyle(color: textColor, fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'สำหรับโครงการวิจัย, ทุน สกสว., บพข., วช. หรือเงินอุดหนุน',
                        style: TextStyle(color: subTextColor, fontSize: 11),
                      ),
                      value: isGrant,
                      activeColor: const Color(0xFF6366F1),
                      onChanged: (val) {
                        setModalState(() {
                          isGrant = val;
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
                        labelText: 'หน่วยงานผู้ให้ทุน',
                        labelStyle: TextStyle(color: subTextColor, fontSize: 13),
                        hintText: 'เช่น วช., บพข., สกสว., กองทุนวิจัย',
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
                    style: TextStyle(color: textColor, fontSize: 14),
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'คำอธิบายโครงการ / วัตถุประสงค์ (ถ้ามี)',
                      labelStyle: TextStyle(color: subTextColor, fontSize: 13),
                      hintText: 'เช่น คุมงบเดินทางและเบิกจ่ายค่าอุปกรณ์',
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
                          colorValue: isGrant ? 0xFF6366F1 : 0xFFEC4899,
                          isGrant: isGrant,
                          grantAgency: isGrant ? agencyCtrl.text.trim() : null,
                        );

                        widget.controller.addProject(newProj);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isGrant ? const Color(0xFF6366F1) : MeowTheme.mustardYellow,
                        foregroundColor: isGrant ? Colors.white : Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('บันทึกโครงการ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
    final bg = isDark ? MeowTheme.navyBackground : const Color(0xFFF8FAFC);
    final cardBg = isDark ? MeowTheme.navySurface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    final projects = widget.controller.projects;
    final activeProject = _selectedProjectId != null
        ? widget.controller.getProjectById(_selectedProjectId!)
        : (projects.isNotEmpty ? projects.first : null);

    final projectTransactions = activeProject != null
        ? widget.controller.filteredTransactions.where((t) => t.projectId == activeProject.id).toList()
        : [];

    final totalBudgetCap = projects.fold(0.0, (sum, p) => sum + p.budgetCap);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? MeowTheme.navySurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'งบโปรเจกต์ & ทุนวิจัย',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: _showAddProjectDialog,
            icon: const Icon(Icons.add_circle_rounded, color: MeowTheme.mustardYellow, size: 28),
            tooltip: 'สร้างโปรเจกต์ใหม่',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Summary Overview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('โครงการทั้งหมด', style: TextStyle(color: subTextColor, fontSize: 11.5)),
                        const SizedBox(height: 4),
                        Text(
                          '${projects.length} โครงการ',
                          style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 32, color: borderColor),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('งบประมาณรวมเพดาน', style: TextStyle(color: subTextColor, fontSize: 11.5)),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '฿${CurrencyFormat.format(totalBudgetCap)}',
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Projects Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'รายการโครงการ & การเบิกจ่าย (Disbursement)',
                  style: TextStyle(color: textColor, fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (projects.isEmpty)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(32),
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
                      'ยังไม่มีโครงการหรืองบประมาณวิจัย',
                      style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'เริ่มสร้างโปรเจกต์ คุมงบทริปท่องเที่ยว หรืองบงานวิจัยได้ทันที',
                      style: TextStyle(color: subTextColor, fontSize: 12.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showAddProjectDialog,
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('สร้างโครงการแรก'),
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
              ...projects.map((proj) {
                final isSelected = activeProject?.id == proj.id;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedProjectId = proj.id;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
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
                                ],
                              ),
                            ),
                            if (proj.isGrant && proj.grantAgency != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  proj.grantAgency!,
                                  style: const TextStyle(color: Color(0xFF818CF8), fontSize: 10.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(Icons.delete_outline_rounded, color: isDark ? Colors.white38 : Colors.grey, size: 20),
                              tooltip: 'ลบโครงการนี้',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _confirmDeleteProject(proj),
                            ),
                          ],
                        ),
                        if (proj.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            proj.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: subTextColor, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 14),
                        BudgetProgressBar(project: proj, showDetails: true),

                        if (proj.isOverBudget) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 16),

            // Project Transaction Logs
            if (activeProject != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'รายการใช้จ่ายในโครงการ: ${activeProject.name}',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Text(
                    '${projectTransactions.length} รายการ',
                    style: TextStyle(color: subTextColor, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (projectTransactions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    'ยังไม่มีรายการใช้จ่ายที่ผูกกับโครงการนี้',
                    style: TextStyle(color: subTextColor, fontSize: 13),
                  ),
                )
              else
                ...projectTransactions.map((tx) {
                  final acc = widget.controller.getAccountById(tx.accountId);
                  return TransactionTile(
                    transaction: tx,
                    account: acc,
                    project: activeProject,
                    onDelete: () => widget.controller.deleteTransaction(tx.id),
                  );
                }),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
