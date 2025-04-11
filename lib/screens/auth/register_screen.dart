import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/blocs/auth/auth_event.dart';
import 'package:finance_app/blocs/auth/auth_state.dart';
import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/utils/common_widget/app_bar_tab_bar.dart';
import 'package:finance_app/utils/common_widget/buttons.dart';
import 'package:finance_app/utils/common_widget/input_fields.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Thêm import l10n

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  void _register() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        SignUpRequested(
          email: _emailController.text,
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Lấy l10n
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      appBar: AppBarTabBar.buildAppBar(
        context: context,
        title: l10n.registerTitle, // Sử dụng l10n
        showBackButton: true,
        onBackPressed: () => AppRoutes.navigateToLogin(context),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            AppRoutes.navigateToDashboard(context);
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error(context)), // Gọi error(context)
                backgroundColor: AppTheme.lightTheme.colorScheme.error,
              ),
            );
          }
        },
        child: Container(
          color: AppTheme.lightTheme.colorScheme.surface,
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  InputFields.buildEmailField(controller: _emailController),
                  const SizedBox(height: 15),
                  InputFields.buildPasswordField(
                    _passwordController,
                    _isPasswordVisible,
                        () => setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    }),
                  ),
                  const SizedBox(height: 15),
                  Buttons.buildSubmitButton(
                    context,
                    l10n.createAccountButton, // Sử dụng l10n
                    _register,
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        text: l10n.alreadyHaveAccount, // Sử dụng l10n
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                        children: [
                          TextSpan(
                            text: l10n.loginNow, // Sử dụng l10n
                            style: TextStyle(
                              color: AppTheme.lightTheme.colorScheme.primary,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => AppRoutes.navigateToLogin(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}