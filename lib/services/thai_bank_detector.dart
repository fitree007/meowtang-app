import 'package:flutter/material.dart';
import '../models/transaction_item.dart';
import '../models/account_item.dart';

class SlipBankIdentification {
  final String bankCode;
  final String bankName;
  final String cleanBank;

  const SlipBankIdentification({
    required this.bankCode,
    required this.bankName,
    required this.cleanBank,
  });

  @override
  String toString() => 'SlipBankIdentification(code: $bankCode, name: $bankName, clean: $cleanBank)';
}

class ThaiBankInfo {
  final String code;
  final String nameTh;
  final String nameEn;
  final String shortName;
  final Color brandColor;
  final IconData icon;
  final List<String> keywords;

  const ThaiBankInfo({
    required this.code,
    required this.nameTh,
    required this.nameEn,
    String? shortName,
    String? shortNameTh,
    String? shortNameEn,
    Color? brandColor,
    Color? primaryColor,
    Color? secondaryColor,
    IconData? icon,
    List<String>? keywords,
  })  : shortName = shortName ?? shortNameTh ?? shortNameEn ?? code,
        brandColor = brandColor ?? primaryColor ?? const Color(0xFF64748B),
        icon = icon ?? Icons.account_balance,
        keywords = keywords ?? const [];

  Color get primaryColor => brandColor;
  Color get secondaryColor => brandColor;
  String get shortNameTh => shortName;
  String get shortNameEn => shortName;
}

typedef ThaiBankMeta = ThaiBankInfo;

class ThaiBankDetector {
  static ThaiBankInfo getBank(String code) => getBankByCode(code);

