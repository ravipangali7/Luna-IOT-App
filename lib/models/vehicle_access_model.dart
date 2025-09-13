class VehicleAccessPermissions {
  final bool allAccess;
  final bool liveTracking;
  final bool history;
  final bool report;
  final bool vehicleProfile;
  final bool events;
  final bool geofencing;
  final bool troubleshoot;
  final bool vehicleEdit;
  final bool shareTracking;

  VehicleAccessPermissions({
    required this.allAccess,
    required this.liveTracking,
    required this.history,
    required this.report,
    required this.vehicleProfile,
    required this.events,
    required this.geofencing,
    required this.troubleshoot,
    required this.vehicleEdit,
    required this.shareTracking,
  });

  factory VehicleAccessPermissions.fromJson(Map<String, dynamic> json) {
    return VehicleAccessPermissions(
      allAccess: json['allAccess'] ?? false,
      liveTracking: json['liveTracking'] ?? false,
      history: json['history'] ?? false,
      report: json['report'] ?? false,
      vehicleProfile: json['vehicleProfile'] ?? false,
      events: json['events'] ?? false,
      geofencing: json['geofencing'] ?? false,
      troubleshoot: json['troubleshoot'] ?? false,
      vehicleEdit: json['vehicleEdit'] ?? false,
      shareTracking: json['shareTracking'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allAccess': allAccess,
      'liveTracking': liveTracking,
      'history': history,
      'report': report,
      'vehicleProfile': vehicleProfile,
      'events': events,
      'geofencing': geofencing,
      'troubleshoot': troubleshoot,
      'vehicleEdit': vehicleEdit,
      'shareTracking': shareTracking,
    };
  }

  VehicleAccessPermissions copyWith({
    bool? allAccess,
    bool? liveTracking,
    bool? history,
    bool? report,
    bool? vehicleProfile,
    bool? events,
    bool? geofencing,
    bool? troubleshoot,
    bool? vehicleEdit,
    bool? shareTracking,
  }) {
    return VehicleAccessPermissions(
      allAccess: allAccess ?? this.allAccess,
      liveTracking: liveTracking ?? this.liveTracking,
      history: history ?? this.history,
      report: report ?? this.report,
      vehicleProfile: vehicleProfile ?? this.vehicleProfile,
      events: events ?? this.events,
      geofencing: geofencing ?? this.geofencing,
      troubleshoot: troubleshoot ?? this.troubleshoot,
      vehicleEdit: vehicleEdit ?? this.vehicleEdit,
      shareTracking: shareTracking ?? this.shareTracking,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VehicleAccessPermissions &&
        other.allAccess == allAccess &&
        other.liveTracking == liveTracking &&
        other.history == history &&
        other.report == report &&
        other.vehicleProfile == vehicleProfile &&
        other.events == events &&
        other.geofencing == geofencing &&
        other.troubleshoot == troubleshoot &&
        other.vehicleEdit == vehicleEdit &&
        other.shareTracking == shareTracking;
  }

  @override
  int get hashCode {
    return allAccess.hashCode ^
        liveTracking.hashCode ^
        history.hashCode ^
        report.hashCode ^
        vehicleProfile.hashCode ^
        events.hashCode ^
        geofencing.hashCode ^
        troubleshoot.hashCode ^
        vehicleEdit.hashCode ^
        shareTracking.hashCode;
  }
}

class VehicleAccessUser {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String status;
  final VehicleAccessRole role;

  VehicleAccessUser({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.status,
    required this.role,
  });

  factory VehicleAccessUser.fromJson(Map<String, dynamic> json) {
    return VehicleAccessUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      status: json['status'] ?? '',
      role: VehicleAccessRole.fromJson(json['role'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'status': status,
      'role': role.toJson(),
    };
  }
}

class VehicleAccessRole {
  final int id;
  final String name;
  final String description;

  VehicleAccessRole({
    required this.id,
    required this.name,
    required this.description,
  });

  factory VehicleAccessRole.fromJson(Map<String, dynamic> json) {
    return VehicleAccessRole(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}

class VehicleAccessVehicle {
  final int id;
  final String imei;
  final String name;
  final String vehicleNo;
  final String vehicleType;

  VehicleAccessVehicle({
    required this.id,
    required this.imei,
    required this.name,
    required this.vehicleNo,
    required this.vehicleType,
  });

  factory VehicleAccessVehicle.fromJson(Map<String, dynamic> json) {
    return VehicleAccessVehicle(
      id: json['id'] ?? 0,
      imei: json['imei'] ?? '',
      name: json['name'] ?? '',
      vehicleNo: json['vehicleNo'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imei': imei,
      'name': name,
      'vehicleNo': vehicleNo,
      'vehicleType': vehicleType,
    };
  }
}

class VehicleAccess {
  final int id;
  final int userId;
  final int vehicleId;
  final String imei;
  final VehicleAccessPermissions permissions;
  final String createdAt;
  final String updatedAt;
  final VehicleAccessUser? user;
  final VehicleAccessVehicle? vehicle;

  VehicleAccess({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.imei,
    required this.permissions,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.vehicle,
  });

  factory VehicleAccess.fromJson(Map<String, dynamic> json) {
    return VehicleAccess(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      vehicleId: json['vehicleId'] ?? 0,
      imei: json['imei'] ?? '',
      permissions: VehicleAccessPermissions.fromJson(json['permissions'] ?? {}),
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      user: json['user'] != null ? VehicleAccessUser.fromJson(json['user']) : null,
      vehicle: json['vehicle'] != null ? VehicleAccessVehicle.fromJson(json['vehicle']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'vehicleId': vehicleId,
      'imei': imei,
      'permissions': permissions.toJson(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'user': user?.toJson(),
      'vehicle': vehicle?.toJson(),
    };
  }

  VehicleAccess copyWith({
    int? id,
    int? userId,
    int? vehicleId,
    String? imei,
    VehicleAccessPermissions? permissions,
    String? createdAt,
    String? updatedAt,
    VehicleAccessUser? user,
    VehicleAccessVehicle? vehicle,
  }) {
    return VehicleAccess(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      imei: imei ?? this.imei,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
      vehicle: vehicle ?? this.vehicle,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VehicleAccess &&
        other.id == id &&
        other.userId == userId &&
        other.vehicleId == vehicleId &&
        other.imei == imei &&
        other.permissions == permissions &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.user == user &&
        other.vehicle == vehicle;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        vehicleId.hashCode ^
        imei.hashCode ^
        permissions.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        user.hashCode ^
        vehicle.hashCode;
  }
}

class VehicleAccessFormData {
  final int userId;
  final int vehicleId;
  final String imei;
  final VehicleAccessPermissions permissions;

  VehicleAccessFormData({
    required this.userId,
    required this.vehicleId,
    required this.imei,
    required this.permissions,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'vehicleId': vehicleId,
      'imei': imei,
      'permissions': permissions.toJson(),
    };
  }

  VehicleAccessFormData copyWith({
    int? userId,
    int? vehicleId,
    String? imei,
    VehicleAccessPermissions? permissions,
  }) {
    return VehicleAccessFormData(
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      imei: imei ?? this.imei,
      permissions: permissions ?? this.permissions,
    );
  }
}

class VehicleAccessResponse {
  final bool success;
  final String message;
  final List<VehicleAccess>? data;
  final VehicleAccess? singleData;

  VehicleAccessResponse({
    required this.success,
    required this.message,
    this.data,
    this.singleData,
  });

  factory VehicleAccessResponse.fromJson(Map<String, dynamic> json) {
    return VehicleAccessResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? (json['data'] as List).map((item) => VehicleAccess.fromJson(item)).toList()
          : null,
      singleData: json['data'] != null && json['data'] is Map<String, dynamic>
          ? VehicleAccess.fromJson(json['data'])
          : null,
    );
  }
}
