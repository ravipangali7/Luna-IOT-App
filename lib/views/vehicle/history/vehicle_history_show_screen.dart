import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/vehicle_controller.dart';
import 'package:luna_iot/models/history_model.dart';
import 'package:luna_iot/models/trip_model.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/services/geo_service.dart';
import 'package:luna_iot/services/trip_service.dart';
import 'package:luna_iot/services/vehicle_service.dart';
import 'package:luna_iot/utils/vehicle_image_state.dart';
import 'package:luna_iot/widgets/vehicle/history/trip_drawer.dart';

class VehicleHistoryShowScreen extends StatefulWidget {
  const VehicleHistoryShowScreen({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  State<VehicleHistoryShowScreen> createState() => _VehicleHistoryShowState();
}

class _VehicleHistoryShowState extends State<VehicleHistoryShowScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> routePoints = [];
  MapType currentMapType = MapType.normal;

  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = false;
  bool isPlaying = false;
  bool isTripSelected = false; // Add this flag

  // Add these new variables for the modal
  bool _showStopModal = false;
  Trip? _selectedStopTrip;
  Trip? _nextTrip;
  String _address = '';
  bool _isLoadingAddress = false;

  List<History> historyData = [];
  List<Trip> trips = [];

  // Animation controller for vehicle movement
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Current data during animation
  DateTime? _currentDateTime;
  double _currentSpeed = 0.0;

  // Camera following optimization
  LatLng? _lastCameraPosition;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _setupAnimation();
    _initializeDefaultDates();
    _cacheVehicleIcon(); // Cache vehicle icon for better performance
  }

