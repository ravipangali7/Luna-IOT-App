class BloodDonation {
  final int? id;
  final String name;
  final String phone;
  final String address;
  final String bloodGroup;
  final String applyType; // 'need' or 'donate'
  final bool status; // true = received/donated, false = pending
  final DateTime? lastDonatedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BloodDonation({
    this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.bloodGroup,
    required this.applyType,
    this.status = false,
    this.lastDonatedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory BloodDonation.fromJson(Map<String, dynamic> json) {
    return BloodDonation(
      id: json['id'],
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      applyType: json['applyType'] ?? '',
      status: json['status'] ?? false,
      lastDonatedAt: json['lastDonatedAt'] != null
          ? DateTime.parse(json['lastDonatedAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'bloodGroup': bloodGroup,
      'applyType': applyType,
      'status': status,
      'lastDonatedAt': lastDonatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  BloodDonation copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    String? bloodGroup,
    String? applyType,
    bool? status,
    DateTime? lastDonatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BloodDonation(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      applyType: applyType ?? this.applyType,
      status: status ?? this.status,
      lastDonatedAt: lastDonatedAt ?? this.lastDonatedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BloodDonationResponse {
  final bool success;
  final String message;
  final List<BloodDonation>? data;
  final String? timestamp;

  BloodDonationResponse({
    required this.success,
    required this.message,
    this.data,
    this.timestamp,
  });

  factory BloodDonationResponse.fromJson(Map<String, dynamic> json) {
    return BloodDonationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? (json['data'] as List)
                .map((item) => BloodDonation.fromJson(item))
                .toList()
          : null,
      timestamp: json['timestamp'],
    );
  }
}

// Blood group options
class BloodGroupOptions {
  static const List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];
}

// Apply type options
class ApplyTypeOptions {
  static const String need = 'need';
  static const String donate = 'donate';

  static const List<String> types = [need, donate];

  static String getDisplayName(String type) {
    switch (type) {
      case need:
        return 'Need Blood';
      case donate:
        return 'Donate Blood';
      default:
        return type;
    }
  }
}
