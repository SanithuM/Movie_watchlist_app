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
  });

  Stream<List<TvShow>> getUserWatchlist(String userId);

  Future<List<TvShow>> searchTvShows(String query);

  Future<Map<String, dynamic>> getTvShowDetails(String showId);
}
