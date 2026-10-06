import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/faraid_engine.dart';
import '../state/expense_controller.dart';
import '../theme/app_theme_model.dart';
import '../utils/format_utils.dart';

/// Inputs shown on the result page for the money breakdown of the first estate.
class FaraidEstateSummary {
  final double gross;
  final double funeral;
  final double debts;
  final double wasiyyah;
  final double net;

  const FaraidEstateSummary({
    required this.gross,
    required this.funeral,
    required this.debts,
    required this.wasiyyah,
    required this.net,
  });
}

const List<Color> kHeirPalette = [
  Color(0xFF3B82F6),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
  Color(0xFF06B6D4),
  Color(0xFFEF4444),
  Color(0xFF84CC16),
  Color(0xFF6366F1),
  Color(0xFF14B8A6),
];

class FaraidResultScreen extends StatelessWidget {
  final ExpenseController controller;
  final MunasakhatResult chain;
  final FaraidEstateSummary summary;

  const FaraidResultScreen({
    super.key,
    required this.controller,
    required this.chain,
    required this.summary,
  });

  String _money(double v) => '฿${FormatUtils.formatCurrency(v)}';

  String _buildShareText() {
    final b = StringBuffer();
    b.writeln('ผลการแบ่งมรดกตามหลักฟะรออิฎ (الفرائض)');
    b.writeln('มรดกสุทธิ: ${_money(summary.net)}');
    for (final stage in chain.stages) {
      b.writeln('');
      b.writeln('■ ขั้นที่ ${stage.index + 1}: ${stage.title} — กองมรดก ${_money(stage.estate)}');
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('ผลการแบ่งมรดก',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: theme.textColor)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'คัดลอกผลลัพธ์',
            icon: Icon(Icons.copy_all_rounded, color: theme.primaryColor),
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
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        children: [
          _EstateHero(summary: summary, theme: theme, money: _money),
          if (chain.errors.isNotEmpty) ...[
            const SizedBox(height: 10),
            _NoticeBox(
              color: const Color(0xFFEF4444),
              icon: Icons.error_outline_rounded,
              text: chain.errors.join('\n'),
            ),
          ],
          if (multi) ...[
            const SizedBox(height: 16),
            _SectionTitle(
              title: 'สรุปเงินที่แต่ละคนได้รับจริง',
              ar: 'المناسخات',
              theme: theme,
            ),
            const SizedBox(height: 8),
            _FinalRecipients(chain: chain, theme: theme, money: _money),
          ],
          for (final stage in chain.stages) ...[
            const SizedBox(height: 18),
            _StageSection(
              stage: stage,
              chain: chain,
              theme: theme,
              isDark: isDark,
              money: _money,
              showHeader: multi,
            ),
          ],
          const SizedBox(height: 18),
          _NoticeBox(
            color: const Color(0xFF64748B),
            icon: Icons.info_outline_rounded,
            text:
                'คำนวณตามมัซฮับชาฟิอีย์ (มัซฮับที่มุสลิมในประเทศไทยส่วนใหญ่ถือปฏิบัติ) ใช้เพื่อศึกษาและวางแผนเบื้องต้น '
                'ก่อนแบ่งจริงควรปรึกษาอิหม่าม ผู้รู้ หรือคณะกรรมการอิสลามประจำจังหวัด / ดาโต๊ะยุติธรรม',
          ),
        ],
      ),
    );
  }
}

class _EstateHero extends StatelessWidget {
  final FaraidEstateSummary summary;
  final AppThemeModel theme;
  final String Function(double) money;

  const _EstateHero({required this.summary, required this.theme, required this.money});

  @override
  Widget build(BuildContext context) {
    Widget line(String label, double v, {bool minus = false}) {
      if (v <= 0 && minus) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12.5))),
            Text('${minus ? '− ' : ''}${money(v)}',
                style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: theme.heroGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('มรดกสุทธิที่นำมาแบ่ง  •  التركة',
              style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(money(summary.net),
                style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 10),
          line('ทรัพย์สินทั้งหมด', summary.gross),
          line('ค่าจัดการศพ (التجهيز)', summary.funeral, minus: true),
          line('ชำระหนี้ (الدين)', summary.debts, minus: true),
          line('พินัยกรรม (الوصية) ไม่เกิน 1/3', summary.wasiyyah, minus: true),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String ar;
  final AppThemeModel theme;
  final String? subtitle;

  const _SectionTitle({required this.title, required this.ar, required this.theme, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title,
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: theme.textColor)),
            ),
            Text(ar,
                textDirection: TextDirection.rtl,
                style: TextStyle(fontSize: 15, color: theme.primaryColor, fontWeight: FontWeight.w600)),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: TextStyle(fontSize: 12, color: theme.textSecondaryColor, height: 1.35)),
        ],
      ],
    );
  }
}

class _FinalRecipients extends StatelessWidget {
  final MunasakhatResult chain;
  final AppThemeModel theme;
  final String Function(double) money;

