import 'dart:convert';
import 'alert_type_model.dart';

class AlertGeofence {
  final int id;
  final String title;
  final String boundary; // JSON string of coordinates
  final List<AlertType> alertTypes;
  final int institute;
  final double? instituteLatitude;
  final double? instituteLongitude;
  final String instituteName;

  AlertGeofence({
    required this.id,
    required this.title,
    required this.boundary,
    required this.alertTypes,
    required this.institute,
    this.instituteLatitude,
    this.instituteLongitude,
    required this.instituteName,
  });

  factory AlertGeofence.fromJson(Map<String, dynamic> json) {
    return AlertGeofence(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      boundary: json['boundary'] ?? '',
      alertTypes:
          (json['alert_types'] as List<dynamic>?)
              ?.map((type) => AlertType.fromJson(type))
              .toList() ??
          [],
      institute: json['institute'] ?? 0,
      instituteLatitude: json['institute_latitude']?.toDouble(),
      instituteLongitude: json['institute_longitude']?.toDouble(),
      instituteName: json['institute_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'boundary': boundary,
      'alert_types': alertTypes.map((type) => type.toJson()).toList(),
      'institute': institute,
      'institute_latitude': instituteLatitude,
      'institute_longitude': instituteLongitude,
      'institute_name': instituteName,
    };
  }

  // Parse boundary JSON string to list of LatLng points
  List<LatLng> getBoundaryPoints() {
    try {
      // Assuming boundary is stored as JSON string like: "[[lat1,lng1],[lat2,lng2],...]"
      final List<dynamic> coordinates = json.decode(boundary);
      return coordinates.map((coord) {
        if (coord is List && coord.length >= 2) {
          return LatLng(coord[0].toDouble(), coord[1].toDouble());
        }
        throw FormatException('Invalid coordinate format');
      }).toList();
    } catch (e) {
      print('Error parsing boundary: $e');
      return [];
    }
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}
