/// EasyOCR & Tesseract OCR Hybrid Fusion Service for Thai Bank Slips
/// Combines EasyOCR CRAFT text region reconstruction + Tesseract LSTM tokenization & Thai bank dictionary
class EasyOcrTesseractFusionService {
  /// Thai digit to Arabic digit lookup
  static const Map<String, String> _thaiToArabicDigits = {
    '๐': '0',
    '๑': '1',
    '๒': '2',
    '๓': '3',
    '๔': '4',
    '๕': '5',
    '๖': '6',
    '๗': '7',
    '๘': '8',
    '๙': '9',
  };

  /// Common OCR dictionary misread corrections for Thai Banking Slips
  static const Map<String, String> _ocrCorrections = {
    'จํานวนเงิน': 'จำนวนเงิน',
    'จําน วนเงิน': 'จำนวนเงิน',
    'จํานวน': 'จำนวน',
    'จําน าน': 'จำนวน',
    'โอนสําเร็จ': 'โอนสำเร็จ',
    'โอน สําเร็จ': 'โอนสำเร็จ',
    'รายการสําเร็จ': 'รายการสำเร็จ',
    'สําเร็จ': 'สำเร็จ',
    'บำท': 'บาท',
    'บ่ท': 'บาท',
    'บ าท': 'บาท',
    'บ า ท': 'บาท',
    'เงน': 'เงิน',
    'เงีน': 'เงิน',
    'เง น': 'เงิน',
    'โอนเงน': 'โอนเงิน',
    'โอนเงีน': 'โอนเงิน',
    'โอนเงิน': 'โอนเงิน',
    'พรอมเพย': 'พร้อมเพย์',
    'พร้อมเพย': 'พร้อมเพย์',
    'พร็อมเพย์': 'พร้อมเพย์',
    'พร้อม เพย์': 'พร้อมเพย์',
    'กสิกร ไทย': 'กสิกรไทย',
    'ไทย พาณิชย์': 'ไทยพาณิชย์',
    'กรุง ไทย': 'กรุงไทย',
    'กรุง เทพ': 'กรุงเทพ',
    'ออม สิน': 'ออมสิน',
    'ทหารไทย ธนชาต': 'ทหารไทยธนชาต',
    'ทีทีบี': 'ttb',
    'ทรู มันนี่': 'ทรูมันนี่',
    'ทรูมันนี': 'ทรูมันนี่',
    'รหัส อ้างอิง': 'รหัสอ้างอิง',
    'หมายเลข อ้างอิง': 'หมายเลขอ้างอิง',
    'เลขที่ อ้างอิง': 'เลขที่อ้างอิง',
    'บันทึก ช่วยจำ': 'บันทึกช่วยจำ',
    'บันทึก ช่วยจํา': 'บันทึกช่วยจำ',
    'ชำระ เงิน': 'ชำระเงิน',
    'ชําระเงิน': 'ชำระเงิน',
    'ค่ำบริกำร': 'ค่าบริการ',
    'บ่ญชี': 'บัญชี',
    'บญชี': 'บัญชี',
    'เลขบญชี': 'เลขบัญชี',
    'เลขบัญช': 'เลขบัญชี',
  };

