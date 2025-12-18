import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:luna_iot/api/services/community_siren_api_service.dart';
import 'package:luna_iot/models/community_siren_model.dart';
import 'package:luna_iot/controllers/auth_controller.dart';

class SmartCommunityController extends GetxController {
  final CommunitySirenApiService _apiService;
  final AudioPlayer _countdownPlayer = AudioPlayer();

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxBool hasAccess = false.obs;
  final Rx<CommunitySirenAccess?> accessData = Rx<CommunitySirenAccess?>(null);
  final RxString errorMessage = ''.obs;
  final RxInt countdown = 5.obs;
  final RxBool isCountdownActive = false.obs;
  
  // Current location
  final RxDouble currentLatitude = 0.0.obs;
  final RxDouble currentLongitude = 0.0.obs;

  SmartCommunityController(this._apiService);

  /// Check if user has access to smart community
  Future<void> checkAccess() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final access = await _apiService.checkMemberAccess();
      accessData.value = access;
      hasAccess.value = access.hasAccess;
    } catch (e) {
      errorMessage.value = e.toString();
      hasAccess.value = false;
      accessData.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Start 5-second countdown
  Future<bool> startCountdown() async {
    if (isCountdownActive.value) return false;

    isCountdownActive.value = true;
    countdown.value = 5;

    // Play initial beep
    await playCountdownBeep();

    final completer = Completer<bool>();

    Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        countdown.value--;

        if (countdown.value > 0) {
          // Play beep for each countdown
          playCountdownBeep();
        } else {
          // Countdown finished
          timer.cancel();
          stopCountdownSound();
          isCountdownActive.value = false;
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        }
      },
    );

    return completer.future;
  }

  /// Cancel countdown
  void cancelCountdown() {
    isCountdownActive.value = false;
    countdown.value = 5;
    stopCountdownSound();
  }

  /// Play countdown beep sound
  Future<void> playCountdownBeep() async {
    try {
      await _countdownPlayer.stop();
      await _countdownPlayer.play(AssetSource('sounds/sos.mp3'));
    } catch (e) {
      print('Error playing countdown beep: $e');
      // Continue without sound if there's an error
    }
  }

  /// Stop countdown sound
  Future<void> stopCountdownSound() async {
    try {
      await _countdownPlayer.stop();
    } catch (e) {
      print('Error stopping countdown sound: $e');
    }
  }

  /// Check location permission and request if needed
  /// Throws exceptions with specific messages to indicate what action UI should take
  Future<bool> checkLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationPermissionException(
          'location_services_disabled'.tr,
          openLocationSettings: true,
        );
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw LocationPermissionException(
            'location_permission_denied'.tr,
            openLocationSettings: false,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationPermissionException(
          'location_permission_permanently_denied'.tr,
          openAppSettings: true,
        );
      }

      // Permission granted
      return true;
    } catch (e) {
      if (e is LocationPermissionException) {
        rethrow;
      }
      throw LocationPermissionException(
        '${'failed_to_check_location_permission'.tr}: ${e.toString()}',
        openLocationSettings: false,
      );
    }
  }

  /// Get current location with permission handling
  Future<void> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('location_services_disabled'.tr);
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('location_permission_denied'.tr);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('location_permission_permanently_denied'.tr);
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      currentLatitude.value = position.latitude;
      currentLongitude.value = position.longitude;
    } catch (e) {
      throw Exception('${'failed_to_get_location'.tr}: ${e.toString()}');
    }
  }

  /// Create community siren history (SOS alert)
  /// Location must be obtained before calling this method
  Future<void> createSosHistory() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Ensure location is available
      if (currentLatitude.value == 0.0 || currentLongitude.value == 0.0) {
        throw Exception('Location is required. Please enable location services.');
      }

      final access = accessData.value;
      if (access == null || !access.hasAccess || access.institute == null) {
        throw Exception('No access to smart community');
      }

      final user = Get.find<AuthController>().currentUser.value;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final institute = access.institute;
      if (institute == null) {
        throw Exception('Institute not found');
      }

      final history = CommunitySirenHistoryCreate(
        source: 'app',
        name: user.name.isNotEmpty ? user.name : user.phone,
        primaryPhone: user.phone,
        latitude: currentLatitude.value,
        longitude: currentLongitude.value,
        datetime: DateTime.now().toIso8601String(),
        status: 'pending',
        institute: institute.id,
        member: user.id,
      );

      await _apiService.createCommunitySirenHistory(history);
    } catch (e) {
      errorMessage.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get current user ID
  int? getCurrentUserId() {
    final user = Get.find<AuthController>().currentUser.value;
    return user?.id;
  }

  @override
  void onClose() {
    _countdownPlayer.dispose();
    super.onClose();
  }
}

/// Custom exception for location permission errors
class LocationPermissionException implements Exception {
  final String message;
  final bool openLocationSettings;
  final bool openAppSettings;

  LocationPermissionException(
    this.message, {
    this.openLocationSettings = false,
    this.openAppSettings = false,
  });

  @override
  String toString() => message;
}

