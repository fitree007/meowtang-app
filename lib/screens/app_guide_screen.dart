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
            'title': '1. Auto Slip Sync (22 Banks & PaoTang)',
            'badge': 'Guide 1 of 12 • Auto Sync',
            'desc': 'Real-time background detector that automatically captures new bank transfer slips from 22 Thai banks and digital wallets (KBank, SCB, KTB, iBank, BBL, TTB, GSB, BAY, CIMB, UOB, TMRW, LHB, KKP, GHB, Tisco, PaoTang, TrueMoney, etc.).',
            'setup': '⚙️ Setup & How to use:\n1. Grant "Photos & Media Permission" in device settings.\n2. When you save or download a transfer slip, the app auto-imports it instantly.\n3. Pull-down to refresh on the Overview screen anytime to reload all data and scan new slips without restarting the app.',
            'tip': '💡 100% smart duplicate prevention ensures no slip is recorded twice.',
          },
          {
            'icon': Icons.verified_rounded,
            'color': const Color(0xFF06B6D4),
            'title': '2. Real-Time Online Slip Verifier',
            'badge': 'Guide 2 of 12 • ITMX Bank Check',
            'desc': 'Verify bank slip authenticity directly with the Thai Interbank ITMX Clearing System. Checks if the transfer actually occurred to prevent fake and photoshopped slips.',
            'setup': '⚙️ How to use:\n1. Tap the floating Arrow Up button (Quick Menu) at bottom right of Dashboard.\n2. Select "Online Slip Verifier ⚡".\n3. Pick an image containing a PromptPay QR code. Real-time bank data is retrieved instantly with 1-tap save.',
            'tip': '💡 Requires clear QR code and internet connection for live bank handshake.',
          },
          {
            'icon': Icons.document_scanner_rounded,
            'color': const Color(0xFF8B5CF6),
            'title': '3. 100% Offline OCR & Auto Amount Fill',
            'badge': 'Guide 3 of 12 • Offline Scanner',
            'desc': 'Extract amount, date/time, sender, receiver, and transfer memo from bank slips completely offline. Also automatically fills the amount into the calculator when picking a slip on the "+" screen!',
            'setup': '⚙️ How to use:\n1. On the "+" entry screen, tap "+ Slip" to pick a receipt. The amount fills into the keypad automatically.\n2. Or tap Arrow Up Menu > "Pick Slip Image (OCR)" to process any slip photo in under a second.',
            'tip': '💡 100% private offline engine keeps all your financial images securely on your device.',
          },
          {
            'icon': Icons.swipe_rounded,
            'color': const Color(0xFF3B82F6),
            'title': '4. Swipe Actions & Live Countdown Undo',
            'badge': 'Guide 4 of 12 • Gestures & Undo',
            'desc': 'Manage transactions at lightning speed using fluid swipe gestures, protected by a live 5-second countdown batch undo system.',
            'setup': '⚙️ How to use:\n• 👉 Swipe Right: Opens the Edit Transaction screen.\n• 👈 Swipe Left: Quick Delete (Shows animated 5s countdown bar).\n• ⏱️ Tap "Undo" anytime during the 5s timer to instantly restore all deleted items.',
            'tip': '💡 You can swipe-delete multiple items quickly; the batch undo bar collects them all together.',
          },
          {
            'icon': Icons.subscriptions_rounded,
            'color': const Color(0xFF6366F1),
            'title': '5. Subscription & Recurring Bills Vault',
            'badge': 'Guide 5 of 12 • Subscription Vault',
            'desc': 'Centralized control center for Netflix, YouTube, Spotify, iCloud, insurance, home rent, and recurring utility bills with renewal alarms and active spending summary.',
            'setup': '⚙️ How to use:\n1. Open Profile / Premium > "Manage Subscription & Recurring Bills".\n2. Add services, specify cycle (Monthly/Yearly), renewal date, and alert days.\n3. Keep track of total monthly expenditure and receive alerts before you get billed.',
            'tip': '💡 Easily sort by next payment date, highest cost, or category, and mark bills as paid in 1 tap.',
          },
          {
            'icon': Icons.currency_exchange_rounded,
            'color': const Color(0xFFEAB308),
            'title': '6. Real-Time Currency & Precious Metals',
            'badge': 'Guide 6 of 12 • Live Rates & Metals',
            'desc': 'Live global exchange rates for 30+ foreign currencies and precious metals (Gold, Silver, Platinum, Palladium) with daily interactive price trend charts and historical lookup.',
            'setup': '⚙️ How to use:\n1. Open Profile / Premium > "Currency Converter & Calculator" or "Precious Metals Calculator".\n2. View daily live spot rates, compare price movements over time, and convert values instantly.',
            'tip': '💡 Includes daily historical chart points and live update badges without leaving the app.',
          },
          {
            'icon': Icons.mosque_rounded,
            'color': const Color(0xFF14B8A6),
            'title': '7. Islamic Halal Finance & Gold Zakat',
            'badge': 'Guide 7 of 12 • Halal Finance',
            'desc': 'Calculate Gold Zakat with real-time live gold prices from Gold Traders Association, track Halal Rizqi blessings, calculate inheritance, and isolate non-halal interests.',
            'setup': '⚙️ How to use:\n1. Open Profile (Human) Menu > "Islamic Finance & Gold Zakat".\n2. Enter your gold weight (Baht/Grams). The system automatically evaluates the Nisab threshold and computes 2.5% Zakat dues.',
            'tip': '💡 Includes a dedicated log to track Sadaqah charity and Zakat disbursements.',
          },
          {
            'icon': Icons.mic_rounded,
            'color': const Color(0xFFEC4899),
            'title': '8. Thai Voice AI Assistant',
            'badge': 'Guide 8 of 12 • Voice AI',
            'desc': 'Speak naturally in Thai or English to log expenses in 2 seconds without typing. Natural Language Processing classifies category and amount automatically.',
            'setup': '⚙️ How to use:\n1. Grant Microphone Permission.\n2. Tap Arrow Up Menu > "Voice Record with AI".\n3. Say e.g. "Lunch 65 baht from KBank" or "Coffee 50". AI automatically creates the transaction.',
            'tip': '💡 Mentioning bank/wallet names automatically routes the expense to that specific account.',
          },
          {
            'icon': Icons.account_balance_rounded,
            'color': const Color(0xFFF59E0B),
            'title': '9. Nationwide Bank Filter & Multi-Accounts',
            'badge': 'Guide 9 of 12 • Bank Accounts',
            'desc': 'Filter transactions and monthly totals by specific Thai banks (KBank, SCB, KTB, BBL, iBank, PaoTang, etc.) and manage separate bank accounts with real official bank logos.',
            'setup': '⚙️ How to use:\n1. In Dashboard, tap the "Bank Filter" chip button to filter history by bank.\n2. Open "Accounts" to manage separate wallets matched directly to your actual bank cards.',
            'tip': '💡 Slips are automatically linked to the sender bank account.',
          },
          {
            'icon': Icons.calculate_rounded,
            'color': const Color(0xFF8B5CF6),
            'title': '10. Built-in Calculator & XL Input',
            'badge': 'Guide 10 of 12 • Calculator Numpad',
            'desc': 'Extra-large input display with live mathematical arithmetic (+, -, ×, ÷) right inside the recording pad without switching apps.',
            'setup': '⚙️ How to use:\n1. Tap "+" or "Add Record" to open the entry screen.\n2. Enter expressions like 50+20*3 and tap "=" to evaluate live total before saving.',
            'tip': '💡 Supports horizontal scrolling for lengthy multi-item expense chains.',
          },
          {
            'icon': Icons.insights_rounded,
            'color': const Color(0xFF0284C7),
            'title': '11. 2-Month Deep Analytics & AI Verdict',
            'badge': 'Guide 11 of 12 • Analytics',
            'desc': 'Compare spending patterns between any two months with AI Smart Verdict, daily burn rates, and savings delta bars.',
            'setup': '⚙️ How to use:\n1. Navigate to "Analytics" tab in bottom navigation.\n2. Select Month A and Month B to inspect comparative charts and category spikes.',
            'tip': '💡 Filter for "Saved Categories" to see where you succeeded in budget trimming.',
          },
          {
            'icon': Icons.picture_as_pdf_rounded,
            'color': const Color(0xFFEF4444),
            'title': '12. PDF Statement A4, Excel Export & Backup',
            'badge': 'Guide 12 of 12 • Export & Backup',
            'desc': 'Export formal financial statements as standard A4 PDF with Thai typography or Excel (.xlsx) directly into your Downloads folder. Plus, 100% offline encrypted backup and restore.',
            'setup': '⚙️ How to use:\n1. Open Profile > "Export Financial Statement PDF" or "Export Excel".\n2. Select period or bank account and export. The file saves directly into Downloads/MeowTang for instant opening and sharing.',
            'tip': '💡 Zero watermark and completely offline, safe from server leaks.',
          },
        ];

      default: // 'th' (Thai)
        return [
          {
            'icon': Icons.sync_rounded,
            'color': const Color(0xFF10B981),
            'title': '1. ดึงสลิปอัตโนมัติ 22 ธนาคาร & เป๋าตัง',
            'badge': 'คู่มือ 1 จาก 12 • ระบบดึงสลิป',
            'desc': 'ระบบตรวจจับสลิปใหม่จากอัลบั้มรูปภาพของ 22 ธนาคารชั้นนำ & กระเป๋าเงินดิจิทัล (กสิกร, ไทยพาณิชย์, กรุงไทย, อิสลาม iBank, กรุงเทพ, ทีทีบี, ออมสิน, กรุงศรี, CIMB, UOB, TMRW, LHB, KKP, GHB, Tisco, เป๋าตัง, TrueMoney ฯลฯ) ทันทีเมื่อเซฟรูป พร้อมระบบป้องกันบันทึกสลิปซ้ำ 100%',
            'setup': '⚙️ วิธีการตั้งค่า & ใช้งาน:\n1. ตรวจสอบว่าได้อนุญาต "สิทธิ์การเข้าถึงรูปภาพ (Photos & Media)" ในการตั้งค่าเครื่อง\n2. เมื่อเซฟรูปสลิปจากแอพธนาคารหรือเป๋าตัง ระบบจะดึงและบันทึกรายการให้อัตโนมัติทันที\n3. ในหน้าภาพรวม สามารถรูดหน้าจอลงสุด (Pull-to-refresh) เพื่อรีเฟรชข้อมูลล่าสุดทั้งหมดและสแกนสลิปใหม่ได้ทันทีโดยไม่ต้องปิดแอพ',
            'tip': '💡 ระบบฉลาดจะอ่านยอดที่ชำระจริง (Net Paid) และข้ามการโอนเงินให้ตัวเองให้อัตโนมัติ',
          },
          {
            'icon': Icons.verified_rounded,
            'color': const Color(0xFF06B6D4),
            'title': '2. ตรวจสลิปแท้ออนไลน์ Real-Time (ITMX)',
            'badge': 'คู่มือ 2 จาก 12 • เช็คสลิปแท้',
            'desc': 'ตรวจสอบความถูกต้องของสลิปโอนเงินโดยตรงกับระบบกลางโครงข่ายธนาคารไทย (ITMX) ยืนยันว่ามีการโอนเงินจริง ป้องกันสลิปปลอมและภาพตัดต่อ 100% พร้อมปุ่มบันทึกเข้าระบบใน 1 แตะ',
            'setup': '⚙️ วิธีการใช้งาน:\n1. แตะปุ่มสายฟ้า ⚡ (เมนูด่วน) ที่มุมขวาล่างของหน้าภาพรวม\n2. เลือกเมนู "ตรวจสลิปแท้ออนไลน์ ⚡"\n3. เลือกรูปภาพสลิปที่มี QR Code หรือสแกนสด ระบบจะดึงข้อมูลจริงจากธนาคารมาแสดงทันที',
            'tip': '💡 จำเป็นต้องมีการเชื่อมต่ออินเทอร์เน็ตในการส่งคำขอตรวจสอบไปยังระบบกลางธนาคาร',
          },
          {
            'icon': Icons.document_scanner_rounded,
            'color': const Color(0xFF8B5CF6),
            'title': '3. สแกนสลิปออฟไลน์ 100% & ใส่ยอดในหน้า + ทันที',
            'badge': 'คู่มือ 3 จาก 12 • OCR ออฟไลน์',
            'desc': 'ถอดรหัสยอดเงิน วันที่ บัญชี และบันทึกช่วยจำ (Memo) จากภาพสลิปได้แบบออฟไลน์ 100% ไม่ต้องต่อเน็ต ปลอดภัยสูงสุด พร้อมระบบดึงยอดเงินจากสลิปมาใส่ในช่องยอดเงินของหน้า "+" ให้ทันทีเมื่อเลือกรูปสลิป',
            'setup': '⚙️ วิธีการใช้งาน:\n1. ในหน้าระบุรายการ "+" แตะปุ่ม "+ สลิป" แล้วเลือกรูป ยอดเงินจะถูกสแกนและกรอกให้อัตโนมัติทันที\n2. หรือแตะปุ่มสายฟ้า ⚡ ที่มุมขวาล่าง > เลือก "เลือกรูปสลิปจากคลังภาพ (OCR)" เพื่อสแกนจัดหมวดหมู่ใน 0.3 วินาที',
            'tip': '💡 ข้อมูลทั้งหมดประมวลผลในเครื่องคุณ 100% ไม่มีทางรั่วไหลออกสู่อินเทอร์เน็ต',
          },
          {
            'icon': Icons.swipe_rounded,
            'color': const Color(0xFF3B82F6),
            'title': '4. การปัดรายการ & ระบบนับถอยหลังยกเลิก (Undo)',
            'badge': 'คู่มือ 4 จาก 12 • ท่าทาง & เลิกทำ',
            'desc': 'จัดการรายการได้อย่างรวดเร็วด้วยการปัดนิ้ว พร้อมระบบนับเวลาถอยหลัง 5 วินาทีแบบสดๆ ป้องกันการเผลอลบพลาด และรองรับการกู้คืนเป็นชุด',
            'setup': '⚙️ วิธีการใช้งาน:\n• 👉 ปัดขวา: เข้าสู่หน้าต่างแก้ไขรายการ (Edit Transaction)\n• 👈 ปัดซ้าย: ลบรายการด่วน (จะมีแถบสีเข้มนับถอยหลัง 5... 4... 3...)\n• ⏱️ กด "เลิกทำ (Undo)" ได้ตลอดเวลาก่อนหมดเวลา 5 วินาที เพื่อดึงรายการทั้งหมดกลับคืนมา',
            'tip': '💡 สามารถปัดลบหลายรายการต่อเนื่องได้ ระบบจะรวมเป็นชุดและนับเวลาถอยหลังให้',
          },
          {
            'icon': Icons.subscriptions_rounded,
            'color': const Color(0xFF6366F1),
            'title': '5. คุมค่า Subscription & บิลประจำรอบบิล',
            'badge': 'คู่มือ 5 จาก 12 • Subscription Vault',
            'desc': 'ศูนย์ควบคุมค่าบริการรายเดือนและรายปี เช่น Netflix, YouTube, Spotify, iCloud, ค่าบ้าน, ค่าน้ำไฟ และเบี้ยประกันภัย พร้อมระบบแจ้งเตือนวันตัดรอบบิลล่วงหน้า',
            'setup': '⚙️ วิธีการใช้งาน:\n1. ไปที่เมนูโปรไฟล์ หรือหน้าพรีเมี่ยม > เลือก "คุมค่า Subscription & บิลประจำ"\n2. เพิ่มบริการที่ใช้งาน กำหนดรอบชำระ (รายเดือน/รายปี), วันที่เริ่มตัดรอบ และจำนวนวันแจ้งเตือนล่วงหน้า\n3. ดูภาพรวมค่าบริการทั้งหมดต่อเดือน พร้อมปุ่มกด "บันทึกจ่ายแล้ว" ได้ใน 1 แตะ',
            'tip': '💡 จัดเรียงตามวันใกล้จ่าย หรือยอดเงินสูงสุดได้ และมีโทรโข่งเตือนเมื่อถึงกำหนดตัดบิล',
          },
          {
            'icon': Icons.currency_exchange_rounded,
            'color': const Color(0xFFEAB308),
            'title': '6. เครื่องคิดเลขแปลงเงิน & คำนวณแร่ทอง/เงิน สด',
            'badge': 'คู่มือ 6 จาก 12 • อัตราแลกเปลี่ยน & แร่มีค่า',
            'desc': 'อัตราแลกเปลี่ยนเงินตราระหว่างประเทศกว่า 30 สกุลเงิน พร้อมคำนวณมูลค่าแร่ทองคำ, แร่เงิน, แพลทินัม และพาลาเดียม อัพเดทสดเรียลไทม์ พร้อมกราฟราคารายวันและย้อนหลัง',
            'setup': '⚙️ วิธีการใช้งาน:\n1. ไปที่เมนูโปรไฟล์ หรือหน้าพรีเมี่ยม > เลือก "เครื่องคิดเลขแปลงเงิน" หรือ "คำนวณแร่ทอง & แร่เงิน"\n2. ดูราคาสปอตสดๆ ของตลาดโลก คำนวณตามน้ำหนัก (กรัม, บาท, ออนซ์) และดูกราฟแนวโน้มราคารายวัน',
            'tip': '💡 รองรับการดูกราฟย้อนหลังและคำนวณแปลงค่าได้ทันทีโดยไม่ต้องเข้าเว็บค้นหา',
          },
          {
            'icon': Icons.mosque_rounded,
            'color': const Color(0xFF14B8A6),
            'title': '7. การเงินอิสลาม & ซะกาตทองคำ Real-Time',
            'badge': 'คู่มือ 7 จาก 12 • การเงินฮาลาล',
            'desc': 'คำนวณซะกาตทองคำแท่งและรูปพรรณตามราคาทองคำสมาคมค้าทองคำสดๆ, จัดการเงินริซกี, คำนวณมรดก และตัดดอกเบี้ยตามหลักชะรีอะฮ์อย่างถูกต้อง',
            'setup': '⚙️ วิธีการตั้งค่า & ใช้งาน:\n1. ไปที่เมนูโปรไฟล์ (คน) > เลือก "การเงินอิสลาม & ซะกาตทองคำ"\n2. ใส่น้ำหนักทองคำที่มี (บาท/กรัม) ระบบจะคำนวณเปรียบเทียบพิกัดนิศอบ (Nisab) และแสดงยอดซะกาต 2.5% ที่ต้องจ่ายทันที',
            'tip': '💡 มีบันทึกประวัติการจ่ายซะกาตและการทำทาน (ศอดะเกาะฮ์) แยกไว้อย่างเป็นระเบียบ',
          },
          {
            'icon': Icons.mic_rounded,
            'color': const Color(0xFFEC4899),
            'title': '8. สั่งจดด้วยเสียง AI ภาษาไทยธรรมชาติ',
            'badge': 'คู่มือ 8 จาก 12 • AI สั่งด้วยเสียง',
            'desc': 'บันทึกรายรับ-รายจ่ายได้เร็วที่สุดโดยไม่ต้องพิมพ์ เพียงพูดภาษาไทยสั้นๆ ระบบ AI NLP จะสกัดยอดเงิน หมวดหมู่ และบัญชีให้อัตโนมัติใน 2 วินาที',
            'setup': '⚙️ วิธีการตั้งค่า & ใช้งาน:\n1. ตรวจสอบว่าได้อนุญาต "สิทธิ์ไมโครโฟน (Microphone)" ในเครื่อง\n2. แตะปุ่มสายฟ้า ⚡ > เลือก "พูดเพื่อจดบันทึกด้วย AI"\n3. พูดสั้นๆ เช่น "กินข้าว 65 บาท", "เติมน้ำมัน 500 โอนจากกสิกร" ระบบจะสร้างรายการให้ทันใจ',
            'tip': '💡 การระบุชื่อธนาคารในประโยคจะช่วยให้ AI เลือกลงบัญชีเงินฝากนั้นให้อัตโนมัติ',
          },
          {
            'icon': Icons.account_balance_rounded,
            'color': const Color(0xFFF59E0B),
            'title': '9. แยกสลิปตามธนาคาร & กระเป๋าเงินแยกบัญชีจริง',
            'badge': 'คู่มือ 9 จาก 12 • ตัวกรองธนาคาร',
            'desc': 'กรองดูรายการและยอดเงินรวมแยกเฉพาะธนาคารที่ต้องการ พร้อมระบบกระเป๋าเงินแยกตามบัญชีธนาคารจริง 22 แห่ง พร้อมโลโก้คมชัด',
            'setup': '⚙️ วิธีการใช้งาน:\n1. ในหน้าภาพรวม แตะปุ่ม "แยกตามธนาคาร (Bank Filter)" เพื่อเลือกเปิด/ปิดธนาคารที่ต้องการแสดงผล\n2. ไปที่เมนู "บัญชี/กระเป๋าเงิน" เพื่อดูยอดเงินแยกตามธนาคารจริง สลิปที่สแกนจะวิ่งเข้าบัญชีธนาคารต้นทางให้อัตโนมัติ',
            'tip': '💡 ใช้ปุ่ม "เลือกทั้งหมด / ยกเลิกทั้งหมด" ด้านล่างเพื่อสลับดูภาพรวมได้อย่างรวดเร็ว',
          },
          {
            'icon': Icons.calculate_rounded,
            'color': const Color(0xFF8B5CF6),
            'title': '10. แป้นพิมพ์คิดเลข & ช่องระบุยอดขนาดใหญ่',
            'badge': 'คู่มือ 10 จาก 12 • แป้นพิมพ์คำนวณ',
            'desc': 'คำนวณตัวเลขบวก ลบ คูณ หาร ได้ในตัว พร้อมช่องแสดงผลขนาดใหญ่พิเศษที่เลื่อนดูแนวนอนได้เมื่อมีรายการบวกเลขยาวๆ',
            'setup': '⚙️ วิธีการใช้งาน:\n1. แตะปุ่ม "+" หรือ "จดบันทึก" เพื่อเปิดแป้นพิมพ์\n2. พิมพ์สูตร เช่น 120+45+60 แล้วกด = เพื่อรวมยอดเงินทันทีโดยไม่ต้องสลับแอพ',
            'tip': '💡 สลับแท็บ "รายจ่าย", "รายรับ", และ "บัตรเครดิต" ได้ที่แถบด้านบนของหน้าต่าง',
          },
          {
            'icon': Icons.insights_rounded,
            'color': const Color(0xFF0284C7),
            'title': '11. วิเคราะห์การเงินเชิงลึก & เปรียบเทียบ 2 เดือน',
            'badge': 'คู่มือ 11 จาก 12 • วิเคราะห์การเงิน',
            'desc': 'เปรียบเทียบพฤติกรรมการใช้จ่ายระหว่าง 2 เดือน พร้อมบทวิเคราะห์ AI Smart Verdict, ค่าเฉลี่ยใช้จ่ายต่อวัน และหมวดหมู่ที่ประหยัดลง',
            'setup': '⚙️ วิธีการใช้งาน:\n1. ไปที่แท็บ "วิเคราะห์ (Analytics)" ที่เมนูด้านล่าง\n2. เลือก เดือน A และ เดือน B ที่ต้องการเปรียบเทียบเพื่อดูความเปลี่ยนแปลงของเงินเก็บ',
            'tip': '💡 กดกรองดูเฉพาะ "หมวดที่ประหยัดขึ้น" เพื่อดูความสำเร็จในการคุมงบประมาณของคุณ',
          },
          {
            'icon': Icons.picture_as_pdf_rounded,
            'color': const Color(0xFFEF4444),
            'title': '12. รายงานสเตทเมนต์ PDF A4, Excel & สำรองข้อมูล',
            'badge': 'คู่มือ 12 จาก 12 • สำรอง & ส่งออก',
            'desc': 'ส่งออกรายงานสรุปบัญชี Statement A4 มาตรฐานเป็นไฟล์ PDF หรือ Excel (.xlsx) บันทึกตรงเข้าโฟลเดอร์ Downloads/MeowTang พร้อมระบบสำรองและกู้คืนข้อมูลแบบออฟไลน์ 100%',
            'setup': '⚙️ วิธีการตั้งค่า & ใช้งาน:\n1. ไปที่เมนูโปรไฟล์ (คน) > "ส่งออกสเตทเมนต์ PDF" หรือ "ส่งออก Excel"\n2. เลือกช่วงเวลาหรือบัญชีที่ต้องการ ระบบจะสร้างเอกสารบันทึกลงโฟลเดอร์ Downloads ทันที พร้อมปุ่มเปิดดูและแชร์\n3. ใช้เมนู "สำรอง & กู้คืนข้อมูล" เพื่อบันทึกไฟล์สำรองเก็บไว้ในเครื่องอย่างปลอดภัย',
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

                            // Real App UI Component Preview Mockup
                            _buildVisualGuidePreview(index, isDark, currentTheme, stepColor, _selectedLang == 'en'),

                            const SizedBox(height: 12),

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

  Widget _buildVisualGuidePreview(int stepIndex, bool isDark, dynamic currentTheme, Color stepColor, bool isEn) {
    final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    Widget content;
    switch (stepIndex) {
      case 0: // Auto Slip Sync
        content = Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.sync_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn ? 'Bank Slip Detected • KBank' : 'ตรวจพบสลิปโอนเงิน • กสิกรไทย',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: currentTheme.textColor,
                          ),
                        ),
                        Text(
                          isEn ? 'Saved to Expenses • ฿250.00' : 'บันทึกเป็นรายจ่ายแล้ว • ฿250.00',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('AUTO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF047857))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_downward_rounded, size: 13, color: currentTheme.textSecondaryColor),
                const SizedBox(width: 4),
                Text(
                  isEn ? 'Pull down on Dashboard to rescan anytime' : 'รูดหน้าจอลงสุดในหน้าภาพรวม เพื่อดึงสลิปใหม่',
                  style: TextStyle(fontSize: 10.5, color: currentTheme.textSecondaryColor),
                ),
              ],
            ),
          ],
        );
        break;

      case 1: // Online Slip Verifier
        content = Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt_rounded, color: Color(0xFFFDE047), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    isEn ? '⚡ ITMX Real-Time Slip Verifier' : '⚡ ตรวจสลิปแท้ออนไลน์ ITMX ธนาคาร',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF06B6D4), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isEn ? 'Verified Transfer: ฿500.00 to นายสมชาย' : 'สลิปแท้ 100% : โอน ฿500.00 ไปยัง นายสมชาย',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: currentTheme.textColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        break;

      case 2: // Offline OCR & Auto Amount Fill
        content = Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF8B5CF6), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      isEn ? '+ Slip Photo' : '+ สลิป',
                      style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward_rounded, color: Color(0xFF8B5CF6), size: 16),
            ),
            Expanded(
              flex: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: currentTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isEn ? 'Auto-filled Amount' : 'ยอดเงินจากสลิปอัตโนมัติ',
                      style: TextStyle(fontSize: 8.5, color: currentTheme.textSecondaryColor),
                    ),
                    const Text(
                      '฿320.00',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
        break;

      case 3: // Swipe Actions & Countdown Undo
        content = Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: currentTheme.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_rounded, color: Color(0xFF3B82F6), size: 12),
                        const SizedBox(width: 2),
                        Text(isEn ? 'Edit' : 'แก้ไข', style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 9.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEn ? '👉 Swipe Right / Left 👈' : '👉 ปัดขวาแก้ไข / ปัดซ้ายลบ 👈',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: currentTheme.textColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 12),
                        const SizedBox(width: 2),
                        Text(isEn ? 'Delete' : 'ลบ', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 9.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_rounded, color: Color(0xFFF59E0B), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isEn ? 'Deleted (Restoring in 5s...)' : 'ลบ 1 รายการ (นับถอยหลัง 5 วินาที...)',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isEn ? 'UNDO' : 'เลิกทำ',
                      style: const TextStyle(color: Colors.black, fontSize: 9.5, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        break;

      case 4: // Subscription Vault
        content = Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: currentTheme.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('N', style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.w900, fontSize: 18)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Netflix Premium', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: currentTheme.textColor)),
                        const Text('฿419/ด.', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF6366F1))),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isEn ? '🔔 In 3 days' : '🔔 อีก 3 วันตัดรอบ',
                            style: const TextStyle(color: Color(0xFFD97706), fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isEn ? 'Mark Paid ✓' : 'บันทึกจ่ายแล้ว ✓',
                            style: const TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        break;

      case 5: // Currency & Precious Metals
        content = Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: currentTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('💵 USD/THB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: currentTheme.textColor)),
                        const Spacer(),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text('฿35.42', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF3B82F6))),
                    const Text('+0.15% วันนี้', style: TextStyle(fontSize: 8.5, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('🥇 ทองคำ 96.5%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: currentTheme.textColor)),
                        const Spacer(),
                        const Icon(Icons.diamond_rounded, color: Color(0xFFD97706), size: 12),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text('฿42,500', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFFD97706))),
                    const Text('คำนวณแร่ทอง/เงิน', style: TextStyle(fontSize: 8.5, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        );
        break;

      case 6: // Islamic Halal Finance & Gold Zakat
        content = Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF14B8A6).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF14B8A6).withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEn ? 'Gold Weight: 85.00 g (Passed Nisab)' : 'ทองคำสะสม: 85.00 กรัม (ผ่านเกณฑ์นิศอบ)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: currentTheme.textColor),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14B8A6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('2.5% ZAKAT', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEn ? 'Zakat Due:' : 'ยอดซะกาตที่ต้องจ่าย:',
                    style: TextStyle(fontSize: 11, color: currentTheme.textSecondaryColor),
                  ),
                  const Text(
                    '฿5,250.00',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F766E)),
                  ),
                ],
              ),
            ],
          ),
        );
        break;

      case 7: // Thai Voice AI Assistant
        content = Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEC4899).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEC4899).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFFF472B6), Color(0xFFDB2777)]),
                ),
                child: const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn ? '🗣️ "Lunch 65 baht from KBank"' : '🗣️ "กินข้าวเที่ยง 65 บาท โอนกสิกร"',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: currentTheme.textColor),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFFDB2777)),
                        const SizedBox(width: 2),
                        Text(
                          isEn ? 'AI parsed: Food • ฿65.00 • KBank' : 'AI จัดการ: อาหาร • ฿65.00 • กสิกร',
                          style: const TextStyle(fontSize: 10, color: Color(0xFFDB2777), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        break;

      case 8: // Bank Filter & Multi-Accounts
        content = Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                  SizedBox(width: 4),
                  Text('กสิกรไทย (KBank)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF4F46E5)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF4F46E5), size: 14),
                  SizedBox(width: 4),
                  Text('SCB', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF4338CA))),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('เป๋าตัง', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
            ),
          ],
        );
        break;

      case 9: // Calculator Numpad & XL Input
        content = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: currentTheme.borderColor),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('120 + 45 + 60', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF8B5CF6))),
                  const Text('= ฿225.00', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['+', '-', '×', '÷', '='].map((op) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: op == '=' ? const Color(0xFF8B5CF6) : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      op,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: op == '=' ? Colors.white : currentTheme.textColor,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
        break;

      case 10: // 2-Month Deep Analytics
        content = Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: currentTheme.borderColor),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isEn ? 'August: ฿18,200' : 'เดือน ส.ค. : ฿18,200', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: currentTheme.textColor)),
                  const Text('เดือน ก.ย. : ฿14,500', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.trending_down_rounded, color: Color(0xFF10B981), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      isEn ? 'Saved ฿3,700 (-20.3%) • AI: Great discipline!' : 'ประหยัดขึ้น ฿3,700 (-20.3%) • AI: คุมงบได้ยอดเยี่ยม',
                      style: const TextStyle(color: Color(0xFF047857), fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        break;

      case 11: // Statement PDF & Excel
        content = Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 20),
                    SizedBox(height: 2),
                    Text('PDF Statement A4', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.table_chart_rounded, color: Color(0xFF10B981), size: 20),
                    SizedBox(height: 2),
                    Text('Excel (.xlsx)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.security_rounded, color: Color(0xFF3B82F6), size: 20),
                    SizedBox(height: 2),
                    Text('สำรองข้อมูลออฟไลน์', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                  ],
                ),
              ),
            ),
          ],
        );
        break;

      default:
        content = const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: content,
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