  /// 1. EasyOCR-style Character & Ligature Normalization
  /// Fixes unicode normalization, merges spaced letters, and converts Thai digits
  static String normalizeOcrText(String rawText) {
    if (rawText.isEmpty) return '';

    String text = rawText;

    // A. Normalize Thai digits to Arabic digits (e.g. ๓๕,๐๐๐.๐๐ -> 35,000.00)
    _thaiToArabicDigits.forEach((thai, arabic) {
      text = text.replaceAll(thai, arabic);
    });

    // B. Fix broken Thai vowel & tone marks (Sara Am, Mai Ek, Mai Tho unicode normalization)
    text = text.replaceAll('\u0E4D\u0E32', '\u0E33'); // Nikhahit + Sara Aa -> Sara Am (ำ)
    text = text.replaceAll('ํา', 'ำ');

    // C. Fix broken spacing between single Thai letters (e.g. "โ อ น เ งิ น" -> "โอนเงิน", "บ า ท" -> "บาท")
    text = text.replaceAll(RegExp(r'(?<=[\u0E01-\u0E4E])\s+(?=[\u0E30-\u0E39\u0E47-\u0E4E])'), '');
    text = text.replaceAll(RegExp(r'(?<=\b[โเแไใ])\s+(?=[\u0E01-\u0E2E])'), '');
    text = text.replaceAll(RegExp(r'(?<=[\u0E01-\u0E2E])\s+(?=[\u0E01-\u0E2E]\b)'), '');

    // D. Apply Thai Banking Slip OCR Dictionary Corrections
    _ocrCorrections.forEach((misread, correct) {
      text = text.replaceAll(misread, correct);
    });

    return text;
  }

