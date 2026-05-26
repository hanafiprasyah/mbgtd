import 'dart:async';

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

class _ScannerPageState extends State<ScannerPage> with WidgetsBindingObserver {
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
                const SnackBar(
                  content: Text('Scan successful! Attendance recorded'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
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
                  content: Text('Scan failed: ${state.message}'),
                  backgroundColor: Colors.red,
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
                  // Overlay box
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isProcessing
                              ? Colors.greenAccent
                              : Colors.white,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: AppSpacing.lg,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isTorchOn ? Icons.flash_on : Icons.flash_off,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              _controller.toggleTorch();
                              setState(() {
                                _isTorchOn = !_isTorchOn;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Loading indicator
                  if (isProcessing)
                    const Positioned.fill(
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
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