  static const List<ThaiBankInfo> supportedBanks = [
    ThaiBankInfo(
      code: 'KBANK',
      nameTh: 'ธนาคารกสิกรไทย',
      nameEn: 'Kasikornbank (K PLUS)',
      shortName: 'KBank',
      brandColor: Color(0xFF138F2D),
      icon: Icons.account_balance,
      keywords: ['กสิกร', 'kbank', 'k plus', 'kplus', 'kasikorn'],
    ),
    ThaiBankInfo(
      code: 'MAKE',
      nameTh: 'MAKE by KBank',
      nameEn: 'MAKE by KBank',
      shortName: 'MAKE',
      brandColor: Color(0xFF10B981),
      icon: Icons.cloud_done_rounded,
      keywords: ['make by kbank', 'make kbank', 'cloud pocket'],
    ),
    ThaiBankInfo(
      code: 'SCB',
      nameTh: 'ธนาคารไทยพาณิชย์',
      nameEn: 'Siam Commercial Bank (SCB EASY)',
      shortName: 'SCB',
      brandColor: Color(0xFF4E2E7F),
      icon: Icons.account_balance,
      keywords: ['ไทยพาณิชย์', 'scb', 'scb easy'],
    ),
    ThaiBankInfo(
      code: 'BBL',
      nameTh: 'ธนาคารกรุงเทพ',
      nameEn: 'Bangkok Bank (Bualuang)',
      shortName: 'BBL',
      brandColor: Color(0xFF1E4598),
      icon: Icons.account_balance,
      keywords: ['กรุงเทพ', 'bbl', 'bualuang'],
    ),
    ThaiBankInfo(
      code: 'KTB',
      nameTh: 'ธนาคารกรุงไทย',
      nameEn: 'Krungthai Bank (NEXT)',
      shortName: 'KTB',
      brandColor: Color(0xFF00A6E6),
      icon: Icons.account_balance,
      keywords: ['กรุงไทย', 'ktb', 'krungthai', 'next'],
    ),
    ThaiBankInfo(
      code: 'TTB',
      nameTh: 'ธนาคารทหารไทยธนชาต',
      nameEn: 'TMBThanachart (ttb touch)',
      shortName: 'ttb',
      brandColor: Color(0xFF002D63),
      icon: Icons.account_balance,
      keywords: ['ทหารไทยธนชาต', 'ttb', 'tmb', 'thanachart'],
    ),
    ThaiBankInfo(
      code: 'BAY',
      nameTh: 'ธนาคารกรุงศรีอยุธยา',
      nameEn: 'Bank of Ayudhya (Krungsri KMA)',
      shortName: 'Krungsri',
      brandColor: Color(0xFFFDB913),
      icon: Icons.account_balance,
      keywords: ['กรุงศรี', 'bay', 'krungsri', 'kma'],
    ),
    ThaiBankInfo(
      code: 'KEPT',
      nameTh: 'Kept by Krungsri',
      nameEn: 'Kept by Krungsri',
      shortName: 'Kept',
      brandColor: Color(0xFF5B45FF),
      icon: Icons.savings_rounded,
      keywords: ['kept', 'kept by krungsri'],
    ),
    ThaiBankInfo(
      code: 'GSB',
      nameTh: 'ธนาคารออมสิน',
      nameEn: 'Government Savings Bank (MyMo)',
      shortName: 'GSB',
      brandColor: Color(0xFFEB198B),
      icon: Icons.account_balance,
      keywords: ['ออมสิน', 'gsb', 'mymo'],
    ),
    ThaiBankInfo(
      code: 'UOB',
      nameTh: 'ธนาคารยูโอบี',
      nameEn: 'United Overseas Bank (UOB TMRW)',
      shortName: 'UOB',
      brandColor: Color(0xFF003882),
      icon: Icons.account_balance,
      keywords: ['ยูโอบี', 'uob', 'tmrw'],
    ),
    ThaiBankInfo(
      code: 'CIMB',
      nameTh: 'ธนาคารซีไอเอ็มบีไทย',
      nameEn: 'CIMB Thai Bank',
      shortName: 'CIMB',
      brandColor: Color(0xFF7E1417),
      icon: Icons.account_balance,
      keywords: ['ซีไอเอ็มบี', 'cimb', 'cimb thai'],
    ),
    ThaiBankInfo(
      code: 'KKP',
      nameTh: 'ธนาคารเกียรตินาคินภัทร',
      nameEn: 'Kiatnakin Phatra (KKP MOBILE)',
      shortName: 'KKP',
      brandColor: Color(0xFF223652),
      icon: Icons.account_balance,
      keywords: ['เกียรตินาคินภัทร', 'เกียรตินาคิน', 'kkp', 'kiatnakin'],
    ),
    ThaiBankInfo(
      code: 'DIME',
      nameTh: 'Dime! by KKP',
      nameEn: 'Dime! by KKP',
      shortName: 'Dime!',
      brandColor: Color(0xFF00D18F),
      icon: Icons.monetization_on_rounded,
      keywords: ['dime', 'dime!'],
    ),
    ThaiBankInfo(
      code: 'GHB',
      nameTh: 'ธนาคารอาคารสงเคราะห์',
      nameEn: 'Government Housing Bank (GHB ALL GEN)',
      shortName: 'GHB (ธอส.)',
      brandColor: Color(0xFFF37021),
      icon: Icons.home_work_rounded,
      keywords: ['อาคารสงเคราะห์', 'ธอส', 'ghb', 'ghb all'],
    ),
    ThaiBankInfo(
      code: 'TISCO',
      nameTh: 'ธนาคารทิสโก้',
      nameEn: 'TISCO Bank (TISCO My Wealth)',
      shortName: 'TISCO',
      brandColor: Color(0xFF004B93),
      icon: Icons.account_balance,
      keywords: ['ทิสโก้', 'tisco', 'my wealth'],
    ),
    ThaiBankInfo(
      code: 'LHBANK',
      nameTh: 'ธนาคารแลนด์ แอนด์ เฮ้าส์',
      nameEn: 'LH Bank (LHB You)',
      shortName: 'LH Bank',
      brandColor: Color(0xFF6D6E71),
      icon: Icons.account_balance,
      keywords: ['แลนด์ แอนด์ เฮ้าส์', 'lh bank', 'lhb', 'lhb you'],
    ),
    ThaiBankInfo(
      code: 'IBANK',
      nameTh: 'ธนาคารอิสลามแห่งประเทศไทย',
      nameEn: 'Islamic Bank of Thailand (iBank)',
      shortName: 'iBank',
      brandColor: Color(0xFF006F3D),
      icon: Icons.account_balance,
      keywords: ['อิสลามแห่งประเทศไทย', 'ibank', 'islamic bank'],
    ),
    ThaiBankInfo(
      code: 'BAAC',
      nameTh: 'ธ.ก.ส. (เพื่อการเกษตรและสหกรณ์)',
      nameEn: 'BAAC (A-Mobile Plus)',
      shortName: 'BAAC (ธ.ก.ส.)',
      brandColor: Color(0xFF006F3D),
      icon: Icons.agriculture_rounded,
      keywords: ['เพื่อการเกษตรและสหกรณ์', 'ธกส', 'baac', 'a-mobile'],
    ),
    ThaiBankInfo(
      code: 'PAOTANG',
      nameTh: 'เป๋าตัง (PaoTang / ถุงเงิน)',
      nameEn: 'PaoTang (G-Wallet)',
      shortName: 'เป๋าตัง',
      brandColor: Color(0xFF00A6E6),
      icon: Icons.wallet,
      keywords: ['เป๋าตัง', 'paotang', 'g-wallet', 'ถุงเงิน'],
    ),
    ThaiBankInfo(
      code: 'TRUEMONEY',
      nameTh: 'ทรูมันนี่ วอลเล็ท',
      nameEn: 'TrueMoney Wallet',
      shortName: 'TrueMoney',
      brandColor: Color(0xFFFF5000),
      icon: Icons.wallet,
      keywords: ['ทรูมันนี่', 'truemoney', 'true money'],
    ),
    ThaiBankInfo(
      code: 'PROMPTPAY',
      nameTh: 'พร้อมเพย์',
      nameEn: 'PromptPay QR',
      shortName: 'PromptPay',
      brandColor: Color(0xFF003D79),
      icon: Icons.qr_code_scanner,
      keywords: ['พร้อมเพย์', 'promptpay'],
    ),
    ThaiBankInfo(
      code: 'CASH',
      nameTh: 'เงินสด / บัญชีอื่นๆ',
      nameEn: 'Cash / Other Accounts',
      shortName: 'Cash',
      brandColor: Color(0xFF10B981),
      icon: Icons.payments,
      keywords: ['เงินสด', 'cash'],
    ),
  ];

