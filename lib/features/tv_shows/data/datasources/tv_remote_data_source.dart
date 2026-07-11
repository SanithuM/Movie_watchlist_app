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

    // Check if there are already watched episodes in the subcollection
    final episodesSnapshot = await showRef.collection('episodes').get();
    final int existingProgress = episodesSnapshot.docs.length;

    int? lastWatchedSeason;
    int? lastWatchedEpisode;
    if (existingProgress > 0) {
      // Fetch the latest watched episode to restore lastWatchedSeason and lastWatchedEpisode
      final latestEpDocs = await showRef
          .collection('episodes')
          .orderBy('watchedAt', descending: true)
          .limit(1)
          .get();
      if (latestEpDocs.docs.isNotEmpty) {
        final data = latestEpDocs.docs.first.data();
        lastWatchedSeason = data['seasonNumber'] as int?;
        lastWatchedEpisode = data['episodeNumber'] as int?;
      }
    }

    int existingWatchedMinutes = 0;
    if (existingProgress > 0) {
      for (final doc in episodesSnapshot.docs) {
        final docData = doc.data();
        final runtime = docData['runtime'] as int?;
        existingWatchedMinutes += runtime ?? (show.episodeRunTime as int? ?? 45);
      }
    } else {
      existingWatchedMinutes = show.watchedMinutes ?? 0;
    }

    await showRef.set({
      'id': show.id,
      'title': show.title,
      'posterPath': show.posterPath,
      'progress': existingProgress > 0 ? existingProgress : show.progress,
      'watchedMinutes': existingWatchedMinutes,
      'totalEpisodes': show.totalEpisodes,
      'status': show.status,
      'seasonEpisodeCounts': show.seasonEpisodeCounts,
      'voteAverage': show.voteAverage,
      'isFavorite': show.isFavorite,
      'episodeRunTime': show.episodeRunTime,
      'episodeRunTimes': show.episodeRunTimes,
      if (lastWatchedSeason != null) 'lastWatchedSeason': lastWatchedSeason,
      if (lastWatchedEpisode != null) 'lastWatchedEpisode': lastWatchedEpisode,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleFavorite({
    required String userId,
    required String showId,
    required bool isFavorite,
  }) async {
    final showRef = _db
        .collection('users')
        .doc(userId)
        .collection('trackedShows')
        .doc(showId);

    await showRef.update({
      'isFavorite': isFavorite,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markEpisodeAsWatched({
    required String userId,
    required String showId,
    required int seasonNum,
    required int episodeNum,
    int? runtime,
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
      if (runtime != null) 'runtime': runtime,
    });

    batch.set(showRef, {
      'progress': FieldValue.increment(1),
      if (runtime != null) 'watchedMinutes': FieldValue.increment(runtime),
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

  Future<void> dropShow({
    required String userId,
    required String showId,
  }) async {
    final showRef = _db
        .collection('users')
        .doc(userId)
        .collection('trackedShows')
        .doc(showId);

    await showRef.update({
      'status': 'dropped',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unmarkEpisodeAsWatched({
    required String userId,
    required String showId,
    required int seasonNum,
    required int episodeNum,
  }) async {
    final showRef = _db
        .collection('users')
        .doc(userId)
        .collection('trackedShows')
        .doc(showId);

    final episodeId = 'S${seasonNum}E$episodeNum';
    final episodeRef = showRef.collection('episodes').doc(episodeId);

    // Fetch the episode document to check for stored runtime
    final episodeSnap = await episodeRef.get();
    int runtimeToSubtract = 0;
    if (episodeSnap.exists) {
      runtimeToSubtract = episodeSnap.data()?['runtime'] as int? ?? 0;
    }

    if (runtimeToSubtract == 0) {
      // Fallback: if there is no runtime stored in the episode doc, we can fetch the show doc to read its average episodeRunTime
      final showSnap = await showRef.get();
      if (showSnap.exists) {
        runtimeToSubtract = showSnap.data()?['episodeRunTime'] as int? ?? 45;
      } else {
        runtimeToSubtract = 45;
      }
    }

    final batch = _db.batch();
    batch.delete(episodeRef);

    batch.set(showRef, {
      'progress': FieldValue.increment(-1),
      'watchedMinutes': FieldValue.increment(-runtimeToSubtract),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to unmark episode as watched: $e');
    }
  }

  Future<void> toggleSeasonWatched({
    required String userId,
    required String showId,
    required int seasonNum,
    required int totalEpisodesInSeason,
    required List<String> watchedEpisodeIds,
    required Map<int, int> episodeRuntimes,
  }) async {
    final showRef = _db
        .collection('users')
        .doc(userId)
        .collection('trackedShows')
        .doc(showId);

    final episodesCollection = showRef.collection('episodes');

    // Find which episodes of this season are currently watched
    final seasonWatchedPrefix = 'S${seasonNum}E';
    final seasonWatchedDocs = watchedEpisodeIds.where((id) => id.startsWith(seasonWatchedPrefix)).toList();

    final bool isFullyWatched = seasonWatchedDocs.length == totalEpisodesInSeason;

    final batch = _db.batch();

    int progressDelta = 0;
    int minutesDelta = 0;

    if (isFullyWatched) {
      // Mark all as unwatched: delete all watched docs for this season
      for (final epId in seasonWatchedDocs) {
        final epNum = int.tryParse(epId.substring(seasonWatchedPrefix.length)) ?? 0;
        final runtime = episodeRuntimes[epNum] ?? 45;
        minutesDelta -= runtime;
        batch.delete(episodesCollection.doc(epId));
      }
      progressDelta = -totalEpisodesInSeason;
    } else {
      // Mark all as watched: add docs for all episodes in this season
      for (int i = 1; i <= totalEpisodesInSeason; i++) {
        final epId = 'S${seasonNum}E$i';
        if (!watchedEpisodeIds.contains(epId)) {
          final runtime = episodeRuntimes[i] ?? 45;
          batch.set(episodesCollection.doc(epId), {
            'seasonNumber': seasonNum,
            'episodeNumber': i,
            'watchedAt': FieldValue.serverTimestamp(),
            'runtime': runtime,
          });
          progressDelta++;
          minutesDelta += runtime;
        }
      }
    }

    batch.set(showRef, {
      'progress': FieldValue.increment(progressDelta),
      'watchedMinutes': FieldValue.increment(minutesDelta),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to toggle season watched: $e');
    }
  }

  Future<void> toggleAllEpisodesWatched({
    required String userId,
    required String showId,
    required List<Map<String, dynamic>> seasonsList,
    required List<String> watchedEpisodeIds,
    required Map<String, int> episodeRuntimes,
  }) async {
    final showRef = _db
        .collection('users')
        .doc(userId)
        .collection('trackedShows')
        .doc(showId);

    final episodesCollection = showRef.collection('episodes');

    // Calculate total episodes across all seasons
    int totalEpisodes = 0;
    for (final s in seasonsList) {
      totalEpisodes += (s['episode_count'] as int? ?? 0);
    }

    final bool isFullyWatched = watchedEpisodeIds.length == totalEpisodes;

    final batch = _db.batch();

    int progressDelta = 0;
    int minutesDelta = 0;

    if (isFullyWatched) {
      // Mark all as unwatched: delete all watched docs
      for (final epId in watchedEpisodeIds) {
        batch.delete(episodesCollection.doc(epId));
        final runtime = episodeRuntimes[epId] ?? 45;
        minutesDelta -= runtime;
      }
      progressDelta = -watchedEpisodeIds.length;
    } else {
      // Mark all as watched: add docs for all episodes in all seasons
      for (final s in seasonsList) {
        final seasonNum = s['season_number'] as int? ?? 0;
        final episodeCount = s['episode_count'] as int? ?? 0;
        for (int i = 1; i <= episodeCount; i++) {
          final epId = 'S${seasonNum}E$i';
          if (!watchedEpisodeIds.contains(epId)) {
            final runtime = episodeRuntimes[epId] ?? 45;
            batch.set(episodesCollection.doc(epId), {
              'seasonNumber': seasonNum,
              'episodeNumber': i,
              'watchedAt': FieldValue.serverTimestamp(),
              'runtime': runtime,
            });
            progressDelta++;
            minutesDelta += runtime;
          }
        }
      }
    }

    batch.set(showRef, {
      'progress': FieldValue.increment(progressDelta),
      'watchedMinutes': FieldValue.increment(minutesDelta),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to toggle all episodes watched: $e');
    }
  }

  Future<void> resetShowProgress({
    required String userId,
    required String showId,
    required List<String> watchedEpisodeIds,
  }) async {
    final showRef = _db
        .collection('users')
        .doc(userId)
        .collection('trackedShows')
        .doc(showId);

    final episodesCollection = showRef.collection('episodes');

    final batch = _db.batch();

    for (final epId in watchedEpisodeIds) {
      batch.delete(episodesCollection.doc(epId));
    }

    batch.set(showRef, {
      'progress': 0,
      'watchedMinutes': 0,
      'lastWatchedSeason': FieldValue.delete(),
      'lastWatchedEpisode': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to reset show progress: $e');
    }
  }
}
