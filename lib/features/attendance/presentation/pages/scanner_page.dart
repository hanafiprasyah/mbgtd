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
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: PermissionService.requestCamera(),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Scan successful! Attendance recorded'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );

              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              });
            }

            if (state is AttendanceError) {
              Navigator.of(context).popUntil((route) => route.isFirst);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Scan failed: ${state.message}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );

              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  setState(() {
                    isScanning = false;
                  });
                }
              });
            }
          },
          child: MobileScanner(
            onDetect: (barcodeCapture) async {
              if (isScanning) return;

              final barcode = barcodeCapture.barcodes.first;
              // Prefer rawValue, fallback to displayValue (iOS safe)
              final raw = barcode.rawValue ?? barcode.displayValue;

              // Guard invalid / empty payloads (e.g. "||", null)
              if (raw == null || raw.trim().isEmpty || raw.trim() == '||') {
                return;
              }

              if (await Vibration.hasVibrator()) {
                Vibration.vibrate(duration: 200);
              }

              setState(() {
                isScanning = true;
              });

              await _audioPlayer.play(AssetSource('notif.wav'));

              context.read<AttendanceBloc>().add(ScanQR(raw));
            },
          ),
        );
      },
    );
  }
}
