import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/blocs/auth/auth_state.dart';
import 'package:finance_app/screens/account/account_screen.dart';
import 'package:finance_app/screens/app_notification/notification_screen.dart';
import 'package:finance_app/screens/app_notification/savings_reminder_screen.dart';
import 'package:finance_app/screens/auth/forgot_password_screen.dart';
import 'package:finance_app/screens/auth/login_screen.dart';
import 'package:finance_app/screens/auth/register_screen.dart';
import 'package:finance_app/screens/report/report_screen.dart';
import 'package:finance_app/screens/top/top_screen.dart';
import 'package:finance_app/screens/transaction/transaction_list_screen.dart';
import 'package:finance_app/screens/transaction/transaction_screen.dart';
import 'package:finance_app/screens/wallet/wallet_screen.dart';
import 'package:finance_app/utils/common_widget/route_transitions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'app_paths.dart';

class AppRoutes {
  static const String loginRoute = 'login';
  static const String registerRoute = 'register';
  static const String dashboardRoute = 'top';
  static const String forgotPasswordRoute = 'forgot-password';
  static const String walletRoute = 'wallet';
  static const String appNotificationRoute = 'app-notification';
  static const String transactionRoute = 'transaction';
  static const String transactionListRoute = 'transaction-list';
  static const String accountRoute = 'account';
  static const String reportRoute = 'report';
  static const String savingsReminderRoute = 'savings-reminder';

  static final router = GoRouter(
    initialLocation: AppPaths.loginPath,
    debugLogDiagnostics: true,
    errorBuilder:
        (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(child: Text('Page not found: ${state.error}')),
        ),
    routes: [
      GoRoute(
        name: loginRoute,
        path: AppPaths.loginPath,
        pageBuilder:
            (context, state) => RouteTransitions.buildPageWithTransition(
              child: const LoginScreen(),
              state: state,
            ),
      ),
      GoRoute(
        name: registerRoute,
        path: AppPaths.registerPath,
        pageBuilder:
            (context, state) => RouteTransitions.buildPageWithTransition(
              child: const RegisterScreen(),
              state: state,
            ),
      ),
      GoRoute(
        name: forgotPasswordRoute,
        path: AppPaths.forgotPasswordPath,
        pageBuilder:
            (context, state) => RouteTransitions.buildPageWithTransition(
              child: const ForgotPasswordScreen(),
              state: state,
            ),
      ),
      GoRoute(
        name: dashboardRoute,
        path: AppPaths.dashboardPath,
        pageBuilder:
            (context, state) => RouteTransitions.buildPageWithTransition(
              child: const TopScreen(),
              state: state,
            ),
        routes: [
          GoRoute(
            name: walletRoute,
            path: 'wallets',
            pageBuilder:
                (context, state) => RouteTransitions.buildPageWithTransition(
                  child: const WalletScreen(),
                  state: state,
                ),
          ),
          GoRoute(
            name: appNotificationRoute,
            path: 'notifications',
            pageBuilder:
                (context, state) => RouteTransitions.buildPageWithTransition(
                  child: const NotificationScreen(),
                  state: state,
                ),
          ),
          GoRoute(
            name: transactionRoute,
            path: 'transactions/add',
            pageBuilder:
                (context, state) => RouteTransitions.buildPageWithTransition(
                  child: const TransactionScreen(),
                  state: state,
                ),
          ),
          GoRoute(
            name: transactionListRoute,
            path: 'transactions',
            pageBuilder:
                (context, state) => RouteTransitions.buildPageWithTransition(
                  child: const TransactionListScreen(),
                  state: state,
                ),
          ),
          GoRoute(
            name: accountRoute,
            path: 'account',
            pageBuilder:
                (context, state) => RouteTransitions.buildPageWithTransition(
                  child: const AccountScreen(),
                  state: state,
                ),
          ),
          GoRoute(
            name: reportRoute,
            path: 'reports',
            pageBuilder:
                (context, state) => RouteTransitions.buildPageWithTransition(
                  child: const ReportScreen(),
                  state: state,
                ),
          ),
          GoRoute(
            name: savingsReminderRoute,
            path: 'savings-reminder',
            pageBuilder:
                (context, state) => RouteTransitions.buildPageWithTransition(
                  child: const SavingsReminderScreen(),
                  state: state,
                ),
          ),
        ],
      ),
    ],
    redirect: (context, state) async {
      final authBloc = context.read<AuthBloc>();
      // Đợi cho đến khi AuthBloc không còn ở trạng thái AuthInitial
      if (authBloc.state is AuthInitial) {
        await authBloc.stream.firstWhere((state) => state is! AuthInitial);
      }

      final authState = authBloc.state;
      final isAuthenticated = authState is AuthAuthenticated;
      final isOnLogin = state.matchedLocation == AppPaths.loginPath;
      final isOnRegister = state.matchedLocation == AppPaths.registerPath;
      final isOnForgotPassword =
          state.matchedLocation == AppPaths.forgotPasswordPath;

      if (!isAuthenticated &&
          !isOnLogin &&
          !isOnRegister &&
          !isOnForgotPassword) {
        return AppPaths.loginPath;
      }

      if (isAuthenticated &&
          (isOnLogin || isOnRegister || isOnForgotPassword)) {
        return AppPaths.dashboardPath;
      }

      return null;
    },
  );

  // Navigation Helpers
  static void navigateToLogin(BuildContext context) =>
      context.go(AppPaths.loginPath);
  static void navigateToRegister(BuildContext context) =>
      context.go(AppPaths.registerPath);
  static void navigateToForgotPassword(BuildContext context) =>
      context.push(AppPaths.forgotPasswordPath);
  static void navigateToDashboard(BuildContext context) =>
      context.go(AppPaths.dashboardPath);
  static void navigateToWallet(BuildContext context) =>
      context.push(AppPaths.walletListPath);
  static void navigateToAppNotification(BuildContext context) =>
      context.push(AppPaths.appNotificationListPath);
  static void navigateToTransaction(BuildContext context) =>
      context.push(AppPaths.addTransactionPath);
  static void navigateToTransactionList(BuildContext context) =>
      context.push(AppPaths.transactionListPath);
  static void navigateToAccount(BuildContext context) =>
      context.push(AppPaths.accountPath);
  static void navigateToReport(BuildContext context) =>
      context.push(AppPaths.reportsPath);
  static void navigateToSavingsReminder(BuildContext context) =>
      context.go(AppPaths.savingsReminderPath);
}
