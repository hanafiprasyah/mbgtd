import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/login/login_bloc.dart';
import '../../logic/login/login_event.dart';
import '../../logic/login/login_state.dart';
import '../../data/repositories/auth_repository.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return BlocProvider(
      create: (_) => LoginBloc(context.read<AuthRepository>()),
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: BlocListener<LoginBloc, LoginState>(
            listener: (context, state) {
              if (state.error == null && !state.isLoading) {
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(controller: emailController),
                TextField(controller: passwordController, obscureText: true),
                const SizedBox(height: 20),
                BlocBuilder<LoginBloc, LoginState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () {
                              context.read<LoginBloc>().add(
                                LoginSubmitted(
                                  emailController.text,
                                  passwordController.text,
                                ),
                              );
                            },
                      child: state.isLoading
                          ? const CircularProgressIndicator()
                          : const Text("Login"),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
