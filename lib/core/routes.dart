import 'package:flutter/material.dart';
import 'package:mbg_test/app.dart';
import 'package:mbg_test/features/attendance/presentation/pages/payroll_history_page.dart';
import 'package:mbg_test/features/attendance/presentation/pages/payroll_page.dart';
import 'package:mbg_test/features/attendance/presentation/pages/qr_generator_page.dart';
import 'package:mbg_test/features/attendance/presentation/pages/scanner_page.dart';
import 'package:mbg_test/features/volunteer/presentation/pages/volunteer_detail_page.dart';
import 'package:mbg_test/features/volunteer/presentation/pages/volunteer_form_page.dart';
import 'package:mbg_test/features/volunteer/presentation/pages/volunteer_list_page.dart';
import '../features/volunteer/data/models/volunteer_model.dart';
import '../presentation/screens/home_screen.dart';

class AppRoutes {
  static Route generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const AuthGate());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/volunteers':
        return MaterialPageRoute(builder: (_) => const VolunteerListPage());
      case '/volunteer-add':
        return MaterialPageRoute(
          builder: (_) => const VolunteerFormPage(),
          settings: settings,
        );
      case '/volunteer-detail':
        return MaterialPageRoute(
          builder: (_) => const VolunteerDetailPage(),
          settings: settings,
        );
      case '/qr-generator':
        final volunteer = settings.arguments as Volunteer;
        return MaterialPageRoute(
          builder: (_) => QrGeneratorPage(
            id: volunteer.id,
            nama: volunteer.namaLengkap,
            tim: volunteer.tim,
          ),
          settings: settings,
        );
      case '/qr-scanner':
        return MaterialPageRoute(builder: (_) => const ScannerPage());
      case '/payroll':
        return MaterialPageRoute(builder: (_) => const PayrollPage());
      case '/payroll-history':
        return MaterialPageRoute(builder: (_) => const PayrollHistoryPage());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('404. Route not found!')),
          ),
        );
    }
  }
}
