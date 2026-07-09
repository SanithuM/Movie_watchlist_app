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

    final seasonAsync = !isCompleted 
        ? ref.watch(tvSeasonDetailsProvider('${show.id}:$nextSeason'))
        : null;

    String episodeTitle = '';
    bool isNew = false;
    if (seasonAsync != null && seasonAsync.hasValue) {
      final episodes = seasonAsync.value?['episodes'] as List<dynamic>? ?? [];
      final currentEp = episodes.firstWhere(
        (ep) => ep['episode_number'] == nextEpisode,
        orElse: () => null,
      );
      if (currentEp != null) {
        episodeTitle = currentEp['name'] ?? '';
        final airDateStr = currentEp['air_date'] as String?;
        if (airDateStr != null && airDateStr.isNotEmpty) {
          final airDate = DateTime.tryParse(airDateStr);
          if (airDate != null) {
            final diff = DateTime.now().difference(airDate).inDays.abs();
            isNew = diff <= 14;
          }
        }
      }
    }
    
    final bool isPremiere = nextEpisode == 1;

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
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Left Image (Cropped)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
              child: Image.network(
                show.posterPath,
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 1),
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
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right, color: Colors.white, size: 10),
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
                            style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Episode Title (e.g. Jer Bud)
                    if (!isCompleted)
                      Text(
                        episodeTitle.isNotEmpty ? episodeTitle : 'Loading details...',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    // Tags Row (PREMIERE, NEW)
                    if (!isCompleted && (isPremiere || isNew)) ...[
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

            // 3. Right Action Button (Checkmark)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: isCompleted
                  ? const Icon(Icons.check_circle, color: Colors.green, size: 36)
                  : GestureDetector(
                      onTap: () {
                        // Trigger the Riverpod action to mark as watched
                        ref.read(tvShowActionProvider.notifier).markEpisodeWatched(
                          userId: currentUserId,
                          showId: show.id,
                          seasonNum: nextSeason, 
                          episodeNum: nextEpisode,
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
                    ),
            ),
          ],
        ),
      ),
    );
  }
}