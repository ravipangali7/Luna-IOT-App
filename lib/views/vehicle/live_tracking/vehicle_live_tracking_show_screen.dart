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
import 'package:luna_iot/widgets/simple_marquee_widget.dart';
import 'package:luna_iot/widgets/vehicle/share_track_modal.dart';

class VehicleLiveTrackingShowScreen extends StatefulWidget {
  const VehicleLiveTrackingShowScreen({
    super.key,
    required this.imei,
    this.fromSchoolVehicle = false,
  });

  final String imei;
  final bool fromSchoolVehicle;

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
  DateTime? _lastCalculationTimestamp;

  // Altitude API optimization
  bool _hasNewLocationData = false;
  String? _cachedAltitude;
  bool _isAltitudeLoading = false;

  // Socket listeners
  Worker? _statusWorker;
  Worker? _locationWorker;

  // Throttling for updates
  Timer? _updateThrottle;
  static const Duration _throttleDuration = Duration(milliseconds: 200);

  // Animation for marker movement
  Timer? _markerAnimationTimer;
  LatLng? _animationStartPosition;
  LatLng? _animationTargetPosition;

  // Timer to update last data display
  Timer? _lastUpdateTimer;

  bool get isWeb => kIsWeb;

  // Check if accessed from school vehicle screen
  bool get _isFromSchoolVehicle {
    // First check widget parameter
    if (widget.fromSchoolVehicle) {
      return true;
    }
    // Fallback: check Get.arguments
    final arguments = Get.arguments;
    if (arguments is Map && arguments['fromSchoolVehicle'] == true) {
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _initializeScreen();
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

    // Leave socket room
    _socketService.leaveVehicleRoom(widget.imei);
    _socketService.clearTrackingImei();

    _statusWorker?.dispose();
    _locationWorker?.dispose();
    _updateThrottle?.cancel();
    _markerAnimationTimer?.cancel();
    _lastUpdateTimer?.cancel();
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

    // Initialize altitude flag for first load
    _hasNewLocationData = true;
    _isAltitudeLoading = true; // Show loading for first load

    // Calculate initial time
    final mostRecentTime = TimeAgo.getMostRecentTime(
      _currentStatus?.createdAt,
      _currentLocation?.createdAt,
    );
    if (mostRecentTime != null) {
      _lastCalculationTimestamp = mostRecentTime;
      lastUpdateTime = TimeAgo.timeAgo(mostRecentTime);
    } else {
      lastUpdateTime = 'No data available';
    }
  }

  // Safe type conversion for int/double values
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return 0.0;
  }

