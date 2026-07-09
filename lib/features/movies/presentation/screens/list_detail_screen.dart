import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/custom_lists_provider.dart';
import 'details_screen.dart';
import '../../../tv_shows/presentation/screens/tv_detail_screen.dart';
import '../../../tv_shows/domain/entities/tv_show.dart';
import '../../data/models/movie_model.dart';

class ListDetailScreen extends ConsumerWidget {
  final CustomList list;

  const ListDetailScreen({super.key, required this.list});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch custom lists to get live updates for this list
    final listsAsync = ref.watch(customListsProvider);
    final liveList = listsAsync.value?.firstWhere(
          (l) => l.id == list.id,
          orElse: () => list,
        ) ??
        list;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(liveList.name, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => _confirmDeleteList(context, ref, liveList),
          ),
        ],
      ),
      body: liveList.items.isEmpty
          ? const Center(
              child: Text(
                "This list is empty.\nAdd movies or TV shows from their detail pages!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2 / 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: liveList.items.length,
              itemBuilder: (context, index) {
                final item = liveList.items[index];
                return GestureDetector(
                  onTap: () {
                    if (item.type == 'movie') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailScreen(
                            mediaItem: Movie(
                              id: int.parse(item.id),
                              title: item.title,
                              posterPath: item.posterPath,
                              overview: '',
                              voteAverage: 0.0,
                            ),
                            isMovie: true,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TvDetailScreen(
                            show: TvShow(
                              id: item.id,
                              title: item.title,
                              posterPath: item.posterPath,
                              progress: 0,
                              totalEpisodes: 0,
                              status: 'watching',
                              seasonEpisodeCounts: [],
                              episodeRunTime: 45,
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.posterPath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[800],
                            alignment: Alignment.center,
                            child: Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                      // Translucent gradient overlay for readability of list items
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black87, Colors.transparent],
                            ),
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                          ),
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      // Small media type badge
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.type.toUpperCase(),
                            style: const TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      // Translucent delete button
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () async {
                            await ref.read(customListsProvider.notifier).toggleItemInList(
                                  listId: liveList.id,
                                  itemId: item.id,
                                  title: item.title,
                                  posterPath: item.posterPath,
                                  type: item.type,
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Removed "${item.title}" from list')),
                              );
                            }
                          },
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black.withOpacity(0.6),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _confirmDeleteList(BuildContext context, WidgetRef ref, CustomList liveList) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text("Delete List?", style: TextStyle(color: Colors.white)),
          content: Text(
            "Are you sure you want to delete the list \"${liveList.name}\"? This action cannot be undone.",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                await ref.read(customListsProvider.notifier).deleteList(liveList.id);
                if (context.mounted) {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // back to profile
                }
              },
              child: const Text("Delete", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
