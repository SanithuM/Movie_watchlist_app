// Domain entity representing a movie (lightweight fields).
class Movie {
  final int id;
  final String title;
  final String? posterPath;

  Movie({required this.id, required this.title, this.posterPath});
}
