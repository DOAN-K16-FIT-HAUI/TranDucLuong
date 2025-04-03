import 'package:finance_app/blocs/auth/auth_state.dart';
import 'package:finance_app/screens/auth/forgot_password_screen.dart';
import 'package:finance_app/screens/auth/login_screen.dart';
import 'package:finance_app/screens/auth/register_screen.dart';
import 'package:finance_app/screens/top/top_screen.dart';
import 'package:finance_app/screens/on_boarding/on_boarding_screen.dart';
import 'package:finance_app/screens/on_boarding/on_boarding_status.dart';
import 'package:finance_app/screens/splash/splash_screen.dart';
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
}

class AppPaths {
  static const String splashPath = '/splash';
  static const String dashboardPath = '/';
  static const String onBoardingPath = '/on-boarding';
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