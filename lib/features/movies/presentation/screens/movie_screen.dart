// Explore movies UI — shows trending and now playing lists.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/movie_providers.dart';
import '../../data/models/movie_model.dart';
import 'details_screen.dart';

class MovieScreen extends ConsumerWidget {
  const MovieScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch both data sources
    final trendingState = ref.watch(trendingMoviesProvider);
    final nowPlayingState = ref.watch(nowPlayingMoviesProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: const Text(
          "Explore Movies",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECTION 1: NEW RELEASES
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Text(
                  "New Releases",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              // Horizontal List for New Releases
              SizedBox(
                height: 250, // Height of the horizontal section
                child: nowPlayingState.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text("Error: $e", style: const TextStyle(color: Colors.white))),
                  data: (movies) => _buildHorizontalMovieList(context, movies),
                ),
              ),

              // SECTION 2: TRENDING
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Text(
                  "Trending Now",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              // Horizontal List for Trending
              SizedBox(
                height: 250,
                child: trendingState.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text("Error: $e", style: const TextStyle(color: Colors.white))),
                  data: (movies) => _buildHorizontalMovieList(context, movies),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // A helper method to build the horizontal list
  Widget _buildHorizontalMovieList(BuildContext context, List<Movie> movies) {
    if (movies.isEmpty) return const Center(child: Text("No movies found", style: TextStyle(color: Colors.white)));

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DetailScreen(movie: movie)),
            );
          },
          child: Container(
            width: 140, // Fixed width for each card
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poster Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    movie.posterPath,
                    height: 200,
                    width: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey, height: 200),
                  ),
                ),
                const SizedBox(height: 8),
                // Title
                Text(
                  movie.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                // Rating
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      movie.voteAverage.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}