import 'dart:math';
import 'package:luna_iot/models/history_model.dart';

class Trip {
  final int tripNumber;
  final DateTime startTime;
  final DateTime endTime;
  final double startLatitude;
  final double startLongitude;
  final double endLatitude;
  final double endLongitude;
  final double distance; // in kilometers
  final Duration duration;
  final double averageSpeed; // in km/h
  final double maxSpeed; // in km/h
  final List<History> tripPoints;

  Trip({
    required this.tripNumber,
    required this.startTime,
    required this.endTime,
    required this.startLatitude,
    required this.startLongitude,
    required this.endLatitude,
    required this.endLongitude,
    required this.distance,
    required this.duration,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.tripPoints,
  });

  // Calculate distance between two points using Haversine formula
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = (lat2 - lat1) * (pi / 180);
    final double dLon = (lon2 - lon1) * (pi / 180);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  // Calculate total distance for a list of points
  static double calculateTotalDistance(List<History> points) {
    if (points.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];

      if (current.latitude != null &&
          current.longitude != null &&
          next.latitude != null &&
          next.longitude != null) {
        totalDistance += calculateDistance(
          current.latitude!,
          current.longitude!,
          next.latitude!,
          next.longitude!,
        );
      }
    }

    return totalDistance;
  }

  // Calculate average speed
  static double calculateAverageSpeed(double distance, Duration duration) {
    if (duration.inSeconds == 0) return 0.0;
    return distance / (duration.inSeconds / 3600); // Convert to km/h
  }

  // Calculate max speed from trip points
  static double calculateMaxSpeed(List<History> points) {
    double maxSpeed = 0.0;
    for (final point in points) {
      if (point.speed != null && point.speed! > maxSpeed) {
        maxSpeed = point.speed!;
      }
    }
    return maxSpeed;
  }

  Map<String, dynamic> toJson() {
    return {
      'tripNumber': tripNumber,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'endLatitude': endLatitude,
      'endLongitude': endLongitude,
      'distance': distance,
      'duration': duration.inSeconds,
      'averageSpeed': averageSpeed,
      'maxSpeed': maxSpeed,
      'tripPoints': tripPoints.map((point) => point.toJson()).toList(),
    };
  }
}
