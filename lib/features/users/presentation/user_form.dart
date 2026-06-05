import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import '../bloc/user_bloc.dart';
import '../bloc/user_event.dart';
import '../bloc/user_state.dart';
import '../data/models/user_model.dart';

class UserFormPage extends StatefulWidget {
  final UserModel? existing;

  const UserFormPage({super.key, this.existing});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final fullnameController = TextEditingController();
  final usernameController = TextEditingController();
  String role = 'scanner';

  final List<String> roles = [
    'aslap',
    'admin',
    'superadmin',
    'sppi',
    'accountant',
    'scanner',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final existing = widget.existing;
    if (existing != null) {
      emailController.text = existing.email;
      fullnameController.text = existing.fullname;
      usernameController.text = existing.username;
      role = existing.role.isNotEmpty ? existing.role : role;
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    fullnameController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  void save() {
    if (!_formKey.currentState!.validate()) return;

    final user = UserModel(
      id: widget.existing?.id ?? '',
      email: emailController.text.trim(),
      fullname: fullnameController.text.trim(),
      username: usernameController.text.trim(),
      role: role,
    );

    final bloc = context.read<UserBloc>();
    if (widget.existing == null) {
      bloc.add(AddUser(user));
    } else {
      bloc.add(UpdateUser(user));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit User' : 'Add User')),
      body: BlocConsumer<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isEdit
                      ? 'User updated successfully'
                      : 'User created successfully',
                ),
              ),
            );
            Navigator.pop(context, state.user);
          }
          if (state is UserError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final isLoading = state is UserLoading;
          return Stack(
            children: [
              SingleChildScrollView(
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: fullnameController,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter full name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter email';
                                  }
                                  final email = value.trim();
                                  final validEmail = RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  );
                                  if (!validEmail.hasMatch(email)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter username';
                                  }
                                  if (value.trim().length < 3) {
                                    return 'Username must be at least 3 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              DropdownButtonFormField<String>(
                                initialValue: roles.contains(role)
                                    ? role
                                    : roles.first,
                                decoration: const InputDecoration(
                                  labelText: 'Role',
                                ),
                                items: roles
                                    .map(
                                      (value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(value.toUpperCase()),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => role = value);
                                  }
                                },
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              ElevatedButton(
                                onPressed: isLoading ? null : save,
                                child: Text(
                                  isEdit ? 'Update User' : 'Create User',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.08),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}
