import 'package:luna_iot/models/device_model.dart';
import 'package:luna_iot/models/location_model.dart';
import 'package:luna_iot/models/status_model.dart';

class Vehicle {
  String imei;
  String? name;
  String? vehicleNo;
  String? vehicleType;
  double? odometer;
  double? mileage;
  int? speedLimit;
  double? minimumFuel;
  bool? isActive;
  DateTime? createdAt;
  DateTime? updatedAt;
  Device? device;
  Status? latestStatus;
  Location? latestLocation;
  double? todayKm;

  // Ownership information
  String? ownershipType; // 'Own', 'Customer', 'Shared'
  Map<String, dynamic>? userVehicle; // User-vehicle relationship data

  Vehicle({
    required this.imei,
    this.name,
    this.vehicleNo,
    this.vehicleType,
    this.odometer,
    this.mileage,
    this.speedLimit,
    this.minimumFuel,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.device,
    this.latestStatus,
    this.latestLocation,
    this.todayKm,
    this.ownershipType,
    this.userVehicle,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      imei: json['imei'] ?? '',
      name: json['name'] ?? '',
      vehicleNo: json['vehicleNo'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      odometer: _parseDouble(json['odometer']),
      mileage: _parseDouble(json['mileage']),
      speedLimit: _parseInt(json['speedLimit']),
      minimumFuel: _parseDouble(json['minimumFuel']),
      isActive: json['is_active'] ?? true,
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
      'imei': imei,
      'name': name,
      'vehicleNo': vehicleNo,
      'vehicleType': vehicleType,
      'odometer': odometer,
      'mileage': mileage,
      'speedLimit': speedLimit,
      'minimumFuel': minimumFuel,
      'is_active': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'device': device?.toJson(),
      'latestStatus': latestStatus?.toJson(),
      'latestLocation': latestLocation?.toJson(),
      'todayKm': todayKm,
      'ownershipType': ownershipType,
      'userVehicle': userVehicle,
    };
  }

  Vehicle copyWith({
    String? imei,
    String? name,
    String? vehicleNo,
    String? vehicleType,
    double? odometer,
    double? mileage,
    int? speedLimit,
    double? minimumFuel,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Device? device,
    Status? latestStatus,
    Location? latestLocation,
    double? todayKm,
    String? ownershipType,
    Map<String, dynamic>? userVehicle,
  }) {
    return Vehicle(
      imei: imei ?? this.imei,
      name: name ?? this.name,
      vehicleNo: vehicleNo ?? this.vehicleNo,
      vehicleType: vehicleType ?? this.vehicleType,
      odometer: odometer ?? this.odometer,
      mileage: mileage ?? this.mileage,
      speedLimit: speedLimit ?? this.speedLimit,
      minimumFuel: minimumFuel ?? this.minimumFuel,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      device: device ?? this.device,
      latestStatus: latestStatus ?? this.latestStatus,
      latestLocation: latestLocation ?? this.latestLocation,
      todayKm: todayKm ?? this.todayKm,
      ownershipType: ownershipType ?? this.ownershipType,
      userVehicle: userVehicle ?? this.userVehicle,
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
}
