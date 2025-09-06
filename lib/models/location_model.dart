class Location {
  final String imei;
  final double? latitude;
  final double? longitude;
  final double? speed;
  final double? course;
  final bool? realTimeGps;
  final int? satellite;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Location({
    required this.imei,
    this.latitude,
    this.longitude,
    this.speed,
    this.course,
    this.realTimeGps,
    this.satellite,
    this.createdAt,
    this.updatedAt,
  });

  Location copyWith({
    String? imei,
    double? latitude,
    double? longitude,
    double? speed,
    double? course,
    bool? realTimeGps,
    int? satellite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Location(
      imei: imei ?? this.imei,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      course: course ?? this.course,
      realTimeGps: realTimeGps ?? this.realTimeGps,
      satellite: satellite ?? this.satellite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      imei: json['imei'] ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      speed: _parseDouble(json['speed']),
      course: _parseDouble(json['course']),
      realTimeGps: _parseBool(json['realTimeGps']),
      satellite: _parseInt(json['satellite']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.parse(value);
    }
    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'imei': imei,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'course': course,
      'realTimeGps': realTimeGps,
      'satellite': satellite,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
