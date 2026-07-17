import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/core/services/camera_prewarm.dart';
import 'package:mbg_test/core/services/permission_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../bloc/attendance_bloc.dart';
import '../../bloc/attendance_event.dart';
import '../../bloc/attendance_state.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mbg_test/core/helper/design_system.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final MobileScannerController _controller =
      CameraPrewarmService.controller;
  bool isScanning = false;
  bool isProcessing = false;
  DateTime? _lastScanTime;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _unlockTimer;

  late Future<bool> _permissionFuture;
  bool _isTorchOn = false;
  String? _lastScannedQR;

  // NEW: surfaces camera-start failures instead of swallowing them.
  String? _cameraError;

  Timer? _idleTimer;
  static const Duration _idleDuration = Duration(seconds: 10);

  // UI-only: drives the animated scan line on the viewfinder.
  late final AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _permissionFuture = PermissionService.requestCamera();
    _initCameraUltraFast();
    _resetIdleTimer();
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();

    _idleTimer = Timer(_idleDuration, () {
      if (!mounted) return;

      if (_controller.value.isRunning) {
        _controller.stop(); // smart pause
      }
    });
  }

  Future<void> _initCameraUltraFast() async {
    try {
      final granted = await _permissionFuture;
      if (!granted) return;

      // In the normal flow this is a no-op: CameraPrewarmService.warmBeforeNavigate()
      // (called from wherever "Scan" was tapped) should already have this running
      // by the time we get here. This is just the safety net for deep links / cold
      // starts that skip that step.
      if (mounted && !_controller.value.isRunning) {
        await _controller.start();
      }
      if (mounted && _cameraError != null) {
        setState(() => _cameraError = null);
      }
    } on MobileScannerException catch (e) {
      if (!mounted) return;
      setState(() => _cameraError = _describeCameraError(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _cameraError = 'Kamera gagal diaktifkan. Coba lagi.');
    }
  }

  String _describeCameraError(MobileScannerException e) {
    switch (e.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Izin kamera ditolak.';
      case MobileScannerErrorCode.unsupported:
        return 'Perangkat ini tidak mendukung kamera untuk scan QR.';
      default:
        return 'Kamera gagal diaktifkan. Coba lagi.';
    }
  }

  Future<void> _retryCamera() async {
    setState(() => _cameraError = null);
    await _initCameraUltraFast();
  }

  Future<void> _handleBackAction() async {
    if (!mounted) return;
    // Do NOT stop camera here → keep it alive for next page / next visit.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Explicit black background: no default-canvas flash while the
      // permission FutureBuilder or the camera texture is still booting.
      backgroundColor: Colors.black,
      body: FutureBuilder<bool>(
        future: _permissionFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const _BootingPlaceholder();
          }

          if (!snapshot.data!) {
            return _PermissionDeniedView(
              onRetry: () {
                setState(() {
                  _permissionFuture = PermissionService.requestCamera();
                });
              },
            );
          }

          return BlocListener<AttendanceBloc, AttendanceState>(
            listener: (context, state) {
              if (state is AttendanceSuccess) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('Scan successful! Attendance recorded'),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );

                setState(() {
                  isProcessing = false;
                });

                Future.microtask(() async {
                  if (!mounted) return;
                  await _handleBackAction();
                });
              }

              if (state is AttendanceError) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Scan failed: ${state.message}')),
                      ],
                    ),
                    backgroundColor: const Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );

                Future.microtask(() async {
                  if (!mounted) return;
                  await _handleBackAction();
                });
              }
            },
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) async {
                _resetIdleTimer();
                if (!_controller.value.isRunning) {
                  try {
                    await _controller.start();
                    if (mounted && _cameraError != null) {
                      setState(() => _cameraError = null);
                    }
                  } on MobileScannerException catch (e) {
                    if (!mounted) return;
                    setState(() => _cameraError = _describeCameraError(e));
                  } catch (_) {
                    // Non-fatal: user can still tap the frame again.
                  }
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _resetIdleTimer,
                onPanDown: (_) => _resetIdleTimer(),
                child: Stack(
                  children: [
                    if (_cameraError != null)
                      _CameraErrorView(
                        message: _cameraError!,
                        onRetry: _retryCamera,
                        onBack: _handleBackAction,
                      )
                    else ...[
                      RepaintBoundary(
                        child: MobileScanner(
                          controller: _controller,
                          fit: BoxFit.cover,
                          tapToFocus: true,
                          useAppLifecycleState: false,
                          errorBuilder: (context, error) {
                            // mobile_scanner's own render-time error path —
                            // previously unhandled, so a texture failure
                            // here just rendered as a blank black surface.
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              setState(
                                () =>
                                    _cameraError = _describeCameraError(error),
                              );
                            });
                            return const _BootingPlaceholder();
                          },
                          placeholderBuilder: (context) =>
                              const _BootingPlaceholder(),
                          onDetect: (barcodeCapture) async {
                            _resetIdleTimer();
                            if (isScanning) return;

                            final now = DateTime.now();
                            if (_lastScanTime != null &&
                                now.difference(_lastScanTime!) <
                                    const Duration(milliseconds: 200)) {
                              return;
                            }
                            _lastScanTime = now;

                            final barcode = barcodeCapture.barcodes.first;
                            final raw =
                                barcode.rawValue ?? barcode.displayValue;

                            if (raw == null ||
                                raw.trim().isEmpty ||
                                raw.trim() == '||') {
                              return;
                            }

                            if (_lastScannedQR == raw) return;
                            _lastScannedQR = raw;

                            setState(() {
                              isScanning = true;
                              isProcessing = true;
                            });

                            if (await Vibration.hasVibrator()) {
                              Vibration.vibrate(duration: 120);
                            }

                            unawaited(
                              _audioPlayer.play(AssetSource('notif.wav')),
                            );

                            if (!mounted) return;
                            context.read<AttendanceBloc>().add(ScanQR(raw));

                            _unlockTimer?.cancel();
                            _unlockTimer = Timer(
                              const Duration(milliseconds: 300),
                              () {
                                if (!mounted) return;
                                setState(() {
                                  isScanning = false;
                                  isProcessing = false;
                                });
                              },
                            );
                          },
                        ),
                      ),
                      // --- Modern viewfinder: dim mask + corner brackets + scan line ---
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _scanLineController,
                            builder: (context, _) {
                              return CustomPaint(
                                painter: _ScannerOverlayPainter(
                                  scanLineValue: _scanLineController.value,
                                  isProcessing: isProcessing,
                                  frameRadius: 24,
                                  frameSize: 260,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],

                    // --- Top bar: gradient backdrop + back button + title ---
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: SizedBox(
                          height: 130,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.black54, Colors.transparent],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              _FrostedIconButton(
                                icon: Icons.arrow_back_ios_new,
                                onTap: isProcessing ? null : _handleBackAction,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // --- Bottom controls: frosted torch toggle ---
                    if (_cameraError == null)
                      Positioned(
                        bottom: AppSpacing.lg,
                        left: 0,
                        right: 0,
                        child: SafeArea(
                          child: Center(
                            child: _FrostedIconButton(
                              icon: _isTorchOn
                                  ? Icons.flash_on
                                  : Icons.flash_off,
                              active: _isTorchOn,
                              size: 56,
                              onTap: () {
                                _controller.toggleTorch();
                                setState(() {
                                  _isTorchOn = !_isTorchOn;
                                });
                              },
                            ),
                          ),
                        ),
                      ),

                    // Processing overlay
                    if (isProcessing)
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.25),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _unlockTimer?.cancel();
    _audioPlayer.dispose();
    _scanLineController.dispose();
    // NO dispose controller here (shared via CameraPrewarmService)
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!mounted || !_controller.value.isInitialized) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _resetIdleTimer();
        if (!_controller.value.isRunning) {
          _controller.start().catchError((e) {
            if (!mounted) return;
            setState(
              () => _cameraError = 'Kamera gagal diaktifkan. Coba lagi.',
            );
          });
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _idleTimer?.cancel();
        if (_controller.value.isRunning) {
          try {
            _controller.stop();
          } catch (_) {}
        }
        break;
      default:
        break;
    }
  }
}

/// Shown while the camera texture hasn't produced its first frame yet.
/// Matches the viewfinder's dark theme instead of a bare spinner on a
/// mismatched background — this is what covers the (now much shorter)
/// gap instead of a flash of black.
class _BootingPlaceholder extends StatelessWidget {
  const _BootingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Izin kamera dibutuhkan untuk memindai QR.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text(
                'Kembali',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
              TextButton(
                onPressed: onBack,
                child: const Text(
                  'Kembali',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Frosted-glass circular icon button used for the back and torch controls.
/// Purely presentational — no business logic lives here.
class _FrostedIconButton extends StatelessWidget {
  const _FrostedIconButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: disabled ? 0.4 : 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: active
                ? Colors.amber.withValues(alpha: 0.85)
                : Colors.black.withValues(alpha: 0.35),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: size,
                height: size,
                child: Icon(icon, color: Colors.white, size: size * 0.42),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the dim mask, corner brackets, and animated scan line for the
/// QR viewfinder. Purely presentational — no scanning logic lives here.
class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter({
    required this.scanLineValue,
    required this.isProcessing,
    required this.frameSize,
    required this.frameRadius,
  });

  final double scanLineValue;
  final bool isProcessing;
  final double frameSize;
  final double frameRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final frameRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: frameSize,
      height: frameSize,
    );

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(frameRect, Radius.circular(frameRadius)),
      );
    final maskPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      holePath,
    );
    canvas.drawPath(
      maskPath,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    final accent = isProcessing ? const Color(0xFF34D399) : Colors.white;
    final bracketPaint = Paint()
      ..color = accent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const bracketLength = 28.0;

    void drawL(Offset start, Offset corner, Offset end) {
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(corner.dx, corner.dy)
        ..lineTo(end.dx, end.dy);
      canvas.drawPath(path, bracketPaint);
    }

    drawL(
      Offset(frameRect.left, frameRect.top + bracketLength),
      frameRect.topLeft,
      Offset(frameRect.left + bracketLength, frameRect.top),
    );
    drawL(
      Offset(frameRect.right - bracketLength, frameRect.top),
      frameRect.topRight,
      Offset(frameRect.right, frameRect.top + bracketLength),
    );
    drawL(
      Offset(frameRect.left, frameRect.bottom - bracketLength),
      frameRect.bottomLeft,
      Offset(frameRect.left + bracketLength, frameRect.bottom),
    );
    drawL(
      Offset(frameRect.right - bracketLength, frameRect.bottom),
      frameRect.bottomRight,
      Offset(frameRect.right, frameRect.bottom - bracketLength),
    );

    if (!isProcessing) {
      final lineY =
          frameRect.top + 16 + (frameRect.height - 32) * scanLineValue;
      final lineRect = Rect.fromLTWH(
        frameRect.left + 12,
        lineY,
        frameRect.width - 24,
        3,
      );
      final shader = LinearGradient(
        colors: [
          accent.withValues(alpha: 0),
          accent.withValues(alpha: 0.9),
          accent.withValues(alpha: 0),
        ],
      ).createShader(lineRect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(lineRect, const Radius.circular(2)),
        Paint()..shader = shader,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanLineValue != scanLineValue ||
        oldDelegate.isProcessing != isProcessing;
  }
}
