import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/transaction_item.dart';
import '../models/category_item.dart';
import '../models/slip_extract_result.dart';
import '../state/expense_controller.dart';
import 'native_bridge_service.dart';
import 'category_matcher_service.dart';
import 'ocr_engine_service.dart';
import 'qr_slip_parser_service.dart';
import 'duplicate_slip_checker.dart';
import 'slip_storage_service.dart';
import 'easyocr_tesseract_fusion_service.dart';
import 'thai_bank_detector.dart';
import '../config/app_config.dart';

class SlipAutoSyncService {
  static bool _isListenerStarted = false;
  static final Set<String> _inFlightKeys = {};
  static final Set<String> _processedKeys = {};

  /// Generates a standardized deduplication key for a slip path or name
  static String _getSlipKey(String? path, String? name) {
    final bName = DuplicateSlipChecker.extractBasename(name);
    final bPath = DuplicateSlipChecker.extractBasename(path);
    return bName.isNotEmpty ? bName : (bPath.isNotEmpty ? bPath : (path ?? ''));
  }

  /// Sets up real-time ContentObserver listener for incoming new slips
  static void setupRealtimeSlipObserver(ExpenseController controller, {Function(TransactionItem item)? onNewTransactionCreated}) {
    _isListenerStarted = true;
    NativeBridgeService.startMediaObserver();
    NativeBridgeService.setSlipDetectedListener((slipData) async {
      final path = slipData['path'] as String? ?? '';
      final name = slipData['name'] as String? ?? '';
      final bankName = slipData['bankName'] as String? ?? 'ธนาคารไทย';

      if (path.isEmpty && name.isEmpty) return;

      final key = _getSlipKey(path, name);
      if (key.isNotEmpty) {
        if (_inFlightKeys.contains(key) || _processedKeys.contains(key)) {
          return;
        }
        _inFlightKeys.add(key);
      }

      try {
        // 1. Initial Duplicate Check against existing database & deleted slips registry & imported registry
        final isDup = DuplicateSlipChecker.isDuplicate(
          existingTransactions: controller.allTransactions,
          deletedSlipIdentifiers: controller.storage.getDeletedSlips(),
          importedSlipIdentifiers: controller.storage.getImportedSlipIdentifiers(),
          filePath: path,
          fileName: name,
        );
        if (isDup) {
          if (key.isNotEmpty) _processedKeys.add(key);
          return;
        }

        if (!controller.canImportMoreSlips) {
          return;
        }

        final item = await _createTransactionFromSlip(
          controller: controller,
          path: path,
          name: name,
          bankName: bankName,
          date: DateTime.now(),
        );

        if (item != null) {
          final added = await controller.addTransaction(item);
          if (added) {
            await controller.recordSlipImported(slipDate: item.date);
            await controller.storage.addImportedSlipIdentifiers([
              path.toLowerCase(),
              name.trim().toLowerCase(),
              DuplicateSlipChecker.extractBasename(name),
              DuplicateSlipChecker.extractBasename(path),
              if (item.slipImageUrl != null) DuplicateSlipChecker.extractBasename(item.slipImageUrl),
              if (item.slipRefId != null && !item.slipRefId!.startsWith('SLIP-') && !item.slipRefId!.startsWith('NO-QR-')) item.slipRefId!.toLowerCase(),
            ]);
            onNewTransactionCreated?.call(item);
          }
          if (key.isNotEmpty) _processedKeys.add(key);
        }
      } finally {
        if (key.isNotEmpty) _inFlightKeys.remove(key);
      }
    });
  }

  /// Returns the start of the previous calendar month (00:00:00 of the 1st day of month - 1)
  static DateTime getStartOfPreviousMonth([DateTime? baseDate]) {
    final now = baseDate ?? DateTime.now();
    return DateTime(now.year, now.month - 1, 1, 0, 0, 0);
  }

  /// Checks whether a date falls within the current month or previous month
  static bool isWithinCurrentOrPreviousMonth(DateTime date, [DateTime? baseDate]) {
    final start = getStartOfPreviousMonth(baseDate);
    return !date.isBefore(start);
  }

  static Future<List<TransactionItem>>? _activeScan;
  static bool _activeScanIsForced = false;

  /// Scans device storage for new bank slips.
  /// When [forceRescan] is true (e.g. user manual pull-to-refresh), scans full 12-month archive to catch any missed slips.
  static Future<List<TransactionItem>> scanAndAutoImportNewSlips(
    ExpenseController controller, {
    bool forceRescan = false,
  }) async {
    final active = _activeScan;
    if (active != null) {
      // Join the running scan; only queue a new one if a forced rescan was requested on top of a normal scan
      if (!forceRescan || _activeScanIsForced) return active;
      try {
        await active;
      } catch (_) {}
      return scanAndAutoImportNewSlips(controller, forceRescan: true);
    }

    final scan = _runScan(controller, forceRescan: forceRescan);
    _activeScan = scan;
    _activeScanIsForced = forceRescan;
    try {
      return await scan;
    } finally {
      if (identical(_activeScan, scan)) _activeScan = null;
    }
  }

