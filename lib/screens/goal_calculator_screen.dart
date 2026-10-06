import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/saving_goal_item.dart';
import '../state/expense_controller.dart';
import '../theme/app_theme_model.dart';
import '../utils/format_utils.dart';

enum CalcMode { howLong, howMuch }

enum SavePeriod { day, week, month }

extension on SavePeriod {
  String get th => switch (this) { SavePeriod.day => 'วัน', SavePeriod.week => 'สัปดาห์', SavePeriod.month => 'เดือน' };
  String get key => switch (this) { SavePeriod.day => 'day', SavePeriod.week => 'week', SavePeriod.month => 'month' };
  int get perYear => switch (this) { SavePeriod.day => 365, SavePeriod.week => 52, SavePeriod.month => 12 };
}

/// One saving plan simulated period by period.
class SavingPlanResult {
  final int periods; // -1 = never reaches the target
  final double deposited;
  final double growth;
  final List<double> balances; // balance after each period

  const SavingPlanResult(this.periods, this.deposited, this.growth, this.balances);

  bool get reachable => periods >= 0;
}

class GoalMath {
  static double periodRate(double annualPct, SavePeriod p) =>
      annualPct <= 0 ? 0 : math.pow(1 + annualPct / 100, 1 / p.perYear) - 1;

  static SavingPlanResult simulate({
    required double target,
    required double start,
    required double perPeriod,
    required SavePeriod period,
    double annualPct = 0,
    int maxPeriods = 365 * 60,
  }) {
    final r = periodRate(annualPct, period);
    var balance = start;
    var deposited = 0.0;
    final balances = <double>[];
    if (balance >= target) return SavingPlanResult(0, 0, 0, balances);
    if (perPeriod <= 0 && r <= 0) return const SavingPlanResult(-1, 0, 0, []);
    for (var i = 1; i <= maxPeriods; i++) {
      balance = balance * (1 + r) + perPeriod;
      deposited += perPeriod;
      balances.add(balance);
      if (balance >= target) return SavingPlanResult(i, deposited, balance - start - deposited, balances);
    }
    return SavingPlanResult(-1, deposited, balance - start - deposited, balances);
  }

  /// Amount needed each period to reach [target] after [periods] periods.
  static double requiredPerPeriod({
    required double target,
    required double start,
    required int periods,
    required SavePeriod period,
    double annualPct = 0,
  }) {
    if (periods <= 0) return math.max(0, target - start);
    final r = periodRate(annualPct, period);
    if (r == 0) return math.max(0, (target - start) / periods);
    final growth = math.pow(1 + r, periods).toDouble();
    final need = (target - start * growth) * r / (growth - 1);
    return math.max(0, need);
  }

  static DateTime dateAfter(DateTime from, SavePeriod p, int n) {
    switch (p) {
      case SavePeriod.day:
        return from.add(Duration(days: n));
      case SavePeriod.week:
        return from.add(Duration(days: 7 * n));
      case SavePeriod.month:
        final m = from.month + n;
        final y = from.year + (m - 1) ~/ 12;
        final mm = (m - 1) % 12 + 1;
        final last = DateTime(y, mm + 1, 0).day;
        return DateTime(y, mm, math.min(from.day, last));
    }
  }

  /// Number of whole periods between now and [deadline].
  static int periodsUntil(DateTime deadline, SavePeriod p) {
    final now = DateTime.now();
    switch (p) {
      case SavePeriod.day:
        return deadline.difference(now).inDays;
      case SavePeriod.week:
        return deadline.difference(now).inDays ~/ 7;
      case SavePeriod.month:
        var months = (deadline.year - now.year) * 12 + deadline.month - now.month;
        if (deadline.day < now.day) months -= 1;
        return months;
    }
  }
}

String _thaiDate(DateTime d) {
  const months = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
  return '${d.day} ${months[d.month - 1]} ${d.year + 543}';
}

