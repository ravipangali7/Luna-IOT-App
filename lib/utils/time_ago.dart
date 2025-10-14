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

    final int years = diff.inDays ~/ 365;
    final int months = (diff.inDays % 365) ~/ 30;
    final int days = diff.inDays % 30;
    final int hours = diff.inHours % 24;
    final int minutes = diff.inMinutes % 60;
    final int seconds = diff.inSeconds % 60;

    // Show only 2 most significant units
    if (years > 0) {
      return months > 0 ? '$years yrs, $months mons ago' : '$years yrs ago';
    } else if (months > 0) {
      return days > 0 ? '$months mons, $days days ago' : '$months mons ago';
    } else if (days > 0) {
      return hours > 0 ? '$days days, $hours hrs ago' : '$days days ago';
    } else if (hours > 0) {
      return minutes > 0 ? '$hours hrs, $minutes m ago' : '$hours hrs ago';
    } else if (minutes > 0) {
      return seconds > 0 ? '$minutes m, $seconds sec ago' : '$minutes m ago';
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
