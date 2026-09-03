import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../widgets/bank_badge.dart';
import '../widgets/meow_mascot_widget.dart';
import 'main_navigation_screen.dart';

class FeatureSlideItem {
  final String emoji;
  final String tag;
  final String title;
  final String subtitle;
  final String description;
  final Color accentColor;
  final Widget Function(dynamic theme, bool isDark) previewBuilder;

  const FeatureSlideItem({
    required this.emoji,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.accentColor,
    required this.previewBuilder,
  });
}

class AppFeaturesShowcaseScreen extends StatefulWidget {
  final ExpenseController controller;
  final VoidCallback? onCompleted;
  final bool isFromOverview;

  const AppFeaturesShowcaseScreen({
    super.key,
    required this.controller,
    this.onCompleted,
    this.isFromOverview = false,
  });

  @override
  State<AppFeaturesShowcaseScreen> createState() => _AppFeaturesShowcaseScreenState();
}

class _AppFeaturesShowcaseScreenState extends State<AppFeaturesShowcaseScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<FeatureSlideItem> get _slides => [
    // Slide 1: Auto Slip Sync & 16 Banks OCR
    FeatureSlideItem(
      emoji: '🧾',
      tag: 'ระบบสแกนสลิป AI 0.3s',
      title: 'ดึงสลิปอัตโนมัติ 16 ธนาคาร',
      subtitle: 'สแกนยอด บัญชี วันที่ และบันทึกช่วยจำ (Memo) ทันที',
      description: 'เชื่อมโยงสลิปจาก 16 ธนาคารหลัก (กสิกร, ไทยพาณิชย์, กรุงไทย, กรุงเทพ, ทีทีบี, ออมสิน, กรุงศรี ฯลฯ) + เป๋าตัง + TrueMoney อ่านข้อมูลแม่นยำใน 0.3 วินาที พร้อมระบบกันสแกนซ้ำ 100% และบันทึกรูปเก็บไว้ถาวร',
      accentColor: const Color(0xFF10B981),
      previewBuilder: (theme, isDark) => _buildSlipPreview(theme, isDark),
    ),

    // Slide 2: Smart 2-Way Budgeting
    FeatureSlideItem(
      emoji: '📊',
      tag: 'คุมงบประมาณสองทาง HP/MP',
      title: 'วางแผนงบ & หลอดเกจพลังงาน',
      subtitle: 'เชื่อมโยงปุ่ม + อัตโนมัติ เตือนสถานะเงินสดๆ',
      description: 'กำหนดงบประมาณรายหมวดที่คุณต้องการได้อิสระ บันทึกรายจ่ายปุ๊บคำนวณหักงบทันที พร้อมหลอดเกจพลังงาน HP/MP เตือนสถานะ (ปกติ 🟢 / ใกล้เต็ม 🟡 / เกินงบ 🚨) ช่วยวางแผนไม่ให้เงินช็อตปลายเดือน',
      accentColor: const Color(0xFF3B82F6),
      previewBuilder: (theme, isDark) => _buildBudgetPreview(theme, isDark),
    ),

    // Slide 3: Financial Goals & Savings Roadmap
    FeatureSlideItem(
      emoji: '🎯',
      tag: 'เป้าหมายการเงิน & เงินออม',
      title: 'กระปุกเงินออม & แผนคำนวณอัจฉริยะ',
      subtitle: 'สร้างเป้าหมายในฝัน พร้อมปุ่มลัดหยอดเงิน 1 วินาที',
      description: 'ตั้งเป้าหมายการเงินได้ไม่จำกัด (เงินฉุกเฉิน, เที่ยว, ซื้อบ้าน/รถ, ปลดหนี้) มีปุ่มลัดหยอดเงินออมได้ทันที พร้อมเครื่องคิดเลขคำนวณวันบรรลุเป้าหมายและแผนเร่งสปีดการออมให้ถึงเป้าหมายได้เร็วขึ้น',
      accentColor: const Color(0xFFF59E0B),
      previewBuilder: (theme, isDark) => _buildGoalPreview(theme, isDark),
    ),

    // Slide 4: Thai Voice Assistant & Built-in Calculator
    FeatureSlideItem(
      emoji: '🎙️',
      tag: 'จดด้วยเสียง & เครื่องคิดเลขในตัว',
      title: 'พูดภาษาไทยบันทึกใน 1 วินาที',
      subtitle: 'AI แยกยอดเงินและจัดหมวดหมู่อัตโนมัติ',
      description: 'แตะปุ่มไมค์พูดภาษาไทย เช่น "กินข้าวขาหมู 65 บาท" หรือ "เติมน้ำมัน 800 บาท" ระบบ AI จะแปลงเสียงเป็นตัวเลขพร้อมเลือกหมวดหมู่ให้เสร็จสรรพ พร้อมแป้นพิมพ์เครื่องคิดเลขในตัว คำนวณบวกลบคูณหารได้ทันที',
      accentColor: const Color(0xFF06B6D4),
      previewBuilder: (theme, isDark) => _buildVoicePreview(theme, isDark),
    ),

    // Slide 5: Visual Analytics & PDF / Excel Export
    FeatureSlideItem(
      emoji: '📈',
      tag: 'วิเคราะห์การเงิน & ส่งออกสเตทเมนต์',
      title: 'รายงานสเตทเมนต์ PDF A4 & Excel',
      subtitle: 'ส่งตรงเข้า Downloads พร้อมเปิดดูและแชร์ทันที',
      description: 'ตรวจสุขภาพการเงินด้วยกราฟสัดส่วนรายรับ-รายจ่ายเชิงลึก ส่งออกรายงาน PDF สเตทเมนต์ A4 มาตรฐานพร้อมฟอนต์ไทยคมชัด หรือส่งออกไฟล์ Excel (UTF-8 BOM) เข้าโฟลเดอร์ Downloads โดยตรง พร้อมแชร์ส่งต่อได้ทันที',
      accentColor: const Color(0xFF8B5CF6),
      previewBuilder: (theme, isDark) => _buildExportPreview(theme, isDark),
    ),

    // Slide 6: Islamic Suite, Multi-Wallet, 18 Themes & 100% Private Offline
    FeatureSlideItem(
      emoji: '👑',
      tag: 'การเงินอิสลาม, 18 ธีม & ปลอดภัย 100%',
      title: 'ครบวงจร มัลติวอลเล็ต & ไพรเวท',
      subtitle: 'คำนวณซะกาต/มรดกฟาราอิฎ, 18 ธีม และไร้โฆษณา 100%',
      description: 'จัดการหลายกระเป๋าเงินพร้อมโลโก้จริงธนาคาร, เครื่องคิดเลขการเงินอิสลาม (ซะกาต & ฟาราอิฎ), 18 ธีม (คลาสสิค, Liquid Glass กระจกใส, น่ารัก) รองรับ Light/Dark mode และปลอดภัย 100% ข้อมูลอยู่ในเครื่อง ไร้โฆษณาคั่น',
      accentColor: const Color(0xFFEC4899),
      previewBuilder: (theme, isDark) => _buildUltimateSuitePreview(theme, isDark),
    ),
  ];

  void _onFinish() async {
    HapticFeedback.mediumImpact();
    await widget.controller.completeShowcase();
    widget.onCompleted?.call();

    if (!mounted) return;
    if (widget.isFromOverview) {
      Navigator.pop(context);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MainNavigationScreen(controller: widget.controller),
        ),
        (route) => false,
      );
    }
  }

  void _onNext() {
    HapticFeedback.selectionClick();
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = widget.controller.currentTheme;
    final isDark = widget.controller.isDarkMode;
    final slides = _slides;
    final isLastPage = _currentPage == slides.length - 1;

    return Scaffold(
      backgroundColor: currentTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.isFromOverview
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: currentTheme.textColor, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          widget.isFromOverview ? 'คู่มือระบบฟีเจอร์เด่นของแอพ' : 'จุดเด่นของเหมียวตังค์ (4/4)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: currentTheme.textColor,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _onFinish,
            child: Text(
              widget.isFromOverview ? 'ปิด' : 'ข้าม',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: currentTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Swipeable Carousel Area
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              itemCount: slides.length,
              itemBuilder: (context, idx) {
                final slide = slides[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: currentTheme.cardBackground,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: currentTheme.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: slide.accentColor.withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Badge & Emoji
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: slide.accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(slide.emoji, style: const TextStyle(fontSize: 22)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: slide.accentColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      slide.tag,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: slide.accentColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    slide.title,
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.bold,
                                      color: currentTheme.textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Subtitle & Description text
                        Text(
                          slide.subtitle,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: slide.accentColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          slide.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: currentTheme.textSecondaryColor,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Visual Mockup Preview Box
                        Expanded(
                          child: Center(
                            child: slide.previewBuilder(currentTheme, isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Navigation & Page Indicators
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Dots Indicator
                Row(
                  children: List.generate(slides.length, (i) {
                    final isSel = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 5),
                      width: isSel ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSel ? currentTheme.primaryColor : currentTheme.borderColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),

                // Next / Finish Button
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      elevation: 0,
                    ),
                    iconAlignment: IconAlignment.end,
                    icon: Icon(isLastPage ? Icons.auto_awesome_rounded : Icons.arrow_forward_rounded, size: 16),
                    label: Text(
                      isLastPage ? 'เข้าสู่เหมียวตังค์ ✨' : 'ถัดไป (${_currentPage + 1}/6)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- MOCKUP PREVIEWS ---

  // Preview 1: Slip Card with 16 Banks
  static Widget _buildSlipPreview(dynamic currentTheme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: currentTheme.surfaceBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: currentTheme.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BankBadge(bankCode: 'KBANK', size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('กสิกรไทย (K PLUS)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
                    Text('ดึงสลิปอัตโนมัติ 16 ธนาคาร', style: TextStyle(fontSize: 10, color: currentTheme.textSecondaryColor)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('✓ สแกน 0.3s', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
              ),
            ],
          ),
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ยอดโอนเงิน:', style: TextStyle(fontSize: 11, color: currentTheme.textSecondaryColor)),
              const Text('฿ 450.00', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('บันทึกช่วยจำ:', style: TextStyle(fontSize: 11, color: currentTheme.textSecondaryColor)),
              Text('ค่าอาหารเที่ยงกับทีม 🍜', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
            ],
          ),
        ],
      ),
    );
  }

  // Preview 2: Budget Bar
  static Widget _buildBudgetPreview(dynamic currentTheme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: currentTheme.surfaceBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: currentTheme.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('หลอดงบประมาณสองทาง (HP/MP)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('✓ ปกติ', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildMiniGaugeRow('🍔 ค่าอาหาร', 0.45, '45%', const Color(0xFF10B981), currentTheme),
          const SizedBox(height: 5),
          _buildMiniGaugeRow('🚗 ค่าน้ำมัน', 0.85, '85%', const Color(0xFFF59E0B), currentTheme),
          const SizedBox(height: 5),
          _buildMiniGaugeRow('🛍️ ช้อปปิ้ง', 1.0, '🚨 เกินงบ', const Color(0xFFEF4444), currentTheme),
        ],
      ),
    );
  }

  static Widget _buildMiniGaugeRow(String name, double progress, String pct, Color color, dynamic currentTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
            Text(pct, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 4.5,
            backgroundColor: currentTheme.cardBackground,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // Preview 3: Goal Card
  static Widget _buildGoalPreview(dynamic currentTheme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: currentTheme.surfaceBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: currentTheme.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Text('🛡️', style: TextStyle(fontSize: 15)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('เงินสำรองฉุกเฉิน 6 เดือน', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
                    Text('เก็บได้แล้ว ฿45,000 / ฿100,000', style: TextStyle(fontSize: 10, color: currentTheme.textSecondaryColor)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: const Text('45%', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: const LinearProgressIndicator(
              value: 0.45,
              minHeight: 4.5,
              backgroundColor: Colors.grey,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(color: currentTheme.cardBackground, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 10)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('ออมวันละ ฿200 จะถึงเป้าใน 275 วัน (มีปุ่มลัดหยอดเงิน)', style: TextStyle(fontSize: 9.5, color: currentTheme.textColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Preview 4: Voice & Calculator
  static Widget _buildVoicePreview(dynamic currentTheme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: currentTheme.surfaceBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: currentTheme.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFF06B6D4), shape: BoxShape.circle),
                child: const Icon(Icons.mic_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('"กินข้าวขาหมู 65 บาท"', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
                    Text('AI แปลงเสียง & จัดหมวดหมู่ใน 1s', style: TextStyle(fontSize: 9.5, color: currentTheme.textSecondaryColor)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF06B6D4).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: const Text('🍔 อาหาร', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF0891B2))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: currentTheme.cardBackground, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🧮 แป้นพิมพ์เครื่องคิดเลขในตัว:', style: TextStyle(fontSize: 9.5, color: currentTheme.textSecondaryColor)),
                Text('65 + 15 = ฿80', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Preview 5: Export Card
  static Widget _buildExportPreview(dynamic currentTheme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: currentTheme.surfaceBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: currentTheme.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('รายงานสเตทเมนต์ PDF A4 & Excel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
                    Text('📁 Downloads / MeowTang /', style: TextStyle(fontSize: 9.5, color: currentTheme.textSecondaryColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(color: currentTheme.primaryColor, borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: const Text('📄 เปิดไฟล์ทันที', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(color: currentTheme.cardBackground, borderRadius: BorderRadius.circular(8), border: Border.all(color: currentTheme.borderColor)),
                  alignment: Alignment.center,
                  child: Text('📤 แชร์ส่งต่อ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Preview 6: Islamic Suite & Security & 18 Themes
  static Widget _buildUltimateSuitePreview(dynamic currentTheme, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const MeowMascotWidget(size: 48, isHeadOnly: false),
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            _buildSecurityTag('🕌 คำนวณซะกาต & มรดก', currentTheme),
            _buildSecurityTag('🎨 18 ธีม + Liquid Glass', currentTheme),
            _buildSecurityTag('☀️/🌙 Light & Dark', currentTheme),
            _buildSecurityTag('🔒 ไพรเวท 100% ไร้โฆษณา', currentTheme),
          ],
        ),
      ],
    );
  }

  static Widget _buildSecurityTag(String text, dynamic currentTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: currentTheme.surfaceBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: currentTheme.borderColor),
      ),
      child: Text(text, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
    );
  }
}
