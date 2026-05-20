import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/presentation/widgets/login_form.dart';
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
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _showContent = true;
        });
      }
    });
  }

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
                    ),
                    child: BlocConsumer<LoginBloc, LoginState>(
                      buildWhen: (prev, curr) =>
                          prev.isLoading != curr.isLoading ||
                          prev.error != curr.error,
                      listener: (context, state) {
                        if (state.error != null) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(state.error!)));
                        }
                      },
                      builder: (context, state) {
                        return Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: _showContent
                                ? ConstrainedBox(
                                    key: const ValueKey('content'),
                                    constraints: const BoxConstraints(
                                      maxWidth: 420,
                                    ),
                                    child: LoginFormWidget(
                                      formKey: _formKey,
                                      emailController: _emailController,
                                      passwordController: _passwordController,
                                      isPasswordHidden: _isPasswordHidden,
                                      onTogglePassword: () {
                                        setState(() {
                                          _isPasswordHidden =
                                              !_isPasswordHidden;
                                        });
                                      },
                                      onSubmit: () => _submit(context, state),
                                      isLoading: state.isLoading,
                                    ),
                                  )
                                : const SizedBox(
                                    key: ValueKey('loader'),
                                    height: 80,
                                    width: 80,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                    ),
                                  ),
                          ),
                        );
                      },
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
      FocusScope.of(context).unfocus();
      context.read<LoginBloc>().add(
        LoginSubmitted(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        ),
      );
    }
  }
}
