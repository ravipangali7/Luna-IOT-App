import 'package:get/get.dart';
import '../models/geofence_model.dart';
import '../api/services/geofence_api_service.dart';

class GeofenceController extends GetxController {
  final GeofenceApiService _geofenceApiService = GeofenceApiService();

  final RxList<GeofenceModel> geofences = <GeofenceModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    getAllGeofences();
  }

  // Get all geofences
  Future<void> getAllGeofences() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final geofencesList = await _geofenceApiService.getAllGeofences();
      geofences.value = geofencesList;
    } catch (e) {
      errorMessage.value = e.toString();
      print('Error getting geofences: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Get geofences by IMEI
  Future<List<GeofenceModel>> getGeofencesByImei(String imei) async {
    try {
      return await _geofenceApiService.getGeofencesByImei(imei);
    } catch (e) {
      errorMessage.value = e.toString();
      print('Error getting geofences by IMEI: $e');
      return [];
    }
  }

  // Create geofence
  Future<bool> createGeofence({
    required String title,
    required GeofenceType type,
    required List<String> boundary,
    List<int>? vehicleIds,
    List<int>? userIds,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final newGeofence = await _geofenceApiService.createGeofence(
        title: title,
        type: type,
        boundary: boundary,
        vehicleIds: vehicleIds,
        userIds: userIds,
      );

      geofences.insert(0, newGeofence);

      // Clear any previous errors
      errorMessage.value = '';

      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      print('Error creating geofence: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update geofence
  Future<bool> updateGeofence({
    required int id,
    String? title,
    GeofenceType? type,
    List<String>? boundary,
    List<int>? vehicleIds,
    List<int>? userIds,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final updatedGeofence = await _geofenceApiService.updateGeofence(
        id: id,
        title: title,
        type: type,
        boundary: boundary,
        vehicleIds: vehicleIds,
        userIds: userIds,
      );

      final index = geofences.indexWhere((g) => g.id == id);
      if (index != -1) {
        geofences[index] = updatedGeofence;
      }

      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      print('Error updating geofence: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Delete geofence
  Future<bool> deleteGeofence(int id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _geofenceApiService.deleteGeofence(id);

      // Remove from local list
      geofences.removeWhere((g) => g.id == id);

      // Clear any previous errors
      errorMessage.value = '';

      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      print('Error deleting geofence: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Clear error message
  void clearError() {
    errorMessage.value = '';
  }
}
