import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CameraPrewarmService {
  CameraPrewarmService._();

  static final MobileScannerController controller = MobileScannerController(
    torchEnabled: false,
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
    autoZoom: false,
    facing: CameraFacing.back,
  );

  static bool _isPrewarmed = false;
  static bool _isWarming = false;

  /// Optional hook so the UI layer can react to a failed prewarm/start
  /// (e.g. show a snackbar) instead of it dying silently like before.
  static void Function(String stage, Object error)? onError;

  /// Cheap best-effort nudge, called once from HomeScreen.initState.
  /// Warms the OS-level camera driver so later starts are faster, then
  /// stops again to avoid keeping the sensor + privacy indicator alive
  /// while the user is just sitting on the dashboard.
  static Future<void> prewarm() async {
    if (_isPrewarmed || _isWarming) return;
    _isWarming = true;
    try {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!controller.value.isRunning) {
        await controller.start();
        await Future.delayed(const Duration(milliseconds: 150));
        await controller.stop();
      }
      _isPrewarmed = true;
    } on MobileScannerException catch (e) {
      _reportError('prewarm', e);
    } catch (e) {
      _reportError('prewarm', e);
    } finally {
      _isWarming = false;
    }
  }

  /// THE key fix: call this the instant the user taps "Scan" / the QR
  /// icon — BEFORE Navigator.push. It's fire-and-forget on purpose: the
  /// camera boot (300-600ms) then overlaps with the page transition
  /// animation instead of happening after ScannerPage is already on
  /// screen. This is what makes the open feel instant, like Shopee/Gojek.
  static void warmBeforeNavigate() {
    if (controller.value.isRunning || _isWarming) return;
    unawaited(_startSafely('warmBeforeNavigate'));
  }

  static Future<void> _startSafely(String stage) async {
    try {
      await controller.start();
    } on MobileScannerException catch (e) {
      _reportError(stage, e);
    } catch (e) {
      _reportError(stage, e);
    }
  }

  static void _reportError(String stage, Object error) {
    // Replace with your logger / Crashlytics. The old code used
    // `catch (_) {}` here, so camera failures on real devices were
    // completely invisible — you'd only ever see "black screen".
    debugPrint('[CameraPrewarmService:$stage] $error');
    onError?.call(stage, error);
  }
}
