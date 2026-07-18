import 'package:mbg_test/app.dart';
import 'package:mbg_test/core/helper/global_scaffold_messenger.dart';
import 'package:flutter/material.dart';
import 'package:mbg_test/core/services/camera_prewarm.dart';
import 'package:mbg_test/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load();

  CameraPrewarmService.onError = (stage, error) {
    debugPrint('Camera error at $stage: $error');

    GlobalScaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Camera failed during $stage. Please try again.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  };

  runApp(const MyApp());
}
