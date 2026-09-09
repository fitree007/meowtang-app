enum TransactionType {
  income,
  expense,
  transfer,
}

enum IncomeStreamType {
  salary,
  freelanceGig,
  ecommerce,
  affiliate,
  investment,
  other,
}

enum ExpenseCategoryType {
  housingRent,
  utilitiesBills,
  softwareTools,
  equipmentAssets,
  foodDining,
  travelTransport,
  shopping,
  general,
}

enum TaxDeductibleType {
  none,
  easyEReceipt,
  socialSecurity,
  lifeInsurance,
  ssfRmfThaiEsg,
  donation2x,
  donationGeneral,
}

class TransactionItem {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String accountId;
  final String? targetAccountId; // For transfer
  final String categoryId;
  final String categoryName;
  final String? note;
  final String? senderName;
  final String? receiverName;
  final String? bankName;
  final String? slipRefId;
  final String? slipImageUrl;
  final String? rawOcrText;
  final String? projectId;
  final IncomeStreamType? incomeStream;
  final TaxDeductibleType taxType;
  final bool isTaxDeductible;
  final double taxDeductibleAmount;
  final List<String> tags;
  final bool isRecurring;
  final String? recurrenceFrequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime? recurrenceEndDate;
  final String? parentRecurringId;

  TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    required this.accountId,
    this.targetAccountId,
    required this.categoryId,
    required this.categoryName,
    this.note,
    this.senderName,
    this.receiverName,
    this.bankName,
    this.slipRefId,
    this.slipImageUrl,
    this.rawOcrText,
    this.projectId,
    this.incomeStream,
    this.taxType = TaxDeductibleType.none,
    this.isTaxDeductible = false,
    this.taxDeductibleAmount = 0.0,
    this.tags = const [],
    this.isRecurring = false,
    this.recurrenceFrequency,
    this.recurrenceEndDate,
    this.parentRecurringId,
  });

  String get categoryDisplayName => categoryName;

  /// Returns clean user-written note, stripping any automated legacy metadata
  String? get cleanNote {
    if (note == null || note!.trim().isEmpty) return null;
    var clean = note!.trim();
    if (clean.startsWith('โอนเงินผ่าน') || clean.startsWith('สลิป:')) {
      return null;
    }
    if (clean.contains('ผู้โอน:') || clean.contains('ผู้รับ:')) {
      if (clean.contains('| บันทึก:')) {
        final parts = clean.split('| บันทึก:');
        clean = parts.last.trim();
      } else {
        return null;
      }
    }
    return clean.isEmpty ? null : clean;
  }

  /// Returns human-readable transfer details from slip: โอนจาก [ผู้โอน] ➔ [ผู้รับ]
  String? get slipTransferDescription {
    String? s = senderName?.trim();
    String? r = receiverName?.trim();

    if (s == 'ไม่ระบุผู้โอน' || s == 'ไม่ระบุ') s = null;
    if (r == 'ไม่ระบุผู้รับ' || r == 'ไม่ระบุ') r = null;

    // Check legacy note for extracted sender/receiver
    if ((s == null || r == null) && note != null && note!.contains('ผู้โอน:')) {
      final match = RegExp(r'ผู้โอน:\s*([^\s|]+(?:\s+[^\s|]+)?)\s*ผู้รับ:\s*([^\s|]+(?:\s+[^\s|]+)?)').firstMatch(note!);
      if (match != null) {
        final extS = match.group(1)?.trim();
        final extR = match.group(2)?.trim();
        if (extS != null && extS != 'ไม่ระบุผู้โอน' && extS != 'ไม่ระบุ') s ??= extS;
        if (extR != null && extR != 'ไม่ระบุผู้รับ' && extR != 'ไม่ระบุ') r ??= extR;
      }
    }

    // Check title if it contains sender/receiver
    if ((s == null || r == null) && title.contains('โอนให้')) {
      final parts = title.split('โอนให้');
      if (parts.length == 2) {
        final part0 = parts[0].trim();
        final part1 = parts[1].trim();
        if (part0.isNotEmpty && !part0.startsWith('โอน')) s ??= part0;
        if (part1.isNotEmpty) r ??= part1;
      }
    }

    String _sanitizePartyName(String name) {
      var n = name.trim();
      n = n.replaceAll(RegExp(r'^[•|~_<>*^\\/#@\s]+|[•|~_<>*^\\/#@\s]+$'), '');
      if (RegExp(r'[\u0E00-\u0E7F]').hasMatch(n) && RegExp(r'[a-zA-Z]').hasMatch(n)) {
        if (n.contains('/') || n.contains('|')) {
          final parts = n.split(RegExp(r'[/|]'));
          for (final p in parts) {
            if (RegExp(r'[\u0E00-\u0E7F]').hasMatch(p) && p.trim().length >= 2) {
              n = p.trim();
              break;
            }
          }
        }
        final engTitleMatch = RegExp(r'\s+(?:MR|MRS|MS|MISS)\.?\s+.*$', caseSensitive: false).firstMatch(n);
        if (engTitleMatch != null) {
          n = n.substring(0, engTitleMatch.start).trim();
        } else {
          final thaiThenEngMatch = RegExp(r'^([\u0E00-\u0E7F\s.]+?)\s+[A-Za-z\s.]+$').firstMatch(n);
          if (thaiThenEngMatch != null && thaiThenEngMatch.group(1)!.trim().length >= 3) {
            n = thaiThenEngMatch.group(1)!.trim();
          }
        }
      }
      return n.trim();
    }

    if (s != null && s.isNotEmpty) s = _sanitizePartyName(s);
    if (r != null && r.isNotEmpty) r = _sanitizePartyName(r);

    if (s != null && s.isNotEmpty && r != null && r.isNotEmpty) {
      return 'โอนจาก $s ➔ $r';
    } else if (r != null && r.isNotEmpty) {
      return 'โอนไปยัง $r';
    } else if (s != null && s.isNotEmpty) {
      return 'โอนโดย $s';
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'date': date.toIso8601String(),
      'accountId': accountId,
      'targetAccountId': targetAccountId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'note': note,
      'senderName': senderName,
      'receiverName': receiverName,
      'bankName': bankName,
      'slipRefId': slipRefId,
      'slipImageUrl': slipImageUrl,
      'rawOcrText': rawOcrText,
      'projectId': projectId,
      'incomeStream': incomeStream?.name,
      'taxType': taxType.name,
      'isTaxDeductible': isTaxDeductible,
      'taxDeductibleAmount': taxDeductibleAmount,
      'tags': tags,
      'isRecurring': isRecurring,
      'recurrenceFrequency': recurrenceFrequency,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'parentRecurringId': parentRecurringId,
    };
  }

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    TransactionType txType = TransactionType.expense;
    final typeStr = json['type']?.toString().toLowerCase() ?? 'expense';
    if (typeStr == 'income') {
      txType = TransactionType.income;
    } else if (typeStr == 'transfer') {
      txType = TransactionType.transfer;
    }

    DateTime txDate = DateTime.now();
    if (json['date'] != null) {
      txDate = DateTime.tryParse(json['date'].toString()) ?? DateTime.now();
    }

    DateTime? recEndDate;
    if (json['recurrenceEndDate'] != null) {
      recEndDate = DateTime.tryParse(json['recurrenceEndDate'].toString());
    }

    final amt = double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0;

    return TransactionItem(
      id: json['id']?.toString() ?? 'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? '',
      amount: amt,
      type: txType,
      date: txDate,
      accountId: json['accountId']?.toString() ?? '',
      targetAccountId: json['targetAccountId']?.toString(),
      categoryId: json['categoryId']?.toString() ?? 'cat_other',
      categoryName: json['categoryName']?.toString() ?? 'ทั่วไป',
      note: json['note']?.toString(),
      senderName: json['senderName']?.toString(),
      receiverName: json['receiverName']?.toString(),
      bankName: json['bankName']?.toString(),
      slipRefId: json['slipRefId']?.toString(),
      slipImageUrl: json['slipImageUrl']?.toString(),
      rawOcrText: json['rawOcrText']?.toString(),
      projectId: json['projectId']?.toString(),
      incomeStream: json['incomeStream'] != null
          ? IncomeStreamType.values.byName(json['incomeStream'].toString())
          : null,
      taxType: json['taxType'] != null
          ? TaxDeductibleType.values.byName(json['taxType'].toString())
          : TaxDeductibleType.none,
      isTaxDeductible: json['isTaxDeductible'] as bool? ?? false,
      taxDeductibleAmount: double.tryParse(json['taxDeductibleAmount']?.toString() ?? '0') ?? 0.0,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurrenceFrequency: json['recurrenceFrequency']?.toString(),
      recurrenceEndDate: recEndDate,
      parentRecurringId: json['parentRecurringId']?.toString(),
    );
  }

  TransactionItem copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    DateTime? date,
    String? accountId,
    String? targetAccountId,
    String? categoryId,
    String? categoryName,
    String? note,
    String? senderName,
    String? receiverName,
    String? bankName,
    String? slipRefId,
    String? slipImageUrl,
    String? rawOcrText,
    List<String>? tags,
    bool? isRecurring,
    String? recurrenceFrequency,
    DateTime? recurrenceEndDate,
    String? parentRecurringId,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
      targetAccountId: targetAccountId ?? this.targetAccountId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      note: note ?? this.note,
      senderName: senderName ?? this.senderName,
      receiverName: receiverName ?? this.receiverName,
      bankName: bankName ?? this.bankName,
      slipRefId: slipRefId ?? this.slipRefId,
      slipImageUrl: slipImageUrl ?? this.slipImageUrl,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      tags: tags ?? this.tags,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceFrequency: recurrenceFrequency ?? this.recurrenceFrequency,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      parentRecurringId: parentRecurringId ?? this.parentRecurringId,
    );
  }
}
