class TaxBracketResult {
  final String range;
  final double minIncome;
  final double maxIncome;
  final double rate;
  final double taxableInThisBracket;
  final double taxAmount;

  TaxBracketResult({
    required this.range,
    required this.minIncome,
    required this.maxIncome,
    required this.rate,
    required this.taxableInThisBracket,
    required this.taxAmount,
  });
}

class TaxCalculationResult {
  final double grossIncome;
  final double standardExpenseDeduction; // 50% max 100k
  final double personalDeduction;        // 60,000
  final double totalAllowableDeductions;
  final double netTaxableIncome;
  final double totalEstimatedTax;
  final double effectiveTaxRate;
  final List<TaxBracketResult> bracketBreakdowns;
  final double potentialTaxSavings;
  final List<String> taxSavingTips;

  TaxCalculationResult({
    required this.grossIncome,
    required this.standardExpenseDeduction,
    required this.personalDeduction,
    required this.totalAllowableDeductions,
    required this.netTaxableIncome,
    required this.totalEstimatedTax,
    required this.effectiveTaxRate,
    required this.bracketBreakdowns,
    required this.potentialTaxSavings,
    required this.taxSavingTips,
  });
}

class TaxProfile {
  final double annualSalaryIncome;
  final double annualFreelanceIncome;
  final double annualEcommerceIncome;
  final double annualAffiliateIncome;
  final double annualInvestmentIncome;
  final double annualOtherIncome;

  // Deductions
  final bool hasSpouseNoIncome;       // 60,000
  final int childCount;               // 30,000 each (60,000 for 2nd child onwards born after 2018)
  final int parentCareCount;          // 30,000 per parent
  final double socialSecurityPaid;    // max 9,000
  final double lifeInsurancePaid;     // max 100,000 (life + health, health max 25k)
  final double healthInsurancePaid;   // included in life max 25,000
  final double pvdRmfSsfPaid;         // max 500,000 combined
  final double thaiEsgPaid;           // max 300,000
  final double easyEReceiptPaid;      // max 50,000
  final double mortgageInterestPaid;  // max 100,000
  final double educationDonationPaid; // 2x max 10%
  final double generalDonationPaid;   // 1x max 10%

  TaxProfile({
    this.annualSalaryIncome = 0.0,
    this.annualFreelanceIncome = 0.0,
    this.annualEcommerceIncome = 0.0,
    this.annualAffiliateIncome = 0.0,
    this.annualInvestmentIncome = 0.0,
    this.annualOtherIncome = 0.0,
    this.hasSpouseNoIncome = false,
    this.childCount = 0,
    this.parentCareCount = 0,
    this.socialSecurityPaid = 9000.0,
    this.lifeInsurancePaid = 0.0,
    this.healthInsurancePaid = 0.0,
    this.pvdRmfSsfPaid = 0.0,
    this.thaiEsgPaid = 0.0,
    this.easyEReceiptPaid = 0.0,
    this.mortgageInterestPaid = 0.0,
    this.educationDonationPaid = 0.0,
    this.generalDonationPaid = 0.0,
  });

  double get totalGrossIncome =>
      annualSalaryIncome +
      annualFreelanceIncome +
      annualEcommerceIncome +
      annualAffiliateIncome +
      annualInvestmentIncome +
      annualOtherIncome;

