import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../services/native_bridge_service.dart';
import '../widgets/meow_fx.dart';

class PermissionOnboardingScreen extends StatefulWidget {
  final ExpenseController controller;
  final VoidCallback onFinish;

  /// Opened from เมนู: shows the real grant status and never resets saved choices.
  final bool fromMenu;

  const PermissionOnboardingScreen({
    super.key,
    required this.controller,
    required this.onFinish,
    this.fromMenu = false,
  });

  @override
  State<PermissionOnboardingScreen> createState() => _PermissionOnboardingScreenState();
}

class _PermissionOnboardingScreenState extends State<PermissionOnboardingScreen> with WidgetsBindingObserver {
  bool _storageAllowed = true;
  bool _audioAllowed = true;
  bool _notificationAllowed = true;
  bool _cameraAllowed = true;
  bool _busy = false;

  /// What the OS has actually granted ('storage', 'audio', 'notification', 'camera'); null until loaded.
  Map<String, bool>? _granted;

  /// Bank-notification reading (a special system setting); null until loaded.
  bool? _listenerOn;

  static const _keys = ['storage', 'audio', 'notification', 'camera'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the system settings: show what changed there.
    if (state == AppLifecycleState.resumed) _loadStatus();
  }

  Future<void> _loadStatus() async {
    final res = await NativeBridgeService.checkAppPermissions();
    final listener = widget.fromMenu ? await NativeBridgeService.isNotificationListenerGranted() : null;
    if (!mounted) return;
    setState(() {
      _granted = {
        for (final k in _keys)
          if (res[k] is bool) k: res[k] as bool,
      };
      _listenerOn = listener;
      // Already-granted permissions start switched on.
      if (_isGranted('storage')) _storageAllowed = true;
      if (_isGranted('audio')) _audioAllowed = true;
      if (_isGranted('notification')) _notificationAllowed = true;
      if (_isGranted('camera')) _cameraAllowed = true;
    });
  }

  bool _isGranted(String key) => _granted?[key] == true;

  bool _wanted(String key) => switch (key) {
        'storage' => _storageAllowed,
        'audio' => _audioAllowed,
        'notification' => _notificationAllowed,
        _ => _cameraAllowed,
      };

  void _setWanted(String key, bool v) => setState(() {
        switch (key) {
          case 'storage':
            _storageAllowed = v;
          case 'audio':
            _audioAllowed = v;
          case 'notification':
            _notificationAllowed = v;
          default:
            _cameraAllowed = v;
        }
      });

