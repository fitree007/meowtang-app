import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction_item.dart';
import 'native_bridge_service.dart';

class SlipStorageService {
  static String? _cachedSlipsDir;

  /// Gets the dedicated app-private sandbox directory for saved slips
  static Future<String> getSlipsDirectoryPath() async {
    if (_cachedSlipsDir != null && _cachedSlipsDir!.isNotEmpty) {
      return _cachedSlipsDir!;
    }
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final slipsDir = Directory('${docDir.path}/saved_slips');
      if (!await slipsDir.exists()) {
        await slipsDir.create(recursive: true);
      }
      _cachedSlipsDir = slipsDir.path;
      return slipsDir.path;
    } catch (_) {
      // Fallback
      final temp = Directory.systemTemp.path;
      final fallbackDir = Directory('$temp/saved_slips');
      if (!fallbackDir.existsSync()) {
        fallbackDir.createSync(recursive: true);
      }
      _cachedSlipsDir = fallbackDir.path;
      return fallbackDir.path;
    }
  }

  /// Compresses and permanently saves a slip into app-internal storage.
  /// Reduces a 3-8MB camera/gallery photo to a crisp ~35-65KB slip image.
  static Future<String> persistSlipImage(String originalPath, {String? customName}) async {
    if (originalPath.isEmpty) return originalPath;

    final sourceFile = File(originalPath);
    if (!await sourceFile.exists()) {
      return originalPath;
    }

    final slipsDir = await getSlipsDirectoryPath();
    final cleanPath = originalPath.replaceAll('\\', '/');

    // If already inside our saved_slips sandbox directory, return directly
    if (cleanPath.contains('/saved_slips/')) {
      return originalPath;
    }

    final baseName = sourceFile.uri.pathSegments.isNotEmpty
        ? sourceFile.uri.pathSegments.last
        : 'slip_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final safeBaseName = baseName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final hashName = 'slip_${safeBaseName.hashCode.abs()}_$safeBaseName';
    final targetFileName = customName ?? hashName;

    // 1. Try Native Hardware Compression (Android BitmapFactory RGB_565 + 78% JPEG)
    try {
      final nativePath = await NativeBridgeService.compressAndSaveSlip(
        originalPath,
        fileName: targetFileName,
      );
      if (nativePath != null && nativePath.isNotEmpty && await File(nativePath).exists()) {
        return nativePath;
      }
    } catch (e) {
      debugPrint('[SlipStorage] Native compression note: $e');
    }

    // 2. Pure Dart Sandbox Copy fallback
    try {
      final targetFile = File('$slipsDir/$targetFileName');
      if (!await targetFile.exists() || await targetFile.length() == 0) {
        await sourceFile.copy(targetFile.path);
      }
      return targetFile.path;
    } catch (e) {
      debugPrint('[SlipStorage] Copy fallback note: $e');
      return originalPath;
    }
  }

  /// Intelligently resolves the slip image file.
  /// If the user deleted the original from phone gallery, it loads the internal sandbox copy.
  static File? resolveSlipFile(String? storedPath) {
    if (storedPath == null || storedPath.trim().isEmpty) {
      return null;
    }

    final directFile = File(storedPath);
    if (directFile.existsSync() && directFile.lengthSync() > 0) {
      return directFile;
    }

    // If original was deleted from external gallery, search our saved_slips directory
    try {
      final cleanPath = storedPath.replaceAll('\\', '/');
      final baseName = cleanPath.split('/').last;
      final safeBaseName = baseName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      final hash = safeBaseName.hashCode.abs();

      if (_cachedSlipsDir != null && _cachedSlipsDir!.isNotEmpty) {
        final candidate1 = File('$_cachedSlipsDir/slip_${hash}_$safeBaseName');
        if (candidate1.existsSync() && candidate1.lengthSync() > 0) {
          return candidate1;
        }

        final candidate2 = File('$_cachedSlipsDir/slip_$hash.jpg');
        if (candidate2.existsSync() && candidate2.lengthSync() > 0) {
          return candidate2;
        }

        final candidate3 = File('$_cachedSlipsDir/$baseName');
        if (candidate3.existsSync() && candidate3.lengthSync() > 0) {
          return candidate3;
        }

        // Fuzzy match in saved_slips
        final dir = Directory(_cachedSlipsDir!);
        if (dir.existsSync()) {
          final list = dir.listSync();
          for (final f in list) {
            if (f is File && f.path.contains(baseName)) {
              return f;
            }
          }
        }
      }
    } catch (_) {}

    return null;
  }

  /// Checks if a slip image exists anywhere (either original or internal backup)
  static bool hasValidSlip(String? storedPath) {
    return resolveSlipFile(storedPath) != null;
  }

  /// Background migration: scans transactions and ensures all external slips have compressed backups
  static Future<void> autoBackupExistingSlips(
    List<TransactionItem> transactions,
    Future<void> Function(TransactionItem updated) onUpdateTransaction,
  ) async {
    final copyList = List<TransactionItem>.from(transactions);
    for (final tx in copyList) {
      if (tx.slipImageUrl != null && tx.slipImageUrl!.isNotEmpty) {
        final currentPath = tx.slipImageUrl!.replaceAll('\\', '/');
        if (!currentPath.contains('/saved_slips/')) {
          final file = File(tx.slipImageUrl!);
          if (await file.exists()) {
            final persistentPath = await persistSlipImage(tx.slipImageUrl!);
            if (persistentPath != tx.slipImageUrl) {
              final updated = tx.copyWith(slipImageUrl: persistentPath);
              await onUpdateTransaction(updated);
            }
          }
        }
      }
    }
  }
}
