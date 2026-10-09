import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/account_item.dart';
import '../state/expense_controller.dart';
import '../widgets/meow_fx.dart';
import '../utils/format_utils.dart';

class SalaryAutoRecordScreen extends StatefulWidget {
  final ExpenseController controller;

  const SalaryAutoRecordScreen({super.key, required this.controller});

  @override
  State<SalaryAutoRecordScreen> createState() => _SalaryAutoRecordScreenState();
}

class _SalaryAutoRecordScreenState extends State<SalaryAutoRecordScreen> {
  late bool _isEnabled;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late int _dayOfMonth;
  late bool _isLastDayOfMonth;
  late String _selectedAccountId;
  late String _selectedCategoryId;

  static const _amountChips = [15000, 20000, 25000, 30000, 40000, 50000];
  static const _dayChips = [25, 26, 27, 28, 30, 1, 5, 10, 15];

  ExpenseController get _ctl => widget.controller;

  @override
  void initState() {
    super.initState();
    final cfg = _ctl.salaryConfig;
    _isEnabled = cfg.isEnabled;
    _amountController = TextEditingController(
      text: cfg.amount > 0 ? CurrencyFormat.format(cfg.amount, trimZero: true) : '',
    );
    _noteController = TextEditingController(text: cfg.note);
    _dayOfMonth = cfg.dayOfMonth;
    _isLastDayOfMonth = cfg.isLastDayOfMonth;

    // Check if account exists
    if (_ctl.accounts.any((a) => a.id == cfg.accountId)) {
      _selectedAccountId = cfg.accountId;
    } else if (_ctl.accounts.isNotEmpty) {
      _selectedAccountId = _ctl.accounts.first.id;
    } else {
      _selectedAccountId = 'acc_cash';
    }

    _selectedCategoryId = cfg.categoryId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double _parseAmount() {
    final clean = _amountController.text.replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  String _baht(double v) => '฿${CurrencyFormat.format(v, trimZero: true)}';

  String get _note => _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : 'เงินเดือนประจำเดือน';

  bool get _dirty {
    final cfg = _ctl.salaryConfig;
    return cfg.isEnabled != _isEnabled ||
        cfg.amount != _parseAmount() ||
        cfg.dayOfMonth != _dayOfMonth ||
        cfg.isLastDayOfMonth != _isLastDayOfMonth ||
        cfg.accountId != _selectedAccountId ||
        cfg.categoryId != _selectedCategoryId ||
        cfg.note != _note;
  }

  /// Next date the controller will record, following the same rules as checkAndProcessRecurringSalary.
  DateTime _nextRun() {
    final now = DateTime.now();
    int dayIn(int y, int m) {
      final dim = DateTime(y, m + 1, 0).day;
      return _isLastDayOfMonth ? dim : _dayOfMonth.clamp(1, dim);
    }

    final thisMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    if (_ctl.salaryConfig.lastRecordedMonth == thisMonth) {
      final n = DateTime(now.year, now.month + 1, 1);
      return DateTime(n.year, n.month, dayIn(n.year, n.month));
    }
    final d = dayIn(now.year, now.month);
    // Already past the day but not recorded yet: it is recorded the next time the app checks (today).
    return DateTime(now.year, now.month, now.day > d ? now.day : d);
  }

  String _accName(String id) {
    for (final a in _ctl.accounts) {
      if (a.id == id) return a.name;
    }
    return '-';
  }

  Future<void> _saveConfig() async {
    HapticFeedback.mediumImpact();
    final amount = _parseAmount();
    final currentCfg = _ctl.salaryConfig;

    final updated = currentCfg.copyWith(
      isEnabled: _isEnabled,
      amount: amount,
      dayOfMonth: _dayOfMonth,
      isLastDayOfMonth: _isLastDayOfMonth,
      accountId: _selectedAccountId,
      categoryId: _selectedCategoryId,
      note: _note,
    );

    await _ctl.updateSalaryAutoRecordConfig(updated);

    if (mounted) {
      _calmToast(
        context,
        _isEnabled ? 'บันทึกการตั้งค่าแล้ว • ครั้งถัดไป ${FormatUtils.formatDateThai(_nextRun())}' : 'ปิดบันทึกเงินเดือนอัตโนมัติแล้ว',
      );
      Navigator.pop(context);
    }
  }

  Future<void> _testRecordNow() async {
    final amount = _parseAmount();
    final c = _C.of(_ctl);
    if (amount <= 0) {
      _calmToast(context, 'กรุณากรอกจำนวนเงินเดือนที่ถูกต้องก่อนบันทึก', error: true);
      return;
    }
    String catName = 'เงินเดือน';
    for (final cat in _ctl.incomeCategories) {
      if (cat.id == _selectedCategoryId) catName = cat.name;
    }
    final now = DateTime.now();
    final dim = DateTime(now.year, now.month + 1, 0).day;
    final autoDay = _isLastDayOfMonth ? dim : _dayOfMonth.clamp(1, dim);

    Widget kv(String k, String v, {Color? color}) => Container(
          height: 42,
          decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
          child: Row(children: [
            Text(k, style: TextStyle(fontSize: 13.5, color: c.sub)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(v,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color ?? c.text)),
            ),
          ]),
        );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: c.card,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('บันทึกเงินเดือนเข้าตอนนี้?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.text)),
              const SizedBox(height: 6),
              Text('จะสร้างรายการรายรับจริง 1 รายการ และเพิ่มยอดบัญชีทันที', style: TextStyle(fontSize: 13.5, height: 1.45, color: c.sub)),
              const SizedBox(height: 12),
              kv('จำนวนเงิน', '+${_baht(amount)}', color: c.ok),
              kv('วันที่', '${FormatUtils.formatDateThai(now)} (วันนี้)'),
              kv('เข้าบัญชี', _accName(_selectedAccountId)),
              kv('หมวด', catName),
              Container(
                padding: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
                child: Text('รอบอัตโนมัติวันที่ $autoDay จะข้ามเดือนนี้ให้ เพื่อไม่ให้บันทึกซ้ำ',
                    style: TextStyle(fontSize: 12.5, height: 1.45, color: c.sub)),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: _outlineButton(c, 'ยกเลิก', () => Navigator.pop(ctx, false))),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const FittedBox(fit: BoxFit.scaleDown, child: Text('บันทึกรายรับเลย', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final currentCfg = _ctl.salaryConfig;
      final updated = currentCfg.copyWith(
        isEnabled: _isEnabled,
        amount: amount,
        dayOfMonth: _dayOfMonth,
        isLastDayOfMonth: _isLastDayOfMonth,
        accountId: _selectedAccountId,
        categoryId: _selectedCategoryId,
        note: _note,
      );
      await _ctl.updateSalaryAutoRecordConfig(updated);
      final success = await _ctl.triggerManualSalaryRecord();
      if (mounted) {
        if (success) {
          _calmToast(context, 'บันทึกรายรับ ${_baht(amount)} เข้า ${_accName(_selectedAccountId)} แล้ว');
          setState(() {});
        } else {
          _calmToast(context, 'ไม่สามารถบันทึกได้ กรุณาตรวจสอบข้อมูล', error: true);
        }
      }
    }
  }

  // --------------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ctl,
      builder: (context, _) {
        final c = _C.of(_ctl);
        final cfg = _ctl.salaryConfig;
        final amount = _parseAmount();
        final amtErr = _isEnabled && amount <= 0;
        final dirty = _dirty;
        var fx = 0;

        final String nextText;
        final Color nextColor;
        if (!_isEnabled) {
          nextText = 'ปิดอยู่ — จะไม่มีการบันทึกเงินเดือนอัตโนมัติ';
          nextColor = c.sub;
        } else if (amtErr) {
          nextText = 'ใส่จำนวนเงินเดือนก่อน จึงจะบันทึกให้ได้';
          nextColor = c.danger;
        } else {
          nextText = 'ครั้งถัดไป: ${FormatUtils.formatDateThai(_nextRun())} • ${_baht(amount)} เข้า ${_accName(_selectedAccountId)}';
          nextColor = c.text;
        }

        final form = <Widget>[
          // Amount
          _sectionLabel(c, 'จำนวนเงินเดือน (บาท)'),
          _calmCard(
            c,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _amountController,
                  onChanged: (_) => setState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: c.text, fontSize: 24, fontWeight: FontWeight.w700),
                  decoration: _inputDeco(c, prefix: '฿  ', hint: '0', error: amtErr),
                ),
                if (amtErr)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(children: [
                      Icon(Icons.error_outline_rounded, size: 16, color: c.danger),
                      const SizedBox(width: 6),
                      Expanded(child: Text('ใส่จำนวนเงินเดือนมากกว่า 0 บาท ก่อนบันทึก', style: TextStyle(fontSize: 12.5, color: c.danger))),
                    ]),
                  ),
                const SizedBox(height: 10),
                _grid(c, 3, [
                  for (final v in _amountChips)
                    _chip(c, _baht(v.toDouble()), amount == v, () {
                      HapticFeedback.selectionClick();
                      setState(() => _amountController.text = CurrencyFormat.format(v.toDouble(), trimZero: true));
                    }),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Day
          _sectionLabel(c, 'วันที่เงินเข้าของทุกเดือน',
              trailingWidget: Text(_isLastDayOfMonth ? 'ทุกวันสิ้นเดือน' : 'ทุกวันที่ $_dayOfMonth',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text))),
          _calmCard(
            c,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('วันที่คนนิยมใช้', style: TextStyle(fontSize: 12.5, color: c.sub)),
                const SizedBox(height: 8),
                _grid(c, 5, [
                  for (final d in _dayChips)
                    _chip(c, '$d', !_isLastDayOfMonth && _dayOfMonth == d, () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isLastDayOfMonth = false;
                        _dayOfMonth = d;
                      });
                    }, fontSize: 15),
                  _chip(c, 'สิ้นเดือน', _isLastDayOfMonth, () {
                    HapticFeedback.selectionClick();
                    setState(() => _isLastDayOfMonth = !_isLastDayOfMonth);
                  }, fontSize: 13),
                ]),
                if (_isLastDayOfMonth)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('สิ้นเดือน = วันที่ 28–31 ตามจำนวนวันของเดือนนั้นๆ', style: TextStyle(fontSize: 12.5, color: c.sub)),
                  ),
                const SizedBox(height: 12),
                Divider(height: 1, color: c.border),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: Text('หรือเลื่อนเลือกวันอื่น (1–31)', style: TextStyle(fontSize: 12.5, color: c.sub))),
                  Text(_isLastDayOfMonth ? 'ใช้สิ้นเดือนอยู่' : 'วันที่ $_dayOfMonth', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
                ]),
                Opacity(
                  opacity: _isLastDayOfMonth ? 0.45 : 1,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: c.accent,
                      inactiveTrackColor: c.line,
                      thumbColor: c.accent,
                      overlayColor: c.accent.withValues(alpha: 0.12),
                      trackHeight: 4,
                      showValueIndicator: ShowValueIndicator.never,
                      tickMarkShape: SliderTickMarkShape.noTickMark,
                    ),
                    child: Slider(
                      value: _dayOfMonth.toDouble().clamp(1, 31),
                      min: 1,
                      max: 31,
                      divisions: 30,
                      onChanged: (val) => setState(() {
                        _isLastDayOfMonth = false;
                        _dayOfMonth = val.round();
                      }),
                    ),
                  ),
                ),
                if (!_isLastDayOfMonth && _dayOfMonth > 28)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('เดือนที่ไม่มีวันที่ $_dayOfMonth จะบันทึกในวันสุดท้ายของเดือนแทน', style: TextStyle(fontSize: 12.5, color: c.sub)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Account
          _sectionLabel(c, 'รับเงินเดือนเข้าบัญชี'),
          _calmCard(
            c,
            child: _ctl.accounts.isEmpty
                ? Padding(padding: const EdgeInsets.all(16), child: Text('ยังไม่มีบัญชี — เพิ่มบัญชีในเมนู “บัญชี & กระเป๋าเงิน” ก่อน', style: c.subtitle))
                : Column(children: [
                    for (var i = 0; i < _ctl.accounts.length; i++) _accRow(c, _ctl.accounts[i], i == 0),
                  ]),
          ),
          const SizedBox(height: 18),
          // Category
          _sectionLabel(c, 'หมวดรายรับ', trailing: 'ใช้แยกดูในสถิติ'),
          _calmCard(
            c,
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in _ctl.incomeCategories)
                  _chip(c, cat.name, _selectedCategoryId == cat.id, () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategoryId = cat.id);
                  }, dot: cat.color, expand: false),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Note
          _sectionLabel(c, 'บันทึกช่วยจำ (ไม่บังคับ)'),
          TextField(
            controller: _noteController,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: c.text, fontSize: 15),
            decoration: _inputDeco(c, hint: 'เช่น เงินเดือนประจำเดือน'),
          ),
        ];

        return Scaffold(
          backgroundColor: c.page,
          appBar: _calmAppBar(context, c, 'บันทึกเงินเดือนอัตโนมัติ', subtitle: 'ถึงวันเงินเข้า แอปจะจดรายรับให้เองทุกเดือน'),
          bottomNavigationBar: _calmBottomBar(
            c,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (amtErr || dirty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(amtErr ? 'ใส่จำนวนเงินเดือนก่อนบันทึก' : 'มีการเปลี่ยนแปลงที่ยังไม่ได้บันทึก',
                        style: TextStyle(fontSize: 12.5, color: amtErr ? c.danger : c.sub)),
                  ),
                _primaryButton(c, 'บันทึกการตั้งค่า', amtErr ? null : _saveConfig),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              // Offline note
              FxFadeUp(
                index: fx++,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 20, color: c.icon),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ออฟไลน์ 100% ไม่ต้องต่อเน็ต', style: c.title.copyWith(fontSize: 14)),
                            Text('แอปจดเงินเดือนให้ในเครื่องคุณเองเมื่อถึงวันที่ตั้งไว้ ข้อมูลไม่ถูกส่งออกไปไหน', style: c.subtitle),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Switch + next run
              FxFadeUp(
                index: fx++,
                child: _calmCard(
                  c,
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isEnabled = !_isEnabled);
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('เปิดบันทึกเงินเดือนอัตโนมัติ', style: c.title),
                                    const SizedBox(height: 2),
                                    Text(
                                      _isEnabled
                                          ? 'เปิดอยู่ • ${_isLastDayOfMonth ? 'ทุกวันสิ้นเดือน' : 'ทุกวันที่ $_dayOfMonth'}'
                                          : 'ปิดอยู่ แอปจะไม่จดเงินเดือนให้',
                                      style: c.subtitle,
                                    ),
                                  ],
                                ),
                              ),
                              _calmSwitch(c, _isEnabled, (v) {
                                HapticFeedback.selectionClick();
                                setState(() => _isEnabled = v);
                              }),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 19, color: nextColor == c.text ? c.icon : nextColor),
                            const SizedBox(width: 10),
                            Expanded(child: Text(nextText, style: TextStyle(fontSize: 13.5, color: nextColor))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!_isEnabled)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
                  child: Text('ปิดอยู่ — เปิดสวิตช์ด้านบนก่อน จึงจะแก้การตั้งค่าด้านล่างได้', style: TextStyle(fontSize: 12.5, color: c.sub)),
                ),
              const SizedBox(height: 18),
              FxFadeUp(
                index: fx++,
                child: IgnorePointer(
                  ignoring: !_isEnabled,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isEnabled ? 1 : 0.45,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: form),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Last record + manual record
              FxFadeUp(
                index: fx++,
                child: _calmCard(
                  c,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.history_rounded, size: 22, color: c.icon),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('บันทึกล่าสุด:', style: TextStyle(fontSize: 12.5, color: c.sub)),
                                  Text(
                                    cfg.lastRecordedDate != null ? FormatUtils.formatDateThai(cfg.lastRecordedDate!) : 'ยังไม่เคยบันทึก',
                                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: c.text),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: c.border),
                      InkWell(
                        onTap: amount > 0 ? _testRecordNow : null,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(Icons.add_rounded, size: 22, color: amount > 0 ? c.link : c.faint),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text('บันทึกรายการเงินเดือนตอนนี้',
                                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: amount > 0 ? c.link : c.faint)),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              Text.rich(TextSpan(style: TextStyle(fontSize: 12.5, height: 1.45, color: c.sub), children: [
                                const TextSpan(text: 'สร้างรายการรายรับ'),
                                TextSpan(text: 'จริง', style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
                                TextSpan(text: ' ${_baht(amount)} ลงวันนี้ ใช้เมื่อเงินเข้าก่อนกำหนด (ไม่ใช่การทดสอบ)'),
                              ])),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Equal-width chips laid out [cols] per row.
  Widget _grid(_C c, int cols, List<Widget> children) => LayoutBuilder(
        builder: (context, box) {
          const gap = 8.0;
          final w = (box.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(spacing: gap, runSpacing: gap, children: [for (final ch in children) SizedBox(width: w, child: ch)]);
        },
      );

  Widget _chip(_C c, String label, bool sel, VoidCallback onTap, {double fontSize = 14, Color? dot, bool expand = true}) => Material(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: sel ? c.accent : c.line, width: sel ? 1.5 : 1),
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (dot != null) ...[
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label,
                        style: TextStyle(fontSize: fontSize, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? c.link : c.icon)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _accRow(_C c, AccountItem acc, bool first) {
    final sel = _selectedAccountId == acc.id;
    final icon = acc.type == AccountType.cash
        ? Icons.payments_outlined
        : acc.type == AccountType.eWallet
            ? Icons.phone_iphone_rounded
            : Icons.account_balance_outlined;
    final kind = acc.type == AccountType.cash ? 'เงินสด' : (acc.type == AccountType.eWallet ? 'e-Wallet' : 'บัญชีธนาคาร');
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedAccountId = acc.id);
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: c.icon),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 62),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: c.border))),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(acc.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: c.title),
                          Text('$kind • คงเหลือ ${_baht(acc.balance)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: c.subtitle),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: sel ? c.accent : c.faint, width: sel ? 2 : 1.5),
                      ),
                      alignment: Alignment.center,
                      child: sel ? Container(width: 10, height: 10, decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle)) : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Calm monochrome menu-page kit (same look as the menu home). Private copy so
