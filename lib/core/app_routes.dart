import 'package:finance_app/blocs/auth/auth_state.dart';
import 'package:finance_app/core/app_paths.dart';
import 'package:finance_app/data/models/group_note.dart';
import 'package:finance_app/screens/account/account_screen.dart';
import 'package:finance_app/screens/app_notification/notification_screen.dart';
import 'package:finance_app/screens/auth/forgot_password_screen.dart';
import 'package:finance_app/screens/auth/login_screen.dart';
import 'package:finance_app/screens/auth/register_screen.dart';
import 'package:finance_app/screens/group_note/add_edit_group_note_screen.dart';
import 'package:finance_app/screens/group_note/group_note_detail_screen.dart';
import 'package:finance_app/screens/group_note/group_note_screen.dart';
import 'package:finance_app/screens/report/report_screen.dart';
import 'package:finance_app/screens/top/top_screen.dart';
import 'package:finance_app/screens/on_boarding/on_boarding_screen.dart';
import 'package:finance_app/screens/on_boarding/on_boarding_status.dart';
import 'package:finance_app/screens/splash/splash_screen.dart';
import 'package:finance_app/screens/transaction/transaction_list.dart';
import 'package:finance_app/screens/transaction/transaction_screen.dart';
import 'package:finance_app/screens/wallet/wallet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:finance_app/blocs/auth/auth_bloc.dart';

class AppRoutes {
  static const String splashRoute = 'splash';
  static const String loginRoute = 'login';
  static const String registerRoute = 'register';
  static const String dashboardRoute = 'top';
  static const String forgotPasswordRoute = 'forgot-password';
  static const String onBoardingRoute = 'on-boarding';
  static const String walletRoute = 'wallet';
  static const String appNotificationRoute = 'app-notification';
  static const String transactionRoute = 'transaction';
  static const String transactionListRoute = 'transaction-list';
  static const String accountRoute = 'account';
  static const String groupNoteRoute = 'group-note';
  static const String addEditGroupNoteRoute = 'group-note/add-edit';
  static const String groupNoteDetailRoute = 'group-note/detail';
  static const String reportRoute = 'report';

