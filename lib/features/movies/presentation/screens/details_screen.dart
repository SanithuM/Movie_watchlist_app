import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/popcorn_rater.dart'; // custom component
import '../../data/models/movie_model.dart';
import '../providers/wishlist_provider.dart';
import '../providers/custom_lists_provider.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final dynamic mediaItem;
  final bool isMovie;

  const DetailScreen({super.key, required this.mediaItem, required this.isMovie});

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
    _currentRating = widget.isMovie ? widget.mediaItem.voteAverage : widget.mediaItem.voteAverage;
  }

  void _showAddToListSheet(
    BuildContext context,
    WidgetRef ref,
    String itemId,
    String title,
    String posterPath,
    String type,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final listsAsync = ref.watch(customListsProvider);
            return listsAsync.when(
              data: (lists) {
                if (lists.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "You don't have any custom lists yet.",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showCreateListDialog(context, ref);
                          },
                          child: const Text("Create a List"),
                        ),
                      ],
                    ),
                  );
                }
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Add to List",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.white),
                              onPressed: () {
                                Navigator.pop(context);
                                _showCreateListDialog(context, ref);
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.grey),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: lists.length,
                          itemBuilder: (context, index) {
                            final list = lists[index];
                            final isInList = list.items.any((item) => item.id == itemId && item.type == type);
                            return CheckboxListTile(
                              title: Text(list.name, style: const TextStyle(color: Colors.white)),
                              value: isInList,
                              activeColor: Colors.amber,
                              checkColor: Colors.black,
                              onChanged: (value) async {
                                await ref.read(customListsProvider.notifier).toggleItemInList(
                                      listId: list.id,
                                      itemId: itemId,
                                      title: title,
                                      posterPath: posterPath,
                                      type: type,
                                    );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.red))),
            );
          },
        );
      },
    );
  }

  void _showCreateListDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text("Create New List", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Enter list name",
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  await ref.read(customListsProvider.notifier).createList(name);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if this movie is in our wishlist
    final wishlist = ref.watch(wishlistProvider);
    final existingMovie = wishlist.firstWhere(
      (m) => m.id == (widget.isMovie ? widget.mediaItem.id : widget.mediaItem.id),
      orElse: () => widget.mediaItem,
    );
    
    // Check if it's actually saved
    final isSaved = wishlist.any((m) => m.id == (widget.isMovie ? widget.mediaItem.id : widget.mediaItem.id));

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // Scrolling App Bar with Image
          SliverAppBar(
            expandedHeight: 400.0,
            pinned: true,
            backgroundColor: Colors.black,
            actions: [
              IconButton(
                icon: Icon(
                  isSaved && existingMovie.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isSaved && existingMovie.isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  if (!isSaved) {
                    // Create movie with isFavorite = true
                    final newMovie = Movie(
                      id: widget.mediaItem.id,
                      title: widget.mediaItem.title,
                      posterPath: widget.mediaItem.posterPath,
                      overview: widget.mediaItem.overview,
                      voteAverage: widget.mediaItem.voteAverage,
                      releaseDate: widget.mediaItem.releaseDate ?? '',
                      isWatched: false,
                      isFavorite: true,
                    );
                    ref.read(wishlistProvider.notifier).addMovie(newMovie);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Added to Favorites!")),
                    );
                  } else {
                    ref.read(wishlistProvider.notifier).toggleFavorite(existingMovie.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(existingMovie.isFavorite
                            ? "Removed from Favorites"
                            : "Added to Favorites!"),
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.playlist_add, color: Colors.white),
                onPressed: () => _showAddToListSheet(
                  context,
                  ref,
                  widget.mediaItem.id.toString(),
                  widget.isMovie ? widget.mediaItem.title : widget.mediaItem.name,
                  widget.mediaItem.posterPath,
                  'movie',
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.isMovie ? widget.mediaItem.title : widget.mediaItem.name,
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.isMovie ? widget.mediaItem.posterPath : widget.mediaItem.posterPath,
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
                        "Released: ${widget.isMovie ? widget.mediaItem.releaseDate : widget.mediaItem.firstAirDate}",
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
                    widget.isMovie ? widget.mediaItem.overview : widget.mediaItem.overview,
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
                          ref.read(wishlistProvider.notifier).updateRating(widget.isMovie ? widget.mediaItem.id : widget.mediaItem.id, _currentRating);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Rating Updated!")),
                          );
                        } else {
                          // CREATE New
                          // create a new movie object with the user's custom rating
                          final newMovie = Movie(
                            id: widget.isMovie ? widget.mediaItem.id : widget.mediaItem.id,
                            title: widget.isMovie ? widget.mediaItem.title : widget.mediaItem.name,
                            posterPath: widget.isMovie ? widget.mediaItem.posterPath : widget.mediaItem.posterPath,
                            overview: widget.isMovie ? widget.mediaItem.overview : widget.mediaItem.overview,
                            voteAverage: _currentRating, // Save the slider value!
                            releaseDate: widget.isMovie ? widget.mediaItem.releaseDate : widget.mediaItem.firstAirDate,
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