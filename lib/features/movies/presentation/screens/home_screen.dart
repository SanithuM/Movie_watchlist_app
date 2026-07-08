import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/auth_service.dart';
import '../../../tv_shows/presentation/providers/tv_providers.dart';
import '../../../tv_shows/presentation/widgets/tv_time_card.dart';

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
              title: const Text(
                'CineList',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white, size: 28),
                  onPressed: () {
                    Navigator.pushNamed(context, '/search');
                  },
                ),
              ],
              bottom: const TabBar(
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

    return Column(
      children: [
        // The "WATCH NEXT" Filter Bar (Static for layout purposes)
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
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'WATCH NEXT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.grid_view_rounded, color: Colors.grey),
            ],
          ),
        ),

        // The List of Shows
        Expanded(
          child: watchlistAsync.when(
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
              if (shows.isEmpty) return _buildEmptyState();

              return ListView.builder(
                itemCount: shows.length,
                padding: const EdgeInsets.only(bottom: 20),
                itemBuilder: (context, index) {
                  final show = shows[index];
                  // 2. We use the imported widget right here
                  return TvTimeCard(show: show, currentUserId: currentUserId);
                },
              );
            },
          ),
        ),
      ],
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
