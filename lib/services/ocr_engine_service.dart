import 'dart:io';
import '../models/transaction_item.dart';
import '../models/category_item.dart';
import '../models/slip_extract_result.dart';
import 'category_matcher_service.dart';
import 'easyocr_tesseract_fusion_service.dart';

class MockSlipTemplate {
  final String id;
  final String title;
  final String bank;
  final String bankCode;
  final String bankName;
  final double amount;
  final String rawText;

  const MockSlipTemplate({
    required this.id,
    required this.title,
    required this.bank,
    required this.bankCode,
    required this.bankName,
    required this.amount,
    required this.rawText,
  });
}

class OcrEngineService {
  static bool isDedicatedBankFolder(String? path) {
    if (path == null || path.trim().isEmpty) return false;
    final lower = path.toLowerCase().replaceAll('\\', '/');
    if (lower.contains('screenshot') || lower.contains('screen_capture') || lower.contains('capture_')) {
      return false;
    }

    final bankFolders = [
      'pictures/kplus', 'pictures/k plus', 'dcim/kplus', 'dcim/k plus',
      'pictures/scb easy', 'pictures/scb', 'dcim/scb easy', 'dcim/scb',
      'pictures/krungthai next', 'pictures/ktb', 'dcim/krungthai next', 'pictures/krungthai',
      'pictures/paotang', 'pictures/เป๋าตัง', 'dcim/paotang', 'download/paotang', 'download/เป๋าตัง',
      'pictures/truemoney', 'pictures/truemoney wallet', 'dcim/truemoney',
      'pictures/bualuang', 'pictures/bangkokbank', 'dcim/bualuang', 'pictures/bbl',
      'pictures/ttb touch', 'pictures/ttb', 'pictures/tmb', 'pictures/thanachart', 'dcim/ttb touch',
      'pictures/mymo', 'dcim/mymo', 'pictures/gsb',
      'pictures/kma', 'pictures/krungsri', 'dcim/kma',
      'pictures/kept', 'dcim/kept',
      'pictures/dime', 'dcim/dime',
      'pictures/cimb', 'pictures/cimb thai', 'dcim/cimb',
      'pictures/tmrw', 'pictures/uob', 'dcim/tmrw',
      'pictures/kkp mobile', 'pictures/kkp', 'dcim/kkp',
      'pictures/ghb all', 'pictures/ghb', 'dcim/ghb',
      'pictures/tisco', 'dcim/tisco',
      'pictures/lhb you', 'pictures/lhb', 'dcim/lhb',
      'pictures/ibank', 'pictures/islamicbank', 'dcim/ibank',
    ];

    return bankFolders.any((bf) => lower.contains(bf));
  }

  static const List<MockSlipTemplate> sampleSlips = [
    MockSlipTemplate(
      id: 'slip_kbank',
      title: 'KBank โอนค่ากาแฟ',
      bank: 'KBANK',
      bankCode: 'KBANK',
      bankName: 'กสิกรไทย (K PLUS)',
      amount: 65.0,
      rawText: 'ธนาคารกสิกรไทย\nโอนเงินสำเร็จ\n25 ก.พ. 2569 08:30 น.\nจาก นายสมชาย ใจดี\nไปยัง ร้านกาแฟ มีสุข\nจำนวนเงิน 65.00 บาท\nรหัสอ้างอิง: 2026022512345678\nบันทึกช่วยจำ: ค่ากาแฟยามเช้า',
    ),
    MockSlipTemplate(
      id: 'slip_scb',
      title: 'SCB โอนค่าอาหาร',
      bank: 'SCB',
      bankCode: 'SCB',
      bankName: 'ไทยพาณิชย์ (SCB EASY)',
      amount: 120.0,
      rawText: 'ธนาคารไทยพาณิชย์\nโอนเงินสำเร็จ\n25 ก.พ. 2569 12:15 น.\nจาก นายสมชาย ใจดี\nไปยัง ร้านก๋วยเตี๋ยวเรือ\nจำนวนเงิน 120.00 บาท\nรหัสอ้างอิง: 2026022587654321\nบันทึกช่วยจำ: ก๋วยเตี๋ยวเรือมื้อเที่ยง',
    ),
    MockSlipTemplate(
      id: 'slip_ktb',
      title: 'Krungthai NEXT รับเงินเดือน',
      bank: 'KTB',
      bankCode: 'KTB',
      bankName: 'กรุงไทย (Krungthai NEXT)',
      amount: 35000.0,
      rawText: 'ธนาคารกรุงไทย\nเงินเข้าบัญชีสำเร็จ\n25 ก.พ. 2569 17:00 น.\nจาก บจก. เทคโนโลยีไทย\nไปยัง นายสมชาย ใจดี\nจำนวนเงิน 35,000.00 บาท\nรหัสอ้างอิง: 2026022599887766\nบันทึกช่วยจำ: เงินเดือนประจำเดือน ก.พ.',
    ),
    MockSlipTemplate(
      id: 'slip_ibank',
      title: 'iBank โอนเงินชำระค่าสินค้า',
      bank: 'IBANK',
      bankCode: 'IBANK',
      bankName: 'อิสลามแห่งประเทศไทย (iBank)',
      amount: 1450.0,
      rawText: 'ธนาคารอิสลามแห่งประเทศไทย (iBank)\nโอนเงินสำเร็จ\n25 ก.พ. 2569 14:00 น.\nจาก นายสมชาย ใจดี\nไปยัง ร้านค้ามุสลิมสโตร์\nจำนวนเงิน 1,450.00 บาท\nรหัสอ้างอิง: 2026022555443322\nบันทึกช่วยจำ: ค่าสินค้าฮาลาล',
    ),
  ];

