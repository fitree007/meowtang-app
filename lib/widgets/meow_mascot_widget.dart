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

class OutfitInfo {
  final String id;
  final String name;
  final String subtitle;
  final Color primaryColor;
  final Color accentColor;
  final IconData icon;

  const OutfitInfo({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.primaryColor,
    required this.accentColor,
    this.icon = Icons.checkroom_rounded,
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
      id: 'cat_siamese',
      name: 'เหมี่ยววิเชียรมาศสยาม (Siamese Cat)',
      subtitle: 'แมววิเชียรมาศแท้ แต้มช็อกโกแลตมงคล ตาสีฟ้าครามสดใส เรียกทรัพย์',
      primaryColor: Color(0xFFD97706),
      secondaryColor: Color(0xFF78350F),
      icon: Icons.pets,
    ),
    MascotInfo(
      id: 'cat_grey',
      name: 'เหมี่ยวเทาสลิดบริติช (British Grey Tabby)',
      subtitle: 'แมวสีเทาควันบุหรี่ ขนเงางาม สุขุม นิ่งสงบ บริหารเงินเนี๊ยบ',
      primaryColor: Color(0xFF64748B),
      secondaryColor: Color(0xFF475569),
      icon: Icons.pets,
    ),
    MascotInfo(
      id: 'cat_tuxedo',
      name: 'เหมี่ยวทักซิโด้มาดคุณชาย (Gentleman Tuxedo)',
      subtitle: 'แมวทักซิโด้สูทดำอกขาว มาดคุณชายผู้มั่งคั่ง สุภาพ รอบคอบ',
      primaryColor: Color(0xFF0F172A),
      secondaryColor: Color(0xFF334155),
      icon: Icons.pets,
    ),
    MascotInfo(
      id: 'cat_pink',
      name: 'เหมี่ยวขาวซากุระหูชมพู (Sakura White Kitty)',
      subtitle: 'แมวขาวปุกปุย หูชมพูพาสเทล น่ารักสดใส อ่อนโยน แจ่มใส',
      primaryColor: Color(0xFFF472B6),
      secondaryColor: Color(0xFFEC4899),
      icon: Icons.favorite,
    ),
    MascotInfo(
      id: 'cat_egypt',
      name: 'เหมี่ยวฟาโรห์อียิปต์โบราณ (Ancient Bastet)',
      subtitle: 'เทพแมวบาสเตตแห่งไอยคุปต์ ปลอกคอทองคำและมงกุฎฟาโรห์ พิทักษ์ทรัพย์สมบัติ',
      primaryColor: Color(0xFFD97706),
      secondaryColor: Color(0xFF0F172A),
      icon: Icons.auto_awesome,
    ),
    MascotInfo(
      id: 'cat_sphynx',
      name: 'เหมี่ยวสฟิงซ์ปราชญ์ทะเลทราย (Desert Sphynx)',
      subtitle: 'แมวสฟิงซ์ไร้ขนหูใหญ่ สง่างาม ปราดเปรื่องเรื่องวางแผนการเงิน',
      primaryColor: Color(0xFFF59E0B),
      secondaryColor: Color(0xFFD97706),
      icon: Icons.psychology,
    ),
    MascotInfo(
      id: 'cat_golden',
      name: 'เหมี่ยวทองคำจักรพรรดิ (Imperial Golden Cat)',
      subtitle: 'แมวสีทองคำอร่าม นำพาความมั่งคั่งและริซกีอันไพศาล',
      primaryColor: Color(0xFFF59E0B),
      secondaryColor: Color(0xFFB45309),
      icon: Icons.auto_awesome,
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

  static const List<OutfitInfo> outfits = [
    OutfitInfo(
      id: 'none',
      name: 'ไม่ใส่ชุด (Original)',
      subtitle: 'ขนปุยแบบธรรมชาติเดิมๆ',
      primaryColor: Color(0xFF94A3B8),
      accentColor: Color(0xFFCBD5E1),
      icon: Icons.block_rounded,
    ),
    OutfitInfo(
      id: 'outfit_hoodie',
      name: 'ฮู้ดดี้สตรีทเท่ (Street Hoodie)',
      subtitle: 'เสื้อฮู้ดดี้สีแดงสดใส มีกระเป๋าหน้าและเชือกฮู้ด',
      primaryColor: Color(0xFFEF4444),
      accentColor: Colors.white,
      icon: Icons.dry_cleaning_rounded,
    ),
    OutfitInfo(
      id: 'outfit_suit',
      name: 'สูททักซิโด้นักบริหาร (Executive Suit)',
      subtitle: 'สูททักซิโด้สีดำสุดหรู เชิ้ตขาวและเนกไทสีทอง',
      primaryColor: Color(0xFF0F172A),
      accentColor: Color(0xFFF59E0B),
      icon: Icons.business_center_rounded,
    ),
    OutfitInfo(
      id: 'outfit_tshirt',
      name: 'เสื้อยืดแคชชวลสบายๆ (Meow Casual)',
      subtitle: 'เสื้อยืดคอกลมสีมินต์สดใส สกรีนรูปปลาทู',
      primaryColor: Color(0xFF0D9488),
      accentColor: Colors.white,
      icon: Icons.checkroom_rounded,
    ),
    OutfitInfo(
      id: 'outfit_sweater',
      name: 'เสื้อไหมพรมกันหนาว (Cozy Sweater)',
      subtitle: 'เสื้อถักไหมพรมลวดลายอบอุ่น นุ่มสบาย',
      primaryColor: Color(0xFFC2410C),
      accentColor: Color(0xFFFEF3C7),
      icon: Icons.waves_rounded,
    ),
    OutfitInfo(
      id: 'outfit_sport',
      name: 'ชุดวอร์มนักกีฬา (Sport Jersey)',
      subtitle: 'ชุดวอร์มสีน้ำเงินแถบขาว สไตล์นักกีฬาวิ่งเร็ว',
      primaryColor: Color(0xFF2563EB),
      accentColor: Colors.white,
      icon: Icons.sports_score_rounded,
    ),
    OutfitInfo(
      id: 'outfit_overalls',
      name: 'ชุดเอี๊ยมยีนส์น่ารัก (Denim Overalls)',
      subtitle: 'ชุดเอี๊ยมผ้ายีนส์สีฟ้า มีกระดุมทองและกระเป๋าหน้า',
      primaryColor: Color(0xFF0284C7),
      accentColor: Color(0xFFFBBF24),
      icon: Icons.agriculture_rounded,
    ),
  ];

  static const List<AccessoryInfo> accessories = [
    AccessoryInfo(id: 'pen', name: 'ปากกาขนนกทองคำ', icon: Icons.edit_rounded),
    AccessoryInfo(id: 'gold_shades', name: 'แว่นตาดำสุดคูล', icon: Icons.remove_red_eye_outlined),
    AccessoryInfo(id: 'crown', name: 'มงกุฎทองคำราชันย์', icon: Icons.workspace_premium_rounded),
    AccessoryInfo(id: 'bowtie', name: 'โบว์ไทสีแดงสุดหล่อ', icon: Icons.loyalty_rounded),
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
    AccessoryInfo(id: 'wings', name: 'ปีกบินสู่อิสรภาพ', icon: Icons.auto_awesome_rounded),
    AccessoryInfo(id: 'trophy', name: 'ถ้วยรางวัลยอดนักออม', icon: Icons.emoji_events_rounded),
    AccessoryInfo(id: 'songkok', name: 'หมวกกะปิเยาะห์มุสลิม', icon: Icons.mosque_rounded),
    AccessoryInfo(id: 'scarf', name: 'ผ้าพันคอสีแดงอบอุ่น', icon: Icons.texture_rounded),
    AccessoryInfo(id: 'shield', name: 'โล่พิทักษ์เงินเก็บ', icon: Icons.shield_rounded),
    AccessoryInfo(id: 'diamond', name: 'เพชรน้ำงามมั่งคั่ง', icon: Icons.diamond_rounded),
    AccessoryInfo(id: 'flower', name: 'ดอกไม้ประดับหู', icon: Icons.local_florist_rounded),
    AccessoryInfo(id: 'halo', name: 'วงแหวนเทวดานำโชค', icon: Icons.circle_outlined),
    AccessoryInfo(id: 'wizard_hat', name: 'หมวกพ่อมดการเงิน', icon: Icons.auto_awesome_rounded),
    AccessoryInfo(id: 'headband', name: 'ผ้าคาดหัวนักสู้', icon: Icons.sports_martial_arts_rounded),
    AccessoryInfo(id: 'wings_grand', name: 'ปีกเทวทูตคู่สีทองสยาย', icon: Icons.auto_awesome_rounded),
    AccessoryInfo(id: 'aurora_halo', name: 'วงแหวนออโรร่าเรืองแสง', icon: Icons.wb_sunny_rounded),
    AccessoryInfo(id: 'royal_cape', name: 'ผ้าคลุมราชันย์ทองคำ', icon: Icons.shield_rounded),
    AccessoryInfo(id: 'phoenix_crown', name: 'มงกุฎฟีนิกซ์ประกายเพชร', icon: Icons.workspace_premium_rounded),
    AccessoryInfo(id: 'magic_wand', name: 'คทาคริสตัลดวงดาว', icon: Icons.flare_rounded),
  ];
}

class MeowMascotWidget extends StatefulWidget {
  final double size;
  final bool withPen;
  final bool isHeadOnly;
  final String? mascotId;
  final String? accessory;
  final String? outfit;
  final String? customPhotoPath;
  final bool isCustomPhoto;
  final bool animate;
  final MascotMood mood;
  final bool showMoodBadge;
  final VoidCallback? onTap;

  const MeowMascotWidget({
    super.key,
    this.size = 80,
    this.withPen = false,
    this.isHeadOnly = false,
    this.mascotId,
    this.accessory,
    this.outfit,
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
    final activeOutfit = widget.outfit ?? 'none';

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
          outfit: activeOutfit,
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
  final String outfit;
  final bool withPen;
  final bool isHeadOnly;

  _UniversalMascotPainter({
    required this.mascotId,
    required this.accessory,
    this.outfit = 'none',
    required this.withPen,
    required this.isHeadOnly,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw Cape or Wings under mascot if selected
    if (accessory == 'royal_cape') {
      _paintRoyalCapeUnder(canvas, w, h);
    }
    if (accessory == 'wings' || accessory == 'wings_grand') {
      _paintWingsUnder(canvas, w, h, isGrand: accessory == 'wings_grand');
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
      case 'cat_siamese':
        _paintSiameseCat(canvas, w, h);
        break;
      case 'cat_grey':
        _paintGreyTabbyCat(canvas, w, h);
        break;
      case 'cat_tuxedo':
        _paintTuxedoCat(canvas, w, h);
        break;
      case 'cat_pink':
        _paintSakuraCat(canvas, w, h);
        break;
      case 'cat_egypt':
        _paintAncientEgyptCat(canvas, w, h);
        break;
      case 'cat_sphynx':
        _paintSphynxCat(canvas, w, h);
        break;
      case 'cat_golden':
        _paintGoldenCat(canvas, w, h);
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

    // 2.5 Draw Wearable Outfit on Body (if any)
    if (!isHeadOnly && outfit != 'none') {
      _paintOutfit(canvas, w, h, outfit);
    }

    // 3. Draw Accessory Overlays (Headwear, Neckwear, Handheld, Aurora Aura)
    if (accessory.isNotEmpty && accessory != 'none') {
      _paintAccessoryOverlay(canvas, w, h);
    }

    // 4. Draw Pen only if explicitly requested via withPen and accessory wasn't already pen
    if (withPen && accessory != 'pen') {
      _paintPen(canvas, w, h);
    }
  }

  void _paintRoyalCapeUnder(Canvas canvas, double w, double h) {
    final capePaint = Paint()..color = const Color(0xFFB91C1C);
    final capeGoldTrim = Paint()..color = const Color(0xFFFBBF24)..style = PaintingStyle.stroke..strokeWidth = w * 0.025;
    final capePath = Path()
      ..moveTo(w * 0.26, h * 0.62)
      ..quadraticBezierTo(w * 0.06, h * 0.85, w * 0.12, h * 1.05)
      ..quadraticBezierTo(w * 0.50, h * 1.10, w * 0.88, h * 1.05)
      ..quadraticBezierTo(w * 0.94, h * 0.85, w * 0.74, h * 0.62)
      ..close();
    canvas.drawPath(capePath, capePaint);
    canvas.drawPath(capePath, capeGoldTrim);
  }

  void _paintWingsUnder(Canvas canvas, double w, double h, {bool isGrand = false}) {
    final goldBright = Paint()..color = const Color(0xFFFDE047);
    final goldBase = Paint()..color = const Color(0xFFF59E0B);
    final goldDeep = Paint()..color = const Color(0xFFD97706);
    final whiteFeather = Paint()..color = Colors.white.withValues(alpha: 0.9);

    final double spread = isGrand ? 1.45 : 1.15;
    final double reachY = isGrand ? 0.05 : 0.22;

    // LEFT WING (Grand Multi-layer)
    final leftOuter = Path()
      ..moveTo(w * 0.32, h * 0.56)
      ..quadraticBezierTo(w * 0.02, h * reachY, -w * (spread - 1.0), h * 0.28)
      ..quadraticBezierTo(-w * (spread - 1.15), h * 0.50, -w * (spread - 1.05), h * 0.62)
      ..quadraticBezierTo(w * 0.05, h * 0.78, w * 0.32, h * 0.72)
      ..close();
    canvas.drawPath(leftOuter, goldDeep);
    canvas.drawPath(leftOuter, goldBase);

    // Left Inner Feathers Layer
    final leftInner = Path()
      ..moveTo(w * 0.30, h * 0.54)
      ..quadraticBezierTo(w * 0.06, h * (reachY + 0.10), -w * (spread - 1.12), h * 0.38)
      ..quadraticBezierTo(w * 0.05, h * 0.65, w * 0.30, h * 0.68)
      ..close();
    canvas.drawPath(leftInner, goldBright);
    if (isGrand) canvas.drawPath(leftInner, whiteFeather);

    // RIGHT WING (Grand Multi-layer)
    final rightOuter = Path()
      ..moveTo(w * 0.68, h * 0.56)
      ..quadraticBezierTo(w * 0.98, h * reachY, w * spread, h * 0.28)
      ..quadraticBezierTo(w * (spread - 0.15), h * 0.50, w * (spread - 0.05), h * 0.62)
      ..quadraticBezierTo(w * 0.95, h * 0.78, w * 0.68, h * 0.72)
      ..close();
    canvas.drawPath(rightOuter, goldDeep);
    canvas.drawPath(rightOuter, goldBase);

    // Right Inner Feathers Layer
    final rightInner = Path()
      ..moveTo(w * 0.70, h * 0.54)
      ..quadraticBezierTo(w * 0.94, h * (reachY + 0.10), w * (spread - 0.12), h * 0.38)
      ..quadraticBezierTo(w * 0.95, h * 0.65, w * 0.70, h * 0.68)
      ..close();
    canvas.drawPath(rightInner, goldBright);
    if (isGrand) canvas.drawPath(rightInner, whiteFeather);
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

  /// 7. Siamese Cat (เหมี่ยววิเชียรมาศสยาม)
  void _paintSiameseCat(Canvas canvas, double w, double h) {
    final creamCoat = Paint()..color = const Color(0xFFFEF3C7);
    final darkSeal = Paint()..color = const Color(0xFF451A03);
    final sapphireEyes = Paint()..color = const Color(0xFF0284C7);
    final pinkNose = Paint()..color = const Color(0xFFF472B6);
    final redCollar = Paint()..color = const Color(0xFFEF4444);
    final goldBell = Paint()..color = const Color(0xFFFBBF24);
    final whiteGlint = Paint()..color = Colors.white;

    if (!isHeadOnly) {
      final body = Path()
        ..moveTo(w * 0.32, h * 0.65)
        ..quadraticBezierTo(w * 0.20, h * 0.85, w * 0.25, h * 0.95)
        ..quadraticBezierTo(w * 0.50, h * 0.99, w * 0.75, h * 0.95)
        ..quadraticBezierTo(w * 0.80, h * 0.85, w * 0.68, h * 0.65)
        ..close();
      canvas.drawPath(body, creamCoat);
      // Dark paws at bottom
      canvas.drawCircle(Offset(w * 0.36, h * 0.93), w * 0.08, darkSeal);
      canvas.drawCircle(Offset(w * 0.64, h * 0.93), w * 0.08, darkSeal);
      // Red collar with gold bell
      canvas.drawPath(Path()..moveTo(w * 0.30, h * 0.66)..quadraticBezierTo(w * 0.50, h * 0.74, w * 0.70, h * 0.66)..lineTo(w * 0.70, h * 0.70)..quadraticBezierTo(w * 0.50, h * 0.78, w * 0.30, h * 0.70)..close(), redCollar);
      canvas.drawCircle(Offset(w * 0.50, h * 0.75), w * 0.05, goldBell);
    }

    // Seal point Ears
    final leftEar = Path()..moveTo(w * 0.16, h * 0.44)..quadraticBezierTo(w * 0.16, h * 0.16, w * 0.30, h * 0.12)..quadraticBezierTo(w * 0.44, h * 0.26, w * 0.42, h * 0.40)..close();
    canvas.drawPath(leftEar, darkSeal);
    final rightEar = Path()..moveTo(w * 0.84, h * 0.44)..quadraticBezierTo(w * 0.84, h * 0.16, w * 0.70, h * 0.12)..quadraticBezierTo(w * 0.56, h * 0.26, w * 0.58, h * 0.40)..close();
    canvas.drawPath(rightEar, darkSeal);

    // Cream Head
    canvas.drawCircle(Offset(w * 0.5, h * 0.52), w * 0.36, creamCoat);

    // Seal Brown Mask in Center of Face
    final mask = Path()
      ..moveTo(w * 0.30, h * 0.44)
      ..quadraticBezierTo(w * 0.50, h * 0.36, w * 0.70, h * 0.44)
      ..quadraticBezierTo(w * 0.74, h * 0.64, w * 0.50, h * 0.68)
      ..quadraticBezierTo(w * 0.26, h * 0.64, w * 0.30, h * 0.44)
      ..close();
    canvas.drawPath(mask, darkSeal);

    // Beautiful Sapphire Blue Eyes
    final eyeR = w * 0.055;
    canvas.drawCircle(Offset(w * 0.35, h * 0.48), eyeR, sapphireEyes);
    canvas.drawCircle(Offset(w * 0.65, h * 0.48), eyeR, sapphireEyes);
    canvas.drawCircle(Offset(w * 0.335, h * 0.465), eyeR * 0.45, whiteGlint);
    canvas.drawCircle(Offset(w * 0.635, h * 0.465), eyeR * 0.45, whiteGlint);

    // Nose & Whiskers
    final nose = Path()..moveTo(w * 0.47, h * 0.54)..lineTo(w * 0.53, h * 0.54)..lineTo(w * 0.50, h * 0.57)..close();
    canvas.drawPath(nose, pinkNose);
    final whiskerPaint = Paint()..color = Colors.white70..style = PaintingStyle.stroke..strokeWidth = w * 0.015..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.16, h * 0.54), Offset(w * 0.28, h * 0.56), whiskerPaint);
    canvas.drawLine(Offset(w * 0.84, h * 0.54), Offset(w * 0.72, h * 0.56), whiskerPaint);
  }

  /// 8. British Grey Tabby Cat (เหมี่ยวเทาสลิดบริติช)
  void _paintGreyTabbyCat(Canvas canvas, double w, double h) {
    final greyCoat = Paint()..color = const Color(0xFF64748B);
    final darkGrey = Paint()..color = const Color(0xFF334155);
    final emeraldEyes = Paint()..color = const Color(0xFF10B981);
    final whitePaint = Paint()..color = Colors.white;
    final pinkPaint = Paint()..color = const Color(0xFFF472B6);
    final yellowCollar = Paint()..color = const Color(0xFFEAB308);
    final bell = Paint()..color = const Color(0xFFFBBF24);

    if (!isHeadOnly) {
      final body = Path()..moveTo(w * 0.32, h * 0.65)..quadraticBezierTo(w * 0.20, h * 0.85, w * 0.25, h * 0.95)..quadraticBezierTo(w * 0.50, h * 0.99, w * 0.75, h * 0.95)..quadraticBezierTo(w * 0.80, h * 0.85, w * 0.68, h * 0.65)..close();
      canvas.drawPath(body, greyCoat);
      // White chest bib
      final bib = Path()..moveTo(w * 0.38, h * 0.68)..quadraticBezierTo(w * 0.32, h * 0.85, w * 0.36, h * 0.95)..lineTo(w * 0.64, h * 0.95)..quadraticBezierTo(w * 0.68, h * 0.85, w * 0.62, h * 0.68)..close();
      canvas.drawPath(bib, whitePaint);
      canvas.drawPath(Path()..moveTo(w * 0.30, h * 0.66)..quadraticBezierTo(w * 0.50, h * 0.74, w * 0.70, h * 0.66)..lineTo(w * 0.70, h * 0.70)..quadraticBezierTo(w * 0.50, h * 0.78, w * 0.30, h * 0.70)..close(), yellowCollar);
      canvas.drawCircle(Offset(w * 0.50, h * 0.75), w * 0.05, bell);
    }

    // Ears
    canvas.drawPath(Path()..moveTo(w * 0.16, h * 0.44)..quadraticBezierTo(w * 0.16, h * 0.16, w * 0.30, h * 0.12)..quadraticBezierTo(w * 0.44, h * 0.26, w * 0.42, h * 0.40)..close(), greyCoat);
    canvas.drawPath(Path()..moveTo(w * 0.22, h * 0.38)..lineTo(w * 0.30, h * 0.18)..lineTo(w * 0.38, h * 0.35)..close(), pinkPaint);
    canvas.drawPath(Path()..moveTo(w * 0.84, h * 0.44)..quadraticBezierTo(w * 0.84, h * 0.16, w * 0.70, h * 0.12)..quadraticBezierTo(w * 0.56, h * 0.26, w * 0.58, h * 0.40)..close(), greyCoat);
    canvas.drawPath(Path()..moveTo(w * 0.78, h * 0.38)..lineTo(w * 0.70, h * 0.18)..lineTo(w * 0.62, h * 0.35)..close(), pinkPaint);

    // Head
    canvas.drawCircle(Offset(w * 0.5, h * 0.52), w * 0.36, greyCoat);

    // Tabby Stripes
    final stripe = Paint()..color = darkGrey.color..style = PaintingStyle.stroke..strokeWidth = w * 0.024..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.50, h * 0.22), Offset(w * 0.50, h * 0.34), stripe);
    canvas.drawLine(Offset(w * 0.42, h * 0.24), Offset(w * 0.44, h * 0.33), stripe);
    canvas.drawLine(Offset(w * 0.58, h * 0.24), Offset(w * 0.56, h * 0.33), stripe);

    // White Muzzle
    final muzzle = Path()..moveTo(w * 0.30, h * 0.56)..quadraticBezierTo(w * 0.50, h * 0.44, w * 0.70, h * 0.56)..quadraticBezierTo(w * 0.50, h * 0.74, w * 0.30, h * 0.56)..close();
    canvas.drawPath(muzzle, whitePaint);
    canvas.drawCircle(Offset(w * 0.28, h * 0.58), w * 0.055, pinkPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.58), w * 0.055, pinkPaint);

    // Eyes
    final eyeR = w * 0.055;
    canvas.drawCircle(Offset(w * 0.35, h * 0.48), eyeR, emeraldEyes);
    canvas.drawCircle(Offset(w * 0.65, h * 0.48), eyeR, emeraldEyes);
    canvas.drawCircle(Offset(w * 0.335, h * 0.465), eyeR * 0.45, whitePaint);
    canvas.drawCircle(Offset(w * 0.635, h * 0.465), eyeR * 0.45, whitePaint);

    final nose = Path()..moveTo(w * 0.47, h * 0.54)..lineTo(w * 0.53, h * 0.54)..lineTo(w * 0.50, h * 0.57)..close();
    canvas.drawPath(nose, pinkPaint);
  }

  /// 9. Gentleman Tuxedo Cat (เหมี่ยวทักซิโด้มาดคุณชาย)
  void _paintTuxedoCat(Canvas canvas, double w, double h) {
    final blackCoat = Paint()..color = const Color(0xFF0F172A);
    final whiteShirt = Paint()..color = Colors.white;
    final goldEyes = Paint()..color = const Color(0xFFFBBF24);
    final pinkNose = Paint()..color = const Color(0xFFF472B6);
    final greenBow = Paint()..color = const Color(0xFF059669);

    if (!isHeadOnly) {
      final body = Path()..moveTo(w * 0.32, h * 0.65)..quadraticBezierTo(w * 0.20, h * 0.85, w * 0.25, h * 0.95)..quadraticBezierTo(w * 0.50, h * 0.99, w * 0.75, h * 0.95)..quadraticBezierTo(w * 0.80, h * 0.85, w * 0.68, h * 0.65)..close();
      canvas.drawPath(body, blackCoat);
      // Pure white tuxedo V-chest
      final vChest = Path()..moveTo(w * 0.38, h * 0.66)..lineTo(w * 0.50, h * 0.96)..lineTo(w * 0.62, h * 0.66)..close();
      canvas.drawPath(vChest, whiteShirt);
      // Mini bow tie
      canvas.drawCircle(Offset(w * 0.50, h * 0.72), w * 0.04, greenBow);
    }

    // Ears
    canvas.drawPath(Path()..moveTo(w * 0.16, h * 0.44)..quadraticBezierTo(w * 0.16, h * 0.16, w * 0.30, h * 0.12)..quadraticBezierTo(w * 0.44, h * 0.26, w * 0.42, h * 0.40)..close(), blackCoat);
    canvas.drawPath(Path()..moveTo(w * 0.22, h * 0.38)..lineTo(w * 0.30, h * 0.18)..lineTo(w * 0.38, h * 0.35)..close(), pinkNose);
    canvas.drawPath(Path()..moveTo(w * 0.84, h * 0.44)..quadraticBezierTo(w * 0.84, h * 0.16, w * 0.70, h * 0.12)..quadraticBezierTo(w * 0.56, h * 0.26, w * 0.58, h * 0.40)..close(), blackCoat);
    canvas.drawPath(Path()..moveTo(w * 0.78, h * 0.38)..lineTo(w * 0.70, h * 0.18)..lineTo(w * 0.62, h * 0.35)..close(), pinkNose);

    // Head
    canvas.drawCircle(Offset(w * 0.5, h * 0.52), w * 0.36, blackCoat);

    // White Chin & Mustache patch
    final whiteChin = Path()..moveTo(w * 0.35, h * 0.56)..quadraticBezierTo(w * 0.50, h * 0.48, w * 0.65, h * 0.56)..quadraticBezierTo(w * 0.50, h * 0.74, w * 0.35, h * 0.56)..close();
    canvas.drawPath(whiteChin, whiteShirt);

    // Eyes
    final eyeR = w * 0.055;
    canvas.drawCircle(Offset(w * 0.35, h * 0.48), eyeR, goldEyes);
    canvas.drawCircle(Offset(w * 0.65, h * 0.48), eyeR, goldEyes);
    canvas.drawCircle(Offset(w * 0.335, h * 0.465), eyeR * 0.45, whiteShirt);
    canvas.drawCircle(Offset(w * 0.635, h * 0.465), eyeR * 0.45, whiteShirt);

    final nose = Path()..moveTo(w * 0.47, h * 0.54)..lineTo(w * 0.53, h * 0.54)..lineTo(w * 0.50, h * 0.57)..close();
    canvas.drawPath(nose, pinkNose);
  }

  /// 10. Sakura White Kitty (เหมี่ยวขาวซากุระหูชมพู)
  void _paintSakuraCat(Canvas canvas, double w, double h) {
    final whiteCoat = Paint()..color = Colors.white;
    final pinkSakura = Paint()..color = const Color(0xFFF472B6);
    final skyBlueEyes = Paint()..color = const Color(0xFF38BDF8);

    if (!isHeadOnly) {
      final body = Path()..moveTo(w * 0.32, h * 0.65)..quadraticBezierTo(w * 0.20, h * 0.85, w * 0.25, h * 0.95)..quadraticBezierTo(w * 0.50, h * 0.99, w * 0.75, h * 0.95)..quadraticBezierTo(w * 0.80, h * 0.85, w * 0.68, h * 0.65)..close();
      canvas.drawPath(body, whiteCoat);
      // Pink ribbon collar
      canvas.drawPath(Path()..moveTo(w * 0.30, h * 0.66)..quadraticBezierTo(w * 0.50, h * 0.74, w * 0.70, h * 0.66)..lineTo(w * 0.70, h * 0.70)..quadraticBezierTo(w * 0.50, h * 0.78, w * 0.30, h * 0.70)..close(), pinkSakura);
      canvas.drawCircle(Offset(w * 0.50, h * 0.75), w * 0.045, Paint()..color = const Color(0xFFFBBF24));
    }

    // Ears
    canvas.drawPath(Path()..moveTo(w * 0.16, h * 0.44)..quadraticBezierTo(w * 0.16, h * 0.16, w * 0.30, h * 0.12)..quadraticBezierTo(w * 0.44, h * 0.26, w * 0.42, h * 0.40)..close(), whiteCoat);
    canvas.drawPath(Path()..moveTo(w * 0.22, h * 0.38)..lineTo(w * 0.30, h * 0.18)..lineTo(w * 0.38, h * 0.35)..close(), pinkSakura);
    canvas.drawPath(Path()..moveTo(w * 0.84, h * 0.44)..quadraticBezierTo(w * 0.84, h * 0.16, w * 0.70, h * 0.12)..quadraticBezierTo(w * 0.56, h * 0.26, w * 0.58, h * 0.40)..close(), whiteCoat);
    canvas.drawPath(Path()..moveTo(w * 0.78, h * 0.38)..lineTo(w * 0.70, h * 0.18)..lineTo(w * 0.62, h * 0.35)..close(), pinkSakura);

    // Head
    canvas.drawCircle(Offset(w * 0.5, h * 0.52), w * 0.36, whiteCoat);
    final cheekPaint = Paint()..color = pinkSakura.color.withValues(alpha: 0.6);
    canvas.drawCircle(Offset(w * 0.28, h * 0.58), w * 0.06, cheekPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.58), w * 0.06, cheekPaint);

    // Eyes
    final eyeR = w * 0.055;
    canvas.drawCircle(Offset(w * 0.35, h * 0.48), eyeR, skyBlueEyes);
    canvas.drawCircle(Offset(w * 0.65, h * 0.48), eyeR, skyBlueEyes);
    canvas.drawCircle(Offset(w * 0.335, h * 0.465), eyeR * 0.45, whiteCoat);
    canvas.drawCircle(Offset(w * 0.635, h * 0.465), eyeR * 0.45, whiteCoat);

    final nose = Path()..moveTo(w * 0.47, h * 0.54)..lineTo(w * 0.53, h * 0.54)..lineTo(w * 0.50, h * 0.57)..close();
    canvas.drawPath(nose, pinkSakura);
  }

  /// 11. Imperial Golden Cat (เหมี่ยวทองคำจักรพรรดิ)
  void _paintGoldenCat(Canvas canvas, double w, double h) {
    final goldCoat = Paint()..color = const Color(0xFFFBBF24);
    final darkAmber = Paint()..color = const Color(0xFFB45309);
    final rubyRed = Paint()..color = const Color(0xFFDC2626);
    final whitePaint = Paint()..color = Colors.white;

    if (!isHeadOnly) {
      final body = Path()..moveTo(w * 0.32, h * 0.65)..quadraticBezierTo(w * 0.20, h * 0.85, w * 0.25, h * 0.95)..quadraticBezierTo(w * 0.50, h * 0.99, w * 0.75, h * 0.95)..quadraticBezierTo(w * 0.80, h * 0.85, w * 0.68, h * 0.65)..close();
      canvas.drawPath(body, goldCoat);
      // Royal golden belly
      final belly = Path()..moveTo(w * 0.38, h * 0.68)..quadraticBezierTo(w * 0.32, h * 0.85, w * 0.36, h * 0.95)..lineTo(w * 0.64, h * 0.95)..quadraticBezierTo(w * 0.68, h * 0.85, w * 0.62, h * 0.68)..close();
      canvas.drawPath(belly, Paint()..color = const Color(0xFFFEF08A));
      // Red royal collar with gold medal
      canvas.drawPath(Path()..moveTo(w * 0.30, h * 0.66)..quadraticBezierTo(w * 0.50, h * 0.74, w * 0.70, h * 0.66)..lineTo(w * 0.70, h * 0.70)..quadraticBezierTo(w * 0.50, h * 0.78, w * 0.30, h * 0.70)..close(), rubyRed);
      canvas.drawCircle(Offset(w * 0.50, h * 0.75), w * 0.055, Paint()..color = const Color(0xFFF59E0B));
    }

    // Ears
    canvas.drawPath(Path()..moveTo(w * 0.16, h * 0.44)..quadraticBezierTo(w * 0.16, h * 0.16, w * 0.30, h * 0.12)..quadraticBezierTo(w * 0.44, h * 0.26, w * 0.42, h * 0.40)..close(), goldCoat);
    canvas.drawPath(Path()..moveTo(w * 0.22, h * 0.38)..lineTo(w * 0.30, h * 0.18)..lineTo(w * 0.38, h * 0.35)..close(), rubyRed);
    canvas.drawPath(Path()..moveTo(w * 0.84, h * 0.44)..quadraticBezierTo(w * 0.84, h * 0.16, w * 0.70, h * 0.12)..quadraticBezierTo(w * 0.56, h * 0.26, w * 0.58, h * 0.40)..close(), goldCoat);
    canvas.drawPath(Path()..moveTo(w * 0.78, h * 0.38)..lineTo(w * 0.70, h * 0.18)..lineTo(w * 0.62, h * 0.35)..close(), rubyRed);

    // Head
    canvas.drawCircle(Offset(w * 0.5, h * 0.52), w * 0.36, goldCoat);

    // Golden Stripes
    final stripe = Paint()..color = darkAmber.color..style = PaintingStyle.stroke..strokeWidth = w * 0.025..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.50, h * 0.22), Offset(w * 0.50, h * 0.34), stripe);
    canvas.drawLine(Offset(w * 0.42, h * 0.24), Offset(w * 0.44, h * 0.33), stripe);
    canvas.drawLine(Offset(w * 0.58, h * 0.24), Offset(w * 0.56, h * 0.33), stripe);

