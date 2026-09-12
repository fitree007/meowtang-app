import 'package:flutter/material.dart';
import '../state/expense_controller.dart';
import '../models/transaction_item.dart';
import '../models/category_item.dart';
import '../models/slip_extract_result.dart';
import '../services/ocr_engine_service.dart';
import '../widgets/bank_badge.dart';
import '../utils/format_utils.dart';

class UploadSlipScreen extends StatefulWidget {
 final ExpenseController controller;

 const UploadSlipScreen({super.key, required this.controller});

 @override
 State<UploadSlipScreen> createState() => _UploadSlipScreenState();
}

class _UploadSlipScreenState extends State<UploadSlipScreen> {
 bool _isProcessing = false;
 SlipExtractResult? _extractedResult;
 String? _selectedAccountId;
 String? _selectedCategoryId;
 String _uploadedImageName = '';
 final TextEditingController _slipTextCtrl = TextEditingController();

 final List<Map<String, dynamic>> _samplePresets = [
  {
   'title': 'สลิป KBank - โอนค่าอาหาร 450 บาท',
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
   'title': 'สลิป SCB - รับค่าคอมมิชชั่น 3,500 บาท',
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
   'title': 'สลิป TrueMoney - เติมน้ำมัน 800 บาท',
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
  {
   'title': 'สลิป Krungthai - รับเงินเดือน/ค่าจ้าง 35,000 บาท',
   'bank': 'KTB',
   'text': '''
Krungthai NEXT
เงินเข้าสำเร็จ
25 ส.ค. 69 08:30 น.
จาก: บริษัท ดิจิทัล โซลูชั่น จำกัด
ไปยัง: นายสมชาย (xxx-0-91283-x)
จำนวนเงิน: 35,000.00 บาท
รหัสอ้างอิง: 202608250830129841KT
ข้อความ: เงินเดือนประจำเดือน
   '''
  },
 ];

 @override
 void initState() {
  super.initState();
  if (widget.controller.accounts.isNotEmpty) {
   _selectedAccountId = widget.controller.accounts.first.id;
  }
  if (widget.controller.categories.isNotEmpty) {
   _selectedCategoryId = widget.controller.categories.first.id;
  }
 }

 @override
 void dispose() {
  _slipTextCtrl.dispose();
  super.dispose();
 }

 Future<void> _processSlip(String text, String fileName) async {
  setState(() {
   _isProcessing = true;
   _uploadedImageName = fileName;
   _slipTextCtrl.text = text.trim();
  });

  await Future.delayed(const Duration(milliseconds: 500));
  if (!mounted) return;

  final result = widget.controller.parseSlip(text, fileName: fileName);

  // Find best category match
  String? matchedCatId;
  for (final cat in widget.controller.categories) {
   if (cat.name.toLowerCase() == result.suggestedCategoryName.toLowerCase()) {
    matchedCatId = cat.id;
    break;
   }
  }
  if (matchedCatId == null && widget.controller.categories.isNotEmpty) {
   matchedCatId = widget.controller.categories.first.id;
  }

  setState(() {
   _isProcessing = false;
   _extractedResult = result;
   _selectedCategoryId = matchedCatId;
  });
 }

 void _saveToLedger() {
  if (_extractedResult == null || _selectedAccountId == null) return;

  final res = _extractedResult!;
  final cat = widget.controller.categories.firstWhere(
   (c) => c.id == _selectedCategoryId,
   orElse: () => widget.controller.categories.first,
  );

  String title = 'โอนเงิน ${res.senderBank}';
  if (res.senderName != 'ไม่ระบุผู้โอน' && res.receiverName != 'ไม่ระบุผู้รับ') {
   title = '${res.senderName} โอนให้ ${res.receiverName}';
  } else if (res.receiverName != 'ไม่ระบุผู้รับ') {
   title = 'โอนให้ ${res.receiverName}';
  } else if (res.memo != null && res.memo!.isNotEmpty) {
   title = res.memo!;
  }

  final noteBuffer = StringBuffer();
  if (res.senderName != 'ไม่ระบุผู้โอน' || res.receiverName != 'ไม่ระบุผู้รับ') {
   noteBuffer.write(' ผู้โอน: ${res.senderName} ผู้รับ: ${res.receiverName} (${res.senderBank})');
  } else {
   noteBuffer.write(' สลิป: ${res.senderBank} (${res.refId})');
  }
  if (res.memo != null && res.memo!.isNotEmpty) {
   noteBuffer.write(' | บันทึก: ${res.memo}');
  }

  final item = TransactionItem(
   id: 'tx_slip_${DateTime.now().millisecondsSinceEpoch}',
   title: title,
   amount: res.amount,
   type: res.suggestedType,
   date: res.dateTime,
   accountId: _selectedAccountId!,
   categoryId: cat.id,
   categoryName: cat.name,
   note: noteBuffer.toString(),
   slipRefId: res.refId,
   rawOcrText: res.rawOcrText,
  );

  widget.controller.addTransaction(item);

  ScaffoldMessenger.of(context).showSnackBar(
   SnackBar(
    backgroundColor: const Color(0xFF10B981),
    content: Row(
     children: [
      const Icon(Icons.check_circle, color: Colors.white),
      const SizedBox(width: 10),
      Expanded(
       child: Text(
        'บันทึกสลิป ฿${FormatUtils.formatCurrency(res.amount)} ลงในบัญชีสำเร็จแล้ว!',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
       ),
      ),
     ],
    ),
   ),
  );
 }

 @override
 Widget build(BuildContext context) {
  return Scaffold(
   backgroundColor: const Color(0xFF0F141C),
   appBar: AppBar(
    backgroundColor: const Color(0xFF0F141C),
    elevation: 0,
    title: const Text(
     'อัพโหลดสลิปเงิน (AI Slip Reader)',
     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
    ),
   ),
   body: SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
      // Upload Box Area
      Container(
       width: double.infinity,
       padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
        color: const Color(0xFF181E29),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
         color: const Color(0xFF38BDF8).withOpacity(0.3),
         width: 1.5,
        ),
       ),
       child: Column(
        children: [
         Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
           color: const Color(0xFF38BDF8).withOpacity(0.12),
           shape: BoxShape.circle,
          ),
          child: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF38BDF8), size: 32),
         ),
         const SizedBox(height: 12),
         const Text(
          'เลือกภาพสลิปเงินจากมือถือ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
         ),
         const SizedBox(height: 4),
         Text(
          'รองรับภาพสลิปโอนเงินทุกธนาคารไทย (KBank, SCB, Krungthai, TrueMoney ฯลฯ)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
         ),
         const SizedBox(height: 16),

