import 'package:flutter/material.dart';

class BankBadge extends StatelessWidget {
  final String bankCode;
  final double size;
  final bool showLabel;
  final TextStyle? labelStyle;

  const BankBadge({
    super.key,
    required this.bankCode,
    this.size = 36.0,
    this.showLabel = false,
    this.labelStyle,
  });

  String get _normalizedCode {
    final code = bankCode.toUpperCase().trim();
    if (code.contains('KBANK') || code.contains('KASIKORN') || code.contains('K PLUS')) return 'KBANK';
    if (code.contains('MAKE')) return 'MAKE';
    if (code.contains('SCB')) return 'SCB';
    if (code.contains('KTB') || code.contains('NEXT')) return 'KTB';
    if (code.contains('BBL') || code.contains('BANGKOK') || code.contains('BUALUANG')) return 'BBL';
    if (code.contains('TTB') || code.contains('TMB') || code.contains('THANACHART')) return 'TTB';
    if (code.contains('GSB') || code.contains('MYMO') || code.contains('ออมสิน')) return 'GSB';
    if (code.contains('KEPT')) return 'KEPT';
    if (code.contains('BAY') || code.contains('KRUNGSRI') || code.contains('KMA')) return 'BAY';
    if (code.contains('IBANK') || code.contains('ISLAMIC') || code.contains('อิสลาม')) return 'IBANK';
    if (code.contains('TRUEMONEY') || code.contains('TRUE')) return 'TRUEMONEY';
    if (code.contains('DIME')) return 'DIME';
    if (code.contains('KKP') || code.contains('KIATNAKIN')) return 'KKP';
    if (code.contains('GHB') || code.contains('ธอส')) return 'GHB';
    if (code.contains('TISCO')) return 'TISCO';
    if (code.contains('LHB') || code.contains('LH BANK') || code.contains('LAND AND HOUSES')) return 'LHBANK';
    if (code.contains('BAAC') || code.contains('ธกส')) return 'BAAC';
    if (code.contains('PAOTANG') || code.contains('เป๋าตัง')) return 'PAOTANG';
    if (code.contains('PROMPTPAY') || code.contains('พร้อมเพย์')) return 'PROMPTPAY';
    if (code.contains('CIMB')) return 'CIMB';
    if (code.contains('UOB') || code.contains('TMRW')) return 'UOB';
    if (code.contains('CASH') || code.contains('เงินสด')) return 'CASH';
    return code;
  }

