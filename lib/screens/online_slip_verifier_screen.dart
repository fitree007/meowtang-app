import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../models/transaction_item.dart';
import '../services/native_bridge_service.dart';
import '../services/online_slip_verification_service.dart';
import '../services/slip_storage_service.dart';
import '../widgets/tactile_button.dart';
import '../utils/format_utils.dart';

class OnlineSlipVerifierScreen extends StatefulWidget {
  final ExpenseController controller;
  final String? initialImagePath;

  const OnlineSlipVerifierScreen({
    super.key,
    required this.controller,
    this.initialImagePath,
  });

  @override
  State<OnlineSlipVerifierScreen> createState() => _OnlineSlipVerifierScreenState();
}

class _OnlineSlipVerifierScreenState extends State<OnlineSlipVerifierScreen>
    with SingleTickerProviderStateMixin {
  String? _imagePath;
  final TextEditingController _amountController = TextEditingController();
  bool _isVerifying = false;
  int _verificationStep = 0; // 0: Idle, 1: Reading QR/Image, 2: Querying Bank, 3: Validating
  OnlineSlipVerificationResult? _result;

  late AnimationController _laserAnimController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _laserAnimController, curve: Curves.easeInOut),
    );

    if (widget.initialImagePath != null && widget.initialImagePath!.isNotEmpty) {
      _imagePath = widget.initialImagePath;
      _startVerification();
    }
  }

  @override
  void dispose() {
    _laserAnimController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    HapticFeedback.selectionClick();
    final path = await NativeBridgeService.pickImageFromGallery();
    if (path != null && path.isNotEmpty && mounted) {
      setState(() {
        _imagePath = path;
        _result = null;
      });
      _startVerification();
    }
  }

  Future<void> _startVerification() async {
    if (_imagePath == null || _imagePath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกรูปภาพสลิปที่ต้องการตรวจสอบ')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isVerifying = true;
      _verificationStep = 1;
      _result = null;
    });

    // Step animation simulation for visual feedback
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && _isVerifying) {
        setState(() => _verificationStep = 2);
      }
    });

    final knownAmount = double.tryParse(_amountController.text.replaceAll(',', '').trim());

    final res = await OnlineSlipVerificationService.verifySlipOnline(
      imagePath: _imagePath!,
      knownAmount: knownAmount,
    );

    if (!mounted) return;

    setState(() {
      _isVerifying = false;
      _verificationStep = 0;
      _result = res;
    });

    if (res.isVerified) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _recordToExpenseBook() async {
    if (_result == null || !_result!.isVerified) return;
    HapticFeedback.mediumImpact();

    final isEn = widget.controller.isEnglish;
    final amount = _result!.amount ?? 0.0;
    final receiverName = _result!.receiverName ?? 'โอนเงิน';

    // Find best matching category
    final expenseCats = widget.controller.expenseCategories;
    final defaultCat = expenseCats.isNotEmpty ? expenseCats.first : null;

    // Find matching account
    final accounts = widget.controller.accounts;
    final defaultAcc = accounts.isNotEmpty ? accounts.first : null;

    final persistentSlipPath = _imagePath != null && _imagePath!.isNotEmpty
        ? await SlipStorageService.persistSlipImage(_imagePath!)
        : _imagePath;

    final item = TransactionItem(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: receiverName.isNotEmpty ? 'โอนให้ $receiverName' : 'โอนเงินสลิปแท้',
      amount: amount > 0 ? amount : 0.0,
      type: TransactionType.expense,
      date: _result!.date ?? DateTime.now(),
      accountId: defaultAcc?.id ?? 'acc_default',
      categoryId: defaultCat?.id ?? 'cat_transfer',
      categoryName: defaultCat?.name ?? 'โอนเงิน',
      note: 'สลิปแท้ผ่านการตรวจสอบ | Ref: ${_result!.ref ?? '-'}',
      tags: ['สลิปแท้', 'ตรวจออนไลน์'],
      slipImageUrl: persistentSlipPath,
    );

    widget.controller.addTransaction(item);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isEn
                    ? 'Added "฿${amount.toStringAsFixed(2)}" to records!'
                    : 'บันทึกรายการ "฿${amount.toStringAsFixed(2)}" ลงสมุดเรียบร้อย!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    Navigator.pop(context);
  }

  void _showInfoDialog() {
    final isDark = widget.controller.isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified_user_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('เกี่ยวกับระบบตรวจสลิปแท้', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ระบบตรวจสลิปแท้ออนไลน์ ทำงานโดยถอดรหัส QR Code บนสลิป แล้วส่งไปตรวจสอบกับฐานข้อมูลเครือข่ายธนาคารแห่งประเทศไทยและ PromptPay แบบ Real-time',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                '✨ สิ่งที่ระบบสามารถยืนยันได้:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text('• ยอดเงินที่โอนจริง และวันเวลาทำรายการจริง\n• ชื่อผู้โอนและชื่อผู้รับจริงจากระบบธนาคาร\n• รหัสอ้างอิงธุรกรรมธนาคาร (Transaction Ref)', style: TextStyle(fontSize: 12.5)),
              SizedBox(height: 12),
              Text(
                '⚠️ ข้อแนะนำ:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                'สลิปที่เพิ่งโอนเสร็จใหม่ๆ อาจต้องรอประมาณ 1–3 นาทีเพื่อให้ระบบธนาคารอัปเดตข้อมูลเข้าส่วนกลาง หากตรวจไม่พบ ให้รอสักครู่แล้วลองใหม่อีกครั้งครับ',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('เข้าใจแล้ว', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = widget.controller.currentTheme;
    final isDark = widget.controller.isDarkMode;
    final isEn = widget.controller.isEnglish;

    final bgColor = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF131B2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'ONLINE VERIFIER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF06B6D4), size: 22),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        physics: const BouncingScrollPhysics(),
        children: [
          // Header Hero Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF0F172A), const Color(0xFF0284C7).withValues(alpha: 0.35)]
                    : [const Color(0xFF0284C7), const Color(0xFF0369A1)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Center(
                    child: Icon(Icons.verified_rounded, color: Colors.white, size: 30),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn ? 'Bank Slip Verifier' : 'ตรวจสลิปแท้ออนไลน์',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEn
                            ? 'Instant verification with Thai Bank networks'
                            : 'เช็คสลิปจริง/ปลอม ดึงข้อมูลตรงจากระบบธนาคาร',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Upload / Live Image Container with Hologram Laser Effect
          Container(
            height: _imagePath != null ? 360 : 210,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isVerifying
                    ? const Color(0xFF06B6D4)
                    : (_result?.isVerified == true
                        ? const Color(0xFF10B981)
                        : (_result != null ? const Color(0xFFEF4444) : borderColor)),
                width: _isVerifying || _result != null ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isVerifying
                      ? const Color(0xFF06B6D4).withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: _imagePath != null
                  ? Stack(
                      children: [
                        // Slip Image Display
                        Center(
                          child: Image.file(
                            File(_imagePath!),
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),

                        // Hologram Scanning Laser Effect
                        if (_isVerifying)
                          AnimatedBuilder(
                            animation: _laserAnimation,
                            builder: (context, child) {
                              return Positioned(
                                top: 360 * _laserAnimation.value,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Color(0xFF00FFFF),
                                        Color(0xFF38BDF8),
                                        Color(0xFF00FFFF),
                                        Colors.transparent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00FFFF).withValues(alpha: 0.8),
                                        blurRadius: 14,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                        // Change Image Button in Top-Right
                        Positioned(
                          top: 12,
                          right: 12,
                          child: TactileButton(
                            onTap: _pickImageFromGallery,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.photo_library_rounded, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'เปลี่ยนรูป',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : InkWell(
                      onTap: _pickImageFromGallery,
                      borderRadius: BorderRadius.circular(24),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF06B6D4).withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_rounded,
                                color: Color(0xFF06B6D4),
                                size: 34,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              isEn ? 'Tap to Select Bank Slip' : 'แตะเพื่อเลือกรูปภาพสลิป',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isEn ? 'Supports all Thai bank transfer slips with QR' : 'รองรับสลิปทุกธนาคารไทยที่มี QR Code',
                              style: TextStyle(color: textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Optional Amount Input (Helpful speed booster)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.speed_rounded, color: Color(0xFFF59E0B), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn ? 'Amount (Optional - Speeds up 3x)' : 'ระบุยอดเงิน (ทางเลือก - เร็วขึ้น 3 เท่า)',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: isEn ? 'e.g. 500.00' : 'เช่น 500.00 (เว้นว่างได้)',
                          hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6), fontSize: 13),
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Main Verify Button
          TactileButton(
            onTap: _isVerifying ? () {} : _startVerification,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF3B82F6), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(27),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: _isVerifying
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _verificationStep == 1
                                ? 'กำลังอ่าน QR Code & สลิป...'
                                : 'กำลังตรวจสอบกับธนาคาร...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.security_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _imagePath != null ? 'เริ่มตรวจสอบสลิปแท้ทันที' : 'เลือกรูปสลิปเพื่อตรวจสอบ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Verification Results Container
          if (_result != null) ...[
            if (_result!.isVerified)
              _buildSuccessResultCard(currentTheme, cardBg, textPrimary, textSecondary, borderColor, isDark, isEn)
            else
              _buildErrorResultCard(currentTheme, cardBg, textPrimary, textSecondary, borderColor, isDark, isEn),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessResultCard(
    dynamic currentTheme,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    bool isDark,
    bool isEn,
  ) {
    final res = _result!;
    final dateStr = res.date != null
        ? '${res.date!.day} ${_formatThaiMonth(res.date!.month)} ${res.date!.year + 543} เวลา ${res.date!.hour.toString().padLeft(2, '0')}:${res.date!.minute.toString().padLeft(2, '0')}:${res.date!.second.toString().padLeft(2, '0')} น.'
        : '-';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF10B981), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Holographic Verified Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'สลิปแท้ 100% (AUTHENTIC)',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (res.responseTimeMs > 0)
                Text(
                  '⚡ ${(res.responseTimeMs / 1000).toStringAsFixed(1)}s',
                  style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          if (res.verificationMethod != null && res.verificationMethod!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.security_rounded, size: 13, color: Color(0xFF0284C7)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      res.verificationMethod!,
                      style: const TextStyle(color: Color(0xFF0284C7), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Big Amount Display
          Center(
            child: Column(
              children: [
                Text(
                  '฿${CurrencyFormat.format(res.amount ?? 0.0)}',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ยอดเงินที่โอนจริงตามระบบธนาคาร',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Sender & Receiver Flow
          Row(
            children: [
              // Sender
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ผู้โอนเงิน', style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      res.senderName ?? '-',
                      style: TextStyle(color: textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      res.senderBankName ?? '-',
                      style: const TextStyle(color: Color(0xFF0284C7), fontSize: 11.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (res.senderAccount != null && res.senderAccount!.isNotEmpty)
                      Text(
                        res.senderAccount!,
                        style: TextStyle(color: textSecondary, fontSize: 11),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Color(0xFF10B981), size: 20),
              // Receiver
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('ผู้รับเงิน', style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      res.receiverName ?? '-',
                      style: TextStyle(color: textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      res.receiverBankName ?? '-',
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 11.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (res.receiverAccount != null && res.receiverAccount!.isNotEmpty)
                      Text(
                        res.receiverAccount!,
                        style: TextStyle(color: textSecondary, fontSize: 11),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Date & Ref Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('วันเวลาทำรายการ:', style: TextStyle(color: textSecondary, fontSize: 11.5)),
              Text(dateStr, style: TextStyle(color: textPrimary, fontSize: 11.5, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('รหัสอ้างอิง (Ref):', style: TextStyle(color: textSecondary, fontSize: 11.5)),
              Row(
                children: [
                  Text(
                    res.ref ?? '-',
                    style: TextStyle(color: textPrimary, fontSize: 11.5, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  ),
                  if (res.ref != null) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: res.ref!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('คัดลอกรหัสอ้างอิงแล้ว'), duration: Duration(seconds: 1)),
                        );
                      },
                      child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF06B6D4)),
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Action: 1-Tap Record to Ledger Button
          TactileButton(
            onTap: _recordToExpenseBook,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_add_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '⚡ บันทึกลงสมุดรายจ่ายทันที',
                      style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorResultCard(
    dynamic currentTheme,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    bool isDark,
    bool isEn,
  ) {
    final res = _result!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'ตรวจสอบสลิปไม่สำเร็จ',
                  style: TextStyle(color: Color(0xFFEF4444), fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            res.errorMessage ?? 'ไม่สามารถยืนยันข้อมูลกับธนาคารได้',
            style: TextStyle(color: textPrimary, fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'หากสลิปเพิ่งทำรายการเสร็จสดๆ แนะนำให้รอประมาณ 1–3 นาทีเพื่อให้ระบบธนาคารอัปเดตข้อมูล หรือลองพิมพ์ยอดเงินในช่องช่วยค้นหาด้านบนครับ',
                    style: TextStyle(color: Colors.grey, fontSize: 11.5, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TactileButton(
            onTap: _startVerification,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  '🔄 ลองตรวจสอบอีกครั้ง',
                  style: TextStyle(color: textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatThaiMonth(int month) {
    const months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }
}