  TaxCalculationResult calculate() {
    final gross = totalGrossIncome;

    // Standard expense deduction: 50% max 100,000 THB for 40(1) and 40(2)
    final standardExpense = (gross * 0.50).clamp(0.0, 100000.0);

    // Personal allowances
    double deductions = 60000.0; // Personal deduction
    if (hasSpouseNoIncome) deductions += 60000.0;
    deductions += childCount * 30000.0;
    deductions += (parentCareCount.clamp(0, 4)) * 30000.0;

    // Insurance & Social Security
    deductions += socialSecurityPaid.clamp(0.0, 9000.0);
    final lifeHealthTotal = (lifeInsurancePaid + healthInsurancePaid.clamp(0.0, 25000.0))
        .clamp(0.0, 100000.0);
    deductions += lifeHealthTotal;

    // Retirement & ESG Funds
    deductions += pvdRmfSsfPaid.clamp(0.0, 500000.0);
    deductions += thaiEsgPaid.clamp(0.0, 300000.0);

    // Other deductions
    deductions += easyEReceiptPaid.clamp(0.0, 50000.0);
    deductions += mortgageInterestPaid.clamp(0.0, 100000.0);

    // Income before donation
    final incomeBeforeDonations = (gross - standardExpense - deductions).clamp(0.0, double.infinity);

    // Donations capped at 10% of remaining income
    final maxDonationAllowance = incomeBeforeDonations * 0.10;
    final totalDonationClaim = (educationDonationPaid * 2.0 + generalDonationPaid)
        .clamp(0.0, maxDonationAllowance);

    final netTaxable = (incomeBeforeDonations - totalDonationClaim).clamp(0.0, double.infinity);

    // Thai Progressive Tax Brackets (2025/2026)
    final brackets = [
      {'min': 0.0, 'max': 150000.0, 'rate': 0.0, 'label': '0 - 150,000 (0%)'},
      {'min': 150000.0, 'max': 300000.0, 'rate': 0.05, 'label': '150,001 - 300,000 (5%)'},
      {'min': 300000.0, 'max': 500000.0, 'rate': 0.10, 'label': '300,001 - 500,000 (10%)'},
      {'min': 500000.0, 'max': 750000.0, 'rate': 0.15, 'label': '500,001 - 750,000 (15%)'},
      {'min': 750000.0, 'max': 1000000.0, 'rate': 0.20, 'label': '750,001 - 1,000,000 (20%)'},
      {'min': 1000000.0, 'max': 2000000.0, 'rate': 0.25, 'label': '1,000,001 - 2,000,000 (25%)'},
      {'min': 2000000.0, 'max': 5000000.0, 'rate': 0.30, 'label': '2,000,001 - 5,000,000 (30%)'},
      {'min': 5000000.0, 'max': double.infinity, 'rate': 0.35, 'label': '5,000,001 ขึ้นไป (35%)'},
    ];

    double totalTax = 0.0;
    final List<TaxBracketResult> bracketResults = [];

    for (final b in brackets) {
      final bMin = b['min'] as double;
      final bMax = b['max'] as double;
      final rate = b['rate'] as double;
      final label = b['label'] as String;

      if (netTaxable > bMin) {
        final taxableInBracket = (netTaxable > bMax ? bMax : netTaxable) - bMin;
        final tax = taxableInBracket * rate;
        totalTax += tax;

        bracketResults.add(TaxBracketResult(
          range: label,
          minIncome: bMin,
          maxIncome: bMax,
          rate: rate,
          taxableInThisBracket: taxableInBracket,
          taxAmount: tax,
        ));
      }
    }

    final effectiveRate = gross > 0 ? (totalTax / gross) * 100 : 0.0;

    // AI Tax Optimization suggestions
    final List<String> tips = [];
    if (easyEReceiptPaid < 50000) {
      tips.add('ยังใช้สิทธิ์ Easy E-Receipt ได้อีก ${(50000 - easyEReceiptPaid).toStringAsFixed(0)} บาท');
    }
    if (thaiEsgPaid < 300000) {
      tips.add('สามารถลงทุน Thai ESG เพิ่มเพื่อลดหย่อนภาษีได้สูงสุดอีก ${(30000 - thaiEsgPaid).clamp(0, 300000).toStringAsFixed(0)} บาท');
    }
    if (lifeInsurancePaid < 100000) {
      tips.add('ใช้สิทธิ์ประกันชีวิต/สุขภาพ เพิ่มได้อีก ${(100000 - lifeInsurancePaid).toStringAsFixed(0)} บาท');
    }
    if (tips.isEmpty) {
      tips.add('คุณบริหารและใช้สิทธิ์ลดหย่อนภาษีได้อย่างคุ้มค่าครบถ้วนแล้ว!');
    }

    return TaxCalculationResult(
      grossIncome: gross,
      standardExpenseDeduction: standardExpense,
      personalDeduction: 60000.0,
      totalAllowableDeductions: deductions + totalDonationClaim,
      netTaxableIncome: netTaxable,
      totalEstimatedTax: totalTax,
      effectiveTaxRate: effectiveRate,
      bracketBreakdowns: bracketResults,
      potentialTaxSavings: (gross * 0.15) - totalTax,
      taxSavingTips: tips,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'annualSalaryIncome': annualSalaryIncome,
      'annualFreelanceIncome': annualFreelanceIncome,
      'annualEcommerceIncome': annualEcommerceIncome,
      'annualAffiliateIncome': annualAffiliateIncome,
      'annualInvestmentIncome': annualInvestmentIncome,
      'annualOtherIncome': annualOtherIncome,
      'hasSpouseNoIncome': hasSpouseNoIncome,
      'childCount': childCount,
      'parentCareCount': parentCareCount,
      'socialSecurityPaid': socialSecurityPaid,
      'lifeInsurancePaid': lifeInsurancePaid,
      'healthInsurancePaid': healthInsurancePaid,
      'pvdRmfSsfPaid': pvdRmfSsfPaid,
      'thaiEsgPaid': thaiEsgPaid,
      'easyEReceiptPaid': easyEReceiptPaid,
      'mortgageInterestPaid': mortgageInterestPaid,
      'educationDonationPaid': educationDonationPaid,
      'generalDonationPaid': generalDonationPaid,
    };
  }

