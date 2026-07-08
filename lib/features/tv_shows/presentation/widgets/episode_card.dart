import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tv_providers.dart';

// 1. Extend ConsumerWidget instead of StatelessWidget to get access to WidgetRef
class EpisodeCard extends ConsumerWidget {
  final String showId;
  final int seasonNum;
  final int episodeNum;
  // Assume you get the current user ID from your auth provider
  final String currentUserId; 

  const EpisodeCard({
    super.key,
    required this.showId,
    required this.seasonNum,
    required this.episodeNum,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2. Listen for side effects (like errors). 
    // ref.listen doesn't rebuild the widget, it just fires a callback.
    ref.listen<AsyncValue<void>>(
      tvShowActionProvider,
      (previousState, nextState) {
        nextState.whenOrNull(
          error: (error, stackTrace) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update: $error'),
                backgroundColor: Colors.red,
              ),
            );
          },
        );
      },
    );

    // 3. Watch the state to rebuild the UI when it changes to loading/data/error
    final actionState = ref.watch(tvShowActionProvider);
    final isLoading = actionState.isLoading;

    return ListTile(
      title: Text('Season $seasonNum, Episode $episodeNum'),
      trailing: IconButton(
        // 4. Swap the icon out for a loading spinner while processing
        icon: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check_circle_outline),
        // Disable the button while loading to prevent double-taps
        onPressed: isLoading
            ? null
            : () {
                // 5. Use ref.read to trigger the method on the Notifier
                ref.read(tvShowActionProvider.notifier).markEpisodeWatched(
                      userId: currentUserId,
                      showId: showId,
                      seasonNum: seasonNum,
                      episodeNum: episodeNum,
                    );
              },
      ),
    );
  }
}