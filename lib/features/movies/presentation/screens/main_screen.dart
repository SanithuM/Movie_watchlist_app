// Bottom-tab main screen that switches between core pages.
import 'package:binged/features/movies/presentation/screens/movie_screen.dart';
import 'package:binged/features/movies/presentation/screens/profile_screen.dart';
import 'package:binged/features/movies/presentation/screens/search_screen.dart';
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey[900]!, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
          currentIndex: _currentIndex,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, height: 1.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, height: 1.5),
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.live_tv_outlined, size: 24),
              activeIcon: Icon(Icons.live_tv, size: 24),
              label: 'Shows',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.movie_creation_outlined, size: 24),
              activeIcon: Icon(Icons.movie, size: 24),
              label: 'Movies',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search, size: 24),
              activeIcon: Icon(Icons.search, size: 24),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 24),
              activeIcon: Icon(Icons.person, size: 24),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}