  static Future<List<TransactionItem>> _runScan(
    ExpenseController controller, {
    required bool forceRescan,
  }) async {
    controller.setProcessingSlips(true);
    try {
      // Note: _inFlightKeys is NOT cleared here — the real-time observer may be processing a slip right now
      _processedKeys.clear();

      // Without photo access the device query returns nothing. Bail out WITHOUT marking the initial scan
      // as completed, so the free 12-month import still runs once the user grants permission later.
      if (!await NativeBridgeService.hasPhotoPermission()) {
        return [];
      }

      final isCreator = AppConfig.isCreatorEdition;
      final isFirstInstallScan = !controller.storage.isInitialDeviceScanCompleted();
      final isInitialScan = isFirstInstallScan || forceRescan;

      // 0. Only perform full DB deduplication and registry seeding on initial scan or if empty
      if (isInitialScan || controller.storage.getImportedSlipIdentifiers().isEmpty) {
        await deduplicateExistingTransactions(controller);

        // Seed persistent registry with any existing transactions
        final existingSlips = <String>[];
        for (final tx in controller.allTransactions) {
          if (tx.slipImageUrl != null && tx.slipImageUrl!.isNotEmpty) {
            existingSlips.add(tx.slipImageUrl!.toLowerCase());
            final bName = DuplicateSlipChecker.extractBasename(tx.slipImageUrl);
            if (bName.isNotEmpty) {
              existingSlips.add(bName);
              if (bName.startsWith('slip_')) {
                final parts = bName.split('_');
                if (parts.length >= 3) {
                  existingSlips.add(parts.sublist(2).join('_'));
                }
              }
            }
          }
          if (tx.slipRefId != null && tx.slipRefId!.isNotEmpty && !tx.slipRefId!.startsWith('SLIP-') && !tx.slipRefId!.startsWith('NO-QR-')) {
            existingSlips.add(tx.slipRefId!.toLowerCase());
          }
        }
        if (existingSlips.isNotEmpty) {
          await controller.storage.addImportedSlipIdentifiers(existingSlips);
        }
      }

      final now = DateTime.now();
      final startOfPreviousMonth = getStartOfPreviousMonth(now);
      // 12-Month Cutoff for Initial Device Scan / Force Rescan: exactly 12 calendar months backwards
      final twelveMonthsAgo = DateTime(now.year - 1, now.month, 1);
      final cutoffDate = isCreator ? DateTime(2000) : (isInitialScan ? twelveMonthsAgo : startOfPreviousMonth);

      // In Creator Edition: 0 (all). In Initial Scan / Force Rescan: 370 days (12 months). In Ongoing Scans: 2 months.
      final daysToScan = isCreator ? 0 : (isInitialScan ? 370 : (now.difference(startOfPreviousMonth).inDays + 2));

      final slipFiles = await NativeBridgeService.scanBankSlips(daysLimit: daysToScan);
      final allSlips = List<Map<String, dynamic>>.from(slipFiles);

      // Direct Physical Folder scan for banking apps & screenshots directories to guarantee 100% detection (Asynchronous I/O)
      final directSlipDirs = [
        Directory('/storage/emulated/0/Pictures/PaoTang'),
        Directory('/storage/emulated/0/Pictures/เป๋าตัง'),
        Directory('/storage/emulated/0/DCIM/PaoTang'),
        Directory('/storage/emulated/0/Download/PaoTang'),
        Directory('/storage/emulated/0/Pictures/KPlus'),
        Directory('/storage/emulated/0/Pictures/K PLUS'),
        Directory('/storage/emulated/0/DCIM/KPlus'),
        Directory('/storage/emulated/0/Pictures/SCBEASY'),
        Directory('/storage/emulated/0/Pictures/SCB EASY'),
        Directory('/storage/emulated/0/Pictures/Krungthai NEXT'),
        Directory('/storage/emulated/0/Pictures/Krungsri'),
        Directory('/storage/emulated/0/Pictures/KMA'),
        Directory('/storage/emulated/0/Pictures/Kept'),
        Directory('/storage/emulated/0/Pictures/MAKE'),
        Directory('/storage/emulated/0/Pictures/UOB'),
        Directory('/storage/emulated/0/Pictures/TMRW'),
        Directory('/storage/emulated/0/Pictures/CIMB'),
        Directory('/storage/emulated/0/Pictures/Dime'),
        Directory('/storage/emulated/0/Pictures/KKP'),
        Directory('/storage/emulated/0/Pictures/GHB'),
        Directory('/storage/emulated/0/Pictures/ธอส'),
        Directory('/storage/emulated/0/Pictures/TISCO'),
        Directory('/storage/emulated/0/Pictures/LHB'),
        Directory('/storage/emulated/0/Pictures/BAAC'),
        Directory('/storage/emulated/0/Pictures/ธกส'),
        Directory('/storage/emulated/0/Pictures/TrueMoney'),
        Directory('/storage/emulated/0/Pictures/ShopeePay'),
        Directory('/storage/emulated/0/Pictures/Screenshots'),
        Directory('/storage/emulated/0/DCIM/Screenshots'),
        Directory('/storage/emulated/0/Pictures'),
        Directory('/storage/emulated/0/Picture'),
      ];

      final parentDirs = {
        '/storage/emulated/0/Pictures',
        '/storage/emulated/0/Picture',
      };

      for (final dir in directSlipDirs) {
        try {
          if (await dir.exists()) {
            final isParentDir = parentDirs.contains(dir.path);
            await for (final entity in dir.list(recursive: false)) {
              if (entity is File) {
                final path = entity.path;
                final ext = path.split('.').last.toLowerCase();
                if (['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
                  final name = path.split(RegExp(r'[\/\\]')).last;
                  final lowerName = name.toLowerCase();

                  // For top-level parent directories (like /Pictures or /DCIM), only scan files that look like slips or screenshots
                  if (isParentDir) {
                    final looksLikeSlipOrScreenshot = lowerName.contains('screenshot') ||
                        lowerName.contains('screen_') ||
                        lowerName.contains('ภาพหน้าจอ') ||
                        lowerName.contains('screencap') ||
                        lowerName.contains('slip') ||
                        lowerName.contains('โอน') ||
                        lowerName.contains('paotang') ||
                        lowerName.contains('เป๋าตัง');
                    if (!looksLikeSlipOrScreenshot) {
                      continue;
                    }
                  }

                  final stat = await entity.stat();
                  // Filter: cutoffDate (12 months for initial scan, 2 months for ongoing scans)
                  if (!isCreator && stat.modified.isBefore(cutoffDate)) {
                    continue;
                  }
                  if (stat.size > 1024) {
                    final baseName = DuplicateSlipChecker.extractBasename(name);
                    
                    // Strict deduplication check inside slip list (check path, name, and basename)
                    final alreadyInList = allSlips.any((s) {
                      final sPath = s['path'] as String? ?? '';
                      final sName = s['name'] as String? ?? '';
                      final sBase = DuplicateSlipChecker.extractBasename(sName.isNotEmpty ? sName : sPath);
                      return sPath == path || (baseName.isNotEmpty && sBase == baseName);
                    });

                    if (!alreadyInList) {
                      final bank = (lowerName.contains('ibank') || lowerName.contains('อิสลาม'))
                          ? 'iBank (อิสลามแห่งประเทศไทย)'
                          : ((lowerName.contains('mymo') || lowerName.contains('gsb') || lowerName.contains('ออมสิน'))
                              ? 'MyMo by GSB (ออมสิน)'
                              : (lowerName.contains('ไทยช่วยไทย') ? 'ไทยช่วยไทย (เป๋าตัง)' : (lowerName.contains('paotang') || lowerName.contains('เป๋าตัง') ? 'เป๋าตัง (PaoTang)' : 'สลิปโอนเงิน')));
                      allSlips.add({
                        'id': path.hashCode.toString(),
                        'name': name,
                        'path': path,
                        'uri': Uri.file(path).toString(),
                        'dateAdded': stat.modified.millisecondsSinceEpoch,
                        'size': stat.size,
                        'bankName': bank,
                      });
                    }
                  }
                }
              }
            }
          }
        } catch (_) {}
      }

    // Sort slips descending by date (newest first) so recent slips are imported immediately
    allSlips.sort((a, b) {
      final aTime = a['dateAdded'] as num? ?? 0;
      final bTime = b['dateAdded'] as num? ?? 0;
      return bTime.compareTo(aTime);
    });

    if (allSlips.isEmpty) {
      if (isInitialScan) {
        if (await NativeBridgeService.hasPhotoPermission()) {
          await controller.storage.setInitialDeviceScanCompleted(true);
        }
        await NativeBridgeService.cancelScanProgressNotification();
      }
      return [];
    }

    // Background notification ONLY for initial first install scan (never during manual pull-to-refresh)
    if (isFirstInstallScan) {
      NativeBridgeService.showScanProgressNotification(
        title: 'เหมียวตังค์: กำลังดึงและอ่านสลิปในเครื่อง... 🔄',
        message: 'ระบบกำลังค้นหาและอ่านสลิปย้อนหลัง 12 เดือนในเครื่องอัตโนมัติ',
      );
    }

    final importedSlips = <TransactionItem>[];
    final pendingBatch = <TransactionItem>[];
    final pendingIdentifiers = <String>[];
    DateTime lastBatchSaveTime = DateTime.now();

    // Pre-cache deduplication sets in memory once to avoid heavy O(N*M) shared_preferences and .toSet() overhead
    final cachedDeletedSet = controller.storage.getDeletedSlips().map((s) => s.trim().toLowerCase()).toSet();
    final cachedImportedSet = controller.storage.getImportedSlipIdentifiers().map((s) => s.trim().toLowerCase()).toSet();
    int iterationCount = 0;
    int unimportedProcessedCount = 0;
    // For ongoing pull-to-refresh scans, cap maximum unimported files processed to keep pull-to-refresh instantaneous (1-2s)
    final maxOcrPerCycle = isInitialScan ? 999999 : 30;

    for (final slip in allSlips) {
      iterationCount++;
      // Yield to UI rendering loop every 8 items even during fast duplicate checks to guarantee 60/120 FPS
      if (iterationCount % 8 == 0) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      final path = slip['path'] as String? ?? '';
      final uri = slip['uri'] as String? ?? '';
      final name = slip['name'] as String? ?? '';
      final bankName = slip['bankName'] as String? ?? 'ธนาคารไทย';
      final timestamp = slip['dateAdded'] as num? ?? DateTime.now().millisecondsSinceEpoch;
      final slipDate = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());

      // Filter: cutoffDate (12 months for initial scan, 2 months for ongoing scans)
      if (!isCreator && slipDate.isBefore(cutoffDate)) {
        continue;
      }

      if (path.isEmpty && name.isEmpty && uri.isEmpty) continue;

      final key = _getSlipKey(path.isNotEmpty ? path : uri, name);
      if (key.isNotEmpty) {
        if (_inFlightKeys.contains(key) || _processedKeys.contains(key)) {
          continue;
        }
        _inFlightKeys.add(key);
      }

      try {
        // 1. Blazing fast O(1) Duplicate Check before OCR using pre-cached sets
        final isDup = DuplicateSlipChecker.isDuplicate(
          existingTransactions: controller.allTransactions,
          cachedDeletedSet: cachedDeletedSet,
          cachedImportedSet: cachedImportedSet,
          filePath: path.isNotEmpty ? path : uri,
          fileName: name,
        );
        if (isDup) {
          if (key.isNotEmpty) _processedKeys.add(key);
          continue;
        }

        // Cap new unimported files processed per ongoing refresh cycle to ensure 1-2s snappy responsiveness
        if (unimportedProcessedCount >= maxOcrPerCycle) {
          break;
        }
        unimportedProcessedCount++;

        // Monthly quota check: only enforced for ongoing scans in PlayStore edition, NOT for Creator Edition or initial scan
        if (!isCreator && !isInitialScan && !controller.canImportMoreSlips) {
          break; // Monthly quota limit reached
        }

        final item = await _createTransactionFromSlip(
          controller: controller,
          path: path,
          uri: uri,
          name: name,
          bankName: bankName,
          date: slipDate,
        );

        if (item != null) {
          // If extracted transaction date is before cutoff date, discard it (unless Creator Edition)
          if (!isCreator && item.date.isBefore(cutoffDate)) {
            if (key.isNotEmpty) _processedKeys.add(key);
            continue;
          }

          final newIds = [
            path.toLowerCase(),
            name.trim().toLowerCase(),
            DuplicateSlipChecker.extractBasename(name),
            DuplicateSlipChecker.extractBasename(path),
            if (item.slipImageUrl != null) DuplicateSlipChecker.extractBasename(item.slipImageUrl),
            if (item.slipRefId != null && !item.slipRefId!.startsWith('SLIP-') && !item.slipRefId!.startsWith('NO-QR-')) item.slipRefId!.toLowerCase(),
          ];

          cachedImportedSet.addAll(newIds);
          pendingBatch.add(item);
          pendingIdentifiers.addAll(newIds);

          // Consolidated batch save every 5 items or 1.2s to prevent UI rebuild thrashing and stutter.
          // Ongoing scans flush every item so the monthly quota check above stays exact.
          if (!isInitialScan || pendingBatch.length >= 5 || DateTime.now().difference(lastBatchSaveTime).inMilliseconds >= 1200) {
            importedSlips.addAll(await _flushBatch(controller, pendingBatch, pendingIdentifiers, isInitialScan));
            lastBatchSaveTime = DateTime.now();
          }

          if (key.isNotEmpty) _processedKeys.add(key);
        }
        // Yield to event loop to keep UI rendering smoothly at 60/120fps
        await Future.delayed(const Duration(milliseconds: 25));
      } finally {
        if (key.isNotEmpty) _inFlightKeys.remove(key);
      }
    }

    // Flush any remaining batch
    if (pendingBatch.isNotEmpty) {
      importedSlips.addAll(await _flushBatch(controller, pendingBatch, pendingIdentifiers, isInitialScan));
    }

      if (isInitialScan) {
        await NativeBridgeService.cancelScanProgressNotification();
        if (importedSlips.isNotEmpty) {
          await NativeBridgeService.showScanCompletedNotification(
            title: 'เหมียวตังค์: ดึงสลิปสำเร็จแล้ว! 🎉',
            message: 'บันทึกย้อนหลังเรียบร้อย ${importedSlips.length} รายการ (โควต้าเดือนนี้ยังเหลือเต็ม 0/10 สลิป)',
          );
        }
        await controller.storage.setInitialDeviceScanCompleted(true);
      }

      return importedSlips;
    } finally {
      controller.setProcessingSlips(false);
    }
  }

