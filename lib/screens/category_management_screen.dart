import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../models/category_item.dart';
import '../models/transaction_item.dart';
import '../widgets/meow_fx.dart';

class CategoryManagementScreen extends StatefulWidget {
  final ExpenseController controller;

  const CategoryManagementScreen({super.key, required this.controller});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  CategoryType _tab = CategoryType.expense;

  static const List<int> _colorPalette = [
    0xFFEF4444, 0xFFF97316, 0xFFF59E0B, 0xFFEAB308, 0xFF84CC16, 0xFF22C55E, 0xFF10B981, 0xFF14B8A6, //
    0xFF06B6D4, 0xFF0EA5E9, 0xFF3B82F6, 0xFF6366F1, 0xFF8B5CF6, 0xFFA855F7, 0xFFD946EF, 0xFFEC4899, //
    0xFFF43F5E, 0xFFB45309, 0xFF78716C, 0xFF94A3B8, 0xFF64748B, 0xFF065F46, 0xFF1E3A8A, 0xFF9D174D,
  ];

  ExpenseController get _ctl => widget.controller;
  bool get _en => _ctl.isEnglish;
  String _t(String th, String en) => _en ? en : th;

  String _typeLabel(CategoryType t) => t == CategoryType.expense ? _t('รายจ่าย', 'expense') : _t('รายรับ', 'income');

  bool _uses(TransactionItem tx, CategoryItem cat) {
    final kindOk = cat.type == CategoryType.expense ? tx.type == TransactionType.expense : tx.type == TransactionType.income;
    if (!kindOk) return false;
    return tx.categoryId == cat.id || tx.categoryName == cat.name;
  }

  int _monthCount(CategoryItem cat) {
    final now = DateTime.now();
    return _ctl.transactions.where((t) => t.date.year == now.year && t.date.month == now.month && _uses(t, cat)).length;
  }

  String _metaText(int n) => n > 0 ? _t('$n รายการเดือนนี้', '$n this month') : _t('ยังไม่มีรายการเดือนนี้', 'Nothing this month');

