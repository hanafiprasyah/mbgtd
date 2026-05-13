import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Camera (untuk QR Scanner)
  static Future<bool> requestCamera() async {
    final status = await Permission.camera.status;

    if (status.isGranted) return true;

    final result = await Permission.camera.request();

    if (result.isGranted) return true;

    if (result.isPermanentlyDenied) {
      await openAppSettings();
    }

    return false;
  }

  /// Storage / Photos (untuk save QR)
  static Future<bool> requestGallery() async {
    final status = await Permission.photos.status;

    if (status.isGranted) return true;

    final result = await Permission.photos.request();

    if (result.isGranted) return true;

    if (result.isPermanentlyDenied) {
      await openAppSettings();
    }

    return false;
  }
}
