// Bottom-tab main screen that switches between core pages.
import 'package:cinelist/features/movies/presentation/screens/movie_screen.dart';
import 'package:cinelist/features/movies/presentation/screens/profile_screen.dart';
import 'package:cinelist/features/movies/presentation/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // The screens for each tab
  final List<Widget> _screens = [
    const HomeScreen(),                          // 0: Home
    const MovieScreen(),                         // 1: Movies
    const SearchScreen(),                        // 2: Search
    const ProfileScreen(),                       // 3: Profile


  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1A1A), // Dark footer
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'Movies'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}