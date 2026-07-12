//HTTP client for TMDB; provides fetch and search helpers.
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiService {
  // Base URL for TMDB
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  final Dio _dio;

  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 10), // Timeout after 10s
          receiveTimeout: const Duration(seconds: 10),
          queryParameters: {
            'api_key': dotenv.env['TMDB_API_KEY'] ?? '', // Automatically adds API key to every request
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

  Future<List<dynamic>> searchMovies(String query, {String? year}) async {
    // Search TMDB for movies matching `query`.
    try {
      final response = await _dio.get(
        '/search/movie',
        queryParameters: {
          'query': query.trim(),
          if (year != null && year.trim().isNotEmpty)
            'primary_release_year': year.trim(),
        }, // Pass the user's search text
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

  // TV search method
  Future<List<dynamic>> searchTvShows(String query, {String? year}) async {
    // Search TMDB for TV shows matching `query`
    try {
      final response = await _dio.get(
        '/search/tv',
        queryParameters: {
          'query': query.trim(),
          if (year != null && year.trim().isNotEmpty)
            'first_air_date_year': year.trim(),
        },
      );

      if (response.statusCode == 200) {
        return response.data['results'];
      } else {
        throw Exception('Failed to search TV shows');
      }
    } on DioException catch (e) {
      throw Exception('Network Error: ${e.message}');
    }
  }

  // Fetch full details for tv show

  Future<Map<String, dynamic>> fetchTvShowDetails(String showId) async {
    try {
      // TMDB endpoint for full series details
      final response = await _dio.get('/tv/$showId');

      if (response.statusCode == 200) {
        // Returning a Map here instead of a List because a specific
        // show returns a single JSON object, not an array of results.
        return response.data;
      } else {
        throw Exception('Failed to load TV show details');
      }
    } on DioException catch (e) {
      throw Exception('Network Error: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> fetchTvSeasonDetails(String showId, int seasonNum) async {
    try {
      final response = await _dio.get('/tv/$showId/season/$seasonNum');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load TV season details');
      }
    } on DioException catch (e) {
      throw Exception('Network Error: ${e.message}');
    }
  }

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

  Future<List<dynamic>> fetchTrendingTvShows() async {
    try {
      final response = await _dio.get('/trending/tv/week');
      if (response.statusCode == 200) {
        return response.data['results'];
      } else {
        throw Exception('Failed to load trending TV shows');
      }
    } on DioException catch (e) {
      throw Exception('Network Error: ${e.message}');
    }
  }
}

// RIVERPOD PROVIDER
// This allows to access ApiService anywhere in the app using "ref.read(apiServiceProvider)"
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
