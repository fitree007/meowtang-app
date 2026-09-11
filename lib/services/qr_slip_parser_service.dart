import 'dart:convert';
import '../models/category_item.dart';
import '../models/slip_extract_result.dart';
import '../models/transaction_item.dart';

class QrSlipResult {
  final bool success;
  final double amount;
  final String? refId;
  final String? receiverName;
  final String? receiverPromptPay;
  final String? senderBank;
  final String? senderBankCode;
  final String? rawPayload;

  const QrSlipResult({
    required this.success,
    this.amount = 0.0,
    this.refId,
    this.receiverName,
    this.receiverPromptPay,
    this.senderBank,
    this.senderBankCode,
    this.rawPayload,
  });
}

class QrSlipParserService {
  /// Standard Bank of Thailand (BOT) 3-digit bank code mapping
  static String? mapBankCodeToName(String? code) {
    if (code == null) return null;
    const map = {
      '002': 'ธนาคารกรุงเทพ',
      '004': 'ธนาคารกสิกรไทย',
      '006': 'ธนาคารกรุงไทย',
      '011': 'ธนาคารทหารไทยธนชาต',
      '014': 'ธนาคารไทยพาณิชย์',
      '022': 'ธนาคารซีไอเอ็มบีไทย',
      '024': 'ธนาคารยูโอบี',
      '025': 'ธนาคารกรุงศรีอยุธยา',
      '030': 'ธนาคารออมสิน',
      '033': 'ธนาคารอาคารสงเคราะห์',
      '034': 'ธนาคารเพื่อการเกษตรและสหกรณ์การเกษตร',
      '066': 'ธนาคารอิสลามแห่งประเทศไทย',
      '067': 'ธนาคารทิสโก้',
      '069': 'ธนาคารเกียรตินาคินภัทร',
      '073': 'ธนาคารแลนด์ แอนด์ เฮ้าส์',
    };
    return map[code.trim()];
  }

  /// Primary entry point: Decodes raw QR Code string payload from a bank slip
  static QrSlipResult parseQrCodePayload(String rawPayload) {
    if (rawPayload.isEmpty) {
      return const QrSlipResult(success: false);
    }

    final clean = rawPayload.trim();

    // 1. EMVCo / PromptPay Standard Slip QR (Starts with 000201)
    if (clean.startsWith('000201') || clean.contains('000201')) {
      final startIndex = clean.indexOf('000201');
      final emvPayload = clean.substring(startIndex);
      final emvResult = _parseEmvCoPayload(emvPayload);
      if (emvResult.success) {
        return emvResult;
      }
    }

    // 2. Bank Slip Verification URL (e.g. https://.../slip?ref=...&amt=...)
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      final urlResult = _parseUrlPayload(clean);
      if (urlResult.success) {
        return urlResult;
      }
    }

    // 3. JSON-formatted QR Payload
    if (clean.startsWith('{') && clean.endsWith('}')) {
      try {
        final map = jsonDecode(clean) as Map<String, dynamic>;
        final amt = double.tryParse(map['amount']?.toString() ?? map['amt']?.toString() ?? '0') ?? 0.0;
        final ref = map['ref']?.toString() ?? map['refId']?.toString() ?? map['transRef']?.toString();
        final receiver = map['receiver']?.toString() ?? map['to']?.toString();
        if (amt > 0 || ref != null) {
          return QrSlipResult(
            success: true,
            amount: amt,
            refId: ref,
            receiverName: receiver,
            rawPayload: clean,
          );
        }
      } catch (_) {}
    }

    // 4. Explicit bank-delimited string format (e.g. KBANK|123456|AMOUNT:500.00)
    final explicitAmtMatch = RegExp(r'(?:AMOUNT|TOTAL|AMT|PRICE)[:\|=]\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)', caseSensitive: false).firstMatch(clean);
    if (explicitAmtMatch != null) {
      final amt = double.tryParse(explicitAmtMatch.group(1)!.replaceAll(',', '')) ?? 0.0;
      if (amt > 0) {
        return QrSlipResult(
          success: true,
          amount: amt,
          rawPayload: clean,
        );
      }
    }

