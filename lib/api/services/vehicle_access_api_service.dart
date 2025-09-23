import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/models/vehicle_access_model.dart';

class VehicleAccessApiService {
  static const String _baseUrl = ApiClient.baseUrl;

  // Get all vehicle access records
  static Future<VehicleAccessResponse> getAllVehicleAccess({
    String? search,
    int? userId,
    int? vehicleId,
    String? imei,
  }) async {
    try {
      String url = '$_baseUrl/api/fleet/vehicle-access';
      List<String> queryParams = [];

      if (search != null) queryParams.add('search=$search');
      if (userId != null) queryParams.add('userId=$userId');
      if (vehicleId != null) queryParams.add('vehicleId=$vehicleId');
      if (imei != null) queryParams.add('imei=$imei');

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        // Django response format: {success: true, message: '...', data: {...}}
        if (jsonData['success'] == true) {
          return VehicleAccessResponse.fromJson(jsonData);
        } else {
          throw Exception(
            'Failed to load vehicle access: ${jsonData['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load vehicle access: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching vehicle access: $e');
    }
  }

  // Get vehicle access by ID
  static Future<VehicleAccess> getVehicleAccessById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/fleet/vehicle-access/$id'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return VehicleAccess.fromJson(jsonData['data']);
        } else {
          throw Exception('Vehicle access not found');
        }
      } else {
        throw Exception(
          'Failed to load vehicle access: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching vehicle access: $e');
    }
  }

  // Get vehicle access by vehicle IMEI
  static Future<VehicleAccessResponse> getVehicleAccessByVehicle(
    String imei,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/fleet/vehicle/$imei/access'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        // Django response format: {success: true, message: '...', data: {...}}
        if (jsonData['success'] == true) {
          return VehicleAccessResponse.fromJson(jsonData);
        } else {
          throw Exception(
            'Failed to load vehicle access by vehicle: ${jsonData['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load vehicle access by vehicle: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching vehicle access by vehicle: $e');
    }
  }

  // Create vehicle access
  static Future<VehicleAccess> createVehicleAccess(
    VehicleAccessFormData formData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/fleet/vehicle-access/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(formData.toJson()),
      );

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return VehicleAccess.fromJson(jsonData['data']);
        } else {
          throw Exception('Failed to create vehicle access');
        }
      } else {
        final jsonData = json.decode(response.body);
        throw Exception(
          jsonData['message'] ?? 'Failed to create vehicle access',
        );
      }
    } catch (e) {
      throw Exception('Error creating vehicle access: $e');
    }
  }

  // Update vehicle access
  static Future<VehicleAccess> updateVehicleAccess(
    int id,
    VehicleAccessFormData formData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/fleet/vehicle-access/update/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(formData.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return VehicleAccess.fromJson(jsonData['data']);
        } else {
          throw Exception('Failed to update vehicle access');
        }
      } else {
        final jsonData = json.decode(response.body);
        throw Exception(
          jsonData['message'] ?? 'Failed to update vehicle access',
        );
      }
    } catch (e) {
      throw Exception('Error updating vehicle access: $e');
    }
  }

  // Delete vehicle access
  static Future<bool> deleteVehicleAccess(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/fleet/vehicle-access/delete/$id'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['success'] == true;
      } else {
        throw Exception(
          'Failed to delete vehicle access: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error deleting vehicle access: $e');
    }
  }

  // Get available users for vehicle access assignment
  static Future<VehicleAccessResponse> getAvailableUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/core/user/users'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        // Django response format: {success: true, message: '...', data: [...]}
        if (jsonData['success'] == true) {
          return VehicleAccessResponse.fromJson(jsonData);
        } else {
          throw Exception(
            'Failed to load available users: ${jsonData['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load available users: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching available users: $e');
    }
  }

  // Get available vehicles for vehicle access assignment
  static Future<VehicleAccessResponse> getAvailableVehicles() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/fleet/vehicle'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        // Django response format: {success: true, message: '...', data: [...]}
        if (jsonData['success'] == true) {
          return VehicleAccessResponse.fromJson(jsonData);
        } else {
          throw Exception(
            'Failed to load available vehicles: ${jsonData['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load available vehicles: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching available vehicles: $e');
    }
  }

  // Update vehicle access permissions (using existing endpoint)
  static Future<VehicleAccess> updateVehicleAccessPermissions(
    String imei,
    int userId,
    VehicleAccessPermissions permissions,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/fleet/vehicle/access'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'imei': imei,
          'userId': userId,
          'permissions': permissions.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return VehicleAccess.fromJson(jsonData['data']);
        } else {
          throw Exception('Failed to update vehicle access permissions');
        }
      } else {
        final jsonData = json.decode(response.body);
        throw Exception(
          jsonData['message'] ?? 'Failed to update vehicle access permissions',
        );
      }
    } catch (e) {
      throw Exception('Error updating vehicle access permissions: $e');
    }
  }

  // Remove vehicle access (using existing endpoint)
  static Future<bool> removeVehicleAccess(String imei, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/fleet/vehicle/access'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'imei': imei, 'userId': userId}),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['success'] == true;
      } else {
        throw Exception(
          'Failed to remove vehicle access: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error removing vehicle access: $e');
    }
  }
}
