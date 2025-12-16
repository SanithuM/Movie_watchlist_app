// Concrete Movie model with JSON (TMDB) serialization helpers.
class Movie {
  final int id;
  final String title;
  final String posterPath;
  final String overview;
  final double voteAverage; // TMDB Global Rating
  final String releaseDate;
  final bool isWatched;
  final double? myRating; // User's Popcorn Rating

  Movie({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.overview,
    required this.voteAverage,
    this.releaseDate = '',
    this.isWatched = false,
    this.myRating, // <--- Initialize this
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    // Create Movie from TMDB JSON, normalizing poster URL.
    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'No Title',
      posterPath: json['poster_path'] != null
          ? (json['poster_path'].toString().startsWith('http')
                ? json['poster_path']
                : 'https://image.tmdb.org/t/p/w500${json['poster_path']}')
          : 'https://via.placeholder.com/200x300',
      overview: json['overview'] ?? '',
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      releaseDate: json['release_date'] ?? 'Unknown',
      isWatched: json['is_watched'] ?? false,
      myRating: json['my_rating'] != null
          ? (json['my_rating'] as num).toDouble()
          : null, // Load from JSON
    );
  }

  Map<String, dynamic> toJson() {
    // Convert Movie to JSON for local storage or upload.
    return {
      'id': id,
      'title': title,
      'poster_path': posterPath,
      'overview': overview,
      'vote_average': voteAverage,
      'release_date': releaseDate,
      'is_watched': isWatched,
      'my_rating': myRating, // Save to JSON
    };
  }
}
