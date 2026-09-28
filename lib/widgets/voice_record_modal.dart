import 'dart:async';
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
      backgroundColor: controller.isDarkMode ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
  String _partialText = '';
  String _status = 'กำลังฟังเสียงพูดของคุณ...';
  double? _parsedAmount;
  String? _parsedTitle;
  TransactionType _parsedType = TransactionType.expense;
  CategoryItem? _parsedCategory;

  late AnimationController _waveAnimCtrl;
  final List<double> _audioLevels = List.filled(7, 0.25);
  double _currentRms = 0.0;
  Timer? _silenceTimer;

  @override
  void initState() {
    super.initState();
    _waveAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addListener(_onWaveTick)
     ..repeat();

    _setupNativeVoiceListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  void _setupNativeVoiceListeners() {
    NativeBridgeService.setVoiceRmsListener((rms, rmsdB) {
      if (!_isListening || !mounted) return;
      _onRealRmsReceived(rms);
    });

    NativeBridgeService.setVoicePartialListener((text) {
      if (!_isListening || !mounted) return;
      if (text.trim().isNotEmpty) {
        setState(() {
          _partialText = text.trim();
        });
        _resetSilenceTimer();
      }
    });

    NativeBridgeService.setVoiceEndOfSpeechListener(() {
      if (!_isListening || !mounted) return;
      setState(() {
        _status = 'ตรวจพบการหยุดพูด กำลังประมวลผล...';
      });
    });
  }

  void _onRealRmsReceived(double rms) {
    _currentRms = rms;
    const multipliers = [0.35, 0.65, 0.95, 1.35, 0.95, 0.65, 0.35];
    setState(() {
      for (int i = 0; i < 7; i++) {
        final target = (rms * multipliers[i] + 0.15).clamp(0.15, 1.0);
        _audioLevels[i] = _audioLevels[i] + (target - _audioLevels[i]) * 0.45;
      }
    });

    if (rms > 0.2) {
      _resetSilenceTimer();
    }
  }

  void _onWaveTick() {
    if (!mounted) return;
    // Ambient breathing oscillation when real audio is quiet or on web simulator
    if (_currentRms < 0.08) {
      final progress = _waveAnimCtrl.value;
      setState(() {
        for (int i = 0; i < 7; i++) {
          final sine = (math.sin((progress * 2 * math.pi) + (i * 0.8)).abs() * 0.35) + 0.15;
          _audioLevels[i] = _audioLevels[i] + (sine - _audioLevels[i]) * 0.15;
        }
      });
    }
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    // When user pauses/stops talking for 1.8 seconds, auto-stop and process
    _silenceTimer = Timer(const Duration(milliseconds: 1800), () {
      if (_isListening && mounted) {
        final candidate = _partialText.isNotEmpty ? _partialText : _recognizedText;
        if (candidate.trim().isNotEmpty) {
          _stopListeningAndProcess();
        }
      }
    });
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _waveAnimCtrl.dispose();
    NativeBridgeService.setVoiceRmsListener(null);
    NativeBridgeService.setVoicePartialListener(null);
    NativeBridgeService.setVoiceEndOfSpeechListener(null);
    super.dispose();
  }

  Future<void> _startListening() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isListening = true;
      _status = 'กำลังฟังเสียงพูดของคุณ...';
      _recognizedText = '';
      _partialText = '';
      _parsedAmount = null;
      _parsedTitle = null;
    });

    final spokenText = await NativeBridgeService.startVoiceRecognition();

    if (!mounted) return;

    final finalText = (spokenText != null && spokenText.trim().isNotEmpty)
        ? spokenText.trim()
        : _partialText.trim();

    if (finalText.isNotEmpty) {
      _processSpokenText(finalText);
    } else {
      setState(() {
        _isListening = false;
        _status = 'ไม่พบเสียงพูด กรุณาแตะไมค์แล้วลองใหม่อีกครั้ง';
      });
    }
  }

  Future<void> _stopListeningAndProcess() async {
    HapticFeedback.lightImpact();
    await NativeBridgeService.stopVoiceRecognition();

    final textToProcess = _partialText.isNotEmpty ? _partialText : _recognizedText;
    if (textToProcess.trim().isNotEmpty) {
      _processSpokenText(textToProcess.trim());
    } else {
      setState(() {
        _isListening = false;
        _status = 'หยุดการฟังแล้ว ไม่พบข้อความเสียง';
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
      _status = 'ตรวจพบข้อมูลเรียบร้อยแล้ว';
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
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const accentColor = Color(0xFF10B981); // Minimalist emerald
    final isIncome = _parsedType == TransactionType.income;

    final currentDisplay = _recognizedText.isNotEmpty
        ? _recognizedText
        : (_partialText.isNotEmpty ? _partialText : '');

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
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
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: const Icon(
                      Icons.mic_none_rounded,
                      color: accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'พูดเพื่อจดบันทึก',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ตรวจจับจังหวะเสียงจริง • บันทึกอัตโนมัติ',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: textSecondary, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Minimalist Mic Hero & Capsule Audio Waves
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Minimalist Solid Circle Mic
                GestureDetector(
                  onTap: _isListening ? _stopListeningAndProcess : _startListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                          ? (_currentRms > 0.3 ? const Color(0xFF047857) : accentColor)
                          : cardBg,
                      border: Border.all(
                        color: _isListening ? accentColor : borderColor,
                        width: _isListening ? 2 : 1.5,
                      ),
                      boxShadow: _isListening
                          ? [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.25),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isListening ? Colors.white : textPrimary,
                      size: 34,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Minimalist Sound Wave Capsule Visualizer (7 Bars)
                SizedBox(
                  height: 38,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(7, (index) {
                      final level = _audioLevels[index];
                      final barHeight = 6.0 + (level * 28.0);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 70),
                        margin: const EdgeInsets.symmetric(horizontal: 2.8),
                        width: 4.0,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: _isListening
                              ? accentColor
                              : textSecondary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Minimalist Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isListening) ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  _status,
                  style: TextStyle(
                    color: _isListening ? accentColor : textSecondary,
                    fontSize: 12.5,
                    fontWeight: _isListening ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Live Recognized Speech Display
          if (currentDisplay.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                '“$currentDisplay”',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ] else ...[
            Text(
              '💡 พูด เช่น: "กินข้าว 60 บาท", "เติมน้ำมัน 500", "เงินเดือน 35000"',
              style: TextStyle(
                color: textSecondary.withValues(alpha: 0.8),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],

          // Action Buttons while listening: Manual Stop Button
          if (_isListening) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      NativeBridgeService.stopVoiceRecognition();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                      'ยกเลิก',
                      style: TextStyle(color: textSecondary, fontSize: 13.5),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _stopListeningAndProcess,
                    icon: const Icon(Icons.stop_rounded, color: Colors.white, size: 20),
                    label: const Text(
                      'หยุดพูด & บันทึก',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Parsed Result Card (when listening stopped and item parsed)
          if (!_isListening && _recognizedText.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isIncome
                      ? MeowTheme.incomeGreen.withValues(alpha: 0.4)
                      : borderColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _parsedTitle ?? "บันทึกเสียง",
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isIncome ? MeowTheme.incomeGreen : MeowTheme.expenseRed)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isIncome ? 'รายรับ' : 'รายจ่าย',
                          style: TextStyle(
                            color: isIncome ? MeowTheme.incomeGreen : MeowTheme.expenseRed,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#${_parsedCategory?.name ?? "ทั่วไป"}',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                      Text(
                        '${isIncome ? "+" : "-"}฿${_parsedAmount != null ? FormatUtils.formatCurrency(_parsedAmount!) : "0.00"}',
                        style: TextStyle(
                          color: isIncome ? MeowTheme.incomeGreen : MeowTheme.expenseRed,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Confirm & Save Button
            TactileButton(
              onTap: _confirmAndSave,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'ยืนยันบันทึกรายการ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
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
