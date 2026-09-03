import 'package:flutter/material.dart';
import '../state/expense_controller.dart';
import '../models/tax_profile.dart';
import '../widgets/glass_container.dart';
import '../widgets/ai_insight_card.dart';

class TaxPreparationScreen extends StatefulWidget {
  final ExpenseController controller;

  const TaxPreparationScreen({super.key, required this.controller});

  @override
  State<TaxPreparationScreen> createState() => _TaxPreparationScreenState();
}

class _TaxPreparationScreenState extends State<TaxPreparationScreen> {
  late TaxProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.controller.taxProfile;
  }

  void _syncFromTransactions() {
    widget.controller.autoSyncTaxProfileFromTransactions();
    setState(() {
      _profile = widget.controller.taxProfile;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF10B981),
        content: Text('ซิงค์ข้อมูลรายได้และค่าลดหย่อนจากสลิปที่บันทึกแล้วสำเร็จ!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taxResult = _profile.calculate();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.account_balance, color: Color(0xFF38BDF8), size: 24),
            SizedBox(width: 8),
            Text(
              'ตัวช่วยวางแผนภาษี (ภ.ง.ด. 90/91)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'ซิงค์จากสลิปที่บันทึก',
            onPressed: _syncFromTransactions,
            icon: const Icon(Icons.sync, color: Color(0xFF38BDF8)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Tax Summary Card
            GlassContainer(
              borderColor: const Color(0xFF8B5CF6).withOpacity(0.5),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4C1D95).withOpacity(0.4),
                  const Color(0xFF1E1B4B).withOpacity(0.7),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ประมาณการภาษีที่ต้องชำระทั้งปี',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'อัตราภาษีเฉลี่ย ${taxResult.effectiveTaxRate.toStringAsFixed(1)}%',
                          style: const TextStyle(color: Color(0xFFDDD6FE), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '฿${taxResult.totalEstimatedTax.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummarySubItem('รายได้รวมทั้งปี', '฿${taxResult.grossIncome.toStringAsFixed(0)}'),
                      _buildSummarySubItem('หักค่าใช้จ่าย & ลดหย่อน', '฿${(taxResult.standardExpenseDeduction + taxResult.totalAllowableDeductions).toStringAsFixed(0)}'),
                      _buildSummarySubItem('เงินได้สุทธิสุทธิ', '฿${taxResult.netTaxableIncome.toStringAsFixed(0)}'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // AI Tax Saving Suggestions
            const Text(
              'คำแนะนำสิทธิ์ลดหย่อนภาษีเพิ่มเติม (AI Tax Advice):',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),

            ...taxResult.taxSavingTips.map((tip) {
              return AiInsightCard(
                title: 'สิทธิ์ลดหย่อนที่ยังใช้ได้',
                message: tip,
                type: InsightType.tax,
              );
            }),

            const SizedBox(height: 16),

            // Interactive Deduction Adjuster / Simulator
            const Text(
              'ปรับค่าลดหย่อนเพื่อจำลองภาษี (Deduction Simulator):',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),

            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSliderItem(
                    label: 'Easy E-Receipt / ช้อปดีมีคืน',
                    max: 50000,
                    value: _profile.easyEReceiptPaid,
                    onChanged: (val) {
                      setState(() {
                        _profile = TaxProfile(
                          annualSalaryIncome: _profile.annualSalaryIncome,
                          annualFreelanceIncome: _profile.annualFreelanceIncome,
                          annualEcommerceIncome: _profile.annualEcommerceIncome,
                          annualAffiliateIncome: _profile.annualAffiliateIncome,
                          socialSecurityPaid: _profile.socialSecurityPaid,
                          lifeInsurancePaid: _profile.lifeInsurancePaid,
                          pvdRmfSsfPaid: _profile.pvdRmfSsfPaid,
                          thaiEsgPaid: _profile.thaiEsgPaid,
                          easyEReceiptPaid: val,
                        );
                      });
                      widget.controller.updateTaxProfile(_profile);
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildSliderItem(
                    label: 'กองทุน Thai ESG (ลดหย่อนสูงสุด 300,000)',
                    max: 300000,
                    value: _profile.thaiEsgPaid,
                    onChanged: (val) {
                      setState(() {
                        _profile = TaxProfile(
                          annualSalaryIncome: _profile.annualSalaryIncome,
                          annualFreelanceIncome: _profile.annualFreelanceIncome,
                          annualEcommerceIncome: _profile.annualEcommerceIncome,
                          annualAffiliateIncome: _profile.annualAffiliateIncome,
                          socialSecurityPaid: _profile.socialSecurityPaid,
                          lifeInsurancePaid: _profile.lifeInsurancePaid,
                          pvdRmfSsfPaid: _profile.pvdRmfSsfPaid,
                          thaiEsgPaid: val,
                          easyEReceiptPaid: _profile.easyEReceiptPaid,
                        );
                      });
                      widget.controller.updateTaxProfile(_profile);
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildSliderItem(
                    label: 'เบี้ยประกันชีวิต & ประกันสุขภาพ',
                    max: 100000,
                    value: _profile.lifeInsurancePaid,
                    onChanged: (val) {
                      setState(() {
                        _profile = TaxProfile(
                          annualSalaryIncome: _profile.annualSalaryIncome,
                          annualFreelanceIncome: _profile.annualFreelanceIncome,
                          annualEcommerceIncome: _profile.annualEcommerceIncome,
                          annualAffiliateIncome: _profile.annualAffiliateIncome,
                          socialSecurityPaid: _profile.socialSecurityPaid,
                          lifeInsurancePaid: val,
                          pvdRmfSsfPaid: _profile.pvdRmfSsfPaid,
                          thaiEsgPaid: _profile.thaiEsgPaid,
                          easyEReceiptPaid: _profile.easyEReceiptPaid,
                        );
                      });
                      widget.controller.updateTaxProfile(_profile);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Step-by-Step Progressive Tax Bracket Breakdown
            const Text(
              'ตารางแจกแจงภาษีขั้นบันได (Progressive Tax Rates):',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),

            GlassContainer(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ...taxResult.bracketBreakdowns.map((bracket) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bracket.range,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Text(
                                'ฐานคำนวณ ฿${bracket.taxableInThisBracket.toStringAsFixed(0)}',
                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                              ),
                            ],
                          ),
                          Text(
                            '฿${bracket.taxAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFFF87171),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (taxResult.bracketBreakdowns.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'เงินได้สุทธิไม่ถึงเกณฑ์เสียภาษี (0 บาท)',
                        style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySubItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildSliderItem({
    required String label,
    required double max,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
            Text('฿${value.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        Slider(
          value: value.clamp(0.0, max),
          min: 0,
          max: max,
          divisions: 20,
          activeColor: const Color(0xFF38BDF8),
          inactiveColor: Colors.white12,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
