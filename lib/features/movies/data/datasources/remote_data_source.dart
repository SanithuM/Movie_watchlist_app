// Interface for remote data fetching (TMDB/API).
import '../models/movie_model.dart';

abstract class RemoteDataSource {
  Future<List<Movie>> fetchTrending();
  Future<List<Movie>> searchMovies(String query);
}
