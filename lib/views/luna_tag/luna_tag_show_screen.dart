import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/luna_tag_controller.dart';
import 'package:luna_iot/models/luna_tag_model.dart';
import 'package:luna_iot/services/geo_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:luna_iot/utils/constants.dart';

class LunaTagShowScreen extends StatefulWidget {
  final String publicKey;
  const LunaTagShowScreen({super.key, required this.publicKey});

  @override
  State<LunaTagShowScreen> createState() => _LunaTagShowScreenState();
}

class _LunaTagShowScreenState extends State<LunaTagShowScreen> {
  late final LunaTagController controller;
  String? action;
  String? imageUrl;
  String? name;

  GoogleMapController? _mapController;
  Marker? _marker;
  CameraPosition? _initialCamera;

  // Playback state variables
  Set<Marker> _playbackMarkers = {};
  Set<Polyline> _playbackPolylines = {};
  List<LatLng> _routePoints = [];
  List<LunaTagData> _playbackDataPoints = [];
  MapType _currentMapType = MapType.normal;

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  
  // Animation state
  bool _isPlaying = false;
  int _currentIndex = 0;
  int _animationSpeed = 300; // Milliseconds between updates
  Timer? _animationTimer;
  DateTime? _currentDateTime;
  

  @override
  void initState() {
    super.initState();
    controller = Get.find<LunaTagController>();
    final args = Get.arguments;
    if (args is Map) {
      action = args['action'] as String?;
      imageUrl = args['image'] as String?;
      name = args['name'] as String?;
    }
    controller.fetchLatestData(widget.publicKey);
    
    // Initialize default dates for playback
    if (action == 'playback') {
      _initializeDefaultDates();
    }
  }

  void _initializeDefaultDates() {
    final today = DateTime.now();
    setState(() {
      _startDate = DateTime(today.year, today.month, today.day - 1); // Yesterday
      _endDate = DateTime(today.year, today.month, today.day); // Today
      _startTime = TimeOfDay(hour: 0, minute: 0); // 12:00 AM
      _endTime = TimeOfDay(hour: 23, minute: 59); // 11:59 PM
    });
  }

