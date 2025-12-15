//sets theme and app routes.
import 'package:cinelist/features/movies/presentation/screens/main_screen.dart';
import 'features/movies/presentation/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'features/auth/presentation/signup_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/movies/presentation/screens/home_screen.dart';
import 'core/widgets/auth_wrapper.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CineList', // Project Name
      // 1. Theme Configuration (Blue)
      theme: ThemeData(
        brightness: Brightness.dark, // Dark mode is best for Movie apps
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue,

        // Modern Material 3 Color Scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
          secondary: Colors.amber, // Good accent color for "Stars/Ratings"
        ),

        // Standardize input styles
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[900],
        ),

        useMaterial3: true,
      ),

      // 2. Navigation Routes
      // This defines the "Map" of the application
      home: const AuthWrapper(), // Decides initial screen based on auth state
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}