    static bool isBankSlip(String rawText, {String? fileName, String? filePath, String? qrPayload}) {
    final file = (fileName ?? filePath ?? '').toLowerCase().replaceAll('\\', '/');

    // 0. Strict Negative Filter: Reject Screenshots and Screen Captures (แคปหน้าจอ)
    if (file.contains('screenshot') || file.contains('screen_capture') || file.contains('capture_')) {
      return false;
    }

    // 1. Strict Multi-Bank Passbook / BookBank / E-Passbook Rejection:
    if (EasyOcrTesseractFusionService.isPassbookOrAccountProof(rawText, fileName: fileName, filePath: filePath)) {
      return false;
    }

    final clean = rawText.toLowerCase();

    // 2. Strict QR Receive / Merchant Signboard / My QR Rejection:
    final isQrReceiveImage = clean.contains('my qr') ||
        clean.contains('myqr') ||
        clean.contains('คิวอาร์ของฉัน') ||
        clean.contains('qr รับเงิน') ||
        clean.contains('สแกนเพื่อรับเงิน') ||
        clean.contains('สแกนจ่าย') ||
        clean.contains('สแกนรับเงิน') ||
        clean.contains('แม่มณี') ||
        clean.contains('ถุงเงิน') ||
        clean.contains('ป้ายคิวอาร์') ||
        file.contains('myqr') ||
        file.contains('my_qr') ||
        file.contains('qr_receive') ||
        file.contains('qr_code_receive') ||
        file.contains('receive_qr');

    final bool hasTransferSuccessEvidence = clean.contains('โอนเงินสำเร็จ') ||
        clean.contains('รายการสำเร็จ') ||
        clean.contains('ชำระเงินสำเร็จ') ||
        clean.contains('เติมเงินสำเร็จ') ||
        clean.contains('ทำรายการสำเร็จ') ||
        clean.contains('transfer successful') ||
        clean.contains('payment successful') ||
        clean.contains('transaction successful') ||
        clean.contains('successful') ||
        clean.contains('สำเร็จ');

    if (isQrReceiveImage && !hasTransferSuccessEvidence) {
      return false;
    }

    // 3. QR Code Analysis (Differentiate between Slip Verification QR vs Pure Static Receive QR)
    if (qrPayload != null && qrPayload.trim().isNotEmpty) {
      final qClean = qrPayload.trim();
      
      // If it's a Static PromptPay Receive QR (Starts with 000201010211...) without slip signature:
      final bool isStaticReceiveQr = (qClean.startsWith('000201010211') || qClean.contains('010211')) &&
          !qClean.contains('http') &&
          !qClean.contains('slip') &&
          !qClean.contains('verify') &&
          !qClean.contains('ITMX');

      if (isStaticReceiveQr && !hasTransferSuccessEvidence) {
        // Pure QR for receiving money -> REJECT
        return false;
      }

      // Valid Bank Slip Verification URLs or ITMX Mini-QR
      if (qClean.contains('http://') ||
          qClean.contains('https://') ||
          qClean.contains('ITMX') ||
          qClean.contains('kplus') ||
          qClean.contains('scb') ||
          qClean.contains('ktb') ||
          qClean.contains('slip') ||
          qClean.contains('verify') ||
          qClean.contains('promptpay')) {
        // If image has transfer evidence or is in a bank folder or has valid ref
        if (hasTransferSuccessEvidence || isDedicatedBankFolder(filePath) || isDedicatedBankFolder(fileName) || clean.contains('รหัสอ้างอิง') || clean.contains('จำนวนเงิน')) {
          return true;
        }
      }
    }

    // 4. Slips in dedicated bank app folders
    final inBankFolder = isDedicatedBankFolder(filePath) || isDedicatedBankFolder(fileName);
    if (inBankFolder) {
      // Must not be a pure receive QR
      if (isQrReceiveImage && !hasTransferSuccessEvidence) return false;
      return true;
    }

    // 5. OCR text verification for slips: MUST have bank/transfer keywords and evidence of transaction
    final slipKeywords = [
      'รายการสำเร็จ', 'โอนเงินสำเร็จ', 'โอนสำเร็จ', 'สำเร็จ', 'ไทยช่วยไทย', 'คนละครึ่ง',
      'เราชนะ', 'สวัสดิการแห่งรัฐ', 'เงินช่วยเหลือ', 'เป๋าตัง', 'paotang', 'g-wallet',
      'gwallet', 'k plus', 'kplus', 'kbank', 'krungthai next', 'krungthai', 'ktb',
      'scb easy', 'scb', 'ibank', 'อิสลาม', 'ttb touch', 'ttb', 'mymo', 'truemoney',
      'โอนเงิน', 'รับเงิน', 'เลขที่รายการ', 'รหัสอ้างอิง', 'หมายเลขอ้างอิง', 'ref no',
      'txid', 'สลิป', 'จำนวนเงิน', 'จำนวนเงินที่ชำระ', 'ยอดเงิน', 'ยอดโอน',
      'transfer successful', 'payment successful', 'transaction successful', 'bualuang', 'bbl'
    ];

    final matchesKeyword = slipKeywords.any((kw) => clean.contains(kw) || file.contains(kw));
    if (matchesKeyword && hasTransferSuccessEvidence) {
      final amount = extractAmountFromText(rawText);
      if (amount > 0) return true;
      // Allow PaoTang / government welfare without amount
      if (clean.contains('เป๋าตัง') || clean.contains('paotang') || clean.contains('g-wallet') || clean.contains('คนละครึ่ง') || clean.contains('เราชนะ') || clean.contains('สวัสดิการ')) {
        return true;
      }
    }

    return false;
  }

