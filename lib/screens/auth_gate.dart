import 'package:flutter/material.dart';
import 'package:priyanakaenterprises/screens/homescreen.dart';
import 'package:priyanakaenterprises/screens/login_screen.dart';
import 'package:priyanakaenterprises/services/auth_provider.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the AuthProvider for changes
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading) {
      // Show a loading screen while checking auth state
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Check the custom isLoggedIn getter
    if (authProvider.isLoggedIn) {
      // User is logged in and verified as distributor
      return const HomeScreen();
    } else {
      // User is not logged in or not a distributor
      return const LoginScreen();
    }
  }
}