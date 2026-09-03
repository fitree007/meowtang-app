import 'package:flutter/material.dart';

class ProjectBudget {
  final String id;
  final String name;
  final String description;
  final double budgetCap;
  final double spentAmount;
  final DateTime startDate;
  final DateTime endDate;
  final int colorValue;
  final bool isGrant;
  final String? grantAgency;
  final Map<String, double> categoryLimits; // e.g. {'equipment': 50000, 'travel': 20000}
  final bool isArchived;

  ProjectBudget({
    required this.id,
    required this.name,
    required this.description,
    required this.budgetCap,
    this.spentAmount = 0.0,
    required this.startDate,
    required this.endDate,
    required this.colorValue,
    this.isGrant = false,
    this.grantAgency,
    this.categoryLimits = const {},
    this.isArchived = false,
  });

  Color get color => Color(colorValue);

  double get remainingBudget => budgetCap - spentAmount;
  double get percentUsed => budgetCap > 0 ? (spentAmount / budgetCap).clamp(0.0, 1.0) : 0.0;
  bool get isOverBudget => spentAmount > budgetCap;
  bool get isNearLimit => percentUsed >= 0.85 && !isOverBudget;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'budgetCap': budgetCap,
      'spentAmount': spentAmount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'colorValue': colorValue,
      'isGrant': isGrant,
      'grantAgency': grantAgency,
      'categoryLimits': categoryLimits,
      'isArchived': isArchived,
    };
  }

  factory ProjectBudget.fromJson(Map<String, dynamic> json) {
    return ProjectBudget(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      budgetCap: (json['budgetCap'] as num).toDouble(),
      spentAmount: (json['spentAmount'] as num?)?.toDouble() ?? 0.0,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      colorValue: json['colorValue'] as int,
      isGrant: json['isGrant'] as bool? ?? false,
      grantAgency: json['grantAgency'] as String?,
      categoryLimits: (json['categoryLimits'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          {},
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }

  ProjectBudget copyWith({
    String? id,
    String? name,
    String? description,
    double? budgetCap,
    double? spentAmount,
    DateTime? startDate,
    DateTime? endDate,
    int? colorValue,
    bool? isGrant,
    String? grantAgency,
    Map<String, double>? categoryLimits,
    bool? isArchived,
  }) {
    return ProjectBudget(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      budgetCap: budgetCap ?? this.budgetCap,
      spentAmount: spentAmount ?? this.spentAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      colorValue: colorValue ?? this.colorValue,
      isGrant: isGrant ?? this.isGrant,
      grantAgency: grantAgency ?? this.grantAgency,
      categoryLimits: categoryLimits ?? this.categoryLimits,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