  /// Advanced RegEx & EasyOCR-Tesseract Fusion parser to extract amount from bank slip text
  static double extractAmountFromText(String rawText) {
    if (rawText.isEmpty) return 0.0;
    return EasyOcrTesseractFusionService.extractAmount(rawText);
  }

  static DateTime extractDateTimeFromText(String rawText, {String? fileName, String? filePath}) {
    final now = DateTime.now();
    try {
      // 0. Pre-process and normalize text:
      // Merge split Thai abbreviations like "ส. ค." -> "ส.ค.", "ก. พ." -> "ก.พ."
      String clean = rawText
          .replaceAll('\r', ' ')
          .replaceAll(RegExp(r'ม\.\s*ค\.?', caseSensitive: false), 'ม.ค.')
          .replaceAll(RegExp(r'ก\.\s*พ\.?', caseSensitive: false), 'ก.พ.')
          .replaceAll(RegExp(r'มี\.\s*ค\.?', caseSensitive: false), 'มี.ค.')
          .replaceAll(RegExp(r'เม\.\s*ย\.?', caseSensitive: false), 'เม.ย.')
          .replaceAll(RegExp(r'พ\.\s*ค\.?', caseSensitive: false), 'พ.ค.')
          .replaceAll(RegExp(r'มิ\.\s*ย\.?', caseSensitive: false), 'มิ.ย.')
          .replaceAll(RegExp(r'ก\.\s*ค\.?', caseSensitive: false), 'ก.ค.')
          .replaceAll(RegExp(r'ส\.\s*ค\.?', caseSensitive: false), 'ส.ค.')
          .replaceAll(RegExp(r'ก\.\s*ย\.?', caseSensitive: false), 'ก.ย.')
          .replaceAll(RegExp(r'ต\.\s*ค\.?', caseSensitive: false), 'ต.ค.')
          .replaceAll(RegExp(r'พ\.\s*ย\.?', caseSensitive: false), 'พ.ย.')
          .replaceAll(RegExp(r'ธ\.\s*ค\.?', caseSensitive: false), 'ธ.ค.');

      final thaiMonthMap = {
        'ม.ค.': 1, 'มกราคม': 1, 'ม.ค': 1, 'มค': 1,
        'ก.พ.': 2, 'กุมภาพันธ์': 2, 'ก.พ': 2, 'กพ': 2,
        'มี.ค.': 3, 'มีนาคม': 3, 'มี.ค': 3, 'มีค': 3,
        'เม.ย.': 4, 'เมษายน': 4, 'เม.ย': 4, 'เมย': 4,
        'พ.ค.': 5, 'พฤษภาคม': 5, 'พ.ค': 5, 'พค': 5,
        'มิ.ย.': 6, 'มิถุนายน': 6, 'มิ.ย': 6, 'มิย': 6,
        'ก.ค.': 7, 'กรกฎาคม': 7, 'ก.ค': 7, 'กค': 7,
        'ส.ค.': 8, 'สิงหาคม': 8, 'ส.ค': 8, 'สค': 8,
        'ก.ย.': 9, 'กันยายน': 9, 'ก.ย': 9, 'กย': 9,
        'ต.ค.': 10, 'ตุลาคม': 10, 'ต.ค': 10, 'ตค': 10,
        'พ.ย.': 11, 'พฤศจิกายน': 11, 'พ.ย': 11, 'พย': 11,
        'ธ.ค.': 12, 'ธันวาคม': 12, 'ธ.ค': 12, 'ธค': 12,
        'jan': 1, 'january': 1,
        'feb': 2, 'february': 2,
        'mar': 3, 'march': 3,
        'apr': 4, 'april': 4,
        'may': 5,
        'jun': 6, 'june': 6,
        'jul': 7, 'july': 7,
        'aug': 8, 'august': 8,
        'sep': 9, 'september': 9,
        'oct': 10, 'october': 10,
        'nov': 11, 'november': 11,
        'dec': 12, 'december': 12,
      };

      int? detectedDay;
      int? detectedMonth;
      int? detectedYear;
      int hour = now.hour;
      int minute = now.minute;
      int second = 0;

      // 1. Extract Time e.g. 14:30:15 or 08:45 or 14.30
      final timeReg = RegExp(r'\b([0-2]?[0-9])[:.]([0-5][0-9])(?::([0-5][0-9]))?\s*(?:น\.|น|hr|hrs)?\b', caseSensitive: false);
      final timeMatch = timeReg.firstMatch(clean);
      if (timeMatch != null) {
        hour = int.tryParse(timeMatch.group(1)!) ?? hour;
        minute = int.tryParse(timeMatch.group(2)!) ?? minute;
        if (timeMatch.group(3) != null) {
          second = int.tryParse(timeMatch.group(3)!) ?? 0;
        }
      }

      // 2. Pattern 1: Thai & English named date e.g. 25 ก.พ. 2569, 25 ส.ค. 69, 25 ส.ค. พ.ศ. 2567, 25 Aug 2026
      final thaiDateReg = RegExp(
        r'([0-3]?[0-9])\s*(?:[\.\-\/]?)\s*(ม\.ค\.|ก\.พ\.|มี\.ค\.|เม\.ย\.|พ\.ค\.|มิ\.ย\.|ก\.ค\.|ส\.ค\.|ก\.ย\.|ต\.ค\.|พ\.ย\.|ธ\.ค\.|ม\.ค|ก\.พ|มี\.ค|เม\.ย|พ\.ค|มิ\.ย|ก\.ค|ส\.ค|ก\.ย|ต\.ค|พ\.ย|ธ\.ค|มค|กพ|มีค|เมย|พค|มิย|กค|สค|กย|ตค|พย|ธค|มกราคม|กุมภาพันธ์|มีนาคม|เมษายน|พฤษภาคม|มิถุนายน|กรกฎาคม|สิงหาคม|กันยายน|ตุลาคม|พฤศจิกายน|ธันวาคม|january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|jun|jul|aug|sep|oct|nov|dec)\s*(?:[\.\-\/]?)\s*(?:พ\.ศ\.|ค\.ศ\.|B\.E\.|BE)?\s*([0-9]{2,4})',
        caseSensitive: false,
      );
      final thaiMatch = thaiDateReg.firstMatch(clean);
      if (thaiMatch != null) {
        detectedDay = int.tryParse(thaiMatch.group(1)!);
        final mStr = thaiMatch.group(2)!.toLowerCase();
        detectedMonth = thaiMonthMap[mStr];
        int? yRaw = int.tryParse(thaiMatch.group(3)!);
        if (yRaw != null) {
          if (yRaw >= 2500) {
            detectedYear = yRaw - 543;
          } else if (yRaw >= 50 && yRaw <= 99) {
            detectedYear = (2500 + yRaw) - 543;
          } else if (yRaw >= 2000) {
            detectedYear = yRaw;
          } else if (yRaw >= 20 && yRaw < 50) {
            detectedYear = 2000 + yRaw;
          }
        }
      }

      // 3. Pattern 2: Numeric dd/MM/yyyy or dd-MM-yyyy or dd.MM.yyyy e.g. 25/08/2026 or 25-08-2569 or 25.08.67
      if (detectedDay == null || detectedMonth == null || detectedYear == null) {
        final numericDateReg = RegExp(r'\b([0-3]?[0-9])[\/\.-]([0-1]?[0-9])[\/\.-]([0-9]{2,4})\b');
        final numMatch = numericDateReg.firstMatch(clean);
        if (numMatch != null) {
          detectedDay = int.tryParse(numMatch.group(1)!);
          detectedMonth = int.tryParse(numMatch.group(2)!);
          int? yRaw = int.tryParse(numMatch.group(3)!);
          if (yRaw != null) {
            if (yRaw >= 2500) {
              detectedYear = yRaw - 543;
            } else if (yRaw >= 50 && yRaw <= 99) {
              detectedYear = (2500 + yRaw) - 543;
            } else if (yRaw >= 2000) {
              detectedYear = yRaw;
            } else if (yRaw >= 20 && yRaw < 50) {
              detectedYear = 2000 + yRaw;
            }
          }
        }
      }

      // 4. Pattern 3: ISO yyyy-MM-dd e.g. 2026-08-25
      if (detectedDay == null || detectedMonth == null || detectedYear == null) {
        final isoDateReg = RegExp(r'\b([0-9]{4})[\/\.-]([0-1]?[0-9])[\/\.-]([0-3]?[0-9])\b');
        final isoMatch = isoDateReg.firstMatch(clean);
        if (isoMatch != null) {
          int? yRaw = int.tryParse(isoMatch.group(1)!);
          detectedMonth = int.tryParse(isoMatch.group(2)!);
          detectedDay = int.tryParse(isoMatch.group(3)!);
          if (yRaw != null) {
            if (yRaw >= 2500) {
              detectedYear = yRaw - 543;
            } else {
              detectedYear = yRaw;
            }
          }
        }
      }

      // 5. If date successfully extracted from OCR text, return it!
      if (detectedDay != null && detectedMonth != null && detectedYear != null) {
        if (detectedMonth >= 1 && detectedMonth <= 12 && detectedDay >= 1 && detectedDay <= 31) {
          return DateTime(detectedYear, detectedMonth, detectedDay, hour, minute, second);
        }
      }

      // 6. Fallback to Filename timestamp (e.g. Screenshot_20260825_143000.jpg, 2026-08-25, or epoch millis)
      if (fileName != null && fileName.isNotEmpty) {
        // Form: YYYYMMDD e.g. 20240825 or 20260825
        final fnDateReg = RegExp(r'(20[2-3][0-9])([0-1][0-9])([0-3][0-9])');
        final fnMatch = fnDateReg.firstMatch(fileName);
        if (fnMatch != null) {
          final fnY = int.tryParse(fnMatch.group(1)!);
          final fnM = int.tryParse(fnMatch.group(2)!);
          final fnD = int.tryParse(fnMatch.group(3)!);
          if (fnY != null && fnM != null && fnD != null && fnM >= 1 && fnM <= 12 && fnD >= 1 && fnD <= 31) {
            return DateTime(fnY, fnM, fnD, hour, minute, second);
          }
        }

        // Form: Epoch timestamp in milliseconds (13 digits e.g. 1724567890123)
        final epochReg = RegExp(r'\b(1[6-9][0-9]{11})\b');
        final epochMatch = epochReg.firstMatch(fileName);
        if (epochMatch != null) {
          final epochVal = int.tryParse(epochMatch.group(1)!);
          if (epochVal != null) {
            final dt = DateTime.fromMillisecondsSinceEpoch(epochVal);
            if (dt.year >= 2020 && dt.year <= now.year + 1) {
              return dt;
            }
          }
        }
      }

      // 7. Fallback to File Last Modified Timestamp on device
      if (filePath != null && filePath.isNotEmpty) {
        final f = File(filePath);
        if (f.existsSync()) {
          final modDate = f.lastModifiedSync();
          if (modDate.year >= 2020 && modDate.year <= now.year + 1) {
            return modDate;
          }
        }
      }

      return now;
    } catch (_) {
      return now;
    }
  }