  Future<void> _selectStartDate() async {
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? today.subtract(Duration(days: 1)),
      firstDate: today.subtract(Duration(days: 30)),
      lastDate: today,
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.year, picked.month, picked.day);
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? today,
      firstDate: _startDate ?? today.subtract(Duration(days: 30)),
      lastDate: today,
    );
    if (picked != null) {
      setState(() {
        _endDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay(hour: 0, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay(hour: 23, minute: 59),
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  List<LunaTagData> _filterDataByTime(List<LunaTagData> allData) {
    if (_startTime == null || _endTime == null) {
      return allData;
    }

    return allData.where((data) {
      final createdAt = data.createdAt;
      if (createdAt == null) return false;

      final dataTime = TimeOfDay.fromDateTime(createdAt);
      final dataDate = DateTime(
        createdAt.year,
        createdAt.month,
        createdAt.day,
      );

      // Check if data is within the selected date range
      bool isWithinDateRange = true;
      if (_startDate != null && _endDate != null) {
        isWithinDateRange = (dataDate.isAtSameMomentAs(_startDate!) ||
                dataDate.isAfter(_startDate!)) &&
            (dataDate.isAtSameMomentAs(_endDate!) ||
                dataDate.isBefore(_endDate!));
      }

      if (!isWithinDateRange) return false;

      // Check if data is within the selected time range
      final dataMinutes = dataTime.hour * 60 + dataTime.minute;
      final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
      final endMinutes = _endTime!.hour * 60 + _endTime!.minute;

      return dataMinutes >= startMinutes && dataMinutes <= endMinutes;
    }).toList();
  }

  Future<void> _fetchPlaybackData() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select both start and end dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await controller.fetchPlaybackData(
        publicKey: widget.publicKey,
        startDate: _startDate!,
        endDate: _endDate!,
      );

      // Filter by time on frontend
      final filteredData = _filterDataByTime(controller.playbackData);

      if (filteredData.isEmpty) {
        setState(() {
          _routePoints = [];
          _playbackMarkers = {};
          _playbackPolylines = {};
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No data found for selected date range'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Store data points for animation
      _playbackDataPoints = filteredData;
      
      // Update map with filtered data
      _updateMapWithPlaybackData(filteredData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch playback data: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _routePoints = [];
        _playbackMarkers = {};
        _playbackPolylines = {};
      });
    }
  }

  void _updateMapWithPlaybackData(List<LunaTagData> data) {
    if (data.isEmpty) {
      setState(() {
        _routePoints = [];
        _playbackMarkers = {};
        _playbackPolylines = {};
      });
      return;
    }

    // Create route points from data (already in ascending order from backend)
    final routePoints = <LatLng>[];
    for (final d in data) {
      if (d.latitude != null && d.longitude != null) {
        routePoints.add(LatLng(d.latitude!, d.longitude!));
      }
    }

    if (routePoints.isEmpty) {
      setState(() {
        _routePoints = [];
        _playbackMarkers = {};
        _playbackPolylines = {};
      });
      return;
    }

    setState(() {
      _routePoints = routePoints;
      _playbackMarkers = {};
      _playbackPolylines = {};

      // Add start point marker (green)
      if (routePoints.isNotEmpty) {
        _playbackMarkers.add(
          Marker(
            markerId: MarkerId('start'),
            position: routePoints.first,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: 'Start Point',
              snippet: _startDate != null
                  ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                  : '',
            ),
          ),
        );
      }

      // Add end point marker (red)
      if (routePoints.length > 1) {
        _playbackMarkers.add(
          Marker(
            markerId: MarkerId('end'),
            position: routePoints.last,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: 'End Point',
              snippet: _endDate != null
                  ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                  : '',
            ),
          ),
        );
      }

      // Add polyline for all points
      if (routePoints.length > 1) {
        _playbackPolylines.add(
          Polyline(
            polylineId: PolylineId('route'),
            points: routePoints,
            color: Colors.blue,
            width: 3,
            geodesic: true,
          ),
        );
      }
      
      // Add markers for each data point (small markers, clickable) - only when not playing
      if (!_isPlaying) {
        for (int i = 0; i < data.length; i++) {
          final point = data[i];
          if (point.latitude != null && point.longitude != null) {
            _playbackMarkers.add(
              Marker(
                markerId: MarkerId('point_$i'),
                position: LatLng(point.latitude!, point.longitude!),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue,
                ),
                anchor: Offset(0.5, 0.5),
                onTap: () => _showPointInfoModal(point),
              ),
            );
          }
        }
      } else {
        // During animation, add initial animated marker at start
        if (routePoints.isNotEmpty && imageUrl != null && imageUrl!.isNotEmpty) {
          _createMarkerFromUrl(imageUrl, size: 64, addBorder: true).then((icon) {
            if (mounted) {
              setState(() {
                _playbackMarkers.add(
                  Marker(
                    markerId: MarkerId('animated'),
                    position: routePoints.first,
                    icon: icon,
                    anchor: Offset(0.5, 0.5),
                    infoWindow: InfoWindow(
                      title: name ?? 'Luna Tag',
                      snippet: 'Playing',
                    ),
                  ),
                );
              });
            }
          });
        }
      }
    });

    // Fit map to show the route
    if (routePoints.length > 1) {
      _fitMapToRoute();
    } else if (routePoints.isNotEmpty) {
      _updateMapCamera(routePoints.first);
    }
  }

  void _fitMapToRoute() {
    if (_mapController != null && _routePoints.length > 1) {
      final bounds = _getBoundsForRoute();
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50.0),
      );
    }
  }

  LatLngBounds _getBoundsForRoute() {
    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (final point in _routePoints) {
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

  void _updateMapCamera(LatLng position) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: position, zoom: 12.0),
        ),
      );
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.hybrid
          : MapType.normal;
    });
  }

  void _playAnimation() {
    if (_routePoints.length < 2) {
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
    
    // Refresh markers to show all point markers again
    if (_playbackDataPoints.isNotEmpty) {
      _updateMapWithPlaybackData(_playbackDataPoints);
    }
  }

  void _calculateAnimationSpeed() {
    if (_routePoints.isEmpty) {
      _animationSpeed = 300; // Default speed
      return;
    }

    final pointCount = _routePoints.length;

    // Adjust speed based on route length
    if (pointCount < 10) {
      _animationSpeed = 200; // Fast for short routes
    } else if (pointCount < 50) {
      _animationSpeed = 300; // Medium speed
    } else {
      _animationSpeed = 400; // Slower for long routes
    }
  }

  void _animate() {
    if (!_isPlaying) {
      return; // Stop if paused
    }

    if (_currentIndex >= _routePoints.length) {
      // Reached end of route
      _resetAnimation();
      return;
    }

    // Get current position
    final currentPosition = _routePoints[_currentIndex];

    // Update animated marker position
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      _createMarkerFromUrl(imageUrl, size: 64, addBorder: true).then((icon) {
        if (mounted && _isPlaying) {
          setState(() {
            // Remove old animated marker
            _playbackMarkers.removeWhere((marker) => marker.markerId == MarkerId('animated'));
            // Add new animated marker at current position
            _playbackMarkers.add(
              Marker(
                markerId: MarkerId('animated'),
                position: currentPosition,
                icon: icon,
                anchor: Offset(0.5, 0.5),
                infoWindow: InfoWindow(
                  title: name ?? 'Luna Tag',
                  snippet: _currentDateTime != null
                      ? _formatDateTime(_currentDateTime!)
                      : 'Playing',
                ),
              ),
            );
          });
        }
      });
    }

    // Update current date/time from data point
    if (_playbackDataPoints.isNotEmpty && _currentIndex < _playbackDataPoints.length) {
      final currentData = _playbackDataPoints[_currentIndex];
      setState(() {
        _currentDateTime = currentData.updatedAt ?? currentData.createdAt;
      });
    }

    // Check if marker is out of bounds and recenter if needed
    _checkAndRecenterIfNeeded(currentPosition);

    // Move to next position
    _currentIndex++;

    // Schedule next update
    _animationTimer = Timer(Duration(milliseconds: _animationSpeed), _animate);
  }

  void _resetAnimation() {
    setState(() {
      _isPlaying = false;
      _currentIndex = 0;
      _currentDateTime = null;
    });

    _animationTimer?.cancel();
    _animationTimer = null;
  }

  Future<bool> _isMarkerInVisibleBounds(LatLng position) async {
    if (_mapController == null) return true;

    try {
      final LatLngBounds visibleRegion = await _mapController!.getVisibleRegion();
      return position.latitude >= visibleRegion.southwest.latitude &&
          position.latitude <= visibleRegion.northeast.latitude &&
          position.longitude >= visibleRegion.southwest.longitude &&
          position.longitude <= visibleRegion.northeast.longitude;
    } catch (e) {
      return true; // On error, assume in bounds
    }
  }

  Future<void> _checkAndRecenterIfNeeded(LatLng position) async {
    final bool isInBounds = await _isMarkerInVisibleBounds(position);

    if (!isInBounds && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLng(position),
      );
    }
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  void _showPointInfoModal(LunaTagData point) async {
    // Get reverse geocode first
    String address = 'Loading...';
    if (point.latitude != null && point.longitude != null) {
      try {
        address = await GeoService.getReverseGeoCode(
          point.latitude!,
          point.longitude!,
        );
      } catch (e) {
        address = 'Address not available';
      }
    } else {
      address = 'No location data';
    }

    final time = point.updatedAt ?? point.createdAt;

    // Show AlertDialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Point Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.titleColor,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  color: AppTheme.titleColor,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.access_time, size: 20, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Time',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.subTitleColor,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              _formatDateTime(time),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.titleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, size: 20, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Address',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.subTitleColor,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              address,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.titleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  if (point.battery != null) ...[
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.battery_5_bar, size: 20, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Battery',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.subTitleColor,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '${point.battery!.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.titleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          name ?? 'Luna Tag',
          style: TextStyle(color: AppTheme.titleColor, fontSize: 14),
        ),
      ),
      body: Obx(() {
        final data = controller.latestData.value;
        if (action == 'playback') {
          return _buildPlaybackView();
        }
        if (action == 'track') {
          // Show loading while fetching data
          if (data == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading location data...'),
                ],
              ),
            );
          }
          
          // Check if location data is available
          if (data.latitude == null || data.longitude == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No location available',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => controller.fetchLatestData(widget.publicKey),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }
          
          final position = LatLng(data.latitude!, data.longitude!);
          _initialCamera ??= CameraPosition(target: position, zoom: 16);
          
          // Create marker with UserLunaTag image
          return FutureBuilder<BitmapDescriptor>(
            future: _createMarkerFromUrl(imageUrl, size: 96, addBorder: true),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading map marker...'),
                    ],
                  ),
                );
              }
              
              final icon = snapshot.data ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
              _marker = Marker(
                markerId: MarkerId(widget.publicKey),
                position: position,
                icon: icon,
                infoWindow: InfoWindow(
                  title: name ?? 'Luna Tag',
                  snippet: 'Battery: ${data.battery?.toStringAsFixed(0) ?? 'N/A'}%',
                ),
              );
              
              return GoogleMap(
                initialCameraPosition: _initialCamera!,
                markers: {if (_marker != null) _marker!},
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                onMapCreated: (controller) => _mapController = controller,
              );
            },
          );
        }
        // Default info view
        if (data == null) {
          return const Center(child: Text('No data available'));
        }
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(label: 'Battery', value: data.battery?.toStringAsFixed(2) ?? 'N/A'),
              const SizedBox(height: 8),
              _InfoRow(label: 'Latitude', value: data.latitude?.toStringAsFixed(6) ?? 'N/A'),
              const SizedBox(height: 8),
              _InfoRow(label: 'Longitude', value: data.longitude?.toStringAsFixed(6) ?? 'N/A'),
              const SizedBox(height: 8),
              _InfoRow(label: 'Updated', value: data.updatedAt?.toLocal().toString() ?? data.createdAt?.toLocal().toString() ?? 'N/A'),
              const Spacer(),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => controller.fetchLatestData(widget.publicKey),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<BitmapDescriptor> _createMarkerFromUrl(String? url, {int size = 96, bool addBorder = false}) async {
    if (url == null || url.isEmpty) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
    try {
      String fullUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        fullUrl = '${Constants.baseUrl}$url';
      }
      final uri = Uri.parse(fullUrl);
      final bundle = NetworkAssetBundle(uri);
      final byteData = await bundle.load(uri.toString());
      final bytes = byteData.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: size, targetHeight: size);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      
      if (addBorder) {
        // Create a larger canvas to accommodate the border
        const borderWidth = 5.0;
        final totalSize = size + (borderWidth * 2).toInt();
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final paint = Paint();
        
        // Draw green border circle
        paint.color = Colors.green;
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = borderWidth;
        canvas.drawCircle(
          Offset(totalSize / 2, totalSize / 2),
          size / 2 + borderWidth / 2,
          paint,
        );
        
        // Draw rounded image in the center
        final imageRect = Rect.fromLTWH(
          borderWidth,
          borderWidth,
          size.toDouble(),
          size.toDouble(),
        );
        final clipPath = Path()
          ..addRRect(RRect.fromRectAndRadius(imageRect, Radius.circular(size / 2)));
        canvas.clipPath(clipPath);
        
        paint.style = PaintingStyle.fill;
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          imageRect,
          paint,
        );
        
        // Convert to image
        final picture = recorder.endRecording();
        final borderImage = await picture.toImage(totalSize, totalSize);
        final borderData = await borderImage.toByteData(format: ui.ImageByteFormat.png);
        final borderBytes = borderData!.buffer.asUint8List();
        image.dispose();
        borderImage.dispose();
        return BitmapDescriptor.fromBytes(borderBytes);
      } else {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = data!.buffer.asUint8List();
        image.dispose();
        return BitmapDescriptor.fromBytes(pngBytes);
      }
    } catch (_) {
      return BitmapDescriptor.defaultMarker;
    }
  }

  Widget _buildPlaybackView() {
    // Get initial camera position from latest data or default
    final latestData = controller.latestData.value;
    LatLng initialPosition = LatLng(27.7172, 85.3240); // Default to Kathmandu
    if (latestData?.latitude != null && latestData?.longitude != null) {
      initialPosition = LatLng(latestData!.latitude!, latestData.longitude!);
    }

    return Column(
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
                mapType: _currentMapType,
                initialCameraPosition: CameraPosition(
                  target: initialPosition,
                  zoom: 12.0,
                ),
                markers: _playbackMarkers,
                polylines: _playbackPolylines,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
              ),

              // Map type toggle button
              Positioned(
                right: 10,
                top: 20,
                child: InkWell(
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

                      // Date and Time pickers
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
                                            _startDate != null
                                                ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                                : 'Start Date',
                                            style: TextStyle(
                                              color: _startDate != null
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
                                        color: _startDate == null
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
                                          color: _startDate == null
                                              ? AppTheme.subTitleColor
                                              : AppTheme.primaryColor,
                                          size: 18,
                                        ),
                                        SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _endDate != null
                                                ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                                : 'End Date',
                                            style: TextStyle(
                                              color: _endDate != null
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

                              // Fetch Button
                              SizedBox(width: 8),
                              SizedBox(
                                width: 50,
                                child: Obx(() => ElevatedButton(
                                  onPressed: (_startDate != null &&
                                          _endDate != null &&
                                          !controller.playbackLoading.value)
                                      ? _fetchPlaybackData
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
                                  child: controller.playbackLoading.value
                                      ? SizedBox(
                                          height: 14,
                                          width: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : Icon(Icons.search, size: 16),
                                )),
                              ),

                              // Play/Stop Button - Show only when route points exist
                              if (_routePoints.length > 1) ...[
                                SizedBox(width: 8),
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
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Icon(
                                      _isPlaying ? Icons.stop : Icons.play_arrow,
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
                                            _startTime != null
                                                ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                                                : 'Start Time',
                                            style: TextStyle(
                                              color: _startTime != null
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
                                            _endTime != null
                                                ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
                                                : 'End Time',
                                            style: TextStyle(
                                              color: _endTime != null
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
                              SizedBox(width: 50), // Spacer for alignment
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataItem({required IconData icon, required String label, required String value}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.subTitleColor,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.titleColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(value),
      ],
    );
  }
}