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
      // wait permission first
      final granted = await _permissionFuture;
      if (!granted) return;

      // tiny delay to let widget mount cleanly
      // await Future.delayed(const Duration(milliseconds: 50));
      if (mounted && !_controller.value.isRunning) {
        await _controller.start();
      }

      // Khusus OPPO
      // if (mounted && !_controller.value.isRunning) {
      //   try {
      //     await _controller.start();
      //   } catch (_) {}
      // }
    } catch (_) {}
  }

  Future<void> _handleBackAction() async {
    if (!mounted) return;

    // Khusus OPPO: stop camera immediately to free up resources for next page (avoid black screen)
    // try {
    //   await _controller.stop();
    //   if (!mounted) return;
    //   Navigator.of(context).pop();
    // } catch (_) {}

    // Do NOT stop camera here → keep it alive for next page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _permissionFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.data!) {
          return const Center(child: Text('Camera permission denied'));
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
                try {} catch (_) {}
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
                try {} catch (_) {}
                if (!mounted) return;
                await _handleBackAction();
              });
            }
          },
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) async {
              _resetIdleTimer();

              // 🔥 Predictive wake: start camera instantly on first touch
              if (!_controller.value.isRunning) {
                try {
                  await _controller.start();
                } catch (_) {}
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _resetIdleTimer,
              onPanDown: (_) => _resetIdleTimer(),
              child: Stack(
                children: [
                  RepaintBoundary(
                    child: MobileScanner(
                      controller: _controller,
                      fit: BoxFit.cover,
                      tapToFocus: true,
                      // Khusus OPPO
                      // useAppLifecycleState: true,
                      useAppLifecycleState: false,
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
                        // Prefer rawValue, fallback to displayValue (iOS safe)
                        final raw = barcode.rawValue ?? barcode.displayValue;

                        // Guard invalid / empty payloads (e.g. "||", null)
                        if (raw == null ||
                            raw.trim().isEmpty ||
                            raw.trim() == '||') {
                          return;
                        }

                        // 🚀 NEW: avoid scan same QR
                        if (_lastScannedQR == raw) return;
                        _lastScannedQR = raw;

                        setState(() {
                          isScanning = true;
                          isProcessing = true;
                        });

                        if (await Vibration.hasVibrator()) {
                          Vibration.vibrate(duration: 120);
                        }

                        // await _audioPlayer.play(AssetSource('notif.wav'));
                        // feedback fire instantly without holding the pipeline
                        unawaited(_audioPlayer.play(AssetSource('notif.wav')));

                        if (!mounted) return;
                        context.read<AttendanceBloc>().add(ScanQR(raw));

                        // cancel previous unlock timer (avoid stacking timers)
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

                  // Helper label under the frame
                  Align(
                    alignment: const Alignment(0, 0.34),
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isProcessing ? 0 : 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Fit QR Code on the box',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

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
                            const SizedBox(width: 12),
                            const Text(
                              'Scan QR Code',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // --- Bottom controls: frosted torch toggle ---
                  Positioned(
                    bottom: AppSpacing.lg,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Center(
                        child: _FrostedIconButton(
                          icon: _isTorchOn ? Icons.flash_on : Icons.flash_off,
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
                                  SizedBox(height: 12),
                                  Text(
                                    'Processing...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
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
          try {
            _controller.start();
          } catch (_) {}
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

    // Dim everything outside the scan frame.
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

    // Corner brackets — color reflects scanning vs. processing state.
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

    // Animated scan line — only while actively scanning, not processing.
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
