import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../widgets/meow_fx.dart';
import '../widgets/meow_paywall_modal.dart';
import 'account_management_screen.dart';
import 'add_transaction_screen.dart';
import 'character_customization_screen.dart';
import 'compare_analytics_screen.dart';
import 'currency_converter_screen.dart';
import 'data_backup_restore_screen.dart';
import 'subscription_vault_screen.dart';
import 'theme_shop_screen.dart';
import 'voice_chat_entry_screen.dart';
import 'zakat_calculator_screen.dart';

/// คู่มือ & ฟีเจอร์เด่น: a grouped list of 12 how-to topics, each opening a step-by-step page.
class AppGuideScreen extends StatefulWidget {
  final ExpenseController controller;
  final VoidCallback? onFinish;

  /// Opens straight on this topic (0..11) instead of the list.
  final int? initialTopic;

  const AppGuideScreen({
    super.key,
    required this.controller,
    this.onFinish,
    this.initialTopic,
  });

  @override
  State<AppGuideScreen> createState() => _AppGuideScreenState();
}

/// Topics opened in this app session (shown as "อ่านแล้ว").
final Set<int> _readTopics = {};

class _AppGuideScreenState extends State<AppGuideScreen> {
  int? _topic; // null = list
  String _query = '';
  final _search = TextEditingController();

  ExpenseController get _c => widget.controller;
  bool get _isEn => _c.guideLanguage == 'en';

