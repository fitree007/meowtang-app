import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/faraid_engine.dart';
import '../state/expense_controller.dart';
import '../theme/app_theme_model.dart';
import '../utils/format_utils.dart';
import '../widgets/meow_fx.dart';

/// Inputs shown on the result page for the money breakdown of the first estate.
class FaraidEstateSummary {
  final double gross;
  final double funeral;
  final double debts;
  final double wasiyyah;
  final double net;

  /// Optional asset breakdown (name, value) that sums to [gross].
  final List<(String, double)> items;

  const FaraidEstateSummary({
    required this.gross,
    required this.funeral,
    required this.debts,
    required this.wasiyyah,
    required this.net,
    this.items = const [],
  });
}

/// Heir colours (dots, share bar), in draft order.
const List<Color> kHeirPalette = [
  Color(0xFF7C3AED),
  Color(0xFFF59E0B),
  Color(0xFF0F766E),
  Color(0xFFDB2777),
  Color(0xFF2563EB),
  Color(0xFF65A30D),
  Color(0xFFEA580C),
  Color(0xFF0891B2),
  Color(0xFF9333EA),
  Color(0xFF475569),
];

String _money(double v) => '฿${FormatUtils.formatCurrency(v)}';

/// Shared look of the inheritance pages (calculator, knowledge, cases, result).
class FaraidStyle {
  FaraidStyle._();

  /// Accent for text and icons on cards (lighter in dark mode so it stays readable).
  static Color ink(AppThemeModel t, bool isDark) =>
      isDark ? Color.lerp(t.primaryColor, Colors.white, 0.45)! : t.primaryColor;

  static Color tint(AppThemeModel t, double a) =>
      Color.alphaBlend(t.primaryColor.withValues(alpha: a), t.cardBackground);

  static BoxDecoration card(AppThemeModel t, bool isDark, {double radius = 20}) => BoxDecoration(
        color: t.cardBackground,
        borderRadius: BorderRadius.circular(radius),
        border: isDark ? Border.all(color: t.borderColor) : null,
        boxShadow: isDark ? null : const [BoxShadow(color: Color(0x0F17142B), blurRadius: 14, offset: Offset(0, 4))],
      );

  /// "1 ทรัพย์สิน…" – the number in the accent colour, then the title.
  static Widget heading(AppThemeModel t, bool isDark, String text, {int? number, double size = 15}) {
    return Text.rich(
      TextSpan(children: [
        if (number != null) TextSpan(text: '$number ', style: TextStyle(color: ink(t, isDark))),
        TextSpan(text: text),
      ]),
      style: TextStyle(fontSize: size, fontWeight: FontWeight.bold, color: t.textColor),
    );
  }

  static Color warn(bool isDark) => isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
}

/// The coloured top bar of the inheritance pages.
class FaraidHeader extends StatelessWidget {
  final AppThemeModel theme;
  final bool isDark;
  final String title;
  final Widget? bottom;
  final List<Widget> actions;

  const FaraidHeader({
    super.key,
    required this.theme,
    required this.isDark,
    required this.title,
    this.bottom,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final text = theme.heroTextColor(isDark);
    final muted = theme.heroTextMutedColor(isDark);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 10, 8, 14),
      decoration: BoxDecoration(
        gradient: theme.heroGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  tooltip: 'ย้อนกลับ',
                  icon: Icon(Icons.chevron_left_rounded, color: text, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: text)),
              ),
              ...actions,
              Padding(
                padding: const EdgeInsets.only(right: 12, left: 4),
                child: Text('الفرائض',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: text.withValues(alpha: 0.85))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('ตามหลักมัซฮับชาฟิอีย์', style: TextStyle(fontSize: 12.5, color: muted)),
          ),
          if (bottom != null) ...[
            const SizedBox(height: 10),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: bottom!),
          ],
        ],
      ),
    );
  }
}

class FaraidResultScreen extends StatelessWidget {
  final ExpenseController controller;
  final MunasakhatResult chain;
  final FaraidEstateSummary summary;

  /// Set when the first estate waits on a fetus or a missing heir.
  final UncertainResult? uncertain;

