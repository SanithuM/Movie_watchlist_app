import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/data/auth_service.dart'; // Import  auth provider
import '../../features/movies/presentation/screens/main_screen.dart'; // App Home
import '../../features/movies/presentation/screens/welcome_screen.dart'; // Login/Start Page

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the authentication state from Firebase
    final authState = ref.watch(authStateProvider);

    return authState.when(
      // DATA LOADED: Check if user exists
      data: (User? user) {
        if (user != null) {
          // User is logged in -> Go to Main App
          return const MainScreen();
        } else {
          // No user -> Go to Welcome/Login
          return const WelcomeScreen();
        }
      },
      // Show a black screen with spinner while checking
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
      // Show error message if something breaks
      error: (e, stack) => Scaffold(
        body: Center(child: Text("Auth Error: $e")),
      ),
    );
  }
}