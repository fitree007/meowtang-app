import 'dart:io';
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

  /// Scans device storage for new bank slips and imports unimported slips from CURRENT & PREVIOUS month only.
  /// On initial import, existing device slips do NOT consume monthly quota, keeping it clean at 0/15!
  static Future<List<TransactionItem>> scanAndAutoImportNewSlips(ExpenseController controller) async {
    _processedKeys.clear();
    _inFlightKeys.clear();
    // 0. Auto-clean existing duplicates in database if any exist
    await deduplicateExistingTransactions(controller);

    // 0.1. Seed persistent registry with any existing transactions
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

    final isCreator = AppConfig.isCreatorEdition;
    final now = DateTime.now();
    final startOfPreviousMonth = getStartOfPreviousMonth(now);
    // In Creator Edition: scan ALL historical slips on device without cutoff (daysLimit = 0)
    final daysToScan = isCreator ? 0 : (now.difference(startOfPreviousMonth).inDays + 2);

    final slipFiles = await NativeBridgeService.scanBankSlips(daysLimit: daysToScan);
    final allSlips = List<Map<String, dynamic>>.from(slipFiles);

    // Direct Physical Folder scan for PaoTang & other slip directories to guarantee 100% detection
    final paoTangDirs = [
      Directory('/storage/emulated/0/Pictures/PaoTang'),
      Directory('/storage/emulated/0/Pictures/เป๋าตัง'),
      Directory('/storage/emulated/0/DCIM/PaoTang'),
      Directory('/storage/emulated/0/Download/PaoTang'),
    ];

    for (final dir in paoTangDirs) {
      try {
        if (dir.existsSync()) {
          final entities = dir.listSync(recursive: false);
          for (final entity in entities) {
            if (entity is File) {
              final path = entity.path;
              final ext = path.split('.').last.toLowerCase();
              if (['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
                final stat = entity.statSync();
                // Filter: strictly current month and previous month only (unless Creator Edition)
                if (!isCreator && stat.modified.isBefore(startOfPreviousMonth)) {
                  continue;
                }
                if (stat.size > 1024) {
                  final name = path.split(RegExp(r'[\/\\]')).last;
                  final baseName = DuplicateSlipChecker.extractBasename(name);
                  
                  // Strict deduplication check inside slip list (check path, name, and basename)
                  final alreadyInList = allSlips.any((s) {
                    final sPath = s['path'] as String? ?? '';
                    final sName = s['name'] as String? ?? '';
                    final sBase = DuplicateSlipChecker.extractBasename(sName.isNotEmpty ? sName : sPath);
                    return sPath == path || (baseName.isNotEmpty && sBase == baseName);
                  });

                  if (!alreadyInList) {
                    final lower = name.toLowerCase();
                    final bank = (lower.contains('ibank') || lower.contains('อิสลาม'))
                        ? 'iBank (อิสลามแห่งประเทศไทย)'
                        : (lower.contains('ไทยช่วยไทย') ? 'ไทยช่วยไทย (เป๋าตัง)' : 'เป๋าตัง (PaoTang)');
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

    if (allSlips.isEmpty) return [];

    final isInitialScan = !controller.storage.isInitialDeviceScanCompleted();
    final importedSlips = <TransactionItem>[];

    for (final slip in allSlips) {
      final path = slip['path'] as String? ?? '';
      final name = slip['name'] as String? ?? '';
      final bankName = slip['bankName'] as String? ?? 'ธนาคารไทย';
      final timestamp = slip['dateAdded'] as num? ?? DateTime.now().millisecondsSinceEpoch;
      final slipDate = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());

      // Filter: strictly current month and previous month only (unless Creator Edition)
      if (!isCreator && slipDate.isBefore(startOfPreviousMonth)) {
        continue;
      }

      if (path.isEmpty && name.isEmpty) continue;

      final key = _getSlipKey(path, name);
      if (key.isNotEmpty) {
        if (_inFlightKeys.contains(key) || _processedKeys.contains(key)) {
          continue;
        }
        _inFlightKeys.add(key);
      }

      try {
        // 1. Initial Duplicate Check before OCR
        final isDup = DuplicateSlipChecker.isDuplicate(
          existingTransactions: controller.allTransactions,
          deletedSlipIdentifiers: controller.storage.getDeletedSlips(),
          importedSlipIdentifiers: controller.storage.getImportedSlipIdentifiers(),
          filePath: path,
          fileName: name,
        );
        if (isDup) {
          if (key.isNotEmpty) _processedKeys.add(key);
          continue;
        }

        // Monthly quota check: only enforced for ongoing scans in PlayStore edition, NOT for Creator Edition or initial scan
        if (!isCreator && !isInitialScan && !controller.canImportMoreSlips) {
          break; // Monthly quota limit reached
        }

        final item = await _createTransactionFromSlip(
          controller: controller,
          path: path,
          name: name,
          bankName: bankName,
          date: slipDate,
        );

        if (item != null) {
          // If extracted transaction date is before previous month, discard it (unless Creator Edition)
          if (!isCreator && item.date.isBefore(startOfPreviousMonth)) {
            if (key.isNotEmpty) _processedKeys.add(key);
            continue;
          }

          final added = await controller.addTransaction(item);
          if (added) {
            importedSlips.add(item);
            await controller.recordSlipImported(
              slipDate: item.date,
              isInitialImport: isInitialScan,
            );
            await controller.storage.addImportedSlipIdentifiers([
              path.toLowerCase(),
              name.trim().toLowerCase(),
              DuplicateSlipChecker.extractBasename(name),
              DuplicateSlipChecker.extractBasename(path),
              if (item.slipImageUrl != null) DuplicateSlipChecker.extractBasename(item.slipImageUrl),
              if (item.slipRefId != null && !item.slipRefId!.startsWith('SLIP-') && !item.slipRefId!.startsWith('NO-QR-')) item.slipRefId!.toLowerCase(),
            ]);
          }
          if (key.isNotEmpty) _processedKeys.add(key);
        }
        // Yield to event loop to keep UI rendering in real-time
        await Future.delayed(const Duration(milliseconds: 10));
      } finally {
        if (key.isNotEmpty) _inFlightKeys.remove(key);
      }
    }

    if (isInitialScan) {
      await controller.storage.setInitialDeviceScanCompleted(true);
    }

    return importedSlips;
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
    ];
    return bankDirs.any((dir) => clean.contains(dir));
  }

  static Future<TransactionItem?> _createTransactionFromSlip({
    required ExpenseController controller,
    required String path,
    required String name,
    required String bankName,
    required DateTime date,
  }) async {
    final file = File(path);
    if (!file.existsSync() && !path.startsWith('content://')) {
      return null;
    }

    // 1. Process image pixels with Google ML Kit native engine
    final mlResult = await NativeBridgeService.processSlipImage(path);
    final qrPayload = mlResult['qrPayload'] as String? ?? '';
    final rawOcrText = mlResult['ocrText'] as String? ?? '';

    final combined = '$rawOcrText $name $bankName';

    // 2. Validate if image is a bank slip
    final isSlipValid = OcrEngineService.isBankSlip(
      combined,
      fileName: name,
      filePath: path,
      qrPayload: qrPayload,
    );

    if (!isSlipValid) {
      return null;
    }

    final cleanCombined = '$rawOcrText $name $bankName $path'.toLowerCase();

    // Check QR code payload first for sending bank code (066 = Islamic Bank of Thailand, 006 = Krungthai, 004 = KBank)
    QrSlipResult? qrSlipParsed;
    if (qrPayload.trim().isNotEmpty) {
      qrSlipParsed = QrSlipParserService.parseQrCodePayload(qrPayload);
    }

    final String? qrSenderCode = qrSlipParsed?.senderBankCode;
    final bool qrIndicatesOtherBank = qrSenderCode != null && qrSenderCode.isNotEmpty && qrSenderCode != '066';

    final bool isKBank = (qrSenderCode == '004') ||
        cleanCombined.contains('k plus') ||
        cleanCombined.contains('kplus') ||
        cleanCombined.contains('kbank') ||
        cleanCombined.contains('kasikorn') ||
        path.toLowerCase().contains('k plus') ||
        path.toLowerCase().contains('kplus') ||
        path.toLowerCase().contains('kbank');

    // Krungthai explicit signatures (Ref ID starting with N006, bank code 006, or Krungthai without Islamic mentions)
    final bool isKrungthai = (qrSenderCode == '006') ||
        qrPayload.contains('N006') ||
        cleanCombined.contains('n006') ||
        path.toLowerCase().contains('krungthai') ||
        (cleanCombined.contains('กรุงไทย') && !cleanCombined.contains('ไอแบงก์') && !cleanCombined.contains('ธนาคารอิสลาม'));

    final bool isSCB = (qrSenderCode == '014') ||
        cleanCombined.contains('scb easy') ||
        cleanCombined.contains('scb') ||
        path.toLowerCase().contains('scb') ||
        (cleanCombined.contains('ไทยพาณิชย์') && !cleanCombined.contains('ไอแบงก์') && !cleanCombined.contains('ธนาคารอิสลาม'));

    final bool isIBank = !qrIndicatesOtherBank &&
        !isKBank &&
        !isKrungthai &&
        !isSCB &&
        ((qrSlipParsed != null && (qrSlipParsed.senderBankCode == '066' || (qrSlipParsed.senderBank != null && qrSlipParsed.senderBank!.contains('อิสลาม')))) ||
            qrPayload.toLowerCase().contains('0103066') ||
            qrPayload.toLowerCase().contains('ibank') ||
            cleanCombined.contains('ibank') ||
            cleanCombined.contains('ไอแบงก์') ||
            cleanCombined.contains('ไอแบงค์') ||
            cleanCombined.contains('ธนาคารอิสลาม') ||
            cleanCombined.contains('อิสลามแห่งประเทศไทย'));

    final bool isPaotangGovNoQr = (cleanCombined.contains('เป๋าตัง') ||
            cleanCombined.contains('paotang') ||
            cleanCombined.contains('g-wallet') ||
            cleanCombined.contains('gwallet') ||
            cleanCombined.contains('ไทยช่วยไทย') ||
            cleanCombined.contains('คนละครึ่ง') ||
            cleanCombined.contains('เราชนะ') ||
            cleanCombined.contains('สวัสดิการ') ||
            path.toLowerCase().contains('paotang') ||
            path.contains('เป๋าตัง')) &&
        !isIBank &&
        !isKBank &&
        !isKrungthai &&
        !isSCB &&
        qrPayload.isEmpty;

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
      final ocrParsed = controller.parseSlip(rawOcrText, fileName: name, filePath: path);
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

    // Special Case: PaoTang / G-Wallet without amount & without QR code (Explicit User Exemption)
    final bool isPaotangFolder = cleanCombined.contains('เป๋าตัง') ||
        cleanCombined.contains('paotang') ||
        cleanCombined.contains('g-wallet') ||
        path.toLowerCase().contains('paotang') ||
        path.contains('เป๋าตัง');

    if (detectedAmount <= 0) {
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
      ocrParsed = controller.parseSlip(rawOcrText, fileName: name, filePath: path);
    }
    final extractedParties = OcrEngineService.extractSenderAndReceiver(rawOcrText, rawOcrText.split('\n'));
    final senderName = (ocrParsed != null && ocrParsed.senderName != 'ไม่ระบุผู้โอน')
        ? ocrParsed.senderName
        : (extractedParties['sender'] != 'ไม่ระบุผู้โอน' ? extractedParties['sender']! : 'ไม่ระบุผู้โอน');
    final receiverName = (ocrParsed != null && ocrParsed.receiverName != 'ไม่ระบุผู้รับ')
        ? ocrParsed.receiverName
        : (extractedParties['receiver'] != 'ไม่ระบุผู้รับ' ? extractedParties['receiver']! : 'ไม่ระบุผู้รับ');

    // 5. Extract Memo / Note using RegEx
    String? extractedMemo = ocrParsed?.memo;
    if (extractedMemo == null || extractedMemo.isEmpty) {
      final memoRegex = RegExp(
        r'(?:บันทึกช่วยจำ|บันทึก|หมายเหตุ|Memo|Note|ข้อความ|รายละเอียด)[:\s]*([^\n\r]+)',
        caseSensitive: false,
      );
      final memoMatch = memoRegex.firstMatch(rawOcrText);
      if (memoMatch != null && memoMatch.group(1) != null) {
        extractedMemo = memoMatch.group(1)!.trim();
      }
    }

    // 6. Detect Income vs Expense for Bank Slip
    final lowerCombined = '$rawOcrText $name $bankName ${extractedMemo ?? ""}'.toLowerCase();
    final incomeKeywords = [
      'เงินเข้า', 'เงินโอนเข้า', 'โอนเงินเข้า', 'เงินเข้าบัญชี', 'ได้รับเงิน', 'รับเงิน',
      'รับโอน', 'โอนเข้า', 'ยอดเงินเข้า', 'เงินฝาก', 'ฝากเงิน', 'รับชำระ', 'รับเงินเดือน',
      'เงินเดือน', 'salary', 'deposit', 'incoming', 'transfer in', 'receive transfer',
      'cr', 'credit', 'โอนให้คุณ', 'ได้รับยอดเงิน', 'เงินเข้าสำเร็จ', 'พร้อมเพย์เงินเข้า',
      'รับโอนเงินสำเร็จ', 'เงินปันผล', 'รายรับ', 'เงินช่วยเหลือ', 'ไทยช่วยไทย', 'สวัสดิการ',
      'คนละครึ่ง', 'เราชนะ'
    ];

    final bool isIncome = (ocrParsed != null && ocrParsed.suggestedType == TransactionType.income) ||
        incomeKeywords.any((kw) => lowerCombined.contains(kw));

    // ตรวจจับการโอนเงินให้ตัวเอง: หากผู้โอนกับผู้รับซ้ำกัน ปรับเป็นโอนเงิน (transfer)
    final bool isSelf = (ocrParsed != null && ocrParsed.isSelfTransfer) ||
        OcrEngineService.isSelfTransfer(senderName, receiverName, rawText: rawOcrText);

    final txType = isSelf ? TransactionType.transfer : (isIncome ? TransactionType.income : TransactionType.expense);

    final customRulesRaw = controller.storage.getKeywordRules();
    final customRules = customRulesRaw.map((r) => KeywordRule.fromJson(r)).toList();

    final expenseFallback = controller.expenseCategories.firstWhere(
      (c) => c.name.contains('รายจ่าย') || c.name.contains('ทั่วไป') || c.name.contains('อื่นๆ'),
      orElse: () => CategoryItem(
        id: 'cat_general_exp',
        name: 'รายจ่ายทั่วไป',
        iconKey: 'category',
        colorValue: 0xFFF59E0B,
        type: CategoryType.expense,
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

    final matchedCat = CategoryMatcherService.matchCategory(
      text: '$rawOcrText $bankName $receiverName $senderName ${extractedMemo ?? ""}',
      availableCategories: targetCategories.isNotEmpty ? targetCategories : controller.categories,
      customRules: customRules,
      fallbackCategory: isIncome ? incomeFallback : expenseFallback,
    );

    // 7. Format Title to show Who transferred to Whom or Income Notification
    String cleanBank = bankName;
    if (isKBank || (qrSenderCode == '004') || cleanBank.contains('กสิกร')) {
      cleanBank = 'กสิกรไทย';
      bankName = 'กสิกรไทย (K PLUS)';
    } else if (isSCB || (qrSenderCode == '014') || cleanBank.contains('ไทยพาณิชย์')) {
      cleanBank = 'ไทยพาณิชย์';
      bankName = 'ไทยพาณิชย์ (SCB EASY)';
    } else if (isKrungthai || (qrSenderCode == '006') || cleanBank.contains('กรุงไทย')) {
      cleanBank = 'กรุงไทย';
      bankName = 'กรุงไทย (Krungthai NEXT)';
    } else if (isIBank || (qrSenderCode == '066') || cleanBank.contains('ธนาคารอิสลาม') || cleanBank.contains('ibank') || cleanBank.contains('ไอแบงก์')) {
      cleanBank = 'ธนาคารอิสลามแห่งประเทศไทย';
      bankName = 'ธนาคารอิสลามแห่งประเทศไทย';
    } else if (cleanBank.contains('กรุงเทพ') || (qrSenderCode == '002')) {
      cleanBank = 'กรุงเทพ';
    } else if (cleanBank.contains('ไทยช่วยไทย')) {
      cleanBank = 'ไทยช่วยไทย (เป๋าตัง)';
    } else if (cleanBank.contains('เป๋าตัง') || cleanBank.contains('paotang')) {
      cleanBank = 'เป๋าตัง';
    }

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
      } else if (isIBank || cleanBank == 'ธนาคารอิสลามแห่งประเทศไทย') {
        title = 'รับเงินโอน (ธนาคารอิสลาม)';
      } else {
        title = 'เงินเข้าบัญชี ($cleanBank)';
      }
    } else {
      if (senderName != 'ไม่ระบุผู้โอน' && receiverName != 'ไม่ระบุผู้รับ') {
        title = '$senderName โอนให้ $receiverName';
      } else if (receiverName != 'ไม่ระบุผู้รับ') {
        title = 'โอนให้ $receiverName';
      } else if (senderName != 'ไม่ระบุผู้โอน') {
        title = '$senderName โอนเงิน ($cleanBank)';
      } else if (isIBank || cleanBank == 'ธนาคารอิสลามแห่งประเทศไทย') {
        title = 'โอนเงินผ่านธนาคารอิสลาม';
      } else {
        title = 'โอนเงินผ่าน$cleanBank';
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

    final persistentSlipPath = await SlipStorageService.persistSlipImage(path);

    // Auto-link slip directly to the corresponding bank account (e.g. IBANK, KBank, SCB, KTB)
    final targetBankCode = isIBank ? 'IBANK' : (isKrungthai ? 'KTB' : ThaiBankDetector.detectCodeFromBankName(cleanBank));
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
      note: (extractedMemo != null && extractedMemo.trim().isNotEmpty) ? extractedMemo.trim() : null,
      senderName: cleanSender,
      receiverName: cleanReceiver,
      bankName: cleanBank,
      slipRefId: refId,
      slipImageUrl: persistentSlipPath,
    );
  }
}