// this screen stays self-contained.
// ---------------------------------------------------------------------------

class _C {
 final Color page, text, sub, icon, faint, card, line, border, seg, accent, link, ok, okText, danger, dangerText, vip, vipLine, disabled;
 final bool dark;

 const _C({
  required this.page,
  required this.text,
  required this.sub,
  required this.icon,
  required this.faint,
  required this.card,
  required this.line,
  required this.border,
  required this.seg,
  required this.accent,
  required this.link,
  required this.ok,
  required this.okText,
  required this.danger,
  required this.dangerText,
  required this.vip,
  required this.vipLine,
  required this.disabled,
  required this.dark,
 });

 factory _C.of(ExpenseController ctl) {
  final t = ctl.currentTheme;
  final dark = ctl.isDarkMode;
  return _C(
   page: t.scaffoldBackground,
   text: t.textColor,
   sub: t.textSecondaryColor,
   icon: dark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
   faint: dark ? Colors.white24 : const Color(0xFFB6BECB),
   card: t.cardBackground,
   line: t.borderColor,
   border: dark ? Colors.white10 : const Color(0xFFEEF0F4),
   seg: dark ? const Color(0xFF0F172A) : const Color(0xFFF1F3F8),
   accent: t.primaryColor,
   link: dark ? const Color(0xFF93C5FD) : t.primaryColor,
   ok: dark ? const Color(0xFF34D399) : const Color(0xFF059669),
   okText: dark ? const Color(0xFF34D399) : const Color(0xFF047857),
   danger: dark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
   dangerText: dark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
   vip: dark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
   vipLine: dark ? const Color(0xFF6B5A1E) : const Color(0xFFE9C98B),
   disabled: dark ? Colors.white12 : const Color(0xFFA5B4CF),
   dark: dark,
  );
 }

