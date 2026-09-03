import '../models/tax_profile.dart';
import '../models/transaction_item.dart';

class TaxCalculatorService {
  TaxProfile buildProfileFromTransactions(List<TransactionItem> transactions) {
    double salary = 0.0;
    double freelance = 0.0;
    double ecommerce = 0.0;
    double affiliate = 0.0;
    double investment = 0.0;
    double other = 0.0;

    double easyEReceipt = 0.0;
    double socialSecurity = 9000.0; // default standard
    double lifeInsurance = 0.0;
    double ssfRmf = 0.0;
    double donations = 0.0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        switch (tx.incomeStream) {
          case IncomeStreamType.salary:
            salary += tx.amount;
            break;
          case IncomeStreamType.freelanceGig:
            freelance += tx.amount;
            break;
          case IncomeStreamType.ecommerce:
            ecommerce += tx.amount;
            break;
          case IncomeStreamType.affiliate:
            affiliate += tx.amount;
            break;
          case IncomeStreamType.investment:
            investment += tx.amount;
            break;
          default:
            other += tx.amount;
            break;
        }
      } else if (tx.type == TransactionType.expense && tx.isTaxDeductible) {
        switch (tx.taxType) {
          case TaxDeductibleType.easyEReceipt:
            easyEReceipt += tx.amount;
            break;
          case TaxDeductibleType.socialSecurity:
            socialSecurity += tx.amount;
            break;
          case TaxDeductibleType.lifeInsurance:
            lifeInsurance += tx.amount;
            break;
          case TaxDeductibleType.ssfRmfThaiEsg:
            ssfRmf += tx.amount;
            break;
          case TaxDeductibleType.donation2x:
          case TaxDeductibleType.donationGeneral:
            donations += tx.amount;
            break;
          default:
            break;
        }
      }
    }

    // If transactions are sparse, provide realistic annual baseline
    if (salary + freelance + ecommerce + affiliate == 0.0) {
      salary = 420000.0; // ~35,000 / month
      freelance = 120000.0;
      affiliate = 60000.0;
      easyEReceipt = 15000.0;
      lifeInsurance = 25000.0;
      ssfRmf = 30000.0;
    }

    return TaxProfile(
      annualSalaryIncome: salary,
      annualFreelanceIncome: freelance,
      annualEcommerceIncome: ecommerce,
      annualAffiliateIncome: affiliate,
      annualInvestmentIncome: investment,
      annualOtherIncome: other,
      socialSecurityPaid: socialSecurity,
      easyEReceiptPaid: easyEReceipt,
      lifeInsurancePaid: lifeInsurance,
      pvdRmfSsfPaid: ssfRmf,
      educationDonationPaid: donations,
    );
  }
}
