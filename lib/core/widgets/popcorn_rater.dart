// Interactive popcorn-themed rating widget (0–10).
import 'package:flutter/material.dart';

class PopcornRater extends StatefulWidget {
  final double initialRating; // 0.0 to 10.0
  final ValueChanged<double> onChanged;

  const PopcornRater({
    super.key,
    this.initialRating = 5.0,
    required this.onChanged,
  });

  @override
  State<PopcornRater> createState() => _PopcornRaterState();
}

class _PopcornRaterState extends State<PopcornRater> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The Visual Representation (The Bucket)
        SizedBox(
          height: 100,
          width: 100,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Background Bucket (Gray)
              const Icon(Icons.local_activity, size: 80, color: Colors.grey),
              
              // Foreground Bucket (Fills up based on rating)
              ClipRect(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  heightFactor: _currentRating / 10, // 0.0 to 1.0
                  child: const Icon(Icons.local_activity, size: 80, color: Colors.amber),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 10),
        Text(
          "Popcorn Score: ${_currentRating.toStringAsFixed(1)} / 10",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),

        // The Slider Control
        Slider(
          value: _currentRating,
          min: 0,
          max: 10,
          divisions: 20, // Allows 0.5 increments
          activeColor: Colors.amber,
          label: _currentRating.toString(),
          onChanged: (value) {
            setState(() {
              _currentRating = value;
            });
            widget.onChanged(value); // Send value back to parent
          },
        ),
      ],
    );
  }
}