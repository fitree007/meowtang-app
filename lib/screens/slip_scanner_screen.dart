import 'package:flutter/material.dart';
import '../state/expense_controller.dart';
import '../services/ocr_engine_service.dart';
import '../models/slip_extract_result.dart';
import '../models/transaction_item.dart';
import '../widgets/glass_container.dart';
import '../widgets/bank_badge.dart';
import '../utils/format_utils.dart';

class SlipScannerScreen extends StatefulWidget {
 final ExpenseController controller;

 const SlipScannerScreen({super.key, required this.controller});

 @override
 State<SlipScannerScreen> createState() => _SlipScannerScreenState();
}

class _SlipScannerScreenState extends State<SlipScannerScreen>
  with SingleTickerProviderStateMixin {
 late AnimationController _animController;
 bool _isScanning = false;
 MockSlipTemplate? _selectedSlip;
 SlipExtractResult? _extractedResult;
 String? _selectedAccountId;
 String? _selectedProjectId;
 final TextEditingController _customSlipTextCtrl = TextEditingController();

 @override
 void initState() {
  super.initState();
  _animController = AnimationController(
   vsync: this,
   duration: const Duration(seconds: 2),
  );

  // Default select first account
  if (widget.controller.accounts.isNotEmpty) {
   _selectedAccountId = widget.controller.accounts.first.id;
  }
  if (widget.controller.projects.isNotEmpty) {
   _selectedProjectId = widget.controller.projects.first.id;
  }

  // Default load first sample slip
  _selectSample(OcrEngineService.sampleSlips.first);
 }

 @override
 void dispose() {
  _animController.dispose();
  _customSlipTextCtrl.dispose();
  super.dispose();
 }

 void _selectSample(MockSlipTemplate sample) {
  setState(() {
   _selectedSlip = sample;
   _customSlipTextCtrl.text = sample.rawText.trim();
   _extractedResult = null;
  });
  _runOcrExtraction(sample.rawText);
 }

 Future<void> _runOcrExtraction(String rawText) async {
  setState(() {
   _isScanning = true;
  });
  _animController.repeat(reverse: true);

  // Simulate AI neural OCR processing latency
  await Future.delayed(const Duration(milliseconds: 600));

  if (!mounted) return;

  final result = widget.controller.parseSlip(rawText);

  setState(() {
   _isScanning = false;
   _extractedResult = result;
  });
  _animController.stop();
 }

 void _saveTransaction() {
  if (_extractedResult == null) return;

  final res = _extractedResult!;
  final item = TransactionItem(
   id: 'tx_slip_${DateTime.now().millisecondsSinceEpoch}',
   title: res.memo != null && res.memo!.isNotEmpty
     ? res.memo!
     : '${res.suggestedType == TransactionType.income ? "รับเงิน" : "จ่ายเงิน"}: ${res.receiverName}',
   amount: res.amount,
   type: res.suggestedType,
   date: res.dateTime,
   accountId: _selectedAccountId ?? (widget.controller.accounts.isNotEmpty ? widget.controller.accounts.first.id : 'acc_default'),
   categoryId: 'cat_other',
   categoryName: res.suggestedCategoryName,
   incomeStream: res.suggestedIncomeStream,
   projectId: _selectedProjectId,
   note: 'สกัดจากสลิป AI: ${res.senderBank} -> ${res.receiverBank} (${res.refId})',
   slipRefId: res.refId,
   rawOcrText: res.rawOcrText,
   taxType: res.suggestedTaxType,
   isTaxDeductible: res.isTaxDeductible,
   taxDeductibleAmount: res.isTaxDeductible ? res.amount : 0.0,
   tags: ['AI-OCR', res.senderBank, if (res.isTaxDeductible) 'TaxDeductible'],
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
        'บันทึกรายการ ฿${FormatUtils.formatCurrency(res.amount)} ลงในบัญชีสำเร็จแล้ว!',
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
   backgroundColor: const Color(0xFF0D1117),
   appBar: AppBar(
    backgroundColor: const Color(0xFF0D1117),
    elevation: 0,
    title: const Row(
     children: [
      Icon(Icons.document_scanner, color: Color(0xFF38BDF8), size: 24),
      SizedBox(width: 8),
      Text(
       'AI OCR สแกนสลิป & ใบเสร็จ',
       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
      ),
     ],
    ),
   ),
   body: SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
    child: Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
      // Sample Slips Selector Header
      const Text(
       'เลือกสลิปตัวอย่างเพื่อทดสอบการสแกน (Thai Bank Slips & e-Receipts):',
       style: TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w600,
       ),
      ),
      const SizedBox(height: 10),

      // Horizontal Slips Selector List
      SizedBox(
       height: 46,
       child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: OcrEngineService.sampleSlips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
         final sample = OcrEngineService.sampleSlips[index];
         final isSelected = _selectedSlip?.id == sample.id;
         return InkWell(
          onTap: () => _selectSample(sample),
          borderRadius: BorderRadius.circular(12),
          child: Container(
           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
           decoration: BoxDecoration(
            color: isSelected
              ? const Color(0xFF6366F1).withOpacity(0.3)
              : const Color(0xFF1E2433),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
             color: isSelected
               ? const Color(0xFF818CF8)
               : Colors.white.withOpacity(0.08),
             width: isSelected ? 1.5 : 1.0,
            ),
           ),
           child: Row(
            children: [
             BankBadge(bankCode: sample.bankCode, size: 20),
             const SizedBox(width: 8),
             Text(
              sample.bankName,
              style: TextStyle(
               color: isSelected ? Colors.white : Colors.white70,
               fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
               fontSize: 12,
              ),
             ),
             const SizedBox(width: 6),
              Text(
               '฿${FormatUtils.formatCurrency(sample.amount, trimZero: true)}',
               style: TextStyle(
               color: isSelected ? const Color(0xFF34D399) : Colors.white54,
               fontWeight: FontWeight.bold,
               fontSize: 12,
              ),
             ),
            ],
           ),
          ),
         );
        },
       ),
      ),
      const SizedBox(height: 16),

      // Virtual Scanner View with Laser Animation
      GlassContainer(
       padding: const EdgeInsets.all(16),
       child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
           Row(
            children: [
             Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
               color: const Color(0xFF6366F1).withOpacity(0.2),
               borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.qr_code_scanner, color: Color(0xFF818CF8), size: 18),
             ),
             const SizedBox(width: 8),
             const Text(
              'หน้าต่างจำลองภาพสลิป (Slip Preview)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
             ),
            ],
           ),
           if (_isScanning)
            Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
             decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
             ),
             child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
               SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
               ),
               SizedBox(width: 6),
               Text('AI กำลังอ่าน...', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11)),
              ],
             ),
            ),
          ],
         ),
         const SizedBox(height: 12),

         // Slip Simulation Box
         Stack(
          children: [
           Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
             color: const Color(0xFF0F141C),
             borderRadius: BorderRadius.circular(14),
             border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Text(
             _customSlipTextCtrl.text,
             style: const TextStyle(
              fontFamily: 'monospace',
              color: Color(0xFFE2E8F0),
              fontSize: 12,
              height: 1.5,
             ),
            ),
           ),

           // Scanning Laser Bar
           if (_isScanning)
            Positioned.fill(
             child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
               return Align(
                alignment: Alignment(0, (_animController.value * 2) - 1),
                child: Container(
                 height: 3,
                 width: double.infinity,
                 decoration: BoxDecoration(
                  gradient: const LinearGradient(
                   colors: [Colors.transparent, Color(0xFF38BDF8), Colors.transparent],
                  ),
                  boxShadow: [
                   BoxShadow(
                    color: const Color(0xFF38BDF8).withOpacity(0.8),
                    blurRadius: 10,
                    spreadRadius: 2,
                   ),
                  ],
                 ),
                ),
               );
              },
             ),
            ),
          ],
         ),

         const SizedBox(height: 12),
         Row(
          children: [
           Expanded(
            child: OutlinedButton.icon(
             onPressed: () => _runOcrExtraction(_customSlipTextCtrl.text),
             icon: const Icon(Icons.refresh, size: 16, color: Color(0xFF818CF8)),
             label: const Text('สแกนซ้ำ', style: TextStyle(color: Color(0xFF818CF8))),
             style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF818CF8)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
             ),
            ),
           ),
          ],
         ),
        ],
       ),
      ),

      const SizedBox(height: 16),

      // Extracted AI Result Card
      if (_extractedResult != null) ...[
       const Text(
        'ผลลัพธ์การสกัดข้อมูลอัตโนมัติ (AI Extracted Data):',
        style: TextStyle(
         color: Colors.white,
         fontWeight: FontWeight.bold,
         fontSize: 15,
        ),
       ),
       const SizedBox(height: 10),

       GlassContainer(
        borderColor: const Color(0xFF10B981).withOpacity(0.4),
        child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
          // Amount and Confidence Row
          Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
            Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
              Text(
               'ยอดเงินที่ตรวจพบ',
               style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
              ),
              const SizedBox(height: 2),
               Text(
                '฿${FormatUtils.formatCurrency(_extractedResult!.amount)}',
                style: const TextStyle(
                 color: Color(0xFF34D399),
                 fontSize: 28,
                 fontWeight: FontWeight.w900,
                ),
               ),
             ],
            ),
            Container(
             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
             decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
             ),
             child: Row(
              children: [
               const Icon(Icons.verified, color: Color(0xFF10B981), size: 14),
               const SizedBox(width: 4),
               Text(
                'ความแม่นยำ ${(_extractedResult!.confidenceScore * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                 color: Color(0xFF10B981),
                 fontWeight: FontWeight.bold,
                 fontSize: 12,
                ),
               ),
              ],
             ),
            ),
           ],
          ),
          const Divider(color: Colors.white12, height: 24),

          // Details Grid
          _buildInfoRow('ประเภทรายการ:', _extractedResult!.suggestedType == TransactionType.income ? ' รายรับ (Income)' : ' รายจ่าย (Expense)'),
          _buildInfoRow('ผู้โอน / ต้นทาง:', '${_extractedResult!.senderName} (${_extractedResult!.senderBank})'),
          _buildInfoRow('ผู้รับ / ปลายทาง:', '${_extractedResult!.receiverName} (${_extractedResult!.receiverBank})'),
          _buildInfoRow('รหัสอ้างอิง:', _extractedResult!.refId),
          if (_extractedResult!.memo != null)
           _buildInfoRow('บันทึกช่วยจำ:', _extractedResult!.memo!),

          if (_extractedResult!.suggestedIncomeStream != null)
           _buildInfoRow('หมวดหมู่รายได้ (Multi-Stream):', _extractedResult!.suggestedIncomeStream!.name),
          if (_extractedResult!.suggestedExpenseCategory != null)
           _buildInfoRow('หมวดหมู่รายจ่าย:', _extractedResult!.suggestedExpenseCategory!.name),

          if (_extractedResult!.isTaxDeductible) ...[
           const SizedBox(height: 8),
           Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
             color: const Color(0xFF8B5CF6).withOpacity(0.15),
             borderRadius: BorderRadius.circular(10),
             border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.4)),
            ),
            child: Row(
             children: [
              const Icon(Icons.receipt, color: Color(0xFFA78BFA), size: 18),
              const SizedBox(width: 8),
              Expanded(
               child: Text(
                ' สิทธิ์ลดหย่อนภาษี: ${_extractedResult!.suggestedTaxType.name}',
                style: const TextStyle(
                 color: Color(0xFFA78BFA),
                 fontSize: 12,
                 fontWeight: FontWeight.bold,
                ),
               ),
              ),
             ],
            ),
           ),
          ],

          const SizedBox(height: 16),

          // Target Account Selector
          const Text('บันทึกลงในบัญชี:', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
           value: _selectedAccountId,
           dropdownColor: const Color(0xFF1E2433),
           style: const TextStyle(color: Colors.white),
           decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0F141C),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
             borderRadius: BorderRadius.circular(10),
             borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
           ),
           items: widget.controller.accounts.map((acc) {
            return DropdownMenuItem<String>(
             value: acc.id,
             child: Row(
              children: [
               BankBadge(bankCode: acc.bankCode, size: 18),
               const SizedBox(width: 8),
               Text(acc.name, style: const TextStyle(fontSize: 13)),
              ],
             ),
            );
           }).toList(),
           onChanged: (val) {
            setState(() {
             _selectedAccountId = val;
            });
           },
          ),

          const SizedBox(height: 12),

          // Project Tag Selector
          const Text('ผูกกับโปรเจกต์/ทุน (Optional):', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String?>(
           value: _selectedProjectId,
           dropdownColor: const Color(0xFF1E2433),
           style: const TextStyle(color: Colors.white),
           decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0F141C),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
             borderRadius: BorderRadius.circular(10),
             borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
           ),
           items: [
            const DropdownMenuItem<String?>(
             value: null,
             child: Text('ไม่ผูกกับโปรเจกต์', style: TextStyle(fontSize: 13, color: Colors.white54)),
            ),
            ...widget.controller.projects.map((proj) {
             return DropdownMenuItem<String?>(
              value: proj.id,
              child: Text(proj.name, style: const TextStyle(fontSize: 13)),
             );
            }),
           ],
           onChanged: (val) {
            setState(() {
             _selectedProjectId = val;
            });
           },
          ),

          const SizedBox(height: 18),

          // Save Button
          SizedBox(
           width: double.infinity,
           height: 48,
           child: ElevatedButton(
            onPressed: _saveTransaction,
            style: ElevatedButton.styleFrom(
             backgroundColor: const Color(0xFF10B981),
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
             elevation: 4,
            ),
            child: const Row(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
              Icon(Icons.save_alt, color: Colors.white),
              SizedBox(width: 8),
              Text(
               'ยืนยันและลงบัญชีทันที',
               style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
               ),
              ),
             ],
            ),
           ),
          ),
         ],
        ),
       ),
      ],
      const SizedBox(height: 30),
     ],
    ),
   ),
  );
 }

 Widget _buildInfoRow(String label, String value) {
  return Padding(
   padding: const EdgeInsets.symmetric(vertical: 3.0),
   child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
     SizedBox(
      width: 140,
      child: Text(
       label,
       style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
      ),
     ),
     Expanded(
      child: Text(
       value,
       style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
       ),
      ),
     ),
    ],
   ),
  );
 }
}
