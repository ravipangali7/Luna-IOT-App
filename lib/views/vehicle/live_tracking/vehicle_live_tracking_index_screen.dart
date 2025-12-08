import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/vehicle_controller.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/services/vehicle_service.dart';
import 'package:luna_iot/utils/vehicle_image_state.dart';
import 'package:luna_iot/widgets/language_switch_widget.dart';
import 'package:luna_iot/widgets/loading_widget.dart';
import 'package:luna_iot/widgets/satellite_connection_status_widget.dart';
import 'package:luna_iot/widgets/vehicle/vehicle_card.dart';

class VehicleLiveTrackingIndexScreen extends StatefulWidget {
  const VehicleLiveTrackingIndexScreen({super.key});

  @override
  State<VehicleLiveTrackingIndexScreen> createState() =>
      _VehicleLiveTrackingIndexScreenState();
}

class _VehicleLiveTrackingIndexScreenState
    extends State<VehicleLiveTrackingIndexScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isLoadingVehicles = false;
  String? _errorMessage;

  Set<Marker> _markers = {};
  final VehicleController _vehicleController = Get.find<VehicleController>();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    // Observe vehicles changes and update markers
    ever(_vehicleController.vehicles, (_) {
      if (mounted && _currentPosition != null) {
        _updateMarkers();
      }
    });
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
          _errorMessage =
              'Location services are disabled. Please enable them in settings.';
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
          _errorMessage =
              'Location permissions are permanently denied. Please enable in settings.';
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
            14.0,
          ),
        );
      }

      // Load vehicles and update markers after getting location
      _loadVehiclesAndUpdateMarkers();
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

  Future<void> _loadVehiclesAndUpdateMarkers() async {
    setState(() {
      _isLoadingVehicles = true;
    });

    try {
      // Wait a bit for vehicles to load if they're still loading
      if (_vehicleController.loading.value) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Update markers with current vehicles
      await _updateMarkers();
    } catch (e) {
      debugPrint('Error loading vehicles: ${e.toString()}');
      Get.snackbar(
        'Error',
        'Failed to load vehicles: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingVehicles = false;
        });
      }
    }
  }

  Future<void> _updateMarkers() async {
    debugPrint('=== UPDATE MARKERS START ===');
    debugPrint('Total vehicles: ${_vehicleController.vehicles.length}');

    final Set<Marker> newMarkers = {};
    int markersCreated = 0;
    int skippedNoLocation = 0;

    for (final vehicle in _vehicleController.vehicles) {
      final location = vehicle.latestLocation;

      if (location == null) {
        debugPrint('Vehicle ${vehicle.imei} has no location - skipping marker');
        skippedNoLocation++;
        continue;
      }

      if (location.latitude == null || location.longitude == null) {
        debugPrint(
            'Vehicle ${vehicle.imei} has null lat/lng - skipping marker');
        skippedNoLocation++;
        continue;
      }

      final lat = location.latitude!;
      final lng = location.longitude!;

      // Skip if coordinates are invalid (0,0)
      if (lat == 0.0 && lng == 0.0) {
        debugPrint('Vehicle ${vehicle.imei} has invalid coordinates - skipping marker');
        skippedNoLocation++;
        continue;
      }

      debugPrint('Creating marker for vehicle ${vehicle.imei} at: $lat, $lng');

      // Get vehicle state for marker icon
      final vehicleState = VehicleService.getState(vehicle);
      debugPrint('Vehicle state: $vehicleState');

      // Get vehicle image path for map marker
      final markerImagePath = VehicleService.imagePath(
        vehicleType: vehicle.vehicleType ?? 'truck',
        vehicleState: vehicleState,
        imageState: VehicleImageState.live,
      );
      debugPrint('Vehicle image path: $markerImagePath');

      // Load custom marker icon
      BitmapDescriptor markerIcon;
      try {
        markerIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(60, 60)),
          markerImagePath,
        );
        debugPrint('Custom marker icon loaded successfully');
      } catch (e) {
        debugPrint('Failed to load custom marker icon: $e, using default');
        // Fallback to default green marker
        markerIcon = BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        );
      }

      newMarkers.add(
        Marker(
          markerId: MarkerId(vehicle.imei),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: vehicle.name ?? vehicle.vehicleNo ?? 'Vehicle',
            snippet: vehicle.vehicleNo ?? vehicle.imei,
          ),
          icon: markerIcon,
          onTap: () {
            _showVehicleBottomSheet(vehicle);
          },
        ),
      );
      markersCreated++;
    }

    debugPrint('=== MARKERS SUMMARY ===');
    debugPrint('Markers created: $markersCreated');
    debugPrint('Markers skipped (no location): $skippedNoLocation');
    debugPrint('Total markers in set: ${newMarkers.length}');

    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }

    debugPrint('=== UPDATE MARKERS END ===');
  }

  void _showVehicleBottomSheet(Vehicle vehicle) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Vehicle Card
              VehicleCard(
                givenVehicle: vehicle,
                isManualCallback: true,
                callback: () {
                  // This callback is called when vehicle card is tapped
                  // We can handle it if needed, or leave empty
                },
              ),

              const SizedBox(height: 16),

              // Live Tracking Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    final route = AppRoutes.vehicleLiveTrackingShow
                        .replaceAll(':imei', vehicle.imei);
                    Get.toNamed(route);
                  },
                  icon: const Icon(Icons.location_on),
                  label: const Text('Live Tracking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'live_tracking'.tr,
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
        actions: [
          const LanguageSwitchWidget(),
          SizedBox(width: 10),
          SatelliteConnectionStatusWidget(
            tooltip: 'connection_status'.tr,
            onTap: () {},
          ),
          SizedBox(width: 10),
          if (_isLoadingVehicles)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _vehicleController.loadVehiclesPaginated();
                _loadVehiclesAndUpdateMarkers();
              },
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingWidget())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 64),
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
                  ? const Center(child: Text('No location data'))
                  : Obx(() {
                      // Show loading if vehicles are loading
                      if (_vehicleController.loading.value) {
                        return Stack(
                          children: [
                            GoogleMap(
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
                              markers: _markers,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              mapToolbarEnabled: false,
                              compassEnabled: true,
                              zoomGesturesEnabled: true,
                              zoomControlsEnabled: true,
                              mapType: MapType.normal,
                            ),
                            Container(
                              color: Colors.black.withOpacity(0.3),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text(
                                      'Loading vehicles...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      // Show empty state if no vehicles
                      if (_vehicleController.vehicles.isEmpty) {
                        return Stack(
                          children: [
                            GoogleMap(
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
                              markers: _markers,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              mapToolbarEnabled: false,
                              compassEnabled: true,
                              zoomGesturesEnabled: true,
                              zoomControlsEnabled: true,
                              mapType: MapType.normal,
                            ),
                            Center(
                              child: Text(
                                'no_vehicles_found'.tr,
                                style: TextStyle(
                                  color: AppTheme.subTitleColor,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      // Show map with markers
                      return Stack(
                        children: [
                          GoogleMap(
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
                            markers: _markers,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            mapToolbarEnabled: false,
                            compassEnabled: true,
                            zoomGesturesEnabled: true,
                            zoomControlsEnabled: true,
                            mapType: MapType.normal,
                          ),
                          // Loading overlay for vehicles
                          if (_isLoadingVehicles)
                            Container(
                              color: Colors.black.withOpacity(0.3),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text(
                                      'Loading vehicles...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    }),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
