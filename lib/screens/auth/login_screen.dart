import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/blocs/auth/auth_event.dart';
import 'package:finance_app/blocs/auth/auth_state.dart';
import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/utils/common_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _rememberPassword = false;

  void _login() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        SignInRequested(
          email: _emailController.text,
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      appBar: CommonWidgets.buildAppBar(
        context: context,
        title: 'Đăng nhập',
        showBackButton: false,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            AppRoutes.navigateToDashboard(context);
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
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
                  CommonWidgets.buildEmailField(controller: _emailController),
                  const SizedBox(height: 15),
                  CommonWidgets.buildPasswordField(
                    _passwordController,
                    _isPasswordVisible,
                    () => setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    }),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberPassword,
                        onChanged:
                            (value) => setState(() {
                              _rememberPassword = value ?? false;
                            }),
                        activeColor: AppTheme.lightTheme.colorScheme.primary,
                      ),
                      Text(
                        'Ghi nhớ mật khẩu?',
                        style: TextStyle(
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  CommonWidgets.buildSubmitButton('Đăng nhập', _login, context),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed:
                            () => AppRoutes.navigateToForgotPassword(context),
                        child: Text(
                          'Quên mật khẩu?',
                          style: TextStyle(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => AppRoutes.navigateToRegister(context),
                        child: Text(
                          'Đăng ký',
                          style: TextStyle(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Hoặc',
                          style: TextStyle(
                            color: AppTheme.lightTheme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      CommonWidgets.buildSocialLoginButton(
                        context: context,
                        onPressed:
                            () => context.read<AuthBloc>().add(
                              const SignInWithFacebookRequested(),
                            ),
                        color: AppTheme.lightTheme.colorScheme.primary,
                        text: 'f',
                      ),
                      CommonWidgets.buildSocialLoginButton(
                        context: context,
                        onPressed:
                            () => context.read<AuthBloc>().add(
                              const SignInWithGoogleRequested(),
                            ),
                        color: Colors.white,
                        text: 'G',
                        textColor: Colors.black,
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
