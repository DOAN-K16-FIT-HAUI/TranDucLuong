import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/blocs/auth/auth_event.dart';
import 'package:finance_app/blocs/auth/auth_state.dart';
import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/utils/common_widget/app_bar_tab_bar.dart';
import 'package:finance_app/utils/common_widget/buttons.dart';
import 'package:finance_app/utils/common_widget/input_fields.dart';
import 'package:finance_app/utils/common_widget/utility_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _checkBiometrics(); // Kiểm tra sinh trắc học khi màn hình khởi tạo
  }

  // Kiểm tra và tự động đăng nhập bằng sinh trắc học nếu được bật
  Future<void> _checkBiometrics() async {
    final prefs = await SharedPreferences.getInstance();
    final isBiometricsEnabled = prefs.getBool('isBiometricsEnabled') ?? false;
    if (isBiometricsEnabled) {
      context.read<AuthBloc>().add(SignInWithBiometricsRequested(context: context));
    }
  }

  // Hàm đăng nhập bằng email/mật khẩu
  void _login() async {
    if (_formKey.currentState!.validate()) {
      // Lưu thông tin đăng nhập nếu người dùng chọn "Remember Password"
      if (_rememberPassword) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('lastEmail', _emailController.text.trim());
        await prefs.setString('lastPassword', _passwordController.text);
      }

      // Gửi sự kiện đăng nhập tới AuthBloc
      context.read<AuthBloc>().add(
        SignInRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBarTabBar.buildAppBar(
        context: context,
        title: l10n.loginTitle,
        showBackButton: false,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            AppRoutes.navigateToDashboard(context);
          } else if (state is AuthFailure) {
            UtilityWidgets.showCustomSnackBar(
              context: context,
              message: state.error(context),
              backgroundColor: Theme.of(context).colorScheme.error,
            );
          }
        },
        child: Container(
          color: Theme.of(context).colorScheme.surface,
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
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberPassword,
                        onChanged: (value) => setState(() {
                          _rememberPassword = value ?? false;
                        }),
                        activeColor: Theme.of(context).colorScheme.primary,
                        checkColor: Theme.of(context).colorScheme.onPrimary,
                        side: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      Text(
                        l10n.rememberPassword,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Buttons.buildSubmitButton(context, l10n.loginButton, _login),
                  const SizedBox(height: 15),
                  // Thêm nút đăng nhập bằng sinh trắc học
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        context.read<AuthBloc>().add(
                          SignInWithBiometricsRequested(context: context),
                        );
                      },
                      icon: Icon(
                        Icons.fingerprint,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(
                        l10n.loginWithBiometrics,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () =>
                            AppRoutes.navigateToForgotPassword(context),
                        child: Text(
                          l10n.forgotPasswordQuestion,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => AppRoutes.navigateToRegister(context),
                        child: Text(
                          l10n.registerButton,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.3),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          l10n.or,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.3),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Buttons.buildSocialLoginButton(
                        context: context,
                        onPressed: () => context.read<AuthBloc>().add(
                          const SignInWithFacebookRequested(),
                        ),
                        color: Theme.of(context).colorScheme.surface,
                        text: 'f',
                      ),
                      Buttons.buildSocialLoginButton(
                        context: context,
                        onPressed: () => context.read<AuthBloc>().add(
                          const SignInWithGoogleRequested(),
                        ),
                        color: Theme.of(context).colorScheme.surface,
                        text: 'G',
                        textColor: Theme.of(context).colorScheme.onSurface,
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