import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import '../bloc/user_bloc.dart';
import '../bloc/user_event.dart';
import '../bloc/user_state.dart';
import '../data/models/user_model.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final searchController = TextEditingController();
  final List<String> roles = [
    'aslap',
    'admin',
    'superadmin',
    'sppi',
    'accountant',
    'scanner',
  ];
  String? selectedRole;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<UserBloc>().add(LoadUser());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<UserBloc>().add(SearchUser(value, selectedRole));
    });
  }

  Future<void> _showRoleFilterDialog() async {
    String? tempRole = selectedRole;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Filter Users'),
          content: DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: tempRole,
            decoration: const InputDecoration(labelText: 'Role'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All roles')),
              ...roles.map(
                (role) => DropdownMenuItem(
                  value: role,
                  child: Text(role.toUpperCase()),
                ),
              ),
            ],
            onChanged: (value) {
              tempRole = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                tempRole = null;
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Reset'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      if (!mounted) return;
      setState(() {
        selectedRole = tempRole;
      });
      context.read<UserBloc>().add(
        SearchUser(searchController.text, selectedRole),
      );
    }
  }

  Future<bool> _confirmDelete(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete user'),
          content: Text(
            'Are you sure you want to delete ${user.fullname}? This action cannot be undone.',
          ),
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

    return confirm == true;
  }

  @override
  Widget build(BuildContext context) {
    final roleChip = selectedRole != null && selectedRole!.isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        title: const Text('Manage Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by role',
            onPressed: _showRoleFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add user',
            onPressed: () => Navigator.pushNamed(context, '/user-add'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Search by name, email, username, role',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            selectedRole = null;
                          });
                          context.read<UserBloc>().add(LoadUser());
                        },
                      )
                    : null,
              ),
            ),
            if (roleChip)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text(selectedRole!.toUpperCase()),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () {
                      setState(() {
                        selectedRole = null;
                      });
                      context.read<UserBloc>().add(
                        SearchUser(searchController.text, null),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: BlocConsumer<UserBloc, UserState>(
                listener: (context, state) {
                  if (state is UserError) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(state.message)));
                  }
                  if (state is UserSuccess) {
                    final message = state.user == null
                        ? 'User deleted successfully'
                        : 'User saved successfully';
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(message)));
                  }
                },
                builder: (context, state) {
                  if (state is UserLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is UserLoaded) {
                    if (state.users.isEmpty) {
                      return const Center(child: Text('No users found.'));
                    }
                    return ListView.builder(
                      itemCount: state.users.length,
                      itemBuilder: (context, index) {
                        final user = state.users[index];

                        final initials = user.fullname.isNotEmpty
                            ? user.fullname
                                  .trim()
                                  .split(' ')
                                  .map((e) => e.isNotEmpty ? e[0] : '')
                                  .take(2)
                                  .join()
                                  .toUpperCase()
                            : '?';

                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            final bloc = context.read<UserBloc>();
                            await Navigator.pushNamed(
                              context,
                              '/user-detail',
                              arguments: user.id,
                            );
                            if (!mounted) return;
                            bloc.add(LoadUser());
                          },
                          child: Container(
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).cardColor.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.15),
                                  child: Text(
                                    initials,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.fullname,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.email_outlined,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              user.email,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.badge_outlined,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            user.role.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      tooltip: 'Edit user',
                                      onPressed: () async {
                                        final bloc = context.read<UserBloc>();
                                        await Navigator.pushNamed(
                                          context,
                                          '/user-edit',
                                          arguments: user,
                                        );
                                        if (!mounted) return;
                                        bloc.add(LoadUser());
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip: 'Delete user',
                                      color: Colors.redAccent,
                                      onPressed: () async {
                                        if (!mounted) return;
                                        final localBloc = context
                                            .read<UserBloc>();
                                        final confirmed = await _confirmDelete(
                                          user,
                                        );
                                        if (!mounted) return;
                                        if (confirmed) {
                                          localBloc.add(DeleteUser(user.id));
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                  if (state is UserError) {
                    return Center(child: Text(state.message));
                  }
                  return const Center(child: Text('Loading users...'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