 TextStyle get title => TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: text);
 TextStyle get subtitle => TextStyle(fontSize: 12.5, height: 1.35, color: sub);
}

/// White app bar: 44px back chevron, 18/700 title, optional 12px subtitle, optional [bottom] (e.g. a segmented control), 1px bottom line.
PreferredSizeWidget _calmAppBar(BuildContext context, _C c, String title,
  {String? subtitle, List<Widget> actions = const [], Widget? bottom, double bottomHeight = 0}) {
 return PreferredSize(
  preferredSize: Size.fromHeight(61 + bottomHeight),
  child: Material(
   color: c.card,
   child: SafeArea(
    bottom: false,
    child: Container(
     decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
     child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
       SizedBox(
        height: 60,
        child: Padding(
         padding: const EdgeInsets.only(left: 6, right: 8),
         child: Row(
          children: [
           SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
             tooltip: 'ย้อนกลับ',
             padding: EdgeInsets.zero,
             icon: Icon(Icons.chevron_left_rounded, size: 28, color: c.text),
             onPressed: () => Navigator.maybePop(context),
            ),
           ),
           const SizedBox(width: 6),
           Expanded(
            child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text)),
              if (subtitle != null)
               Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.sub)),
             ],
            ),
           ),
           ...actions,
          ],
         ),
        ),
       ),
       if (bottom != null) SizedBox(height: bottomHeight, child: bottom),
      ],
     ),
    ),
   ),
  ),
 );
}