  SlipExtractResult parseSlipText(String rawText, List<CategoryItem> categories, {String? defaultBankCode, String? fileName, String? filePath}) {
    final normalizedText = EasyOcrTesseractFusionService.normalizeOcrText(rawText.replaceAll('\r', ''));
    final cleanText = normalizedText;
    final lines = cleanText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    final cleanCombined = '$cleanText $fileName $filePath'.toLowerCase();
    final bool isIBank = cleanCombined.contains('ibank') || cleanCombined.contains('อิสลาม');
    final bool isPaotangGov = (cleanCombined.contains('เป๋าตัง') ||
            cleanCombined.contains('paotang') ||
            cleanCombined.contains('g-wallet') ||
            cleanCombined.contains('gwallet') ||
            cleanCombined.contains('ไทยช่วยไทย') ||
            cleanCombined.contains('คนละครึ่ง') ||
            cleanCombined.contains('เราชนะ') ||
            cleanCombined.contains('สวัสดิการ') ||
            (filePath != null && (filePath.toLowerCase().contains('paotang') || filePath.contains('เป๋าตัง')))) &&
        !isIBank;

    // 1. Amount Extraction
    double amount = 0.0;
    if (isPaotangGov) {
      // User rule: For PaoTang slips without QR Code, set amount to 0.0 always so user can fill manually
      amount = 0.0;
    } else {
      // Normal flow for all other banks and iBank
      amount = EasyOcrTesseractFusionService.extractAmount(cleanText);
      if (amount <= 0) {
        amount = extractAmountFromText(cleanText);
      }
    }

    // 2. Exact Date & Time Extraction from slip text / metadata
    final DateTime dateTime = extractDateTimeFromText(cleanText, fileName: fileName, filePath: filePath);

    String senderName = 'ไม่ระบุผู้โอน';
    String senderBank = defaultBankCode ?? EasyOcrTesseractFusionService.detectBankName(cleanText);
    String senderAccount = '-';
    String receiverName = 'ไม่ระบุผู้รับ';
    String receiverBank = 'พร้อมเพย์/ธนาคาร';
    String receiverAccount = '-';
    String refId = 'REF-${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}';
    String? memo;

    // 3. Ref ID Extraction
    final fusedRef = EasyOcrTesseractFusionService.extractRefId(cleanText);
    if (fusedRef.isNotEmpty) {
      refId = fusedRef;
    } else {
      final refRegexes = [
        RegExp(r'(?:รหัสอ้างอิง|เลขอ้างอิง|หมายเลขอ้างอิง|เลขที่รายการ|Ref|Ref No|Ref\.|เลขที่เอกสาร|TxID)[:\s]*([A-Za-z0-9-]+)', caseSensitive: false),
        RegExp(r'\b([0-9]{14,24}[A-Za-z0-9]*)\b'),
      ];

      for (final reg in refRegexes) {
        final match = reg.firstMatch(cleanText);
        if (match != null && match.group(1) != null) {
          refId = match.group(1)!.trim();
          break;
        }
      }
    }

    // 4. Memo / Note Extraction
    final fusedMemo = EasyOcrTesseractFusionService.extractMemo(cleanText);
    if (fusedMemo.isNotEmpty) {
      memo = fusedMemo;
    } else {
      final memoRegexes = [
        RegExp(r'(?:บันทึกช่วยจำ|บันทึก|หมายเหตุ|Memo|Note|ข้อความ|เพื่อ|รายละเอียด)[:\s]*([^\n\r]+)', caseSensitive: false),
      ];
      for (final reg in memoRegexes) {
        final memoMatch = reg.firstMatch(cleanText);
        if (memoMatch != null && memoMatch.group(1) != null) {
          final extractedMemo = memoMatch.group(1)!.trim();
          if (extractedMemo.isNotEmpty) {
            memo = extractedMemo;
            break;
          }
        }
      }
    }

    if (isPaotangGov && amount <= 0) {
      if (memo == null || memo.isEmpty) {
        memo = 'สลิปไม่มี QR Code (แตะเพื่อระบุยอดเงิน)';
      }
    }

    // 5. Sender & Receiver Extraction
    final parties = extractSenderAndReceiver(cleanText, lines);
    senderName = parties['sender']!;
    receiverName = parties['receiver']!;

    final bool isSelf = isSelfTransfer(senderName, receiverName, rawText: cleanText);

    // 6. Detect Bank Name with Multi-Layer Directional & Album Fuzzy Matching
    senderBank = defaultBankCode ??
        EasyOcrTesseractFusionService.detectBankName(cleanText, filePath: filePath ?? fileName);

    // 7. Transaction Type & Category Classification (Auto-detect Income vs Expense)
    final lower = cleanText.toLowerCase();
    TransactionType suggestedType = TransactionType.expense;
    final incomeKeywords = [
      'เงินเข้า', 'เงินโอนเข้า', 'โอนเงินเข้า', 'เงินเข้าบัญชี', 'ได้รับเงิน', 'รับเงิน',
      'รับโอน', 'โอนเข้า', 'ยอดเงินเข้า', 'เงินฝาก', 'ฝากเงิน', 'รับชำระ', 'รับเงินเดือน',
      'เงินเดือน', 'salary', 'deposit', 'incoming', 'transfer in', 'receive transfer',
      'cr', 'credit', 'โอนให้คุณ', 'ได้รับยอดเงิน', 'เงินเข้าสำเร็จ', 'พร้อมเพย์เงินเข้า',
      'รับโอนเงินสำเร็จ', 'เงินปันผล', 'รายรับ'
    ];

    if (incomeKeywords.any((kw) => lower.contains(kw))) {
      suggestedType = TransactionType.income;
    }

    final fallbackIncome = categories.firstWhere(
      (c) => c.type == CategoryType.income && (c.name.contains('รายได้') || c.name.contains('โอน') || c.name.contains('ริซกี') || c.name.contains('เงินเดือน')),
      orElse: () => CategoryItem(
        id: 'cat_income_default',
        name: 'รับเงินโอน / รายได้',
        iconKey: 'payments',
        colorValue: 0xFF10B981,
        type: CategoryType.income,
      ),
    );

    final fallbackExpense = categories.firstWhere(
      (c) => c.type == CategoryType.expense,
      orElse: () => CategoryItem(
        id: 'cat_expense',
        name: 'รายจ่าย',
        iconKey: 'category',
        colorValue: 0xFFF59E0B,
        type: CategoryType.expense,
      ),
    );

    final textForMatching = [memo ?? '', receiverName, senderName, cleanText].join(' ');
    final matchedCat = CategoryMatcherService.matchCategory(
      text: textForMatching,
      availableCategories: categories.where((c) => c.type == (suggestedType == TransactionType.income ? CategoryType.income : CategoryType.expense)).toList(),
      fallbackCategory: suggestedType == TransactionType.income ? fallbackIncome : fallbackExpense,
    );

    // If generic fallback but memo has a specific topic, use memo as suggested category name
    String suggestedCategory = matchedCat.name;
    if (matchedCat == fallbackExpense || matchedCat == fallbackIncome) {
      if (memo != null && memo.trim().length >= 2 && memo.trim().length <= 25) {
        suggestedCategory = memo.trim().replaceAll(RegExp(r'^(?:บันทึกช่วยจำ|บันทึก|หมายเหตุ|Memo|Note)[:\s]*', caseSensitive: false), '');
      }
    }

    return SlipExtractResult(
      senderName: senderName,
      senderBank: senderBank,
      senderAccount: senderAccount,
      receiverName: receiverName,
      receiverBank: receiverBank,
      receiverAccount: receiverAccount,
      amount: amount,
      dateTime: dateTime,
      refId: refId,
      memo: memo,
      rawOcrText: cleanText,
      confidenceScore: amount > 0 ? 0.98 : 0.50,
      suggestedType: suggestedType,
      suggestedCategoryName: suggestedCategory,
      isSelfTransfer: isSelf,
    );
  }

