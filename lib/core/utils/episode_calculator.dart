// lib/core/utils/episode_calculator.dart

class EpisodeCalculator {
  /// Calculates the next season and episode based on total progress.
  /// [progress] is the total number of episodes watched.
  /// [seasonEpisodeCounts] is an ordered list of episode counts per season.
  /// Returns a map with 'season' and 'episode', or -1 if completed.
  static Map<String, int> getNextEpisode(int progress, List<int> seasonEpisodeCounts) {
    int remainingProgress = progress;
    int currentSeasonIndex = 0;

    // Loop through seasons as long as there are seasons left
    while (currentSeasonIndex < seasonEpisodeCounts.length) {
      int epsInCurrentSeason = seasonEpisodeCounts[currentSeasonIndex];

      if (remainingProgress >= epsInCurrentSeason) {
        // The user has watched this entire season. 
        // Subtract its episodes and move to the next season.
        remainingProgress -= epsInCurrentSeason;
        currentSeasonIndex++;
      } else {
        // The user is currently in the middle of this season.
        return {
          'season': currentSeasonIndex + 1, // +1 because index 0 is Season 1
          'episode': remainingProgress + 1, // +1 because remaining = watched in this season
        };
      }
    }

    // If the loop finishes, the user has completed all available episodes.
    return {
      'season': -1,
      'episode': -1,
    };
  }
}