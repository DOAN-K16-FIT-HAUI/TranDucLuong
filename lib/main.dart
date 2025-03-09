import 'package:datn_haui/data/repositories/transaction_repository.dart';
import 'package:datn_haui/features/auth/screens/login_screen.dart';
import 'package:datn_haui/features/auth/screens/signup_screen.dart';
import 'package:datn_haui/features/transactions/bloc/transation_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/transactions/screens/transaction_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(),
        ),
        BlocProvider(
          create: (context) => TransactionBloc(
            transactionRepository: TransactionRepository(userId: "uid"),
          )..add(LoadTransactions()),
        ),
      ],
      child: MaterialApp(
        initialRoute: FirebaseAuth.instance.currentUser == null ? '/' : '/transactions',
        routes: {
          '/': (context) => LoginScreen(),
          '/signup': (context) => SignupScreen(),
          '/transactions': (context) => TransactionScreen(),
        },
      ),
    );
  }
}