String _duration(DateTime from, DateTime to) {
  var months = (to.year - from.year) * 12 + to.month - from.month;
  final lastDayOfTo = DateTime(to.year, to.month + 1, 0).day;
  if (to.day < from.day && to.day < lastDayOfTo) months -= 1;
  if (months <= 0) {
    final days = to.difference(from).inDays;
    return days <= 0 ? 'วันนี้' : '$days วัน';
  }
  final y = months ~/ 12;
  final m = months % 12;
  return [if (y > 0) '$y ปี', if (m > 0) '$m เดือน'].join(' ');
}

String _baht(double v) => '฿${FormatUtils.formatMoney(v)}';

class GoalCalculatorScreen extends StatefulWidget {
  final ExpenseController controller;

  const GoalCalculatorScreen({super.key, required this.controller});

  @override
  State<GoalCalculatorScreen> createState() => _GoalCalculatorScreenState();
}

class _GoalCalculatorScreenState extends State<GoalCalculatorScreen> {
  CalcMode _mode = CalcMode.howLong;
  SavePeriod _period = SavePeriod.month;
  final _targetCtrl = TextEditingController(text: '100000');
  final _startCtrl = TextEditingController(text: '0');
  final _amountCtrl = TextEditingController(text: '5000');
  final _returnCtrl = TextEditingController(text: '0');
  int _deadlineMonths = 12;

  @override
  void dispose() {
    _targetCtrl.dispose();
    _startCtrl.dispose();
    _amountCtrl.dispose();
    _returnCtrl.dispose();
    super.dispose();
  }

