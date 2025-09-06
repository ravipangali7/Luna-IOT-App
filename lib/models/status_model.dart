class Status {
  final String imei;
  final int? battery;
  final int? signal;
  final bool? ignition;
  final bool? charging;
  final bool? relay;
  final DateTime? createdAt;

  Status({
    required this.imei,
    this.battery,
    this.signal,
    this.ignition,
    this.charging,
    this.relay,
    this.createdAt,
  });

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
      imei: json['imei'] ?? '',
      battery: _parseInt(json['battery']),
      signal: _parseInt(json['signal']),
      ignition: _parseBool(json['ignition']),
      charging: _parseBool(json['charging']),
      relay: _parseBool(json['relay']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
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

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'imei': imei,
      'battery': battery,
      'signal': signal,
      'ignition': ignition,
      'charging': charging,
      'relay': relay,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Status copyWith({
    String? imei,
    int? battery,
    int? signal,
    bool? ignition,
    bool? charging,
    bool? relay,
    DateTime? createdAt,
  }) {
    return Status(
      imei: imei ?? this.imei,
      battery: battery ?? this.battery,
      signal: signal ?? this.signal,
      ignition: ignition ?? this.ignition,
      charging: charging ?? this.charging,
      relay: relay ?? this.relay,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
