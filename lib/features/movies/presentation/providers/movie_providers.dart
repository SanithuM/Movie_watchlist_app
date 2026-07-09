import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../data/repositories/movie_repository.dart';
import '../../data/models/movie_model.dart';

// Provider for the Movie Repository itself
final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  final api = ref.read(apiServiceProvider);
  final storage = ref.read(localStorageServiceProvider);

  return MovieRepository(api, storage);
});

// Stream Provider for the User's Personal Movie Watchlist from Firestore
final movieWatchlistProvider = StreamProvider<List<Movie>>((ref) {
  final repository = ref.watch(movieRepositoryProvider);

  // Listen to the Firebase Auth state changes implicitly
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return Stream.value([]);
  }

  // Assumes your MovieRepository has a method returning a Stream<List<Movie>> from Firestore
  return repository.streamUserWatchlist(user.uid);
});

// Future Provider for Trending Movies
final trendingMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final repository = ref.watch(movieRepositoryProvider);
  return repository.getTrendingMovies();
});

// Future Provider for Now Playing Movies
final nowPlayingMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final repository = ref.watch(movieRepositoryProvider);
  return repository.getNowPlayingMovies();
});

// Notifier Provider for performing write operations on the Movie Watchlist
final movieActionProvider =
    AsyncNotifierProvider<MovieActionNotifier, void>(MovieActionNotifier.new);

class MovieActionNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Add a movie to the watchlist or log a new entry
  Future<void> addMovieToWatchlist(Movie movie) async {
    final userId = _currentUserId;
    if (userId == null) return;

    state = const AsyncLoading();
    try {
      await ref.read(movieRepositoryProvider).addMovie(userId, movie);
      state = const AsyncData(null);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }

  // Update movie status (e.g., changing status from 'watchlist' to 'completed')
  Future<void> updateMovieStatus(String movieId, String status) async {
    final userId = _currentUserId;
    if (userId == null) return;

    state = const AsyncLoading();
    try {
      await ref.read(movieRepositoryProvider).updateMovieStatus(userId, movieId, status);
      state = const AsyncData(null);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }

  // Remove a movie entirely from the personal tracking list
  Future<void> removeMovieFromWatchlist(String movieId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    state = const AsyncLoading();
    try {
      await ref.read(movieRepositoryProvider).deleteMovie(userId, movieId);
      state = const AsyncData(null);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }
}
