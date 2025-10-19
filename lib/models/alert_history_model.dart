class AlertHistory {
  final String source; // 'app'
  final String name;
  final String primaryPhone;
  final String? secondaryPhone;
  final int alertType;
  final double latitude;
  final double longitude;
  final String datetime; // ISO 8601 format
  final String? image;
  final String? remarks;
  final String status; // 'pending'
  final int institute;

  AlertHistory({
    required this.source,
    required this.name,
    required this.primaryPhone,
    this.secondaryPhone,
    required this.alertType,
    required this.latitude,
    required this.longitude,
    required this.datetime,
    this.image,
    this.remarks,
    required this.status,
    required this.institute,
  });

  factory AlertHistory.fromJson(Map<String, dynamic> json) {
    return AlertHistory(
      source: json['source'] ?? '',
      name: json['name'] ?? '',
      primaryPhone: json['primary_phone'] ?? '',
      secondaryPhone: json['secondary_phone'],
      alertType: json['alert_type'] ?? 0,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      datetime: json['datetime'] ?? '',
      image: json['image'],
      remarks: json['remarks'],
      status: json['status'] ?? '',
      institute: json['institute'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'name': name,
      'primary_phone': primaryPhone,
      'secondary_phone': secondaryPhone,
      'alert_type': alertType,
      'latitude': latitude,
      'longitude': longitude,
      'datetime': datetime,
      'image': image,
      'remarks': remarks,
      'status': status,
      'institute': institute,
    };
  }

  // Create AlertHistory for SOS alert
  factory AlertHistory.createSosAlert({
    required String name,
    required String primaryPhone,
    required int alertType,
    required double latitude,
    required double longitude,
    required int institute,
  }) {
    return AlertHistory(
      source: 'app',
      name: name,
      primaryPhone: primaryPhone,
      secondaryPhone: '',
      alertType: alertType,
      latitude: latitude,
      longitude: longitude,
      datetime: _getNepaliDateTime(),
      image: null,
      remarks: null,
      status: 'pending',
      institute: institute,
    );
  }

  // Get current Nepal time (UTC+5:45)
  static String _getNepaliDateTime() {
    final now = DateTime.now().toUtc();
    final nepaliTime = now.add(Duration(hours: 5, minutes: 45));
    return nepaliTime.toIso8601String();
  }

  // Helper method to parse latitude/longitude from string or number
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