  void _showDeniedSnack() {
    final isEn = widget.controller.isEnglish;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(isEn
          ? 'Some permissions were not allowed. You can turn them on in Settings.'
          : 'ยังไม่ได้อนุญาตบางสิทธิ์ เปิดเองได้ที่การตั้งค่าของเครื่อง'),
      action: SnackBarAction(
        label: isEn ? 'Settings' : 'เปิดการตั้งค่า',
        onPressed: NativeBridgeService.openAppSettings,
      ),
    ));
  }

  /// Menu: ask for [ask] now, keep the saved choices in sync and stay on the page.
  Future<void> _request(List<String> ask) async {
    if (_busy || ask.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    final status = await NativeBridgeService.requestAppPermissions(only: ask);
    if (status['storage'] is bool) {
      final ok = status['storage'] as bool;
      await widget.controller.savePermissions(bankAlbum: ok, installedApps: true, mainAlbum: ok);
    }
    await _loadStatus();
    if (!mounted) return;
    setState(() => _busy = false);
    final denied = [for (final k in ask) if (status[k] == false) k];
    if (denied.isNotEmpty) {
      _showDeniedSnack();
    } else if (ask.every(_isGranted)) {
      final isEn = widget.controller.isEnglish;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(ask.length == 1
            ? (isEn ? 'Allowed: ${_info(ask.first, isEn).$1}' : 'อนุญาต${_info(ask.first, isEn).$1}แล้ว')
            : (isEn ? 'All permissions allowed' : 'อนุญาตครบทุกสิทธิ์แล้ว')),
      ));
    }
  }

  Future<void> _onConfirmAll() async {
    if (_busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    // Ask only for what is switched on and not granted yet.
    final ask = [for (final k in _keys) if (_wanted(k) && !_isGranted(k)) k];
    var status = <String, dynamic>{};
    if (ask.isNotEmpty) {
      status = await NativeBridgeService.requestAppPermissions(only: ask);
    }
    final storageOk = status['storage'] is bool ? status['storage'] as bool : (_isGranted('storage') || _storageAllowed);
    await widget.controller.savePermissions(
      bankAlbum: storageOk,
      installedApps: true,
      mainAlbum: storageOk,
    );
    final denied = [for (final k in ask) if (status[k] == false) k];
    if (!mounted) return;
    setState(() => _busy = false);
    if (denied.isNotEmpty) _showDeniedSnack();
    widget.onFinish();
  }

  Future<void> _onSkip() async {
    HapticFeedback.selectionClick();
    // From the menu, leaving must not wipe choices made earlier.
    if (!widget.fromMenu) {
      await widget.controller.savePermissions(
        bankAlbum: false,
        installedApps: false,
        mainAlbum: false,
      );
    }
    widget.onFinish();
  }

  /// (title, used for, icon, recommended)
  (String, String, IconData, bool) _info(String key, bool isEn) => switch (key) {
        'storage' => (
            isEn ? 'Photos & bank slips' : 'คลังรูปภาพและสลิปธนาคาร',
            isEn ? 'scan transfer slips and record them automatically' : 'สแกนสลิปโอนเงินเข้าแอพและจดบัญชีอัตโนมัติ',
            Icons.image_outlined,
            true,
          ),
        'audio' => (
            isEn ? 'Microphone' : 'ไมโครโฟน',
            isEn ? 'record by voice with AI' : 'พูดบันทึกด้วยเสียง AI',
            Icons.mic_none_rounded,
            false,
          ),
        'notification' => (
            isEn ? 'Notifications' : 'การแจ้งเตือน',
            isEn ? 'new-slip alerts & bill due dates' : 'แจ้งเตือนสลิปใหม่ & ตัดรอบบิล',
            Icons.notifications_none_rounded,
            false,
          ),
        _ => (
            isEn ? 'Camera' : 'กล้องถ่ายรูป',
            isEn ? 'scan slips / receipts live • scan the moving QR' : 'สแกนสลิปสด / ใบเสร็จ • สแกน QR ย้ายเครื่อง',
            Icons.photo_camera_outlined,
            false,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final isEn = widget.controller.isEnglish;
    final p = _Pal.of(widget.controller);
    final menu = widget.fromMenu;
    final n = _keys.where(_isGranted).length;
    final missing = [for (final k in _keys) if (!_isGranted(k)) k];
    final all = missing.isEmpty;
    final canPop = Navigator.canPop(context);

    final sections = <Widget>[
      _buildSummary(p, isEn, n, missing),
      _section(
        p,
        isEn ? 'App permissions' : 'สิทธิ์ของแอป',
        Container(
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.line)),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [for (var i = 0; i < _keys.length; i++) _buildPermRow(p, isEn, _keys[i], i == 0)]),
        ),
      ),
      if (menu) _section(p, isEn ? 'Special access (in phone settings)' : 'สิทธิ์พิเศษ (ตั้งค่าในเครื่อง)', _buildListenerCard(p, isEn)),
      if (menu) _buildDeniedHelp(p, isEn),
      _buildPrivacy(p, isEn),
    ];

    final String barLabel;
    final bool barEnabled;
    final VoidCallback barTap;
    if (menu) {
      barLabel = all
          ? (isEn ? 'All permissions allowed' : 'อนุญาตครบแล้ว')
          : (isEn ? 'Allow the rest (${missing.length})' : 'อนุญาตที่เหลือ (${missing.length})');
      barEnabled = !all;
      barTap = all ? widget.onFinish : () => _request(missing);
    } else {
      barLabel = isEn ? 'Allow & get started' : 'อนุญาตและเริ่มต้นใช้งาน';
      barEnabled = true;
      barTap = _onConfirmAll;
    }

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          _AppBarPlain(
            pal: p,
            title: menu
                ? (isEn ? 'Device Permissions' : 'สิทธิ์การเข้าถึงอุปกรณ์')
                : (isEn ? 'Convenience permissions' : 'อนุญาตสิทธิ์เพื่อความสะดวก'),
            subtitle: menu
                ? (isEn ? 'Turn on only what you need • change any time' : 'เปิดเฉพาะที่ต้องใช้ • เปลี่ยนได้ทุกเมื่อ')
                : (isEn ? 'For automatic slip scanning & smart alerts' : 'เพื่อให้เหมียวสแกนสลิปและแจ้งเตือนให้อัตโนมัติ'),
            showBack: menu || canPop,
            backLabel: isEn ? 'Back' : 'ย้อนกลับ',
            trailing: menu
                ? null
                : TextButton(
                    onPressed: _onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: p.sub,
                      minimumSize: const Size(44, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(isEn ? 'Skip' : 'ข้ามไปก่อน', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                for (var i = 0; i < sections.length; i++) ...[
                  if (i > 0) const SizedBox(height: 18),
                  FxFadeUp(index: i, child: sections[i]),
                ],
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: p.card, border: Border(top: BorderSide(color: p.line))),
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
            child: Semantics(
              button: true,
              enabled: barEnabled,
              child: FxPress(
                onTap: _busy ? null : barTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: barEnabled ? p.accent : p.line,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _busy
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: barEnabled ? Colors.white : p.sub),
                        )
                      : Text(barLabel,
                          style: TextStyle(
                              fontSize: 15.5, fontWeight: FontWeight.w600, color: barEnabled ? Colors.white : p.sub)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(_Pal p, String title, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.sub)),
          ),
          const SizedBox(height: 8),
          child,
        ],
      );

  Widget _buildSummary(_Pal p, bool isEn, int n, List<String> missing) {
    final total = _keys.length;
    final sub = missing.isEmpty
        ? (isEn ? 'All set — every feature can work' : 'ครบแล้ว ใช้ได้ทุกฟีเจอร์')
        : (isEn
            ? 'Missing: ${missing.map((k) => _info(k, isEn).$1).join(', ')} — related features will not work yet'
            : 'ยังขาด: ${missing.map((k) => _info(k, isEn).$1).join(', ')} — ฟีเจอร์ที่เกี่ยวข้องจะยังใช้ไม่ได้');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.line)),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: FxProgress(
              value: n / total,
              builder: (_, v) => CustomPaint(
                painter: _RingPainter(value: v, color: p.accent, track: p.divider),
                child: Center(
                  child: Text('$n/$total',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: p.text,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEn ? 'Allowed $n of $total' : 'อนุญาตแล้ว $n จาก $total',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.text)),
                const SizedBox(height: 3),
                Text(sub, style: TextStyle(fontSize: 12.5, height: 1.45, color: p.sub)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermRow(_Pal p, bool isEn, String key, bool first) {
    final (title, use, icon, rec) = _info(key, isEn);
    final ok = _isGranted(key);
    final menu = widget.fromMenu;
    final Widget trailing;
    if (ok) {
      trailing = Icon(Icons.check_rounded, size: 22, color: p.sub);
    } else if (menu) {
      trailing = OutlinedButton(
        onPressed: _busy ? null : () => _request([key]),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(76, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          foregroundColor: p.link,
          side: BorderSide(color: p.link),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(isEn ? 'Allow' : 'อนุญาต', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      );
    } else {
      trailing = Switch(
        value: _wanted(key),
        activeThumbColor: Colors.white,
        activeTrackColor: p.accent,
        onChanged: (v) {
          HapticFeedback.selectionClick();
          _setWanted(key, v);
        },
      );
    }
    final status = ok
        ? (isEn ? 'Allowed' : 'อนุญาตแล้ว')
        : menu
            ? (isEn ? 'Not allowed yet' : 'ยังไม่อนุญาต')
            : _wanted(key)
                ? (isEn ? 'Will ask when you continue' : 'จะขออนุญาตเมื่อกดเริ่มต้นใช้งาน')
                : (isEn ? 'Off for now' : 'ปิดไว้ก่อน');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 16), child: Icon(icon, size: 22, color: p.icon)),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 76),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: p.divider))),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.text)),
                            if (rec) _OutlinePill(pal: p, label: isEn ? 'Recommended' : 'แนะนำ', radius: 6),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(isEn ? 'Used for: $use' : 'ใช้กับ: $use',
                            style: TextStyle(fontSize: 12.5, height: 1.4, color: p.sub)),
                        const SizedBox(height: 2),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(status,
                              key: ValueKey(status),
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: ok ? p.sub : p.text)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: KeyedSubtree(key: ValueKey(ok), child: trailing)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListenerCard(_Pal p, bool isEn) {
    final on = _listenerOn;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.notifications_none_rounded, size: 22, color: p.icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(isEn ? 'Read bank notifications' : 'อ่านแจ้งเตือนธนาคาร',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.text)),
                        ),
                        if (on != null)
                          _OutlinePill(pal: p, label: on ? (isEn ? 'On' : 'เปิดอยู่') : (isEn ? 'Off' : 'ปิดอยู่')),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEn
                          ? 'Used for: recording income automatically when money comes in (K PLUS, SCB EASY, Krungthai NEXT …)'
                          : 'ใช้กับ: ดึงรายรับอัตโนมัติเมื่อมีเงินเข้า (K PLUS, SCB EASY, Krungthai NEXT …)',
                      style: TextStyle(fontSize: 12.5, height: 1.4, color: p.sub),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: _OutlineAction(
              pal: p,
              label: isEn ? 'Open settings' : 'เปิดการตั้งค่า',
              onTap: () {
                HapticFeedback.selectionClick();
                NativeBridgeService.openNotificationListenerSettings();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeniedHelp(_Pal p, bool isEn) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 22, color: p.icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        isEn
                            ? 'Said no before? Turn it on in phone settings'
                            : 'ถ้าเคยกดปฏิเสธ ต้องเปิดเองในการตั้งค่าเครื่อง',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: p.text)),
                    const SizedBox(height: 2),
                    Text(
                        isEn
                            ? 'Go to Settings › Apps › MeowTang › Permissions and turn on what you need'
                            : 'ไปที่ ตั้งค่า › แอป › เหมียวตังค์ › สิทธิ์ แล้วเปิดสิทธิ์ที่ต้องการ',
                        style: TextStyle(fontSize: 12.5, height: 1.5, color: p.sub)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: _OutlineAction(
              pal: p,
              label: isEn ? 'Open phone settings' : 'เปิดการตั้งค่าเครื่อง',
              onTap: () {
                HapticFeedback.selectionClick();
                NativeBridgeService.openAppSettings();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacy(_Pal p, bool isEn) {
    final points = isEn
        ? ['Slip photos are never uploaded to a server', 'Speech is turned into text on your phone', 'Only bank-app notifications are read']
        : ['ไม่อัปโหลดรูปสลิปขึ้นเซิร์ฟเวอร์', 'เสียงพูดแปลงเป็นข้อความในเครื่อง', 'อ่านเฉพาะแจ้งเตือนจากแอปธนาคาร'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline_rounded, size: 22, color: p.icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEn ? '100% private' : 'ปลอดภัย 100%',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: p.text)),
                    const SizedBox(height: 2),
                    Text(
                        isEn
                            ? 'Slip photos and all your data are processed on this phone and never leave it'
                            : 'รูปสลิปและข้อมูลทั้งหมดประมวลผลในเครื่อง ไม่ส่งออกภายนอก',
                        style: TextStyle(fontSize: 12.5, height: 1.45, color: p.sub)),
                  ],
                ),
              ),
            ],
          ),
          for (final t in points)
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 8),
              child: Row(
                children: [
                  Icon(Icons.check_rounded, size: 16, color: p.sub),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t, style: TextStyle(fontSize: 13, color: p.body))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color track;
  const _RingPainter({required this.value, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final r = (math.min(size.width, size.height) - stroke) / 2;
    final c = size.center(Offset.zero);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(c, r, base);
    if (value <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * value.clamp(0.0, 1.0), false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.value != value || old.color != color || old.track != track;
}

class _OutlinePill extends StatelessWidget {
  final _Pal pal;
  final String label;
  final double radius;
  const _OutlinePill({required this.pal, required this.label, this.radius = 10});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius), border: Border.all(color: pal.strongLine)),
        child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: pal.body)),
      );
}

