import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/auth_service.dart';
import '../../../tv_shows/presentation/providers/tv_providers.dart';
import '../../../tv_shows/presentation/widgets/tv_time_card.dart';
import '../../../tv_shows/domain/entities/tv_show.dart';

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

                // TAB 2: Upcoming (Empty State for now)
                _buildUpcomingTab(),
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
    // Watch your Firestore stream provider
    final watchlistAsync = ref.watch(tvWatchlistProvider(currentUserId));

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

  Widget _buildUpcomingTab() {
    return const Center(
      child: Text(
        'No upcoming episodes.',
        style: TextStyle(color: Colors.grey, fontSize: 16),
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
