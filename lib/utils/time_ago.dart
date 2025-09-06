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
}
