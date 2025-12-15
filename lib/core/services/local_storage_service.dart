// Simple local cache using Hive for storing movie lists.
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocalStorageService {
  static const String _movieBoxName = 'movie_cache';

  // Initialize Hive
  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_movieBoxName);
  }

  // Save a list of movies (from API JSON) to local storage
  // Cache raw movie JSON under 'trending'.
  Future<void> cacheMovies(List<dynamic> movies) async {
    final box = Hive.box(_movieBoxName);
    // We store the list under a specific key, e.g., 'trending'
    await box.put('trending', movies);
  }

  // Retrieve movies when offline
  // Short: Return cached trending movies or empty list.
  List<dynamic> getCachedMovies() {
    final box = Hive.box(_movieBoxName);
    // Return empty list if nothing is saved
    return box.get('trending', defaultValue: []); 
  }
}

// RIVERPOD PROVIDER
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});