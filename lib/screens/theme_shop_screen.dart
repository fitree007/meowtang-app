import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/app_theme_model.dart';
import '../widgets/meow_fx.dart';
import '../widgets/meow_paywall_modal.dart';
import '../config/app_config.dart';

class ThemeShopScreen extends StatefulWidget {
  final ExpenseController controller;

  const ThemeShopScreen({super.key, required this.controller});

  @override
  State<ThemeShopScreen> createState() => _ThemeShopScreenState();
}

class _ThemeShopScreenState extends State<ThemeShopScreen> {
  int _tab = 0;

  static const _cats = [ThemeCategory.classic, ThemeCategory.minimal, ThemeCategory.cute];

  ExpenseController get _c => widget.controller;
  bool get _isEn => _c.isEnglish;
  String _name(AppThemeModel t) => _isEn ? t.nameEn : t.name;
  String _catLabel(int i) => switch (i) {
        0 => _isEn ? 'Classic' : 'คลาสสิค',
        1 => _isEn ? 'Minimal' : 'มินิมอล',
        _ => _isEn ? 'Cute' : 'น่ารัก',
      };

  /// The theme saved by the user (not the one being tried).
  AppThemeModel get _savedTheme => AppThemePresets.getById(_c.storage.getCurrentThemeId(), isDark: _c.isDarkMode);

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  Future<void> _buy(AppThemeModel theme) async {
    HapticFeedback.mediumImpact();
    await _c.purchaseTheme(theme.id);
    if (_c.testDriveThemeId == theme.id) _c.cancelThemeTestDrive();
    _snack(_isEn
        ? 'Bought ${_name(theme)} — yours for life, and it is now in use'
        : 'ซื้อ ${_name(theme)} แล้ว — ใช้ได้ตลอดชีพ และเปลี่ยนเป็นธีมนี้ให้แล้ว');
  }

  void _openVip() {
    MeowPaywallModal.show(
      context,
      controller: _c,
      reason: 'สมัคร VIP เพื่อปลดล็อคทุกธีมและดึงสลิปไม่จำกัด',
    );
  }

