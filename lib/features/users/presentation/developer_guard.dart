import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/features/authentication/data/repositories/auth_repository.dart';
import 'package:mbg_test/features/users/data/repositories/user_repository.dart';
import 'package:mbg_test/features/authentication/presentation/screens/not_found_screen.dart';

class DeveloperRouteGuard extends StatelessWidget {
  final Widget child;
  const DeveloperRouteGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authRepo = context.read<AuthRepository>();
    final userRepo = context.read<UserRepository>();

    // Create a stream that emits the user's role whenever the auth state changes
    Stream<String?> getRoleStream() {
      return authRepo.user.asyncMap((firebaseUser) async {
        if (firebaseUser == null) return null;
        try {
          final userModel = await userRepo.getUserById(firebaseUser.uid);
          return userModel.role;
        } catch (e) {
          return null;
        }
      });
    }

    return StreamBuilder<String?>(
      stream: getRoleStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final role = snapshot.data;
        if (role == 'developer') return child;
        return const NotFoundPage();
      },
    );
  }
}
