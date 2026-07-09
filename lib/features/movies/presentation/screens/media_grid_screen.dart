import 'package:flutter/material.dart';
import '../../data/models/movie_model.dart';
import '../../../tv_shows/domain/entities/tv_show.dart';
import '../providers/custom_lists_provider.dart';
import 'details_screen.dart';
import '../../../tv_shows/presentation/screens/tv_detail_screen.dart';
import 'list_detail_screen.dart';

class MediaGridScreen extends StatelessWidget {
  final String title;
  final List<dynamic> items;

  const MediaGridScreen({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final bool isListGrid = items.isNotEmpty && items.first is CustomList;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(title, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                "No items in this category.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isListGrid ? 2 : 3,
                childAspectRatio: isListGrid ? 1.3 : 2 / 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                if (item is CustomList) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ListDetailScreen(list: item),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[800]!),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${item.items.length} items',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final String posterPath = item is Movie ? item.posterPath : (item as TvShow).posterPath;
                final String displayTitle = item is Movie ? item.title : (item as TvShow).title;

                return GestureDetector(
                  onTap: () {
                    if (item is Movie) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailScreen(mediaItem: item, isMovie: true),
                        ),
                      );
                    } else if (item is TvShow) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TvDetailScreen(show: item),
                        ),
                      );
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      posterPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[800],
                        alignment: Alignment.center,
                        child: Text(
                          displayTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
