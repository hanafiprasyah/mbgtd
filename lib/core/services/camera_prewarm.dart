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

  // Tracks an in-flight controller.start() call, if any.
  static Future<void>? _startingFuture;

  /// Single-flight camera start. ANY code that wants the camera running
  /// (warmBeforeNavigate, ScannerPage.initState, pointer-wake,
  /// didChangeAppLifecycleState resume, ...) must go through this instead
  /// of calling `controller.start()` directly.
  ///
  /// Why this exists: `controller.value.isRunning` only flips to true
  /// AFTER the native start() call resolves. If two callers both check
  /// `!isRunning` in that window and both call `start()`, mobile_scanner
  /// throws MobileScannerException ("Called start() while already
  /// started" / "still initializing"). This was firing release-only
  /// because release's faster frame timing made it common for
  /// ScannerPage.initState to run while warmBeforeNavigate's start() was
  /// still pending. Routing every caller through the same in-flight
  /// Future makes the race impossible instead of just narrowing it.
  static Future<void> ensureStarted() {
    if (controller.value.isRunning) return Future.value();
    return _startingFuture ??= _doStart();
  }

  static Future<void> _doStart() async {
    try {
      await controller.start();
    } finally {
      _startingFuture = null;
    }
  }

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
        await ensureStarted();
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
      await ensureStarted();
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
