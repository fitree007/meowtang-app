import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';

class MascotInfo {
  final String id;
  final String name;
  final String subtitle;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;

  const MascotInfo({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
  });
}

class AccessoryInfo {
  final String id;
  final String name;
  final IconData icon;
  final bool isUnlockable;
  final String? unlockRequirement;

  const AccessoryInfo({
    required this.id,
    required this.name,
    required this.icon,
    this.isUnlockable = false,
    this.unlockRequirement,
  });
}

class MascotCatalog {
  static const List<MascotInfo> characters = [
    MascotInfo(
      id: 'cat_quill',
      name: 'เหมี่ยวส้มจอมวางแผน (Ginger Tabby)',
      subtitle: 'แมวส้มลายสลิดตาแป๋ว จดทุกบาท วางแผนรอบคอบ',
      primaryColor: Color(0xFFF97316),
      secondaryColor: Color(0xFFEA580C),
      icon: Icons.pets,
    ),
    MascotInfo(
      id: 'cat_black',
      name: 'เหมี่ยวดำตาวิ้งค์นำโชค (Lucky Black Cat)',
      subtitle: 'แมวดำลึกลับตาสีทองประกาย เรียกทรัพย์โชคลาภ',
      primaryColor: Color(0xFF1E293B),
      secondaryColor: Color(0xFF0F172A),
      icon: Icons.auto_awesome,
    ),
    MascotInfo(
      id: 'cat_persian',
      name: 'เหมี่ยวเปอร์เซียราชนิกุล (Royal Persian)',
      subtitle: 'แมวเปอร์เซียขนฟูสีขาวนวล ตา 2 สี หรูหรามีระดับ',
      primaryColor: Color(0xFF38BDF8),
      secondaryColor: Color(0xFF0284C7),
      icon: Icons.workspace_premium,
    ),
    MascotInfo(
      id: 'cat_calico',
      name: 'เหมี่ยว 3 สีนำโชค (Fortune Calico)',
      subtitle: 'แมวสามสีขาวส้มดำ กวักเงินกวักทอง ริซกีไหลมาเทมา',
      primaryColor: Color(0xFFF59E0B),
      secondaryColor: Color(0xFFD97706),
      icon: Icons.favorite,
    ),
    MascotInfo(
      id: 'cat_muslim',
      name: 'เหมี่ยวขาวมุสลิมริซกี (Muslim Rizqi Cat)',
      subtitle: 'แมวขาวสะอาดใส่หมวกกะปิเยาะห์ สุภาพ เรียบร้อย มีบารอกัต',
      primaryColor: Color(0xFF10B981),
      secondaryColor: Color(0xFF059669),
      icon: Icons.mosque,
    ),
    MascotInfo(
      id: 'cat_samurai',
      name: 'เหมี่ยวซามูไรการเงิน (Samurai Cat)',
      subtitle: 'แมวสายลุยมาดเท่ ผ้าคาดหัวสีแดง วินัยการเงินเฉียบคม',
      primaryColor: Color(0xFFEF4444),
      secondaryColor: Color(0xFFDC2626),
      icon: Icons.military_tech,
    ),
    MascotInfo(
      id: 'shiba_gold',
      name: 'ชิบะนักออม (Saver Shiba)',
      subtitle: 'ผู้พิทักษ์เงินออมและวินัยการเงิน ซื่อสัตย์ภักดี',
      primaryColor: Color(0xFFEAB308),
      secondaryColor: Color(0xFFCA8A04),
      icon: Icons.pets,
    ),
    MascotInfo(
      id: 'lion_gold',
      name: 'สิงโตริซกี (Golden Lion)',
      subtitle: 'ผู้นำแห่งความมุ่งมั่น วางแผนการเงินมั่นคงดั่งราชา',
      primaryColor: Color(0xFFF59E0B),
      secondaryColor: Color(0xFFD97706),
      icon: Icons.shield,
    ),
    MascotInfo(
      id: 'panda_saver',
      name: 'แพนด้าประหยัด (Saver Panda)',
      subtitle: 'ไม่ฟุ่มเฟือย มีวินัยการออมสม่ำเสมอใจเย็น',
      primaryColor: Color(0xFF334155),
      secondaryColor: Color(0xFF0F172A),
      icon: Icons.savings,
    ),
    MascotInfo(
      id: 'fox_smart',
      name: 'จิ้งจอกอัจฉริยะ (Smart Fox)',
      subtitle: 'เฉียบคมเรื่องจัดสรรงบประมาณและการเงินรอบด้าน',
      primaryColor: Color(0xFFEA580C),
      secondaryColor: Color(0xFFC2410C),
      icon: Icons.psychology,
    ),
    MascotInfo(
      id: 'owl_wise',
      name: 'นกฮูกนักวิเคราะห์ (Wise Owl)',
      subtitle: 'รอบรู้การเงิน มองการณ์ไกล สรุปสถิติแม่นยำ',
      primaryColor: Color(0xFF6366F1),
      secondaryColor: Color(0xFF4F46E5),
      icon: Icons.school,
    ),
    MascotInfo(
      id: 'rabbit_rich',
      name: 'กระต่ายคล่องแคล่ว (Active Bunny)',
      subtitle: 'คล่องตัว รวดเร็ว บันทึกรายรับรายจ่ายทันใจ',
      primaryColor: Color(0xFFEC4899),
      secondaryColor: Color(0xFFBE185D),
      icon: Icons.speed,
    ),
    MascotInfo(
      id: 'bear_wealth',
      name: 'พี่หมีมั่นคง (Solid Bear)',
      subtitle: 'อบอุ่น มั่นคง รากฐานการเงินแข็งแกร่งดั่งภูผา',
      primaryColor: Color(0xFF854D0E),
      secondaryColor: Color(0xFF713F12),
      icon: Icons.security,
    ),
    MascotInfo(
      id: 'robot_ai',
      name: 'หุ่นยนต์ AI ริซกี (Cyber Bot)',
      subtitle: 'ตรวจจับสลิปเร็วแรงด้วยพลัง AI อัจฉริยะล้ำยุค',
      primaryColor: Color(0xFF0EA5E9),
      secondaryColor: Color(0xFF0284C7),
      icon: Icons.smart_toy,
    ),
  ];

  static const List<AccessoryInfo> accessories = [
    AccessoryInfo(id: 'pen', name: 'ปากกาขนนกทองคำ', icon: Icons.edit_rounded),
    AccessoryInfo(id: 'gold_shades', name: 'แว่นตาดำสุดคูล', icon: Icons.visibility_rounded),
    AccessoryInfo(id: 'crown', name: 'มงกุฎทองคำราชันย์', icon: Icons.workspace_premium_rounded),
    AccessoryInfo(id: 'bowtie', name: 'โบว์ไทสีแดงสุดหล่อ', icon: Icons.straighten_rounded),
    AccessoryInfo(id: 'grad_cap', name: 'หมวกบัณฑิตนักคิด', icon: Icons.school_rounded),
    AccessoryInfo(id: 'headphones', name: 'หูฟังเกมเมอร์ไร้สาย', icon: Icons.headphones_rounded),
    AccessoryInfo(id: 'coin', name: 'เหรียญทองคำนำโชค', icon: Icons.monetization_on_rounded),
    AccessoryInfo(id: 'money_bag', name: 'ถุงทองออมริซกี', icon: Icons.savings_rounded),
    AccessoryInfo(id: 'calculator', name: 'เครื่องคิดเลขอัจฉริยะ', icon: Icons.calculate_rounded),
    AccessoryInfo(id: 'book', name: 'สมุดบัญชีปกทอง', icon: Icons.menu_book_rounded),
    AccessoryInfo(id: 'star', name: 'ดาวทองคำนำทาง', icon: Icons.star_rounded),
    AccessoryInfo(id: 'coffee', name: 'กาแฟแก้วโปรด', icon: Icons.local_cafe_rounded),
    AccessoryInfo(id: 'laptop', name: 'แล็ปท็อปทำงาน', icon: Icons.laptop_mac_rounded),
    AccessoryInfo(id: 'target', name: 'เป้าหมายการเงิน', icon: Icons.track_changes_rounded),
    AccessoryInfo(id: 'party_hat', name: 'หมวกปาร์ตี้ฉลอง', icon: Icons.celebration_rounded),
    AccessoryInfo(id: 'wings', name: 'ปีกบินสู่อิสรภาพ', icon: Icons.flight_rounded),
    AccessoryInfo(id: 'trophy', name: 'ถ้วยรางวัลยอดนักออม', icon: Icons.emoji_events_rounded),
    AccessoryInfo(id: 'songkok', name: 'หมวกกะปิเยาะห์มุสลิม', icon: Icons.mosque_rounded),
    AccessoryInfo(id: 'scarf', name: 'ผ้าพันคอสีแดงอบอุ่น', icon: Icons.checkroom_rounded),
    AccessoryInfo(id: 'shield', name: 'โล่พิทักษ์เงินเก็บ', icon: Icons.shield_rounded),
    AccessoryInfo(id: 'diamond', name: 'เพชรน้ำงามมั่งคั่ง', icon: Icons.diamond_rounded),
    AccessoryInfo(id: 'flower', name: 'ดอกไม้ประดับหู', icon: Icons.local_florist_rounded),
    AccessoryInfo(id: 'halo', name: 'วงแหวนเทวดานำโชค', icon: Icons.wb_sunny_rounded),
    AccessoryInfo(id: 'wizard_hat', name: 'หมวกพ่อมดการเงิน', icon: Icons.auto_awesome_rounded),
    AccessoryInfo(id: 'headband', name: 'ผ้าคาดหัวนักสู้', icon: Icons.sports_kabaddi_rounded),
  ];
}

