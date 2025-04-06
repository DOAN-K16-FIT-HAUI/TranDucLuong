import 'package:finance_app/blocs/auth/auth_state.dart';
import 'package:finance_app/core/app_paths.dart';
import 'package:finance_app/screens/app_notification/notification_screen.dart';
import 'package:finance_app/screens/auth/forgot_password_screen.dart';
import 'package:finance_app/screens/auth/login_screen.dart';
import 'package:finance_app/screens/auth/register_screen.dart';
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
    ],
    redirect: (context, state) async {
      final isOnSplash = state.matchedLocation == AppPaths.splashPath;

      // If on the splash screen, wait for a delay and then redirect
      if (isOnSplash) {
        // Adjusted delay to 3 seconds
        await Future.delayed(const Duration(seconds: 2));

        // Check onboarding and authentication status
        final hasSeenOnboarding = await OnboardingStatus.hasSeenOnboarding();
        final authState = context.read<AuthBloc>().state;
        final isAuthenticated = authState is AuthAuthenticated;

        if (!hasSeenOnboarding) {
          return AppPaths.onBoardingPath; // Show onboarding if not seen
        } else if (isAuthenticated) {
          return AppPaths.dashboardPath; // Go to top if authenticated
        } else {
          return AppPaths.loginPath; // Go to login if not authenticated
        }
      }

      // Existing redirect logic for other screens
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

      if (hasSeenOnboarding && isAuthenticated && (isOnLogin || isOnRegister || isOnForgotPassword || isOnOnboarding)) {
        return AppPaths.dashboardPath;
      }

      if (hasSeenOnboarding && !isAuthenticated && !isOnLogin && !isOnRegister && !isOnForgotPassword) {
        return AppPaths.loginPath;
      }

      return null; // No redirect
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
}