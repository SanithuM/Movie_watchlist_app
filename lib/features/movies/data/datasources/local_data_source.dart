// Interface for local cache operations for movies.
import '../models/movie_model.dart';

abstract class LocalDataSource {
  Future<void> cacheMovies(List<Movie> movies);
  Future<List<Movie>> getCachedMovies();
}
