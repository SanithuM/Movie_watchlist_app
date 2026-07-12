import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/auth_service.dart';
import '../providers/wishlist_provider.dart';
import '../../data/models/movie_model.dart';
import 'details_screen.dart';

class MovieScreen extends ConsumerWidget {
  const MovieScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Auth error: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'Sign in to view your Movie watchlist.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              title: const TabBar(
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
                tabs: [
                  Tab(text: 'WATCH LIST'),
                  Tab(text: 'UPCOMING'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // TAB 1: Watch List
                _buildWatchListTab(context, ref),

                // TAB 2: Upcoming
                _buildUpcomingTab(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWatchListTab(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);

    // Filter to only movies that are not watched yet
    final remainingMovies = wishlist.where((movie) => !movie.isWatched).toList();

    if (remainingMovies.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24, top: 12),
      itemCount: remainingMovies.length,
      itemBuilder: (context, index) {
        return _MovieTimeCard(movie: remainingMovies[index]);
      },
    );
  }

  Widget _buildUpcomingTab() {
    return const Center(
      child: Text(
        'No upcoming movies.',
        style: TextStyle(color: Colors.grey, fontSize: 16),
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
            "No movies added yet!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Search and add movies to your wishlist.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _MovieTimeCard extends ConsumerStatefulWidget {
  final Movie movie;

  const _MovieTimeCard({
    required this.movie,
  });

  @override
  ConsumerState<_MovieTimeCard> createState() => _MovieTimeCardState();
}

class _MovieTimeCardState extends ConsumerState<_MovieTimeCard> {
  bool _showDelete = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        setState(() {
          _showDelete = !_showDelete;
        });
      },
      onTap: () {
        if (_showDelete) {
          setState(() {
            _showDelete = false;
          });
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailScreen(mediaItem: widget.movie, isMovie: true),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Left Image (Cropped)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
              child: Image.network(
                widget.movie.posterPath,
                width: 95,
                height: 125,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => Container(
                  width: 95,
                  height: 125,
                  color: Colors.grey[900],
                  child: const Icon(Icons.movie, color: Colors.grey),
                ),
              ),
            ),
            
            const SizedBox(width: 16),

            // 2. Middle Info Column
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Movie Title Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.movie.title.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right, color: Colors.white, size: 10),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Release Date or Rating info
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          widget.movie.voteAverage.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Release Date
                    Text(
                      widget.movie.releaseDate.isNotEmpty ? 'Released: ${widget.movie.releaseDate}' : 'Release Date Unknown',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // 3. Right Action Button (Checkmark or Delete)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _showDelete
                  ? GestureDetector(
                      onTap: () {
                        // Delete movie
                        ref.read(wishlistProvider.notifier).removeMovie(widget.movie.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"${widget.movie.title}" removed from watchlist!'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    )
                  : widget.movie.isWatched
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 36)
                      : GestureDetector(
                          onTap: () {
                            // Toggle watched status
                            ref.read(wishlistProvider.notifier).toggleWatched(widget.movie.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('"${widget.movie.title}" marked as watched!')),
                            );
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}