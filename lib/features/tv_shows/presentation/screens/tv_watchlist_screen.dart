import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tv_providers.dart';

class TvWatchlistScreen extends ConsumerWidget {
  final String currentUserId;

  const TvWatchlistScreen({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the stream provider and pass in the user ID
    final watchlistAsyncValue = ref.watch(tvWatchlistProvider(currentUserId));

    return Scaffold(
      appBar: AppBar(title: const Text('My Shows')),
      // .when handles the 3 possible states of a stream automatically
      body: watchlistAsyncValue.when(
        data: (shows) {
          if (shows.isEmpty) {
            return const Center(child: Text('Your watchlist is empty.'));
          }
          
          return ListView.builder(
            itemCount: shows.length,
            itemBuilder: (context, index) {
              final show = shows[index];
              return ListTile(
                title: Text(show.title),
                subtitle: Text('${show.progress} / ${show.totalEpisodes} Watched'),
                trailing: CircularProgressIndicator(
                  value: show.totalEpisodes > 0 
                      ? show.progress / show.totalEpisodes 
                      : 0,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error loading watchlist: $error'),
        ),
      ),
    );
  }
}