class User {
  final int id;
  final String name;
  final String phone;
  final String status;
  final Role role;
  final List<String> permissions; // Direct user permissions
  final String? profilePicture;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    required this.role,
    this.permissions = const [],
    this.profilePicture,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle role - it can be either a string, object, or array
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
    } else if (json['roles'] is List && (json['roles'] as List).isNotEmpty) {
      // If roles is an array, take the first role (your backend uses this format)
      final rolesList = json['roles'] as List;
      final firstRole = rolesList.first as Map<String, dynamic>;
      role = Role.fromJson(firstRole);
    } else {
      // Default role if role is null or invalid
      role = Role.defaultRole();
    }

    // Handle permissions - can be array of strings or null
    List<String> permissions = [];
    if (json['permissions'] != null && json['permissions'] is List) {
      permissions = List<String>.from(json['permissions']);
    }

    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      status: json['status'] ?? 'ACTIVE',
      role: role,
      permissions: permissions,
      profilePicture: json['profilePicture'],
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
      'permissions': permissions,
      'profilePicture': profilePicture,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Get all user permissions (role + direct)
  List<String> getAllPermissions() {
    // Return all permissions (role + direct) as sent by Django
    return permissions.toList();
  }

  // Check if user has specific permission (role or direct)
  bool hasPermission(String permissionName) {
    return getAllPermissions().contains(permissionName);
  }

  // Check if user has any of the specified permissions
  bool hasAnyPermission(List<String> permissionNames) {
    List<String> userPermissions = getAllPermissions();
    return permissionNames.any(
      (permission) => userPermissions.contains(permission),
    );
  }

  // Check if user has all of the specified permissions
  bool hasAllPermissions(List<String> permissionNames) {
    List<String> userPermissions = getAllPermissions();
    return permissionNames.every(
      (permission) => userPermissions.contains(permission),
    );
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
    if (json['permissions'] != null && json['permissions'] is List) {
      final permissionsList = json['permissions'] as List;
      permissions = permissionsList.map((p) {
        if (p is String) {
          // If permission is a string, create a basic Permission object
          return Permission(id: 0, name: p);
        } else if (p is Map<String, dynamic>) {
          // If permission is an object, parse it normally
          return Permission.fromJson(p);
        } else {
          // Fallback
          return Permission(id: 0, name: p.toString());
        }
      }).toList();
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
