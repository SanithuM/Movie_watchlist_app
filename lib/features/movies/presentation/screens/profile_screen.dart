import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/movie_model.dart';
import '../providers/wishlist_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/custom_lists_provider.dart';
import 'details_screen.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import 'list_detail_screen.dart';
import 'media_grid_screen.dart';
import '../../../tv_shows/domain/entities/tv_show.dart';
import '../../../tv_shows/presentation/providers/tv_providers.dart';
import '../../../tv_shows/presentation/screens/tv_detail_screen.dart';
import '../../../../core/utils/episode_calculator.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // Helper to safely parse image paths (Base64, Network, or File)
  ImageProvider? _getImageProvider(String? imageString) {
    if (imageString == null || imageString.isEmpty) {
      return null;
    }
    // Base64 Check
    if (imageString.length > 500) {
      try {
        return MemoryImage(base64Decode(imageString));
      } catch (e) {
        return null;
      }
    }
    if (imageString.startsWith('http')) return NetworkImage(imageString);
    if (!kIsWeb) {
      final file = File(imageString);
      return file.existsSync() ? FileImage(file) : null;
    }
    return null;
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

  Widget _buildCreateListCard(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showCreateListDialog(context, ref),
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add, color: Colors.white, size: 36),
            SizedBox(height: 8),
            Text(
              'CREATE A NEW LIST',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomListCard(BuildContext context, CustomList list) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListDetailScreen(list: list),
          ),
        );
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[800]!),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              list.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${list.items.length} items',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required VoidCallback onTapChevron,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: InkWell(
        onTap: onTapChevron,
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: icon == Icons.favorite ? Colors.red : Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Fetch Movie Data
    final movieWishlist = ref.watch(wishlistProvider);
    final watchedMovies = movieWishlist.where((m) => m.isWatched).toList()
      ..sort((a, b) {
        final aTime = a.watchedAt ?? DateTime(1970);
        final bTime = b.watchedAt ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });
    final favoriteMovies = movieWishlist.where((m) => m.isFavorite).toList();

    // Fetch TV Show Data
    final tvAsyncValue = ref.watch(tvWatchlistProvider(currentUserId));
    List<TvShow> trackedShows = [];
    List<TvShow> favoriteShows = [];
    if (tvAsyncValue.hasValue) {
      trackedShows = tvAsyncValue.value!
          .where((s) => s.status != 'dropped')
          .toList();
      favoriteShows = trackedShows.where((s) => s.isFavorite).toList();
    }

    // --- CALCULATE STATS ---
    final int totalMoviesWatched = watchedMovies.length;

    int totalEpisodesWatched = 0;
    int totalTvMinutes = 0;
    if (tvAsyncValue.hasValue) {
      totalEpisodesWatched = tvAsyncValue.value!.fold(
        0,
        (sum, show) => sum + show.progress,
      );
      totalTvMinutes = tvAsyncValue.value!.fold(
        0,
        (sum, show) => sum + (show.watchedMinutes ?? (show.progress * show.episodeRunTime)),
      );
    }

    final int totalMovieMinutes = totalMoviesWatched * 120;

    final movieTime = EpisodeCalculator.formatTime(totalMovieMinutes);
    final tvTime = EpisodeCalculator.formatTime(totalTvMinutes);

    final bannerProvider = _getImageProvider(profileState.bannerPath);
    final avatarProvider = _getImageProvider(profileState.avatarPath);

    final customListsAsync = ref.watch(customListsProvider);
    final customLists = customListsAsync.value ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER (BANNER & AVATAR) ---
            SizedBox(
              height: 235,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // BANNER with dark gradient overlay
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      image: bannerProvider != null
                          ? DecorationImage(
                              image: bannerProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.black.withOpacity(0.1),
                            Colors.black.withOpacity(0.8),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // SETTINGS ICON (Three dots menu)
                  Positioned(
                    top: 50,
                    right: 16,
                    child: IconButton(
                      icon: const Icon(
                        Icons.more_horiz,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  // AVATAR & INFO ROW
                  Positioned(
                    top: 140,
                    left: 20,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Avatar Circle with slim white border
                        Container(
                          padding: const EdgeInsets.all(1),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.grey[800],
                            backgroundImage: avatarProvider,
                            child: avatarProvider == null
                                ? const Icon(
                                    Icons.person,
                                    size: 36,
                                    color: Colors.white54,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Name & EDIT Button
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: 8.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  profileState.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  height: 30,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const EditProfileScreen(),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text(
                                      'EDIT',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 1.0,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- TV TIME STYLE STATS SECTION ---
            Padding(
              padding: const EdgeInsets.only(top: 0.0, bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Stats',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Horizontal Scrollable Cards
                  SizedBox(
                    height: 90,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                      ),
                      children: [
                        _buildTimeCard(
                          title: 'TV time',
                          icon: Icons.tv,
                          months: tvTime['months']!,
                          days: tvTime['days']!,
                          hours: tvTime['hours']!,
                        ),
                        const SizedBox(width: 8),
                        _buildCountCard(
                          title: 'Episodes watched',
                          icon: Icons.tv,
                          count: totalEpisodesWatched,
                        ),
                        const SizedBox(width: 8),
                        _buildTimeCard(
                          title: 'Movie time',
                          icon: Icons.movie_creation_outlined,
                          months: movieTime['months']!,
                          days: movieTime['days']!,
                          hours: movieTime['hours']!,
                        ),
                        const SizedBox(width: 8),
                        _buildCountCard(
                          title: 'Movies watched',
                          icon: Icons.movie_creation_outlined,
                          count: totalMoviesWatched,
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),

            // --- ONE VIEW SECTIONS (TV TIME STYLE) ---
            
            // SHOWS (TRACKED)
            _buildSectionHeader(
              context,
              title: "Shows",
              onTapChevron: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MediaGridScreen(
                    title: "Shows",
                    items: trackedShows,
                  ),
                ),
              ),
            ),
            tvAsyncValue.when(
              loading: () => const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator(color: Colors.amber)),
              ),
              error: (err, stack) => SizedBox(
                height: 160,
                child: Center(
                  child: Text(
                    'Error loading shows',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
              data: (_) => _buildTvHorizontalList(
                context,
                trackedShows,
                emptyMessage: "No shows tracked yet.",
              ),
            ),
            const SizedBox(height: 24),

            // 3. FAVORITE SHOWS
            _buildSectionHeader(
              context,
              title: "Favorite shows",
              icon: Icons.favorite,
              onTapChevron: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MediaGridScreen(
                    title: "Favorite Shows",
                    items: favoriteShows,
                  ),
                ),
              ),
            ),
            tvAsyncValue.when(
              loading: () => const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator(color: Colors.amber)),
              ),
              error: (err, stack) => SizedBox(
                height: 160,
                child: Center(
                  child: Text(
                    'Error loading favorite shows',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
              data: (_) => _buildTvHorizontalList(
                context,
                favoriteShows,
                emptyMessage: "No favorite shows yet.",
              ),
            ),
            const SizedBox(height: 24),

            // 4. MOVIES (WATCHED)
            _buildSectionHeader(
              context,
              title: "Movies",
              onTapChevron: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MediaGridScreen(
                    title: "Movies",
                    items: watchedMovies,
                  ),
                ),
              ),
            ),
            _buildMovieHorizontalList(
              context,
              watchedMovies,
              emptyMessage: "No movies watched yet.",
            ),
            const SizedBox(height: 24),

            // 5. FAVORITE MOVIES
            _buildSectionHeader(
              context,
              title: "Favorite movies",
              icon: Icons.favorite,
              onTapChevron: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MediaGridScreen(
                    title: "Favorite Movies",
                    items: favoriteMovies,
                  ),
                ),
              ),
            ),
            _buildMovieHorizontalList(
              context,
              favoriteMovies,
              emptyMessage: "No favorite movies yet.",
            ),
            const SizedBox(height: 80), // spacer for bottom nav bar
          ],
        ),
      ),
    );
  }

  // WIDGET BUILDERS

  Widget _buildTimeCard({required String title, required IconData icon, required int months, required int days, required int hours}) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.grey[800]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          // Top Row (Title & Icon)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[800], thickness: 1),
          // Bottom Row (Time Data)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTimeColumn(months, 'MONTHS'),
                _buildTimeColumn(days, 'DAYS'),
                _buildTimeColumn(hours, 'HOURS'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(int value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildCountCard({required String title, required IconData icon, required int count}) {
    // Format large numbers with commas (e.g., 8160 -> 8,160)
    final formattedCount = count.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.grey[800]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          // Top Row (Title & Icon)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[800], thickness: 1),
          // Bottom Row (Count Data)
          Expanded(
            child: Center(
              child: Text(
                formattedCount,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieHorizontalList(
    BuildContext context,
    List<Movie> movies, {
    String emptyMessage = "No movies watched yet.",
  }) {
    if (movies.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: Text(
          emptyMessage,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DetailScreen(mediaItem: movie, isMovie: true),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  movie.posterPath,
                  height: 150,
                  width: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey[800], height: 150),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTvHorizontalList(
    BuildContext context,
    List<TvShow> shows, {
    String emptyMessage = "No shows tracked yet.",
  }) {
    if (shows.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: Text(
          emptyMessage,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: shows.length,
        itemBuilder: (context, index) {
          final show = shows[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TvDetailScreen(show: show),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  show.posterPath,
                  height: 150,
                  width: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey[800], height: 150),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
