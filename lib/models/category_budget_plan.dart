class CategoryBudgetPlan {
  final bool isEnabled;
  final String cycle; // 'daily', 'monthly', 'yearly', 'all'
  final double totalBudget;
  final Map<String, double> categoryBudgets;
  final int planDurationDays;
  final String? budgetMonthYear; // e.g. "2026-09"
  final DateTime? endDate; // Custom end date

  const CategoryBudgetPlan({
    this.isEnabled = false,
    this.cycle = 'monthly',
    this.totalBudget = 0.0,
    this.categoryBudgets = const {},
    this.planDurationDays = 30,
    this.budgetMonthYear,
    this.endDate,
  });

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'cycle': cycle,
        'totalBudget': totalBudget,
        'categoryBudgets': categoryBudgets,
        'planDurationDays': planDurationDays,
        'budgetMonthYear': budgetMonthYear,
        'endDate': endDate?.toIso8601String(),
      };

  factory CategoryBudgetPlan.fromJson(Map<String, dynamic> json) {
    final rawMap = json['categoryBudgets'] as Map<String, dynamic>? ?? {};
    final budgets = <String, double>{};
    rawMap.forEach((key, val) {
      if (val is num) {
        budgets[key] = val.toDouble();
      }
    });

    DateTime? parsedEndDate;
    if (json['endDate'] != null) {
      try {
        parsedEndDate = DateTime.parse(json['endDate'].toString());
      } catch (_) {}
    }

    return CategoryBudgetPlan(
      isEnabled: json['isEnabled'] as bool? ?? false,
      cycle: json['cycle'] as String? ?? 'monthly',
      totalBudget: (json['totalBudget'] as num?)?.toDouble() ?? (json['monthlySalary'] as num?)?.toDouble() ?? 0.0,
      categoryBudgets: budgets,
      planDurationDays: (json['planDurationDays'] as num?)?.toInt() ?? 30,
      budgetMonthYear: json['budgetMonthYear'] as String?,
      endDate: parsedEndDate,
    );
  }

  double get totalAllocated {
    return categoryBudgets.values.fold(0.0, (sum, val) => sum + val);
  }

  double get unallocatedAmount {
    return (totalBudget - totalAllocated).clamp(0.0, double.infinity);
  }

  CategoryBudgetPlan copyWith({
    bool? isEnabled,
    String? cycle,
    double? totalBudget,
    Map<String, double>? categoryBudgets,
    int? planDurationDays,
    String? budgetMonthYear,
    DateTime? endDate,
  }) {
    return CategoryBudgetPlan(
      isEnabled: isEnabled ?? this.isEnabled,
      cycle: cycle ?? this.cycle,
      totalBudget: totalBudget ?? this.totalBudget,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      planDurationDays: planDurationDays ?? this.planDurationDays,
      budgetMonthYear: budgetMonthYear ?? this.budgetMonthYear,
      endDate: endDate ?? this.endDate,
    );
  }
}
