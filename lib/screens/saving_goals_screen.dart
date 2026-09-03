import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/saving_goal_item.dart';
import '../state/expense_controller.dart';
import '../widgets/tactile_button.dart';
import '../widgets/meow_mascot_widget.dart';
import '../utils/format_utils.dart';
import 'goal_calculator_screen.dart';

class SavingGoalsScreen extends StatefulWidget {
  final ExpenseController controller;

  const SavingGoalsScreen({super.key, required this.controller});

  @override
  State<SavingGoalsScreen> createState() => _SavingGoalsScreenState();
}

class _SavingGoalsScreenState extends State<SavingGoalsScreen> {
  final List<String> _emojis = ['🎯', '🛡️', '✈️', '🚗', '🏡', '💻', '💍', '📚', '🎁', '👶', '🏥', '💰'];
  final List<int> _colors = [
    0xFF10B981,
    0xFF3B82F6,
    0xFFF59E0B,
    0xFF8B5CF6,
    0xFFEC4899,
    0xFF06B6D4,
    0xFFEF4444,
    0xFF14B8A6,
  ];

  String _formatThaiDate(DateTime d) {
    const months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    final thaiYear = (d.year + 543).toString().substring(2);
    return '${d.day} ${months[d.month - 1]} $thaiYear';
  }