  const FaraidResultScreen({
    super.key,
    required this.controller,
    required this.chain,
    required this.summary,
    this.uncertain,
  });

  String _buildShareText() {
    final b = StringBuffer();
    b.writeln('ผลการแบ่งมรดกตามหลักฟะรออิฎ (الفرائض)');
    if (summary.items.isNotEmpty) {
      b.writeln('ทรัพย์สินรวม: ${_money(summary.gross)}');
      for (final it in summary.items) {
        b.writeln('  - ${it.$1}: ${_money(it.$2)}');
      }
    }
    b.writeln('มรดกสุทธิ: ${_money(summary.net)}');
    for (final stage in chain.stages) {
      b.writeln('');
      b.writeln('■ ขั้นที่ ${stage.index + 1}: ${stage.title} — กองมรดก ${_money(stage.estate)}');
      final u = uncertain;
      if (stage.index == 0 && u != null) {
        b.writeln('(มีทายาทที่ยังไม่แน่นอน — แบ่งให้เฉพาะส่วนที่แน่นอนก่อน)');
        for (final e in u.known.entries) {
          b.write('• ${e.key.th} ${e.value} คน: รับได้ทันที ${_money(u.paidNow(e.key).toDouble() * stage.estate)}');
          if (e.value > 1) b.write(' (คนละ ${_money(u.minPerPerson[e.key]!.toDouble() * stage.estate)})');
          b.writeln();
        }
        b.writeln('• กันไว้ก่อน (الموقوف): ${_money(u.reserved.toDouble() * stage.estate)}');
        continue;
      }
      final passed = chain.passedOn(stage.index);
      for (final s in stage.result.shares) {
        final per = s.perPerson.toDouble() * stage.estate;
        b.write('• ${s.type.th} ${s.count} คน: ${s.fractionLabel} = ${_money(s.share.toDouble() * stage.estate)}');
        if (s.count > 1) b.write(' (คนละ ${_money(per)})');
        final p = passed[s.type];
        if (p != null) {
          b.write(' — ${p.entries.map((e) => 'คนที่ ${e.key} เสียชีวิต ส่งต่อขั้นที่ ${e.value + 1}').join(', ')}');
        }
        b.writeln();
      }
      if (stage.result.unallocated.isPositive) {
        b.writeln('• ส่วนที่เหลือ (ذوو الأرحام/بيت المال): ${_money(stage.result.unallocated.toDouble() * stage.estate)}');
      }
    }
    b.writeln('');
    b.writeln('คำนวณโดยแอพเหมียวตังค์ — ควรตรวจสอบกับผู้รู้หรือคณะกรรมการอิสลามประจำจังหวัดก่อนแบ่งจริง');
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = controller.currentTheme;
    final isDark = controller.isDarkMode;
    final multi = chain.stages.length > 1;
    var fx = 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: Column(
        children: [
          FaraidHeader(
            theme: theme,
            isDark: isDark,
            title: 'ผลการแบ่งมรดก',
            actions: [
              Builder(
                builder: (context) => IconButton(
                  tooltip: 'คัดลอกผลลัพธ์',
                  icon: Icon(Icons.copy_all_outlined, color: theme.heroTextColor(isDark)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _buildShareText()));
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('คัดลอกผลการแบ่งมรดกแล้ว นำไปวางในแชทได้เลย'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                FxFadeUp(index: fx++, child: _EstateCard(summary: summary, theme: theme, isDark: isDark)),
                if (chain.errors.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  FaraidNote(theme: theme, isDark: isDark, text: chain.errors.join('\n'), danger: true),
                ],
                if (multi) ...[
                  const SizedBox(height: 14),
                  FxFadeUp(
                    index: fx++,
                    child: _FinalRecipients(chain: chain, uncertain: uncertain, theme: theme, isDark: isDark),
                  ),
                ],
                for (final stage in chain.stages) ...[
                  const SizedBox(height: 14),
                  FxFadeUp(
                    index: fx++,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: FaraidStyle.card(theme, isDark),
                      child: stage.index == 0 && uncertain != null
                          ? FaraidUncertainBreakdown(
                              result: uncertain!,
                              estate: stage.estate,
                              theme: theme,
                              isDark: isDark,
                              title: 'ขั้นที่ 1: แบ่งเฉพาะส่วนที่แน่นอนก่อน',
                              outcomesOpen: true,
                            )
                          : FaraidShareBreakdown(
                              result: stage.result,
                              estate: stage.estate,
                              theme: theme,
                              isDark: isDark,
                              passed: chain.passedOn(stage.index),
                              title: multi ? 'ขั้นที่ ${stage.index + 1}: ${stage.title}' : 'ผลการแบ่งมรดก',
                              subtitle: !multi
                                  ? null
                                  : stage.index == 0
                                      ? 'กองมรดก ${_money(stage.estate)}'
                                      : stage.simultaneous
                                          ? 'ไม่รับมรดกจากผู้ตายคนแรก เพราะไม่รู้ว่าใครเสียชีวิตก่อน → แบ่งเฉพาะทรัพย์สินของตนเอง ${_money(stage.estate)} ให้ทายาทของผู้ตายคนนี้'
                                          : 'ได้รับจากขั้นก่อน ${_money(stage.inherited)} (= ${stage.fractionOfOriginal} ของมรดกเดิม)'
                                              '${stage.ownAssets > 0 ? ' + ทรัพย์สินส่วนตัว ${_money(stage.ownAssets)}' : ''} → แบ่งให้ทายาทของผู้ตายคนนี้ ${_money(stage.estate)}',
                            ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                FaraidDisclaimer(
                  theme: theme,
                  text: 'ผลนี้คำนวณตามหลักมัซฮับชาฟิอีย์เพื่อเป็นแนวทางเบื้องต้น ก่อนแบ่งจริงควรยืนยันกับผู้รู้ '
                      'หรือดะโต๊ะยุติธรรม / คณะกรรมการอิสลามประจำจังหวัด',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Plain white paragraph at the bottom of the inheritance pages.
class FaraidDisclaimer extends StatelessWidget {
  final AppThemeModel theme;
  final String text;

  const FaraidDisclaimer({super.key, required this.theme, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: theme.cardBackground, borderRadius: BorderRadius.circular(14)),
      child: Text(text, style: TextStyle(fontSize: 12, height: 1.6, color: theme.textSecondaryColor)),
    );
  }
}

/// A tinted notice (special-case flags, warnings, errors).
class FaraidNote extends StatelessWidget {
  final AppThemeModel theme;
  final bool isDark;
  final String? title;
  final String text;
  final bool danger;

  const FaraidNote({super.key, required this.theme, required this.isDark, this.title, required this.text, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final red = isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
    final ink = danger ? red : FaraidStyle.ink(theme, isDark);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: danger ? red.withValues(alpha: 0.1) : FaraidStyle.tint(theme, isDark ? 0.16 : 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(title!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ink)),
          if (title != null) const SizedBox(height: 2),
          Text(text, style: TextStyle(fontSize: 12, height: 1.45, color: danger ? red : theme.textSecondaryColor)),
        ],
      ),
    );
  }
}

class _EstateCard extends StatelessWidget {
  final FaraidEstateSummary summary;
  final AppThemeModel theme;
  final bool isDark;

  const _EstateCard({required this.summary, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Widget line(String label, double v, {bool minus = false}) {
      if (v <= 0 && minus) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 12.5, color: theme.textSecondaryColor))),
            Text('${minus ? '− ' : ''}${_money(v)}',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: theme.textColor)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: FaraidStyle.card(theme, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaraidStyle.heading(theme, isDark, 'ทรัพย์สินและสิทธิก่อนแบ่ง'),
          const SizedBox(height: 8),
          line('ทรัพย์สินรวมของผู้ตาย', summary.gross),
          for (final it in summary.items)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  Expanded(child: Text('• ${it.$1}', style: TextStyle(fontSize: 12, color: theme.textSecondaryColor))),
                  Text(_money(it.$2), style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
                ],
              ),
            ),
          line('ค่าจัดการศพ', summary.funeral, minus: true),
          line('หนี้สิน', summary.debts, minus: true),
          line('พินัยกรรม (วะศียะฮ์) ไม่เกิน 1/3', summary.wasiyyah, minus: true),
          Divider(height: 20, color: theme.borderColor),
          Row(
            children: [
              Expanded(
                child: Text('มรดกสุทธิที่นำมาแบ่ง',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: theme.textColor)),
              ),
              FxProgress(
                value: summary.net,
                builder: (_, v) => Text(_money(v),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FaraidStyle.ink(theme, isDark))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinalRecipients extends StatelessWidget {
  final MunasakhatResult chain;
  final UncertainResult? uncertain;
  final AppThemeModel theme;
  final bool isDark;

  const _FinalRecipients({required this.chain, required this.uncertain, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (final stage in chain.stages) {
      final u = uncertain;
      if (stage.index == 0 && u != null) {
        for (final e in u.known.entries) {
          final paid = u.paidNow(e.key).toDouble() * stage.estate;
          if (paid <= 0) continue;
          rows.add(_row(1, '${e.key.th}${e.value > 1 ? ' ${e.value} คน' : ''}', null, paid,
              e.value > 1 ? paid / e.value : null));
        }
        rows.add(_row(1, 'กันไว้ก่อน (มัวกูฟ)', 'รอทารกคลอด / ศาลตัดสิน', u.reserved.toDouble() * stage.estate, null));
        continue;
      }
      final passed = chain.passedOn(stage.index);
      for (final s in stage.result.shares) {
        if (!s.share.isPositive) continue;
        final dead = passed[s.type]?.length ?? 0;
        final alive = s.count - dead;
        if (alive <= 0) continue;
        final per = s.perPerson.toDouble() * stage.estate;
        rows.add(_row(
          stage.index + 1,
          '${s.type.th}${alive > 1 ? ' $alive คน' : ''}',
          stage.index > 0
              ? 'ทายาทของ${stage.title.replaceAll(' (เสียชีวิตตามมา)', '').replaceAll(' (เสียชีวิตพร้อมกัน)', '')}'
              : null,
          per * alive,
          alive > 1 ? per : null,
        ));
      }
      if (stage.result.unallocated.isPositive) {
        rows.add(_row(stage.index + 1, 'ซะวิลอัรฮาม / บัยตุลมาล', null,
            stage.result.unallocated.toDouble() * stage.estate, null));
      }
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: FaraidStyle.card(theme, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaraidStyle.heading(theme, isDark, 'สรุปเงินที่แต่ละคนได้รับจริง'),
          const SizedBox(height: 2),
          Text('มรดกซ้อน (มุนาสะเคาะฮ์) • المناسخات',
              style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
          const SizedBox(height: 6),
          ...rows,
          const SizedBox(height: 8),
          Text(
            'คนเดียวกันอาจได้รับจากหลายขั้น เช่น ภรรยาของผู้ตายคนแรกคือ "แม่" ในขั้นที่ 2 — ให้นำยอดของคนเดียวกันมารวมกัน',
            style: TextStyle(fontSize: 12, height: 1.45, color: theme.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _row(int stage, String title, String? sub, double amount, double? each) {
    final ink = FaraidStyle.ink(theme, isDark);
    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.borderColor.withValues(alpha: 0.6)))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: FaraidStyle.tint(theme, isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('ชั้นที่ $stage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ink)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: theme.textColor)),
                if (sub != null) Text(sub, style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_money(amount), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textColor)),
              if (each != null)
                Text('คนละ ${_money(each)}', style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Multi-colour bar of everyone's share; grows from the left.
class _ShareBar extends StatelessWidget {
  final List<(double, Color)> parts;

  const _ShareBar({required this.parts});

  @override
  Widget build(BuildContext context) {
    final visible = parts.where((p) => p.$1 > 0).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: SizedBox(
        height: 14,
        child: LayoutBuilder(
          builder: (context, c) => FxProgress(
            value: 1,
            builder: (_, v) => Align(
              alignment: Alignment.centerLeft,
              child: ClipRect(
                child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: v.clamp(0.0, 1.0),
                child: SizedBox(
                  width: c.maxWidth,
                  child: Row(
                    children: [
                      for (var i = 0; i < visible.length; i++) ...[
                        if (i > 0) const SizedBox(width: 2),
                        Expanded(
                          flex: (visible[i].$1 * 1000).round().clamp(1, 1000),
                          child: Container(color: visible[i].$2),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The share rows of one estate: bar, heirs with fraction / basis / amount, blocked heirs and steps.
class FaraidShareBreakdown extends StatefulWidget {
  final FaraidResult result;
  final double estate;
  final AppThemeModel theme;
  final bool isDark;
  final String? title;
  final int? number;
  final String? subtitle;
  final Map<HeirType, Map<int, int>> passed;

  /// When set, every heir row offers "died before the division".
  final void Function(HeirShare share)? onDied;

  const FaraidShareBreakdown({
    super.key,
    required this.result,
    required this.estate,
    required this.theme,
    required this.isDark,
    this.title,
    this.number,
    this.subtitle,
    this.passed = const {},
    this.onDied,
  });

  @override
  State<FaraidShareBreakdown> createState() => _FaraidShareBreakdownState();
}

class _FaraidShareBreakdownState extends State<FaraidShareBreakdown> {
  bool _showSteps = true;

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final theme = widget.theme;
    final isDark = widget.isDark;
    final ink = FaraidStyle.ink(theme, isDark);
    final top = r.awlTo ?? r.asl;
    final baseText = 'ฐาน (อัศล์) ${r.asl}${r.awlTo != null ? ' → เอาล์เป็น ${r.awlTo}' : ''}'
        '${r.tashih != top ? ' → ปรับฐาน (ตัศฮีห์) ${r.tashih}' : ''}';
    final shares = r.shares.where((s) => s.share.isPositive || s.reason.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.title != null) FaraidStyle.heading(theme, isDark, widget.title!, number: widget.number),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 2),
          Text(widget.subtitle!, style: TextStyle(fontSize: 12, height: 1.4, color: theme.textSecondaryColor)),
        ],
        const SizedBox(height: 2),
        Text(baseText, style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
        if (r.specialCase != null || r.awlTo != null || r.isRadd) ...[
          const SizedBox(height: 10),
          if (r.specialCase != null)
            FaraidNote(
              theme: theme,
              isDark: isDark,
              title: r.specialCase!,
              text: 'ระบบตรวจพบกรณีพิเศษ และคำนวณตามคำตัดสินของเศาะหาบะฮ์ที่มัซฮับชาฟิอีย์ยึด',
            ),
          if (r.awlTo != null) ...[
            if (r.specialCase != null) const SizedBox(height: 6),
            FaraidNote(
              theme: theme,
              isDark: isDark,
              title: 'อัล-เอาล์',
              text: 'ส่วนฟุรูฎรวมเกินกองมรดก ฐาน ${r.asl} เพิ่มเป็น ${r.awlTo} ทุกคนลดลงตามสัดส่วน',
            ),
          ],
          if (r.isRadd) ...[
            if (r.specialCase != null || r.awlTo != null) const SizedBox(height: 6),
            FaraidNote(
              theme: theme,
              isDark: isDark,
              title: 'อัร-ร็อดด์',
              text: 'ไม่มีอะศอบะฮ์ ส่วนที่เหลือเฉลี่ยคืนให้ทายาทฟุรูฎตามสัดส่วน (ยกเว้นคู่สมรส)',
            ),
          ],
        ],
        const SizedBox(height: 12),
        if (shares.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: theme.scaffoldBackground, borderRadius: BorderRadius.circular(12)),
            child: Text(
              'ยังไม่ได้ระบุทายาท — ถ้าไม่มีทายาทเลยจริง ๆ มรดกจะตกแก่ญาติซะวิลอัรฮาม หรือบัยตุลมาล',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: theme.textSecondaryColor),
            ),
          )
        else ...[
          _ShareBar(parts: [
            for (var i = 0; i < shares.length; i++) (shares[i].share.toDouble(), kHeirPalette[i % kHeirPalette.length]),
            if (r.unallocated.isPositive) (r.unallocated.toDouble(), theme.borderColor),
          ]),
          const SizedBox(height: 12),
          for (var i = 0; i < shares.length; i++) _row(shares[i], kHeirPalette[i % kHeirPalette.length], ink),
          if (r.unallocated.isPositive)
            _plainRow(
              'ซะวิลอัรฮาม / บัยตุลมาล',
              '${r.unallocated} • ส่วนที่เหลือ',
              'ไม่มีทายาทฟุรูฎ/อะศอบะฮ์รับส่วนที่เหลือ ตกแก่ญาติสายอื่น (เช่น ลูกของบุตรสาว) หรือบัยตุลมาล',
              r.unallocated.toDouble() * widget.estate,
            ),
        ],
        if (r.steps.isNotEmpty) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _showSteps = !_showSteps),
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: EdgeInsets.zero,
                foregroundColor: ink,
              ),
              child: Text(_showSteps ? 'ซ่อนวิธีคิด' : 'ดูวิธีคิดทีละขั้น',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          if (_showSteps) FaraidStepsBox(theme: theme, isDark: isDark, steps: r.steps),
        ],
        if (r.blocked.isNotEmpty) ...[
          const SizedBox(height: 12),
          FaraidBlockedBox(
            isDark: isDark,
            lines: [
              for (final b in r.blocked) '${b.type.th}${b.count > 1 ? ' (${b.count} คน)' : ''} — ${b.reason}',
            ],
          ),
        ],
      ],
    );
  }

  Widget _row(HeirShare s, Color color, Color ink) {
    final theme = widget.theme;
    final r = widget.result;
    final total = s.share.toDouble() * widget.estate;
    final per = s.perPerson.toDouble() * widget.estate;
    final units = (s.share * Frac(r.tashih)).toDouble().round();
    final passed = widget.passed[s.type];
    final secondary = TextStyle(fontSize: 12, color: theme.textSecondaryColor);
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.borderColor.withValues(alpha: 0.6)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: s.type.th),
                    if (s.count > 1)
                      TextSpan(
                        text: '  ${s.count} คน',
                        style: TextStyle(fontWeight: FontWeight.w400, color: theme.textSecondaryColor),
                      ),
                  ]),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textColor),
                ),
              ),
              const SizedBox(width: 8),
              FxProgress(
                value: total,
                builder: (_, v) => Text(_money(v),
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: theme.textColor)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: s.share.isPositive ? '$units/${r.tashih}' : '0',
                            style: TextStyle(fontWeight: FontWeight.bold, color: ink),
                          ),
                          TextSpan(text: ' • ${s.basis.th} • ${s.fractionLabel}'),
                        ]),
                        style: secondary,
                      ),
                    ),
                    if (s.count > 1) Text('คนละ ${_money(per)}', style: secondary),
                  ],
                ),
                if (s.reason.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(s.reason, style: TextStyle(fontSize: 12, height: 1.45, color: theme.textSecondaryColor)),
                ],
                if (passed != null)
                  for (final e in passed.entries)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${s.count > 1 ? 'คนที่ ${e.key} ' : ''}เสียชีวิตก่อนแบ่ง → ส่วน ${_money(per)} ส่งต่อไปแบ่งในขั้นที่ ${e.value + 1}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ink),
                      ),
                    ),
                if (widget.onDied != null && s.share.isPositive)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: OutlinedButton(
                      onPressed: () => widget.onDied!(s),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(44, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        foregroundColor: ink,
                        side: BorderSide(color: ink.withValues(alpha: 0.35)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('เสียชีวิตก่อนแบ่ง → คำนวณมรดกซ้อน', style: TextStyle(fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _plainRow(String title, String line, String note, double amount) {
    final theme = widget.theme;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: theme.scaffoldBackground, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textColor)),
                Text(line, style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
                Text(note, style: TextStyle(fontSize: 12, height: 1.4, color: theme.textSecondaryColor)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(_money(amount), style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: theme.textColor)),
        ],
      ),
    );
  }
}

/// "วิธีคิดทีละขั้น" – numbered steps on a tinted panel.
class FaraidStepsBox extends StatelessWidget {
  final AppThemeModel theme;
  final bool isDark;
  final List<FaraidStep> steps;

  const FaraidStepsBox({super.key, required this.theme, required this.isDark, required this.steps});

  @override
  Widget build(BuildContext context) {
    final ink = FaraidStyle.ink(theme, isDark);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: theme.scaffoldBackground, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('วิธีคิดทีละขั้น', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textColor)),
          for (var i = 0; i < steps.length; i++) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: theme.cardBackground, shape: BoxShape.circle),
                  child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ink)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: '${steps[i].title} (${steps[i].ar})\n',
                        style: TextStyle(fontWeight: FontWeight.w600, color: theme.textColor),
                      ),
                      TextSpan(text: steps[i].detail),
                    ]),
                    style: TextStyle(fontSize: 12.5, height: 1.6, color: theme.textSecondaryColor),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// "ญาติที่ไม่ได้รับสิทธิ์ (ฮัจบ์)" – orange box listing blocked relatives.
class FaraidBlockedBox extends StatelessWidget {
  final bool isDark;
  final List<String> lines;

  const FaraidBlockedBox({super.key, required this.isDark, required this.lines});

  @override
  Widget build(BuildContext context) {
    final head = isDark ? const Color(0xFFFDBA74) : const Color(0xFF9A3412);
    final body = isDark ? const Color(0xFFFED7AA) : const Color(0xFF7C2D12);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFFF97316).withValues(alpha: 0.12) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ญาติที่ไม่ได้รับสิทธิ์ (ฮัจบ์)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: head)),
          for (final l in lines) ...[
            const SizedBox(height: 4),
            Text(l, style: TextStyle(fontSize: 12, height: 1.4, color: body)),
          ],
        ],
      ),
    );
  }
}

/// Al-Haml / al-Mafqud: what can be paid now, what is held back, and how each outcome settles it.
class FaraidUncertainBreakdown extends StatefulWidget {
  final UncertainResult result;
  final double estate;
  final AppThemeModel theme;
  final bool isDark;
  final String? title;
  final int? number;

