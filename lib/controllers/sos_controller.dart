import 'dart:math' show cos, sqrt, asin, sin, pi, min, max;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:luna_iot/api/services/alert_system_api_service.dart';
import 'package:luna_iot/models/alert_geofence_model.dart';
import 'package:luna_iot/models/alert_type_model.dart';
import 'package:luna_iot/controllers/auth_controller.dart';

class SosController extends GetxController {
  final AlertSystemApiService _alertSystemApiService;

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

  // Current user location
  final RxDouble currentLatitude = 0.0.obs;
  final RxDouble currentLongitude = 0.0.obs;

  // SOS Process Stages
  static const List<String> progressStages = [
    'Getting your location...',
    'Checking service availability...',
    'Loading emergency services...',
    'Calculating nearest facility...',
    'Sending alert...',
  ];

  // Initialize SOS process
  Future<void> startSosProcess() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Stage 1: Get location (0-20%)
      await _updateProgress(0.0, progressStages[0]);
      await _getCurrentLocation();

      // Stage 2: Check service availability (20-40%)
      await _updateProgress(0.2, progressStages[1]);
      await _fetchAlertGeofences();

      // Stage 3: Check if location is in any geofence (40-60%)
      await _updateProgress(0.4, progressStages[2]);
      final matchingGeofences = _findMatchingGeofences(
        currentLatitude.value,
        currentLongitude.value,
      );

      if (matchingGeofences.isEmpty) {
        throw Exception(
          'No emergency service available in your area. Please contact authorities directly.',
        );
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
      await _updateProgress(0.6, progressStages[3]);
      final filteredGeofences = _filterGeofencesByAlertType(selectedAlertType);
      final nearestInstitute = _findNearestInstitute(
        currentLatitude.value,
        currentLongitude.value,
        filteredGeofences,
      );

      // Stage 5: Send alert (80-100%)
      await _updateProgress(0.8, progressStages[4]);
      await _createSosAlert(selectedAlertType, nearestInstitute);

      await _updateProgress(1.0, 'Alert sent successfully!');

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
        throw Exception(
          'Location services are disabled. Please enable location services in your device settings.',
        );
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(
            'Location permission denied. Please grant location permission to use SOS feature.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permissions are permanently denied. Please enable location permission in app settings.',
        );
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      currentLatitude.value = position.latitude;
      currentLongitude.value = position.longitude;
    } catch (e) {
      throw Exception('Failed to get location: ${e.toString()}');
    }
  }

  // Fetch all alert geofences from backend
  Future<void> _fetchAlertGeofences() async {
    try {
      allGeofences.value = await _alertSystemApiService.getAlertGeofences();
    } catch (e) {
      throw Exception('Failed to load emergency services: ${e.toString()}');
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
      throw Exception(
        'No emergency services available for the selected alert type.',
      );
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
        throw Exception(
          'User not logged in. Please log in to use SOS feature.',
        );
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
      throw Exception('Failed to send alert: ${e.toString()}');
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
}