    // Eyes
    final eyeR = w * 0.055;
    final dark = Paint()..color = const Color(0xFF1E293B);
    canvas.drawCircle(Offset(w * 0.35, h * 0.48), eyeR, dark);
    canvas.drawCircle(Offset(w * 0.65, h * 0.48), eyeR, dark);
    canvas.drawCircle(Offset(w * 0.335, h * 0.465), eyeR * 0.45, whitePaint);
    canvas.drawCircle(Offset(w * 0.635, h * 0.465), eyeR * 0.45, whitePaint);

    final nose = Path()..moveTo(w * 0.47, h * 0.54)..lineTo(w * 0.53, h * 0.54)..lineTo(w * 0.50, h * 0.57)..close();
    canvas.drawPath(nose, darkAmber);
  }

  void _paintAncientEgyptCat(Canvas canvas, double w, double h) {
    final coatPaint = Paint()..color = const Color(0xFF0F172A);
    final goldPaint = Paint()..color = const Color(0xFFF59E0B);
    final darkGold = Paint()..color = const Color(0xFFD97706);
    final lapisBlue = Paint()..color = const Color(0xFF0284C7);
    final turquoise = Paint()..color = const Color(0xFF06B6D4);
    final amberEye = Paint()..color = const Color(0xFFFBBF24);
    final eyeBlack = Paint()..color = const Color(0xFF020617);
    final whitePaint = Paint()..color = Colors.white;

    if (!isHeadOnly) {
      final body = Path()
        ..moveTo(w * 0.32, h * 0.65)
        ..quadraticBezierTo(w * 0.20, h * 0.85, w * 0.25, h * 0.95)
        ..quadraticBezierTo(w * 0.50, h * 0.99, w * 0.75, h * 0.95)
        ..quadraticBezierTo(w * 0.80, h * 0.85, w * 0.68, h * 0.65)
        ..close();
      canvas.drawPath(body, coatPaint);

      final collarBand1 = Path()
        ..moveTo(w * 0.28, h * 0.66)
        ..quadraticBezierTo(w * 0.50, h * 0.76, w * 0.72, h * 0.66)
        ..lineTo(w * 0.73, h * 0.72)
        ..quadraticBezierTo(w * 0.50, h * 0.82, w * 0.27, h * 0.72)
        ..close();
      canvas.drawPath(collarBand1, goldPaint);

      final collarBand2 = Path()
        ..moveTo(w * 0.30, h * 0.72)
        ..quadraticBezierTo(w * 0.50, h * 0.82, w * 0.70, h * 0.72)
        ..lineTo(w * 0.68, h * 0.77)
        ..quadraticBezierTo(w * 0.50, h * 0.86, w * 0.32, h * 0.77)
        ..close();
      canvas.drawPath(collarBand2, lapisBlue);

      canvas.drawCircle(Offset(w * 0.50, h * 0.80), w * 0.05, darkGold);
      canvas.drawCircle(Offset(w * 0.50, h * 0.80), w * 0.035, goldPaint);
    }

    final leftEar = Path()
      ..moveTo(w * 0.16, h * 0.44)
      ..quadraticBezierTo(w * 0.14, h * 0.14, w * 0.28, h * 0.10)
      ..quadraticBezierTo(w * 0.44, h * 0.24, w * 0.42, h * 0.40)
      ..close();
    final rightEar = Path()
      ..moveTo(w * 0.84, h * 0.44)
      ..quadraticBezierTo(w * 0.86, h * 0.14, w * 0.72, h * 0.10)
      ..quadraticBezierTo(w * 0.56, h * 0.24, w * 0.58, h * 0.40)
      ..close();
    canvas.drawPath(leftEar, coatPaint);
    canvas.drawPath(rightEar, coatPaint);

    final leftInner = Path()
      ..moveTo(w * 0.22, h * 0.38)
      ..lineTo(w * 0.28, h * 0.16)
      ..lineTo(w * 0.38, h * 0.35)
      ..close();
    final rightInner = Path()
      ..moveTo(w * 0.78, h * 0.38)
      ..lineTo(w * 0.72, h * 0.16)
      ..lineTo(w * 0.62, h * 0.35)
      ..close();
    canvas.drawPath(leftInner, darkGold);
    canvas.drawPath(rightInner, darkGold);

    canvas.drawCircle(Offset(w * 0.50, h * 0.52), w * 0.36, coatPaint);

    final diadem = Path()
      ..moveTo(w * 0.24, h * 0.34)
      ..quadraticBezierTo(w * 0.50, h * 0.28, w * 0.76, h * 0.34)
      ..lineTo(w * 0.74, h * 0.38)
      ..quadraticBezierTo(w * 0.50, h * 0.32, w * 0.26, h * 0.38)
      ..close();
    canvas.drawPath(diadem, goldPaint);

    canvas.drawCircle(Offset(w * 0.50, h * 0.30), w * 0.04, turquoise);
    canvas.drawCircle(Offset(w * 0.50, h * 0.30), w * 0.02, goldPaint);

    final linerPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(w * 0.22, h * 0.46), Offset(w * 0.38, h * 0.46), linerPaint);
    canvas.drawLine(Offset(w * 0.28, h * 0.46), Offset(w * 0.24, h * 0.54), linerPaint);

    canvas.drawLine(Offset(w * 0.78, h * 0.46), Offset(w * 0.62, h * 0.46), linerPaint);
    canvas.drawLine(Offset(w * 0.72, h * 0.46), Offset(w * 0.76, h * 0.54), linerPaint);

    final eyeR = w * 0.055;
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.35, h * 0.48), width: eyeR * 2.2, height: eyeR * 1.6), amberEye);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.65, h * 0.48), width: eyeR * 2.2, height: eyeR * 1.6), amberEye);

    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.35, h * 0.48), width: eyeR * 0.7, height: eyeR * 1.5), eyeBlack);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.65, h * 0.48), width: eyeR * 0.7, height: eyeR * 1.5), eyeBlack);

    canvas.drawCircle(Offset(w * 0.33, h * 0.45), eyeR * 0.35, whitePaint);
    canvas.drawCircle(Offset(w * 0.63, h * 0.45), eyeR * 0.35, whitePaint);

    final noseEgypt = Path()
      ..moveTo(w * 0.47, h * 0.54)
      ..lineTo(w * 0.53, h * 0.54)
      ..lineTo(w * 0.50, h * 0.57)
      ..close();
    canvas.drawPath(noseEgypt, goldPaint);

    final whiskerPaint = Paint()
      ..color = darkGold.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.015
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.20, h * 0.56), Offset(w * 0.32, h * 0.58), whiskerPaint);
    canvas.drawLine(Offset(w * 0.18, h * 0.62), Offset(w * 0.32, h * 0.61), whiskerPaint);
    canvas.drawLine(Offset(w * 0.80, h * 0.56), Offset(w * 0.68, h * 0.58), whiskerPaint);
    canvas.drawLine(Offset(w * 0.82, h * 0.62), Offset(w * 0.68, h * 0.61), whiskerPaint);
  }

  void _paintSphynxCat(Canvas canvas, double w, double h) {
    final skinPaint = Paint()..color = const Color(0xFFFDE68A);
    final skinShade = Paint()..color = const Color(0xFFF59E0B);
    final innerEar = Paint()..color = const Color(0xFFFCA5A5);
    final turquoiseCollar = Paint()..color = const Color(0xFF0D9488);
    final goldBell = Paint()..color = const Color(0xFFEAB308);
    final jadeEye = Paint()..color = const Color(0xFF10B981);
    final darkPupil = Paint()..color = const Color(0xFF0F172A);
    final whitePaint = Paint()..color = Colors.white;

    if (!isHeadOnly) {
      final body = Path()
        ..moveTo(w * 0.34, h * 0.65)
        ..quadraticBezierTo(w * 0.22, h * 0.85, w * 0.27, h * 0.95)
        ..quadraticBezierTo(w * 0.50, h * 0.99, w * 0.73, h * 0.95)
        ..quadraticBezierTo(w * 0.78, h * 0.85, w * 0.66, h * 0.65)
        ..close();
      canvas.drawPath(body, skinPaint);

      final collar = Path()
        ..moveTo(w * 0.30, h * 0.66)
        ..quadraticBezierTo(w * 0.50, h * 0.74, w * 0.70, h * 0.66)
        ..lineTo(w * 0.70, h * 0.71)
        ..quadraticBezierTo(w * 0.50, h * 0.79, w * 0.30, h * 0.71)
        ..close();
      canvas.drawPath(collar, turquoiseCollar);
      canvas.drawCircle(Offset(w * 0.50, h * 0.76), w * 0.045, goldBell);
    }

    final leftEar = Path()
      ..moveTo(w * 0.12, h * 0.46)
      ..quadraticBezierTo(w * 0.06, h * 0.10, w * 0.24, h * 0.05)
      ..quadraticBezierTo(w * 0.44, h * 0.20, w * 0.40, h * 0.38)
      ..close();
    final rightEar = Path()
      ..moveTo(w * 0.88, h * 0.46)
      ..quadraticBezierTo(w * 0.94, h * 0.10, w * 0.76, h * 0.05)
      ..quadraticBezierTo(w * 0.56, h * 0.20, w * 0.60, h * 0.38)
      ..close();
    canvas.drawPath(leftEar, skinPaint);
    canvas.drawPath(rightEar, skinPaint);

    final leftInner = Path()
      ..moveTo(w * 0.18, h * 0.42)
      ..lineTo(w * 0.24, h * 0.10)
      ..lineTo(w * 0.36, h * 0.34)
      ..close();
    final rightInner = Path()
      ..moveTo(w * 0.82, h * 0.42)
      ..lineTo(w * 0.76, h * 0.10)
      ..lineTo(w * 0.64, h * 0.34)
      ..close();
    canvas.drawPath(leftInner, innerEar);
    canvas.drawPath(rightInner, innerEar);

    final head = Path()
      ..moveTo(w * 0.50, h * 0.20)
      ..quadraticBezierTo(w * 0.82, h * 0.24, w * 0.84, h * 0.48)
      ..quadraticBezierTo(w * 0.76, h * 0.74, w * 0.50, h * 0.76)
      ..quadraticBezierTo(w * 0.24, h * 0.74, w * 0.16, h * 0.48)
      ..quadraticBezierTo(w * 0.18, h * 0.24, w * 0.50, h * 0.20)
      ..close();
    canvas.drawPath(head, skinPaint);

    final wrinklePaint = Paint()
      ..color = skinShade.color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.016
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.45, h * 0.26), Offset(w * 0.55, h * 0.26), wrinklePaint);
    canvas.drawLine(Offset(w * 0.43, h * 0.30), Offset(w * 0.57, h * 0.30), wrinklePaint);

    final eyeR = w * 0.06;
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.34, h * 0.48), width: eyeR * 2.2, height: eyeR * 1.6), jadeEye);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.66, h * 0.48), width: eyeR * 2.2, height: eyeR * 1.6), jadeEye);

    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.34, h * 0.48), width: eyeR * 0.6, height: eyeR * 1.5), darkPupil);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.66, h * 0.48), width: eyeR * 0.6, height: eyeR * 1.5), darkPupil);

    canvas.drawCircle(Offset(w * 0.32, h * 0.45), eyeR * 0.35, whitePaint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.45), eyeR * 0.35, whitePaint);

    final noseSphynx = Path()
      ..moveTo(w * 0.47, h * 0.55)
      ..lineTo(w * 0.53, h * 0.55)
      ..lineTo(w * 0.50, h * 0.58)
      ..close();
    canvas.drawPath(noseSphynx, innerEar);

    canvas.drawCircle(Offset(w * 0.40, h * 0.62), w * 0.012, skinShade);
    canvas.drawCircle(Offset(w * 0.36, h * 0.63), w * 0.012, skinShade);
    canvas.drawCircle(Offset(w * 0.60, h * 0.62), w * 0.012, skinShade);
    canvas.drawCircle(Offset(w * 0.64, h * 0.63), w * 0.012, skinShade);
  }

  void _paintShiba(Canvas canvas, double w, double h) {
    final shibaGold = Paint()..color = const Color(0xFFEAB308);
    if (!isHeadOnly) {
      final body = Path()..moveTo(w * 0.32, h * 0.65)..quadraticBezierTo(w * 0.20, h * 0.85, w * 0.25, h * 0.95)..quadraticBezierTo(w * 0.50, h * 0.99, w * 0.75, h * 0.95)..quadraticBezierTo(w * 0.80, h * 0.85, w * 0.68, h * 0.65)..close();
      canvas.drawPath(body, shibaGold);
      final bib = Path()..moveTo(w * 0.38, h * 0.68)..quadraticBezierTo(w * 0.32, h * 0.85, w * 0.36, h * 0.95)..lineTo(w * 0.64, h * 0.95)..quadraticBezierTo(w * 0.68, h * 0.85, w * 0.62, h * 0.68)..close();
      canvas.drawPath(bib, Paint()..color = Colors.white);
      canvas.drawPath(Path()..moveTo(w * 0.30, h * 0.66)..quadraticBezierTo(w * 0.50, h * 0.74, w * 0.70, h * 0.66)..lineTo(w * 0.70, h * 0.70)..quadraticBezierTo(w * 0.50, h * 0.78, w * 0.30, h * 0.70)..close(), Paint()..color = const Color(0xFF0284C7));
      canvas.drawCircle(Offset(w * 0.50, h * 0.75), w * 0.05, Paint()..color = const Color(0xFFFBBF24));
    }
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
    if (!isHeadOnly) {
      final body = Path()..moveTo(w * 0.32, h * 0.65)..quadraticBezierTo(w * 0.20, h * 0.85, w * 0.25, h * 0.95)..quadraticBezierTo(w * 0.50, h * 0.99, w * 0.75, h * 0.95)..quadraticBezierTo(w * 0.80, h * 0.85, w * 0.68, h * 0.65)..close();
      canvas.drawPath(body, Paint()..color = const Color(0xFFF59E0B));
      canvas.drawPath(Path()..moveTo(w * 0.38, h * 0.68)..quadraticBezierTo(w * 0.32, h * 0.85, w * 0.36, h * 0.95)..lineTo(w * 0.64, h * 0.95)..quadraticBezierTo(w * 0.68, h * 0.85, w * 0.62, h * 0.68)..close(), Paint()..color = const Color(0xFFFDE68A));
      canvas.drawCircle(Offset(w * 0.50, h * 0.75), w * 0.05, Paint()..color = const Color(0xFFD97706));
    }
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
    if (!isHeadOnly) {
      final body = Path()..moveTo(w * 0.32, h * 0.65)..quadraticBezierTo(w * 0.20, h * 0.85, w * 0.25, h * 0.95)..quadraticBezierTo(w * 0.50, h * 0.99, w * 0.75, h * 0.95)..quadraticBezierTo(w * 0.80, h * 0.85, w * 0.68, h * 0.65)..close();
      canvas.drawPath(body, darkPaint);
      final whiteChest = Path()..moveTo(w * 0.36, h * 0.68)..quadraticBezierTo(w * 0.32, h * 0.85, w * 0.36, h * 0.95)..lineTo(w * 0.64, h * 0.95)..quadraticBezierTo(w * 0.68, h * 0.85, w * 0.64, h * 0.68)..close();
      canvas.drawPath(whiteChest, whitePaint);
    }

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
    if (!isHeadOnly) {
      final body = Path()..moveTo(w * 0.32, h * 0.65)..quadraticBezierTo(w * 0.20, h * 0.85, w * 0.25, h * 0.95)..quadraticBezierTo(w * 0.50, h * 0.99, w * 0.75, h * 0.95)..quadraticBezierTo(w * 0.80, h * 0.85, w * 0.68, h * 0.65)..close();
      canvas.drawPath(body, foxOrange);
      final whiteChest = Path()..moveTo(w * 0.38, h * 0.68)..quadraticBezierTo(w * 0.32, h * 0.85, w * 0.36, h * 0.95)..lineTo(w * 0.64, h * 0.95)..quadraticBezierTo(w * 0.68, h * 0.85, w * 0.62, h * 0.68)..close();
      canvas.drawPath(whiteChest, Paint()..color = Colors.white);
    }
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
    if (!isHeadOnly) {
      final body = Path()..moveTo(w * 0.32, h * 0.65)..quadraticBezierTo(w * 0.20, h * 0.85, w * 0.25, h * 0.95)..quadraticBezierTo(w * 0.50, h * 0.99, w * 0.75, h * 0.95)..quadraticBezierTo(w * 0.80, h * 0.85, w * 0.68, h * 0.65)..close();
      canvas.drawPath(body, purplePaint);
      final chest = Path()..moveTo(w * 0.38, h * 0.68)..quadraticBezierTo(w * 0.32, h * 0.85, w * 0.36, h * 0.95)..lineTo(w * 0.64, h * 0.95)..quadraticBezierTo(w * 0.68, h * 0.85, w * 0.62, h * 0.68)..close();
      canvas.drawPath(chest, Paint()..color = const Color(0xFFE0E7FF));
    }
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
    if (!isHeadOnly) {
      final body = Path()..moveTo(w * 0.32, h * 0.65)..quadraticBezierTo(w * 0.20, h * 0.85, w * 0.25, h * 0.95)..quadraticBezierTo(w * 0.50, h * 0.99, w * 0.75, h * 0.95)..quadraticBezierTo(w * 0.80, h * 0.85, w * 0.68, h * 0.65)..close();
      canvas.drawPath(body, whitePaint);
      final belly = Path()..moveTo(w * 0.38, h * 0.68)..quadraticBezierTo(w * 0.32, h * 0.85, w * 0.36, h * 0.95)..lineTo(w * 0.64, h * 0.95)..quadraticBezierTo(w * 0.68, h * 0.85, w * 0.62, h * 0.68)..close();
      canvas.drawPath(belly, Paint()..color = const Color(0xFFFCE7F3));
    }
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
    if (!isHeadOnly) {
      final body = Path()..moveTo(w * 0.32, h * 0.65)..quadraticBezierTo(w * 0.20, h * 0.85, w * 0.25, h * 0.95)..quadraticBezierTo(w * 0.50, h * 0.99, w * 0.75, h * 0.95)..quadraticBezierTo(w * 0.80, h * 0.85, w * 0.68, h * 0.65)..close();
      canvas.drawPath(body, brownPaint);
      final belly = Path()..moveTo(w * 0.38, h * 0.68)..quadraticBezierTo(w * 0.32, h * 0.85, w * 0.36, h * 0.95)..lineTo(w * 0.64, h * 0.95)..quadraticBezierTo(w * 0.68, h * 0.85, w * 0.62, h * 0.68)..close();
      canvas.drawPath(belly, Paint()..color = const Color(0xFFFEF08A));
    }
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
    if (!isHeadOnly) {
      final body = Path()..moveTo(w * 0.32, h * 0.65)..quadraticBezierTo(w * 0.20, h * 0.85, w * 0.25, h * 0.95)..quadraticBezierTo(w * 0.50, h * 0.99, w * 0.75, h * 0.95)..quadraticBezierTo(w * 0.80, h * 0.85, w * 0.68, h * 0.65)..close();
      canvas.drawPath(body, Paint()..color = const Color(0xFF0F172A));
      canvas.drawCircle(Offset(w * 0.50, h * 0.78), w * 0.04, Paint()..color = const Color(0xFF10B981));
    }
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

      case 'wings_grand':
      case 'wings':
      case 'royal_cape':
        // Painted under mascot
        break;

      case 'aurora_halo':
        final auraOuter = Paint()
          ..color = const Color(0xFF38BDF8).withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.08
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        final auraInner = Paint()
          ..color = const Color(0xFFFDE047)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.035;
        canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.50, h * 0.06), width: w * 0.54, height: h * 0.16), auraOuter);
        canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.50, h * 0.06), width: w * 0.50, height: h * 0.14), auraInner);
        // Sparkle stars
        canvas.drawCircle(Offset(w * 0.22, h * 0.06), w * 0.025, paintWhite);
        canvas.drawCircle(Offset(w * 0.78, h * 0.06), w * 0.025, paintWhite);
        break;

      case 'phoenix_crown':
        final crownPath = Path()
          ..moveTo(w * 0.24, h * 0.16)
          ..lineTo(w * 0.32, -h * 0.04)
          ..lineTo(w * 0.42, h * 0.08)
          ..lineTo(w * 0.50, -h * 0.08)
          ..lineTo(w * 0.58, h * 0.08)
          ..lineTo(w * 0.68, -h * 0.04)
          ..lineTo(w * 0.76, h * 0.16)
          ..close();
        canvas.drawPath(crownPath, paintGold);
        canvas.drawCircle(Offset(w * 0.50, -h * 0.08), w * 0.04, paintRed);
        canvas.drawCircle(Offset(w * 0.32, -h * 0.04), w * 0.035, paintBlue);
        canvas.drawCircle(Offset(w * 0.68, -h * 0.04), w * 0.035, paintBlue);
        canvas.drawCircle(Offset(w * 0.50, h * 0.06), w * 0.03, paintWhite);
        break;

      case 'magic_wand':
        final wandPath = Path()
          ..moveTo(w * 0.62, h * 0.84)
          ..lineTo(w * 0.88, h * 0.36)
          ..lineTo(w * 0.92, h * 0.38)
          ..lineTo(w * 0.66, h * 0.86)
          ..close();
        canvas.drawPath(wandPath, Paint()..color = const Color(0xFFF59E0B));
        canvas.drawCircle(Offset(w * 0.90, h * 0.35), w * 0.08, Paint()..color = const Color(0xFF38BDF8));
        canvas.drawCircle(Offset(w * 0.90, h * 0.35), w * 0.04, paintWhite);
        break;

      case 'pen':
        _paintPen(canvas, w, h);
        break;

      case 'none':
      default:
        break;
    }
  }

  void _paintPen(Canvas canvas, double w, double h) {
    final paintBlue = Paint()..color = const Color(0xFF0284C7);
    final paintGold = Paint()..color = const Color(0xFFFBBF24);
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
  }

  void _paintOutfit(Canvas canvas, double w, double h, String outfit) {
    switch (outfit) {
      case 'outfit_hoodie':
        final hoodiePaint = Paint()..color = const Color(0xFFEF4444);
        final darkRed = Paint()..color = const Color(0xFFB91C1C);

        final hoodieBody = Path()
          ..moveTo(w * 0.28, h * 0.69)
          ..quadraticBezierTo(w * 0.22, h * 0.85, w * 0.25, h * 0.96)
          ..quadraticBezierTo(w * 0.50, h * 1.00, w * 0.75, h * 0.96)
          ..quadraticBezierTo(w * 0.78, h * 0.85, w * 0.72, h * 0.69)
          ..close();
        canvas.drawPath(hoodieBody, hoodiePaint);

        final hem = Path()
          ..moveTo(w * 0.26, h * 0.93)
          ..quadraticBezierTo(w * 0.50, h * 0.97, w * 0.74, h * 0.93)
          ..lineTo(w * 0.75, h * 0.96)
          ..quadraticBezierTo(w * 0.50, h * 1.00, w * 0.25, h * 0.96)
          ..close();
        canvas.drawPath(hem, darkRed);

        final pocket = Path()
          ..moveTo(w * 0.38, h * 0.83)
          ..lineTo(w * 0.62, h * 0.83)
          ..lineTo(w * 0.66, h * 0.93)
          ..lineTo(w * 0.34, h * 0.93)
          ..close();
        canvas.drawPath(pocket, darkRed);

        final hoodNeck = Path()
          ..moveTo(w * 0.32, h * 0.67)
          ..quadraticBezierTo(w * 0.50, h * 0.76, w * 0.68, h * 0.67)
          ..quadraticBezierTo(w * 0.50, h * 0.72, w * 0.32, h * 0.67)
          ..close();
        canvas.drawPath(hoodNeck, darkRed);

        final stringPaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = w * 0.018..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(w * 0.44, h * 0.71), Offset(w * 0.43, h * 0.81), stringPaint);
        canvas.drawLine(Offset(w * 0.56, h * 0.71), Offset(w * 0.57, h * 0.81), stringPaint);
        canvas.drawCircle(Offset(w * 0.43, h * 0.81), w * 0.015, Paint()..color = const Color(0xFFCBD5E1));
        canvas.drawCircle(Offset(w * 0.57, h * 0.81), w * 0.015, Paint()..color = const Color(0xFFCBD5E1));
        break;

      case 'outfit_suit':
        final suitDark = Paint()..color = const Color(0xFF0F172A);
        final lapelDark = Paint()..color = const Color(0xFF1E293B);
        final whiteShirt = Paint()..color = Colors.white;
        final goldTie = Paint()..color = const Color(0xFFF59E0B);

        final suitBody = Path()
          ..moveTo(w * 0.28, h * 0.69)
          ..quadraticBezierTo(w * 0.22, h * 0.85, w * 0.25, h * 0.96)
          ..quadraticBezierTo(w * 0.50, h * 1.00, w * 0.75, h * 0.96)
          ..quadraticBezierTo(w * 0.78, h * 0.85, w * 0.72, h * 0.69)
          ..close();
        canvas.drawPath(suitBody, suitDark);

        final shirt = Path()
          ..moveTo(w * 0.40, h * 0.68)
          ..lineTo(w * 0.60, h * 0.68)
          ..lineTo(w * 0.50, h * 0.86)
          ..close();
        canvas.drawPath(shirt, whiteShirt);

        final tieKnot = Path()
          ..moveTo(w * 0.47, h * 0.70)
          ..lineTo(w * 0.53, h * 0.70)
          ..lineTo(w * 0.52, h * 0.74)
          ..lineTo(w * 0.48, h * 0.74)
          ..close();
        canvas.drawPath(tieKnot, goldTie);
        final tieBlade = Path()
          ..moveTo(w * 0.48, h * 0.74)
          ..lineTo(w * 0.52, h * 0.74)
          ..lineTo(w * 0.53, h * 0.86)
          ..lineTo(w * 0.50, h * 0.90)
          ..lineTo(w * 0.47, h * 0.86)
          ..close();
        canvas.drawPath(tieBlade, goldTie);

        final leftLapel = Path()
          ..moveTo(w * 0.34, h * 0.68)
          ..lineTo(w * 0.42, h * 0.77)
          ..lineTo(w * 0.48, h * 0.88)
          ..lineTo(w * 0.36, h * 0.88)
          ..close();
        canvas.drawPath(leftLapel, lapelDark);
        final rightLapel = Path()
          ..moveTo(w * 0.66, h * 0.68)
          ..lineTo(w * 0.58, h * 0.77)
          ..lineTo(w * 0.52, h * 0.88)
          ..lineTo(w * 0.64, h * 0.88)
          ..close();
        canvas.drawPath(rightLapel, lapelDark);

        canvas.drawCircle(Offset(w * 0.50, h * 0.92), w * 0.018, goldTie);
        break;

      case 'outfit_tshirt':
        final tShirtPaint = Paint()..color = const Color(0xFF0D9488);
        final collarTeal = Paint()..color = const Color(0xFF115E59);
        final printWhite = Paint()..color = Colors.white.withValues(alpha: 0.9);

        final tBody = Path()
          ..moveTo(w * 0.28, h * 0.69)
          ..quadraticBezierTo(w * 0.22, h * 0.85, w * 0.25, h * 0.96)
          ..quadraticBezierTo(w * 0.50, h * 1.00, w * 0.75, h * 0.96)
          ..quadraticBezierTo(w * 0.78, h * 0.85, w * 0.72, h * 0.69)
          ..close();
        canvas.drawPath(tBody, tShirtPaint);

        final crewCollar = Path()
          ..moveTo(w * 0.36, h * 0.68)
          ..quadraticBezierTo(w * 0.50, h * 0.76, w * 0.64, h * 0.68)
          ..quadraticBezierTo(w * 0.50, h * 0.72, w * 0.36, h * 0.68)
          ..close();
        canvas.drawPath(crewCollar, collarTeal);

        final fishBody = Path()
          ..moveTo(w * 0.44, h * 0.82)
          ..quadraticBezierTo(w * 0.50, h * 0.78, w * 0.56, h * 0.82)
          ..quadraticBezierTo(w * 0.50, h * 0.86, w * 0.44, h * 0.82)
          ..close();
        canvas.drawPath(fishBody, printWhite);
        final fishTail = Path()
          ..moveTo(w * 0.55, h * 0.82)
          ..lineTo(w * 0.60, h * 0.79)
          ..lineTo(w * 0.60, h * 0.85)
          ..close();
        canvas.drawPath(fishTail, printWhite);
        break;

      case 'outfit_sweater':
        final sweaterPaint = Paint()..color = const Color(0xFFC2410C);
        final darkOrange = Paint()..color = const Color(0xFF9A3412);
        final creamPaint = Paint()..color = const Color(0xFFFEF3C7);

        final sBody = Path()
          ..moveTo(w * 0.28, h * 0.69)
          ..quadraticBezierTo(w * 0.22, h * 0.85, w * 0.25, h * 0.96)
          ..quadraticBezierTo(w * 0.50, h * 1.00, w * 0.75, h * 0.96)
          ..quadraticBezierTo(w * 0.78, h * 0.85, w * 0.72, h * 0.69)
          ..close();
        canvas.drawPath(sBody, sweaterPaint);

        final sCollar = Path()
          ..moveTo(w * 0.34, h * 0.68)
          ..quadraticBezierTo(w * 0.50, h * 0.76, w * 0.66, h * 0.68)
          ..quadraticBezierTo(w * 0.50, h * 0.72, w * 0.34, h * 0.68)
          ..close();
        canvas.drawPath(sCollar, darkOrange);

        final patternBand = Path()
          ..moveTo(w * 0.28, h * 0.79)
          ..lineTo(w * 0.72, h * 0.79)
          ..lineTo(w * 0.74, h * 0.85)
          ..lineTo(w * 0.26, h * 0.85)
          ..close();
        canvas.drawPath(patternBand, darkOrange);

        final chevronPaint = Paint()..color = creamPaint.color..style = PaintingStyle.stroke..strokeWidth = w * 0.02..strokeCap = StrokeCap.round;
        for (double cx = 0.32; cx <= 0.68; cx += 0.08) {
          canvas.drawLine(Offset(w * cx, h * 0.84), Offset(w * (cx + 0.04), h * 0.80), chevronPaint);
          canvas.drawLine(Offset(w * (cx + 0.04), h * 0.80), Offset(w * (cx + 0.08), h * 0.84), chevronPaint);
        }
        break;

      case 'outfit_sport':
        final blueJersey = Paint()..color = const Color(0xFF2563EB);
        final whiteStripe = Paint()..color = Colors.white;

        final spBody = Path()
          ..moveTo(w * 0.28, h * 0.69)
          ..quadraticBezierTo(w * 0.22, h * 0.85, w * 0.25, h * 0.96)
          ..quadraticBezierTo(w * 0.50, h * 1.00, w * 0.75, h * 0.96)
          ..quadraticBezierTo(w * 0.78, h * 0.85, w * 0.72, h * 0.69)
          ..close();
        canvas.drawPath(spBody, blueJersey);

        final stripePaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = w * 0.022;
        canvas.drawLine(Offset(w * 0.31, h * 0.72), Offset(w * 0.28, h * 0.94), stripePaint);
        canvas.drawLine(Offset(w * 0.69, h * 0.72), Offset(w * 0.72, h * 0.94), stripePaint);

        final vCollar = Path()
          ..moveTo(w * 0.40, h * 0.68)
          ..lineTo(w * 0.50, h * 0.75)
          ..lineTo(w * 0.60, h * 0.68)
          ..close();
        canvas.drawPath(vCollar, whiteStripe);

        final numStyle = TextStyle(color: Colors.white, fontSize: w * 0.12, fontWeight: FontWeight.w900);
        final textSpan = TextSpan(text: '99', style: numStyle);
        final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
        textPainter.layout();
        textPainter.paint(canvas, Offset(w * 0.50 - (textPainter.width / 2), h * 0.80));
        break;

      case 'outfit_overalls':
        final innerYellow = Paint()..color = const Color(0xFFFBBF24);
        final denimBlue = Paint()..color = const Color(0xFF0284C7);
        final brassButton = Paint()..color = const Color(0xFFF59E0B);

        final inBody = Path()
          ..moveTo(w * 0.28, h * 0.69)
          ..quadraticBezierTo(w * 0.22, h * 0.85, w * 0.25, h * 0.96)
          ..quadraticBezierTo(w * 0.50, h * 1.00, w * 0.75, h * 0.96)
          ..quadraticBezierTo(w * 0.78, h * 0.85, w * 0.72, h * 0.69)
          ..close();
        canvas.drawPath(inBody, innerYellow);

        final overalls = Path()
          ..moveTo(w * 0.36, h * 0.76)
          ..lineTo(w * 0.64, h * 0.76)
          ..lineTo(w * 0.68, h * 0.84)
          ..quadraticBezierTo(w * 0.78, h * 0.88, w * 0.75, h * 0.96)
          ..quadraticBezierTo(w * 0.50, h * 1.00, w * 0.25, h * 0.96)
          ..quadraticBezierTo(w * 0.22, h * 0.88, w * 0.32, h * 0.84)
          ..close();
        canvas.drawPath(overalls, denimBlue);

        final strapPaint = Paint()..color = denimBlue.color..style = PaintingStyle.stroke..strokeWidth = w * 0.045..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(w * 0.34, h * 0.68), Offset(w * 0.38, h * 0.77), strapPaint);
        canvas.drawLine(Offset(w * 0.66, h * 0.68), Offset(w * 0.62, h * 0.77), strapPaint);

        canvas.drawCircle(Offset(w * 0.38, h * 0.78), w * 0.022, brassButton);
        canvas.drawCircle(Offset(w * 0.62, h * 0.78), w * 0.022, brassButton);

        final bibPocket = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.50, h * 0.86), width: w * 0.20, height: h * 0.09), const Radius.circular(3));
        canvas.drawRRect(bibPocket, Paint()..color = const Color(0xFF0369A1));
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _UniversalMascotPainter oldDelegate) {
    return oldDelegate.mascotId != mascotId ||
        oldDelegate.accessory != accessory ||
        oldDelegate.outfit != outfit ||
        oldDelegate.withPen != withPen ||
        oldDelegate.isHeadOnly != isHeadOnly;
  }
}

