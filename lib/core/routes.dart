import 'package:flutter/material.dart';
import 'package:mbg_test/auth_gate.dart';
import 'package:mbg_test/features/users/presentation/developer_guard.dart';
import 'package:mbg_test/features/authentication/presentation/screens/home_screen.dart';
import 'package:mbg_test/features/users/data/models/user_model.dart';
import 'package:mbg_test/features/users/presentation/user_detail.dart';
import 'package:mbg_test/features/users/presentation/user_form.dart';
import 'package:mbg_test/features/users/presentation/user_list.dart';
import 'package:mbg_test/features/authentication/presentation/screens/not_found_screen.dart';
import 'package:mbg_test/features/volunteer/data/models/volunteer_model.dart';
import 'package:mbg_test/features/attendance/presentation/pages/payroll_page.dart';
import 'package:mbg_test/features/attendance/presentation/pages/scanner_page.dart';
import 'package:mbg_test/features/attendance/presentation/pages/qr_generator_page.dart';
import 'package:mbg_test/features/volunteer/presentation/pages/volunteer_form_page.dart';
import 'package:mbg_test/features/volunteer/presentation/pages/volunteer_list_page.dart';
import 'package:mbg_test/features/attendance/presentation/pages/payroll_detail_page.dart';
import 'package:mbg_test/features/attendance/presentation/pages/payroll_history_page.dart';
import 'package:mbg_test/features/volunteer/presentation/pages/volunteer_detail_page.dart';

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
      case '/payroll-detail-page':
        final id = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => PayrollDetailPage(id: id),
          settings: settings,
        );
      case '/payroll-history':
        return MaterialPageRoute(builder: (_) => const PayrollHistoryPage());
      case '/manage-users':
        return MaterialPageRoute(
          builder: (_) => DeveloperRouteGuard(child: const UserListPage()),
        );
      case '/user-add':
        return MaterialPageRoute(
          builder: (_) => DeveloperRouteGuard(child: const UserFormPage()),
          settings: settings,
        );
      case '/user-edit':
        final user = settings.arguments as UserModel;
        return MaterialPageRoute(
          builder: (_) =>
              DeveloperRouteGuard(child: UserFormPage(existing: user)),
          settings: settings,
        );
      case '/user-detail':
        final id = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => DeveloperRouteGuard(child: UserDetailPage(id: id)),
          settings: settings,
        );
      default:
        return MaterialPageRoute(builder: (_) => const NotFoundPage());
    }
  }
}
