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
    Future.microtask(() {
      if (mounted) {
        context.read<AuthBloc>().add(AuthCheckRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        Widget child;

        if (state is AuthInitial) {
          child = Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Checking session...',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        } else if (state is AuthAuthenticated) {
          child = const HomeScreen();
        } else {
          child = const LoginScreen();
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: KeyedSubtree(key: ValueKey(state.runtimeType), child: child),
        );
      },
    );
  }
}
