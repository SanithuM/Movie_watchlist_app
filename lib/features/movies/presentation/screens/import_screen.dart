import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/api_service.dart';
import '../../data/models/movie_model.dart';
import '../providers/wishlist_provider.dart';
import '../../../tv_shows/domain/entities/tv_show.dart';
import '../../../tv_shows/presentation/providers/tv_providers.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  bool _isImporting = false;
  String _statusMessage = 'Select your TV Time CSV export to begin.';
  double _progress = 0.0;
  List<_FailedImportItem> _failedItems = [];

  Future<void> _startImport() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) {
      return;
    }

    setState(() {
      _isImporting = true;
      _failedItems = [];
      _statusMessage = 'Parsing CSV file...';
      _progress = 0.1;
    });

    try {
      final bytes = result.files.single.bytes!;
      final csvString = utf8.decode(bytes, allowMalformed: true);

      List<List<dynamic>> csvTable = const CsvToListConverter(
        eol: '\n',
      ).convert(csvString);
      if (csvTable.length <= 1) {
        csvTable = const CsvToListConverter(eol: '\r\n').convert(csvString);
      }

      if (csvTable.length <= 1) {
        throw Exception(
          'CSV file appears empty or could not be parsed. Found ${csvTable.length} rows.',
        );
      }

      final headers = csvTable.first
          .map((e) => e.toString().toLowerCase().trim())
          .toList();

      final tvShowNameIndex = _findHeaderIndex(headers, [
        'tv_show_name',
        'show_name',
        'series_name',
        'show_title',
        'series_title',
        'show',
        'series',
        'tv_show',
      ]);

      final movieTitleIndex = _findHeaderIndex(headers, [
        'movie_title',
        'movie_name',
        'title',
        'name',
      ]);

      final mediaTypeIndex = _findHeaderIndex(headers, ['media_type', 'type']);
      final yearIndex = _findHeaderIndex(headers, ['year', 'release_year']);
      final ratingIndex = _findHeaderIndex(headers, ['rating', 'my_rating']);
      final watchedAtIndex = _findHeaderIndex(headers, ['watched_at']);
      final seasonIndex = _findHeaderIndex(headers, ['season', 'season_number', 'season_num', 'season_number_index']);
      final episodeIndex = _findHeaderIndex(headers, ['episode', 'episode_number', 'episode_num', 'episode_number_index']);

      // We need at least one title column index
      final titleIndex = movieTitleIndex >= 0 ? movieTitleIndex : tvShowNameIndex;

      if (titleIndex == -1) {
        throw Exception(
          'Could not find a title or show name column. Found headers: $headers',
        );
      }

      final hasTvHeaders = tvShowNameIndex >= 0 || seasonIndex >= 0 || episodeIndex >= 0;

      String safeString(dynamic val) {
        if (val == null) return '';
        final s = val.toString().trim();
        return s.toLowerCase() == 'null' ? '' : s;
      }

      final rowsToImport = <_ImportRow>[];
      for (int i = 1; i < csvTable.length; i++) {
        final row = csvTable[i];
        if (row.length <= titleIndex) continue;

        final mediaType = mediaTypeIndex >= 0 && row.length > mediaTypeIndex
            ? safeString(row[mediaTypeIndex]).toLowerCase()
            : '';

        bool isTv = false;
        if (mediaType.isNotEmpty) {
          isTv = mediaType == 'tv' ||
              mediaType == 'show' ||
              mediaType == 'series' ||
              mediaType == 'episode';
        } else {
          isTv = hasTvHeaders;
        }

        String title = '';
        if (isTv) {
          if (tvShowNameIndex >= 0 && row.length > tvShowNameIndex) {
            title = safeString(row[tvShowNameIndex]);
          } else if (movieTitleIndex >= 0 && row.length > movieTitleIndex) {
            title = safeString(row[movieTitleIndex]);
          }
        } else {
          if (movieTitleIndex >= 0 && row.length > movieTitleIndex) {
            title = safeString(row[movieTitleIndex]);
          } else if (tvShowNameIndex >= 0 && row.length > tvShowNameIndex) {
            title = safeString(row[tvShowNameIndex]);
          }
        }

        if (title.isEmpty) continue;

        final year = yearIndex >= 0 && row.length > yearIndex
            ? safeString(row[yearIndex])
            : '';
        final ratingText = ratingIndex >= 0 && row.length > ratingIndex
            ? safeString(row[ratingIndex])
            : '';
        final watchedAt = watchedAtIndex >= 0 && row.length > watchedAtIndex
            ? safeString(row[watchedAtIndex])
            : '';

        final seasonText = seasonIndex >= 0 && row.length > seasonIndex
            ? safeString(row[seasonIndex])
            : '';
        final episodeText = episodeIndex >= 0 && row.length > episodeIndex
            ? safeString(row[episodeIndex])
            : '';

        final season = int.tryParse(seasonText);
        final episode = int.tryParse(episodeText);

        rowsToImport.add(
          _ImportRow(
            index: i,
            title: title,
            mediaType: mediaType,
            year: year,
            ratingText: ratingText,
            watchedAt: watchedAt,
            season: season,
            episode: episode,
            forceTvShow: isTv,
          ),
        );
      }

      if (rowsToImport.isEmpty) {
        throw Exception(
          'Parsed successfully, but found no valid media entries.',
        );
      }

      // Group rows to optimize TV show imports (reducing network requests and writing watched history)
      final tvShowTasks = <String, List<_ImportRow>>{};
      final groupedTasks = <_GroupedImportTask>[];

      for (final row in rowsToImport) {
        if (row.isTvShow) {
          final key = row.title.toLowerCase().trim();
          if (key.isNotEmpty) {
            tvShowTasks.putIfAbsent(key, () => []).add(row);
          }
        } else {
          groupedTasks.add(
            _GroupedImportTask(
              title: row.title,
              isTvShow: false,
              rows: [row],
            ),
          );
        }
      }

      for (final entry in tvShowTasks.entries) {
        final rows = entry.value;
        if (rows.isNotEmpty) {
          groupedTasks.add(
            _GroupedImportTask(
              title: rows.first.title, // Use original casing
              isTvShow: true,
              rows: rows,
            ),
          );
        }
      }

      final totalShows = groupedTasks.where((task) => task.isTvShow).length;
      final totalMovies = groupedTasks.where((task) => !task.isTvShow).length;

      if (!mounted) return;
      setState(() {
        _statusMessage =
            'Found $totalShows TV shows and $totalMovies movies. Starting import...';
      });

      final apiService = ref.read(apiServiceProvider);
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      var successCount = 0;
      var skippedCount = 0;
      final failedItems = <_FailedImportItem>[];

      for (int i = 0; i < groupedTasks.length; i++) {
        final task = groupedTasks[i];

        if (!mounted) return;
        setState(() {
          _statusMessage =
              'Importing "${task.title}"... (${i + 1}/${groupedTasks.length})';
          _progress = 0.1 + (0.9 * (i / groupedTasks.length));
        });

        final failureReason = await _importGroupedTask(
          apiService: apiService,
          currentUserId: currentUserId,
          task: task,
        );

        if (failureReason == null) {
          successCount++;
        } else {
          skippedCount++;
          failedItems.add(
            _FailedImportItem(
              row: task.rows.first,
              allRows: task.rows,
              reason: failureReason,
            ),
          );
        }

        await Future.delayed(const Duration(milliseconds: 250));
      }

      if (!mounted) return;
      setState(() {
        _isImporting = false;
        _progress = 1.0;
        _failedItems = failedItems;
        _statusMessage = failedItems.isEmpty
            ? 'Import Complete! Imported $successCount items.'
            : 'Import Complete! Imported $successCount items. Skipped $skippedCount. ${failedItems.length} need manual matching.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isImporting = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<String?> _importGroupedTask({
    required ApiService apiService,
    required String currentUserId,
    required _GroupedImportTask task,
  }) async {
    try {
      if (task.isTvShow) {
        final representativeRow = task.rows.first;
        final searchResults = await _searchTvShowMatches(apiService, representativeRow);
        if (searchResults.isEmpty) {
          return 'TMDB could not find this TV show.';
        }

        final firstResult = searchResults.first;
        final tmdbId = firstResult['id'].toString();

        await _saveTvShowWithEpisodes(
          apiService: apiService,
          currentUserId: currentUserId,
          tmdbId: tmdbId,
          showTitle: firstResult['name'] ?? representativeRow.title,
          rows: task.rows,
        );
        return null;
      }

      if (!task.isTvShow) {
        final row = task.rows.first;
        final searchResults = await _searchMovieMatches(apiService, row);
        if (searchResults.isEmpty) {
          return 'TMDB could not find this movie.';
        }

        final movie = Movie.fromJson(
          Map<String, dynamic>.from(searchResults.first),
        );
        await ref
            .read(wishlistProvider.notifier)
            .addMovie(
              Movie(
                id: movie.id,
                title: movie.title,
                posterPath: movie.posterPath,
                overview: movie.overview,
                voteAverage: movie.voteAverage,
                releaseDate: movie.releaseDate,
                isWatched: true,
                myRating: double.tryParse(row.ratingText),
              ),
            );
        return null;
      }

      return 'Unsupported media type.';
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> _saveTvShowWithEpisodes({
    required ApiService apiService,
    required String currentUserId,
    required String tmdbId,
    required String showTitle,
    required List<_ImportRow> rows,
  }) async {
    final details = await apiService.fetchTvShowDetails(tmdbId);
    final runTimeList = details['episode_run_time'] as List?;
    final int episodeRunTime = (runTimeList != null && runTimeList.isNotEmpty)
        ? (runTimeList.first as num).toInt()
        : 45;
    final seasons = details['seasons'] as List? ?? [];
    final episodeCounts = seasons
        .where((s) =>
            s != null &&
            s is Map &&
            s['season_number'] != null &&
            (s['season_number'] as num) > 0)
        .map<int>((s) => (s['episode_count'] as num?)?.toInt() ?? 0)
        .toList();

    final totalEpisodes = episodeCounts.fold<int>(
      0,
      (acc, val) => acc + val,
    );

    final watchedEpisodes = <String>{};
    final watchedList = <Map<String, dynamic>>[];

    bool hasEpisodeDetails = false;
    for (final row in rows) {
      if (row.season != null && row.episode != null) {
        hasEpisodeDetails = true;
        final key = 'S${row.season}E${row.episode}';
        if (!watchedEpisodes.contains(key)) {
          watchedEpisodes.add(key);
          watchedList.add({
            'seasonNumber': row.season,
            'episodeNumber': row.episode,
            'watchedAt': row.watchedAt.isNotEmpty
                ? DateTime.tryParse(row.watchedAt) ?? DateTime.now()
                : DateTime.now(),
          });
        }
      }
    }

    int episodesWatchedCount = 0;
    if (hasEpisodeDetails) {
      episodesWatchedCount = watchedEpisodes.length;
    } else {
      final watchedRows = rows.where((r) => r.watchedAt.isNotEmpty).length;
      episodesWatchedCount = watchedRows > 0 ? watchedRows : 1;
    }

    if (episodesWatchedCount > totalEpisodes && totalEpisodes > 0) {
      episodesWatchedCount = totalEpisodes;
    }

    final tvShow = TvShow(
      id: tmdbId,
      title: details['name'] ?? showTitle,
      posterPath: details['poster_path'] != null
          ? 'https://image.tmdb.org/t/p/w500${details['poster_path']}'
          : 'https://via.placeholder.com/200x300',
      progress: episodesWatchedCount,
      totalEpisodes: totalEpisodes,
      status: episodesWatchedCount >= totalEpisodes ? 'completed' : 'watching',
      seasonEpisodeCounts: episodeCounts,
      voteAverage: (details['vote_average'] ?? 0.0).toDouble(),
      episodeRunTime: episodeRunTime,
    );

    await ref
        .read(tvRepositoryProvider)
        .addShow(userId: currentUserId, show: tvShow);

    if (hasEpisodeDetails && watchedList.isNotEmpty) {
      final db = FirebaseFirestore.instance;
      final showRef = db
          .collection('users')
          .doc(currentUserId)
          .collection('trackedShows')
          .doc(tmdbId);

      for (var j = 0; j < watchedList.length; j += 500) {
        final end = j + 500 < watchedList.length ? j + 500 : watchedList.length;
        final batch = db.batch();

        for (var k = j; k < end; k++) {
          final ep = watchedList[k];
          final episodeId = 'S${ep['seasonNumber']}E${ep['episodeNumber']}';
          final episodeRef = showRef.collection('episodes').doc(episodeId);
          batch.set(episodeRef, {
            'seasonNumber': ep['seasonNumber'],
            'episodeNumber': ep['episodeNumber'],
            'watchedAt': Timestamp.fromDate(ep['watchedAt'] as DateTime),
          });
        }

        await batch.commit();
      }
    }
  }

  Future<void> _openManualMatchSheet(_FailedImportItem failedItem) async {
    final apiService = ref.read(apiServiceProvider);
    final queryController = TextEditingController(
      text: _buildSearchQuery(failedItem.row.title, failedItem.row.year),
    );
    List<dynamic> searchResults = [];
    String? errorText;
    bool isSearching = false;
    bool initialSearchTriggered = false;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF111111),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) {
          Future<void> runSearch(
            void Function(void Function()) setSheetState,
          ) async {
            final query = queryController.text.trim();
            if (query.isEmpty) {
              setSheetState(() {
                errorText = 'Enter a title to search.';
              });
              return;
            }

            setSheetState(() {
              isSearching = true;
              errorText = null;
            });

            try {
              final results = failedItem.row.isTvShow
                  ? await apiService.searchTvShows(query)
                  : await apiService.searchMovies(query);

              setSheetState(() {
                searchResults = results;
                isSearching = false;
                errorText = results.isEmpty ? 'No TMDB matches found.' : null;
              });
            } catch (e) {
              setSheetState(() {
                isSearching = false;
                errorText = e.toString();
              });
            }
          }

          Future<void> importSelection(
            Map<String, dynamic> selectedResult,
          ) async {
            try {
              await _importSelectedResult(failedItem.allRows, selectedResult);
              if (!mounted) return;
              setState(() {
                _failedItems.removeWhere(
                  (item) => item.row.index == failedItem.row.index,
                );
                _statusMessage = _failedItems.isEmpty
                    ? 'Manual import complete. All items imported.'
                    : 'Imported "${failedItem.row.title}" manually. ${_failedItems.length} still need matching.';
              });
              if (sheetContext.mounted) {
                Navigator.pop(sheetContext);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Imported "${failedItem.row.title}" successfully.',
                    ),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Manual import failed: $e')),
                );
              }
            }
          }

          return SafeArea(
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                if (!initialSearchTriggered) {
                  initialSearchTriggered = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!sheetContext.mounted) {
                      return;
                    }
                    runSearch(setSheetState);
                  });
                }

                return Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search manually',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          failedItem.row.title,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: queryController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Search TMDB',
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.grey[900],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onSubmitted: (_) => runSearch(setSheetState),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: isSearching
                                ? null
                                : () => runSearch(setSheetState),
                            child: Text(
                              isSearching ? 'Searching...' : 'Search',
                            ),
                          ),
                        ),
                        if (errorText != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            errorText!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Expanded(
                          child: searchResults.isEmpty && !isSearching
                              ? const Center(
                                  child: Text(
                                    'Search results will appear here.',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: searchResults.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final candidate = Map<String, dynamic>.from(
                                      searchResults[index],
                                    );
                                    return InkWell(
                                      onTap: () => importSelection(candidate),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[900],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey[800]!,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 72,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[850],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.movie_outlined,
                                                color: Colors.white54,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _candidateTitle(candidate),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _candidateSubtitle(
                                                      candidate,
                                                    ),
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                              Icons.chevron_right,
                                              color: Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    } finally {
      queryController.dispose();
    }
  }

  Future<void> _importSelectedResult(
    List<_ImportRow> rows,
    Map<String, dynamic> selectedResult,
  ) async {
    final apiService = ref.read(apiServiceProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    final firstRow = rows.first;

    if (firstRow.isTvShow) {
      final tmdbId = selectedResult['id'].toString();
      await _saveTvShowWithEpisodes(
        apiService: apiService,
        currentUserId: currentUserId,
        tmdbId: tmdbId,
        showTitle: selectedResult['name'] ?? firstRow.title,
        rows: rows,
      );
      return;
    }

    final movie = Movie.fromJson(selectedResult);
    await ref
        .read(wishlistProvider.notifier)
        .addMovie(
          Movie(
            id: movie.id,
            title: movie.title,
            posterPath: movie.posterPath,
            overview: movie.overview,
            voteAverage: movie.voteAverage,
            releaseDate: movie.releaseDate,
            isWatched: true,
            myRating: double.tryParse(firstRow.ratingText),
          ),
        );
  }

  Widget _buildFailedItemsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Needs manual matching',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_failedItems.length}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: _failedItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final failedItem = _failedItems[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: ListTile(
                  title: Text(
                    failedItem.row.title,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${failedItem.row.mediaTypeLabel} • ${failedItem.reason}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => _openManualMatchSheet(failedItem),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final showFailedPanel = !_isImporting && _failedItems.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Import from TV Time',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Icon(
                Icons.cloud_upload_outlined,
                size: 80,
                color: Colors.amber,
              ),
              const SizedBox(height: 24),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 24),
              if (_isImporting) ...[
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey,
                  color: Colors.amber,
                  minHeight: 8,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please do not close this screen. TMDB rate limits apply.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ] else if (showFailedPanel) ...[
                Expanded(child: _buildFailedItemsPanel()),
              ] else ...[
                const Spacer(),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isImporting ? null : _startImport,
                  child: const Text(
                    'Select CSV File',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int _findHeaderIndex(List<String> headers, List<String> candidates) {
  for (final candidate in candidates) {
    final index = headers.indexOf(candidate);
    if (index != -1) {
      return index;
    }
  }
  return -1;
}

String _buildSearchQuery(String title, String year) {
  final trimmedTitle = title.trim();
  if (year.isEmpty) return trimmedTitle;
  return '$trimmedTitle $year';
}

Future<List<dynamic>> _searchMovieMatches(
  ApiService apiService,
  _ImportRow row,
) async {
  final searchResults = await apiService.searchMovies(
    row.title,
    year: row.year,
  );
  if (searchResults.isNotEmpty || row.year.isEmpty) {
    return searchResults;
  }

  return apiService.searchMovies(row.title);
}

Future<List<dynamic>> _searchTvShowMatches(
  ApiService apiService,
  _ImportRow row,
) async {
  final searchResults = await apiService.searchTvShows(
    row.title,
    year: row.year,
  );
  if (searchResults.isNotEmpty || row.year.isEmpty) {
    return searchResults;
  }

  return apiService.searchTvShows(row.title);
}

String _candidateTitle(Map<String, dynamic> candidate) {
  return (candidate['title'] ?? candidate['name'] ?? 'Untitled').toString();
}

String _candidateSubtitle(Map<String, dynamic> candidate) {
  final year = (candidate['release_date'] ?? candidate['first_air_date'] ?? '')
      .toString()
      .trim();
  final rating = (candidate['vote_average'] ?? '').toString().trim();

  final parts = <String>[];
  if (year.isNotEmpty) {
    parts.add(year);
  }
  if (rating.isNotEmpty && rating != '0.0' && rating != '0') {
    parts.add('TMDB $rating');
  }
  return parts.isEmpty ? 'TMDB match' : parts.join(' • ');
}

class _GroupedImportTask {
  final String title;
  final bool isTvShow;
  final List<_ImportRow> rows;

  _GroupedImportTask({
    required this.title,
    required this.isTvShow,
    required this.rows,
  });
}

class _ImportRow {
  final int index;
  final String title;
  final String mediaType;
  final String year;
  final String ratingText;
  final String watchedAt;
  final int? season;
  final int? episode;
  final bool forceTvShow;

  const _ImportRow({
    required this.index,
    required this.title,
    required this.mediaType,
    required this.year,
    required this.ratingText,
    required this.watchedAt,
    this.season,
    this.episode,
    this.forceTvShow = false,
  });

  bool get isTvShow =>
      forceTvShow ||
      mediaType == 'tv' ||
      mediaType == 'show' ||
      mediaType == 'series' ||
      mediaType == 'episode';

  bool get isMovie =>
      !isTvShow && (mediaType == 'movie' || mediaType == 'film' || mediaType.isEmpty);

  String get mediaTypeLabel {
    if (isTvShow) return 'TV';
    if (isMovie) return 'Movie';
    return mediaType;
  }
}

class _FailedImportItem {
  final _ImportRow row;
  final List<_ImportRow> allRows;
  final String reason;

  const _FailedImportItem({
    required this.row,
    required this.allRows,
    required this.reason,
  });
}
