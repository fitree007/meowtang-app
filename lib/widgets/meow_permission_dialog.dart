import 'package:flutter/material.dart';
import '../services/native_bridge_service.dart';

enum MeowPermissionType {
  notification,
  storage,
  microphone,
  camera,
}

class MeowPermissionDialog {
  /// Prompts user with a polite, clear explanation before requesting system permission
  static Future<bool> requestWithExplanation(
    BuildContext context, {
    required MeowPermissionType type,
    String? customTitle,
    String? customMessage,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData icon;
    Color iconColor;
    String title;
    String message;

    switch (type) {
      case MeowPermissionType.notification:
        icon = Icons.notifications_active_rounded;
        iconColor = const Color(0xFF6366F1);
        title = customTitle ?? 'เปิดการแจ้งเตือนเหมียวตังค์ 🔔';
        message = customMessage ??
            'อนุญาตให้เหมียวตังค์ส่งการแจ้งเตือน เพื่อเตือนความจำก่อนถึงวันตัดรอบบิล Subscription และแจ้งเตือนสรุปรายรับ-รายจ่ายที่สำคัญ เพื่อไม่ให้คุณพลาดทุกธุรกรรม';
        break;
      case MeowPermissionType.storage:
        icon = Icons.photo_library_rounded;
        iconColor = const Color(0xFF10B981);
        title = customTitle ?? 'ขอสิทธิ์เข้าถึงคลังรูปภาพ 📸';
        message = customMessage ??
            'อนุญาตให้เหมียวตังค์เข้าถึงรูปภาพสลิป เพื่อช่วยสแกนและดึงสลิปธนาคารเข้าสู่ระบบให้อัตโนมัติ โดยรูปทั้งหมดจะถูกประมวลผลภายในเครื่องของคุณเท่านั้น ปลอดภัย 100%';
        break;
      case MeowPermissionType.microphone:
        icon = Icons.mic_rounded;
        iconColor = const Color(0xFF0EA5E9);
        title = customTitle ?? 'ขอสิทธิ์เข้าถึงไมโครโฟน 🎙️';
        message = customMessage ??
            'อนุญาตให้เหมียวตังค์รับเสียงพูด เพื่อให้คุณสามารถพูดบันทึกรายรับ-รายจ่ายภาษาไทยได้ง่ายๆ โดยไม่ต้องเสียเวลาพิมพ์';
        break;
      case MeowPermissionType.camera:
        icon = Icons.camera_alt_rounded;
        iconColor = const Color(0xFFF59E0B);
        title = customTitle ?? 'ขอสิทธิ์เข้าถึงกล้อง 📷';
        message = customMessage ??
            'อนุญาตให้เหมียวตังค์ใช้งานกล้องเพื่อถ่ายภาพสลิปหรือใบเสร็จได้ทันที';
        break;
    }

    final bool? shouldProceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 14, color: isDark ? Colors.white60 : Colors.black45),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'ข้อมูลของคุณปลอดภัยและเก็บไว้ในเครื่องเท่านั้น',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'ไว้คราวหลัง',
              style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF94A3B8)),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: iconColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'อนุญาตสิทธิ์',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldProceed == true) {
      final res = await NativeBridgeService.requestAppPermissions();
      return res['allGranted'] == true;
    }
    return false;
  }
}
