class FleetReport {
  int totalDays;
  ServicingReport servicing;
  ExpensesReport expenses;
  EnergyCostReport energyCost;

  FleetReport({
    required this.totalDays,
    required this.servicing,
    required this.expenses,
    required this.energyCost,
  });

  factory FleetReport.fromJson(Map<String, dynamic> json) {
    return FleetReport(
      totalDays: json['total_days'] ?? 0,
      servicing: ServicingReport.fromJson(json['servicing'] ?? {}),
      expenses: ExpensesReport.fromJson(json['expenses'] ?? {}),
      energyCost: EnergyCostReport.fromJson(json['energy_cost'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_days': totalDays,
      'servicing': servicing.toJson(),
      'expenses': expenses.toJson(),
      'energy_cost': energyCost.toJson(),
    };
  }
}

class ServicingReport {
  int totalCount;
  double totalAmount;
  List<Map<String, dynamic>> details;

  ServicingReport({
    required this.totalCount,
    required this.totalAmount,
    required this.details,
  });

  factory ServicingReport.fromJson(Map<String, dynamic> json) {
    return ServicingReport(
      totalCount: json['total_count'] ?? 0,
      totalAmount: _parseDouble(json['total_amount']) ?? 0.0,
      details: json['details'] != null 
          ? List<Map<String, dynamic>>.from(json['details'])
          : [],
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

  Map<String, dynamic> toJson() {
    return {
      'total_count': totalCount,
      'total_amount': totalAmount,
      'details': details,
    };
  }
}

class ExpensesReport {
  int totalCount;
  double totalAmount;
  Map<String, double> byType;
  List<Map<String, dynamic>> details;

  ExpensesReport({
    required this.totalCount,
    required this.totalAmount,
    required this.byType,
    required this.details,
  });

  factory ExpensesReport.fromJson(Map<String, dynamic> json) {
    return ExpensesReport(
      totalCount: json['total_count'] ?? 0,
      totalAmount: _parseDouble(json['total_amount']) ?? 0.0,
      byType: json['by_type'] != null 
          ? Map<String, double>.from(
              (json['by_type'] as Map).map((k, v) => MapEntry(k, _parseDouble(v) ?? 0.0))
            )
          : {},
      details: json['details'] != null 
          ? List<Map<String, dynamic>>.from(json['details'])
          : [],
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

  Map<String, dynamic> toJson() {
    return {
      'total_count': totalCount,
      'total_amount': totalAmount,
      'by_type': byType,
      'details': details,
    };
  }
}

class EnergyCostReport {
  int totalCount;
  double totalAmount;
  double totalUnits;
  Map<String, double> byType;
  List<Map<String, dynamic>> details;

  EnergyCostReport({
    required this.totalCount,
    required this.totalAmount,
    required this.totalUnits,
    required this.byType,
    required this.details,
  });

  factory EnergyCostReport.fromJson(Map<String, dynamic> json) {
    return EnergyCostReport(
      totalCount: json['total_count'] ?? 0,
      totalAmount: _parseDouble(json['total_amount']) ?? 0.0,
      totalUnits: _parseDouble(json['total_units']) ?? 0.0,
      byType: json['by_type'] != null 
          ? Map<String, double>.from(
              (json['by_type'] as Map).map((k, v) => MapEntry(k, _parseDouble(v) ?? 0.0))
            )
          : {},
      details: json['details'] != null 
          ? List<Map<String, dynamic>>.from(json['details'])
          : [],
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

  Map<String, dynamic> toJson() {
    return {
      'total_count': totalCount,
      'total_amount': totalAmount,
      'total_units': totalUnits,
      'by_type': byType,
      'details': details,
    };
  }
}

// Vehicle info for reports
class VehicleInfo {
  int id;
  String name;
  String imei;
  String? vehicleNo;

  VehicleInfo({
    required this.id,
    required this.name,
    required this.imei,
    this.vehicleNo,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      imei: json['imei'] ?? '',
      vehicleNo: json['vehicle_no'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imei': imei,
      'vehicle_no': vehicleNo,
    };
  }
}

// Single vehicle report (used in all vehicles report)
class VehicleFleetReport {
  VehicleInfo vehicle;
  ServicingReport servicing;
  ExpensesReport expenses;
  EnergyCostReport energyCost;

  VehicleFleetReport({
    required this.vehicle,
    required this.servicing,
    required this.expenses,
    required this.energyCost,
  });

  factory VehicleFleetReport.fromJson(Map<String, dynamic> json) {
    return VehicleFleetReport(
      vehicle: VehicleInfo.fromJson(json['vehicle'] ?? {}),
      servicing: ServicingReport.fromJson(json['servicing'] ?? {}),
      expenses: ExpensesReport.fromJson(json['expenses'] ?? {}),
      energyCost: EnergyCostReport.fromJson(json['energy_cost'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle': vehicle.toJson(),
      'servicing': servicing.toJson(),
      'expenses': expenses.toJson(),
      'energy_cost': energyCost.toJson(),
    };
  }
}

// Aggregated totals for all vehicles (simplified structure)
class AggregatedReport {
  int servicingTotalCount;
  double servicingTotalAmount;
  int expensesTotalCount;
  double expensesTotalAmount;
  Map<String, double> expensesByType;
  int energyCostTotalCount;
  double energyCostTotalAmount;
  double energyCostTotalUnits;
  Map<String, double> energyCostByType;

  AggregatedReport({
    required this.servicingTotalCount,
    required this.servicingTotalAmount,
    required this.expensesTotalCount,
    required this.expensesTotalAmount,
    required this.expensesByType,
    required this.energyCostTotalCount,
    required this.energyCostTotalAmount,
    required this.energyCostTotalUnits,
    required this.energyCostByType,
  });

  factory AggregatedReport.fromJson(Map<String, dynamic> json) {
    final servicing = json['servicing'] ?? {};
    final expenses = json['expenses'] ?? {};
    final energyCost = json['energy_cost'] ?? {};
    
    return AggregatedReport(
      servicingTotalCount: servicing['total_count'] ?? 0,
      servicingTotalAmount: _parseDouble(servicing['total_amount']) ?? 0.0,
      expensesTotalCount: expenses['total_count'] ?? 0,
      expensesTotalAmount: _parseDouble(expenses['total_amount']) ?? 0.0,
      expensesByType: expenses['by_type'] != null
          ? Map<String, double>.from(
              (expenses['by_type'] as Map).map((k, v) => MapEntry(k, _parseDouble(v) ?? 0.0))
            )
          : {},
      energyCostTotalCount: energyCost['total_count'] ?? 0,
      energyCostTotalAmount: _parseDouble(energyCost['total_amount']) ?? 0.0,
      energyCostTotalUnits: _parseDouble(energyCost['total_units']) ?? 0.0,
      energyCostByType: energyCost['by_type'] != null
          ? Map<String, double>.from(
              (energyCost['by_type'] as Map).map((k, v) => MapEntry(k, _parseDouble(v) ?? 0.0))
            )
          : {},
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

  Map<String, dynamic> toJson() {
    return {
      'servicing': {
        'total_count': servicingTotalCount,
        'total_amount': servicingTotalAmount,
      },
      'expenses': {
        'total_count': expensesTotalCount,
        'total_amount': expensesTotalAmount,
        'by_type': expensesByType,
      },
      'energy_cost': {
        'total_count': energyCostTotalCount,
        'total_amount': energyCostTotalAmount,
        'total_units': energyCostTotalUnits,
        'by_type': energyCostByType,
      },
    };
  }
}

// All vehicles fleet report
class AllVehiclesFleetReport {
  int totalDays;
  int totalVehicles;
  AggregatedReport aggregated;
  List<VehicleFleetReport> vehicles;

  AllVehiclesFleetReport({
    required this.totalDays,
    required this.totalVehicles,
    required this.aggregated,
    required this.vehicles,
  });

  factory AllVehiclesFleetReport.fromJson(Map<String, dynamic> json) {
    return AllVehiclesFleetReport(
      totalDays: json['total_days'] ?? 0,
      totalVehicles: json['total_vehicles'] ?? 0,
      aggregated: AggregatedReport.fromJson(json['aggregated'] ?? {}),
      vehicles: (json['vehicles'] as List<dynamic>?)
              ?.map((v) => VehicleFleetReport.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_days': totalDays,
      'total_vehicles': totalVehicles,
      'aggregated': aggregated.toJson(),
      'vehicles': vehicles.map((v) => v.toJson()).toList(),
    };
  }
}