  /// Saves the pending batch and returns only the items that were really added
  /// (addTransactionsBatch silently drops duplicates). Quota is charged only for those.
  static Future<List<TransactionItem>> _flushBatch(
    ExpenseController controller,
    List<TransactionItem> pendingBatch,
    List<String> pendingIdentifiers,
    bool isInitialScan,
  ) async {
    final batch = List<TransactionItem>.from(pendingBatch);
    pendingBatch.clear();
    final identifiers = List<String>.from(pendingIdentifiers);
    pendingIdentifiers.clear();

    await controller.addTransactionsBatch(batch, isInitialImport: isInitialScan);
    await controller.storage.addImportedSlipIdentifiers(identifiers);

    final savedIds = controller.allTransactions.map((t) => t.id).toSet();
    final added = batch.where((t) => savedIds.contains(t.id)).toList();

    if (!isInitialScan) {
      for (final item in added) {
        await controller.recordSlipImported(slipDate: item.date, isInitialImport: false);
      }
    }
    return added;
  }

  /// Cleans up any existing duplicate transactions in the database (e.g. from previous double-scans)
  static Future<int> deduplicateExistingTransactions(ExpenseController controller) async {
    final all = List<TransactionItem>.from(controller.allTransactions);
    if (all.length <= 1) return 0;

    final toRemoveIds = <String>{};
    final seenSlips = <String>{};

    for (int i = 0; i < all.length; i++) {
      final tx = all[i];
      if (toRemoveIds.contains(tx.id)) continue;

      // 1. Check duplicate image filename
      if (tx.slipImageUrl != null && tx.slipImageUrl!.isNotEmpty) {
        final bName = DuplicateSlipChecker.extractBasename(tx.slipImageUrl);
        if (bName.isNotEmpty) {
          if (seenSlips.contains(bName)) {
            toRemoveIds.add(tx.id);
            continue;
          }
          seenSlips.add(bName);
        }
      }

      // 2. Check duplicate with another transaction in the list
      for (int j = i + 1; j < all.length; j++) {
        final other = all[j];
        if (toRemoveIds.contains(other.id)) continue;

        final isDup = DuplicateSlipChecker.isDuplicate(
          existingTransactions: [tx],
          filePath: other.slipImageUrl,
          fileName: other.slipImageUrl != null ? DuplicateSlipChecker.extractBasename(other.slipImageUrl) : null,
          refId: other.slipRefId,
          amount: other.amount,
          date: other.date,
          bankName: other.bankName,
          excludeId: other.id,
        );

        if (isDup) {
          toRemoveIds.add(other.id);
        }
      }
    }

    if (toRemoveIds.isNotEmpty) {
      for (final id in toRemoveIds) {
        await controller.deleteTransaction(id);
      }
    }

    return toRemoveIds.length;
  }

