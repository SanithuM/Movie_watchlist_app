// Reusable small loading spinner used across the app.
import 'package:flutter/material.dart';

class LoadingSpinner extends StatelessWidget {
  const LoadingSpinner({super.key, this.size = 24.0});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: size,
        width: size,
        child: const Center(child: CircularProgressIndicator()),
      );
}
