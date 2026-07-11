import '../entities/tv_show.dart';

abstract class TvRepository {
  Future<void> addShow({
    required String userId,
    required TvShow show,
  });

  Future<void> markEpisodeAsWatched({
    required String userId,
    required String showId,
    required int seasonNum,
    required int episodeNum,
    int? runtime,
  });

  Stream<List<TvShow>> getUserWatchlist(String userId);

  Future<List<TvShow>> searchTvShows(String query);

  Future<Map<String, dynamic>> getTvShowDetails(String showId);

  Future<void> toggleFavorite({
    required String userId,
    required String showId,
    required bool isFavorite,
  });

  Future<void> dropShow({
    required String userId,
    required String showId,
  });

  Future<void> unmarkEpisodeAsWatched({
    required String userId,
    required String showId,
    required int seasonNum,
    required int episodeNum,
  });

  Future<void> toggleSeasonWatched({
    required String userId,
    required String showId,
    required int seasonNum,
    required int totalEpisodesInSeason,
    required List<String> watchedEpisodeIds,
    required int fallbackRuntime,
  });

  Future<void> toggleAllEpisodesWatched({
    required String userId,
    required String showId,
    required List<Map<String, dynamic>> seasonsList,
    required List<String> watchedEpisodeIds,
    required int fallbackRuntime,
  });

  Future<void> resetShowProgress({
    required String userId,
    required String showId,
    required List<String> watchedEpisodeIds,
  });
}
