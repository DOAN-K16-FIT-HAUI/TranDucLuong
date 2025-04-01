import 'package:finance_app/blocs/auth/auth_state.dart';
import 'package:finance_app/screens/auth/forgot_password_screen.dart';
import 'package:finance_app/screens/auth/login_screen.dart';
import 'package:finance_app/screens/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:finance_app/blocs/auth/auth_bloc.dart';

class AppRoutes {
  static const String loginRoute = 'login';
  static const String registerRoute = 'register';
  static const String dashboardRoute = 'dashboard';
  static const String forgotPasswordRoute = 'forgot-password';

  static final router = GoRouter(
    initialLocation: AppPaths.loginPath, // Bắt đầu từ login
    debugLogDiagnostics: true,
    errorBuilder: (context, state) => const Scaffold(body: Center(child: Text('Page not found'))),
    routes: [
      GoRoute(
        name: loginRoute,
        path: AppPaths.loginPath,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: registerRoute,
        path: AppPaths.registerPath,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        name: dashboardRoute,
        path: AppPaths.dashboardPath,
        builder: (context, state) => const Placeholder(), // Thay bằng DashboardScreen của bạn
      ),
      GoRoute(
        name: forgotPasswordRoute,
        path: AppPaths.forgotPasswordPath,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
    ],
    redirect: (context, state) {
      final authState = context.read<AuthBloc>().state;
      final isAuthenticated = authState is AuthAuthenticated;
      final isOnLogin = state.matchedLocation == AppPaths.loginPath;
      final isOnRegister = state.matchedLocation == AppPaths.registerPath;
      final isOnForgotPassword = state.matchedLocation == AppPaths.forgotPasswordPath;

      if (!isAuthenticated && !isOnLogin && !isOnRegister && !isOnForgotPassword) {
        return AppPaths.loginPath; // Chuyển hướng về login nếu chưa xác thực
      }
      if (isAuthenticated && (isOnLogin || isOnRegister || isOnForgotPassword)) {
        return AppPaths.dashboardPath; // Chuyển hướng về dashboard nếu đã xác thực
      }
      return null; // Không chuyển hướng
    },

  );

  static void navigateToLogin(BuildContext context) => context.goNamed(loginRoute);
  static void navigateToRegister(BuildContext context) => context.goNamed(registerRoute);
  static void navigateToForgotPassword(BuildContext context) => context.goNamed(forgotPasswordRoute);
  static void navigateToDashboard(BuildContext context) => context.goNamed(dashboardRoute);
}

class AppPaths {
  static const String dashboardPath = '/';
  static const String transactionsPath = '/transactions';
  static const String addTransactionPath = '/transactions/add';
  static const String editTransactionPath = '/transactions/:id';
  static const String categoriesPath = '/categories';
  static const String settingsPath = '/settings';
  static const String reportsPath = '/reports';
  static const String loginPath = '/login';
  static const String registerPath = '/register';
  static const String forgotPasswordPath = '/forgot-password';
  static const String transactionListPath = '/transaction-list';
}