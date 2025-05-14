import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:finance_app/blocs/account/account_bloc.dart';
import 'package:finance_app/blocs/app_notification/notification_bloc.dart';
import 'package:finance_app/blocs/app_notification/notification_event.dart';
import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/blocs/localization/localization_bloc.dart';
import 'package:finance_app/blocs/localization/localization_event.dart';
import 'package:finance_app/blocs/localization/localization_state.dart';
import 'package:finance_app/blocs/report/report_bloc.dart';
import 'package:finance_app/blocs/theme/theme_bloc.dart';
import 'package:finance_app/blocs/theme/theme_event.dart';
import 'package:finance_app/blocs/theme/theme_state.dart';
import 'package:finance_app/blocs/transaction/transaction_bloc.dart';
import 'package:finance_app/blocs/wallet/wallet_bloc.dart';
import 'package:finance_app/blocs/wallet/wallet_event.dart';
import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/data/services/local_notification_service.dart';
import 'package:finance_app/di/injection.dart';
import 'package:finance_app/flavor_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Kết nối với Firebase Emulator trong flavor test
  if (FlavorConfig.isTest()) {
    FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
  }
  debugPrint('Background message: ${message.messageId}');

  // Enhanced background notification handling for different message types
  final data = message.data;
  final notification = message.notification;

  if (notification != null) {
    int notificationId;
    String payload;

    // Process different notification types
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'spending_alert':
          notificationId = LocalNotificationService.spendingAlertNotificationId;
          payload = 'spending_alert';
          break;
        case 'savings_reminder':
          notificationId =
              LocalNotificationService.savingsReminderNotificationId;
          payload = 'savings_reminder';
          break;
        default:
          notificationId = message.hashCode;
          payload = data['type'] ?? 'notification';
      }
    } else {
      notificationId = message.hashCode;
      payload = 'notification';
    }

    // Show notification regardless of type
    await LocalNotificationService.showNotification(
      id: notificationId,
      title: notification.title ?? 'New Notification',
      body: notification.body ?? 'You have a new notification',
      payload: payload,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Add HTTP override for connection issues (especially in emulators)
  HttpOverrides.global = MyHttpOverrides();

  // Initialize plugins that need context-less initialization
  try {
    // Initialize connectivity plugin for network checks
    await Connectivity().checkConnectivity();
  } catch (e) {
    debugPrint('Connectivity plugin initialization error: $e');
    // Continue even if plugin fails
  }

  try {
    await Firebase.initializeApp().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Firebase initialization timed out');
      },
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // Don't rethrow - let the app continue even with Firebase issues
  }

  // Kết nối với Firebase Emulator trong flavor test
  if (FlavorConfig.isTest()) {
    debugPrint('Connecting to Firebase Emulator...');
    FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);
    debugPrint('Emulator setup complete.');
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  setupDependencies();

  // Initialize local notifications
  await LocalNotificationService.initialize();

  runApp(const MyApp());
}

// HTTP override class to help with certificate verification issues
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        BlocProvider<ThemeBloc>(
          create: (context) => sl<ThemeBloc>()..add(LoadThemeEvent()),
        ),
        BlocProvider<LocalizationBloc>(
          create:
              (context) => sl<LocalizationBloc>()..add(LoadLocalizationEvent()),
        ),
        BlocProvider<AuthBloc>(create: (context) => sl<AuthBloc>()),
        BlocProvider<NotificationBloc>(
          create:
              (context) =>
                  sl<NotificationBloc>()..add(InitializeNotifications()),
        ),
        BlocProvider<WalletBloc>(
          create: (context) => sl<WalletBloc>()..add(LoadWallets()),
        ),
        BlocProvider<TransactionBloc>(
          create: (context) => sl<TransactionBloc>(),
        ),
        BlocProvider<AccountBloc>(create: (context) => sl<AccountBloc>()),
        BlocProvider<ReportBloc>(create: (context) => sl<ReportBloc>()),
        Provider<TransactionRepository>(
          create: (context) => sl<TransactionRepository>(),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<LocalizationBloc, LocalizationState>(
            builder: (context, localizationState) {
              final themeData = themeState.themeData;
              final locale = localizationState.locale;

              return MaterialApp.router(
                routerConfig: AppRoutes.router,
                debugShowCheckedModeBanner: false,
                title: AppLocalizations.of(context)?.appTitle ?? 'Finance App',
                theme: themeData,
                locale: locale,
                supportedLocales: const [
                  Locale('en', 'US'),
                  Locale('vi', 'VN'),
                  Locale('ja', 'JP'),
                ],
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
              );
            },
          );
        },
      ),
    );
  }
}
