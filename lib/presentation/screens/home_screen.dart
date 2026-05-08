import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            onPressed: () {
              context.read<AuthBloc>().add(AuthLoggedOut());
              Navigator.pushReplacementNamed(context, '/');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(child: Text("Welcome 👋")),
    );
  }
}
