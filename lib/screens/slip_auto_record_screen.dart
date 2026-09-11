import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction_item.dart';
import '../models/category_item.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../services/native_bridge_service.dart';
import '../services/ocr_engine_service.dart';
import '../services/category_matcher_service.dart';
import '../services/qr_slip_parser_service.dart';
import '../services/duplicate_slip_checker.dart';
import '../services/easyocr_tesseract_fusion_service.dart';
import '../services/slip_storage_service.dart';
import '../services/thai_bank_detector.dart';
import '../widgets/meow_wheel_date_picker.dart';
import '../widgets/meow_paywall_modal.dart';

class SlipAutoRecordScreen extends StatefulWidget {
 final ExpenseController controller;
 final String? initialImagePath;

 const SlipAutoRecordScreen({
  super.key,
  required this.controller,
  this.initialImagePath,
 });

 @override
 State<SlipAutoRecordScreen> createState() => _SlipAutoRecordScreenState();
}

class _SlipAutoRecordScreenState extends State<SlipAutoRecordScreen> {
 String? _imagePath;
 bool _isAnalyzing = false;
 final TextEditingController _amountCtrl = TextEditingController();
 final TextEditingController _titleCtrl = TextEditingController();
 final TextEditingController _noteCtrl = TextEditingController();
 final TextEditingController _refCtrl = TextEditingController();

 TransactionType _type = TransactionType.expense;
 DateTime _transactionDate = DateTime.now();
 CategoryItem? _selectedCategory;
 String? _selectedAccountId;
 String _detectedBank = 'พร้อมเพย์ / ธนาคาร';
 bool _isSelfTransfer = false;
 String? _senderName;
 String? _receiverName;

 @override
 void initState() {
  super.initState();
  if (widget.controller.accounts.isNotEmpty) {
   _selectedAccountId = widget.controller.accounts.first.id;
  }
  if (widget.controller.expenseCategories.isNotEmpty) {
   _selectedCategory = widget.controller.expenseCategories.first;
  }

  if (widget.initialImagePath != null) {
   _imagePath = widget.initialImagePath;
   _analyzeSlip(_imagePath!);
  } else {
   WidgetsBinding.instance.addPostFrameCallback((_) {
    _pickSlipFromGallery();
   });
  }
 }

 Future<void> _pickSlipFromGallery() async {
   if (!widget.controller.canImportMoreSlips) {
     final monthlyUsed = widget.controller.currentMonthSlipCount;
     final monthlyMax = widget.controller.maxFreeSlipsPerMonth;
     final isEn = widget.controller.isEnglish;
     MeowPaywallModal.show(
       context,
       controller: widget.controller,
       reason: isEn
           ? 'Monthly slip quota reached ($monthlyUsed/$monthlyMax slips). Watch short ad for +2 free slips or upgrade to VIP for unlimited slips!'
           : 'โควต้าสลิปฟรีเดือนนี้ครบแล้ว ($monthlyUsed/$monthlyMax สลิป) 🎬 ดูคลิปสั้นรับฟรี +2 สลิปได้ทันที หรือสมัคร VIP สแกนไม่อั้นตลอดชีพ 👑',
     );
     return;
   }
   await NativeBridgeService.requestAppPermissions();
   final path = await NativeBridgeService.pickImageFromGallery();
  if (path != null && path.isNotEmpty) {
   setState(() {
    _imagePath = path;
   });
   _analyzeSlip(path);
  }
 }