class AccessoryVisualWidget extends StatelessWidget {
  final String accessoryId;
  final double size;
  final Color? color;

  const AccessoryVisualWidget({
    super.key,
    required this.accessoryId,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? const Color(0xFFF59E0B);

    if (accessoryId == 'wings_grand') {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          size: Size(size, size),
          painter: _WingsIconPainter(const Color(0xFFF59E0B)),
        ),
      );
    }
    if (accessoryId == 'gold_shades') {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          size: Size(size, size),
          painter: _GlassesIconPainter(activeColor),
        ),
      );
    }

    if (accessoryId == 'bowtie') {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          size: Size(size, size),
          painter: _BowtieIconPainter(activeColor),
        ),
      );
    }

    if (accessoryId == 'wings') {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          size: Size(size, size),
          painter: _WingsIconPainter(activeColor),
        ),
      );
    }

    if (accessoryId == 'scarf') {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          size: Size(size, size),
          painter: _ScarfIconPainter(activeColor),
        ),
      );
    }

    if (accessoryId == 'halo') {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          size: Size(size, size),
          painter: _HaloIconPainter(activeColor),
        ),
      );
    }

    if (accessoryId == 'headband') {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          size: Size(size, size),
          painter: _HeadbandIconPainter(activeColor),
        ),
      );
    }

    final acc = MascotCatalog.accessories.firstWhere(
      (a) => a.id == accessoryId,
      orElse: () => MascotCatalog.accessories.first,
    );
    return Icon(acc.icon, size: size, color: activeColor);
  }
}