  /// Robust helper to check if a slip is a self-transfer (คนโอนกับคนรับเป็นคนเดียวกัน)
  static bool isSelfTransfer(String sender, String receiver, {String? rawText}) {
    if (rawText != null) {
      final lowerRaw = rawText.toLowerCase();
      if (lowerRaw.contains('โอนระหว่างบัญชีตนเอง') ||
          lowerRaw.contains('โอนเข้าบัญชีตนเอง') ||
          lowerRaw.contains('โอนเงินให้ตัวเอง') ||
          lowerRaw.contains('โอนให้ตัวเอง') ||
          lowerRaw.contains('บัญชีของฉัน') ||
          lowerRaw.contains('โอนเงินระหว่างบัญชีตนเอง') ||
          lowerRaw.contains('transfer to own account') ||
          lowerRaw.contains('own account transfer') ||
          lowerRaw.contains('between own accounts')) {
        return true;
      }
    }

    final sClean = _normalizePersonName(sender);
    final rClean = _normalizePersonName(receiver);

    if (sClean.isEmpty || rClean.isEmpty || sClean == 'ไม่ระบุผู้โอน' || rClean == 'ไม่ระบุผู้รับ') {
      return false;
    }

    // Exact match after cleaning titles & spaces
    if (sClean == rClean) return true;

    // Substring or prefix match (e.g. "สมชาย ใจดี" vs "สมชาย" or "นาย สมชาย" vs "สมชาย")
    if (sClean.length >= 4 && rClean.length >= 4) {
      if (sClean.contains(rClean) || rClean.contains(sClean)) {
        return true;
      }
    }

    // Check matching first name and last name initial e.g. "สมชาย ใ." vs "สมชาย ใจดี" or "somchai j" vs "somchai jaidee"
    final sParts = sClean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final rParts = rClean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();

    if (sParts.isNotEmpty && rParts.isNotEmpty) {
      if (sParts.first == rParts.first && sParts.first.length >= 3) {
        if (sParts.length > 1 && rParts.length > 1) {
          final sInitial = sParts[1].substring(0, 1);
          final rInitial = rParts[1].substring(0, 1);
          if (sParts[1].startsWith(rInitial) || rParts[1].startsWith(sInitial)) {
            return true;
          }
        } else {
          return true;
        }
      }
    }

    return false;
  }

