import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/services/online_slip_verification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Online & ITMX Slip Verification Tests', () {
    test('1. Bank code to readable Thai name mapping', () {
      expect(OnlineSlipVerificationService.mapBankCodeToName('004'), contains('กสิกรไทย'));
      expect(OnlineSlipVerificationService.mapBankCodeToName('KBANK'), contains('กสิกรไทย'));
      expect(OnlineSlipVerificationService.mapBankCodeToName('014'), contains('ไทยพาณิชย์'));
      expect(OnlineSlipVerificationService.mapBankCodeToName('006'), contains('กรุงไทย'));
      expect(OnlineSlipVerificationService.mapBankCodeToName('002'), contains('กรุงเทพ'));
      expect(OnlineSlipVerificationService.mapBankCodeToName('011'), contains('ทหารไทยธนชาต'));
      expect(OnlineSlipVerificationService.mapBankCodeToName('025'), contains('กรุงศรีอยุธยา'));
      expect(OnlineSlipVerificationService.mapBankCodeToName('030'), contains('ออมสิน'));
      expect(OnlineSlipVerificationService.mapBankCodeToName('034'), contains('ธ.ก.ส.'));
      expect(OnlineSlipVerificationService.mapBankCodeToName('066'), contains('อิสลามแห่งประเทศไทย'));
      expect(OnlineSlipVerificationService.mapBankCodeToName('IBANK'), contains('อิสลามแห่งประเทศไทย'));
      expect(OnlineSlipVerificationService.mapBankCodeToName('098'), contains('พร้อมเพย์'));
    });

    test('2. Missing image file gracefully returns fast error without blocking', () async {
      final res = await OnlineSlipVerificationService.verifySlipOnline(imagePath: 'non_existent_file.jpg');
      expect(res.isVerified, isFalse);
      expect(res.errorCode, 'file-not-found');
      expect(res.responseTimeMs, lessThan(2000));
    });
  });
}