  void _showAddOrEditGoalModal({SavingGoalItem? goal}) {
    HapticFeedback.selectionClick();
    final currentTheme = widget.controller.currentTheme;

    final titleCtrl = TextEditingController(text: goal?.title ?? '');
    final targetCtrl = TextEditingController(text: goal != null ? goal.targetAmount.toStringAsFixed(0) : '50000');
    final initialCtrl = TextEditingController(text: goal != null ? goal.currentAmount.toStringAsFixed(0) : '0');
    final savingRateCtrl = TextEditingController(text: '100');
    String selectedEmoji = goal?.categoryEmoji ?? '🎯';
    int selectedColor = goal?.colorHex ?? 0xFF10B981;

    final quickTemplates = [
      {'emoji': '🛡️', 'title': 'เงินสำรองฉุกเฉิน 6 เดือน', 'amt': '100000', 'color': 0xFF10B981},
      {'emoji': '✈️', 'title': 'ทริปท่องเที่ยวในฝัน', 'amt': '35000', 'color': 0xFF3B82F6},
      {'emoji': '💻', 'title': 'ซื้อคอมพิวเตอร์ / มือถือ', 'amt': '45000', 'color': 0xFF8B5CF6},
      {'emoji': '🚗', 'title': 'เงินดาวน์รถยนต์', 'amt': '150000', 'color': 0xFFF59E0B},
      {'emoji': '🏡', 'title': 'เก็บเงินซื้อบ้าน / คอนโด', 'amt': '200000', 'color': 0xFFEC4899},
      {'emoji': '📚', 'title': 'ทุนการศึกษา / พัฒนาตัวเอง', 'amt': '30000', 'color': 0xFF06B6D4},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: currentTheme.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      goal != null ? 'แก้ไขเป้าหมายการออม' : 'ตั้งเป้าหมายการออมใหม่ 🎯',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: currentTheme.textColor),
                    ),
                    if (goal != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                        onPressed: () {
                          widget.controller.deleteSavingGoal(goal.id);
                          Navigator.pop(ctx);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (goal == null) ...[
                  Text(
                    'ไอเดียเป้าหมายยอดนิยม:',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: currentTheme.textSecondaryColor),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: quickTemplates.map((t) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            avatar: Text(t['emoji'] as String, style: const TextStyle(fontSize: 13)),
                            label: Text(t['title'] as String, style: const TextStyle(fontSize: 11.5)),
                            backgroundColor: currentTheme.surfaceBackground,
                            onPressed: () {
                              setSheetState(() {
                                titleCtrl.text = t['title'] as String;
                                targetCtrl.text = t['amt'] as String;
                                selectedEmoji = t['emoji'] as String;
                                selectedColor = t['color'] as int;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: titleCtrl,
                  style: TextStyle(color: currentTheme.textColor, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'ชื่อเป้าหมายการออม (เช่น ซื้อทอง, เงินดาวน์รถ)',
                    labelStyle: TextStyle(color: currentTheme.textSecondaryColor, fontSize: 13),
                    filled: true,
                    fillColor: currentTheme.surfaceBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: targetCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: currentTheme.textColor, fontSize: 15, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'ยอดเป้าหมายรวม',
                          prefixText: '฿ ',
                          filled: true,
                          fillColor: currentTheme.surfaceBackground,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: initialCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: currentTheme.textColor, fontSize: 15, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'เงินเก็บที่มีอยู่แล้ว',
                          prefixText: '฿ ',
                          filled: true,
                          fillColor: currentTheme.surfaceBackground,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: savingRateCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: currentTheme.textColor, fontSize: 14, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'วางแผนจะเก็บออมวันละ (บาท) เพื่อคำนวณคาดการณ์',
                    prefixText: '฿ ',
                    filled: true,
                    fillColor: currentTheme.surfaceBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
                  ),
                ),
                const SizedBox(height: 14),
                Text('เลือกไอคอนเป้าหมาย:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentTheme.textSecondaryColor)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: _emojis.map((em) {
                    final isSel = selectedEmoji == em;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedEmoji = em),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSel ? currentTheme.primaryColor.withValues(alpha: 0.2) : currentTheme.surfaceBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSel ? currentTheme.primaryColor : currentTheme.borderColor),
                        ),
                        child: Text(em, style: const TextStyle(fontSize: 18)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final title = titleCtrl.text.trim();
                      final target = double.tryParse(targetCtrl.text.replaceAll(',', '').trim()) ?? 0.0;
                      final initial = double.tryParse(initialCtrl.text.replaceAll(',', '').trim()) ?? 0.0;
                      final rate = double.tryParse(savingRateCtrl.text.replaceAll(',', '').trim()) ?? 100.0;

                      if (title.isNotEmpty && target > 0) {
                        final daysNeeded = rate > 0 ? ((target - initial) / rate).ceil() : 365;
                        final autoTargetDate = DateTime.now().add(Duration(days: daysNeeded > 0 ? daysNeeded : 1));

                        if (goal != null) {
                          widget.controller.updateSavingGoal(
                            goal.copyWith(
                              title: title,
                              targetAmount: target,
                              currentAmount: initial,
                              categoryEmoji: selectedEmoji,
                              colorHex: selectedColor,
                              targetDate: autoTargetDate,
                            ),
                          );
                        } else {
                          widget.controller.addSavingGoal(
                            SavingGoalItem(
                              id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
                              title: title,
                              targetAmount: target,
                              currentAmount: initial,
                              categoryEmoji: selectedEmoji,
                              colorHex: selectedColor,
                              targetDate: autoTargetDate,
                              createdAt: DateTime.now(),
                            ),
                          );
                        }
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(goal != null ? 'บันทึกการแก้ไข' : 'สร้างเป้าหมายการออมนี้', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDepositModal(SavingGoalItem goal) {
    HapticFeedback.selectionClick();
    final currentTheme = widget.controller.currentTheme;
    final amtCtrl = TextEditingController(text: '1000');
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: currentTheme.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            Text(
              'หยอดกระปุก: ${goal.title}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: currentTheme.textColor),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amtCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: TextStyle(color: currentTheme.textColor, fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'จำนวนเงินที่ต้องการหยอด',
                prefixText: '฿ ',
                filled: true,
                fillColor: currentTheme.surfaceBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              style: TextStyle(color: currentTheme.textColor, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'บันทึกช่วยจำ (เช่น เงินพิเศษ, โบนัส)',
                filled: true,
                fillColor: currentTheme.surfaceBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final amt = double.tryParse(amtCtrl.text.replaceAll(',', '').trim()) ?? 0.0;
                  if (amt > 0) {
                    widget.controller.depositToSavingGoal(goal.id, amt, note: noteCtrl.text.trim());
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('หยอดกระปุกสำเร็จ 💰', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = widget.controller.currentTheme;
    final isDark = widget.controller.isDarkMode;
    final goals = widget.controller.savingGoals;

    final totalTarget = goals.fold(0.0, (sum, g) => sum + g.targetAmount);
    final totalSaved = goals.fold(0.0, (sum, g) => sum + g.currentAmount);
    final totalProgress = totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: currentTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: currentTheme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: currentTheme.textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'เป้าหมายการออมของฉัน',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'เปิดเครื่องคำนวณเวลาเก็บออม',
            icon: Icon(Icons.calculate_rounded, color: currentTheme.primaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GoalCalculatorScreen(controller: widget.controller),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: currentTheme.heroGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: currentTheme.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ความคืบหน้าเงินออมทุกเป้าหมาย',
                        style: TextStyle(
                          color: (currentTheme.primaryColor.computeLuminance() > 0.55) ? Colors.black87 : Colors.white70,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(totalProgress * 100).toInt()}% สำเร็จ',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '฿ ${FormatUtils.formatMoney(totalSaved)} / ฿ ${FormatUtils.formatMoney(totalTarget)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: totalProgress,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'รายการเป้าหมาย (${goals.length})',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddOrEditGoalModal(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('ตั้งเป้าหมาย', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (goals.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
                decoration: BoxDecoration(
                  color: currentTheme.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: currentTheme.borderColor),
                ),
                child: Column(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 44)),
                    const SizedBox(height: 10),
                    Text(
                      'คุณยังไม่มีเป้าหมายการออมเงิน',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'แตะปุ่ม "ตั้งเป้าหมาย" เพื่อเริ่มเก็บเงินสู่อนาคตของคุณ',
                      style: TextStyle(fontSize: 11.5, color: currentTheme.textSecondaryColor),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: goals.length,
                itemBuilder: (context, idx) {
                  final goal = goals[idx];
                  final progress = goal.progress;
                  final remaining = goal.remainingAmount;
                  final isDone = goal.isCompleted || goal.currentAmount >= goal.targetAmount;

                  final daysAt100 = remaining > 0 ? (remaining / 100).ceil() : 0;
                  final dateAt100 = DateTime.now().add(Duration(days: daysAt100));

                  final daysAt150 = remaining > 0 ? (remaining / 150).ceil() : 0;
                  final daysSavedWithBoost = daysAt100 - daysAt150;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: currentTheme.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDone ? const Color(0xFF10B981).withValues(alpha: 0.5) : currentTheme.borderColor,
                        width: isDone ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(goal.categoryEmoji, style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      goal.title,
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isDone ? '🎉 บรรลุเป้าหมายแล้ว!' : 'เหลืออีก ฿${FormatUtils.formatMoney(remaining)}',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                                        color: isDone ? const Color(0xFF10B981) : currentTheme.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _showDepositModal(goal),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.savings_rounded, size: 14),
                                  label: const Text('+ หยอดเงิน', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: Icon(Icons.more_vert_rounded, size: 18, color: currentTheme.textSecondaryColor),
                                  onPressed: () => _showAddOrEditGoalModal(goal: goal),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '฿${FormatUtils.formatMoney(goal.currentAmount)} / ฿${FormatUtils.formatMoney(goal.targetAmount)}',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: currentTheme.primaryColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            valueColor: AlwaysStoppedAnimation<Color>(isDone ? const Color(0xFF10B981) : currentTheme.primaryColor),
                            minHeight: 7,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (!isDone && remaining > 0)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: currentTheme.borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFF59E0B)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'AI คาดการณ์ล่วงหน้า (ถ้าออม 100 บ./วัน):',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'จะครบเป้าหมายในอีก $daysAt100 วัน (ประมาณ ${_formatThaiDate(dateAt100)})',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                                ),
                                if (daysSavedWithBoost > 10) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '⚡ เร่งสปีด: ถ้าออมเพิ่มอีก 50 บ./วัน (เป็น 150 บ.) จะสำเร็จเร็วขึ้นถึง $daysSavedWithBoost วัน!',
                                    style: TextStyle(fontSize: 10.5, color: currentTheme.textSecondaryColor),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
