import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/vehicle_api_service.dart';

class SetAreaModal extends StatefulWidget {
  const SetAreaModal({super.key});

  @override
  State<SetAreaModal> createState() => _SetAreaModalState();
}

class _SetAreaModalState extends State<SetAreaModal> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // 1km radius in meters
  static const double _radiusMeters = 1000.0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled. Please enable them in settings.';
          _isLoading = false;
        });
        Get.snackbar(
          'Location Services Disabled',
          'Location services are currently disabled. Tap to open settings.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 5),
          onTap: (_) async {
            await Geolocator.openLocationSettings();
          },
        );
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permission denied.';
            _isLoading = false;
          });
          Get.snackbar(
            'Permission Denied',
            'Location permission denied',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permissions are permanently denied. Please enable in settings.';
          _isLoading = false;
        });
        Get.snackbar(
          'Permission Denied',
          'Location permissions are permanently denied. Please enable in settings.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 5),
          onTap: (_) async {
            await Geolocator.openAppSettings();
          },
        );
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      // Move camera to current location
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            14.0, // Zoom level to show ~1km radius
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get location: ${e.toString()}';
        _isLoading = false;
      });
      Get.snackbar(
        'Error',
        'Failed to get current location',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<void> _saveLocation() async {
    if (_currentPosition == null) {
      Get.snackbar(
        'Error',
        'No location available',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final apiClient = Get.find<ApiClient>();
      final vehicleApiService = VehicleApiService(apiClient);

      await vehicleApiService.updateMySchoolLocation(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      // Close dialog first, then show snackbar
      Get.back(result: {
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
      });

      // Show success snackbar after dialog closes
      Get.snackbar(
        'Success',
        'Location updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save location: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Set<Circle> _getGeofenceCircle() {
    if (_currentPosition == null) return {};

    return {
      Circle(
        circleId: const CircleId('geofence'),
        center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        radius: _radiusMeters,
        strokeWidth: 2,
        strokeColor: AppTheme.primaryColor,
        fillColor: AppTheme.primaryColor.withOpacity(0.2),
      ),
    };
  }

  Set<Marker> _getMarkers() {
    if (_currentPosition == null) return {};

    return {
      Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: '1km radius geofence area',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Set Area (1km Radius)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.titleColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(
                      Icons.close,
                      color: AppTheme.subTitleColor,
                    ),
                  ),
                ],
              ),
            ),

            // Map or Loading/Error
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Getting your location...',
                            style: TextStyle(
                              color: AppTheme.subTitleColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.subTitleColor,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _getCurrentLocation,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _currentPosition == null
                          ? const Center(
                              child: Text('No location data'),
                            )
                          : GoogleMap(
                              onMapCreated: (GoogleMapController controller) {
                                _mapController = controller;
                                // Move camera to current location
                                controller.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                    LatLng(
                                      _currentPosition!.latitude,
                                      _currentPosition!.longitude,
                                    ),
                                    14.0,
                                  ),
                                );
                              },
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                zoom: 14.0,
                              ),
                              markers: _getMarkers(),
                              circles: _getGeofenceCircle(),
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              mapType: MapType.normal,
                            ),
            ),

            // Info and Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Info text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'The circular area shows a 1km radius from your current location. This will be saved as your geofenced area.',
                            style: TextStyle(
                              color: AppTheme.subTitleColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () => Get.back(),
                          child: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSaving || _currentPosition == null
                              ? null
                              : _saveLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Save Location'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

