import 'package:finance_app/blocs/account/account_bloc.dart';
import 'package:finance_app/blocs/account/account_event.dart';
import 'package:finance_app/blocs/account/account_state.dart';
import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/blocs/theme/theme_bloc.dart';
import 'package:finance_app/blocs/theme/theme_event.dart';
import 'package:finance_app/blocs/localization/localization_bloc.dart';
import 'package:finance_app/blocs/localization/localization_event.dart' as localization; // Sử dụng alias
import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/utils/common_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (context) => AccountBloc(authBloc: context.read<AuthBloc>())..add(LoadAccountDataEvent()),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: CommonWidgets.buildAppBar(
          context: context,
          title: l10n.appTitle,
          showBackButton: false,
          actions: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () => AppRoutes.appNotificationRoute,
            ),
          ],
        ),
        body: BlocListener<AccountBloc, AccountState>(
          listener: (context, state) {
            if (state is AccountError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            } else if (state is AccountPasswordChanged) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.passwordChangedSuccess,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
            } else if (state is AccountLoggedOut) {
              print("AccountLoggedOut state received. Should redirect to login via GoRouter.");
            }
          },
          child: BlocBuilder<AccountBloc, AccountState>(
            builder: (context, state) {
              if (state is AccountLoading) {
                return CommonWidgets.buildLoadingIndicator(context);
              } else if (state is AccountLoaded) {
                final isEmailLogin = state.user.loginMethod == 'email';
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(context, l10n.personalInfo),
                      _buildUserInfo(context, state),
                      const SizedBox(height: 16),

                      _buildSectionTitle(context, l10n.appearance),
                      _buildSwitchTile(
                        context: context,
                        title: l10n.darkMode,
                        value: state.user.isDarkMode ?? false,
                        onChanged: (value) {
                          context.read<AccountBloc>().add(ToggleDarkModeEvent(value));
                          context.read<ThemeBloc>().add(ToggleThemeEvent(value));
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildLanguageSelector(context, state),
                      const SizedBox(height: 16),

                      _buildSectionTitle(context, l10n.security),
                      _buildActionTile(
                        context: context,
                        title: l10n.changePassword,
                        icon: Icons.key_outlined,
                        onTap: isEmailLogin
                            ? () => _showChangePasswordDialog(context)
                            : null,
                        textColor: isEmailLogin
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 8),
                      _buildActionTile(
                        context: context,
                        title: l10n.biometrics,
                        icon: Icons.fingerprint,
                        onTap: () {},
                      ),
                      const SizedBox(height: 8),
                      _buildActionTile(
                        context: context,
                        title: l10n.deleteAccount,
                        icon: Icons.delete_outline,
                        onTap: () {
                          CommonWidgets.showDeleteDialog(
                            context: context,
                            title: l10n.deleteAccountConfirm,
                            content: l10n.actionCannotBeUndone,
                            onDeletePressed: () {
                              context.read<AccountBloc>().add(DeleteAccountEvent());
                            },
                          );
                        },
                        textColor: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),

                      _buildLogoutButton(context),
                    ],
                  ),
                );
              } else if (state is AccountError) {
                return CommonWidgets.buildErrorState(
                  context: context,
                  message: state.message,
                  onRetry: () {
                    context.read<AccountBloc>().add(LoadAccountDataEvent());
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    CommonWidgets.showFormDialog(
      context: context,
      formKey: formKey,
      title: l10n.changePasswordTitle,
      actionButtonText: l10n.confirm,
      formFields: [
        CommonWidgets.buildTextField(
          controller: oldPasswordController,
          label: l10n.oldPassword,
          hint: l10n.enterOldPassword,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.enterOldPassword;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CommonWidgets.buildTextField(
          controller: newPasswordController,
          label: l10n.newPassword,
          hint: l10n.enterNewPassword,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.enterNewPassword;
            }
            if (value.length < 6) {
              return l10n.passwordMinLength;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CommonWidgets.buildTextField(
          controller: confirmPasswordController,
          label: l10n.confirmNewPassword,
          hint: l10n.enterConfirmPassword,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.enterConfirmPassword;
            }
            if (value != newPasswordController.text) {
              return l10n.passwordsDoNotMatch;
            }
            return null;
          },
        ),
      ],
      onActionButtonPressed: () {
        context.read<AccountBloc>().add(
          ChangePasswordEvent(
            oldPassword: oldPasswordController.text,
            newPassword: newPasswordController.text,
          ),
        );
      },
    );
  }

  void _showEditUserInfoDialog(BuildContext context, AccountLoaded state) {
    final l10n = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    final displayNameController = TextEditingController(text: state.user.displayName);
    final photoUrlController = TextEditingController(text: state.user.photoUrl);
    final emailController = TextEditingController(text: state.user.email);
    final currentPasswordController = TextEditingController();

    final isEmailLogin = state.user.loginMethod == 'email';

    CommonWidgets.showFormDialog(
      context: context,
      formKey: formKey,
      title: l10n.editPersonalInfo,
      actionButtonText: l10n.save,
      formFields: [
        CommonWidgets.buildTextField(
          controller: displayNameController,
          label: l10n.displayName,
          hint: l10n.enterDisplayName,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.enterDisplayName;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CommonWidgets.buildTextField(
          controller: photoUrlController,
          label: l10n.photoUrl,
          hint: l10n.enterPhotoUrl,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!Uri.parse(value).isAbsolute) {
                return l10n.invalidUrl;
              }
            }
            return null;
          },
        ),
        if (isEmailLogin)
          StatefulBuilder(
            builder: (context, setState) {
              bool emailChanged = emailController.text != state.user.email;
              bool isPasswordVisible = false;

              return Column(
                children: [
                  const SizedBox(height: 16),
                  CommonWidgets.buildEmailField(
                    controller: emailController,
                    onChanged: (value) {
                      setState(() {
                        emailChanged = value != state.user.email;
                      });
                    },
                  ),
                  if (emailChanged) ...[
                    const SizedBox(height: 16),
                    CommonWidgets.buildPasswordField(
                      currentPasswordController,
                      isPasswordVisible,
                          () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                  ],
                ],
              );
            },
          ),
      ],
      onActionButtonPressed: () {
        if (formKey.currentState!.validate()) {
          final emailChanged = emailController.text != state.user.email;
          context.read<AccountBloc>().add(
            UpdateUserInfoEvent(
              displayName: displayNameController.text,
              photoUrl: photoUrlController.text.isEmpty
                  ? null
                  : photoUrlController.text,
              email: isEmailLogin ? emailController.text : null,
              currentPassword:
              emailChanged && isEmailLogin ? currentPasswordController.text : null,
            ),
          );
        }
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.headlineMedium);
  }

  Widget _buildUserInfo(BuildContext context, AccountLoaded state) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: CommonWidgets.boxDecoration(context),
      child: ListTile(
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: state.user.photoUrl != null
              ? NetworkImage(state.user.photoUrl!)
              : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
        ),
        title: Text(
          state.user.displayName ?? 'Người dùng',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          state.user.email,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        onTap: () => _showEditUserInfoDialog(context, state),
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: CommonWidgets.boxDecoration(context),
      child: ListTile(
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveTrackColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, AccountLoaded state) {
    final l10n = AppLocalizations.of(context)!;
    final languages = ['Tiếng Việt', 'English', '日本語'];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: CommonWidgets.buildDropdownField(
        label: l10n.language,
        value: state.user.language ?? 'Tiếng Việt',
        items: languages,
        onChanged: (newLanguage) {
          if (newLanguage != null) {
            context.read<AccountBloc>().add(ChangeLanguageEvent(newLanguage));
            context.read<LocalizationBloc>().add(localization.ChangeLanguageEvent(newLanguage)); // Sử dụng alias
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return l10n.language;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback? onTap,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: CommonWidgets.boxDecoration(context),
      child: ListTile(
        leading: Icon(
          icon,
          color: textColor ??
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: textColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: ElevatedButton(
          onPressed: () {
            CommonWidgets.showDeleteDialog(
              context: context,
              title: l10n.confirmLogout,
              content: '',
              onDeletePressed: () {
                context.read<AccountBloc>().add(LogoutEvent());
              },
            );
          },
          style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
            backgroundColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.error,
            ),
          ),
          child: Text(
            l10n.logout,
            style: Theme.of(context)
                .elevatedButtonTheme
                .style
                ?.textStyle
                ?.resolve({})
                ?.copyWith(color: Theme.of(context).colorScheme.onError),
          ),
        ),
      ),
    );
  }
}