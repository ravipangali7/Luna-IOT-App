import 'dart:math' show cos, sqrt, asin, sin, pi, min, max;
import 'package:audioplayers/audioplayers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:luna_iot/api/services/alert_system_api_service.dart';
import 'package:luna_iot/models/alert_geofence_model.dart';
import 'package:luna_iot/models/alert_type_model.dart';
import 'package:luna_iot/controllers/auth_controller.dart';

class SosController extends GetxController {
  final AlertSystemApiService _alertSystemApiService;
  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioPlayer? _countdownPlayer; // Track countdown audio player

  SosController(this._alertSystemApiService);

  // Observable variables for UI updates
  final RxDouble progress = 0.0.obs;
  final RxString progressMessage = ''.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Data storage
  final RxList<AlertGeofence> allGeofences = <AlertGeofence>[].obs;
  final RxList<AlertType> availableAlertTypes = <AlertType>[].obs;
  final RxList<AlertGeofence> matchingGeofences = <AlertGeofence>[].obs;
  final RxString selectedInstituteName = ''.obs;

  // Current user location
  final RxDouble currentLatitude = 0.0.obs;
  final RxDouble currentLongitude = 0.0.obs;

  // SOS Process Stages
  static const List<String> progressStages = [
    'getting_your_location',
    'checking_service_availability',
    'loading_emergency_services',
    'calculating_nearest_facility',
    'sending_alert',
  ];

  // Initialize SOS process
  Future<void> startSosProcess() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Stage 1: Get location (0-20%)
      await _updateProgress(0.0, progressStages[0].tr);
      await _getCurrentLocation();

      // Stage 2: Check service availability (20-40%)
      await _updateProgress(0.2, progressStages[1].tr);
      await fetchAlertGeofences();

      // Stage 3: Check if location is in any geofence (40-60%)
      await _updateProgress(0.4, progressStages[2].tr);
      final matchingGeofences = _findMatchingGeofences(
        currentLatitude.value,
        currentLongitude.value,
      );

      if (matchingGeofences.isEmpty) {
        throw Exception('no_emergency_service_available'.tr);
      }

      this.matchingGeofences.value = matchingGeofences;

      // Extract unique alert types
      final uniqueAlertTypes = _getUniqueAlertTypes(matchingGeofences);
      availableAlertTypes.value = uniqueAlertTypes;

