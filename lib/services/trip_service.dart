import 'package:luna_iot/models/history_model.dart';
import 'package:luna_iot/models/trip_model.dart';

class TripService {
  static List<Trip> calculateTrips(List<History> historyData) {
    if (historyData.isEmpty) return [];

    // Separate location and status data
    final locationData = historyData
        .where((data) => data.type == 'location')
        .toList();

    final statusData = historyData
        .where((data) => data.type == 'status')
        .toList();

    if (locationData.isEmpty) return [];

    // If no status data (ignition events), create single trip
    if (statusData.isEmpty) {
      final singleTrip = _createSingleTrip(locationData, 1);
      return _isValidTrip(singleTrip) ? [singleTrip] : [];
    }

    // Create trips based on ignition off events
    List<Trip> trips = [];
    int tripNumber = 1;
    int lastTripEndIndex = 0;

    // Sort status data by time to find ignition off events
    statusData.sort(
      (a, b) => (a.createdAt ?? DateTime.now()).compareTo(
        b.createdAt ?? DateTime.now(),
      ),
    );

    for (final statusEvent in statusData) {
      if (statusEvent.ignition == false) {
        // Find the index of the last location point before or at this ignition off event
        final ignitionOffTime = statusEvent.createdAt;
        if (ignitionOffTime != null) {
          int tripEndIndex = locationData.lastIndexWhere(
            (loc) =>
                loc.createdAt != null &&
                !loc.createdAt!.isAfter(ignitionOffTime),
          );

          // Only create a trip if there are at least 2 points between lastTripEndIndex and tripEndIndex
          if (tripEndIndex > lastTripEndIndex) {
            final tripPoints = locationData.sublist(
              lastTripEndIndex,
              tripEndIndex + 1,
            );
            final trip = _createTripFromPoints(tripPoints, tripNumber);
            if (_isValidTrip(trip)) {
              trips.add(trip);
              tripNumber++;
            }
            lastTripEndIndex = tripEndIndex; // Next trip starts from here
          }
        }
      }
    }

    // Create final trip from last end to the end of locationData
    if (lastTripEndIndex < locationData.length - 1) {
      final tripPoints = locationData.sublist(
        lastTripEndIndex,
        locationData.length,
      );
      final trip = _createTripFromPoints(tripPoints, tripNumber);
      if (_isValidTrip(trip)) {
        trips.add(trip);
      }
    }

    return trips;
  }

  static bool _isValidTrip(Trip trip) {
    // Ignore trips with 0 meter distance or 0 second duration
    return trip.distance > 0 && trip.duration.inSeconds > 0;
  }

  static Trip _createSingleTrip(List<History> points, int tripNumber) {
    if (points.isEmpty) {
      throw Exception('Cannot create trip from empty points');
    }

    final startPoint = points.first;
    final endPoint = points.last;

    final startTime = startPoint.createdAt ?? DateTime.now();
    final endTime = endPoint.createdAt ?? DateTime.now();
    final duration = endTime.difference(startTime);

    final distance = Trip.calculateTotalDistance(points);
    final averageSpeed = Trip.calculateAverageSpeed(distance, duration);
    final maxSpeed = Trip.calculateMaxSpeed(points);

    return Trip(
      tripNumber: tripNumber,
      startTime: startTime,
      endTime: endTime,
      startLatitude: startPoint.latitude ?? 0.0,
      startLongitude: startPoint.longitude ?? 0.0,
      endLatitude: endPoint.latitude ?? 0.0,
      endLongitude: endPoint.longitude ?? 0.0,
      distance: distance,
      duration: duration,
      averageSpeed: averageSpeed,
      maxSpeed: maxSpeed,
      tripPoints: points,
    );
  }

  static Trip _createTripFromPoints(List<History> points, int tripNumber) {
    if (points.isEmpty) {
      throw Exception('Cannot create trip from empty points');
    }

    final startPoint = points.first;
    final endPoint = points.last;

    final startTime = startPoint.createdAt ?? DateTime.now();
    final endTime = endPoint.createdAt ?? DateTime.now();
    final duration = endTime.difference(startTime);

    final distance = Trip.calculateTotalDistance(points);
    final averageSpeed = Trip.calculateAverageSpeed(distance, duration);
    final maxSpeed = Trip.calculateMaxSpeed(points);

    return Trip(
      tripNumber: tripNumber,
      startTime: startTime,
      endTime: endTime,
      startLatitude: startPoint.latitude ?? 0.0,
      startLongitude: startPoint.longitude ?? 0.0,
      endLatitude: endPoint.latitude ?? 0.0,
      endLongitude: endPoint.longitude ?? 0.0,
      distance: distance,
      duration: duration,
      averageSpeed: averageSpeed,
      maxSpeed: maxSpeed,
      tripPoints: points,
    );
  }

  /// Format duration to readable string
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Format distance to readable string
  static String formatDistance(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)}m';
    } else {
      return '${distance.toStringAsFixed(2)}km';
    }
  }

  /// Format speed to readable string
  static String formatSpeed(double speed) {
    return '${speed.toStringAsFixed(1)} km/h';
  }
}
