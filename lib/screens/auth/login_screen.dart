import 'package:finance_app/blocs/auth/auth_event.dart';
import 'package:finance_app/blocs/auth/auth_state.dart';
import 'package:finance_app/core/AppRoutes.dart';
import 'package:finance_app/screens/auth/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finance_app/blocs/auth/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            AppRoutes.navigateToDashboard(context);
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthLoading) {
                    return const CircularProgressIndicator();
                  }
                  return Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          context.read<AuthBloc>().add(
                            SignInRequested(
                              email: _emailController.text,
                              password: _passwordController.text,
                            ),
                          );
                        },
                        child: const Text('Login'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          context.read<AuthBloc>().add(const SignInWithGoogleRequested());
                        },
                        child: const Text('Login with Google'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  AppRoutes.navigateToRegister(context);
                },
                child: const Text('Don\'t have an account? Register here'),
              ),
              // Trong LoginScreen
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                  );
                },
                child: const Text('Quên mật khẩu?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}