import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/core/helper/global_scaffold_messenger.dart';
import 'package:mbg_test/features/authentication/logic/auth/auth_bloc.dart';
import 'package:mbg_test/features/authentication/logic/auth/auth_event.dart';
import 'package:mbg_test/core/helper/design_system.dart';

Widget buildLogoutButton(BuildContext context) {
  final cs = Theme.of(context).colorScheme;

  return SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmation'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: cs.error),
                child: const Text('I\'m Sure'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          if (context.mounted) {
            GlobalScaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Logging out...'),
                duration: Duration(milliseconds: 1500),
              ),
            );
            context.read<AuthBloc>().add(AuthLoggedOut());
          }
        }
      },
      icon: const Icon(Icons.logout),
      label: const Text("Logout"),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: cs.errorContainer,
        foregroundColor: cs.onErrorContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
  );
}
