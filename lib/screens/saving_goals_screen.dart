import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/saving_goal_item.dart';
import '../state/expense_controller.dart';
import '../theme/app_theme_model.dart';
import '../utils/format_utils.dart';
import 'goal_calculator_screen.dart';

const _planLabels = {'day': 'วัน', 'week': 'สัปดาห์', 'month': 'เดือน'};

String _thaiDate(DateTime d) {
  const months = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
  return '${d.day} ${months[d.month - 1]} ${(d.year + 543).toString().substring(2)}';
}

String _baht(double v) => '฿${FormatUtils.formatMoney(v)}';

double _parse(String s) => double.tryParse(s.replaceAll(',', '').trim()) ?? 0.0;

class SavingGoalsScreen extends StatefulWidget {
  final ExpenseController controller;

  const SavingGoalsScreen({super.key, required this.controller});

  @override
  State<SavingGoalsScreen> createState() => _SavingGoalsScreenState();
}

class _SavingGoalsScreenState extends State<SavingGoalsScreen> {
  static const _emojis = ['🎯', '🛡️', '✈️', '🚗', '🏡', '💻', '📱', '💍', '📚', '🕋', '👶', '🏥', '🎁', '💰'];
  static const _colors = [
    0xFF10B981,
    0xFF3B82F6,
    0xFFF59E0B,
    0xFF8B5CF6,
    0xFFEC4899,
    0xFF06B6D4,
    0xFFEF4444,
    0xFF14B8A6,
  ];
  static const _templates = [
    ('🛡️', 'เงินสำรองฉุกเฉิน', 60000.0, 0xFF10B981),
    ('🕋', 'ไปทำฮัจญ์/อุมเราะฮ์', 150000.0, 0xFF14B8A6),
    ('✈️', 'ทริปเที่ยว', 30000.0, 0xFF3B82F6),
    ('📱', 'มือถือ/คอมใหม่', 35000.0, 0xFF8B5CF6),
    ('🚗', 'เงินดาวน์รถ', 100000.0, 0xFFF59E0B),
    ('🏡', 'ดาวน์บ้าน/คอนโด', 200000.0, 0xFFEC4899),
    ('📚', 'การศึกษา', 30000.0, 0xFF06B6D4),
  ];

