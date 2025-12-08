import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:luna_iot/api/services/garbage_api_service.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/models/location_model.dart';
import 'package:luna_iot/models/status_model.dart';
import 'package:luna_iot/services/vehicle_service.dart';
import 'package:luna_iot/utils/vehicle_image_state.dart';
import 'package:luna_iot/widgets/loading_widget.dart';
import 'package:luna_iot/widgets/vehicle/vehicle_card.dart';

class GarbageIndexScreen extends StatefulWidget {
  const GarbageIndexScreen({super.key});

  @override
  State<GarbageIndexScreen> createState() => _GarbageIndexScreenState();
}

class _GarbageIndexScreenState extends State<GarbageIndexScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isLoadingVehicles = false;
  String? _errorMessage;
  
  List<Map<String, dynamic>> _garbageVehiclesData = [];
  Set<Marker> _markers = {};
  Set<String> _subscribedImeis = {}; // Track subscribed vehicles by IMEI
  bool _isSubscribing = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    try {
      final garbageApiService = Get.find<GarbageApiService>();
      final subscriptions = await garbageApiService.getMySubscriptions();
      setState(() {
        _subscribedImeis = subscriptions
            .map((sub) => sub['vehicle_imei'] as String)
            .toSet();
      });
    } catch (e) {
      debugPrint('Error loading subscriptions: $e');
    }
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
            14.0,
          ),
        );
      }

      // Load garbage vehicles after getting location
      _loadGarbageVehicles();
      _loadSubscriptions();
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

  Future<void> _loadGarbageVehicles() async {
    setState(() {
      _isLoadingVehicles = true;
    });

    try {
      final garbageApiService = Get.find<GarbageApiService>();
      final vehiclesData = await garbageApiService.getGarbageVehiclesWithLocations();

      debugPrint('=== GARBAGE VEHICLES DATA ===');
      debugPrint('Total vehicles data received: ${vehiclesData.length}');
      
      for (int i = 0; i < vehiclesData.length; i++) {
        final data = vehiclesData[i];
        debugPrint('--- Vehicle Data $i ---');
        debugPrint('Institute: ${data['institute']}');
        debugPrint('Vehicle: ${data['vehicle']}');
        debugPrint('Location: ${data['location']}');
        
        final vehicle = data['vehicle'] as Vehicle;
        final location = data['location'] as Location?;
        debugPrint('Vehicle IMEI: ${vehicle.imei}');
        debugPrint('Vehicle Name: ${vehicle.name}');
        debugPrint('Vehicle No: ${vehicle.vehicleNo}');
        if (location != null) {
          debugPrint('Location Latitude: ${location.latitude}');
          debugPrint('Location Longitude: ${location.longitude}');
        } else {
          debugPrint('Location: NULL');
        }
      }

      setState(() {
        _garbageVehiclesData = vehiclesData;
        _isLoadingVehicles = false;
      });

      debugPrint('=== UPDATING MARKERS ===');
      debugPrint('Vehicles data count: ${_garbageVehiclesData.length}');
      await _updateMarkers();
    } catch (e) {
      debugPrint('=== ERROR LOADING GARBAGE VEHICLES ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      setState(() {
        _isLoadingVehicles = false;
      });
      Get.snackbar(
        'Error',
        'Failed to load garbage vehicles: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<void> _updateMarkers() async {
    debugPrint('=== UPDATE MARKERS START ===');
    debugPrint('Total vehicles data: ${_garbageVehiclesData.length}');
    
    final Set<Marker> newMarkers = {};
    int markersCreated = 0;
    int skippedNoLocation = 0;

    for (int i = 0; i < _garbageVehiclesData.length; i++) {
      final vehicleData = _garbageVehiclesData[i];
      debugPrint('--- Processing vehicle $i ---');
      
      final vehicle = vehicleData['vehicle'] as Vehicle;
      final location = vehicleData['location'] as Location?;

      debugPrint('Vehicle IMEI: ${vehicle.imei}');
      debugPrint('Vehicle Name: ${vehicle.name}');
      debugPrint('Location object: $location');
      
      if (location == null) {
        debugPrint('Location is NULL - skipping marker');
        skippedNoLocation++;
        continue;
      }

      debugPrint('Location latitude: ${location.latitude}');
      debugPrint('Location longitude: ${location.longitude}');

      if (location.latitude != null && location.longitude != null) {
        final lat = location.latitude!;
        final lng = location.longitude!;
        
        debugPrint('Creating marker at: $lat, $lng');

        // Get vehicle state for marker icon
        // Create a temporary vehicle object with location and status for state calculation
        final tempVehicle = Vehicle(imei: vehicle.imei);
        tempVehicle.name = vehicle.name;
        tempVehicle.vehicleNo = vehicle.vehicleNo;
        tempVehicle.vehicleType = vehicle.vehicleType;
        tempVehicle.latestLocation = location;
        
        // If we have status data, use it; otherwise create minimal status
        if (vehicle.latestStatus != null) {
          tempVehicle.latestStatus = vehicle.latestStatus;
        } else {
          // Create minimal status for state calculation
          tempVehicle.latestStatus = Status(
            imei: vehicle.imei,
            battery: 0,
            signal: 0,
            charging: false,
            ignition: false,
            relay: false,
            createdAt: location.createdAt ?? DateTime.now(),
            updatedAt: location.updatedAt ?? DateTime.now(),
          );
        }
        
        final vehicleState = VehicleService.getState(tempVehicle);
        debugPrint('Vehicle state: $vehicleState');
        
        // Get vehicle image path for map marker (use actual vehicle type and 'live' state)
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
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        }

        newMarkers.add(
          Marker(
            markerId: MarkerId(vehicle.imei),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: vehicle.name ?? vehicle.vehicleNo ?? 'Garbage Vehicle',
              snippet: vehicle.vehicleNo ?? vehicle.imei,
            ),
            icon: markerIcon,
            onTap: () {
              _showVehicleBottomSheet(vehicleData);
            },
          ),
        );
        markersCreated++;
      } else {
        debugPrint('Location lat/lng is null - skipping marker');
        skippedNoLocation++;
      }
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

  void _showVehicleBottomSheet(Map<String, dynamic> vehicleData) {
    final institute = vehicleData['institute'] as Map<String, dynamic>;
    final vehicle = vehicleData['vehicle'] as Vehicle;
    final location = vehicleData['location'] as Location?;
    
    // Update vehicle with location data for VehicleCard
    if (location != null) {
      vehicle.latestLocation = location;
    }

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
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

            // Institute Details Section
            _buildInstituteCard(institute),

            const SizedBox(height: 16),

            // Vehicle Card - Use the full VehicleCard widget
            VehicleCard(
              givenVehicle: vehicle,
              isManualCallback: true,
              callback: () {
                // This callback is called when vehicle card is tapped
                // We can handle it if needed, or leave empty
              },
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      final route = AppRoutes.vehicleLiveTrackingShow
                          .replaceAll(':imei', vehicle.imei);
                      Get.toNamed(
                        route,
                        arguments: {'garbage': true},
                      );
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text('Live Tracking'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSubscribing ? null : () => _handleSetNotify(vehicle),
                    icon: Icon(
                      _subscribedImeis.contains(vehicle.imei)
                          ? Icons.notifications_active
                          : Icons.notifications,
                    ),
                    label: Text(
                      _subscribedImeis.contains(vehicle.imei)
                          ? 'Unsubscribe'
                          : 'Set Notify',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _subscribedImeis.contains(vehicle.imei)
                          ? Colors.green
                          : AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      disabledBackgroundColor: Colors.grey[300],
                      disabledForegroundColor: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _handleSetNotify(Vehicle vehicle) async {
    if (_currentPosition == null) {
      Get.snackbar(
        'Location Required',
        'Please enable location services to subscribe to notifications',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    setState(() {
      _isSubscribing = true;
    });

    try {
      final garbageApiService = Get.find<GarbageApiService>();
      final isSubscribed = _subscribedImeis.contains(vehicle.imei);

      if (isSubscribed) {
        // Unsubscribe
        await garbageApiService.unsubscribeFromVehicle(vehicle.imei);
        setState(() {
          _subscribedImeis.remove(vehicle.imei);
        });
        Get.snackbar(
          'Success',
          'Unsubscribed from ${vehicle.name}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        // Subscribe
        await garbageApiService.subscribeToVehicle(
          vehicle.imei,
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        setState(() {
          _subscribedImeis.add(vehicle.imei);
        });
        Get.snackbar(
          'Success',
          'Subscribed to ${vehicle.name}. You will receive notifications when the vehicle is within 300m.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      final isSubscribed = _subscribedImeis.contains(vehicle.imei);
      Get.snackbar(
        'Error',
        'Failed to ${isSubscribed ? 'unsubscribe' : 'subscribe'}: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() {
        _isSubscribing = false;
      });
    }
  }

  Widget _buildInstituteCard(Map<String, dynamic> institute) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Show logo if available, otherwise show icon
              institute['logo'] != null && institute['logo'].toString().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        institute['logo'],
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.business,
                          size: 20,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.business,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  institute['name'] ?? 'Unknown Institute',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.titleColor,
                  ),
                ),
              ),
            ],
          ),
          if (institute['phone'] != null && institute['phone'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 16,
                  color: AppTheme.subTitleColor,
                ),
                const SizedBox(width: 8),
                Text(
                  institute['phone'],
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.subTitleColor,
                  ),
                ),
              ],
            ),
          ],
          if (institute['address'] != null && institute['address'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppTheme.subTitleColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    institute['address'],
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.subTitleColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Garbage Vehicles',
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
        actions: [
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
              onPressed: _loadGarbageVehicles,
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
                  ? const Center(child: Text('No location data'))
                  : Stack(
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
                                    'Loading garbage vehicles...',
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
                    ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

