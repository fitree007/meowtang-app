import 'dart:convert';

class GoalDepositLog {
 final String id;
 final DateTime date;
 final double amount;
 final String? note;

 GoalDepositLog({
  required this.id,
  required this.date,
  required this.amount,
  this.note,
 });

 Map<String, dynamic> toJson() => {
  'id': id,
  'date': date.toIso8601String(),
  'amount': amount,
  'note': note,
 };

 factory GoalDepositLog.fromJson(Map<String, dynamic> json) => GoalDepositLog(
  id: json['id'] as String? ?? '',
  date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
  amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
  note: json['note'] as String?,
 );
}

class SavingGoalItem {
 final String id;
 final String title;
 final double targetAmount;
 double currentAmount;
 final DateTime? targetDate;
 final String categoryEmoji;
 final int colorHex;
 bool isCompleted;
 final String? notes;
 final DateTime createdAt;
 final List<GoalDepositLog> depositHistory;
 /// How much the user plans to save per [planFrequency] period (null = no plan).
 final double? plannedAmount;
 /// 'day', 'week' or 'month'.
 final String planFrequency;

 SavingGoalItem({
  required this.id,
  required this.title,
  required this.targetAmount,
  this.currentAmount = 0.0,
  this.targetDate,
  this.categoryEmoji = '',
  this.colorHex = 0xFFF59E0B, // Default Amber/Gold
  this.isCompleted = false,
  this.notes,
  DateTime? createdAt,
  List<GoalDepositLog>? depositHistory,
  this.plannedAmount,
  this.planFrequency = 'month',
 }) : createdAt = createdAt ?? DateTime.now(),
    depositHistory = depositHistory ?? [];

 /// Days in one plan period.
 static double daysPerPeriod(String frequency) {
  switch (frequency) {
   case 'day':
    return 1;
   case 'week':
    return 7;
   default:
    return 30.4375;
  }
 }

 /// Saving periods left between [from] and [to], counting a started period as a whole one
 /// (calendar months for 'month').
 static int periodsBetween(DateTime from, DateTime to, String frequency) {
  final days = (to.difference(from).inHours / 24).ceil();
  switch (frequency) {
   case 'day':
    return days;
   case 'week':
    return (days / 7).ceil();
   default:
    var months = (to.year - from.year) * 12 + to.month - from.month;
    if (to.day < from.day) months -= 1;
    if (dateAfterPeriods(from, months, frequency).isBefore(to)) months += 1;
    return months;
  }
 }

 /// Amount needed per period to save [remaining] by [deadline].
 static double? requiredFor(double remaining, DateTime deadline, String frequency) {
  if (remaining <= 0) return null;
  final now = DateTime.now();
  if (!deadline.isAfter(now)) return null;
  final periods = periodsBetween(now, deadline, frequency);
  return remaining / (periods < 1 ? 1 : periods);
 }

 /// Amount needed per plan period to reach the target by [targetDate].
 double? get requiredPerPeriod {
  final date = targetDate;
  if (date == null) return null;
  return requiredFor(remainingAmount, date, planFrequency);
 }

 /// Estimated finish date when following [plannedAmount].
 DateTime? get projectedFinishDate {
  final plan = plannedAmount;
  if (plan == null || plan <= 0) return null;
  if (remainingAmount <= 0) return DateTime.now();
  return dateAfterPeriods(DateTime.now(), (remainingAmount / plan).ceil(), planFrequency);
 }

 static DateTime dateAfterPeriods(DateTime from, int periods, String frequency) {
  switch (frequency) {
   case 'day':
    return from.add(Duration(days: periods));
   case 'week':
    return from.add(Duration(days: periods * 7));
   default:
    final last = DateTime(from.year, from.month + periods + 1, 0).day;
    return DateTime(from.year, from.month + periods, from.day > last ? last : from.day);
  }
 }

 double get savedAmount => currentAmount;
 double get progress => progressRatio;

 double get progressRatio {
  if (targetAmount <= 0) return 1.0;
  return (currentAmount / targetAmount).clamp(0.0, 1.0);
 }

 double get progressPercentage {
  return (progressRatio * 100).clamp(0.0, 100.0);
 }

 double get remainingAmount {
  final rem = targetAmount - currentAmount;
  return rem < 0 ? 0 : rem;
 }

 int? get remainingDays {
  if (targetDate == null) return null;
  final diff = targetDate!.difference(DateTime.now()).inDays;
  return diff < 0 ? 0 : diff;
 }

 double? get requiredSavingsPerDay {
  final days = remainingDays;
  if (days == null || days <= 0 || remainingAmount <= 0) return null;
  return remainingAmount / days;
 }

 Map<String, dynamic> toJson() => {
  'id': id,
  'title': title,
  'targetAmount': targetAmount,
  'currentAmount': currentAmount,
  'targetDate': targetDate?.toIso8601String(),
  'categoryEmoji': categoryEmoji,
  'colorHex': colorHex,
  'isCompleted': isCompleted,
  'notes': notes,
  'createdAt': createdAt.toIso8601String(),
  'depositHistory': depositHistory.map((d) => d.toJson()).toList(),
  'plannedAmount': plannedAmount,
  'planFrequency': planFrequency,
 };

 factory SavingGoalItem.fromJson(Map<String, dynamic> json) => SavingGoalItem(
  id: json['id'] as String? ?? '',
  title: json['title'] as String? ?? 'เป้าหมายการออม',
  targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
  currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
  targetDate: json['targetDate'] != null
    ? DateTime.tryParse(json['targetDate'] as String)
    : null,
  categoryEmoji: json['categoryEmoji'] as String? ?? '',
  colorHex: json['colorHex'] as int? ?? 0xFFF59E0B,
  isCompleted: json['isCompleted'] as bool? ?? false,
  notes: json['notes'] as String?,
  createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  depositHistory: (json['depositHistory'] as List<dynamic>?)
      ?.map((e) => GoalDepositLog.fromJson(e as Map<String, dynamic>))
      .toList() ??
    [],
  plannedAmount: (json['plannedAmount'] as num?)?.toDouble(),
  planFrequency: json['planFrequency'] as String? ?? 'month',
 );

 static String encodeList(List<SavingGoalItem> list) =>
   jsonEncode(list.map((e) => e.toJson()).toList());

 static List<SavingGoalItem> decodeList(String jsonStr) {
  if (jsonStr.isEmpty) return [];
  try {
   final decoded = jsonDecode(jsonStr) as List<dynamic>;
   return decoded.map((e) => SavingGoalItem.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
   return [];
  }
 }

  SavingGoalItem copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? categoryEmoji,
    int? colorHex,
    bool? isCompleted,
    String? notes,
    DateTime? createdAt,
    List<GoalDepositLog>? depositHistory,
    double? plannedAmount,
    String? planFrequency,
    bool clearTargetDate = false,
    bool clearPlan = false,
  }) {
    return SavingGoalItem(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      plannedAmount: clearPlan ? null : (plannedAmount ?? this.plannedAmount),
      planFrequency: planFrequency ?? this.planFrequency,
      categoryEmoji: categoryEmoji ?? this.categoryEmoji,
      colorHex: colorHex ?? this.colorHex,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      depositHistory: depositHistory ?? this.depositHistory,
    );
  }
}