  ExpenseController get c => widget.controller;

  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  // ---------------------------------------------------------------------------
  // Create / edit
  // ---------------------------------------------------------------------------
  void _openEditor({SavingGoalItem? goal}) {
    HapticFeedback.selectionClick();
    final theme = c.currentTheme;
    final titleCtrl = TextEditingController(text: goal?.title ?? '');
    final targetCtrl = TextEditingController(text: goal != null ? goal.targetAmount.toStringAsFixed(0) : '');
    final currentCtrl = TextEditingController(text: goal != null ? goal.currentAmount.toStringAsFixed(0) : '');
    final planCtrl = TextEditingController(
        text: goal?.plannedAmount != null ? goal!.plannedAmount!.toStringAsFixed(0) : '');
    var emoji = goal?.categoryEmoji.isNotEmpty == true ? goal!.categoryEmoji : '🎯';
    var color = goal?.colorHex ?? _colors.first;
    var freq = goal?.planFrequency ?? 'month';
    DateTime? targetDate = goal?.targetDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final target = _parse(targetCtrl.text);
          final current = _parse(currentCtrl.text);
          final plan = _parse(planCtrl.text);
          final remaining = (target - current).clamp(0.0, double.infinity);
          String? preview;
          if (target > 0 && remaining == 0) {
            preview = '🎉 ยอดที่มีอยู่ครบเป้าหมายแล้ว';
          } else if (target > 0 && targetDate != null) {
            final need = SavingGoalItem.requiredFor(remaining, targetDate!, freq);
            if (need != null) {
              preview = 'ต้องออม${_planLabels[freq]}ละ ${_baht(need)} เพื่อให้ครบภายใน ${_thaiDate(targetDate!)}';
              if (plan > 0) {
                preview += plan + 0.01 >= need
                    ? '\n✅ แผนของคุณทันกำหนด'
                    : '\n⚠️ แผนปัจจุบันยังไม่ทัน ขาดอีก ${_baht(need - plan)}/${_planLabels[freq]}';
              }
            }
          } else if (target > 0 && plan > 0) {
            final periods = (remaining / plan).ceil();
            final finish = SavingGoalItem.dateAfterPeriods(DateTime.now(), periods, freq);
            preview = 'ออม${_planLabels[freq]}ละ ${_baht(plan)} จะครบใน $periods ${_planLabels[freq]} (ประมาณ ${_thaiDate(finish)})';
          }

          return _SheetFrame(
            theme: theme,
            title: goal == null ? 'ตั้งเป้าหมายใหม่' : 'แก้ไขเป้าหมาย',
            trailing: goal == null
                ? null
                : IconButton(
                    tooltip: 'ลบเป้าหมาย',
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                    onPressed: () async {
                      final ok = await _confirmDelete(goal);
                      if (ok && ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
            children: [
              if (goal == null) ...[
                _label('เลือกจากไอเดียยอดนิยม', theme),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final t in _templates)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            avatar: Text(t.$1),
                            label: Text(t.$2, style: const TextStyle(fontSize: 12)),
                            onPressed: () => setSheet(() {
                              emoji = t.$1;
                              titleCtrl.text = t.$2;
                              targetCtrl.text = t.$3.toStringAsFixed(0);
                              color = t.$4;
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              _textField(titleCtrl, 'ชื่อเป้าหมาย', theme, hint: 'เช่น เงินสำรองฉุกเฉิน', onChanged: () => setSheet(() {})),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _moneyField(targetCtrl, 'ยอดเป้าหมาย', theme, onChanged: () => setSheet(() {}))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _moneyField(currentCtrl, goal == null ? 'มีอยู่แล้ว' : 'ยอดออมปัจจุบัน', theme,
                          onChanged: () => setSheet(() {}))),
                ],
              ),
              const SizedBox(height: 14),
              _label('แผนการออม (ไม่บังคับ)', theme),
              Row(
                children: [
                  Expanded(child: _moneyField(planCtrl, 'ออมครั้งละ', theme, onChanged: () => setSheet(() {}))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Segmented(
                      theme: theme,
                      options: [
                        for (final e in _planLabels.entries)
                          (e.value, freq == e.key, () => setSheet(() => freq = e.key)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _label('กำหนดวันที่ต้องการให้ครบ (ไม่บังคับ)', theme),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('ไม่กำหนด'),
                    selected: targetDate == null,
                    onSelected: (_) => setSheet(() => targetDate = null),
                  ),
                  for (final m in [6, 12, 24])
                    ChoiceChip(
                      label: Text('$m เดือน'),
                      selected: false,
                      onSelected: (_) => setSheet(() {
                        final now = DateTime.now();
                        targetDate = DateTime(now.year, now.month + m, now.day);
                      }),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.event_rounded, size: 16),
                    label: Text(targetDate == null ? 'เลือกวันที่' : _thaiDate(targetDate!)),
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: targetDate ?? DateTime(now.year + 1, now.month, now.day),
                        firstDate: now.add(const Duration(days: 1)),
                        lastDate: DateTime(now.year + 40),
                      );
                      if (picked != null) setSheet(() => targetDate = picked);
                    },
                  ),
                ],
              ),
              if (preview != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(preview, style: TextStyle(fontSize: 12.5, height: 1.45, color: theme.textColor)),
                ),
              ],
              const SizedBox(height: 14),
              _label('ไอคอนและสี', theme),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final e in _emojis)
                    GestureDetector(
                      onTap: () => setSheet(() => emoji = e),
                      child: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: emoji == e ? Color(color).withValues(alpha: 0.2) : theme.surfaceBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: emoji == e ? Color(color) : theme.borderColor),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: [
                  for (final col in _colors)
                    GestureDetector(
                      onTap: () => setSheet(() => color = col),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Color(col),
                          shape: BoxShape.circle,
                          border: Border.all(color: color == col ? theme.textColor : Colors.transparent, width: 2.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty || target <= 0) {
                      _snack('กรุณาใส่ชื่อและยอดเป้าหมาย', color: const Color(0xFFEF4444));
                      return;
                    }
                    if (goal == null) {
                      c.addSavingGoal(SavingGoalItem(
                        id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
                        title: title,
                        targetAmount: target,
                        currentAmount: current,
                        categoryEmoji: emoji,
                        colorHex: color,
                        targetDate: targetDate,
                        plannedAmount: plan > 0 ? plan : null,
                        planFrequency: freq,
                        isCompleted: current >= target,
                      ));
                    } else {
                      c.updateSavingGoal(goal.copyWith(
                        title: title,
                        targetAmount: target,
                        currentAmount: current,
                        categoryEmoji: emoji,
                        colorHex: color,
                        targetDate: targetDate,
                        clearTargetDate: targetDate == null,
                        plannedAmount: plan > 0 ? plan : null,
                        clearPlan: plan <= 0,
                        planFrequency: freq,
                        isCompleted: current >= target,
                      ));
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(goal == null ? 'สร้างเป้าหมาย' : 'บันทึก',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _confirmDelete(SavingGoalItem goal) async {
    final theme = c.currentTheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('ลบ "${goal.title}"?', style: TextStyle(color: theme.textColor, fontSize: 17)),
        content: Text(
          'ประวัติการออมของเป้าหมายนี้จะถูกลบด้วย (ไม่กระทบยอดเงินในบัญชี)',
          style: TextStyle(color: theme.textSecondaryColor, fontSize: 13.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await c.deleteSavingGoal(goal.id);
      return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Deposit / withdraw
  // ---------------------------------------------------------------------------
  void _openMoneySheet(SavingGoalItem goal, {required bool withdraw}) {
    HapticFeedback.selectionClick();
    final theme = c.currentTheme;
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String? accountId;
    final quick = <double>{
      if (!withdraw && goal.plannedAmount != null) goal.plannedAmount!,
      100,
      500,
      1000,
      if (!withdraw && goal.remainingAmount > 0) goal.remainingAmount,
      if (withdraw && goal.currentAmount > 0) goal.currentAmount,
    }.where((v) => v > 0).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => _SheetFrame(
          theme: theme,
          title: withdraw ? 'ถอนเงินออกจาก "${goal.title}"' : 'ออมเงินเข้า "${goal.title}"',
          children: [
            Text(
              withdraw
                  ? 'ยอดออมตอนนี้ ${_baht(goal.currentAmount)}'
                  : 'ออมแล้ว ${_baht(goal.currentAmount)} • เหลืออีก ${_baht(goal.remainingAmount)}',
              style: TextStyle(fontSize: 12.5, color: theme.textSecondaryColor),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amtCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              onChanged: (_) => setSheet(() {}),
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: theme.textColor),
              decoration: _decoration(theme, label: 'จำนวนเงิน', prefix: '฿ '),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final q in quick)
                  ActionChip(
                    label: Text(
                      q == goal.plannedAmount && !withdraw
                          ? 'ตามแผน ${_baht(q)}'
                          : (q == goal.remainingAmount && !withdraw)
                              ? 'ให้ครบเป้า ${_baht(q)}'
                              : (withdraw && q == goal.currentAmount)
                                  ? 'ถอนทั้งหมด'
                                  : _baht(q),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => setSheet(() => amtCtrl.text = q.toStringAsFixed(q % 1 == 0 ? 0 : 2)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (c.accounts.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                initialValue: accountId,
                isExpanded: true,
                decoration: _decoration(theme, label: withdraw ? 'คืนเงินเข้าบัญชี' : 'ตัดเงินจากบัญชี'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('ไม่เชื่อมกับบัญชี (บันทึกเฉย ๆ)')),
                  for (final a in c.accounts)
                    DropdownMenuItem<String?>(
                      value: a.id,
                      child: Text('${a.name} (${_baht(a.balance)})', overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setSheet(() => accountId = v),
              ),
              const SizedBox(height: 10),
            ],
            _textField(noteCtrl, 'บันทึกช่วยจำ (ไม่บังคับ)', theme, hint: withdraw ? 'เช่น ใช้จ่ายฉุกเฉิน' : 'เช่น โบนัส'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: withdraw ? const Color(0xFFF97316) : const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: Icon(withdraw ? Icons.outbox_rounded : Icons.savings_rounded),
                label: Text(withdraw ? 'ยืนยันถอนเงิน' : 'ยืนยันออมเงิน',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () async {
                  final amt = _parse(amtCtrl.text);
                  if (amt <= 0) return;
                  if (withdraw && amt > goal.currentAmount) {
                    _snack('ถอนได้ไม่เกิน ${_baht(goal.currentAmount)}', color: const Color(0xFFEF4444));
                    return;
                  }
                  final wasDone = goal.currentAmount >= goal.targetAmount;
                  final note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();
                  if (withdraw) {
                    await c.withdrawFromSavingGoal(goal.id, amt, note: note, accountId: accountId);
                  } else {
                    await c.depositToSavingGoal(goal.id, amt, note: note, accountId: accountId);
                  }
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  HapticFeedback.mediumImpact();
                  if (!withdraw && !wasDone && goal.currentAmount >= goal.targetAmount) {
                    _snack('🎉 ยินดีด้วย! บรรลุเป้าหมาย "${goal.title}" แล้ว', color: const Color(0xFF10B981));
                  } else {
                    _snack(withdraw ? 'ถอน ${_baht(amt)} แล้ว' : 'ออมเพิ่ม ${_baht(amt)} แล้ว');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openHistory(SavingGoalItem goal) {
    final theme = c.currentTheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SheetFrame(
        theme: theme,
        title: 'ประวัติ "${goal.title}"',
        children: [
          if (goal.depositHistory.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('ยังไม่มีรายการ', style: TextStyle(color: theme.textSecondaryColor)),
              ),
            )
          else
            for (final log in goal.depositHistory)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: (log.amount >= 0 ? const Color(0xFF10B981) : const Color(0xFFF97316)).withValues(alpha: 0.14),
                  child: Icon(log.amount >= 0 ? Icons.south_west_rounded : Icons.north_east_rounded,
                      color: log.amount >= 0 ? const Color(0xFF10B981) : const Color(0xFFF97316), size: 20),
                ),
                title: Text(log.amount >= 0 ? 'ออมเพิ่ม' : 'ถอนออก',
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.textColor)),
                subtitle: Text('${_thaiDate(log.date)}${log.note != null && log.note!.isNotEmpty ? ' • ${log.note}' : ''}',
                    style: TextStyle(color: theme.textSecondaryColor, fontSize: 12)),
                trailing: Text(
                  '${log.amount >= 0 ? '+' : '−'}${_baht(log.amount.abs())}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: log.amount >= 0 ? const Color(0xFF10B981) : const Color(0xFFF97316),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Page
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final theme = c.currentTheme;
        final isDark = c.isDarkMode;
        final goals = c.savingGoals;
        final active = goals.where((g) => g.currentAmount < g.targetAmount).toList();
        final done = goals.where((g) => g.currentAmount >= g.targetAmount).toList();
        final totalTarget = goals.fold(0.0, (s, g) => s + g.targetAmount);
        final totalSaved = goals.fold(0.0, (s, g) => s + g.currentAmount);
        final progress = totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;
        final heroText = theme.heroTextColor(isDark);
        final heroMuted = theme.heroTextMutedColor(isDark);

        return Scaffold(
          backgroundColor: theme.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackground,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('เป้าหมายการออมของฉัน',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: theme.textColor)),
            actions: [
              IconButton(
                tooltip: 'คำนวณเวลาเก็บออม',
                icon: Icon(Icons.calculate_rounded, color: theme.primaryColor),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GoalCalculatorScreen(controller: c)),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openEditor(),
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('ตั้งเป้าหมาย', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(gradient: theme.heroGradient, borderRadius: BorderRadius.circular(22)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ออมแล้วทั้งหมด', style: TextStyle(color: heroMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(_baht(totalSaved),
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: heroText)),
                    ),
                    Text('จากเป้าหมายรวม ${_baht(totalTarget)}', style: TextStyle(color: heroMuted, fontSize: 12.5)),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 9,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation(heroText),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${(progress * 100).toStringAsFixed(0)}% • กำลังออม ${active.length} • สำเร็จ ${done.length}',
                        style: TextStyle(color: heroText, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (goals.isEmpty)
                _EmptyState(theme: theme, onCreate: () => _openEditor())
              else ...[
                if (active.isNotEmpty) ...[
                  _sectionTitle('กำลังออม', theme),
                  for (final g in active) _goalCard(g, theme, isDark),
                ],
                if (done.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _sectionTitle('สำเร็จแล้ว 🎉', theme),
                  for (final g in done) _goalCard(g, theme, isDark),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String t, AppThemeModel theme) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.textColor)),
      );

  Widget _goalCard(SavingGoalItem g, AppThemeModel theme, bool isDark) {
    final color = Color(g.colorHex);
    final isDone = g.currentAmount >= g.targetAmount;
    final pct = (g.progressRatio * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDone ? const Color(0xFF10B981).withValues(alpha: 0.5) : theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
                child: Text(g.categoryEmoji.isEmpty ? '🎯' : g.categoryEmoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.textColor)),
                    const SizedBox(height: 2),
                    Text('${_baht(g.currentAmount)} จาก ${_baht(g.targetAmount)}',
                        style: TextStyle(fontSize: 12.5, color: theme.textSecondaryColor)),
                  ],
                ),
              ),
              Text('$pct%', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color)),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: theme.textSecondaryColor),
                onSelected: (v) {
                  if (v == 'edit') _openEditor(goal: g);
                  if (v == 'history') _openHistory(g);
                  if (v == 'delete') _confirmDelete(g);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('แก้ไข / ตั้งแผน')),
                  PopupMenuItem(value: 'history', child: Text('ประวัติการออม')),
                  PopupMenuItem(value: 'delete', child: Text('ลบ', style: TextStyle(color: Color(0xFFEF4444)))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: g.progressRatio,
              minHeight: 9,
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation(isDone ? const Color(0xFF10B981) : color),
            ),
          ),
          const SizedBox(height: 10),
          _insight(g, theme, color),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openMoneySheet(g, withdraw: false),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('ออมเงิน', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: g.currentAmount > 0 ? () => _openMoneySheet(g, withdraw: true) : null,
                  icon: const Icon(Icons.remove_rounded, size: 18),
                  label: const Text('ถอน', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'ประวัติ',
                onPressed: () => _openHistory(g),
                icon: Icon(Icons.history_rounded, color: theme.textSecondaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _insight(SavingGoalItem g, AppThemeModel theme, Color color) {
    final per = _planLabels[g.planFrequency] ?? 'เดือน';
    String text;
    IconData icon;
    Color tone = color;

    if (g.currentAmount >= g.targetAmount) {
      text = 'บรรลุเป้าหมายแล้ว เก่งมาก!';
      icon = Icons.emoji_events_rounded;
      tone = const Color(0xFF10B981);
    } else if (g.targetDate != null) {
      final days = g.targetDate!.difference(DateTime.now()).inDays;
      if (days <= 0) {
        text = 'เลยกำหนด ${_thaiDate(g.targetDate!)} แล้ว ยังขาด ${_baht(g.remainingAmount)} — แตะ ⋮ เพื่อเลื่อนวันหรือปรับแผน';
        icon = Icons.warning_amber_rounded;
        tone = const Color(0xFFEF4444);
      } else {
        final need = g.requiredPerPeriod ?? 0;
        text = 'เหลือ $days วัน (ถึง ${_thaiDate(g.targetDate!)}) ต้องออม$perละ ${_baht(need)}';
        icon = Icons.flag_rounded;
        final plan = g.plannedAmount;
        if (plan != null && plan > 0) {
          if (plan + 0.01 >= need) {
            text += '\n✅ แผน ${_baht(plan)}/$per ทันกำหนด';
          } else {
            text += '\n⚠️ แผน ${_baht(plan)}/$per ยังไม่ทัน ขาดอีก ${_baht(need - plan)}/$per';
            tone = const Color(0xFFF59E0B);
          }
        }
      }
    } else if (g.projectedFinishDate != null) {
      final periods = (g.remainingAmount / g.plannedAmount!).ceil();
      text = 'ออม$perละ ${_baht(g.plannedAmount!)} อีก $periods $per จะครบ (ประมาณ ${_thaiDate(g.projectedFinishDate!)})';
      icon = Icons.timeline_rounded;
    } else {
      text = 'ยังไม่ได้ตั้งแผน — แตะ ⋮ > แก้ไข เพื่อดูว่าจะครบเมื่อไหร่';
      icon = Icons.lightbulb_outline_rounded;
      tone = theme.textSecondaryColor;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: tone.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: tone),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12.5, height: 1.4, color: theme.textColor))),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Form helpers
  // ---------------------------------------------------------------------------
  Widget _label(String t, AppThemeModel theme) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: theme.textSecondaryColor)),
      );

  InputDecoration _decoration(AppThemeModel theme, {String? label, String? prefix, String? hint}) => InputDecoration(
        labelText: label,
        prefixText: prefix,
        hintText: hint,
        filled: true,
        fillColor: theme.surfaceBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.borderColor)),
        enabledBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.borderColor)),
      );

  Widget _textField(TextEditingController ctrl, String label, AppThemeModel theme, {String? hint, VoidCallback? onChanged}) {
    return TextField(
      controller: ctrl,
      onChanged: onChanged == null ? null : (_) => onChanged(),
      style: TextStyle(color: theme.textColor, fontSize: 14),
      decoration: _decoration(theme, label: label, hint: hint),
    );
  }

  Widget _moneyField(TextEditingController ctrl, String label, AppThemeModel theme, {VoidCallback? onChanged}) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      onChanged: onChanged == null ? null : (_) => onChanged(),
      style: TextStyle(color: theme.textColor, fontSize: 15, fontWeight: FontWeight.bold),
      decoration: _decoration(theme, label: label, prefix: '฿ '),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  final AppThemeModel theme;
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  const _SheetFrame({required this.theme, required this.title, required this.children, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: theme.cardBackground,
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
                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: theme.textColor)),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final AppThemeModel theme;
  final List<(String, bool, VoidCallback)> options;

  const _Segmented({required this.theme, required this.options});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.surfaceBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: GestureDetector(
                onTap: o.$3,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: o.$2 ? theme.primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('/${o.$1}',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold, color: o.$2 ? Colors.white : theme.textSecondaryColor)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppThemeModel theme;
  final VoidCallback onCreate;

  const _EmptyState({required this.theme, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 46)),
          const SizedBox(height: 10),
          Text('ยังไม่มีเป้าหมายการออม',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.textColor)),
          const SizedBox(height: 4),
          Text('ตั้งเป้าหมาย ใส่แผนออมต่อเดือน แล้วแอพจะบอกว่าจะครบเมื่อไหร่',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, height: 1.4, color: theme.textSecondaryColor)),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('ตั้งเป้าหมายแรก'),
            style: FilledButton.styleFrom(backgroundColor: theme.primaryColor),
          ),
        ],
      ),
    );
  }
}
