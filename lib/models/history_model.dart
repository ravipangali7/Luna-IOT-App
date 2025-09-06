class History {
  final String imei;
  final String type; // 'location' or 'status'
  final String dataType; // 'location' or 'status'
  final DateTime? createdAt;

  // Location fields
  final double? latitude;
  final double? longitude;
  final double? speed;
  final double? course;
  final bool? realTimeGps;
  final int? satellite;

  // Status fields (simplified - only 3 fields)
  final bool? ignition;

  History({
    required this.imei,
    required this.type,
    required this.dataType,
    this.createdAt,
    this.latitude,
    this.longitude,
    this.speed,
    this.course,
    this.realTimeGps,
    this.satellite,
    this.ignition,
  });

  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      imei: json['imei'] ?? '',
      type: json['type'] ?? '',
      dataType: json['dataType'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      speed: _parseDouble(json['speed']),
      course: _parseDouble(json['course']),
      realTimeGps: _parseBool(json['realTimeGps']),
      satellite: _parseInt(json['satellite']),
      ignition: _parseBool(json['ignition']),
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
      try {
        return int.parse(value);
      } catch (e) {
        return null;
      }
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
      'type': type,
      'dataType': dataType,
      'createdAt': createdAt?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'course': course,
      'realTimeGps': realTimeGps,
      'satellite': satellite,
      'ignition': ignition,
    };
  }
}
