import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/blocs/auth/auth_event.dart';
import 'package:finance_app/blocs/auth/auth_state.dart';
import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/utils/common_widget/app_bar_tab_bar.dart';
import 'package:finance_app/utils/common_widget/buttons.dart';
import 'package:finance_app/utils/common_widget/input_fields.dart';
import 'package:finance_app/utils/common_widget/utility_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBarTabBar.buildAppBar(
        context: context,
        title: l10n.forgotPasswordTitle,
        showBackButton: true,
        onBackPressed: () => AppRoutes.navigateToLogin(context),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  l10n.enterEmailToResetPassword,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                InputFields.buildEmailField(controller: _emailController),
                const SizedBox(height: 20),
                Buttons.buildSubmitButton(
                  context,
                  l10n.confirm,
                  _resetPassword,
                ),
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
      builder: (_) => Center(
        child: UtilityWidgets.buildLoadingIndicator(context: context),
      ),
    );
  }

  void _handleAuthInitial(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context, rootNavigator: true).pop();
    UtilityWidgets.showCustomSnackBar(
      context: context,
      message: l10n.passwordResetRequestSent,
      backgroundColor: AppTheme.incomeColor,
    );
    AppRoutes.navigateToLogin(context);
  }

  void _handleAuthFailure(BuildContext context, String Function(BuildContext) error) {
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context, rootNavigator: true).pop();
    UtilityWidgets.showCustomSnackBar(
      context: context,
      message: '${l10n.error}: ${error(context)}',
      backgroundColor: Theme.of(context).colorScheme.error,
    );
  }
}