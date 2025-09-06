class ReportStats {
  final double totalKm;
  final int totalTime; // in minutes
  final double averageSpeed;
  final double maxSpeed;
  final int totalIdleTime; // in minutes
  final int totalRunningTime; // in minutes
  final int totalOverspeedTime; // in minutes
  final int totalStopTime; // in minutes

  ReportStats({
    required this.totalKm,
    required this.totalTime,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.totalIdleTime,
    required this.totalRunningTime,
    required this.totalOverspeedTime,
    required this.totalStopTime,
  });

  factory ReportStats.fromJson(Map<String, dynamic> json) {
    return ReportStats(
      totalKm: (json['totalKm'] ?? 0).toDouble(),
      totalTime: json['totalTime'] ?? 0,
      averageSpeed: (json['averageSpeed'] ?? 0).toDouble(),
      maxSpeed: (json['maxSpeed'] ?? 0).toDouble(),
      totalIdleTime: json['totalIdleTime'] ?? 0,
      totalRunningTime: json['totalRunningTime'] ?? 0,
      totalOverspeedTime: json['totalOverspeedTime'] ?? 0,
      totalStopTime: json['totalStopTime'] ?? 0,
    );
  }
}

class DailyData {
  final String date;
  final double averageSpeed;
  final double maxSpeed;
  final double totalKm;
  final int locationCount;

  DailyData({
    required this.date,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.totalKm,
    required this.locationCount,
  });

  factory DailyData.fromJson(Map<String, dynamic> json) {
    return DailyData(
      date: json['date'] ?? '',
      averageSpeed: (json['averageSpeed'] ?? 0).toDouble(),
      maxSpeed: (json['maxSpeed'] ?? 0).toDouble(),
      totalKm: (json['totalKm'] ?? 0).toDouble(),
      locationCount: json['locationCount'] ?? 0,
    );
  }
}

class ReportData {
  final ReportStats stats;
  final List<DailyData> dailyData;

  ReportData({required this.stats, required this.dailyData});

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      stats: ReportStats.fromJson(json['stats'] ?? {}),
      dailyData:
          (json['dailyData'] as List?)
              ?.map((item) => DailyData.fromJson(item))
              .toList() ??
          [],
    );
  }
}
