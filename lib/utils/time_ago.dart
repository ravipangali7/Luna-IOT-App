class TimeAgo {
  static String timeAgo(DateTime dateTime, {DateTime? dateTime2}) {
    // Determine which datetime to use: the most recent (latest)
    DateTime baseTime;
    if (dateTime2 != null) {
      baseTime = dateTime.isAfter(dateTime2) ? dateTime : dateTime2;
    } else {
      baseTime = dateTime;
    }

    final now = DateTime.now();
    final diff = now.difference(baseTime);

    final int hours = diff.inHours;
    final int minutes = diff.inMinutes % 60;
    final int seconds = diff.inSeconds % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours hrs, $minutes m, $seconds sec ago';
    } else if (hours == 0 && minutes > 0) {
      return '$minutes m, $seconds sec ago';
    } else {
      return '$seconds sec ago';
    }
  }

  /// Unified method to calculate last update time from vehicle data
  /// Returns the most recent time between status and location, or null if no data
  static DateTime? getMostRecentTime(
    DateTime? statusTime,
    DateTime? locationTime,
  ) {
    if (statusTime != null && locationTime != null) {
      // Both exist - compare and return the most recent
      return statusTime.isAfter(locationTime) ? statusTime : locationTime;
    } else if (statusTime != null) {
      // Only status exists
      return statusTime;
    } else if (locationTime != null) {
      // Only location exists
      return locationTime;
    } else {
      // Neither exists
      return null;
    }
  }

  /// Unified method to calculate last update time string
  /// Handles both vehicle data and socket data with same logic
  static String calculateLastUpdateTime({
    DateTime? statusTime,
    DateTime? locationTime,
    DateTime? socketTime,
  }) {
    DateTime? mostRecentTime;

    if (socketTime != null) {
      // Socket data takes priority - use it directly
      mostRecentTime = socketTime;
    } else {
      // Use vehicle data with unified logic
      mostRecentTime = getMostRecentTime(statusTime, locationTime);
    }

    if (mostRecentTime != null) {
      return timeAgo(mostRecentTime);
    } else {
      return 'No data available';
    }
  }
}
