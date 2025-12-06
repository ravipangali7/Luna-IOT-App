class VehicleDocument {
  int? id;
  int vehicleId;
  String? vehicleName;
  String? vehicleImei;
  String title;
  DateTime lastExpireDate;
  int expireInMonth;
  String? documentImageOne;
  String? documentImageTwo;
  String? remarks;
  DateTime? createdAt;
  DateTime? updatedAt;

  VehicleDocument({
    this.id,
    required this.vehicleId,
    this.vehicleName,
    this.vehicleImei,
    required this.title,
    required this.lastExpireDate,
    required this.expireInMonth,
    this.documentImageOne,
    this.documentImageTwo,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleDocument.fromJson(Map<String, dynamic> json) {
    return VehicleDocument(
      id: json['id'],
      vehicleId: _parseInt(json['vehicle'] ?? json['vehicle_id']) ?? 0,
      vehicleName: json['vehicle_name'],
      vehicleImei: json['vehicle_imei'],
      title: json['title'] ?? '',
      lastExpireDate: json['last_expire_date'] != null 
          ? DateTime.parse(json['last_expire_date']) 
          : DateTime.now(),
      expireInMonth: _parseInt(json['expire_in_month']) ?? 12,
      documentImageOne: json['document_image_one'],
      documentImageTwo: json['document_image_two'],
      remarks: json['remarks'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle': vehicleId,
      'title': title,
      'last_expire_date': lastExpireDate.toIso8601String().split('T')[0],
      'expire_in_month': expireInMonth,
      'remarks': remarks,
    };
  }

  VehicleDocument copyWith({
    int? id,
    int? vehicleId,
    String? vehicleName,
    String? vehicleImei,
    String? title,
    DateTime? lastExpireDate,
    int? expireInMonth,
    String? documentImageOne,
    String? documentImageTwo,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleDocument(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleName: vehicleName ?? this.vehicleName,
      vehicleImei: vehicleImei ?? this.vehicleImei,
      title: title ?? this.title,
      lastExpireDate: lastExpireDate ?? this.lastExpireDate,
      expireInMonth: expireInMonth ?? this.expireInMonth,
      documentImageOne: documentImageOne ?? this.documentImageOne,
      documentImageTwo: documentImageTwo ?? this.documentImageTwo,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

