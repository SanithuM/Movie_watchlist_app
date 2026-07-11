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

  /// Calculates the average runtime from TMDB's episode_run_time list.
  static int getAverageRuntime(List<dynamic>? runTimeList) {
    if (runTimeList == null || runTimeList.isEmpty) {
      return 45; // default fallback
    }
    final total = runTimeList.map((e) => (e as num).toInt()).reduce((a, b) => a + b);
    return (total / runTimeList.length).round();
  }

  /// Formats total minutes into months, days, and hours.
  static Map<String, int> formatTime(int totalMinutes) {
    final int months = totalMinutes ~/ (60 * 24 * 30);
    final int remainingAfterMonths = totalMinutes % (60 * 24 * 30);
    final int days = remainingAfterMonths ~/ (60 * 24);
    final int remainingAfterDays = remainingAfterMonths % (60 * 24);
    final int hours = remainingAfterDays ~/ 60;
    return {'months': months, 'days': days, 'hours': hours};
  }
}