  void _initializeDefaultDates() {
    final today = DateTime.now();
    setState(() {
      startDate = DateTime(today.year, today.month, today.day - 1); // Yesterday
      endDate = DateTime(
        today.year,
        today.month,
        today.day,
        23,
        59,
        59,
      ); // Today end of day
    });

    // Automatically fetch history data for yesterday to today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchHistoryData();
    });
  }

  void _setupAnimation() {
    // Calculate duration based on number of route points
    final duration = _calculateAnimationDuration();

    _animationController = AnimationController(duration: duration, vsync: this);

    // Use linear curve for smooth, consistent movement
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.linear, // Linear animation for consistent movement
      ),
    );

    _animation.addListener(() {
      _updateVehiclePosition();
    });

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          isPlaying = false;
        });

        // Restore original polyline when animation completes
        _restoreOriginalPolyline();
      }
    });
  }

  // Calculate animation duration based on number of route points
  Duration _calculateAnimationDuration() {
    if (routePoints.isEmpty) {
      return Duration(seconds: 10); // Default duration if no points
    }

    final pointCount = routePoints.length;

    // Base calculation: 150ms per point for smooth, visible movement
    // This ensures balanced movement between visible and smooth
    final baseDurationMs = pointCount * 150; // 150ms = 0.15 seconds per point

    // Apply minimum and maximum limits
    final minDuration = Duration(seconds: 3); // Minimum 3 seconds
    final maxDuration = Duration(
      minutes: 2,
    ); // Maximum 2 minutes for very long routes

    final calculatedDuration = Duration(milliseconds: baseDurationMs);

    // Clamp between min and max
    if (calculatedDuration < minDuration) {
      return minDuration;
    } else if (calculatedDuration > maxDuration) {
      return maxDuration;
    } else {
      return calculatedDuration;
    }
  }

  void _initializeMap() {
    final location = widget.vehicle.latestLocation;
    if (location?.latitude != null && location?.longitude != null) {
      final initialPosition = LatLng(location!.latitude!, location.longitude!);
      _updateMapCamera(initialPosition);
    }
  }

  void _updateMapCamera(LatLng position) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: position, zoom: 15.0),
        ),
      );
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: today.subtract(Duration(days: 1)),
      firstDate: today.subtract(Duration(days: 30)),
      lastDate: today,
    );
    if (picked != null) {
      setState(() {
        // Send only date string: YYYY-MM-DD
        startDate = DateTime(picked.year, picked.month, picked.day);

        // Reset end date if it's before start date
        if (endDate != null && endDate!.isBefore(startDate!)) {
          endDate = null;
        }
        // If end date is same as start date, set it to end of day
        else if (endDate != null &&
            endDate!.year == startDate!.year &&
            endDate!.month == startDate!.month &&
            endDate!.day == startDate!.day) {
          endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select start date first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final DateTime today = DateTime.now();
    DateTime lastDate;

    // Logic for end date selection based on start date
    if (startDate!.isAtSameMomentAs(
      DateTime(today.year, today.month, today.day),
    )) {
      lastDate = today;
    } else if (startDate!.isAtSameMomentAs(
      DateTime(today.year, today.month, today.day - 1),
    )) {
      lastDate = today;
    } else {
      lastDate = startDate!.add(Duration(days: 3));
      if (lastDate.isAfter(today)) {
        lastDate = today;
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate!.add(Duration(days: 1)),
      firstDate: startDate!,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        // Send only date string: YYYY-MM-DD
        endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
  }

  Future<void> _fetchHistoryData() async {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select both start and end dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final controller = Get.find<VehicleController>();

      // Fetch combined history data
      final historyData = await controller.getCombinedHistoryByDateRange(
        widget.vehicle.imei,
        startDate!,
        endDate!,
      );

      setState(() {
        this.historyData = historyData;
      });

      print('Fetched ${historyData.length} history records');

      // CRITICAL: Clear map immediately if no data
      if (historyData.isEmpty) {
        setState(() {
          routePoints = [];
          _markers = {};
          _polylines = {};
          trips = [];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No data found for selected date range'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Calculate trips
      _calculateTrips();

      // Update map with history
      _updateMapWithHistory();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch history data: $e'),
          backgroundColor: Colors.red,
        ),
      );

      // Clear map on error
      setState(() {
        routePoints = [];
        _markers = {};
        _polylines = {};
        trips = [];
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _calculateTrips() {
    try {
      final locationRecords = historyData
          .where((d) => d.type == 'location')
          .length;
      final statusRecords = historyData.where((d) => d.type == 'status').length;

      print('Processing ${historyData.length} total records from server');
      print('Location records: $locationRecords');
      print('Status records: $statusRecords');

      // Debug: Check date range of received data
      if (historyData.isNotEmpty) {
        final firstRecord = historyData.first;
        final lastRecord = historyData.last;
        print('First record: ${firstRecord.createdAt}');
        print('Last record: ${lastRecord.createdAt}');
      }

      // Debug status events
      final statusEvents = historyData
          .where((d) => d.type == 'status')
          .toList();
      for (final event in statusEvents.take(3)) {
        print('  - Ignition: ${event.ignition} at ${event.createdAt}');
      }

      // Use the data as received from server (should already be filtered)
      trips = TripService.calculateTrips(historyData);
      print('Calculated trips: ${trips.length}');

      for (final trip in trips) {
        print(
          'Trip ${trip.tripNumber}: ${trip.tripPoints.length} points, '
          'Distance: ${trip.distance.toStringAsFixed(2)}km, '
          'Duration: ${trip.duration.inMinutes}min, '
          'Start: ${trip.startTime}, End: ${trip.endTime}',
        );
      }
    } catch (e) {
      debugPrint('Error calculating trips: $e');
      trips = [];
    }
  }

  void _onTripSelected(Trip trip) {
    // Show trip details on map
    _showTripOnMap(trip);
  }

  void _showTripOnMap(Trip trip) {
    if (trip.tripPoints.isEmpty) return;

    setState(() {
      isTripSelected = true; // Set flag when trip is selected

      // Update route points to show only this trip
      routePoints = trip.tripPoints
          .where((data) => data.latitude != null && data.longitude != null)
          .map((data) => LatLng(data.latitude!, data.longitude!))
          .toList();

      _markers = {};
      _polylines = {};

      // Add start point marker (green)
      if (routePoints.isNotEmpty) {
        _markers.add(
          Marker(
            markerId: MarkerId('start'),
            position: routePoints.first,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: 'Trip ${trip.tripNumber} Start',
              snippet:
                  '${trip.startTime.hour}:${trip.startTime.minute.toString().padLeft(2, '0')}',
            ),
          ),
        );
      }

      // Add vehicle marker at start point
      if (routePoints.isNotEmpty) {
        _addVehicleMarker(routePoints.first, true);
      }

      // Add polyline
      if (routePoints.length > 1) {
        _polylines.add(
          Polyline(
            polylineId: PolylineId('route'),
            points: routePoints,
            color: Colors.blue,
            width: 3,
            geodesic: true,
          ),
        );
      }
    });

    // Fit map to show the trip
    if (routePoints.length > 1) {
      _fitMapToRoute();
    } else if (routePoints.isNotEmpty) {
      _updateMapCamera(routePoints.first);
    }

    // Close drawer
    Navigator.of(context).pop();
  }

  void _updateMapWithHistory() {
    // CRITICAL: Clear map if no data
    if (historyData.isEmpty) {
      setState(() {
        isTripSelected = false;
        routePoints = [];
        _markers = {};
        _polylines = {};
      });

      print('No history data found - cleared map completely');
      return;
    }

    // Filter only location data for map
    final locationDataList = historyData
        .where((data) => data.type == 'location')
        .toList();

    // CRITICAL: Clear map if no location data
    if (locationDataList.isEmpty) {
      setState(() {
        isTripSelected = false;
        routePoints = [];
        _markers = {};
        _polylines = {};
      });

      print('No location data found - cleared map completely');
      return;
    }

    setState(() {
      isTripSelected = false; // Reset flag when showing all history

      routePoints = locationDataList
          .where((data) => data.latitude != null && data.longitude != null)
          .map((data) => LatLng(data.latitude!, data.longitude!))
          .toList();

      _markers = {};
      _polylines = {};

      // Add start point marker (green)
      if (routePoints.isNotEmpty) {
        _markers.add(
          Marker(
            markerId: MarkerId('start'),
            position: routePoints.first,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: 'Start Point',
              snippet: '${startDate?.toString().split(' ')[0]}',
            ),
          ),
        );
      }

      // Add end point marker (red)
      if (routePoints.length > 1) {
        _markers.add(
          Marker(
            markerId: MarkerId('end'),
            position: routePoints.last,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: 'End Point',
              snippet: '${endDate?.toString().split(' ')[0]}',
            ),
          ),
        );
      }

      // Add vehicle marker at start point
      if (routePoints.isNotEmpty) {
        _addVehicleMarker(routePoints.first, true);
      }

      // Add stop point markers (only when no trip is selected)
      _addStopPointMarkers();

      // Add polyline
      if (routePoints.length > 1) {
        _polylines.add(
          Polyline(
            polylineId: PolylineId('route'),
            points: routePoints,
            color: Colors.blue,
            width: 3,
            geodesic: true,
          ),
        );
      }
    });

    // Fit map to show entire route
    if (routePoints.length > 1) {
      _fitMapToRoute();
    } else if (routePoints.isNotEmpty) {
      _updateMapCamera(routePoints.first);
    }
  }

  // Get actual timestamps from history data using ignition status
  Map<String, DateTime?> _getStopPointTimestamps(Trip trip, Trip? nextTrip) {
    // Get the stop point location (trip end point)
    final stopLatitude = trip.endLatitude;
    final stopLongitude = trip.endLongitude;

    // Find the exact history record with this lat/lng
    final locationHistory = historyData
        .where((data) => data.type == 'location')
        .toList();

    // Find the arrival record (exact match with stop point coordinates)
    History? arrivalRecord;
    for (final record in locationHistory) {
      if (record.latitude != null &&
          record.longitude != null &&
          record.latitude == stopLatitude &&
          record.longitude == stopLongitude) {
        arrivalRecord = record;
        break;
      }
    }

    // Find ignition off status record after arrival
    History? ignitionOffRecord;
    if (arrivalRecord != null) {
      final arrivalIndex = historyData.indexOf(arrivalRecord);
      if (arrivalIndex >= 0) {
        // Look for ignition off status after arrival
        for (int i = arrivalIndex; i < historyData.length; i++) {
          final record = historyData[i];
          if (record.type == 'status' && record.ignition == false) {
            ignitionOffRecord = record;
            break;
          }
        }
      }
    }

    // Find departure record (next location record after ignition off)
    History? departureRecord;
    if (ignitionOffRecord != null) {
      final ignitionOffIndex = historyData.indexOf(ignitionOffRecord);
      if (ignitionOffIndex >= 0) {
        // Look for next location record after ignition off
        for (int i = ignitionOffIndex; i < historyData.length; i++) {
          final record = historyData[i];
          if (record.type == 'location') {
            departureRecord = record;
            break;
          }
        }
      }
    }

    return {
      'arrival_time': arrivalRecord?.createdAt,
      'departure_time': departureRecord?.createdAt,
    };
  }

  // Calculate duration between actual history points
  Duration _calculateStopDuration() {
    if (_selectedStopTrip == null) return Duration.zero;

    final timestamps = _getStopPointTimestamps(_selectedStopTrip!, _nextTrip);
    final arrivalTime = timestamps['arrival_time'];
    final departureTime = timestamps['departure_time'];

    if (arrivalTime != null && departureTime != null) {
      return departureTime.difference(arrivalTime);
    }
    return Duration.zero;
  }

  // Add stop point markers method
  // Add stop point markers method
  void _addStopPointMarkers() async {
    if (trips.isEmpty || isTripSelected) return;

    try {
      // Load stop pin image with very small size
      final BitmapDescriptor stopPinIcon =
          await BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(size: Size(16, 16)), // Very small size
            'assets/images/stop_pin.png',
          );

      // Add stop markers for all trips except the last one
      for (int i = 0; i < trips.length - 1; i++) {
        final trip = trips[i];
        final stopPosition = LatLng(trip.endLatitude, trip.endLongitude);

        // Calculate stop duration for this trip
        final timestamps = _getStopPointTimestamps(
          trip,
          i + 1 < trips.length ? trips[i + 1] : null,
        );
        final arrivalTime = timestamps['arrival_time'];
        final departureTime = timestamps['departure_time'];

        Duration stopDuration = Duration.zero;
        if (arrivalTime != null && departureTime != null) {
          stopDuration = departureTime.difference(arrivalTime);
        }

        // Only show stop marker if duration is at least 1 minute
        if (stopDuration.inMinutes >= 1) {
          setState(() {
            _markers.add(
              Marker(
                markerId: MarkerId('stop_${trip.tripNumber}'),
                position: stopPosition,
                icon: stopPinIcon,
                anchor: const Offset(
                  0.5,
                  1.0,
                ), // Perfect alignment - center bottom
                infoWindow: InfoWindow(
                  title: 'Stop Point ${trip.tripNumber}',
                  snippet:
                      '${trip.endTime.hour}:${trip.endTime.minute.toString().padLeft(2, '0')}',
                ),
                onTap: () => _showStopPointModal(trip, i),
              ),
            );
          });
        }
      }
    } catch (e) {
      // Fallback to default marker if image loading fails
      for (int i = 0; i < trips.length - 1; i++) {
        final trip = trips[i];
        final stopPosition = LatLng(trip.endLatitude, trip.endLongitude);

        // Calculate stop duration for this trip
        final timestamps = _getStopPointTimestamps(
          trip,
          i + 1 < trips.length ? trips[i + 1] : null,
        );
        final arrivalTime = timestamps['arrival_time'];
        final departureTime = timestamps['departure_time'];

        Duration stopDuration = Duration.zero;
        if (arrivalTime != null && departureTime != null) {
          stopDuration = departureTime.difference(arrivalTime);
        }

        // Only show stop marker if duration is at least 1 minute
        if (stopDuration.inMinutes >= 1) {
          setState(() {
            _markers.add(
              Marker(
                markerId: MarkerId('stop_${trip.tripNumber}'),
                position: stopPosition,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
                onTap: () => _showStopPointModal(trip, i),
                infoWindow: InfoWindow(
                  title: 'Stop Point',
                  snippet:
                      '${trip.endTime.hour}:${trip.endTime.minute.toString().padLeft(2, '0')}',
                ),
              ),
            );
          });
        }
      }
    }
  }

  // Show stop point modal
  void _showStopPointModal(Trip trip, int tripIndex) async {
    setState(() {
      _selectedStopTrip = trip;
      _nextTrip = tripIndex + 1 < trips.length ? trips[tripIndex + 1] : null;
      _showStopModal = true;
      _isLoadingAddress = true;
    });

    // Get reverse geocode
    try {
      final address = await GeoService.getReverseGeoCode(
        trip.endLatitude,
        trip.endLongitude,
      );
      setState(() {
        _address = address;
        _isLoadingAddress = false;
      });
    } catch (e) {
      setState(() {
        _address = 'Address not available';
        _isLoadingAddress = false;
      });
    }
  }

  // Format date time nicely
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Close stop point modal
  void _closeStopModal() {
    setState(() {
      _showStopModal = false;
      _selectedStopTrip = null;
      _nextTrip = null;
      _address = '';
    });
  }

  // Format duration nicely
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  void _fitMapToRoute() {
    if (_mapController != null && routePoints.length > 1) {
      final bounds = _getBoundsForRoute();
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50.0), // 50.0 is padding
      );
    }
  }

  LatLngBounds _getBoundsForRoute() {
    double minLat = routePoints.first.latitude;
    double maxLat = routePoints.first.latitude;
    double minLng = routePoints.first.longitude;
    double maxLng = routePoints.first.longitude;

    for (final point in routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _addVehicleMarker(LatLng position, bool isStopped) async {
    try {
      // Get vehicle image path for stopped state
      final vehicleImagePath = VehicleService.imagePath(
        vehicleType: widget.vehicle.vehicleType ?? 'Car',
        vehicleState: isStopped
            ? VehicleService.stopped
            : VehicleService.running,
        imageState: VehicleImageState.live,
      );

      final BitmapDescriptor vehicleIcon =
          await BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(size: Size(60, 60)),
            vehicleImagePath,
          );

      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId('vehicle'),
            position: position, // This will be the current route position
            icon: vehicleIcon,
            rotation:
                0.0, // Vehicle marker doesn't rotate - map rotates instead
            anchor: Offset(0.5, 0.5), // Center the marker perfectly
            infoWindow: InfoWindow(
              title: 'Vehicle',
              snippet: isStopped ? 'Stopped' : 'Moving',
            ),
          ),
        );
      });
    } catch (e) {
      // Fallback to default marker if image loading fails
      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId('vehicle'),
            position: position, // This will be the current route position
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            rotation:
                0.0, // Vehicle marker doesn't rotate - map rotates instead
            anchor: Offset(0.5, 0.5), // Center the marker perfectly
            infoWindow: InfoWindow(
              title: 'Vehicle',
              snippet: isStopped ? 'Stopped' : 'Moving',
            ),
          ),
        );
      });
    }
  }

  void _updateVehiclePosition() {
    if (routePoints.isEmpty) return;

    final progress = _animation.value;
    final totalPoints = routePoints.length - 1;

    // Calculate current segment and interpolation
    final currentIndex = (progress * totalPoints).floor();
    final nextIndex = (currentIndex + 1).clamp(0, totalPoints);

    // Calculate smooth interpolation within the current segment
    final segmentProgress = (progress * totalPoints) - currentIndex;

    // Use smooth interpolation to reduce jumping
    final smoothInterpolation = _applySmoothInterpolation(segmentProgress);

    final currentPoint = routePoints[currentIndex];
    final nextPoint = routePoints[nextIndex];

    // Smooth interpolation between points
    final lat =
        currentPoint.latitude +
        (nextPoint.latitude - currentPoint.latitude) * smoothInterpolation;
    final lng =
        currentPoint.longitude +
        (nextPoint.longitude - currentPoint.longitude) * smoothInterpolation;

    final newPosition = LatLng(lat, lng);

    // Calculate bearing (rotation) for the map
    double bearing = 0.0;
    if (nextIndex > currentIndex) {
      bearing = _calculateBearing(currentPoint, nextPoint);
    }

    // Update current data for display (this updates the bottom card)
    _updateCurrentData(currentIndex, nextIndex, smoothInterpolation);

    // Perform all visual updates in a single batched operation
    _performFrameUpdate(newPosition, bearing, progress);
  }

  // Cache for vehicle icon to avoid reloading
  BitmapDescriptor? _cachedVehicleIcon;

  // Perform all visual updates in a single batched setState
  void _performFrameUpdate(
    LatLng newPosition,
    double bearing,
    double progress,
  ) {
    setState(() {
      // Update vehicle marker position
      _markers.removeWhere((marker) => marker.markerId == MarkerId('vehicle'));
      _markers.add(
        Marker(
          markerId: MarkerId('vehicle'),
          position: newPosition,
          icon:
              _cachedVehicleIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          rotation: 0.0,
          anchor: Offset(0.5, 0.5),
          infoWindow: InfoWindow(title: 'Vehicle', snippet: 'Moving'),
        ),
      );

      // Update polyline for eating effect
      _updatePolylineForAnimationInternal(progress);
    });

    // Update camera outside setState for better performance
    _moveMapAroundVehicle(newPosition, bearing);
  }

  // Cache vehicle icon for better performance
  Future<void> _cacheVehicleIcon() async {
    try {
      final vehicleImagePath = VehicleService.imagePath(
        vehicleType: widget.vehicle.vehicleType ?? 'Car',
        vehicleState: VehicleService.running,
        imageState: VehicleImageState.live,
      );

      _cachedVehicleIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(60, 60)),
        vehicleImagePath,
      );
    } catch (e) {
      // Use default marker if caching fails
      _cachedVehicleIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueBlue,
      );
    }
  }

  // Move map around vehicle marker to keep it centered
  void _moveMapAroundVehicle(LatLng position, double bearing) {
    if (_mapController == null) return;

    // Check if vehicle has moved significantly (very small threshold for responsive following)
    if (_lastCameraPosition != null) {
      final distance = _calculateDistance(_lastCameraPosition!, position);
      if (distance < 0.0000001) {
        // ~0.01 meter in degrees for very responsive visual updates
        return;
      }
    }

    _lastCameraPosition = position;

    // Use moveCamera for instant response to keep vehicle perfectly centered
    _mapController!.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position, // Keep vehicle position in center
          zoom: 16.0, // Closer zoom for slow movement
          bearing: bearing, // Rotate map to match vehicle direction
          // tilt: 45.0, // Slight tilt for better road view
        ),
      ),
    );
  }

  // Calculate distance between two LatLng points
  double _calculateDistance(LatLng point1, LatLng point2) {
    final lat1 = point1.latitude * (pi / 180);
    final lat2 = point2.latitude * (pi / 180);
    final deltaLat = (point2.latitude - point1.latitude) * (pi / 180);
    final deltaLng = (point2.longitude - point1.longitude) * (pi / 180);

    final a =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLng / 2) * sin(deltaLng / 2);
    final c = 2 * asin(sqrt(a));

    return c; // Distance in radians
  }

  // Apply smooth interpolation to reduce jumping
  double _applySmoothInterpolation(double t) {
    // Use cubic easing for smooth acceleration/deceleration
    return t * t * (3.0 - 2.0 * t); // Smoothstep 3rd order for smooth movement
  }

  // Internal polyline update method (called from batched setState)
  void _updatePolylineForAnimationInternal(double progress) {
    if (routePoints.length < 2) return;

    // Calculate how many points the vehicle has passed with more precision
    final totalPoints = routePoints.length - 1;
    final currentPointIndex = (progress * totalPoints).floor();

    // Get the current interpolated position
    final segmentProgress = (progress * totalPoints) - currentPointIndex;
    final currentPosition = _getInterpolatedPosition(
      currentPointIndex,
      segmentProgress,
    );

    // Create new polyline starting from current vehicle position
    List<LatLng> remainingPoints = [];

    // Add current interpolated position as first point
    remainingPoints.add(currentPosition);

    // Add all remaining route points after current position
    if (currentPointIndex < routePoints.length - 1) {
      remainingPoints.addAll(routePoints.skip(currentPointIndex + 1));
    }

    // Remove existing polyline and add new one
    _polylines.removeWhere(
      (polyline) => polyline.polylineId == PolylineId('route'),
    );

    // Always show polyline if there are at least 2 points (current + next)
    if (remainingPoints.length >= 2) {
      _polylines.add(
        Polyline(
          polylineId: PolylineId('route'),
          points: remainingPoints,
          color: Colors.blue,
          width: 3,
          geodesic: true,
        ),
      );
    }
  }

  // Helper method to get interpolated position between two points
  LatLng _getInterpolatedPosition(int currentIndex, double segmentProgress) {
    if (currentIndex >= routePoints.length - 1) {
      return routePoints.last;
    }

    final currentPoint = routePoints[currentIndex];
    final nextPoint = routePoints[currentIndex + 1];

    // Apply smooth interpolation
    final smoothProgress = _applySmoothInterpolation(segmentProgress);

    final lat =
        currentPoint.latitude +
        (nextPoint.latitude - currentPoint.latitude) * smoothProgress;
    final lng =
        currentPoint.longitude +
        (nextPoint.longitude - currentPoint.longitude) * smoothProgress;

    return LatLng(lat, lng);
  }

  // Restore original polyline when animation stops or completes
  void _restoreOriginalPolyline() {
    if (routePoints.length < 2) return;

    setState(() {
      _polylines.removeWhere(
        (polyline) => polyline.polylineId == PolylineId('route'),
      );

      // Restore the full original polyline
      _polylines.add(
        Polyline(
          polylineId: PolylineId('route'),
          points: routePoints,
          color: Colors.blue,
          width: 3,
          geodesic: true,
        ),
      );
    });
  }

  void _updateCurrentData(
    int currentIndex,
    int nextIndex,
    double interpolation,
  ) {
    if (historyData.isEmpty) return;

    // Get location data for current and next points
    final locationDataList = historyData
        .where((data) => data.type == 'location')
        .toList();

    if (locationDataList.isEmpty) return;

    if (currentIndex < locationDataList.length &&
        nextIndex < locationDataList.length) {
      final currentData = locationDataList[currentIndex];
      final nextData = locationDataList[nextIndex];

      // Interpolate date/time
      if (currentData.createdAt != null && nextData.createdAt != null) {
        final currentTime = currentData.createdAt!;
        final nextTime = nextData.createdAt!;
        final timeDiff = nextTime.difference(currentTime).inMilliseconds;
        final interpolatedTime = currentTime.add(
          Duration(milliseconds: (timeDiff * interpolation).round()),
        );

        setState(() {
          _currentDateTime = interpolatedTime;
        });
      }

      // Interpolate speed
      if (currentData.speed != null && nextData.speed != null) {
        final currentSpeed = currentData.speed!;
        final nextSpeed = nextData.speed!;
        final interpolatedSpeed =
            currentSpeed + (nextSpeed - currentSpeed) * interpolation;

        setState(() {
          _currentSpeed = interpolatedSpeed;
        });
      }
    }
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final double lat1 = start.latitude * (pi / 180);
    final double lat2 = end.latitude * (pi / 180);
    final double dLng = (end.longitude - start.longitude) * (pi / 180);

    final double y = sin(dLng) * cos(lat2);
    final double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);

    double bearing = atan2(y, x) * (180 / pi);
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  void _playAnimation() {
    if (routePoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No route to animate'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isPlaying = true;
    });

    // Recalculate animation duration based on current route points
    final newDuration = _calculateAnimationDuration();
    _animationController.duration = newDuration;

    // Create stationary vehicle marker at start position (only once)
    // This marker will never move - only the map moves around it
    setState(() {
      _markers.removeWhere((marker) => marker.markerId == MarkerId('vehicle'));
    });

    if (routePoints.isNotEmpty) {
      _addVehicleMarker(routePoints.first, false);
    }

    // Set camera to road level zoom at start position
    if (routePoints.isNotEmpty) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: routePoints.first,
            zoom: 18.0, // Closer zoom for slow movement
            tilt: 45.0, // Slight tilt for better road view
          ),
        ),
      );
    }

    // Wait a bit for the camera to adjust, then start animation
    Future.delayed(Duration(milliseconds: 300), () {
      _animationController.reset();
      _animationController.forward();
    });
  }

  void _stopAnimation() {
    _animationController.stop();
    setState(() {
      isPlaying = false;
    });

    // Restore original polyline when animation stops
    _restoreOriginalPolyline();
  }

  // Add toggle map type function
  void _toggleMapType() {
    setState(() {
      currentMapType = currentMapType == MapType.normal
          ? MapType.hybrid
          : MapType.normal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: BackButton(),
        title: Text(
          'History: ${widget.vehicle.vehicleNo}',
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
      ),
      drawer: TripDrawer(trips: trips, onTripSelected: _onTripSelected),
      body: Stack(
        children: [
          // Full screen map
          GoogleMap(
            mapType: currentMapType,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                widget.vehicle.latestLocation?.latitude ?? 0,
                widget.vehicle.latestLocation?.longitude ?? 0,
              ), // Default to Kathmandu
              zoom: 15.0,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
          ),

          // Map Buttons
          Positioned(
            right: 10,
            top: 20,
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

                // Trip Button
                InkWell(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
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
                    child: Icon(Icons.route, size: 25, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Bottom control panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Date pickers and buttons row
                  Row(
                    children: [
                      // Start Date
                      Expanded(
                        flex: 2,
                        child: InkWell(
                          onTap: _selectStartDate,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppTheme.secondaryColor,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: AppTheme.primaryColor,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    startDate != null
                                        ? '${startDate!.day}/${startDate!.month}/${startDate!.year}'
                                        : 'Start',
                                    style: TextStyle(
                                      color: startDate != null
                                          ? AppTheme.titleColor
                                          : AppTheme.subTitleColor,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 8),

                      // End Date
                      Expanded(
                        flex: 2,
                        child: InkWell(
                          onTap: _selectEndDate,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: startDate == null
                                    ? AppTheme.secondaryColor.withOpacity(0.5)
                                    : AppTheme.secondaryColor,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: startDate == null
                                      ? AppTheme.subTitleColor
                                      : AppTheme.primaryColor,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    endDate != null
                                        ? '${endDate!.day}/${endDate!.month}/${endDate!.year}'
                                        : 'End',
                                    style: TextStyle(
                                      color: endDate != null
                                          ? AppTheme.titleColor
                                          : AppTheme.subTitleColor,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 8),

                      // Go Button
                      SizedBox(
                        width: 50,
                        child: ElevatedButton(
                          onPressed:
                              (startDate != null &&
                                  endDate != null &&
                                  !isLoading)
                              ? _fetchHistoryData
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  height: 14,
                                  width: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Icon(Icons.search, size: 16),
                        ),
                      ),

                      SizedBox(width: 8),

                      // Play/Stop Button
                      if (routePoints.length > 1)
                        SizedBox(
                          width: 50,
                          child: ElevatedButton(
                            onPressed: isPlaying
                                ? _stopAnimation
                                : _playAnimation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPlaying
                                  ? Colors.red
                                  : AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Icon(
                              isPlaying ? Icons.stop : Icons.play_arrow,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Animation info row (shown during animation)
                  if (isPlaying && _currentDateTime != null)
                    Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Date and Time
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        color: AppTheme.primaryColor,
                                        size: 14,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '${_currentDateTime!.day}/${_currentDateTime!.month}/${_currentDateTime!.year}',
                                        style: TextStyle(
                                          color: AppTheme.titleColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        color: AppTheme.primaryColor,
                                        size: 14,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '${_currentDateTime!.hour.toString().padLeft(2, '0')}:${_currentDateTime!.minute.toString().padLeft(2, '0')}:${_currentDateTime!.second.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          color: AppTheme.titleColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Speed
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.speed,
                                        color: AppTheme.primaryColor,
                                        size: 14,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Speed',
                                        style: TextStyle(
                                          color: AppTheme.subTitleColor,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '${_currentSpeed.toStringAsFixed(1)} km/h',
                                    style: TextStyle(
                                      color: AppTheme.titleColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Date range info (when not playing)
                  if (startDate != null && endDate != null && !isPlaying)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Date Range: ${startDate!.day}/${startDate!.month}/${startDate!.year} - ${endDate!.day}/${endDate!.month}/${endDate!.year}',
                        style: TextStyle(
                          color: AppTheme.subTitleColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Map Buttons
          if (_showStopModal && _selectedStopTrip != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    margin: EdgeInsets.all(20),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: Colors.red.shade600,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stop Point',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.titleColor,
                                    ),
                                  ),
                                  if (!_isLoadingAddress)
                                    Text(
                                      _address,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.subTitleColor,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _closeStopModal,
                              icon: Icon(
                                Icons.close,
                                color: AppTheme.subTitleColor,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        // Get actual timestamps
                        Builder(
                          builder: (context) {
                            final timestamps = _getStopPointTimestamps(
                              _selectedStopTrip!,
                              _nextTrip,
                            );
                            final arrivalTime = timestamps['arrival_time'];
                            final departureTime = timestamps['departure_time'];

                            return Column(
                              children: [
                                // Arrival Time (when vehicle stopped)
                                if (arrivalTime != null)
                                  _buildTimeRow(
                                    'Arrival Time',
                                    _formatDateTime(arrivalTime),
                                    Icons.arrow_forward,
                                    Colors.orange,
                                  ),

                                if (arrivalTime != null) SizedBox(height: 8),

                                // Departure Time (when vehicle started next trip)
                                if (departureTime != null) ...[
                                  _buildTimeRow(
                                    'Departure Time',
                                    _formatDateTime(departureTime),
                                    Icons.departure_board,
                                    Colors.green,
                                  ),

                                  SizedBox(height: 8),

                                  // Duration
                                  _buildTimeRow(
                                    'Stop Duration',
                                    _formatDuration(_calculateStopDuration()),
                                    Icons.timer,
                                    Colors.blue,
                                  ),
                                ],
                              ],
                            );
                          },
                        ),

                        SizedBox(height: 16),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _closeStopModal();
                                  _showTripOnMap(_selectedStopTrip!);
                                },
                                icon: Icon(Icons.route, size: 16),
                                label: Text('View Trip'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            if (_nextTrip != null) ...[
                              SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _closeStopModal();
                                    _showTripOnMap(_nextTrip!);
                                  },
                                  icon: Icon(Icons.arrow_forward, size: 16),
                                  label: Text('Next Trip'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper method to build time rows
  Widget _buildTimeRow(String title, String time, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.subTitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.titleColor,
                    fontWeight: FontWeight.bold,
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
    _mapController?.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