class OutfitVisualWidget extends StatelessWidget {
  final String outfitId;
  final double size;
  final Color? color;

  const OutfitVisualWidget({
    super.key,
    required this.outfitId,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (outfitId == 'none') {
      return Icon(Icons.block_rounded, size: size, color: color ?? Colors.grey);
    }
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _OutfitIconPainter(outfitId: outfitId, color: color),
      ),
    );
  }
}

class _GlassesIconPainter extends CustomPainter {
  final Color color;
  _GlassesIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final framePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round;
    final lensPaint = Paint()..color = const Color(0xFF0F172A);

    final leftRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.28, h * 0.50), width: w * 0.40, height: h * 0.36),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(leftRect, lensPaint);
    canvas.drawRRect(leftRect, framePaint);

    final rightRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.72, h * 0.50), width: w * 0.40, height: h * 0.36),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(rightRect, lensPaint);
    canvas.drawRRect(rightRect, framePaint);

    final bridge = Path()
      ..moveTo(w * 0.46, h * 0.48)
      ..quadraticBezierTo(w * 0.50, h * 0.42, w * 0.54, h * 0.48);
    canvas.drawPath(bridge, framePaint);

    final glarePaint = Paint()
      ..color = Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.20, h * 0.42), Offset(w * 0.32, h * 0.56), glarePaint);
    canvas.drawLine(Offset(w * 0.64, h * 0.42), Offset(w * 0.76, h * 0.56), glarePaint);
  }

  @override
  bool shouldRepaint(covariant _GlassesIconPainter oldDelegate) => oldDelegate.color != color;
}

