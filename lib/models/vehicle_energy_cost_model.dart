class VehicleEnergyCost {
  int? id;
  int vehicleId;
  String? vehicleName;
  String? vehicleImei;
  String title;
  String energyType; // 'fuel' or 'electric'
  DateTime entryDate;
  double amount;
  double totalUnit;
  String? remarks;
  DateTime? createdAt;
  DateTime? updatedAt;

  VehicleEnergyCost({
    this.id,
    required this.vehicleId,
    this.vehicleName,
    this.vehicleImei,
    required this.title,
    required this.energyType,
    required this.entryDate,
    required this.amount,
    required this.totalUnit,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleEnergyCost.fromJson(Map<String, dynamic> json) {
    return VehicleEnergyCost(
      id: json['id'],
      vehicleId: _parseInt(json['vehicle'] ?? json['vehicle_id']) ?? 0,
      vehicleName: json['vehicle_name'],
      vehicleImei: json['vehicle_imei'],
      title: json['title'] ?? '',
      energyType: json['energy_type'] ?? 'fuel',
      entryDate: json['entry_date'] != null ? DateTime.parse(json['entry_date']) : DateTime.now(),
      amount: _parseDouble(json['amount']) ?? 0.0,
      totalUnit: _parseDouble(json['total_unit']) ?? 0.0,
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
      'energy_type': energyType,
      'entry_date': entryDate.toIso8601String().split('T')[0],
      'amount': amount,
      'total_unit': totalUnit,
      'remarks': remarks,
    };
  }

  VehicleEnergyCost copyWith({
    int? id,
    int? vehicleId,
    String? vehicleName,
    String? vehicleImei,
    String? title,
    String? energyType,
    DateTime? entryDate,
    double? amount,
    double? totalUnit,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleEnergyCost(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleName: vehicleName ?? this.vehicleName,
      vehicleImei: vehicleImei ?? this.vehicleImei,
      title: title ?? this.title,
      energyType: energyType ?? this.energyType,
      entryDate: entryDate ?? this.entryDate,
      amount: amount ?? this.amount,
      totalUnit: totalUnit ?? this.totalUnit,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

