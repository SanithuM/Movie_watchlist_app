import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/tv_show.dart';
import '../providers/tv_providers.dart';
import '../screens/tv_detail_screen.dart';
import '../../../../core/utils/episode_calculator.dart';

class TvTimeCard extends ConsumerWidget {
  final TvShow show;
  final String currentUserId;

  const TvTimeCard({
    super.key, 
    required this.show, 
    required this.currentUserId
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dynamically calculate the season and episode using new utility
    final nextEpData = EpisodeCalculator.getNextEpisode(
      show.progress, 
      show.seasonEpisodeCounts,
    );

    final int nextSeason = nextEpData['season']!;
    final int nextEpisode = nextEpData['episode']!;
    final bool isCompleted = nextSeason == -1;

    // Calculate how many episodes are left in the current season
    final int episodesLeft = isCompleted 
        ? 0 
        : show.seasonEpisodeCounts[nextSeason - 1] - nextEpisode;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TvDetailScreen(show: show),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[900]!),
        ),
        child: Row(
          children: [
            // 1. Left Image (Cropped)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Image.network(
                show.posterPath,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => Container(
                  width: 110,
                  height: 110,
                  color: Colors.grey[800],
                  child: const Icon(Icons.tv, color: Colors.grey),
                ),
              ),
            ),
            
            const SizedBox(width: 12),

            // 2. Middle Info Column
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Show Title Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[700]!),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              show.title.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 8),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Episode String (e.g., S01 | E03 +13)
                    Row(
                      children: [
                        Text(
                          isCompleted 
                              ? 'COMPLETED' 
                              : 'S${nextSeason.toString().padLeft(2, '0')} | E${nextEpisode.toString().padLeft(2, '0')}', 
                          style: TextStyle(
                            color: isCompleted ? Colors.green : Colors.white, 
                            fontSize: 16, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        if (!isCompleted && episodesLeft > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '+$episodesLeft',
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 3. Right Action Button (Checkmark)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: IconButton(
                icon: Icon(
                  isCompleted ? Icons.check_circle : Icons.check_circle_outline, 
                  color: isCompleted ? Colors.green : Colors.grey, 
                  size: 32,
                ),
                onPressed: isCompleted ? null : () {
                  // Trigger the Riverpod action to mark as watched
                  ref.read(tvShowActionProvider.notifier).markEpisodeWatched(
                    userId: currentUserId,
                    showId: show.id,
                    seasonNum: nextSeason, 
                    episodeNum: nextEpisode,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}