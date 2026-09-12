import 'package:flutter/material.dart';
import '../state/expense_controller.dart';
import '../models/transaction_item.dart';
import '../models/category_item.dart';
import '../services/nlp_parser_service.dart';
import '../utils/format_utils.dart';

class VoiceChatEntryScreen extends StatefulWidget {
  final ExpenseController controller;

  const VoiceChatEntryScreen({super.key, required this.controller});

  @override
  State<VoiceChatEntryScreen> createState() => _VoiceChatEntryScreenState();
}

class _VoiceChatEntryScreenState extends State<VoiceChatEntryScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  bool _isListening = false;
  ParsedNlpTransaction? _parsedResult;

  final List<String> _quickPhrases = [
    'ค่ากาแฟสด 65 บาท',
    'เติมน้ำมัน ปตท 500 บาท SCB',
    'ได้ค่าคอม TikTok 1,500 บาท',
    'จ่ายค่าอินเทอร์เน็ตบ้าน 599 บาท',
    'ซื้อหนังสือเตรียมสอบ 320 บาท',
    'บริจาคมัสยิด 200 บาท',
  ];

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _processInput(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _isListening = true;
      _textCtrl.text = text;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final res = widget.controller.parseNlpSpeech(text);
      setState(() {
        _isListening = false;
        _parsedResult = res;
      });
    });
  }

  void _confirmAndSave() {
    if (_parsedResult == null) return;
    final res = _parsedResult!;

    // Auto-create category if new
    final targetType = res.type == TransactionType.income ? CategoryType.income : CategoryType.expense;
    final cat = widget.controller.ensureCategoryExists(res.categoryName, targetType);

    String targetAccId = widget.controller.accounts.isNotEmpty ? widget.controller.accounts.first.id : 'acc_cash';
    if (res.bankNameKeyword != null) {
      final match = widget.controller.accounts.firstWhere(
        (a) => a.bankCode.toUpperCase() == res.bankNameKeyword!.toUpperCase(),
        orElse: () => widget.controller.accounts.first,
      );
      targetAccId = match.id;
    }

    final item = TransactionItem(
      id: 'tx_voice_${DateTime.now().millisecondsSinceEpoch}',
      title: res.title,
      amount: res.amount,
      type: res.type,
      date: DateTime.now(),
      accountId: targetAccId,
      categoryId: cat.id,
      categoryName: cat.name,
      note: 'สั่งงานด้วยเสียง/ข้อความ: "${res.rawInput}"',
    );

    widget.controller.addTransaction(item);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        content: Text('บันทึก "${res.title}" ฿${FormatUtils.formatCurrency(res.amount)} สำเร็จแล้ว!'),
      ),
    );

    setState(() {
      _textCtrl.clear();
      _parsedResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F141C),
        elevation: 0,
        title: const Text('สั่งงานด้วยเสียง AI (Voice NLP)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voice Input Box
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF181E29),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _textCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'พิมพ์หรือพูดประโยค เช่น "เติมน้ำมัน 500 บาท SCB"',
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFF10B981)),
                        onPressed: () => _processInput(_textCtrl.text),
                      ),
                    ),
                    onSubmitted: _processInput,
                  ),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),

                  // Mic action button
                  GestureDetector(
                    onTap: () {
                      _processInput('เติมน้ำมัน 500 บาท SCB');
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF10B981),
                      ),
                      child: const Icon(Icons.mic, color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('แตะไมค์เพื่อจำลองการพูด', style: TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Quick phrases
            const Text('ประโยคตัวอย่างที่พูดได้:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _quickPhrases.map((phrase) {
                return ActionChip(
                  label: Text(phrase, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  backgroundColor: const Color(0xFF181E29),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withOpacity(0.06)),
                  ),
                  onPressed: () => _processInput(phrase),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Parsed Result Card
            if (_parsedResult != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF181E29),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _parsedResult!.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          '${_parsedResult!.type == TransactionType.income ? "+" : "-"}฿${FormatUtils.formatCurrency(_parsedResult!.amount)}',
                          style: TextStyle(
                            color: _parsedResult!.type == TransactionType.income ? const Color(0xFF34D399) : const Color(0xFFF87171),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'หมวดหมู่: ${_parsedResult!.categoryName}${_parsedResult!.isNewCategory ? " (สร้างหมวดใหม่)" : ""}',
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _confirmAndSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('ยืนยันและบันทึก', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
