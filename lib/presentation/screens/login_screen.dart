import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mbg_test/core/helper/design_system.dart';

import '../../logic/login/login_bloc.dart';
import '../../logic/login/login_event.dart';
import '../../logic/login/login_state.dart';
import '../../data/repositories/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordHidden = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginBloc(context.read<AuthRepository>()),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            maintainBottomViewPadding: true,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    top: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                      maxHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: BlocConsumer<LoginBloc, LoginState>(
                        listener: (context, state) {
                          if (state.error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(state.error!)),
                            );
                          }
                        },
                        builder: (context, state) {
                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Title
                                  Text(
                                    "MBGTD Apps",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    "Login to continue",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),

                                  const SizedBox(height: AppSpacing.xl),

                                  Form(
                                    key: _formKey,
                                    child: Column(
                                      children: [
                                        // EMAIL FIELD
                                        TextFormField(
                                          controller: _emailController,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          decoration: const InputDecoration(
                                            labelText: "Email",
                                            border: OutlineInputBorder(),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return "Email cannot be empty";
                                            }
                                            if (!value.contains('@')) {
                                              return "Invalid email format";
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        // PASSWORD FIELD
                                        TextFormField(
                                          controller: _passwordController,
                                          obscureText: _isPasswordHidden,
                                          textInputAction: TextInputAction.done,
                                          decoration: InputDecoration(
                                            labelText: "Password",
                                            border: const OutlineInputBorder(),
                                            suffixIcon: IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  _isPasswordHidden =
                                                      !_isPasswordHidden;
                                                });
                                              },
                                              icon: Icon(
                                                _isPasswordHidden
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                size: AppSpacing.lg,
                                              ),
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return "Password cannot be empty";
                                            }
                                            if (value.length < 6) {
                                              return "Minimum 6 characters required";
                                            }
                                            return null;
                                          },
                                          onFieldSubmitted: (_) {
                                            _submit(context, state);
                                          },
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () async {
                                              final email = _emailController
                                                  .text
                                                  .trim();

                                              if (email.isEmpty ||
                                                  !email.contains('@')) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "Please enter a valid email first",
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }

                                              try {
                                                await FirebaseAuth.instance
                                                    .sendPasswordResetEmail(
                                                      email: email,
                                                    );

                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "Password reset link has been sent to your email",
                                                    ),
                                                  ),
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      "Failed to send email: $e",
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            child: const Text(
                                              "Forgot Password?",
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: AppSpacing.md),

                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: state.isLoading
                                          ? null
                                          : () => _submit(context, state),
                                      child: state.isLoading
                                          ? const SizedBox(
                                              width: AppSpacing.lg,
                                              height: AppSpacing.lg,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text("Login"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _submit(BuildContext context, LoginState state) {
    if (_formKey.currentState!.validate()) {
      context.read<LoginBloc>().add(
        LoginSubmitted(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        ),
      );
    }
  }
}
