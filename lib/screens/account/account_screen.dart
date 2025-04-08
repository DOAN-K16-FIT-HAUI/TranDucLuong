import 'package:finance_app/blocs/account/account_bloc.dart';
import 'package:finance_app/blocs/account/account_event.dart';
import 'package:finance_app/blocs/account/account_state.dart';
import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/utils/common_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AccountBloc(authBloc: context.read<AuthBloc>())..add(LoadAccountDataEvent()),
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        appBar: CommonWidgets.buildAppBar(
          context: context,
          title: 'Cài đặt chung',
          showBackButton: false,
          actions: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: AppTheme.lightTheme.colorScheme.onPrimary,
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
                      color: AppTheme.lightTheme.colorScheme.onError,
                    ),
                  ),
                  backgroundColor: AppTheme.lightTheme.colorScheme.error,
                ),
              );
            } else if (state is AccountPasswordChanged) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Đổi mật khẩu thành công!',
                    style: GoogleFonts.poppins(
                      color: AppTheme.lightTheme.colorScheme.onPrimary,
                    ),
                  ),
                  backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                ),
              );
            } else if (state is AccountLoggedOut) {
              AppRoutes.navigateToLogin(context);
            }
          },
          child: BlocBuilder<AccountBloc, AccountState>(
            builder: (context, state) {
              if (state is AccountLoading) {
                return CommonWidgets.buildLoadingIndicator();
              } else if (state is AccountLoaded) {
                final isEmailLogin = state.user.loginMethod == 'email';
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Thông tin cá nhân'),
                      _buildUserInfo(context, state),
                      const SizedBox(height: 16),

                      _buildSectionTitle('Giao diện'),
                      _buildSwitchTile(
                        title: 'Chế độ tối',
                        value: state.user.isDarkMode ?? false,
                        onChanged: (value) {
                          context.read<AccountBloc>().add(
                            ToggleDarkModeEvent(value),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildLanguageSelector(context, state),
                      const SizedBox(height: 16),

                      _buildSectionTitle('Bảo mật'),
                      _buildActionTile(
                        title: 'Đổi mật khẩu',
                        icon: Icons.key_outlined,
                        onTap: isEmailLogin
                            ? () => _showChangePasswordDialog(context)
                            : null,
                        textColor: isEmailLogin
                            ? AppTheme.lightTheme.colorScheme.onSurface
                            : AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 8),
                      _buildActionTile(
                        title: 'Sinh trắc học',
                        icon: Icons.fingerprint,
                        onTap: () {},
                      ),
                      const SizedBox(height: 8),
                      _buildActionTile(
                        title: 'Xóa tài khoản',
                        icon: Icons.delete_outline,
                        onTap: () {
                          CommonWidgets.showDeleteDialog(
                            context: context,
                            title: 'Bạn có chắc chắn xóa tài khoản không?',
                            content: 'Hành động này không thể hoàn tác.',
                            onDeletePressed: () {
                              context.read<AccountBloc>().add(
                                DeleteAccountEvent(),
                              );
                            },
                          );
                        },
                        textColor: AppTheme.lightTheme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),

                      _buildLogoutButton(context),
                    ],
                  ),
                );
              } else if (state is AccountError) {
                return CommonWidgets.buildErrorState(
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
    final formKey = GlobalKey<FormState>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    CommonWidgets.showFormDialog(
      context: context,
      formKey: formKey,
      title: 'Đổi mật khẩu',
      actionButtonText: 'Xác nhận',
      formFields: [
        CommonWidgets.buildTextField(
          controller: oldPasswordController,
          label: 'Mật khẩu cũ',
          hint: 'Nhập mật khẩu cũ',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập mật khẩu cũ';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CommonWidgets.buildTextField(
          controller: newPasswordController,
          label: 'Mật khẩu mới',
          hint: 'Nhập mật khẩu mới',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập mật khẩu mới';
            }
            if (value.length < 6) {
              return 'Mật khẩu mới phải dài ít nhất 6 ký tự';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CommonWidgets.buildTextField(
          controller: confirmPasswordController,
          label: 'Xác nhận mật khẩu mới',
          hint: 'Xác nhận mật khẩu mới',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng xác nhận mật khẩu mới';
            }
            if (value != newPasswordController.text) {
              return 'Mật khẩu xác nhận không khớp';
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
    final formKey = GlobalKey<FormState>();
    final displayNameController = TextEditingController(
      text: state.user.displayName,
    );
    final photoUrlController = TextEditingController(text: state.user.photoUrl);
    final emailController = TextEditingController(text: state.user.email);
    final currentPasswordController = TextEditingController();

    final isEmailLogin = state.user.loginMethod == 'email';

    CommonWidgets.showFormDialog(
      context: context,
      formKey: formKey,
      title: 'Sửa thông tin cá nhân',
      actionButtonText: 'Lưu',
      formFields: [
        CommonWidgets.buildTextField(
          controller: displayNameController,
          label: 'Tên hiển thị',
          hint: 'Nhập tên hiển thị',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập tên hiển thị';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CommonWidgets.buildTextField(
          controller: photoUrlController,
          label: 'URL ảnh đại diện',
          hint: 'Nhập URL ảnh đại diện',
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!Uri.parse(value).isAbsolute) {
                return 'URL không hợp lệ';
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

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTheme.lightTheme.textTheme.headlineMedium);
  }

  Widget _buildUserInfo(BuildContext context, AccountLoaded state) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: CommonWidgets.boxDecoration(),
      child: ListTile(
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: state.user.photoUrl != null
              ? NetworkImage(state.user.photoUrl!)
              : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
        ),
        title: Text(
          state.user.displayName ?? 'Người dùng',
          style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          state.user.email,
          style: AppTheme.lightTheme.textTheme.bodySmall,
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
            alpha: 0.6,
          ),
        ),
        onTap: () => _showEditUserInfoDialog(context, state),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: CommonWidgets.boxDecoration(),
      child: ListTile(
        title: Text(title, style: AppTheme.lightTheme.textTheme.bodyLarge),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.lightTheme.colorScheme.primary,
          inactiveTrackColor:
          AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, AccountLoaded state) {
    final languages = ['Tiếng Việt', 'English', '日本語'];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: CommonWidgets.buildDropdownField(
        label: 'Ngôn ngữ',
        value: state.user.language ?? 'Tiếng Việt',
        items: languages,
        onChanged: (newLanguage) {
          if (newLanguage != null) {
            context.read<AccountBloc>().add(ChangeLanguageEvent(newLanguage));
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Vui lòng chọn một ngôn ngữ';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required VoidCallback? onTap,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: CommonWidgets.boxDecoration(),
      child: ListTile(
        leading: Icon(
          icon,
          color: textColor ??
              AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        title: Text(
          title,
          style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
            color: textColor ?? AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
            alpha: 0.6,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: ElevatedButton(
          onPressed: () {
            CommonWidgets.showDeleteDialog(
              context: context,
              title: 'Bạn có chắc chắn đăng xuất tài khoản không?',
              content: '',
              onDeletePressed: () {
                context.read<AccountBloc>().add(LogoutEvent());
              },
            );
          },
          style: AppTheme.lightTheme.elevatedButtonTheme.style?.copyWith(
            backgroundColor: WidgetStateProperty.all(
              AppTheme.lightTheme.colorScheme.error,
            ),
          ),
          child: Text(
            'Đăng xuất',
            style: AppTheme.lightTheme.elevatedButtonTheme.style?.textStyle
                ?.resolve({})
                ?.copyWith(color: AppTheme.lightTheme.colorScheme.onError),
          ),
        ),
      ),
    );
  }
}