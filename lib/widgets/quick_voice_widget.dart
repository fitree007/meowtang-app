import 'package:flutter/material.dart';
import '../state/expense_controller.dart';
import '../models/transaction_item.dart';
import '../models/category_item.dart';
import '../models/account_item.dart';
import '../services/nlp_parser_service.dart';
import '../utils/format_utils.dart';

class QuickVoiceWidget extends StatefulWidget {
  final ExpenseController controller;

  const QuickVoiceWidget({super.key, required this.controller});

  @override
  State<QuickVoiceWidget> createState() => _QuickVoiceWidgetState();
}

class _QuickVoiceWidgetState extends State<QuickVoiceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isRecording = false;
  String? _recognizedText;
  ParsedNlpTransaction? _parsedResult;

  final List<String> _quickVoiceChips = [
    'ได้รับเงินเดือน 35,000 บาท',
    'เติมน้ำมัน 500 บาท',
    '20-5 บาท',
    'จ่ายค่ากาแฟ 65 บาท',
    'ได้ค่าคอม 1,200 บาท',
    'ค่าข้าวเที่ยง 80 บาท',
    'บริจาคมัสยิด 200 บาท',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _startRecording([String? presetText]) {
    if (presetText != null) {
      // Instant direct save without waiting
      _stopAndAutoSave(presetText);
      return;
    }

    setState(() {
      _isRecording = true;
      _recognizedText = 'กำลังฟังเสียงพูดของคุณ...';
      _parsedResult = null;
    });
    _animController.repeat();

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      _stopAndAutoSave('เติมน้ำมัน 500 บาท');
    });
  }

  void _stopAndAutoSave(String text) {
    _animController.stop();
    final parsed = widget.controller.parseNlpSpeech(text);

    // Auto-create category if not exists
    final targetCategoryType = parsed.type == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;

    final cat = widget.controller.ensureCategoryExists(parsed.categoryName, targetCategoryType);

    // Find allowed account (honoring allowAutoDeduction)
    AccountItem targetAcc;
    if (parsed.bankNameKeyword != null) {
      targetAcc = widget.controller.accounts.firstWhere(
        (a) => a.bankCode.toUpperCase() == parsed.bankNameKeyword!.toUpperCase() && a.allowAutoDeduction,
        orElse: () => widget.controller.accounts.firstWhere(
          (a) => a.isDefault && a.allowAutoDeduction,
          orElse: () => widget.controller.accounts.firstWhere(
            (a) => a.allowAutoDeduction,
            orElse: () => widget.controller.accounts.first,
          ),
        ),
      );
    } else {
      targetAcc = widget.controller.accounts.firstWhere(
        (a) => a.isDefault && a.allowAutoDeduction,
        orElse: () => widget.controller.accounts.firstWhere(
          (a) => a.allowAutoDeduction,
          orElse: () => widget.controller.accounts.first,
        ),
      );
    }

    final item = TransactionItem(
      id: 'tx_voice_${DateTime.now().millisecondsSinceEpoch}',
      title: parsed.title,
      amount: parsed.amount,
      type: parsed.type,
      date: DateTime.now(),
      accountId: targetAcc.id,
      categoryId: cat.id,
      categoryName: cat.name,
      note: '🎙️ บันทึกเสียง: "$text"',
    );

    widget.controller.addTransaction(item);

    setState(() {
      _isRecording = false;
      _recognizedText = text;
      _parsedResult = parsed;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '✨ บันทึกทันที: ${parsed.type == TransactionType.income ? "+" : "-"}฿${FormatUtils.formatCurrency(parsed.amount)} (${cat.name})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF181E29),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isRecording ? const Color(0xFFEF4444) : Colors.white.withValues(alpha: 0.06),
          width: _isRecording ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          // Circular Voice Button
          Center(
            child: GestureDetector(
              onTap: () {
                if (_isRecording) {
                  _stopAndAutoSave('เติมน้ำมัน 500 บาท');
                } else {
                  _startRecording();
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isRecording)
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return Container(
                          width: 70 + (_animController.value * 20),
                          height: 70 + (_animController.value * 20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFEF4444).withValues(alpha: 0.3 * (1 - _animController.value)),
                          ),
                        );
                      },
                    ),
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isRecording
                            ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                            : [const Color(0xFF10B981), const Color(0xFF059669)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withValues(alpha: 0.4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isRecording ? 'กำลังฟังเสียงพูด... แตะเพื่อบันทึกทันที' : 'แตะไมค์แล้วพูด หรือแตะคำสั่งด่วนด้านล่างเพื่อบันทึกทันที',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _isRecording ? const Color(0xFFFCA5A5) : Colors.white70,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Preset Voice Chips
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: _quickVoiceChips.map((phrase) {
              return ActionChip(
                label: Text(phrase, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                backgroundColor: const Color(0xFF0F141C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                ),
                onPressed: () => _stopAndAutoSave(phrase),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
