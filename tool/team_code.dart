// Creates team member codes that unlock VIP for free in the app.
//
// Run from the project folder:
//   dart run tool/team_code.dart init  E:/MeowTang-keys/team_code.key
//       Creates the signing key (once). Prints the public key to put in
//       lib/services/team_code_service.dart. Back the key file up; keep it secret.
//   dart run tool/team_code.dart make  E:/MeowTang-keys/team_code.key <id> "<name>" [YYYY-MM-DD]
//       Prints a code for team member <id> (1-65535), valid until the date
//       (or forever when no date is given), and logs it in team_codes.csv
//       next to the key file. To revoke a code, add its id to
//       TeamCodeService.revokedIds and release an update.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

final _epoch = DateTime.utc(2020, 1, 1);

Future<void> main(List<String> args) async {
  if (args.length >= 2 && args[0] == 'init') return _init(args[1]);
  if (args.length >= 4 && args[0] == 'make') return _make(args[1], int.parse(args[2]), args[3], args.length > 4 ? args[4] : null);
  stderr.writeln('usage:\n  init <keyfile>\n  make <keyfile> <id> "<name>" [YYYY-MM-DD]');
  exitCode = 64;
}

Future<void> _init(String keyPath) async {
  final file = File(keyPath);
  if (file.existsSync()) {
    stderr.writeln('$keyPath already exists; not overwriting it (old codes would stop working).');
    exitCode = 1;
    return;
  }
  final pair = await Ed25519().newKeyPair();
  final seed = await pair.extractPrivateKeyBytes();
  final pub = await pair.extractPublicKey();
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(base64Encode(seed));
  stdout.writeln('Key saved to $keyPath (keep it secret, back it up).');
  stdout.writeln('Public key for TeamCodeService._publicKey:');
  stdout.writeln(base64Encode(pub.bytes));
}

Future<void> _make(String keyPath, int id, String name, String? until) async {
  if (id < 1 || id > 0xFFFF) throw ArgumentError('id must be 1..65535');
  var days = 0;
  if (until != null) {
    final d = DateTime.parse(until);
    days = DateTime.utc(d.year, d.month, d.day).difference(_epoch).inDays;
  }
  final payload = Uint8List.fromList([1, id >> 8, id & 0xFF, days >> 8, days & 0xFF]);
  final seed = base64Decode(File(keyPath).readAsStringSync().trim());
  final pair = await Ed25519().newKeyPairFromSeed(seed);
  final sig = await Ed25519().sign(payload, keyPair: pair);
  final code = 'MT-${base64Url.encode([...payload, ...sig.bytes]).replaceAll('=', '')}';

  final log = File('${File(keyPath).parent.path}/team_codes.csv');
  if (!log.existsSync()) log.writeAsStringSync('id,name,valid_until,created\n');
  log.writeAsStringSync('$id,"$name",${until ?? 'forever'},${DateTime.now().toIso8601String().substring(0, 10)}\n',
      mode: FileMode.append);
  stdout.writeln(code);
}
