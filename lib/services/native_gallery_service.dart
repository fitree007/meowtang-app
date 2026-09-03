import 'native_bridge_service.dart';

class NativeGalleryService {
  /// Opens the device's native photo gallery and returns the chosen image file path
  static Future<String?> pickImageFromGallery() async {
    return await NativeBridgeService.pickImageFromGallery();
  }
}
