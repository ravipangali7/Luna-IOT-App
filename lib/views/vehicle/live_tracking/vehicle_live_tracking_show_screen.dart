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
import 'package:luna_iot/utils/vehicle_utils.dart';
import 'package:luna_iot/widgets/loading_widget.dart';
import 'package:luna_iot/widgets/satellite_connection_status_widget.dart';
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
    extends State<VehicleLiveTrackingShowScreen>
    with TickerProviderStateMixin {
  // Vehicle data
  Vehicle vehicle = Vehicle(imei: '');
  bool isLoadingVehicle = true;

  // Map controllers and data
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> routePoints = [];
  LatLng? _vehiclePosition;
  BitmapDescriptor? _customMarkerIcon;

  // Vehicle state
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
  String lastUpdateTime = '...';
  String _lastCalculatedTime = '...';
  DateTime? _lastCalculationTimestamp;

  // Socket listeners
  Worker? _statusWorker;
  Worker? _locationWorker;

  // Animation controllers for smooth movement
  late AnimationController _cameraAnimationController;
  late AnimationController _markerAnimationController;

  // Animation settings
  static const Duration _animationDuration = Duration(milliseconds: 1000);
  static const Duration _markerAnimationDuration = Duration(milliseconds: 500);

  // Throttling for updates
  Timer? _updateThrottle;
  static const Duration _throttleDuration = Duration(milliseconds: 200);

  bool get isWeb => kIsWeb;

  @override
  void initState() {
    super.initState();
    _initializeAnimationControllers();
    _initializeScreen();
  }

  void _initializeAnimationControllers() {
    _cameraAnimationController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );
    _markerAnimationController = AnimationController(
      duration: _markerAnimationDuration,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(VehicleLiveTrackingShowScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imei != widget.imei) {
      _resetAndReinitialize();
    }
  }

  void _initializeScreen() {
    _fetchVehicleData();
  }

  void _resetAndReinitialize() {
    _stopTracking();
    _resetState();
    _initializeScreen();
  }

  void _resetState() {
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
  }

  void _stopTracking() {
    _isTracking = false;

    // Clear the tracking IMEI in socket service
    _socketService.clearTrackingImei();

    _statusWorker?.dispose();
    _locationWorker?.dispose();
    _updateThrottle?.cancel();
    _cameraAnimationController.stop();
    _markerAnimationController.stop();
  }

  // Fetch vehicle data from API
  Future<void> _fetchVehicleData() async {
    try {
      setState(() {
        isLoadingVehicle = true;
      });

      final vehicleData = await Get.find<VehicleApiService>().getVehicleByImei(
        widget.imei,
      );

      // Check if vehicle is inactive
      if (!vehicleData.isVehicleActive) {
        VehicleUtils.showInactiveVehicleModal(
          vehicle: vehicleData,
          action: 'Live Tracking',
        );
        setState(() {
          isLoadingVehicle = false;
        });
        return;
      }

      setState(() {
        vehicle = vehicleData;
        isLoadingVehicle = false;
      });

      // Initialize data after fetching
      _initializeVehicleData();
      _initializeMap();
      _loadCustomMarker();
      _startRealTimeTracking();
    } catch (e) {
      setState(() {
        isLoadingVehicle = false;
      });
      Get.snackbar('Error', 'Failed to load vehicle data: $e');
    }
  }

  // Initialize map with vehicle's latest location
  void _initializeMap() {
    final location = vehicle.latestLocation;
    if (location?.latitude != null && location?.longitude != null) {
      _vehiclePosition = LatLng(location!.latitude!, location.longitude!);
      _currentLocation = location;
      routePoints.add(_vehiclePosition!);
      _updateMarker();
      _updatePolyline();
      _updateMapRotation();
    }
  }

  // Initialize vehicle data
  void _initializeVehicleData() {
    vehicleState = VehicleService.getState(vehicle);
    vehicleImage = VehicleService.imagePath(
      vehicleType: vehicle.vehicleType ?? '',
      vehicleState: vehicleState!,
      imageState: VehicleImageState.live,
    );
    _currentLocation = vehicle.latestLocation;
    _currentStatus = vehicle.latestStatus;

    // Calculate initial time
    _calculateLastUpdateTime();
  }

  void _calculateLastUpdateTime() {
    final mostRecentTime = TimeAgo.getMostRecentTime(
      _currentStatus?.createdAt,
      _currentLocation?.createdAt,
    );

    if (mostRecentTime != null) {
      _lastCalculationTimestamp = mostRecentTime;
      _lastCalculatedTime = TimeAgo.timeAgo(mostRecentTime);
      lastUpdateTime = _lastCalculatedTime;
    } else {
      lastUpdateTime = 'No data available';
    }
  }

  // Start real-time tracking with optimized socket handling
  void _startRealTimeTracking() {
    if (_isTracking) return;

    // Set the tracking IMEI in socket service to filter updates
    _socketService.setTrackingImei(widget.imei);

    _isTracking = true;

    // Status updates listener - now filtered at socket level
    _statusWorker = ever(_socketService.statusUpdates, (
      Map<String, dynamic> statusUpdates,
    ) {
      if (!mounted || !_isTracking) return;

      // Since we're filtering at socket level, we should only get updates for our IMEI
      final statusData = statusUpdates[widget.imei];
      if (statusData != null) {
        _throttledUpdate(() => _updateStatusFromSocket(statusData));
      }
    });

    // Location updates listener - now filtered at socket level
    _locationWorker = ever(_socketService.locationUpdates, (
      Map<String, dynamic> locationUpdates,
    ) {
      if (!mounted || !_isTracking) return;

      // Since we're filtering at socket level, we should only get updates for our IMEI
      final locationData = locationUpdates[widget.imei];
      if (locationData != null) {
        _throttledUpdate(() => _updateLocationFromSocket(locationData));
      }
    });
  }

  // Throttled update to prevent excessive updates
  void _throttledUpdate(VoidCallback updateFunction) {
    _updateThrottle?.cancel();
    _updateThrottle = Timer(_throttleDuration, updateFunction);
  }

  // Update status from socket
  void _updateStatusFromSocket(Map<String, dynamic> statusData) {
    if (!mounted || !_isTracking || statusData.isEmpty) return;

    try {
      final newStatus = Status.fromJson(statusData);

      final updatedVehicle = vehicle.copyWith(latestStatus: newStatus);
      final newVehicleState = VehicleService.getState(updatedVehicle);
      final newVehicleImage = VehicleService.imagePath(
        vehicleType: updatedVehicle.vehicleType ?? '',
        vehicleState: newVehicleState,
        imageState: VehicleImageState.live,
      );

      setState(() {
        vehicle = updatedVehicle;
        _currentStatus = newStatus;
        vehicleState = newVehicleState;
        vehicleImage = newVehicleImage;

        // Update last update time using unified logic
        final newTimestamp = newStatus.createdAt;
        if (newTimestamp != null) {
          if (_lastCalculationTimestamp == null ||
              newTimestamp.isAfter(_lastCalculationTimestamp!)) {
            _lastCalculationTimestamp = newTimestamp;
            _lastCalculatedTime = TimeAgo.timeAgo(newTimestamp);
            lastUpdateTime = _lastCalculatedTime;
          }
        }
      });

      _loadCustomMarker();
    } catch (e) {}
  }

  // Update location from socket with smooth animation
  void _updateLocationFromSocket(Map<String, dynamic> locationData) {
    if (!mounted || !_isTracking) return;

    try {
      final newLocation = Location.fromJson(locationData);

      if (newLocation.latitude != null && newLocation.longitude != null) {
        final newPosition = LatLng(
          newLocation.latitude!,
          newLocation.longitude!,
        );

        // Check if position has actually changed
        if (_vehiclePosition != null &&
            _vehiclePosition!.latitude == newPosition.latitude &&
            _vehiclePosition!.longitude == newPosition.longitude) {
          return; // Skip if position hasn't changed
        }

        final updatedVehicle = vehicle.copyWith(latestLocation: newLocation);
        final newVehicleState = VehicleService.getState(updatedVehicle);
        final newVehicleImage = VehicleService.imagePath(
          vehicleType: updatedVehicle.vehicleType ?? '',
          vehicleState: newVehicleState,
          imageState: VehicleImageState.live,
        );

        // Store previous position for animation
        LatLng? previousPosition = _vehiclePosition;

        setState(() {
          vehicle = updatedVehicle;
          _currentLocation = newLocation;
          _vehiclePosition = newPosition;
          routePoints.add(newPosition);
          vehicleState = newVehicleState;
          vehicleImage = newVehicleImage;

          // Update last update time using unified logic
          final newTimestamp = newLocation.createdAt;
          if (newTimestamp != null) {
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

        // Start smooth animation from previous position to new position
        if (previousPosition != null) {
          _animateToNewPosition(previousPosition, newPosition, newLocation);
        } else {
          // First position - just center on vehicle
          _centerOnVehicleWithRotation(newPosition, newLocation.course ?? 0.0);
        }

        _loadCustomMarker();
      }
    } catch (e) {}
  }

  // Center on vehicle with map rotation
  void _centerOnVehicleWithRotation(LatLng position, double course) {
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: 17.0,
          bearing: course,
          tilt: 0.0,
        ),
      ),
    );
  }

  // Animate smooth movement from point 0 to point 1 over 5 seconds
  void _animateToNewPosition(
    LatLng fromPosition,
    LatLng toPosition,
    Location newLocation,
  ) {
    if (_mapController == null || !_isTracking) return;

    // First, draw the polyline (it's already drawn in setState above)
    // Now start smooth linear animation from 0.01 to 0.99 over 5 seconds
    _startSmoothLinearAnimation(fromPosition, toPosition, newLocation);
  }

  // Start smooth linear animation between two points over 5 seconds
  void _startSmoothLinearAnimation(
    LatLng fromPosition,
    LatLng toPosition,
    Location newLocation,
  ) {
    const int totalSteps = 300; // 0.01 to 1.0 = 300 steps for smoother movement
    const Duration stepDuration = Duration(
      milliseconds: 50,
    ); // 15 seconds / 300 steps = 50ms per step

    int currentStep = 0;
    double course = newLocation.course ?? 0.0;

    Timer.periodic(stepDuration, (timer) {
      if (currentStep >= totalSteps || !_isTracking || !mounted) {
        timer.cancel();
        return;
      }

      // Calculate interpolation factor (0.01 to 1.0)
      double t = (currentStep + 1) / totalSteps; // 0.01 to 1.0

      // Linear interpolation between points
      double lat =
          fromPosition.latitude +
          (toPosition.latitude - fromPosition.latitude) * t;
      double lng =
          fromPosition.longitude +
          (toPosition.longitude - fromPosition.longitude) * t;

      LatLng interpolatedPosition = LatLng(lat, lng);

      // Update both marker position and map position during animation
      setState(() {
        _vehiclePosition = interpolatedPosition;
        _updateMarker();
      });

      // Update map position with smooth movement
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: interpolatedPosition,
            zoom: 17.0,
            bearing: course,
            tilt: 0.0,
          ),
        ),
      );

      currentStep++;
    });
  }

  // Load custom marker
  Future<void> _loadCustomMarker() async {
    if (!mounted) return;

    try {
      _customMarkerIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(90, 90)),
        vehicleImage!,
      );
      _updateMarker();
    } catch (e) {
      _customMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueBlue,
      );
      _updateMarker();
    }
  }

  // Update marker with improved rotation
  void _updateMarker() {
    if (_vehiclePosition == null || !mounted) return;

    // Calculate marker rotation based on vehicle course
    double markerRotation = _calculateMarkerRotation();

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
          rotation: markerRotation,
          anchor: const Offset(0.5, 0.5), // Center the marker rotation
        ),
      };
    });
  }

  // Calculate marker rotation - always keep marker pointing North (upward)
  double _calculateMarkerRotation() {
    // Marker always points North (0 degrees) regardless of vehicle course
    // Only the map rotates, not the marker
    return 0.0;
  }

  // Update polyline for route tracking
  void _updatePolyline() {
    if (routePoints.length < 2 || !mounted) return;

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

  // Update map rotation based on vehicle course with intelligent following
  void _updateMapRotation() {
    if (_currentLocation?.course != null && mounted) {
      double newRotation = _currentLocation!.course!.toDouble();
      setState(() {
        _mapRotation = newRotation;
      });
    }
  }

  // Toggle map type
  void _toggleMapType() {
    if (mounted) {
      setState(() {
        currentMapType = currentMapType == MapType.normal
            ? MapType.hybrid
            : MapType.normal;
      });
    }
  }

  // Build status panel
  Widget _buildStatusPanel() {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 2),
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        spacing: 8,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Speedometer
              SpeedometerWidget(vehicle: vehicle),

              // Today Km
              Column(
                children: [
                  FaIcon(
                    FontAwesomeIcons.road,
                    color: AppTheme.stopColor,
                    size: 30,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Today Km',
                    style: TextStyle(
                      color: AppTheme.titleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${vehicle.todayKm?.toStringAsFixed(2) ?? 0}Km',
                    style: TextStyle(
                      color: AppTheme.subTitleColor,
                      fontSize: 12,
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
                    size: 30,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Last Data',
                    style: TextStyle(
                      color: AppTheme.titleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    lastUpdateTime,
                    style: TextStyle(
                      color: AppTheme.subTitleColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              // Battery, Real Time Gps, Signal
              Column(
                spacing: 3,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 15),
              SizedBox(width: 5),
              Expanded(
                child: FutureBuilder(
                  future: GeoService.getReverseGeoCode(
                    _currentLocation?.latitude ?? 0,
                    _currentLocation?.longitude ?? 0,
                  ),
                  builder: (context, snapshot) => Text(
                    snapshot.data ?? '...',
                    style: TextStyle(
                      color: AppTheme.subTitleColor,
                      fontSize: 12,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build bottom info panel with odometer and altitude
  Widget _buildBottomInfoPanel() {
    return Container(
      margin: const EdgeInsets.all(10),
      child: Row(
        children: [
          // Odometer Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                    color: Colors.black12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.straighten,
                    color: Colors.orange.shade800,
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Odometer',
                          style: TextStyle(
                            color: AppTheme.subTitleColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${vehicle.odometer}Km',
                          style: TextStyle(
                            color: AppTheme.titleColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: 8),

          // Altitude Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                    color: Colors.black12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.landscape,
                    color: Colors.purple.shade600,
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Altitude',
                          style: TextStyle(
                            color: AppTheme.subTitleColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
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
                                  color: AppTheme.titleColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }

                            if (snapshot.hasError || !snapshot.hasData) {
                              return Text(
                                'N/A',
                                style: TextStyle(
                                  color: AppTheme.titleColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }

                            final altitude = snapshot.data ?? '0';
                            return Text(
                              '${altitude}m',
                              style: TextStyle(
                                color: AppTheme.titleColor,
                                fontSize: 15,
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
        actions: [
          SatelliteConnectionStatusWidget(
            tooltip: 'Connection Status',
            onTap: () {},
          ),
          SizedBox(width: 10),
        ],
      ),
      body: _vehiclePosition == null
          ? const Center(child: LoadingWidget())
          : Stack(
              children: [
                // Google Map
                GoogleMap(
                  mapType: currentMapType,
                  initialCameraPosition: CameraPosition(
                    target: _vehiclePosition!,
                    zoom: 17.0,
                    bearing: _mapRotation,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (GoogleMapController controller) {
                    if (isWeb) {
                      _mapController = controller;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {});
                      });
                    } else {
                      _mapController = controller;
                    }
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
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

                // Bottom Info Panel
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomInfoPanel(),
                ),

                // Map Controls
                Positioned(
                  right: 10,
                  top: 150,
                  child: Column(
                    spacing: 10,
                    children: [
                      // Satellite button
                      InkWell(
                        onTap: _toggleMapType,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 4),
                            borderRadius: BorderRadius.circular(300),
                            boxShadow: [
                              BoxShadow(
                                offset: const Offset(0, 0),
                                spreadRadius: 1,
                                blurRadius: 15,
                                color: Colors.black12,
                              ),
                            ],
                          ),
                          child: const CircleAvatar(
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
                                offset: const Offset(0, 0),
                                spreadRadius: 1,
                                blurRadius: 15,
                                color: Colors.black12,
                              ),
                            ],
                          ),
                          child: const Icon(
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
                              const SnackBar(
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
                                offset: const Offset(0, 0),
                                spreadRadius: 1,
                                blurRadius: 15,
                                color: Colors.black12,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.sunny_snowing,
                            size: 25,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _stopTracking();
    _mapController?.dispose();
    _cameraAnimationController.dispose();
    _markerAnimationController.dispose();
    super.dispose();
  }
}
