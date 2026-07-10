import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/tv_show.dart';
import '../providers/tv_providers.dart';
import '../../../movies/presentation/providers/custom_lists_provider.dart';
import '../../../../core/utils/episode_calculator.dart';

class TvDetailScreen extends ConsumerStatefulWidget {
  final TvShow show;

  const TvDetailScreen({super.key, required this.show});

  @override
  ConsumerState<TvDetailScreen> createState() => _TvDetailScreenState();
}

class _TvDetailScreenState extends ConsumerState<TvDetailScreen> {
  final Set<int> _expandedSeasons = {};

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

  String _getNetworkName(Map<String, dynamic> details) {
    final networks = details['networks'] as List<dynamic>?;
    if (networks != null && networks.isNotEmpty) {
      return networks[0]['name'] ?? 'Unknown Network';
    }
    return 'Unknown Network';
  }

  Widget _buildAboutTab(BuildContext context, Map<String, dynamic> details, TvShow liveShow, User? currentUser, bool isLoading, AsyncValue<List<TvShow>> watchlistAsync) {
    final String overviewText = details['overview'] ?? 'No synopsis available.';
    final runtimeList = details['episode_run_time'] as List?;
    final int episodeRuntime = (runtimeList != null && runtimeList.isNotEmpty)
        ? (runtimeList.first as num).toInt()
        : 45;

    final genresList = (details['genres'] as List?)
        ?.map((g) => g['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toList() ?? [];

    final isTracked = watchlistAsync.value?.any((s) => s.id == widget.show.id) ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tracking Section
          const Text(
            'TRACKING STATUS',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          if (currentUser == null)
            const Text(
              'Sign in to track this show.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            )
          else if (!isTracked)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add Show to Watchlist',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: isLoading ? null : () async {
                  final totalEpisodes = (details['number_of_episodes'] as int?) ?? 0;
                  final seasons = (details['seasons'] as List<dynamic>?) ?? [];
                  final seasonEpisodeCounts = <int>[];
                  for (var season in seasons) {
                    final seasonNum = season['season_number'] as int?;
                    final episodeCount = season['episode_count'] as int?;
                    if (seasonNum != null && seasonNum > 0 && episodeCount != null) {
                      seasonEpisodeCounts.add(episodeCount);
                    }
                  }
                  final runTimeList = details['episode_run_time'] as List?;
                  final int episodeRunTime = (runTimeList != null && runTimeList.isNotEmpty)
                      ? (runTimeList.first as num).toInt()
                      : 45;

                  final showWithMetadata = TvShow(
                    id: widget.show.id,
                    title: widget.show.title,
                    posterPath: widget.show.posterPath,
                    progress: 0,
                    totalEpisodes: totalEpisodes,
                    status: 'watching',
                    seasonEpisodeCounts: seasonEpisodeCounts,
                    voteAverage: widget.show.voteAverage,
                    episodeRunTime: episodeRunTime,
                  );

                  await ref.read(tvShowActionProvider.notifier).addShow(
                    userId: currentUser.uid,
                    show: showWithMetadata,
                  );
                },
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: liveShow.status == 'dropped' ? 'dropped' : 'watching',
                  dropdownColor: Colors.grey[900],
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.amber),
                  items: const [
                    DropdownMenuItem(value: 'watching', child: Text('Watching')),
                    DropdownMenuItem(value: 'dropped', child: Text('Dropped')),
                  ],
                  onChanged: isLoading ? null : (val) async {
                    if (val == 'dropped') {
                      await ref.read(tvShowActionProvider.notifier).dropShow(
                        userId: currentUser.uid,
                        showId: widget.show.id,
                      );
                    } else {
                      final totalEpisodes = (details['number_of_episodes'] as int?) ?? 0;
                      final seasons = (details['seasons'] as List<dynamic>?) ?? [];
                      final seasonEpisodeCounts = <int>[];
                      for (var season in seasons) {
                        final seasonNum = season['season_number'] as int?;
                        final episodeCount = season['episode_count'] as int?;
                        if (seasonNum != null && seasonNum > 0 && episodeCount != null) {
                          seasonEpisodeCounts.add(episodeCount);
                        }
                      }
                      final runTimeList = details['episode_run_time'] as List?;
                      final int episodeRunTime = (runTimeList != null && runTimeList.isNotEmpty)
                          ? (runTimeList.first as num).toInt()
                          : 45;
                      final showWithMetadata = TvShow(
                        id: widget.show.id,
                        title: widget.show.title,
                        posterPath: widget.show.posterPath,
                        progress: liveShow.progress,
                        totalEpisodes: totalEpisodes,
                        status: 'watching',
                        seasonEpisodeCounts: seasonEpisodeCounts,
                        voteAverage: widget.show.voteAverage,
                        episodeRunTime: episodeRunTime,
                      );
                      await ref.read(tvShowActionProvider.notifier).addShow(
                        userId: currentUser.uid,
                        show: showWithMetadata,
                      );
                    }
                  },
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Synopsis
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
            overviewText,
            style: const TextStyle(color: Colors.grey, height: 1.5, fontSize: 15),
          ),
          const SizedBox(height: 24),
          // Information Section
          const Text(
            'Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Status', details['status'] ?? 'N/A'),
          _buildInfoRow('First Air Date', details['first_air_date'] ?? 'N/A'),
          _buildInfoRow('Last Air Date', details['last_air_date'] ?? 'N/A'),
          _buildInfoRow('Episode Runtime', '$episodeRuntime mins'),
          if (genresList.isNotEmpty)
            _buildInfoRow('Genres', genresList.join(', ')),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotTrackedEpisodesView(BuildContext context, WidgetRef ref, Map<String, dynamic> details, String userId, bool isLoading) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.tv_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Not Tracking Yet',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add this show to your watchlist to start tracking episodes and seasons progress.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Show to Watchlist', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: isLoading ? null : () async {
                final totalEpisodes = (details['number_of_episodes'] as int?) ?? 0;
                final seasons = (details['seasons'] as List<dynamic>?) ?? [];
                final seasonEpisodeCounts = <int>[];
                for (var season in seasons) {
                  final seasonNum = season['season_number'] as int?;
                  final episodeCount = season['episode_count'] as int?;
                  if (seasonNum != null && seasonNum > 0 && episodeCount != null) {
                    seasonEpisodeCounts.add(episodeCount);
                  }
                }
                final runTimeList = details['episode_run_time'] as List?;
                final int episodeRunTime = (runTimeList != null && runTimeList.isNotEmpty)
                    ? (runTimeList.first as num).toInt()
                    : 45;

                final showWithMetadata = TvShow(
                  id: widget.show.id,
                  title: widget.show.title,
                  posterPath: widget.show.posterPath,
                  progress: 0,
                  totalEpisodes: totalEpisodes,
                  status: 'watching',
                  seasonEpisodeCounts: seasonEpisodeCounts,
                  voteAverage: widget.show.voteAverage,
                  episodeRunTime: episodeRunTime,
                );

                await ref.read(tvShowActionProvider.notifier).addShow(
                  userId: userId,
                  show: showWithMetadata,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackedEpisodesView(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> details,
    TvShow liveShow,
    List<String> watchedEpisodeIds,
    String userId,
  ) {
    final seasons = details['seasons'] as List<dynamic>? ?? [];
    int totalEpisodes = 0;
    for (final s in seasons) {
      totalEpisodes += (s['episode_count'] as int? ?? 0);
    }

    final sortedSeasons = List<dynamic>.from(seasons)
      ..sort((a, b) {
        final aNum = a['season_number'] as int? ?? 0;
        final bNum = b['season_number'] as int? ?? 0;
        if (aNum == 0) return 1;
        if (bNum == 0) return -1;
        return aNum.compareTo(bNum);
      });

    List<int> seasonCounts = liveShow.seasonEpisodeCounts;
    if (seasonCounts.isEmpty) {
      seasonCounts = seasons
          .where((s) => (s['season_number'] as int? ?? 0) > 0)
          .map((s) => s['episode_count'] as int? ?? 0)
          .toList();
    }

    final nextEpData = EpisodeCalculator.getNextEpisode(liveShow.progress, seasonCounts);
    final int nextSeason = nextEpData['season']!;
    final int nextEpisode = nextEpData['episode']!;
    final bool isFinished = nextSeason == -1;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Continue tracking',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (watchedEpisodeIds.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.history, color: Colors.grey),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.grey[900],
                      title: const Text('Reset Progress', style: TextStyle(color: Colors.white)),
                      content: const Text(
                        'Are you sure you want to reset your progress? This will mark all episodes as unwatched.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await ref.read(tvShowActionProvider.notifier).resetShowProgress(
                              userId: userId,
                              showId: liveShow.id,
                              watchedEpisodeIds: watchedEpisodeIds,
                            );
                          },
                          child: const Text('Reset', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (isFinished) ...[
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: details['backdrop_path'] != null
                  ? DecorationImage(
                      image: NetworkImage('https://image.tmdb.org/t/p/w500${details['backdrop_path']}'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.75),
                        BlendMode.srcOver,
                      ),
                    )
                  : null,
              color: Colors.grey[900],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Finished',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "That's all, folks!",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          ref.watch(tvSeasonDetailsProvider('${liveShow.id}:$nextSeason')).when(
            data: (seasonData) {
              final episodes = seasonData['episodes'] as List<dynamic>? ?? [];
              final episode = episodes.firstWhere(
                (ep) => (ep['episode_number'] as int? ?? 0) == nextEpisode,
                orElse: () => null,
              );

              final String epTitle = episode != null ? (episode['name'] ?? 'TBA') : 'Episode $nextEpisode';
              final String epOverview = episode != null ? (episode['overview'] ?? '') : '';
              final String? stillPath = episode != null ? episode['still_path'] : null;

              final String epImageUrl = stillPath != null
                  ? 'https://image.tmdb.org/t/p/w500$stillPath'
                  : (details['backdrop_path'] != null
                      ? 'https://image.tmdb.org/t/p/w500${details['backdrop_path']}'
                      : liveShow.posterPath);

              return Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(epImageUrl),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.65),
                      BlendMode.srcOver,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await ref.read(tvShowActionProvider.notifier).markEpisodeWatched(
                          userId: userId,
                          showId: liveShow.id,
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
                        child: const Icon(Icons.check, color: Colors.black, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'S$nextSeason E$nextEpisode: $epTitle',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (epOverview.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              epOverview,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => Container(
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const CircularProgressIndicator(color: Colors.amber),
            ),
            error: (_, __) => Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await ref.read(tvShowActionProvider.notifier).markEpisodeWatched(
                        userId: userId,
                        showId: liveShow.id,
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
                      child: const Icon(Icons.check, color: Colors.black, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'S$nextSeason E$nextEpisode',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'All episodes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () async {
                await ref.read(tvShowActionProvider.notifier).toggleAllEpisodesWatched(
                  userId: userId,
                  showId: liveShow.id,
                  seasonsList: List<Map<String, dynamic>>.from(seasons),
                  watchedEpisodeIds: watchedEpisodeIds,
                );
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: (watchedEpisodeIds.length == totalEpisodes && totalEpisodes > 0)
                      ? Colors.green
                      : Colors.transparent,
                  border: (watchedEpisodeIds.length == totalEpisodes && totalEpisodes > 0)
                      ? null
                      : Border.all(color: Colors.grey),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: (watchedEpisodeIds.length == totalEpisodes && totalEpisodes > 0)
                      ? Colors.white
                      : Colors.grey,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: sortedSeasons.length,
          itemBuilder: (context, index) {
            final season = sortedSeasons[index];
            final seasonNum = season['season_number'] as int? ?? 0;
            final totalEpisodesInSeason = season['episode_count'] as int? ?? 0;
            final isSpecials = seasonNum == 0;
            final String seasonName = isSpecials ? "Specials" : (season['name'] ?? 'Season $seasonNum');

            final seasonWatchedPrefix = 'S${seasonNum}E';
            final int watchedInSeason = watchedEpisodeIds.where((id) => id.startsWith(seasonWatchedPrefix)).length;
            final bool isSeasonFullyWatched = watchedInSeason == totalEpisodesInSeason && totalEpisodesInSeason > 0;
            final bool isSeasonExpanded = _expandedSeasons.contains(seasonNum);

            return Container(
              margin: const EdgeInsets.only(bottom: 12.0),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey[850]!,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Column(
                  children: [
                  ListTile(
                    onTap: () {
                      setState(() {
                        if (isSeasonExpanded) {
                          _expandedSeasons.remove(seasonNum);
                        } else {
                          _expandedSeasons.add(seasonNum);
                        }
                      });
                    },
                    title: Row(
                      children: [
                        Text(
                          seasonName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isSeasonExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$watchedInSeason/$totalEpisodesInSeason',
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () async {
                            await ref.read(tvShowActionProvider.notifier).toggleSeasonWatched(
                              userId: userId,
                              showId: liveShow.id,
                              seasonNum: seasonNum,
                              totalEpisodesInSeason: totalEpisodesInSeason,
                              watchedEpisodeIds: watchedEpisodeIds,
                            );
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isSeasonFullyWatched ? Colors.green : Colors.transparent,
                              border: isSeasonFullyWatched ? null : Border.all(color: Colors.grey),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: isSeasonFullyWatched ? Colors.white : Colors.grey,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isSeasonExpanded) ...[
                    const Divider(color: Colors.grey, height: 1),
                    ref.watch(tvSeasonDetailsProvider('${liveShow.id}:$seasonNum')).when(
                      data: (seasonData) {
                        final episodes = seasonData['episodes'] as List<dynamic>? ?? [];
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          itemCount: episodes.length,
                          itemBuilder: (context, epIndex) {
                            final ep = episodes[epIndex];
                            final epNum = ep['episode_number'] as int? ?? 0;
                            final String epId = 'S${seasonNum}E$epNum';
                            final bool isEpWatched = watchedEpisodeIds.contains(epId);
                            final String epName = ep['name'] ?? 'Episode $epNum';
                            final String airDate = ep['air_date'] ?? 'No Air Date';

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Episode $epNum: $epName',
                                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          airDate,
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      if (isEpWatched) {
                                        await ref.read(tvShowActionProvider.notifier).unmarkEpisodeAsWatched(
                                          userId: userId,
                                          showId: liveShow.id,
                                          seasonNum: seasonNum,
                                          episodeNum: epNum,
                                        );
                                      } else {
                                        await ref.read(tvShowActionProvider.notifier).markEpisodeWatched(
                                          userId: userId,
                                          showId: liveShow.id,
                                          seasonNum: seasonNum,
                                          episodeNum: epNum,
                                        );
                                      }
                                    },
                                    child: Icon(
                                      isEpWatched ? Icons.check_circle : Icons.check_circle_outline,
                                      color: isEpWatched ? Colors.green : Colors.grey,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(color: Colors.amber),
                        ),
                      ),
                      error: (err, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Error: $err',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (isSeasonFullyWatched)
                    Container(
                      height: 3,
                      color: Colors.green,
                    ),
                ],
              ),
            ),
          );
          },
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(tvShowDetailsProvider(widget.show.id));
    final actionState = ref.watch(tvShowActionProvider);
    final bool isLoading = actionState.isLoading;

    final currentUser = FirebaseAuth.instance.currentUser;
    final watchlistAsync = ref.watch(tvWatchlistProvider(currentUser?.uid ?? ''));
    final liveShow = watchlistAsync.value?.cast<TvShow>().firstWhere(
      (s) => s.id == widget.show.id,
      orElse: () => widget.show,
    ) ?? widget.show;

    final watchedEpisodesAsync = ref.watch(tvWatchedEpisodesProvider(widget.show.id));
    final watchedEpisodeIds = watchedEpisodesAsync.value ?? [];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF141414),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 280.0,
                pinned: true,
                backgroundColor: const Color(0xFF141414),
                leading: IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
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
                              final isTracked = watchlistAsync.value?.any((s) => s.id == widget.show.id) ?? false;
                              if (!isTracked) {
                                final totalEpisodes = (detailsAsync.value?['number_of_episodes'] as int?) ?? 0;
                                final seasons = (detailsAsync.value?['seasons'] as List<dynamic>?) ?? [];
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
                                  id: widget.show.id,
                                  title: widget.show.title,
                                  posterPath: widget.show.posterPath,
                                  progress: 0,
                                  totalEpisodes: totalEpisodes,
                                  status: 'watching',
                                  seasonEpisodeCounts: seasonEpisodeCounts,
                                  voteAverage: widget.show.voteAverage,
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
                                      showId: widget.show.id,
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
                        widget.show.id,
                        widget.show.title,
                        widget.show.posterPath,
                        'tv',
                      ),
                    ),
                  ],
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: detailsAsync.when(
                    data: (details) {
                      final String? backdropPath = details['backdrop_path'];
                      final String imageUrl = backdropPath != null
                          ? 'https://image.tmdb.org/t/p/w1280$backdropPath'
                          : widget.show.posterPath;
                      final status = details['status'] ?? 'Unknown';
                      final numSeasons = details['number_of_seasons'] ?? 0;
                      final network = _getNetworkName(details);
                      final voteAverage = (details['vote_average'] as num?)?.toDouble() ?? 0.0;

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  const Color(0xFF141414),
                                  const Color(0xFF141414).withOpacity(0.0),
                                ],
                                stops: const [0.0, 1.0],
                              ),
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.4],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 60,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.show.title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 2),
                                        blurRadius: 4,
                                        color: Colors.black87,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$numSeasons seasons • $status • $network',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          shadows: [
                                            Shadow(
                                              offset: Offset(0, 1),
                                              blurRadius: 2,
                                              color: Colors.black87,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (voteAverage > 0) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'T',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${(voteAverage * 10).toInt()}%',
                                        style: const TextStyle(
                                          color: Colors.amber,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(widget.show.posterPath, fit: BoxFit.cover),
                        Container(color: Colors.black45),
                        const Center(child: CircularProgressIndicator(color: Colors.amber)),
                      ],
                    ),
                    error: (_, __) => Image.network(widget.show.posterPath, fit: BoxFit.cover),
                  ),
                ),
                bottom: const TabBar(
                  indicatorColor: Color(0xFF8B5CF6),
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                  tabs: [
                    Tab(text: 'ABOUT'),
                    Tab(text: 'EPISODES'),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              detailsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.amber)),
                error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                data: (details) => _buildAboutTab(context, details, liveShow, currentUser, isLoading, watchlistAsync),
              ),
              detailsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.amber)),
                error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                data: (details) {
                  if (currentUser == null) {
                    return const Center(
                      child: Text(
                        'Sign in to track episodes.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }

                  final isTracked = watchlistAsync.value?.any((s) => s.id == widget.show.id) ?? false;
                  if (!isTracked) {
                    return _buildNotTrackedEpisodesView(context, ref, details, currentUser.uid, isLoading);
                  }

                  return _buildTrackedEpisodesView(
                    context,
                    ref,
                    details,
                    liveShow,
                    watchedEpisodeIds,
                    currentUser.uid,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
