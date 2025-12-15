// Movie detail screen with overview, rating, and add/update actions.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/popcorn_rater.dart'; // custom component
import '../../data/models/movie_model.dart';
import '../providers/wishlist_provider.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final Movie movie;

  const DetailScreen({super.key, required this.movie});

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  // Local state for the slider before saving
  double _currentRating = 5.0; 
  final bool _isMessageVisible = false;

  @override
  void initState() {
    super.initState();
    // Initialize rating with the movie's existing rating (or default 5.0)
    _currentRating = widget.movie.voteAverage;
  }

  @override
  Widget build(BuildContext context) {
    // Check if this movie is in our wishlist
    final wishlist = ref.watch(wishlistProvider);
    final existingMovie = wishlist.firstWhere(
      (m) => m.id == widget.movie.id,
      orElse: () => widget.movie,
    );
    
    // Check if it's actually saved
    final isSaved = wishlist.any((m) => m.id == widget.movie.id);

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // Scrolling App Bar with Image
          SliverAppBar(
            expandedHeight: 400.0,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.movie.title,
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.movie.posterPath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey),
                  ),
                  // Gradient to make text readable
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black],
                        stops: [0.6, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Movie Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Release Date & Status
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "Released: ${widget.movie.releaseDate}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const Spacer(),
                      if (isSaved && existingMovie.isWatched)
                        const Chip(
                          label: Text("Watched", style: TextStyle(color: Colors.white)),
                          backgroundColor: Colors.green,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Overview
                  const Text(
                    "Overview",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.movie.overview,
                    style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 40),

                  // THE CUSTOM COMPONENT
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Rate this Movie",
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          PopcornRater(
                            initialRating: _currentRating, // Use the value from state
                            onChanged: (value) {
                              setState(() {
                                _currentRating = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 4. Action Button (Add/Update)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSaved ? Colors.amber : Colors.blue,
                        foregroundColor: Colors.black,
                      ),
                      icon: Icon(isSaved ? Icons.save : Icons.add),
                      label: Text(
                        isSaved ? "Update Rating" : "Add to Wishlist",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      onPressed: () {
                        if (isSaved) {
                          // UPDATE Existing
                          ref.read(wishlistProvider.notifier).updateRating(widget.movie.id, _currentRating);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Rating Updated!")),
                          );
                        } else {
                          // CREATE New
                          // create a new movie object with the user's custom rating
                          final newMovie = Movie(
                            id: widget.movie.id,
                            title: widget.movie.title,
                            posterPath: widget.movie.posterPath,
                            overview: widget.movie.overview,
                            voteAverage: _currentRating, // Save the slider value!
                            releaseDate: widget.movie.releaseDate,
                            isWatched: false,
                          );
                          ref.read(wishlistProvider.notifier).addMovie(newMovie);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Added to Wishlist!")),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}