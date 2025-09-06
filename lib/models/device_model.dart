class Device {
  final String id;
  final String imei;
  final String? phone;
  final String? sim;
  final String? protocol;
  final String? iccid;
  final String? model;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Map<String, dynamic>>? userDevices;
  final List<Map<String, dynamic>>? vehicles;

  Device({
    required this.id,
    required this.imei,
    this.phone,
    this.sim,
    this.protocol,
    this.iccid,
    this.model,
    this.createdAt,
    this.updatedAt,
    this.userDevices,
    this.vehicles,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'].toString(),
      imei: json['imei'] ?? '',
      phone: json['phone'] ?? '',
      sim: json['sim'] ?? '',
      protocol: json['protocol'] ?? '',
      iccid: json['iccid'] ?? '',
      model: json['model'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      userDevices: json['userDevices'] != null
          ? List<Map<String, dynamic>>.from(json['userDevices'])
          : null,
      vehicles: json['vehicles'] != null
          ? List<Map<String, dynamic>>.from(json['vehicles'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imei': imei,
      'phone': phone,
      'sim': sim,
      'protocol': protocol,
      'iccid': iccid,
      'model': model,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'userDevices': userDevices,
      'vehicles': vehicles,
    };
  }

  Device copyWith({
    String? id,
    String? imei,
    String? phone,
    String? sim,
    String? protocol,
    String? iccid,
    String? model,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Map<String, dynamic>>? userDevices,
    List<Map<String, dynamic>>? vehicles,
  }) {
    return Device(
      id: id ?? this.id,
      imei: imei ?? this.imei,
      phone: phone ?? this.phone,
      sim: sim ?? this.sim,
      protocol: protocol ?? this.protocol,
      iccid: iccid ?? this.iccid,
      model: model ?? this.model,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userDevices: userDevices ?? this.userDevices,
      vehicles: vehicles ?? this.vehicles,
    );
  }
}
