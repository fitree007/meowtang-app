import 'dart:convert';

class SalaryAutoRecordConfig {
  final bool isEnabled;
  final double amount;
  final int dayOfMonth; // 1 to 31
  final bool isLastDayOfMonth;
  final String accountId;
  final String categoryId;
  final String note;
  final String? lastRecordedMonth; // e.g. '2026-09'
  final DateTime? lastRecordedDate;
  final bool notifyUser;

  const SalaryAutoRecordConfig({
    this.isEnabled = false,
    this.amount = 0.0,
    this.dayOfMonth = 25,
    this.isLastDayOfMonth = false,
    this.accountId = 'acc_kbank',
    this.categoryId = 'cat_salary',
    this.note = 'เงินเดือนประจำเดือน',
    this.lastRecordedMonth,
    this.lastRecordedDate,
    this.notifyUser = true,
  });

  SalaryAutoRecordConfig copyWith({
    bool? isEnabled,
    double? amount,
    int? dayOfMonth,
    bool? isLastDayOfMonth,
    String? accountId,
    String? categoryId,
    String? note,
    String? lastRecordedMonth,
    DateTime? lastRecordedDate,
    bool? notifyUser,
  }) {
    return SalaryAutoRecordConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      amount: amount ?? this.amount,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      isLastDayOfMonth: isLastDayOfMonth ?? this.isLastDayOfMonth,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      lastRecordedMonth: lastRecordedMonth ?? this.lastRecordedMonth,
      lastRecordedDate: lastRecordedDate ?? this.lastRecordedDate,
      notifyUser: notifyUser ?? this.notifyUser,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'amount': amount,
      'dayOfMonth': dayOfMonth,
      'isLastDayOfMonth': isLastDayOfMonth,
      'accountId': accountId,
      'categoryId': categoryId,
      'note': note,
      'lastRecordedMonth': lastRecordedMonth,
      'lastRecordedDate': lastRecordedDate?.toIso8601String(),
      'notifyUser': notifyUser,
    };
  }

  factory SalaryAutoRecordConfig.fromMap(Map<String, dynamic> map) {
    return SalaryAutoRecordConfig(
      isEnabled: map['isEnabled'] as bool? ?? false,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      dayOfMonth: (map['dayOfMonth'] as num?)?.toInt() ?? 25,
      isLastDayOfMonth: map['isLastDayOfMonth'] as bool? ?? false,
      accountId: map['accountId'] as String? ?? 'acc_kbank',
      categoryId: map['categoryId'] as String? ?? 'cat_salary',
      note: map['note'] as String? ?? 'เงินเดือนประจำเดือน',
      lastRecordedMonth: map['lastRecordedMonth'] as String?,
      lastRecordedDate: map['lastRecordedDate'] != null
          ? DateTime.tryParse(map['lastRecordedDate'] as String)
          : null,
      notifyUser: map['notifyUser'] as bool? ?? true,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory SalaryAutoRecordConfig.fromJson(String source) {
    try {
      final map = jsonDecode(source) as Map<String, dynamic>;
      return SalaryAutoRecordConfig.fromMap(map);
    } catch (_) {
      return const SalaryAutoRecordConfig();
    }
  }
}
