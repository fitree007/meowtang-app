import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../models/transaction_item.dart';
import '../utils/format_utils.dart';

enum CompareMode { twoMonths, twoYears }

class CompareAnalyticsScreen extends StatefulWidget {
  final ExpenseController controller;

  const CompareAnalyticsScreen({super.key, required this.controller});

  @override
  State<CompareAnalyticsScreen> createState() => _CompareAnalyticsScreenState();
}

class _CompareAnalyticsScreenState extends State<CompareAnalyticsScreen> {
  CompareMode _mode = CompareMode.twoMonths;

  late DateTime _monthA;
  late DateTime _monthB;
  late int _yearA;
  late int _yearB;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthA = DateTime(now.year, now.month, 1);
    _monthB = DateTime(now.year, (now.month - 1 > 0) ? now.month - 1 : 12, 1);
    if (now.month == 1) {
      _monthB = DateTime(now.year - 1, 12, 1);
    }
    _yearA = now.year;
    _yearB = now.year - 1;
  }

  String _formatThaiMonth(DateTime d) {
    const months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    return '${months[d.month - 1]} ${d.year + 543}';
  }

  Map<String, dynamic> _computeComparison() {
    if (_mode == CompareMode.twoMonths) {
      return widget.controller.compareTwoMonths(_monthA, _monthB);
    } else {
      double incomeA = 0.0;
      double expenseA = 0.0;
      int txCountA = 0;
      final Map<String, double> catExpenseA = {};

      double incomeB = 0.0;
      double expenseB = 0.0;
      int txCountB = 0;
      final Map<String, double> catExpenseB = {};

      for (final tx in widget.controller.allTransactions) {
        if (tx.date.year == _yearA) {
          txCountA++;
          if (tx.type == TransactionType.income) incomeA += tx.amount;
          if (tx.type == TransactionType.expense) {
            expenseA += tx.amount;
            catExpenseA[tx.categoryDisplayName] = (catExpenseA[tx.categoryDisplayName] ?? 0.0) + tx.amount;
          }
        } else if (tx.date.year == _yearB) {
          txCountB++;
          if (tx.type == TransactionType.income) incomeB += tx.amount;
          if (tx.type == TransactionType.expense) {
            expenseB += tx.amount;
            catExpenseB[tx.categoryDisplayName] = (catExpenseB[tx.categoryDisplayName] ?? 0.0) + tx.amount;
          }
        }
      }

      final expenseDelta = expenseA - expenseB;
      final expenseDeltaPct = expenseB > 0 ? (expenseDelta / expenseB) * 100 : 0.0;
      final incomeDelta = incomeA - incomeB;
      final netA = incomeA - expenseA;
      final netB = incomeB - expenseB;
      final netDelta = netA - netB;

      final dailyAvgA = expenseA / 365.0;
      final dailyAvgB = expenseB / 365.0;

      final allCats = {...catExpenseA.keys, ...catExpenseB.keys};
      final List<Map<String, dynamic>> categoryDeltas = [];
      for (final c in allCats) {
        final a = catExpenseA[c] ?? 0.0;
        final b = catExpenseB[c] ?? 0.0;
        categoryDeltas.add({
          'name': c,
          'amountA': a,
          'amountB': b,
          'delta': a - b,
          'deltaPercent': b > 0 ? ((a - b) / b) * 100 : 0.0,
        });
      }
      categoryDeltas.sort((a, b) => (b['amountA'] as double).compareTo(a['amountA'] as double));

      return {
        'incomeA': incomeA,
        'incomeB': incomeB,
        'incomeDelta': incomeDelta,
        'expenseA': expenseA,
        'expenseB': expenseB,
        'expenseDelta': expenseDelta,
        'expenseDeltaPercent': expenseDeltaPct,
        'netA': netA,
        'netB': netB,
        'netDelta': netDelta,
        'txCountA': txCountA,
        'txCountB': txCountB,
        'dailyAvgExpenseA': dailyAvgA,
        'dailyAvgExpenseB': dailyAvgB,
        'categoryDeltas': categoryDeltas,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = widget.controller.currentTheme;
    final data = _computeComparison();

    final labelA = _mode == CompareMode.twoMonths ? _formatThaiMonth(_monthA) : 'ปี ${_yearA + 543}';
    final labelB = _mode == CompareMode.twoMonths ? _formatThaiMonth(_monthB) : 'ปี ${_yearB + 543}';

    final expenseA = data['expenseA'] as double;
    final expenseB = data['expenseB'] as double;
    final expenseDelta = data['expenseDelta'] as double;
    final expenseDeltaPct = data['expenseDeltaPercent'] as double;

    final incomeA = data['incomeA'] as double;
    final incomeB = data['incomeB'] as double;
    final netA = data['netA'] as double;
    final netB = data['netB'] as double;

    final dailyAvgA = data['dailyAvgExpenseA'] as double;
    final dailyAvgB = data['dailyAvgExpenseB'] as double;
    final txCountA = data['txCountA'] as int;
    final txCountB = data['txCountB'] as int;

    final categoryDeltas = data['categoryDeltas'] as List<Map<String, dynamic>>? ?? [];

    return Scaffold(
      backgroundColor: currentTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: currentTheme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: currentTheme.textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'เปรียบเทียบการเงิน ⚖️',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: currentTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: currentTheme.borderColor),
              ),
              child: Row(
                children: [
                  _buildModeTab('เปรียบเทียบ 2 เดือน', CompareMode.twoMonths, currentTheme),
                  _buildModeTab('เปรียบเทียบ 2 ปี', CompareMode.twoYears, currentTheme),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: currentTheme.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: currentTheme.primaryColor.withValues(alpha: 0.6), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: currentTheme.primaryColor, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text('ช่วงหลัก (A)', style: TextStyle(fontSize: 11, color: currentTheme.textSecondaryColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(labelA, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: currentTheme.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF64748B).withValues(alpha: 0.4), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF64748B), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text('ช่วงเปรียบเทียบ (B)', style: TextStyle(fontSize: 11, color: currentTheme.textSecondaryColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(labelB, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildMetricCard(
              title: 'รายจ่ายรวม (Expense)',
              valA: expenseA,
              valB: expenseB,
              labelA: labelA,
              labelB: labelB,
              delta: expenseDelta,
              deltaPct: expenseDeltaPct,
              isExpense: true,
              currentTheme: currentTheme,
            ),
            const SizedBox(height: 10),
            _buildMetricCard(
              title: 'รายรับรวม (Income)',
              valA: incomeA,
              valB: incomeB,
              labelA: labelA,
              labelB: labelB,
              delta: incomeA - incomeB,
              deltaPct: incomeB > 0 ? ((incomeA - incomeB) / incomeB) * 100 : 0.0,
              isExpense: false,
              currentTheme: currentTheme,
            ),
            const SizedBox(height: 10),
            _buildMetricCard(
              title: 'เงินออมคงเหลือสุทธิ (Net Savings)',
              valA: netA,
              valB: netB,
              labelA: labelA,
              labelB: labelB,
              delta: netA - netB,
              deltaPct: netB.abs() > 0 ? ((netA - netB) / netB.abs()) * 100 : 0.0,
              isExpense: false,
              currentTheme: currentTheme,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: currentTheme.cardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: currentTheme.borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('จ่ายเฉลี่ยต่อวัน', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
                      Text('$labelA: ฿${FormatUtils.formatMoney(dailyAvgA)} | $labelB: ฿${FormatUtils.formatMoney(dailyAvgB)}', style: TextStyle(fontSize: 11.5, color: currentTheme.textSecondaryColor)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('จำนวนรายการบันทึก', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
                      Text('$labelA: $txCountA รายการ | $labelB: $txCountB รายการ', style: TextStyle(fontSize: 11.5, color: currentTheme.textSecondaryColor)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'หมดเงินไปกับอะไรเยอะสุด (เปรียบเทียบหมวดหมู่):',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: currentTheme.textColor),
            ),
            const SizedBox(height: 8),
            if (categoryDeltas.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: currentTheme.cardBackground, borderRadius: BorderRadius.circular(16)),
                child: Center(child: Text('ไม่มีข้อมูลหมวดหมู่ในช่วงนี้', style: TextStyle(fontSize: 12, color: currentTheme.textSecondaryColor))),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categoryDeltas.length.clamp(0, 6),
                itemBuilder: (context, idx) {
                  final cat = categoryDeltas[idx];
                  final name = cat['name'] as String;
                  final a = cat['amountA'] as double;
                  final b = cat['amountB'] as double;
                  final diff = a - b;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: currentTheme.cardBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: currentTheme.borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
                              const SizedBox(height: 2),
                              Text('$labelA: ฿${FormatUtils.formatMoney(a)} vs $labelB: ฿${FormatUtils.formatMoney(b)}', style: TextStyle(fontSize: 11, color: currentTheme.textSecondaryColor)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (diff > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            diff > 0 ? '+฿${FormatUtils.formatMoney(diff)} 🔺' : '-฿${FormatUtils.formatMoney(diff.abs())} 🔻',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: diff > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required double valA,
    required double valB,
    required String labelA,
    required String labelB,
    required double delta,
    required double deltaPct,
    required bool isExpense,
    required dynamic currentTheme,
  }) {
    final isGood = isExpense ? delta <= 0 : delta >= 0;
    final badgeColor = isGood ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: currentTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: currentTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  delta >= 0 ? '+${deltaPct.toStringAsFixed(1)}%' : '${deltaPct.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(labelA, style: TextStyle(fontSize: 11, color: currentTheme.primaryColor, fontWeight: FontWeight.bold)),
                    Text('฿${FormatUtils.formatMoney(valA)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(labelB, style: TextStyle(fontSize: 11, color: currentTheme.textSecondaryColor)),
                    Text('฿${FormatUtils.formatMoney(valB)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, CompareMode mode, dynamic currentTheme) {
    final isSel = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _mode = mode;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? currentTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                color: isSel ? Colors.white : currentTheme.textSecondaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
