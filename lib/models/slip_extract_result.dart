import 'transaction_item.dart';

class SlipExtractResult {
  final String senderName;
  final String senderBank;
  final String senderAccount;
  final String receiverName;
  final String receiverBank;
  final String receiverAccount;
  final double amount;
  final DateTime dateTime;
  final String refId;
  final String? memo;
  final String rawOcrText;
  final double confidenceScore;
  final TransactionType suggestedType;
  final IncomeStreamType? suggestedIncomeStream;
  final ExpenseCategoryType? suggestedExpenseCategory;
  final TaxDeductibleType suggestedTaxType;
  final bool isTaxDeductible;
  final String suggestedCategoryName;
  final bool isSelfTransfer;

  SlipExtractResult({
    required this.senderName,
    required this.senderBank,
    required this.senderAccount,
    required this.receiverName,
    required this.receiverBank,
    required this.receiverAccount,
    required this.amount,
    required this.dateTime,
    required this.refId,
    this.memo,
    required this.rawOcrText,
    this.confidenceScore = 0.98,
    this.suggestedType = TransactionType.expense,
    this.suggestedIncomeStream,
    this.suggestedExpenseCategory,
    this.suggestedTaxType = TaxDeductibleType.none,
    this.isTaxDeductible = false,
    this.suggestedCategoryName = 'ทั่วไป',
    this.isSelfTransfer = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'senderName': senderName,
      'senderBank': senderBank,
      'senderAccount': senderAccount,
      'receiverName': receiverName,
      'receiverBank': receiverBank,
      'receiverAccount': receiverAccount,
      'amount': amount,
      'dateTime': dateTime.toIso8601String(),
      'refId': refId,
      'memo': memo,
      'rawOcrText': rawOcrText,
      'confidenceScore': confidenceScore,
      'suggestedType': suggestedType.name,
      'suggestedIncomeStream': suggestedIncomeStream?.name,
      'suggestedExpenseCategory': suggestedExpenseCategory?.name,
      'suggestedTaxType': suggestedTaxType.name,
      'isTaxDeductible': isTaxDeductible,
    };
  }

  factory SlipExtractResult.fromJson(Map<String, dynamic> json) {
    return SlipExtractResult(
      senderName: json['senderName'] as String,
      senderBank: json['senderBank'] as String,
      senderAccount: json['senderAccount'] as String,
      receiverName: json['receiverName'] as String,
      receiverBank: json['receiverBank'] as String,
      receiverAccount: json['receiverAccount'] as String,
      amount: (json['amount'] as num).toDouble(),
      dateTime: DateTime.parse(json['dateTime'] as String),
      refId: json['refId'] as String,
      memo: json['memo'] as String?,
      rawOcrText: json['rawOcrText'] as String,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.95,
      suggestedType: TransactionType.values.byName(json['suggestedType'] as String),
      suggestedIncomeStream: json['suggestedIncomeStream'] != null
          ? IncomeStreamType.values.byName(json['suggestedIncomeStream'] as String)
          : null,
      suggestedExpenseCategory: json['suggestedExpenseCategory'] != null
          ? ExpenseCategoryType.values.byName(json['suggestedExpenseCategory'] as String)
          : null,
      suggestedTaxType: json['suggestedTaxType'] != null
          ? TaxDeductibleType.values.byName(json['suggestedTaxType'] as String)
          : TaxDeductibleType.none,
      isTaxDeductible: json['isTaxDeductible'] as bool? ?? false,
    );
  }
}
