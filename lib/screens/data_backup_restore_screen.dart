import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../services/data_backup_service.dart';
import '../services/native_bridge_service.dart';
import '../widgets/qr_code_display_widget.dart';

class DataBackupRestoreScreen extends StatefulWidget {
  final ExpenseController controller;

  const DataBackupRestoreScreen({super.key, required this.controller});

  @override
  State<DataBackupRestoreScreen> createState() => _DataBackupRestoreScreenState();
}

class _DataBackupRestoreScreenState extends State<DataBackupRestoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isProcessing = false;
  String? _lastSavedFilePath;

  // P2P Transfer Server State (Sender)
  DataTransferServer? _p2pServer;
  String? _localIp;
  String _pinCode = '8829';
  bool _isServerRunning = false;

  // P2P Receiver Manual Input Controllers
  final TextEditingController _ipInputController = TextEditingController();
  final TextEditingController _pinInputController = TextEditingController();
  int _p2pModeIndex = 0; // 0 = Sender, 1 = Receiver

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _p2pModeIndex == 0) {
        _startP2pServer();
      } else {
        _stopP2pServer();
      }
    });
    _generateRandomPin();
  }

  void _generateRandomPin() {
    final rand = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    setState(() => _pinCode = rand);
  }

  @override
  void dispose() {
    _stopP2pServer();
    _tabController.dispose();
    _ipInputController.dispose();
    _pinInputController.dispose();
    super.dispose();
  }

  Future<void> _startP2pServer() async {
    setState(() => _isProcessing = true);
    _localIp = await DataBackupService.getLocalIpAddress();

    if (_localIp == null || _localIp!.isEmpty) {
      _localIp = '192.168.1.50'; // Fallback indicator
    }

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
        });

        if (savedPath != null) {
          _showSuccessDialog(
            title: 'บันทึกไฟล์สำรองสำเร็จ! 🎉',
            message: 'ไฟล์สำรองข้อมูลถูกบันทึกไว้ที่:\n\n📁 $savedPath\n\nสามารถนำไฟล์นี้ไปใช้กู้คืนในเครื่องใหม่ หรือส่งต่อได้ทันทีครับ',
            icon: Icons.check_circle_rounded,
            iconColor: MeowTheme.incomeGreen,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่สามารถบันทึกไฟล์ลงเครื่องได้ กรุณาตรวจสอบสิทธิ์การเข้าถึง')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('พร้อมส่งต่อไฟล์สำรองข้อมูลแล้ว')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการแชร์: $e')),
        );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบข้อมูลสำรองที่ถูกต้อง หรือยกเลิกการเลือกไฟล์')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการอ่านไฟล์: $e')),
        );
      }
    }
  }

  // ==========================================================
  // RESTORE CONFIRMATION & EXECUTION
  // ==========================================================
  void _showRestoreConfirmationModal(Map<String, dynamic> data) {
    final isDark = widget.controller.isDarkMode;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final cardBg = isDark ? MeowTheme.navySurface : Colors.white;

    final txCount = (data['transactions'] as List?)?.length ?? 0;
    final accCount = (data['accounts'] as List?)?.length ?? 0;
    final catCount = (data['categories'] as List?)?.length ?? 0;
    final goalCount = (data['savingGoals'] as List?)?.length ?? 0;
    final backupDate = data['exportedAt'] as String? ?? 'ไม่ระบุวันที่';

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: MeowTheme.mustardYellow.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.settings_backup_restore_rounded, color: MeowTheme.mustardYellow, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'พบข้อมูลสำรองที่ถูกต้อง! 📦',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      Text(
                        'วันที่สำรอง: ${backupDate.split('T').first}',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary Stats Grid
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F1E36) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? MeowTheme.borderColor : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat('ธุรกรรม', '$txCount รายการ', Icons.receipt_long_rounded, MeowTheme.incomeGreen),
                  _buildMiniStat('บัญชี', '$accCount บัญชี', Icons.account_balance_wallet_rounded, MeowTheme.actionBlue),
                  _buildMiniStat('หมวดหมู่', '$catCount หมวด', Icons.grid_view_rounded, const Color(0xFFF59E0B)),
                  _buildMiniStat('เป้าหมาย', '$goalCount รายการ', Icons.track_changes_rounded, const Color(0xFFEC4899)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'เลือกรูปแบบการกู้คืนข้อมูล:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 10),

            // Option 1: Replace All (Recommended for new phone)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MeowTheme.incomeGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _executeRestore(data, replaceAll: true);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.refresh_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'เขียนทับทั้งหมด (สำหรับย้ายเครื่องใหม่ 100%)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Option 2: Merge
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: BorderSide(color: isDark ? Colors.white30 : const Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _executeRestore(data, replaceAll: false);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.merge_type_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'ผสานรวมข้อมูล (ไม่ลบข้อมูลเดิมที่มีอยู่)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
      ],
    );
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
          _showSuccessDialog(
            title: 'กู้คืนข้อมูลสำเร็จเรียบร้อย! 🎉',
            message: 'ข้อมูลธุรกรรม หมวดหมู่ บัญชีกระเป๋าเงิน และการตั้งค่าทั้งหมดถูกนำเข้าและพร้อมใช้งาน 100% แล้วครับ',
            icon: Icons.verified_rounded,
            iconColor: MeowTheme.incomeGreen,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เกิดข้อผิดพลาด ไม่สามารถกู้คืนข้อมูลได้')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ไม่พบ QR Code การโอนย้ายข้อมูลในรูปภาพที่เลือก')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการสแกน: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleManualConnect() async {
    final ip = _ipInputController.text.trim();
    final pin = _pinInputController.text.trim();

    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอก IP Address ของเครื่องส่ง')),
      );
      return;
    }

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
          _showRestoreConfirmationModal(data);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เชื่อมต่อเครื่องต้นทางไม่สำเร็จ กรุณาตรวจสอบว่าต่อ Wi-Fi วงเดียวกันหรือไม่')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการดึงข้อมูล: $e')),
        );
      }
    }
  }

  void _showSuccessDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
  }) {
    final isDark = widget.controller.isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? MeowTheme.navySurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 13, height: 1.4)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MeowTheme.mustardYellow,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ตกลง', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = widget.controller.currentTheme;
    final isDark = widget.controller.isDarkMode;
    final isEn = widget.controller.isEnglish;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? MeowTheme.navySurface : Colors.white;
    final borderColor = isDark ? MeowTheme.borderColor : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: currentTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEn ? 'Backup & Migration' : 'สำรอง & ย้ายข้อมูลข้ามเครื่อง',
          style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: MeowTheme.mustardYellow,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.grey,
          indicatorColor: MeowTheme.mustardYellow,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.folder_zip_rounded, size: 18), text: '📁 สำรองด้วยไฟล์ (.rizqi)'),
            Tab(icon: Icon(Icons.qr_code_scanner_rounded, size: 18), text: '📲 ย้ายด้วย QR Code'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildFileBackupTab(cardBg, borderColor, textPrimary, textSecondary, isDark),
              _buildQrMigrationTab(cardBg, borderColor, textPrimary, textSecondary, isDark),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: const Center(
                child: CircularProgressIndicator(color: MeowTheme.mustardYellow),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // TAB 1: FILE BACKUP & RESTORE (Minimal & Human-Friendly)
  // ==========================================================
  Widget _buildFileBackupTab(Color cardBg, Color borderColor, Color textPrimary, Color textSecondary, bool isDark) {
    final totalTxs = widget.controller.allTransactions.length;
    final totalAccs = widget.controller.accounts.length;
    final totalCats = widget.controller.categories.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // 1. Current Device Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: MeowTheme.incomeGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inventory_2_rounded, color: MeowTheme.incomeGreen, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ข้อมูลในเครื่องปัจจุบัน',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$totalTxs รายการธุรกรรม • $totalAccs บัญชี • $totalCats หมวดหมู่',
                          style: TextStyle(fontSize: 11.5, color: textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Section 1: Export
        Text(
          'สำรองข้อมูล (Export)',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textPrimary),
        ),
        const SizedBox(height: 8),

        // Save to Downloads Button
        GestureDetector(
          onTap: _handleSaveToDownloads,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: MeowTheme.actionBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.download_rounded, color: MeowTheme.actionBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'บันทึกไฟล์สำรองลงเครื่อง (.rizqi)',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'บันทึกเก็บไว้ในโฟลเดอร์ Download ของมือถือ',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Share Backup File Button
        GestureDetector(
          onTap: _handleShareBackupFile,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: MeowTheme.mustardYellow.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.share_rounded, color: MeowTheme.mustardYellow, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'แชร์ไฟล์ไปเครื่องอื่น (LINE / Drive / Email)',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ส่งไฟล์ไปยัง LINE ส่วนตัว หรือบันทึกบน Google Drive',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Section 2: Restore
        Text(
          'กู้คืนข้อมูล (Restore)',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textPrimary),
        ),
        const SizedBox(height: 8),

        GestureDetector(
          onTap: _handlePickAndRestoreFile,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MeowTheme.incomeGreen.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: MeowTheme.incomeGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.restore_page_rounded, color: MeowTheme.incomeGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'เลือกไฟล์เพื่อกู้คืนข้อมูล (.rizqi / .json)',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'นำไฟล์สำรองที่เคยบันทึกไว้กลับมาใช้งาน',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 4. Clean Step Guide
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F1E36) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.help_outline_rounded, color: MeowTheme.mustardYellow, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'วิธีย้ายข้อมูลไปเครื่องใหม่ง่ายๆ',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildStepItem('1', 'เครื่องเดิม: กด "แชร์ไฟล์ไปเครื่องอื่น" ส่งเข้า LINE ตัวเอง', textPrimary, textSecondary),
              const SizedBox(height: 6),
              _buildStepItem('2', 'เครื่องใหม่: โหลดแอพ แล้วกดดาวน์โหลดไฟล์จาก LINE', textPrimary, textSecondary),
              const SizedBox(height: 6),
              _buildStepItem('3', 'เครื่องใหม่: กด "เลือกไฟล์เพื่อกู้คืนข้อมูล" เพื่อเริ่มใช้งานได้ทันที', textPrimary, textSecondary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(String number, String text, Color textPrimary, Color textSecondary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: MeowTheme.mustardYellow,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(number, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 11.5, color: textSecondary, height: 1.35)),
        ),
      ],
    );
  }

  // ==========================================================
  // TAB 2: P2P QR CODE MIGRATION (TO PHONE / IPAD)
  // ==========================================================
  Widget _buildQrMigrationTab(Color cardBg, Color borderColor, Color textPrimary, Color textSecondary, bool isDark) {
    final transferUrl = 'http://${_localIp ?? "127.0.0.1"}:${DataBackupService.p2pPort}/rizqi_backup?pin=$_pinCode';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Mode Selector: Sender vs Receiver
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F1E36) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _p2pModeIndex = 0);
                    _startP2pServer();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _p2pModeIndex == 0 ? (isDark ? MeowTheme.navySurface : Colors.white) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _p2pModeIndex == 0 ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : [],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_rounded, size: 16, color: _p2pModeIndex == 0 ? MeowTheme.mustardYellow : Colors.grey),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'เครื่องส่ง (เครื่องเดิม)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: _p2pModeIndex == 0 ? FontWeight.bold : FontWeight.normal,
                              color: _p2pModeIndex == 0 ? textPrimary : Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _p2pModeIndex = 1);
                    _stopP2pServer();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _p2pModeIndex == 1 ? (isDark ? MeowTheme.navySurface : Colors.white) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _p2pModeIndex == 1 ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : [],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_rounded, size: 16, color: _p2pModeIndex == 1 ? MeowTheme.incomeGreen : Colors.grey),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'เครื่องรับ (เครื่องใหม่)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: _p2pModeIndex == 1 ? FontWeight.bold : FontWeight.normal,
                              color: _p2pModeIndex == 1 ? textPrimary : Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_p2pModeIndex == 0) ...[
          // ================= SENDER VIEW =================
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: MeowTheme.incomeGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isServerRunning ? 'พร้อมส่งข้อมูลไร้สาย' : 'กำลังเตรียมการเชื่อมต่อ...',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: MeowTheme.incomeGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // QR Code
                Center(
                  child: QrCodeDisplayWidget(
                    data: transferUrl,
                    size: 200,
                    foregroundColor: const Color(0xFF0F172A),
                    backgroundColor: Colors.white,
                    embeddedLogo: const Icon(Icons.account_balance_wallet_rounded, color: MeowTheme.mustardYellow, size: 24),
                  ),
                ),
                const SizedBox(height: 14),

                // PIN & IP Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F1E36) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'IP: ${_localIp ?? "127.0.0.1"}',
                          style: TextStyle(fontSize: 11, color: textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('PIN: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(_pinCode, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: MeowTheme.mustardYellow)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Instructions Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F1E36) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('คำแนะนำ:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '1. ต่อ Wi-Fi เดียวกันทั้งสองเครื่อง (หรือเปิด Hotspot ให้อีกเครื่องต่อ)\n2. เปิดเครื่องใหม่แล้วสแกน QR Code นี้เพื่อดึงข้อมูลได้ทันที',
                  style: TextStyle(fontSize: 11.5, color: textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ] else ...[
          // ================= RECEIVER VIEW =================
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MeowTheme.incomeGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: MeowTheme.incomeGreen, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  'รับข้อมูลจากเครื่องเดิม',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'สแกน QR Code จากรูปถ่าย หรือเชื่อมต่อด้วย IP Address',
                  style: TextStyle(fontSize: 11.5, color: textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Button: Scan QR from Gallery
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MeowTheme.incomeGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _handleScanQrFromImage,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.photo_library_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('เลือกรูปภาพ QR Code', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                const Divider(),
                const SizedBox(height: 8),

                // Manual IP & PIN Input
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('หรือระบุ IP ด้วยตนเอง:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textPrimary)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: TextField(
                        controller: _ipInputController,
                        style: TextStyle(color: textPrimary, fontSize: 12.5),
                        decoration: InputDecoration(
                          hintText: 'IP เครื่องเดิม เช่น 192.168.1.50',
                          hintStyle: TextStyle(color: textSecondary, fontSize: 11),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _pinInputController,
                        style: TextStyle(color: textPrimary, fontSize: 12.5),
                        decoration: InputDecoration(
                          hintText: 'PIN',
                          hintStyle: TextStyle(color: textSecondary, fontSize: 11),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MeowTheme.actionBlue,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      side: const BorderSide(color: MeowTheme.actionBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _handleManualConnect,
                    child: const Text('ดึงข้อมูลผ่าน IP Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