class _BowtieIconPainter extends CustomPainter {
  final Color color;
  _BowtieIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bowPaint = Paint()..color = const Color(0xFFEF4444);
    final knotPaint = Paint()..color = const Color(0xFFDC2626);
    final goldRing = Paint()..color = const Color(0xFFFBBF24);

    final leftWing = Path()
      ..moveTo(w * 0.50, h * 0.50)
      ..lineTo(w * 0.12, h * 0.26)
      ..quadraticBezierTo(w * 0.08, h * 0.50, w * 0.12, h * 0.74)
      ..close();
    canvas.drawPath(leftWing, bowPaint);

    final rightWing = Path()
      ..moveTo(w * 0.50, h * 0.50)
      ..lineTo(w * 0.88, h * 0.26)
      ..quadraticBezierTo(w * 0.92, h * 0.50, w * 0.88, h * 0.74)
      ..close();
    canvas.drawPath(rightWing, bowPaint);

    canvas.drawCircle(Offset(w * 0.50, h * 0.50), w * 0.14, knotPaint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.50), w * 0.08, goldRing);
  }

  @override
  bool shouldRepaint(covariant _BowtieIconPainter oldDelegate) => oldDelegate.color != color;
}

class _WingsIconPainter extends CustomPainter {
  final Color color;
  _WingsIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final wingPaint = Paint()..color = const Color(0xFFF59E0B);

