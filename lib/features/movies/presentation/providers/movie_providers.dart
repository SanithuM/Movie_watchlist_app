// Riverpod providers for movie repository, trending and now-playing.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../data/repositories/movie_repository.dart';
import '../../data/models/movie_model.dart';

// Provider for the Repository itself
final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  final api = ref.read(apiServiceProvider);
  final storage = ref.read(localStorageServiceProvider);
  
  return MovieRepository(api, storage);
});

// Provider for "Trending"
final trendingMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final repository = ref.watch(movieRepositoryProvider);
  return repository.getTrendingMovies();
});

// Provider for "New Releases"
final nowPlayingMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final repository = ref.watch(movieRepositoryProvider);
  return repository.getNowPlayingMovies();
});