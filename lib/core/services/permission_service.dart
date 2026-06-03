import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Camera (for scan QR)
  static Future<bool> requestCamera() async {
    final status = await Permission.camera.status;

    /// If permission is already granted, return true immediately.
    if (status.isGranted) return true;

    final result = await Permission.camera.request();

    /// If permission is granted after the request, return true.
    if (result.isGranted) return true;

    /// If permission is permanently denied, open app settings to allow the user to grant permission manually.
    if (result.isPermanentlyDenied) {
      await openAppSettings();
    }

    return false;
  }

  /// Storage / Photos (for save QR)
  static Future<bool> requestGallery() async {
    final status = await Permission.photos.status;

    if (status.isGranted) return true;

    final result = await Permission.photos.request();

    if (result.isGranted) return true;

    if (result.isPermanentlyDenied) {
      /// If permission is permanently denied, open app settings to allow the user to grant permission manually.
      await openAppSettings();
    }

    return false;
  }
}