  // ------------------------------------------------------------ add / edit sheet
  void _openSheet({CategoryItem? existing, required CategoryType type}) {
    final c = _C.of(_ctl);
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    var iconKey = existing?.iconKey ?? (type == CategoryType.income ? 'payments' : 'restaurant');
    var color = existing?.colorValue ?? (type == CategoryType.income ? 0xFF10B981 : 0xFFF97316);
    var touched = false;
    final groups = CategoryCatalog.iconGroups;
    var group = groups.indexWhere((g) => g.icons.any((i) => i.key == iconKey));
    if (group < 0) group = 0;
    final label = _typeLabel(type);

    _showCalmSheet<void>(
      context,
      c,
      title: isEdit ? _t('แก้ไขหมวดหมู่', 'Edit category') : _t('หมวดหมู่$labelใหม่', 'New $label category'),
      subtitle: isEdit
          ? '${_t('หมวด$label', _en ? 'Category' : '')} • ${_metaText(_monthCount(existing))}'
          : _t('ตั้งชื่อ เลือกสีและไอคอน', 'Name it, pick a colour and icon'),
      builder: (ctx, setSheet) {
        final list = type == CategoryType.expense ? _ctl.expenseCategories : _ctl.incomeCategories;
        final name = nameCtrl.text.trim();
        final dup = list.any((x) => x.name == name && x.id != existing?.id);
        final nameErr = (touched && name.isEmpty) || dup;
        final canSave = name.isNotEmpty && !dup;
        final pos = isEdit ? list.indexWhere((x) => x.id == existing.id) : -1;

        Future<void> move(int d) async {
          final j = pos + d;
          if (pos < 0 || j < 0 || j >= list.length) return;
          HapticFeedback.selectionClick();
          await _ctl.reorderCategories(type, pos, d > 0 ? j + 1 : j);
          setSheet(() {});
        }

        Widget arrow(IconData icon, bool enabled, VoidCallback onTap, String tip) => SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                tooltip: tip,
                onPressed: enabled ? onTap : null,
                icon: Icon(icon, size: 24, color: enabled ? c.icon : c.faint),
              ),
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _fieldLabel(c, _t('ชื่อหมวดหมู่', 'Category name')),
            TextField(
              controller: nameCtrl,
              onChanged: (_) => setSheet(() => touched = true),
              style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w500),
              decoration: _inputDeco(
                c,
                hint: _t('เช่น อาหาร, ค่าน้ำมัน, ช้อปปิ้ง', 'e.g. Coffee, Taxi, Rent'),
                error: nameErr,
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 10),
                  child: Center(widthFactor: 1, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(color), shape: BoxShape.circle))),
                ),
              ),
            ),
            if (nameErr)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(dup ? _t('มีหมวดชื่อนี้แล้ว ลองใช้ชื่ออื่น', 'That name is taken') : _t('กรุณาใส่ชื่อหมวดหมู่', 'Please enter a name'),
                    style: TextStyle(fontSize: 12.5, color: c.danger)),
              ),
            if (isEdit && pos >= 0) ...[
              const SizedBox(height: 12),
              _calmCard(
                c,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text.rich(TextSpan(style: TextStyle(fontSize: 14, color: c.text), children: [
                          TextSpan(text: _t('ลำดับที่ ', 'Position ')),
                          TextSpan(text: '${pos + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          TextSpan(text: _t(' จาก ${list.length}', ' of ${list.length}')),
                        ])),
                      ),
                      arrow(Icons.keyboard_arrow_up_rounded, pos > 0, () => move(-1), _t('เลื่อนขึ้น', 'Move up')),
                      arrow(Icons.keyboard_arrow_down_rounded, pos < list.length - 1, () => move(1), _t('เลื่อนลง', 'Move down')),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text(_t('สี', 'Colour'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text))),
                TextButton.icon(
                  style: TextButton.styleFrom(minimumSize: const Size(44, 44), foregroundColor: c.link),
                  onPressed: () => _showCustomColorPicker(
                    c,
                    initialColor: Color(color),
                    onColorSelected: (nc) => setSheet(() => color = nc.toARGB32()),
                  ),
                  icon: Icon(Icons.palette_outlined, size: 19, color: c.link),
                  label: Text(_t('กำหนดสีเอง', 'Custom colour'), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: c.link)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LayoutBuilder(builder: (context, box) {
              final size = ((box.maxWidth - 7 * 8) / 8).clamp(28.0, 44.0);
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final col in _colorPalette)
                    Semantics(
                      button: true,
                      selected: col == color,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setSheet(() => color = col);
                        },
                        child: Container(
                          width: size,
                          height: size,
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: col == color ? c.text : Colors.transparent, width: 2),
                          ),
                          child: Container(decoration: BoxDecoration(color: Color(col), shape: BoxShape.circle)),
                        ),
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(height: 16),
            Text(_t('ไอคอน', 'Icon'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: c.seg, borderRadius: BorderRadius.circular(12)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var gi = 0; gi < groups.length; gi++)
                      Material(
                        color: gi == group ? c.card : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        elevation: 0,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(9),
                          onTap: () => setSheet(() => group = gi),
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            child: Text(
                              _en ? groups[gi].titleEn : groups[gi].title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: gi == group ? FontWeight.w600 : FontWeight.w400,
                                color: gi == group ? c.link : c.sub,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (context, box) {
              final size = ((box.maxWidth - 7 * 6) / 8).clamp(36.0, 48.0);
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final item in groups[group].icons)
                    Tooltip(
                      message: item.label,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setSheet(() => iconKey = item.key);
                        },
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: item.key == iconKey ? c.accent : Colors.transparent, width: 1.5),
                          ),
                          child: Icon(item.icon, size: 22, color: item.key == iconKey ? c.link : c.icon),
                        ),
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(height: 18),
            _primaryButton(
              c,
              isEdit ? _t('บันทึกการแก้ไข', 'Save changes') : _t('สร้างหมวดหมู่ใหม่', 'Create category'),
              () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty || list.any((x) => x.name == name && x.id != existing?.id)) {
                  setSheet(() => touched = true);
                  return;
                }
                if (isEdit) {
                  _ctl.updateCategory(existing.copyWith(name: name, iconKey: iconKey, colorValue: color));
                } else {
                  _ctl.addCategory(CategoryItem(
                    id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    iconKey: iconKey,
                    colorValue: color,
                    type: type,
                    isDefault: false,
                  ));
                }
                HapticFeedback.mediumImpact();
                Navigator.pop(ctx);
                _calmToast(context, isEdit ? _t('บันทึก “$name” แล้ว', 'Saved “$name”') : _t('สร้างหมวด “$name” แล้ว', 'Created “$name”'));
              },
              color: canSave ? null : c.disabled,
            ),
            if (isEdit) ...[
              const SizedBox(height: 6),
              SizedBox(
                height: 48,
                child: TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _confirmDelete(existing);
                  },
                  icon: Icon(Icons.delete_outline_rounded, size: 20, color: c.danger),
                  label: Text(_t('ลบหมวดหมู่นี้', 'Delete this category'), style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: c.danger)),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------- delete flow
  Future<void> _confirmDelete(CategoryItem cat) async {
    final c = _C.of(_ctl);
    final list = cat.type == CategoryType.expense ? _ctl.expenseCategories : _ctl.incomeCategories;
    final others = list.where((x) => x.id != cat.id).toList();
    final used = _ctl.transactions.where((t) => _uses(t, cat)).toList();
    CategoryItem? target = others.isEmpty
        ? null
        : others.firstWhere((x) => x.name == 'อื่นๆ' || x.name == 'รายได้อื่น' || x.id == 'other', orElse: () => others.last);

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Icon(Icons.delete_outline_rounded, size: 24, color: c.danger),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_t('ลบหมวด “${cat.name}” ?', 'Delete “${cat.name}”?'),
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.text)),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  if (used.isNotEmpty && others.isNotEmpty) ...[
                    _calmCard(
                      c,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 20, color: c.danger),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(TextSpan(style: TextStyle(fontSize: 13.5, height: 1.45, color: c.text), children: [
                              TextSpan(text: _t('มี ${used.length} รายการใช้หมวดนี้', '${used.length} entries use this category'), style: const TextStyle(fontWeight: FontWeight.w700)),
                              TextSpan(text: _t(' — ย้ายไปหมวดอื่นก่อนลบ เพื่อไม่ให้รายการหายจากสถิติ', ' — move them first so they stay in your stats')),
                            ])),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(_t('ย้ายรายการไปหมวด', 'Move entries to'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.sub)),
                    const SizedBox(height: 8),
                    LayoutBuilder(builder: (context, box) {
                      final w = (box.maxWidth - 16) / 3;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final o in others)
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => setSheet(() => target = o),
                              child: Container(
                                width: w,
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: c.card,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: o.id == target?.id ? c.accent : c.line, width: o.id == target?.id ? 1.5 : 1),
                                ),
                                child: Row(children: [
                                  Container(width: 8, height: 8, decoration: BoxDecoration(color: o.color, shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(o.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: o.id == target?.id ? FontWeight.w600 : FontWeight.w400,
                                          color: o.id == target?.id ? c.link : c.icon,
                                        )),
                                  ),
                                ]),
                              ),
                            ),
                        ],
                      );
                    }),
                  ] else if (used.isNotEmpty)
                    Text(_t('ไม่มีหมวดอื่นให้ย้าย รายการ ${used.length} รายการจะกลายเป็น “ไม่ระบุหมวด”', 'No other category to move to; ${used.length} entries will be uncategorised'),
                        style: TextStyle(fontSize: 13.5, height: 1.45, color: c.sub))
                  else
                    Text(_t('ยังไม่มีรายการใช้หมวดนี้ ลบได้ทันทีโดยไม่กระทบสถิติ', 'No entries use this category, so your stats stay the same'),
                        style: TextStyle(fontSize: 13.5, height: 1.45, color: c.sub)),
                  const SizedBox(height: 18),
                  Row(children: [
                    Expanded(child: _outlineButton(c, _t('ยกเลิก', 'Cancel'), () => Navigator.pop(ctx, false), height: 50)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.danger,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            used.isNotEmpty && target != null
                                ? _t('ย้าย ${used.length} รายการ แล้วลบ', 'Move ${used.length} & delete')
                                : _t('ลบหมวดหมู่', 'Delete category'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (ok != true) return;

    final index = list.indexWhere((x) => x.id == cat.id);
    final moved = <TransactionItem>[];
    final dest = target;
    if (dest != null) {
      for (final tx in used) {
        moved.add(tx);
        await _ctl.updateTransaction(tx.copyWith(categoryId: dest.id, categoryName: dest.name));
      }
    }
    await _ctl.deleteCategory(cat.id);
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    final msg = _t('ลบหมวด “${cat.name}” แล้ว', 'Deleted “${cat.name}”') +
        (moved.isNotEmpty && dest != null ? _t(' • ย้าย ${moved.length} รายการไป “${dest.name}”', ' • moved ${moved.length} to “${dest.name}”') : '');
    _calmToast(context, msg, actionLabel: _t('เลิกทำ', 'Undo'), onAction: () async {
      await _ctl.addCategory(cat);
      final now = cat.type == CategoryType.expense ? _ctl.expenseCategories : _ctl.incomeCategories;
      final from = now.indexWhere((x) => x.id == cat.id);
      if (from >= 0 && index >= 0 && from != index) await _ctl.reorderCategories(cat.type, from, index);
      for (final tx in moved) {
        await _ctl.updateTransaction(tx);
      }
      if (mounted) _calmToast(context, _t('กู้คืนหมวดหมู่แล้ว', 'Category restored'));
    });
  }

  void _showCustomColorPicker(_C c, {required Color initialColor, required ValueChanged<Color> onColorSelected}) {
    double r = (initialColor.r * 255).roundToDouble();
    double g = (initialColor.g * 255).roundToDouble();
    double b = (initialColor.b * 255).roundToDouble();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setPickerState) {
          final current = Color.fromARGB(255, r.toInt(), g.toInt(), b.toInt());
          Widget slider(String l, double v, ValueChanged<double> on) => Row(children: [
                SizedBox(width: 18, child: Text(l, style: TextStyle(color: c.sub, fontWeight: FontWeight.w600))),
                Expanded(child: Slider(value: v, min: 0, max: 255, activeColor: c.accent, onChanged: on)),
                SizedBox(width: 32, child: Text('${v.toInt()}', style: TextStyle(fontSize: 12.5, color: c.sub))),
              ]);
          return AlertDialog(
            backgroundColor: c.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(_t('กำหนดสีเอง', 'Custom colour'), style: TextStyle(color: c.text, fontSize: 17, fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 48,
                    width: double.infinity,
                    decoration: BoxDecoration(color: current, borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: Text(
                      '#${current.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, shadows: [Shadow(color: Colors.black45, blurRadius: 4)]),
                    ),
                  ),
                  const SizedBox(height: 14),
                  slider('R', r, (v) => setPickerState(() => r = v)),
                  slider('G', g, (v) => setPickerState(() => g = v)),
                  slider('B', b, (v) => setPickerState(() => b = v)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_t('ยกเลิก', 'Cancel'), style: TextStyle(color: c.sub))),
              TextButton(
                onPressed: () {
                  onColorSelected(current);
                  Navigator.pop(ctx);
                },
                child: Text(_t('ใช้สีนี้', 'Apply'), style: TextStyle(color: c.link, fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );
  }

  // --------------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ctl,
      builder: (context, _) {
        final c = _C.of(_ctl);
        final expenseCats = _ctl.expenseCategories;
        final incomeCats = _ctl.incomeCategories;
        final list = _tab == CategoryType.expense ? expenseCats : incomeCats;
        final label = _typeLabel(_tab);

        Widget seg(String text, CategoryType t) {
          final sel = _tab == t;
          return Expanded(
            child: Material(
              color: sel ? c.card : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _tab = t);
                },
                child: SizedBox(
                  height: 44,
                  child: Center(
                    child: Text(text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? c.link : c.sub)),
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: c.page,
          appBar: _calmAppBar(context, c, _t('หมวดหมู่รายรับ-รายจ่าย', 'Categories'),
              subtitle: _t('จัดลำดับ เพิ่ม แก้ไข หรือลบหมวดหมู่', 'Reorder, add, edit or delete')),
          bottomNavigationBar: _calmBottomBar(
            c,
            _primaryButton(c, _t('เพิ่มหมวดหมู่$label', 'Add $label category'), () => _openSheet(type: _tab), icon: Icons.add_rounded),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: c.seg, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  seg(_t('หมวดรายจ่าย (${expenseCats.length})', 'Expense (${expenseCats.length})'), CategoryType.expense),
                  seg(_t('หมวดรายรับ (${incomeCats.length})', 'Income (${incomeCats.length})'), CategoryType.income),
                ]),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.drag_indicator_rounded, size: 16, color: c.faint),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _t('แตะค้างที่จุดแล้วลากเพื่อจัดลำดับ • แตะหมวดเพื่อแก้ไขหรือลบ', 'Drag the dots to reorder • tap a category to edit or delete'),
                        style: TextStyle(fontSize: 12.5, color: c.sub),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (list.isEmpty)
                FxFadeUp(
                  key: ValueKey('empty_$_tab'),
                  child: _calmCard(
                    c,
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                    child: Column(
                      children: [
                        Icon(Icons.category_outlined, size: 32, color: c.sub),
                        const SizedBox(height: 10),
                        Text(_t('ยังไม่มีหมวด$label', 'No $label categories yet'), style: c.title),
                        const SizedBox(height: 4),
                        Text(_t('สร้างหมวดแรกไว้ แล้วตอนจดรายการจะเลือกหมวดได้ทันที', 'Create one and pick it when you add an entry'),
                            textAlign: TextAlign.center, style: c.subtitle),
                        const SizedBox(height: 14),
                        _outlineButton(c, _t('เพิ่มหมวดหมู่แรก', 'Add the first category'), () => _openSheet(type: _tab), icon: Icons.add_rounded),
                      ],
                    ),
                  ),
                )
              else
                FxFadeUp(
                  key: ValueKey('list_$_tab'),
                  index: 1,
                  child: _calmCard(
                    c,
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: list.length,
                      proxyDecorator: (child, i, anim) => Material(
                        color: c.card,
                        elevation: 4,
                        shadowColor: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                        child: child,
                      ),
                      onReorderItem: (oldIndex, newIndex) {
                        HapticFeedback.mediumImpact();
                        // The controller expects the classic (pre-removal) target index.
                        _ctl.reorderCategories(_tab, oldIndex, newIndex > oldIndex ? newIndex + 1 : newIndex);
                      },
                      itemBuilder: (context, i) => _row(c, list[i], i),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(_C c, CategoryItem cat, int index) {
    final n = _monthCount(cat);
    return Material(
      key: ValueKey(cat.id),
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          _openSheet(existing: cat, type: cat.type);
        },
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Semantics(
                label: _t('ลากเพื่อจัดลำดับ', 'Drag to reorder'),
                child: SizedBox(width: 44, height: 64, child: Icon(Icons.drag_indicator_rounded, size: 20, color: c.faint)),
              ),
            ),
            Container(width: 10, height: 10, decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 64),
                padding: const EdgeInsets.only(top: 10, bottom: 10, right: 10),
                decoration: BoxDecoration(border: index == 0 ? null : Border(top: BorderSide(color: c.border))),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(children: [
                            Flexible(child: Text(cat.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: c.title)),
                            if (!cat.isDefault) ...[const SizedBox(width: 8), Flexible(child: _pill(c, _t('กำหนดเอง', 'Custom')))],
                          ]),
                          const SizedBox(height: 2),
                          Text(_metaText(n), style: TextStyle(fontSize: 12.5, color: n > 0 ? c.sub : c.sub.withValues(alpha: 0.75))),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 22, color: c.faint),
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

/// Small outlined pill used for neutral status ("บัญชีหลัก", "VIP", "เปิดอยู่").
Widget _pill(_C c, String text, {Color? color, Color? border}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: border ?? c.line)),
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color ?? c.sub)),
     );

/// Label above an input: 13/600, optional grey suffix like "(ไม่บังคับ)".
Widget _fieldLabel(_C c, String label, {String? hint}) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(TextSpan(children: [
       TextSpan(text: label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text)),
       if (hint != null) TextSpan(text: ' $hint', style: TextStyle(fontSize: 13, color: c.sub)),
      ])),
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

/// Bottom sheet frame: grab handle, 18/700 title, optional subtitle, close button.
Future<T?> _showCalmSheet<T>(BuildContext context, _C c, {required String title, String? subtitle, required Widget Function(BuildContext ctx, StateSetter setSheet) builder}) {
 return showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  backgroundColor: c.card,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
  builder: (ctx) => StatefulBuilder(
   builder: (ctx, setSheet) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
    child: SafeArea(
     top: false,
     child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.9),
      child: SingleChildScrollView(
       padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
       child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
         Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(2)))),
         const SizedBox(height: 10),
         Row(
          children: [
           Expanded(
            child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text)),
              if (subtitle != null) Text(subtitle, style: TextStyle(fontSize: 12.5, color: c.sub)),
             ],
            ),
           ),
           SizedBox(
            width: 44,
            height: 44,
            child: IconButton(tooltip: 'ปิด', icon: Icon(Icons.close_rounded, size: 22, color: c.sub), onPressed: () => Navigator.pop(ctx)),
           ),
          ],
         ),
         const SizedBox(height: 12),
         builder(ctx, setSheet),
        ],
       ),
      ),
     ),
    ),
   ),
  ),
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