    final left = Path()
      ..moveTo(w * 0.45, h * 0.60)
      ..quadraticBezierTo(w * 0.10, h * 0.20, 0, h * 0.40)
      ..quadraticBezierTo(w * 0.15, h * 0.75, w * 0.45, h * 0.70)
      ..close();
    canvas.drawPath(left, wingPaint);

    final right = Path()
      ..moveTo(w * 0.55, h * 0.60)
      ..quadraticBezierTo(w * 0.90, h * 0.20, w, h * 0.40)
      ..quadraticBezierTo(w * 0.85, h * 0.75, w * 0.55, h * 0.70)
      ..close();
    canvas.drawPath(right, wingPaint);
  }

  @override
  bool shouldRepaint(covariant _WingsIconPainter oldDelegate) => oldDelegate.color != color;
}

class _ScarfIconPainter extends CustomPainter {
  final Color color;
  _ScarfIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final scarfPaint = Paint()..color = const Color(0xFFEF4444);

    final wrap = Path()
      ..moveTo(w * 0.15, h * 0.45)
      ..quadraticBezierTo(w * 0.50, h * 0.60, w * 0.85, h * 0.45)
      ..lineTo(w * 0.85, h * 0.60)
      ..quadraticBezierTo(w * 0.50, h * 0.75, w * 0.15, h * 0.60)
      ..close();
    canvas.drawPath(wrap, scarfPaint);

