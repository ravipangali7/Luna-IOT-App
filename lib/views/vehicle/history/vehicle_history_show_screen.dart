import 'dart:async';
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
  TimeOfDay? startTime;
  TimeOfDay? endTime;
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

  // Cached location data for performance
  List<History> _cachedLocationData = [];

  // Simple vehicle playback state
  int _currentIndex = 0;
  bool _isPlaying = false;
  int _animationSpeed = 300; // Milliseconds between updates
  Timer? _animationTimer;

  // Current data during animation
  DateTime? _currentDateTime;
  double _currentSpeed = 0.0;

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
      endDate = DateTime(today.year, today.month, today.day); // Today
      startTime = TimeOfDay(hour: 0, minute: 0); // 12:00 AM
      endTime = TimeOfDay(hour: 23, minute: 59); // 11:59 PM
    });

    // Automatically fetch history data for yesterday to today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchHistoryData();
    });
  }

  void _setupAnimation() {
    // Simple setup - no complex animation controller needed
    // Animation will be handled by recursive timer
  }

  // Calculate animation speed based on route length
  void _calculateAnimationSpeed() {
    if (routePoints.isEmpty) {
      _animationSpeed = 300; // Default speed
      return;
    }

    final pointCount = routePoints.length;

    // Adjust speed based on route length
    if (pointCount < 10) {
      _animationSpeed = 200; // Fast for short routes
    } else if (pointCount < 50) {
      _animationSpeed = 300; // Medium speed
    } else {
      _animationSpeed = 400; // Slower for long routes
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
          CameraPosition(target: position, zoom: 12.0),
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
        endDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: startTime ?? TimeOfDay(hour: 0, minute: 0),
    );
    if (picked != null) {
      setState(() {
        startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: endTime ?? TimeOfDay(hour: 23, minute: 59),
    );
    if (picked != null) {
      setState(() {
        endTime = picked;
      });
    }
  }

  // Filter history data by time on frontend
  List<History> _filterHistoryByTime(List<History> allHistoryData) {
    if (startTime == null || endTime == null) {
      return allHistoryData;
    }

    return allHistoryData.where((history) {
      if (history.createdAt == null) return false;

      final historyTime = TimeOfDay.fromDateTime(history.createdAt!);
      final historyDate = DateTime(
        history.createdAt!.year,
        history.createdAt!.month,
        history.createdAt!.day,
      );

      // Check if history is within the selected date range
      bool isWithinDateRange = true;
      if (startDate != null && endDate != null) {
        isWithinDateRange =
            (historyDate.isAtSameMomentAs(startDate!) ||
                historyDate.isAfter(startDate!)) &&
            (historyDate.isAtSameMomentAs(endDate!) ||
                historyDate.isBefore(endDate!));
      }

      if (!isWithinDateRange) return false;

      // Check if history is within the selected time range
      final historyMinutes = historyTime.hour * 60 + historyTime.minute;
      final startMinutes = startTime!.hour * 60 + startTime!.minute;
      final endMinutes = endTime!.hour * 60 + endTime!.minute;

      return historyMinutes >= startMinutes && historyMinutes <= endMinutes;
    }).toList();
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
      final allHistoryData = await controller.getCombinedHistoryByDateRange(
        widget.vehicle.imei,
        startDate!,
        endDate!,
      );

      // Filter by time on frontend
      final filteredHistoryData = _filterHistoryByTime(allHistoryData);

      setState(() {
        this.historyData = filteredHistoryData;
        // Cache location data for performance
        _cachedLocationData = filteredHistoryData
            .where((data) => data.type == 'location')
            .toList();
      });

      print('Fetched ${historyData.length} history records');

      // CRITICAL: Clear map immediately if no data
      if (historyData.isEmpty) {
        setState(() {
          routePoints = [];
          _markers = {};
          _polylines = {};
          trips = [];
          // No slider to hide
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
        // No slider to hide
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
      // No slider needed

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
        double initialBearing = 0.0;
        if (routePoints.length > 1) {
          initialBearing = _calculateBearing(routePoints.first, routePoints[1]);
        }
        _addVehicleMarker(routePoints.first, true, bearing: initialBearing);
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
        // No slider to hide
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
        // No slider to hide
      });

      print('No location data found - cleared map completely');
      return;
    }

    setState(() {
      isTripSelected = false; // Reset flag when showing all history
      // No slider needed

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
        double initialBearing = 0.0;
        if (routePoints.length > 1) {
          initialBearing = _calculateBearing(routePoints.first, routePoints[1]);
        }
        _addVehicleMarker(routePoints.first, true, bearing: initialBearing);
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

      // Collect all stop markers first, then add them in one setState
      final List<Marker> stopMarkers = [];

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
          stopMarkers.add(
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
        }
      }

      // Add all stop markers in one setState call
      if (stopMarkers.isNotEmpty) {
        setState(() {
          _markers.addAll(stopMarkers);
        });
      }
    } catch (e) {
      // Fallback to default marker if image loading fails - also batched
      final List<Marker> fallbackMarkers = [];

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
          fallbackMarkers.add(
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
        }
      }

      // Add all fallback markers in one setState call
      if (fallbackMarkers.isNotEmpty) {
        setState(() {
          _markers.addAll(fallbackMarkers);
        });
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

  Future<void> _addVehicleMarker(
    LatLng position,
    bool isStopped, {
    double bearing = 0.0,
  }) async {
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
                bearing, // Rotate vehicle marker based on direction of travel
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
                bearing, // Rotate vehicle marker based on direction of travel
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

  // Cache for vehicle icon to avoid reloading
  BitmapDescriptor? _cachedVehicleIcon;

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

  // Apply simple linear interpolation for smooth performance

  // Internal polyline update method (called from batched setState)

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

  // Check if vehicle position is within visible map bounds
  Future<bool> _isVehicleInVisibleBounds(LatLng vehiclePosition) async {
    if (_mapController == null) return true;

    try {
      final LatLngBounds visibleRegion = await _mapController!
          .getVisibleRegion();

      // Check if vehicle position is within bounds
      final bool isInBounds =
          vehiclePosition.latitude >= visibleRegion.southwest.latitude &&
          vehiclePosition.latitude <= visibleRegion.northeast.latitude &&
          vehiclePosition.longitude >= visibleRegion.southwest.longitude &&
          vehiclePosition.longitude <= visibleRegion.northeast.longitude;

      return isInBounds;
    } catch (e) {
      return true; // On error, assume in bounds
    }
  }

  // Recenter camera on vehicle when it goes out of bounds
  Future<void> _recenterCameraOnVehicle(LatLng vehiclePosition) async {
    if (_mapController == null) return;

    try {
      // Only update position, preserve current zoom level and other camera properties
      await _mapController!.animateCamera(
        CameraUpdate.newLatLng(vehiclePosition),
      );
    } catch (e) {
      print('Error recentering camera: $e');
    }
  }

  // Check if vehicle is out of bounds and recenter if needed
  Future<void> _checkAndRecenterIfNeeded(LatLng vehiclePosition) async {
    final bool isInBounds = await _isVehicleInVisibleBounds(vehiclePosition);

    if (!isInBounds) {
      // Vehicle is out of frame, recenter camera
      await _recenterCameraOnVehicle(vehiclePosition);
    }
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

    if (_isPlaying) {
      _stopAnimation();
    } else {
      _startAnimation();
    }
  }

  void _startAnimation() {
    setState(() {
      _isPlaying = true;
      _currentIndex = 0; // Start from beginning
    });

    _calculateAnimationSpeed();
    _animate();
  }

  void _stopAnimation() {
    setState(() {
      _isPlaying = false;
    });

    _animationTimer?.cancel();
    _animationTimer = null;
  }

  // Core recursive animation function
  void _animate() {
    if (!_isPlaying) {
      return; // Stop if paused
    }

    if (_currentIndex >= routePoints.length) {
      // Reached end of route
      _resetAnimation();
      return;
    }

    // Get current position data
    final currentPosition = routePoints[_currentIndex];

    // Update marker position
    setState(() {
      _markers.removeWhere((marker) => marker.markerId == MarkerId('vehicle'));
      _markers.add(
        Marker(
          markerId: MarkerId('vehicle'),
          position: LatLng(currentPosition.latitude, currentPosition.longitude),
          icon:
              _cachedVehicleIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          rotation: _calculateBearingForIndex(_currentIndex),
          anchor: Offset(0.5, 0.5),
          infoWindow: InfoWindow(title: 'Vehicle', snippet: 'Moving'),
        ),
      );
    });

    // Update UI displays
    if (_cachedLocationData.isNotEmpty &&
        _currentIndex < _cachedLocationData.length) {
      final currentData = _cachedLocationData[_currentIndex];
      setState(() {
        if (currentData.createdAt != null) {
          _currentDateTime = currentData.createdAt!;
        }
        if (currentData.speed != null) {
          _currentSpeed = currentData.speed!;
        }
      });
    }

    // Check if vehicle is out of bounds and recenter if needed
    _checkAndRecenterIfNeeded(
      LatLng(currentPosition.latitude, currentPosition.longitude),
    );

    // Move to next position
    _currentIndex++;

    // Schedule next update (creates smooth animation)
    _animationTimer = Timer(Duration(milliseconds: _animationSpeed), _animate);
  }

  void _resetAnimation() {
    setState(() {
      _isPlaying = false;
      _currentIndex = 0;
      _currentSpeed = 0.0;
      _currentDateTime = null;
    });

    _animationTimer?.cancel();
    _animationTimer = null;
  }

  double _calculateBearingForIndex(int index) {
    if (index >= routePoints.length - 1) {
      return 0.0;
    }

    final currentPoint = routePoints[index];
    final nextPoint = routePoints[index + 1];
    return _calculateBearing(currentPoint, nextPoint);
  }

  // Add toggle map type function
  void _toggleMapType() {
    setState(() {
      currentMapType = currentMapType == MapType.normal
          ? MapType.hybrid
          : MapType.normal;
    });
  }

  // Add method to update slider value based on animation progress

  // Add method to handle slider changes

  // Add method to update vehicle position from slider

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
      body: Column(
        children: [
          // Data display row - only visible during playback
          if (_isPlaying && _currentDateTime != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              margin: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDataItem(
                    icon: Icons.speed,
                    label: 'Speed',
                    value: '${_currentSpeed.toStringAsFixed(1)} km/h',
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade300),
                  _buildDataItem(
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value: _currentDateTime != null
                        ? '${_currentDateTime!.day}/${_currentDateTime!.month}/${_currentDateTime!.year}'
                        : '--',
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade300),
                  _buildDataItem(
                    icon: Icons.access_time,
                    label: 'Time',
                    value: _currentDateTime != null
                        ? '${_currentDateTime!.hour.toString().padLeft(2, '0')}:${_currentDateTime!.minute.toString().padLeft(2, '0')}:${_currentDateTime!.second.toString().padLeft(2, '0')}'
                        : '--',
                  ),
                ],
              ),
            ),
          // Map widget
          Expanded(
            child: Stack(
              children: [
                // Full screen map
                GoogleMap(
                  mapType: currentMapType,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      widget.vehicle.latestLocation?.latitude ?? 0,
                      widget.vehicle.latestLocation?.longitude ?? 0,
                    ), // Default to Kathmandu
                    zoom: 12.0,
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
                          child: Icon(
                            Icons.route,
                            size: 25,
                            color: Colors.white,
                          ),
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

                        SizedBox(height: 8),

                        // Date and Time pickers (always visible)
                        Column(
                          children: [
                            // Date pickers row
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
                                                  : 'Start Date',
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
                                              ? AppTheme.secondaryColor
                                                    .withOpacity(0.5)
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
                                                  : 'End Date',
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

                                // Go Button (only when not playing)
                                if (!isPlaying) ...[
                                  SizedBox(width: 8),

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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: isLoading
                                          ? SizedBox(
                                              height: 14,
                                              width: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : Icon(Icons.search, size: 16),
                                    ),
                                  ),

                                  SizedBox(width: 8),
                                ],

                                // Play/Stop Button (always visible when route points exist)
                                if (routePoints.length > 1) ...[
                                  SizedBox(
                                    width: 50,
                                    child: ElevatedButton(
                                      onPressed: _playAnimation,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isPlaying
                                            ? Colors.red
                                            : AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Icon(
                                        _isPlaying
                                            ? Icons.stop
                                            : Icons.play_arrow,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            SizedBox(height: 8),

                            // Time pickers row
                            Row(
                              children: [
                                // Start Time
                                Expanded(
                                  flex: 2,
                                  child: InkWell(
                                    onTap: _selectStartTime,
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
                                            Icons.access_time,
                                            color: AppTheme.primaryColor,
                                            size: 18,
                                          ),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              startTime != null
                                                  ? '${startTime!.format(context)}'
                                                  : 'Start Time',
                                              style: TextStyle(
                                                color: startTime != null
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

                                // End Time
                                Expanded(
                                  flex: 2,
                                  child: InkWell(
                                    onTap: _selectEndTime,
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
                                            Icons.access_time,
                                            color: AppTheme.primaryColor,
                                            size: 18,
                                          ),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              endTime != null
                                                  ? '${endTime!.format(context)}'
                                                  : 'End Time',
                                              style: TextStyle(
                                                color: endTime != null
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

                                // Spacer to align with buttons above
                                SizedBox(width: 50),
                                SizedBox(width: 8),
                                if (routePoints.length > 1) SizedBox(width: 50),
                              ],
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                              'Range: ${startDate!.day}/${startDate!.month}/${startDate!.year} ${startTime?.format(context) ?? '12:00 AM'} - ${endDate!.day}/${endDate!.month}/${endDate!.year} ${endTime?.format(context) ?? '11:59 PM'}',
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                  final arrivalTime =
                                      timestamps['arrival_time'];
                                  final departureTime =
                                      timestamps['departure_time'];

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

                                      if (arrivalTime != null)
                                        SizedBox(height: 8),

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
                                          _formatDuration(
                                            _calculateStopDuration(),
                                          ),
                                          Icons.timer,
                                          Colors.blue,
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),

                              SizedBox(height: 8),

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
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                        icon: Icon(
                                          Icons.arrow_forward,
                                          size: 16,
                                        ),
                                        label: Text('Next Trip'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
          ),
        ],
      ),
    );
  }

  // Helper method to build data items for the display row
  Widget _buildDataItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.blue.shade700),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
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
    _animationTimer?.cancel();
    super.dispose();
  }
}
