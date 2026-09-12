import 'package:flutter/material.dart';
import '../state/expense_controller.dart';
import '../widgets/glass_container.dart';
import '../widgets/cashflow_chart.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/bank_badge.dart';
import '../utils/format_utils.dart';

class PredictiveCashflowScreen extends StatelessWidget {
  final ExpenseController controller;

  const PredictiveCashflowScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final forecast = controller.cashflowForecast;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.auto_graph, color: Color(0xFF38BDF8), size: 24),
            SizedBox(width: 8),
            Text(
              'คาดการณ์สภาพคล่องล่วงหน้า (Predictive ML)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Liquidity Alert Banner if any
            if (forecast.hasLiquidityAlert && forecast.alertMessage != null)
              AiInsightCard(
                title: 'สัญญาณเตือนสภาพคล่อง',
                message: forecast.alertMessage!,
                type: InsightType.warning,
              ),

            const SizedBox(height: 10),

            // Runway & Key Stats Row
            Row(
              children: [
                Expanded(
                  child: GlassContainer(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Runway สภาพคล่อง', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${forecast.runwayMonths}',
                              style: const TextStyle(color: Color(0xFF34D399), fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(width: 4),
                            const Text('เดือน', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassContainer(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Burn Rate รายเดือน', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          '฿${FormatUtils.formatCurrency(forecast.estimatedMonthlyBurnRate, trimZero: true)}',
                          style: const TextStyle(color: Color(0xFFF87171), fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Interactive Forecast Chart
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'กราฟแนวโน้มเงินสดคงเหลือ 30 วันข้างหน้า',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('AI Projection', style: TextStyle(color: Color(0xFF818CF8), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  CashflowChart(
                    timeline: forecast.timeline,
                    currentBalance: forecast.currentTotalBalance,
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),

                  // 30 / 60 / 90 Forecast Chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildProjectionChip('อีก 30 วัน', forecast.projected30DaysBalance),
                      _buildProjectionChip('อีก 60 วัน', forecast.projected60DaysBalance),
                      _buildProjectionChip('อีก 90 วัน', forecast.projected90DaysBalance),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Upcoming Fixed Bills
            const Text(
              'บิลประจำ & ค่าใช้จ่ายคงที่รายเดือน (Recurring Bills):',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),

            ...forecast.upcomingBills.map((bill) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${bill.dueDayOfMonth}',
                            style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bill.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                BankBadge(bankCode: bill.sourceAccount, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'ตัดบัญชี ${bill.sourceAccount} ทุกวันที่ ${bill.dueDayOfMonth}',
                                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '฿${FormatUtils.formatCurrency(bill.expectedAmount, trimZero: true)}',
                        style: const TextStyle(color: Color(0xFFF87171), fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // AI Financial Insights List
            const Text(
              'ข้อคิดเห็นและคำแนะนำจาก AI:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),

            ...forecast.aiFinancialInsights.map((insight) {
              return AiInsightCard(
                title: 'AI Smart Insight',
                message: insight,
                type: InsightType.tip,
              );
            }),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionChip(String label, double amount) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          '฿${FormatUtils.formatCurrency(amount, trimZero: true)}',
          style: TextStyle(
            color: amount >= 0 ? const Color(0xFF38BDF8) : const Color(0xFFEF4444),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
