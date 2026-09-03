import 'package:flutter/services.dart';

typedef OnSlipDetectedCallback = void Function(Map<String, dynamic> slipData);
typedef OnDataReloadCallback = void Function();

class NativeBridgeService {
  static const MethodChannel _channel = MethodChannel('com.afitree.rizqi/native');
  static OnSlipDetectedCallback? _slipListener;
  static OnSlipDetectedCallback? _openSlipListener;
  static OnDataReloadCallback? _dataReloadListener;
  static bool _isListenerInitialized = false;

  static void initMethodCallHandler() {
    if (_isListenerInitialized) return;
    _isListenerInitialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNewSlipDetected') {
        if (call.arguments is Map) {
          final data = Map<String, dynamic>.from(call.arguments as Map);
          _slipListener?.call(data);
        }
      } else if (call.method == 'onOpenSlipFromNotification') {
        if (call.arguments is Map) {
          final data = Map<String, dynamic>.from(call.arguments as Map);
          _openSlipListener?.call(data);
        }
      } else if (call.method == 'onVoiceTransactionAdded' || call.method == 'onAppResumed') {
        _dataReloadListener?.call();
      }
    });
  }

  static void setSlipDetectedListener(OnSlipDetectedCallback listener) {
    initMethodCallHandler();
    _slipListener = listener;
  }

  static void setOpenSlipFromNotificationListener(OnSlipDetectedCallback listener) {
    initMethodCallHandler();
    _openSlipListener = listener;
  }

  static void setDataReloadListener(OnDataReloadCallback listener) {
    initMethodCallHandler();
    _dataReloadListener = listener;
  }

  /// Gets the slip path passed via PendingIntent when app was launched from notification
  static Future<String?> getInitialSlipPath() async {
    try {
      final String? path = await _channel.invokeMethod('getInitialSlipPath');
      return path;
    } catch (_) {
      return null;
    }
  }

  /// Requests actual Android runtime permissions from OS (Storage/Media, Audio, Camera)
  static Future<Map<String, dynamic>> requestAppPermissions() async {
    try {
      final res = await _channel.invokeMethod('requestAppPermissions');
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
      return {'allGranted': true};
    } catch (e) {
      return {'allGranted': true, 'error': e.toString()};
    }
  }

  /// Checks current permission status
  static Future<Map<String, dynamic>> checkAppPermissions() async {
    try {
      final res = await _channel.invokeMethod('checkAppPermissions');
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
      return {'allGranted': true};
    } catch (e) {
      return {'allGranted': true};
    }
  }

  /// Starts real-time MediaStore ContentObserver & Foreground Service
  static Future<bool> startMediaObserver() async {
    try {
      initMethodCallHandler();
      final res = await _channel.invokeMethod('startMediaObserver');
      return res == true;
    } catch (e) {
      return false;
    }
  }

  /// Starts Foreground Service explicitly
  static Future<bool> startBackgroundService() async {
    try {
      final res = await _channel.invokeMethod('startBackgroundService');
      return res == true;
    } catch (e) {
      return false;
    }
  }

  /// Stops background observer
  static Future<bool> stopMediaObserver() async {
    try {
      final res = await _channel.invokeMethod('stopMediaObserver');
      return res == true;
    } catch (e) {
      return false;
    }
  }

  /// Saves an exported file (PDF, CSV, Excel) to the public Downloads/MeowTang folder
  static Future<String?> saveExportFile({
    required String fileName,
    Uint8List? bytes,
    String? content,
    String subDir = 'MeowTang',
  }) async {
    try {
      final String? path = await _channel.invokeMethod('saveExportFile', {
        'fileName': fileName,
        if (bytes != null) 'bytes': bytes,
        if (content != null) 'content': content,
        'subDir': subDir,
      });
      return path;
    } catch (e) {
      return null;
    }
  }

  /// Opens file with the default system application (e.g. PDF viewer, Excel, etc.)
  static Future<bool> openFile(String filePath) async {
    try {
      final res = await _channel.invokeMethod('openFile', {'filePath': filePath});
      return res == true;
    } catch (e) {
      return false;
    }
  }

  /// Shares a file via Android system share chooser
  static Future<bool> shareFile(String filePath, {String title = 'แชร์ไฟล์รายงานเหมียวตังค์'}) async {
    try {
      final res = await _channel.invokeMethod('shareFile', {
        'filePath': filePath,
        'title': title,
      });
      return res == true;
    } catch (e) {
      return false;
    }
  }

  /// Shares backup file via Android Intent
  static Future<bool> shareBackupFile(String filePath, {String title = 'สำรองข้อมูลเหมียวตังค์'}) async {
    try {
      final res = await _channel.invokeMethod('shareBackupFile', {
        'filePath': filePath,
        'title': title,
      });
      return res == true;
    } catch (e) {
      return false;
    }
  }

  /// Picks a backup file from device storage
  static Future<String?> pickBackupFile() async {
    try {
      final String? content = await _channel.invokeMethod('pickBackupFile');
      return content;
    } catch (e) {
      return null;
    }
  }

  /// Saves backup content string to Downloads folder
  static Future<String?> saveBackupToDownloads(String fileName, String content) async {
    try {
      final String? path = await _channel.invokeMethod('saveBackupToDownloads', {
        'fileName': fileName,
        'content': content,
      });
      return path;
    } catch (e) {
      return null;
    }
  }

  /// Shares CSV file via Android Intent
  static Future<bool> shareCsvFile(String filePath) async {
    return shareFile(filePath, title: 'ส่งออกรายงานเหมียวตังค์');
  }

  /// Launches native image picker
  static Future<String?> pickImageFromGallery() async {
    try {
      final String? path = await _channel.invokeMethod('pickImage');
      return path;
    } catch (e) {
      return null;
    }
  }

  /// Automatically scans phone storage & bank folders for recent bank slip images
  static Future<List<Map<String, dynamic>>> scanBankSlips({int daysLimit = 30}) async {
    try {
      final res = await _channel.invokeMethod('scanBankSlips', {'daysLimit': daysLimit});
      if (res is List) {
        return res.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Detects installed banking apps on the user's phone
  static Future<List<Map<String, String>>> getInstalledBankingApps() async {
    try {
      final res = await _channel.invokeMethod('getInstalledBankingApps');
      if (res is List) {
        return res.map((item) => Map<String, String>.from(item as Map)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Starts native in-app Thai speech recognition
  static Future<String?> startVoiceRecognition() async {
    try {
      final String? text = await _channel.invokeMethod('startVoiceRecognition');
      return text;
    } catch (e) {
      return null;
    }
  }

  /// Stops in-app speech recognition listening
  static Future<void> stopVoiceRecognition() async {
    try {
      await _channel.invokeMethod('stopVoiceRecognition');
    } catch (_) {}
  }

  /// Processes slip image pixels via Google ML Kit Barcode (QR) & Thai OCR Text Recognition
  static Future<Map<String, dynamic>> processSlipImage(String filePath) async {
    try {
      final res = await _channel.invokeMethod('processSlipImage', {'filePath': filePath});
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
      return {};
    } catch (e) {
      return {'error': e.toString(), 'qrPayload': '', 'ocrText': ''};
    }
  }

  /// Checks if Android Notification Listener Access is granted
  static Future<bool> isNotificationListenerGranted() async {
    try {
      final res = await _channel.invokeMethod('isNotificationListenerGranted');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  /// Opens Android Notification Listener Access Settings screen
  static Future<bool> openNotificationListenerSettings() async {
    try {
      final res = await _channel.invokeMethod('openNotificationListenerSettings');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  /// Compresses and saves slip image to app private sandbox directory (saved_slips)
  static Future<String?> compressAndSaveSlip(String filePath, {String? fileName}) async {
    try {
      final res = await _channel.invokeMethod('compressAndSaveSlip', {
        'filePath': filePath,
        if (fileName != null) 'fileName': fileName,
      });
      if (res is String && res.isNotEmpty) {
        return res;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