  void _showTestDriveExpiredDialog(AppThemeModel theme) {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    final p = _Pal.of(_c);
    final isEn = _isEn;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: p.card,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_off_outlined, size: 28, color: p.icon),
              const SizedBox(height: 8),
              Text(isEn ? 'Your 30-second trial is over' : 'หมดเวลาทดลองใช้ 30 วิ',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.text)),
              const SizedBox(height: 8),
              Text(
                isEn
                    ? 'You are back on ${_name(_savedTheme)} • Like ${_name(theme)}? Buy it once for ฿${AppConfig.themePriceThb} and keep it for life'
                    : 'ตอนนี้กลับเป็น ${_name(_savedTheme)} แล้ว • ชอบ ${_name(theme)} ไหม? ซื้อครั้งเดียว ฿${AppConfig.themePriceThb} ใช้ได้ตลอดชีพ',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, height: 1.5, color: p.sub),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _OutlineButton(
                      pal: p,
                      label: isEn ? 'Maybe later' : 'ไว้คราวหน้า',
                      height: 48,
                      onTap: () => Navigator.pop(ctx),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PrimaryButton(
                      pal: p,
                      height: 48,
                      radius: 14,
                      label: isEn ? 'Buy ฿${AppConfig.themePriceThb}' : 'ซื้อ ฿${AppConfig.themePriceThb}',
                      onTap: () {
                        Navigator.pop(ctx);
                        _buy(theme);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLockedThemeOptions(AppThemeModel theme) {
    HapticFeedback.selectionClick();
    final p = _Pal.of(_c);
    final isEn = _isEn;
    final preview = theme.copyWithMode(_c.isDarkMode);

    showModalBottomSheet(
      context: context,
      backgroundColor: p.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_name(theme), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.text)),
                        const SizedBox(height: 2),
                        Text(
                          isEn
                              ? '${_catLabel(_cats.indexOf(theme.category))} theme • not unlocked yet'
                              : 'ธีม${_catLabel(_cats.indexOf(theme.category))} • ยังไม่ปลดล็อค',
                          style: TextStyle(fontSize: 13, color: p.sub),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: p.seg,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(ctx),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.close_rounded, size: 22, color: p.sub, semanticLabel: isEn ? 'Close' : 'ปิด'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: preview.scaffoldBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: p.divider),
                ),
                alignment: Alignment.center,
                child: _PhonePreview(theme: preview, width: 118, height: 196, large: true),
              ),
              const SizedBox(height: 12),
              _OutlineButton(
                pal: p,
                height: 52,
                radius: 16,
                strong: true,
                icon: Icons.timer_outlined,
                label: isEn ? 'Try for 30 seconds (free)' : 'ทดลอง 30 วินาที (ฟรี)',
                onTap: () {
                  Navigator.pop(ctx);
                  _c.startThemeTestDrive(
                    theme.id,
                    onExpired: () => _showTestDriveExpiredDialog(theme),
                  );
                },
              ),
              const SizedBox(height: 12),
              _PrimaryButton(
                pal: p,
                height: 56,
                label: isEn ? 'Buy this theme ฿${AppConfig.themePriceThb}' : 'ซื้อธีมนี้ ฿${AppConfig.themePriceThb}',
                sub: isEn ? 'Pay once, use for life' : 'จ่ายครั้งเดียว ใช้ได้ตลอดชีพ',
                onTap: () {
                  Navigator.pop(ctx);
                  _buy(theme);
                },
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openVip();
                  },
                  style: TextButton.styleFrom(foregroundColor: p.link),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isEn ? 'Or unlock every theme with' : 'หรือปลดล็อคทุกธีมด้วย',
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      _VipBadge(color: p.link),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final p = _Pal.of(_c);
        final isEn = _isEn;
        final isDark = _c.isDarkMode;
        final vip = _c.isPremium;
        final trialId = _c.testDriveThemeId;
        final unlocked = AppThemePresets.allThemes.where((t) => t.id != trialId && _c.isThemeUnlocked(t.id)).length;
        final total = AppThemePresets.allThemes.length;
        final themes = AppThemePresets.getThemesByCategory(_cats[_tab]);

        return Scaffold(
          backgroundColor: p.bg,
          body: Column(
            children: [
              _AppBarPlain(
                pal: p,
                title: isEn ? 'Theme shop' : 'ร้านค้าธีม',
                subtitle: vip
                    ? (isEn ? '$total themes • all unlocked with VIP' : '$total ธีม • ปลดล็อคครบด้วย VIP')
                    : (isEn ? '$total themes • $unlocked unlocked' : '$total ธีม • ปลดล็อคแล้ว $unlocked ธีม'),
                backLabel: isEn ? 'Back' : 'ย้อนกลับ',
                trailing: IconButton(
                  icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 22, color: p.icon),
                  tooltip: isDark
                      ? (isEn ? 'Switch to light mode' : 'เปลี่ยนเป็นโหมดสว่าง')
                      : (isEn ? 'Switch to dark mode' : 'เปลี่ยนเป็นโหมดมืด'),
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _c.setDarkMode(!isDark);
                  },
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  children: [
                    FxFadeUp(index: 0, child: _buildHero(p, trialId)),
                    const SizedBox(height: 14),
                    FxFadeUp(
                      index: 1,
                      child: _Segmented(
                        pal: p,
                        selected: _tab,
                        labels: [for (var i = 0; i < 3; i++) _catLabel(i)],
                        onSelect: (i) {
                          HapticFeedback.selectionClick();
                          setState(() => _tab = i);
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        isEn ? '${_catLabel(_tab)} themes • ${themes.length}' : 'ธีม${_catLabel(_tab)} • ${themes.length} ธีม',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.sub),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildGrid(p, themes, trialId),
                    if (!vip) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: p.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: p.line),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, size: 20, color: p.sub),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text.rich(
                                TextSpan(children: [
                                  TextSpan(text: isEn ? 'Tap a locked theme to ' : 'แตะธีมที่ล็อคไว้เพื่อ '),
                                  TextSpan(
                                    text: isEn ? 'try it free for 30 seconds' : 'ทดลองใช้ฟรี 30 วินาที',
                                    style: TextStyle(color: p.text, fontWeight: FontWeight.w600),
                                  ),
                                  TextSpan(
                                      text: isEn
                                          ? ' before you decide. Bought themes are yours for life.'
                                          : ' ก่อนตัดสินใจ ธีมที่ซื้อแล้วใช้ได้ตลอดชีพ'),
                                ]),
                                style: TextStyle(fontSize: 12.5, height: 1.5, color: p.sub),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!vip)
                Container(
                  decoration: BoxDecoration(color: p.card, border: Border(top: BorderSide(color: p.line))),
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 14 + MediaQuery.of(context).padding.bottom),
                  child: _PrimaryButton(
                    pal: p,
                    height: 52,
                    label: isEn ? 'Unlock all $total themes with' : 'ปลดล็อคทุก $total ธีมด้วย',
                    badge: true,
                    onTap: _openVip,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHero(_Pal p, String? trialId) {
    final isEn = _isEn;
    final trial = trialId != null;
    final shown = _c.currentTheme;
    final secs = _c.testDriveRemainingSeconds;
    final label = trial
        ? (isEn ? 'Trying now • ${secs}s left' : 'กำลังทดลองใช้ • เหลือ 0:${secs.toString().padLeft(2, '0')}')
        : (isEn ? 'In use' : 'ใช้อยู่');
    final note = trial
        ? (isEn ? 'When time is up you go back to ${_name(_savedTheme)}' : 'หมดเวลาแล้วจะกลับเป็น ${_name(_savedTheme)} อัตโนมัติ')
        : (isEn
            ? 'Tap a theme below to preview it. Unlocked themes apply right away.'
            : 'แตะธีมด้านล่างเพื่อดูตัวอย่าง ธีมที่ปลดล็อคแล้วกดใช้ได้ทันที');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.line)),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: _PhonePreview(key: ValueKey(shown.id), theme: shown, width: 64, height: 92, compact: true),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (trial) ...[Icon(Icons.timer_outlined, size: 16, color: p.sub), const SizedBox(width: 6)],
                    Flexible(child: Text(label, style: TextStyle(fontSize: 12.5, color: p.sub))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(_name(shown), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.text)),
                const SizedBox(height: 4),
                Text(note, style: TextStyle(fontSize: 12.5, height: 1.4, color: p.sub)),
                if (trial) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _SmallButton(
                        pal: p,
                        primary: true,
                        label: isEn ? 'Buy ฿${AppConfig.themePriceThb}' : 'ซื้อ ฿${AppConfig.themePriceThb}',
                        onTap: () => _buy(shown),
                      ),
                      _SmallButton(
                        pal: p,
                        label: isEn ? 'Stop trial' : 'เลิกทดลอง',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _c.cancelThemeTestDrive();
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(_Pal p, List<AppThemeModel> themes, String? trialId) {
    final isEn = _isEn;
    final isDark = _c.isDarkMode;
    final savedId = _c.storage.getCurrentThemeId();
    final cards = <Widget>[];
    for (var i = 0; i < themes.length; i++) {
      final theme = themes[i].copyWithMode(isDark);
      final isTrial = trialId == theme.id;
      final inUse = theme.id == savedId;
      final owned = !isTrial && _c.isThemeUnlocked(theme.id);
      final selected = isTrial || (trialId == null && inUse);
      final (chip, chipColor, chipWeight, chipIcon) = isTrial
          ? (isEn ? 'Trying' : 'กำลังทดลอง', p.text, FontWeight.w600, Icons.timer_outlined)
          : inUse
              ? (isEn ? 'In use' : 'ใช้งานอยู่', p.link, FontWeight.w600, Icons.check_rounded)
              : owned
                  ? (isEn ? 'Unlocked' : 'ปลดล็อคแล้ว', p.sub, FontWeight.w400, null)
                  : ('฿${AppConfig.themePriceThb}', p.text, FontWeight.w600, Icons.lock_outline_rounded);

      cards.add(FxFadeUp(
        key: ValueKey('${_tab}_${theme.id}'),
        index: 2 + i ~/ 2,
        child: Semantics(
          button: true,
          selected: selected,
          label: '${_name(theme)} • $chip',
          child: FxPress(
            onTap: () {
              if (owned) {
                HapticFeedback.selectionClick();
                if (_c.isThemeInTestDrive) _c.cancelThemeTestDrive();
                final changed = theme.id != _c.storage.getCurrentThemeId();
                _c.setTheme(theme.id);
                if (changed) _snack(isEn ? 'Switched to ${_name(theme)}' : 'เปลี่ยนเป็น ${_name(theme)} แล้ว');
              } else {
                _showLockedThemeOptions(theme);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(selected ? 10 : 11),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? p.link : p.line, width: selected ? 2 : 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 128,
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: p.divider),
                    ),
                    alignment: Alignment.center,
                    child: _PhonePreview(theme: theme, width: 70, height: 112),
                  ),
                  const SizedBox(height: 8),
                  Text(_name(theme),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.5, height: 1.3, fontWeight: FontWeight.w600, color: p.text)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (chipIcon != null) ...[Icon(chipIcon, size: 16, color: chipColor), const SizedBox(width: 4)],
                      Flexible(
                          child: Text(chip, style: TextStyle(fontSize: 12.5, fontWeight: chipWeight, color: chipColor))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ));
    }
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += 2) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: cards[i]),
            const SizedBox(width: 12),
            Expanded(child: i + 1 < cards.length ? cards[i + 1] : const SizedBox()),
          ],
        ),
      ));
    }
    return Column(children: rows);
  }
}