  const _FinalRecipients({required this.chain, required this.theme, required this.money});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (final stage in chain.stages) {
      final passed = chain.passedOn(stage.index);
      for (final s in stage.result.shares) {
        if (!s.share.isPositive) continue;
        final dead = passed[s.type]?.length ?? 0;
        final alive = s.count - dead;
        if (alive <= 0) continue;
        final per = s.perPerson.toDouble() * stage.estate;
        rows.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('ขั้น ${stage.index + 1}',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: theme.primaryColor)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${s.type.th}${alive > 1 ? ' $alive คน' : ''}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textColor)),
                    if (stage.index > 0)
                      Text('ทายาทของ${stage.title.replaceAll(' (เสียชีวิตตามมา)', '')}',
                          style: TextStyle(fontSize: 11, color: theme.textSecondaryColor)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(money(per * alive),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: theme.textColor)),
                  if (alive > 1)
                    Text('คนละ ${money(per)}', style: TextStyle(fontSize: 11, color: theme.textSecondaryColor)),
                ],
              ),
            ],
          ),
        ));
      }
      if (stage.result.unallocated.isPositive) {
        rows.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text('ขั้น ${stage.index + 1}: ญาติสายอื่น / บัยตุลมาล',
                    style: TextStyle(fontSize: 12.5, color: theme.textSecondaryColor)),
              ),
              Text(money(stage.result.unallocated.toDouble() * stage.estate),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textSecondaryColor)),
            ],
          ),
        ));
      }
    }
    rows.add(Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Text(
        '💡 คนเดียวกันอาจได้รับจากหลายขั้น เช่น ภรรยาของผู้ตายคนแรกคือ "แม่" ในขั้นที่ 2 — ให้นำยอดของคนเดียวกันมารวมกัน',
        style: TextStyle(fontSize: 11.5, height: 1.4, color: theme.textSecondaryColor),
      ),
    ));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
    );
  }
}

class _StageSection extends StatelessWidget {
  final StageOutcome stage;
  final MunasakhatResult chain;
  final AppThemeModel theme;
  final bool isDark;
  final String Function(double) money;
  final bool showHeader;

  const _StageSection({
    required this.stage,
    required this.chain,
    required this.theme,
    required this.isDark,
    required this.money,
    required this.showHeader,
  });

  @override
  Widget build(BuildContext context) {
    final r = stage.result;
    final passed = chain.passedOn(stage.index);
    final visible = r.shares.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          _SectionTitle(
            title: 'ขั้นที่ ${stage.index + 1}: ${stage.title}',
            ar: stage.index == 0 ? 'المسألة الأولى' : 'المسألة الثانية',
            theme: theme,
            subtitle: stage.index == 0
                ? 'กองมรดก ${money(stage.estate)}'
                : 'ได้รับจากขั้นก่อน ${money(stage.inherited)} (= ${stage.fractionOfOriginal} ของมรดกเดิม)'
                    '${stage.ownAssets > 0 ? ' + ทรัพย์สินส่วนตัว ${money(stage.ownAssets)}' : ''} → แบ่งให้ทายาทของผู้ตายคนนี้ ${money(stage.estate)}',
          ),
          const SizedBox(height: 10),
        ] else ...[
          _SectionTitle(title: 'ส่วนแบ่งของทายาทแต่ละคน', ar: 'أنصبة الورثة', theme: theme),
          const SizedBox(height: 10),
        ],
        if (r.shares.isEmpty && r.unallocated.isPositive)
          _NoticeBox(
            color: const Color(0xFFF59E0B),
            icon: Icons.help_outline_rounded,
            text: 'ยังไม่ได้ระบุทายาท — ถ้าไม่มีทายาทเลยจริง ๆ มรดกจะตกแก่ญาติสายอื่น (ذوو الأرحام) หรือบัยตุลมาล (بيت المال)',
          ),
        if (r.specialCase != null || r.awlTo != null || r.isRadd)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (r.specialCase != null) _Badge(text: '⭐ ${r.specialCase}', color: const Color(0xFF8B5CF6)),
                if (r.awlTo != null) _Badge(text: 'อัล-เอาล์ (العول) ${r.asl} → ${r.awlTo}', color: const Color(0xFFEF4444)),
                if (r.isRadd) const _Badge(text: 'อัร-ร็อด (الرد) เฉลี่ยคืน', color: Color(0xFF10B981)),
              ],
            ),
          ),
        if (visible.isNotEmpty) ...[
          _ShareBar(shares: visible, unallocated: r.unallocated, theme: theme),
          const SizedBox(height: 12),
        ],
        for (var i = 0; i < visible.length; i++)
          _HeirShareCard(
            share: visible[i],
            color: kHeirPalette[i % kHeirPalette.length],
            estate: stage.estate,
            tashih: r.tashih,
            passed: passed[visible[i].type],
            theme: theme,
            money: money,
          ),
        if (r.unallocated.isPositive && r.shares.isNotEmpty)
          _NoticeBox(
            color: const Color(0xFF64748B),
            icon: Icons.account_balance_rounded,
            text:
                'ส่วนที่เหลือ ${money(r.unallocated.toDouble() * stage.estate)} (${r.unallocated}) ไม่มีทายาทฟัรฎ์/อะศอบะฮ์มารับ ตกแก่ญาติสายอื่น (ذوو الأرحام) เช่น ลูกของลูกสาว หรือบัยตุลมาล (بيت المال)',
          ),
        if (r.blocked.isNotEmpty) ...[
          const SizedBox(height: 4),
          _BlockedCard(blocked: r.blocked, theme: theme, isDark: isDark),
        ],
        const SizedBox(height: 10),
        _StepsCard(steps: r.steps, theme: theme),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _ShareBar extends StatelessWidget {
  final List<HeirShare> shares;
  final Frac unallocated;
  final AppThemeModel theme;

  const _ShareBar({required this.shares, required this.unallocated, required this.theme});

  @override
  Widget build(BuildContext context) {
    final parts = <Widget>[];
    for (var i = 0; i < shares.length; i++) {
      final v = shares[i].share.toDouble();
      if (v <= 0) continue;
      parts.add(Expanded(
        flex: (v * 1000).round().clamp(1, 1000),
        child: Container(color: kHeirPalette[i % kHeirPalette.length]),
      ));
    }
    if (unallocated.isPositive) {
      parts.add(Expanded(
        flex: (unallocated.toDouble() * 1000).round().clamp(1, 1000),
        child: Container(color: theme.borderColor),
      ));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(height: 14, child: Row(children: parts)),
    );
  }
}