  /// Checks if the image is in an official dedicated bank app folder or PaoTang folder
  static bool isDedicatedBankOrPaotangFolder(String path, String name) {
    final clean = '$path $name'.toLowerCase().replaceAll('\\', '/');
    // Reject screenshots
    if (clean.contains('screenshot') || clean.contains('screen_capture') || clean.contains('capture_') || clean.contains('/screenshots')) {
      return false;
    }
    // Reject camera & general downloads
    if (clean.contains('dcim/camera') || clean.contains('pictures/facebook') || clean.contains('pictures/line') ||
        clean.contains('pictures/instagram') || clean.contains('pictures/telegram') || clean.contains('pictures/saved')) {
      return false;
    }

    final bankDirs = [
      'pictures/kplus', 'pictures/k plus', 'dcim/kplus', 'dcim/k plus', 'k plus', 'kplus', 'kbank',
      'pictures/scb easy', 'pictures/scb', 'dcim/scb easy', 'dcim/scb', 'scb easy', 'scbeasy',
      'pictures/krungthai next', 'pictures/ktb', 'dcim/krungthai next', 'pictures/krungthai', 'krungthai next',
      'pictures/paotang', 'pictures/เป๋าตัง', 'dcim/paotang', 'download/paotang', 'download/เป๋าตัง', 'paotang', 'เป๋าตัง', 'g-wallet', 'gwallet',
      'pictures/truemoney', 'pictures/truemoney wallet', 'dcim/truemoney', 'truemoney',
      'pictures/bualuang', 'pictures/bangkokbank', 'dcim/bualuang', 'pictures/bbl', 'bualuang', 'bangkokbank',
      'pictures/ttb touch', 'pictures/ttb', 'pictures/tmb', 'pictures/thanachart', 'dcim/ttb touch', 'ttb touch',
      'pictures/mymo', 'dcim/mymo', 'pictures/gsb', 'mymo',
      'pictures/kma', 'pictures/krungsri', 'dcim/kma', 'kma',
      'pictures/kept', 'dcim/kept', 'kept',
      'pictures/dime', 'dcim/dime', 'dime',
      'pictures/cimb', 'pictures/cimb thai', 'dcim/cimb', 'cimb',
      'pictures/tmrw', 'pictures/uob', 'dcim/tmrw', 'tmrw', 'uob',
      'pictures/kkp mobile', 'pictures/kkp', 'dcim/kkp', 'kkp',
      'pictures/ghb all', 'pictures/ghb', 'dcim/ghb', 'ghb',
      'pictures/tisco', 'dcim/tisco', 'tisco',
      'pictures/lhb you', 'pictures/lhb', 'dcim/lhb', 'lhb',
      'pictures/ibank', 'pictures/islamicbank', 'dcim/ibank', 'ibank',
      'pictures/make', 'dcim/make', 'make by kbank', 'cloud pocket',
      'pictures/baac', 'dcim/baac', 'pictures/ธกส', 'pictures/a-mobile', 'baac', 'a-mobile', 'ธกส',
      'pictures/shopeepay', 'pictures/airpay', 'dcim/shopeepay', 'shopeepay', 'airpay',
    ];
    return bankDirs.any((dir) => clean.contains(dir));
  }

