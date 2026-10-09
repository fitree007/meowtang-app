import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/saving_goal_item.dart';
import '../state/expense_controller.dart';
import '../theme/app_theme_model.dart';
import '../utils/format_utils.dart';
import '../widgets/meow_fx.dart';

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

String _monthYear(DateTime d) {
  const months = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
  return '${months[d.month - 1]} ${d.year + 543}';
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

String _baht(double v) => '฿${FormatUtils.formatMoney(v, trimZero: true)}';

String _plain(double v) => FormatUtils.formatMoney(v, trimZero: true);

class GoalCalculatorScreen extends StatefulWidget {
  final ExpenseController controller;

  const GoalCalculatorScreen({super.key, required this.controller});

  @override
  State<GoalCalculatorScreen> createState() => _GoalCalculatorScreenState();
}

class _GoalCalculatorScreenState extends State<GoalCalculatorScreen> {
  CalcMode _mode = CalcMode.howLong;
  SavePeriod _period = SavePeriod.month;
  final _targetCtrl = TextEditingController(text: '100,000');
  final _startCtrl = TextEditingController(text: '0');
  final _amountCtrl = TextEditingController(text: '5,000');
  final _returnCtrl = TextEditingController(text: '0');
  int _deadlineMonths = 12;

  static const _quick = {
    SavePeriod.day: [50.0, 100.0, 200.0, 500.0],
    SavePeriod.week: [300.0, 500.0, 1000.0, 2000.0],
    SavePeriod.month: [3000.0, 5000.0, 7000.0, 10000.0],
  };

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

  SavingGoalItem? get _sourceGoal {
    for (final g in widget.controller.savingGoals) {
      if (g.currentAmount < g.targetAmount) return g;
    }
    return null;
  }

  void _useGoal(SavingGoalItem g) {
    HapticFeedback.selectionClick();
    setState(() {
      _targetCtrl.text = _plain(g.targetAmount);
      _startCtrl.text = _plain(g.currentAmount);
      final f = SavePeriod.values.where((p) => p.key == g.planFrequency);
      if (f.isNotEmpty) _period = f.first;
      if (g.plannedAmount != null && g.plannedAmount! > 0) _amountCtrl.text = _plain(g.plannedAmount!);
    });
  }

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
    final canCreate = sim.reachable && sim.periods > 0;
    var i = 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: Column(
        children: [
          _header(theme),
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  FxFadeUp(index: i++, child: _inputCard(theme, isDark)),
                  const SizedBox(height: 16),
                  FxFadeUp(index: i++, child: _buildAnswer(theme, isDark, target, start, remaining, perPeriod, sim, finish)),
                  if (canCreate) ...[
                    const SizedBox(height: 16),
                    FxFadeUp(index: i++, child: _buildMilestones(theme, isDark, target, start, sim)),
                    const SizedBox(height: 16),
                    FxFadeUp(index: i++, child: _buildEquivalents(theme, isDark, perPeriod)),
                  ],
                ],
              ),
            ),
          ),
          _bottomBar(theme, canCreate ? () => _createGoal(target, start, perPeriod, finish!) : null),
        ],
      ),
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
                child: Text('คำนวณเวลาเก็บออม',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputCard(AppThemeModel theme, bool isDark) {
    final goal = _sourceGoal;
    final amount = _p(_amountCtrl);
    return _card(
      theme,
      isDark,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('ระบุข้อมูล', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: theme.textColor)),
              const SizedBox(width: 8),
              if (goal != null)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                  child: Material(
                    color: theme.primaryColor.withValues(alpha: isDark ? 0.22 : 0.1),
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () => _useGoal(goal),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              'ใช้ข้อมูลเป้าหมาย: ${goal.title}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? theme.textColor : theme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _segmented(theme, isDark, [
            ('ใช้เวลานานแค่ไหน?', _mode == CalcMode.howLong, () => setState(() => _mode = CalcMode.howLong)),
            ('ต้องออมเท่าไหร่?', _mode == CalcMode.howMuch, () => setState(() => _mode = CalcMode.howMuch)),
          ]),
          const SizedBox(height: 10),
          _segmented(theme, isDark, [
            for (final p in SavePeriod.values) ('ออมราย${p.th}', _period == p, () => setState(() => _period = p)),
          ]),
          const SizedBox(height: 14),
          _field(_targetCtrl, 'เป้าหมายเงินรวมที่ต้องการ (บาท)', theme),
          const SizedBox(height: 14),
          _field(_startCtrl, 'เงินเก็บที่มีอยู่', theme),
          const SizedBox(height: 14),
          if (_mode == CalcMode.howLong) ...[
            _field(_amountCtrl, 'เงินที่จะออม/${_period.th}', theme, highlight: true),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final q in _quick[_period]!) ...[
                  Expanded(child: _quickChip(theme, q, amount == q)),
                  if (q != _quick[_period]!.last) const SizedBox(width: 6),
                ],
              ],
            ),
          ] else ...[
            _label('อยากให้ครบภายใน', theme),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final m in [3, 6, 12, 24, 36, 60])
                  _optionChip(theme, m < 12 ? '$m เดือน' : '${m ~/ 12} ปี', _deadlineMonths == m,
                      () => setState(() => _deadlineMonths = m)),
              ],
            ),
            const SizedBox(height: 6),
            Text('ครบกำหนด ${_thaiDate(_deadline)}', style: TextStyle(fontSize: 12.5, color: theme.textSecondaryColor)),
          ],
          const SizedBox(height: 14),
          _field(_returnCtrl, 'ผลตอบแทนคาดการณ์ต่อปี % (ไม่บังคับ)', theme, prefix: '', suffix: '%'),
          const SizedBox(height: 6),
          Text('เช่น เงินปันผลกองทุน/สหกรณ์ ใส่ 0 ถ้าเก็บเงินสดหรือบัญชีออมทรัพย์ที่ไม่มีผลตอบแทน',
              style: TextStyle(fontSize: 12, color: theme.textSecondaryColor, height: 1.4)),
        ],
      ),
    );
  }

  Widget _quickChip(AppThemeModel theme, double q, bool selected) {
    return Material(
      color: selected ? theme.primaryColor : theme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: selected ? BorderSide.none : BorderSide(color: theme.borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _amountCtrl.text = _plain(q));
        },
        child: SizedBox(
          height: 44,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  _baht(q),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? Colors.white : theme.textColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _optionChip(AppThemeModel theme, String label, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? theme.primaryColor : theme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: selected ? BorderSide.none : BorderSide(color: theme.borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              widthFactor: 1,
              child: Text(label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? Colors.white : theme.textColor,
                  )),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswer(
    AppThemeModel theme,
    bool isDark,
    double target,
    double start,
    double remaining,
    double perPeriod,
    SavingPlanResult sim,
    DateTime? finish,
  ) {
    final now = DateTime.now();
    final heroText = theme.heroTextColor(isDark);
    final heroMuted = theme.heroTextMutedColor(isDark);
    final headline = _mode == CalcMode.howLong ? 'ผลการคำนวณระยะเวลาเก็บออม' : 'ผลการคำนวณเงินที่ต้องออม';
    final ok = target > 0 && remaining > 0 && sim.reachable;

    final bigStyle = TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: heroText, height: 1.2);
    final unitStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: heroText);
    Widget big;
    String? note;
    if (target <= 0) {
      big = Text('ใส่ยอดเป้าหมาย', style: bigStyle.copyWith(fontSize: 24));
      note = 'กรอกจำนวนเงินที่อยากมีด้านบน';
    } else if (remaining <= 0) {
      big = Text('ครบแล้ว', style: bigStyle);
      note = 'เงินที่มีอยู่ ${_baht(start)} ถึงเป้าหมายแล้ว';
    } else if (!sim.reachable) {
      big = Text('ยังคำนวณไม่ได้', style: bigStyle.copyWith(fontSize: 24));
      note = 'ใส่จำนวนเงินที่จะออมต่อ${_period.th}ให้มากกว่า 0';
    } else if (_mode == CalcMode.howLong) {
      // "1 ปี 8 เดือน" with the numbers large and the units smaller, as in the draft.
      final parts = _duration(now, finish!).split(' ');
      big = Text.rich(
        TextSpan(children: [
          for (var k = 0; k < parts.length; k++)
            TextSpan(
              text: k == parts.length - 1 ? parts[k] : '${parts[k]} ',
              style: int.tryParse(parts[k]) != null ? bigStyle : unitStyle,
            ),
        ]),
      );
    } else {
      big = FxProgress(
        value: perPeriod,
        builder: (_, v) => Text.rich(TextSpan(children: [
          TextSpan(text: '${_baht(v == perPeriod ? v : v.roundToDouble())} ', style: bigStyle),
          TextSpan(text: '/${_period.th}', style: unitStyle),
        ])),
      );
    }

    Widget tile(String label, String value) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: heroText.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: heroMuted)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: heroText)),
                ),
              ],
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: theme.heroGradient, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(headline, style: TextStyle(fontSize: 12.5, color: heroMuted)),
          const SizedBox(height: 10),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: big),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(note, style: TextStyle(fontSize: 13, color: heroMuted, height: 1.4)),
          ],
          if (ok && sim.periods > 0) ...[
            const SizedBox(height: 14),
            Row(children: [
              tile('ยอดที่ต้องเก็บเพิ่ม', _baht(remaining)),
              const SizedBox(width: 8),
              tile('คาดว่าจะสำเร็จ', _monthYear(finish!)),
            ]),
            if (sim.growth > 0) ...[
              const SizedBox(height: 8),
              Row(children: [
                tile('ฝากรวม', _baht(sim.deposited)),
                const SizedBox(width: 8),
                tile('ผลตอบแทน', _baht(sim.growth)),
              ]),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildEquivalents(AppThemeModel theme, bool isDark, double perPeriod) {
    final perDay = perPeriod / SavingGoalItem.daysPerPeriod(_period.key);
    final rows = [
      ('ต่อวัน', perDay),
      ('ต่อสัปดาห์', perDay * 7),
      ('ต่อเดือน', perDay * 30.4375),
      ('ต่อปี', perDay * 365.25),
    ];
    return _card(
      theme,
      isDark,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('เทียบให้เห็นภาพ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: theme.textColor)),
          const SizedBox(height: 2),
          Text('แผนเดียวกัน คิดเป็นเงินออม', style: TextStyle(fontSize: 12.5, color: theme.textSecondaryColor)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final r in rows) ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(color: theme.surfaceBackground, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Text(r.$1, style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(_baht(r.$2.roundToDouble()),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: theme.textColor)),
                        ),
                      ],
                    ),
                  ),
                ),
                if (r != rows.last) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text('ตัวอย่าง: งดกาแฟแก้วละ ฿60 วันละแก้ว = ออมได้เดือนละ ~${_baht((60 * 30.4375).roundToDouble())}',
              style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
        ],
      ),
    );
  }

  Widget _buildMilestones(AppThemeModel theme, bool isDark, double target, double start, SavingPlanResult sim) {
    final now = DateTime.now();
    final labels = {0.25: 'ของเป้าหมาย', 0.5: 'ครึ่งทางแล้ว', 0.75: 'ใกล้ถึงเป้า', 1.0: 'บรรลุเป้าหมาย'};
    final line = theme.primaryColor.withValues(alpha: 0.2);
    var nextMarked = false;
    final rows = <Widget>[];
    for (final pct in labels.keys) {
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
      final filled = reached || !nextMarked;
      if (!reached) nextMarked = true;
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 20,
              child: Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(top: 3),
                    decoration: BoxDecoration(
                      color: filled ? theme.primaryColor : Colors.transparent,
                      shape: BoxShape.circle,
                      border: filled ? null : Border.all(color: theme.primaryColor, width: 2),
                    ),
                    child: reached ? const Icon(Icons.check_rounded, size: 10, color: Colors.white) : null,
                  ),
                  if (!last) Expanded(child: Container(width: 2, color: line)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: last ? 0 : 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(text: '${(pct * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.w700)),
                          TextSpan(text: ' ${labels[pct]} • ${_baht(amount)}'),
                        ]),
                        style: TextStyle(fontSize: 13.5, color: theme.textColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      reached ? 'ถึงแล้ว' : (date == null ? '-' : _monthYear(date)),
                      style: TextStyle(
                        fontSize: 13.5,
                        color: reached ? theme.primaryColor : theme.textSecondaryColor,
                        fontWeight: reached ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ));
    }
    return _card(
      theme,
      isDark,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('เส้นทางความสำเร็จ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: theme.textColor)),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _bottomBar(AppThemeModel theme, VoidCallback? onCreate) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(top: BorderSide(color: theme.borderColor)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: SafeArea(
        top: false,
        child: FilledButton(
          onPressed: onCreate,
          style: FilledButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: const Text('สร้างเป็นเป้าหมายการออม', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
        ),
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
  Widget _card(AppThemeModel theme, bool isDark, Widget child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: isDark ? Border.all(color: theme.borderColor) : null,
          boxShadow: isDark ? null : const [BoxShadow(color: Color(0x0F0F172A), blurRadius: 14, offset: Offset(0, 4))],
        ),
        child: child,
      );

  Widget _label(String t, AppThemeModel theme) =>
      Text(t, style: TextStyle(fontSize: 13, color: theme.textSecondaryColor));

  Widget _field(TextEditingController c, String label, AppThemeModel theme,
      {String prefix = '', String? suffix, bool highlight = false}) {
    OutlineInputBorder border(Color color) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color, width: 1.5));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(label, theme),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: theme.textColor, fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            isDense: true,
            prefixText: prefix.isEmpty ? null : prefix,
            prefixStyle: TextStyle(color: theme.textSecondaryColor, fontSize: 16, fontWeight: FontWeight.w600),
            suffixText: suffix,
            filled: true,
            fillColor: theme.cardBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: border(theme.borderColor),
            enabledBorder: border(highlight ? theme.primaryColor : theme.borderColor),
            focusedBorder: border(theme.primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _segmented(AppThemeModel theme, bool isDark, List<(String, bool, VoidCallback)> options) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final o in options) ...[
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  o.$3();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  constraints: const BoxConstraints(minHeight: 44),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: o.$2 ? theme.cardBackground : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow:
                        o.$2 ? const [BoxShadow(color: Color(0x1A0F172A), blurRadius: 4, offset: Offset(0, 1))] : null,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(o.$1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: o.$2 ? FontWeight.w600 : FontWeight.w400,
                            color: o.$2 ? (isDark ? theme.textColor : theme.primaryColor) : theme.textColor)),
                  ),
                ),
              ),
            ),
            if (o != options.last) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}
