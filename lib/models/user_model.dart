class User {
  final int id;
  final String name;
  final String phone;
  final String status;
  final Role role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle role - it can be either a string or an object
    Role role;
    if (json['role'] is String) {
      // If role is a string, create a basic role object
      role = Role(
        id: 0,
        name: json['role'] as String,
        description: null,
        permissions: [],
      );
    } else if (json['role'] is Map<String, dynamic>) {
      // If role is an object, parse it normally
      role = Role.fromJson(json['role'] as Map<String, dynamic>);
    } else {
      // Default role if role is null or invalid
      role = Role.defaultRole();
    }

    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      status: json['status'] ?? 'ACTIVE',
      role: role,
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
      'status': status,
      'role': role.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class Role {
  final int id;
  final String name;
  final String? description;
  final List<Permission> permissions;

  Role({
    required this.id,
    required this.name,
    this.description,
    required this.permissions,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    List<Permission> permissions = [];
    if (json['permissions'] != null) {
      permissions = (json['permissions'] as List)
          .map((p) => Permission.fromJson(p))
          .toList();
    }

    return Role(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      permissions: permissions,
    );
  }

  factory Role.defaultRole() {
    return Role(
      id: 0,
      name: 'Customer',
      description: 'Default user role',
      permissions: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'permissions': permissions.map((p) => p.toJson()).toList(),
    };
  }

  // Role-based access methods
  bool get isSuperAdmin => name == 'Super Admin';
  bool get isDealer => name == 'Dealer';
  bool get isCustomer => name == 'Customer';

  // Permission-based access methods
  bool hasPermission(String permissionName) {
    return permissions.any((p) => p.name == permissionName);
  }

  // Device permissions
  bool canAccessDevices() {
    return isSuperAdmin || isDealer; // Super Admin and Dealer can view devices
  }

  bool canCreateDevices() {
    return isSuperAdmin; // Only Super Admin can create devices
  }

  bool canUpdateDevices() {
    return isSuperAdmin; // Only Super Admin can update devices
  }

  bool canDeleteDevices() {
    return isSuperAdmin; // Only Super Admin can delete devices
  }

  // Vehicle permissions
  bool canAccessVehicles() {
    return isSuperAdmin ||
        isDealer ||
        isCustomer; // All roles can view vehicles
  }

  bool canCreateVehicles() {
    return isSuperAdmin ||
        isDealer ||
        isCustomer; // All roles can create vehicles
  }

  bool canUpdateVehicles() {
    return isSuperAdmin ||
        isDealer ||
        isCustomer; // All roles can update vehicles
  }

  bool canDeleteVehicles() {
    return isSuperAdmin; // Only Super Admin can delete vehicles
  }

  // User management permissions
  bool canAccessUsers() {
    return isSuperAdmin; // Only Super Admin can access users
  }

  bool canCreateUsers() {
    return isSuperAdmin; // Only Super Admin can create users
  }

  bool canUpdateUsers() {
    return isSuperAdmin; // Only Super Admin can update users
  }

  bool canDeleteUsers() {
    return isSuperAdmin; // Only Super Admin can delete users
  }

  // Role management permissions
  bool canAccessRoles() {
    return isSuperAdmin; // Only Super Admin can access roles
  }

  // Device monitoring permissions
  bool canAccessDeviceMonitoring() {
    return isSuperAdmin; // Only Super Admin can access device monitoring
  }

  // Live tracking permissions
  bool canAccessLiveTracking() {
    return isSuperAdmin ||
        isDealer ||
        isCustomer; // All roles can access live tracking
  }
}

class Permission {
  final int id;
  final String name;
  final String? description;

  Permission({required this.id, required this.name, this.description});

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'description': description};
  }
}
