import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';
import '../providers/wishlist_provider.dart';
import 'details_screen.dart'; 
import '../../../tv_shows/presentation/providers/tv_providers.dart';
import '../../../tv_shows/domain/entities/tv_show.dart';
import '../../../tv_shows/presentation/screens/tv_detail_screen.dart';
import '../../data/models/movie_model.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch your strongly-typed search results
    final movieResults = ref.watch(searchResultsProvider); // Returns AsyncValue<List<Movie>>
    final tvResults = ref.watch(tvSearchResultsProvider);  // Returns AsyncValue<List<TvShow>>
    final wishlist = ref.watch(wishlistProvider);

    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false,
          iconTheme: const IconThemeData(color: Colors.white),
          title: TextField(
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Search movies & TV shows...',
              hintStyle: TextStyle(color: Colors.white54),
              border: InputBorder.none,
              suffixIcon: Icon(Icons.search, color: Colors.white),
            ),
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).updateQuery(value);
            },
          ),
          bottom: const TabBar(
            indicatorColor: Colors.amber,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Movies', icon: Icon(Icons.movie)),
              Tab(text: 'TV Shows', icon: Icon(Icons.tv)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- TAB 1: MOVIE SEARCH RESULTS ---
            movieResults.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
              data: (movies) => _buildMediaList(
                context, 
                ref, 
                items: movies, // This is now a List<Movie>
                wishlist: wishlist, 
                isMovie: true
              ),
            ),

            // --- TAB 2: TV SHOW SEARCH RESULTS ---
            tvResults.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
              data: (shows) => _buildMediaList(
                context, 
                ref, 
                items: shows, // This is now a List<TvShow>
                wishlist: wishlist, 
                isMovie: false
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method now handles strongly-typed domain entities safely
  Widget _buildMediaList(
    BuildContext context, 
    WidgetRef ref, 
    {required List<dynamic> items, required List<dynamic> wishlist, required bool isMovie}
  ) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Type to search...',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        // We can safely check the ID on either entity
        final isAlreadyAdded = wishlist.any((m) => m.id == item.id);

        // 1. Safely extract values based on the entity type
        final String title = isMovie ? (item as Movie).title : (item as TvShow).title;
        final String posterPath = isMovie ? (item as Movie).posterPath : (item as TvShow).posterPath;
        
        final String dateToDisplay = isMovie 
            ? ((item as Movie).releaseDate.isNotEmpty ? (item).releaseDate.split('-')[0] : 'N/A')
            : 'TV Show'; // Or map your air date here if you added it to the entity

        return ListTile(
          onTap: isMovie
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(mediaItem: item, isMovie: true),
                    ),
                  );
                }
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TvDetailScreen(show: item as TvShow),
                    ),
                  );
                },
          leading: Image.network(
            posterPath,
            width: 50,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Icon(isMovie ? Icons.movie : Icons.tv, color: Colors.grey),
          ),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            dateToDisplay,
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: IconButton(
            icon: Icon(
              isAlreadyAdded ? Icons.check_circle : Icons.add_circle_outline,
              color: isAlreadyAdded ? Colors.green : Colors.white,
            ),
            onPressed: isAlreadyAdded
                ? null
                : () {
                    if (isMovie) {
                      ref.read(wishlistProvider.notifier).addMovie(item as Movie);
                    } else {
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      if (userId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please sign in to track TV shows.'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                        return;
                      }

                      ref.read(tvShowActionProvider.notifier).markEpisodeWatched(
                        userId: userId, 
                        showId: (item as TvShow).id,
                        seasonNum: 1, 
                        episodeNum: 1, 
                      );
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$title added!'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
          ),
        );
      },
    );
  }
}