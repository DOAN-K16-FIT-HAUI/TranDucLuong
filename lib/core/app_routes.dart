import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/blocs/auth/auth_state.dart';
import 'package:finance_app/blocs/group_note/group_note_bloc.dart';
import 'package:finance_app/data/models/group_note.dart';
// import 'package:finance_app/data/repositories/group_note_repository.dart'; // Not needed here
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
import 'package:finance_app/utils/common_widget/route_transitions.dart'; // Use common transitions
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

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

  static final router = GoRouter(
    initialLocation: AppPaths.splashPath,
    debugLogDiagnostics: true,
    errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Page not found: ${state.error}'))),
    routes: [
      GoRoute(
        name: splashRoute,
        path: AppPaths.splashPath,
        pageBuilder: (context, state) => RouteTransitions.buildPageWithTransition( // Use common transition
          child: const SplashScreen(),
          state: state,
        ),
      ),
      // --- Other top-level routes using RouteTransitions.buildPageWithTransition ---
      GoRoute(
        name: onBoardingRoute,
        path: AppPaths.onBoardingPath,
        pageBuilder: (context, state) => RouteTransitions.buildPageWithTransition( // Use common transition
          child: const OnboardingScreen(),
          state: state,
        ),
      ),
      GoRoute(
        name: loginRoute,
        path: AppPaths.loginPath,
        pageBuilder: (context, state) => RouteTransitions.buildPageWithTransition( // Use common transition
          child: const LoginScreen(),
          state: state,
        ),
      ),
      GoRoute(
        name: registerRoute,
        path: AppPaths.registerPath,
        pageBuilder: (context, state) => RouteTransitions.buildPageWithTransition( // Use common transition
          child: const RegisterScreen(),
          state: state,
        ),
      ),
      GoRoute(
        name: forgotPasswordRoute,
        path: AppPaths.forgotPasswordPath,
        pageBuilder: (context, state) => RouteTransitions.buildPageWithTransition( // Use common transition
          child: const ForgotPasswordScreen(),
          state: state,
        ),
      ),
      // --- Dashboard and its nested routes ---
      GoRoute(
          name: dashboardRoute,
          path: AppPaths.dashboardPath,
          pageBuilder: (context, state) =>
              RouteTransitions.buildPageWithTransition( // Use common transition
                child: const TopScreen(),
                state: state,
              ),
          routes: [
            GoRoute(
              name: groupNoteRoute,
              path: 'group-notes',
              pageBuilder: (context, state) {
                return RouteTransitions.buildPageWithTransition( // Use common transition
                  child: BlocProvider.value(
                    value: GetIt.instance<GroupNoteBloc>(),
                    child: const GroupNoteScreen(),
                  ),
                  state: state,
                  // transitionType: RouteTransitionType.slide // Optional specific transition
                );
              },
            ),
            // Keep Add/Edit/Detail routes using RouteTransitions.buildPageWithTransition
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

                return RouteTransitions.buildPageWithTransition( // Use common transition
                  child: BlocProvider.value(
                    value: GetIt.instance<GroupNoteBloc>(),
                    child: AddEditGroupNoteScreen(
                      note: note,
                      status: status,
                      groupId: groupId,
                      onSave: (savedNote) {
                        if (status == 'add') { context.read<GroupNoteBloc>().add(AddNote(savedNote)); }
                        else { context.read<GroupNoteBloc>().add(EditNote(savedNote)); }
                      },
                    ),
                  ),
                  state: state,
                  transitionType: RouteTransitionType.slide, // Specific transition
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
                return RouteTransitions.buildPageWithTransition( // Use common transition
                  child: BlocProvider.value(
                    value: GetIt.instance<GroupNoteBloc>(),
                    child: GroupNoteDetailScreen(note: note),
                  ),
                  state: state,
                  transitionType: RouteTransitionType.slide, // Specific transition
                );
              },
            ),
            // --- Other nested routes using RouteTransitions.buildPageWithTransition ---
            GoRoute(
              name: walletRoute,
              path: 'wallets',
              pageBuilder: (context, state) => RouteTransitions.buildPageWithTransition( // Use common transition
                child: WalletScreen(), state: state,
              ),
            ),
            GoRoute(
              name: appNotificationRoute,
              path: 'notifications',
              pageBuilder: (context, state) => RouteTransitions.buildPageWithTransition( // Use common transition
                child: NotificationScreen(), state: state,
              ),
            ),
            GoRoute(
              name: transactionRoute,
              path: 'transactions/add',
              pageBuilder: (context, state) => RouteTransitions.buildPageWithTransition( // Use common transition
                child: const TransactionScreen(), state: state,
              ),
            ),
            GoRoute(
              name: transactionListRoute,
              path: 'transactions',
              pageBuilder: (context, state) => RouteTransitions.buildPageWithTransition( // Use common transition
                child: const TransactionListScreen(), state: state,
              ),
            ),
            GoRoute(
              name: accountRoute,
              path: 'account',
              pageBuilder: (context, state) => RouteTransitions.buildPageWithTransition( // Use common transition
                child: const AccountScreen(), state: state,
              ),
            ),
            GoRoute(
              name: reportRoute,
              path: 'reports',
              pageBuilder: (context, state) => RouteTransitions.buildPageWithTransition( // Use common transition
                child: const ReportScreen(), state: state,
              ),
            ),
          ]),
    ],
    // --- redirect logic remains the same ---
    redirect: (context, state) async {
      final authState = context.read<AuthBloc>().state;
      final isAuthenticated = authState is AuthAuthenticated;
      final isOnSplash = state.matchedLocation == AppPaths.splashPath;
      final isOnLogin = state.matchedLocation == AppPaths.loginPath;
      final isOnRegister = state.matchedLocation == AppPaths.registerPath;
      final isOnForgotPassword = state.matchedLocation == AppPaths.forgotPasswordPath;
      final isOnOnboarding = state.matchedLocation == AppPaths.onBoardingPath;

      if (isOnSplash) {
        await Future.delayed(const Duration(seconds: 1)); // Giữ delay nếu muốn
        final hasSeenOnboarding = await OnboardingStatus.hasSeenOnboarding();

        if (!hasSeenOnboarding) {
          // Nếu chưa xem onboarding, đi đến onboarding
          return AppPaths.onBoardingPath;
        } else {
          // Nếu ĐÃ xem onboarding, KIỂM TRA ĐĂNG NHẬP NGAY LẬP TỨC
          if (isAuthenticated) {
            // Nếu đã đăng nhập, đi đến dashboard
            return AppPaths.dashboardPath;
          } else {
            // Nếu chưa đăng nhập, đi đến login
            return AppPaths.loginPath;
          }
        }
        // Không cần return null ở đây nữa vì đã xử lý hết các trường hợp
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

  // --- Navigation Helpers - Keep using push/go and standard Navigator ---
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

  // Keep standard Navigator.push for screens needing complex data/callbacks not easily passed via go_router extras
  static void navigateToAddEditGroupNote(
      BuildContext context,
      GroupNoteModel? note,
      String status,
      Function(GroupNoteModel) onSave,
      {required String groupId}) {
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

// --- AppPaths remain the same ---
class AppPaths {
  static const String splashPath = '/splash';
  static const String onBoardingPath = '/onboarding';
  static const String loginPath = '/login';
  static const String registerPath = '/register';
  static const String forgotPasswordPath = '/forgot-password';
  static const String dashboardPath = '/top';
  static const String walletListPath = '/top/wallets';
  static const String appNotificationListPath = '/top/notifications';
  static const String addTransactionPath = '/top/transactions/add';
  static const String transactionListPath = '/top/transactions';
  static const String accountPath = '/top/account';
  static const String reportsPath = '/top/reports';
  static const String groupNoteListPath = '/top/group-notes';
  static const String addEditGroupNotePath = '/top/group-notes/edit';
  static String groupNoteDetailPath(String noteId) => '/top/group-notes/detail/$noteId';
}