  static String _normalizePersonName(String name) {
    var clean = fixThaiOcrGlitches(name).trim().toLowerCase();
    // Remove titles
    clean = clean.replaceAll(RegExp(r'^(นาย|นาง|นางสาว|น\.ส\.|ด\.ช\.|ด\.ญ\.|คุณ|บจก\.|หจก\.|บริษัท|ร้าน|mr\.|mrs\.|ms\.|miss|dr\.)\s*'), '');
    clean = clean.replaceAll(RegExp(r'[0-9\-_*#().\/,:]'), '');
    clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();
    return clean;
  }

  /// Fixes common Thai OCR misrecognitions and character distortions
  static String fixThaiOcrGlitches(String text) {
    var s = text;

    // 1. Fix common Thai OCR character misrecognitions without ASCII word boundary limitations
    s = s.replaceAll(RegExp(r'(?:^|[\s])uาย(?:[\s]|$)', caseSensitive: false), ' นาย ');
    s = s.replaceAll(RegExp(r'(?:^|[\s])uางสาว(?:[\s]|$)', caseSensitive: false), ' นางสาว ');
    s = s.replaceAll(RegExp(r'(?:^|[\s])uาง(?:[\s]|$)', caseSensitive: false), ' นาง ');
    s = s.replaceAll(RegExp(r'(?:^|[\s])(?:u\.a\.|u\.ส\.|น\.a\.|น\.a|u\.a)(?:[\s]|$)', caseSensitive: false), ' น.ส. ');
    s = s.replaceAll(RegExp(r'(?:^|[\s])(?:lปยัง|ไปย้ง|ไปยง)(?:[\s]|$)', caseSensitive: false), ' ไปยัง ');
    s = s.replaceAll(RegExp(r'(?:^|[\s])(?:จๅก|lอนจาก)(?:[\s]|$)', caseSensitive: false), ' จาก ');
    s = s.replaceAll(RegExp(r'(?:^|[\s])(?:โอนไห้|lอนให้)(?:[\s]|$)', caseSensitive: false), ' โอนให้ ');
    s = s.replaceAll(RegExp(r'(?:^|[\s])(?:ร้ๅน|ร่าน)(?:[\s]|$)', caseSensitive: false), ' ร้าน ');
    s = s.replaceAll(RegExp(r'(?:^|[\s])uจก\.(?:[\s]|$)', caseSensitive: false), ' บจก. ');
    s = s.replaceAll(RegExp(r'(?:^|[\s])หuก\.(?:[\s]|$)', caseSensitive: false), ' หจก. ');

    // 2. Remove noise symbols while preserving Thai, English letters, dots in titles and spaces
    s = s.replaceAll(RegExp(r'[•|~_<>*^\\/#@]+'), ' ');

    // 3. Normalize duplicate consecutive Thai tone marks / vowels (OCR glitch)
    s = s.replaceAll(RegExp(r'ิ{2,}'), 'ิ');
    s = s.replaceAll(RegExp(r'่{2,}'), '่');
    s = s.replaceAll(RegExp(r'้{2,}'), '้');
    s = s.replaceAll(RegExp(r'๊{2,}'), '๊');
    s = s.replaceAll(RegExp(r'๋{2,}'), '๋');
    s = s.replaceAll(RegExp(r'์{2,}'), '์');

    // 4. Normalize multiple spaces
    s = s.replaceAll(RegExp(r'[ \t]+'), ' ').trim();

    return s;
  }

