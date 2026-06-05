import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import '../bloc/user_bloc.dart';
import '../bloc/user_event.dart';
import '../bloc/user_state.dart';
import '../data/models/user_model.dart';
import 'user_form.dart';

class UserDetailPage extends StatefulWidget {
  final String id;

  const UserDetailPage({super.key, required this.id});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<UserBloc>().add(GetUserById(widget.id));
  }

  Future<bool> _confirmDelete(UserModel user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete user'),
          content: Text('Delete ${user.fullname}? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Details')),
      body: BlocConsumer<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is UserSuccess && state.user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User deleted successfully')),
            );
            Navigator.pop(context, true);
          }
        },
        builder: (context, state) {
          if (state is UserLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is UserDetailLoaded) {
            final user = state.user;
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.lg),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            user.fullname,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Role: ${user.role.toUpperCase()}'),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Email: ${user.email}'),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Username: ${user.username}'),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit'),
                                  onPressed: () async {
                                    if (!mounted) return;
                                    final localBloc = context.read<UserBloc>();
                                    final updated = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            UserFormPage(existing: user),
                                      ),
                                    );
                                    if (!mounted) return;
                                    if (updated != null) {
                                      localBloc.add(GetUserById(widget.id));
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Delete'),
                                  onPressed: () async {
                                    if (!mounted) return;
                                    final localBloc = context.read<UserBloc>();
                                    final confirmed = await _confirmDelete(
                                      user,
                                    );
                                    if (!mounted) return;
                                    if (confirmed) {
                                      localBloc.add(DeleteUser(user.id));
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          if (state is UserError) {
            return Center(child: Text(state.message));
          }
          return const Center(child: Text('Waiting for user details...'));
        },
      ),
    );
  }
}