 Future<void> _analyzeSlip(String path) async {
  setState(() {
   _isAnalyzing = true;
  });

  final file = File(path);
  DateTime slipDate = DateTime.now();
  try {
   if (file.existsSync()) {
    slipDate = file.lastModifiedSync();
   }
  } catch (_) {}

  final fileName = path.split(RegExp(r'[/\\]')).last;

  // 1. Duplicate Check
  final isDuplicate = DuplicateSlipChecker.isDuplicate(
   existingTransactions: widget.controller.allTransactions,
   filePath: path,
   fileName: fileName,
  );

  if (isDuplicate && mounted) {
   ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
     content: Text(' สลิปนี้ได้รับการบันทึกลงในระบบเรียบร้อยแล้ว (ตรวจพบสลิปซ้ำ)'),
     backgroundColor: Colors.orange,
    ),
   );
  }

  // 2. Process real image pixels via Google ML Kit Native Engine
  final mlResult = await NativeBridgeService.processSlipImage(path);
  final qrPayload = mlResult['qrPayload'] as String? ?? '';
  final rawOcrText = mlResult['ocrText'] as String? ?? '';

  final combinedText = '$rawOcrText $fileName';
  final lowerCombined = combinedText.toLowerCase();

  // 3. Validate if image is a bank slip
  final isSlip = OcrEngineService.isBankSlip(
   combinedText,
   fileName: fileName,
   filePath: path,
  ) || qrPayload.isNotEmpty || rawOcrText.contains(RegExp(r'โอน|สำเร็จ|จำนวนเงิน|บาท|ธนาคาร|kbank|scb|ktb|truemoney|promptpay|พร้อมเพย์|transaction|transfer', caseSensitive: false));

  if (!isSlip && !isDuplicate && mounted) {
   ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
     content: Text(' รูปภาพนี้อาจไม่ใช่สลิปธนาคาร (ไม่พบข้อความยืนยันการโอนเงิน)'),
     backgroundColor: Colors.orange,
    ),
   );
  }

  // 4. STEP 1: Attempt QR Code / Barcode Scanning First
  double detectedAmount = 0.0;
  String refNo = 'REF-${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}';
  String bankName = 'ธนาคารไทย';
  String? qrSenderBankCode;
  bool isParsedFromQr = false;

  QrSlipResult? qrResult;
  if (qrPayload.isNotEmpty) {
   qrResult = QrSlipParserService.parseQrCodePayload(qrPayload);
   if (qrResult.success) {
    if (qrResult.amount > 0) {
      detectedAmount = qrResult.amount;
      isParsedFromQr = true;
    }
    if (qrResult.refId != null && qrResult.refId!.isNotEmpty) {
      refNo = qrResult.refId!;
    }
    if (qrResult.senderBank != null && qrResult.senderBank!.isNotEmpty) {
      bankName = qrResult.senderBank!;
    }
    if (qrResult.senderBankCode != null && qrResult.senderBankCode!.isNotEmpty) {
      qrSenderBankCode = qrResult.senderBankCode;
    }
   }
  }

  // 4. Extract Sender & Receiver Names & Amount (with qrPayload included)
  final ocrParsed = widget.controller.parseSlip(
   rawOcrText,
   fileName: fileName,
   filePath: path,
   qrPayload: qrPayload,
  );
  final extractedParties = OcrEngineService.extractSenderAndReceiver(rawOcrText, rawOcrText.split('\n'));
  final senderName = (ocrParsed.senderName != 'ไม่ระบุผู้โอน')
    ? ocrParsed.senderName
    : (extractedParties['sender'] != 'ไม่ระบุผู้โอน' ? extractedParties['sender']! : 'ไม่ระบุผู้โอน');
  final receiverName = (ocrParsed.receiverName != 'ไม่ระบุผู้รับ')
    ? ocrParsed.receiverName
    : (extractedParties['receiver'] != 'ไม่ระบุผู้รับ' ? extractedParties['receiver']! : 'ไม่ระบุผู้รับ');

  final cleanCombined = '$rawOcrText $fileName $bankName $path'.toLowerCase();
  final senderCode = qrSenderBankCode ?? qrResult?.senderBankCode;
  final bool qrIndicatesOtherBank = senderCode != null && senderCode.isNotEmpty && senderCode != '066';

  final bool isKBank = (senderCode == '004') ||
      cleanCombined.contains('k plus') ||
      cleanCombined.contains('kplus') ||
      cleanCombined.contains('kbank') ||
      cleanCombined.contains('kasikorn') ||
      path.toLowerCase().contains('k plus') ||
      path.toLowerCase().contains('kplus') ||
      path.toLowerCase().contains('kbank');

  final bool isKrungthai = (senderCode == '006') ||
      qrPayload.contains('N006') ||
      cleanCombined.contains('n006') ||
      path.toLowerCase().contains('krungthai') ||
      (cleanCombined.contains('กรุงไทย') && !cleanCombined.contains('ไอแบงก์') && !cleanCombined.contains('ธนาคารอิสลาม'));

  final bool isSCB = (senderCode == '014') ||
      cleanCombined.contains('scb easy') ||
      cleanCombined.contains('scb') ||
      path.toLowerCase().contains('scb') ||
      (cleanCombined.contains('ไทยพาณิชย์') && !cleanCombined.contains('ไอแบงก์') && !cleanCombined.contains('ธนาคารอิสลาม'));

  final bool isIBank = !qrIndicatesOtherBank &&
      !isKBank &&
      !isKrungthai &&
      !isSCB &&
      ((senderCode == '066') ||
          (qrResult != null && (qrResult.senderBank != null && qrResult.senderBank!.contains('อิสลาม'))) ||
          qrPayload.toLowerCase().contains('0103066') ||
          qrPayload.toLowerCase().contains('ibank') ||
          cleanCombined.contains('ibank') ||
          cleanCombined.contains('ไอแบงก์') ||
          cleanCombined.contains('ไอแบงค์') ||
          cleanCombined.contains('ธนาคารอิสลาม') ||
          cleanCombined.contains('อิสลามแห่งประเทศไทย'));

  final bool isPaotangGovNoQr = (cleanCombined.contains('เป๋าตัง') ||
          cleanCombined.contains('paotang') ||
          cleanCombined.contains('g-wallet') ||
          cleanCombined.contains('gwallet') ||
          cleanCombined.contains('ไทยช่วยไทย') ||
          cleanCombined.contains('คนละครึ่ง') ||
          cleanCombined.contains('เราชนะ') ||
          cleanCombined.contains('สวัสดิการ') ||
          path.toLowerCase().contains('paotang') ||
          path.contains('เป๋าตัง')) &&
      !isIBank &&
      !isKBank &&
      !isKrungthai &&
      !isSCB &&
      qrPayload.isEmpty;

  // STEP 2: Fallback to Advanced OCR Text Recognition for Amount
  if (detectedAmount <= 0) {
   if (isPaotangGovNoQr) {
     final paotangAmtRegex = RegExp(
       r'(?:จำนวนเงินที่ชำระ|จํานวนเงินที่ชำระ)[:\s\n]*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})|[0-9]+(?:\.[0-9]{2})?)',
       caseSensitive: false,
     );
     final match = paotangAmtRegex.firstMatch(rawOcrText);
     if (match != null && match.group(1) != null) {
       final rawVal = match.group(1)!.replaceAll(',', '').trim();
       detectedAmount = double.tryParse(rawVal) ?? 0.0;
     }
   } else {
     if (ocrParsed.amount > 0) {
       detectedAmount = ocrParsed.amount;
       if (ocrParsed.refId.isNotEmpty) refNo = ocrParsed.refId;
       if (ocrParsed.senderBank.isNotEmpty && bankName == 'ธนาคารไทย') bankName = ocrParsed.senderBank;
     } else {
       detectedAmount = OcrEngineService.extractAmountFromText(rawOcrText.isNotEmpty ? rawOcrText : fileName);
     }
   }
  }

  // Extract exact Date & Time printed on the slip
  final extractedDate = OcrEngineService.extractDateTimeFromText(
   rawOcrText,
   fileName: fileName,
   filePath: path,
  );
  if (extractedDate.year >= 2020 && extractedDate.year <= DateTime.now().year + 1) {
   slipDate = extractedDate;
  }

  // 5. Extract Memo using RegEx from OCR text
  String? memo = ocrParsed.memo;
  if (memo == null || memo.isEmpty) {
   final memoRegex = RegExp(
    r'(?:บันทึกช่วยจำ|บันทึก|หมายเหตุ|Memo|Note|ข้อความ|รายละเอียด)[:\s]*([^\n\r]+)',
    caseSensitive: false,
   );
   final memoMatch = memoRegex.firstMatch(rawOcrText);
   if (memoMatch != null && memoMatch.group(1) != null) {
    memo = memoMatch.group(1)!.trim();
   }
  }

  // 6. Detect Bank Name with QR code & sender-section priority
  if (qrResult?.senderBank != null && qrResult!.senderBank!.isNotEmpty) {
   bankName = qrResult.senderBank!;
  } else if (isIBank) {
   bankName = 'ธนาคารอิสลามแห่งประเทศไทย';
  } else if (isKrungthai) {
   bankName = 'กรุงไทย (Krungthai NEXT)';
  } else if (isSCB) {
   bankName = 'ไทยพาณิชย์ (SCB EASY)';
  } else if (isKBank) {
   bankName = 'กสิกรไทย (K PLUS)';
  } else if (ocrParsed.senderBank.isNotEmpty && ocrParsed.senderBank != 'ธนาคารไทย') {
   bankName = ocrParsed.senderBank;
  } else if (bankName == 'ธนาคารไทย' || bankName.isEmpty) {
   bankName = EasyOcrTesseractFusionService.detectBankName(rawOcrText, filePath: path);
  }

  // 7. Auto-detect Income vs Expense
  final targetType = ocrParsed.suggestedType;
  final bool isIncomeSlip = targetType == TransactionType.income;

  // 8. Match Category according to Income / Expense
  final customRulesRaw = widget.controller.storage.getKeywordRules();
  final customRules = customRulesRaw.map((r) => KeywordRule.fromJson(r)).toList();

  final expenseFallback = widget.controller.expenseCategories.firstWhere(
    (c) => c.name.contains('รายจ่าย') || c.name.contains('ทั่วไป'),
    orElse: () => widget.controller.expenseCategories.isNotEmpty
      ? widget.controller.expenseCategories.first
      : widget.controller.categories.first,
  );

  final incomeFallback = widget.controller.incomeCategories.firstWhere(
    (c) => c.name.contains('เงินเดือน') || c.name.contains('รายได้') || c.name.contains('โอน') || c.name.contains('ริซกี'),
    orElse: () => widget.controller.incomeCategories.isNotEmpty
      ? widget.controller.incomeCategories.first
      : widget.controller.categories.first,
  );

  final targetCategories = isIncomeSlip
      ? (widget.controller.incomeCategories.isNotEmpty ? widget.controller.incomeCategories : widget.controller.categories.where((c) => c.type == CategoryType.income).toList())
      : (widget.controller.expenseCategories.isNotEmpty ? widget.controller.expenseCategories : widget.controller.categories.where((c) => c.type == CategoryType.expense).toList());

  final matchedCategory = await CategoryMatcherService.matchOrAutoCreateCategory(
    noteOrMemo: memo ?? '',
    recipientOrMerchant: '$rawOcrText $bankName $receiverName $senderName',
    controller: widget.controller,
    type: isIncomeSlip ? CategoryType.income : CategoryType.expense,
    fallbackCategory: isIncomeSlip ? incomeFallback : expenseFallback,
  );

  // 9. Generate Title showing Who transferred to Whom (iOS format: โอนเงินผ่าน(ชื่อธนาคาร))
  final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;
  String cleanBank = bankName;
  if (isKBank || (senderCode == '004') || cleanBank.contains('กสิกร')) {
    cleanBank = 'กสิกรไทย';
    bankName = 'กสิกรไทย (K PLUS)';
  } else if (isSCB || (senderCode == '014') || cleanBank.contains('ไทยพาณิชย์')) {
    cleanBank = 'ไทยพาณิชย์';
    bankName = 'ไทยพาณิชย์ (SCB EASY)';
  } else if (isKrungthai || (senderCode == '006') || cleanBank.contains('กรุงไทย')) {
    cleanBank = 'กรุงไทย';
    bankName = 'กรุงไทย (Krungthai NEXT)';
  } else if (isIBank || (senderCode == '066') || cleanBank.contains('ธนาคารอิสลาม') || cleanBank.contains('ibank') || cleanBank.contains('ไอแบงก์')) {
    cleanBank = 'ธนาคารอิสลาม';
    bankName = 'ธนาคารอิสลามแห่งประเทศไทย';
  } else if (cleanBank.contains('กรุงเทพ') || (senderCode == '002')) {
    cleanBank = 'กรุงเทพ';
  } else if (cleanBank.contains('ทหารไทย') || cleanBank.contains('ttb') || (senderCode == '011')) {
    cleanBank = 'ทหารไทยธนชาต (ttb)';
  } else if (cleanBank.contains('ออมสิน') || cleanBank.contains('mymo') || (senderCode == '030')) {
    cleanBank = 'ออมสิน';
  } else if (cleanBank.contains('กรุงศรี') || (senderCode == '025')) {
    cleanBank = 'กรุงศรีอยุธยา';
  } else if (cleanBank.contains('ทรูมันนี่') || cleanBank.contains('truemoney')) {
    cleanBank = 'ทรูมันนี่';
  } else if (cleanBank.contains('พร้อมเพย์') || cleanBank.contains('promptpay')) {
    cleanBank = 'พร้อมเพย์';
  } else if (cleanBank.contains('ไทยช่วยไทย')) {
    cleanBank = 'ไทยช่วยไทย (เป๋าตัง)';
  } else if (cleanBank.contains('เป๋าตัง') || cleanBank.contains('paotang')) {
    cleanBank = 'เป๋าตัง';
  }

  String title;
  if (isIOS) {
    title = isIncomeSlip ? 'รับเงินโอนผ่าน$cleanBank' : 'โอนเงินผ่าน$cleanBank';
  } else {
    title = isIncomeSlip ? 'รับเงินโอน $bankName' : 'โอนเงิน $bankName';
    if (isIncomeSlip) {
      if (senderName != 'ไม่ระบุผู้โอน') {
        title = 'รับเงินจาก $senderName';
      } else {
        title = 'เงินโอนเข้า ($bankName)';
      }
    } else {
      if (senderName != 'ไม่ระบุผู้โอน' && receiverName != 'ไม่ระบุผู้รับ') {
        title = '$senderName โอนให้ $receiverName';
      } else if (receiverName != 'ไม่ระบุผู้รับ') {
        title = 'โอนให้ $receiverName';
      } else if (senderName != 'ไม่ระบุผู้โอน') {
        title = '$senderName โอนเงิน ($bankName)';
      }
    }
  }

  if (detectedAmount <= 0) {
    memo = 'โปรดระบุยอด';
  }

  final bool isSelf = ocrParsed.isSelfTransfer ||
    OcrEngineService.isSelfTransfer(senderName, receiverName, rawText: rawOcrText);

  // Auto-select the bank account corresponding to the slip's bank
  final targetBankCode = isIBank
      ? 'IBANK'
      : (isKrungthai
          ? 'KTB'
          : (isSCB
              ? 'SCB'
              : (isKBank
                  ? 'KBANK'
                  : ThaiBankDetector.detectCodeFromBankName(cleanBank))));
  final targetAccount = widget.controller.getOrCreateAccountForBank(targetBankCode, bankName: bankName);

  if (mounted) {
   setState(() {
    _isAnalyzing = false;
    _detectedBank = bankName;
    _selectedAccountId = targetAccount.id;
    _isSelfTransfer = isSelf;
    _type = targetType;
    _amountCtrl.text = detectedAmount > 0 ? detectedAmount.toStringAsFixed(2) : '';
    _titleCtrl.text = title;
    _refCtrl.text = refNo;
    _senderName = (senderName != 'ไม่ระบุผู้โอน' && senderName.trim().isNotEmpty) ? senderName.trim() : null;
    _receiverName = (receiverName != 'ไม่ระบุผู้รับ' && receiverName.trim().isNotEmpty) ? receiverName.trim() : null;
    _noteCtrl.text = (memo != null && memo.trim().isNotEmpty) ? memo.trim() : '';
    _transactionDate = slipDate;
    _selectedCategory = matchedCategory;
   });
  }
 }

 void _saveSlipTransaction() async {
  final amount = double.tryParse(_amountCtrl.text.trim());
  if (amount == null || amount <= 0) {
   ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
     content: Text('กรุณาระบุจำนวนเงินที่ถูกต้อง'),
     backgroundColor: MeowTheme.expenseRed,
    ),
   );
   return;
  }

  final title = _titleCtrl.text.trim().isEmpty ? 'รายการสลิปเงิน' : _titleCtrl.text.trim();
  final cat = _selectedCategory ?? (widget.controller.expenseCategories.isNotEmpty ? widget.controller.expenseCategories.first : widget.controller.categories.first);

  final persistentSlipPath = _imagePath != null && _imagePath!.isNotEmpty
      ? await SlipStorageService.persistSlipImage(_imagePath!)
      : _imagePath;

  if (!widget.controller.canImportMoreSlips) {
     final monthlyUsed = widget.controller.currentMonthSlipCount;
     final monthlyMax = widget.controller.maxFreeSlipsPerMonth;
     final isEn = widget.controller.isEnglish;
      MeowPaywallModal.show(
        context,
        controller: widget.controller,
        reason: isEn
            ? 'Monthly slip quota reached ($monthlyUsed/$monthlyMax slips). Watch short ad for +2 free slips or upgrade to VIP for unlimited slips!'
            : 'โควต้าสลิปฟรีเดือนนี้ครบแล้ว ($monthlyUsed/$monthlyMax สลิป) 🎬 ดูคลิปสั้นรับฟรี +2 สลิปได้ทันที หรือสมัคร VIP สแกนไม่อั้นตลอดชีพ 👑',
      );
     return;
   }

  final item = TransactionItem(
   id: 'tx_slip_${DateTime.now().millisecondsSinceEpoch}',
   title: title,
   amount: amount,
   type: _type,
   date: _transactionDate,
   accountId: _selectedAccountId ?? 'acc_cash',
   categoryId: cat.id,
   categoryName: cat.name,
   note: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
   senderName: _senderName,
   receiverName: _receiverName,
   bankName: _detectedBank,
   slipRefId: _refCtrl.text.trim(),
   slipImageUrl: persistentSlipPath,
  );

   final added = await widget.controller.addTransaction(item, allowManualOverride: true);
   if (!added) {
    if (mounted) {
     ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
       content: Text('ไม่สามารถบันทึกรายการได้ กรุณาตรวจสอบข้อมูล'),
       backgroundColor: MeowTheme.expenseRed,
      ),
     );
    }
    return;
   }
   await widget.controller.recordSlipImported(slipDate: item.date);

  ScaffoldMessenger.of(context).showSnackBar(
   SnackBar(
    content: Row(
     children: [
      const Icon(Icons.check_circle, color: Colors.white),
      const SizedBox(width: 10),
      Expanded(
       child: Text(
        ' บันทึกสลิป ฿${amount.toStringAsFixed(2)} ลงบัญชีเรียบร้อยแล้ว!',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
       ),
      ),
     ],
    ),
    backgroundColor: MeowTheme.incomeGreen,
   ),
  );

  Navigator.pop(context);
 }

 String _formatThaiDate(DateTime d) {
  const months = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
  final thaiYear = (d.year + 543) % 100;
  final timeStr = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  return '${d.day} ${months[d.month - 1]} $thaiYear เวลา $timeStr น.';
 }

 Future<void> _pickDate() async {
  HapticFeedback.selectionClick();
  final picked = await MeowWheelDatePicker.showWheelDatePicker(
   context: context,
   initialDate: _transactionDate,
   firstDate: DateTime(2000),
   lastDate: DateTime(2040),
   isEnglish: widget.controller.isEnglish,
   isDarkMode: widget.controller.isDarkMode,
   title: widget.controller.isEnglish ? 'Select Slip Date' : 'เลือกวันและเวลาในสลิป',
  );
  if (picked != null) {
   setState(() => _transactionDate = picked);
  }
 }

 @override
 Widget build(BuildContext context) {
    final currentTheme = widget.controller.currentTheme;
    final isDark = widget.controller.isDarkMode;
    final isEn = widget.controller.isEnglish;
  return Scaffold(
   backgroundColor: currentTheme.scaffoldBackground,
   appBar: AppBar(
    backgroundColor: currentTheme.primaryColor,
    leading: IconButton(
     icon: const Icon(Icons.arrow_back_ios_new, color: MeowTheme.textDarkPrimary),
     onPressed: () => Navigator.pop(context),
    ),
    title: const Text(
     'อ่านสลิปและบันทึกอัตโนมัติ',
     style: TextStyle(color: MeowTheme.textDarkPrimary, fontSize: 18, fontWeight: FontWeight.bold),
    ),
    actions: [
     IconButton(
      icon: const Icon(Icons.photo_library_outlined, color: MeowTheme.textDarkPrimary),
      tooltip: 'เลือกสลิปรูปอื่น',
      onPressed: _pickSlipFromGallery,
     ),
    ],
   ),
   body: ListView(
    padding: const EdgeInsets.all(18),
    children: [
     // Slip Image Card
     if (_imagePath != null) ...[
      Container(
       decoration: BoxDecoration(
        color: currentTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: currentTheme.borderColor),
       ),
       child: Column(
        children: [
         ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
           height: 220,
           width: double.infinity,
           color: Colors.black,
           child: Image.file(
            File(_imagePath!),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
             child: Icon(Icons.receipt_long, color: MeowTheme.mustardYellow, size: 60),
            ),
           ),
          ),
         ),
         Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
            Row(
             children: [
              const Icon(Icons.check_circle, color: MeowTheme.incomeGreen, size: 18),
              const SizedBox(width: 6),
              Text(
               'ตรวจพบ: $_detectedBank',
               style: TextStyle(color: currentTheme.textColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '⚡ EasyOCR & Tesseract',
                  style: TextStyle(color: Color(0xFF047857), fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
             ],
            ),
            TextButton.icon(
             onPressed: _pickSlipFromGallery,
             icon: const Icon(Icons.refresh, size: 16, color: MeowTheme.actionBlue),
             label: const Text('เปลี่ยนรูป', style: TextStyle(color: MeowTheme.actionBlue, fontSize: 12)),
            ),
           ],
          ),
         ),
        ],
       ),
      ),
      if (_isSelfTransfer) ...[
       const SizedBox(height: 12),
       Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
         color: const Color(0xFFFEF3C7),
         borderRadius: BorderRadius.circular(16),
         border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
        ),
        child: const Row(
         children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 22),
          SizedBox(width: 10),
          Expanded(
           child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             Text(
              'สลิปโอนเงินให้ตัวเอง (Self-Transfer)',
              style: TextStyle(
               color: Color(0xFFB45309),
               fontWeight: FontWeight.bold,
               fontSize: 13,
              ),
             ),
             SizedBox(height: 2),
             Text(
              'ตรวจพบว่าชื่อผู้โอนและผู้รับเป็นคนเดียวกัน ระบบจะไม่นับเป็นรายรับหรือรายจ่ายจริง',
              style: TextStyle(
               color: Color(0xFF78350F),
               fontSize: 11.5,
              ),
             ),
            ],
           ),
          ),
         ],
        ),
       ),
      ],
     ] else ...[
      GestureDetector(
       onTap: _pickSlipFromGallery,
       child: Container(
        height: 180,
        decoration: BoxDecoration(
         color: currentTheme.cardBackground,
         borderRadius: BorderRadius.circular(20),
         border: Border.all(color: MeowTheme.actionBlue, width: 1.5),
        ),
        child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
          Icon(Icons.photo_library_rounded, size: 48, color: MeowTheme.mustardYellow),
          SizedBox(height: 12),
          Text(
           'แตะเพื่อเลือกรูปสลิปจากอัลบั้มในมือถือ',
           style: TextStyle(color: currentTheme.textColor, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text(
           'รองรับสลิปทุกธนาคารไทย (KBank, SCB, Krungthai, TrueMoney ฯลฯ)',
           style: TextStyle(color: currentTheme.textSecondaryColor, fontSize: 12),
          ),
         ],
        ),
       ),
      ),
     ],
     const SizedBox(height: 18),

     // Extracted Form Card
     Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
       color: currentTheme.cardBackground,
       borderRadius: BorderRadius.circular(20),
       border: Border.all(color: currentTheme.borderColor),
      ),
      child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
        Text('ข้อมูลที่อ่านได้จากสลิป (ตรวจสอบ/แก้ไขได้):',
          style: TextStyle(color: currentTheme.textSecondaryColor, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),

        // Amount Field
        Text('จำนวนเงินในสลิป (บาท)', style: TextStyle(color: currentTheme.textSecondaryColor, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
         controller: _amountCtrl,
         keyboardType: const TextInputType.numberWithOptions(decimal: true),
         style: TextStyle(color: MeowTheme.incomeGreen, fontSize: 28, fontWeight: FontWeight.bold),
         decoration: InputDecoration(
          prefixText: '฿ ',
          hintText: '0.00',
          prefixStyle: TextStyle(color: MeowTheme.incomeGreen, fontSize: 28, fontWeight: FontWeight.bold),
          filled: true,
          fillColor: currentTheme.surfaceBackground,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
         ),
        ),
        const SizedBox(height: 14),

        // Title / Receiver
        Text('รายการ / ผู้รับโอน', style: TextStyle(color: currentTheme.textSecondaryColor, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
         controller: _titleCtrl,
         style: TextStyle(color: currentTheme.textColor, fontSize: 15),
         decoration: InputDecoration(
          filled: true,
          fillColor: currentTheme.surfaceBackground,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
         ),
        ),
        const SizedBox(height: 14),

        // Category & Account Row
        Row(
         children: [
          // Category
          Expanded(
           child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             Text('หมวดหมู่', style: TextStyle(color: currentTheme.textSecondaryColor, fontSize: 12)),
             const SizedBox(height: 6),
             DropdownButtonFormField<CategoryItem>(
              value: _selectedCategory,
              dropdownColor: currentTheme.cardBackground,
              style: TextStyle(color: currentTheme.textColor, fontSize: 13),
              decoration: InputDecoration(
               filled: true,
               fillColor: currentTheme.surfaceBackground,
               contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
               border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
              ),
              items: widget.controller.categories.map((c) {
               return DropdownMenuItem(
                value: c,
                child: Text('#${c.name}', overflow: TextOverflow.ellipsis),
               );
              }).toList(),
              onChanged: (val) {
               if (val != null) setState(() => _selectedCategory = val);
              },
             ),
            ],
           ),
          ),
          const SizedBox(width: 12),
          // Account
          Expanded(
           child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             Text('บันทึกลงบัญชี', style: TextStyle(color: currentTheme.textSecondaryColor, fontSize: 12)),
             const SizedBox(height: 6),
             DropdownButtonFormField<String>(
              value: _selectedAccountId,
              dropdownColor: currentTheme.cardBackground,
              style: TextStyle(color: currentTheme.textColor, fontSize: 13),
              decoration: InputDecoration(
               filled: true,
               fillColor: currentTheme.surfaceBackground,
               contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
               border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
              ),
              items: widget.controller.accounts.map((a) {
               return DropdownMenuItem(
                value: a.id,
                child: Text(a.name, overflow: TextOverflow.ellipsis),
               );
              }).toList(),
              onChanged: (val) {
               if (val != null) setState(() => _selectedAccountId = val);
              },
             ),
            ],
           ),
          ),
         ],
        ),
        const SizedBox(height: 14),

        // Note Field
        Text('บันทึกช่วยจำ (Memo)', style: TextStyle(color: currentTheme.textSecondaryColor, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
         controller: _noteCtrl,
         style: TextStyle(color: currentTheme.textColor, fontSize: 14),
         decoration: InputDecoration(
          filled: true,
          fillColor: currentTheme.surfaceBackground,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: currentTheme.borderColor)),
         ),
        ),
        const SizedBox(height: 14),

        // Date Picker
        Text('วันและเวลาในสลิป', style: TextStyle(color: currentTheme.textSecondaryColor, fontSize: 12)),
        const SizedBox(height: 6),
        GestureDetector(
         onTap: _pickDate,
         child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
           color: currentTheme.surfaceBackground,
           borderRadius: BorderRadius.circular(14),
           border: Border.all(color: currentTheme.borderColor),
          ),
          child: Row(
           children: [
            const Icon(Icons.calendar_month, color: MeowTheme.mustardYellow, size: 18),
            const SizedBox(width: 10),
            Expanded(
             child: Text(
              _formatThaiDate(_transactionDate),
              style: TextStyle(color: currentTheme.textColor, fontSize: 14, fontWeight: FontWeight.w500),
             ),
            ),
            const Icon(Icons.edit, color: MeowTheme.actionBlue, size: 16),
           ],
          ),
         ),
        ),
       ],
      ),
     ),
     const SizedBox(height: 24),

     // Instant Save Button
     Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
       gradient: MeowTheme.blueButtonGradient,
       borderRadius: BorderRadius.circular(28),
       boxShadow: [
        BoxShadow(
         color: MeowTheme.actionBlue.withOpacity(0.4),
         blurRadius: 16,
         offset: const Offset(0, 6),
        ),
       ],
      ),
      child: ElevatedButton(
       style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
       ),
       onPressed: _saveSlipTransaction,
       child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
         Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
         SizedBox(width: 10),
         Text(
          'บันทึกจากสลิปนี้ทันที',
          style: TextStyle(
           color: Colors.white,
           fontSize: 18,
           fontWeight: FontWeight.bold,
          ),
         ),
        ],
       ),
      ),
     ),
     const SizedBox(height: 30),
    ],
   ),
  );
 }
}