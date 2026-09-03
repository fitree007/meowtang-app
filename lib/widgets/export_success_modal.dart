import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/native_bridge_service.dart';

class ExportSuccessModal extends StatelessWidget {
  final String title;
  final String fileName;
  final String filePath;
  final String formatType; // 'PDF' or 'Excel / CSV'
  final int totalCount;
  final double totalIncome;
  final double totalExpense;
  final dynamic currentTheme;

  const ExportSuccessModal({
    super.key,
    required this.title,
    required this.fileName,
    required this.filePath,
    required this.formatType,
    required this.totalCount,
    required this.totalIncome,
    required this.totalExpense,
    required this.currentTheme,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String fileName,
    required String filePath,
    required String formatType,
    required int totalCount,
    required double totalIncome,
    required double totalExpense,
    required dynamic currentTheme,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExportSuccessModal(
        title: title,
        fileName: fileName,
        filePath: filePath,
        formatType: formatType,
        totalCount: totalCount,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        currentTheme: currentTheme,
      ),
    );
  }

  String _formatDisplayPath(String rawPath) {
    if (rawPath.contains('Download') || rawPath.contains('download')) {
      return '📁 โฟลเดอร์ Downloads / MeowTang /\n$fileName';
    }
    return '📁 $rawPath';
  }

  @override
  Widget build(BuildContext context) {
    final isPdf = formatType.toUpperCase() == 'PDF';
    final formatColor = isPdf ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: currentTheme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ส่งออกไฟล์สำเร็จแล้ว 🎉',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: currentTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      title,
                      style: TextStyle(fontSize: 12, color: currentTheme.textSecondaryColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: formatColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: formatColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  formatType,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: formatColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Location Box (บอกที่อยู่ของไฟล์อย่างชัดเจน)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: currentTheme.surfaceBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: currentTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '📍 ที่อยู่ของไฟล์ (File Location):',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: currentTheme.textSecondaryColor),
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: filePath));
                        HapticFeedback.selectionClick();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📋 คัดลอกที่อยู่ไฟล์ไปยังคลิปบอร์ดแล้ว'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(Icons.copy_rounded, size: 12, color: currentTheme.primaryColor),
                          const SizedBox(width: 3),
                          Text(
                            'คัดลอกที่อยู่',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: currentTheme.primaryColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: currentTheme.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _formatDisplayPath(filePath),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: currentTheme.textColor,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '💡 คุณสามารถเปิดดูไฟล์ได้จากแอพ "ไฟล์ / Downloads" ในมือถือได้ตลอดเวลา',
                  style: TextStyle(fontSize: 10.5, color: currentTheme.textSecondaryColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Summary Stats Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: currentTheme.surfaceBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatPill('จำนวนรายการ', '$totalCount รายการ', currentTheme),
                _buildStatPill('รายรับ', '+฿${totalIncome.toStringAsFixed(0)}', currentTheme, color: const Color(0xFF10B981)),
                _buildStatPill('รายจ่าย', '-฿${totalExpense.toStringAsFixed(0)}', currentTheme, color: const Color(0xFFEF4444)),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Action Buttons
          Row(
            children: [
              // Open File Button (Primary)
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      HapticFeedback.selectionClick();
                      final opened = await NativeBridgeService.openFile(filePath);
                      if (!opened && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ไม่สามารถเปิดไฟล์ได้โดยตรง กรุณาใช้ปุ่มแชร์ส่งไปยังแอพอื่น')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: Icon(isPdf ? Icons.picture_as_pdf_rounded : Icons.table_chart_rounded, size: 18),
                    label: const Text('เปิดไฟล์ทันที', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Share Button
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      HapticFeedback.selectionClick();
                      await NativeBridgeService.shareFile(filePath, title: 'ส่งออกรายงานเหมียวตังค์: $fileName');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: currentTheme.textColor,
                      side: BorderSide(color: currentTheme.borderColor, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('แชร์ไฟล์ / ส่งต่อ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, dynamic currentTheme, {Color? color}) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10.5, color: currentTheme.textSecondaryColor)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color ?? currentTheme.textColor)),
      ],
    );
  }
}