  @override
  void initState() {
    super.initState();
    final t = widget.initialTopic;
    if (t != null && t >= 0 && t < _topics.length) _open(t, haptic: false);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(int i, {bool haptic = true}) {
    if (haptic) HapticFeedback.selectionClick();
    setState(() {
      _topic = i;
      _readTopics.add(i);
    });
  }

  void _backToList() {
    HapticFeedback.selectionClick();
    setState(() => _topic = null);
  }

  void _finishGuide() {
    HapticFeedback.mediumImpact();
    widget.controller.completeAppGuide();
    if (widget.onFinish != null) {
      widget.onFinish!();
    } else {
      Navigator.pop(context);
    }
  }

  void _push(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  /// "ลองเลย" target for a topic, or null when the feature lives on a main tab.
  VoidCallback? _tryAction(int i) {
    Widget? screen;
    var vip = false;
    switch (i) {
      case 0:
      case 8:
        screen = AccountManagementScreen(controller: _c);
      case 4:
        screen = SubscriptionVaultScreen(controller: _c);
        vip = true;
      case 5:
        screen = CurrencyConverterScreen(controller: _c);
        vip = true;
      case 6:
        screen = ZakatCalculatorScreen(controller: _c);
        vip = true;
      case 7:
        screen = VoiceChatEntryScreen(controller: _c);
      case 9:
        screen = AddTransactionScreen(controller: _c);
      case 10:
        screen = CompareAnalyticsScreen(controller: _c);
      case 11:
        screen = DataBackupRestoreScreen(controller: _c);
    }
    if (screen == null) return null;
    final target = screen;
    return () {
      HapticFeedback.lightImpact();
      if (vip && !_c.isPremium) {
        MeowPaywallModal.show(context, controller: _c, reason: 'ฟีเจอร์พรีเมี่ยมสำหรับสมาชิก VIP เท่านั้น');
        return;
      }
      _push(target);
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final p = _Pal.of(_c);
        final isEn = _isEn;
        final t = _topic;
        return PopScope(
          canPop: t == null || widget.initialTopic != null,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _topic != null) _backToList();
          },
          child: Scaffold(
            backgroundColor: p.bg,
            body: Column(
              children: [
                _AppBarPlain(
                  pal: p,
                  title: isEn ? 'Guide & features' : 'คู่มือ & ฟีเจอร์เด่น',
                  subtitle: t == null
                      ? (isEn ? '${_topics.length} topics • tap for step-by-step help' : '${_topics.length} หัวข้อ • แตะเพื่อดูวิธีใช้ทีละขั้น')
                      : (isEn
                          ? 'Topic ${t + 1} of ${_topics.length} • ${_topics[t].title(true)}'
                          : 'หัวข้อ ${t + 1} จาก ${_topics.length} • ${_topics[t].title(false)}'),
                  backLabel: t == null ? (isEn ? 'Back' : 'ย้อนกลับ') : (isEn ? 'Back to all topics' : 'กลับไปหน้ารวม'),
                  onBack: t == null || widget.initialTopic != null ? null : _backToList,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: t == null
                        ? KeyedSubtree(key: const ValueKey('list'), child: _buildList(p, isEn))
                        : KeyedSubtree(key: ValueKey('t$t'), child: _buildDetail(p, isEn, t)),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(color: p.card, border: Border(top: BorderSide(color: p.line))),
                  padding: EdgeInsets.fromLTRB(16, t == null ? 12 : 10, 16, 14 + MediaQuery.of(context).padding.bottom),
                  child: t == null ? _buildListFooter(p, isEn) : _buildDetailFooter(p, isEn, t),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // List view
  // ---------------------------------------------------------------------------

  Widget _buildList(_Pal p, bool isEn) {
    final q = _query.trim().toLowerCase();
    bool match(_Topic t) =>
        q.isEmpty || '${t.title(isEn)} ${t.what(isEn)} ${t.desc(isEn)} ${t.title(!isEn)}'.toLowerCase().contains(q);
    final read = _readTopics.length;
    final total = _topics.length;

    final groups = <Widget>[];
    for (final g in _Group.values) {
      final items = [for (var i = 0; i < total; i++) if (_topics[i].group == g && match(_topics[i])) i];
      if (items.isEmpty) continue;
      groups.add(Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel(p, '${g.label(isEn)} (${items.length})'),
          _card(p, [
            for (var k = 0; k < items.length; k++)
              _row(
                p,
                icon: _topics[items[k]].icon,
                title: _topics[items[k]].title(isEn),
                subtitle: _topics[items[k]].what(isEn),
                first: k == 0,
                trailing: _readTopics.contains(items[k])
                    ? Text(isEn ? 'Read' : 'อ่านแล้ว', style: TextStyle(fontSize: 12, color: p.sub))
                    : null,
                onTap: () => _open(items[k]),
              ),
          ]),
        ],
      ));
    }

    final children = <Widget>[
      // Overview + reading progress
      Container(
        padding: const EdgeInsets.all(16),
        decoration: _box(p),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.menu_book_outlined, size: 22, color: p.icon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isEn ? 'All-in-one money app' : 'ครบจบ ในแอปเดียว',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.text)),
                      const SizedBox(height: 2),
                      Text(
                        isEn
                            ? 'Record by hand or automatically, analyse, and use money tools — tap a topic for step-by-step help'
                            : 'จดเอง จดอัตโนมัติ วิเคราะห์ และเครื่องมือการเงิน — แตะหัวข้อเพื่อดูวิธีใช้ทีละขั้น',
                        style: TextStyle(fontSize: 12.5, height: 1.45, color: p.sub),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(isEn ? 'Read $read/$total' : 'อ่านแล้ว $read/$total',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: p.text, fontFeatures: const [FontFeature.tabularFigures()])),
                const Spacer(),
                Text(
                  read == total
                      ? (isEn ? 'All topics read' : 'ครบทุกหัวข้อแล้ว')
                      : (isEn ? '${total - read} to go' : 'เหลืออีก ${total - read} หัวข้อ'),
                  style: TextStyle(fontSize: 13, color: p.sub),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FxBar(value: read / total, color: p.accent, track: p.divider, height: 6),
          ],
        ),
      ),
      // Search
      TextField(
        controller: _search,
        onChanged: (v) => setState(() => _query = v),
        style: TextStyle(fontSize: 14.5, color: p.text),
        cursorColor: p.accent,
        decoration: InputDecoration(
          hintText: isEn ? 'Search how-tos, e.g. slip, gold, zakat' : 'ค้นหาวิธีใช้ เช่น สลิป, ทอง, ซากาต',
          hintStyle: TextStyle(fontSize: 14.5, color: p.sub),
          filled: true,
          fillColor: p.card,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: p.sub),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: isEn ? 'Clear search' : 'ล้างคำค้น',
                  icon: Icon(Icons.close_rounded, size: 20, color: p.sub),
                  onPressed: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                ),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.line)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.link, width: 1.5)),
        ),
      ),
      if (groups.isEmpty)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: _box(p),
          child: Column(
            children: [
              Icon(Icons.search_rounded, size: 22, color: p.sub),
              const SizedBox(height: 6),
              Text(isEn ? 'No topic matches “${_query.trim()}”' : 'ไม่พบหัวข้อ “${_query.trim()}”',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.text)),
              const SizedBox(height: 6),
              Text(isEn ? 'Try slip, voice, gold or backup' : 'ลองคำว่า สลิป, เสียง, ทอง หรือ สำรอง',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: p.sub)),
            ],
          ),
        ),
      ...groups,
      if (q.isEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionLabel(p, isEn ? 'Make it yours' : 'ปรับแต่งในแบบคุณ'),
            _card(p, [
              _row(
                p,
                icon: Icons.sentiment_satisfied_outlined,
                title: isEn ? 'Mascot & accessories' : 'ตัวละคร & มาสคอต',
                subtitle: isEn ? '22 characters and accessories' : '22 ตัวละคร และอุปกรณ์คู่กาย',
                first: true,
                onTap: () => _push(CharacterCustomizationScreen(controller: _c)),
              ),
              _row(
                p,
                icon: Icons.palette_outlined,
                title: isEn ? 'Theme shop' : 'ร้านค้าธีม',
                subtitle: isEn ? '18 themes • 30-second free trial' : '18 ธีม ทดลองใช้ฟรี 30 วินาที',
                onTap: () => _push(ThemeShopScreen(controller: _c)),
              ),
              _row(
                p,
                icon: _c.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                title: isEn ? 'Appearance' : 'โหมดการแสดงผล',
                subtitle: isEn ? 'Light • Dark' : 'สว่าง • มืด',
                chevron: false,
                trailing: Text(
                  _c.isDarkMode ? (isEn ? 'Dark' : 'มืด') : (isEn ? 'Light' : 'สว่าง'),
                  style: TextStyle(fontSize: 13, color: p.sub),
                ),
                onTap: () => _c.setDarkMode(!_c.isDarkMode),
              ),
            ]),
          ],
        ),
      Text(
        isEn
            ? 'The guide follows the language set in the app • version ${ExpenseController.appVersion}'
            : 'คู่มือแสดงตามภาษาที่ตั้งไว้ในแอป • เวอร์ชัน ${ExpenseController.appVersion}',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: p.sub),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          FxFadeUp(index: i, child: children[i]),
        ],
      ],
    );
  }

  Widget _buildListFooter(_Pal p, bool isEn) {
    final firstUnread = [for (var i = 0; i < _topics.length; i++) i].where((i) => !_readTopics.contains(i)).firstOrNull;
    return _PrimaryButton(
      pal: p,
      label: firstUnread == null
          ? (isEn ? 'All read — review from the first topic' : 'อ่านครบแล้ว — ทบทวนตั้งแต่หัวข้อแรก')
          : (isEn ? 'Continue: ${_topics[firstUnread].title(true)}' : 'อ่านต่อ: ${_topics[firstUnread].title(false)}'),
      onTap: () => _open(firstUnread ?? 0),
    );
  }

  // ---------------------------------------------------------------------------
  // Detail view
  // ---------------------------------------------------------------------------

  Widget _buildDetail(_Pal p, bool isEn, int i) {
    final t = _topics[i];
    final steps = t.steps(isEn);
    final mock = t.mock(isEn);
    final mockColor = switch (t.mockTone) {
      _Tone.expense => p.expense,
      _Tone.income => p.income,
      _Tone.accent => p.link,
      _Tone.muted => p.sub,
      _Tone.plain => p.text,
    };

    final children = <Widget>[
      Container(
        padding: const EdgeInsets.all(16),
        decoration: _box(p),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.only(top: 4), child: Icon(t.icon, size: 24, color: p.icon)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: p.strongLine)),
                        child: Text(
                          isEn
                              ? 'Topic ${i + 1} of ${_topics.length} • ${t.group.label(true)}'
                              : 'หัวข้อ ${i + 1} จาก ${_topics.length} • ${t.group.label(false)}',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: p.body),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(t.title(isEn), style: TextStyle(fontSize: 19, height: 1.3, fontWeight: FontWeight.w700, color: p.text)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(t.desc(isEn), style: TextStyle(fontSize: 14, height: 1.6, color: p.body)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(isEn ? 'Example in the app' : 'ตัวอย่างในแอป',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: p.sub)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.line)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(mock.$1, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.text)),
                              Text(mock.$2, style: TextStyle(fontSize: 12, color: p.sub)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(mock.$3, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: mockColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel(p, isEn ? 'How to use it in ${steps.length} steps' : 'วิธีใช้งาน ${steps.length} ขั้นตอน'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: _box(p),
            child: Column(
              children: [
                for (var k = 0; k < steps.length; k++)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(top: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.strongLine, width: 1.5)),
                        child: Text('${k + 1}', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.icon)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(0, 14, 0, 12),
                          decoration: BoxDecoration(border: k == 0 ? null : Border(top: BorderSide(color: p.divider))),
                          child: Text(steps[k], style: TextStyle(fontSize: 14, height: 1.55, color: p.text)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: _box(p),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 22, color: p.icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEn ? 'Tip' : 'เคล็ดลับ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.text)),
                  const SizedBox(height: 2),
                  Text(t.tip(isEn), style: TextStyle(fontSize: 13.5, height: 1.55, color: p.body)),
                ],
              ),
            ),
          ],
        ),
      ),
      _OutlineButton(
        pal: p,
        label: isEn
            ? 'Back to all topics (read ${_readTopics.length}/${_topics.length})'
            : 'กลับไปหน้ารวม (อ่านแล้ว ${_readTopics.length}/${_topics.length})',
        color: p.link,
        onTap: widget.initialTopic != null ? () => Navigator.maybePop(context) : _backToList,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        for (var k = 0; k < children.length; k++) ...[
          if (k > 0) const SizedBox(height: 14),
          FxFadeUp(index: k, child: children[k]),
        ],
      ],
    );
  }

  Widget _buildDetailFooter(_Pal p, bool isEn, int i) {
    final tryIt = _tryAction(i);
    final last = i == _topics.length - 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (tryIt != null) ...[
          _PrimaryButton(pal: p, label: _topics[i].tryLabel(isEn), onTap: tryIt),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: _OutlineButton(
                pal: p,
                height: 46,
                label: i == 0 ? (isEn ? '‹ First topic' : '‹ หัวข้อแรกแล้ว') : '‹ ${_topics[i - 1].title(isEn)}',
                color: i == 0 ? p.faint : p.text,
                onTap: i == 0 ? null : () => _open(i - 1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: last
                  ? (tryIt == null
                      ? _PrimaryButton(pal: p, height: 46, radius: 14, label: isEn ? 'Got it, start' : 'เข้าใจแล้ว เริ่มใช้งาน', onTap: _finishGuide)
                      : _OutlineButton(
                          pal: p, height: 46, label: isEn ? 'Got it, start' : 'เข้าใจแล้ว เริ่มใช้งาน', color: p.text, onTap: _finishGuide))
                  : _OutlineButton(
                      pal: p,
                      height: 46,
                      label: '${_topics[i + 1].title(isEn)} ›',
                      color: p.text,
                      onTap: () => _open(i + 1),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared pieces
  // ---------------------------------------------------------------------------

  BoxDecoration _box(_Pal p) =>
      BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.line));

  Widget _sectionLabel(_Pal p, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.sub)),
      );

  Widget _card(_Pal p, List<Widget> rows) => Container(
        decoration: _box(p),
        clipBehavior: Clip.antiAlias,
        child: Material(color: Colors.transparent, child: Column(children: rows)),
      );

  Widget _row(
    _Pal p, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    bool first = false,
    bool chevron = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: Row(
          children: [
            Icon(icon, size: 22, color: p.icon),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 64),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: p.divider))),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.text)),
                          const SizedBox(height: 1),
                          Text(subtitle, style: TextStyle(fontSize: 12.5, height: 1.4, color: p.sub)),
                        ],
                      ),
                    ),
                    if (trailing != null) ...[const SizedBox(width: 8), trailing],
                    if (chevron) Icon(Icons.chevron_right_rounded, size: 20, color: p.faint),
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
// Content
// ---------------------------------------------------------------------------

