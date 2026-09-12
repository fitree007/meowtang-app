import 'package:flutter/material.dart';
import '../state/expense_controller.dart';
import '../models/transaction_item.dart';
import '../models/category_item.dart';
import '../utils/format_utils.dart';

class ChatInputBar extends StatefulWidget {
 final ExpenseController controller;
 final Function(String text)? onTextMessageSent;
 final Function(String slipText, String bankName)? onSlipUploaded;

 const ChatInputBar({
  super.key,
  required this.controller,
  this.onTextMessageSent,
  this.onSlipUploaded,
 });

 @override
 State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
 final TextEditingController _textCtrl = TextEditingController();
 bool _isListening = false;

 final List<String> _quickVoicePresets = [
  'กินข้าว 60 บาท',
  'เติมน้ำมัน 500 บาท SCB',
  'ค่ากาแฟ 65 บาท',
  'ได้ค่าคอม TikTok 1,200 บาท',
  'ซื้อของแม็คโคร 850 บาท',
  'บริจาคมัสยิด 100 บาท',
 ];

 final List<Map<String, dynamic>> _sampleSlips = [
  {
   'title': 'สลิป KBank (฿450.00)',
   'bank': 'KBANK',
   'text': '''
ธนาคารกสิกรไทย K PLUS
โอนเงินสำเร็จ
25 ส.ค. 69 18:30 น.
จาก: นายสมชาย (xxx-2-34981-x)
ไปยัง: ร้านอาหารเพลินพุง (xxx-8-99012-x)
จำนวนเงิน: 450.00 บาท
รหัสอ้างอิง: 202608250049182390KB
บันทึกช่วยจำ: ค่าอาหารมื้อเย็น
   '''
  },
  {
   'title': 'สลิป SCB (฿3,500.00)',
   'bank': 'SCB',
   'text': '''
SCB EASY
รายการโอนเงินเข้าสำเร็จ
25 ส.ค. 69 14:15 น.
ผู้โอน: TIKTOK PTE. LTD.
เข้าบัญชี: นายสมชาย (xxx-1-44589-x)
จำนวนเงิน: 3,500.00 บาท
เลขอ้างอิง: 202608251415093819SC
บันทึก: ค่าคอมมิชชั่น TikTok Creator
   '''
  },
  {
   'title': 'สลิป TrueMoney (฿800.00)',
   'bank': 'TRUEMONEY',
   'text': '''
TrueMoney Wallet
ชำระเงินสำเร็จ
25 ส.ค. 69 10:20 น.
โอนจาก: 089-xxx-4591
โอนไปยัง: ปั๊มน้ำมัน ปตท. สาขาหลัก
จำนวนเงิน: 800.00 บาท
หมายเลขอ้างอิง: TM20260825994012
บันทึก: ค่าน้ำมันเดินทาง
   '''
  },
 ];

 @override
 void dispose() {
  _textCtrl.dispose();
  super.dispose();
 }

 void _handleSend() {
  final text = _textCtrl.text.trim();
  if (text.isEmpty) return;

  _processTextMessage(text);
  _textCtrl.clear();
 }

 void _processTextMessage(String text) {
  final parsed = widget.controller.parseNlpSpeech(text);

  // Auto-create category if new
  final targetType = parsed.type == TransactionType.income
    ? CategoryType.income
    : CategoryType.expense;

  final cat = widget.controller.ensureCategoryExists(parsed.categoryName, targetType);

  String targetAccId = widget.controller.accounts.isNotEmpty
    ? widget.controller.accounts.first.id
    : 'acc_cash';

  if (parsed.bankNameKeyword != null) {
   final match = widget.controller.accounts.firstWhere(
    (a) => a.bankCode.toUpperCase() == parsed.bankNameKeyword!.toUpperCase(),
    orElse: () => widget.controller.accounts.first,
   );
   targetAccId = match.id;
  }

  final item = TransactionItem(
   id: 'tx_msg_${DateTime.now().millisecondsSinceEpoch}',
   title: parsed.title,
   amount: parsed.amount,
   type: parsed.type,
   date: DateTime.now(),
   accountId: targetAccId,
   categoryId: cat.id,
   categoryName: cat.name,
   note: 'จดแชท: "$text"',
  );

  widget.controller.addTransaction(item);

  if (widget.onTextMessageSent != null) {
   widget.onTextMessageSent!(text);
  }
 }

