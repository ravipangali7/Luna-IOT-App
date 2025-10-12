import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:luna_iot/api/services/relay_api_service.dart';
import 'package:luna_iot/api/api_client.dart';

class RelayController extends GetxController {
  late final RelayApiService _relayApiService;

  // Observable variables
  final isLoading = false.obs;
  final relayStatus = false.obs;
  final currentCommand = ''.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize API service
    _relayApiService = RelayApiService(Get.find<ApiClient>());
  }

  // Turn relay ON
  Future<void> turnRelayOn(String phone) async {
    try {
      isLoading.value = true;
      currentCommand.value = 'ON';
      errorMessage.value = '';

      // Send relay ON command
      final result = await _relayApiService.turnRelayOn(phone);

      if (result['success'] == true) {
        // Update relay status
        relayStatus.value = true;

        // Show success message
        Get.snackbar(
          'Success',
          'Relay turned ON successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );

        // Clear any error messages
        errorMessage.value = '';
      } else {
        // Handle error
        final message = result['message'] ?? 'Unknown error occurred';
        errorMessage.value = message;

        Get.snackbar(
          'Error',
          message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      print('Error turning relay ON: $e');
      errorMessage.value = 'Network error. Please check your connection.';

      Get.snackbar(
        'Error',
        'Network error. Please check your connection.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
      currentCommand.value = '';
    }
  }

  // Turn relay OFF
  Future<void> turnRelayOff(String phone) async {
    try {
      isLoading.value = true;
      currentCommand.value = 'OFF';
      errorMessage.value = '';

      // Send relay OFF command
      final result = await _relayApiService.turnRelayOff(phone);

      if (result['success'] == true) {
        // Update relay status
        relayStatus.value = false;

        // Show success message
        Get.snackbar(
          'Success',
          'Relay turned OFF successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );

        // Clear any error messages
        errorMessage.value = '';
      } else {
        // Handle error
        final message = result['message'] ?? 'Unknown error occurred';
        errorMessage.value = message;

        Get.snackbar(
          'Error',
          message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      print('Error turning relay OFF: $e');
      errorMessage.value = 'Network error. Please check your connection.';

      Get.snackbar(
        'Error',
        'Network error. Please check your connection.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
      currentCommand.value = '';
    }
  }

  // Initialize relay status from vehicle data
  void initializeRelayStatus(bool? vehicleRelayStatus) {
    if (vehicleRelayStatus != null) {
      relayStatus.value = vehicleRelayStatus;
    } else {
      relayStatus.value = false; // Default to OFF if no status available
    }
  }

  // Get current relay status (keeping for backward compatibility)
  Future<void> getRelayStatus(String imei) async {
    try {
      final result = await _relayApiService.getRelayStatus(imei);

      if (result['success'] == true) {
        final data = result['data'];
        if (data != null) {
          // Parse relay status from backend response
          final status = data['relayStatus'];
          if (status == 'ON') {
            relayStatus.value = true;
          } else if (status == 'OFF') {
            relayStatus.value = false;
          }
        }
      } else {
        print('Error getting relay status: ${result['message']}');
      }
    } catch (e) {
      print('Error getting relay status: $e');
    }
  }

  // Clear error message
  void clearErrorMessage() {
    errorMessage.value = '';
  }

  // Reset all states
  void reset() {
    isLoading.value = false;
    currentCommand.value = '';
    errorMessage.value = '';
  }
}
