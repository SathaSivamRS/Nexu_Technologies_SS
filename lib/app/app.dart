import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/authentication/presentation/providers/auth_provider.dart';
import '../features/authentication/presentation/screens/sign_in_screen.dart';
import 'home_navigation_shell.dart';
import 'theme.dart';

class NexuRouteRunnerApp extends ConsumerWidget {
  const NexuRouteRunnerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return MaterialApp(
      title: 'NEXU RouteRunner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.isLoading
          ? const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Restoring RouteRunner Session...',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : authState.isAuthenticated
              ? const HomeNavigationShell()
              : const SignInScreen(),
    );
  }
}