enum _Group {
  auto('จดง่าย อัตโนมัติ', 'Easy & automatic'),
  plan('วิเคราะห์ & วางแผน', 'Insights & planning'),
  tool('เครื่องมือการเงิน & อิสลาม', 'Money & Islamic tools'),
  safe('ปลอดภัย & ย้ายข้อมูลได้เอง', 'Safe & portable data');

  final String th, en;
  const _Group(this.th, this.en);
  String label(bool isEn) => isEn ? en : th;
}

enum _Tone { expense, income, accent, muted, plain }

class _Topic {
  final _Group group;
  final IconData icon;
  final List<String> _title, _what, _desc, _steps, _tip, _try;
  final List<List<String>> _mock; // [th(title, meta, value), en(...)]
  final _Tone mockTone;

  const _Topic(this.group, this.icon, this._title, this._what, this._desc, this._steps, this._tip, this._mock, this.mockTone, this._try);

  String title(bool en) => _title[en ? 1 : 0];
  String what(bool en) => _what[en ? 1 : 0];
  String desc(bool en) => _desc[en ? 1 : 0];
  List<String> steps(bool en) => _steps[en ? 1 : 0].split('\n');
  String tip(bool en) => _tip[en ? 1 : 0];
  (String, String, String) mock(bool en) {
    final m = _mock[en ? 1 : 0];
    return (m[0], m[1], m[2]);
  }

