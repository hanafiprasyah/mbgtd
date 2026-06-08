import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mbg_test/core/helper/design_system.dart';

class LoginFormWidget extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isPasswordHidden;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final bool isLoading;

  bool _isValidEmail(String value) {
    final v = value.trim();
    // Simple, pragmatic email check for UX; Firebase will ultimately validate.
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(v);
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  const LoginFormWidget({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isPasswordHidden,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title
        Text(
          "MBGTD Apps",
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.xs),

        Text(
          "Login to continue",
          style: Theme.of(context).textTheme.bodyMedium,
        ),

        const SizedBox(height: AppSpacing.xl),

        Form(
          key: formKey,
          child: Column(
            children: [
              /// EMAIL
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Email cannot be empty";
                  }
                  if (!_isValidEmail(value)) {
                    return "Invalid email format";
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.sm),

              /// PASSWORD
              TextFormField(
                controller: passwordController,
                obscureText: isPasswordHidden,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: "Password",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: onTogglePassword,
                    icon: Icon(
                      isPasswordHidden
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: AppSpacing.lg,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Password cannot be empty";
                  }
                  if (value.length < 6) {
                    return "Minimum 6 characters required";
                  }
                  return null;
                },
                onFieldSubmitted: (_) => onSubmit(),
              ),

              const SizedBox(height: AppSpacing.sm),

              /// FORGOT PASSWORD
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    final email = emailController.text.trim();

                    if (email.isEmpty || !_isValidEmail(email)) {
                      _showSnackBar(
                        context,
                        "Please enter a valid email first",
                      );
                      return;
                    }

                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(
                        email: email,
                      );
                    } catch (_) {
                      // Intentionally ignore the specific error to avoid leaking
                      // account existence / backend details.
                    }

                    if (context.mounted) {
                      _showSnackBar(
                        context,
                        "If the email exists, we sent a password reset link.",
                      );
                    }
                  },

                  child: const Text("Forgot Password?"),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        /// BUTTON
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
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
    );
  }
}
