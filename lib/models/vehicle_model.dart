import 'package:flutter/foundation.dart';
import 'package:luna_iot/models/device_model.dart';
import 'package:luna_iot/models/location_model.dart';
import 'package:luna_iot/models/status_model.dart';

class Vehicle {
  int? id;
  String imei;
  String? name;
  String? vehicleNo;
  String? vehicleType;
  double? odometer;
  double? mileage;
  int? speedLimit;
  double? minimumFuel;
  String? expireDate;
  bool? isActive;
  bool? isRelay;
  DateTime? createdAt;
  DateTime? updatedAt;
  Device? device;
  Status? latestStatus;
  Location? latestLocation;
  double? todayKm;

  // Ownership information
  String? ownershipType; // 'Own', 'Customer', 'Shared'
  Map<String, dynamic>? userVehicle; // User-vehicle relationship data
  List<Map<String, dynamic>>?
  userVehicles; // Multiple user-vehicle relationships

  Vehicle({
    this.id,
    required this.imei,
    this.name,
    this.vehicleNo,
    this.vehicleType,
    this.odometer,
    this.mileage,
    this.speedLimit,
    this.minimumFuel,
    this.expireDate,
    this.isActive,
    this.isRelay,
    this.createdAt,
    this.updatedAt,
    this.device,
    this.latestStatus,
    this.latestLocation,
    this.todayKm,
    this.ownershipType,
    this.userVehicle,
    this.userVehicles,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    // DEBUG: Log is_relay parsing
    final rawIsRelay = json['is_relay'];
    final hasIsRelayField = json.containsKey('is_relay');
    final parsedIsRelay = hasIsRelayField ? _parseBool(json['is_relay']) : null;
    debugPrint('=== VEHICLE PARSING DEBUG (IMEI: ${json['imei']}) ===');
    debugPrint('is_relay field exists: $hasIsRelayField');
    debugPrint('Raw is_relay value: $rawIsRelay (type: ${rawIsRelay.runtimeType})');
    debugPrint('Parsed isRelay value: $parsedIsRelay (type: ${parsedIsRelay.runtimeType})');
    
    // DEBUG: Log expireDate parsing
    final rawExpireDate = json['expireDate'];
    final hasExpireDateField = json.containsKey('expireDate');
    debugPrint('expireDate field exists: $hasExpireDateField');
    debugPrint('Raw expireDate value: $rawExpireDate (type: ${rawExpireDate?.runtimeType})');
    debugPrint('=== END VEHICLE PARSING DEBUG ===');
    
    return Vehicle(
      id: json['id'],
      imei: json['imei'] ?? '',
      name: json['name'],
      vehicleNo: json['vehicleNo'],
      vehicleType: json['vehicleType'],
      odometer: _parseDouble(json['odometer']),
      mileage: _parseDouble(json['mileage']),
      speedLimit: _parseInt(json['speedLimit']),
      minimumFuel: _parseDouble(json['minimumFuel']),
      expireDate: json['expireDate'],
      isActive: json['is_active'] != null ? (_parseBool(json['is_active']) ?? true) : true,
      // Parse is_relay - handle missing field, null, boolean, integer (1/0), and string cases
      // If field is missing, set to null. If present, parse it (can be null, true, or false)
      isRelay: parsedIsRelay,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      device: json['device'] != null ? Device.fromJson(json['device']) : null,
      latestStatus: json['latestStatus'] != null
          ? Status.fromJson(json['latestStatus'])
          : null,
      latestLocation: json['latestLocation'] != null
          ? Location.fromJson(json['latestLocation'])
          : null,
      todayKm: _parseDouble(json['todayKm']),
      ownershipType: _determineOwnershipType(json),
      userVehicle: _getUserVehicleData(json),
      userVehicles: json['userVehicles'] != null
          ? List<Map<String, dynamic>>.from(json['userVehicles'])
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
      final lower = value.toLowerCase().trim();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
      return null;
    }
    return null;
  }

  // Determine ownership type from userVehicles data
  static String? _determineOwnershipType(Map<String, dynamic> json) {
    // First check if ownershipType is directly provided
    if (json['ownershipType'] != null) {
      return json['ownershipType'];
    }

    // Check userVehicles array to determine ownership
    final userVehicles = json['userVehicles'];
    if (userVehicles is List && userVehicles.isNotEmpty) {
      final userVehicle = userVehicles.first as Map<String, dynamic>;
      final isMain = userVehicle['isMain'] == true;

      if (isMain) {
        return 'Own';
      } else {
        return 'Shared';
      }
    }

    // Check single userVehicle object
    final userVehicle = json['userVehicle'];
    if (userVehicle is Map<String, dynamic>) {
      final isMain = userVehicle['isMain'] == true;

      if (isMain) {
        return 'Own';
      } else {
        return 'Shared';
      }
    }

    return null;
  }

  // Get user vehicle data from either userVehicle or userVehicles
  static Map<String, dynamic>? _getUserVehicleData(Map<String, dynamic> json) {
    // First check single userVehicle object
    if (json['userVehicle'] != null) {
      return Map<String, dynamic>.from(json['userVehicle']);
    }

    // Check userVehicles array and get the first one (main user)
    final userVehicles = json['userVehicles'];
    if (userVehicles is List && userVehicles.isNotEmpty) {
      return Map<String, dynamic>.from(
        userVehicles.first as Map<String, dynamic>,
      );
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imei': imei,
      'name': name,
      'vehicleNo': vehicleNo,
      'vehicleType': vehicleType,
      'odometer': odometer,
      'mileage': mileage,
      'speedLimit': speedLimit,
      'minimumFuel': minimumFuel,
      'expireDate': expireDate,
      'is_active': isActive,
      'is_relay': isRelay,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'device': device?.toJson(),
      'latestStatus': latestStatus?.toJson(),
      'latestLocation': latestLocation?.toJson(),
      'todayKm': todayKm,
      'ownershipType': ownershipType,
      'userVehicle': userVehicle,
      'userVehicles': userVehicles,
    };
  }

  Vehicle copyWith({
    int? id,
    String? imei,
    String? name,
    String? vehicleNo,
    String? vehicleType,
    double? odometer,
    double? mileage,
    int? speedLimit,
    double? minimumFuel,
    String? expireDate,
    bool? isActive,
    bool? isRelay,
    DateTime? createdAt,
    DateTime? updatedAt,
    Device? device,
    Status? latestStatus,
    Location? latestLocation,
    double? todayKm,
    String? ownershipType,
    Map<String, dynamic>? userVehicle,
    List<Map<String, dynamic>>? userVehicles,
  }) {
    return Vehicle(
      id: id ?? this.id,
      imei: imei ?? this.imei,
      name: name ?? this.name,
      vehicleNo: vehicleNo ?? this.vehicleNo,
      vehicleType: vehicleType ?? this.vehicleType,
      odometer: odometer ?? this.odometer,
      mileage: mileage ?? this.mileage,
      speedLimit: speedLimit ?? this.speedLimit,
      minimumFuel: minimumFuel ?? this.minimumFuel,
      expireDate: expireDate ?? this.expireDate,
      isActive: isActive ?? this.isActive,
      isRelay: isRelay ?? this.isRelay,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      device: device ?? this.device,
      latestStatus: latestStatus ?? this.latestStatus,
      latestLocation: latestLocation ?? this.latestLocation,
      todayKm: todayKm ?? this.todayKm,
      ownershipType: ownershipType ?? this.ownershipType,
      userVehicle: userVehicle ?? this.userVehicle,
      userVehicles: userVehicles ?? this.userVehicles,
    );
  }

  bool get hasValidLocation {
    return latestLocation?.latitude != null &&
        latestLocation?.longitude != null &&
        latestLocation!.latitude != 0.0 &&
        latestLocation!.longitude != 0.0;
  }

  // Check if vehicle is active
  bool get isVehicleActive => isActive ?? true;

  // Permission checking methods
  bool get isMainUser => userVehicle?['isMain'] == true;
  bool get hasAllAccess => userVehicle?['allAccess'] == true;
  bool get canLiveTracking =>
      hasAllAccess || userVehicle?['liveTracking'] == true;
  bool get canViewHistory => hasAllAccess || userVehicle?['history'] == true;
  bool get canViewReport => hasAllAccess || userVehicle?['report'] == true;
  bool get canEditVehicle => hasAllAccess || userVehicle?['edit'] == true;
  bool get canManageGeofence =>
      hasAllAccess || userVehicle?['geofence'] == true;
  bool get canShareTracking =>
      hasAllAccess || userVehicle?['shareTracking'] == true;
  bool get canReceiveNotifications => userVehicle?['notification'] == true;

  // Check if user has specific permission
  bool hasPermission(String permission) {
    if (hasAllAccess) return true;
    return userVehicle?[permission] == true;
  }

  // Helper method to parse ISO date string (handles with/without timezone)
  static DateTime? _parseISODate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return null;
    }

