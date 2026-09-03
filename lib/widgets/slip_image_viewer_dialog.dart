import 'dart:io';
import 'package:flutter/material.dart';
import '../services/slip_storage_service.dart';
import '../theme/meow_theme.dart';

class SlipImageViewerDialog extends StatelessWidget {
  final String imagePath;
  final String? title;
  final VoidCallback? onReplace;
  final VoidCallback? onDelete;

  const SlipImageViewerDialog({
    super.key,
    required this.imagePath,
    this.title,
    this.onReplace,
    this.onDelete,
  });

  static void show(
    BuildContext context,
    String imagePath, {
    String? title,
    VoidCallback? onReplace,
    VoidCallback? onDelete,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (_) => SlipImageViewerDialog(
        imagePath: imagePath,
        title: title,
        onReplace: onReplace,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedFile = SlipStorageService.resolveSlipFile(imagePath);
    final targetFile = resolvedFile ?? File(imagePath);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Zoomable Interactive Image
          InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 5.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                targetFile,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 300,
                  height: 400,
                  decoration: BoxDecoration(
                    color: MeowTheme.navySurface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_rounded, color: MeowTheme.mustardYellow, size: 48),
                        SizedBox(height: 10),
                        Text('ไม่พบไฟล์รูปภาพสลิป', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Top Header with Title and Close Button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (title != null && title!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      title!,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  const SizedBox(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Controls (Replace / Delete / Zoom Hint)
          Positioned(
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onReplace != null || onDelete != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onReplace != null)
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.photo_library_rounded, size: 16, color: Color(0xFF10B981)),
                            label: const Text('เปลี่ยนสลิป', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                            onPressed: onReplace,
                          ),
                        if (onReplace != null && onDelete != null)
                          Container(width: 1, height: 16, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 4)),
                        if (onDelete != null)
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                            label: const Text('ลบสลิป', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                            onPressed: onDelete,
                          ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in, color: MeowTheme.mustardYellow, size: 15),
                      SizedBox(width: 6),
                      Text(
                        'ใช้นิ้วซูมเข้า-ออกดูสลิปเต็มจอ',
                        style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
