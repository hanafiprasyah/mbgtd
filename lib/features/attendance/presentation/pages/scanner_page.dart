import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/core/services/permission_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../bloc/attendance_bloc.dart';
import '../../bloc/attendance_event.dart';
import '../../bloc/attendance_state.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool isScanning = false;

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
            if (state is AttendanceSuccess || state is AttendanceError) {
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
            onDetect: (barcodeCapture) {
              if (isScanning) return;

              final barcode = barcodeCapture.barcodes.first;
              final raw = barcode.rawValue;

              if (raw != null) {
                setState(() {
                  isScanning = true;
                });

                context.read<AttendanceBloc>().add(ScanQR(raw));
              }
            },
          ),
        );
      },
    );
  }
}