    return const QrSlipResult(success: false);
  }

  /// Parses EMVCo Tag-Length-Value (TLV) payload
  static QrSlipResult _parseEmvCoPayload(String payload) {
    try {
      final tlvMap = <String, String>{};
      int i = 0;

      while (i + 4 <= payload.length) {
        final tag = payload.substring(i, i + 2);
        final lengthStr = payload.substring(i + 2, i + 4);
        final length = int.tryParse(lengthStr);
        if (length == null || i + 4 + length > payload.length) {
          break;
        }
        final value = payload.substring(i + 4, i + 4 + length);
        tlvMap[tag] = value;
        i += 4 + length;
      }

      // Tag 54: Transaction Amount (e.g. 5406120.00 -> 120.00)
      double amount = 0.0;
      if (tlvMap.containsKey('54')) {
        final amtStr = tlvMap['54']!.replaceAll(',', '').trim();
        amount = double.tryParse(amtStr) ?? 0.0;
      }

      // Tag 59: Merchant / Receiver Name
      String? receiverName = tlvMap['59'];

      // Tag 62: Additional Data (Sub-tags: 05 Reference ID, 07 Terminal ID)
      String? refId;
      if (tlvMap.containsKey('62')) {
        final additionalData = tlvMap['62']!;
        int j = 0;
        while (j + 4 <= additionalData.length) {
          final subTag = additionalData.substring(j, j + 2);
          final subLen = int.tryParse(additionalData.substring(j + 2, j + 4)) ?? 0;
          if (j + 4 + subLen > additionalData.length) break;
          final subVal = additionalData.substring(j + 4, j + 4 + subLen);
          if (subTag == '05' || subTag == '07' || subTag == '01') {
            refId = subVal;
          }
          j += 4 + subLen;
        }
      }

      // Tag 29 / 30 / 31: PromptPay Target (Phone / Tax ID / e-Wallet)
      String? promptPayTarget;
      for (final tag in ['29', '30', '31']) {
        if (tlvMap.containsKey(tag)) {
          final val = tlvMap[tag]!;
          promptPayTarget = val;
          break;
        }
      }

      // Extract Sending Bank Code
      // In ITMX / Thai QR standard, Sub-tag 01 with length 3 indicates the 3-digit BOT bank code ('0103' + code)
      String? senderBankCode;
      String? senderBank;

      final bankSubTagMatch = RegExp(r'0103(002|004|006|011|014|022|024|025|030|033|034|066|067|069|073)').firstMatch(payload);
      if (bankSubTagMatch != null) {
        senderBankCode = bankSubTagMatch.group(1);
        senderBank = mapBankCodeToName(senderBankCode);
      }

      if (senderBankCode == null) {
        for (final tag in ['00', '30', '31']) {
          if (tlvMap.containsKey(tag)) {
            final data = tlvMap[tag]!;
            final m = RegExp(r'0103(002|004|006|011|014|022|024|025|030|033|034|066|067|069|073)').firstMatch(data);
            if (m != null) {
              senderBankCode = m.group(1);
              senderBank = mapBankCodeToName(senderBankCode);
              break;
            }
          }
        }
      }

      // Check for explicit iBank brand indicators ONLY if bank was not already determined
      if (senderBank == null &&
          (payload.toLowerCase().contains('ibank') ||
           payload.toLowerCase().contains('islamic bank') ||
           payload.contains('ธนาคารอิสลาม') ||
           payload.contains('0103066'))) {
        senderBankCode = '066';
        senderBank = 'ธนาคารอิสลามแห่งประเทศไทย';
      }

      // Only valid slip QR if there is an explicit amount > 0, transaction reference ID, or recognized sending bank code
      if (amount > 0 || (refId != null && refId.isNotEmpty) || (senderBankCode != null && senderBankCode.isNotEmpty)) {
        return QrSlipResult(
          success: true,
          amount: amount,
          refId: refId,
          receiverName: receiverName,
          receiverPromptPay: promptPayTarget,
          senderBank: senderBank,
          senderBankCode: senderBankCode,
          rawPayload: payload,
        );
      }
    } catch (_) {}

    return const QrSlipResult(success: false);
  }

  /// Parses URL parameters for slip verification payloads
  static QrSlipResult _parseUrlPayload(String urlStr) {
    try {
      final uri = Uri.parse(urlStr);
      final params = uri.queryParameters;

      double amount = 0.0;
      for (final key in ['amount', 'amt', 'total', 'price', 'val']) {
        if (params.containsKey(key)) {
          amount = double.tryParse(params[key]!.replaceAll(',', '')) ?? 0.0;
          if (amount > 0) break;
        }
      }

      String? refId;
      for (final key in ['ref', 'refId', 'transRef', 'txId', 'id', 'reference']) {
        if (params.containsKey(key)) {
          refId = params[key];
          break;
        }
      }

      String? bank;
      if (urlStr.contains('kplus') || urlStr.contains('kasikornbank')) {
        bank = 'กสิกรไทย (K PLUS)';
      } else if (urlStr.contains('scb')) {
        bank = 'ไทยพาณิชย์ (SCB EASY)';
      } else if (urlStr.contains('krungthai') || urlStr.contains('ktb')) {
        bank = 'กรุงไทย (Krungthai NEXT)';
      } else if (urlStr.contains('truemoney')) {
        bank = 'TrueMoney Wallet';
      } else if (urlStr.contains('ibank')) {
        bank = 'iBank (อิสลามแห่งประเทศไทย)';
      }

      if (amount > 0 || refId != null) {
        return QrSlipResult(
          success: true,
          amount: amount,
          refId: refId,
          senderBank: bank,
          rawPayload: urlStr,
        );
      }
    } catch (_) {}

    return const QrSlipResult(success: false);
  }

  /// Converts a successful QR Result into SlipExtractResult
  static SlipExtractResult toSlipExtractResult({
    required QrSlipResult qrResult,
    required List<CategoryItem> categories,
    String? fallbackBank,
  }) {
    final bank = qrResult.senderBank ?? fallbackBank ?? 'พร้อมเพย์ / ธนาคาร';
    final receiver = qrResult.receiverName ?? qrResult.receiverPromptPay ?? 'ผู้รับเงิน';
    final ref = qrResult.refId ?? 'QR-${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}';

    return SlipExtractResult(
      senderName: 'บัญชีของฉัน',
      senderBank: bank,
      senderAccount: '-',
      receiverName: receiver,
      receiverBank: 'พร้อมเพย์',
      receiverAccount: qrResult.receiverPromptPay ?? '-',
      amount: qrResult.amount,
      dateTime: DateTime.now(),
      refId: ref,
      memo: 'สแกน QR Code จากสลิป ($bank)',
      rawOcrText: 'QR Code Payload: ${qrResult.rawPayload ?? ""}',
      confidenceScore: 0.99,
      suggestedType: TransactionType.expense,
      suggestedCategoryName: categories.isNotEmpty ? categories.first.name : 'อาหาร & เครื่องดื่ม',
    );
  }
}