  static Future<TransactionItem?> _createTransactionFromSlip({
    required ExpenseController controller,
    required String path,
    String? uri,
    required String name,
    required String bankName,
    required DateTime date,
  }) async {
    final effectivePath = (path.isNotEmpty && File(path).existsSync())
        ? path
        : ((uri != null && uri.startsWith('content://')) ? uri : path);
    final file = File(effectivePath);
    if (!file.existsSync() && !effectivePath.startsWith('content://')) {
      return null;
    }

    // 1. Process image pixels with Google ML Kit native engine
    final mlResult = await NativeBridgeService.processSlipImage(effectivePath);
    final qrPayload = mlResult['qrPayload'] as String? ?? '';
    final rawOcrText = mlResult['ocrText'] as String? ?? '';

    final combined = '$rawOcrText $name $bankName';

    // 2. Validate if image is a bank slip
    final isSlipValid = OcrEngineService.isBankSlip(
      combined,
      fileName: name,
      filePath: effectivePath,
      qrPayload: qrPayload,
    );

    if (!isSlipValid) {
      return null;
    }

    final cleanCombined = '$rawOcrText $name $bankName $effectivePath'.toLowerCase();

    // Check QR code payload first for sending bank code (066 = Islamic Bank of Thailand, 006 = Krungthai, 004 = KBank)
    QrSlipResult? qrSlipParsed;
    if (qrPayload.trim().isNotEmpty) {
      qrSlipParsed = QrSlipParserService.parseQrCodePayload(qrPayload);
    }

    final String? qrSenderCode = qrSlipParsed?.senderBankCode;

    // Detect Bank using unified ThaiBankDetector.identifySlipBank (strict sender/receiver isolation)
    final bankIdent = ThaiBankDetector.identifySlipBank(
      rawOcrText: rawOcrText,
      qrSenderBankCode: qrSenderCode,
      qrSenderBank: qrSlipParsed?.senderBank ?? (bankName != 'ธนาคารไทย' ? bankName : null),
      qrPayload: qrPayload,
      filePath: path,
      fileName: name,
    );

    final bool isIBank = bankIdent.bankCode == 'IBANK';
    final bool isKBank = bankIdent.bankCode == 'KBANK';
    final bool isKrungthai = bankIdent.bankCode == 'KTB';
    final bool isSCB = bankIdent.bankCode == 'SCB';
    final bool isPaotangGovNoQr = bankIdent.bankCode == 'PAOTANG' && qrPayload.isEmpty;

    // 3. Extract Amount & Identifiers
    final bool hasQrCode = qrPayload.trim().isNotEmpty;
    double detectedAmount = 0.0;
    String refId = 'SLIP-${DateTime.now().millisecondsSinceEpoch}';

    // Step A: Parse from QR Code payload if available
    if (hasQrCode) {
      final qrResult = QrSlipParserService.parseQrCodePayload(qrPayload);
      if (qrResult.success && qrResult.amount > 0) {
        detectedAmount = qrResult.amount;
        if (qrResult.refId != null && qrResult.refId!.isNotEmpty) refId = qrResult.refId!;
        if (qrResult.senderBank != null) bankName = qrResult.senderBank!;
      }
    }

    // Step B: If amount not inside QR payload, ALWAYS extract exact amount from OCR text!
    if (detectedAmount <= 0) {
      final ocrParsed = controller.parseSlip(
        rawOcrText,
        fileName: name,
        filePath: path,
        qrPayload: qrPayload,
        defaultBankCode: bankIdent.bankCode,
      );
      if (ocrParsed.amount > 0) {
        detectedAmount = ocrParsed.amount;
        if (ocrParsed.refId.isNotEmpty) refId = ocrParsed.refId;
        if (ocrParsed.senderBank.isNotEmpty) bankName = ocrParsed.senderBank;
      } else {
        detectedAmount = OcrEngineService.extractAmountFromText(rawOcrText.isNotEmpty ? rawOcrText : name);
      }
    }

    // Step C: Fallback to EasyOCR/Tesseract fusion if needed
    if (detectedAmount <= 0) {
      detectedAmount = EasyOcrTesseractFusionService.extractAmount(rawOcrText);
    }

    // Special Case: PaoTang / Government Project Slips (Explicit User Directive: Initial amount = 0.0)
    // CRITICAL EXCEPTION: Islamic Bank (iBank) is strictly exempted and preserved as-is!
    final bool isIBankExempt = isIBank ||
        cleanCombined.contains('อิสลาม') ||
        cleanCombined.contains('ibank') ||
        cleanCombined.contains('islamic') ||
        cleanCombined.contains('บัญชีไอแบงก์') ||
        cleanCombined.contains('บัญชีไอแบงค์') ||
        cleanCombined.contains('ไอแบงก์') ||
        cleanCombined.contains('ไอแบงค์') ||
        cleanCombined.contains('ไอเเบงก์') ||
        cleanCombined.contains('ไอเเบงค์') ||
        cleanCombined.contains('ไอแบง') ||
        cleanCombined.contains('ไอเเบง');
    final bool isPaotangFolder = cleanCombined.contains('เป๋าตัง') ||
        cleanCombined.contains('paotang') ||
        cleanCombined.contains('g-wallet') ||
        path.toLowerCase().contains('paotang') ||
        path.contains('เป๋าตัง');

    final bool isPaotangGovProject = !isIBankExempt && (
        cleanCombined.contains('ไทยช่วยไทย') ||
        cleanCombined.contains('คนละครึ่ง') ||
        cleanCombined.contains('เราชนะ') ||
        cleanCombined.contains('สวัสดิการแห่งรัฐ') ||
        cleanCombined.contains('เงินช่วยเหลือ') ||
        isPaotangFolder
    );

    if (isPaotangGovProject) {
      final govAmt = EasyOcrTesseractFusionService.extractPaotangGovPaidAmount(rawOcrText);
      if (govAmt > 0) {
        detectedAmount = govAmt;
      }
      refId = 'GOV-PAOTANG-${DateTime.now().millisecondsSinceEpoch}';
    } else if (detectedAmount <= 0) {
      if (isPaotangFolder && !hasQrCode) {
        // PaoTang no-QR exception: Allow 0.0 with prompt
        detectedAmount = 0.0;
        refId = 'NO-QR-${DateTime.now().millisecondsSinceEpoch}';
      } else {
        // For other banks without QR and without valid amount -> Reject non-slip image
        final inBankFolder = isDedicatedBankOrPaotangFolder(path, name) ||
            OcrEngineService.isDedicatedBankFolder(path) ||
            OcrEngineService.isDedicatedBankFolder(name);
        if (!inBankFolder) {
          return null;
        }
      }
    }

    // Extract exact Date & Time printed on the slip
    DateTime txDate = OcrEngineService.extractDateTimeFromText(
      rawOcrText,
      fileName: name,
      filePath: path,
    );
    if (txDate.year < 2020 || txDate.year > DateTime.now().year + 1) {
      txDate = date;
    }

    // 3.5. Secondary Duplicate Check with extracted amount, date, refId
    final isPostDup = DuplicateSlipChecker.isDuplicate(
      existingTransactions: controller.allTransactions,
      deletedSlipIdentifiers: controller.storage.getDeletedSlips(),
      importedSlipIdentifiers: controller.storage.getImportedSlipIdentifiers(),
      filePath: path,
      fileName: name,
      refId: refId,
      amount: detectedAmount,
      date: txDate,
      bankName: bankName,
    );
    if (isPostDup) {
      await controller.storage.addImportedSlipIdentifiers([
        path.toLowerCase(),
        name.trim().toLowerCase(),
        DuplicateSlipChecker.extractBasename(name),
        DuplicateSlipChecker.extractBasename(path),
        if (refId.isNotEmpty && !refId.startsWith('SLIP-') && !refId.startsWith('NO-QR-')) refId.toLowerCase(),
      ]);
      return null;
    }

    // 4. Extract Sender & Receiver Names
    SlipExtractResult? ocrParsed;
    if (rawOcrText.isNotEmpty) {
      ocrParsed = controller.parseSlip(
        rawOcrText,
        fileName: name,
        filePath: path,
        qrPayload: qrPayload,
        defaultBankCode: bankIdent.bankCode,
      );
    }
    final extractedParties = OcrEngineService.extractSenderAndReceiver(rawOcrText, rawOcrText.split('\n'));
    final senderName = (ocrParsed != null && ocrParsed.senderName != 'ไม่ระบุผู้โอน')
        ? ocrParsed.senderName
        : (extractedParties['sender'] != 'ไม่ระบุผู้โอน' ? extractedParties['sender']! : 'ไม่ระบุผู้โอน');
    final receiverName = (ocrParsed != null && ocrParsed.receiverName != 'ไม่ระบุผู้รับ')
        ? ocrParsed.receiverName
        : (extractedParties['receiver'] != 'ไม่ระบุผู้รับ' ? extractedParties['receiver']! : 'ไม่ระบุผู้รับ');

    // 5. Extract Memo / Note using EasyOcrTesseractFusionService & RegEx
    String? extractedMemo = ocrParsed?.memo;
    if (extractedMemo == null || extractedMemo.isEmpty) {
      final fusionMemo = EasyOcrTesseractFusionService.extractMemo(rawOcrText);
      if (fusionMemo.isNotEmpty) {
        extractedMemo = fusionMemo;
      }
    }
    if (extractedMemo == null || extractedMemo.isEmpty) {
      final memoRegex = RegExp(
        r'(?:บันทึกช่วยจำ|บันทึกช่วยจํา|ข้อความช่วยจำ|ช่วยจำ|บันทึก|หมายเหตุ|Memo|Note|ข้อความ|รายละเอียด)[:\s]*([^\n\r]+)',
        caseSensitive: false,
      );
      final memoMatch = memoRegex.firstMatch(rawOcrText);
      if (memoMatch != null && memoMatch.group(1) != null) {
        extractedMemo = memoMatch.group(1)!.trim();
      }
    }

    // 6. Detect Income vs Expense vs Transfer for Bank Slip using unified engine
    final bool isSelf = (ocrParsed != null && ocrParsed.isSelfTransfer) ||
        OcrEngineService.isSelfTransfer(senderName, receiverName, rawText: rawOcrText);

    final TransactionType txType = (ocrParsed != null && ocrParsed.suggestedType != TransactionType.expense)
        ? ocrParsed.suggestedType
        : OcrEngineService.detectSlipTransactionType(
            rawText: rawOcrText,
            fileName: name,
            filePath: path,
            memo: extractedMemo,
            senderName: senderName,
            receiverName: receiverName,
            isSelf: isSelf,
          );
    final bool isIncome = txType == TransactionType.income;
    final lowerCombined = '$rawOcrText $name $bankName ${extractedMemo ?? ""}'.toLowerCase();

    final customRulesRaw = controller.storage.getKeywordRules();
    final customRules = customRulesRaw.map((r) => KeywordRule.fromJson(r)).toList();

    final expenseFallback = controller.expenseCategories.firstWhere(
      (c) => c.name == 'รายจ่ายอื่นๆ' || c.id == 'cat_other_exp' || c.name.contains('อื่นๆ'),
      orElse: () => controller.expenseCategories.firstWhere(
        (c) => c.name.contains('รายจ่าย') || c.name.contains('ทั่วไป'),
        orElse: () => CategoryItem(
          id: 'cat_other_exp',
          name: 'รายจ่ายอื่นๆ',
          iconKey: 'category',
          colorValue: 0xFF94A3B8,
          type: CategoryType.expense,
        ),
      ),
    );

    final incomeFallback = controller.incomeCategories.firstWhere(
      (c) => c.name.contains('เงินเดือน') || c.name.contains('รายได้') || c.name.contains('โอน') || c.name.contains('ริซกี') || c.name.contains('ช่วยเหลือ'),
      orElse: () => CategoryItem(
        id: 'cat_income_default',
        name: 'รับเงินโอน / รายได้',
        iconKey: 'payments',
        colorValue: 0xFF10B981,
        type: CategoryType.income,
      ),
    );

    final targetCategories = isIncome
        ? (controller.incomeCategories.isNotEmpty ? controller.incomeCategories : controller.categories.where((c) => c.type == CategoryType.income).toList())
        : (controller.expenseCategories.isNotEmpty ? controller.expenseCategories : controller.categories.where((c) => c.type == CategoryType.expense).toList());

    final bool hasMemo = extractedMemo != null &&
        extractedMemo.trim().isNotEmpty &&
        extractedMemo.trim() != 'โปรดระบุยอด';

    // Search context: combine memo, recipient name, sender name, and OCR text for keyword matching
    final searchContext = [
      if (hasMemo) extractedMemo!,
      if (receiverName != 'ไม่ระบุผู้รับ' && receiverName.trim().isNotEmpty) receiverName.trim(),
      if (senderName != 'ไม่ระบุผู้โอน' && senderName.trim().isNotEmpty) senderName.trim(),
      rawOcrText,
    ].join(' ');

    final matchResult = CategoryMatcherService.matchCategoryWithResult(
      text: searchContext,
      availableCategories: targetCategories.isNotEmpty ? targetCategories : controller.categories,
      customRules: customRules,
      fallbackCategory: isIncome ? incomeFallback : expenseFallback,
    );

    CategoryItem matchedCat = matchResult.category;
    String? matchedTag = matchResult.tag;

    // 7. Format Title to show Who transferred to Whom or Income Notification
    String cleanBank = bankIdent.cleanBank;
    bankName = bankIdent.bankName;

    String title;
    if (isIncome) {
      if (lowerCombined.contains('ไทยช่วยไทย')) {
        title = 'เงินช่วยเหลือ (ไทยช่วยไทย)';
      } else if (lowerCombined.contains('คนละครึ่ง')) {
        title = 'สิทธิประโยชน์ (คนละครึ่ง)';
      } else if (lowerCombined.contains('เราชนะ')) {
        title = 'เงินช่วยเหลือ (เราชนะ)';
      } else if (lowerCombined.contains('สวัสดิการ')) {
        title = 'เงินช่วยเหลือ (สวัสดิการแห่งรัฐ)';
      } else if (senderName != 'ไม่ระบุผู้โอน' && senderName.isNotEmpty) {
        title = 'รับเงินโอนจาก $senderName';
      } else if (isIBank || cleanBank == 'ธนาคารอิสลาม') {
        title = 'รับเงินโอนผ่านธนาคารอิสลาม';
      } else {
        title = 'รับเงินโอนผ่าน$cleanBank';
      }
    } else {
      final isBillPayment = rawOcrText.contains('จ่ายบิล') ||
          rawOcrText.contains('ชำระบิล') ||
          rawOcrText.contains('เติมเงิน') ||
          rawOcrText.contains('ชำระค่าบริการ');
      if (receiverName != 'ไม่ระบุผู้รับ' && receiverName.trim().isNotEmpty) {
        if (isBillPayment) {
          title = 'จ่ายบิล $receiverName';
        } else {
          title = 'โอนให้ $receiverName';
        }
      } else {
        if (isBillPayment) {
          title = 'จ่ายบิลผ่าน$cleanBank';
        } else {
          title = 'โอนเงินผ่าน$cleanBank';
        }
      }
    }

    final cleanSender = (senderName != 'ไม่ระบุผู้โอน' && senderName.trim().isNotEmpty) ? senderName.trim() : null;
    final cleanReceiver = (receiverName != 'ไม่ระบุผู้รับ' && receiverName.trim().isNotEmpty) ? receiverName.trim() : null;

    // Clean up extractedMemo: remove any legacy warning strings
    if (extractedMemo != null) {
      extractedMemo = extractedMemo
          .replaceAll('ไม่มี QR Code - กรุณากรอกยอดเงิน', '')
          .replaceAll('ไม่มี QR Code กรุณากรอกยอดเงิน', '')
          .trim();
      if (extractedMemo.isEmpty) extractedMemo = null;
    }

    // When detectedAmount is 0 (or <= 0), set memo to 'โปรดระบุยอด' as requested by the user
    if (detectedAmount <= 0.0) {
      extractedMemo = 'โปรดระบุยอด';
    } else if (extractedMemo != null && (extractedMemo.contains('สลิปไม่มี QR Code') || extractedMemo.contains('แตะเพื่อระบุยอด') || extractedMemo.contains('โปรดระบุยอด'))) {
      extractedMemo = null;
    }

    // Prepare tags list
    final List<String> itemTags = [];
    if (matchedTag != null && matchedTag.trim().isNotEmpty) {
      final cleanTag = matchedTag.trim().replaceAll('#', '');
      if (cleanTag.isNotEmpty) {
        itemTags.add(cleanTag);
      }
    }

    String? finalNote = (extractedMemo != null && extractedMemo.trim().isNotEmpty) ? extractedMemo.trim() : null;
    if (itemTags.isNotEmpty) {
      final tagBadge = itemTags.map((t) => '#$t').join(' ');
      if (finalNote == null || finalNote.isEmpty) {
        finalNote = tagBadge;
      } else if (!finalNote.contains(tagBadge)) {
        finalNote = '$finalNote $tagBadge';
      }
    }

    final persistentSlipPath = await SlipStorageService.persistSlipImage(effectivePath);

    // Auto-link slip directly to the corresponding bank account (e.g. IBANK, KBank, SCB, KTB)
    final targetBankCode = bankIdent.bankCode;
    final targetAccount = controller.getOrCreateAccountForBank(targetBankCode, bankName: cleanBank);

    return TransactionItem(
      id: 'tx_auto_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      amount: detectedAmount,
      type: txType,
      date: txDate,
      accountId: targetAccount.id,
      categoryId: matchedCat.id,
      categoryName: matchedCat.name,
      note: finalNote,
      senderName: cleanSender,
      receiverName: cleanReceiver,
      bankName: cleanBank,
      slipRefId: refId,
      slipImageUrl: persistentSlipPath,
      tags: itemTags,
    );
  }
}