  factory TaxProfile.fromJson(Map<String, dynamic> json) {
    return TaxProfile(
      annualSalaryIncome: (json['annualSalaryIncome'] as num?)?.toDouble() ?? 0.0,
      annualFreelanceIncome: (json['annualFreelanceIncome'] as num?)?.toDouble() ?? 0.0,
      annualEcommerceIncome: (json['annualEcommerceIncome'] as num?)?.toDouble() ?? 0.0,
      annualAffiliateIncome: (json['annualAffiliateIncome'] as num?)?.toDouble() ?? 0.0,
      annualInvestmentIncome: (json['annualInvestmentIncome'] as num?)?.toDouble() ?? 0.0,
      annualOtherIncome: (json['annualOtherIncome'] as num?)?.toDouble() ?? 0.0,
      hasSpouseNoIncome: json['hasSpouseNoIncome'] as bool? ?? false,
      childCount: json['childCount'] as int? ?? 0,
      parentCareCount: json['parentCareCount'] as int? ?? 0,
      socialSecurityPaid: (json['socialSecurityPaid'] as num?)?.toDouble() ?? 9000.0,
      lifeInsurancePaid: (json['lifeInsurancePaid'] as num?)?.toDouble() ?? 0.0,
      healthInsurancePaid: (json['healthInsurancePaid'] as num?)?.toDouble() ?? 0.0,
      pvdRmfSsfPaid: (json['pvdRmfSsfPaid'] as num?)?.toDouble() ?? 0.0,
      thaiEsgPaid: (json['thaiEsgPaid'] as num?)?.toDouble() ?? 0.0,
      easyEReceiptPaid: (json['easyEReceiptPaid'] as num?)?.toDouble() ?? 0.0,
      mortgageInterestPaid: (json['mortgageInterestPaid'] as num?)?.toDouble() ?? 0.0,
      educationDonationPaid: (json['educationDonationPaid'] as num?)?.toDouble() ?? 0.0,
      generalDonationPaid: (json['generalDonationPaid'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