  /// 2. Tesseract LSTM-style High Precision Monetary Amount Extraction
  /// Finds numbers formatted like 1,234.56 or 1234.56 with keyword proximity weighting and strict fee exclusion
  static double extractAmount(String text) {
    final clean = normalizeOcrText(text);
    final lines = clean.split('\n');

    // 1. High Priority: Look for amount keywords on individual lines with exclusions
    for (final line in lines) {
      final l = line.trim();
      if (l.isEmpty) continue;
      final lower = l.toLowerCase();

      // Skip lines that contain fee, reference numbers, merchant/biller IDs, or account numbers
      if (lower.contains('ค่าธรรมเนียม') ||
          lower.contains('fee') ||
          lower.contains('รหัสอ้างอิง') ||
          lower.contains('เลขที่อ้างอิง') ||
          lower.contains('เลขอ้างอิง') ||
          lower.contains('ref no') ||
          lower.contains('ref id') ||
          lower.contains('หมายเลขร้านค้า') ||
          lower.contains('รหัสผู้รับเงิน') ||
          lower.contains('รหัสร้านค้า') ||
          lower.contains('เลขที่บัญชี') ||
          lower.contains('หมายเลขบัญชี')) {
        continue;
      }

      // Check for K PLUS "จำนวน:" or standard "จำนวนเงิน"
      if (lower.contains('จำนวนเงินที่ชำระ') ||
          lower.contains('ยอดเงินที่ชำระ') ||
          lower.contains('ยอดชำระ') ||
          lower.contains('จำนวนเงิน') ||
          lower.contains('จํานวนเงิน') ||
          lower.contains('จำนวน:') ||
          lower.contains('จํานวน:') ||
          lower.contains('จำนวน ') ||
          lower.contains('จํานวน ') ||
          lower.contains('ยอดเงิน') ||
          lower.contains('ยอดเงินโอน') ||
          lower.contains('ยอดโอน') ||
          lower.contains('เงินที่จ่าย') ||
          lower.contains('amount') ||
          lower.contains('total')) {
        final m = RegExp(r'([0-9]{1,3}(?:,[0-9]{3})*\.[0-9]{2}|[0-9]+\.[0-9]{2})').firstMatch(l);
        if (m != null) {
          final rawNum = m.group(1)?.replaceAll(',', '').trim();
          final val = double.tryParse(rawNum ?? '');
          if (val != null && val > 0 && val < 50000000) {
            return val;
          }
        }
      }
    }

    // 2. High priority: Context Regex matching keyword followed by 2-decimal number
    final contextRegexes = [
      RegExp(
        r'(?:จำนวนเงินที่ชำระ|ยอดเงินที่ชำระ|ยอดชำระ|จำนวนเงิน|จํานวนเงิน|จำนวน:|จํานวน:|จำนวน|จํานวน|ยอดเงิน|ยอดเงินโอน|ยอดโอน|โอนเงิน|สิทธิ์ที่ใช้|สิทธิที่ใช้|สิทธิ์คงเหลือ|สิทธิคนละครึ่ง|เงินที่จ่ายจริง|จำนวนเงินที่ได้รับ|เงินช่วยเหลือ|Total|Amount)[:\s\n]*([0-9]{1,3}(?:,[0-9]{3})*\.[0-9]{2}|[0-9]+\.[0-9]{2})',
        caseSensitive: false,
      ),
      RegExp(r'(?:฿|B)\s*([0-9]{1,3}(?:,[0-9]{3})*\.[0-9]{2}|[0-9]+\.[0-9]{2})'),
    ];

    for (final reg in contextRegexes) {
      final matches = reg.allMatches(clean);
      for (final match in matches) {
        final rawNum = match.group(1)?.replaceAll(',', '').trim();
        if (rawNum != null) {
          final val = double.tryParse(rawNum);
          if (val != null && val > 0 && val < 50000000) {
            return val;
          }
        }
      }
    }

    // 3. Match numbers followed by บาท / THB / Baht / บ. (excluding 0.00 fee)
    final bahtMatches = RegExp(r'([0-9]{1,3}(?:,[0-9]{3})*\.[0-9]{2}|[0-9]+\.[0-9]{2})\s*(?:บาท|THB|Baht|บ\.)', caseSensitive: false).allMatches(clean);
    for (final match in bahtMatches) {
      final startIdx = match.start > 25 ? match.start - 25 : 0;
      final prefix = clean.substring(startIdx, match.start).toLowerCase();
      if (prefix.contains('ค่าธรรมเนียม') || prefix.contains('fee')) {
        continue;
      }
      final rawNum = match.group(1)?.replaceAll(',', '').trim();
      if (rawNum != null) {
        final val = double.tryParse(rawNum);
        if (val != null && val > 0 && val < 50000000) {
          return val;
        }
      }
    }

    // 4. Any 2-decimal numbers on the slip (excluding dates/years e.g. 68, 69, 70, times e.g. 08.49)
    final generalRegex = RegExp(r'\b([0-9]{1,3}(?:,[0-9]{3})*\.[0-9]{2}|[0-9]+\.[0-9]{2})\b');
    final matches = generalRegex.allMatches(clean);
    for (final match in matches) {
      final startIdx = match.start > 20 ? match.start - 20 : 0;
      final prefix = clean.substring(startIdx, match.start).toLowerCase();
      // Exclude if prefix is date/month/time
      if (prefix.contains('ม.ค') || prefix.contains('ก.พ') || prefix.contains('มี.ค') ||
          prefix.contains('เม.ย') || prefix.contains('พ.ค') || prefix.contains('มิ.ย') ||
          prefix.contains('ก.ค') || prefix.contains('ส.ค') || prefix.contains('ก.ย') ||
          prefix.contains('ต.ค') || prefix.contains('พ.ย') || prefix.contains('ธ.ค') ||
          prefix.contains('เวลา') || prefix.contains('time') || prefix.contains('date')) {
        continue;
      }

      final rawNum = match.group(1)?.replaceAll(',', '').trim();
      if (rawNum != null) {
        // Exclude year fractions like 8.69, 9.69, 3.69
        if (rawNum.endsWith('.69') || rawNum.endsWith('.68') || rawNum.endsWith('.70')) {
          continue;
        }
        final val = double.tryParse(rawNum);
        if (val != null && val > 0 && val < 50000000) {
          return val;
        }
      }
    }

    return 0.0;
  }

  static String extractRefId(String text) {
    final clean = normalizeOcrText(text);

    final refRegexes = [
      RegExp(r'(?:รหัสอ้างอิง|เลขที่อ้างอิง|หมายเลขอ้างอิง|เลขที่รายการ|Ref(?:\.|\s*No|\s*ID)?|Transaction\s*ID)[:\s]*([A-Za-z0-9\-_]{8,35})', caseSensitive: false),
      RegExp(r'\b(202[4-9][0-9]{10,24})\b'), // Standard Thai Bank Ref timestamp format e.g. 20260225...
      RegExp(r'\b([0-9]{4}[A-Z0-9]{10,20})\b'),
    ];

    for (final reg in refRegexes) {
      final match = reg.firstMatch(clean);
      if (match != null && match.group(1) != null) {
        final ref = match.group(1)!.trim();
        if (ref.length >= 8) {
          return ref;
        }
      }
    }

    return '';
  }

