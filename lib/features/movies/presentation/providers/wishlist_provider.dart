import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/movie_model.dart';

class WishlistNotifier extends Notifier<List<Movie>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  List<Movie> build() {
    // On init, try to load from Firestore if user is logged in
    _loadFromFirestore();
    return [];
  }

  // Load data from Cloud
  Future<void> _loadFromFirestore() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .get();

      final cloudMovies = snapshot.docs
          .map((doc) => Movie.fromJson(doc.data()))
          .toList();

      // Update state
      state = cloudMovies;
    }
  }

  // Add Movie (Saves to Cloud)
  Future<void> addMovie(Movie movie) async {
    if (!state.any((m) => m.id == movie.id)) {
      // Update Local State (Instant UI update)
      state = [...state, movie];

      // Sync to Firestore
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('wishlist')
            .doc(movie.id.toString()) // Use Movie ID as Doc ID
            .set(movie.toJson());
      }
    }
  }

  // Update Rating/Watched (Saves to Cloud)
  Future<void> updateRating(int movieId, double newRating) async {
    state = [
      for (final movie in state)
        if (movie.id == movieId)
          // Create new movie object with 'myRating' updated
          Movie(
            id: movie.id,
            title: movie.title,
            posterPath: movie.posterPath,
            overview: movie.overview,
            voteAverage: movie.voteAverage, // Keep original TMDB rating
            releaseDate: movie.releaseDate,
            isWatched: movie.isWatched,
            myRating: newRating,
          )
        else
          movie,
    ];

    // Sync Update to Firestore (Save as 'my_rating')
    _syncUpdateToCloud(movieId, {'my_rating': newRating});
  }

  Future<void> toggleWatched(int movieId) async {
    // Find the movie to get its current status
    final movie = state.firstWhere((m) => m.id == movieId);
    final newStatus = !movie.isWatched;

    state = [
      for (final m in state)
        if (m.id == movieId)
          _updateMovieLocally(m, isWatched: newStatus)
        else
          m,
    ];

    // Sync Update to Firestore
    _syncUpdateToCloud(movieId, {'is_watched': newStatus});
  }

  // Helper to construct new Movie object
  Movie _updateMovieLocally(Movie m, {double? voteAverage, bool? isWatched}) {
    return Movie(
      id: m.id,
      title: m.title,
      posterPath: m.posterPath,
      overview: m.overview,
      voteAverage: voteAverage ?? m.voteAverage,
      releaseDate: m.releaseDate,
      isWatched: isWatched ?? m.isWatched,
    );
  }

  // Helper to push updates to Firebase
  Future<void> _syncUpdateToCloud(
    int movieId,
    Map<String, dynamic> data,
  ) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .doc(movieId.toString())
          .update(data);
    }
  }
}

final wishlistProvider = NotifierProvider<WishlistNotifier, List<Movie>>(() {
  return WishlistNotifier();
});
