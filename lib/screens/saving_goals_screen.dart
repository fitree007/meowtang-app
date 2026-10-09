import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/saving_goal_item.dart';
import '../state/expense_controller.dart';
import '../theme/app_theme_model.dart';
import '../utils/format_utils.dart';
import '../widgets/meow_fx.dart';
import 'goal_calculator_screen.dart';

const _planLabels = {'day': 'วัน', 'week': 'สัปดาห์', 'month': 'เดือน'};

String _thaiDate(DateTime d) {
  const months = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
  return '${d.day} ${months[d.month - 1]} ${(d.year + 543).toString().substring(2)}';
}

String _thaiMonthYear(DateTime d) {
  const months = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
  return '${months[d.month - 1]} ${d.year + 543}';
}

/// Goals store an emoji key (older data); the UI shows it as a line icon like the draft.
const _goalIcons = <String, IconData>{
  '🎯': Icons.flag_outlined,
  '🛡️': Icons.shield_outlined,
  '✈️': Icons.flight_takeoff_rounded,
  '🚗': Icons.directions_car_outlined,
  '🏡': Icons.home_outlined,
  '💻': Icons.laptop_outlined,
  '📱': Icons.smartphone_outlined,
  '💍': Icons.diamond_outlined,
  '📚': Icons.school_outlined,
  '🕋': Icons.mosque_outlined,
  '👶': Icons.child_care_outlined,
  '🏥': Icons.local_hospital_outlined,
  '🎁': Icons.card_giftcard_outlined,
  '💰': Icons.savings_outlined,
};

IconData _goalIcon(String emoji) => _goalIcons[emoji] ?? Icons.flag_outlined;

