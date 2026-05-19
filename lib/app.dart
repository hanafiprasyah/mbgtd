import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/core/routes.dart';
import 'package:mbg_test/features/attendance/bloc/attendance_bloc.dart';
import 'package:mbg_test/features/attendance/data/repositories/attendance_repository.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_bloc.dart';
import 'package:mbg_test/features/volunteer/data/repositories/volunteer_repository.dart';
import 'package:mbg_test/logic/auth/auth_event.dart';

import 'logic/auth/auth_bloc.dart';
import 'logic/auth/auth_state.dart';
import 'data/repositories/auth_repository.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/home_screen.dart';

import "package:mbg_test/core/helper/design_system.dart";

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => VolunteerRepository()),
        RepositoryProvider(create: (_) => AttendanceRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(context.read<AuthRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                VolunteerBloc(context.read<VolunteerRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                AttendanceBloc(context.read<AttendanceRepository>()),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          onGenerateRoute: AppRoutes.generateRoute,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blueAccent,
              primary: Colors.blueAccent,
              secondary: const Color(0xFF90CAF9), // soft blue
              surface: Colors.white,
            ),
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              centerTitle: true,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.blueAccent.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
                borderSide: BorderSide(color: Colors.blueAccent, width: 1.5),
              ),
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.black87),
              titleLarge: TextStyle(fontWeight: FontWeight.bold),
            ),
            cardTheme: CardThemeData(
              elevation: AppElevation.medium,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
          home: const AuthGate(),
        ),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(AuthCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is AuthAuthenticated) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
