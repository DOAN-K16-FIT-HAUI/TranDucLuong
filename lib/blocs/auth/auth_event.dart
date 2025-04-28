import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;

  const SignUpRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class SignInWithGoogleRequested extends AuthEvent {
  const SignInWithGoogleRequested();

  @override
  List<Object?> get props => [];
}

class SignInWithFacebookRequested extends AuthEvent {
  const SignInWithFacebookRequested();
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

class PasswordResetRequested extends AuthEvent {
  final String email;

  const PasswordResetRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class SignInWithBiometricsRequested extends AuthEvent {
  final BuildContext context;

  const SignInWithBiometricsRequested({required this.context});

  @override
  List<Object?> get props => [context];
}

class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();

  @override
  List<Object?> get props => [];
}