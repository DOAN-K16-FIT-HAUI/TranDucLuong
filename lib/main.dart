import 'package:finance_app/blocs/account/account_bloc.dart';
import 'package:finance_app/blocs/app_notification/notification_bloc.dart';
import 'package:finance_app/blocs/app_notification/notification_event.dart';
import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/blocs/theme/theme_bloc.dart';
import 'package:finance_app/blocs/theme/theme_event.dart';
import 'package:finance_app/blocs/theme/theme_state.dart';
import 'package:finance_app/blocs/localization/localization_bloc.dart';
import 'package:finance_app/blocs/localization/localization_event.dart';
import 'package:finance_app/blocs/localization/localization_state.dart';
import 'package:finance_app/blocs/transaction/transaction_bloc.dart';
import 'package:finance_app/blocs/wallet/wallet_bloc.dart';
import 'package:finance_app/blocs/wallet/wallet_event.dart';
import 'package:finance_app/blocs/group_note/group_note_bloc.dart'; // Add this import
import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/data/repositories/group_note_repository.dart';
import 'package:finance_app/di/injection.dart';
import 'package:finance_app/firebase_option.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await SharedPreferences.getInstance();
  setupDependencies();
  runApp(const MyApp());
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
          create: (context) => sl<LocalizationBloc>()..add(LoadLocalizationEvent()),
        ),
        BlocProvider<AuthBloc>(
          create: (context) => sl<AuthBloc>(),
        ),
        BlocProvider<NotificationBloc>(
          create: (context) => sl<NotificationBloc>()..add(InitializeNotifications()),
        ),
        BlocProvider<WalletBloc>(
          create: (context) => sl<WalletBloc>()..add(LoadWallets()),
        ),
        BlocProvider<TransactionBloc>(
          create: (context) => sl<TransactionBloc>(),
        ),
        BlocProvider<AccountBloc>(
          create: (context) => sl<AccountBloc>(),
        ),
        BlocProvider<GroupNoteBloc>(
          create: (context) => sl<GroupNoteBloc>(),
        ),
        Provider<TransactionRepository>(
          create: (context) => sl<TransactionRepository>(),
        ),
        Provider<GroupNoteRepository>(
          create: (context) => sl<GroupNoteRepository>(),
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