/// Sticky bottom action bar (white, top border).
Widget _calmBottomBar(_C c, Widget child) => Container(
      decoration: BoxDecoration(color: c.card, border: Border(top: BorderSide(color: c.line))),
      child: SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), child: child)),
     );

/// Full-width 52px accent button; null [onTap] shows the disabled look.
Widget _primaryButton(_C c, String label, VoidCallback? onTap, {IconData? icon, Color? color, bool busy = false}) {
 final bg = onTap == null ? c.disabled : (color ?? c.accent);
 return SizedBox(
  width: double.infinity,
  height: 52,
  child: ElevatedButton(
   onPressed: busy ? null : onTap,
   style: ElevatedButton.styleFrom(
    backgroundColor: bg,
    disabledBackgroundColor: busy ? bg : c.disabled,
    foregroundColor: Colors.white,
    disabledForegroundColor: Colors.white.withValues(alpha: 0.9),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
   ),
   child: busy
       ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
       : Row(
           mainAxisSize: MainAxisSize.min,
           children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
           ],
          ),
  ),
 );
}

/// Outlined secondary button (44px+).
Widget _outlineButton(_C c, String label, VoidCallback? onTap, {IconData? icon, Color? color, double height = 48}) {
 final fg = color ?? c.text;
 return SizedBox(
  height: height,
  child: OutlinedButton(
   onPressed: onTap,
   style: OutlinedButton.styleFrom(
    foregroundColor: fg,
    side: BorderSide(color: c.line),
    backgroundColor: c.card,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
   ),
   child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
     if (icon != null) ...[Icon(icon, size: 19, color: fg), const SizedBox(width: 8)],
     Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg))),
    ],
   ),
  ),
 );
}

