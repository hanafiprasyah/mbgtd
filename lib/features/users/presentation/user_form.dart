import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/core/helper/global_scaffold_messenger.dart';
import 'package:mbg_test/features/users/bloc/user_bloc.dart';
import 'package:mbg_test/features/users/bloc/user_state.dart';
import 'package:mbg_test/features/users/bloc/user_event.dart';
import 'package:mbg_test/features/users/data/models/user_model.dart';

class UserFormPage extends StatefulWidget {
  final UserModel? existing;

  const UserFormPage({super.key, this.existing});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullnameController = TextEditingController();
  final _usernameController = TextEditingController();
  String _role = 'scanner';
  bool _hasUnsavedChanges = false;

  final List<String> _roles = [
    'aslap',
    'admin',
    'sppi',
    'accountant',
    'scanner',
    'nutritionist',
    'chef',
    'volunteer',
  ];

  // Validation regex patterns
  static final RegExp _usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp _fullnameRegex = RegExp(r"^[a-zA-Z\s.\'-]{2,50}$");

  @override
  void initState() {
    super.initState();
    _setupControllers();
  }

  void _setupControllers() {
    final existing = widget.existing;
    if (existing != null) {
      _emailController.text = existing.email;
      _fullnameController.text = existing.fullname;
      _usernameController.text = existing.username;
      _role = existing.role.isNotEmpty ? existing.role : _role;
    }

    // Listen for changes to track unsaved changes
    _emailController.addListener(_onFormChanged);
    _fullnameController.addListener(_onFormChanged);
    _usernameController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullnameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  String? _validateFullname(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    final trimmed = value.trim();
    if (!_fullnameRegex.hasMatch(trimmed)) {
      return 'Full name must be 2-50 characters and contain only letters, spaces, dots, apostrophes, or hyphens';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final email = value.trim();
    if (!_emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address (e.g., name@example.com)';
    }
    if (email.length > 100) {
      return 'Email must not exceed 100 characters';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    final username = value.trim();
    if (!_usernameRegex.hasMatch(username)) {
      return 'Username must be 3-20 characters and contain only letters, numbers, or underscores';
    }
    return null;
  }

  Future<bool> _onWillPop() async {
    if (!mounted) return true;
    if (!_hasUnsavedChanges) return true;
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Do you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final user = UserModel(
      id: widget.existing?.id ?? '',
      email: _emailController.text.trim().toLowerCase(), // Normalize email
      fullname: _fullnameController.text.trim(),
      username: _usernameController.text.trim().toLowerCase(),
      role: _role,
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? 'Edit User' : 'Add Staff User'),
          actions: [
            if (isEdit)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete User'),
                      content: const Text(
                        'Are you sure you want to delete this user? This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            final bloc = context.read<UserBloc>();
                            bloc.add(DeleteUser(widget.existing!.id));
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                tooltip: 'Delete user',
              ),
          ],
        ),
        body: BlocConsumer<UserBloc, UserState>(
          listener: (context, state) {
            if (state is UserSuccess) {
              GlobalScaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(
                    isEdit
                        ? 'User updated successfully'
                        : 'User created successfully',
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pop(context, state.user);
            }
            if (state is UserError) {
              GlobalScaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );
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
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.lg),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Form(
                            key: _formKey,
                            onChanged: () {
                              if (!_hasUnsavedChanges) {
                                setState(() => _hasUnsavedChanges = true);
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Full Name Field
                                TextFormField(
                                  controller: _fullnameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Full Name',
                                    prefixIcon: Icon(Icons.person_outline),
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  validator: _validateFullname,
                                  textInputAction: TextInputAction.next,
                                  enabled: !isLoading,
                                ),
                                const SizedBox(height: AppSpacing.md),

                                // Email Field
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email_outlined),
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  validator: _validateEmail,
                                  textInputAction: TextInputAction.next,
                                  enabled: !isLoading,
                                  autofillHints: const [AutofillHints.email],
                                ),
                                const SizedBox(height: AppSpacing.md),

                                // Username Field
                                TextFormField(
                                  controller: _usernameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Username',
                                    prefixIcon: Icon(Icons.alternate_email),
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Colors.white,
                                    helperText:
                                        '3-20 characters, letters, numbers, underscores only',
                                  ),
                                  validator: _validateUsername,
                                  textInputAction: TextInputAction.next,
                                  enabled: !isLoading,
                                  autofillHints: const [AutofillHints.username],
                                ),
                                const SizedBox(height: AppSpacing.md),

                                // Role Dropdown
                                DropdownButtonFormField<String>(
                                  initialValue: _roles.contains(_role)
                                      ? _role
                                      : _roles.first,
                                  decoration: const InputDecoration(
                                    labelText: 'Role',
                                    prefixIcon: Icon(Icons.badge_outlined),
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  items: _roles.map((value) {
                                    return DropdownMenuItem(
                                      value: value,
                                      child: Row(
                                        children: [
                                          Icon(
                                            _getRoleIcon(value),
                                            size: 18,
                                            color: _getRoleColor(value),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            value.toUpperCase(),
                                            style: TextStyle(
                                              fontWeight: value == _role
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: isLoading
                                      ? null
                                      : (value) {
                                          if (value != null && value != _role) {
                                            setState(() {
                                              _role = value;
                                              _hasUnsavedChanges = true;
                                            });
                                          }
                                        },
                                  isExpanded: true,
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                // Action Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: isLoading
                                            ? null
                                            : () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: isLoading ? null : _save,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(
                                            context,
                                          ).primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                        child: isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : Text(
                                                isEdit
                                                    ? 'Update User'
                                                    : 'Create User',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
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
                  ),
                ),
                if (isLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'accountant':
        return Icons.receipt_rounded;
      case 'sppi':
        return Icons.assignment_ind_rounded;
      case 'aslap':
        return Icons.analytics_rounded;
      case 'nutritionist':
        return Icons.health_and_safety_rounded;
      case 'chef':
        return Icons.local_dining_rounded;
      case 'volunteer':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.qr_code_scanner;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.blue;
      case 'accountant':
        return Colors.green;
      case 'sppi':
        return Colors.orange;
      case 'aslap':
        return Colors.purple;
      case 'nutritionist':
        return Colors.teal;
      case 'chef':
        return Colors.amber;
      case 'volunteer':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}
