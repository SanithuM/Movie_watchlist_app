import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/tv_show.dart';
import '../providers/tv_providers.dart';
import '../../../movies/presentation/providers/custom_lists_provider.dart';

class TvDetailScreen extends ConsumerWidget {
  final TvShow show;

  const TvDetailScreen({super.key, required this.show});

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
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the future provider using the show's ID
    final detailsAsync = ref.watch(tvShowDetailsProvider(show.id));
    final actionState = ref.watch(tvShowActionProvider);
    final bool isLoading = actionState.isLoading;
    
    // Get current user from Firebase Auth
    final currentUser = FirebaseAuth.instance.currentUser;
    final watchlistAsync = ref.watch(tvWatchlistProvider(currentUser?.uid ?? ''));
    final liveShow = watchlistAsync.value?.cast<TvShow>().firstWhere(
      (s) => s.id == show.id,
      orElse: () => show,
    ) ?? show;

    // Safely extract the backdrop if the data has loaded
    final String? backdropPath = detailsAsync.value?['backdrop_path'];
    final String headerImageUrl = backdropPath != null
        ? 'https://image.tmdb.org/t/p/w1280$backdropPath'
        : show.posterPath; // Fallback to poster while loading


    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: CustomScrollView(
        slivers: [
          // --- HERO HEADER ---
          SliverAppBar(
            expandedHeight: 220.0,
            pinned: true,
            backgroundColor: const Color(0xFF141414),
            actions: [
              if (currentUser != null) ...[
                IconButton(
                  icon: Icon(
                    liveShow.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: liveShow.isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final isTracked = watchlistAsync.value?.any((s) => s.id == show.id) ?? false;
                          if (!isTracked) {
                            final totalEpisodes =
                                (detailsAsync.value?['number_of_episodes'] as int?) ?? 0;
                            final seasons =
                                (detailsAsync.value?['seasons'] as List<dynamic>?) ?? [];
                            final seasonEpisodeCounts = <int>[];

                            for (var season in seasons) {
                              final seasonNum = season['season_number'] as int?;
                              final episodeCount = season['episode_count'] as int?;
                              if (seasonNum != null && seasonNum > 0 && episodeCount != null) {
                                seasonEpisodeCounts.add(episodeCount);
                              }
                            }

                            final runTimeList = detailsAsync.value?['episode_run_time'] as List?;
                            final int episodeRunTime = (runTimeList != null && runTimeList.isNotEmpty)
                                ? (runTimeList.first as num).toInt()
                                : 45;

                            final showWithMetadata = TvShow(
                              id: show.id,
                              title: show.title,
                              posterPath: show.posterPath,
                              progress: 0,
                              totalEpisodes: totalEpisodes,
                              status: 'watching',
                              seasonEpisodeCounts: seasonEpisodeCounts,
                              voteAverage: show.voteAverage,
                              isFavorite: true,
                              episodeRunTime: episodeRunTime,
                            );

                            await ref.read(tvShowActionProvider.notifier).addShow(
                                  userId: currentUser.uid,
                                  show: showWithMetadata,
                                );
                          } else {
                            await ref.read(tvShowActionProvider.notifier).toggleFavorite(
                                  userId: currentUser.uid,
                                  showId: show.id,
                                  currentStatus: liveShow.isFavorite,
                                );
                          }
                          
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(liveShow.isFavorite
                                  ? "Removed from Favorites"
                                  : "Added to Favorites!"),
                            ),
                          );
                        },
                ),
                IconButton(
                  icon: const Icon(Icons.playlist_add, color: Colors.white),
                  onPressed: () => _showAddToListSheet(
                    context,
                    ref,
                    show.id,
                    show.title,
                    show.posterPath,
                    'tv',
                  ),
                ),
              ],
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(headerImageUrl, fit: BoxFit.cover),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          const Color(0xFF141414),
                          const Color(0xFF141414).withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- OVERLAPPING INFO & POSTER ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            show.posterPath,
                            width: 100,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 40.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  show.title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Display Network if data is ready, else show loading text
                                Text(
                                  detailsAsync.value != null
                                      ? _getNetworkName(detailsAsync.value!)
                                      : 'Loading...',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- ACTION BUTTON ---
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onPressed: isLoading ? null : () async {
                                if (currentUser == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please log in first')),
                                  );
                                  return;
                                }

                                // Get total episodes from the details
                                final totalEpisodes =
                                    (detailsAsync.value?['number_of_episodes'] as int?) ?? 0;
                                final seasons =
                                    (detailsAsync.value?['seasons'] as List<dynamic>?) ?? [];
                                final seasonEpisodeCounts = <int>[];

                                for (var season in seasons) {
                                  final seasonNum = season['season_number'] as int?;
                                  final episodeCount = season['episode_count'] as int?;
                                  if (seasonNum != null && seasonNum > 0 && episodeCount != null) {
                                    seasonEpisodeCounts.add(episodeCount);
                                  }
                                }

                                final runTimeList = detailsAsync.value?['episode_run_time'] as List?;
                                final int episodeRunTime = (runTimeList != null && runTimeList.isNotEmpty)
                                    ? (runTimeList.first as num).toInt()
                                    : 45;

                                // Create TvShow object with full data
                                final showWithMetadata = TvShow(
                                  id: show.id,
                                  title: show.title,
                                  posterPath: show.posterPath,
                                  progress: 0,
                                  totalEpisodes: totalEpisodes,
                                  status: 'watching',
                                  seasonEpisodeCounts: seasonEpisodeCounts,
                                  voteAverage: show.voteAverage,
                                  episodeRunTime: episodeRunTime,
                                );

                                // Call the action
                                await ref.read(tvShowActionProvider.notifier).addShow(
                                      userId: currentUser.uid,
                                      show: showWithMetadata,
                                    );

                                if (!context.mounted) return;

                                // Handle result
                                final result = ref.read(tvShowActionProvider);
                                result.whenOrNull(
                                  error: (error, _) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $error')),
                                    );
                                  },
                                  data: (_) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Show added to watchlist!')),
                                    );
                                  },
                                );
                              },
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Add Show',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- DYNAMIC CONTENT (SYNOPSIS & SEASONS) ---
          // A SliverToBoxAdapter must contain the AsyncValue.when so it returns a valid Sliver
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: detailsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: Colors.amber),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Text(
                    'Error loading details: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                data: (details) {
                  final seasons = details['seasons'] as List<dynamic>? ?? [];
                  // Filter out "Specials" (Season 0) if you only want main seasons
                  final mainSeasons = seasons
                      .where((s) => s['season_number'] > 0)
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Synopsis',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        details['overview'] ?? 'No synopsis available.',
                        style: const TextStyle(color: Colors.grey, height: 1.5),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Seasons',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // We use shrinkWrap: true because this ListView is inside a CustomScrollView
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: mainSeasons.length,
                        itemBuilder: (context, index) {
                          final season = mainSeasons[index];
                          return Card(
                            color: Colors.grey[900],
                            margin: const EdgeInsets.only(bottom: 8.0),
                            child: ListTile(
                              leading: season['poster_path'] != null
                                  ? Image.network(
                                      'https://image.tmdb.org/t/p/w200${season['poster_path']}',
                                      width: 40,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.tv, color: Colors.grey),
                              title: Text(
                                season['name'] ??
                                    'Season ${season['season_number']}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                '${season['episode_count']} Episodes',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                              onTap: () {
                                // TODO: Navigate to Season Detail Screen
                                // to show the list of episodes
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to extract the network safely
  String _getNetworkName(Map<String, dynamic> details) {
    final networks = details['networks'] as List<dynamic>?;
    if (networks != null && networks.isNotEmpty) {
      return networks[0]['name'] ?? 'Unknown Network';
    }
    return 'Unknown Network';
  }
}
