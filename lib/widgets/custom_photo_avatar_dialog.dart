import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../services/native_bridge_service.dart';
import '../widgets/tactile_button.dart';

class CustomPhotoAvatarDialog extends StatefulWidget {
 final ExpenseController controller;
 final Function(String? imagePath) onSaved;

 const CustomPhotoAvatarDialog({
  super.key,
  required this.controller,
  required this.onSaved,
 });

 static Future<void> show(
  BuildContext context,
  ExpenseController controller, {
  required Function(String? imagePath) onSaved,
 }) async {
  await showModalBottomSheet(
   context: context,
   backgroundColor: controller.isDarkMode ? MeowTheme.navySurface : Colors.white,
   isScrollControlled: true,
   shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
   ),
   builder: (_) => CustomPhotoAvatarDialog(
    controller: controller,
    onSaved: onSaved,
   ),
  );
 }

 @override
 State<CustomPhotoAvatarDialog> createState() => _CustomPhotoAvatarDialogState();
}

class _CustomPhotoAvatarDialogState extends State<CustomPhotoAvatarDialog> {
 String? _pickedPath;
 bool _useCustomAvatar = true;

 @override
 void initState() {
  super.initState();
  _pickedPath = widget.controller.customAvatarPath;
  _useCustomAvatar = widget.controller.isCustomAvatarEnabled;
 }

 Future<void> _pickPhoto() async {
  HapticFeedback.selectionClick();
  final path = await NativeBridgeService.pickImageFromGallery();
  if (path != null && path.isNotEmpty) {
   setState(() {
    _pickedPath = path;
    _useCustomAvatar = true;
   });
  }
 }

 void _clearPhoto() {
  HapticFeedback.selectionClick();
  setState(() {
   _pickedPath = null;
   _useCustomAvatar = false;
  });
 }

 void _confirm() async {
  HapticFeedback.mediumImpact();
  if (_useCustomAvatar && _pickedPath != null) {
   await widget.controller.setCustomAvatar(_pickedPath);
   widget.onSaved(_pickedPath);
  } else {
   await widget.controller.setCustomAvatar(null);
   widget.onSaved(null);
  }
  if (!mounted) return;
  Navigator.pop(context);
 }

 @override
 Widget build(BuildContext context) {
  final isDark = widget.controller.isDarkMode;
  final isEn = widget.controller.isEnglish;
  final textPrimary = isDark ? MeowTheme.textLightPrimary : const Color(0xFF0F172A);
  final textSecondary = isDark ? MeowTheme.textLightSecondary : const Color(0xFF64748B);

  final hasPhoto = _pickedPath != null && _pickedPath!.isNotEmpty;

  return Padding(
   padding: EdgeInsets.only(
    left: 24,
    right: 24,
    top: 24,
    bottom: MediaQuery.of(context).viewInsets.bottom + 28,
   ),
   child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
     // Drag Handle
     Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
       color: Colors.grey.withOpacity(0.3),
       borderRadius: BorderRadius.circular(2),
      ),
     ),
     const SizedBox(height: 16),

     // Title
     Text(
      isEn ? ' Custom Photo Mascot Avatar' : ' ใส่รูปตัวเองตรงมาสคอต',
      style: TextStyle(
       color: textPrimary,
       fontSize: 18,
       fontWeight: FontWeight.bold,
      ),
     ),
     const SizedBox(height: 6),
     Text(
      isEn
        ? 'Use your own photo as companion avatar with circular smart frame'
        : 'ตั้งรูปถ่ายของคุณเป็นตัวละครคู่หู พร้อมระบบตัดขอบพอร์ตเทรตสวยงาม',
      textAlign: TextAlign.center,
      style: TextStyle(color: textSecondary, fontSize: 13),
     ),
     const SizedBox(height: 24),

     // Live Circular Photo Preview
     Center(
      child: Stack(
       alignment: Alignment.center,
       children: [
        Container(
         width: 120,
         height: 120,
         decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
           colors: [
            Color(0xFFFEF08A),
            Color(0xFFEAB308),
            Color(0xFFCA8A04),
           ],
          ),
          boxShadow: [
           BoxShadow(
            color: MeowTheme.mustardYellow.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
           ),
          ],
         ),
         padding: const EdgeInsets.all(4),
         child: Container(
          decoration: const BoxDecoration(
           shape: BoxShape.circle,
           color: Color(0xFF0F172A),
          ),
          child: ClipOval(
           child: hasPhoto
             ? (_pickedPath!.startsWith('http')
               ? Image.network(
                 _pickedPath!,
                 fit: BoxFit.cover,
                 errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 54, color: Colors.white70),
                )
               : File(_pickedPath!).existsSync()
                 ? Image.file(
                   File(_pickedPath!),
                   fit: BoxFit.cover,
                   errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 54, color: Colors.white70),
                  )
                 : const Icon(Icons.person, size: 54, color: Colors.white70))
             : const Icon(Icons.person_add_alt_1_rounded, size: 50, color: MeowTheme.mustardYellow),
          ),
         ),
        ),
        if (hasPhoto)
         Positioned(
          right: 4,
          bottom: 4,
          child: Container(
           padding: const EdgeInsets.all(6),
           decoration: const BoxDecoration(
            color: MeowTheme.incomeGreen,
            shape: BoxShape.circle,
           ),
           child: const Icon(Icons.check, color: Colors.white, size: 16),
          ),
         ),
       ],
      ),
     ),
     const SizedBox(height: 20),

     // Photo Action Buttons
     Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
       TactileButton(
        onTap: _pickPhoto,
        child: Container(
         padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
         decoration: BoxDecoration(
          color: MeowTheme.actionBlue,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
           BoxShadow(
            color: MeowTheme.actionBlue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
           ),
          ],
         ),
         child: Row(
          children: [
           const Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 18),
           const SizedBox(width: 8),
           Text(
            hasPhoto
              ? (isEn ? 'Change Photo' : 'เปลี่ยนรูปถ่าย')
              : (isEn ? 'Choose from Gallery' : 'เลือกรูปจากเครื่อง'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
           ),
          ],
         ),
        ),
       ),
       if (hasPhoto) ...[
        const SizedBox(width: 12),
        TactileButton(
         onTap: _clearPhoto,
         child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
           color: Colors.red.withOpacity(0.15),
           borderRadius: BorderRadius.circular(16),
           border: Border.all(color: Colors.red.withOpacity(0.4)),
          ),
          child: Row(
           children: [
            const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
            const SizedBox(width: 6),
            Text(
             isEn ? 'Reset' : 'ใช้มาสคอตเดิม',
             style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
            ),
           ],
          ),
         ),
        ),
       ],
      ],
     ),
     const SizedBox(height: 24),

     // Confirm Save Button
     TactileButton(
      onTap: _confirm,
      child: Container(
       width: double.infinity,
       height: 52,
       decoration: BoxDecoration(
        gradient: MeowTheme.buttonGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
         BoxShadow(
          color: MeowTheme.mustardYellow.withOpacity(0.4),
          blurRadius: 14,
          offset: const Offset(0, 5),
         ),
        ],
       ),
       child: Center(
        child: Text(
         isEn ? 'Apply Avatar' : 'บันทึกรูปมาสคอต',
         style: const TextStyle(
          color: MeowTheme.textDarkPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
         ),
        ),
       ),
      ),
     ),
    ],
   ),
  );
 }
}
