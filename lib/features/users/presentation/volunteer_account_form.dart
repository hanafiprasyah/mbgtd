import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/core/helper/global_scaffold_messenger.dart';
import 'package:mbg_test/features/users/bloc/volunteer_account_bloc.dart';
import 'package:mbg_test/features/users/bloc/volunteer_account_event.dart';
import 'package:mbg_test/features/users/bloc/volunteer_account_state.dart';
import 'package:mbg_test/features/users/data/services/volunteer_auth_service.dart';
import 'package:mbg_test/features/volunteer/data/repositories/volunteer_repository.dart';

/// One-shot flow: admin picks an existing volunteer (one that has no login
/// yet), fills in login details, and submitting does everything in the
/// app — creates the Firebase Auth account, the `users` document (role
/// fixed to `volunteer`), and links it back to the chosen `volunteers`
/// document. No manual Firebase Console steps required.
class VolunteerAccountFormPage extends StatefulWidget {
  const VolunteerAccountFormPage({super.key});

  @override
  State<VolunteerAccountFormPage> createState() =>
      _VolunteerAccountFormPageState();
}

class _VolunteerAccountFormPageState extends State<VolunteerAccountFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullnameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _volunteerRepository = VolunteerRepository();
  final _authService = VolunteerAuthService();

  String? _selectedVolunteerId;
  bool _obscurePassword = true;

  static final RegExp _usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp _fullnameRegex = RegExp(r"^[a-zA-Z\s.\'-]{2,50}$");

  @override
  void dispose() {
    _emailController.dispose();
    _fullnameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateFullname(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (!_fullnameRegex.hasMatch(value.trim())) {
      return 'Full name must be 2-50 characters (letters, spaces, . \' - only)';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) return 'Username is required';
    if (!_usernameRegex.hasMatch(value.trim())) {
      return 'Username must be 3-20 characters (letters, numbers, underscore)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  void _generatePassword() {
    setState(() {
      _passwordController.text = _authService.generateRandomPassword();
      _obscurePassword = false;
    });
  }

  void _submit(BuildContext context) {
    if (_selectedVolunteerId == null) {
      GlobalScaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Please select a volunteer first.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    context.read<VolunteerAccountBloc>().add(
      SubmitVolunteerAccount(
        volunteerId: _selectedVolunteerId!,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullname: _fullnameController.text.trim(),
        username: _usernameController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VolunteerAccountBloc(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Add Volunteer Account')),
        body: BlocConsumer<VolunteerAccountBloc, VolunteerAccountState>(
          listener: (context, state) {
            if (state is VolunteerAccountSuccess) {
              GlobalScaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Volunteer login created and linked successfully',
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pop(context, state.user);
            }
            if (state is VolunteerAccountError) {
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
            final isLoading = state is VolunteerAccountSubmitting;
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Info banner
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.lg,
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.volunteer_activism_rounded,
                                        size: 18,
                                        color: Colors.teal,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "Creates a Firebase Authentication login, a 'users' record with role 'volunteer', and links it to the volunteer you pick below — all in one step.",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.teal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),

                                // Volunteer picker: only volunteers without a
                                // linked account show up here.
                                StreamBuilder<List<Map<String, dynamic>>>(
                                  stream: _volunteerRepository
                                      .getUnlinkedVolunteers(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }

                                    final volunteers = snapshot.data!;

                                    if (volunteers.isEmpty) {
                                      return Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.lg,
                                          ),
                                        ),
                                        child: const Text(
                                          "All volunteers already have a linked login account. Add a new volunteer record first.",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      );
                                    }

                                    // Guard against the currently selected
                                    // volunteer disappearing from this list
                                    // (e.g. it just got linked by this very
                                    // submit, and the widget rebuilds once
                                    // more before the page pops). Never pass
                                    // a `value` that isn't in `items` this
                                    // frame — that's exactly what
                                    // DropdownButtonFormField asserts on and
                                    // crashes over.
                                    final validSelectedId =
                                        _selectedVolunteerId != null &&
                                            volunteers.any(
                                              (v) =>
                                                  v['id'] ==
                                                  _selectedVolunteerId,
                                            )
                                        ? _selectedVolunteerId
                                        : null;

                                    if (_selectedVolunteerId != null &&
                                        validSelectedId == null) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            if (mounted) {
                                              setState(
                                                () =>
                                                    _selectedVolunteerId = null,
                                              );
                                            }
                                          });
                                    }

                                    return DropdownButtonFormField<String>(
                                      initialValue: validSelectedId,
                                      decoration: const InputDecoration(
                                        labelText: 'Select Volunteer',
                                        prefixIcon: Icon(Icons.people_outline),
                                        border: OutlineInputBorder(),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                      isExpanded: true,
                                      items: volunteers.map((v) {
                                        final tim = v['tim'] as String;
                                        final label = tim.isNotEmpty
                                            ? '${v['namaLengkap']} ($tim)'
                                            : v['namaLengkap'] as String;
                                        return DropdownMenuItem<String>(
                                          value: v['id'] as String,
                                          child: Text(
                                            label,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: isLoading
                                          ? null
                                          : (value) {
                                              final selected = volunteers
                                                  .firstWhere(
                                                    (v) => v['id'] == value,
                                                  );
                                              setState(() {
                                                _selectedVolunteerId = value;
                                                if (_fullnameController.text
                                                    .trim()
                                                    .isEmpty) {
                                                  _fullnameController.text =
                                                      selected['namaLengkap']
                                                          as String;
                                                  _usernameController.text =
                                                      (selected['namaLengkap']
                                                              as String)
                                                          .toLowerCase()
                                                          .replaceAll(
                                                            RegExp(
                                                              r'[^a-z0-9_]',
                                                            ),
                                                            '_',
                                                          );
                                                }
                                              });
                                            },
                                      validator: (value) => value == null
                                          ? 'Please select a volunteer'
                                          : null,
                                    );
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),

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
                                    helperText: 'Used to log in to the app',
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

                                // Password Field
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    border: const OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Colors.white,
                                    helperText:
                                        'Minimum 6 characters. Share this with the volunteer.',
                                    suffixIcon: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                          onPressed: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.autorenew),
                                          tooltip: 'Generate random password',
                                          onPressed: isLoading
                                              ? null
                                              : _generatePassword,
                                        ),
                                      ],
                                    ),
                                  ),
                                  validator: _validatePassword,
                                  textInputAction: TextInputAction.done,
                                  enabled: !isLoading,
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
                                        onPressed: isLoading
                                            ? null
                                            : () => _submit(context),
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
                                            : const Text(
                                                'Create Account',
                                                style: TextStyle(
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
}
