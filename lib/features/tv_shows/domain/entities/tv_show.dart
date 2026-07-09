class TvShow {
  final String id;
  final String title;
  final String posterPath;
  final int progress;
  final int totalEpisodes;
  final String status;
  final List<int> seasonEpisodeCounts;
  final double voteAverage;
  final bool isFavorite;
  final int episodeRunTime;
  final DateTime? updatedAt;

  TvShow({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.progress,
    required this.totalEpisodes,
    required this.status,
    required this.seasonEpisodeCounts,
    this.voteAverage = 0.0,
    this.isFavorite = false,
    this.episodeRunTime = 45,
    this.updatedAt,
  });
}