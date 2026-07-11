import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/datasources/tv_remote_data_source.dart';
import '../../data/repositories/tv_repository_impl.dart';
import '../../domain/repositories/tv_repository.dart';
import '../../domain/entities/tv_show.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/episode_calculator.dart';

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

final tvSeasonDetailsProvider = FutureProvider.family.autoDispose<Map<String, dynamic>, String>((ref, param) async {
  final parts = param.split(':');
  final showId = parts[0];
  final seasonNum = int.parse(parts[1]);
  final apiService = ref.watch(apiServiceProvider);
  return apiService.fetchTvSeasonDetails(showId, seasonNum);
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
    int? runtime,
  }) async {
    state = const AsyncLoading();

    try {
      await ref.read(tvRepositoryProvider).markEpisodeAsWatched(
        userId: userId,
        showId: showId,
        seasonNum: seasonNum,
        episodeNum: episodeNum,
        runtime: runtime,
      );
      state = const AsyncData(null);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }

  Future<void> toggleFavorite({
    required String userId,
    required String showId,
    required bool currentStatus,
  }) async {
    state = const AsyncLoading();

    try {
      await ref.read(tvRepositoryProvider).toggleFavorite(
        userId: userId,
        showId: showId,
        isFavorite: !currentStatus,
      );
      state = const AsyncData(null);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }

  Future<void> dropShow({
    required String userId,
    required String showId,
  }) async {
    state = const AsyncLoading();

    try {
      await ref.read(tvRepositoryProvider).dropShow(
        userId: userId,
        showId: showId,
      );
      state = const AsyncData(null);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }

  Future<void> unmarkEpisodeAsWatched({
    required String userId,
    required String showId,
    required int seasonNum,
    required int episodeNum,
  }) async {
    state = const AsyncLoading();

    try {
      await ref.read(tvRepositoryProvider).unmarkEpisodeAsWatched(
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

  Future<void> toggleSeasonWatched({
    required String userId,
    required String showId,
    required int seasonNum,
    required int totalEpisodesInSeason,
    required List<String> watchedEpisodeIds,
    required int fallbackRuntime,
  }) async {
    state = const AsyncLoading();

    try {
      await ref.read(tvRepositoryProvider).toggleSeasonWatched(
        userId: userId,
        showId: showId,
        seasonNum: seasonNum,
        totalEpisodesInSeason: totalEpisodesInSeason,
        watchedEpisodeIds: watchedEpisodeIds,
        fallbackRuntime: fallbackRuntime,
      );
      state = const AsyncData(null);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }

  Future<void> toggleAllEpisodesWatched({
    required String userId,
    required String showId,
    required List<Map<String, dynamic>> seasonsList,
    required List<String> watchedEpisodeIds,
    required int fallbackRuntime,
  }) async {
    state = const AsyncLoading();

    try {
      await ref.read(tvRepositoryProvider).toggleAllEpisodesWatched(
        userId: userId,
        showId: showId,
        seasonsList: seasonsList,
        watchedEpisodeIds: watchedEpisodeIds,
        fallbackRuntime: fallbackRuntime,
      );
      state = const AsyncData(null);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }

  Future<void> resetShowProgress({
    required String userId,
    required String showId,
    required List<String> watchedEpisodeIds,
  }) async {
    state = const AsyncLoading();

    try {
      await ref.read(tvRepositoryProvider).resetShowProgress(
        userId: userId,
        showId: showId,
        watchedEpisodeIds: watchedEpisodeIds,
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

final tvWatchedEpisodesProvider = StreamProvider.family<List<String>, String>((ref, showId) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('trackedShows')
      .doc(showId)
      .collection('episodes')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
});

class UpcomingEpisode {
  final TvShow show;
  final int seasonNumber;
  final int episodeNumber;
  final String episodeTitle;
  final DateTime airDate;
  final String airTime; // e.g. "8:30 AM" or "5:30 PM"
  final String network;  // e.g. "ADULT SWIM"
  final bool isAired;

  UpcomingEpisode({
    required this.show,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.episodeTitle,
    required this.airDate,
    required this.airTime,
    required this.network,
    required this.isAired,
  });
}

final tvUpcomingEpisodesProvider = FutureProvider.family<List<UpcomingEpisode>, String>((ref, userId) async {
  final watchlistAsync = ref.watch(tvWatchlistProvider(userId));
  final shows = watchlistAsync.value ?? [];
  
  final List<UpcomingEpisode> upcomingList = [];
  
  for (final show in shows) {
    if (show.status == 'dropped') continue;

    // Calculate next unwatched episode
    final nextEpData = EpisodeCalculator.getNextEpisode(
      show.progress,
      show.seasonEpisodeCounts,
    );
    final int nextSeason = nextEpData['season']!;
    final int nextEpisode = nextEpData['episode']!;
    if (nextSeason == -1) continue; // completed

    try {
      // 1. Fetch show details to get networks
      final showDetails = await ref.read(tvShowDetailsProvider(show.id).future);
      final networks = showDetails['networks'] as List<dynamic>?;
      final networkName = (networks != null && networks.isNotEmpty)
          ? (networks[0]['name'] ?? 'Unknown Network').toString().toUpperCase()
          : 'UNKNOWN NETWORK';

      // 2. Fetch season details for the next season
      final seasonDetails = await ref.read(tvSeasonDetailsProvider('${show.id}:$nextSeason').future);
      final episodes = seasonDetails['episodes'] as List<dynamic>? ?? [];

      for (final ep in episodes) {
        final epNum = ep['episode_number'] as int? ?? 0;
        
        // Include unwatched episodes
        if (epNum >= nextEpisode) {
          final airDateStr = ep['air_date'] as String?;
          if (airDateStr == null || airDateStr.isEmpty) continue;
          
          final airDate = DateTime.tryParse(airDateStr);
          if (airDate == null) continue;

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final epDateOnly = DateTime(airDate.year, airDate.month, airDate.day);
          
          // Only include if airDate is within the last 14 days or in the future
          if (epDateOnly.isBefore(today.subtract(const Duration(days: 14)))) {
            continue;
          }

          final isAired = epDateOnly.isBefore(today) || epDateOnly.isAtSameMomentAs(today);

          // Plausible air time mapping based on network
          String airTime = '8:00 PM';
          if (networkName.contains('ADULT SWIM')) {
            airTime = '8:30 AM';
          } else if (networkName.contains('AT-X')) {
            airTime = '5:30 PM';
          } else if (networkName.contains('HBO')) {
            airTime = '9:00 PM';
          } else if (networkName.contains('NETFLIX')) {
            airTime = '12:00 AM';
          }

          upcomingList.add(UpcomingEpisode(
            show: show,
            seasonNumber: nextSeason,
            episodeNumber: epNum,
            episodeTitle: ep['name'] ?? 'TBA',
            airDate: epDateOnly,
            airTime: airTime,
            network: networkName,
            isAired: isAired,
          ));
        }
      }
    } catch (e) {
      print('Error fetching upcoming for show ID ${show.id}: $e');
    }
  }

  // Sort chronologically by airDate
  upcomingList.sort((a, b) => a.airDate.compareTo(b.airDate));
  return upcomingList;
});

final tvSortedWatchlistProvider = FutureProvider.family<List<TvShow>, String>((ref, userId) async {
  final watchlistAsync = ref.watch(tvWatchlistProvider(userId));
  final shows = watchlistAsync.value ?? [];

  final List<MapEntry<TvShow, DateTime>> sortedEntries = [];

  for (final show in shows) {
    if (show.status == 'dropped') continue;

    // Calculate current next unwatched episode
    final nextEpData = EpisodeCalculator.getNextEpisode(
      show.progress,
      show.seasonEpisodeCounts,
    );
    final int nextSeason = nextEpData['season']!;
    final int nextEpisode = nextEpData['episode']!;

    if (nextSeason == -1) {
      // Completed shows go to the bottom
      sortedEntries.add(MapEntry(show, DateTime(1970)));
      continue;
    }

    try {
      final seasonDetails = await ref.read(tvSeasonDetailsProvider('${show.id}:$nextSeason').future);
      final episodes = seasonDetails['episodes'] as List<dynamic>? ?? [];
      final currentEp = episodes.firstWhere(
        (ep) => ep['episode_number'] == nextEpisode,
        orElse: () => null,
      );

      DateTime sortDate = DateTime(1970);
      if (currentEp != null) {
        final airDateStr = currentEp['air_date'] as String?;
        if (airDateStr != null && airDateStr.isNotEmpty) {
          final parsed = DateTime.tryParse(airDateStr);
          if (parsed != null) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            // We sort by airDate only if it has already released (i.e. is today or in the past)
            if (parsed.isBefore(today) || parsed.isAtSameMomentAs(today)) {
              sortDate = parsed;
            }
          }
        }
      }
      sortedEntries.add(MapEntry(show, sortDate));
    } catch (e) {
      // Fallback to updatedAt or fallback very low date if failed to load
      sortedEntries.add(MapEntry(show, show.updatedAt ?? DateTime(1970)));
    }
  }

  // Sort by sortDate descending (newest released first).
  // If the sortDate is equal (e.g. both are DateTime(1970)), fallback to ordering by updatedAt descending
  sortedEntries.sort((a, b) {
    final cmp = b.value.compareTo(a.value);
    if (cmp != 0) return cmp;
    
    final aUpdated = a.key.updatedAt ?? DateTime(1970);
    final bUpdated = b.key.updatedAt ?? DateTime(1970);
    return bUpdated.compareTo(aUpdated);
  });

  return sortedEntries.map((e) => e.key).toList();
});