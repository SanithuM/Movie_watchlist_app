import 'package:cinelist/features/tv_shows/domain/entities/tv_show.dart';

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
    return await remoteDataSource.addShow(
      userId: userId,
      show: show,
    );
  }

  @override
  Future<void> markEpisodeAsWatched({
    required String userId,
    required String showId,
    required int seasonNum,
    required int episodeNum,
  }) async {
    // This is where you would also add error handling,
    // logging, or logic to check connectivity before calling the source
    return await remoteDataSource.markEpisodeAsWatched(
      userId: userId,
      showId: showId,
      seasonNum: seasonNum,
      episodeNum: episodeNum,
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
  }) async {
    return await remoteDataSource.toggleSeasonWatched(
      userId: userId,
      showId: showId,
      seasonNum: seasonNum,
      totalEpisodesInSeason: totalEpisodesInSeason,
      watchedEpisodeIds: watchedEpisodeIds,
    );
  }

  @override
  Future<void> toggleAllEpisodesWatched({
    required String userId,
    required String showId,
    required List<Map<String, dynamic>> seasonsList,
    required List<String> watchedEpisodeIds,
  }) async {
    return await remoteDataSource.toggleAllEpisodesWatched(
      userId: userId,
      showId: showId,
      seasonsList: seasonsList,
      watchedEpisodeIds: watchedEpisodeIds,
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