  Color get bankColor {
    switch (_normalizedCode) {
      case 'KBANK':
        return const Color(0xFF138F2D);
      case 'MAKE':
        return const Color(0xFF10B981);
      case 'SCB':
        return const Color(0xFF4E2A84);
      case 'KTB':
        return const Color(0xFF00A6E6);
      case 'BBL':
        return const Color(0xFF1E3F8B);
      case 'TTB':
        return const Color(0xFF002D62);
      case 'GSB':
        return const Color(0xFFE91E63);
      case 'BAY':
        return const Color(0xFFFECB00);
      case 'KEPT':
        return const Color(0xFF5B45FF);
      case 'UOB':
        return const Color(0xFF002A6A);
      case 'CIMB':
        return const Color(0xFF7E0000);
      case 'KKP':
        return const Color(0xFF223652);
      case 'DIME':
        return const Color(0xFF00D18F);
      case 'GHB':
        return const Color(0xFFF37021);
      case 'TISCO':
        return const Color(0xFF004B93);
      case 'LHBANK':
        return const Color(0xFF6D6E71);
      case 'IBANK':
        return const Color(0xFF006F3D);
      case 'BAAC':
        return const Color(0xFF004D40);
      case 'PAOTANG':
        return const Color(0xFF00A6E6);
      case 'TRUEMONEY':
        return const Color(0xFFFF6C00);
      case 'PROMPTPAY':
        return const Color(0xFF003D79);
      case 'CASH':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF64748B);
    }
  }

  String get bankDisplayName {
    switch (_normalizedCode) {
      case 'KBANK':
        return 'K PLUS (กสิกรไทย)';
      case 'MAKE':
        return 'MAKE by KBank';
      case 'SCB':
        return 'SCB EASY (ไทยพาณิชย์)';
      case 'KTB':
        return 'Krungthai NEXT (กรุงไทย)';
      case 'BBL':
        return 'Bangkok Bank (กรุงเทพ)';
      case 'TTB':
        return 'ttb touch (ทหารไทยธนชาต)';
      case 'GSB':
        return 'MyMo by GSB (ออมสิน)';
      case 'BAY':
        return 'KMA-Krungsri (กรุงศรี)';
      case 'KEPT':
        return 'Kept by Krungsri';
      case 'UOB':
        return 'UOB TMRW Thailand (ยูโอบี)';
      case 'CIMB':
        return 'CIMB Thai Digital Banking';
      case 'KKP':
        return 'KKP MOBILE (เกียรตินาคินภัทร)';
      case 'DIME':
        return 'Dime! by KKP';
      case 'GHB':
        return 'GHB ALL GEN (ธอส.)';
      case 'TISCO':
        return 'TISCO My Wealth (ทิสโก้)';
      case 'LHBANK':
        return 'LHB You (แลนด์ แอนด์ เฮ้าส์)';
      case 'IBANK':
        return 'iBank (อิสลามแห่งประเทศไทย)';
      case 'BAAC':
        return 'A-Mobile Plus (ธ.ก.ส.)';
      case 'PAOTANG':
        return 'เป๋าตัง (G-Wallet)';
      case 'TRUEMONEY':
        return 'TrueMoney Wallet';
      case 'PROMPTPAY':
        return 'PromptPay พร้อมเพย์';
      case 'CASH':
        return 'เงินสด (Cash)';
      default:
        return 'บัญชีอื่นๆ ($bankCode)';
    }
  }

  String? get _bankLogoAsset {
    final code = _normalizedCode.toLowerCase();
    const available = [
      'kbank', 'scb', 'bbl', 'ktb', 'ttb', 'bay', 'gsb', 'uob',
      'cimb', 'kkp', 'ghb', 'tisco', 'lhbank', 'ibank', 'baac',
      'promptpay', 'truemoney', 'make', 'kept', 'dime', 'paotang'
    ];
    if (available.contains(code)) {
      return 'assets/icons/banks/$code.png';
    }
    return null;
  }

  Widget _buildFallbackContainer() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bankColor,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: bankColor.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: _buildFallbackSymbol(),
      ),
    );
  }

  Widget _buildFallbackSymbol() {
    switch (_normalizedCode) {
      case 'KBANK':
        return Text('K', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: size * 0.52));
      case 'MAKE':
        return Icon(Icons.cloud_done_rounded, color: Colors.white, size: size * 0.58);
      case 'SCB':
        return Icon(Icons.shield_moon_rounded, color: const Color(0xFFFFD700), size: size * 0.58);
      case 'KTB':
        return Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: size * 0.58);
      case 'BBL':
        return Icon(Icons.spa_rounded, color: const Color(0xFFFF9900), size: size * 0.58);
      case 'TTB':
        return Text('ttb', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: size * 0.40, letterSpacing: -0.5));
      case 'GSB':
        return Icon(Icons.umbrella_rounded, color: Colors.white, size: size * 0.58);
      case 'BAY':
        return Icon(Icons.account_balance_rounded, color: const Color(0xFF2C2C2C), size: size * 0.58);
      case 'KEPT':
        return Icon(Icons.savings_rounded, color: Colors.white, size: size * 0.58);
      case 'UOB':
        return Icon(Icons.grid_view_rounded, color: const Color(0xFFFF2D55), size: size * 0.56);
      case 'CIMB':
        return Icon(Icons.change_history_rounded, color: Colors.white, size: size * 0.58);
      case 'KKP':
        return Text('KKP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: size * 0.35));
      case 'DIME':
        return Text('Dime!', style: TextStyle(color: const Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: size * 0.30));
      case 'GHB':
        return Icon(Icons.home_work_rounded, color: Colors.white, size: size * 0.58);
      case 'TISCO':
        return Icon(Icons.diamond_rounded, color: Colors.white, size: size * 0.58);
      case 'LHBANK':
        return Icon(Icons.local_florist_rounded, color: Colors.white, size: size * 0.58);
      case 'IBANK':
        return Icon(Icons.dark_mode_rounded, color: const Color(0xFFFFD700), size: size * 0.56);
      case 'BAAC':
        return Icon(Icons.agriculture_rounded, color: const Color(0xFFFFD700), size: size * 0.58);
      case 'PAOTANG':
        return Icon(Icons.wallet_rounded, color: Colors.white, size: size * 0.58);
      case 'TRUEMONEY':
        return Icon(Icons.monetization_on_rounded, color: Colors.white, size: size * 0.58);
      case 'PROMPTPAY':
        return Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: size * 0.56);
      case 'CASH':
        return Icon(Icons.payments_rounded, color: Colors.white, size: size * 0.58);
      default:
        return Icon(Icons.account_balance_rounded, color: Colors.white, size: size * 0.55);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset = _bankLogoAsset;

    final Widget badge;
    if (asset != null) {
      badge = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: bankColor.withValues(alpha: 0.20),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            asset,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildFallbackContainer(),
          ),
        ),
      );
    } else {
      badge = _buildFallbackContainer();
    }

    if (!showLabel) return badge;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            bankDisplayName,
            style: labelStyle ??
                const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
