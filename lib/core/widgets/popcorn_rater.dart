import 'package:flutter/material.dart';

class PopcornRater extends StatefulWidget {
  // Starting value for the rater. Expected range: 0.0 to 10.0.
  final double initialRating;

  // Callback invoked when the rating changes. Parent widgets should
  // use this to persist or react to rating updates.
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
  // Holds the live rating while the user interacts with the slider.
  // We initialize this from the widget's `initialRating` in initState().
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    // Seed the internal state from the widget property.
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    // The whole widget is a compact column: icon (visual fill), label,
    // and slider control.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Visual representation: a bucket/popcorn icon that fills from
        // the bottom as the rating increases. We use a Stack of two
        // identical icons: a gray background and a colored foreground
        // that is clipped according to the rating.
        SizedBox(
          height: 100,
          width: 100,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Background icon - acts as the "empty" bucket silhouette.
              const Icon(Icons.local_activity, size: 80, color: Colors.grey),

              // Foreground icon - colored and masked to show fill level.
              // `Align.heightFactor` controls what fraction of the child
              // is visible; dividing by 10 maps the 0..10 rating to 0..1.
              ClipRect(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  heightFactor: _currentRating / 10, // maps to 0.0..1.0
                  child: const Icon(Icons.local_activity, size: 80, color: Colors.amber),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Numeric label that shows the rating with one decimal place.
        Text(
          "Popcorn Score: ${_currentRating.toStringAsFixed(1)} / 10",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),

        // A Slider to allow changing the rating. We use `divisions: 20`
        // to provide 0.5 increments (10 / 20 = 0.5). The `onChanged`
        // handler updates internal state and forwards the value to the
        // parent via the provided `onChanged` callback.
        Slider(
          value: _currentRating,
          min: 0,
          max: 10,
          divisions: 20, // Enables 0.5 steps
          activeColor: Colors.amber,
          label: _currentRating.toString(),
          onChanged: (value) {
            setState(() {
              // Update the live rating so the UI reflects the change.
              _currentRating = value;
            });
            // Notify parent of the new rating so it can persist/react.
            widget.onChanged(value);
          },
        ),
      ],
    );
  }
}