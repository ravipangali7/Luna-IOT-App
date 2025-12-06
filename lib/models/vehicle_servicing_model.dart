class VehicleServicing {
  int? id;
  int vehicleId;
  String? vehicleName;
  String? vehicleImei;
  String title;
  double odometer;
  double amount;
  DateTime date;
  String? remarks;
  DateTime? createdAt;
  DateTime? updatedAt;

  VehicleServicing({
    this.id,
    required this.vehicleId,
    this.vehicleName,
    this.vehicleImei,
    required this.title,
    required this.odometer,
    required this.amount,
    required this.date,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleServicing.fromJson(Map<String, dynamic> json) {
    return VehicleServicing(
      id: json['id'],
      vehicleId: _parseInt(json['vehicle'] ?? json['vehicle_id']) ?? 0,
      vehicleName: json['vehicle_name'],
      vehicleImei: json['vehicle_imei'],
      title: json['title'] ?? '',
      odometer: _parseDouble(json['odometer']) ?? 0.0,
      amount: _parseDouble(json['amount']) ?? 0.0,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle': vehicleId,
      'title': title,
      'odometer': odometer,
      'amount': amount,
      'date': date.toIso8601String().split('T')[0],
      'remarks': remarks,
    };
  }

  VehicleServicing copyWith({
    int? id,
    int? vehicleId,
    String? vehicleName,
    String? vehicleImei,
    String? title,
    double? odometer,
    double? amount,
    DateTime? date,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleServicing(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleName: vehicleName ?? this.vehicleName,
      vehicleImei: vehicleImei ?? this.vehicleImei,
      title: title ?? this.title,
      odometer: odometer ?? this.odometer,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

