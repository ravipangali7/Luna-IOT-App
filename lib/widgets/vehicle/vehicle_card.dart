import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/relay_api_service.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/controllers/relay_controller.dart';
import 'package:luna_iot/models/location_model.dart';
import 'package:luna_iot/models/status_model.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/services/geo_service.dart';
import 'package:luna_iot/services/socket_service.dart';
import 'package:luna_iot/services/vehicle_service.dart';
import 'package:luna_iot/utils/time_ago.dart';
import 'package:luna_iot/utils/vehicle_image_state.dart';
import 'package:luna_iot/utils/vehicle_utils.dart';
import 'package:luna_iot/widgets/vehicle/vehicle_card_bottom_sheet.dart';
import 'package:luna_iot/widgets/simple_marquee_widget.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle givenVehicle;
  final bool isManualCallback;
  final Function? callback;

  const VehicleCard({
    super.key,
    required this.givenVehicle,
    this.isManualCallback = false,
    this.callback,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final socketService = Get.find<SocketService>();
      final statusData = socketService.getStatusForImei(givenVehicle.imei);

      final vehicle = Vehicle(imei: givenVehicle.imei);

      // Use socket data if available, otherwise use vehicle's existing data
      // Vehicle Data
      vehicle.name = givenVehicle.name;
      vehicle.vehicleNo = givenVehicle.vehicleNo;
      vehicle.vehicleType = givenVehicle.vehicleType;
      vehicle.odometer = givenVehicle.odometer;
      vehicle.mileage = givenVehicle.mileage;
      vehicle.speedLimit = givenVehicle.speedLimit;
      vehicle.minimumFuel = givenVehicle.minimumFuel;
      vehicle.todayKm = givenVehicle.todayKm;
      vehicle.ownershipType = givenVehicle.ownershipType;
      vehicle.userVehicle = givenVehicle.userVehicle;
      vehicle.isActive = givenVehicle.isActive; // Copy the isActive field
      vehicle.device = givenVehicle.device; // Copy the device field - FIXED!

      // Vehicle Status Data
      vehicle.latestStatus = Status(
        imei: givenVehicle.imei,
        battery:
            statusData?['battery'] ?? givenVehicle.latestStatus?.battery ?? 0,
        signal: statusData?['signal'] ?? givenVehicle.latestStatus?.signal ?? 0,
        charging:
            statusData?['charging'] ??
            givenVehicle.latestStatus?.charging ??
            false,
        ignition:
            statusData?['ignition'] ??
            givenVehicle.latestStatus?.ignition ??
            false,
        relay:
            statusData?['relay'] ?? givenVehicle.latestStatus?.relay ?? false,
        createdAt:
            (statusData?['createdAt'] != null
                ? DateTime.parse(statusData!['createdAt'].toString())
                : givenVehicle.latestStatus?.createdAt) ??
            DateTime.now(),
      );

      // Vehicle Location Data
      vehicle.latestLocation = Location(
        imei: givenVehicle.imei,
        latitude: givenVehicle.latestLocation?.latitude ?? 0,
        longitude: givenVehicle.latestLocation?.longitude ?? 0,
        speed: givenVehicle.latestLocation?.speed ?? 0,
        course: givenVehicle.latestLocation?.course ?? 0,
        realTimeGps: givenVehicle.latestLocation?.realTimeGps ?? false,
        satellite: givenVehicle.latestLocation?.satellite ?? 0,
        createdAt: givenVehicle.latestLocation?.createdAt ?? DateTime.now(),
      );

      // FIXED: Use cached time that only updates when there's new data
      final latestUpdateTime = _getCachedLastUpdateTime(
        givenVehicle.imei,
        statusData,
      );

      final String vehicleState = VehicleService.getState(vehicle);
      final bool isInactive = !vehicle.isVehicleActive;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: () {
            if (isInactive) {
              // Show inactive vehicle modal instead of navigating
              VehicleUtils.showInactiveVehicleModal(
                vehicle: vehicle,
                action: 'Live Tracking',
              );
              return;
            }

            if (isManualCallback) {
              callback?.call();
            } else {
              _showVehicleBottomSheet(context, vehicle, vehicleState);
            }
          },
          child: Column(
            children: [
              Row(
                children: [
                  // Inactive Badge
                  if (isInactive)
                    Container(
                      margin: EdgeInsets.only(left: 5),
                      padding: EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 12,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        'INACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 8,
                        ),
                      ),
                    ),

                  // Shared Access - Only show for active vehicles
                  if (!isInactive)
                    Container(
                      margin: EdgeInsets.only(left: 5),
                      padding: EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 12,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.purple.shade600,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        vehicle.ownershipType?.toUpperCase() ?? '',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 8,
                        ),
                      ),
                    ),

                  // Power Disconnected - Only show for active vehicles
                  if (!isInactive && vehicle.latestStatus?.charging == true)
                    SizedBox()
                  else if (!isInactive)
                    Container(
                      margin: EdgeInsets.only(left: 5),
                      padding: EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 12,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: vehicle.latestStatus?.charging == true
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        vehicle.latestStatus?.charging == true
                            ? 'POWER CONNECTED'
                            : 'POWER DISCONNECTED',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 8,
                        ),
                      ),
                    ),
                ],
              ),

              // Main Part
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isInactive ? Colors.grey.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      spreadRadius: -10,
                      blurRadius: 30,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: Column(
                  spacing: 3,
                  children: [
                    // Main Design Part
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // First Data Column
                        Column(
                          children: [
                            // Vehicle Image
                            Image.asset(
                              VehicleService.imagePath(
                                vehicleType: vehicle.vehicleType ?? 'car',
                                vehicleState: vehicleState,
                                imageState: VehicleImageState.status,
                              ),

                              width: 80,
                            ),

                            // Gap
                            SizedBox(height: 5),

                            // Vehicle No.
                            SizedBox(
                              width: 100,
                              child: Text(
                                vehicle.vehicleNo ?? '',
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.titleColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // Gap
                            SizedBox(height: 2),

                            // Vehicle Name
                            SizedBox(
                              width: 100,
                              child: Text(
                                vehicle.name ?? '',
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.subTitleColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Second Data Column - Only show for active vehicles
                        if (!isInactive)
                          Column(
                            spacing: 8,
                            children: [
                              // Speed
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: VehicleService.getStateColor(
                                    vehicleState,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      spacing: 5,
                                      children: [
                                        Icon(
                                          Icons.speed,
                                          color: Colors.white,
                                          size: 15,
                                        ),
                                        Text(
                                          '${vehicleState == VehicleService.stopped ? 0 : vehicle.latestLocation?.speed ?? 0} km/h',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),

                                    Text(
                                      vehicleState.toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Battery, Signal and Satellite
                              Row(
                                spacing: 8,
                                children: [
                                  VehicleService.getSatellite(
                                    value:
                                        vehicle.latestLocation?.satellite ?? 0,
                                  ),
                                  VehicleService.getBattery(
                                    value: vehicle.latestStatus?.battery ?? 0,
                                  ),
                                  VehicleService.getSignal(
                                    value: vehicle.latestStatus?.signal ?? 0,
                                  ),
                                ],
                              ),
                            ],
                          ),

                        // Third Data Column - Only show for active vehicles
                        if (!isInactive)
                          Column(
                            spacing: 5,
                            children: [
                              Row(
                                spacing: 5,
                                children: [
                                  StatsCard(
                                    title: 'Today',
                                    value:
                                        '${vehicle.todayKm?.toStringAsFixed(2) ?? 999}Km',
                                    icon: Icons.today,
                                    color: Colors.blue.shade800,
                                  ),
                                  StatsCard(
                                    title: 'Fuel',
                                    value:
                                        '${((vehicle.todayKm ?? 0) / (vehicle.mileage ?? 1)).toStringAsFixed(2)}L',
                                    icon: Icons.local_gas_station,
                                    color: Colors.orange.shade800,
                                  ),
                                ],
                              ),
                              Row(
                                spacing: 5,
                                children: [
                                  StatsCard(
                                    title: 'ODO',
                                    value: '${vehicle.odometer}Km',
                                    icon: Icons.straighten,
                                    color: Colors.purple.shade800,
                                  ),
                                  _AltitudeWidget(
                                    latitude:
                                        vehicle.latestLocation?.latitude ?? 0,
                                    longitude:
                                        vehicle.latestLocation?.longitude ?? 0,
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),

                    // Last Data Update - Only show for active vehicles
                    if (!isInactive)
                      Row(
                        children: [
                          Icon(
                            Icons.update,
                            color: AppTheme.titleColor,
                            size: 12,
                          ),
                          Text(
                            latestUpdateTime,
                            style: TextStyle(
                              color: AppTheme.subTitleColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                    // Geo Reverse Location - Only show for active vehicles
                    if (!isInactive)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppTheme.titleColor,
                            size: 12,
                          ),
                          _GeocodeWidget(
                            latitude: vehicle.latestLocation?.latitude,
                            longitude: vehicle.latestLocation?.longitude,
                            hasValidLocation: vehicle.hasValidLocation,
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
    });
  }

  // Static cache to store time for each vehicle
  static final Map<String, String> _timeCache = {};
  static final Map<String, DateTime> _timestampCache = {};

  // Unified cached time calculation method
  String _getCachedLastUpdateTime(
    String imei,
    Map<String, dynamic>? statusData,
  ) {
    DateTime? socketTime;

    // Check if we have new socket data
    if (statusData?['createdAt'] != null) {
      try {
        socketTime = DateTime.parse(statusData!['createdAt'].toString());
      } catch (e) {
        // If parsing fails, socketTime remains null
      }
    }

    // Use unified calculation method
    final timeString = TimeAgo.calculateLastUpdateTime(
      statusTime: givenVehicle.latestStatus?.createdAt,
      locationTime: givenVehicle.latestLocation?.createdAt,
      socketTime: socketTime,
    );

    // Update cache if we have new socket data or no cache exists
    if (socketTime != null) {
      if (!_timestampCache.containsKey(imei) ||
          socketTime.isAfter(_timestampCache[imei]!)) {
        _timestampCache[imei] = socketTime;
        _timeCache[imei] = timeString;
      }
    } else if (!_timeCache.containsKey(imei)) {
      // Cache the calculated time from vehicle data
      final mostRecentTime = TimeAgo.getMostRecentTime(
        givenVehicle.latestStatus?.createdAt,
        givenVehicle.latestLocation?.createdAt,
      );
      if (mostRecentTime != null) {
        _timestampCache[imei] = mostRecentTime;
      }
      _timeCache[imei] = timeString;
    }

    return _timeCache[imei] ?? timeString;
  }

  // Show bottom sheet
  void _showVehicleBottomSheet(
    BuildContext context,
    Vehicle vehicle,
    String? vehicleState,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        try {
          final relayController = Get.find<RelayController>();
          return VehicleCardBottomSheet(
            vehicle: vehicle,
            vehicleState: vehicleState ?? '',
            relayController: relayController,
          );
        } catch (e) {
          print('RelayController not found, creating new one: $e');
          // Create a new RelayController if not found
          final apiClient = Get.find<ApiClient>();
          final relayApiService = RelayApiService(apiClient);
          final relayController = RelayController();
          Get.put(relayApiService);
          Get.put(relayController);

          return VehicleCardBottomSheet(
            vehicle: vehicle,
            vehicleState: vehicleState ?? '',
            relayController: relayController,
          );
        }
      },
    );
  }
}

// Stats Card Widget
class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 65,
      height: 80,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          Text(title, style: TextStyle(color: color, fontSize: 9)),
          Text(
            value,
            textAlign: TextAlign.center,
            overflow: TextOverflow.clip,
            style: TextStyle(color: Colors.black, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

// Custom Altitude Widget with coordinate-based caching
class _AltitudeWidget extends StatefulWidget {
  final double latitude;
  final double longitude;

  const _AltitudeWidget({required this.latitude, required this.longitude});

  @override
  State<_AltitudeWidget> createState() => _AltitudeWidgetState();
}

class _AltitudeWidgetState extends State<_AltitudeWidget> {
  String? _cachedAltitude;
  String? _lastCoordinates;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    final currentCoords = '${widget.latitude}_${widget.longitude}';

    // Only fetch if coordinates changed or no cache exists
    if (_lastCoordinates != currentCoords ||
        (_cachedAltitude == null && !_isLoading && !_hasError)) {
      _lastCoordinates = currentCoords;
      _cachedAltitude = null;
      _isLoading = true;
      _hasError = false;

      // Fetch altitude asynchronously with error handling
      GeoService.getAltitude(widget.latitude, widget.longitude)
          .then((altitude) {
            if (mounted && _lastCoordinates == currentCoords) {
              setState(() {
                _cachedAltitude = altitude;
                _isLoading = false;
                _hasError = false;
              });
            }
          })
          .catchError((error) {
            if (mounted && _lastCoordinates == currentCoords) {
              setState(() {
                _cachedAltitude = '0'; // Default value on error
                _isLoading = false;
                _hasError = true;
              });
            }
          });
    }

    return StatsCard(
      title: 'Altitude',
      value: _isLoading ? '...' : "${_cachedAltitude ?? '0'}m",
      icon: Icons.landscape,
      color: _hasError ? Colors.grey.shade800 : Colors.green.shade800,
    );
  }
}

// Custom Geocode Widget with coordinate-based caching
class _GeocodeWidget extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final bool hasValidLocation;

  const _GeocodeWidget({
    required this.latitude,
    required this.longitude,
    required this.hasValidLocation,
  });

  @override
  State<_GeocodeWidget> createState() => _GeocodeWidgetState();
}

class _GeocodeWidgetState extends State<_GeocodeWidget> {
  String? _cachedAddress;
  String? _lastCoordinates;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.hasValidLocation ||
        widget.latitude == null ||
        widget.longitude == null) {
      return Expanded(
        child: Text(
          'No location data',
          style: TextStyle(color: AppTheme.subTitleColor, fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    final currentCoords = '${widget.latitude}_${widget.longitude}';

    // Only fetch if coordinates changed or no cache exists
    if (_lastCoordinates != currentCoords ||
        (_cachedAddress == null && !_isLoading)) {
      _lastCoordinates = currentCoords;
      _cachedAddress = null;
      _isLoading = true;

      // Fetch geocode asynchronously
      GeoService.getReverseGeoCode(widget.latitude!, widget.longitude!)
          .then((address) {
            if (mounted && _lastCoordinates == currentCoords) {
              setState(() {
                _cachedAddress = address;
                _isLoading = false;
              });
            }
          })
          .catchError((error) {
            if (mounted && _lastCoordinates == currentCoords) {
              setState(() {
                _cachedAddress = 'Location unavailable';
                _isLoading = false;
              });
            }
          });
    }

    if (_isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.subTitleColor),
            ),
          ),
          SizedBox(width: 4),
          Text(
            'Loading...',
            style: TextStyle(color: AppTheme.subTitleColor, fontSize: 12),
          ),
        ],
      );
    }

    if (_cachedAddress == null) {
      return Expanded(
        child: Text(
          'Location unavailable',
          style: TextStyle(color: AppTheme.subTitleColor, fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Expanded(
      child: SimpleMarqueeText(
        text: _cachedAddress!,
        style: TextStyle(color: AppTheme.subTitleColor, fontSize: 12),
        scrollAxisExtent: 200.0,
        scrollDuration: Duration(seconds: 10),
        autoStart: true,
      ),
    );
  }
}
