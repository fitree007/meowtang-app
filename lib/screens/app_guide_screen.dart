import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../widgets/meow_mascot_widget.dart';
import '../widgets/tactile_button.dart';

class AppGuideScreen extends StatefulWidget {
  final ExpenseController controller;
  final VoidCallback? onFinish;

  const AppGuideScreen({
    super.key,
    required this.controller,
    this.onFinish,
  });

  @override
  State<AppGuideScreen> createState() => _AppGuideScreenState();
}

class _AppGuideScreenState extends State<AppGuideScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedLang = 'th';

  @override
  void initState() {
    super.initState();
    _selectedLang = widget.controller.guideLanguage;
  }

  void _onLangChanged(String lang) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedLang = lang;
    });
    widget.controller.setGuideLanguage(lang);
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _getGuideSteps().length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishGuide();
    }
  }

  void _finishGuide() {
    HapticFeedback.mediumImpact();
    widget.controller.completeAppGuide();
    if (widget.onFinish != null) {
      widget.onFinish!();
    } else {
      Navigator.pop(context);
    }
  }

  List<Map<String, dynamic>> _getGuideSteps() {
    switch (_selectedLang) {
      case 'en':
        return [
          {
            'icon': Icons.sync_rounded,
            'color': const Color(0xFF10B981),
            'title': '1. Auto Slip Sync (Banks & PaoTang)',
            'badge': 'Guide 1 of 10 • Auto Sync',
            'desc': 'Real-time background detector that automatically captures new bank transfer slips from 12+ Thai banks and the Pictures/PaoTang directory (e.g. Thai Chuey Thai 60/40, iBank, State Welfare).',
            'setup': '⚙️ Setup & How to use:\n1. Grant "Photos & Media Permission" in system settings.\n2. When you save or download a transfer slip from banking apps or PaoTang, the app auto-imports it instantly.\n3. Tap "Auto-Sync Slips" button on Dashboard or pull-to-refresh to run a manual storage scan anytime.',
            'tip': '💡 100% smart duplicate prevention ensures no slip is recorded twice.',
          },
          {
            'icon': Icons.verified_rounded,
            'color': const Color(0xFF06B6D4),
            'title': '2. Real-Time Online Slip Verifier',
            'badge': 'Guide 2 of 10 • ITMX Bank Check',
            'desc': 'Verify bank slip authenticity directly with the Thai Interbank ITMX Clearing System. Checks if the transfer actually occurred to prevent fake and photoshopped slips.',
            'setup': '⚙️ How to use:\n1. Tap the floating Arrow Up button (Quick Menu) at bottom right of Dashboard.\n2. Select "Online Slip Verifier ⚡".\n3. Pick an image containing a PromptPay QR code. Real-time bank data is retrieved instantly with 1-tap save.',
            'tip': '💡 Requires clear QR code and internet connection for live bank handshake.',
          },
          {
            'icon': Icons.document_scanner_rounded,
            'color': const Color(0xFF8B5CF6),
            'title': '3. 100% Offline Dual-Engine OCR',
            'badge': 'Guide 3 of 10 • Offline Scanner',
            'desc': 'Extract amount, date/time, sender, and receiver from bank slips completely offline. No internet required, zero ads, and 100% private data kept only on your device.',
            'setup': '⚙️ How to use:\n1. Tap Arrow Up Menu > "Pick Slip Image (OCR)".\n2. Choose any slip photo from your gallery. AI extracts the transaction in under a second.',
            'tip': '💡 Built-in Self-Transfer Filter automatically skips transfers between your own accounts.',
          },
          {
            'icon': Icons.swipe_rounded,
            'color': const Color(0xFF3B82F6),
            'title': '4. Swipe Actions & Live Countdown Undo',
            'badge': 'Guide 4 of 10 • Gestures & Undo',
            'desc': 'Manage transactions at lightning speed using fluid swipe gestures, protected by a live 5-second countdown batch undo system.',
            'setup': '⚙️ How to use:\n• 👉 Swipe Right: Opens the Edit Transaction screen.\n• 👈 Swipe Left: Quick Delete (Shows animated 5s countdown bar).\n• ⏱️ Tap "Undo" anytime during the 5s timer to instantly restore all deleted items.',
            'tip': '💡 You can swipe-delete multiple items quickly; the batch undo bar collects them all together.',
          },
          {
            'icon': Icons.mosque_rounded,
            'color': const Color(0xFF14B8A6),
            'title': '5. Islamic Halal Finance & Gold Zakat',
            'badge': 'Guide 5 of 10 • Halal Finance',
            'desc': 'Calculate Gold Zakat with real-time live gold prices from Gold Traders Association, track Halal Rizqi blessings, calculate inheritance, and isolate non-halal interests.',
            'setup': '⚙️ How to use:\n1. Open Profile (Human) Menu > "Islamic Finance & Gold Zakat".\n2. Enter your gold weight (Baht/Grams). The system automatically evaluates the Nisab threshold and computes 2.5% Zakat dues.',
            'tip': '💡 Includes a dedicated log to track Sadaqah charity and Zakat disbursements.',
          },
          {
            'icon': Icons.mic_rounded,
            'color': const Color(0xFFEC4899),
            'title': '6. Thai Voice AI Assistant',
            'badge': 'Guide 6 of 10 • Voice AI',
            'desc': 'Speak naturally in Thai or English to log expenses in 2 seconds without typing. Natural Language Processing classifies category and amount automatically.',
            'setup': '⚙️ How to use:\n1. Grant Microphone Permission.\n2. Tap Arrow Up Menu > "Voice Record with AI".\n3. Say e.g. "Lunch 65 baht from KBank" or "Coffee 50". AI automatically creates the transaction.',
            'tip': '💡 Mentioning bank/wallet names automatically routes the expense to that specific account.',
          },
          {
            'icon': Icons.account_balance_rounded,
            'color': const Color(0xFFF59E0B),
            'title': '7. Nationwide Bank Filter',
            'badge': 'Guide 7 of 10 • Bank Filter',
            'desc': 'Filter transactions and monthly totals by specific Thai banks (KBank, SCB, KTB, BBL, iBank, PaoTang, etc.) with real-time balance calculations.',
            'setup': '⚙️ How to use:\n1. In Dashboard, tap the "Bank Filter" chip button.\n2. Check/uncheck specific banks to show or hide their transaction history and totals.',
            'tip': '💡 Use "Select All / Deselect All" for rapid multi-bank switching.',
          },
          {
            'icon': Icons.calculate_rounded,
            'color': const Color(0xFF6366F1),
            'title': '8. Built-in Calculator & XL Input',
            'badge': 'Guide 8 of 10 • Calculator Numpad',
            'desc': 'Extra-large input display with live mathematical arithmetic (+, -, ×, ÷) right inside the recording pad without switching apps.',
            'setup': '⚙️ How to use:\n1. Tap "+" or "Add Record" to open the entry screen.\n2. Enter expressions like 50+20*3 and tap "=" to evaluate live total before saving.',
            'tip': '💡 Supports horizontal scrolling for lengthy multi-item expense chains.',
          },
          {
            'icon': Icons.insights_rounded,
            'color': const Color(0xFF0284C7),
            'title': '9. 2-Month Deep Analytics & AI Verdict',
            'badge': 'Guide 9 of 10 • Analytics',
            'desc': 'Compare spending patterns between any two months with AI Smart Verdict, daily burn rates, and savings delta bars.',
            'setup': '⚙️ How to use:\n1. Navigate to "Analytics" tab in bottom navigation.\n2. Select Month A and Month B to inspect comparative charts and category spikes.',
            'tip': '💡 Filter for "Saved Categories" to see where you succeeded in budget trimming.',
          },
          {
            'icon': Icons.backup_rounded,
            'color': const Color(0xFF10B981),
            'title': '10. Excel / CSV Export & Device Backup',
            'badge': 'Guide 10 of 10 • Data & Backup',
            'desc': 'Export professional financial statements to Excel (.xlsx) / CSV and create encrypted device backups for 100% data portability.',
            'setup': '⚙️ How to use:\n1. Open Profile (Human) Menu > "Export Excel / CSV" or "Backup & Restore".\n2. Tap "Export / Share File" to save or send your financial spreadsheet.',
            'tip': '💡 All data stays 100% offline on your phone; regular backups ensure peace of mind.',
          },
        ];

      default: // 'th' (Thai)
        return [
          {
            'icon': Icons.sync_rounded,
            'color': const Color(0xFF10B981),
            'title': '1. ดึงสลิปอัตโนมัติจากธนาคาร & เป๋าตัง',
            'badge': 'คู่มือ 1 จาก 10 • ระบบดึงสลิป',
            'desc': 'ระบบตรวจจับสลิปใหม่จากอัลบั้มรูปภาพของ 12+ ธนาคารชั้นนำ และโฟลเดอร์ Pictures/PaoTang (เช่น สลิปไทยช่วยไทย 60/40, คนละครึ่ง, สวัสดิการแห่งรัฐ, ธนาคารอิสลาม iBank) ทันทีเมื่อเซฟรูป พร้อมระบบป้องกันบันทึกสลิปซ้ำ 100%',
            'setup': '⚙️ วิธีการตั้งค่า & ใช้งาน:\n1. ตรวจสอบว่าได้อนุญาต "สิทธิ์การเข้าถึงรูปภาพ (Photos & Media)" ในการตั้งค่าเครื่อง\n2. เมื่อเซฟรูปสลิปจากแอพธนาคารหรือเป๋าตัง ระบบจะดึงและบันทึกรายการให้อัตโนมัติทันที\n3. ในหน้าภาพรวม สามารถกดปุ่ม "ดึงสลิปอัตโนมัติ" หรือรูดหน้าจอลง (Pull-to-refresh) เพื่อสแกนสลิปย้อนหลังได้ตลอดเวลา',
            'tip': '💡 ระบบฉลาดจะอ่านยอดที่ชำระจริง (Net Paid) และข้ามการโอนเงินให้ตัวเองให้อัตโนมัติ',
          },
          {
            'icon': Icons.verified_rounded,
            'color': const Color(0xFF06B6D4),
            'title': '2. ตรวจสลิปแท้ออนไลน์ Real-Time (ITMX)',
            'badge': 'คู่มือ 2 จาก 10 • เช็คสลิปแท้',
            'desc': 'ตรวจสอบความถูกต้องของสลิปโอนเงินโดยตรงกับระบบกลางโครงข่ายธนาคารไทย (ITMX) ยืนยันว่ามีการโอนเงินจริง ป้องกันสลิปปลอมและภาพตัดต่อ 100% พร้อมปุ่มบันทึกเข้าระบบใน 1 แตะ',
            'setup': '⚙️ วิธีการใช้งาน:\n1. แตะปุ่มลูกศรขึ้น (เมนูด่วน) ที่มุมขวาล่างของหน้าภาพรวม\n2. เลือกเมนู "ตรวจสลิปแท้ออนไลน์ ⚡"\n3. เลือกรูปภาพสลิปที่มี QR Code หรือสแกนสด ระบบจะดึงข้อมูลจริงจากธนาคารมาแสดงทันที',
            'tip': '💡 จำเป็นต้องมีการเชื่อมต่ออินเทอร์เน็ตในการส่งคำขอตรวจสอบไปยังระบบกลางธนาคาร',
          },
          {
            'icon': Icons.document_scanner_rounded,
            'color': const Color(0xFF8B5CF6),
            'title': '3. สแกนสลิปออฟไลน์ 100% (Dual-Engine OCR)',
            'badge': 'คู่มือ 3 จาก 10 • OCR ออฟไลน์',
            'desc': 'ถอดรหัสยอดเงิน วันที่ บัญชี และบันทึกช่วยจำจากภาพสลิปได้แบบออฟไลน์ 100% ไม่ต้องต่อเน็ต ฟรีตลอดชีพ ข้อมูลรูปและตัวเลขทั้งหมดถูกประมวลผลในเครื่องคุณเท่านั้น ปลอดภัยสูงสุด',
            'setup': '⚙️ วิธีการใช้งาน:\n1. แตะปุ่มลูกศรขึ้นที่มุมขวาล่าง > เลือก "เลือกรูปสลิปจากคลังภาพ (OCR)"\n2. เลือกรูปสลิปที่ต้องการ ระบบจะสกัดยอดเงิน วันที่ และจัดหมวดหมู่ให้อัตโนมัติใน 1 วินาที',
            'tip': '💡 ระบบคัดกรองการโอนเงินให้ตัวเอง (Self-Transfer Filter) ช่วยให้ยอดรายรับ-รายจ่ายไม่เบิ้ลซ้ำซ้อน',
          },
          {
            'icon': Icons.swipe_rounded,
            'color': const Color(0xFF3B82F6),
            'title': '4. การปัดรายการ & ระบบนับถอยหลังยกเลิก (Undo)',
            'badge': 'คู่มือ 4 จาก 10 • ท่าทาง & เลิกทำ',
            'desc': 'จัดการรายการได้อย่างรวดเร็วด้วยการปัดนิ้ว พร้อมระบบนับเวลาถอยหลัง 5 วินาทีแบบสดๆ ป้องกันการเผลอลบพลาด และรองรับการกู้คืนเป็นชุด',
            'setup': '⚙️ วิธีการใช้งาน:\n• 👉 ปัดขวา: เข้าสู่หน้าต่างแก้ไขรายการ (Edit Transaction)\n• 👈 ปัดซ้าย: ลบรายการด่วน (จะมีแถบสีเข้มนับถอยหลัง 5... 4... 3...)\n• ⏱️ กด "เลิกทำ (Undo)" ได้ตลอดเวลาก่อนหมดเวลา 5 วินาที เพื่อดึงรายการทั้งหมดกลับคืนมา',
            'tip': '💡 สามารถปัดลบหลายรายการต่อเนื่องได้ ระบบจะรวมเป็นชุดและนับเวลาถอยหลังให้',
          },
          {
            'icon': Icons.mosque_rounded,
            'color': const Color(0xFF14B8A6),
            'title': '5. การเงินอิสลาม & ซะกาตทองคำ Real-Time',
            'badge': 'คู่มือ 5 จาก 10 • การเงินฮาลาล',
            'desc': 'คำนวณซะกาตทองคำแท่งและรูปพรรณตามราคาทองคำสมาคมค้าทองคำสดๆ, จัดการเงินริซกี, คำนวณมรดก และตัดดอกเบี้ยตามหลักชะรีอะฮ์อย่างถูกต้อง',
            'setup': '⚙️ วิธีการตั้งค่า & ใช้งาน:\n1. ไปที่เมนูโปรไฟล์ (คน) > เลือก "การเงินอิสลาม & ซะกาตทองคำ"\n2. ใส่น้ำหนักทองคำที่มี (บาท/กรัม) ระบบจะคำนวณเปรียบเทียบพิกัดนิศอบ (Nisab) และแสดงยอดซะกาต 2.5% ที่ต้องจ่ายทันที',
            'tip': '💡 มีบันทึกประวัติการจ่ายซะกาตและการทำทาน (ศอดะเกาะฮ์) แยกไว้อย่างเป็นระเบียบ',
          },
          {
            'icon': Icons.mic_rounded,
            'color': const Color(0xFFEC4899),
            'title': '6. สั่งจดด้วยเสียง AI ภาษาไทยธรรมชาติ',
            'badge': 'คู่มือ 6 จาก 10 • AI สั่งด้วยเสียง',
            'desc': 'บันทึกรายรับ-รายจ่ายได้เร็วที่สุดโดยไม่ต้องพิมพ์ เพียงพูดภาษาไทยสั้นๆ ระบบ AI NLP จะสกัดยอดเงิน หมวดหมู่ และบัญชีให้อัตโนมัติใน 2 วินาที',
            'setup': '⚙️ วิธีการตั้งค่า & ใช้งาน:\n1. ตรวจสอบว่าได้อนุญาต "สิทธิ์ไมโครโฟน (Microphone)" ในเครื่อง\n2. แตะปุ่มลูกศรขึ้น > เลือก "พูดเพื่อจดบันทึกด้วย AI"\n3. พูดสั้นๆ เช่น "กินข้าว 65 บาท", "เติมน้ำมัน 500 โอนจากกสิกร" ระบบจะสร้างรายการให้ทันใจ',
            'tip': '💡 การระบุชื่อธนาคารในประโยคจะช่วยให้ AI เลือกลงบัญชีเงินฝากนั้นให้อัตโนมัติ',
          },
          {
            'icon': Icons.account_balance_rounded,
            'color': const Color(0xFFF59E0B),
            'title': '7. แยกสลิปตามธนาคารทั่วประเทศ (Bank Filter)',
            'badge': 'คู่มือ 7 จาก 10 • ตัวกรองธนาคาร',
            'desc': 'กรองดูรายการและยอดเงินรวมแยกเฉพาะธนาคารที่ต้องการ เช่น ดูเฉพาะยอดกสิกร, ไทยพาณิชย์, กรุงไทย, เป๋าตัง หรือดูทุกธนาคารพร้อมกัน',
            'setup': '⚙️ วิธีการใช้งาน:\n1. ในหน้าภาพรวม แตะปุ่ม "แยกตามธนาคาร (Bank Filter)"\n2. ติ๊กเลือกเปิด/ปิดธนาคารที่ต้องการแสดงผล ยอดรวมและประวัติจะคำนวณใหม่สดๆ ทันที',
            'tip': '💡 ใช้ปุ่ม "เลือกทั้งหมด / ยกเลิกทั้งหมด" ด้านล่างเพื่อสลับดูภาพรวมได้อย่างรวดเร็ว',
          },
          {
            'icon': Icons.calculate_rounded,
            'color': const Color(0xFF6366F1),
            'title': '8. แป้นพิมพ์คิดเลข & ช่องระบุยอดขนาดใหญ่',
            'badge': 'คู่มือ 8 จาก 10 • แป้นพิมพ์คำนวณ',
            'desc': 'คำนวณตัวเลขบวก ลบ คูณ หาร ได้ในตัว พร้อมช่องแสดงผลขนาดใหญ่พิเศษที่เลื่อนดูแนวนอนได้เมื่อมีรายการบวกเลขยาวๆ',
            'setup': '⚙️ วิธีการใช้งาน:\n1. แตะปุ่ม "+" หรือ "จดบันทึก" เพื่อเปิดแป้นพิมพ์\n2. พิมพ์สูตร เช่น 120+45+60 แล้วกด = เพื่อรวมยอดเงินทันทีโดยไม่ต้องสลับแอพ',
            'tip': '💡 สลับแท็บ "รายจ่าย", "รายรับ", และ "โอนเงิน" ได้ที่แถบด้านบนของหน้าต่าง',
          },
          {
            'icon': Icons.insights_rounded,
            'color': const Color(0xFF0284C7),
            'title': '9. วิเคราะห์การเงินเชิงลึก & เปรียบเทียบ 2 เดือน',
            'badge': 'คู่มือ 9 จาก 10 • วิเคราะห์การเงิน',
            'desc': 'เปรียบเทียบพฤติกรรมการใช้จ่ายระหว่าง 2 เดือน พร้อมบทวิเคราะห์ AI Smart Verdict, ค่าเฉลี่ยใช้จ่ายต่อวัน และหมวดหมู่ที่ประหยัดลง',
            'setup': '⚙️ วิธีการใช้งาน:\n1. ไปที่แท็บ "วิเคราะห์ (Analytics)" ที่เมนูด้านล่าง\n2. เลือก เดือน A และ เดือน B ที่ต้องการเปรียบเทียบเพื่อดูความเปลี่ยนแปลงของเงินเก็บ',
            'tip': '💡 กดกรองดูเฉพาะ "หมวดที่ประหยัดขึ้น" เพื่อดูความสำเร็จในการคุมงบประมาณของคุณ',
          },
          {
            'icon': Icons.backup_rounded,
            'color': const Color(0xFF10B981),
            'title': '10. ส่งออกรายงาน Excel/CSV & สำรองข้อมูล',
            'badge': 'คู่มือ 10 จาก 10 • สำรอง & ส่งออก',
            'desc': 'ส่งออกรายงานบัญชี Statement รายรับรายจ่าย และหมวดหมู่ภาษีเป็นไฟล์ Excel (.xlsx) / CSV พร้อมระบบสำรองข้อมูลในเครื่องเพื่อความปลอดภัย 100%',
            'setup': '⚙️ วิธีการตั้งค่า & ใช้งาน:\n1. ไปที่เมนูโปรไฟล์ (คน) > "ส่งออก Excel / CSV" หรือ "สำรอง & กู้คืนข้อมูล"\n2. เลือกช่วงเวลาที่ต้องการ แล้วกด "แชร์ / ส่งออกไฟล์"\n3. สามารถนำไฟล์สำรองข้อมูลมากด "กู้คืน (Restore)" เมื่อเปลี่ยนเครื่องใหม่ได้ทันที',
            'tip': '💡 ข้อมูลทั้งหมดอยู่ในเครื่องคุณ 100% แนะนำให้กดส่งออกไฟล์สำรองเก็บไว้เป็นระยะ',
          },
        ];
    }
  }

  String _getButtonNextText() {
    final isLast = _currentPage == _getGuideSteps().length - 1;
    switch (_selectedLang) {
      case 'en':
        return isLast ? 'Got it! Start using app 🚀' : 'Next Tip ➔';
      default:
        return isLast ? 'เข้าใจแล้ว เริ่มต้นใช้งาน 🚀' : 'คำแนะนำถัดไป ➔';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = widget.controller.currentTheme;
    final isDark = widget.controller.isDarkMode;
    final steps = _getGuideSteps();

    return Scaffold(
      backgroundColor: currentTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: currentTheme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: currentTheme.textColor, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _selectedLang == 'en' ? 'App User Guide & Manual' : 'คู่มือและวิธีใช้งานแอพ',
          style: TextStyle(
            color: currentTheme.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Step Counter Badge
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: currentTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentPage + 1} / ${steps.length}',
              style: TextStyle(
                color: currentTheme.primaryColor,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Language Selection Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildLangTab('th', '🇹🇭 ภาษาไทย', currentTheme)),
                    const SizedBox(width: 4),
                    Expanded(child: _buildLangTab('en', '🇬🇧 English', currentTheme)),
                  ],
                ),
              ),
            ),

            // Page Indicator Dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  steps.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: _currentPage == index ? 22 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? currentTheme.primaryColor
                          : currentTheme.textSecondaryColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),

            // Main Content PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: steps.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final step = steps[index];
                  final Color stepColor = step['color'] as Color;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: currentTheme.cardBackground,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: stepColor.withValues(alpha: isDark ? 0.35 : 0.25),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: stepColor.withValues(alpha: isDark ? 0.12 : 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Icon + Badge
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [stepColor, stepColor.withValues(alpha: 0.75)],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: stepColor.withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    step['icon'] as IconData,
                                    size: 26,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: stepColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          step['badge'] as String,
                                          style: TextStyle(
                                            color: stepColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        step['title'] as String,
                                        style: TextStyle(
                                          color: currentTheme.textColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Description
                            Text(
                              step['desc'] as String,
                              style: TextStyle(
                                color: currentTheme.textColor,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Setup / How-to Box
                            if (step['setup'] != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: currentTheme.borderColor.withValues(alpha: 0.6),
                                  ),
                                ),
                                child: Text(
                                  (step['setup'] as String).replaceAll('\\n', '\n'),
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 12),

                            // Tip Box
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: stepColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: stepColor.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                step['tip'] as String,
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Bottom Navigation Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  if (_currentPage > 0) ...[
                    TactileButton(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: currentTheme.surfaceBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: currentTheme.borderColor),
                        ),
                        child: Icon(Icons.arrow_back, size: 20, color: currentTheme.textColor),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: TactileButton(
                      onTap: _nextPage,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF38BDF8), Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _getButtonNextText(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangTab(String langCode, String label, dynamic currentTheme) {
    final isSelected = _selectedLang == langCode;

    return TactileButton(
      onTap: () => _onLangChanged(langCode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? currentTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: currentTheme.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : currentTheme.textSecondaryColor,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
