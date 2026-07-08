import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tv_show_model.dart';

class TvRemoteDataSource {
  final FirebaseFirestore _db;

  TvRemoteDataSource({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  Future<void> addShow({
    required String userId,
    required dynamic show,
  }) async {
    final showRef = _db
        .collection('users')
        .doc(userId)
        .collection('trackedShows')
        .doc(show.id);

    await showRef.set({
      'id': show.id,
      'title': show.title,
      'posterPath': show.posterPath,
      'progress': show.progress,
      'totalEpisodes': show.totalEpisodes,
      'status': show.status,
      'seasonEpisodeCounts': show.seasonEpisodeCounts,
      'voteAverage': show.voteAverage,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markEpisodeAsWatched({
    required String userId,
    required String showId,
    required int seasonNum,
    required int episodeNum,
  }) async {
    final batch = _db.batch();

    final showRef = _db
        .collection('users')
        .doc(userId)
        .collection('trackedShows')
        .doc(showId);

    final episodeId = 'S${seasonNum}E$episodeNum';
    final episodeRef = showRef.collection('episodes').doc(episodeId);

    batch.set(episodeRef, {
      'seasonNumber': seasonNum,
      'episodeNumber': episodeNum,
      'watchedAt': FieldValue.serverTimestamp(),
    });

    batch.set(showRef, {
      'progress': FieldValue.increment(1),
      'lastWatchedSeason': seasonNum,
      'lastWatchedEpisode': episodeNum,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark episode as watched: $e');
    }
  }

  Future<void> ensureShowExists({
    required String userId,
    required String showId,
    required Map<String, dynamic> showData,
  }) async {
    final showRef = _db
        .collection('users')
        .doc(userId)
        .collection('trackedShows')
        .doc(showId);

    final docSnapshot = await showRef.get();
    if (!docSnapshot.exists) {
      await showRef.set(showData, SetOptions(merge: true));
    }
  }

  Stream<List<TvShowModel>> getUserWatchlist(String userId) {
  return _db
      .collection('users')
      .doc(userId)
      .collection('trackedShows')
      // Ordering by updatedAt ensures recently watched shows jump to the top
      .orderBy('updatedAt', descending: true) 
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => TvShowModel.fromFirestore(doc.id, doc.data()))
          .toList());
}
}
