// Search screen UI that queries movies and shows results.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';
import '../providers/wishlist_provider.dart';
import 'details_screen.dart'; 

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(searchResultsProvider);
    final wishlist = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.white),
        title: TextField(
          autofocus: true, // Automatically open keyboard when entering screen
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search movies...',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
            suffixIcon: Icon(Icons.search, color: Colors.white),
          ),
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).updateQuery(value);
          },
        ),
      ),
      body: searchResults.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (movies) {
          if (movies.isEmpty) {
            return const Center(
              child: Text(
                'Type to search...',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];

              // Check if this movie is already in our wishlist
              final isAlreadyAdded = wishlist.any((m) => m.id == movie.id);

              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(movie: movie),
                    ),
                  );
                },
                
                leading: Image.network(
                  movie.posterPath,
                  width: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.movie, color: Colors.grey),
                ),
                title: Text(
                  movie.title,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  movie.releaseDate.length >= 4 
                    ? movie.releaseDate.split('-')[0] 
                    : 'N/A', // Safety check for date
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: IconButton(
                  icon: Icon(
                    isAlreadyAdded
                        ? Icons.check_circle
                        : Icons.add_circle_outline,
                    color: isAlreadyAdded ? Colors.green : Colors.white,
                  ),
                  onPressed: isAlreadyAdded
                      ? null
                      : () {
                          // Add to local wishlist
                          ref.read(wishlistProvider.notifier).addMovie(movie);

                          // Show a little popup confirmation
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${movie.title} added!'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                ),
              );
            },
          );
        },
      ),
    );
  }
}