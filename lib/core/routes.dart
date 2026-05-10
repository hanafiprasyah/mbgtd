import 'package:flutter/material.dart';
import 'package:mbg_test/features/volunteer/presentation/pages/volunteer_form_page.dart';
import 'package:mbg_test/features/volunteer/presentation/pages/volunteer_list_page.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/home_screen.dart';

class AppRoutes {
  static Route generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/volunteers':
        return MaterialPageRoute(builder: (_) => const VolunteerListPage());
      case '/volunteer-add':
        return MaterialPageRoute(builder: (_) => const VolunteerFormPage());
      // case '/volunteers-detail':
      //   return MaterialPageRoute(builder: (_) => const VolunteerDetailPage());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('404'))),
        );
    }
  }
}