 void _showSlipPickerDialog() {
  showModalBottomSheet(
   context: context,
   backgroundColor: const Color(0xFF181E29),
   shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
   ),
   builder: (ctx) {
    return Padding(
     padding: const EdgeInsets.all(20),
     child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
         const Row(
          children: [
           Icon(Icons.photo_library_rounded, color: Color(0xFF38BDF8), size: 20),
           SizedBox(width: 8),
           Text(
            'เลือกรูปสลิปเงิน (AI OCR Reader)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
           ),
          ],
         ),
         IconButton(
          onPressed: () => Navigator.pop(ctx),
          icon: const Icon(Icons.close, color: Colors.white54),
         ),
        ],
       ),
       const SizedBox(height: 8),
       const Text(
        'แตะเพื่อจำลองอัพโหลดสลิปจากอัลบั้มมือถือ หรือเลือกสลิปตัวอย่าง:',
        style: TextStyle(color: Colors.white70, fontSize: 12),
       ),
       const SizedBox(height: 14),

       ..._sampleSlips.map((slip) {
        return Container(
         margin: const EdgeInsets.only(bottom: 8),
         child: ListTile(
          tileColor: const Color(0xFF0F141C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: const Icon(Icons.receipt_long, color: Color(0xFF38BDF8)),
          title: Text(slip['title'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: Text('ธนาคาร ${slip["bank"]} • ดึงข้อมูลอัตโนมัติ', style: const TextStyle(color: Colors.white54, fontSize: 11)),
          onTap: () {
           Navigator.pop(ctx);
           _processSlipUpload(slip['text']);
          },
         ),
        );
       }),
      ],
     ),
    );
   },
  );
 }

 void _processSlipUpload(String slipText) {
  final result = widget.controller.parseSlip(slipText);

  final targetType = result.suggestedType == TransactionType.income
    ? CategoryType.income
    : CategoryType.expense;

  final cat = widget.controller.ensureCategoryExists(result.suggestedCategoryName, targetType);

  String targetAccId = widget.controller.accounts.isNotEmpty
    ? widget.controller.accounts.first.id
    : 'acc_cash';

  final item = TransactionItem(
   id: 'tx_slip_${DateTime.now().millisecondsSinceEpoch}',
   title: result.memo != null && result.memo!.isNotEmpty
     ? result.memo!
     : '${result.suggestedType == TransactionType.income ? "รับเงิน" : "จ่ายเงิน"}: ${result.receiverName}',
   amount: result.amount,
   type: result.suggestedType,
   date: result.dateTime,
   accountId: targetAccId,
   categoryId: cat.id,
   categoryName: cat.name,
   note: 'สลิป AI: ${result.senderBank} -> ${result.receiverBank}',
   slipRefId: result.refId,
   rawOcrText: result.rawOcrText,
  );

  widget.controller.addTransaction(item);

  ScaffoldMessenger.of(context).showSnackBar(
   SnackBar(
    backgroundColor: const Color(0xFF10B981),
    content: Text(' อ่านสลิปสำเร็จ! บันทึก ฿${FormatUtils.formatCurrency(result.amount)} ลงในแชทแล้ว'),
   ),
  );
 }

 void _showVoicePresetsDialog() {
  showModalBottomSheet(
   context: context,
   backgroundColor: const Color(0xFF181E29),
   shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
   ),
   builder: (ctx) {
    return Padding(
     padding: const EdgeInsets.all(20),
     child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       const Row(
        children: [
         Icon(Icons.mic, color: Color(0xFF10B981), size: 20),
         SizedBox(width: 8),
         Text(
          'พูดบันทึกด่วน (Quick Voice)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
         ),
        ],
       ),
       const SizedBox(height: 8),
       const Text(
        'แตะประโยคเพื่อจำลองเสียงพูด หรือกดไมค์เพื่อบันทึกทันที:',
        style: TextStyle(color: Colors.white70, fontSize: 12),
       ),
       const SizedBox(height: 14),

       Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _quickVoicePresets.map((phrase) {
         return ActionChip(
          label: Text(phrase, style: const TextStyle(color: Colors.white, fontSize: 12)),
          backgroundColor: const Color(0xFF0F141C),
          shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(12),
           side: BorderSide(color: const Color(0xFF10B981).withOpacity(0.3)),
          ),
          onPressed: () {
           Navigator.pop(ctx);
           _processTextMessage(phrase);
          },
         );
        }).toList(),
       ),
      ],
     ),
    );
   },
  );
 }

 @override
 Widget build(BuildContext context) {
  return Container(
   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
   decoration: BoxDecoration(
    color: const Color(0xFF181E29),
    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
   ),
   child: SafeArea(
    top: false,
    child: Row(
     children: [
      // 1. Slip / Photo Button
      IconButton(
       icon: const Icon(Icons.receipt_long_rounded, color: Color(0xFF38BDF8), size: 24),
       tooltip: 'อัพโหลดสลิป',
       onPressed: _showSlipPickerDialog,
      ),

      // 2. Mic Button
      IconButton(
       icon: const Icon(Icons.mic_rounded, color: Color(0xFF10B981), size: 24),
       tooltip: 'พูดบันทึกเสียง',
       onPressed: _showVoicePresetsDialog,
      ),

      // 3. Text Input Box
      Expanded(
       child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
         color: const Color(0xFF0F141C),
         borderRadius: BorderRadius.circular(24),
         border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: TextField(
         controller: _textCtrl,
         style: const TextStyle(color: Colors.white, fontSize: 13),
         decoration: const InputDecoration(
          hintText: 'พิมพ์จด เช่น "กินข้าว 60", "กาแฟ 50"...',
          hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
         ),
         onSubmitted: (_) => _handleSend(),
        ),
       ),
      ),

      const SizedBox(width: 6),

      // 4. Send Button
      Container(
       width: 38,
       height: 38,
       decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF10B981),
       ),
       child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
        onPressed: _handleSend,
       ),
      ),
     ],
    ),
   ),
  );
 }
}
