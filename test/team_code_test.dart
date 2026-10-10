import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/services/team_code_service.dart';

void main() {
  // Made with tool/team_code.dart for member 65000, valid until 2020-06-30:
  // it verifies but expired long ago, so it is safe to keep in the repo.
  const expired = 'MT-Af3oALVGiTS0erHWcBtS2HKp_vVSeMQBfwCU8ogst2Z3zEemTbI_0UDIF3qzzSafM0MrNEuox8KGw2gA1FtG9bdZ9GwD';

  test('a code made by the tool verifies, with its member id and end', () async {
    final parsed = await TeamCodeService.verify(expired);
    expect(parsed, isNotNull);
    expect(parsed!.id, 65000);
    // Valid through the end of 30 June 2020, Thai time.
    expect(parsed.until, DateTime.utc(2020, 6, 30, 17));
  });

  test('surrounding spaces from a pasted code are fine', () async {
    expect(await TeamCodeService.verify(' $expired\n'.trim()), isNotNull);
  });

  test('a changed code is rejected', () async {
    // Change the member id byte; the signature no longer matches.
    final tampered = 'MT-Af3p${expired.substring(7)}';
    expect(await TeamCodeService.verify(tampered), isNull);
  });

  test('other text is rejected', () async {
    expect(await TeamCodeService.verify(''), isNull);
    expect(await TeamCodeService.verify('MT-'), isNull);
    expect(await TeamCodeService.verify('VIP-FREE-2026'), isNull);
    expect(await TeamCodeService.verify(expired.substring(0, 40)), isNull);
  });
}
