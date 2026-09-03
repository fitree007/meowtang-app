import 'dart:math';
import '../models/transaction_item.dart';
import '../models/account_item.dart';

class ForecastDayPoint {
 final DateTime date;
 final double projectedBalance;
 final double projectedIncome;
 final double projectedExpense;
 final bool isDangerLow;
 final String? note;

 ForecastDayPoint({
  required this.date,
  required this.projectedBalance,
  required this.projectedIncome,
  required this.projectedExpense,
  this.isDangerLow = false,
  this.note,
 });
}

class RecurringBillItem {
 final String name;
 final double expectedAmount;
 final int dueDayOfMonth;
 final ExpenseCategoryType category;
 final String sourceAccount;

 RecurringBillItem({
  required this.name,
  required this.expectedAmount,
  required this.dueDayOfMonth,
  required this.category,
  required this.sourceAccount,
 });
}

class CashflowForecastResult {
 final double currentTotalBalance;
 final double projected30DaysBalance;
 final double projected60DaysBalance;
 final double projected90DaysBalance;
 final double estimatedMonthlyBurnRate;
 final double estimatedMonthlyIncome;
 final double netMonthlyCashFlow;
 final int runwayMonths;
 final bool hasLiquidityAlert;
 final String? alertMessage;
 final List<ForecastDayPoint> timeline;
 final List<RecurringBillItem> upcomingBills;
 final List<String> aiFinancialInsights;

 CashflowForecastResult({
  required this.currentTotalBalance,
  required this.projected30DaysBalance,
  required this.projected60DaysBalance,
  required this.projected90DaysBalance,
  required this.estimatedMonthlyBurnRate,
  required this.estimatedMonthlyIncome,
  required this.netMonthlyCashFlow,
  required this.runwayMonths,
  required this.hasLiquidityAlert,
  this.alertMessage,
  required this.timeline,
  required this.upcomingBills,
  required this.aiFinancialInsights,
 });
}