  /// Show the outcome list straight away (result page) instead of behind a toggle.
  final bool outcomesOpen;

  const FaraidUncertainBreakdown({
    super.key,
    required this.result,
    required this.estate,
    required this.theme,
    required this.isDark,
    this.title,
    this.number,
    this.outcomesOpen = false,
  });

  @override
  State<FaraidUncertainBreakdown> createState() => _FaraidUncertainBreakdownState();
}

class _FaraidUncertainBreakdownState extends State<FaraidUncertainBreakdown> {
  late bool _showOutcomes = widget.outcomesOpen;

  @override
  Widget build(BuildContext context) {
    final u = widget.result;
    final theme = widget.theme;
    final isDark = widget.isDark;
    final ink = FaraidStyle.ink(theme, isDark);
    final estate = widget.estate;
    final reserved = u.reserved.toDouble() * estate;
    final known = u.known.entries.toList();
    final secondary = TextStyle(fontSize: 12, color: theme.textSecondaryColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.title != null) FaraidStyle.heading(theme, isDark, widget.title!, number: widget.number),
        const SizedBox(height: 2),
        Text(
          'คำนวณ ${u.outcomes.length} สถานการณ์ แล้วให้แต่ละคนรับส่วนที่น้อยที่สุดก่อน ที่เหลือกันไว้ (มัวกูฟ)',
          style: secondary,
        ),
        const SizedBox(height: 12),
        _ShareBar(parts: [
          for (var i = 0; i < known.length; i++)
            (u.paidNow(known[i].key).toDouble(), kHeirPalette[i % kHeirPalette.length]),
          (u.reserved.toDouble(), theme.borderColor),
        ]),
        const SizedBox(height: 12),
        for (var i = 0; i < known.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.borderColor.withValues(alpha: 0.6)))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: kHeirPalette[i % kHeirPalette.length], borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${known[i].key.th}${known[i].value > 1 ? ' ${known[i].value} คน' : ''}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textColor),
                      ),
                    ),
                    Text(
                      _money(u.paidNow(known[i].key).toDouble() * estate),
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: theme.textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(
                              text: '${u.paidNow(known[i].key)}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: ink),
                            ),
                            TextSpan(
                              text: u.paidNow(known[i].key).isPositive
                                  ? ' • ส่วนที่น้อยที่สุดในทุกสถานการณ์'
                                  : ' • ยังไม่ได้รับ เพราะบางกรณีถูกกันสิทธิ์',
                            ),
                          ]),
                          style: secondary,
                        ),
                      ),
                      if (known[i].value > 1)
                        Text('คนละ ${_money(u.minPerPerson[known[i].key]!.toDouble() * estate)}', style: secondary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: theme.scaffoldBackground, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('กันไว้ก่อน (มัวกูฟ)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textColor)),
                    Text('${u.reserved} • แบ่งเพิ่มเมื่อทราบผลแน่นอน', style: secondary),
                  ],
                ),
              ),
              Text(_money(reserved),
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: FaraidStyle.warn(isDark))),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (!widget.outcomesOpen)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _showOutcomes = !_showOutcomes),
              style: TextButton.styleFrom(minimumSize: const Size(44, 44), padding: EdgeInsets.zero, foregroundColor: ink),
              child: Text(
                _showOutcomes ? 'ซ่อนตารางสถานการณ์' : 'ดูผลแต่ละสถานการณ์ (${u.outcomes.length})',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          )
        else ...[
          const SizedBox(height: 10),
          Text('เมื่อทราบผลแล้ว ส่วนที่กันไว้แบ่งอย่างไร',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: theme.textColor)),
          Text('แตะสถานการณ์ที่เกิดขึ้นจริงเพื่อดูว่าแต่ละคนได้รับเพิ่มเท่าไร', style: secondary),
          const SizedBox(height: 8),
        ],
        if (_showOutcomes)
          for (final o in u.outcomes) _outcomeTile(context, o),
      ],
    );
  }

  Widget _outcomeTile(BuildContext context, ScenarioOutcome o) {
    final theme = widget.theme;
    final estate = widget.estate;
    final r = o.result;
    final lines = <Widget>[];
    for (final s in r.shares) {
      if (!s.share.isPositive) continue;
      final full = s.share.toDouble() * estate;
      final knownCount = widget.result.known[s.type] ?? 0;
      final paid = (widget.result.minPerPerson[s.type] ?? Frac.zero).toDouble() * estate * knownCount;
      final extraPeople = s.count - knownCount;
      final topUp = full - paid;
      final who = extraPeople > 0 && knownCount > 0
          ? '${s.type.th} ${s.count} คน (รวมคนใหม่ $extraPeople)'
          : '${s.type.th}${s.count > 1 ? ' ${s.count} คน' : ''}${knownCount == 0 ? ' (คนใหม่)' : ''}';
      lines.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(child: Text('$who • ${s.fractionLabel}', style: TextStyle(fontSize: 12.5, color: theme.textColor))),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_money(full), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textColor)),
                  if (topUp > 0.005)
                    Text(
                      'รับเพิ่มจากส่วนที่กันไว้ ${_money(topUp)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    for (final b in r.blocked) {
      lines.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text('• ${b.type.th} ไม่ได้รับ — ${b.reason}',
            style: TextStyle(fontSize: 12, height: 1.35, color: theme.textSecondaryColor)),
      ));
    }
    if (r.unallocated.isPositive) {
      lines.add(Text(
        '• ส่วนที่เหลือ ${_money(r.unallocated.toDouble() * estate)} ตกแก่ญาติสายอื่น / บัยตุลมาล',
        style: TextStyle(fontSize: 12, color: theme.textSecondaryColor),
      ));
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: theme.scaffoldBackground,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 10),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            title: Text(
              o.scenario.label.isEmpty ? 'กรณีปกติ' : o.scenario.label,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: theme.textColor),
            ),
            subtitle: Text(
              'ฐาน ${r.asl}${r.awlTo != null ? ' → เอาล์ ${r.awlTo}' : ''}${r.isRadd ? ' • ร็อดด์' : ''}${r.specialCase != null ? ' • ${r.specialCase}' : ''}',
              style: TextStyle(fontSize: 12, color: theme.textSecondaryColor),
            ),
            children: lines,
          ),
        ),
      ),
    );
  }
}