/// 1px-bordered card, radius 16.
Widget _calmCard(_C c, {required Widget child, EdgeInsetsGeometry? padding}) => Container(
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.line)),
      clipBehavior: Clip.antiAlias,
      child: Material(color: Colors.transparent, child: padding == null ? child : Padding(padding: padding, child: child)),
     );

/// 13px/600 grey label above a card group, with an optional right-hand value.
Widget _sectionLabel(_C c, String title, {String? trailing, Widget? trailingWidget}) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
       children: [
        Expanded(child: Text(title, style: TextStyle(color: c.sub, fontSize: 13, fontWeight: FontWeight.w600))),
        if (trailing != null) Text(trailing, style: TextStyle(color: c.sub, fontSize: 13, fontFeatures: const [FontFeature.tabularFigures()])),
        ?trailingWidget,
       ],
      ),
     );

/// Toggle switch in the accent colour.
Widget _calmSwitch(_C c, bool value, ValueChanged<bool>? onChanged) => Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: c.accent,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: c.dark ? Colors.white24 : const Color(0xFFCBD5E1),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
     );

InputDecoration _inputDeco(_C c, {String? hint, String? prefix, bool error = false, Widget? prefixIcon, Widget? suffixIcon}) {
 OutlineInputBorder b(Color col, [double w = 1]) => OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: col, width: w));
 return InputDecoration(
  isDense: true,
  hintText: hint,
  hintStyle: TextStyle(color: c.sub.withValues(alpha: 0.8), fontSize: 14.5, fontWeight: FontWeight.w400),
  // Shown as an icon so the prefix (e.g. ฿) stays visible while the field is empty.
  prefixIcon: prefixIcon ??
    (prefix == null
      ? null
      : Padding(
        padding: const EdgeInsets.only(left: 14, right: 8),
        child: Text(prefix.trim(), style: TextStyle(color: c.sub, fontSize: 16, fontWeight: FontWeight.w600)),
       )),
  prefixIconConstraints: prefix != null && prefixIcon == null ? const BoxConstraints(minWidth: 0, minHeight: 0) : null,
  suffixIcon: suffixIcon,
  filled: true,
  fillColor: c.card,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  enabledBorder: b(error ? c.danger : c.line),
  focusedBorder: b(error ? c.danger : c.accent, 1.5),
  border: b(c.line),
 );
}

/// Dark floating toast with an optional action (e.g. เลิกทำ).
void _calmToast(BuildContext context, String msg, {bool error = false, String? actionLabel, VoidCallback? onAction}) {
 final m = ScaffoldMessenger.of(context);
 m.hideCurrentSnackBar();
 m.showSnackBar(SnackBar(
  content: Text(msg, style: const TextStyle(fontSize: 13.5, color: Colors.white)),
  behavior: SnackBarBehavior.floating,
  backgroundColor: error ? const Color(0xFFB91C1C) : const Color(0xFF0F172A),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  duration: Duration(seconds: actionLabel != null ? 5 : 3),
  action: actionLabel == null ? null : SnackBarAction(label: actionLabel, textColor: const Color(0xFF93C5FD), onPressed: onAction ?? () {}),
 ));
}
