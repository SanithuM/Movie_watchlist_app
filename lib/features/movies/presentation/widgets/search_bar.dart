// Small reusable search bar for movie queries.
import 'package:flutter/material.dart';

class MovieSearchBar extends StatelessWidget {
  final ValueChanged<String>? onSearch;
  const MovieSearchBar({super.key, this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search movies...'),
        onSubmitted: onSearch,
      ),
    );
  }
}