  // Start real-time tracking with optimized socket handling
  void _startRealTimeTracking() {
    if (_isTracking) return;

    // Join socket room for this vehicle (room-based filtering)
    _socketService.joinVehicleRoom(widget.imei);
    _socketService.setTrackingImei(widget.imei);

    _isTracking = true;

    // Start timer to update "last data" display every second
    _lastUpdateTimer?.cancel();
    _lastUpdateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted || !_isTracking) {
        timer.cancel();
        return;
      }
      if (_lastCalculationTimestamp != null) {
        setState(() {
          lastUpdateTime = TimeAgo.timeAgo(_lastCalculationTimestamp!);
        });
      }
    });

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

      // Only call setState if still mounted
      if (!mounted) return;

      setState(() {
        vehicle = updatedVehicle;
        _currentStatus = newStatus;
        vehicleState = newVehicleState;
        vehicleImage = newVehicleImage;

        // Reset timestamp to NOW when socket arrives
        _lastCalculationTimestamp = DateTime.now();
        lastUpdateTime = TimeAgo.timeAgo(_lastCalculationTimestamp!);
      });

      _loadCustomMarker();
    } catch (e) {
      debugPrint('Error updating status from socket: $e');
    }
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

        // Only call setState if still mounted
        if (!mounted) return;

        setState(() {
          vehicle = updatedVehicle;
          _currentLocation = newLocation;
          vehicleState = newVehicleState;
          vehicleImage = newVehicleImage;

          // Reset timestamp to NOW when socket arrives
          _lastCalculationTimestamp = DateTime.now();
          lastUpdateTime = TimeAgo.timeAgo(_lastCalculationTimestamp!);

          // Mark that we have new location data for altitude API
          _hasNewLocationData = true;
          _isAltitudeLoading = true; // Show loading for new data

          _updateMapRotation();
        });

        // Start marker animation to new position
        _startMarkerAnimation(newPosition, newLocation);

        _loadCustomMarker();
      }
    } catch (e) {
      debugPrint('Error updating location from socket: $e');
    }
  }

  // Start marker animation to new position
  void _startMarkerAnimation(LatLng targetPosition, Location newLocation) {
    // If animation is in progress, complete it first to avoid backtracking
    if (_markerAnimationTimer != null && _markerAnimationTimer!.isActive) {
      _markerAnimationTimer!.cancel();
      // Jump to previous target position
      if (_animationTargetPosition != null) {
        _vehiclePosition = _animationTargetPosition;
        routePoints.add(_animationTargetPosition!);
        _updateMarker();
        _updatePolyline();
      }
    }

    // Set animation parameters
    _animationStartPosition = _vehiclePosition ?? targetPosition;
    _animationTargetPosition = targetPosition;

    // Start marker animation
    const int totalSteps = 30; // 30 steps over 3 seconds = 100ms per step
    const Duration stepDuration = Duration(milliseconds: 100);
    int currentStep = 0;

    _markerAnimationTimer = Timer.periodic(stepDuration, (timer) {
      if (currentStep >= totalSteps || !_isTracking || !mounted) {
        timer.cancel();
        // Animation complete - set final position
        _vehiclePosition = targetPosition;
        routePoints.add(targetPosition);
        _updateMarker();
        _updatePolyline();
        // Move camera to final position
        _centerOnVehicleWithRotation(
          targetPosition,
          _toDouble(newLocation.course),
        );
        return;
      }

      currentStep++;
      double progress = currentStep / totalSteps;

      // Calculate interpolated position
      LatLng interpolatedPosition = LatLng(
        _animationStartPosition!.latitude +
            (_animationTargetPosition!.latitude -
                    _animationStartPosition!.latitude) *
                progress,
        _animationStartPosition!.longitude +
            (_animationTargetPosition!.longitude -
                    _animationStartPosition!.longitude) *
                progress,
      );

      _vehiclePosition = interpolatedPosition;
      _updateMarker();

      // Rotate map at each step
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: interpolatedPosition,
              zoom: 16.0,
              bearing: _toDouble(newLocation.course),
              tilt: 0.0,
            ),
          ),
        );
      }

      // Add intermediate points to polyline every 3 steps (every 300ms)
      if (currentStep % 3 == 0) {
        routePoints.add(interpolatedPosition);
        _updatePolyline();
      }
    });
  }

  // Center on vehicle with map rotation
  void _centerOnVehicleWithRotation(LatLng position, double course) {
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: 16.0,
          bearing: course,
          tilt: 0.0,
        ),
      ),
    );
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

  // Calculate marker rotation - always point North
  double _calculateMarkerRotation() {
    // Marker always points North (0 degrees)
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
                  builder: (context, snapshot) {
                    final address = snapshot.data ?? '...';
                    return SimpleMarqueeText(
                      text: address,
                      style: TextStyle(
                        color: AppTheme.subTitleColor,
                        fontSize: 12,
                      ),
                      scrollAxisExtent: 300.0,
                      scrollDuration: Duration(seconds: 10),
                      autoStart: true,
                    );
                  },
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
                          future: _hasNewLocationData
                              ? GeoService.getAltitude(
                                  _currentLocation?.latitude ?? 0,
                                  _currentLocation?.longitude ?? 0,
                                ).then((altitude) {
                                  _cachedAltitude = altitude;
                                  _hasNewLocationData =
                                      false; // Reset flag after API call
                                  _isAltitudeLoading =
                                      false; // Stop loading after API call
                                  return altitude;
                                })
                              : Future.value(_cachedAltitude ?? 'N/A'),
                          builder: (context, snapshot) {
                            // Show loading only if we have no cached data and are loading
                            if (_isAltitudeLoading && _cachedAltitude == null) {
                              return Text(
                                '...',
                                style: TextStyle(
                                  color: AppTheme.titleColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }

                            // Show loading if we're waiting for new data and have no cached data
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                _cachedAltitude == null) {
                              return Text(
                                '...',
                                style: TextStyle(
                                  color: AppTheme.titleColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }

                            // Show error if there's an error and no cached data
                            if ((snapshot.hasError || !snapshot.hasData) &&
                                _cachedAltitude == null) {
                              return Text(
                                'N/A',
                                style: TextStyle(
                                  color: AppTheme.titleColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }

                            // Show cached altitude if available, otherwise show new data
                            final altitude =
                                _cachedAltitude ?? snapshot.data ?? '0';
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
                    zoom: 15.0,
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
                  zoomGesturesEnabled: true,
                  zoomControlsEnabled: true,
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

                      // History Button - Hide if from school vehicle screen
                      if (!_isFromSchoolVehicle)
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

                      // Share Track Button - Hide if from school vehicle screen
                      if (!_isFromSchoolVehicle)
                        InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => ShareTrackModal(
                                imei: widget.imei,
                                vehicleNo: vehicle.vehicleNo ?? 'Unknown',
                              ),
                            );
                          },
                          child: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.purple.shade600,
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
                              Icons.share,
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
    super.dispose();
  }
}
