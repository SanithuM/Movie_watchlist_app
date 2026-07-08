import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/datasources/tv_remote_data_source.dart';
import '../../data/repositories/tv_repository_impl.dart';
import '../../domain/repositories/tv_repository.dart';
import '../../domain/entities/tv_show.dart';

// --- 1. Dependency Injection ---
// These providers ensure you only instantiate your Firebase and Repo classes once.

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final tvRemoteDataSourceProvider = Provider<TvRemoteDataSource>((ref) {
  final db = ref.watch(firebaseFirestoreProvider);
  return TvRemoteDataSource(db: db);
});

final tvRepositoryProvider = Provider<TvRepository>((ref) {
  final dataSource = ref.watch(tvRemoteDataSourceProvider);
  return TvRepositoryImpl(dataSource);
});

final tvWatchlistProvider = StreamProvider.family<List<TvShow>, String>((ref, userId) {
  final repository = ref.watch(tvRepositoryProvider);
  return repository.getUserWatchlist(userId);
});

final tvShowDetailsProvider = FutureProvider.family.autoDispose<Map<String, dynamic>, String>((ref, showId) async {
  final repository = ref.watch(tvRepositoryProvider);
  return repository.getTvShowDetails(showId);
});

// --- 2. Action State Notifier ---
// This handles user actions (like tapping "Mark Watched") and tracks the
// loading/error state so your UI can show a spinner or error dialog.

class TvShowActionNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addShow({
    required String userId,
    required TvShow show,
  }) async {
    state = const AsyncLoading();

    try {
      await ref.read(tvRepositoryProvider).addShow(
        userId: userId,
        show: show,
      );
      state = const AsyncData(null);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }

  Future<void> markEpisodeWatched({
    required String userId,
    required String showId,
    required int seasonNum,
    required int episodeNum,
  }) async {
    state = const AsyncLoading();

    try {
      await ref.read(tvRepositoryProvider).markEpisodeAsWatched(
        userId: userId,
        showId: showId,
        seasonNum: seasonNum,
        episodeNum: episodeNum,
      );
      state = const AsyncData(null);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }
}

// Expose the Notifier to the UI
final tvShowActionProvider =
    AsyncNotifierProvider<TvShowActionNotifier, void>(TvShowActionNotifier.new);