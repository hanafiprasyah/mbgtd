import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/core/services/permission_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../bloc/attendance_bloc.dart';
import '../../bloc/attendance_event.dart';
import '../../bloc/attendance_state.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool isScanning = false;
  bool isProcessing = false;
  final MobileScannerController _controller = MobileScannerController(
    torchEnabled: false,
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
    autoZoom: true,
  );
  DateTime? _lastScanTime;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _cameraStarted = false;
  late Future<bool> _permissionFuture;
  bool _isTorchOn = false;
  String? _lastScannedQR;

  @override
  void initState() {
    super.initState();
    _permissionFuture = PermissionService.requestCamera();
  }

  Future<void> _handleBackAction() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        // Ensure widget tree (MobileScanner) is fully attached
        await Future.delayed(const Duration(milliseconds: 300));

        if (!mounted) return;

        try {
          await _controller.start();
          _cameraStarted = true;
        } catch (_) {
          // Retry once if controller not yet attached
          await Future.delayed(const Duration(milliseconds: 200));
          if (!mounted) return;
          await _controller.start();
          _cameraStarted = true;
        }
      });
    }
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

              _handleBackAction();
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

              _handleBackAction();

              Future.microtask(() async {
                if (!mounted) return;
                try {
                  await _controller.start();
                } catch (_) {}
              });

              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  setState(() {
                    isScanning = false;
                    isProcessing = false;
                  });
                }
              });
            }
          },
          child: Stack(
            children: [
              RepaintBoundary(
                child: MobileScanner(
                  controller: _controller,
                  onDetect: (barcodeCapture) async {
                    if (isScanning) return;

                    final now = DateTime.now();
                    if (_lastScanTime != null &&
                        now.difference(_lastScanTime!) <
                            const Duration(milliseconds: 300)) {
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

                    // 🚀 NEW: cegah scan QR yang sama

                    if (_lastScannedQR == raw) return;
                    _lastScannedQR = raw;

                    setState(() {
                      isScanning = true;
                      isProcessing = true;
                    });

                    if (await Vibration.hasVibrator()) {
                      Vibration.vibrate(duration: 200);
                    }

                    await _audioPlayer.play(AssetSource('notif.wav'));

                    if (!mounted) return;
                    await _controller.stop();

                    if (!mounted) return;
                    context.read<AttendanceBloc>().add(ScanQR(raw));
                  },
                ),
              ),
              // Overlay box
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Positioned(
                bottom: 32,
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
        );
      },
    );
  }
}