  static final router = GoRouter(
    initialLocation: AppPaths.splashPath,
    debugLogDiagnostics: true,
    errorBuilder: (context, state) =>
    const Scaffold(body: Center(child: Text('Page not found'))),
    routes: [
      GoRoute(
        name: splashRoute,
        path: AppPaths.splashPath,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        name: onBoardingRoute,
        path: AppPaths.onBoardingPath,
        builder: (context, state) => const OnboardingScreen(),
      ),
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
        builder: (context, state) => TopScreen(),
      ),
      GoRoute(
        name: forgotPasswordRoute,
        path: AppPaths.forgotPasswordPath,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        name: walletRoute,
        path: AppPaths.walletListPath,
        builder: (context, state) => WalletScreen(),
      ),
      GoRoute(
        name: appNotificationRoute,
        path: AppPaths.appNotificationListPath,
        builder: (context, state) => NotificationScreen(),
      ),
      GoRoute(
        name: transactionRoute,
        path: AppPaths.addTransactionPath,
        builder: (context, state) => const TransactionScreen(),
      ),
      GoRoute(
        name: transactionListRoute,
        path: AppPaths.transactionListPath,
        builder: (context, state) => const TransactionListScreen(),
      ),
      GoRoute(
        name: accountRoute,
        path: AppPaths.accountPath,
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        name: groupNoteRoute,
        path: AppPaths.groupNotePath,
        builder: (context, state) => const GroupNoteScreen(),
      ),
      GoRoute(
        name: addEditGroupNoteRoute,
        path: AppPaths.addEditGroupNotePath,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          return AddEditGroupNoteScreen(
            note: args?['note'] as GroupNoteModel?,
            onSave: args?['onSave'] as Function(GroupNoteModel),
            status: args?['status'] as String,
          );
        },
      ),
      GoRoute(
        name: groupNoteDetailRoute,
        path: AppPaths.groupNoteDetailPath,
        builder: (context, state) {
          final note = state.extra as GroupNoteModel;
          return GroupNoteDetailScreen(note: note);
        },
      ),
      GoRoute(
        name: reportRoute,
        path: AppPaths.reportsPath,
        builder: (context, state) => const ReportScreen(),
      ),
    ],
    redirect: (context, state) async {
      final isOnSplash = state.matchedLocation == AppPaths.splashPath;

      if (isOnSplash) {
        await Future.delayed(const Duration(seconds: 2));

        final hasSeenOnboarding = await OnboardingStatus.hasSeenOnboarding();
        final authState = context.read<AuthBloc>().state;
        final isAuthenticated = authState is AuthAuthenticated;

        if (!hasSeenOnboarding) {
          return AppPaths.onBoardingPath;
        } else if (isAuthenticated) {
          return AppPaths.dashboardPath;
        } else {
          return AppPaths.loginPath;
        }
      }

      final hasSeenOnboarding = await OnboardingStatus.hasSeenOnboarding();
      final authState = context.read<AuthBloc>().state;
      final isAuthenticated = authState is AuthAuthenticated;
      final isOnLogin = state.matchedLocation == AppPaths.loginPath;
      final isOnRegister = state.matchedLocation == AppPaths.registerPath;
      final isOnForgotPassword =
          state.matchedLocation == AppPaths.forgotPasswordPath;
      final isOnOnboarding = state.matchedLocation == AppPaths.onBoardingPath;

      if (!hasSeenOnboarding && !isOnOnboarding) {
        return AppPaths.onBoardingPath;
      }

      if (hasSeenOnboarding &&
          isAuthenticated &&
          (isOnLogin || isOnRegister || isOnForgotPassword || isOnOnboarding)) {
        return AppPaths.dashboardPath;
      }

      if (hasSeenOnboarding &&
          !isAuthenticated &&
          !isOnLogin &&
          !isOnRegister &&
          !isOnForgotPassword) {
        return AppPaths.loginPath;
      }

      return null;
    },
  );

  static void navigateToSplash(BuildContext context) =>
      context.goNamed(splashRoute);
  static void navigateToOnBoarding(BuildContext context) =>
      context.goNamed(onBoardingRoute);
  static void navigateToLogin(BuildContext context) =>
      context.goNamed(loginRoute);
  static void navigateToRegister(BuildContext context) =>
      context.goNamed(registerRoute);
  static void navigateToForgotPassword(BuildContext context) =>
      context.goNamed(forgotPasswordRoute);
  static void navigateToDashboard(BuildContext context) =>
      context.goNamed(dashboardRoute);
  static void navigateToWallet(BuildContext context) =>
      context.goNamed(walletRoute);
  static void navigateToAppNotification(BuildContext context) =>
      context.goNamed(appNotificationRoute);
  static void navigateToTransaction(BuildContext context) =>
      context.goNamed(transactionRoute);
  static void navigateToTransactionList(BuildContext context) =>
      context.goNamed(transactionListRoute);
  static void navigateToAccount(BuildContext context) =>
      context.goNamed(accountRoute);
  static void navigateToGroupNote(BuildContext context) =>
      context.goNamed(groupNoteRoute);
  static void navigateToAddEditGroupNote(
      BuildContext context, GroupNoteModel? note, String status, Function(GroupNoteModel) onSave) {
    context.pushNamed(addEditGroupNoteRoute,
        extra: {'note': note, 'onSave': onSave, 'status': status});
  }
  static void navigateToGroupNoteDetail(BuildContext context, GroupNoteModel note) {
    context.pushNamed(groupNoteDetailRoute, extra: note);
  }
  static void navigateToReport(BuildContext context) =>
      context.goNamed(reportRoute);
}