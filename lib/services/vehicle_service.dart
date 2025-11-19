import 'package:flutter/material.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/utils/datatype_parser.dart';
import 'package:luna_iot/utils/vehicle_image_state.dart';

class VehicleService {
  static const noData = 'nodata';
  static const inactive = 'inactive';
  static const stopped = 'stop';
  static const idle = 'idle';
  static const running = 'running';
  static const overspeed = 'overspeed';

  static const noDataColor = Colors.grey;
  static Color inactiveColor = Colors.blue.shade700;
  static Color stoppedColor = Colors.red;
  static Color idleColor = Colors.yellow.shade800;
  static Color runningColor = Colors.green.shade700;
  static Color overspeedColor = Colors.orange.shade700;

  // Get State
  static String getState(Vehicle vehicle) {
    if ((vehicle.latestStatus == null && vehicle.latestLocation == null) ||
        (vehicle.latestStatus?.ignition == null &&
            vehicle.latestLocation?.latitude == null)) {
      return noData;
    }

    // Check both status and location timestamps to find the most recent data
    DateTime? mostRecentTimestamp;

    if (vehicle.latestStatus?.updatedAt != null &&
        vehicle.latestLocation?.updatedAt != null) {
      // Both exist, use the more recent one
      if (vehicle.latestStatus!.updatedAt!.isAfter(
        vehicle.latestLocation!.updatedAt!,
      )) {
        mostRecentTimestamp = vehicle.latestStatus!.updatedAt!;
      } else {
        mostRecentTimestamp = vehicle.latestLocation!.updatedAt!;
      }
    } else if (vehicle.latestStatus?.updatedAt != null) {
      // Only status exists
      mostRecentTimestamp = vehicle.latestStatus!.updatedAt!;
    } else if (vehicle.latestLocation?.updatedAt != null) {
      // Only location exists
      mostRecentTimestamp = vehicle.latestLocation!.updatedAt!;
    }

    if (mostRecentTimestamp != null) {
      final now = DateTime.now().toUtc();
      // Handle backend timestamp - if it's not UTC, treat as Nepal time (UTC+5:45)
      DateTime updatedAt;
      if (mostRecentTimestamp.isUtc) {
        updatedAt = mostRecentTimestamp.toUtc();
      } else {
        final localTime = mostRecentTimestamp;
        updatedAt = DateTime.utc(
          localTime.year,
          localTime.month,
          localTime.day,
          localTime.hour,
          localTime.minute,
          localTime.second,
          localTime.millisecond,
        ).subtract(Duration(hours: 5, minutes: 45));
      }
      final difference = now.difference(updatedAt);

      if (difference.inHours > 12) {
        return inactive;
      }
    }

    if (vehicle.latestStatus?.ignition == false) {
      return stopped;
    }

    if (vehicle.latestStatus?.ignition == true) {
      if (DatatypeParser.parseInt(vehicle.latestLocation?.speed) != null &&
          DatatypeParser.parseInt(vehicle.latestLocation?.speed)! <= 5) {
        return idle;
      }

      if (DatatypeParser.parseInt(vehicle.latestLocation?.speed) != null &&
          DatatypeParser.parseInt(vehicle.latestLocation?.speed)! > 5) {
        if (DatatypeParser.parseInt(vehicle.speedLimit) != null &&
            DatatypeParser.parseInt(vehicle.speedLimit)! <
                DatatypeParser.parseInt(vehicle.latestLocation?.speed)!) {
          return overspeed;
        }
        return running;
      }
    }

    return noData;
  }

  // Get Color
  static Color getStateColor(String state) {
    switch (state) {
      case noData:
        return noDataColor;
      case inactive:
        return inactiveColor;
      case stopped:
        return stoppedColor;
      case idle:
        return idleColor;
      case running:
        return runningColor;
      case overspeed:
        return overspeedColor;
      default:
        return noDataColor;
    }
  }

  // Get Image path
  static String imagePath({
    required String vehicleType,
    required String vehicleState,
    required String imageState,
  }) {
    // Ensure we have valid vehicle type and state with fallbacks
    final validVehicleType = vehicleType.isNotEmpty
        ? vehicleType.toLowerCase()
        : 'car';
    final validVehicleState = vehicleState.isNotEmpty
        ? vehicleState.toLowerCase()
        : 'nodata';

    if (VehicleImageState.status == imageState) {
      return 'assets/icon/$imageState/${validVehicleType}_${validVehicleState}.png';
    }
    // return 'assets/icon/$imageState/${imageState.toLowerCase()}_arrow_${vehicleState.toLowerCase()}.png';
    return 'assets/icon/$imageState/${imageState.toLowerCase()}_${validVehicleType}_${validVehicleState}.png';
  }

  // Get Battery
  static getBattery({required int value, double size = 16}) {
    switch (value) {
      case 0:
        return Icon(Icons.battery_alert, color: Colors.red, size: size);
      case 1:
        return Icon(Icons.battery_1_bar, color: Colors.red, size: size);
      case 2:
        return Icon(Icons.battery_2_bar, color: Colors.redAccent, size: size);
      case 3:
        return Icon(
          Icons.battery_3_bar,
          color: Colors.yellow.shade700,
          size: size,
        );
      case 4:
        return Icon(
          Icons.battery_4_bar,
          color: Colors.yellow.shade700,
          size: size,
        );
      case 5:
        return Icon(Icons.battery_5_bar, color: Colors.green, size: size);
      case 6:
        return Icon(Icons.battery_full, color: Colors.green, size: size);
      default:
        return Icon(Icons.battery_unknown, color: Colors.grey, size: size);
    }
  }

  // Get Signal
  static getSignal({required int value, double size = 16}) {
    switch (value) {
      case 0:
        return Icon(
          Icons.signal_cellular_nodata_sharp,
          color: Colors.red,
          size: size,
        );
      case 1:
        return Icon(
          Icons.signal_cellular_alt_1_bar,
          color: Colors.red,
          size: size,
        );
      case 2:
        return Icon(
          Icons.signal_cellular_alt_2_bar,
          color: Colors.yellow.shade800,
          size: size,
        );
      case 3:
        return Icon(
          Icons.signal_cellular_alt_2_bar,
          color: Colors.green,
          size: size,
        );
      case 4:
        return Icon(Icons.signal_cellular_alt, color: Colors.green, size: size);
      default:
        return Icon(Icons.signal_cellular_off, color: Colors.grey, size: size);
    }
  }

  // Get Satellite
  static getSatellite({required int value, double size = 16}) {
    if (value > 4) {
      return Icon(Icons.gps_fixed, size: size, color: Colors.green);
    } else {
      return Icon(Icons.gps_off, size: size, color: Colors.grey);
    }
  }

  // Get Relay
  static getRelay({required bool? value, double size = 16}) {
    if (value == true) {
      return Icon(Icons.power, size: size, color: Colors.green);
    } else if (value == false) {
      return Icon(Icons.power_off, size: size, color: Colors.grey);
    } else {
      return Icon(Icons.power_off, size: size, color: Colors.grey);
    }
  }
}
