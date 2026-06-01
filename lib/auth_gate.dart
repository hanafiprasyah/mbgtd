import 'logic/auth/auth_bloc.dart';
import 'logic/auth/auth_state.dart';
import 'package:flutter/material.dart';
import 'presentation/screens/home_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'presentation/screens/login_screen.dart';
import 'package:mbg_test/logic/auth/auth_event.dart';

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
