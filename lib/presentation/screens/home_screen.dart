import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/features/volunteer/presentation/pages/volunteer_list_page.dart';
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
            },

            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          const Center(child: Text("Welcome!")),
          SizedBox(height: 20),
          ElevatedButton(
            child: Text('Go to volunteer list'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VolunteerListPage()),
            ),
          ),
        ],
      ),
    );
  }
}
