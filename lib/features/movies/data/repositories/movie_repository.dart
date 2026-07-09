// Repository coordinating API + local cache for Movie data.
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../models/movie_model.dart';

class MovieRepository {
  final ApiService _apiService;
  final LocalStorageService _localStorage;

  MovieRepository(this._apiService, this._localStorage);

  // Returns trending movies; prefers online then falls back to cache.
  Future<List<Movie>> getTrendingMovies() async {
    // Check Internet Connection
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = connectivityResult != ConnectivityResult.none;

    if (hasInternet) {
      try {
        // ONLINE FLOW
        print('Fetching from API...');
        
        // Fetch raw data from API
        final rawData = await _apiService.fetchTrendingMovies();
        
        // Convert raw JSON to Movie objects
        final movies = rawData.map((json) => Movie.fromJson(json)).toList();

        // Save to Local Storage immediately
        // This ensures next time they are offline, data is there.
        // We convert back to JSON because our Hive setup stores raw maps.
        await _localStorage.cacheMovies(rawData); 
        
        return movies;

      } catch (e) {
        // If API fails (server error), fallback to offline
        print('API Error: $e. Switching to offline mode.');
        return _getDestinedData();
      }
    } else {
      // OFFLINE FLOW
      print('No Internet. Fetching from Local Storage...');
      return _getDestinedData();
    }
  }

  // Helper to get data from Hive
  List<Movie> _getDestinedData() {
    final cachedData = _localStorage.getCachedMovies();
    // Convert the cached JSON list into Movie objects
    // 'cast<Map<dynamic, dynamic>>' helps fix Hive type issues
    return cachedData
        .map((json) => Movie.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }
  Future<List<Movie>> searchMovies(String query) async {
    // Search for movies via API (requires internet).
    if (query.isEmpty) return [];

    // Check internet (Search usually requires internet)
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw Exception("No internet connection for search.");
    }

    try {
      final rawData = await _apiService.searchMovies(query);
      // Convert JSON to Movie objects
      return rawData.map((json) => Movie.fromJson(json)).toList();
    } catch (e) {
      throw Exception(e.toString());
    }
  }
  // Add this inside MovieRepository
  // Fetch now-playing movies (simple API call for now).
  Future<List<Movie>> getNowPlayingMovies() async {
    try {
      final rawData = await _apiService.fetchNowPlayingMovies();
      return rawData.map((json) => Movie.fromJson(json)).toList();
    } catch (e) {
      // In a real app, return cached data when offline.
      return [];
    }
  }

  // Get real-time updates for user's movie watchlist/wishlist from Firestore
  Stream<List<Movie>> streamUserWatchlist(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Movie.fromJson(doc.data()))
              .toList();
        });
  }

  // Add a movie to the watchlist in Firestore
  Future<void> addMovie(String userId, Movie movie) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(movie.id.toString())
        .set(movie.toJson());
  }

  // Update movie status (e.g. isWatched) in Firestore
  Future<void> updateMovieStatus(String userId, String movieId, String status) async {
    final isWatched = status == 'completed';
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(movieId)
        .update({'is_watched': isWatched});
  }

  // Delete a movie from the watchlist in Firestore
  Future<void> deleteMovie(String userId, String movieId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(movieId)
        .delete();
  }
}