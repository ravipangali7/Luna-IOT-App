class VehicleExpenses {
  int? id;
  int vehicleId;
  String? vehicleName;
  String? vehicleImei;
  String title;
  String expensesType; // 'part' or 'fine'
  DateTime entryDate;
  int? partExpireMonth;
  double amount;
  String? remarks;
  DateTime? createdAt;
  DateTime? updatedAt;

  VehicleExpenses({
    this.id,
    required this.vehicleId,
    this.vehicleName,
    this.vehicleImei,
    required this.title,
    required this.expensesType,
    required this.entryDate,
    this.partExpireMonth,
    required this.amount,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleExpenses.fromJson(Map<String, dynamic> json) {
    return VehicleExpenses(
      id: json['id'],
      vehicleId: _parseInt(json['vehicle'] ?? json['vehicle_id']) ?? 0,
      vehicleName: json['vehicle_name'],
      vehicleImei: json['vehicle_imei'],
      title: json['title'] ?? '',
      expensesType: json['expenses_type'] ?? 'part',
      entryDate: json['entry_date'] != null ? DateTime.parse(json['entry_date']) : DateTime.now(),
      partExpireMonth: _parseInt(json['part_expire_month']),
      amount: _parseDouble(json['amount']) ?? 0.0,
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
      'expenses_type': expensesType,
      'entry_date': entryDate.toIso8601String().split('T')[0],
      'part_expire_month': partExpireMonth,
      'amount': amount,
      'remarks': remarks,
    };
  }

  VehicleExpenses copyWith({
    int? id,
    int? vehicleId,
    String? vehicleName,
    String? vehicleImei,
    String? title,
    String? expensesType,
    DateTime? entryDate,
    int? partExpireMonth,
    double? amount,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleExpenses(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleName: vehicleName ?? this.vehicleName,
      vehicleImei: vehicleImei ?? this.vehicleImei,
      title: title ?? this.title,
      expensesType: expensesType ?? this.expensesType,
      entryDate: entryDate ?? this.entryDate,
      partExpireMonth: partExpireMonth ?? this.partExpireMonth,
      amount: amount ?? this.amount,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

