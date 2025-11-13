class LunaTag {
  final int id;
  final String publicKey;
  final bool isLostMode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LunaTag({
    required this.id,
    required this.publicKey,
    required this.isLostMode,
    this.createdAt,
    this.updatedAt,
  });

  factory LunaTag.fromJson(Map<String, dynamic> json) {
    return LunaTag(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : (json['id'] ?? 0),
      publicKey: json['publicKey'] ?? json['public_key'] ?? '',
      isLostMode: json['is_lost_mode'] ?? json['isLostMode'] ?? false,
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'publicKey': publicKey,
      'is_lost_mode': isLostMode,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class LunaTagData {
  final int id;
  final String publicKey;
  final double? battery;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LunaTagData({
    required this.id,
    required this.publicKey,
    this.battery,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  factory LunaTagData.fromJson(Map<String, dynamic> json) {
    return LunaTagData(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : (json['id'] ?? 0),
      publicKey: json['publicKey_value'] ?? json['publicKey'] ?? json['public_key'] ?? '',
      battery: _toDouble(json['battery']),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class UserLunaTag {
  final int id;
  final String publicKey; // LunaTag publicKey string
  final String? name;
  final String? image;
  final DateTime? expireDate;
  final bool isActive;
  final bool isLostMode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserLunaTag({
    required this.id,
    required this.publicKey,
    this.name,
    this.image,
    this.expireDate,
    required this.isActive,
    this.isLostMode = false,
    this.createdAt,
    this.updatedAt,
  });

  factory UserLunaTag.fromJson(Map<String, dynamic> json) {
    return UserLunaTag(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : (json['id'] ?? 0),
      publicKey: json['publicKey_value'] ?? json['publicKey'] ?? json['public_key'] ?? '',
      name: json['name'],
      image: json['image'],
      expireDate: _parseDate(json['expire_date']),
      isActive: json['is_active'] ?? json['isActive'] ?? false,
      isLostMode: json['is_lost_mode'] ?? json['isLostMode'] ?? false,
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'publicKey': publicKey,
      'name': name,
      'image': image,
      'expire_date': expireDate?.toIso8601String(),
      'is_active': isActive,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}