// ---------------------------------------------------------------------------
// Private building blocks
// ---------------------------------------------------------------------------

/// A tiny phone drawn in the theme's own colours (header, cards, accent pill).
class _PhonePreview extends StatelessWidget {
  final AppThemeModel theme;
  final double width;
  final double height;
  final bool compact;
  final bool large;

  const _PhonePreview({super.key, required this.theme, required this.width, required this.height, this.compact = false, this.large = false});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final hdr = t.isDark ? t.primaryDark : t.primaryColor;
    final hdrFg = t.isHeroLight(t.isDark) ? t.textColor : Colors.white;
    final accent = t.primaryLight;
    final card = t.cardBackground;
    final line = t.borderColor;
    final s = large ? 1.6 : 1.0;
    Widget bar(double w, double h, Color c, {double r = 3}) =>
        Container(width: w, height: h, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(r)));

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.scaffoldBackground,
        borderRadius: BorderRadius.circular(compact ? 12 : 12 * (large ? 1.5 : 1)),
        border: Border.all(color: const Color(0x1F0F172A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: compact ? 22 : 24 * s,
            color: hdr,
            padding: EdgeInsets.symmetric(horizontal: 6 * s),
            alignment: Alignment.centerLeft,
            child: compact ? null : bar(26 * s, 5 * s, hdrFg.withValues(alpha: 0.8)),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(6 * s, 7 * s, 6 * s, 0),
            height: compact ? 26 : 30 * s,
            padding: EdgeInsets.symmetric(horizontal: 6 * s),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(7 * s)),
            child: compact
                ? null
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [bar(34 * s, 4 * s, line), SizedBox(height: 4 * s), bar(22 * s, 4 * s, line)],
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(6 * s, 6 * s, 0, 0),
            child: bar(compact ? 30 : 32 * s, compact ? 10 : 11 * s, accent, r: 6 * s),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(6 * s, 6 * s, 6 * s, 0),
            height: compact ? 12 : 14 * s,
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(5 * s)),
          ),
          if (large)
            Container(
              margin: EdgeInsets.fromLTRB(6 * s, 6 * s, 6 * s, 0),
              height: 14 * s,
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(5 * s)),
            ),
        ],
      ),
    );
  }
}

