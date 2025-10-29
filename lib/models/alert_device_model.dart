class AlertDevice {
  final String id;
  final String imei;
  final String phone;
  final String type;
  final int battery;
  final int signal;
  final bool ignition;
  final bool charging;
  final bool relay;
  final DateTime? lastDataAt;
  final bool isInactive;
  final String statusTable;
  final InstituteInfo? institute;

  AlertDevice({
    required this.id,
    required this.imei,
    required this.phone,
    required this.type,
    required this.battery,
    required this.signal,
    required this.ignition,
    required this.charging,
    required this.relay,
    this.lastDataAt,
    required this.isInactive,
    required this.statusTable,
    this.institute,
  });

  factory AlertDevice.fromJson(Map<String, dynamic> json) {
    return AlertDevice(
      id: json['id']?.toString() ?? '',
      imei: json['imei'] ?? '',
      phone: json['phone'] ?? '',
      type: json['type'] ?? '',
      battery: json['battery'] ?? 0,
      signal: json['signal'] ?? 0,
      ignition: json['ignition'] ?? false,
      charging: json['charging'] ?? false,
      relay: json['relay'] ?? false,
      lastDataAt: json['lastDataAt'] != null
          ? DateTime.parse(json['lastDataAt'])
          : null,
      isInactive: json['isInactive'] ?? false,
      statusTable: json['statusTable'] ?? '',
      institute: json['institute'] != null
          ? InstituteInfo.fromJson(json['institute'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imei': imei,
      'phone': phone,
      'type': type,
      'battery': battery,
      'signal': signal,
      'ignition': ignition,
      'charging': charging,
      'relay': relay,
      'lastDataAt': lastDataAt?.toIso8601String(),
      'isInactive': isInactive,
      'statusTable': statusTable,
      'institute': institute?.toJson(),
    };
  }

  String get deviceName {
    switch (type.toLowerCase()) {
      case 'buzzer':
        return 'Buzzer';
      case 'sos':
        return 'Switch';
      default:
        return type.toUpperCase();
    }
  }
}

class InstituteInfo {
  final int id;
  final String name;
  final String? logo;

  InstituteInfo({required this.id, required this.name, this.logo});

  factory InstituteInfo.fromJson(Map<String, dynamic> json) {
    return InstituteInfo(
      id: json['id'],
      name: json['name'],
      logo: json['logo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'logo': logo};
  }
}
