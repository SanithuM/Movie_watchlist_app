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
    super.updatedAt,
  });

  factory TvShowModel.fromFirestore(String id, Map<String, dynamic> data) {
    final Timestamp? updatedTimestamp = data['updatedAt'] as Timestamp?;
    return TvShowModel(
      id: id,
      title: data['title'] ?? 'Unknown Show',
      posterPath: data['posterPath'] ?? '',
      progress: data['progress'] ?? 0,
      totalEpisodes: data['totalEpisodes'] ?? 0,
      status: data['status'] ?? 'watching',
      seasonEpisodeCounts: List<int>.from(data['seasonEpisodeCounts'] ?? []),
      voteAverage: (data['voteAverage'] ?? 0.0).toDouble(),
      isFavorite: data['isFavorite'] ?? false,
      episodeRunTime: data['episodeRunTime'] ?? 45,
      updatedAt: updatedTimestamp?.toDate(),
    );
  }
}