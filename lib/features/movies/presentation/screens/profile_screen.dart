import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/movie_model.dart';
import '../providers/wishlist_provider.dart';
import '../providers/profile_provider.dart';
import 'details_screen.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
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
    final file = File(imageString);
    return file.existsSync() ? FileImage(file) : null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Fetch Movie Data
    final movieWishlist = ref.watch(wishlistProvider);
    final watchedMovies = movieWishlist.where((m) => m.isWatched).toList();
    final ratedMovies = movieWishlist.where((m) => m.myRating != null).toList();

    // Fetch TV Show Data
    final tvAsyncValue = ref.watch(tvWatchlistProvider(currentUserId));

    // Extract completed shows synchronously if data is available
    List<TvShow> completedShows = [];
    if (tvAsyncValue.hasValue) {
      completedShows = tvAsyncValue.value!.where((show) {
        final nextEpData = EpisodeCalculator.getNextEpisode(
          show.progress,
          show.seasonEpisodeCounts,
        );
        return nextEpData['season'] == -1; // -1 means completed
      }).toList();
    }

    // --- CALCULATE STATS ---
    // Total movies watched
    final int totalMoviesWatched = watchedMovies.length;

    // Total episodes watched across all tracking shows
    int totalEpisodesWatched = 0;
    if (tvAsyncValue.hasValue) {
      totalEpisodesWatched = tvAsyncValue.value!.fold(
        0,
        (sum, show) => sum + show.progress,
      );
    }

    // Temporary calculations for time (assuming 120 mins per movie, 45 mins per episode)
    final int totalMovieMinutes = totalMoviesWatched * 120;
    final int totalTvMinutes = totalEpisodesWatched * 45;

    // Helper function to convert minutes to M / D / H
    Map<String, int> formatTime(int totalMinutes) {
      final int months = totalMinutes ~/ (60 * 24 * 30);
      final int remainingAfterMonths = totalMinutes % (60 * 24 * 30);
      final int days = remainingAfterMonths ~/ (60 * 24);
      final int remainingAfterDays = remainingAfterMonths % (60 * 24);
      final int hours = remainingAfterDays ~/ 60;
      return {'months': months, 'days': days, 'hours': hours};
    }

    final movieTime = formatTime(totalMovieMinutes);
    final tvTime = formatTime(totalTvMinutes);

    final bannerProvider = _getImageProvider(profileState.bannerPath);
    final avatarProvider = _getImageProvider(profileState.avatarPath);

    return Scaffold(
      backgroundColor: Colors.black,
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // --- HEADER (BANNER & AVATAR) ---
                    SizedBox(
                      height: 280,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // BANNER
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
                            child: bannerProvider != null
                                ? Container(
                                    color: Colors.black.withOpacity(0.3),
                                  )
                                : null,
                          ),

                          // SETTINGS ICON
                          Positioned(
                            top: 50,
                            right: 16,
                            child: IconButton(
                              icon: const Icon(
                                Icons.settings,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SettingsScreen(),
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
                                // Avatar Circle
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.grey[800],
                                    backgroundImage: avatarProvider,
                                    child: avatarProvider == null
                                        ? const Icon(
                                            Icons.person,
                                            size: 50,
                                            color: Colors.white54,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Name & Edit Button
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 12.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          profileState.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 32,
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
                                              side: BorderSide(
                                                color: Colors.grey[600]!,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                            ),
                                            child: const Text('Edit Profile'),
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
                      padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
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
                  ],
                ),
              ),

              // --- STICKY TAB BAR ---
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  const TabBar(
                    indicatorColor: Colors.amber,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: 'Movies'),
                      Tab(text: 'TV Shows'),
                    ],
                  ),
                ),
              ),
            ];
          },

          // --- TAB CONTENT ---
          body: TabBarView(
            children: [
              // MOVIE TAB
              ListView(
                padding: const EdgeInsets.only(top: 16, bottom: 80),
                children: [
                  _buildSectionHeader("Watched Movies"),
                  _buildMovieHorizontalList(context, watchedMovies),
                  const SizedBox(height: 24),
                  _buildSectionHeader("Rated Movies"),
                  _buildMovieHorizontalList(
                    context,
                    ratedMovies,
                    isRatedSection: true,
                  ),
                ],
              ),

              // TV SHOW TAB
              ListView(
                padding: const EdgeInsets.only(top: 16, bottom: 80),
                children: [
                  _buildSectionHeader("Completed Shows"),
                  tvAsyncValue.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(
                      child: Text(
                        'Error loading shows',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    data: (_) =>
                        _buildTvHorizontalList(context, completedShows),
                  ),
                ],
              ),
            ],
          ),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
        ],
      ),
    );
  }

  Widget _buildMovieHorizontalList(
    BuildContext context,
    List<Movie> movies, {
    bool isRatedSection = false,
  }) {
    if (movies.isEmpty) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        child: Text(
          "No movies ${isRatedSection ? 'rated' : 'watched'} yet.",
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }
    return SizedBox(
      height: 180,
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
              width: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      movie.posterPath,
                      height: 150,
                      width: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.grey[800], height: 150),
                    ),
                  ),
                  if (isRatedSection) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          movie.myRating?.toStringAsFixed(1) ?? "0.0",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTvHorizontalList(BuildContext context, List<TvShow> shows) {
    if (shows.isEmpty) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        child: const Text(
          "No shows completed yet.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return SizedBox(
      height: 150,
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

// Helper class to make the TabBar sticky inside a NestedScrollView
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.black, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
