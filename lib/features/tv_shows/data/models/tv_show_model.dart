import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/tv_show.dart';

class TvShowModel extends TvShow {
  TvShowModel({
    required super.id,
    required super.title,
    required super.posterPath,
    required super.progress,
    required super.totalEpisodes,
    required super.status,
    required super.seasonEpisodeCounts,
    required super.voteAverage,
    super.isFavorite,
    super.episodeRunTime,
    super.episodeRunTimes,
    super.watchedMinutes,
    super.updatedAt,
  });

  factory TvShowModel.fromFirestore(String id, Map<String, dynamic> data) {
    final Timestamp? updatedTimestamp = data['updatedAt'] as Timestamp?;
    
    // Parse the runtimes safely as a list of integers
    final List<int> runTimes = List<int>.from(data['episodeRunTimes'] ?? [data['episodeRunTime'] ?? 45]);
    final int progress = data['progress'] ?? 0;

    // Dynamically calculate accurate watched minutes
    int calculatedWatchedMinutes = 0;
    if (runTimes.length == 1) {
      // Fallback: If the API only gave one average runtime, use it uniformly
      calculatedWatchedMinutes = progress * runTimes.first;
    } else {
      // Dynamic: Add up the actual duration of each watched episode
      for (int i = 0; i < progress; i++) {
        if (i < runTimes.length) {
          calculatedWatchedMinutes += runTimes[i];
        } else {
          // Fallback if progress exceeds mapped episode lengths
          calculatedWatchedMinutes += runTimes.last; 
        }
      }
    }

    return TvShowModel(
      id: id,
      title: data['title'] ?? 'Unknown Show',
      posterPath: data['posterPath'] ?? '',
      progress: progress,
      totalEpisodes: data['totalEpisodes'] ?? 0,
      status: data['status'] ?? 'watching',
      seasonEpisodeCounts: List<int>.from(data['seasonEpisodeCounts'] ?? []),
      voteAverage: (data['voteAverage'] ?? 0.0).toDouble(),
      isFavorite: data['isFavorite'] ?? false,
      episodeRunTime: data['episodeRunTime'] ?? 45,
      episodeRunTimes: runTimes,
      // Use the accurately calculated value if Firestore doesn't explicitly override it
      watchedMinutes: data['watchedMinutes'] as int? ?? calculatedWatchedMinutes,
      updatedAt: updatedTimestamp?.toDate(),
    );
  }
}