      // Close progress dialog - user will select alert type
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = e.toString();
      rethrow;
    }
  }

  // Continue SOS process after alert type selection
  Future<void> continueSosProcess(AlertType selectedAlertType) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Stage 4: Calculate nearest facility (60-80%)
      await _updateProgress(0.6, progressStages[3].tr);
      final filteredGeofences = _filterGeofencesByAlertType(selectedAlertType);
      final nearestInstitute = _findNearestInstitute(
        currentLatitude.value,
        currentLongitude.value,
        filteredGeofences,
      );

      // Stage 5: Send alert (80-100%)
      await _updateProgress(0.8, progressStages[4].tr);
      await _createSosAlert(selectedAlertType, nearestInstitute);

      await _updateProgress(1.0, 'alert_sent_successfully'.tr);

      // Set loading to false - UI will handle cleanup
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = e.toString();
      rethrow;
    }
  }

  // Get current location with permission handling
  Future<void> _getCurrentLocation() async {
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
        timeLimit: Duration(seconds: 10),
      );

      currentLatitude.value = position.latitude;
      currentLongitude.value = position.longitude;
    } catch (e) {
      throw Exception('${'failed_to_get_location'.tr}: ${e.toString()}');
    }
  }

  // Fetch all alert geofences from backend
  Future<void> fetchAlertGeofences() async {
    try {
      allGeofences.value = await _alertSystemApiService.getAlertGeofences();
    } catch (e) {
      throw Exception(
        '${'failed_to_load_emergency_services'.tr}: ${e.toString()}',
      );
    }
  }

  // Find geofences that contain the given point
  List<AlertGeofence> _findMatchingGeofences(double lat, double lng) {
    return allGeofences.where((geofence) {
      try {
        final boundaryPoints = geofence.getBoundaryPoints();
        return isPointInPolygon(lat, lng, boundaryPoints);
      } catch (e) {
        print('Error checking geofence ${geofence.id}: $e');
        return false;
      }
    }).toList();
  }

  // Point-in-polygon check using ray casting algorithm
  bool isPointInPolygon(double lat, double lng, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    int intersectCount = 0;
    for (int i = 0; i < polygon.length; i++) {
      final p1 = polygon[i];
      final p2 = polygon[(i + 1) % polygon.length];

      if (lat > min(p1.latitude, p2.latitude) &&
          lat <= max(p1.latitude, p2.latitude) &&
          lng <= max(p1.longitude, p2.longitude)) {
        final xIntersection =
            (lat - p1.latitude) *
                (p2.longitude - p1.longitude) /
                (p2.latitude - p1.latitude) +
            p1.longitude;

        if (p1.longitude == p2.longitude || lng <= xIntersection) {
          intersectCount++;
        }
      }
    }
    return intersectCount % 2 != 0;
  }

  // Get unique alert types from matching geofences
  List<AlertType> _getUniqueAlertTypes(List<AlertGeofence> geofences) {
    final Set<AlertType> uniqueTypes = {};
    for (final geofence in geofences) {
      uniqueTypes.addAll(geofence.alertTypes);
    }
    return uniqueTypes.toList();
  }

  // Filter geofences by selected alert type
  List<AlertGeofence> _filterGeofencesByAlertType(AlertType alertType) {
    return matchingGeofences.where((geofence) {
      return geofence.alertTypes.any((type) => type.id == alertType.id);
    }).toList();
  }

  // Find nearest institute using Haversine formula
  AlertGeofence _findNearestInstitute(
    double userLat,
    double userLng,
    List<AlertGeofence> geofences,
  ) {
    if (geofences.isEmpty) {
      throw Exception('no_emergency_services_for_alert_type'.tr);
    }

    AlertGeofence nearest = geofences.first;
    double minDistance = double.infinity;

    for (final geofence in geofences) {
      if (geofence.instituteLatitude != null &&
          geofence.instituteLongitude != null) {
        final distance = calculateDistance(
          userLat,
          userLng,
          geofence.instituteLatitude!,
          geofence.instituteLongitude!,
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearest = geofence;
        }
      }
    }

    return nearest;
  }

  // Calculate distance between two points using Haversine formula
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371.0; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  // Create SOS alert
  Future<void> _createSosAlert(
    AlertType alertType,
    AlertGeofence nearestInstitute,
  ) async {
    try {
      // Get current user info
      final authController = Get.find<AuthController>();
      final currentUser = authController.currentUser.value;

      if (currentUser == null) {
        throw Exception('user_not_logged_in'.tr);
      }

      await _alertSystemApiService.createSosAlert(
        name: currentUser.name,
        primaryPhone: currentUser.phone,
        alertType: alertType.id,
        latitude: currentLatitude.value,
        longitude: currentLongitude.value,
        institute: nearestInstitute.institute,
      );
    } catch (e) {
      throw Exception('${'failed_to_send_alert'.tr}: ${e.toString()}');
    }
  }

  // Update progress and message
  Future<void> _updateProgress(double progressValue, String message) async {
    progress.value = progressValue;
    progressMessage.value = message;
    await Future.delayed(
      Duration(milliseconds: 500),
    ); // Smooth progress animation
  }

  // Reset progress state
  void resetProgress() {
    progress.value = 0.0;
    progressMessage.value = '';
    isLoading.value = false;
    errorMessage.value = '';
    allGeofences.clear();
    availableAlertTypes.clear();
    matchingGeofences.clear();
    currentLatitude.value = 0.0;
    currentLongitude.value = 0.0;
  }

  // Get current progress percentage for UI
  int get progressPercentage => (progress.value * 100).round();

  // Check if SOS process is ready for alert type selection
  bool get isReadyForAlertTypeSelection =>
      !isLoading.value &&
      availableAlertTypes.isNotEmpty &&
      errorMessage.value.isEmpty;

  // Get error message for display
  String get displayErrorMessage => errorMessage.value;

  // Get available alert types for selection
  List<AlertType> get alertTypesForSelection => availableAlertTypes;

  // Get matching geofences count
  int get matchingGeofencesCount => matchingGeofences.length;

  // NEW FLOW: Process SOS with alert type from 0-99%
  Future<Map<String, dynamic>> processSosToNinetyNine(
    AlertType alertType,
  ) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Stage 1: Get location (0-20%)
      await _updateProgress(0.0, progressStages[0].tr);
      await _getCurrentLocation();

      // Stage 2: Check service availability (20-40%)
      await _updateProgress(0.2, progressStages[1].tr);
      await fetchAlertGeofences();

      // Stage 3: Check if location is in any geofence (40-60%)
      await _updateProgress(0.4, progressStages[2].tr);
      final matchingGeofences = _findMatchingGeofences(
        currentLatitude.value,
        currentLongitude.value,
      );

      if (matchingGeofences.isEmpty) {
        throw Exception('no_emergency_service_available'.tr);
      }

      this.matchingGeofences.value = matchingGeofences;

      // Stage 4: Calculate nearest facility (60-80%)
      await _updateProgress(
        0.6,
        '${'finding_nearest_facility'.tr} ${alertType.name}...',
      );
      final filteredGeofences = _filterGeofencesByAlertType(alertType);
      final nearestInstitute = _findNearestInstitute(
        currentLatitude.value,
        currentLongitude.value,
        filteredGeofences,
      );

      // Store institute name for display
      selectedInstituteName.value = nearestInstitute.instituteName;

      // Stage 5: Prepare for sending (80-99%)
      await _updateProgress(
        0.7,
        '${'found_institute'.tr}: ${nearestInstitute.instituteName}',
      );
      await Future.delayed(Duration(milliseconds: 500)); // Brief pause
      await _updateProgress(0.8, 'preparing_to_send_alert'.tr);
      await Future.delayed(Duration(milliseconds: 500)); // Brief pause
      await _updateProgress(0.99, 'ready_to_send_alert'.tr);

      // Return data needed for final send
      return {
        'nearestInstitute': nearestInstitute,
        'alertType': alertType,
        'latitude': currentLatitude.value,
        'longitude': currentLongitude.value,
      };
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = e.toString();
      rethrow;
    }
  }

  // NEW FLOW: Send final alert at 100%
  Future<void> sendFinalAlert(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;

      // Stage 6: Send alert (99-100%)
      await _updateProgress(0.99, progressStages[4].tr);
      await _createSosAlert(
        data['alertType'] as AlertType,
        data['nearestInstitute'] as AlertGeofence,
      );

      await _updateProgress(1.0, 'alert_sent_successfully'.tr);
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = e.toString();
      rethrow;
    }
  }

  // Check if location services are enabled
  Future<bool> checkLocationServices() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      return serviceEnabled;
    } catch (e) {
      print('Error checking location services: $e');
      return false;
    }
  }

  // Fetch all alert types from database (excluding "Help")
  Future<List<AlertType>> getAllAlertTypes() async {
    try {
      final alertTypes = await _alertSystemApiService.getAlertTypes();
      // Filter out "Help" alert type
      return alertTypes
          .where((type) => type.name.toLowerCase() != 'help')
          .toList();
    } catch (e) {
      print('Error fetching alert types: $e');
      return [];
    }
  }

  // Process location and match with geofences after alert type selection
  Future<Map<String, dynamic>> processLocationAndMatchGeofence(
    AlertType selectedAlertType,
  ) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Stage 1: Get location
      await _updateProgress(0.1, 'checking_location'.tr);
      await _getCurrentLocation();

      // Stage 2: Check service availability
      await _updateProgress(0.3, 'checking_service_availability'.tr);
      await fetchAlertGeofences();

      // Stage 3: Match with geofences
      await _updateProgress(0.5, 'matching_services'.tr);
      final matchingGeofences = _findMatchingGeofences(
        currentLatitude.value,
        currentLongitude.value,
      );

      if (matchingGeofences.isEmpty) {
        throw Exception('no_service_in_area'.tr);
      }

      this.matchingGeofences.value = matchingGeofences;

      // Stage 4: Filter by alert type and find nearest facility
      await _updateProgress(0.7, 'calculating_nearest_facility'.tr);
      final filteredGeofences = _filterGeofencesByAlertType(selectedAlertType);

      if (filteredGeofences.isEmpty) {
        throw Exception('no_emergency_services_for_alert_type'.tr);
      }

      final nearestInstitute = _findNearestInstitute(
        currentLatitude.value,
        currentLongitude.value,
        filteredGeofences,
      );

      // Store institute name for display
      selectedInstituteName.value = nearestInstitute.instituteName;

      // Stage 5: Prepare for sending (set without delay for immediate countdown)
      progress.value = 0.9;
      progressMessage.value = 'ready_to_send_alert'.tr;

      // Return data needed for final send
      return {
        'nearestInstitute': nearestInstitute,
        'alertType': selectedAlertType,
        'latitude': currentLatitude.value,
        'longitude': currentLongitude.value,
      };
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = e.toString();
      rethrow;
    }
  }

  // Play countdown beep (single play, not loop)
  Future<void> playCountdownBeep() async {
    try {
      // Stop and dispose previous player if exists
      await _countdownPlayer?.stop();
      await _countdownPlayer?.dispose();

      // Create and store new player
      _countdownPlayer = AudioPlayer();
      await _countdownPlayer!.play(AssetSource('sounds/sos.mp3'));
      // await _countdownPlayer!.play(AssetSource('sounds/sos.m4a'));
    } catch (e) {
      print('Error playing countdown beep: $e');
      // Continue without sound if there's an error
    }
  }

  // Stop countdown sound
  Future<void> stopCountdownSound() async {
    try {
      await _audioPlayer.stop();
      await _countdownPlayer?.stop();
      await _countdownPlayer?.dispose();
      _countdownPlayer = null;
    } catch (e) {
      print('Error stopping countdown sound: $e');
    }
  }

  // Helper method to clean error messages (remove "Exception: " prefix)
  String _cleanErrorMessage(dynamic error) {
    final errorStr = error.toString();
    if (errorStr.startsWith('Exception: ')) {
      return errorStr.substring(11); // Remove "Exception: " prefix
    }
    return errorStr;
  }

  // Get cleaned error message for display
  String getCleanErrorMessage(dynamic error) {
    return _cleanErrorMessage(error);
  }

  // Dispose audio player
  @override
  void onClose() {
    _audioPlayer.dispose();
    _countdownPlayer?.dispose();
    super.onClose();
  }
}
