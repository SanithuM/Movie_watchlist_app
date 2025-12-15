// Providers for search query and search results using Riverpod.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/movie_model.dart';
import 'movie_providers.dart'; 

// 1. Use Notifier instead of StateProvider
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() {
    return ''; // Initial empty string
  }

  void updateQuery(String newQuery) {
    state = newQuery;
  }
}

// Define the provider using NotifierProvider
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

// The Search Results Provider (remains a FutureProvider)
final searchResultsProvider = FutureProvider.autoDispose<List<Movie>>((ref) async {
  // Watch the new Notifier provider
  final query = ref.watch(searchQueryProvider);
  final repository = ref.read(movieRepositoryProvider);
  
  if (query.isEmpty) return [];

  // Debounce (wait 500ms) is good, but for simplicity we keep it direct here
  await Future.delayed(const Duration(milliseconds: 500));
  
  return repository.searchMovies(query);
});