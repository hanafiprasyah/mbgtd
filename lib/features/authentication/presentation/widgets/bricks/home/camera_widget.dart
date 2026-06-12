import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mbg_test/core/services/camera_prewarm.dart';

class CameraPrewarmWidget extends StatelessWidget {
  const CameraPrewarmWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: 0,
              child: SizedBox(
                width: 1,
                height: 1,
                child: MobileScanner(
                  controller: CameraPrewarmService.controller,
                ),
              ),
            ),
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 500),
              tween: Tween(begin: 0.8, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: const CircularProgressIndicator(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
