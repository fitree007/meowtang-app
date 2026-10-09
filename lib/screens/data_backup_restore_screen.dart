import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../state/expense_controller.dart';
import '../services/data_backup_service.dart';
import '../services/native_bridge_service.dart';
import '../widgets/meow_fx.dart';
import '../widgets/qr_code_display_widget.dart';

class DataBackupRestoreScreen extends StatefulWidget {
  final ExpenseController controller;

  const DataBackupRestoreScreen({super.key, required this.controller});

  @override
  State<DataBackupRestoreScreen> createState() => _DataBackupRestoreScreenState();
}

class _DataBackupRestoreScreenState extends State<DataBackupRestoreScreen> {
  int _tab = 0; // 0 = file, 1 = QR

  bool _isProcessing = false;
  String? _lastSavedFilePath;
  DateTime? _lastSavedAt;

  // P2P Transfer Server State (Sender)
  DataTransferServer? _p2pServer;
  String? _localIp;
  String _pinCode = '8829';
  bool _isServerRunning = false;
  bool _noNetwork = false; // no Wi-Fi/LAN address, so the phone cannot be reached

  // P2P Receiver Manual Input Controllers
  final TextEditingController _ipInputController = TextEditingController();
  final TextEditingController _pinInputController = TextEditingController();
  int _p2pModeIndex = 0; // 0 = Sender, 1 = Receiver
  bool _advOpen = false;
  String? _manualError;