    try {
      // Try parsing as-is first (handles most ISO formats)
      DateTime parsedDate = DateTime.parse(dateString);
      
      // If the date is in UTC or has timezone, convert to local
      // Otherwise, use as-is
      return parsedDate;
    } catch (e) {
      // If standard parsing fails, try to handle edge cases
      try {
        // Remove timezone info if present and try again
        String cleanedDate = dateString.split('+').first.split('Z').first.trim();
        // Ensure we have at least date part
        if (cleanedDate.length >= 10) {
          return DateTime.parse(cleanedDate);
        }
      } catch (e2) {
        // If all parsing fails, return null
        return null;
      }
    }
    return null;
  }

  // Get expiration status
  // Returns: 'expired', 'week', 'month', or null
  String? getExpirationStatus() {
    debugPrint('=== EXPIRATION STATUS DEBUG (Vehicle: ${name ?? imei}) ===');
    debugPrint('expireDate value: $expireDate');
    debugPrint('expireDate type: ${expireDate.runtimeType}');
    debugPrint('expireDate is null: ${expireDate == null}');
    debugPrint('expireDate is empty: ${expireDate?.isEmpty ?? true}');
    
    if (expireDate == null || expireDate!.isEmpty) {
      debugPrint('expireDate is null or empty, returning null');
      debugPrint('=== END EXPIRATION STATUS DEBUG ===');
      return null;
    }

    try {
      // Parse expireDate string to DateTime using improved parser
      final expireDateTime = _parseISODate(expireDate);
      debugPrint('Parsed expireDateTime: $expireDateTime');
      
      if (expireDateTime == null) {
        debugPrint('Failed to parse expireDate, returning null');
        debugPrint('=== END EXPIRATION STATUS DEBUG ===');
        return null;
      }

      // Compare dates at day level (ignore time)
      final expireDateOnly = DateTime(expireDateTime.year, expireDateTime.month, expireDateTime.day);
      final now = DateTime.now();
      final nowDateOnly = DateTime(now.year, now.month, now.day);
      final difference = expireDateOnly.difference(nowDateOnly);
      final daysUntilExpiration = difference.inDays;

      debugPrint('expireDateOnly: $expireDateOnly');
      debugPrint('nowDateOnly: $nowDateOnly');
      debugPrint('daysUntilExpiration: $daysUntilExpiration');

      // If expiration date is today or in the past, it's expired
      String? status;
      if (daysUntilExpiration <= 0) {
        status = 'expired';
      } else if (daysUntilExpiration <= 7) {
        status = 'week';
      } else if (daysUntilExpiration <= 30) {
        status = 'month';
      } else {
        status = null;
      }
      
      debugPrint('Expiration status result: $status');
      debugPrint('=== END EXPIRATION STATUS DEBUG ===');
      return status;
    } catch (e) {
      // If parsing fails, return null
      debugPrint('Error parsing expiration date: $e');
      debugPrint('=== END EXPIRATION STATUS DEBUG ===');
      return null;
    }
  }

  // Check if vehicle is expired
  // More robust check that compares dates at day level
  bool get isExpired {
    debugPrint('=== IS EXPIRED CHECK (Vehicle: ${name ?? imei}) ===');
    debugPrint('expireDate value: $expireDate');
    
    if (expireDate == null || expireDate!.isEmpty) {
      debugPrint('expireDate is null or empty, returning false');
      debugPrint('=== END IS EXPIRED CHECK ===');
      return false;
    }

    try {
      // Parse expireDate string to DateTime using improved parser
      final expireDateTime = _parseISODate(expireDate);
      debugPrint('Parsed expireDateTime: $expireDateTime');
      
      if (expireDateTime == null) {
        debugPrint('Failed to parse expireDate, returning false');
        debugPrint('=== END IS EXPIRED CHECK ===');
        return false;
      }

      // Compare dates at day level (ignore time)
      final expireDateOnly = DateTime(expireDateTime.year, expireDateTime.month, expireDateTime.day);
      final now = DateTime.now();
      final nowDateOnly = DateTime(now.year, now.month, now.day);
      
      debugPrint('expireDateOnly: $expireDateOnly');
      debugPrint('nowDateOnly: $nowDateOnly');
      
      // Vehicle is expired if expiration date is today or before today
      final isExpiredResult = expireDateOnly.isBefore(nowDateOnly) || expireDateOnly.isAtSameMomentAs(nowDateOnly);
      debugPrint('isExpired result: $isExpiredResult');
      debugPrint('=== END IS EXPIRED CHECK ===');
      return isExpiredResult;
    } catch (e) {
      // If parsing fails, return false
      debugPrint('Error checking expiration: $e');
      debugPrint('=== END IS EXPIRED CHECK ===');
      return false;
    }
  }
}