         Row(
          children: [
           Expanded(
            child: ElevatedButton.icon(
             onPressed: () {
              _processSlip(_samplePresets.first['text'], 'slip_gallery_01.jpg');
             },
             icon: const Icon(Icons.photo_library_rounded, size: 16, color: Colors.white),
             label: const Text('เลือกจากอัลบั้ม', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
             style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 10),
             ),
            ),
           ),
           const SizedBox(width: 8),
           Expanded(
            child: OutlinedButton.icon(
             onPressed: () {
              _processSlip(_samplePresets[1]['text'], 'slip_camera_02.jpg');
             },
             icon: const Icon(Icons.camera_alt_rounded, size: 16, color: Color(0xFF38BDF8)),
             label: const Text('ถ่ายภาพสลิป', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
             style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF38BDF8)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 10),
             ),
            ),
           ),
          ],
         ),
        ],
       ),
      ),

      const SizedBox(height: 16),

      // Quick Preset Slips for Instant Testing
      const Text(
       'หรือทดสอบกับสลิปตัวอย่าง:',
       style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      SizedBox(
       height: 38,
       child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _samplePresets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
         final preset = _samplePresets[idx];
         return InkWell(
          onTap: () => _processSlip(preset['text'], 'sample_${preset["bank"]}.jpg'),
          borderRadius: BorderRadius.circular(10),
          child: Container(
           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
           decoration: BoxDecoration(
            color: const Color(0xFF181E29),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
           ),
           child: Row(
            children: [
             BankBadge(bankCode: preset['bank'], size: 16),
             const SizedBox(width: 6),
             Text(preset['title'], style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
           ),
          ),
         );
        },
       ),
      ),

      const SizedBox(height: 18),

      // Processing Indicator
      if (_isProcessing) ...[
       Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: const Column(
         children: [
          CircularProgressIndicator(color: Color(0xFF38BDF8)),
          SizedBox(height: 10),
          Text('AI กำลังอ่านและสกัดข้อมูลจากภาพสลิป...', style: TextStyle(color: Colors.white70, fontSize: 12)),
         ],
        ),
       ),
      ],

      // Extracted Results Card
      if (_extractedResult != null && !_isProcessing) ...[
       const Text(
        'ข้อมูลที่ AI อ่านได้จากสลิป:',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
       ),
       const SizedBox(height: 8),

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
            Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
              Text('ยอดเงินในสลิป', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
              const SizedBox(height: 2),
              Text(
               '฿${FormatUtils.formatCurrency(_extractedResult!.amount)}',
               style: const TextStyle(
                color: Color(0xFF34D399),
                fontSize: 26,
                fontWeight: FontWeight.w900,
               ),
              ),
             ],
            ),
            Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
             decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
             ),
             child: Text(
              _extractedResult!.suggestedType == TransactionType.income ? ' รายรับ' : ' รายจ่าย',
              style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11),
             ),
            ),
           ],
          ),
          const Divider(color: Colors.white12, height: 20),

          _buildRow('ธนาคารต้นทาง:', _extractedResult!.senderBank),
          _buildRow('ผู้โอน:', _extractedResult!.senderName),
          _buildRow('ผู้รับ:', _extractedResult!.receiverName),
          _buildRow('รหัสอ้างอิง:', _extractedResult!.refId),
          if (_extractedResult!.memo != null)
           _buildRow('บันทึกช่วยจำ:', _extractedResult!.memo!),

          const SizedBox(height: 14),

          // Account Selector
          const Text('บันทึกลงบัญชี:', style: TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
           value: _selectedAccountId,
           dropdownColor: const Color(0xFF1E2433),
           style: const TextStyle(color: Colors.white),
           decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0F141C),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
           ),
           items: widget.controller.accounts.map((acc) {
            return DropdownMenuItem(
             value: acc.id,
             child: Text(acc.name, style: const TextStyle(fontSize: 13)),
            );
           }).toList(),
           onChanged: (val) {
            setState(() {
             _selectedAccountId = val;
            });
           },
          ),

          const SizedBox(height: 10),

          // Category Selector
          const Text('หมวดหมู่:', style: TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
           value: _selectedCategoryId,
           dropdownColor: const Color(0xFF1E2433),
           style: const TextStyle(color: Colors.white),
           decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0F141C),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
           ),
           items: widget.controller.categories.map((cat) {
            return DropdownMenuItem(
             value: cat.id,
             child: Text(cat.name, style: const TextStyle(fontSize: 13)),
            );
           }).toList(),
           onChanged: (val) {
            setState(() {
             _selectedCategoryId = val;
            });
           },
          ),

          const SizedBox(height: 16),

          // Save Button
          SizedBox(
           width: double.infinity,
           height: 44,
           child: ElevatedButton(
            onPressed: _saveToLedger,
            style: ElevatedButton.styleFrom(
             backgroundColor: const Color(0xFF10B981),
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ยืนยันและลงบัญชีทันที', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
           ),
          ),
         ],
        ),
       ),
      ],
      const SizedBox(height: 40),
     ],
    ),
   ),
  );
 }

 Widget _buildRow(String label, String value) {
  return Padding(
   padding: const EdgeInsets.symmetric(vertical: 2.5),
   child: Row(
    children: [
     SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11))),
     Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))),
    ],
   ),
  );
 }
}
