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

    if (vehicle.latestStatus?.createdAt != null) {
      final now = DateTime.now();
      final createdAt = vehicle.latestStatus!.createdAt!;
      final difference = now.difference(createdAt);
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
    if (VehicleImageState.status == imageState) {
      return 'assets/icon/$imageState/${vehicleType.toLowerCase()}_${vehicleState.toLowerCase()}.png';
    }
    // return 'assets/icon/$imageState/${imageState.toLowerCase()}_arrow_${vehicleState.toLowerCase()}.png';
    return 'assets/icon/$imageState/${imageState.toLowerCase()}_${vehicleType.toLowerCase()}_${vehicleState.toLowerCase()}.png';
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
}
