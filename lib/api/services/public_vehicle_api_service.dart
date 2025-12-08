import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/api_endpoints.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/models/location_model.dart';
import 'package:luna_iot/models/status_model.dart';

class PublicVehicleApiService {
  final ApiClient _apiClient;

  PublicVehicleApiService(this._apiClient);

  /// Get all public vehicles with basic info
  Future<List<Vehicle>> getPublicVehicles() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.getPublicVehicles);

      // Django response format: {success: true, message: '...', data: [...]}
      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> vehiclesJson = response.data['data'] as List;
        return vehiclesJson.map((json) => Vehicle.fromJson(json)).toList();
      }
      throw Exception(
        'Failed to get public vehicles: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Get latest location for a vehicle by IMEI
  Future<Location?> getLatestLocation(String imei) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getLatestLocation.replaceAll(':imei', imei),
      );

      // Django response format: {success: true, message: '...', data: {...}}
      if (response.data['success'] == true && response.data['data'] != null) {
        return Location.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      // If location not found, return null instead of throwing
      if (e.response?.statusCode == 404) {
        return null;
      }
      // For other errors, return null (don't break the flow)
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get all public vehicles with their latest locations and institute data
  /// Returns a list of maps containing institute, vehicle, and location data
  /// Only includes vehicles where is_active=True
  Future<List<Map<String, dynamic>>> getPublicVehiclesWithLocations() async {
    try {
      debugPrint('=== PUBLIC VEHICLE API SERVICE: Fetching vehicles with locations ===');
      debugPrint('Endpoint: ${ApiEndpoints.getPublicVehiclesWithLocations}');
      
      final response = await _apiClient.dio.get(
        ApiEndpoints.getPublicVehiclesWithLocations,
      );

      debugPrint('=== API RESPONSE RECEIVED ===');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response success: ${response.data['success']}');
      debugPrint('Response message: ${response.data['message']}');
      debugPrint('Response data type: ${response.data['data'].runtimeType}');
      debugPrint('Response data: ${response.data['data']}');

      // Django response format: {success: true, message: '...', data: [...]}
      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'] as List;
        debugPrint('=== PARSING RESPONSE DATA ===');
        debugPrint('Total institutes: ${data.length}');
        
        // Parse the structured response
        final List<Map<String, dynamic>> result = [];
        
        for (int i = 0; i < data.length; i++) {
          final instituteData = data[i];
          debugPrint('--- Institute $i ---');
          debugPrint('Institute data: $instituteData');
          
          final institute = instituteData['institute'] as Map<String, dynamic>;
          final vehicles = instituteData['vehicles'] as List<dynamic>;
          
          debugPrint('Institute name: ${institute['name']}');
          debugPrint('Institute ID: ${institute['id']}');
          debugPrint('Vehicles count: ${vehicles.length}');
          
          for (int j = 0; j < vehicles.length; j++) {
            final vehicleData = vehicles[j];
            debugPrint('  --- Vehicle $j ---');
            debugPrint('  Vehicle data: $vehicleData');
            
            final vehicleJson = vehicleData['vehicle'] as Map<String, dynamic>;
            final locationJson = vehicleData['location'] as Map<String, dynamic>?;
            final statusJson = vehicleData['status'] as Map<String, dynamic>?;
            final publicVehicleJson = vehicleData['public_vehicle'] as Map<String, dynamic>?;
            
            debugPrint('  Vehicle JSON: $vehicleJson');
            debugPrint('  Location JSON: $locationJson');
            debugPrint('  Status JSON: $statusJson');
            debugPrint('  Public Vehicle JSON: $publicVehicleJson');
            
            // Parse vehicle
            final vehicle = Vehicle.fromJson(vehicleJson);
            debugPrint('  Parsed Vehicle IMEI: ${vehicle.imei}');
            debugPrint('  Parsed Vehicle Name: ${vehicle.name}');
            
            // Parse location if available
            Location? location;
            if (locationJson != null) {
              debugPrint('  Parsing location...');
              location = Location.fromJson(locationJson);
              vehicle.latestLocation = location;
              debugPrint('  Location parsed - Lat: ${location.latitude}, Lng: ${location.longitude}');
            } else {
              debugPrint('  Location is NULL');
            }
            
            // Parse status if available
            if (statusJson != null) {
              debugPrint('  Parsing status...');
              final status = Status.fromJson(statusJson);
              vehicle.latestStatus = status;
              debugPrint('  Status parsed - Ignition: ${status.ignition}, Battery: ${status.battery}');
            } else {
              debugPrint('  Status is NULL');
            }
            
            // Add to result with institute data
            result.add({
              'institute': institute,
              'vehicle': vehicle,
              'location': location,
              'public_vehicle': publicVehicleJson,
            });
            debugPrint('  Added to result list');
          }
        }
        
        debugPrint('=== PARSING COMPLETE ===');
        debugPrint('Total result items: ${result.length}');
        
        return result;
      }
      debugPrint('=== API RESPONSE ERROR ===');
      debugPrint('Success is false or data is null');
      throw Exception(
        'Failed to get public vehicles with locations: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      debugPrint('=== DIO EXCEPTION ===');
      debugPrint('Error: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      debugPrint('Status code: ${e.response?.statusCode}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('=== GENERAL EXCEPTION ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to get public vehicles with locations: $e');
    }
  }

  /// Subscribe to public vehicle notifications
  Future<Map<String, dynamic>> subscribeToVehicle(
    String imei,
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.subscribeToPublicVehicle,
        data: {
          'imei': imei,
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'notification': true,
        },
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(
        'Failed to subscribe: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Unsubscribe from public vehicle notifications
  Future<bool> unsubscribeFromVehicle(String imei) async {
    try {
      final response = await _apiClient.dio.delete(
        ApiEndpoints.unsubscribeFromPublicVehicle,
        data: {'imei': imei},
      );

      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Get all subscriptions for current user
  Future<List<Map<String, dynamic>>> getMySubscriptions() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getMyPublicVehicleSubscriptions,
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> subscriptionsJson = response.data['data'] as List;
        return subscriptionsJson
            .map((json) => json as Map<String, dynamic>)
            .toList();
      }
      throw Exception(
        'Failed to get subscriptions: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Update subscription location
  Future<Map<String, dynamic>> updateSubscriptionLocation(
    int subscriptionId,
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.updatePublicVehicleSubscriptionLocation
            .replaceAll(':subscriptionId', subscriptionId.toString()),
        data: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        },
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(
        'Failed to update subscription: ${response.data['message'] ?? 'Unknown error'}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}