  /// Clean person or business name extracted from slip without distorting Thai characters
  static String cleanPersonOrShopName(String raw) {
    var name = fixThaiOcrGlitches(raw);

    // Strip bank names & promptpay tags
    name = name.replaceAll(
      RegExp(
        r'(?:ธนาคาร|ธ\.)?\s*(?:กสิกรไทย|ไทยพาณิชย์|กรุงไทย|กรุงเทพ|กรุงศรี|ทหารไทยธนชาต|ออมสิน|อิสลาม|เคจีไอ|เกียรตินาคิน|ttb|kbank|scb|ktb|bbl|gsb|ibank|promptpay|พร้อมเพย์|k plus|scb easy|krungthai next|true money|truemoney|เป๋าตัง|g-wallet)',
        caseSensitive: false,
      ),
      '',
    );

    // Strip account masks (e.g. xxx-x-x6249-x, 081-xxx-8270, x-1234, 123-4-56789-0)
    name = name.replaceAll(RegExp(r'[0-9xX*#\-]{4,}'), '');

    // Strip generic slip keywords
    name = name.replaceAll(
      RegExp(
        r'(?:รายการสำเร็จ|โอนสำเร็จ|โอนเงินสำเร็จ|จำนวนเงิน|ยอดเงิน|บาท|THB|รหัสอ้างอิง|สแกน|QR Code|วันที่|เวลา|บันทึกช่วยจำ|หมายเหตุ|Ref\s*No|รหัสพร้อมเพย์)[:\s]*.*',
        caseSensitive: false,
      ),
      '',
    );

    // Strip prefix markers like "จาก", "ผู้โอน", "ไปยัง", "ผู้รับ" if left at start
    name = name.replaceAll(
      RegExp(
        r'^(?:จาก|ผู้โอน|โอนจาก|ไปยัง|ผู้รับ|ผู้รับเงิน|ผู้รับโอน|โอนไปยัง|โอนให้|เข้าบัญชี|ถึง|From|To|Sender|Receiver)[:\s]*',
        caseSensitive: false,
      ),
      '',
    );

    // Clean remaining punctuation and extra spaces
    name = name.replaceAll(RegExp(r'^[\s\-_•|>.,]+|[\s\-_•|<.,]+$'), '');
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Standardize Title formatting
    if (name.startsWith('น.ส.') && !name.startsWith('น.ส. ')) {
      name = name.replaceFirst('น.ส.', 'น.ส. ');
    } else if (name.startsWith('นาย') && !name.startsWith('นาย ')) {
      name = name.replaceFirst('นาย', 'นาย ');
    } else if (name.startsWith('นางสาว') && !name.startsWith('นางสาว ')) {
      name = name.replaceFirst('นางสาว', 'นางสาว ');
    } else if (name.startsWith('นาง') && !name.startsWith('นาง ')) {
      name = name.replaceFirst('นาง', 'นาง ');
    } else if (name.startsWith('คุณ') && !name.startsWith('คุณ ')) {
      name = name.replaceFirst('คุณ', 'คุณ ');
    } else if (name.startsWith('ร้าน') && !name.startsWith('ร้าน ')) {
      name = name.replaceFirst('ร้าน', 'ร้าน ');
    } else if (name.startsWith('บจก.') && !name.startsWith('บจก. ')) {
      name = name.replaceFirst('บจก.', 'บจก. ');
    } else if (name.startsWith('หจก.') && !name.startsWith('หจก. ')) {
      name = name.replaceFirst('หจก.', 'หจก. ');
    }

    return name.trim();
  }

