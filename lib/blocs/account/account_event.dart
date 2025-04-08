import 'package:equatable/equatable.dart';

abstract class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object?> get props => [];
}

class LoadAccountDataEvent extends AccountEvent {}

class ToggleDarkModeEvent extends AccountEvent {
  final bool isDarkMode;
  const ToggleDarkModeEvent(this.isDarkMode);

  @override
  List<Object?> get props => [isDarkMode];
}

class ChangePasswordEvent extends AccountEvent {
  final String oldPassword;
  final String newPassword;

  const ChangePasswordEvent({required this.oldPassword, required this.newPassword});

  @override
  List<Object?> get props => [oldPassword, newPassword];
}

class ChangeLanguageEvent extends AccountEvent {
  final String language;

  const ChangeLanguageEvent(this.language);

  @override
  List<Object?> get props => [language];
}

class UpdateUserInfoEvent extends AccountEvent {
  final String? displayName;
  final String? photoUrl;
  final String? email; // Thêm email
  final String? currentPassword; // Thêm mật khẩu hiện tại để xác thực lại

  const UpdateUserInfoEvent({
    this.displayName,
    this.photoUrl,
    this.email,
    this.currentPassword,
  });

  @override
  List<Object?> get props => [displayName, photoUrl, email, currentPassword];
}

class DeleteAccountEvent extends AccountEvent {}

class LogoutEvent extends AccountEvent {}