import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../state/expense_controller.dart';

/// Free VIP for team members, unlocked with a code made by tool/team_code.dart.
///
/// A code is a small payload (member id, last valid day) signed with an
/// Ed25519 key that never leaves the developer's computer; the app only has
/// the public key, so codes cannot be made from the app. Codes are given away,
/// never sold, so no payment happens outside Google Play.
class TeamCodeService {
  TeamCodeService._();

  static const _publicKey = '2drhV00jpe1U0zV5S38oHGSoAzmRyB1Dx68/+mEcUus=';

  /// Member ids whose codes no longer work (e.g. someone who left the team).
  static const Set<int> revokedIds = {};

  static const tier = 'team';
  static final _epoch = DateTime.utc(2020, 1, 1);

  /// Checks [code]; on success VIP is turned on and null is returned,
  /// otherwise a message for the user.
  static Future<String?> redeem(ExpenseController controller, String code, {bool isEn = false}) async {
    final parsed = await verify(code.trim());
    if (parsed == null) return isEn ? 'This code is not valid' : 'โค้ดนี้ไม่ถูกต้อง';
    if (revokedIds.contains(parsed.id)) return isEn ? 'This code has been cancelled' : 'โค้ดนี้ถูกยกเลิกแล้ว';
    if (parsed.until != null && DateTime.now().isAfter(parsed.until!)) {
      return isEn ? 'This code has expired' : 'โค้ดนี้หมดอายุแล้ว';
    }
    await controller.storage.setTeamCode(code.trim());
    await controller.setPremiumStatus(true, tier: tier, expiry: parsed.until);
    return null;
  }

  /// On start: switches team VIP off when its code was cancelled in an update.
  /// (The end date is enforced by the stored VIP expiry.)
  static Future<void> recheck(ExpenseController controller) async {
    if (controller.premiumTier != tier) return;
    final code = controller.storage.getTeamCode();
    final parsed = code == null ? null : await verify(code);
    if (parsed == null || revokedIds.contains(parsed.id)) {
      await controller.storage.setTeamCode(null);
      await controller.setPremiumStatus(false, tier: 'none');
    }
  }

  /// The member id and last valid moment of [code], or null when it is not a valid code.
  static Future<({int id, DateTime? until})?> verify(String code) async {
    try {
      if (!code.startsWith('MT-')) return null;
      var b64 = code.substring(3);
      b64 = b64.padRight((b64.length + 3) ~/ 4 * 4, '=');
      final bytes = base64Url.decode(b64);
      if (bytes.length != 5 + 64 || bytes[0] != 1) return null;
      final payload = bytes.sublist(0, 5);
      final ok = await Ed25519().verify(
        payload,
        signature: Signature(
          bytes.sublist(5),
          publicKey: SimplePublicKey(base64Decode(_publicKey), type: KeyPairType.ed25519),
        ),
      );
      if (!ok) return null;
      final id = payload[1] << 8 | payload[2];
      final days = payload[3] << 8 | payload[4];
      // Valid through the end of its last day, Thai time.
      final until = days == 0 ? null : _epoch.add(Duration(days: days + 1, hours: -7));
      return (id: id, until: until);
    } catch (_) {
      return null;
    }
  }
}
