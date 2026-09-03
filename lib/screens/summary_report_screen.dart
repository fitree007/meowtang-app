import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../models/transaction_item.dart';

class SummaryReportScreen extends StatefulWidget {
  final ExpenseController controller;

  const SummaryReportScreen({super.key, required this.controller});

  @override
  State<SummaryReportScreen> createState() => _SummaryReportScreenState();
}

class _SummaryReportScreenState extends State<SummaryReportScreen> {
  int _selectedFilterIdx = 0; // 0: ทั้งหมด, 1: วันนี้, 2: สัปดาห์นี้, 3: เดือนนี้

  List<TransactionItem> _getFilteredData() {
    final all = widget.controller.allTransactions;
    final now = DateTime.now();

    if (_selectedFilterIdx == 1) {
      // Today
      return all.where((t) => t.date.year == now.year && t.date.month == now.month && t.date.day == now.day).toList();
    } else if (_selectedFilterIdx == 2) {
      // This week
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      return all.where((t) => t.date.isAfter(startOfWeek.subtract(const Duration(days: 1)))).toList();
    } else if (_selectedFilterIdx == 3) {
      // This month
      return all.where((t) => t.date.year == now.year && t.date.month == now.month).toList();
    }
    return all;
  }

  void _exportExcel() {
    final csvContent = widget.controller.exportToExcelCsv();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                      Icon(Icons.table_chart_rounded, color: Color(0xFF10B981), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'ส่งออกไฟล์ Excel / CSV สำเร็จ',
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
                'ข้อมูลตารางได้รับการจัดรูปแบบ UTF-8 BOM สำหรับ Microsoft Excel และ Google Sheets ภาษาไทยเรียบร้อยแล้ว:',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),

              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F141C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    csvContent,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFFE2E8F0),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: csvContent));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF10B981),
                        content: Text('คัดลอกข้อมูลตาราง Excel ลงในคลิปบอร์ดแล้ว! สามารถนำไปวางใน Excel ได้ทันที'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16, color: Colors.white),
                  label: const Text('คัดลอกข้อมูลทั้งหมดสำหรับ Excel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredData();

    double income = 0.0;
    double expense = 0.0;
    final Map<String, double> categoryAmounts = {};

    for (final tx in filtered) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        expense += tx.amount;
        categoryAmounts[tx.categoryDisplayName] = (categoryAmounts[tx.categoryDisplayName] ?? 0.0) + tx.amount;
      }
    }

    final net = income - expense;

    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F141C),
        elevation: 0,
        title: const Text(
          'สรุปภาพรวม & ส่งออก Excel',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'ส่งออกไฟล์ Excel',
            onPressed: _exportExcel,
            icon: const Icon(Icons.file_download_outlined, color: Color(0xFF10B981)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Pills
            Row(
              children: [
                _buildFilterChip(0, 'ทั้งหมด'),
                const SizedBox(width: 6),
                _buildFilterChip(1, 'วันนี้'),
                const SizedBox(width: 6),
                _buildFilterChip(2, 'สัปดาห์นี้'),
                const SizedBox(width: 6),
                _buildFilterChip(3, 'เดือนนี้'),
              ],
            ),
            const SizedBox(height: 16),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF181E29),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatBox('รายรับรวม (ริซกี)', '+฿${income.toStringAsFixed(2)}', const Color(0xFF34D399)),
                      Container(width: 1, height: 40, color: Colors.white12),
                      _buildStatBox('รายจ่ายรวม', '-฿${expense.toStringAsFixed(2)}', const Color(0xFFF87171)),
                      Container(width: 1, height: 40, color: Colors.white12),
                      _buildStatBox('คงเหลือสุทธิ', '฿${net.toStringAsFixed(2)}', net >= 0 ? const Color(0xFF38BDF8) : const Color(0xFFF87171)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Export to Excel Banner Button
            InkWell(
              onTap: _exportExcel,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.table_view_rounded, color: Color(0xFF10B981), size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ส่งออกรายงานเป็นไฟล์ Excel (.csv)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 2),
                          Text('นำไปเปิดใน Microsoft Excel, Google Sheets พร้อมหัวตารางภาษาไทย', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Color(0xFF10B981), size: 14),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Category Breakdown List
            const Text(
              'สัดส่วนค่าใช้จ่ายตามหมวดหมู่:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),

            if (categoryAmounts.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: Text('ยังไม่มีข้อมูลการใช้จ่ายในช่วงเวลานี้', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
              )
            else
              ...categoryAmounts.entries.map((entry) {
                final pct = expense > 0 ? (entry.value / expense * 100).toStringAsFixed(1) : '0';
                final percentFraction = expense > 0 ? (entry.value / expense).clamp(0.0, 1.0) : 0.0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181E29),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('฿${entry.value.toStringAsFixed(2)} ($pct%)', style: const TextStyle(color: Color(0xFFF87171), fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          Container(
                            height: 6,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: percentFraction,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilterIdx == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilterIdx = index;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF10B981) : const Color(0xFF181E29),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