  /// 4. Memo / Note Extractor (Extracts บันทึกช่วยจำ / ข้อความช่วยจำ / Memo / Note)
  static String extractMemo(String text) {
    final clean = normalizeOcrText(text);

    // 1. Check direct inline pattern
    final memoRegex = RegExp(
      r'(?:บันทึกช่วยจำ|ข้อความช่วยจำ|ช่วยจำ|บันทึก|หมายเหตุ|Memo|Note|ข้อความ)[:\s]*([^\n\r]+)',
      caseSensitive: false,
    );
    final match = memoRegex.firstMatch(clean);
    if (match != null && match.group(1) != null) {
      final memo = match.group(1)!.trim();
      if (memo.isNotEmpty &&
          !memo.toLowerCase().contains('รหัสอ้างอิง') &&
          !memo.toLowerCase().contains('ref no') &&
          !memo.toLowerCase().contains('ref:') &&
          !memo.toLowerCase().contains('บาท')) {
        return memo;
      }
    }

    // 2. Check multi-line pattern (where "บันทึกช่วยจำ" is on its own line and the memo is on the next line)
    final lines = clean.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final memoKeyRegex = RegExp(
        r'^(?:บันทึกช่วยจำ|ข้อความช่วยจำ|ช่วยจำ|บันทึก|หมายเหตุ|Memo|Note|ข้อความ)[:\s]*(.*)$',
        caseSensitive: false,
      );
      final m = memoKeyRegex.firstMatch(line);
      if (m != null) {
        final sameLine = m.group(1)?.trim() ?? '';
        if (sameLine.isNotEmpty &&
            !sameLine.contains('รหัสอ้างอิง') &&
            !sameLine.contains('ref') &&
            !sameLine.contains('บาท')) {
          return sameLine;
        }
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          if (nextLine.isNotEmpty &&
              !nextLine.contains('รหัสอ้างอิง') &&
              !nextLine.contains('ref') &&
              !nextLine.contains('ค่าธรรมเนียม') &&
              !nextLine.contains('บาท') &&
              !nextLine.contains('สแกน') &&
              !nextLine.contains('QR') &&
              nextLine.length <= 100) {
            return nextLine;
          }
        }
      }
    }

    return '';
  }

  /// 5. Thai Bank Name Recognizer with Multi-Layer Directional & Album Fuzzy Matching
  static String detectBankName(String text, {String? filePath}) {
    // 1. Album / File Path check (Highest priority)
    if (filePath != null && filePath.isNotEmpty) {
      final fileLower = filePath.toLowerCase();
      if (fileLower.contains('k plus') || fileLower.contains('kplus') || fileLower.contains('kbank') || fileLower.contains('kasikorn')) {
        return 'กสิกรไทย (K PLUS)';
      }
      if (fileLower.contains('scb easy') || fileLower.contains('scb') || fileLower.contains('ไทยพาณิชย์')) {
        return 'ไทยพาณิชย์ (SCB EASY)';
      }
      if (fileLower.contains('ibank') || fileLower.contains('อิสลาม') || fileLower.contains('islamic')) {
        return 'iBank (อิสลามแห่งประเทศไทย)';
      }
      if (fileLower.contains('paotang') || fileLower.contains('เป๋าตัง') || fileLower.contains('gwallet') || fileLower.contains('g-wallet') || fileLower.contains('ไทยช่วยไทย')) {
        if (fileLower.contains('ibank') || fileLower.contains('อิสลาม')) {
          return 'iBank (อิสลามแห่งประเทศไทย)';
        }
        if (fileLower.contains('ไทยช่วยไทย')) {
          return 'ไทยช่วยไทย (เป๋าตัง)';
        }
        return 'เป๋าตัง (PaoTang)';
      }
      if (fileLower.contains('krungthai next') || fileLower.contains('krungthai') || fileLower.contains('ktb')) {
        return 'กรุงไทย (Krungthai NEXT)';
      }
      if (fileLower.contains('bualuang') || fileLower.contains('bangkok bank') || fileLower.contains('bbl')) {
        return 'กรุงเทพ (Bualuang)';
      }
      if (fileLower.contains('ttb touch') || fileLower.contains('ttb') || fileLower.contains('tmb') || fileLower.contains('thanachart')) {
        return 'ttb touch';
      }
      if (fileLower.contains('kma') || fileLower.contains('krungsri') || fileLower.contains('bay')) {
        return 'กรุงศรีอยุธยา (KMA)';
      }
      if (fileLower.contains('mymo') || fileLower.contains('gsb') || fileLower.contains('ออมสิน')) {
        return 'MyMo (ออมสิน)';
      }
      if (fileLower.contains('a-mobile') || fileLower.contains('baac') || fileLower.contains('ธกส')) {
        return 'ธ.ก.ส. (A-Mobile Plus)';
      }
      if (fileLower.contains('truemoney') || fileLower.contains('true money') || fileLower.contains('ทรูมันนี่')) {
        return 'TrueMoney Wallet';
      }
      if (fileLower.contains('uob tmrw') || fileLower.contains('uob') || fileLower.contains('ยูโอบี')) {
        return 'UOB TMRW';
      }
      if (fileLower.contains('cimb') || fileLower.contains('ซีไอเอ็มบี')) {
        return 'CIMB Thai';
      }
      if (fileLower.contains('dime') || fileLower.contains('kkp') || fileLower.contains('เกียรตินาคิน')) {
        return 'เกียรตินาคินภัทร (Dime! / KKP)';
      }
      if (fileLower.contains('lhb you') || fileLower.contains('lh bank') || fileLower.contains('lhbank')) {
        return 'แลนด์ แอนด์ เฮ้าส์ (LHB You)';
      }
    }

    final clean = normalizeOcrText(text).toLowerCase();
    final lines = clean.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    // 2. Check Top Header Lines (Sender Bank Branding)
    if (lines.isNotEmpty) {
      final topHeader = lines.take(3).join(' ');
      final headerBank = _matchSingleBankName(topHeader);
      if (headerBank != null) return headerBank;
    }

    // 3. Check "จาก / From / ผู้โอน"
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('จาก') || line.startsWith('ผู้โอน') || line.startsWith('from')) {
        final senderSnippet = lines.skip(i).take(3).join(' ');
        final sBank = _matchSingleBankName(senderSnippet);
        if (sBank != null) return sBank;
        break;
      }
    }

    // 4. Fallback to general text matching
    final generalBank = _matchSingleBankName(clean);
    return generalBank ?? 'ธนาคารไทย';
  }

  static String? _matchSingleBankName(String clean) {
    if (clean.contains('k plus') || clean.contains('kplus') || clean.contains('kbank') || clean.contains('กสิกร')) {
      return 'กสิกรไทย (K PLUS)';
    }
    if (clean.contains('scb') || clean.contains('ไทยพาณิชย์') || clean.contains('แม่มณี')) {
      return 'ไทยพาณิชย์ (SCB EASY)';
    }
    if (clean.contains('ibank') || clean.contains('อิสลามแห่งประเทศไทย') || clean.contains('อิสลาม') || clean.contains('islamic')) {
      return 'iBank (อิสลามแห่งประเทศไทย)';
    }
    if (clean.contains('ไทยช่วยไทย') || clean.contains('คนละครึ่ง') || clean.contains('เราชนะ') || clean.contains('สวัสดิการแห่งรัฐ') || clean.contains('เงินช่วยเหลือ')) {
      return 'ไทยช่วยไทย (เป๋าตัง)';
    }
    if (clean.contains('เป๋าตัง') || clean.contains('paotang') || clean.contains('g-wallet') || clean.contains('gwallet')) {
      return 'เป๋าตัง (PaoTang)';
    }
    if (clean.contains('krungthai') || clean.contains('ktb') || clean.contains('กรุงไทย') || clean.contains('next')) {
      return 'กรุงไทย (Krungthai NEXT)';
    }
    if (clean.contains('truemoney') || clean.contains('ทรูมันนี่')) {
      return 'TrueMoney Wallet';
    }
    if (clean.contains('bbl') || clean.contains('bualuang') || clean.contains('กรุงเทพ') || clean.contains('โมบายแบงก์กิ้ง')) {
      return 'กรุงเทพ (Bualuang)';
    }
    if (clean.contains('ttb') || clean.contains('ทหารไทยธนชาต') || clean.contains('ทหารไทย') || clean.contains('ธนชาต') || clean.contains('ทีทีบี')) {
      return 'ttb touch';
    }
    if (clean.contains('mymo') || clean.contains('ออมสิน') || clean.contains('gsb')) {
      return 'MyMo (ออมสิน)';
    }
    if (clean.contains('bay') || clean.contains('กรุงศรี') || clean.contains('kma') || clean.contains('ayudhya')) {
      return 'กรุงศรีอยุธยา (KMA)';
    }
    if (clean.contains('baac') || clean.contains('ธ.ก.ส.') || clean.contains('ธกส') || clean.contains('เกษตรและสหกรณ์')) {
      return 'ธ.ก.ส. (A-Mobile Plus)';
    }
    if (clean.contains('shopeepay') || clean.contains('ช้อปปี้')) {
      return 'ShopeePay';
    }
    if (clean.contains('cimb') || clean.contains('ซีไอเอ็มบี')) {
      return 'CIMB Thai';
    }
    if (clean.contains('uob') || clean.contains('tmrw') || clean.contains('ยูโอบี')) {
      return 'UOB TMRW';
    }
    if (clean.contains('dime!') || clean.contains('dime') || clean.contains('kkp') || clean.contains('เกียรตินาคิน')) {
      return 'เกียรตินาคินภัทร (Dime! / KKP)';
    }
    if (clean.contains('lhb you') || clean.contains('lh bank') || clean.contains('lhbank')) {
      return 'แลนด์ แอนด์ เฮ้าส์ (LHB You)';
    }
    if (clean.contains('promptpay') || clean.contains('พร้อมเพย์')) {
      return 'พร้อมเพย์';
    }
    return null;
  }

  /// 6. Hybrid Fusion Confidence Score
  static double calculateConfidenceScore({
    required bool hasQr,
    required double amount,
    required String refId,
    required String bankName,
  }) {
    double score = 0.0;
    if (hasQr) score += 40.0;
    if (amount > 0.0) score += 30.0;
    if (refId.isNotEmpty) score += 15.0;
    if (bankName != 'ธนาคารไทย') score += 15.0;
    return score.clamp(0.0, 100.0);
  }

  /// 7. Strict Multi-Bank Passbook / BookBank / E-Passbook Identification
  /// Recognizes physical and digital passbooks across all 11 Thai Banks and classifies them as non-slips
  static bool isPassbookOrAccountProof(String text, {String? fileName, String? filePath}) {
    final clean = normalizeOcrText(text).toLowerCase();
    final file = (fileName ?? filePath ?? '').toLowerCase();

    // Passbook keywords for physical bookbanks and e-savings proofs:
    final passbookSignatures = [
      // Common terms
      'สมุดเงินฝาก', 'สมุดเงินฝากออมทรัพย์', 'สมุดคู่ฝาก', 'สมุดบัญชี', 'หน้าสมุดบัญชี', 'หน้าสมุดเงินฝาก',
      'สมุดคู่ฝากธนาคาร', 'ข้อมูลบัญชีเงินฝาก', 'หนังสือรับรองการเปิดบัญชี', 'หนังสือรับรองยอดเงิน',
      'ใช้เพื่อแสดงหมายเลขบัญชี', 'ใช้เป็นหลักฐานแสดงการเปิดบัญชี', 'สาขาเจ้าของบัญชี', 'รหัสสาขา',
      'ชื่อบัญชี', 'name of account', 'account name', 'passbook', 'bookbank', 'book_bank', 'e-passbook', 'epassbook',
      'หน้าแรกของสมุดบัญชี', 'หน้าสมุด', 'book bank', 'หน้าบัญชี', 'สำเนาสมุดบัญชี', 'สมุดธนาคาร',
      
      // KBank (K PLUS e-Savings & Physical Book)
      'k-eshop', 'k-saving', 'k-deposit', 'e-saving', 'e-savings',
      'statement', 'bank statement', 'รายการเดินบัญชี', 'หนังสือรับรองสถานะทางการเงิน',
      'k-esavings', 'k esavings', 'esavings', 'online savings', 'สำนักพหลโยธิน',

      // SCB (SCB EASY Digital Passbook & Purple Book)
      'สมุดบัญชีเงินฝาก', 'เงินฝากออมทรัพย์', 'เงินฝากประจำ', 'เงินฝากกระแสรายวัน', 'บันทึกภาพสมุดบัญชี',

      // KTB (Krungthai NEXT e-Passbook & Blue Book)
      'krungthai next สมุดบัญชี', 'สมุดคู่ฝากประเภทเงินฝากออมทรัพย์',

      // BBL (Bualuang e-Savings & Blue/Orange Book)
      'สมุดเงินฝากสะสมทรัพย์', 'bbl e-savings', 'สะสมทรัพย์',

      // TTB (ttb touch e-Passbook & all free)
      'ttb all free', 'allfree', 'all free', 'ttb basic', 'ออลล์ฟรี', 'หน้าสมุดบัญชี ttb',

      // GSB (MyMo e-Passbook & Pink Book)
      'เงินฝากเผื่อเรียก', 'เผื่อเรียกพิเศษ', 'เงินฝากเผื่อเรียกพิเศษ', 'เลขทะเบียนบัญชี',

      // BAY (KMA e-Passbook & Yellow Book)
      'เงินฝากออมทรัพย์ มีแต่ได้', 'มีแต่ได้', 'ออมทรัพย์มีแต่ได้',

      // BAAC / ธ.ก.ส.
      'ธนาคารเพื่อการเกษตรและสหกรณ์การเกษตร', 'ทวีโชค', 'เงินฝากออมทรัพย์ทวีโชค', 'สมุดเงินฝาก ธ.ก.ส.',

      // GHB / ธอส.
      'ธนาคารอาคารสงเคราะห์', 'สมุดคู่ฝาก ธอส.',

      // iBank / อิสลาม
      'เงินฝากออมทรัพย์ วาดิอะฮ์', 'วาดิอะฮ์', 'อัลฮะซัน', 'สมุดบัญชีเงินฝาก ibank',

      // CIMB & UOB
      'speed d', 'one account', 'tmrw account'
    ];

    bool containsPassbookKeyword = false;
    for (final sig in passbookSignatures) {
      if (clean.contains(sig) || file.contains(sig)) {
        containsPassbookKeyword = true;
        break;
      }
    }

    if (!containsPassbookKeyword) return false;

    // Check if there is an explicit transaction completion confirmation
    final hasTransferSuccess = clean.contains('โอนเงินสำเร็จ') ||
        clean.contains('โอนสำเร็จ') ||
        clean.contains('รายการสำเร็จ') ||
        clean.contains('ชำระสำเร็จ') ||
        clean.contains('เงินเข้าสำเร็จ') ||
        clean.contains('รับโอนเงินสำเร็จ') ||
        clean.contains('transfer successful') ||
        clean.contains('payment successful');

    // If it has passbook signatures and lacks transfer success phrases, it is a PASSBOOK (reject!)
    return !hasTransferSuccess;
  }
}