class CashflowForecastService {
 CashflowForecastResult generateForecast({
  required List<AccountItem> accounts,
  required List<TransactionItem> historyTransactions,
  int forecastDays = 60,
 }) {
  final currentTotal = accounts.fold(0.0, (sum, a) => sum + a.balance);

  // Calculate historical monthly averages
  final now = DateTime.now();
  final past30Days = now.subtract(const Duration(days: 30));

  double past30Expense = 0.0;
  double past30Income = 0.0;

  for (final tx in historyTransactions) {
   if (tx.date.isAfter(past30Days)) {
    if (tx.type == TransactionType.expense) {
     past30Expense += tx.amount;
    } else if (tx.type == TransactionType.income) {
     past30Income += tx.amount;
    }
   }
  }

  if (past30Expense == 0.0) past30Expense = 24500.0;
  if (past30Income == 0.0) past30Income = 38000.0;

  final dailyAvgExpense = past30Expense / 30.0;
  final dailyAvgIncome = past30Income / 30.0;

  // Recurring fixed bills
  final recurringBills = [
   RecurringBillItem(
    name: 'ค่าเช่าคอนโด / ที่พัก',
    expectedAmount: 12000.0,
    dueDayOfMonth: 1,
    category: ExpenseCategoryType.housingRent,
    sourceAccount: 'KBANK',
   ),
   RecurringBillItem(
    name: 'ค่าอินเทอร์เน็ต & มือถือ (AIS/True)',
    expectedAmount: 1299.0,
    dueDayOfMonth: 15,
    category: ExpenseCategoryType.utilitiesBills,
    sourceAccount: 'SCB',
   ),
   RecurringBillItem(
    name: 'Cloud & AI Subscriptions (Gemini/ChatGPT/Vercel)',
    expectedAmount: 2450.0,
    dueDayOfMonth: 18,
    category: ExpenseCategoryType.softwareTools,
    sourceAccount: 'KBANK',
   ),
   RecurringBillItem(
    name: 'ประกันสังคม มาตรา 39/33',
    expectedAmount: 750.0,
    dueDayOfMonth: 25,
    category: ExpenseCategoryType.utilitiesBills,
    sourceAccount: 'KTB',
   ),
   RecurringBillItem(
    name: 'ผ่อนชำระบัตรเครดิต / อุปกรณ์',
    expectedAmount: 4800.0,
    dueDayOfMonth: 28,
    category: ExpenseCategoryType.equipmentAssets,
    sourceAccount: 'SCB',
   ),
  ];

  // Build day-by-day projected timeline
  final List<ForecastDayPoint> timeline = [];
  double runningBalance = currentTotal;
  bool liquidityAlertTriggered = false;
  String? firstAlertMessage;

  for (int d = 1; d <= forecastDays; d++) {
   final forecastDate = now.add(Duration(days: d));
   final dayOfMonth = forecastDate.day;

   // Check recurring bill triggers
   double dayExpense = dailyAvgExpense * 0.4; // variable daily expense baseline
   double dayIncome = 0.0;

   // Periodic income spikes (e.g. Freelance payouts on 10th & 25th, Salary on 28th)
   if (dayOfMonth == 10) {
    dayIncome += past30Income * 0.35; // Affiliate / Gig payout
   } else if (dayOfMonth == 25) {
    dayIncome += past30Income * 0.40; // Freelance milestone payout
   } else if (dayOfMonth == 28) {
    dayIncome += past30Income * 0.25; // Base salary / other
   } else {
    // stochastic minor income (e-commerce sales)
    dayIncome += (dailyAvgIncome * 0.3) * (0.8 + (d % 3) * 0.2);
   }

   // Check bills for this day
   for (final bill in recurringBills) {
    if (bill.dueDayOfMonth == dayOfMonth) {
     dayExpense += bill.expectedAmount;
    }
   }

   runningBalance = runningBalance + dayIncome - dayExpense;

   final isLow = runningBalance < 10000.0;
   if (isLow && !liquidityAlertTriggered) {
    liquidityAlertTriggered = true;
    firstAlertMessage = ' สภาพคล่องเสี่ยงขาดแคลนในวันที่ ${forecastDate.day}/${forecastDate.month} (คงเหลือประมาณ ฿${runningBalance.toStringAsFixed(0)})';
   }

   timeline.add(ForecastDayPoint(
    date: forecastDate,
    projectedBalance: runningBalance,
    projectedIncome: dayIncome,
    projectedExpense: dayExpense,
    isDangerLow: isLow,
    note: isLow ? 'เงินสดต่ำกว่าเกณฑ์ความปลอดภัย' : null,
   ));
  }

  final projected30 = timeline.length >= 30 ? timeline[29].projectedBalance : runningBalance;
  final projected60 = timeline.length >= 60 ? timeline[59].projectedBalance : runningBalance;
  final projected90 = timeline.length >= 90 ? timeline[89].projectedBalance : projected60;

  final netCashFlow = past30Income - past30Expense;
  final runway = past30Expense > 0 ? (currentTotal / past30Expense).floor() : 12;

  // AI Financial Insights
  final List<String> insights = [];
  if (netCashFlow > 0) {
   insights.add('กระแสเงินสดสุทธิเป็นบวก +฿${netCashFlow.toStringAsFixed(0)} ต่อเดือน เติบโตดี');
  } else {
   insights.add(' อัตราการใช้จ่ายสูงกว่ารายได้ -฿${netCashFlow.abs().toStringAsFixed(0)} ควรควบคุมงบโฆษณาหรือค่ากินดื่ม');
  }

  insights.add('มีเงินสำรองฉุกเฉินครอบคลุมค่าใช้จ่ายได้ประมาณ $runway เดือน');
  insights.add('รายได้จาก Affiliate & Gig มีรอบรับเงินช่วงวันที่ 10 และ 25 ของเดือน');

  return CashflowForecastResult(
   currentTotalBalance: currentTotal,
   projected30DaysBalance: projected30,
   projected60DaysBalance: projected60,
   projected90DaysBalance: projected90,
   estimatedMonthlyBurnRate: past30Expense,
   estimatedMonthlyIncome: past30Income,
   netMonthlyCashFlow: netCashFlow,
   runwayMonths: runway,
   hasLiquidityAlert: liquidityAlertTriggered,
   alertMessage: firstAlertMessage,
   timeline: timeline,
   upcomingBills: recurringBills,
   aiFinancialInsights: insights,
  );
 }
}
