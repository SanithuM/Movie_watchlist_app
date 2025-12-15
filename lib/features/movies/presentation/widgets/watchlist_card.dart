// Compact card used in watchlist to show movie and mark watched.
import 'package:flutter/material.dart';
import '../../data/models/movie_model.dart';

class WatchlistCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onToggleWatched;

  const WatchlistCard({
    super.key,
    required this.movie,
    required this.onToggleWatched,
  });

  @override
  Widget build(BuildContext context) {
    // Extract year from string
    final String year = movie.releaseDate.length >= 4
        ? movie.releaseDate.substring(0, 4)
        : 'N/A';

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C), // Dark grey background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Movie Banner Poster (Left Side)
          // We use ClipRRect only on the left side to match the container's corners
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: Image.network(
              movie.posterPath,
              width: 80, // Fixed width for the poster
              height: double.infinity, // Fills the full height of the container
              fit: BoxFit.cover, // Ensures image doesn't stretch weirdly
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                color: Colors.grey[800],
                child: const Icon(Icons.movie, color: Colors.grey),
              ),
            ),
          ),

          // Title and Year (Expanded to take up middle space)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center text vertically
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis, // Add ... if title is too long
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(year, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),

          // "Watched" Checkbox (Right Side)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: onToggleWatched,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // LOGIC: Green if watched, White if not
                  color: movie.isWatched ? Colors.green : Colors.white,
                ),
                child: Icon(
                  Icons.check,
                  size: 20,
                  // LOGIC: White icon if watched, Grey icon if not
                  color: movie.isWatched ? Colors.white : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