  static ThaiBankInfo getBankByCode(String code) {
    final clean = code.toUpperCase().trim();
    return supportedBanks.firstWhere(
      (b) => b.code == clean || b.shortName.toUpperCase() == clean,
      orElse: () => const ThaiBankInfo(
        code: 'OTHER',
        nameTh: 'บัญชีอื่นๆ',
        nameEn: 'Other Account',
        shortName: 'Other',
        brandColor: Color(0xFF64748B),
        icon: Icons.account_balance_wallet,
      ),
    );
  }

  /// Detects bank from a transaction given its account, image path, QR payload, and directional OCR text
  static String detectBankCode(TransactionItem tx, List<AccountItem> accounts) {
    // Layer 0: Explicit bank from bankName or dedicated banking folder (highest authority)
    final tLower = tx.title.toLowerCase();
    final nLower = (tx.note ?? '').toLowerCase();
    final bLower = (tx.bankName ?? '').toLowerCase();
    final pathLower = (tx.slipImageUrl ?? '').toLowerCase();

    // Fast-path: Explicit bank from bankName
    if (bLower.contains('กสิกร') || bLower.contains('k plus') || bLower.contains('kplus') || bLower.contains('kbank') || bLower == '004') {
      return 'KBANK';
    }
    if (bLower.contains('ไทยพาณิชย์') || bLower.contains('scb') || bLower == '014') {
      return 'SCB';
    }
    if (bLower.contains('กรุงไทย') || bLower.contains('ktb') || bLower == '006') {
      return 'KTB';
    }
    if (bLower.contains('ธนาคารอิสลาม') || bLower.contains('ibank') || bLower == '066' || bLower.contains('ไอแบงก์') || bLower.contains('ไอแบงค์')) {
      return 'IBANK';
    }

    // Fast-path: Slip in dedicated banking album/folder
    if (pathLower.contains('k plus') || pathLower.contains('kplus') || pathLower.contains('kbank') || pathLower.contains('kasikorn')) {
      return 'KBANK';
    }
    if (pathLower.contains('scb easy') || pathLower.contains('scb') || pathLower.contains('ไทยพาณิชย์')) {
      return 'SCB';
    }
    if (pathLower.contains('krungthai next') || pathLower.contains('krungthai') || pathLower.contains('ktb')) {
      return 'KTB';
    }
    if (pathLower.contains('ibank') || pathLower.contains('islamicbank') || pathLower.contains('ธนาคารอิสลาม')) {
      return 'IBANK';
    }

    // Explicit Islamic Bank indicator in Title or Note (e.g. "โอนเงินผ่านธนาคารอิสลาม")
    if (tLower.contains('ธนาคารอิสลาม') || tLower.contains('ibank') ||
        nLower.contains('ธนาคารอิสลาม') || nLower.contains('ibank')) {
      return 'IBANK';
    }

    // Layer 1: Check matching registered account's bankCode
    final matchedAcc = accounts.firstWhere(
      (a) => a.id == tx.accountId,
      orElse: () => AccountItem(
        id: '',
        name: '',
        bankCode: 'CASH',
        accountNumber: '',
        colorValue: 0,
      ),
    );

    if (matchedAcc.id.isNotEmpty && matchedAcc.bankCode.isNotEmpty && matchedAcc.bankCode != 'CASH') {
      final code = matchedAcc.bankCode.toUpperCase();
      if (supportedBanks.any((b) => b.code == code)) {
        return code;
      }
    }

    // Layer 2: Check Album / File Path (100% accurate for slips saved from specific banking apps)
    if (tx.slipImageUrl != null && tx.slipImageUrl!.isNotEmpty) {
      if (pathLower.contains('paotang') || pathLower.contains('เป๋าตัง') || pathLower.contains('gwallet') || pathLower.contains('g-wallet') || pathLower.contains('ไทยช่วยไทย') || pathLower.contains('ถุงเงิน') || pathLower.contains('tungngern')) {
        if (pathLower.contains('ibank') || pathLower.contains('ธนาคารอิสลาม') ||
            bLower.contains('ธนาคารอิสลาม') || bLower.contains('ibank') || bLower == '066' ||
            bLower.contains('ไอแบงก์') || bLower.contains('ไอแบงค์') ||
            tx.title.contains('ธนาคารอิสลาม') || (tx.note?.contains('ธนาคารอิสลาม') ?? false) ||
            (tx.rawOcrText?.contains('ธนาคารอิสลาม') ?? false) || (tx.rawOcrText?.contains('ไอแบงก์') ?? false) || (tx.rawOcrText?.contains('ibank') ?? false)) {
          return 'IBANK';
        }
        return 'PAOTANG';
      }
      if (pathLower.contains('krungthai next') || pathLower.contains('krungthai') || pathLower.contains('ktb')) {
        return 'KTB';
      }
      if (pathLower.contains('bualuang') || pathLower.contains('bangkok bank') || pathLower.contains('bbl')) {
        return 'BBL';
      }
      if (pathLower.contains('ttb touch') || pathLower.contains('ttb') || pathLower.contains('tmb') || pathLower.contains('thanachart')) {
        return 'TTB';
      }
      if (pathLower.contains('kma') || pathLower.contains('krungsri') || pathLower.contains('bay')) {
        return 'BAY';
      }
      if (pathLower.contains('mymo') || pathLower.contains('gsb') || pathLower.contains('ออมสิน')) {
        return 'GSB';
      }
      if (pathLower.contains('a-mobile') || pathLower.contains('baac') || pathLower.contains('ธกส')) {
        return 'BAAC';
      }
      if (pathLower.contains('truemoney') || pathLower.contains('true money') || pathLower.contains('ทรูมันนี่')) {
        return 'TRUEMONEY';
      }
      if (pathLower.contains('uob tmrw') || pathLower.contains('uob') || pathLower.contains('ยูโอบี')) {
        return 'UOB';
      }
      if (pathLower.contains('cimb') || pathLower.contains('ซีไอเอ็มบี')) {
        return 'CIMB';
      }
      if (pathLower.contains('dime') || pathLower.contains('kkp') || pathLower.contains('เกียรตินาคิน')) {
        return 'KKP';
      }
      if (pathLower.contains('lhb you') || pathLower.contains('lh bank') || pathLower.contains('lhbank')) {
        return 'LHBANK';
      }
    }

    // Layer 3: Check Directional OCR Text (Prioritize Sender/Top Header over Receiver)
    final rawText = tx.rawOcrText ?? '';
    if (rawText.isNotEmpty) {
      final lines = rawText.split('\n').map((l) => l.trim().toLowerCase()).where((l) => l.isNotEmpty).toList();

      // Check first 3 lines (Header/App Branding area)
      final topLines = lines.take(3).join(' ');
      final topBank = _detectBankFromTextSnippet(topLines);
      if (topBank != null) return topBank;

      // Check "จาก / From / ผู้โอน" section
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.startsWith('จาก') || line.startsWith('ผู้โอน') || line.startsWith('from')) {
          final senderSnippet = lines.skip(i).take(3).join(' ');
          final sBank = _detectBankFromTextSnippet(senderSnippet);
          if (sBank != null) return sBank;
          break;
        }
      }
    }

    // Layer 4: General keyword & note/title search
    final fullText = '${tx.bankName ?? ""} ${tx.rawOcrText ?? ""} ${tx.note ?? ""} ${tx.title}'.toLowerCase();
    final generalBank = _detectBankFromTextSnippet(fullText);
    if (generalBank != null) return generalBank;

    // Default to Cash or Other
    return 'CASH';
  }

  /// Extracts standard bank code from bank name or brand string
  static String detectCodeFromBankName(String bankName) {
    final clean = bankName.toLowerCase().trim();
    if (clean.contains('อิสลาม') || clean.contains('ibank') || clean.contains('ไอแบงก์') || clean.contains('ไอแบงค์') || clean == '066') {
      return 'IBANK';
    }
    if (clean.contains('กสิกร') || clean.contains('kbank') || clean.contains('k plus')) {
      return 'KBANK';
    }
    if (clean.contains('ไทยพาณิชย์') || clean.contains('scb')) {
      return 'SCB';
    }
    if (clean.contains('กรุงไทย') || clean.contains('ktb')) {
      return 'KTB';
    }
    if (clean.contains('กรุงเทพ') || clean.contains('bbl') || clean.contains('bualuang')) {
      return 'BBL';
    }
    if (clean.contains('กรุงศรี') || clean.contains('bay') || clean.contains('kma')) {
      return 'BAY';
    }
    if (clean.contains('ออมสิน') || clean.contains('gsb') || clean.contains('mymo')) {
      return 'GSB';
    }
    if (clean.contains('ทหารไทย') || clean.contains('ธนชาต') || clean.contains('ttb') || clean.contains('ทีทีบี')) {
      return 'TTB';
    }
    if (clean.contains('ธ.ก.ส') || clean.contains('baac') || clean.contains('ธกส')) {
      return 'BAAC';
    }
    if (clean.contains('อาคารสงเคราะห์') || clean.contains('ธอส') || clean.contains('ghb')) {
      return 'GHB';
    }
    if (clean.contains('ยูโอบี') || clean.contains('uob')) {
      return 'UOB';
    }
    if (clean.contains('ซีไอเอ็มบี') || clean.contains('cimb')) {
      return 'CIMB';
    }
    if (clean.contains('เกียรตินาคิน') || clean.contains('kkp') || clean.contains('dime')) {
      return 'KKP';
    }
    if (clean.contains('ทิสโก้') || clean.contains('tisco')) {
      return 'TISCO';
    }
    if (clean.contains('แลนด์ แอนด์ เฮ้าส์') || clean.contains('แอล เอช') || clean.contains('lhb')) {
      return 'LHBANK';
    }
    if (clean.contains('ทรูมันนี่') || clean.contains('truemoney')) {
      return 'TRUEMONEY';
    }
    if (clean.contains('ช้อปปี้') || clean.contains('shopeepay')) {
      return 'SHOPEEPAY';
    }
    if (clean.contains('แรบบิท') || clean.contains('rabbit')) {
      return 'RABBITLINEPAY';
    }
    if (clean.contains('เป๋าตัง') || clean.contains('paotang') || clean.contains('g-wallet')) {
      return 'PAOTANG';
    }
    return 'CASH';
  }

  static String? _detectBankFromTextSnippet(String text) {
    if (text.contains('k plus') || text.contains('kplus') || text.contains('kbank') || text.contains('กสิกรไทย') || text.contains('กสิกร') || text.contains('kasikorn')) {
      return 'KBANK';
    }
    if (text.contains('scb easy') || text.contains('scb') || text.contains('ไทยพาณิชย์') || text.contains('แม่มณี') || text.contains('siam commercial')) {
      return 'SCB';
    }
    if (text.contains('ibank') ||
        text.contains('อิสลามแห่งประเทศไทย') ||
        text.contains('ธนาคารอิสลาม') ||
        text.contains('ธ.อิสลาม') ||
        text.contains('islamic bank') ||
        text.contains('ไอแบงก์') ||
        text.contains('ไอแบงค์')) {
      return 'IBANK';
    }
    if (text.contains('ไทยช่วยไทย') || text.contains('คนละครึ่ง') || text.contains('เราชนะ') || text.contains('สวัสดิการแห่งรัฐ') || text.contains('เป๋าตัง') || text.contains('paotang') || text.contains('g-wallet') || text.contains('gwallet')) {
      return 'PAOTANG';
    }
    if (text.contains('krungthai next') || text.contains('krungthai') || text.contains('ktb') || text.contains('กรุงไทย')) {
      return 'KTB';
    }
    if (text.contains('bualuang') || text.contains('bangkok bank') || text.contains('กรุงเทพ') || text.contains('bbl') || text.contains('โมบายแบงก์กิ้ง')) {
      return 'BBL';
    }
    if (text.contains('ttb touch') || text.contains('ttb') || text.contains('ทหารไทยธนชาต') || text.contains('ทหารไทย') || text.contains('ธนชาต') || text.contains('thanachart') || text.contains('ทีทีบี')) {
      return 'TTB';
    }
    if (text.contains('kma') || text.contains('krungsri') || text.contains('กรุงศรีอยุธยา') || text.contains('กรุงศรี') || text.contains('bay') || text.contains('ayudhya')) {
      return 'BAY';
    }
    if (text.contains('mymo') || text.contains('gsb') || text.contains('ออมสิน') || text.contains('government savings')) {
      return 'GSB';
    }
    if (text.contains('a-mobile') || text.contains('baac') || text.contains('ธ.ก.ส.') || text.contains('ธกส') || text.contains('เพื่อการเกษตรและสหกรณ์')) {
      return 'BAAC';
    }
    if (text.contains('truemoney') || text.contains('true money') || text.contains('ทรูมันนี่') || text.contains('tmn')) {
      return 'TRUEMONEY';
    }
    if (text.contains('uob tmrw') || text.contains('uob') || text.contains('ยูโอบี')) {
      return 'UOB';
    }
    if (text.contains('cimb') || text.contains('ซีไอเอ็มบี')) {
      return 'CIMB';
    }
    if (text.contains('dime!') || text.contains('dime') || text.contains('kkp') || text.contains('เกียรตินาคิน')) {
      return 'KKP';
    }
    if (text.contains('lhb you') || text.contains('lh bank') || text.contains('lhbank') || text.contains('แลนด์ แอนด์ เฮ้าส์')) {
      return 'LHBANK';
    }
    if (text.contains('promptpay') || text.contains('พร้อมเพย์')) {
      return 'PROMPTPAY';
    }
    return null;
  }

  static ThaiBankInfo detectBankFromText(String text) {
    final code = _detectBankFromTextSnippet(text.toLowerCase()) ?? 'OTHER';
    return getBankByCode(code);
  }

  /// Detects the issuing bank of a slip with bulletproof prioritization:
  /// 1. QR Code 3-digit BOT bank code (Ultimate Authority)
  /// 2. Dedicated banking album/folder path (when present)
  /// 3. OCR text with STRICT exclusion of receiver section (Header & Sender only)
  static SlipBankIdentification identifySlipBank({
    required String rawOcrText,
    String? qrSenderBankCode,
    String? qrSenderBank,
    String? qrPayload,
    String? filePath,
    String? fileName,
    bool isIncome = false,
  }) {
    // --- Priority 1: QR Code BOT Bank Code (Highest Authority) ---
    String? code = qrSenderBankCode?.trim();
    if (code == null || code.isEmpty) {
      if (qrPayload != null && qrPayload.trim().isNotEmpty) {
        final subMatch = RegExp(r'0103(002|004|006|011|014|022|024|025|030|033|034|066|067|069|073)').firstMatch(qrPayload);
        if (subMatch != null) {
          code = subMatch.group(1);
        }
      }
    }

    if (code != null && code.isNotEmpty) {
      switch (code) {
        case '004':
          return const SlipBankIdentification(bankCode: 'KBANK', bankName: 'กสิกรไทย (K PLUS)', cleanBank: 'กสิกรไทย');
        case '006':
          return const SlipBankIdentification(bankCode: 'KTB', bankName: 'กรุงไทย (Krungthai NEXT)', cleanBank: 'กรุงไทย');
        case '014':
          return const SlipBankIdentification(bankCode: 'SCB', bankName: 'ไทยพาณิชย์ (SCB EASY)', cleanBank: 'ไทยพาณิชย์');
        case '002':
          return const SlipBankIdentification(bankCode: 'BBL', bankName: 'กรุงเทพ (Bualuang)', cleanBank: 'กรุงเทพ');
        case '011':
          return const SlipBankIdentification(bankCode: 'TTB', bankName: 'ทหารไทยธนชาต (ttb)', cleanBank: 'ทหารไทยธนชาต (ttb)');
        case '025':
          return const SlipBankIdentification(bankCode: 'BAY', bankName: 'กรุงศรีอยุธยา (KMA)', cleanBank: 'กรุงศรีอยุธยา');
        case '030':
          return const SlipBankIdentification(bankCode: 'GSB', bankName: 'MyMo (ออมสิน)', cleanBank: 'ออมสิน');
        case '034':
          return const SlipBankIdentification(bankCode: 'BAAC', bankName: 'ธ.ก.ส. (A-Mobile Plus)', cleanBank: 'ธ.ก.ส.');
        case '066':
          return const SlipBankIdentification(bankCode: 'IBANK', bankName: 'iBank (อิสลามแห่งประเทศไทย)', cleanBank: 'ธนาคารอิสลาม');
        case '022':
          return const SlipBankIdentification(bankCode: 'CIMB', bankName: 'CIMB Thai', cleanBank: 'ซีไอเอ็มบี');
        case '024':
          return const SlipBankIdentification(bankCode: 'UOB', bankName: 'UOB TMRW', cleanBank: 'ยูโอบี');
        case '069':
          return const SlipBankIdentification(bankCode: 'KKP', bankName: 'เกียรตินาคินภัทร (Dime! / KKP)', cleanBank: 'เกียรตินาคินภัทร');
        case '073':
          return const SlipBankIdentification(bankCode: 'LHBANK', bankName: 'แลนด์ แอนด์ เฮ้าส์ (LHB You)', cleanBank: 'แลนด์ แอนด์ เฮ้าส์');
      }
    }

    if (qrSenderBank != null && qrSenderBank.trim().isNotEmpty && qrSenderBank != 'ธนาคารไทย') {
      final bCode = detectCodeFromBankName(qrSenderBank);
      if (bCode != 'CASH' && bCode != 'OTHER') {
        return _makeBankIdentification(bCode, fallbackName: qrSenderBank);
      }
    }

    if (qrPayload != null && qrPayload.trim().isNotEmpty) {
      final lowerQr = qrPayload.toLowerCase();
      if (lowerQr.contains('kasikornbank') || lowerQr.contains('kplus')) {
        return const SlipBankIdentification(bankCode: 'KBANK', bankName: 'กสิกรไทย (K PLUS)', cleanBank: 'กสิกรไทย');
      }
      if (lowerQr.contains('krungthai') || lowerQr.contains('ktb') || lowerQr.contains('n006')) {
        return const SlipBankIdentification(bankCode: 'KTB', bankName: 'กรุงไทย (Krungthai NEXT)', cleanBank: 'กรุงไทย');
      }
      if (lowerQr.contains('scbeasy') || lowerQr.contains('scb')) {
        return const SlipBankIdentification(bankCode: 'SCB', bankName: 'ไทยพาณิชย์ (SCB EASY)', cleanBank: 'ไทยพาณิชย์');
      }
      if (lowerQr.contains('bangkokbank') || lowerQr.contains('bualuang')) {
        return const SlipBankIdentification(bankCode: 'BBL', bankName: 'กรุงเทพ (Bualuang)', cleanBank: 'กรุงเทพ');
      }
      if (lowerQr.contains('ttbbank') || lowerQr.contains('ttb')) {
        return const SlipBankIdentification(bankCode: 'TTB', bankName: 'ทหารไทยธนชาต (ttb)', cleanBank: 'ทหารไทยธนชาต (ttb)');
      }
      if (lowerQr.contains('gsb.or.th') || lowerQr.contains('mymo')) {
        return const SlipBankIdentification(bankCode: 'GSB', bankName: 'MyMo (ออมสิน)', cleanBank: 'ออมสิน');
      }
      if (lowerQr.contains('krungsri') || lowerQr.contains('kma')) {
        return const SlipBankIdentification(bankCode: 'BAY', bankName: 'กรุงศรีอยุธยา (KMA)', cleanBank: 'กรุงศรีอยุธยา');
      }
      if (lowerQr.contains('ibank') || lowerQr.contains('0103066')) {
        return const SlipBankIdentification(bankCode: 'IBANK', bankName: 'ธนาคารอิสลามแห่งประเทศไทย', cleanBank: 'ธนาคารอิสลาม');
      }
    }

    // --- Priority 2: Dedicated Bank Folder / Path (Album check) ---
    final pathLower = (filePath ?? '').toLowerCase();
    if (pathLower.isNotEmpty && !pathLower.contains('/cache/')) {
      if (pathLower.contains('k plus') || pathLower.contains('kplus') || pathLower.contains('kbank')) {
        return const SlipBankIdentification(bankCode: 'KBANK', bankName: 'กสิกรไทย (K PLUS)', cleanBank: 'กสิกรไทย');
      }
      if (pathLower.contains('scb easy') || pathLower.contains('scb') || pathLower.contains('ไทยพาณิชย์')) {
        return const SlipBankIdentification(bankCode: 'SCB', bankName: 'ไทยพาณิชย์ (SCB EASY)', cleanBank: 'ไทยพาณิชย์');
      }
      if (pathLower.contains('krungthai next') || pathLower.contains('krungthai') || pathLower.contains('ktb')) {
        return const SlipBankIdentification(bankCode: 'KTB', bankName: 'กรุงไทย (Krungthai NEXT)', cleanBank: 'กรุงไทย');
      }
      if (pathLower.contains('bualuang') || pathLower.contains('bangkokbank')) {
        return const SlipBankIdentification(bankCode: 'BBL', bankName: 'กรุงเทพ (Bualuang)', cleanBank: 'กรุงเทพ');
      }
      if (pathLower.contains('ttb touch') || pathLower.contains('ttb')) {
        return const SlipBankIdentification(bankCode: 'TTB', bankName: 'ทหารไทยธนชาต (ttb)', cleanBank: 'ทหารไทยธนชาต (ttb)');
      }
      if (pathLower.contains('mymo') || pathLower.contains('gsb')) {
        return const SlipBankIdentification(bankCode: 'GSB', bankName: 'MyMo (ออมสิน)', cleanBank: 'ออมสิน');
      }
      if (pathLower.contains('kma') || pathLower.contains('krungsri')) {
        return const SlipBankIdentification(bankCode: 'BAY', bankName: 'กรุงศรีอยุธยา (KMA)', cleanBank: 'กรุงศรีอยุธยา');
      }
      if (pathLower.contains('ibank') || pathLower.contains('islamicbank') || pathLower.contains('อิสลาม')) {
        return const SlipBankIdentification(bankCode: 'IBANK', bankName: 'ธนาคารอิสลามแห่งประเทศไทย', cleanBank: 'ธนาคารอิสลาม');
      }
      if (pathLower.contains('paotang') || pathLower.contains('เป๋าตัง') || pathLower.contains('g-wallet')) {
        return const SlipBankIdentification(bankCode: 'PAOTANG', bankName: 'เป๋าตัง (PaoTang)', cleanBank: 'เป๋าตัง');
      }
      if (pathLower.contains('truemoney') || pathLower.contains('ทรูมันนี่')) {
        return const SlipBankIdentification(bankCode: 'TRUEMONEY', bankName: 'TrueMoney Wallet', cleanBank: 'ทรูมันนี่');
      }
    }

    // --- Priority 3: OCR Text with STRICT Sender / Receiver Separation ---
    final cleanOcr = rawOcrText.replaceAll('\r', '').trim();
    if (cleanOcr.isEmpty) {
      return const SlipBankIdentification(bankCode: 'OTHER', bankName: 'ธนาคารไทย', cleanBank: 'ธนาคารไทย');
    }

    final lowerCleanOcr = cleanOcr.toLowerCase();

    // If it's an Income Slip, money was received INTO the receiver account,
    // so we want to identify the receiver account bank for the user's asset balance!
    if (isIncome) {
      final bCode = _detectBankFromTextSnippet(lowerCleanOcr);
      if (bCode != null) {
        return _makeBankIdentification(bCode);
      }
    }

    // For standard Expense/Transfer slips, the bank is the SENDER / ISSUING bank.
    // Cut off the Receiver Section completely so recipient bank NEVER hijacks detection!
    final receiverRegex = RegExp(
      r'(?:ไปยัง|ผู้รับเงิน|ผู้รับโอน|ผู้รับ|โอนไปยัง|โอนให้|เข้าบัญชี|เข้าบช|เลขที่บัญชีผู้รับ|บัญชีผู้รับ|ปลายทาง|\bto\b|\breceiver\b|\brecipient\b)',
      caseSensitive: false,
    );
    final receiverMatch = receiverRegex.firstMatch(lowerCleanOcr);
    final senderSection = receiverMatch != null ? lowerCleanOcr.substring(0, receiverMatch.start) : lowerCleanOcr;

    // A. Top Header (first 3-4 lines of sender section or OCR) - Highest confidence for App branding
    final lines = senderSection.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isNotEmpty) {
      final topHeader = lines.take(3).join(' ');
      final headerBank = _detectBankFromTextSnippet(topHeader);
      if (headerBank != null) {
        return _makeBankIdentification(headerBank);
      }
    }

    // B. Search inside "จาก / ผู้โอน / From" line
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('จาก') || line.contains('ผู้โอน') || line.contains('from')) {
        final senderSnippet = lines.skip(i).take(3).join(' ');
        final sBank = _detectBankFromTextSnippet(senderSnippet);
        if (sBank != null) {
          return _makeBankIdentification(sBank);
        }
        break;
      }
    }

    // C. Entire Sender Section (Everything before "ไปยัง")
    final sectionBank = _detectBankFromTextSnippet(senderSection);
    if (sectionBank != null) {
      return _makeBankIdentification(sectionBank);
    }

    // D. Safe Fallback: Check top lines of full OCR text before anything else
    final allLines = lowerCleanOcr.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (allLines.isNotEmpty) {
      final topLines = allLines.take(3).join(' ');
      final topBank = _detectBankFromTextSnippet(topLines);
      if (topBank != null) {
        return _makeBankIdentification(topBank);
      }
    }

    // E. General Fallback
    final generalCode = detectCodeFromBankName(lowerCleanOcr);
    return _makeBankIdentification(generalCode);
  }

  static SlipBankIdentification _makeBankIdentification(String bankCode, {String? fallbackName}) {
    switch (bankCode.toUpperCase()) {
      case 'KBANK':
        return const SlipBankIdentification(bankCode: 'KBANK', bankName: 'กสิกรไทย (K PLUS)', cleanBank: 'กสิกรไทย');
      case 'MAKE':
        return const SlipBankIdentification(bankCode: 'MAKE', bankName: 'MAKE by KBank', cleanBank: 'MAKE by KBank');
      case 'SCB':
        return const SlipBankIdentification(bankCode: 'SCB', bankName: 'ไทยพาณิชย์ (SCB EASY)', cleanBank: 'ไทยพาณิชย์');
      case 'KTB':
        return const SlipBankIdentification(bankCode: 'KTB', bankName: 'กรุงไทย (Krungthai NEXT)', cleanBank: 'กรุงไทย');
      case 'BBL':
        return const SlipBankIdentification(bankCode: 'BBL', bankName: 'กรุงเทพ (Bualuang)', cleanBank: 'กรุงเทพ');
      case 'TTB':
        return const SlipBankIdentification(bankCode: 'TTB', bankName: 'ทหารไทยธนชาต (ttb)', cleanBank: 'ทหารไทยธนชาต (ttb)');
      case 'BAY':
        return const SlipBankIdentification(bankCode: 'BAY', bankName: 'กรุงศรีอยุธยา (KMA)', cleanBank: 'กรุงศรีอยุธยา');
      case 'GSB':
        return const SlipBankIdentification(bankCode: 'GSB', bankName: 'MyMo (ออมสิน)', cleanBank: 'ออมสิน');
      case 'BAAC':
        return const SlipBankIdentification(bankCode: 'BAAC', bankName: 'ธ.ก.ส. (A-Mobile Plus)', cleanBank: 'ธ.ก.ส.');
      case 'IBANK':
        return const SlipBankIdentification(bankCode: 'IBANK', bankName: 'iBank (อิสลามแห่งประเทศไทย)', cleanBank: 'ธนาคารอิสลาม');
      case 'PAOTANG':
        return const SlipBankIdentification(bankCode: 'PAOTANG', bankName: 'เป๋าตัง (PaoTang)', cleanBank: 'เป๋าตัง');
      case 'TRUEMONEY':
        return const SlipBankIdentification(bankCode: 'TRUEMONEY', bankName: 'TrueMoney Wallet', cleanBank: 'ทรูมันนี่');
      case 'PROMPTPAY':
        return const SlipBankIdentification(bankCode: 'PROMPTPAY', bankName: 'พร้อมเพย์', cleanBank: 'พร้อมเพย์');
      case 'UOB':
        return const SlipBankIdentification(bankCode: 'UOB', bankName: 'UOB TMRW', cleanBank: 'ยูโอบี');
      case 'CIMB':
        return const SlipBankIdentification(bankCode: 'CIMB', bankName: 'CIMB Thai', cleanBank: 'ซีไอเอ็มบี');
      case 'KKP':
        return const SlipBankIdentification(bankCode: 'KKP', bankName: 'เกียรตินาคินภัทร (Dime! / KKP)', cleanBank: 'เกียรตินาคินภัทร');
      case 'LHBANK':
        return const SlipBankIdentification(bankCode: 'LHBANK', bankName: 'แลนด์ แอนด์ เฮ้าส์ (LHB You)', cleanBank: 'แลนด์ แอนด์ เฮ้าส์');
      default:
        return SlipBankIdentification(
          bankCode: bankCode,
          bankName: fallbackName ?? 'ธนาคารไทย',
          cleanBank: fallbackName ?? 'ธนาคารไทย',
        );
    }
  }
}