  static final _nf = NumberFormat('#,##0', 'en_US');
  static const _thMonths = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
  static String _thDate(DateTime d) => '${d.day} ${_thMonths[d.month - 1]} ${d.year + 543}';
  static String _hm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _generateRandomPin();
  }

  void _generateRandomPin() {
    final rand = (1000 + Random.secure().nextInt(9000)).toString();
    setState(() => _pinCode = rand);
  }

  void _selectTab(int i) {
    if (i == _tab) return;
    HapticFeedback.selectionClick();
    setState(() => _tab = i);
    if (i == 1 && _p2pModeIndex == 0) {
      _startP2pServer();
    } else {
      _stopP2pServer();
    }
  }

  @override
  void dispose() {
    _stopP2pServer();
    _ipInputController.dispose();
    _pinInputController.dispose();
    super.dispose();
  }

  Future<void> _startP2pServer() async {
    if (_p2pServer != null) return; // already running
    setState(() => _isProcessing = true);
    _localIp = await DataBackupService.getLocalIpAddress();

    if (_localIp == null || _localIp!.isEmpty) {
      // Without a Wi-Fi address the other phone cannot connect; say so instead of showing a fake IP.
      if (mounted) {
        setState(() {
          _localIp = null;
          _noNetwork = true;
          _isServerRunning = false;
          _isProcessing = false;
        });
      }
      return;
    }
    _noNetwork = false;

    _p2pServer = DataTransferServer(
      storage: widget.controller.storage,
      pinCode: _pinCode,
    );

    final port = await _p2pServer?.start();
    if (mounted) {
      setState(() {
        _isServerRunning = port != null;
        _isProcessing = false;
      });
    }
  }

  Future<void> _stopP2pServer() async {
    await _p2pServer?.stop();
    _p2pServer = null;
    if (mounted) {
      setState(() => _isServerRunning = false);
    }
  }

  // ==========================================================
  // FILE BACKUP ACTIONS
  // ==========================================================
  Future<void> _handleSaveToDownloads() async {
    HapticFeedback.mediumImpact();
    setState(() => _isProcessing = true);

    try {
      final savedPath = await DataBackupService.saveBackupToDeviceDownloads(widget.controller.storage);
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _lastSavedFilePath = savedPath;
          if (savedPath != null) _lastSavedAt = DateTime.now();
        });

        if (savedPath != null) {
          _calmToast(context, 'บันทึกไฟล์สำรองแล้ว • $savedPath');
        } else {
          _calmToast(context, 'ไม่สามารถบันทึกไฟล์ลงเครื่องได้ กรุณาตรวจสอบสิทธิ์การเข้าถึง', error: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _calmToast(context, 'เกิดข้อผิดพลาด: $e', error: true);
      }
    }
  }

  Future<void> _handleShareBackupFile() async {
    HapticFeedback.mediumImpact();
    setState(() => _isProcessing = true);

    try {
      final file = await DataBackupService.createBackupFile(widget.controller.storage);
      final ok = await DataBackupService.shareBackupFile(file);

      if (mounted) {
        setState(() => _isProcessing = false);
        if (!ok) {
          _calmToast(context, 'แชร์ไฟล์ไม่สำเร็จ ลองใหม่อีกครั้ง หรือใช้ "บันทึกไฟล์สำรองลงเครื่อง" แทน', error: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _calmToast(context, 'เกิดข้อผิดพลาดในการแชร์: $e', error: true);
      }
    }
  }

  Future<void> _handlePickAndRestoreFile() async {
    HapticFeedback.selectionClick();
    setState(() => _isProcessing = true);

    try {
      final backupData = await DataBackupService.pickAndParseBackupFile();
      if (mounted) {
        setState(() => _isProcessing = false);

        if (backupData != null) {
          _showRestoreConfirmationModal(backupData);
        } else {
          _calmToast(context, 'ไม่พบข้อมูลสำรองที่ถูกต้อง หรือยกเลิกการเลือกไฟล์');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _calmToast(context, 'เกิดข้อผิดพลาดในการอ่านไฟล์: $e', error: true);
      }
    }
  }

  // ==========================================================
  // RESTORE CONFIRMATION & EXECUTION
  // ==========================================================
  Widget _statRow(_C c, List<(String, String)> items) => Row(
        children: [
          for (final s in items)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(s.$1,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.text, fontFeatures: const [FontFeature.tabularFigures()])),
                  ),
                  Text(s.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: c.sub)),
                ],
              ),
            ),
        ],
      );

  List<(String, String)> _currentStats() {
    final ctl = widget.controller;
    return [
      (_nf.format(ctl.allTransactions.length), 'รายการ'),
      (_nf.format(ctl.accounts.length), 'บัญชี'),
      (_nf.format(ctl.categories.length), 'หมวดหมู่'),
      (_nf.format(ctl.savingGoals.length), 'เป้าหมาย'),
    ];
  }

  void _showRestoreConfirmationModal(Map<String, dynamic> data, {bool fromPeer = false}) {
    final c = _C.of(widget.controller);
    final txCount = (data['transactions'] as List?)?.length ?? 0;
    final accCount = (data['accounts'] as List?)?.length ?? 0;
    final catCount = (data['categories'] as List?)?.length ?? 0;
    final goalCount = (data['savingGoals'] as List?)?.length ?? 0;
    final exported = DateTime.tryParse(data['exportedAt'] as String? ?? '')?.toLocal();
    final src = fromPeer
        ? 'รับจากเครื่องเดิมผ่าน Wi-Fi${exported != null ? ' • ข้อมูล ณ ${_thDate(exported)}' : ''}'
        : (exported != null ? 'ไฟล์สำรองเมื่อ ${_thDate(exported)} เวลา ${_hm(exported)}' : 'ไฟล์สำรอง (ไม่ระบุวันที่)');

    Widget option({required IconData icon, required String title, required String sub, required bool primary, required VoidCallback onTap}) {
      final fg = primary ? Colors.white : c.danger;
      return Material(
        color: primary ? c.accent : c.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: primary ? null : Border.all(color: c.danger.withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: fg),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: fg)),
                      Text(sub, style: TextStyle(fontSize: 12.5, color: primary ? Colors.white.withValues(alpha: 0.85) : c.sub)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    _showCalmSheet<void>(context, c, title: 'พบข้อมูลสำรองที่ถูกต้อง', subtitle: src, builder: (ctx, _) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _calmCard(
            c,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: _statRow(c, [
              (_nf.format(txCount), 'รายการ'),
              (_nf.format(accCount), 'บัญชี'),
              (_nf.format(catCount), 'หมวดหมู่'),
              (_nf.format(goalCount), 'เป้าหมาย'),
            ]),
          ),
          const SizedBox(height: 16),
          Text('จะกู้คืนแบบไหน?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.sub)),
          const SizedBox(height: 8),
          // Option 1 (safe, default): merge into what is already on this phone
          option(
            icon: Icons.merge_type_rounded,
            title: 'ผสานรวมข้อมูล (แนะนำ)',
            sub: 'เก็บข้อมูลในเครื่องนี้ไว้ + เพิ่มจากไฟล์ (ไม่ซ้ำ)',
            primary: true,
            onTap: () {
              Navigator.pop(ctx);
              _executeRestore(data, replaceAll: false);
            },
          ),
          const SizedBox(height: 10),
          // Option 2 (destructive): replace everything, asks again first
          option(
            icon: Icons.delete_outline_rounded,
            title: 'เขียนทับทั้งหมด',
            sub: 'ลบข้อมูลในเครื่องนี้ แล้วใช้ข้อมูลจากไฟล์แทน',
            primary: false,
            onTap: () {
              Navigator.pop(ctx);
              _confirmReplaceAll(data, fromPeer: fromPeer);
            },
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('ยกเลิก', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: c.sub)),
            ),
          ),
        ],
      );
    });
  }

  /// Second confirmation before wiping this phone's data; a safety backup is saved first.
  Future<void> _confirmReplaceAll(Map<String, dynamic> data, {bool fromPeer = false}) async {
    final ctl = widget.controller;
    final c = _C.of(ctl);
    final txNow = ctl.allTransactions.length;
    final accNow = ctl.accounts.length;
    final stats = _currentStats();

    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 14),
              Row(children: [
                Icon(Icons.warning_amber_rounded, size: 26, color: c.danger),
                const SizedBox(width: 10),
                Expanded(child: Text('ยืนยันเขียนทับทั้งหมด?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text))),
              ]),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Text('ข้อมูลต่อไปนี้ในเครื่องนี้จะถูกลบ และแทนที่ด้วยข้อมูลจากไฟล์สำรอง ย้อนกลับไม่ได้',
                    style: TextStyle(fontSize: 13.5, height: 1.45, color: c.sub)),
              ),
              const SizedBox(height: 14),
              _calmCard(
                c,
                child: Column(
                  children: [
                    for (var i = 0; i < stats.length; i++)
                      Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: c.border))),
                        child: Row(children: [
                          Expanded(child: Text(stats[i].$2, style: TextStyle(fontSize: 14, color: c.text))),
                          Text(stats[i].$1, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                        ]),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // The safety backup is always made (it is what makes overwriting recoverable).
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('สำรองข้อมูลปัจจุบันให้อัตโนมัติก่อน', style: c.title.copyWith(fontSize: 14.5)),
                        Text('บันทึกไว้ในโฟลเดอร์ Download • กู้กลับได้ถ้าเปลี่ยนใจ', style: c.subtitle),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _primaryButton(c, 'ลบและเขียนทับทั้งหมด', () => Navigator.pop(ctx, 'overwrite'), color: c.danger),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, 'merge'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: c.line),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('กลับไปเลือก “ผสานรวม” แทน', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: c.link)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (choice == 'merge') {
      _showRestoreConfirmationModal(data, fromPeer: fromPeer);
      return;
    }
    if (choice != 'overwrite') return;

    if (txNow + accNow > 0) {
      setState(() => _isProcessing = true);
      String? safety;
      try {
        safety = await DataBackupService.saveBackupToDeviceDownloads(ctl.storage);
      } catch (_) {
        safety = null;
      }
      if (!mounted) return;
      if (safety == null) {
        setState(() => _isProcessing = false);
        _calmToast(context, 'สำรองข้อมูลเดิมไม่สำเร็จ จึงยกเลิกการเขียนทับเพื่อไม่ให้ข้อมูลหาย (ลอง "ผสานรวม" แทนได้)', error: true);
        return;
      }
      _lastSavedFilePath = safety;
      _lastSavedAt = DateTime.now();
    }
    await _executeRestore(data, replaceAll: true);
  }

  Future<void> _executeRestore(Map<String, dynamic> data, {required bool replaceAll}) async {
    setState(() => _isProcessing = true);
    HapticFeedback.heavyImpact();

    try {
      final ok = await widget.controller.storage.importAllDataFromMap(data, replaceAll: replaceAll);
      if (ok) {
        await widget.controller.reloadFromStorage();
      }

      if (mounted) {
        setState(() => _isProcessing = false);
        if (ok) {
          _calmToast(
            context,
            replaceAll ? 'เขียนทับเรียบร้อย • ข้อมูลเดิมสำรองไว้ที่โฟลเดอร์ Download แล้ว' : 'ผสานรวมข้อมูลเรียบร้อย • ไม่มีข้อมูลซ้ำ',
          );
        } else {
          _calmToast(context, 'เกิดข้อผิดพลาด ไม่สามารถกู้คืนข้อมูลได้', error: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _calmToast(context, 'เกิดข้อผิดพลาด: $e', error: true);
      }
    }
  }

  // ==========================================================
  // P2P QR CODE MIGRATION ACTIONS (RECEIVER)
  // ==========================================================
  Future<void> _handleScanQrFromImage() async {
    HapticFeedback.selectionClick();
    setState(() => _isProcessing = true);

    try {
      final imagePath = await NativeBridgeService.pickImageFromGallery();
      if (imagePath != null && imagePath.isNotEmpty) {
        final res = await NativeBridgeService.processSlipImage(imagePath);
        final qrPayload = res['qrPayload'] as String? ?? '';

        if (qrPayload.isNotEmpty && (qrPayload.startsWith('http://') || qrPayload.startsWith('https://') || qrPayload.startsWith('rizqi://'))) {
          await _fetchDataFromPeerQr(qrPayload);
        } else {
          if (mounted) _calmToast(context, 'ไม่พบ QR Code การโอนย้ายข้อมูลในรูปภาพที่เลือก');
        }
      }
    } catch (e) {
      if (mounted) _calmToast(context, 'เกิดข้อผิดพลาดในการสแกน: $e', error: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleManualConnect() async {
    final ip = _ipInputController.text.trim();
    final pin = _pinInputController.text.trim();
    final ipOk = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(ip);
    final pinOk = pin.isEmpty || RegExp(r'^\d{4}$').hasMatch(pin);

    if (!ipOk || !pinOk) {
      setState(() => _manualError = ip.isEmpty
          ? 'กรุณากรอกที่อยู่ IP ของเครื่องเดิม'
          : !ipOk
              ? 'ที่อยู่ IP ไม่ถูกต้อง (ตัวอย่าง 192.168.1.42)'
              : 'PIN ต้องเป็นตัวเลข 4 หลัก');
      return;
    }
    setState(() => _manualError = null);

    final url = 'http://$ip:${DataBackupService.p2pPort}/rizqi_backup${pin.isNotEmpty ? "?pin=$pin" : ""}';
    await _fetchDataFromPeerQr(url);
  }

  Future<void> _fetchDataFromPeerQr(String rawUrl) async {
    setState(() => _isProcessing = true);
    String targetUrl = rawUrl;
    if (targetUrl.startsWith('rizqi://transfer?')) {
      final uri = Uri.parse(targetUrl);
      final ip = uri.queryParameters['ip'] ?? '127.0.0.1';
      final port = uri.queryParameters['port'] ?? '${DataBackupService.p2pPort}';
      final pin = uri.queryParameters['pin'] ?? '';
      targetUrl = 'http://$ip:$port/rizqi_backup${pin.isNotEmpty ? "?pin=$pin" : ""}';
    }

    try {
      final data = await DataTransferClient.fetchBackupFromUrl(targetUrl);
      if (mounted) {
        setState(() => _isProcessing = false);
        if (data != null) {
          _showRestoreConfirmationModal(data, fromPeer: true);
        } else {
          _calmToast(context, 'เชื่อมต่อเครื่องต้นทางไม่สำเร็จ กรุณาตรวจสอบว่าต่อ Wi-Fi วงเดียวกันหรือไม่', error: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _calmToast(context, 'เกิดข้อผิดพลาดในการดึงข้อมูล: $e', error: true);
      }
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = _C.of(widget.controller);
        final isEn = widget.controller.isEnglish;

        Widget seg(String label, int i) {
          final sel = _tab == i;
          return Expanded(
            child: Material(
              color: sel ? c.card : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _selectTab(i),
                child: SizedBox(
                  height: 44,
                  child: Center(
                    child: Text(label,
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
          appBar: _calmAppBar(context, c, isEn ? 'Backup & transfer' : 'สำรอง & ย้ายข้อมูล',
              subtitle: isEn ? 'Free • your data stays on your phone' : 'ฟรี • ข้อมูลอยู่ในเครื่องของคุณเท่านั้น',
              bottomHeight: 64,
              bottom: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: c.seg, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [seg('สำรองด้วยไฟล์', 0), seg('ย้ายด้วย QR Code', 1)]),
                ),
              )),
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(child: _tab == 0 ? _buildFileBackupTab(c) : _buildQrMigrationTab(c)),
                ],
              ),
              if (_isProcessing)
                Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: Center(child: CircularProgressIndicator(color: c.dark ? Colors.white : c.accent)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _navRow(_C c, {required IconData icon, required String title, required String sub, required VoidCallback onTap}) => _calmCard(
        c,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.fromLTRB(16, 11, 12, 11),
            child: Row(
              children: [
                Icon(icon, size: 22, color: c.icon),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(title, style: c.title), const SizedBox(height: 2), Text(sub, style: c.subtitle)],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 22, color: c.faint),
              ],
            ),
          ),
        ),
      );

  // ==========================================================
  // TAB 1: FILE BACKUP & RESTORE
  // ==========================================================
  Widget _buildFileBackupTab(_C c) {
    final saved = _lastSavedAt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // 1. Last backup + what is on this phone
        FxFadeUp(
          child: _calmCard(
            c,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 22, color: c.icon),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('สำรองล่าสุด', style: TextStyle(fontSize: 12.5, color: c.sub)),
                            Text(
                              saved != null ? '${_thDate(saved)} • วันนี้' : 'ยังไม่ได้สำรองในรอบนี้',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text),
                            ),
                          ],
                        ),
                      ),
                      if (saved != null) Text('เพิ่งสำรอง', style: TextStyle(fontSize: 12.5, color: c.sub)),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: c.border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ข้อมูลในเครื่องปัจจุบัน', style: TextStyle(fontSize: 12.5, color: c.sub)),
                      const SizedBox(height: 8),
                      _statRow(c, _currentStats()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Section 1: Export
        FxFadeUp(
          index: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionLabel(c, 'สำรองข้อมูล (Export)'),
              _primaryButton(c, 'บันทึกไฟล์สำรองลงเครื่อง', _handleSaveToDownloads, icon: Icons.file_download_outlined),
              const SizedBox(height: 10),
              _navRow(c,
                  icon: Icons.cloud_upload_outlined,
                  title: 'แชร์ไฟล์ไปเครื่องอื่น',
                  sub: 'ส่งทาง LINE / Google Drive / Email',
                  onTap: _handleShareBackupFile),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                child: Text(
                  _lastSavedFilePath != null ? 'ไฟล์ล่าสุด: $_lastSavedFilePath' : 'ไฟล์จะถูกเก็บในโฟลเดอร์ Download ของเครื่อง',
                  style: TextStyle(fontSize: 12.5, color: c.sub),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section 2: Restore
        FxFadeUp(
          index: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionLabel(c, 'กู้คืนข้อมูล (Restore)'),
              _navRow(c,
                  icon: Icons.sync_rounded,
                  title: 'เลือกไฟล์เพื่อกู้คืนข้อมูล',
                  sub: 'ไฟล์สำรองจากแอปเหมียวตังค์ • ตรวจไฟล์ให้ก่อนเสมอ',
                  onTap: _handlePickAndRestoreFile),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Step guide
        FxFadeUp(
          index: 3,
          child: _calmCard(
            c,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('วิธีย้ายข้อมูลไปเครื่องใหม่ง่ายๆ', style: c.title),
                const SizedBox(height: 12),
                _step(c, '1', 'เครื่องเดิม: กด “บันทึก” หรือ “แชร์ไฟล์”', 'ส่งไฟล์สำรองเข้า LINE ของตัวเอง, Google Drive หรืออีเมล'),
                _step(c, '2', 'เครื่องใหม่: ติดตั้งเหมียวตังค์', 'เปิดไฟล์สำรองที่ส่งมาให้เครื่องใหม่บันทึกไว้'),
                _step(c, '3', 'เครื่องใหม่: กด “เลือกไฟล์เพื่อกู้คืน”', 'เลือก “ผสานรวมข้อมูล” — เสร็จแล้ว'),
                Divider(height: 1, color: c.border),
                SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed: () => _selectTab(1),
                    child: Text('หรือย้ายแบบไร้สายด้วย QR Code', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.link)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _step(_C c, String n, String title, String sub) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.line)),
              child: Text(n, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.icon)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
                  Text(sub, style: c.subtitle),
                ],
              ),
            ),
          ],
        ),
      );

  // ==========================================================
  // TAB 2: P2P QR CODE MIGRATION
  // ==========================================================
  Widget _buildQrMigrationTab(_C c) {
    final transferUrl = 'http://${_localIp ?? "127.0.0.1"}:${DataBackupService.p2pPort}/rizqi_backup?pin=$_pinCode';
    final ctl = widget.controller;

    Widget role(int i, String title, String sub) {
      final sel = _p2pModeIndex == i;
      return Expanded(
        child: Material(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              if (sel) return;
              HapticFeedback.selectionClick();
              setState(() {
                _p2pModeIndex = i;
                _advOpen = false;
                _manualError = null;
              });
              if (i == 0) {
                _startP2pServer();
              } else {
                _stopP2pServer();
              }
            },
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sel ? c.accent : c.line, width: sel ? 2 : 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone_iphone_rounded, size: 22, color: sel ? c.link : c.icon),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: c.title.copyWith(color: sel ? c.link : c.text)),
                        Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: c.sub)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget advHeader(String sub) => InkWell(
          onTap: () => setState(() {
            _advOpen = !_advOpen;
            _manualError = null;
          }),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 22, color: c.icon),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text('ตั้งค่าขั้นสูง', style: c.title), Text(sub, style: c.subtitle)],
                  ),
                ),
                AnimatedRotation(
                  turns: _advOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 24, color: c.sub),
                ),
              ],
            ),
          ),
        );

    final txt = '${_nf.format(ctl.allTransactions.length)} รายการ • ${ctl.accounts.length} บัญชี • ${ctl.categories.length} หมวดหมู่ • ${ctl.savingGoals.length} เป้าหมาย';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 18, color: c.sub),
            const SizedBox(width: 8),
            Expanded(
              child: Text('ย้ายแบบไร้สาย ไม่ต้องใช้ไฟล์ — เปิดหน้านี้บนทั้ง 2 เครื่อง และเชื่อมต่อ Wi-Fi เดียวกัน',
                  style: TextStyle(fontSize: 13, height: 1.45, color: c.sub)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _sectionLabel(c, 'เครื่องนี้คือ'),
        Row(children: [role(0, 'เครื่องส่ง', 'เครื่องเดิม'), const SizedBox(width: 10), role(1, 'เครื่องรับ', 'เครื่องใหม่')]),
        const SizedBox(height: 16),
        if (_p2pModeIndex == 0) ...[
          // ================= SENDER VIEW =================
          FxFadeUp(
            key: ValueKey('send_$_noNetwork$_isServerRunning'),
            child: _calmCard(
              c,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: _noNetwork
                  ? Column(
                      children: [
                        Icon(Icons.wifi_off_rounded, size: 30, color: c.sub),
                        const SizedBox(height: 10),
                        Text('ยังไม่ได้เชื่อมต่อ Wi-Fi', style: c.title.copyWith(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('เชื่อม Wi-Fi วงเดียวกับเครื่องใหม่ก่อน แล้วกด “ลองใหม่” QR Code จะแสดงขึ้นมา',
                            textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.45, color: c.sub)),
                        const SizedBox(height: 14),
                        _primaryButton(c, 'ลองใหม่', _startP2pServer, icon: Icons.refresh_rounded),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 48,
                          child: TextButton(
                            onPressed: () => _selectTab(0),
                            child: Text('ไม่มี Wi-Fi? ย้ายด้วยไฟล์สำรองแทน', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.link)),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          Icon(_isServerRunning ? Icons.check_rounded : Icons.more_horiz_rounded, size: 18, color: c.sub),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(_isServerRunning ? 'พร้อมส่ง • เชื่อมต่อ Wi-Fi แล้ว' : 'กำลังเตรียมการเชื่อมต่อ...',
                                style: TextStyle(fontSize: 13, color: c.icon)),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: c.line),
                            ),
                            child: QrCodeDisplayWidget(
                              data: transferUrl,
                              size: 196,
                              foregroundColor: const Color(0xFF0F172A),
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text('ใช้เครื่องใหม่สแกน QR นี้', textAlign: TextAlign.center, style: c.title.copyWith(fontSize: 16)),
                        const SizedBox(height: 6),
                        Text(
                          'บนเครื่องใหม่: เมนู › สำรอง & ย้ายข้อมูล › ย้ายด้วย QR Code › เลือก “เครื่องรับ” แล้วเลือกรูป QR นี้',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, height: 1.5, color: c.sub),
                        ),
                        Text('จะส่ง $txt', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, height: 1.5, color: c.sub)),
                      ],
                    ),
            ),
          ),
          if (!_noNetwork) ...[
            const SizedBox(height: 16),
            FxFadeUp(
              index: 1,
              child: _calmCard(
                c,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    advHeader('รหัสสำหรับกรอกเอง ถ้าเครื่องใหม่สแกนไม่ได้'),
                    if (_advOpen)
                      Container(
                        margin: const EdgeInsets.only(left: 54),
                        padding: const EdgeInsets.fromLTRB(0, 12, 16, 14),
                        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('ที่อยู่ (IP)', style: TextStyle(fontSize: 12.5, color: c.sub)),
                              SelectableText(_localIp ?? '-', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
                            ]),
                          ),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('PIN', style: TextStyle(fontSize: 12.5, color: c.sub)),
                              SelectableText(_pinCode,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 2, color: c.text)),
                            ]),
                          ),
                        ]),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ] else ...[
          // ================= RECEIVER VIEW =================
          FxFadeUp(
            key: const ValueKey('recv'),
            child: _calmCard(
              c,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.qr_code_scanner_rounded, size: 34, color: c.icon),
                  const SizedBox(height: 10),
                  Text('รับข้อมูลจากเครื่องเดิม', textAlign: TextAlign.center, style: c.title.copyWith(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('ถ่ายรูปหรือแคปหน้าจอ QR บนเครื่องเดิม แล้วเลือกรูปนั้น',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.45, color: c.sub)),
                  const SizedBox(height: 16),
                  _primaryButton(c, 'เลือกรูป QR จากคลังภาพ', _handleScanQrFromImage, icon: Icons.image_outlined),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FxFadeUp(
            index: 1,
            child: _calmCard(
              c,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  advHeader('สแกนไม่ได้? กรอกรหัสเชื่อมต่อเอง'),
                  if (_advOpen)
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'ดูตัวเลขได้ที่เครื่องเดิม ในหัวข้อ “ตั้งค่าขั้นสูง” ใต้ QR Code • IP คือที่อยู่ของเครื่องเดิมใน Wi-Fi, PIN คือรหัสยืนยัน 4 หลัก',
                            style: TextStyle(fontSize: 12.5, height: 1.45, color: c.sub),
                          ),
                          const SizedBox(height: 12),
                          _fieldLabel(c, 'ที่อยู่เครื่องเดิม (IP)'),
                          TextField(
                            controller: _ipInputController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() => _manualError = null),
                            style: TextStyle(color: c.text, fontSize: 15),
                            decoration: _inputDeco(c, hint: 'เช่น 192.168.1.42', error: _manualError != null && _manualError!.contains('IP')),
                          ),
                          const SizedBox(height: 12),
                          _fieldLabel(c, 'รหัส PIN 4 หลัก'),
                          TextField(
                            controller: _pinInputController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                            onChanged: (_) => setState(() => _manualError = null),
                            style: TextStyle(color: c.text, fontSize: 15),
                            decoration: _inputDeco(c, hint: 'เช่น 4821', error: _manualError != null && _manualError!.contains('PIN')),
                          ),
                          if (_manualError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(_manualError!, style: TextStyle(fontSize: 12.5, color: c.danger)),
                            ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 50,
                            child: OutlinedButton(
                              onPressed: _handleManualConnect,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: c.accent),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text('เชื่อมต่อด้วยรหัส', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: c.link)),
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
      ],
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
