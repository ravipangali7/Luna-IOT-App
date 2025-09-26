import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:luna_iot/api/services/vehicle_api_service.dart';
import 'package:luna_iot/app/app_routes.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/models/location_model.dart';
import 'package:luna_iot/models/status_model.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/services/geo_service.dart';
import 'package:luna_iot/services/socket_service.dart';
import 'package:luna_iot/services/vehicle_service.dart';
import 'package:luna_iot/utils/time_ago.dart';
import 'package:luna_iot/utils/vehicle_image_state.dart';
import 'package:luna_iot/widgets/loading_widget.dart';
import 'package:luna_iot/widgets/vehicle/speedometer_widget.dart';
import 'package:luna_iot/widgets/weather_modal_widget.dart';

class VehicleLiveTrackingShowScreen extends StatefulWidget {
  const VehicleLiveTrackingShowScreen({super.key, required this.imei});

  final String imei;

  @override
  State<VehicleLiveTrackingShowScreen> createState() =>
      _VehicleLiveTrackingShowScreenState();
}

class _VehicleLiveTrackingShowScreenState
    extends State<VehicleLiveTrackingShowScreen> {
  Vehicle vehicle = Vehicle(imei: '');
  bool isLoadingVehicle = true;

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> routePoints = [];
  LatLng? _vehiclePosition;
  BitmapDescriptor? _customMarkerIcon;

  String? vehicleState;
  String? vehicleImage;
  double _mapRotation = 0.0;
  MapType currentMapType = MapType.normal;

  // Socket service
  final SocketService _socketService = Get.find<SocketService>();

  // Real-time data
  Location? _currentLocation;
  Status? _currentStatus;
  bool _isTracking = false;
  bool isDisposed = false;
  String lastUpdateTime = '...';
  // Add this variable to store the last calculated time
  String _lastCalculatedTime = '...';
  DateTime? _lastCalculationTimestamp;

  // Add these variables to store the listeners
  Worker? _statusWorker;
  Worker? _locationWorker;

  // Add these variables for offline detection
  bool _showOfflineModal = false;
  Timer? _offlineCheckTimer;

  bool get isWeb => kIsWeb;
  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void didUpdateWidget(VehicleLiveTrackingShowScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if IMEI has changed
    if (oldWidget.imei != widget.imei) {
      _resetAndReinitialize();
    }
  }

  void _initializeScreen() {
    print('Initializing screen for IMEI: ${widget.imei}');
    _fetchVehicleData();
  }

  void _resetAndReinitialize() {
    print('Resetting and reinitializing for new IMEI: ${widget.imei}');
    // Stop current tracking
    _isTracking = false;
    _statusWorker?.dispose();
    _locationWorker?.dispose();
    _offlineCheckTimer?.cancel();

    // Reset state
    setState(() {
      vehicle = Vehicle(imei: '');
      _currentLocation = null;
      _currentStatus = null;
      _vehiclePosition = null;
      _markers.clear();
      _polylines.clear();
      routePoints.clear();
      isLoadingVehicle = true;
    });

    // Reinitialize with new IMEI
    _initializeScreen();
  }

  // Add this method to fetch vehicle data
  Future<void> _fetchVehicleData() async {
    try {
      print('Fetching vehicle data for IMEI: ${widget.imei}');
      setState(() {
        isLoadingVehicle = true;
      });

      // Call your vehicle API service
      final vehicleData = await Get.find<VehicleApiService>().getVehicleByImei(
        widget.imei,
      );

      print(
        'Fetched vehicle data: ${vehicleData.vehicleNo} (${vehicleData.imei})',
      );
      setState(() {
        vehicle = vehicleData;
        isLoadingVehicle = false;
      });

      // Initialize data after fetching
      if (vehicle != null) {
        _initializeVehicleData();
        _initializeMap();
        _startRealTimeTracking();
        _startOfflineCheck();
        _checkOfflineStatus();
      }
    } catch (e) {
      setState(() {
        isLoadingVehicle = false;
      });
      Get.snackbar('Error', 'Failed to load vehicle data: $e');
    }
  }

  // Initialize Map
  void _initializeMap() {
    final location = vehicle.latestLocation;
    if (location?.latitude != null && location?.longitude != null) {
      _vehiclePosition = LatLng(location!.latitude!, location.longitude!);
      _currentLocation = location;
      routePoints.add(_vehiclePosition!);
      _updateMarker();
      _updatePolyline();
    }
  }

  // Initialize Vehicle data
  void _initializeVehicleData() {
    vehicleState = VehicleService.getState(vehicle);
    vehicleImage = VehicleService.imagePath(
      vehicleType: vehicle.vehicleType ?? '',
      vehicleState: vehicleState!,
      imageState: VehicleImageState.live,
    );
    _currentLocation = vehicle.latestLocation;
    _currentStatus = vehicle.latestStatus;

    // FIX: Calculate time only once and store it
    if (_currentLocation?.createdAt != null &&
        _currentStatus?.createdAt != null) {
      // Use the more recent timestamp from database
      final dbLocationTime = _currentLocation!.createdAt!;
      final dbStatusTime = _currentStatus!.createdAt!;
      final mostRecentDBTime = dbLocationTime.isAfter(dbStatusTime)
          ? dbLocationTime
          : dbStatusTime;

      _lastCalculationTimestamp = mostRecentDBTime;
      _lastCalculatedTime = TimeAgo.timeAgo(mostRecentDBTime);
      lastUpdateTime = _lastCalculatedTime;
    } else if (_currentLocation?.createdAt != null) {
      _lastCalculationTimestamp = _currentLocation!.createdAt!;
      _lastCalculatedTime = TimeAgo.timeAgo(_lastCalculationTimestamp!);
      lastUpdateTime = _lastCalculatedTime;
    } else if (_currentStatus?.createdAt != null) {
      _lastCalculationTimestamp = _currentStatus!.createdAt!;
      _lastCalculatedTime = TimeAgo.timeAgo(_lastCalculationTimestamp!);
      lastUpdateTime = _lastCalculatedTime;
    } else {
      lastUpdateTime = 'No data available';
    }

    _loadCustomMarker();
  }

  // Start Real time tracking
  void _startRealTimeTracking() {
    _isTracking = true;

    // Store the workers so we can dispose them later
    _statusWorker = ever(_socketService.statusUpdates, (
      Map<String, dynamic> statusUpdates,
    ) {
      if (!mounted) return; // Use mounted instead of isDisposed

      final statusData = statusUpdates[vehicle.imei];
      if (statusData != null) {
        _updateStatusFromSocket(statusData);
      }
    });

    // Listen for location updates
    _locationWorker = ever(_socketService.locationUpdates, (
      Map<String, dynamic> locationUpdates,
    ) {
      if (!mounted) return; // Use mounted instead of isDisposed

      final locationData = locationUpdates[vehicle.imei];
      if (locationData != null) {
        _updateLocationFromSocket(locationData);
      }
    });
  }

  // Update Status from socket
  void _updateStatusFromSocket(Map<String, dynamic> statusData) {
    if (!mounted) return; // Use mounted instead of isDisposed
    if (isDisposed) return; // Check if widget is disposed

    try {
      // Add additional null safety check
      if (statusData.isEmpty) {
        debugPrint('Status data is empty, skipping update: $statusData');
        return;
      }
      final newStatus = Status.fromJson(statusData);
      // Create updated vehicle with new status
      final updatedVehicle = vehicle.copyWith(latestStatus: newStatus);

      // Get new vehicle state based on updated status
      final newVehicleState = VehicleService.getState(updatedVehicle);
      vehicle = updatedVehicle;

      // Get new image path
      final newVehicleImage = VehicleService.imagePath(
        vehicleType: updatedVehicle.vehicleType ?? '',
        vehicleState: newVehicleState,
        imageState: VehicleImageState.live,
      );

      setState(() {
        _currentStatus = newStatus;
        vehicleState = newVehicleState;
        vehicleImage = newVehicleImage;

        // Update last update time using same logic as vehicle card
        if (_currentLocation?.createdAt != null &&
            newStatus.createdAt != null) {
          // Only update if we have NEW data
          final newTimestamp = newStatus.createdAt!;
          if (_lastCalculationTimestamp == null ||
              newTimestamp.isAfter(_lastCalculationTimestamp!)) {
            _lastCalculationTimestamp = newTimestamp;
            _lastCalculatedTime = TimeAgo.timeAgo(newTimestamp);
            lastUpdateTime = _lastCalculatedTime;
          }
        }
      });

      // Reload marker with new state
      _loadCustomMarker();
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
  }

  // Update Location from socket
  void _updateLocationFromSocket(Map<String, dynamic> locationData) {
    if (!mounted) return; // Use mounted instead of isDisposed
    if (isDisposed) return;
    try {
      final newLocation = Location.fromJson(locationData);

      if (newLocation.latitude != null && newLocation.longitude != null) {
        final newPosition = LatLng(
          newLocation.latitude!,
          newLocation.longitude!,
        );
        final updatedVehicle = vehicle.copyWith(latestLocation: newLocation);

        // Get new vehicle state based on updated status
        final newVehicleState = VehicleService.getState(updatedVehicle);
        vehicle = updatedVehicle;

        final newVehicleImage = VehicleService.imagePath(
          vehicleType: updatedVehicle.vehicleType ?? '',
          vehicleState: newVehicleState,
          imageState: VehicleImageState.live,
        );

        setState(() {
          _currentLocation = newLocation;
          _vehiclePosition = newPosition;
          routePoints.add(newPosition);
          vehicleState = newVehicleState; // ✅ Update vehicle state
          vehicleImage = newVehicleImage;

          // Update last update time using same logic as vehicle card
          if (newLocation.createdAt != null &&
              _currentStatus?.createdAt != null) {
            // Only update if we have NEW data
            final newTimestamp = newLocation.createdAt!;
            if (_lastCalculationTimestamp == null ||
                newTimestamp.isAfter(_lastCalculationTimestamp!)) {
              _lastCalculationTimestamp = newTimestamp;
              _lastCalculatedTime = TimeAgo.timeAgo(newTimestamp);
              lastUpdateTime = _lastCalculatedTime;
            }
          }

          _updateMarker();
          _updatePolyline();
          _updateMapRotation();
        });
        _loadCustomMarker();

        if (_mapController != null && _isTracking) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: newPosition,
                zoom: 15.0,
                bearing: _mapRotation,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  // Load Custom Marker
  Future<void> _loadCustomMarker() async {
    if (isDisposed) return;

    try {
      _customMarkerIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(90, 90)),
        // const ImageConfiguration(size: Size(90, 90)),
        vehicleImage!,
      );
      _updateMarker();
    } catch (e) {
      debugPrint('Error loading custom marker: $e');
      _customMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueBlue,
      );
      _updateMarker();
    }
  }

  // Update Marker
  _updateMarker() {
    if (_vehiclePosition == null || isDisposed) return;

    setState(() {
      _markers = {
        Marker(
          markerId: MarkerId(vehicle.imei),
          position: _vehiclePosition!,

          icon:
              _customMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: vehicle.vehicleNo ?? 'Vehicle',
            snippet: '${vehicle.vehicleType} - $vehicleState',
          ),
          rotation: 0.0,
        ),
      };
    });
  }

  // Update Polyline
  void _updatePolyline() {
    if (routePoints.length < 2 || isDisposed) return;

    setState(() {
      _polylines = {
        Polyline(
          polylineId: PolylineId('${vehicle.imei}_route'),
          points: routePoints,
          color: Colors.purple,
          width: 3,
          geodesic: true,
        ),
      };
    });
  }

  // Rotate Vehicle
  void _updateMapRotation() {
    if (_currentLocation?.course != null) {
      setState(() {
        _mapRotation = _currentLocation!.course!.toDouble();
      });
    }
  }

  // Add toggle map type function
  void _toggleMapType() {
    setState(() {
      currentMapType = currentMapType == MapType.normal
          ? MapType.hybrid
          : MapType.normal;
    });
  }

  // Start offline check timer
  void _startOfflineCheck() {
    if (!mounted) return;
    _offlineCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkOfflineStatus();
    });
  }

  // Check if device is offline
  void _checkOfflineStatus() {
    if (_currentLocation?.createdAt == null &&
        _currentStatus?.createdAt == null) {
      return;
    }

    final now = DateTime.now();
    DateTime? lastUpdate;

    if (_currentLocation?.createdAt != null &&
        _currentStatus?.createdAt != null) {
      lastUpdate =
          _currentLocation!.createdAt!.isAfter(_currentStatus!.createdAt!)
          ? _currentLocation!.createdAt!
          : _currentStatus!.createdAt!;
    } else if (_currentLocation?.createdAt != null) {
      lastUpdate = _currentLocation!.createdAt!;
    } else if (_currentStatus?.createdAt != null) {
      lastUpdate = _currentStatus!.createdAt!;
    }

    if (lastUpdate != null) {
      try {
        // Force both times to be in UTC for consistent comparison
        final lastUpdateUTC = DateTime.utc(
          lastUpdate.year,
          lastUpdate.month,
          lastUpdate.day,
          lastUpdate.hour,
          lastUpdate.minute,
          lastUpdate.second,
          lastUpdate.millisecond,
          lastUpdate.microsecond,
        );

        final nowUTC = DateTime.utc(
          now.year,
          now.month,
          now.day,
          now.hour,
          now.minute,
          now.second,
          now.millisecond,
          now.microsecond,
        );

        final difference = nowUTC.difference(lastUpdateUTC);
        final isOffline = difference.inSeconds >= 120;

        // Check if vehicle state is running or overspeed
        final isActiveState =
            vehicleState == VehicleService.running ||
            vehicleState == VehicleService.overspeed;

        setState(() {
          _showOfflineModal = isOffline && isActiveState;
        });
      } catch (e) {
        debugPrint('Error in time calculation: $e');
        // Fallback: use absolute time difference
        final difference = now.difference(lastUpdate).abs();
        final isOffline = difference.inSeconds >= 20;

        final isActiveState =
            vehicleState == VehicleService.running ||
            vehicleState == VehicleService.overspeed;

        setState(() {
          _showOfflineModal = isOffline && isActiveState;
        });
      }
    }
  }

  // Status Panel
  Widget _buildStatusPanel() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(blurRadius: 8, offset: Offset(0, 2), color: Colors.black12),
        ],
      ),
      child: Column(
        spacing: 8,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Speedometer
              Column(
                children: [
                  SpeedometerWidget(currentSpeed: _currentLocation!.speed!),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black45, width: 1),
                    ),
                    child: Text(
                      'ODO: ${vehicle.odometer}Km',
                      style: TextStyle(fontSize: 8),
                    ),
                  ),
                ],
              ),

              // Today Km
              Column(
                children: [
                  FaIcon(
                    FontAwesomeIcons.road,
                    color: AppTheme.stopColor,
                    size: 35,
                  ),
                  Text(
                    'Today Km',
                    style: TextStyle(
                      color: AppTheme.titleColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${vehicle.todayKm?.toStringAsFixed(2) ?? 0}Km',
                    style: TextStyle(
                      color: AppTheme.subTitleColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),

              // Last Update
              Column(
                children: [
                  FaIcon(
                    FontAwesomeIcons.clock,
                    color: AppTheme.inactiveColor,
                    size: 35,
                  ),
                  Text(
                    'Last Data',
                    style: TextStyle(
                      color: AppTheme.titleColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    lastUpdateTime,
                    style: TextStyle(
                      color: AppTheme.subTitleColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),

              // Battery, Real Time Gps, Signal
              Column(
                spacing: 5,
                children: [
                  VehicleService.getBattery(
                    value: _currentStatus?.battery ?? 0,
                    size: 20,
                  ),
                  VehicleService.getSignal(
                    value: _currentStatus?.signal ?? 0,
                    size: 20,
                  ),
                  VehicleService.getSatellite(
                    value: _currentLocation?.satellite ?? 0,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),

          // Reverse Geo Code
          Row(
            spacing: 5,
            children: [
              Icon(Icons.location_on, color: Colors.red, size: 15),
              FutureBuilder(
                future: GeoService.getReverseGeoCode(
                  _currentLocation?.latitude ?? 0,
                  _currentLocation?.longitude ?? 0,
                ),
                builder: (context, snapshot) => Text(
                  snapshot.data ?? '...',
                  style: TextStyle(color: AppTheme.subTitleColor, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Tracking: ${vehicle.vehicleNo}',
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
      ),

      // Body
      body: _vehiclePosition == null
          ? const Center(child: LoadingWidget())
          : Stack(
              children: [
                GoogleMap(
                  mapType: currentMapType,
                  initialCameraPosition: CameraPosition(
                    target: _vehiclePosition!,
                    zoom: 15.0,
                    bearing: _mapRotation,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (GoogleMapController controller) {
                    if (isWeb) {
                      // Web-specific handling
                      print('Map created on web');
                      _mapController = controller;
                      // Force a rebuild after map creation
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {});
                      });
                    } else {
                      _mapController = controller;
                    }
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                  trafficEnabled: false,
                  buildingsEnabled: true,
                  indoorViewEnabled: true,
                ),

                // Status Panel
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildStatusPanel(),
                ),

                // Map Buttons
                Positioned(
                  right: 10,
                  top: 150,
                  child: Column(
                    spacing: 10,
                    children: [
                      // Satellite button
                      InkWell(
                        onTap: () => _toggleMapType(),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 4),
                            borderRadius: BorderRadius.circular(300),
                            boxShadow: [
                              BoxShadow(
                                offset: Offset(0, 0),
                                spreadRadius: 1,
                                blurRadius: 15,
                                color: Colors.black12,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            backgroundImage: AssetImage(
                              'assets/images/satellite_view_icon.png',
                            ),
                          ),
                        ),
                      ),

                      // History Button
                      InkWell(
                        onTap: () => Get.toNamed(
                          AppRoutes.vehicleHistoryShow,
                          arguments: vehicle,
                        ),
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(300),
                            boxShadow: [
                              BoxShadow(
                                offset: Offset(0, 0),
                                spreadRadius: 1,
                                blurRadius: 15,
                                color: Colors.black12,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.history,
                            size: 25,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // Weather Button
                      InkWell(
                        onTap: () {
                          if (_currentLocation?.latitude != null &&
                              _currentLocation?.longitude != null) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => WeatherModalWidget(
                                latitude: _currentLocation!.latitude!,
                                longitude: _currentLocation!.longitude!,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'No location data available for weather',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(300),
                            boxShadow: [
                              BoxShadow(
                                offset: Offset(0, 0),
                                spreadRadius: 1,
                                blurRadius: 15,
                                color: Colors.black12,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.sunny_snowing,
                            size: 25,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // Altitude Button
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(300),
                          boxShadow: [
                            BoxShadow(
                              offset: Offset(0, 0),
                              spreadRadius: 1,
                              blurRadius: 15,
                              color: Colors.black12,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.landscape,
                              size: 15,
                              color: Colors.white,
                            ),

                            FutureBuilder(
                              future: GeoService.getAltitude(
                                _currentLocation?.latitude ?? 0,
                                _currentLocation?.longitude ?? 0,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Text(
                                    '...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }

                                if (snapshot.hasError || !snapshot.hasData) {
                                  return Text(
                                    'N/A',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }

                                final altitude = snapshot.data ?? '0';
                                return Text(
                                  '${altitude}m',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Offline
                // Offline Modal
                // if (_showOfflineModal)
                // Positioned.fill(child: _buildOfflineModal()),
              ],
            ),
    );
  }

  // Build offline modal
  Widget _buildOfflineModal() {
    return Container(
      color: Colors.black.withOpacity(0.7), // Semi-transparent black overlay
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.red.shade700,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Large Offline Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.wifi_off, color: Colors.white, size: 60),
              ),

              const SizedBox(height: 20),

              // Offline Title
              Text(
                'DEVICE OFFLINE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 15),

              // Offline Message
              Text(
                'No data received for more than 12 seconds',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Warning Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.yellow.shade300,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Map interaction disabled',
                    style: TextStyle(
                      color: Colors.yellow.shade300,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // Vehicle Info
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Vehicle: ${vehicle.vehicleNo ?? 'Unknown'}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'State: ${vehicleState?.toUpperCase() ?? 'UNKNOWN'}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Last Update Info
              Text(
                'Last Update: $lastUpdateTime',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isTracking = false;
    _mapController?.dispose();
    _offlineCheckTimer?.cancel(); // Cancel the timer

    // Dispose the workers to prevent memory leaks
    _statusWorker?.dispose();
    _locationWorker?.dispose();
    super.dispose();
  }
}