    final tail = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.65, h * 0.50, w * 0.18, h * 0.40),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(tail, scarfPaint);
  }

  @override
  bool shouldRepaint(covariant _ScarfIconPainter oldDelegate) => oldDelegate.color != color;
}

class _HaloIconPainter extends CustomPainter {
  final Color color;
  _HaloIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final haloPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.12;
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.50, h * 0.50), width: w * 0.80, height: h * 0.42), haloPaint);
  }

  @override
  bool shouldRepaint(covariant _HaloIconPainter oldDelegate) => oldDelegate.color != color;
}

class _HeadbandIconPainter extends CustomPainter {
  final Color color;
  _HeadbandIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final hbPaint = Paint()..color = const Color(0xFFEF4444);

    final band = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.50, h * 0.50), width: w * 0.84, height: h * 0.24),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(band, hbPaint);

    final knotTail = Path()
      ..moveTo(w * 0.80, h * 0.50)
      ..lineTo(w * 0.98, h * 0.70)
      ..lineTo(w * 0.88, h * 0.80)
      ..close();
    canvas.drawPath(knotTail, hbPaint);
  }

  @override
  bool shouldRepaint(covariant _HeadbandIconPainter oldDelegate) => oldDelegate.color != color;
}

class _OutfitIconPainter extends CustomPainter {
  final String outfitId;
  final Color? color;
  _OutfitIconPainter({required this.outfitId, this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    switch (outfitId) {
      case 'outfit_hoodie':
        final p = Paint()..color = color ?? const Color(0xFFEF4444);
        final body = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.18, h * 0.25, w * 0.64, h * 0.65), Radius.circular(w * 0.10));
        canvas.drawRRect(body, p);
        canvas.drawCircle(Offset(w * 0.50, h * 0.22), w * 0.16, p);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.32, h * 0.58, w * 0.36, h * 0.22), Radius.circular(w * 0.04)), Paint()..color = const Color(0xFFB91C1C));
        break;

      case 'outfit_suit':
        final p = Paint()..color = color ?? const Color(0xFF0F172A);
        final body = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.18, h * 0.25, w * 0.64, h * 0.65), Radius.circular(w * 0.08));
        canvas.drawRRect(body, p);
        final shirt = Path()..moveTo(w * 0.35, h * 0.25)..lineTo(w * 0.65, h * 0.25)..lineTo(w * 0.50, h * 0.65)..close();
        canvas.drawPath(shirt, Paint()..color = Colors.white);
        final tie = Path()..moveTo(w * 0.48, h * 0.30)..lineTo(w * 0.52, h * 0.30)..lineTo(w * 0.50, h * 0.60)..close();
        canvas.drawPath(tie, Paint()..color = const Color(0xFFF59E0B));
        break;

      case 'outfit_tshirt':
        final p = Paint()..color = color ?? const Color(0xFF0D9488);
        final t = Path()
          ..moveTo(w * 0.32, h * 0.24)
          ..lineTo(w * 0.10, h * 0.45)
          ..lineTo(w * 0.22, h * 0.55)
          ..lineTo(w * 0.24, h * 0.48)
          ..lineTo(w * 0.24, h * 0.88)
          ..lineTo(w * 0.76, h * 0.88)
          ..lineTo(w * 0.76, h * 0.48)
          ..lineTo(w * 0.78, h * 0.55)
          ..lineTo(w * 0.90, h * 0.45)
          ..lineTo(w * 0.68, h * 0.24)
          ..close();
        canvas.drawPath(t, p);
        canvas.drawCircle(Offset(w * 0.50, h * 0.55), w * 0.10, Paint()..color = Colors.white);
        break;

      case 'outfit_sweater':
        final p = Paint()..color = color ?? const Color(0xFFC2410C);
        final body = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.18, h * 0.25, w * 0.64, h * 0.65), Radius.circular(w * 0.08));
        canvas.drawRRect(body, p);
        canvas.drawLine(Offset(w * 0.20, h * 0.55), Offset(w * 0.80, h * 0.55), Paint()..color = const Color(0xFFFEF3C7)..strokeWidth = 3);
        break;

      case 'outfit_sport':
        final p = Paint()..color = color ?? const Color(0xFF2563EB);
        final body = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.18, h * 0.25, w * 0.64, h * 0.65), Radius.circular(w * 0.08));
        canvas.drawRRect(body, p);
        canvas.drawLine(Offset(w * 0.28, h * 0.28), Offset(w * 0.28, h * 0.86), Paint()..color = Colors.white..strokeWidth = 2);
        canvas.drawLine(Offset(w * 0.72, h * 0.28), Offset(w * 0.72, h * 0.86), Paint()..color = Colors.white..strokeWidth = 2);
        break;

      case 'outfit_overalls':
        final inner = Paint()..color = const Color(0xFFFBBF24);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.20, h * 0.25, w * 0.60, h * 0.65), Radius.circular(w * 0.08)), inner);
        final denim = Paint()..color = color ?? const Color(0xFF0284C7);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.25, h * 0.45, w * 0.50, h * 0.45), Radius.circular(w * 0.06)), denim);
        canvas.drawLine(Offset(w * 0.32, h * 0.25), Offset(w * 0.32, h * 0.48), Paint()..color = denim.color..strokeWidth = 4);
        canvas.drawLine(Offset(w * 0.68, h * 0.25), Offset(w * 0.68, h * 0.48), Paint()..color = denim.color..strokeWidth = 4);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _OutfitIconPainter oldDelegate) => oldDelegate.outfitId != outfitId || oldDelegate.color != color;
}
