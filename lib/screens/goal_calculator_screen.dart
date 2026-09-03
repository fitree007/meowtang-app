import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../utils/format_utils.dart';

enum SavingsFrequencyMode { daily, monthly, yearly }

class GoalCalculatorScreen extends StatefulWidget {
  final ExpenseController controller;

  const GoalCalculatorScreen({super.key, required this.controller});

  @override
  State<GoalCalculatorScreen> createState() => _GoalCalculatorScreenState();
}

class _GoalCalculatorScreenState extends State<GoalCalculatorScreen> {
  SavingsFrequencyMode _frequency = SavingsFrequencyMode.daily;

  final TextEditingController _targetCtrl = TextEditingController(text: '100000');
  final TextEditingController _initialCtrl = TextEditingController(text: '10000');
  final TextEditingController _savingAmtCtrl = TextEditingController(text: '200');

  @override
  void dispose() {
    _targetCtrl.dispose();
    _initialCtrl.dispose();
    _savingAmtCtrl.dispose();
    super.dispose();
  }

  String _formatThaiDate(DateTime d) {
    const months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    final thaiYear = (d.year + 543).toString().substring(2);
    return '${d.day} ${months[d.month - 1]} $thaiYear';
  }

  String _formatDuration(int totalDays) {
    if (totalDays <= 0) return '0 วัน (ครบแล้ว)';
    final years = totalDays ~/ 365;
    final remainingDays = totalDays % 365;
    final months = remainingDays ~/ 30;
    final days = remainingDays % 30;

    final parts = <String>[];
    if (years > 0) parts.add('$years ปี');
    if (months > 0) parts.add('$months เดือน');
    if (days > 0 || parts.isEmpty) parts.add('$days วัน');
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = widget.controller.currentTheme;

    final double target = double.tryParse(_targetCtrl.text.replaceAll(',', '').trim()) ?? 0.0;
    final double initial = double.tryParse(_initialCtrl.text.replaceAll(',', '').trim()) ?? 0.0;
    final double savingAmt = double.tryParse(_savingAmtCtrl.text.replaceAll(',', '').trim()) ?? 0.0;
    final double remaining = (target - initial) > 0 ? (target - initial) : 0.0;

    double dailySaving = 0.0;
    if (_frequency == SavingsFrequencyMode.daily) {
      dailySaving = savingAmt;
    } else if (_frequency == SavingsFrequencyMode.monthly) {
      dailySaving = savingAmt / 30.0;
    } else {
      dailySaving = savingAmt / 365.0;
    }

    final int totalDaysNeeded = dailySaving > 0 ? (remaining / dailySaving).ceil() : 0;
    final DateTime targetCompletionDate = DateTime.now().add(Duration(days: totalDaysNeeded > 0 ? totalDaysNeeded : 0));

    final m25Days = (totalDaysNeeded * 0.25).ceil();
    final m50Days = (totalDaysNeeded * 0.50).ceil();
    final m75Days = (totalDaysNeeded * 0.75).ceil();

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
          'คำนวณเวลาเก็บออมอัจฉริยะ 🧮',
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
                  _buildFreqTab('ออมรายวัน', SavingsFrequencyMode.daily, currentTheme),
                  _buildFreqTab('ออมรายเดือน', SavingsFrequencyMode.monthly, currentTheme),
                  _buildFreqTab('ออมรายปี', SavingsFrequencyMode.yearly, currentTheme),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: currentTheme.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: currentTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ระบุข้อมูลเพื่อจำลองระยะเวลา:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _targetCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: currentTheme.textColor, fontSize: 15, fontWeight: FontWeight.bold),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'เป้าหมายเงินรวมที่ต้องการ (บาท)',
                      prefixText: '฿ ',
                      filled: true,
                      fillColor: currentTheme.surfaceBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _initialCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: currentTheme.textColor, fontSize: 14, fontWeight: FontWeight.bold),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'เงินเก็บที่มีอยู่',
                            prefixText: '฿ ',
                            filled: true,
                            fillColor: currentTheme.surfaceBackground,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _savingAmtCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: currentTheme.textColor, fontSize: 14, fontWeight: FontWeight.bold),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: _frequency == SavingsFrequencyMode.daily
                                ? 'เงินที่จะออม/วัน'
                                : (_frequency == SavingsFrequencyMode.monthly ? 'เงินที่จะออม/เดือน' : 'เงินที่จะออม/ปี'),
                            prefixText: '฿ ',
                            filled: true,
                            fillColor: currentTheme.surfaceBackground,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: currentTheme.heroGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: currentTheme.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ผลการคำนวณระยะเวลาเก็บออม',
                        style: TextStyle(
                          color: (currentTheme.primaryColor.computeLuminance() > 0.55) ? Colors.black87 : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Smart AI ✨', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(totalDaysNeeded),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalDaysNeeded > 0
                        ? 'คาดว่าจะสำเร็จในวันที่ ${_formatThaiDate(targetCompletionDate)}'
                        : '🎉 ยอดเงินเก็บครบตามเป้าหมายแล้ว!',
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ยอดที่ต้องเก็บเพิ่ม', style: TextStyle(color: (currentTheme.primaryColor.computeLuminance() > 0.55) ? Colors.black54 : Colors.white60, fontSize: 11)),
                            Text('฿ ${FormatUtils.formatMoney(remaining)}', style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ออมรวมเป็นจำนวน', style: TextStyle(color: (currentTheme.primaryColor.computeLuminance() > 0.55) ? Colors.black54 : Colors.white60, fontSize: 11)),
                            Text('$totalDaysNeeded วัน', style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'เส้นทางความสำเร็จ (Milestones):',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: currentTheme.textColor),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: currentTheme.cardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: currentTheme.borderColor),
              ),
              child: Column(
                children: [
                  _buildMilestoneRow('25% ของเป้าหมาย', target * 0.25, m25Days, currentTheme),
                  const Divider(height: 16),
                  _buildMilestoneRow('50% ครึ่งทางแล้ว', target * 0.50, m50Days, currentTheme),
                  const Divider(height: 16),
                  _buildMilestoneRow('75% ใกล้ถึงเป้า', target * 0.75, m75Days, currentTheme),
                  const Divider(height: 16),
                  _buildMilestoneRow('100% บรรลุเป้าหมาย 🏆', target, totalDaysNeeded, currentTheme, isFinal: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneRow(String title, double amount, int days, dynamic currentTheme, {bool isFinal = false}) {
    final milestoneDate = DateTime.now().add(Duration(days: days > 0 ? days : 0));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isFinal ? const Color(0xFF10B981).withValues(alpha: 0.15) : currentTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFinal ? Icons.emoji_events_rounded : Icons.flag_rounded,
                size: 14,
                color: isFinal ? const Color(0xFF10B981) : currentTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
                Text('฿${FormatUtils.formatMoney(amount)}', style: TextStyle(fontSize: 11, color: currentTheme.textSecondaryColor)),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$days วัน', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isFinal ? const Color(0xFF10B981) : currentTheme.textColor)),
            Text(_formatThaiDate(milestoneDate), style: TextStyle(fontSize: 10.5, color: currentTheme.textSecondaryColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildFreqTab(String label, SavingsFrequencyMode mode, dynamic currentTheme) {
    final isSel = _frequency == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _frequency = mode;
            if (mode == SavingsFrequencyMode.daily) _savingAmtCtrl.text = '200';
            if (mode == SavingsFrequencyMode.monthly) _savingAmtCtrl.text = '6000';
            if (mode == SavingsFrequencyMode.yearly) _savingAmtCtrl.text = '72000';
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
