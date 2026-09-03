import 'package:flutter/material.dart';
import '../theme/meow_theme.dart';
import '../widgets/meow_mascot_widget.dart';

class MeowOnboardingScreen extends StatefulWidget {
 final VoidCallback onFinish;

 const MeowOnboardingScreen({super.key, required this.onFinish});

 @override
 State<MeowOnboardingScreen> createState() => _MeowOnboardingScreenState();
}

class _MeowOnboardingScreenState extends State<MeowOnboardingScreen> {
 final PageController _pageController = PageController();
 int _currentPage = 0;

 final List<Map<String, String>> _slides = [
  {
   'title': 'เหมียวมาช่วยจดรายจ่าย\nจากสลิปแล้ว เมี้ยว~',
   'subtitle':
     'เหมียวจะสแกน QR Code จากรูปสลิปในคลังภาพของเครื่องนี้ แล้วจดเป็นรายจ่ายให้ทุกวัน',
  },
  {
   'title': 'จดบัตรเครดิต ง่าย\nแค่อัปโหลดใบแจ้งยอด',
   'subtitle':
     'ใช้บัตรหลายใบก็จดได้ จดให้ทั้งรายจ่าย, ยอดผ่อน, ดอกเบี้ย, เงินคืน',
  },
  {
   'title': 'สรุปให้เลย เงินหายไปไหน?\nใช้หมวดไหนเยอะ?',
   'subtitle':
     'สิ่งนี้ต้องถูกใจพี่มนุษย์! ดูสรุปรายจ่ายแต่ละหมวดหมู่ รู้ทันการใช้จ่าย ใช้ตรงไหนเยอะ เหมียวบอกได้',
  },
 ];

 void _nextPage() {
  if (_currentPage < _slides.length - 1) {
   _pageController.nextPage(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
   );
  } else {
   _showWelcomeDialog();
  }
 }

 void _showWelcomeDialog() {
  showModalBottomSheet(
   context: context,
   isScrollControlled: true,
   backgroundColor: MeowTheme.navySurface,
   shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
   ),
   builder: (ctx) => Container(
    padding: const EdgeInsets.all(28),
    child: Column(
     mainAxisSize: MainAxisSize.min,
     children: [
      const MeowMascotWidget(size: 80, isHeadOnly: true),
      const SizedBox(height: 16),
      const Text(
       'เหมียวพร้อมจดแล้ว!',
       style: TextStyle(
        color: MeowTheme.textLightPrimary,
        fontSize: 22,
        fontWeight: FontWeight.bold,
       ),
      ),
      const SizedBox(height: 8),
      const Text(
       'เปิดแอปบ่อยๆ ให้เหมียวจดได้ต่อเนื่องนะ เมี้ยว~',
       textAlign: TextAlign.center,
       style: TextStyle(color: MeowTheme.textLightSecondary, fontSize: 14),
      ),
      const SizedBox(height: 24),
      SizedBox(
       width: double.infinity,
       height: 52,
       child: ElevatedButton(
        style: ElevatedButton.styleFrom(
         backgroundColor: MeowTheme.actionBlue,
         shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
         ),
        ),
        onPressed: () {
         Navigator.pop(ctx);
         widget.onFinish();
        },
        child: const Text(
         'เริ่มใช้งานเหมียวจดเลย!',
         style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
         ),
        ),
       ),
      ),
      const SizedBox(height: 16),
     ],
    ),
   ),
  );
 }

 @override
 Widget build(BuildContext context) {
  return Scaffold(
   backgroundColor: MeowTheme.navyBackground,
   body: Stack(
    children: [
     // Background Split
     Column(
      children: [
       Expanded(
        flex: 5,
        child: Container(color: MeowTheme.navyBackground),
       ),
       Expanded(
        flex: 5,
        child: Container(color: MeowTheme.mustardYellow),
       ),
      ],
     ),

     // Content Pages
     SafeArea(
      child: Column(
       children: [
        // Top Flag / Language
        Padding(
         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
         child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
           Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
             color: MeowTheme.navyCard,
             borderRadius: BorderRadius.circular(16),
             border: Border.all(color: MeowTheme.borderColor),
            ),
            child: const Row(
             mainAxisSize: MainAxisSize.min,
             children: [
              Text(' ไทย', style: TextStyle(color: Colors.white, fontSize: 12)),
              Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
             ],
            ),
           ),
          ],
         ),
        ),

        // PageView
        Expanded(
         child: PageView.builder(
          controller: _pageController,
          onPageChanged: (idx) => setState(() => _currentPage = idx),
          itemCount: _slides.length,
          itemBuilder: (context, index) {
           final slide = _slides[index];
           return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
              const SizedBox(height: 16),
              Text(
               slide['title']!,
               style: const TextStyle(
                color: MeowTheme.textLightPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.3,
               ),
              ),
              const SizedBox(height: 12),
              Text(
               slide['subtitle']!,
               style: const TextStyle(
                color: MeowTheme.textLightSecondary,
                fontSize: 14,
                height: 1.4,
               ),
              ),
              const Spacer(),
              Center(
               child: MeowMascotWidget(size: 140, withPen: true),
              ),
              const Spacer(),
             ],
            ),
           );
          },
         ),
        ),

        // Dots indicator
        Row(
         mainAxisAlignment: MainAxisAlignment.center,
         children: List.generate(
          _slides.length,
          (idx) => Container(
           margin: const EdgeInsets.symmetric(horizontal: 4),
           width: _currentPage == idx ? 10 : 8,
           height: _currentPage == idx ? 10 : 8,
           decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == idx
              ? MeowTheme.actionBlue
              : Colors.white.withOpacity(0.5),
           ),
          ),
         ),
        ),
        const SizedBox(height: 20),

        // Navigation Buttons (ย้อนกลับ / ต่อไป)
        Padding(
         padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
         child: Row(
          children: [
           if (_currentPage > 0) ...[
            TextButton(
             onPressed: () {
              _pageController.previousPage(
               duration: const Duration(milliseconds: 300),
               curve: Curves.easeInOut,
              );
             },
             child: const Text(
              'ย้อนกลับ',
              style: TextStyle(
               color: MeowTheme.textDarkPrimary,
               fontSize: 16,
               fontWeight: FontWeight.bold,
              ),
             ),
            ),
            const Spacer(),
           ] else ...[
            const Spacer(),
           ],
           SizedBox(
            width: 140,
            height: 48,
            child: ElevatedButton(
             style: ElevatedButton.styleFrom(
              backgroundColor: MeowTheme.actionBlue,
              shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.circular(24),
              ),
             ),
             onPressed: _nextPage,
             child: Text(
              _currentPage == _slides.length - 1 ? 'เริ่มต้นใช้งาน' : 'ต่อไป',
              style: const TextStyle(
               color: Colors.white,
               fontSize: 16,
               fontWeight: FontWeight.bold,
              ),
             ),
            ),
           ),
          ],
         ),
        ),
        const SizedBox(height: 12),
       ],
      ),
     ),
    ],
   ),
  );
 }
}
