import 'package:flutter/material.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/home_screen.dart';

class AppRoutes {
  static Route generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('404'))),
        );
    }
  }
}