String _baht(double v) => '฿${FormatUtils.formatMoney(v, trimZero: true)}';

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
  // Popular ideas shown as chips (draft copy first, then the app's extra ideas).
  static const _templates = [
    ('🛡️', 'เงินสำรองฉุกเฉิน 6 เดือน', 60000.0, 0xFF10B981),
    ('✈️', 'ทริปท่องเที่ยวในฝัน', 30000.0, 0xFF3B82F6),
    ('🚗', 'เงินดาวน์รถยนต์', 100000.0, 0xFFF59E0B),
    ('💻', 'ซื้อคอมพิวเตอร์ / มือถือ', 35000.0, 0xFF8B5CF6),
    ('📚', 'ทุนการศึกษา / พัฒนาตัวเอง', 30000.0, 0xFF06B6D4),
    ('🏡', 'ดาวน์บ้าน/คอนโด', 200000.0, 0xFFEC4899),
    ('🕋', 'ไปทำฮัจญ์/อุมเราะฮ์', 150000.0, 0xFF14B8A6),
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
  void _openEditor({SavingGoalItem? goal, (String, String, double, int)? template}) {
    HapticFeedback.selectionClick();
    final theme = c.currentTheme;
    final titleCtrl = TextEditingController(text: goal?.title ?? template?.$2 ?? '');
    final targetCtrl = TextEditingController(
        text: goal != null ? goal.targetAmount.toStringAsFixed(0) : template?.$3.toStringAsFixed(0) ?? '');
    final currentCtrl = TextEditingController(text: goal != null ? goal.currentAmount.toStringAsFixed(0) : '');
    final planCtrl = TextEditingController(
        text: goal?.plannedAmount != null ? goal!.plannedAmount!.toStringAsFixed(0) : '');
    var emoji = goal?.categoryEmoji.isNotEmpty == true ? goal!.categoryEmoji : template?.$1 ?? '🎯';
    var color = goal?.colorHex ?? template?.$4 ?? _colors.first;
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
            preview = 'ยอดที่มีอยู่ครบเป้าหมายแล้ว';
          } else if (target > 0 && targetDate != null) {
            final need = SavingGoalItem.requiredFor(remaining, targetDate!, freq);
            if (need != null) {
              preview = 'ต้องออม${_planLabels[freq]}ละ ${_baht(need)} เพื่อให้ครบภายใน ${_thaiDate(targetDate!)}';
              if (plan > 0) {
                preview += plan + 0.01 >= need
                    ? '\nแผนของคุณทันกำหนด'
                    : '\nแผนปัจจุบันยังไม่ทัน ขาดอีก ${_baht(need - plan)}/${_planLabels[freq]}';
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
                            avatar: Icon(_goalIcon(t.$1), size: 16),
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
                        child: Icon(_goalIcon(e), size: 20, color: emoji == e ? Color(color) : theme.textSecondaryColor),
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
                    _snack('ยินดีด้วย! บรรลุเป้าหมาย "${goal.title}" แล้ว', color: const Color(0xFF10B981));
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
          if (goal.currentAmount > 0) ...[
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _openMoneySheet(goal, withdraw: true);
              },
              icon: const Icon(Icons.remove_rounded, size: 18),
              label: const Text('ถอนเงินออก', style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.textColor,
                minimumSize: const Size.fromHeight(44),
                side: BorderSide(color: theme.borderColor, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
          ],
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
        final ordered = [...active, ...done];
        var i = 0;

        return Scaffold(
          backgroundColor: theme.scaffoldBackground,
          body: Column(
            children: [
              _header(theme),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  children: [
                    FxFadeUp(index: i++, child: _hero(goals, theme, isDark)),
                    const SizedBox(height: 18),
                    FxFadeUp(
                      index: i++,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _listHeader(goals.length, theme),
                          const SizedBox(height: 10),
                          if (goals.isEmpty) _EmptyState(theme: theme),
                          for (final g in ordered) ...[
                            _goalCard(g, theme, isDark),
                            if (g != ordered.last) const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    FxFadeUp(index: i++, child: _ideas(theme)),
                  ],
                ),
              ),
              _bottomBar(theme),
            ],
          ),
        );
      },
    );
  }

  Widget _header(AppThemeModel theme) {
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
                tooltip: 'ย้อนกลับ',
                constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                padding: EdgeInsets.zero,
                icon: Icon(Icons.chevron_left_rounded, color: theme.textColor, size: 28),
                onPressed: () => Navigator.maybePop(context),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text('เป้าหมายการออมของฉัน',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(List<SavingGoalItem> goals, AppThemeModel theme, bool isDark) {
    final totalTarget = goals.fold(0.0, (s, g) => s + g.targetAmount);
    final totalSaved = goals.fold(0.0, (s, g) => s + g.currentAmount);
    final remaining = goals.fold(0.0, (s, g) => s + g.remainingAmount);
    final progress = totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;
    final heroText = theme.heroTextColor(isDark);
    final heroMuted = theme.heroTextMutedColor(isDark);

    String? forecast;
    if (goals.isNotEmpty) {
      if (remaining <= 0) {
        forecast = 'ครบทุกเป้าหมายแล้ว เก่งมาก!';
      } else {
        final days = (remaining / 100).ceil();
        final when = DateTime.now().add(Duration(days: days));
        forecast = 'จะครบเป้าหมายในอีก ${FormatUtils.formatMoney(days.toDouble(), trimZero: true)} วัน (ประมาณ ${_thaiMonthYear(when)})';
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: theme.heroGradient, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: FxProgress(
                  value: progress,
                  duration: const Duration(milliseconds: 1000),
                  builder: (_, v) => CustomPaint(
                    painter: _RingPainter(value: v, track: heroText.withValues(alpha: 0.2), color: heroText),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${(v * 100).round()}%',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: heroText, height: 1.2)),
                          Text('สำเร็จ', style: TextStyle(fontSize: 12, color: heroMuted, height: 1.2)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ความคืบหน้าเงินออมทุกเป้าหมาย', style: TextStyle(fontSize: 12.5, color: heroMuted)),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: FxProgress(
                        value: totalSaved,
                        builder: (_, v) => Text(_baht(v == totalSaved ? v : v.roundToDouble()),
                            maxLines: 1, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: heroText)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('จากยอดเป้าหมายรวม ${_baht(totalTarget)}', style: TextStyle(fontSize: 13, color: heroMuted)),
                  ],
                ),
              ),
            ],
          ),
          if (forecast != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: heroText.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(Icons.auto_awesome_outlined,
                        size: 20, color: theme.isHeroLight(isDark) ? const Color(0xFFB45309) : const Color(0xFFFDE68A)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI คาดการณ์ (ถ้าออม 100 บ./วัน)',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: heroText)),
                        const SizedBox(height: 2),
                        Text(forecast, style: TextStyle(fontSize: 12.5, color: heroMuted, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _listHeader(int count, AppThemeModel theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'รายการเป้าหมาย '),
                TextSpan(
                    text: '· $count', style: TextStyle(fontWeight: FontWeight.w500, color: theme.textSecondaryColor)),
              ]),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textColor),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GoalCalculatorScreen(controller: c)),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Center(
                  widthFactor: 1,
                  child: Text('คำนวณเวลาเก็บออม ›',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: theme.isDark ? Color.lerp(theme.primaryColor, Colors.white, 0.5) : theme.primaryColor)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(AppThemeModel theme, bool isDark) => BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: theme.borderColor) : null,
        boxShadow: isDark ? null : const [BoxShadow(color: Color(0x0F0F172A), blurRadius: 14, offset: Offset(0, 4))],
      );

  Widget _goalCard(SavingGoalItem g, AppThemeModel theme, bool isDark) {
    final color = Color(g.colorHex);
    final isDone = g.currentAmount >= g.targetAmount;
    final pct = (g.progressRatio * 100).round();
    final insight = _insight(g, theme);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(theme, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.22 : 0.14), borderRadius: BorderRadius.circular(14)),
                child: Icon(_goalIcon(g.categoryEmoji), size: 24, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: theme.textColor)),
                    const SizedBox(height: 2),
                    Text(isDone ? 'บรรลุเป้าหมายแล้ว' : 'เหลืออีก ${_baht(g.remainingAmount)}',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: isDone ? const Color(0xFF059669) : theme.textSecondaryColor,
                            fontWeight: isDone ? FontWeight.w600 : FontWeight.w400)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'แก้ไขเป้าหมาย',
                constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                padding: EdgeInsets.zero,
                icon: Icon(Icons.edit_outlined, size: 20, color: theme.textSecondaryColor),
                onPressed: () => _openEditor(goal: g),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: _baht(g.currentAmount)),
                    TextSpan(
                      text: ' / ${_baht(g.targetAmount)}',
                      style: TextStyle(fontWeight: FontWeight.w400, color: theme.textSecondaryColor),
                    ),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textColor),
                ),
              ),
              Text('$pct%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          FxBar(
            value: g.progressRatio,
            color: color,
            track: isDark ? theme.borderColor : const Color(0xFFE9EDF3),
          ),
          if (insight != null) ...[
            const SizedBox(height: 10),
            insight,
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _openMoneySheet(g, withdraw: false),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('+ หยอดเงิน', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openHistory(g),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textColor,
                    backgroundColor: theme.cardBackground,
                    minimumSize: const Size.fromHeight(44),
                    side: BorderSide(color: theme.borderColor, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ดูประวัติ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Plan / deadline hint for a goal. Null when the goal has neither, as in the draft.
  Widget? _insight(SavingGoalItem g, AppThemeModel theme) {
    final per = _planLabels[g.planFrequency] ?? 'เดือน';
    String text;
    IconData icon;
    Color tone = theme.textSecondaryColor;

    if (g.currentAmount >= g.targetAmount) {
      return null;
    } else if (g.targetDate != null) {
      final days = g.targetDate!.difference(DateTime.now()).inDays;
      if (days <= 0) {
        text = 'เลยกำหนด ${_thaiDate(g.targetDate!)} แล้ว ยังขาด ${_baht(g.remainingAmount)} แตะไอคอนแก้ไขเพื่อเลื่อนวันหรือปรับแผน';
        icon = Icons.error_outline_rounded;
        tone = const Color(0xFFDC2626);
      } else {
        final need = g.requiredPerPeriod ?? 0;
        text = 'เหลือ $days วัน (ถึง ${_thaiDate(g.targetDate!)}) ต้องออม$perละ ${_baht(need)}';
        icon = Icons.flag_outlined;
        final plan = g.plannedAmount;
        if (plan != null && plan > 0) {
          if (plan + 0.01 >= need) {
            text += '\nแผน ${_baht(plan)}/$per ทันกำหนด';
          } else {
            text += '\nแผน ${_baht(plan)}/$per ยังไม่ทัน ขาดอีก ${_baht(need - plan)}/$per';
            tone = const Color(0xFFD97706);
          }
        }
      }
    } else if (g.projectedFinishDate != null) {
      final periods = (g.remainingAmount / g.plannedAmount!).ceil();
      text = 'ออม$perละ ${_baht(g.plannedAmount!)} อีก $periods $per จะครบ (ประมาณ ${_thaiDate(g.projectedFinishDate!)})';
      icon = Icons.schedule_rounded;
    } else {
      return null;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, size: 16, color: tone)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 12.5, height: 1.4, color: tone == theme.textSecondaryColor ? theme.textSecondaryColor : tone)),
        ),
      ],
    );
  }

  Widget _ideas(AppThemeModel theme) {
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(color: theme.primaryColor.withValues(alpha: 0.4), radius: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: theme.cardBackground, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ตั้งเป้าหมายใหม่',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: theme.textColor)),
            const SizedBox(height: 2),
            Text('เลือกจากไอเดียยอดนิยม หรือพิมพ์ชื่อเอง',
                style: TextStyle(fontSize: 12.5, color: theme.textSecondaryColor)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in _templates)
                  _IdeaChip(theme: theme, label: t.$2, onTap: () => _openEditor(template: t)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(AppThemeModel theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(top: BorderSide(color: theme.borderColor)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: SafeArea(
        top: false,
        child: FilledButton.icon(
          onPressed: () => _openEditor(),
          style: FilledButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          icon: const Icon(Icons.add_rounded, size: 22),
          label: const Text('ตั้งเป้าหมายการออมใหม่', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
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

  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.flag_outlined, size: 36, color: theme.textSecondaryColor),
          const SizedBox(height: 10),
          Text('ยังไม่มีเป้าหมายการออม',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: theme.textColor)),
          const SizedBox(height: 4),
          Text('ตั้งเป้าหมาย ใส่แผนออมต่อเดือน แล้วแอพจะบอกว่าจะครบเมื่อไหร่',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, height: 1.4, color: theme.textSecondaryColor)),
        ],
      ),
    );
  }
}

class _IdeaChip extends StatelessWidget {
  final AppThemeModel theme;
  final String label;
  final VoidCallback onTap;

  const _IdeaChip({required this.theme, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.surfaceBackground,
      shape: StadiumBorder(side: BorderSide(color: theme.borderColor)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              widthFactor: 1,
              child: Text(label, style: TextStyle(fontSize: 13, color: theme.textColor)),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color track;
  final Color color;

  _RingPainter({required this.value, required this.track, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.shortestSide / 2 - stroke / 2 - 3);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 6.2832, false, p..color = track);
    if (value > 0) canvas.drawArc(rect, -1.5708, 6.2832 * value.clamp(0.0, 1.0), false, p..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.color != color || old.track != track;
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(0.75);
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