class _VipBadge extends StatelessWidget {
  final Color color;
  const _VipBadge({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: color)),
        child: Text('VIP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: color)),
      );
}

class _SmallButton extends StatelessWidget {
  final _Pal pal;
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _SmallButton({required this.pal, required this.label, required this.onTap, this.primary = false});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    return IntrinsicWidth(child: Material(
      color: primary ? p.accent : p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: primary ? BorderSide.none : BorderSide(color: p.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: primary ? FontWeight.w600 : FontWeight.w500, color: primary ? Colors.white : p.sub)),
        ),
      ),
    ));
  }
}

class _OutlineButton extends StatelessWidget {
  final _Pal pal;
  final String label;
  final double height;
  final double radius;
  final bool strong;
  final IconData? icon;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.pal,
    required this.label,
    required this.onTap,
    this.height = 48,
    this.radius = 14,
    this.strong = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final p = pal;
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: strong ? p.strongLine : p.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 20, color: p.icon), const SizedBox(width: 8)],
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: strong ? 15 : 14, fontWeight: FontWeight.w600, color: p.text)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final _Pal pal;
  final String label;
  final String? sub;
  final bool badge;
  final double height;
  final double radius;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.pal,
    required this.label,
    required this.onTap,
    this.sub,
    this.badge = false,
    this.height = 52,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: FxPress(
        onTap: onTap,
        child: Container(
          height: height,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: pal.accent, borderRadius: BorderRadius.circular(radius)),
          child: sub != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                    Text(sub!, style: const TextStyle(fontSize: 12, color: Color(0xD9FFFFFF))),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                    if (badge) ...[const SizedBox(width: 8), const _VipBadge(color: Colors.white)],
                  ],
                ),
        ),
      ),
    );
  }
}

