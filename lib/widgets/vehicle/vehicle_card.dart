import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
import 'package:luna_iot/widgets/vehicle/vehicle_card_bottom_sheet.dart';

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

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: () {
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
                  // Shared Access
                  Container(
                    margin: EdgeInsets.only(left: 5),
                    padding: EdgeInsets.symmetric(vertical: 2, horizontal: 12),
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

                  // Power Disconnected
                  vehicle.latestStatus?.charging == true
                      ? SizedBox()
                      : Container(
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
                  color: Colors.white,
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

                        // Second Data Column
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
                                  value: vehicle.latestLocation?.satellite ?? 0,
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

                        // Third Data Column
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
                                FutureBuilder(
                                  future: GeoService.getAltitude(
                                    vehicle.latestLocation?.latitude ?? 0,
                                    vehicle.latestLocation?.longitude ?? 0,
                                  ),
                                  builder: (context, snapshot) => StatsCard(
                                    title: 'Altitude',
                                    value: "${snapshot.data ?? '0'}m",
                                    icon: Icons.landscape,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Last Data Update
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

                    // Geo Reverse Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppTheme.titleColor,
                          size: 12,
                        ),
                        FutureBuilder(
                          future: vehicle.hasValidLocation
                              ? GeoService.getReverseGeoCode(
                                  vehicle.latestLocation!.latitude!,
                                  vehicle.latestLocation!.longitude!,
                                )
                              : Future.value('No location data'),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.subTitleColor,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Loading...',
                                    style: TextStyle(
                                      color: AppTheme.subTitleColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              );
                            }

                            if (snapshot.hasError) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 12,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Network error',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              );
                            }

                            final address =
                                snapshot.data ?? 'Location unavailable';
                            return Expanded(
                              child: Text(
                                address,
                                style: TextStyle(
                                  color: AppTheme.subTitleColor,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
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

  // NEW: Cached time calculation method
  String _getCachedLastUpdateTime(
    String imei,
    Map<String, dynamic>? statusData,
  ) {
    // Check if we have new socket data
    if (statusData?['createdAt'] != null) {
      try {
        final socketTime = DateTime.parse(statusData!['createdAt'].toString());

        // Check if this is new data (more recent than what we have cached)
        if (!_timestampCache.containsKey(imei) ||
            socketTime.isAfter(_timestampCache[imei]!)) {
          // Update cache with new data
          _timestampCache[imei] = socketTime;
          _timeCache[imei] = TimeAgo.timeAgo(socketTime);
          return _timeCache[imei]!;
        }
      } catch (e) {
        // If parsing fails, fall back to cached data
      }
    }

    // If no new data, check if we have cached time
    if (_timeCache.containsKey(imei)) {
      return _timeCache[imei]!;
    }

    // If no cache, calculate from vehicle data and cache it
    final vehicle = givenVehicle;
    DateTime? mostRecentTime;

    if (vehicle.latestLocation?.createdAt != null &&
        vehicle.latestStatus?.createdAt != null) {
      mostRecentTime =
          vehicle.latestLocation!.createdAt!.isAfter(
            vehicle.latestStatus!.createdAt!,
          )
          ? vehicle.latestLocation!.createdAt!
          : vehicle.latestStatus!.createdAt!;
    } else if (vehicle.latestLocation?.createdAt != null) {
      mostRecentTime = vehicle.latestLocation!.createdAt!;
    } else if (vehicle.latestStatus?.createdAt != null) {
      mostRecentTime = vehicle.latestStatus!.createdAt!;
    }

    if (mostRecentTime != null) {
      _timestampCache[imei] = mostRecentTime;
      _timeCache[imei] = TimeAgo.timeAgo(mostRecentTime);
      return _timeCache[imei]!;
    } else {
      _timeCache[imei] = 'No data available';
      return _timeCache[imei]!;
    }
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
      builder: (context) => VehicleCardBottomSheet(
        vehicle: vehicle,
        vehicleState: vehicleState ?? '',
        relayController: Get.find<RelayController>(),
      ),
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