  double _p(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '').trim()) ?? 0.0;

  DateTime get _deadline => GoalMath.dateAfter(DateTime.now(), SavePeriod.month, _deadlineMonths);

  @override
  Widget build(BuildContext context) {
    final theme = widget.controller.currentTheme;
    final isDark = widget.controller.isDarkMode;
    final target = _p(_targetCtrl);
    final start = _p(_startCtrl);
    final annual = _p(_returnCtrl).clamp(0.0, 30.0);
    final remaining = math.max(0.0, target - start);

    // Resolve the plan for both modes into: amount per period + number of periods.
    late double perPeriod;
    late SavingPlanResult sim;
    if (_mode == CalcMode.howLong) {
      perPeriod = _p(_amountCtrl);
    } else {
      final periods = math.max(1, GoalMath.periodsUntil(_deadline, _period));
      perPeriod = GoalMath.requiredPerPeriod(
        target: target,
        start: start,
        periods: periods,
        period: _period,
        annualPct: annual,
      );
      perPeriod = (perPeriod * 100).ceil() / 100;
    }
    sim = GoalMath.simulate(target: target, start: start, perPeriod: perPeriod, period: _period, annualPct: annual);
    final now = DateTime.now();
    final finish = sim.reachable ? GoalMath.dateAfter(now, _period, sim.periods) : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('คำนวณเวลาเก็บออม',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: theme.textColor)),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
          children: [
            _segmented(theme, [
              ('⏳ ใช้เวลานานแค่ไหน?', _mode == CalcMode.howLong, () => setState(() => _mode = CalcMode.howLong)),
              ('💰 ต้องออมเท่าไหร่?', _mode == CalcMode.howMuch, () => setState(() => _mode = CalcMode.howMuch)),
            ], height: 52),
            const SizedBox(height: 14),
            _card(
              theme,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field(_targetCtrl, 'อยากมีเงินเท่าไหร่ (เป้าหมาย)', theme, big: true),
                  const SizedBox(height: 10),
                  _field(_startCtrl, 'ตอนนี้มีเก็บไว้แล้ว', theme),
                  const SizedBox(height: 14),
                  Text(_mode == CalcMode.howLong ? 'จะออมทุก ๆ' : 'ออมเป็นรอบทุก ๆ',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: theme.textSecondaryColor)),
                  const SizedBox(height: 6),
                  _segmented(theme, [
                    for (final p in SavePeriod.values)
                      (p.th, _period == p, () => setState(() => _period = p)),
                  ]),
                  const SizedBox(height: 12),
                  if (_mode == CalcMode.howLong)
                    _field(_amountCtrl, 'ออม${_period.th}ละ', theme)
                  else ...[
                    Text('อยากให้ครบภายใน',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: theme.textSecondaryColor)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final m in [3, 6, 12, 24, 36, 60])
                          ChoiceChip(
                            label: Text(m < 12 ? '$m เดือน' : '${m ~/ 12} ปี'),
                            selected: _deadlineMonths == m,
                            onSelected: (_) => setState(() => _deadlineMonths = m),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('ครบกำหนด ${_thaiDate(_deadline)}',
                        style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
                  ],
                  const SizedBox(height: 12),
                  _field(_returnCtrl, 'ผลตอบแทนคาดการณ์ต่อปี % (ไม่บังคับ)', theme, prefix: '', suffix: '%'),
                  const SizedBox(height: 4),
                  Text('เช่น เงินปันผลกองทุน/สหกรณ์ ใส่ 0 ถ้าเก็บเงินสดหรือบัญชีออมทรัพย์ที่ไม่มีผลตอบแทน',
                      style: TextStyle(fontSize: 11.5, color: theme.textSecondaryColor)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildAnswer(theme, target, start, remaining, perPeriod, sim, finish),
            if (sim.reachable && sim.periods > 0) ...[
              const SizedBox(height: 16),
              _buildEquivalents(theme, perPeriod),
              const SizedBox(height: 16),
              _buildMilestones(theme, isDark, target, start, sim),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: () => _createGoal(target, start, perPeriod, finish!),
                  icon: const Icon(Icons.flag_rounded),
                  label: const Text('สร้างเป็นเป้าหมายการออม', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnswer(
    AppThemeModel theme,
    double target,
    double start,
    double remaining,
    double perPeriod,
    SavingPlanResult sim,
    DateTime? finish,
  ) {
    final now = DateTime.now();
    final String headline;
    final String big;
    final String sentence;
    if (target <= 0) {
      headline = 'ใส่ยอดเป้าหมาย';
      big = '-';
      sentence = 'กรอกจำนวนเงินที่อยากมีด้านบน';
    } else if (remaining <= 0) {
      headline = 'ครบแล้ว';
      big = '🎉';
      sentence = 'เงินที่มีอยู่ ${_baht(start)} ถึงเป้าหมายแล้ว';
    } else if (!sim.reachable) {
      headline = 'ยังคำนวณไม่ได้';
      big = '—';
      sentence = 'ใส่จำนวนเงินที่จะออมต่อ${_period.th}ให้มากกว่า 0';
    } else if (_mode == CalcMode.howLong) {
      headline = 'จะครบเป้าหมายใน';
      big = _duration(now, finish!);
      sentence =
          'ถ้าออม${_period.th}ละ ${_baht(perPeriod)} อีก ${sim.periods} ${_period.th} จะมีเงินครบ ${_baht(target)} ประมาณวันที่ ${_thaiDate(finish)}';
    } else {
      headline = 'ต้องออม${_period.th}ละ';
      big = _baht(perPeriod);
      sentence =
          'ออม${_period.th}ละ ${_baht(perPeriod)} รวม ${sim.periods} ${_period.th} จะมีเงินครบ ${_baht(target)} ภายใน ${_thaiDate(finish!)}';
    }

    Widget stat(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: theme.heroGradient, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headline, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(big, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 6),
          Text(sentence, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.45)),
          if (sim.reachable && sim.periods > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                stat('ต้องเก็บเพิ่ม', _baht(remaining)),
                stat('ฝากรวม', _baht(sim.deposited)),
                stat('ผลตอบแทน', _baht(math.max(0, sim.growth))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEquivalents(AppThemeModel theme, double perPeriod) {
    final perDay = perPeriod / SavingGoalItem.daysPerPeriod(_period.key);
    final rows = [
      ('ต่อวัน', perDay),
      ('ต่อสัปดาห์', perDay * 7),
      ('ต่อเดือน', perDay * 30.4375),
      ('ต่อปี', perDay * 365.25),
    ];
    return _card(
      theme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('เทียบให้เห็นภาพ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textColor)),
          const SizedBox(height: 4),
          Text('แผนเดียวกัน คิดเป็นเงินออม',
              style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final r in rows)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(color: theme.surfaceBackground, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Text(r.$1, style: TextStyle(fontSize: 11, color: theme.textSecondaryColor)),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(_baht(r.$2),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textColor)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('💡 ตัวอย่าง: งดกาแฟแก้วละ ฿60 วันละแก้ว = ออมได้เดือนละ ~${_baht(60 * 30.4375)}',
              style: TextStyle(fontSize: 11.5, color: theme.textSecondaryColor)),
        ],
      ),
    );
  }

  Widget _buildMilestones(AppThemeModel theme, bool isDark, double target, double start, SavingPlanResult sim) {
    final now = DateTime.now();
    final items = <Widget>[];
    for (final pct in [0.25, 0.5, 0.75, 1.0]) {
      final amount = target * pct;
      final reached = start >= amount;
      int? idx;
      if (!reached) {
        for (var i = 0; i < sim.balances.length; i++) {
          if (sim.balances[i] >= amount) {
            idx = i + 1;
            break;
          }
        }
      }
      final date = reached ? null : (idx == null ? null : GoalMath.dateAfter(now, _period, idx));
      final last = pct == 1.0;
      items.add(Row(
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: reached
                      ? const Color(0xFF10B981)
                      : (last ? const Color(0xFFF59E0B) : theme.primaryColor).withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: reached
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                    : Text(last ? '🏆' : '${(pct * 100).toInt()}%',
                        style: TextStyle(fontSize: last ? 15 : 10.5, fontWeight: FontWeight.bold, color: theme.primaryColor)),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(last ? 'ครบเป้าหมาย' : '${(pct * 100).toInt()}% ของเป้าหมาย',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textColor)),
                Text(_baht(amount), style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(reached ? 'ถึงแล้ว ✓' : (date == null ? '-' : _thaiDate(date)),
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: reached ? const Color(0xFF10B981) : theme.textColor)),
              if (!reached && date != null)
                Text('อีก ${_duration(now, date)}', style: TextStyle(fontSize: 11, color: theme.textSecondaryColor)),
            ],
          ),
        ],
      ));
      if (!last) {
        items.add(Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Container(width: 2, height: 16, color: theme.borderColor),
        ));
      }
    }
    return _card(
      theme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('เส้นทางสู่เป้าหมาย', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textColor)),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  Future<void> _createGoal(double target, double start, double perPeriod, DateTime finish) async {
    final nameCtrl = TextEditingController();
    final theme = widget.controller.currentTheme;
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('ตั้งชื่อเป้าหมาย', style: TextStyle(color: theme.textColor, fontSize: 17)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'เช่น เงินดาวน์บ้าน'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim().isEmpty ? 'เป้าหมายการออม' : nameCtrl.text.trim()),
            child: const Text('สร้าง'),
          ),
        ],
      ),
    );
    if (name == null) return;
    await widget.controller.addSavingGoal(SavingGoalItem(
      id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
      title: name,
      targetAmount: target,
      currentAmount: start,
      categoryEmoji: '🎯',
      colorHex: 0xFF10B981,
      targetDate: finish,
      plannedAmount: perPeriod,
      planFrequency: _period.key,
    ));
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('สร้างเป้าหมาย "$name" แล้ว ดูได้ในหน้าเป้าหมายการออม'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  // ---------------------------------------------------------------------------
  Widget _card(AppThemeModel theme, Widget child) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.borderColor),
        ),
        child: child,
      );

  Widget _field(TextEditingController c, String label, AppThemeModel theme,
      {bool big = false, String prefix = '฿ ', String? suffix}) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: theme.textColor, fontSize: big ? 20 : 15, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix.isEmpty ? null : prefix,
        suffixText: suffix,
        filled: true,
        fillColor: theme.surfaceBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.borderColor)),
        enabledBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.borderColor)),
      ),
    );
  }

  Widget _segmented(AppThemeModel theme, List<(String, bool, VoidCallback)> options, {double height = 44}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  o.$3();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: o.$2 ? theme.primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(o.$1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: o.$2 ? Colors.white : theme.textSecondaryColor)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