class MeowMascotWidget extends StatefulWidget {
  final double size;
  final bool withPen;
  final bool isHeadOnly;
  final String? mascotId;
  final String? accessory;
  final String? customPhotoPath;
  final bool isCustomPhoto;
  final bool animate;
  final MascotMood mood;
  final bool showMoodBadge;
  final VoidCallback? onTap;

  const MeowMascotWidget({
    super.key,
    this.size = 80,
    this.withPen = true,
    this.isHeadOnly = false,
    this.mascotId,
    this.accessory,
    this.customPhotoPath,
    this.isCustomPhoto = false,
    this.animate = true,
    this.mood = MascotMood.normal,
    this.showMoodBadge = true,
    this.onTap,
  });

  @override
  State<MeowMascotWidget> createState() => _MeowMascotWidgetState();
}

class _MeowMascotWidgetState extends State<MeowMascotWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  bool _isTapped = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(covariant MeowMascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    setState(() => _isTapped = true);
    _animCtrl.forward().then((_) {
      if (mounted) {
        _animCtrl.reverse().then((_) {
          if (mounted) setState(() => _isTapped = false);
        });
      }
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final activeId = widget.mascotId ?? 'cat_quill';
    final activeAcc = widget.accessory ?? 'pen';

    Widget mascotCore;
    if (widget.isCustomPhoto && widget.customPhotoPath != null && widget.customPhotoPath!.isNotEmpty) {
      final acc = MascotCatalog.accessories.firstWhere(
        (a) => a.id == activeAcc,
        orElse: () => MascotCatalog.accessories.first,
      );

      mascotCore = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Wings Overlay if chosen
          if (activeAcc == 'wings') ...[
            Positioned(
              left: -widget.size * 0.25,
              top: widget.size * 0.15,
              child: Icon(Icons.flight_rounded, color: const Color(0xFFFBBF24), size: widget.size * 0.50),
            ),
            Positioned(
              right: -widget.size * 0.25,
              top: widget.size * 0.15,
              child: Transform.flip(
                flipX: true,
                child: Icon(Icons.flight_rounded, color: const Color(0xFFFBBF24), size: widget.size * 0.50),
              ),
            ),
          ],

          // 2. Main Photo Container
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFF59E0B),
                width: (widget.size * 0.04).clamp(2.0, 5.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: widget.customPhotoPath!.startsWith('http')
                  ? Image.network(
                      widget.customPhotoPath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white70),
                    )
                  : File(widget.customPhotoPath!).existsSync()
                      ? Image.file(
                          File(widget.customPhotoPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white70),
                        )
                      : const Icon(Icons.person, color: Colors.white70),
            ),
          ),

          // 3. Wearable Crown on Photo
          if (activeAcc == 'crown')
            Positioned(
              top: -widget.size * 0.18,
              child: Icon(
                Icons.workspace_premium_rounded,
                color: const Color(0xFFFBBF24),
                size: (widget.size * 0.48).clamp(24.0, 48.0),
                shadows: const [
                  Shadow(color: Color(0xFFD97706), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
            ),

          // 4. Wearable Glasses / Shades on Photo
          if (activeAcc == 'gold_shades')
            Positioned(
              top: widget.size * 0.28,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: widget.size * 0.08, vertical: widget.size * 0.03),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFBBF24), width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: widget.size * 0.18, height: widget.size * 0.12, decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(6))),
                    Container(width: widget.size * 0.06, height: 2, color: const Color(0xFFFBBF24)),
                    Container(width: widget.size * 0.18, height: widget.size * 0.12, decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ),
            ),

          // 5. Wearable Grad Cap on Photo
          if (activeAcc == 'grad_cap')
            Positioned(
              top: -widget.size * 0.16,
              child: Icon(
                Icons.school_rounded,
                color: const Color(0xFF6366F1),
                size: (widget.size * 0.44).clamp(22.0, 44.0),
                shadows: const [Shadow(color: Colors.black38, blurRadius: 6)],
              ),
            ),

          // 6. Wearable Party Hat on Photo
          if (activeAcc == 'party_hat')
            Positioned(
              top: -widget.size * 0.18,
              right: widget.size * 0.10,
              child: Icon(
                Icons.celebration_rounded,
                color: const Color(0xFFEC4899),
                size: (widget.size * 0.42).clamp(20.0, 42.0),
                shadows: const [Shadow(color: Colors.black38, blurRadius: 6)],
              ),
            ),

          // 7. Wearable Bowtie on Photo
          if (activeAcc == 'bowtie')
            Positioned(
              bottom: -widget.size * 0.05,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: widget.size * 0.08, vertical: widget.size * 0.03),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                child: const Text('🎀', style: TextStyle(fontSize: 14)),
              ),
            ),

          // 8. Wearable Headphones on Photo
          if (activeAcc == 'headphones')
            Positioned(
              top: widget.size * 0.04,
              child: Icon(
                Icons.headphones_rounded,
                color: const Color(0xFF0EA5E9),
                size: (widget.size * 0.90).clamp(36.0, 90.0),
                shadows: const [Shadow(color: Colors.black45, blurRadius: 6)],
              ),
            ),

          // 9. Companion Badge at Bottom-Right
          if (widget.withPen && !widget.isHeadOnly)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.all(widget.size * 0.06),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Icon(
                  acc.icon,
                  color: const Color(0xFFF59E0B),
                  size: (widget.size * 0.22).clamp(12.0, 22.0),
                ),
              ),
            ),
        ],
      );
    } else {
      mascotCore = CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _UniversalMascotPainter(
          mascotId: activeId,
          accessory: activeAcc,
          withPen: widget.withPen,
          isHeadOnly: widget.isHeadOnly,
        ),
      );
    }

    // Mood & Petting Overlays
    Widget fullMascot = Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        mascotCore,
        // Mood Badge
        if (widget.showMoodBadge && widget.mood != MascotMood.normal)
          Positioned(
            top: -2,
            left: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: widget.mood == MascotMood.happy
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (widget.mood == MascotMood.happy ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Icon(
                widget.mood == MascotMood.happy ? Icons.auto_awesome : Icons.sentiment_dissatisfied,
                color: Colors.white,
                size: (widget.size * 0.16).clamp(10.0, 15.0),
              ),
            ),
          ),
        // Floating Heart on Petting/Tap
        if (_isTapped)
          Positioned(
            top: -widget.size * 0.25,
            child: AnimatedOpacity(
              opacity: _isTapped ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.favorite_rounded,
                color: Colors.redAccent,
                size: (widget.size * 0.3).clamp(18.0, 26.0),
              ),
            ),
          ),
      ],
    );

    fullMascot = RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animCtrl,
        builder: (context, child) {
          final bounceScale = 1.0 + (_animCtrl.value * 0.16);
          final bounceOffset = _animCtrl.value * (widget.isHeadOnly ? -4.0 : -8.0);

          return Transform.translate(
            offset: Offset(0, bounceOffset),
            child: Transform.scale(
              scale: bounceScale,
              child: child,
            ),
          );
        },
        child: fullMascot,
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: fullMascot,
        ),
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: fullMascot,
    );
  }
}

class _UniversalMascotPainter extends CustomPainter {
  final String mascotId;
  final String accessory;
  final bool withPen;
  final bool isHeadOnly;

