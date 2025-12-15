// Home screen showing active watchlist items.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/watchlist_card.dart';
import '../providers/wishlist_provider.dart';
import 'details_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get ALL movies from the provider
    final allMovies = ref.watch(wishlistProvider);

    // FILTER: Only keep movies that are NOT watched
    final activeWishlist = allMovies.where((movie) => !movie.isWatched).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Home',
          style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 30),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
        ],
      ),
      body: activeWishlist.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: activeWishlist.length,
              itemBuilder: (context, index) {
                final movie = activeWishlist[index];
                return GestureDetector(
                   onTap: () {
                     Navigator.push(
                       context,
                       MaterialPageRoute(builder: (context) => DetailScreen(movie: movie)),
                     );
                   },
                   child: WatchlistCard(
                    movie: movie,
                    onToggleWatched: () {
                      // Logic to toggle "Watched" status
                      // When this runs, the provider updates -> widget rebuilds -> filter runs -> movie disappears
                      ref.read(wishlistProvider.notifier).toggleWatched(movie.id);
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.movie_filter_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No movies yet!",
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "Add movies to your watchlist",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}