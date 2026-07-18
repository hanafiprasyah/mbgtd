import 'package:flutter/material.dart';

/// A [ScaffoldMessenger] that can be accessed without a widget [BuildContext].
///
/// Import this file from any feature, then use for example:
/// `GlobalScaffoldMessenger.showSnackBar(const SnackBar(...))`.
class GlobalScaffoldMessenger {
  GlobalScaffoldMessenger._();

  static final GlobalKey<ScaffoldMessengerState> key =
      GlobalKey<ScaffoldMessengerState>();

  static void showSnackBar(SnackBar snackBar) {
    final messenger = key.currentState;
    if (messenger == null) {
      debugPrint('Global ScaffoldMessenger is not ready yet.');
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static void hideCurrentSnackBar() {
    key.currentState?.hideCurrentSnackBar();
  }
}
