import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Files inside the app's own private storage.
class AppFiles {
  AppFiles._();

  static String? _root;

  /// Whether [path] is in the app's private storage (its documents, files or
  /// cache folders), so the app may delete it. Photos in the user's gallery
  /// are never in there.
  static Future<bool> isAppOwned(String path) async {
    try {
      // e.g. /data/user/0/<package>/app_flutter -> /data/user/0/<package>
      _root ??= (await getApplicationDocumentsDirectory()).parent.path;
      return path.startsWith('${_root!}/');
    } catch (_) {
      return false;
    }
  }

  /// Deletes [path] if it is the app's own file; errors are ignored.
  static Future<void> deleteIfAppOwned(String? path) async {
    if (path == null || path.isEmpty || !await isAppOwned(path)) return;
    try {
      await File(path).delete();
    } catch (_) {}
  }
}
