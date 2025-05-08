import 'package:equatable/equatable.dart';
import 'package:finance_app/data/models/user.dart';
import 'package:flutter/material.dart';

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

class AccountError extends AccountState {
  final String Function(BuildContext context) message;
  const AccountError(this.message);
}

class AccountPasswordChanged extends AccountState {}

class AccountLoggedOut extends AccountState {}

class AccountDeleted extends AccountState {}
