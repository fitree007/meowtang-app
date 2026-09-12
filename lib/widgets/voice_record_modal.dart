import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction_item.dart';
import '../models/category_item.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../services/native_bridge_service.dart';
import '../widgets/tactile_button.dart';
import '../utils/format_utils.dart';

class VoiceRecordModal extends StatefulWidget {
  final ExpenseController controller;

  const VoiceRecordModal({super.key, required this.controller});

  static Future<void> show(BuildContext context, ExpenseController controller) async {
    HapticFeedback.selectionClick();
    await showModalBottomSheet(
      context: context,
      backgroundColor: controller.isDarkMode ? MeowTheme.navySurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      builder: (ctx) => VoiceRecordModal(controller: controller),
    );
  }

  @override
  State<VoiceRecordModal> createState() => _VoiceRecordModalState();
}

class _VoiceRecordModalState extends State<VoiceRecordModal>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  String _recognizedText = '';
  String _status = 'แตะที่ไมโครโฟน แล้วพูดเพื่อบันทึก...';
  double? _parsedAmount;
  String? _parsedTitle;
  TransactionType _parsedType = TransactionType.expense;
  CategoryItem? _parsedCategory;

  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isListening = true;
      _status = 'กำลังฟังเสียงของคุณ... พูดได้เลยครับ';
      _recognizedText = '';
      _parsedAmount = null;
      _parsedTitle = null;
    });

    final spokenText = await NativeBridgeService.startVoiceRecognition();

    if (!mounted) return;

    if (spokenText != null && spokenText.trim().isNotEmpty) {
      _processSpokenText(spokenText.trim());
    } else {
      setState(() {
        _isListening = false;
        _status = 'ไม่พบเสียงพูด กรุณาแตะไมโครโฟนแล้วลองใหม่อีกครั้ง';
      });
    }
  }

  void _processSpokenText(String text) {
    HapticFeedback.lightImpact();
    final parsed = widget.controller.parseNlpSpeech(text);

    final targetCategories = parsed.type == TransactionType.income
        ? widget.controller.incomeCategories
        : widget.controller.expenseCategories;

    CategoryItem matchedCat = targetCategories.isNotEmpty
        ? targetCategories.first
        : widget.controller.categories.first;

    final found = targetCategories.firstWhere(
      (c) =>
          c.name.toLowerCase().contains(parsed.categoryName.toLowerCase()) ||
          parsed.categoryName.toLowerCase().contains(c.name.toLowerCase()),
      orElse: () => matchedCat,
    );
    matchedCat = found;

    setState(() {
      _isListening = false;
      _recognizedText = text;
      _parsedAmount = parsed.amount > 0 ? parsed.amount : null;
      _parsedTitle = parsed.title.isNotEmpty ? parsed.title : text;
      _parsedType = parsed.type;
      _parsedCategory = matchedCat;
      _status = 'แปลงเสียงเป็นข้อความสำเร็จ ✨';
    });
  }

  void _confirmAndSave() {
    if (_parsedAmount == null || _parsedAmount! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาระบุจำนวนเงินที่ถูกต้อง')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final isIncome = _parsedType == TransactionType.income;

    final item = TransactionItem(
      id: 'tx_voice_${DateTime.now().millisecondsSinceEpoch}',
      title: _parsedTitle ?? (isIncome ? 'รายรับเสียง' : 'รายจ่ายเสียง'),
      amount: _parsedAmount!,
      type: _parsedType,
      date: DateTime.now(),
      accountId: widget.controller.accounts.isNotEmpty
          ? widget.controller.accounts.first.id
          : 'acc_cash',
      categoryId: _parsedCategory?.id ??
          (isIncome ? 'cat_income_default' : 'cat_general_exp'),
      categoryName: _parsedCategory?.name ??
          (isIncome ? 'รับเงินโอน / รายได้' : 'รายจ่ายทั่วไป'),
      note: '🎙️ คำพูด: "$_recognizedText"',
    );

    widget.controller.addTransaction(item);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✨ บันทึก "${item.title}" ${isIncome ? "+" : "-"}฿${FormatUtils.formatCurrency(item.amount)} เรียบร้อยแล้ว!',
        ),
        backgroundColor:
            isIncome ? MeowTheme.incomeGreen : MeowTheme.expenseRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.controller.isDarkMode;
    final textPrimary =
        isDark ? MeowTheme.textLightPrimary : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? MeowTheme.textLightSecondary : const Color(0xFF64748B);
    final cardBg = isDark ? MeowTheme.navyCard : const Color(0xFFF8FAFC);
    final isIncome = _parsedType == TransactionType.income;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: Color(0xFF0284C7),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'พูดเพื่อจดบันทึก (Voice AI)',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: textSecondary, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Animated Waves & Glowing Mic Hero
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: AnimatedBuilder(
                animation: _animCtrl,
                builder: (context, child) {
                  final progress = _animCtrl.value;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Concentric Ripple Wave 1
                      if (_isListening)
                        Container(
                          width: 100 + (progress * 65),
                          height: 100 + (progress * 65),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF38BDF8).withValues(
                                alpha: (1.0 - progress).clamp(0.0, 0.7),
                              ),
                              width: 2.2,
                            ),
                          ),
                        ),

                      // Concentric Ripple Wave 2 (Staggered by 0.5)
                      if (_isListening)
                        Container(
                          width: 100 + (((progress + 0.5) % 1.0) * 65),
                          height: 100 + (((progress + 0.5) % 1.0) * 65),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: MeowTheme.mustardYellow.withValues(
                                alpha: (1.0 - ((progress + 0.5) % 1.0))
                                    .clamp(0.0, 0.6),
                              ),
                              width: 1.8,
                            ),
                          ),
                        ),

                      // Animated Equalizer Wave Bars underneath mic
                      if (_isListening)
                        Positioned(
                          bottom: 12,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(7, (index) {
                              final barHeight = 8.0 +
                                  (math.sin((progress * 2 * math.pi) +
                                              (index * 0.9))
                                          .abs() *
                                      20.0);
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2.5),
                                width: 3.5,
                                height: barHeight,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFF38BDF8),
                                      Color(0xFF2563EB),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                        ),

                      // Main Tactile Mic Button
                      GestureDetector(
                        onTap: _startListening,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _isListening ? 86 : 80,
                          height: _isListening ? 86 : 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _isListening
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF38BDF8),
                                      Color(0xFF2563EB),
                                      Color(0xFF1D4ED8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : (isIncome
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF10B981),
                                          Color(0xFF059669),
                                        ],
                                      )
                                    : MeowTheme.blueButtonGradient),
                            boxShadow: [
                              BoxShadow(
                                color: (_isListening
                                        ? const Color(0xFF2563EB)
                                        : (isIncome
                                            ? const Color(0xFF10B981)
                                            : MeowTheme.actionBlue))
                                    .withValues(
                                        alpha: _isListening ? 0.6 : 0.35),
                                blurRadius: _isListening ? 22 : 14,
                                spreadRadius: _isListening ? 3 : 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Live Listening Badge / Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _isListening
                  ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                  : cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isListening
                    ? const Color(0xFFEF4444).withValues(alpha: 0.35)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isListening) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isListening ? const Color(0xFFEF4444) : textPrimary,
                    fontSize: 13.5,
                    fontWeight:
                        _isListening ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Speech Example Prompts
          Text(
            '💡 พูดได้เลย เช่น: "กินข้าว 60 บาท", "เติมน้ำมัน 500 โอนจากกสิกร", "เงินเดือน 35000"',
            style: TextStyle(
              color: textSecondary.withValues(alpha: 0.8),
              fontSize: 11.5,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 18),

          // Recognized & Parsed Result Card
          if (_recognizedText.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: (isIncome
                          ? MeowTheme.incomeGreen
                          : const Color(0xFF38BDF8))
                      .withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isIncome
                            ? MeowTheme.incomeGreen
                            : const Color(0xFF38BDF8))
                        .withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.record_voice_over_rounded,
                        color: isIncome
                            ? MeowTheme.incomeGreen
                            : const Color(0xFF0284C7),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ได้ยินว่า: "$_recognizedText"',
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: (isIncome
                                  ? MeowTheme.incomeGreen
                                  : MeowTheme.expenseRed)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isIncome
                                ? MeowTheme.incomeGreen
                                : MeowTheme.expenseRed,
                          ),
                        ),
                        child: Text(
                          isIncome ? '💰 รายรับ' : '💸 รายจ่าย',
                          style: TextStyle(
                            color: isIncome
                                ? MeowTheme.incomeGreen
                                : MeowTheme.expenseRed,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'รายการ: ${_parsedTitle ?? ""}',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'หมวดหมู่: #${_parsedCategory?.name ?? "ทั่วไป"}',
                              style: const TextStyle(
                                color: MeowTheme.mustardYellow,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isIncome ? "+" : "-"}฿${_parsedAmount != null ? FormatUtils.formatCurrency(_parsedAmount!) : "0.00"}',
                        style: TextStyle(
                          color: isIncome
                              ? MeowTheme.incomeGreen
                              : MeowTheme.expenseRed,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Save Action Button
            TactileButton(
              onTap: _confirmAndSave,
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF38BDF8),
                      Color(0xFF2563EB),
                      Color(0xFF1D4ED8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'บันทึกรายการนี้ทันที 🚀',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