  String tryLabel(bool en) => _try[en ? 1 : 0];
}

// Order = guide order 1..12.
const _topics = <_Topic>[
  _Topic(
    _Group.auto,
    Icons.receipt_long_outlined,
    ['ดึงสลิปอัตโนมัติ', 'Auto slip import'],
    ['โอนเงินแล้วบันทึกให้เอง รองรับ 22 ธนาคาร', 'Transfers are recorded for you • 22 banks'],
    [
      'เหมียวตังค์อ่านสลิปโอนเงินที่แอปธนาคารบันทึกไว้ในอัลบั้มรูป แล้วสร้างรายการให้ทันที ไม่ต้องพิมพ์เอง รองรับ 22 ธนาคารและ e-Wallet',
      'MeowTang reads the transfer slips your bank app saves to your photos and creates the entry right away — no typing. Works with 22 banks and e-wallets.',
    ],
    [
      'อนุญาตสิทธิ์ “รูปภาพ” ให้เหมียวตังค์ (ทำครั้งเดียว)\nโอนเงินในแอปธนาคารตามปกติ และให้แอปธนาคารบันทึกสลิปลงเครื่อง\nเหมียวตังค์อ่านสลิปใหม่และบันทึกให้ — ถ้าหมวดหรือยอดไม่ถูก แตะรายการเพื่อแก้ได้',
      'Allow MeowTang to use “Photos” (once)\nTransfer in your bank app as usual and let it save the slip to your phone\nMeowTang reads the new slip and records it — tap the entry to fix the category or amount',
    ],
    [
      'เปิด/ปิด “บันทึกสลิปอัตโนมัติ” แยกทีละบัญชีได้ที่ เมนู › บัญชี & กระเป๋าเงิน',
      'Turn “auto-record slips” on or off per account in Menu › Accounts & wallets.',
    ],
    [
      ['โอนเงิน • ร้านข้าวมันไก่', 'บันทึกจากสลิป', '−฿50'],
      ['Transfer • Chicken rice shop', 'Recorded from a slip', '−฿50'],
    ],
    _Tone.expense,
    ['ลองเลย: ตั้งค่าสลิปอัตโนมัติ', 'Try it: set up auto slips'],
  ),
  _Topic(
    _Group.safe,
    Icons.verified_user_outlined,
    ['ตรวจสลิปแท้', 'Check real slips'],
    ['เช็กสลิปที่ลูกค้าส่งมาว่าเป็นของจริง', 'Check that a customer’s slip is genuine'],
    [
      'เวลาขายของแล้วลูกค้าส่งสลิปมา ให้เหมียวตังค์อ่าน QR บนสลิปเพื่อเช็กว่าข้อมูลตรงกับรายการโอนจริง ช่วยกันสลิปปลอมหรือภาพตัดต่อ',
      'When a customer sends you a slip, MeowTang reads its QR code to check it matches a real transfer — protection against fake or edited slips.',
    ],
    [
      'แตะปุ่มเมนูด่วน มุมขวาล่างของหน้าภาพรวม › ตรวจสลิปแท้ออนไลน์\nเลือกรูปสลิปที่มี QR Code จากอัลบั้ม หรือสแกนสด (ต้องต่ออินเทอร์เน็ต)\nดูผล “ข้อมูลตรง” หรือ “น่าสงสัย” พร้อมยอดเงิน ชื่อผู้รับ และเวลาโอน',
      'Tap the quick-menu button at the bottom right of Overview › Online slip check\nPick a slip with a QR code from your photos, or scan it live (needs internet)\nSee “matches” or “suspicious” with the amount, receiver and transfer time',
    ],
    [
      'สลิปที่ผ่านแล้วก็ควรเช็กยอดเงินเข้าในแอปธนาคารของคุณอีกครั้งก่อนส่งของ',
      'Even for a slip that passes, check the money arrived in your bank app before you ship.',
    ],
    [
      ['สลิปถูกต้อง', 'ไทยพาณิชย์ • 14:05', '฿1,290'],
      ['Slip is genuine', 'SCB • 14:05', '฿1,290'],
    ],
    _Tone.income,
    ['', ''],
  ),
  _Topic(
    _Group.auto,
    Icons.wifi_off_rounded,
    ['อ่านสลิปออฟไลน์', 'Offline slip reading'],
    ['อ่านสลิปบนเครื่อง ไม่ต้องใช้เน็ต', 'Slips are read on your phone, no internet'],
    [
      'การอ่านสลิปทำบนมือถือของคุณเอง ไม่ต้องต่ออินเทอร์เน็ต และรูปสลิปไม่ถูกส่งออกไปที่ไหน จึงทั้งเร็วและเป็นส่วนตัว',
      'Slips are read on your own phone without internet, and slip photos are never sent anywhere — fast and private.',
    ],
    [
      'ไม่ต้องตั้งค่าเพิ่ม — เปิดดึงสลิปอัตโนมัติไว้ก็พอ\nแม้ไม่มีเน็ต ก็โอนเงินหรือสแกนจ่ายได้ตามปกติ\nเปิดเหมียวตังค์ สลิปใหม่จะถูกอ่านและบันทึกทันที',
      'Nothing to set up — just keep auto slip import on\nTransfer or scan-to-pay as usual, even offline\nOpen MeowTang and new slips are read and recorded right away',
    ],
    [
      'เหมาะกับตอนสัญญาณไม่ดี เช่น บนรถไฟฟ้าใต้ดินหรือต่างจังหวัด',
      'Handy when the signal is weak, such as on the subway or upcountry.',
    ],
    [
      ['ไม่มีอินเทอร์เน็ต', 'อ่านสลิปใหม่แล้ว 2 ใบ', 'บันทึกแล้ว'],
      ['No internet', '2 new slips read', 'Recorded'],
    ],
    _Tone.muted,
    ['', ''],
  ),
  _Topic(
    _Group.auto,
    Icons.swipe_outlined,
    ['ปัดรายการ & เลิกทำ', 'Swipe & undo'],
    ['ปัดเพื่อแก้หรือลบ ลบผิดกดเลิกทำได้', 'Swipe to edit or delete, undo mistakes'],
    [
      'จัดการรายการได้เร็วขึ้นด้วยการปัด ไม่ต้องเปิดเข้าไปทีละรายการ และถ้าลบผิดก็เรียกคืนได้ทันที',
      'Handle entries faster with a swipe instead of opening each one — and bring back anything deleted by mistake.',
    ],
    [
      'ในหน้ารายการ ปัดรายการไปทางซ้ายเพื่อลบ\nปัดไปทางขวาเพื่อแก้ไขยอด หมวด หรือบัญชี\nลบผิด? แตะ “เลิกทำ” ที่แถบด้านล่างก่อนแถบหายไป',
      'In the list, swipe an entry left to delete it\nSwipe right to edit the amount, category or account\nDeleted by mistake? Tap “Undo” on the bar at the bottom before it disappears',
    ],
    [
      'ปัดลบหลายรายการติดกันได้ แถบเลิกทำจะรวมไว้ให้เรียกคืนพร้อมกัน',
      'You can swipe-delete several entries in a row — the undo bar collects them all.',
    ],
    [
      ['ลบ “กาแฟหน้าออฟฟิศ” แล้ว', 'แตะเพื่อเรียกคืน', 'เลิกทำ'],
      ['Deleted “Office coffee”', 'Tap to bring it back', 'Undo'],
    ],
    _Tone.accent,
    ['', ''],
  ),
  _Topic(
    _Group.plan,
    Icons.event_repeat_outlined,
    ['Subscription', 'Subscriptions'],
    ['รวมค่าสมาชิกรายเดือน เตือนก่อนตัดเงิน', 'All memberships in one place, reminders first'],
    [
      'รวมบริการที่ตัดเงินประจำ เช่น Netflix เพลง หรือค่ามือถือ ไว้ในที่เดียว เห็นยอดรวมต่อเดือนและต่อปี และเตือนก่อนถึงวันตัดเงิน',
      'Keep recurring charges like Netflix, music or your phone bill in one place, see the monthly and yearly total, and get reminded before each charge.',
    ],
    [
      'เปิดแท็บพรีเมี่ยม › Subscription & บิลประจำ\nแตะ “+ เพิ่ม” เลือกบริการ ใส่ราคาและวันตัดเงิน เช่น Netflix ฿419 ทุกวันที่ 5\nตั้งให้เตือนล่วงหน้ากี่วันก็ได้ เมื่อจ่ายแล้วกด “บันทึกจ่ายแล้ว” ได้ใน 1 แตะ',
      'Open the Premium tab › Subscriptions & bills\nTap “+ Add”, pick the service and enter the price and billing day, e.g. Netflix ฿419 on the 5th\nChoose how many days ahead to be reminded; once paid, mark it paid in one tap',
    ],
    [
      'ดู “ยอดต่อปี” แล้วลองยกเลิกบริการที่ไม่ค่อยได้ใช้ — ประหยัดได้มากกว่าที่คิด',
      'Look at the yearly total and cancel what you rarely use — it adds up.',
    ],
    [
      ['Netflix', 'ตัดเงินพรุ่งนี้ • บันเทิง', '฿419'],
      ['Netflix', 'Charged tomorrow • Entertainment', '฿419'],
    ],
    _Tone.expense,
    ['ลองเลย: เพิ่ม Subscription', 'Try it: add a subscription'],
  ),
  _Topic(
    _Group.tool,
    Icons.language_rounded,
    ['แปลงเงิน & ทอง', 'Currency & gold'],
    ['150+ สกุลเงิน และราคาทองวันนี้', '150+ currencies and today’s gold price'],
    [
      'แปลงค่าเงินได้มากกว่า 150 สกุล และดูราคาทองคำแท่ง/ทองรูปพรรณวันนี้ ใช้ตอนเที่ยวต่างประเทศหรือซื้อขายทอง',
      'Convert more than 150 currencies and check today’s gold bar and jewellery prices — for trips abroad or buying and selling gold.',
    ],
    [
      'เปิดแท็บพรีเมี่ยม › แปลงค่าเงิน หรือ คำนวณทอง & แร่เงิน\nเลือกสกุลเงิน เช่น JPY แล้วพิมพ์จำนวน แอปแปลงเป็นบาทให้ทันที\nในหน้าคำนวณทอง ใส่น้ำหนักเป็นบาทหรือกรัม ดูราคาซื้อ-ขายและกราฟราคา',
      'Open the Premium tab › Currency converter or Gold & silver calculator\nPick a currency such as JPY and type the amount — it converts to baht instantly\nIn the gold calculator, enter the weight in baht or grams to see buy/sell prices and the chart',
    ],
    [
      'ตอนเพิ่มรายการ เลือกสกุลเงินอื่นได้ แอปจะบันทึกเป็นบาทตามอัตราวันนั้นให้',
      'When adding an entry you can pick another currency; it is saved in baht at that day’s rate.',
    ],
    [
      ['10,000 JPY', 'อัตราวันนี้', '≈ ฿2,250'],
      ['10,000 JPY', 'Today’s rate', '≈ ฿2,250'],
    ],
    _Tone.plain,
    ['ลองเลย: แปลงค่าเงิน', 'Try it: convert currency'],
  ),
  _Topic(
    _Group.tool,
    Icons.dark_mode_outlined,
    ['การเงินอิสลาม & ซากาต', 'Islamic finance & zakat'],
    ['คำนวณซากาตจากเงินออมและทอง', 'Work out zakat on savings and gold'],
    [
      'ช่วยคำนวณซากาตประจำปีจากเงินออม ทอง และทรัพย์สินที่ครอบครองครบ 1 ปี โดยเทียบกับเกณฑ์นิศอบให้อัตโนมัติ',
      'Calculates your yearly zakat on savings, gold and assets held for a full year, checked against the nisab automatically.',
    ],
    [
      'เปิดแท็บพรีเมี่ยม › คำนวณซากาต\nใส่เงินออม ทอง และทรัพย์สินที่ถือครองครบ 1 ปี (ดึงยอดบัญชีจากแอปได้)\nแอปเทียบกับนิศอบ แล้วบอกยอดซากาตที่ต้องจ่าย (2.5%)',
      'Open the Premium tab › Zakat calculator\nEnter savings, gold and assets held for a full year (account balances can be pulled in)\nThe app compares with the nisab and shows the zakat due (2.5%)',
    ],
    [
      'นิศอบคิดจากราคาทองวันนี้ในหน้า แปลงเงิน & ทอง หากไม่แน่ใจกรณีพิเศษ ควรปรึกษาผู้รู้',
      'The nisab uses today’s gold price. For special cases, ask a scholar.',
    ],
    [
      ['ซากาตปีนี้', 'ทรัพย์สินถึงนิศอบแล้ว', '2.5%'],
      ['Zakat this year', 'Assets have reached the nisab', '2.5%'],
    ],
    _Tone.plain,
    ['ลองเลย: คำนวณซากาต', 'Try it: calculate zakat'],
  ),
  _Topic(
    _Group.auto,
    Icons.mic_none_rounded,
    ['พูดจดด้วยเสียง', 'Record by voice'],
    ['พูด “กาแฟ 65 บาท” แล้วบันทึกให้', 'Say “coffee 65 baht” and it is recorded'],
    [
      'จดรายการด้วยการพูด ไม่ต้องพิมพ์ แอปแยกชื่อรายการ จำนวนเงิน และเลือกหมวดหมู่ให้',
      'Record entries by speaking instead of typing — the app picks out the name and amount and chooses the category.',
    ],
    [
      'แตะปุ่ม + แล้วแตะไอคอนไมโครโฟน (ครั้งแรกให้อนุญาตไมโครโฟน)\nพูดชื่อรายการตามด้วยจำนวนเงิน เช่น “กาแฟ 65 บาท”\nตรวจหมวดหมู่และบัญชีที่แอปเลือกให้ แล้วกด บันทึก',
      'Tap + and then the microphone icon (allow the microphone the first time)\nSay the item followed by the amount, e.g. “coffee 65 baht”\nCheck the category and account the app chose, then tap Save',
    ],
    [
      'ตั้งคีย์เวิร์ดเองได้ เช่น “ชาตรามือ” → อาหาร #ชานม ที่ เมนู › กฎคีย์เวิร์ดจัดหมวด แอปจะเลือกหมวดได้แม่นขึ้น',
      'Add your own keywords, e.g. “Cha Tra Mue” → Food #milktea, in Menu › Keyword category rules for better category picks.',
    ],
    [
      ['“กาแฟ 65 บาท”', 'อาหาร • เงินสด', '−฿65'],
      ['“Coffee 65 baht”', 'Food • Cash', '−฿65'],
    ],
    _Tone.expense,
    ['ลองเลย: พูดจดรายการแรก', 'Try it: say your first entry'],
  ),
  _Topic(
    _Group.plan,
    Icons.account_balance_outlined,
    ['แยกตามธนาคาร', 'By bank account'],
    ['ดูยอดและรายการแยกทีละบัญชี', 'Balances and entries per account'],
    [
      'ดูยอดคงเหลือ รายรับ และรายจ่ายของแต่ละบัญชีแยกกัน เช่น กสิกรไทย ไทยพาณิชย์ TrueMoney หรือเงินสด',
      'See the balance, income and spending of each account separately — KBank, SCB, TrueMoney or cash.',
    ],
    [
      'เปิด เมนู › บัญชี & กระเป๋าเงิน\nแตะบัญชีที่ต้องการ เช่น กสิกรไทย\nดูรายการและสรุปรายรับ-รายจ่ายเฉพาะบัญชีนั้น เลือกเดือนได้',
      'Open Menu › Accounts & wallets\nTap the account you want, e.g. KBank\nSee only that account’s entries and income/spending summary, by month',
    ],
    [
      'ย้ายเงินระหว่างบัญชีของตัวเองให้ใช้ “โอนระหว่างบัญชี” จะไม่นับเป็นรายจ่าย',
      'Moving money between your own accounts? Use “Transfer between accounts” so it is not counted as spending.',
    ],
    [
      ['กสิกรไทย', 'บัญชีหลัก • สลิปอัตโนมัติ', 'ยอดคงเหลือ'],
      ['KBank', 'Main account • auto slips', 'Balance'],
    ],
    _Tone.income,
    ['ลองเลย: ดูบัญชีของฉัน', 'Try it: see my accounts'],
  ),
  _Topic(
    _Group.auto,
    Icons.calculate_outlined,
    ['แป้นคิดเลข', 'Built-in calculator'],
    ['พิมพ์ 120+35 ในช่องเงินได้เลย', 'Type 120+35 straight into the amount'],
    [
      'ช่องจำนวนเงินคิดเลขได้ในตัว รวมหลายยอดหรือหารค่าอาหารกับเพื่อนได้โดยไม่ต้องสลับไปแอปเครื่องคิดเลข',
      'The amount field is a calculator — add up several amounts or split a bill with friends without switching apps.',
    ],
    [
      'ตอนเพิ่มรายการ แตะช่องจำนวนเงิน\nใช้ปุ่ม + − × ÷ เช่น 120+35+15\nกด = หรือกด บันทึก แอปคิดยอดให้ (฿170)',
      'When adding an entry, tap the amount field\nUse + − × ÷, e.g. 120+35+15\nTap = or Save and the app works out the total (฿170)',
    ],
    [
      'หารค่าอาหาร: พิมพ์ 1,280÷4 ได้ ฿320 ต่อคน',
      'Splitting a meal: type 1,280÷4 to get ฿320 each.',
    ],
    [
      ['120+35+15', 'อาหาร', '= ฿170'],
      ['120+35+15', 'Food', '= ฿170'],
    ],
    _Tone.plain,
    ['ลองเลย: เพิ่มรายการ', 'Try it: add an entry'],
  ),
  _Topic(
    _Group.plan,
    Icons.table_chart_outlined,
    ['เทียบ 2 เดือน', 'Compare 2 months'],
    ['เห็นทันทีว่าหมวดไหนใช้เพิ่มขึ้น', 'See which categories went up'],
    [
      'เทียบรายรับ-รายจ่ายของ 2 เดือนแบบหมวดต่อหมวด รู้ทันทีว่าเดือนนี้ใช้มากขึ้นหรือน้อยลงตรงไหน',
      'Compare two months category by category to see straight away where you spent more or less.',
    ],
    [
      'เปิดแท็บ สถิติ › เทียบเดือน\nเลือก 2 เดือนที่ต้องการ\nดูหมวดที่เพิ่มขึ้น ▲ หรือลดลง ▼ แตะหมวดเพื่อดูรายการ',
      'Open the Stats tab › Compare months\nPick the two months you want\nSee categories that went up ▲ or down ▼ and tap one to see its entries',
    ],
    [
      'เริ่มจากหมวดที่เพิ่มขึ้นมากที่สุด แล้วตั้งงบประมาณให้หมวดนั้นในเดือนหน้า',
      'Start with the category that rose most and set a budget for it next month.',
    ],
    [
      ['อาหาร', 'เดือนนี้เทียบเดือนก่อน', '▼ ฿590'],
      ['Food', 'This month vs last month', '▼ ฿590'],
    ],
    _Tone.income,
    ['ลองเลย: เทียบเดือนนี้', 'Try it: compare this month'],
  ),
  _Topic(
    _Group.safe,
    Icons.file_download_outlined,
    ['ส่งออก & สำรองข้อมูล', 'Export & backup'],
    ['ส่งออก Excel / PDF และสำรองไว้ย้ายเครื่อง', 'Excel / PDF export and backups for a new phone'],
    [
      'ข้อมูลเป็นของคุณ ส่งออกเป็นไฟล์ไปใช้ต่อ หรือสำรองไว้เพื่อกู้คืนตอนเปลี่ยนมือถือ',
      'Your data is yours — export it as a file, or back it up to restore when you change phones.',
    ],
    [
      'เปิด เมนู › ส่งออก แล้วเลือกช่วงเวลา\nเลือก Excel หรือ PDF แล้วกดส่งออก (สำหรับสมาชิก VIP)\nสำรอง: เมนู › สำรองข้อมูล › บันทึกไฟล์สำรอง แล้วกู้คืนหรือสแกน QR ในเครื่องใหม่',
      'Open Menu › Export and pick a period\nChoose Excel or PDF and export (for VIP members)\nBackup: Menu › Backup › save a backup file, then restore it or scan the QR on the new phone',
    ],
    [
      'ก่อนเปลี่ยนเครื่องให้สำรองใหม่อีกครั้ง ข้อมูลทั้งหมดจะย้ายไปครบ',
      'Make a fresh backup right before you switch phones so everything moves across.',
    ],
    [
      ['รายงานเดือนนี้.xlsx', 'Excel • พร้อมแชร์', 'แชร์'],
      ['This month.xlsx', 'Excel • ready to share', 'Share'],
    ],
    _Tone.accent,
    ['ลองเลย: สำรองข้อมูลตอนนี้', 'Try it: back up now'],
  ),
];