  _UniversalMascotPainter({
    required this.mascotId,
    required this.accessory,
    required this.withPen,
    required this.isHeadOnly,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw Wings under mascot if selected
    if (accessory == 'wings' && withPen) {
      _paintWingsUnder(canvas, w, h);
    }

    // 2. Draw Mascot Body & Face
    switch (mascotId) {
      case 'cat_black':
        _paintBlackCat(canvas, w, h);
        break;
      case 'cat_persian':
        _paintPersianCat(canvas, w, h);
        break;
      case 'cat_calico':
        _paintCalicoCat(canvas, w, h);
        break;
      case 'cat_muslim':
        _paintMuslimCat(canvas, w, h);
        break;
      case 'cat_samurai':
        _paintSamuraiCat(canvas, w, h);
        break;
      case 'shiba_gold':
        _paintShiba(canvas, w, h);
        break;
      case 'lion_gold':
        _paintLion(canvas, w, h);
        break;
      case 'panda_saver':
        _paintPanda(canvas, w, h);
        break;
      case 'fox_smart':
        _paintFox(canvas, w, h);
        break;
      case 'owl_wise':
        _paintOwl(canvas, w, h);
        break;
      case 'rabbit_rich':
        _paintRabbit(canvas, w, h);
        break;
      case 'bear_wealth':
        _paintBear(canvas, w, h);
        break;
      case 'robot_ai':
        _paintRobot(canvas, w, h);
        break;
      case 'cat_quill':
      default:
        _paintGingerTabbyCat(canvas, w, h);
        break;
    }

    // 3. Draw Accessory Overlays (Headwear, Neckwear, Handheld)
    if (withPen) {
      _paintAccessoryOverlay(canvas, w, h);
    }
  }

  void _paintWingsUnder(Canvas canvas, double w, double h) {
    final goldPaint = Paint()..color = const Color(0xFFFBBF24);
    final shadowGold = Paint()..color = const Color(0xFFD97706);

    // Left Wing
    final leftWing = Path()
      ..moveTo(w * 0.30, h * 0.50)
      ..quadraticBezierTo(w * 0.05, h * 0.20, -w * 0.15, h * 0.35)
      ..quadraticBezierTo(w * 0.05, h * 0.60, w * 0.30, h * 0.70)
      ..close();
    canvas.drawPath(leftWing, shadowGold);
    canvas.drawPath(leftWing, goldPaint..style = PaintingStyle.fill);

    // Right Wing
    final rightWing = Path()
      ..moveTo(w * 0.70, h * 0.50)
      ..quadraticBezierTo(w * 0.95, h * 0.20, w * 1.15, h * 0.35)
      ..quadraticBezierTo(w * 0.95, h * 0.60, w * 0.70, h * 0.70)
      ..close();
    canvas.drawPath(rightWing, shadowGold);
    canvas.drawPath(rightWing, goldPaint..style = PaintingStyle.fill);
  }

  /// 1. Ginger Tabby Cat (เหมี่ยวส้มจอมวางแผน)
  void _paintGingerTabbyCat(Canvas canvas, double w, double h) {
    final gingerPaint = Paint()..color = const Color(0xFFF97316);
    final darkOrange = Paint()..color = const Color(0xFFC2410C);
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);
    final pinkPaint = Paint()..color = const Color(0xFFF472B6);
    final darkPaint = Paint()..color = const Color(0xFF1E293B);
    final goldBell = Paint()..color = const Color(0xFFFBBF24);

    if (!isHeadOnly) {
      // Body
      final body = Path()
        ..moveTo(w * 0.32, h * 0.65)
        ..quadraticBezierTo(w * 0.20, h * 0.85, w * 0.25, h * 0.95)
        ..quadraticBezierTo(w * 0.50, h * 0.99, w * 0.75, h * 0.95)
        ..quadraticBezierTo(w * 0.80, h * 0.85, w * 0.68, h * 0.65)
        ..close();
      canvas.drawPath(body, gingerPaint);

      // Belly
      final belly = Path()
        ..moveTo(w * 0.38, h * 0.68)
        ..quadraticBezierTo(w * 0.32, h * 0.85, w * 0.36, h * 0.95)
        ..lineTo(w * 0.64, h * 0.95)
        ..quadraticBezierTo(w * 0.68, h * 0.85, w * 0.62, h * 0.68)
        ..close();
      canvas.drawPath(belly, whitePaint);

      // Tail
      final tail = Path()
        ..moveTo(w * 0.74, h * 0.90)
        ..quadraticBezierTo(w * 0.96, h * 0.80, w * 0.92, h * 0.62)
        ..quadraticBezierTo(w * 0.86, h * 0.62, w * 0.82, h * 0.82)
        ..close();
      canvas.drawPath(tail, darkOrange);

      // Collar
      final collar = Path()
        ..moveTo(w * 0.30, h * 0.66)
        ..quadraticBezierTo(w * 0.50, h * 0.74, w * 0.70, h * 0.66)
        ..lineTo(w * 0.70, h * 0.70)
        ..quadraticBezierTo(w * 0.50, h * 0.78, w * 0.30, h * 0.70)
        ..close();
      canvas.drawPath(collar, Paint()..color = const Color(0xFF2563EB));
      canvas.drawCircle(Offset(w * 0.50, h * 0.75), w * 0.05, goldBell);
    }

    // Ears
    final leftEar = Path()..moveTo(w * 0.16, h * 0.44)..quadraticBezierTo(w * 0.16, h * 0.16, w * 0.30, h * 0.12)..quadraticBezierTo(w * 0.44, h * 0.26, w * 0.42, h * 0.40)..close();
    canvas.drawPath(leftEar, gingerPaint);
    final leftInner = Path()..moveTo(w * 0.22, h * 0.38)..lineTo(w * 0.30, h * 0.18)..lineTo(w * 0.38, h * 0.35)..close();
    canvas.drawPath(leftInner, pinkPaint);

    final rightEar = Path()..moveTo(w * 0.84, h * 0.44)..quadraticBezierTo(w * 0.84, h * 0.16, w * 0.70, h * 0.12)..quadraticBezierTo(w * 0.56, h * 0.26, w * 0.58, h * 0.40)..close();
    canvas.drawPath(rightEar, gingerPaint);
    final rightInner = Path()..moveTo(w * 0.78, h * 0.38)..lineTo(w * 0.70, h * 0.18)..lineTo(w * 0.62, h * 0.35)..close();
    canvas.drawPath(rightInner, pinkPaint);

    // Head
    canvas.drawCircle(Offset(w * 0.5, h * 0.52), w * 0.36, gingerPaint);

    // Tabby Stripes on Forehead
    final stripePaint = Paint()..color = darkOrange.color..style = PaintingStyle.stroke..strokeWidth = w * 0.025..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.50, h * 0.22), Offset(w * 0.50, h * 0.34), stripePaint);
    canvas.drawLine(Offset(w * 0.42, h * 0.24), Offset(w * 0.44, h * 0.33), stripePaint);
    canvas.drawLine(Offset(w * 0.58, h * 0.24), Offset(w * 0.56, h * 0.33), stripePaint);

    // White Muzzle
    final muzzle = Path()
      ..moveTo(w * 0.30, h * 0.56)
      ..quadraticBezierTo(w * 0.50, h * 0.44, w * 0.70, h * 0.56)
      ..quadraticBezierTo(w * 0.50, h * 0.74, w * 0.30, h * 0.56)
      ..close();
    canvas.drawPath(muzzle, whitePaint);

    // Cheeks
    canvas.drawCircle(Offset(w * 0.28, h * 0.58), w * 0.055, pinkPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.58), w * 0.055, pinkPaint);

    // Big Anime Eyes
    final eyeR = w * 0.055;
    canvas.drawCircle(Offset(w * 0.35, h * 0.48), eyeR, darkPaint);
    canvas.drawCircle(Offset(w * 0.65, h * 0.48), eyeR, darkPaint);
    canvas.drawCircle(Offset(w * 0.335, h * 0.465), eyeR * 0.45, whitePaint);
    canvas.drawCircle(Offset(w * 0.635, h * 0.465), eyeR * 0.45, whitePaint);
    canvas.drawCircle(Offset(w * 0.37, h * 0.50), eyeR * 0.25, whitePaint);
    canvas.drawCircle(Offset(w * 0.67, h * 0.50), eyeR * 0.25, whitePaint);

    // Nose & Mouth
    final nose = Path()..moveTo(w * 0.47, h * 0.54)..lineTo(w * 0.53, h * 0.54)..lineTo(w * 0.50, h * 0.57)..close();
    canvas.drawPath(nose, pinkPaint);

    final mouthPaint = Paint()..color = darkPaint.color..style = PaintingStyle.stroke..strokeWidth = w * 0.02..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(w * 0.50, h * 0.57)..quadraticBezierTo(w * 0.44, h * 0.63, w * 0.40, h * 0.59), mouthPaint);
    canvas.drawPath(Path()..moveTo(w * 0.50, h * 0.57)..quadraticBezierTo(w * 0.56, h * 0.63, w * 0.60, h * 0.59), mouthPaint);

    // Whiskers
    final whiskerPaint = Paint()..color = darkPaint.color.withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = w * 0.015..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.16, h * 0.53), Offset(w * 0.26, h * 0.55), whiskerPaint);
    canvas.drawLine(Offset(w * 0.15, h * 0.60), Offset(w * 0.25, h * 0.59), whiskerPaint);
    canvas.drawLine(Offset(w * 0.84, h * 0.53), Offset(w * 0.74, h * 0.55), whiskerPaint);
    canvas.drawLine(Offset(w * 0.85, h * 0.60), Offset(w * 0.75, h * 0.59), whiskerPaint);
  }

  /// 2. Lucky Black Cat (เหมี่ยวดำตาวิ้งค์นำโชค)
  void _paintBlackCat(Canvas canvas, double w, double h) {
    final blackPaint = Paint()..color = const Color(0xFF1E293B);
    final goldEyes = Paint()..color = const Color(0xFFFBBF24);
    final pinkPaint = Paint()..color = const Color(0xFFF472B6);
    final redCollar = Paint()..color = const Color(0xFFEF4444);
    final goldBell = Paint()..color = const Color(0xFFFBBF24);
    final whiteSparkle = Paint()..color = const Color(0xFFFFFFFF);

    if (!isHeadOnly) {
      final body = Path()..moveTo(w * 0.32, h * 0.65)..quadraticBezierTo(w * 0.20, h * 0.85, w * 0.25, h * 0.95)..quadraticBezierTo(w * 0.50, h * 0.99, w * 0.75, h * 0.95)..quadraticBezierTo(w * 0.80, h * 0.85, w * 0.68, h * 0.65)..close();
      canvas.drawPath(body, blackPaint);
      canvas.drawPath(Path()..moveTo(w * 0.30, h * 0.66)..quadraticBezierTo(w * 0.50, h * 0.74, w * 0.70, h * 0.66)..lineTo(w * 0.70, h * 0.70)..quadraticBezierTo(w * 0.50, h * 0.78, w * 0.30, h * 0.70)..close(), redCollar);
      canvas.drawCircle(Offset(w * 0.50, h * 0.75), w * 0.05, goldBell);
    }

    // Ears
    canvas.drawPath(Path()..moveTo(w * 0.16, h * 0.44)..quadraticBezierTo(w * 0.16, h * 0.16, w * 0.30, h * 0.12)..quadraticBezierTo(w * 0.44, h * 0.26, w * 0.42, h * 0.40)..close(), blackPaint);
    canvas.drawPath(Path()..moveTo(w * 0.22, h * 0.38)..lineTo(w * 0.30, h * 0.18)..lineTo(w * 0.38, h * 0.35)..close(), pinkPaint);
    canvas.drawPath(Path()..moveTo(w * 0.84, h * 0.44)..quadraticBezierTo(w * 0.84, h * 0.16, w * 0.70, h * 0.12)..quadraticBezierTo(w * 0.56, h * 0.26, w * 0.58, h * 0.40)..close(), blackPaint);
    canvas.drawPath(Path()..moveTo(w * 0.78, h * 0.38)..lineTo(w * 0.70, h * 0.18)..lineTo(w * 0.62, h * 0.35)..close(), pinkPaint);

    // Head
    canvas.drawCircle(Offset(w * 0.5, h * 0.52), w * 0.36, blackPaint);

    // Cheeks
    canvas.drawCircle(Offset(w * 0.28, h * 0.58), w * 0.055, pinkPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.58), w * 0.055, pinkPaint);

    // Golden Sparkling Eyes
    final eyeR = w * 0.06;
    canvas.drawCircle(Offset(w * 0.35, h * 0.48), eyeR, goldEyes);
    canvas.drawCircle(Offset(w * 0.65, h * 0.48), eyeR, goldEyes);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.35, h * 0.48), width: eyeR * 0.8, height: eyeR * 1.8), Paint()..color = const Color(0xFF0F172A));
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.65, h * 0.48), width: eyeR * 0.8, height: eyeR * 1.8), Paint()..color = const Color(0xFF0F172A));
    canvas.drawCircle(Offset(w * 0.33, h * 0.45), eyeR * 0.4, whiteSparkle);
    canvas.drawCircle(Offset(w * 0.63, h * 0.45), eyeR * 0.4, whiteSparkle);

    // Nose & Mouth
    canvas.drawPath(Path()..moveTo(w * 0.47, h * 0.54)..lineTo(w * 0.53, h * 0.54)..lineTo(w * 0.50, h * 0.57)..close(), pinkPaint);
    final mouthPaint = Paint()..color = Colors.white70..style = PaintingStyle.stroke..strokeWidth = w * 0.02..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(w * 0.50, h * 0.57)..quadraticBezierTo(w * 0.44, h * 0.63, w * 0.40, h * 0.59), mouthPaint);
    canvas.drawPath(Path()..moveTo(w * 0.50, h * 0.57)..quadraticBezierTo(w * 0.56, h * 0.63, w * 0.60, h * 0.59), mouthPaint);

    // White Whiskers
    final whiskerPaint = Paint()..color = Colors.white60..style = PaintingStyle.stroke..strokeWidth = w * 0.015..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.16, h * 0.53), Offset(w * 0.26, h * 0.55), whiskerPaint);
    canvas.drawLine(Offset(w * 0.15, h * 0.60), Offset(w * 0.25, h * 0.59), whiskerPaint);
    canvas.drawLine(Offset(w * 0.84, h * 0.53), Offset(w * 0.74, h * 0.55), whiskerPaint);
    canvas.drawLine(Offset(w * 0.85, h * 0.60), Offset(w * 0.75, h * 0.59), whiskerPaint);
  }

  /// 3. Royal Persian Cat (เหมี่ยวเปอร์เซียราชนิกุล ขนฟู ตา 2 สี)
  void _paintPersianCat(Canvas canvas, double w, double h) {
    final furWhite = Paint()..color = const Color(0xFFF8FAFC);
    final blueEye = Paint()..color = const Color(0xFF0284C7);
    final amberEye = Paint()..color = const Color(0xFFF59E0B);
    final pinkPaint = Paint()..color = const Color(0xFFF472B6);
    final darkPupil = Paint()..color = const Color(0xFF0F172A);
    final whiteSparkle = Paint()..color = const Color(0xFFFFFFFF);

    if (!isHeadOnly) {
      final body = Path()..moveTo(w * 0.32, h * 0.65)..quadraticBezierTo(w * 0.15, h * 0.85, w * 0.25, h * 0.95)..quadraticBezierTo(w * 0.50, h * 0.99, w * 0.75, h * 0.95)..quadraticBezierTo(w * 0.85, h * 0.85, w * 0.68, h * 0.65)..close();
      canvas.drawPath(body, furWhite);
    }

    // Fluffy Cheeks & Head
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * math.pi / 180;
      canvas.drawCircle(Offset(w * 0.5 + (w * 0.32) * math.cos(angle), h * 0.52 + (h * 0.30) * math.sin(angle)), w * 0.12, furWhite);
    }
    canvas.drawCircle(Offset(w * 0.5, h * 0.52), w * 0.36, furWhite);

    // Ears
    canvas.drawPath(Path()..moveTo(w * 0.18, h * 0.40)..lineTo(w * 0.28, h * 0.14)..lineTo(w * 0.40, h * 0.35)..close(), furWhite);
    canvas.drawPath(Path()..moveTo(w * 0.23, h * 0.35)..lineTo(w * 0.28, h * 0.20)..lineTo(w * 0.35, h * 0.32)..close(), pinkPaint);
    canvas.drawPath(Path()..moveTo(w * 0.82, h * 0.40)..lineTo(w * 0.72, h * 0.14)..lineTo(w * 0.60, h * 0.35)..close(), furWhite);
    canvas.drawPath(Path()..moveTo(w * 0.77, h * 0.35)..lineTo(w * 0.72, h * 0.20)..lineTo(w * 0.65, h * 0.32)..close(), pinkPaint);

    // Heterochromia Eyes (Left Blue, Right Amber)
    final eyeR = w * 0.055;
    canvas.drawCircle(Offset(w * 0.35, h * 0.48), eyeR, blueEye);
    canvas.drawCircle(Offset(w * 0.65, h * 0.48), eyeR, amberEye);
    canvas.drawCircle(Offset(w * 0.35, h * 0.48), eyeR * 0.55, darkPupil);
    canvas.drawCircle(Offset(w * 0.65, h * 0.48), eyeR * 0.55, darkPupil);
    canvas.drawCircle(Offset(w * 0.33, h * 0.46), eyeR * 0.3, whiteSparkle);
    canvas.drawCircle(Offset(w * 0.63, h * 0.46), eyeR * 0.3, whiteSparkle);

    // Cheeks
    canvas.drawCircle(Offset(w * 0.28, h * 0.58), w * 0.055, pinkPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.58), w * 0.055, pinkPaint);

    // Flat Persian Nose & Mouth
    canvas.drawCircle(Offset(w * 0.5, h * 0.53), w * 0.03, pinkPaint);
    final mouthPaint = Paint()..color = darkPupil.color..style = PaintingStyle.stroke..strokeWidth = w * 0.018..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(w * 0.50, h * 0.55)..quadraticBezierTo(w * 0.45, h * 0.60, w * 0.41, h * 0.57), mouthPaint);
    canvas.drawPath(Path()..moveTo(w * 0.50, h * 0.55)..quadraticBezierTo(w * 0.55, h * 0.60, w * 0.59, h * 0.57), mouthPaint);
  }

  /// 4. Muslim Rizqi Cat (เหมี่ยวขาวมุสลิมริซกี ใส่หมวกกะปิเยาะห์/ซงก๊ก)
  void _paintMuslimCat(Canvas canvas, double w, double h) {
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);
    final greenKapiyah = Paint()..color = const Color(0xFF10B981);
    final goldTrim = Paint()..color = const Color(0xFFFBBF24);
    final pinkPaint = Paint()..color = const Color(0xFFF472B6);
    final darkPaint = Paint()..color = const Color(0xFF1E293B);

    if (!isHeadOnly) {
      final body = Path()..moveTo(w * 0.32, h * 0.65)..quadraticBezierTo(w * 0.20, h * 0.85, w * 0.25, h * 0.95)..quadraticBezierTo(w * 0.50, h * 0.99, w * 0.75, h * 0.95)..quadraticBezierTo(w * 0.80, h * 0.85, w * 0.68, h * 0.65)..close();
      canvas.drawPath(body, whitePaint);
      canvas.drawPath(Path()..moveTo(w * 0.30, h * 0.66)..quadraticBezierTo(w * 0.50, h * 0.74, w * 0.70, h * 0.66)..lineTo(w * 0.70, h * 0.72)..quadraticBezierTo(w * 0.50, h * 0.80, w * 0.30, h * 0.72)..close(), greenKapiyah);
    }

    // Ears
    canvas.drawPath(Path()..moveTo(w * 0.16, h * 0.44)..quadraticBezierTo(w * 0.16, h * 0.16, w * 0.30, h * 0.12)..quadraticBezierTo(w * 0.44, h * 0.26, w * 0.42, h * 0.40)..close(), whitePaint);
    canvas.drawPath(Path()..moveTo(w * 0.22, h * 0.38)..lineTo(w * 0.30, h * 0.18)..lineTo(w * 0.38, h * 0.35)..close(), pinkPaint);
    canvas.drawPath(Path()..moveTo(w * 0.84, h * 0.44)..quadraticBezierTo(w * 0.84, h * 0.16, w * 0.70, h * 0.12)..quadraticBezierTo(w * 0.56, h * 0.26, w * 0.58, h * 0.40)..close(), whitePaint);
    canvas.drawPath(Path()..moveTo(w * 0.78, h * 0.38)..lineTo(w * 0.70, h * 0.18)..lineTo(w * 0.62, h * 0.35)..close(), pinkPaint);

    // Head
    canvas.drawCircle(Offset(w * 0.5, h * 0.52), w * 0.36, whitePaint);

    // Green Kapiyah Cap on Head
    final kapiyah = Path()
      ..moveTo(w * 0.32, h * 0.25)
      ..quadraticBezierTo(w * 0.50, h * 0.12, w * 0.68, h * 0.25)
      ..lineTo(w * 0.66, h * 0.32)
      ..quadraticBezierTo(w * 0.50, h * 0.24, w * 0.34, h * 0.32)
      ..close();
    canvas.drawPath(kapiyah, greenKapiyah);
    canvas.drawPath(Path()..moveTo(w * 0.33, h * 0.31)..quadraticBezierTo(w * 0.50, h * 0.24, w * 0.67, h * 0.31), Paint()..color = goldTrim.color..style = PaintingStyle.stroke..strokeWidth = 2);

    // Cheeks
    canvas.drawCircle(Offset(w * 0.28, h * 0.58), w * 0.055, pinkPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.58), w * 0.055, pinkPaint);

    // Eyes
    final eyeR = w * 0.055;
    canvas.drawCircle(Offset(w * 0.35, h * 0.48), eyeR, darkPaint);
    canvas.drawCircle(Offset(w * 0.65, h * 0.48), eyeR, darkPaint);
    canvas.drawCircle(Offset(w * 0.335, h * 0.465), eyeR * 0.45, whitePaint);
    canvas.drawCircle(Offset(w * 0.635, h * 0.465), eyeR * 0.45, whitePaint);

    // Nose & Mouth
    canvas.drawPath(Path()..moveTo(w * 0.47, h * 0.54)..lineTo(w * 0.53, h * 0.54)..lineTo(w * 0.50, h * 0.57)..close(), pinkPaint);
    final mouthPaint = Paint()..color = darkPaint.color..style = PaintingStyle.stroke..strokeWidth = w * 0.02..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(w * 0.50, h * 0.57)..quadraticBezierTo(w * 0.44, h * 0.63, w * 0.40, h * 0.59), mouthPaint);
    canvas.drawPath(Path()..moveTo(w * 0.50, h * 0.57)..quadraticBezierTo(w * 0.56, h * 0.63, w * 0.60, h * 0.59), mouthPaint);
  }

  /// 5. Samurai Cat (เหมี่ยวซามูไรการเงิน ผ้าคาดหัวแดง)
  void _paintSamuraiCat(Canvas canvas, double w, double h) {
    final greyPaint = Paint()..color = const Color(0xFF64748B);
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);
    final redHeadband = Paint()..color = const Color(0xFFEF4444);
    final pinkPaint = Paint()..color = const Color(0xFFF472B6);
    final darkPaint = Paint()..color = const Color(0xFF0F172A);

    if (!isHeadOnly) {
      final body = Path()..moveTo(w * 0.32, h * 0.65)..quadraticBezierTo(w * 0.20, h * 0.85, w * 0.25, h * 0.95)..quadraticBezierTo(w * 0.50, h * 0.99, w * 0.75, h * 0.95)..quadraticBezierTo(w * 0.80, h * 0.85, w * 0.68, h * 0.65)..close();
      canvas.drawPath(body, greyPaint);
    }

    // Ears
    canvas.drawPath(Path()..moveTo(w * 0.16, h * 0.44)..quadraticBezierTo(w * 0.16, h * 0.16, w * 0.30, h * 0.12)..quadraticBezierTo(w * 0.44, h * 0.26, w * 0.42, h * 0.40)..close(), greyPaint);
    canvas.drawPath(Path()..moveTo(w * 0.22, h * 0.38)..lineTo(w * 0.30, h * 0.18)..lineTo(w * 0.38, h * 0.35)..close(), pinkPaint);
    canvas.drawPath(Path()..moveTo(w * 0.84, h * 0.44)..quadraticBezierTo(w * 0.84, h * 0.16, w * 0.70, h * 0.12)..quadraticBezierTo(w * 0.56, h * 0.26, w * 0.58, h * 0.40)..close(), greyPaint);
    canvas.drawPath(Path()..moveTo(w * 0.78, h * 0.38)..lineTo(w * 0.70, h * 0.18)..lineTo(w * 0.62, h * 0.35)..close(), pinkPaint);

    // Head
    canvas.drawCircle(Offset(w * 0.5, h * 0.52), w * 0.36, greyPaint);

    // Red Samurai Headband
    final headband = Path()
      ..moveTo(w * 0.16, h * 0.34)
      ..quadraticBezierTo(w * 0.50, h * 0.26, w * 0.84, h * 0.34)
      ..lineTo(w * 0.83, h * 0.40)
      ..quadraticBezierTo(w * 0.50, h * 0.32, w * 0.17, h * 0.40)
      ..close();
    canvas.drawPath(headband, redHeadband);
    canvas.drawPath(Path()..moveTo(w * 0.82, h * 0.36)..lineTo(w * 0.94, h * 0.44)..lineTo(w * 0.84, h * 0.48)..close(), redHeadband);

    // White Muzzle
    canvas.drawCircle(Offset(w * 0.5, h * 0.60), w * 0.18, whitePaint);

    // Eyes
    final eyeR = w * 0.055;
    canvas.drawCircle(Offset(w * 0.35, h * 0.48), eyeR, darkPaint);
    canvas.drawCircle(Offset(w * 0.65, h * 0.48), eyeR, darkPaint);
    canvas.drawCircle(Offset(w * 0.335, h * 0.465), eyeR * 0.45, whitePaint);
    canvas.drawCircle(Offset(w * 0.635, h * 0.465), eyeR * 0.45, whitePaint);

    // Nose & Mouth
    canvas.drawPath(Path()..moveTo(w * 0.47, h * 0.54)..lineTo(w * 0.53, h * 0.54)..lineTo(w * 0.50, h * 0.57)..close(), pinkPaint);
    final mouthPaint = Paint()..color = darkPaint.color..style = PaintingStyle.stroke..strokeWidth = w * 0.02..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(w * 0.50, h * 0.57)..quadraticBezierTo(w * 0.44, h * 0.63, w * 0.40, h * 0.59), mouthPaint);
    canvas.drawPath(Path()..moveTo(w * 0.50, h * 0.57)..quadraticBezierTo(w * 0.56, h * 0.63, w * 0.60, h * 0.59), mouthPaint);
  }

  /// 6. Calico Cat (เหมี่ยวสามสีนำโชค)
  void _paintCalicoCat(Canvas canvas, double w, double h) {
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);
    final orangePaint = Paint()..color = const Color(0xFFF97316);
    final blackPaint = Paint()..color = const Color(0xFF1E293B);
    final pinkPaint = Paint()..color = const Color(0xFFF472B6);
    final darkPaint = Paint()..color = const Color(0xFF1E293B);

    if (!isHeadOnly) {
      canvas.drawPath(Path()..moveTo(w * 0.32, h * 0.65)..quadraticBezierTo(w * 0.20, h * 0.85, w * 0.25, h * 0.95)..quadraticBezierTo(w * 0.50, h * 0.99, w * 0.75, h * 0.95)..quadraticBezierTo(w * 0.80, h * 0.85, w * 0.68, h * 0.65)..close(), whitePaint);
      canvas.drawCircle(Offset(w * 0.30, h * 0.80), w * 0.10, orangePaint);
      canvas.drawCircle(Offset(w * 0.70, h * 0.85), w * 0.08, blackPaint);
    }

    // Left Ear Orange, Right Ear Black
    canvas.drawPath(Path()..moveTo(w * 0.16, h * 0.44)..quadraticBezierTo(w * 0.16, h * 0.16, w * 0.30, h * 0.12)..quadraticBezierTo(w * 0.44, h * 0.26, w * 0.42, h * 0.40)..close(), orangePaint);
    canvas.drawPath(Path()..moveTo(w * 0.22, h * 0.38)..lineTo(w * 0.30, h * 0.18)..lineTo(w * 0.38, h * 0.35)..close(), pinkPaint);
    canvas.drawPath(Path()..moveTo(w * 0.84, h * 0.44)..quadraticBezierTo(w * 0.84, h * 0.16, w * 0.70, h * 0.12)..quadraticBezierTo(w * 0.56, h * 0.26, w * 0.58, h * 0.40)..close(), blackPaint);
    canvas.drawPath(Path()..moveTo(w * 0.78, h * 0.38)..lineTo(w * 0.70, h * 0.18)..lineTo(w * 0.62, h * 0.35)..close(), pinkPaint);

    // Head
    canvas.drawCircle(Offset(w * 0.5, h * 0.52), w * 0.36, whitePaint);
    canvas.drawCircle(Offset(w * 0.32, h * 0.36), w * 0.14, orangePaint);
    canvas.drawCircle(Offset(w * 0.68, h * 0.34), w * 0.12, blackPaint);

    // Cheeks
    canvas.drawCircle(Offset(w * 0.28, h * 0.58), w * 0.055, pinkPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.58), w * 0.055, pinkPaint);

    // Eyes
    final eyeR = w * 0.055;
    canvas.drawCircle(Offset(w * 0.35, h * 0.48), eyeR, darkPaint);
    canvas.drawCircle(Offset(w * 0.65, h * 0.48), eyeR, darkPaint);
    canvas.drawCircle(Offset(w * 0.335, h * 0.465), eyeR * 0.45, whitePaint);
    canvas.drawCircle(Offset(w * 0.635, h * 0.465), eyeR * 0.45, whitePaint);

    // Nose & Mouth
    canvas.drawPath(Path()..moveTo(w * 0.47, h * 0.54)..lineTo(w * 0.53, h * 0.54)..lineTo(w * 0.50, h * 0.57)..close(), pinkPaint);
    final mouthPaint = Paint()..color = darkPaint.color..style = PaintingStyle.stroke..strokeWidth = w * 0.02..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(w * 0.50, h * 0.57)..quadraticBezierTo(w * 0.44, h * 0.63, w * 0.40, h * 0.59), mouthPaint);
    canvas.drawPath(Path()..moveTo(w * 0.50, h * 0.57)..quadraticBezierTo(w * 0.56, h * 0.63, w * 0.60, h * 0.59), mouthPaint);
  }

  void _paintShiba(Canvas canvas, double w, double h) {
    final shibaGold = Paint()..color = const Color(0xFFEAB308);
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);
    final darkPaint = Paint()..color = const Color(0xFF1E293B);
    final pinkPaint = Paint()..color = const Color(0xFFF472B6);

    final leftEar = Path()..moveTo(w * 0.22, h * 0.38)..lineTo(w * 0.32, h * 0.12)..lineTo(w * 0.44, h * 0.34)..close();
    final rightEar = Path()..moveTo(w * 0.78, h * 0.38)..lineTo(w * 0.68, h * 0.12)..lineTo(w * 0.56, h * 0.34)..close();
    canvas.drawPath(leftEar, shibaGold);
    canvas.drawPath(rightEar, shibaGold);

    canvas.drawCircle(Offset(w * 0.5, h * 0.54), w * 0.36, shibaGold);
    final muzzle = Path()..moveTo(w * 0.24, h * 0.60)..quadraticBezierTo(w * 0.50, h * 0.38, w * 0.76, h * 0.60)..quadraticBezierTo(w * 0.50, h * 0.88, w * 0.24, h * 0.60)..close();
    canvas.drawPath(muzzle, whitePaint);

    canvas.drawCircle(Offset(w * 0.36, h * 0.48), w * 0.045, darkPaint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.48), w * 0.045, darkPaint);
    canvas.drawCircle(Offset(w * 0.36, h * 0.38), w * 0.04, whitePaint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.38), w * 0.04, whitePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.56), width: w * 0.09, height: h * 0.06), darkPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.64), width: w * 0.08, height: h * 0.08), pinkPaint);
  }

  void _paintLion(Canvas canvas, double w, double h) {
    final goldMane = Paint()..color = const Color(0xFFD97706);
    final lionFace = Paint()..color = const Color(0xFFFDE68A);
    final darkPaint = Paint()..color = const Color(0xFF1E293B);

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final cx = w * 0.5 + (w * 0.34) * math.cos(angle);
      final cy = h * 0.52 + (h * 0.34) * math.sin(angle);
      canvas.drawCircle(Offset(cx, cy), w * 0.14, goldMane);
    }
    canvas.drawCircle(Offset(w * 0.5, h * 0.52), w * 0.32, lionFace);
    canvas.drawCircle(Offset(w * 0.38, h * 0.46), w * 0.045, darkPaint);
    canvas.drawCircle(Offset(w * 0.62, h * 0.46), w * 0.045, darkPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.56), width: w * 0.10, height: h * 0.07), darkPaint);
  }

  void _paintPanda(Canvas canvas, double w, double h) {
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);
    final darkPaint = Paint()..color = const Color(0xFF0F172A);

    canvas.drawCircle(Offset(w * 0.24, h * 0.26), w * 0.12, darkPaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.26), w * 0.12, darkPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.54), w * 0.36, whitePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.36, h * 0.48), width: w * 0.16, height: h * 0.22), darkPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.64, h * 0.48), width: w * 0.16, height: h * 0.22), darkPaint);
    canvas.drawCircle(Offset(w * 0.37, h * 0.48), w * 0.035, whitePaint);
    canvas.drawCircle(Offset(w * 0.63, h * 0.48), w * 0.035, whitePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.60), width: w * 0.10, height: h * 0.07), darkPaint);
  }

  void _paintFox(Canvas canvas, double w, double h) {
    final foxOrange = Paint()..color = const Color(0xFFEA580C);
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);
    final darkPaint = Paint()..color = const Color(0xFF1E293B);

    final leftEar = Path()..moveTo(w * 0.18, h * 0.40)..lineTo(w * 0.28, h * 0.08)..lineTo(w * 0.46, h * 0.30)..close();
    final rightEar = Path()..moveTo(w * 0.82, h * 0.40)..lineTo(w * 0.72, h * 0.08)..lineTo(w * 0.54, h * 0.30)..close();
    canvas.drawPath(leftEar, foxOrange);
    canvas.drawPath(rightEar, foxOrange);

    canvas.drawCircle(Offset(w * 0.5, h * 0.52), w * 0.36, foxOrange);
    final whiteMuzzle = Path()..moveTo(w * 0.18, h * 0.58)..quadraticBezierTo(w * 0.50, h * 0.42, w * 0.82, h * 0.58)..lineTo(w * 0.50, h * 0.86)..close();
    canvas.drawPath(whiteMuzzle, whitePaint);
    canvas.drawCircle(Offset(w * 0.36, h * 0.46), w * 0.045, darkPaint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.46), w * 0.045, darkPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.66), w * 0.05, darkPaint);
  }

  void _paintOwl(Canvas canvas, double w, double h) {
    final purplePaint = Paint()..color = const Color(0xFF6366F1);
    final goldPaint = Paint()..color = const Color(0xFFFBBF24);
    final darkPaint = Paint()..color = const Color(0xFF1E293B);
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);

    canvas.drawCircle(Offset(w * 0.5, h * 0.54), w * 0.38, purplePaint);
    canvas.drawCircle(Offset(w * 0.36, h * 0.48), w * 0.14, whitePaint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.48), w * 0.14, whitePaint);
    canvas.drawCircle(Offset(w * 0.36, h * 0.48), w * 0.07, goldPaint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.48), w * 0.07, goldPaint);
    canvas.drawCircle(Offset(w * 0.36, h * 0.48), w * 0.04, darkPaint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.48), w * 0.04, darkPaint);
    final beak = Path()..moveTo(w * 0.46, h * 0.56)..lineTo(w * 0.54, h * 0.56)..lineTo(w * 0.50, h * 0.68)..close();
    canvas.drawPath(beak, goldPaint);
  }

  void _paintRabbit(Canvas canvas, double w, double h) {
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);
    final pinkPaint = Paint()..color = const Color(0xFFF472B6);
    final darkPaint = Paint()..color = const Color(0xFF1E293B);

    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.32, h * 0.22), width: w * 0.16, height: h * 0.40), whitePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.32, h * 0.22), width: w * 0.09, height: h * 0.28), pinkPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.68, h * 0.22), width: w * 0.16, height: h * 0.40), whitePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.68, h * 0.22), width: w * 0.09, height: h * 0.28), pinkPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.58), w * 0.35, whitePaint);
    canvas.drawCircle(Offset(w * 0.32, h * 0.65), w * 0.06, pinkPaint);
    canvas.drawCircle(Offset(w * 0.68, h * 0.65), w * 0.06, pinkPaint);
    canvas.drawCircle(Offset(w * 0.38, h * 0.54), w * 0.045, darkPaint);
    canvas.drawCircle(Offset(w * 0.62, h * 0.54), w * 0.045, darkPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.62), w * 0.03, pinkPaint);
  }

  void _paintBear(Canvas canvas, double w, double h) {
    final brownPaint = Paint()..color = const Color(0xFF854D0E);
    final lightBrown = Paint()..color = const Color(0xFFFEF08A);
    final darkPaint = Paint()..color = const Color(0xFF1E293B);

    canvas.drawCircle(Offset(w * 0.24, h * 0.26), w * 0.14, brownPaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.26), w * 0.14, brownPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.54), w * 0.38, brownPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.64), width: w * 0.34, height: h * 0.24), lightBrown);
    canvas.drawCircle(Offset(w * 0.36, h * 0.48), w * 0.045, darkPaint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.48), w * 0.045, darkPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.58), w * 0.04, darkPaint);
  }

  void _paintRobot(Canvas canvas, double w, double h) {
    final cyanPaint = Paint()..color = const Color(0xFF0EA5E9);
    final darkNavy = Paint()..color = const Color(0xFF0F172A);
    final limePaint = Paint()..color = const Color(0xFF10B981);

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.5, h * 0.54), width: w * 0.68, height: h * 0.62), const Radius.circular(14)), cyanPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.5, h * 0.50), width: w * 0.54, height: h * 0.30), const Radius.circular(8)), darkNavy);
    canvas.drawCircle(Offset(w * 0.38, h * 0.50), w * 0.06, limePaint);
    canvas.drawCircle(Offset(w * 0.62, h * 0.50), w * 0.06, limePaint);
  }

  /// 4. Draw ALL 25 Accessories with Rich Visual Details
  void _paintAccessoryOverlay(Canvas canvas, double w, double h) {
    final paintGold = Paint()..color = const Color(0xFFFBBF24);
    final paintDarkGold = Paint()..color = const Color(0xFFD97706);
    final paintRed = Paint()..color = const Color(0xFFEF4444);
    final paintBlue = Paint()..color = const Color(0xFF0284C7);
    final paintDark = Paint()..color = const Color(0xFF0F172A);
    final paintWhite = Paint()..color = const Color(0xFFFFFFFF);
    final paintGreen = Paint()..color = const Color(0xFF10B981);
    final paintPurple = Paint()..color = const Color(0xFF8B5CF6);

    switch (accessory) {
      case 'crown':
        final crownPath = Path()
          ..moveTo(w * 0.30, h * 0.18)
          ..lineTo(w * 0.36, h * 0.02)
          ..lineTo(w * 0.50, h * 0.12)
          ..lineTo(w * 0.64, h * 0.02)
          ..lineTo(w * 0.70, h * 0.18)
          ..close();
        canvas.drawPath(crownPath, paintGold);
        canvas.drawCircle(Offset(w * 0.36, h * 0.02), w * 0.03, paintRed);
        canvas.drawCircle(Offset(w * 0.50, h * 0.12), w * 0.035, paintBlue);
        canvas.drawCircle(Offset(w * 0.64, h * 0.02), w * 0.03, paintRed);
        break;

      case 'gold_shades':
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.35, h * 0.48), width: w * 0.20, height: h * 0.12), const Radius.circular(5)), paintDark);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.65, h * 0.48), width: w * 0.20, height: h * 0.12), const Radius.circular(5)), paintDark);
        canvas.drawLine(Offset(w * 0.35, h * 0.48), Offset(w * 0.65, h * 0.48), Paint()..color = paintGold.color..strokeWidth = 2.5);
        canvas.drawLine(Offset(w * 0.28, h * 0.45), Offset(w * 0.38, h * 0.51), Paint()..color = Colors.white38..strokeWidth = 2);
        canvas.drawLine(Offset(w * 0.58, h * 0.45), Offset(w * 0.68, h * 0.51), Paint()..color = Colors.white38..strokeWidth = 2);
        break;

      case 'grad_cap':
        final cap = Path()
          ..moveTo(w * 0.50, h * 0.06)
          ..lineTo(w * 0.80, h * 0.15)
          ..lineTo(w * 0.50, h * 0.24)
          ..lineTo(w * 0.20, h * 0.15)
          ..close();
        canvas.drawPath(cap, paintDark);
        canvas.drawCircle(Offset(w * 0.50, h * 0.15), w * 0.03, paintGold);
        canvas.drawLine(Offset(w * 0.50, h * 0.15), Offset(w * 0.78, h * 0.22), Paint()..color = paintGold.color..strokeWidth = 2);
        break;

      case 'headphones':
        final hpPaint = Paint()..color = const Color(0xFF0EA5E9)..style = PaintingStyle.stroke..strokeWidth = w * 0.045..strokeCap = StrokeCap.round;
        canvas.drawArc(Rect.fromCenter(center: Offset(w * 0.50, h * 0.40), width: w * 0.74, height: h * 0.60), math.pi, math.pi, false, hpPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.14, h * 0.48), width: w * 0.09, height: h * 0.20), const Radius.circular(6)), Paint()..color = const Color(0xFF0EA5E9));
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.86, h * 0.48), width: w * 0.09, height: h * 0.20), const Radius.circular(6)), Paint()..color = const Color(0xFF0EA5E9));
        break;

      case 'party_hat':
        final partyHat = Path()
          ..moveTo(w * 0.65, h * 0.02)
          ..lineTo(w * 0.82, h * 0.28)
          ..lineTo(w * 0.54, h * 0.26)
          ..close();
        canvas.drawPath(partyHat, paintPurple);
        canvas.drawCircle(Offset(w * 0.65, h * 0.02), w * 0.04, paintGold);
        break;

      case 'bowtie':
        final bowtie = Path()
          ..moveTo(w * 0.50, h * 0.70)
          ..lineTo(w * 0.38, h * 0.64)
          ..lineTo(w * 0.38, h * 0.76)
          ..lineTo(w * 0.50, h * 0.70)
          ..lineTo(w * 0.62, h * 0.64)
          ..lineTo(w * 0.62, h * 0.76)
          ..close();
        canvas.drawPath(bowtie, paintRed);
        canvas.drawCircle(Offset(w * 0.50, h * 0.70), w * 0.035, paintDarkGold);
        break;

      case 'scarf':
        final scarf = Path()
          ..moveTo(w * 0.30, h * 0.66)
          ..quadraticBezierTo(w * 0.50, h * 0.76, w * 0.70, h * 0.66)
          ..lineTo(w * 0.70, h * 0.74)
          ..quadraticBezierTo(w * 0.50, h * 0.84, w * 0.30, h * 0.74)
          ..close();
        canvas.drawPath(scarf, paintRed);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.64, h * 0.84), width: w * 0.10, height: h * 0.18), const Radius.circular(4)), paintRed);
        break;

      case 'songkok':
        final songkok = Path()
          ..moveTo(w * 0.34, h * 0.24)
          ..quadraticBezierTo(w * 0.50, h * 0.12, w * 0.66, h * 0.24)
          ..lineTo(w * 0.64, h * 0.32)
          ..quadraticBezierTo(w * 0.50, h * 0.23, w * 0.36, h * 0.32)
          ..close();
        canvas.drawPath(songkok, paintDark);
        canvas.drawPath(Path()..moveTo(w * 0.35, h * 0.30)..quadraticBezierTo(w * 0.50, h * 0.23, w * 0.65, h * 0.30), Paint()..color = paintGold.color..style = PaintingStyle.stroke..strokeWidth = 2);
        break;

      case 'halo':
        final haloPaint = Paint()..color = const Color(0xFFFDE047)..style = PaintingStyle.stroke..strokeWidth = w * 0.035;
        canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.50, h * 0.08), width: w * 0.46, height: h * 0.14), haloPaint);
        break;

      case 'wizard_hat':
        final wiz = Path()
          ..moveTo(w * 0.50, h * -0.05)
          ..lineTo(w * 0.76, h * 0.26)
          ..lineTo(w * 0.24, h * 0.26)
          ..close();
        canvas.drawPath(wiz, paintPurple);
        canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.50, h * 0.26), width: w * 0.60, height: h * 0.10), paintPurple);
        canvas.drawCircle(Offset(w * 0.50, h * 0.14), w * 0.04, paintGold);
        break;

      case 'flower':
        canvas.drawCircle(Offset(w * 0.72, h * 0.24), w * 0.06, paintRed);
        canvas.drawCircle(Offset(w * 0.66, h * 0.20), w * 0.05, paintPurple);
        canvas.drawCircle(Offset(w * 0.78, h * 0.20), w * 0.05, paintPurple);
        canvas.drawCircle(Offset(w * 0.66, h * 0.28), w * 0.05, paintPurple);
        canvas.drawCircle(Offset(w * 0.78, h * 0.28), w * 0.05, paintPurple);
        canvas.drawCircle(Offset(w * 0.72, h * 0.24), w * 0.03, paintGold);
        break;

      case 'headband':
        final hb = Path()
          ..moveTo(w * 0.16, h * 0.35)
          ..quadraticBezierTo(w * 0.50, h * 0.27, w * 0.84, h * 0.35)
          ..lineTo(w * 0.83, h * 0.41)
          ..quadraticBezierTo(w * 0.50, h * 0.33, w * 0.17, h * 0.41)
          ..close();
        canvas.drawPath(hb, paintRed);
        canvas.drawPath(Path()..moveTo(w * 0.82, h * 0.37)..lineTo(w * 0.96, h * 0.46)..lineTo(w * 0.84, h * 0.50)..close(), paintRed);
        break;

      case 'coin':
        canvas.drawCircle(Offset(w * 0.74, h * 0.74), w * 0.17, paintGold);
        canvas.drawCircle(Offset(w * 0.74, h * 0.74), w * 0.13, paintDarkGold);
        canvas.drawCircle(Offset(w * 0.74, h * 0.74), w * 0.08, paintGold);
        break;

      case 'money_bag':
        final bag = Path()
          ..moveTo(w * 0.74, h * 0.60)
          ..lineTo(w * 0.68, h * 0.66)
          ..lineTo(w * 0.60, h * 0.86)
          ..quadraticBezierTo(w * 0.74, h * 0.94, w * 0.88, h * 0.86)
          ..lineTo(w * 0.80, h * 0.66)
          ..close();
        canvas.drawPath(bag, paintGreen);
        canvas.drawCircle(Offset(w * 0.74, h * 0.62), w * 0.04, paintGold);
        break;

      case 'calculator':
        final calc = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.74, h * 0.76), width: w * 0.22, height: h * 0.28), const Radius.circular(5));
        canvas.drawRRect(calc, paintDark);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.74, h * 0.68), width: w * 0.16, height: h * 0.07), const Radius.circular(2)), Paint()..color = const Color(0xFF6EE7B7));
        for (int row = 0; row < 2; row++) {
          for (int col = 0; col < 2; col++) {
            canvas.drawCircle(Offset(w * (0.69 + col * 0.10), h * (0.76 + row * 0.08)), w * 0.025, paintWhite);
          }
        }
        break;

      case 'book':
        final book = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.74, h * 0.76), width: w * 0.24, height: h * 0.28), const Radius.circular(4));
        canvas.drawRRect(book, paintBlue);
        canvas.drawLine(Offset(w * 0.65, h * 0.64), Offset(w * 0.65, h * 0.88), Paint()..color = paintGold.color..strokeWidth = 3);
        canvas.drawCircle(Offset(w * 0.76, h * 0.76), w * 0.04, paintGold);
        break;

      case 'coffee':
        final cup = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.74, h * 0.78), width: w * 0.20, height: h * 0.20), const Radius.circular(4));
        canvas.drawRRect(cup, Paint()..color = const Color(0xFF78350F));
        canvas.drawCircle(Offset(w * 0.86, h * 0.78), w * 0.05, Paint()..color = const Color(0xFF78350F)..style = PaintingStyle.stroke..strokeWidth = 3);
        canvas.drawLine(Offset(w * 0.70, h * 0.64), Offset(w * 0.70, h * 0.58), Paint()..color = Colors.white54..strokeWidth = 2);
        canvas.drawLine(Offset(w * 0.78, h * 0.64), Offset(w * 0.78, h * 0.58), Paint()..color = Colors.white54..strokeWidth = 2);
        break;

      case 'laptop':
        final screen = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.74, h * 0.70), width: w * 0.26, height: h * 0.18), const Radius.circular(3));
        canvas.drawRRect(screen, Paint()..color = const Color(0xFF334155));
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.74, h * 0.70), width: w * 0.22, height: h * 0.14), const Radius.circular(2)), Paint()..color = const Color(0xFF38BDF8));
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.74, h * 0.82), width: w * 0.32, height: h * 0.05), const Radius.circular(2)), Paint()..color = const Color(0xFF64748B));
        break;

      case 'target':
        canvas.drawCircle(Offset(w * 0.74, h * 0.74), w * 0.17, paintRed);
        canvas.drawCircle(Offset(w * 0.74, h * 0.74), w * 0.12, paintWhite);
        canvas.drawCircle(Offset(w * 0.74, h * 0.74), w * 0.07, paintRed);
        canvas.drawCircle(Offset(w * 0.74, h * 0.74), w * 0.025, paintGold);
        break;

      case 'trophy':
        final cup = Path()
          ..moveTo(w * 0.66, h * 0.62)
          ..lineTo(w * 0.82, h * 0.62)
          ..lineTo(w * 0.78, h * 0.76)
          ..quadraticBezierTo(w * 0.74, h * 0.82, w * 0.70, h * 0.76)
          ..close();
        canvas.drawPath(cup, paintGold);
        canvas.drawRect(Rect.fromCenter(center: Offset(w * 0.74, h * 0.86), width: w * 0.14, height: h * 0.07), paintDark);
        break;

      case 'shield':
        final sh = Path()
          ..moveTo(w * 0.64, h * 0.64)
          ..lineTo(w * 0.84, h * 0.64)
          ..lineTo(w * 0.84, h * 0.78)
          ..quadraticBezierTo(w * 0.74, h * 0.90, w * 0.64, h * 0.78)
          ..close();
        canvas.drawPath(sh, paintBlue);
        canvas.drawPath(sh, Paint()..color = paintGold.color..style = PaintingStyle.stroke..strokeWidth = 2);
        canvas.drawCircle(Offset(w * 0.74, h * 0.74), w * 0.04, paintGold);
        break;

      case 'diamond':
        final dia = Path()
          ..moveTo(w * 0.74, h * 0.62)
          ..lineTo(w * 0.86, h * 0.72)
          ..lineTo(w * 0.74, h * 0.88)
          ..lineTo(w * 0.62, h * 0.72)
          ..close();
        canvas.drawPath(dia, Paint()..color = const Color(0xFF38BDF8));
        canvas.drawLine(Offset(w * 0.62, h * 0.72), Offset(w * 0.86, h * 0.72), Paint()..color = Colors.white..strokeWidth = 1.5);
        break;

      case 'star':
        canvas.drawCircle(Offset(w * 0.74, h * 0.74), w * 0.16, paintGold);
        canvas.drawCircle(Offset(w * 0.74, h * 0.74), w * 0.07, paintWhite);
        break;

      case 'pen':
      default:
        final penPath = Path()
          ..moveTo(w * 0.56, h * 0.76)
          ..lineTo(w * 0.92, h * 0.14)
          ..lineTo(w * 0.98, h * 0.18)
          ..lineTo(w * 0.62, h * 0.80)
          ..close();
        canvas.drawPath(penPath, Paint()..color = const Color(0xFF38BDF8));
        canvas.drawLine(Offset(w * 0.58, h * 0.76), Offset(w * 0.94, h * 0.16), Paint()..color = paintGold.color..strokeWidth = w * 0.02);
        final penTip = Path()..moveTo(w * 0.92, h * 0.14)..lineTo(w * 0.98, h * 0.06)..lineTo(w * 0.98, h * 0.18)..close();
        canvas.drawPath(penTip, paintBlue);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _UniversalMascotPainter oldDelegate) {
    return oldDelegate.mascotId != mascotId ||
        oldDelegate.accessory != accessory ||
        oldDelegate.withPen != withPen ||
        oldDelegate.isHeadOnly != isHeadOnly;
  }
}
