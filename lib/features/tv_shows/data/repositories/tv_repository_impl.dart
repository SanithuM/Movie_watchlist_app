import 'package:binged/features/tv_shows/domain/entities/tv_show.dart';

import '../../../../core/services/api_service.dart';

import '../../domain/repositories/tv_repository.dart';
import '../datasources/tv_remote_data_source.dart';

class TvRepositoryImpl implements TvRepository {
  final TvRemoteDataSource remoteDataSource;
  final ApiService _apiService;

  TvRepositoryImpl(this.remoteDataSource, {ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  @override
  Future<void> addShow({
    required String userId,
    required TvShow show,
  }) async {
    List<int> episodeRunTimes = show.episodeRunTimes;

    if (episodeRunTimes.isEmpty || (episodeRunTimes.length == 1 && episodeRunTimes.first == 45)) {
      final constructedRuntimes = <int>[];
      try {
        final details = await _apiService.fetchTvShowDetails(show.id);
        final seasons = details['seasons'] as List<dynamic>? ?? [];
        for (final season in seasons) {
          final seasonNum = season['season_number'] as int?;
          if (seasonNum != null && seasonNum > 0) {
            try {
              final seasonDetails = await _apiService.fetchTvSeasonDetails(show.id, seasonNum);
              final episodes = seasonDetails['episodes'] as List<dynamic>? ?? [];
              for (final ep in episodes) {
                final runtime = ep['runtime'] as int? ?? show.episodeRunTime;
                constructedRuntimes.add(runtime);
              }
            } catch (_) {
              final epCount = season['episode_count'] as int? ?? 0;
              for (int i = 0; i < epCount; i++) {
                constructedRuntimes.add(show.episodeRunTime);
              }
            }
          }
        }
      } catch (_) {}

      if (constructedRuntimes.isNotEmpty) {
        episodeRunTimes = constructedRuntimes;
      }
    }

    final updatedShow = TvShow(
      id: show.id,
      title: show.title,
      posterPath: show.posterPath,
      progress: show.progress,
      totalEpisodes: show.totalEpisodes,
      status: show.status,
      seasonEpisodeCounts: show.seasonEpisodeCounts,
      voteAverage: show.voteAverage,
      isFavorite: show.isFavorite,
      episodeRunTime: show.episodeRunTime,
      episodeRunTimes: episodeRunTimes,
      watchedMinutes: show.watchedMinutes,
      updatedAt: show.updatedAt,
    );

    return await remoteDataSource.addShow(
      userId: userId,
      show: updatedShow,
    );
  }

  @override
  Future<void> markEpisodeAsWatched({
    required String userId,
    required String showId,
    required int seasonNum,
    required int episodeNum,
    int? runtime,
  }) async {
    // This is where you would also add error handling,
    // logging, or logic to check connectivity before calling the source
    return await remoteDataSource.markEpisodeAsWatched(
      userId: userId,
      showId: showId,
      seasonNum: seasonNum,
      episodeNum: episodeNum,
      runtime: runtime,
    );
  }

  @override
  Stream<List<TvShow>> getUserWatchlist(String userId) {
    return remoteDataSource.getUserWatchlist(userId).map(
          (list) => List<TvShow>.from(list),
        );
  }

@override
Future<Map<String, dynamic>> getTvShowDetails(String showId) async {
  try {
    return await _apiService.fetchTvShowDetails(showId);
  } catch (e) {
    throw Exception('Failed to fetch show details: $e');
  }
}

  @override
  Future<List<TvShow>> searchTvShows(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return [];

    final rawData = await _apiService.searchTvShows(normalizedQuery);
    return rawData.map((json) {
      final data = json as Map<String, dynamic>;

      return TvShow(
        id: (data['id'] ?? '').toString(),
        title: data['name'] ?? data['original_name'] ?? 'Unknown Show',
        posterPath: data['poster_path'] != null
            ? 'https://image.tmdb.org/t/p/w500${data['poster_path']}'
            : 'https://via.placeholder.com/200x300',
        progress: 0,
        totalEpisodes: 0,
        status: 'search result',
        seasonEpisodeCounts: [],
        voteAverage: (data['vote_average'] ?? 0.0).toDouble(),
        episodeRunTime: 45,
      );
    }).toList();
  }

  @override
  Future<void> toggleFavorite({
    required String userId,
    required String showId,
    required bool isFavorite,
  }) async {
    return await remoteDataSource.toggleFavorite(
      userId: userId,
      showId: showId,
      isFavorite: isFavorite,
    );
  }

  @override
  Future<void> dropShow({
    required String userId,
    required String showId,
  }) async {
    return await remoteDataSource.dropShow(
      userId: userId,
      showId: showId,
    );
  }

  @override
  Future<void> unmarkEpisodeAsWatched({
    required String userId,
    required String showId,
    required int seasonNum,
    required int episodeNum,
  }) async {
    return await remoteDataSource.unmarkEpisodeAsWatched(
      userId: userId,
      showId: showId,
      seasonNum: seasonNum,
      episodeNum: episodeNum,
    );
  }

  @override
  Future<void> toggleSeasonWatched({
    required String userId,
    required String showId,
    required int seasonNum,
    required int totalEpisodesInSeason,
    required List<String> watchedEpisodeIds,
    required int fallbackRuntime,
  }) async {
    Map<int, int> episodeRuntimes = {};
    try {
      final seasonDetails = await _apiService.fetchTvSeasonDetails(showId, seasonNum);
      final episodes = seasonDetails['episodes'] as List<dynamic>? ?? [];
      for (final ep in episodes) {
        final epNum = ep['episode_number'] as int?;
        if (epNum != null) {
          episodeRuntimes[epNum] = ep['runtime'] as int? ?? fallbackRuntime;
        }
      }
    } catch (e) {
      for (int i = 1; i <= totalEpisodesInSeason; i++) {
        episodeRuntimes[i] = fallbackRuntime;
      }
    }

    return await remoteDataSource.toggleSeasonWatched(
      userId: userId,
      showId: showId,
      seasonNum: seasonNum,
      totalEpisodesInSeason: totalEpisodesInSeason,
      watchedEpisodeIds: watchedEpisodeIds,
      episodeRuntimes: episodeRuntimes,
    );
  }

  @override
  Future<void> toggleAllEpisodesWatched({
    required String userId,
    required String showId,
    required List<Map<String, dynamic>> seasonsList,
    required List<String> watchedEpisodeIds,
    required int fallbackRuntime,
  }) async {
    final Map<String, int> episodeRuntimes = {};
    try {
      final List<Future<Map<String, dynamic>>> seasonFutures = [];
      final List<int> seasonNums = [];
      for (final s in seasonsList) {
        final sNum = s['season_number'] as int? ?? 0;
        if (sNum > 0) {
          seasonFutures.add(_apiService.fetchTvSeasonDetails(showId, sNum));
          seasonNums.add(sNum);
        }
      }
      final seasonsDetails = await Future.wait(seasonFutures);
      for (int i = 0; i < seasonsDetails.length; i++) {
        final details = seasonsDetails[i];
        final seasonNum = seasonNums[i];
        final episodes = details['episodes'] as List<dynamic>? ?? [];
        for (final ep in episodes) {
          final epNum = ep['episode_number'] as int?;
          if (epNum != null) {
            episodeRuntimes['S${seasonNum}E$epNum'] = ep['runtime'] as int? ?? fallbackRuntime;
          }
        }
      }
    } catch (e) {
      for (final s in seasonsList) {
        final seasonNum = s['season_number'] as int? ?? 0;
        final episodeCount = s['episode_count'] as int? ?? 0;
        for (int i = 1; i <= episodeCount; i++) {
          episodeRuntimes['S${seasonNum}E$i'] = fallbackRuntime;
        }
      }
    }

    return await remoteDataSource.toggleAllEpisodesWatched(
      userId: userId,
      showId: showId,
      seasonsList: seasonsList,
      watchedEpisodeIds: watchedEpisodeIds,
      episodeRuntimes: episodeRuntimes,
    );
  }

  @override
  Future<void> resetShowProgress({
    required String userId,
    required String showId,
    required List<String> watchedEpisodeIds,
  }) async {
    return await remoteDataSource.resetShowProgress(
      userId: userId,
      showId: showId,
      watchedEpisodeIds: watchedEpisodeIds,
    );
  }
}