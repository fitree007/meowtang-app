import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'storage_service.dart';
import 'native_bridge_service.dart';

class DataBackupService {
  static const String fileExtension = '.rizqi';
  static const int p2pPort = 8899;

  /// Generates the complete backup JSON payload from storage
  static String generateBackupJson(StorageService storage) {
    final map = storage.exportAllDataAsMap();
    final encoder = const JsonEncoder.withIndent('  ');
    return encoder.convert(map);
  }

  /// Creates a local .rizqi backup file in app storage and returns the File
  static Future<File> createBackupFile(StorageService storage) async {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd_HHmm').format(now);
    final fileName = 'Rizqi_Backup_$dateStr$fileExtension';

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    final jsonContent = generateBackupJson(storage);
    await file.writeAsString(jsonContent, encoding: utf8);
    return file;
  }

  /// Saves backup file directly to the device's public Downloads folder
  static Future<String?> saveBackupToDeviceDownloads(StorageService storage) async {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd_HHmm').format(now);
    final fileName = 'Rizqi_Backup_$dateStr$fileExtension';
    final jsonContent = generateBackupJson(storage);

    try {
      // 1. Try native method to save to Downloads
      final nativePath = await NativeBridgeService.saveBackupToDownloads(fileName, jsonContent);
      if (nativePath != null && nativePath.isNotEmpty) {
        return nativePath;
      }

      // 2. Fallback to app documents
      final docsDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${docsDir.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      final file = File('${backupDir.path}/$fileName');
      await file.writeAsString(jsonContent, encoding: utf8);
      return file.path;
    } catch (e) {
      debugPrint('Error saving backup to downloads: $e');
      return null;
    }
  }

  /// Shares backup file via Android Chooser (LINE, Drive, Email, Bluetooth, etc.)
  static Future<bool> shareBackupFile(File file) async {
    return await NativeBridgeService.shareBackupFile(
      file.path,
      title: 'สำรองข้อมูลเหมียวตังค์ (Rizqi Backup)',
    );
  }

  /// Opens native file picker to select a backup file (.rizqi or .json) and parses it
  static Future<Map<String, dynamic>?> pickAndParseBackupFile() async {
    try {
      final fileContent = await NativeBridgeService.pickBackupFile();
      if (fileContent == null || fileContent.trim().isEmpty) {
        return null;
      }
      return parseBackupJson(fileContent);
    } catch (e) {
      debugPrint('Error picking and parsing backup file: $e');
      return null;
    }
  }

  /// Parses and validates a backup JSON string
  static Map<String, dynamic>? parseBackupJson(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('transactions') || decoded.containsKey('accounts')) {
          return decoded;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Invalid JSON format: $e');
      return null;
    }
  }

  /// Gets the local Wi-Fi IPv4 address of this device
  static Future<String?> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && (addr.address.startsWith('192.168.') ||
              addr.address.startsWith('10.') ||
              addr.address.startsWith('172.'))) {
            return addr.address;
          }
        }
      }

      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        return interfaces.first.addresses.first.address;
      }
    } catch (e) {
      debugPrint('Error getting local IP: $e');
    }
    return null;
  }
}

/// Lightweight P2P Local HTTP Server for transferring data over local Wi-Fi / Hotspot
class DataTransferServer {
  HttpServer? _server;
  final StorageService storage;
  final String pinCode;

  DataTransferServer({required this.storage, required this.pinCode});

  bool get isRunning => _server != null;

  Future<int?> start() async {
    try {
      await stop();
      _server = await HttpServer.bind(InternetAddress.anyIPv4, DataBackupService.p2pPort);
      _server!.listen(_handleRequest);
      return _server!.port;
    } catch (e) {
      debugPrint('Error starting P2P server: $e');
      return null;
    }
  }

  void _handleRequest(HttpRequest request) async {
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', '*');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    if (request.uri.path == '/rizqi_backup') {
      final reqPin = request.uri.queryParameters['pin'];
      if (reqPin != null && reqPin != pinCode) {
        request.response.statusCode = HttpStatus.forbidden;
        request.response.write(jsonEncode({'error': 'Invalid PIN'}));
        await request.response.close();
        return;
      }

      final backupJson = DataBackupService.generateBackupJson(storage);
      request.response.headers.contentType = ContentType.json;
      request.response.statusCode = HttpStatus.ok;
      request.response.write(backupJson);
      await request.response.close();
    } else if (request.uri.path == '/ping') {
      request.response.headers.contentType = ContentType.json;
      request.response.statusCode = HttpStatus.ok;
      request.response.write(jsonEncode({'app': 'Rizqi', 'status': 'ready'}));
      await request.response.close();
    } else {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    }
  }

  Future<void> stop() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
  }
}

/// Client helper to download backup payload from a peer device over Wi-Fi
class DataTransferClient {
  static Future<Map<String, dynamic>?> fetchBackupFromUrl(String url) async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
      final uri = Uri.parse(url);
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == HttpStatus.ok) {
        final content = await response.transform(utf8.decoder).join();
        return DataBackupService.parseBackupJson(content);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching backup from peer: $e');
      return null;
    } finally {
      client?.close();
    }
  }
}