class _HeirShareCard extends StatelessWidget {
  final HeirShare share;
  final Color color;
  final double estate;
  final int tashih;
  final Map<int, int>? passed;
  final AppThemeModel theme;
  final String Function(double) money;

  const _HeirShareCard({
    required this.share,
    required this.color,
    required this.estate,
    required this.tashih,
    required this.passed,
    required this.theme,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final total = share.share.toDouble() * estate;
    final per = share.perPerson.toDouble() * estate;
    final units = (share.perPerson * Frac(tashih)).toDouble().round();
    final pct = share.share.toDouble() * 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.borderColor),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${share.type.th}${share.count > 1 ? ' (${share.count} คน)' : ''}',
                                  style: TextStyle(
                                      fontSize: 14.5, fontWeight: FontWeight.bold, color: theme.textColor)),
                              const SizedBox(height: 1),
                              Text('${share.type.ar}  •  ${share.type.arLatin}',
                                  style: TextStyle(fontSize: 11.5, color: theme.textSecondaryColor)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(money(total),
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
                            Text('${pct.toStringAsFixed(2)}%',
                                style: TextStyle(fontSize: 11.5, color: theme.textSecondaryColor)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Chip(text: '${share.basis.th} (${share.basis.ar})', color: color),
                        _Chip(text: 'สัดส่วน ${share.fractionLabel}', color: theme.textSecondaryColor),
                        if (share.count > 1) _Chip(text: 'คนละ ${money(per)}', color: const Color(0xFF10B981)),
                        if (units > 0) _Chip(text: 'คนละ $units/$tashih ส่วน', color: theme.textSecondaryColor),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(share.reason,
                        style: TextStyle(fontSize: 12, height: 1.45, color: theme.textSecondaryColor)),
                    if (passed != null)
                      for (final e in passed!.entries)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.subdirectory_arrow_right_rounded, size: 16, color: Color(0xFF3B82F6)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${share.count > 1 ? 'คนที่ ${e.key} ' : ''}เสียชีวิตก่อนแบ่ง → ส่วน ${money(per)} ส่งต่อไปแบ่งในขั้นที่ ${e.value + 1}',
                                  style: const TextStyle(
                                      fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                                ),
                              ),
                            ],
                          ),
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

class _Chip extends StatelessWidget {
  final String text;
  final Color color;

  const _Chip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _BlockedCard extends StatelessWidget {
  final List<BlockedHeir> blocked;
  final AppThemeModel theme;
  final bool isDark;

  const _BlockedCard({required this.blocked, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.block_rounded, size: 16, color: theme.textSecondaryColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text('ทายาทที่ไม่ได้รับในกรณีนี้ (مَحْجُوب มะห์ญูบ)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final b in blocked)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ${b.type.th}${b.count > 1 ? ' (${b.count} คน)' : ''}',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: theme.textColor)),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(b.reason,
                        style: TextStyle(fontSize: 11.5, height: 1.4, color: theme.textSecondaryColor)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  final List<FaraidStep> steps;
  final AppThemeModel theme;

  const _StepsCard({required this.steps, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.borderColor),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Icon(Icons.format_list_numbered_rounded, color: theme.primaryColor),
          title: Text('วิธีคิดทีละขั้นตอน',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textColor)),
          subtitle: Text('طريقة الحساب',
              style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
          children: [
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Text('${i + 1}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${steps[i].title}  (${steps[i].ar})',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textColor)),
                          const SizedBox(height: 3),
                          Text(steps[i].detail,
                              style: TextStyle(fontSize: 12, height: 1.45, color: theme.textSecondaryColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoticeBox extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _NoticeBox({required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, height: 1.45, color: color))),
        ],
      ),
    );
  }
}
