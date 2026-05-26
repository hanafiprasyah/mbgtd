import 'package:mobile_scanner/mobile_scanner.dart';

class CameraPrewarmService {
  static final MobileScannerController controller = MobileScannerController(
    torchEnabled: false,
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
    autoZoom: true,
    facing: CameraFacing.back,
    // Khusus OPPO
    // facing: CameraFacing.front,
    lensType: CameraLensType.normal,
  );

  static bool _isPrewarmed = false;

  static Future<void> prewarm() async {
    if (_isPrewarmed) return;
    try {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!controller.value.isRunning) {
        await controller.start();
        await Future.delayed(const Duration(milliseconds: 200));
        await controller.stop();
      }
      _isPrewarmed = true;
    } catch (_) {}
  }
}
