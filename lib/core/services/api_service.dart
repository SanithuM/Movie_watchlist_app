//HTTP client for TMDB; provides fetch and search helpers.
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiService {
  // Base URL for TMDB
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _apiKey = 'ad18282e6d80edc89aaae58570b501a4';

  final Dio _dio;

  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 10), // Timeout after 10s
          receiveTimeout: const Duration(seconds: 10),
          queryParameters: {
            'api_key': _apiKey, // Automatically adds API key to every request
            'language': 'en-US',
          },
        ),
      );

  // Example: Fetch Trending Movies
  // Retrieve weekly trending movies list from TMDB.
  Future<List<dynamic>> fetchTrendingMovies() async {
    try {
      final response = await _dio.get('/trending/movie/week');

      if (response.statusCode == 200) {
        // Return the list of movies from the 'results' field
        return response.data['results'];
      } else {
        throw Exception('Failed to load movies');
      }
    } on DioException catch (e) {
      // Handle Dio-specific errors (no internet, server down, etc.)
      throw Exception('Network Error: ${e.message}');
    }
  }

  Future<List<dynamic>> searchMovies(String query) async {
    // Search TMDB for movies matching `query`.
    try {
      final response = await _dio.get(
        '/search/movie',
        queryParameters: {'query': query}, // Pass the user's search text
      );

      if (response.statusCode == 200) {
        return response.data['results'];
      } else {
        throw Exception('Failed to search movies');
      }
    } on DioException catch (e) {
      throw Exception('Network Error: ${e.message}');
    }
  }

  // Add this inside ApiService
  Future<List<dynamic>> fetchNowPlayingMovies() async {
    // Get movies currently playing in theaters.
    try {
      final response = await _dio.get('/movie/now_playing');
      if (response.statusCode == 200) {
        return response.data['results'];
      } else {
        throw Exception('Failed to load now playing movies');
      }
    } on DioException catch (e) {
      throw Exception('Network Error: ${e.message}');
    }
  }
}

// RIVERPOD PROVIDER
// This allows to access ApiService anywhere in the app using "ref.read(apiServiceProvider)"
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
