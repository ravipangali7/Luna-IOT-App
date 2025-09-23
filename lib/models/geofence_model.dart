import 'package:luna_iot/models/user_model.dart';
import 'package:luna_iot/models/vehicle_model.dart';

class GeofenceModel {
  final int? id;
  final String title;
  final GeofenceType type;
  final List<String> boundary;
  final List<Vehicle> vehicles;
  final List<User> users;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GeofenceModel({
    this.id,
    required this.title,
    required this.type,
    required this.boundary,
    this.vehicles = const [],
    this.users = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory GeofenceModel.fromJson(Map<String, dynamic> json) {
    return GeofenceModel(
      id: json['id'],
      title: json['title'] ?? '',
      type: GeofenceType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => GeofenceType.Entry,
      ),
      boundary: List<String>.from(json['boundary'] ?? []),
      vehicles: json['vehicles'] != null
          ? (json['vehicles'] as List).map((v) => Vehicle.fromJson(v)).toList()
          : [],
      users: json['users'] != null
          ? (json['users'] as List).map((u) => User.fromJson(u)).toList()
          : [],
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
      'title': title,
      'type': type.toString().split('.').last,
      'boundary': boundary,
      'vehicles': vehicles.map((v) => v.toJson()).toList(),
      'users': users.map((u) => u.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  GeofenceModel copyWith({
    int? id,
    String? title,
    GeofenceType? type,
    List<String>? boundary,
    User? createdBy,
    List<Vehicle>? vehicles,
    List<User>? users,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GeofenceModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      boundary: boundary ?? this.boundary,
      vehicles: vehicles ?? this.vehicles,
      users: users ?? this.users,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum GeofenceType { Entry, Exit }
