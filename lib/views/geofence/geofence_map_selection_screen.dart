import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:luna_iot/app/app_theme.dart';

class GeofenceMapSelectionScreen extends StatefulWidget {
  final List<Map<String, double>>? initialBoundary;

  const GeofenceMapSelectionScreen({super.key, this.initialBoundary});

  @override
  State<GeofenceMapSelectionScreen> createState() =>
      _GeofenceMapSelectionScreenState();
}

class _GeofenceMapSelectionScreenState
    extends State<GeofenceMapSelectionScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
  List<Map<String, double>> _boundaryPoints = [];
  bool _isDrawing = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialBoundary != null) {
      _boundaryPoints = List<Map<String, double>>.from(widget.initialBoundary!);
      _updateMap();
    }
  }

  void _updateMap() {
    _markers.clear();
    _polygons.clear();

    // Add markers for each boundary point
    for (int i = 0; i < _boundaryPoints.length; i++) {
      final point = _boundaryPoints[i];
      _markers.add(
        Marker(
          markerId: MarkerId('point_$i'),
          position: LatLng(point['latitude']!, point['longitude']!),
          infoWindow: InfoWindow(title: 'Point ${i + 1}'),
        ),
      );
    }

    // Add polygon if we have enough points
    if (_boundaryPoints.length >= 3) {
      _polygons.add(
        Polygon(
          polygonId: const PolygonId('boundary'),
          points: _boundaryPoints
              .map((point) => LatLng(point['latitude']!, point['longitude']!))
              .toList(),
          strokeWidth: 2,
          strokeColor: AppTheme.primaryColor,
          fillColor: AppTheme.primaryColor.withOpacity(0.2),
        ),
      );
    }

    setState(() {});
  }

  void _onMapTap(LatLng position) {
    if (_isDrawing) {
      setState(() {
        _boundaryPoints.add({
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
        _updateMap();
      });
    }
  }

  void _startDrawing() {
    setState(() {
      _isDrawing = true;
      _boundaryPoints.clear();
      _updateMap();
    });
  }

  void _stopDrawing() {
    setState(() {
      _isDrawing = false;
    });
  }

  void _undoLastPoint() {
    if (_boundaryPoints.isNotEmpty) {
      setState(() {
        _boundaryPoints.removeLast();
        _updateMap();
      });
    }
  }

  void _clearBoundary() {
    setState(() {
      _boundaryPoints.clear();
      _updateMap();
    });
  }

  void _saveBoundary() {
    if (_boundaryPoints.length < 3) {
      Get.snackbar(
        'Error',
        'Please select at least 3 points to form a boundary',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.back(result: _boundaryPoints);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Geofence Boundary'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.titleColor,
        actions: [
          if (_isDrawing)
            IconButton(
              onPressed: _stopDrawing,
              icon: const Icon(Icons.stop),
              tooltip: 'Stop Drawing',
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;

              // Set initial camera position to Nepal
              controller.animateCamera(
                CameraUpdate.newLatLngBounds(
                  LatLngBounds(
                    southwest: const LatLng(26.347, 80.058), // SW Nepal
                    northeast: const LatLng(30.447, 88.201), // NE Nepal
                  ),
                  50, // padding
                ),
              );
            },
            onTap: _onMapTap,
            markers: _markers,
            polygons: _polygons,
            initialCameraPosition: const CameraPosition(
              target: LatLng(28.3949, 84.1240), // Center of Nepal
              zoom: 7,
            ),
          ),

          // Action buttons overlay
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  onPressed: _isDrawing ? _stopDrawing : _startDrawing,
                  backgroundColor: _isDrawing
                      ? Colors.red
                      : AppTheme.primaryColor,
                  child: Icon(
                    _isDrawing ? Icons.stop : Icons.edit,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  onPressed: _undoLastPoint,
                  backgroundColor: AppTheme.warningColor,
                  child: const Icon(Icons.undo, color: Colors.white),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  onPressed: _clearBoundary,
                  backgroundColor: AppTheme.errorColor,
                  child: const Icon(Icons.clear, color: Colors.white),
                ),
              ],
            ),
          ),

          // Boundary info overlay
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Boundary Points: ${_boundaryPoints.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_boundaryPoints.isNotEmpty) ...[
                      Text(
                        'Points: ${_boundaryPoints.map((point) => '(${point['latitude']?.toStringAsFixed(6)}, ${point['longitude']?.toStringAsFixed(6)})').join(' → ')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _boundaryPoints.length >= 3
                                ? _saveBoundary
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Save Boundary'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