// ---------------------------------------------------------------------------
// Private building blocks
// ---------------------------------------------------------------------------

class _PrimaryButton extends StatelessWidget {
  final _Pal pal;
  final String label;
  final VoidCallback onTap;
  final double height;
  final double radius;

  const _PrimaryButton({required this.pal, required this.label, required this.onTap, this.height = 52, this.radius = 16});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: FxPress(
          onTap: onTap,
          child: Container(
            height: height,
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: pal.accent, borderRadius: BorderRadius.circular(radius)),
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      );
}

class _OutlineButton extends StatelessWidget {
  final _Pal pal;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final double height;

  const _OutlineButton({required this.pal, required this.label, required this.color, required this.onTap, this.height = 48});

  @override
  Widget build(BuildContext context) => Material(
        color: pal.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: pal.line)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: height,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: height < 48 ? 13 : 14, fontWeight: FontWeight.w600, color: color)),
          ),
        ),
      );
}

/// White app bar: 44px back chevron, left-aligned title and a one-line subtitle.
class _AppBarPlain extends StatelessWidget {
  final _Pal pal;
  final String title;
  final String subtitle;
  final String backLabel;
  final VoidCallback? onBack;

  const _AppBarPlain({required this.pal, required this.title, required this.subtitle, required this.backLabel, this.onBack});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    return Container(
      decoration: BoxDecoration(color: p.card, border: Border(bottom: BorderSide(color: p.line))),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack ?? () => Navigator.maybePop(context),
                tooltip: backLabel,
                icon: Icon(Icons.chevron_left_rounded, size: 30, color: p.text),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.text)),
                    const SizedBox(height: 1),
                    Text(subtitle,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: p.sub)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Neutral palette derived from the active theme (same mapping as the menu).
class _Pal {
  final Color bg, card, text, sub, body, icon, faint, line, strongLine, divider, accent, link, income, expense;

  const _Pal({
    required this.bg,
    required this.card,
    required this.text,
    required this.sub,
    required this.body,
    required this.icon,
    required this.faint,
    required this.line,
    required this.strongLine,
    required this.divider,
    required this.accent,
    required this.link,
    required this.income,
    required this.expense,
  });

  factory _Pal.of(ExpenseController ctl) {
    final t = ctl.currentTheme;
    final dark = ctl.isDarkMode;
    return _Pal(
      bg: t.scaffoldBackground,
      card: t.cardBackground,
      text: t.textColor,
      sub: t.textSecondaryColor,
      body: dark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
      icon: dark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
      faint: dark ? Colors.white30 : const Color(0xFF9AA3B2),
      line: t.borderColor,
      strongLine: dark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
      divider: dark ? Colors.white10 : const Color(0xFFEEF0F4),
      accent: t.primaryColor,
      link: dark ? const Color(0xFF93C5FD) : t.primaryColor,
      income: dark ? const Color(0xFF34D399) : MeowTheme.incomeGreen,
      expense: dark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
    );
  }
}
