import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mbg_test/core/helper/global_scaffold_messenger.dart';
import 'package:mbg_test/core/services/permission_service.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'dart:typed_data';

class QrGeneratorPage extends StatefulWidget {
  final String id;
  final String nama;
  final String tim;

  const QrGeneratorPage({
    super.key,
    required this.id,
    required this.nama,
    required this.tim,
  });

  @override
  State<QrGeneratorPage> createState() => _QrGeneratorPageState();
}

class _QrGeneratorPageState extends State<QrGeneratorPage>
    with SingleTickerProviderStateMixin {
  final repaintKey = GlobalKey();

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get qrData {
    final id = widget.id.trim();
    final nama = widget.nama.trim();
    final tim = widget.tim.trim();
    final data = "$id|$nama|$tim";

    return data;
  }

  Future<void> saveQr() async {
    final hasPermission = await PermissionService.requestGallery();
    final status = await Permission.storage.request();

    if (!hasPermission && !status.isGranted) return;

    final boundary =
        repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    final image = await boundary.toImage(pixelRatio: 5);
    final byteData = await image.toByteData(format: ImageByteFormat.png);

    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    final result = await ImageGallerySaverPlus.saveImage(
      pngBytes,
      name: "qr_${widget.nama}_${DateTime.now().millisecondsSinceEpoch}",
      quality: 100,
    );

    if (mounted) {
      GlobalScaffoldMessenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text(
            result['isSuccess'] == true
                ? 'QR saved to gallery'
                : 'Failed to save QR, please check your permission.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Code')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Header Info
              Column(
                children: [
                  Text(
                    widget.nama,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.tim,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),

              const Spacer(),

              // Animated QR Card
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: RepaintBoundary(
                    key: repaintKey,
                    child: PrettyQrView.data(
                      data: qrData,
                      decoration: const PrettyQrDecoration(
                        quietZone: PrettyQrQuietZone.standard,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saveQr,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Save QR to Gallery'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