  /// Robust helper to extract Sender and Receiver from slip lines (Supporting all Thai Banks including K PLUS, SCB, KTB, BBL, TTB, Paotang)
  static Map<String, String> extractSenderAndReceiver(String rawText, List<String> lines) {
    final fixedText = fixThaiOcrGlitches(rawText);
    final cleanLines = fixedText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String? senderName;
    String? receiverName;

    // Strategy 1: Explicit keyword matching (จาก / ไปยัง / ผู้โอน / ผู้รับ)
    for (int i = 0; i < cleanLines.length; i++) {
      final line = cleanLines[i];
      final lower = line.toLowerCase();

      // Check Sender Keywords
      if (lower.startsWith('จาก:') || lower.startsWith('ผู้โอน:') || lower.startsWith('โอนจาก:') || lower.startsWith('from:')) {
        final ext = cleanPersonOrShopName(line.substring(line.indexOf(':') + 1));
        if (ext.isNotEmpty && ext.length >= 2) senderName = ext;
      } else if (lower.startsWith('จาก ') || lower.startsWith('ผู้โอน ') || lower.startsWith('โอนจาก ') || lower.startsWith('from ')) {
        final ext = cleanPersonOrShopName(line);
        if (ext.isNotEmpty && ext.length >= 2) senderName = ext;
      } else if (lower == 'จาก' || lower == 'ผู้โอน' || lower == 'โอนจาก' || lower == 'from') {
        if (i + 1 < cleanLines.length) {
          final ext = cleanPersonOrShopName(cleanLines[i + 1]);
          if (ext.isNotEmpty && ext.length >= 2) senderName = ext;
        }
      }

      // Check Receiver Keywords
      if (lower.startsWith('ไปยัง:') || lower.startsWith('ผู้รับ:') || lower.startsWith('ผู้รับเงิน:') || lower.startsWith('โอนไปยัง:') || lower.startsWith('โอนให้:') || lower.startsWith('to:')) {
        final ext = cleanPersonOrShopName(line.substring(line.indexOf(':') + 1));
        if (ext.isNotEmpty && ext.length >= 2) receiverName = ext;
      } else if (lower.startsWith('ไปยัง ') || lower.startsWith('ผู้รับ ') || lower.startsWith('ผู้รับเงิน ') || lower.startsWith('โอนไปยัง ') || lower.startsWith('โอนให้ ') || lower.startsWith('เข้าบัญชี ') || lower.startsWith('to ') || lower.startsWith('ถึง ')) {
        final ext = cleanPersonOrShopName(line);
        if (ext.isNotEmpty && ext.length >= 2) receiverName = ext;
      } else if (lower == 'ไปยัง' || lower == 'ผู้รับ' || lower == 'ผู้รับเงิน' || lower == 'โอนไปยัง' || lower == 'โอนให้' || lower == 'เข้าบัญชี' || lower == 'to' || lower == 'ถึง') {
        if (i + 1 < cleanLines.length) {
          final ext = cleanPersonOrShopName(cleanLines[i + 1]);
          if (ext.isNotEmpty && ext.length >= 2) receiverName = ext;
        }
      }
    }

    // Strategy 2: Visual bank block extraction (Names with Titles or before account masks)
    final candidateNames = <String>[];
    final titleRegex = RegExp(
      r'^(?:นาย|นาง|นางสาว|น\.ส\.|ด\.ช\.|ด\.ญ\.|คุณ|บจก\.|หจก\.|บริษัท|ร้าน|บมจ\.|MR\.|MRS\.|MS\.|MISS)\s+',
      caseSensitive: false,
    );

    for (int i = 0; i < cleanLines.length; i++) {
      final line = cleanLines[i];
      final cleaned = cleanPersonOrShopName(line);

      if (cleaned.isEmpty || cleaned.length < 2) continue;

      final hasTitle = titleRegex.hasMatch(line) || titleRegex.hasMatch(cleaned);
      final isBeforeBankOrAccount = (i + 1 < cleanLines.length) &&
          (cleanLines[i + 1].contains('กสิกร') ||
              cleanLines[i + 1].contains('ไทยพาณิชย์') ||
              cleanLines[i + 1].contains('กรุงไทย') ||
              cleanLines[i + 1].contains('กรุงเทพ') ||
              cleanLines[i + 1].contains('พร้อมเพย์') ||
              cleanLines[i + 1].contains('xxx') ||
              cleanLines[i + 1].contains('***') ||
              cleanLines[i + 1].contains('PromptPay'));

      if (hasTitle || isBeforeBankOrAccount) {
        if (!candidateNames.contains(cleaned)) {
          candidateNames.add(cleaned);
        }
      }
    }

    senderName ??= candidateNames.isNotEmpty ? candidateNames[0] : null;
    if (receiverName == null) {
      if (candidateNames.length > 1 && candidateNames[1] != senderName) {
        receiverName = candidateNames[1];
      } else if (candidateNames.isNotEmpty && candidateNames[0] != senderName) {
        receiverName = candidateNames[0];
      }
    }

    return {
      'sender': senderName ?? 'ไม่ระบุผู้โอน',
      'receiver': receiverName ?? 'ไม่ระบุผู้รับ',
    };
  }
}
