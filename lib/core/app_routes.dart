import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/blocs/auth/auth_state.dart';
import 'package:finance_app/blocs/group_note/group_note_bloc.dart';
import 'package:finance_app/data/models/group_note.dart';
import 'package:finance_app/screens/account/account_screen.dart';
import 'package:finance_app/screens/app_notification/notification_screen.dart';
import 'package:finance_app/screens/auth/forgot_password_screen.dart';
import 'package:finance_app/screens/auth/login_screen.dart';
import 'package:finance_app/screens/auth/register_screen.dart';
import 'package:finance_app/screens/group_note/add_edit_group_note_screen.dart';
import 'package:finance_app/screens/group_note/group_note_detail_screen.dart';
import 'package:finance_app/screens/group_note/group_note_screen.dart';
import 'package:finance_app/screens/on_boarding/on_boarding_screen.dart';
import 'package:finance_app/screens/on_boarding/on_boarding_status.dart';
import 'package:finance_app/screens/report/report_screen.dart';
import 'package:finance_app/screens/splash/splash_screen.dart';
import 'package:finance_app/screens/top/top_screen.dart';
import 'package:finance_app/screens/transaction/transaction_list.dart';
import 'package:finance_app/screens/transaction/transaction_screen.dart';
import 'package:finance_app/screens/wallet/wallet_screen.dart';
import 'package:finance_app/utils/common_widget/route_transitions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'app_paths.dart'; // Import AppPaths

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
  static const String addEditGroupNoteRoute = 'add-edit-group-note';
  static const String groupNoteDetailRoute = 'group-note-detail';
  static const String reportRoute = 'report';
  static const String barcodeScannerRoute = 'barcode-scanner'; // Thêm route

  static final router = GoRouter(
    initialLocation: AppPaths.splashPath,
    debugLogDiagnostics: true,
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
    routes: [
      GoRoute(
        name: splashRoute,
        path: AppPaths.splashPath,
        pageBuilder: (context, state) => RouteTransitions.buildPageWithTransition(
          child: const SplashScreen(),
          state: state,
        ),
      ),
      GoRoute(
        name: onBoardingRoute,
        path: AppPaths.onBoardingPath,
        pageBuilder: (context, state) => RouteTransitions.buildPageWithTransition(
          child: const OnboardingScreen(),
          state: state,
        ),
      ),
      GoRoute(
        name: loginRoute,
        path: AppPaths.loginPath,
        pageBuilder: (context, state) => RouteTransitions.buildPageWithTransition(
          child: const LoginScreen(),
          state: state,
        ),
      ),
      GoRoute(
        name: registerRoute,
        path: AppPaths.registerPath,
        pageBuilder: (context, state) => RouteTransitions.buildPageWithTransition(
          child: const RegisterScreen(),
          state: state,
        ),
      ),
      GoRoute(
        name: forgotPasswordRoute,
        path: AppPaths.forgotPasswordPath,
        pageBuilder: (context, state) => RouteTransitions.buildPageWithTransition(
          child: const ForgotPasswordScreen(),
          state: state,
        ),
      ),
      GoRoute(
        name: dashboardRoute,
        path: AppPaths.dashboardPath,
        pageBuilder: (context, state) => RouteTransitions.buildPageWithTransition(
          child: const TopScreen(),
          state: state,
        ),
        routes: [
          GoRoute(
            name: groupNoteRoute,
            path: 'group-notes',
            pageBuilder: (context, state) => RouteTransitions.buildPageWithTransition(
              child: BlocProvider.value(
                value: GetIt.instance<GroupNoteBloc>(),
                child: const GroupNoteScreen(),
              ),
              state: state,
            ),
          ),
          GoRoute(
            name: addEditGroupNoteRoute,
            path: 'group-notes/edit',
            pageBuilder: (context, state) {
              final args = state.extra as Map<String, dynamic>?;
              final note = args?['note'] as GroupNoteModel?;
              final status = args?['status'] as String? ?? (note == null ? 'add' : 'edit');
              final groupId = args?['groupId'] as String?;

              if (groupId == null) {
                return MaterialPage(child: Scaffold(body: Center(child: Text("Error: Group ID missing"))));
              }

              return RouteTransitions.buildPageWithTransition(
                child: BlocProvider.value(
                  value: GetIt.instance<GroupNoteBloc>(),
                  child: AddEditGroupNoteScreen(
                    note: note,
                    status: status,
                    groupId: groupId,
                    onSave: (savedNote) {
                      if (status == 'add') {
                        context.read<GroupNoteBloc>().add(AddNote(savedNote));
                      } else {
                        context.read<GroupNoteBloc>().add(EditNote(savedNote));
                      }
                    },
                  ),
                ),
                state: state,
                transitionType: RouteTransitionType.slide,
              );
            },
          ),
          GoRoute(
            name: groupNoteDetailRoute,
            path: 'group-notes/detail/:noteId',
            pageBuilder: (context, state) {
              final note = state.extra as GroupNoteModel?;
              final noteId = state.pathParameters['noteId'];

              if (note == null || note.id != noteId) {
                return MaterialPage(child: Scaffold(body: Center(child: Text("Error: Note data missing or ID mismatch"))));
              }
              return RouteTransitions.buildPageWithTransition(
                child: BlocProvider.value(
                  value: GetIt.instance<GroupNoteBloc>(),
                  child: GroupNoteDetailScreen(note: note),
                ),
                state: state,
                transitionType: RouteTransitionType.slide,
              );
            },
          ),
          GoRoute(
            name: walletRoute,
            path: 'wallets',
            pageBuilder: (context, state) => RouteTransitions.buildPageWithTransition(
              child: const WalletScreen(),
              state: state,
            ),
          ),
          GoRoute(
            name: appNotificationRoute,
            path: 'notifications',
            pageBuilder: (context, state) => RouteTransitions.buildPageWithTransition(
              child: const NotificationScreen(),
              state: state,
            ),
          ),
          GoRoute(
            name: transactionRoute,
            path: 'transactions/add',
            pageBuilder: (context, state) => RouteTransitions.buildPageWithTransition(
              child: const TransactionScreen(),
              state: state,
            ),
          ),
          GoRoute(
            name: transactionListRoute,
            path: 'transactions',
            pageBuilder: (context, state) => RouteTransitions.buildPageWithTransition(
              child: const TransactionListScreen(),
              state: state,
            ),
          ),
          GoRoute(
            name: accountRoute,
            path: 'account',
            pageBuilder: (context, state) => RouteTransitions.buildPageWithTransition(
              child: const AccountScreen(),
              state: state,
            ),
          ),
          GoRoute(
            name: reportRoute,
            path: 'reports',
            pageBuilder: (context, state) => RouteTransitions.buildPageWithTransition(
              child: const ReportScreen(),
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
      final isOnSplash = state.matchedLocation == AppPaths.splashPath;
      final isOnLogin = state.matchedLocation == AppPaths.loginPath;
      final isOnRegister = state.matchedLocation == AppPaths.registerPath;
      final isOnForgotPassword = state.matchedLocation == AppPaths.forgotPasswordPath;
      final isOnOnboarding = state.matchedLocation == AppPaths.onBoardingPath;

      if (isOnSplash) {
        await Future.delayed(const Duration(seconds: 1));
        final hasSeenOnboarding = await OnboardingStatus.hasSeenOnboarding();

        if (!hasSeenOnboarding) {
          return AppPaths.onBoardingPath;
        } else {
          return isAuthenticated ? AppPaths.dashboardPath : AppPaths.loginPath;
        }
      }

      final hasSeenOnboarding = await OnboardingStatus.hasSeenOnboarding();

      if (!hasSeenOnboarding && !isOnOnboarding) {
        return AppPaths.onBoardingPath;
      }

      if (hasSeenOnboarding && !isAuthenticated && !isOnLogin && !isOnRegister && !isOnForgotPassword && !isOnOnboarding) {
        return AppPaths.loginPath;
      }

      if (isAuthenticated && (isOnLogin || isOnRegister || isOnOnboarding || isOnForgotPassword)) {
        return AppPaths.dashboardPath;
      }

      return null;
    },
  );

  // Navigation Helpers
  static void navigateToSplash(BuildContext context) => context.go(AppPaths.splashPath);
  static void navigateToOnBoarding(BuildContext context) => context.go(AppPaths.onBoardingPath);
  static void navigateToLogin(BuildContext context) => context.go(AppPaths.loginPath);
  static void navigateToRegister(BuildContext context) => context.go(AppPaths.registerPath);
  static void navigateToForgotPassword(BuildContext context) => context.push(AppPaths.forgotPasswordPath);
  static void navigateToDashboard(BuildContext context) => context.go(AppPaths.dashboardPath);
  static void navigateToWallet(BuildContext context) => context.push(AppPaths.walletListPath);
  static void navigateToAppNotification(BuildContext context) => context.push(AppPaths.appNotificationListPath);
  static void navigateToTransaction(BuildContext context) => context.push(AppPaths.addTransactionPath);
  static void navigateToTransactionList(BuildContext context) => context.push(AppPaths.transactionListPath);
  static void navigateToAccount(BuildContext context) => context.push(AppPaths.accountPath);
  static void navigateToReport(BuildContext context) => context.push(AppPaths.reportsPath);
  static void navigateToGroupNoteList(BuildContext context) => context.push(AppPaths.groupNoteListPath);
  static void navigateToBarcodeScanner(BuildContext context) => context.push(AppPaths.barcodeScannerPath);

  static void navigateToAddEditGroupNote(
      BuildContext context,
      GroupNoteModel? note,
      String status,
      Function(GroupNoteModel) onSave, {
        required String groupId,
      }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: GetIt.instance<GroupNoteBloc>(),
          child: AddEditGroupNoteScreen(
            note: note,
            status: status,
            groupId: groupId,
            onSave: onSave,
          ),
        ),
      ),
    );
  }

  static void navigateToGroupNoteDetail(BuildContext context, GroupNoteModel note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: GetIt.instance<GroupNoteBloc>(),
          child: GroupNoteDetailScreen(note: note),
        ),
      ),
    );
  }
}