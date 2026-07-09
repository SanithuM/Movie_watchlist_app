import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/auth_service.dart';
import '../../../tv_shows/presentation/providers/tv_providers.dart';
import '../../../tv_shows/presentation/widgets/tv_time_card.dart';
import '../../../tv_shows/domain/entities/tv_show.dart';
import '../../../tv_shows/presentation/screens/tv_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
                'Sign in to view your TV watchlist.',
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
                _buildWatchListTab(context, ref, user.uid),

                // TAB 2: Upcoming
                _buildUpcomingTab(context, ref, user.uid),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWatchListTab(
    BuildContext context,
    WidgetRef ref,
    String currentUserId,
  ) {
    // Watch your sorted Firestore/TMDB provider
    final watchlistAsync = ref.watch(tvSortedWatchlistProvider(currentUserId));

    return watchlistAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      error: (err, stack) {
        final message = err.toString().contains('permission-denied')
            ? 'You are signed in, but Firestore is blocking this read. Check your Firestore rules for users/$currentUserId/trackedShows.'
            : 'Error: $err';

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        );
      },
      data: (shows) {
        final remainingShows = shows
            .where((show) =>
                show.status != 'dropped' &&
                (show.totalEpisodes == 0 ||
                 show.progress < show.totalEpisodes))
            .toList();

        if (remainingShows.isEmpty) return _buildEmptyState();

        final watchNextShows = <TvShow>[];
        final haventWatchedShows = <TvShow>[];

        final now = DateTime.now();
        for (final show in remainingShows) {
          if (show.updatedAt != null) {
            final diff = now.difference(show.updatedAt!);
            if (diff.inDays >= 7) {
              haventWatchedShows.add(show);
            } else {
              watchNextShows.add(show);
            }
          } else {
            // Fallback split if updatedAt is not set: first 2 are watchNext, rest are haventWatched
            if (watchNextShows.length < 2) {
              watchNextShows.add(show);
            } else {
              haventWatchedShows.add(show);
            }
          }
        }

        final listItems = <Widget>[];

        // WATCH NEXT SECTION
        if (watchNextShows.isNotEmpty) {
          listItems.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2E2E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'WATCH NEXT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Icon(Icons.grid_view_rounded, color: Colors.grey, size: 24),
                ],
              ),
            ),
          );

          for (final show in watchNextShows) {
            listItems.add(
              Dismissible(
                key: Key('dismiss_tv_${show.id}'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E1E),
                      title: const Text("Drop Show?", style: TextStyle(color: Colors.white)),
                      content: Text(
                        "Are you sure you want to drop \"${show.title}\" from your watchlist?",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Drop"),
                        ),
                      ],
                    ),
                  );
                  return confirm ?? false;
                },
                background: Container(
                  color: Colors.red[900],
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      Text(
                        "Drop the Show ",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Icon(Icons.delete_outline, color: Colors.white),
                    ],
                  ),
                ),
                onDismissed: (direction) async {
                  await ref.read(tvShowActionProvider.notifier).dropShow(
                    userId: currentUserId,
                    showId: show.id,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${show.title}" dropped from your watchlist.'),
                      ),
                    );
                  }
                },
                child: TvTimeCard(show: show, currentUserId: currentUserId),
              ),
            );
          }
        }

        // HAVEN'T WATCHED FOR A WHILE SECTION
        if (haventWatchedShows.isNotEmpty) {
          listItems.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2E2E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "HAVEN'T WATCHED FOR A WHILE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

          for (final show in haventWatchedShows) {
            listItems.add(
              Dismissible(
                key: Key('dismiss_tv_${show.id}'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E1E),
                      title: const Text("Drop Show?", style: TextStyle(color: Colors.white)),
                      content: Text(
                        "Are you sure you want to drop \"${show.title}\" from your watchlist?",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Drop"),
                        ),
                      ],
                    ),
                  );
                  return confirm ?? false;
                },
                background: Container(
                  color: Colors.red[900],
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      Text(
                        "Drop the Show ",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Icon(Icons.delete_outline, color: Colors.white),
                    ],
                  ),
                ),
                onDismissed: (direction) async {
                  await ref.read(tvShowActionProvider.notifier).dropShow(
                    userId: currentUserId,
                    showId: show.id,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${show.title}" dropped from your watchlist.'),
                      ),
                    );
                  }
                },
                child: TvTimeCard(show: show, currentUserId: currentUserId),
              ),
            );
          }
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: listItems,
        );
      },
    );
  }

  Widget _buildUpcomingTab(BuildContext context, WidgetRef ref, String currentUserId) {
    final upcomingAsync = ref.watch(tvUpcomingEpisodesProvider(currentUserId));

    return upcomingAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Error loading upcoming episodes: $err',
          style: const TextStyle(color: Colors.red),
        ),
      ),
      data: (episodes) {
        if (episodes.isEmpty) {
          return const Center(
            child: Text(
              'No upcoming episodes.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        // Group the episodes by airDate/label
        final Map<String, List<UpcomingEpisode>> groupedEpisodes = {};
        final List<String> groupOrder = [];

        String formatAirDate(DateTime date) {
          const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
          return "${months[date.month - 1]} ${date.day}, ${date.year}";
        }

        String getDayName(DateTime date) {
          const days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
          return days[date.weekday - 1];
        }

        String getGroupLabel(DateTime date) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final epDate = DateTime(date.year, date.month, date.day);
          
          final difference = epDate.difference(today).inDays;
          
          if (difference <= 0) {
            return formatAirDate(epDate);
          } else if (difference < 7) {
            return getDayName(epDate);
          } else {
            return 'LATER';
          }
        }

        for (final ep in episodes) {
          final label = getGroupLabel(ep.airDate);
          if (!groupedEpisodes.containsKey(label)) {
            groupedEpisodes[label] = [];
            groupOrder.add(label);
          }
          groupedEpisodes[label]!.add(ep);
        }

        final listItems = <Widget>[];

        for (final label in groupOrder) {
          listItems.add(
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 16.0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2E2E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );

          final sectionEpisodes = groupedEpisodes[label]!;
          for (final ep in sectionEpisodes) {
            listItems.add(_buildUpcomingCard(context, ref, currentUserId, ep, label == 'LATER'));
          }
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: listItems,
        );
      },
    );
  }

  Widget _buildUpcomingCard(
    BuildContext context,
    WidgetRef ref,
    String currentUserId,
    UpcomingEpisode ep,
    bool isLater,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysDifference = ep.airDate.difference(today).inDays;

    final isPremiere = ep.episodeNumber == 1;
    final isNew = ep.isAired; 

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TvDetailScreen(show: ep.show),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
              child: Image.network(
                ep.show.posterPath,
                width: 95,
                height: 125,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => Container(
                  width: 95,
                  height: 125,
                  color: Colors.grey[900],
                  child: const Icon(Icons.tv, color: Colors.grey),
                ),
              ),
            ),
            
            const SizedBox(width: 16),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white54, width: 1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              ep.show.title.toUpperCase(),
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
                          const Icon(Icons.chevron_right, color: Colors.white54, size: 10),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'S${ep.seasonNumber.toString().padLeft(2, '0')} | E${ep.episodeNumber.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      ep.episodeTitle,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (isPremiere || isNew) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (isPremiere)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PREMIERE',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (isNew)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ep.isAired
                  ? GestureDetector(
                      onTap: () {
                        ref.read(tvShowActionProvider.notifier).markEpisodeWatched(
                          userId: currentUserId,
                          showId: ep.show.id,
                          seasonNum: ep.seasonNumber,
                          episodeNum: ep.episodeNumber,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${ep.show.title} S${ep.seasonNumber}E${ep.episodeNumber} marked as watched!',
                            ),
                          ),
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
                    )
                  : isLater
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '$daysDifference',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'DAYS',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              ep.airTime,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ep.network,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.tv_off_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No shows added yet!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Search and add shows to track them.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
