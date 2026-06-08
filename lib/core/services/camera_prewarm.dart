import 'package:mobile_scanner/mobile_scanner.dart';

class CameraPrewarmService {
  static final MobileScannerController controller = MobileScannerController(
    torchEnabled: false,
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
    autoZoom: false,
    facing: CameraFacing.back,
  );

  /// Prewarms the camera to reduce the delay when starting the scanner for the first time.
  static bool _isPrewarmed = false;

  static Future<void> prewarm() async {
    if (_isPrewarmed) return;
    try {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!controller.value.isRunning) {
        await controller.start();
        await Future.delayed(const Duration(milliseconds: 150));
        await controller.stop();
      }
      _isPrewarmed = true;
    } catch (_) {
      // Ignore any errors during prewarming, as it's not critical.
    }
  }
}
