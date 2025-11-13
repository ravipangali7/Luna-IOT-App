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
import 'package:luna_iot/widgets/vehicle/school_vehicle_card_bottom_sheet.dart';
import 'package:luna_iot/app/app_routes.dart';
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

  // Helper function to safely convert int/double to double
  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Helper function to safely convert int/double to int
  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Helper function to safely convert int/string to bool
  bool? _toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lowerValue = value.toLowerCase();
      return lowerValue == 'true' || lowerValue == '1';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final socketService = Get.find<SocketService>();
      final statusData = socketService.getStatusForImei(givenVehicle.imei);
      final locationData = socketService.locationUpdates[givenVehicle.imei];

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
      DateTime? statusCreatedAt;
      DateTime? statusUpdatedAt;

      if (statusData?['createdAt'] != null) {
        try {
          statusCreatedAt = _parseSocketDateTime(statusData!['createdAt']);
        } catch (e) {
          statusCreatedAt =
              givenVehicle.latestStatus?.createdAt ?? DateTime.now();
        }
      } else {
        statusCreatedAt =
            givenVehicle.latestStatus?.createdAt ?? DateTime.now();
      }

      if (statusData?['updatedAt'] != null) {
        try {
          statusUpdatedAt = _parseSocketDateTime(statusData!['updatedAt']);
        } catch (e) {
          statusUpdatedAt =
              givenVehicle.latestStatus?.updatedAt ?? DateTime.now();
        }
      } else {
        statusUpdatedAt =
            givenVehicle.latestStatus?.updatedAt ?? DateTime.now();
      }

      vehicle.latestStatus = Status(
        imei: givenVehicle.imei,
        battery:
            statusData?['battery'] ?? givenVehicle.latestStatus?.battery ?? 0,
        signal: statusData?['signal'] ?? givenVehicle.latestStatus?.signal ?? 0,
        charging:
            _toBool(statusData?['charging']) ??
            givenVehicle.latestStatus?.charging ??
            false,
        ignition:
            _toBool(statusData?['ignition']) ??
            givenVehicle.latestStatus?.ignition ??
            false,
        relay:
            _toBool(statusData?['relay']) ??
            givenVehicle.latestStatus?.relay ??
            false,
        createdAt: statusCreatedAt,
        updatedAt: statusUpdatedAt,
      );

      // Vehicle Location Data - Use socket data if available
      DateTime? locationCreatedAt;
      DateTime? locationUpdatedAt;

      if (locationData?['createdAt'] != null) {
        try {
          locationCreatedAt = _parseSocketDateTime(locationData!['createdAt']);
        } catch (e) {
          locationCreatedAt =
              givenVehicle.latestLocation?.createdAt ?? DateTime.now();
        }
      } else {
        locationCreatedAt =
            givenVehicle.latestLocation?.createdAt ?? DateTime.now();
      }

      if (locationData?['updatedAt'] != null) {
        try {
          locationUpdatedAt = _parseSocketDateTime(locationData!['updatedAt']);
        } catch (e) {
          locationUpdatedAt =
              givenVehicle.latestLocation?.updatedAt ?? DateTime.now();
        }
      } else {
        locationUpdatedAt =
            givenVehicle.latestLocation?.updatedAt ?? DateTime.now();
      }

      // Only set latestLocation if we have valid coordinates
      final latitude =
          _toDouble(locationData?['latitude']) ??
          givenVehicle.latestLocation?.latitude;
      final longitude =
          _toDouble(locationData?['longitude']) ??
          givenVehicle.latestLocation?.longitude;

      if (latitude != null &&
          longitude != null &&
          latitude != 0.0 &&
          longitude != 0.0) {
        vehicle.latestLocation = Location(
          imei: givenVehicle.imei,
          latitude: latitude,
          longitude: longitude,
          speed:
              _toDouble(locationData?['speed']) ??
              givenVehicle.latestLocation?.speed ??
              0.0,
          course:
              _toDouble(locationData?['course']) ??
              givenVehicle.latestLocation?.course ??
              0.0,
          realTimeGps:
              locationData?['realTimeGps'] ??
              givenVehicle.latestLocation?.realTimeGps ??
              false,
          satellite:
              _toInt(locationData?['satellite']) ??
              givenVehicle.latestLocation?.satellite ??
              0,
          createdAt: locationCreatedAt,
          updatedAt: locationUpdatedAt,
        );
      } else {
        // Keep the original location if no valid coordinates
        vehicle.latestLocation = givenVehicle.latestLocation;
      }

      // Get last update time from socket or vehicle data
      final latestUpdateTime = _getLastUpdateTime(statusData, locationData);

      final String vehicleState = VehicleService.getState(vehicle);

      // Check for state change when socket data arrives
      if (statusData != null || locationData != null) {
        final imei = givenVehicle.imei;
        final previousState = _lastVehicleState[imei];

        if (previousState != null &&
            previousState != vehicleState &&
            vehicleState.isNotEmpty) {
          // State changed - reset "Since" to now
          _sinceStartTime[imei] = DateTime.now();
        }

        // Update the cached state
        _lastVehicleState[imei] = vehicleState;
      }
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

                            // Gap
                            SizedBox(height: 2),

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

                    // Last Data and Since - Only show for active vehicles
                    if (!isInactive)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Last Data
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
                          // Since
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule,
                                  color: AppTheme.titleColor,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Since: ${_getSince()}',
                                  style: TextStyle(
                                    color: AppTheme.titleColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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

  // Static cache to store socket receive timestamps and detect changes
  static final Map<String, DateTime> _socketReceiveTime = {};
  static final Map<String, String> _lastSocketDataHash = {};

  // Static cache for state change detection and "Since" tracking
  static final Map<String, String> _lastVehicleState = {};
  static final Map<String, DateTime> _sinceStartTime = {};

  // Timer-based time calculation with socket data change detection
  String _getLastUpdateTime(
    Map<String, dynamic>? statusData,
    Map<String, dynamic>? locationData,
  ) {
    final imei = givenVehicle.imei;

    // Create hash of current socket data to detect changes
    final currentHash = '${statusData?.hashCode}_${locationData?.hashCode}';

    // Check if socket data changed
    if (_lastSocketDataHash[imei] != currentHash &&
        (statusData != null || locationData != null)) {
      // Socket data changed - reset to now
      _socketReceiveTime[imei] = DateTime.now();
      _lastSocketDataHash[imei] = currentHash;
    }

    // If we have socket receive time, use it
    if (_socketReceiveTime.containsKey(imei)) {
      return TimeAgo.timeAgo(_socketReceiveTime[imei]!);
    }

    // No socket data yet - use vehicle data updatedAt timestamp
    final mostRecentTime = TimeAgo.getMostRecentTime(
      givenVehicle.latestStatus?.updatedAt,
      givenVehicle.latestLocation?.updatedAt,
    );

    if (mostRecentTime != null) {
      return TimeAgo.timeAgo(mostRecentTime);
    }

    return 'No data';
  }

  // Parse socket datetime with proper timezone handling
  static DateTime _parseSocketDateTime(dynamic value) {
    if (value == null) throw Exception('Null datetime value');

    final dateStr = value.toString();
    // Convert space to 'T' for ISO format if needed
    final isoString = dateStr.contains('T')
        ? dateStr
        : dateStr.replaceFirst(' ', 'T');

    // Parse as local time (socket sends Nepal time from server)
    return DateTime.parse(isoString);
  }

  // Helper method to get "Since" time with state change detection
  String _getSince() {
    final imei = givenVehicle.imei;

    // If we have socket-based since time (state changed), use it
    if (_sinceStartTime.containsKey(imei)) {
      return _timeAgoWithoutSeconds(_sinceStartTime[imei]!);
    }

    // No socket data yet - use vehicle data createdAt timestamp
    final statusCreated = givenVehicle.latestStatus?.createdAt;
    final locationCreated = givenVehicle.latestLocation?.createdAt;
    final mostRecent = TimeAgo.getMostRecentTime(
      statusCreated,
      locationCreated,
    );

    return mostRecent != null ? _timeAgoWithoutSeconds(mostRecent) : 'No data';
  }

  // TimeAgo without seconds for "Since" display
  String _timeAgoWithoutSeconds(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    final int days = diff.inDays;
    final int hours = diff.inHours % 24;
    final int minutes = diff.inMinutes % 60;

    // >= 24 hours: show days and hours
    if (days > 0) {
      return hours > 0 ? '$days days, $hours hrs ago' : '$days days ago';
    }
    // < 24 hours but >= 1 hour: show hours and minutes
    else if (hours > 0) {
      return minutes > 0 ? '$hours hrs, $minutes m ago' : '$hours hrs ago';
    }
    // < 1 hour but >= 1 minute: show minutes only
    else if (minutes > 0) {
      return '$minutes m ago';
    }
    // < 1 minute
    else {
      return 'Just now';
    }
  }

  // Show bottom sheet
  void _showVehicleBottomSheet(
    BuildContext context,
    Vehicle vehicle,
    String? vehicleState,
  ) {
    // Check if we're on the school vehicle screen
    final bool isSchoolVehicleScreen = Get.currentRoute == AppRoutes.schoolVehicleIndex;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Use school vehicle bottom sheet if on school vehicle screen
        if (isSchoolVehicleScreen) {
          return SchoolVehicleCardBottomSheet(
            vehicle: vehicle,
            vehicleState: vehicleState ?? '',
          );
        }

        // Otherwise use regular bottom sheet
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
      // DON'T clear cache - keep old value visible
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
                // DON'T update cache on error - keep old value
                // If no cache exists, set default
                if (_cachedAltitude == null) {
                  _cachedAltitude = '0';
                }
                _isLoading = false;
                _hasError = true;
              });
            }
          });
    }

    return StatsCard(
      title: 'Altitude',
      // Show "..." only if NO cached data exists
      value: (_isLoading && _cachedAltitude == null)
          ? '...'
          : "${_cachedAltitude ?? '0'}m",
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
      // DON'T clear cache - keep old value visible
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
                // DON'T update cache on error - keep old value
                // If no cache exists, set default
                if (_cachedAddress == null) {
                  _cachedAddress = 'Location unavailable';
                }
                _isLoading = false;
              });
            }
          });
    }

    // Show loading indicator ONLY if no cached data
    if (_isLoading && _cachedAddress == null) {
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
