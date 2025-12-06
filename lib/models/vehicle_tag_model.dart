class VehicleTag {
  int? id;
  String vtid;
  String? vehicleModel;
  String? registrationNo;
  String? registerType;
  String? vehicleCategory;
  String? sosNumber;
  String? smsNumber;
  bool? isActive;
  bool? isDownloaded;
  int? visitCount;
  int? alertCount;
  int? smsAlertCount;
  Map<String, dynamic>? userInfo;
  DateTime? createdAt;
  DateTime? updatedAt;

  VehicleTag({
    this.id,
    required this.vtid,
    this.vehicleModel,
    this.registrationNo,
    this.registerType,
    this.vehicleCategory,
    this.sosNumber,
    this.smsNumber,
    this.isActive,
    this.isDownloaded,
    this.visitCount,
    this.alertCount,
    this.smsAlertCount,
    this.userInfo,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleTag.fromJson(Map<String, dynamic> json) {
    return VehicleTag(
      id: json['id'],
      vtid: json['vtid'] ?? '',
      vehicleModel: json['vehicle_model'],
      registrationNo: json['registration_no'],
      registerType: json['register_type'],
      vehicleCategory: json['vehicle_category'],
      sosNumber: json['sos_number'],
      smsNumber: json['sms_number'],
      isActive: json['is_active'] ?? true,
      isDownloaded: json['is_downloaded'] ?? false,
      visitCount: json['visit_count'] ?? 0,
      alertCount: json['alert_count'] ?? 0,
      smsAlertCount: json['sms_alert_count'] ?? 0,
      userInfo: json['user_info'] is Map<String, dynamic>
          ? json['user_info']
          : (json['user_info'] == 'unassigned' ? null : null),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vtid': vtid,
      'vehicle_model': vehicleModel,
      'registration_no': registrationNo,
      'register_type': registerType,
      'vehicle_category': vehicleCategory,
      'sos_number': sosNumber,
      'sms_number': smsNumber,
      'is_active': isActive,
      'is_downloaded': isDownloaded,
      'visit_count': visitCount,
      'alert_count': alertCount,
      'sms_alert_count': smsAlertCount,
      'user_info': userInfo,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get displayName {
    if (registrationNo != null && registrationNo!.isNotEmpty) {
      return '$registrationNo | $vtid';
    }
    return vtid;
  }

  String get userDisplayName {
    if (userInfo != null && userInfo!['name'] != null) {
      return userInfo!['name'];
    }
    return 'Unassigned';
  }
}

