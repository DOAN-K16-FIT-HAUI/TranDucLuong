import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/blocs/auth/auth_event.dart';
import 'package:finance_app/blocs/auth/auth_state.dart';
import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/utils/common_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ForgotPasswordScreenState createState() => ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _resetPassword() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        PasswordResetRequested(email: _emailController.text.trim()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => AppRoutes.navigateToLogin(context),
        ),
        title: Text('Quên mật khẩu'),
        centerTitle: true,
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        foregroundColor: AppTheme.lightTheme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoading) {
            _showLoadingDialog(context);
          } else if (state is AuthInitial) {
            _handleAuthInitial(context);
          } else if (state is AuthFailure) {
            _handleAuthFailure(context, state.error);
          }
        },
        child: Container(
          color: AppTheme.lightTheme.colorScheme.surface,
          height: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Nhập email để khôi phục mật khẩu',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                CommonWidgets.buildEmailField(_emailController),
                const SizedBox(height: 20),
                CommonWidgets.buildSubmitButton('Xác nhận', _resetPassword),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _handleAuthInitial(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Yêu cầu đặt lại mật khẩu đã được gửi đến email của bạn!',
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      ),
    );
    AppRoutes.navigateToLogin(context);
  }

  void _handleAuthFailure(BuildContext context, String error) {
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lỗi: $error'),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
      ),
    );
  }
}