class _OutlineAction extends StatelessWidget {
  final _Pal pal;
  final String label;
  final VoidCallback onTap;
  const _OutlineAction({required this.pal, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          foregroundColor: pal.link,
          side: BorderSide(color: pal.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      );
}

/// White app bar: 44px back chevron, left-aligned title and a one-line subtitle.
class _AppBarPlain extends StatelessWidget {
  final _Pal pal;
  final String title;
  final String subtitle;
  final String backLabel;
  final bool showBack;
  final Widget? trailing;

  const _AppBarPlain({
    required this.pal,
    required this.title,
    required this.subtitle,
    required this.backLabel,
    this.showBack = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final p = pal;
    return Container(
      decoration: BoxDecoration(color: p.card, border: Border(bottom: BorderSide(color: p.line))),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: EdgeInsets.fromLTRB(showBack ? 4 : 16, 8, trailing == null ? 16 : 8, 8),
          child: Row(
            children: [
              if (showBack) ...[
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  tooltip: backLabel,
                  icon: Icon(Icons.chevron_left_rounded, size: 30, color: p.text),
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
                const SizedBox(width: 4),
              ],
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
  final Color bg, card, text, sub, body, icon, line, strongLine, divider, accent, link;

  const _Pal({
    required this.bg,
    required this.card,
    required this.text,
    required this.sub,
    required this.body,
    required this.icon,
    required this.line,
    required this.strongLine,
    required this.divider,
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
      body: dark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
      icon: dark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
      line: t.borderColor,
      strongLine: dark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
      divider: dark ? Colors.white10 : const Color(0xFFEEF0F4),
      accent: t.primaryColor,
      link: dark ? const Color(0xFF93C5FD) : t.primaryColor,
    );
  }
}