/// Grey track with a white sliding pill (animated) — the draft's segmented control.
class _Segmented extends StatelessWidget {
  final _Pal pal;
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  const _Segmented({required this.pal, required this.labels, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: p.seg, borderRadius: BorderRadius.circular(14)),
      child: LayoutBuilder(builder: (context, c) {
        final w = (c.maxWidth - 4 * (labels.length - 1)) / labels.length;
        return SizedBox(
          height: 44,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: selected * (w + 4),
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: const [BoxShadow(color: Color(0x140F172A), blurRadius: 2, offset: Offset(0, 1))],
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    SizedBox(
                      width: w,
                      child: Semantics(
                        button: true,
                        selected: i == selected,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onSelect(i),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 180),
                              style: TextStyle(
                                fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                                fontSize: 14,
                                fontWeight: i == selected ? FontWeight.w600 : FontWeight.w500,
                                color: i == selected ? p.link : p.sub,
                              ),
                              child: Text(labels[i], maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// White app bar: 44px back chevron, left-aligned title and a one-line subtitle.
class _AppBarPlain extends StatelessWidget {
  final _Pal pal;
  final String title;
  final String subtitle;
  final String backLabel;
  final Widget? trailing;

  const _AppBarPlain({required this.pal, required this.title, required this.subtitle, required this.backLabel, this.trailing});

  @override
  Widget build(BuildContext context) {
    final p = pal;
    return Container(
      decoration: BoxDecoration(color: p.card, border: Border(bottom: BorderSide(color: p.line))),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: EdgeInsets.fromLTRB(4, 8, trailing == null ? 16 : 8, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
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
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Neutral palette derived from the active theme (same mapping as the menu).
class _Pal {
  final Color bg, card, text, sub, icon, line, strongLine, divider, seg, accent, link;

  const _Pal({
    required this.bg,
    required this.card,
    required this.text,
    required this.sub,
    required this.icon,
    required this.line,
    required this.strongLine,
    required this.divider,
    required this.seg,
    required this.accent,
    required this.link,
  });

  factory _Pal.of(ExpenseController ctl) {
    final t = ctl.currentTheme;
    final dark = ctl.isDarkMode;
    return _Pal(
      bg: t.scaffoldBackground,
      card: t.cardBackground,
      text: t.textColor,
      sub: t.textSecondaryColor,
      icon: dark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
      line: t.borderColor,
      strongLine: dark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
      divider: dark ? Colors.white10 : const Color(0xFFEEF0F4),
      seg: dark ? const Color(0xFF0F172A) : const Color(0xFFF1F3F8),
      accent: t.primaryColor,
      link: dark ? const Color(0xFF93C5FD) : t.primaryColor,
    );
  }
}
