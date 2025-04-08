import 'package:equatable/equatable.dart';
import 'package:finance_app/data/models/user.dart';

abstract class AccountState extends Equatable {
  const AccountState();

  @override
  List<Object?> get props => [];
}

class AccountLoading extends AccountState {}

class AccountLoaded extends AccountState {
  final UserModel user;

  const AccountLoaded({required this.user});

  @override
  List<Object?> get props => [user];
}

class AccountPasswordChanged extends AccountState {}

class AccountError extends AccountState {
  final String message;
  const AccountError(this.message);

  @override
  List<Object?> get props => [message];
}

class AccountLoggedOut extends AccountState {}