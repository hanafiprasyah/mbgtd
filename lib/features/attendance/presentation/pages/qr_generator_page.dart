import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

class _QrGeneratorPageState extends State<QrGeneratorPage> {
  final repaintKey = GlobalKey();

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

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['isSuccess'] == true
                ? 'QR saved to gallery'
                : 'Failed to save QR',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Code')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RepaintBoundary(
            key: repaintKey,
            child: PrettyQrView.data(
              data: qrData,
              decoration: const PrettyQrDecoration(
                quietZone: PrettyQrQuietZone.standard,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: saveQr,
            child: const Text('Save to Gallery'),
          ),
        ],
      ),
    );
  }
}
