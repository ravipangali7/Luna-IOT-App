import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:luna_iot/models/vehicle_model.dart';
import 'package:luna_iot/services/vehicle_service.dart';

class SpeedometerWidget extends StatelessWidget {
  final Vehicle vehicle;

  const SpeedometerWidget({super.key, required this.vehicle});

  // Get current speed from vehicle location
  double get currentSpeed {
    return vehicle.latestLocation?.speed?.toDouble() ?? 0.0;
  }

  // Get vehicle state using VehicleService
  String get vehicleState {
    return VehicleService.getState(vehicle);
  }

  // Get status color using VehicleService
  Color get statusColor {
    return VehicleService.getStateColor(vehicleState);
  }

  // Check if vehicle is stopped or inactive
  bool get isStoppedOrInactive {
    return vehicleState == VehicleService.stopped ||
        vehicleState == VehicleService.inactive;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 10, right: 10, top: 10),
      child: SizedBox(
        width: 80,
        height: 70,
        child: SfRadialGauge(
          enableLoadingAnimation: true,
          animationDuration: 1500,
          axes: <RadialAxis>[
            RadialAxis(
              minimum: 0,
              maximum: 150,
              radiusFactor: 1,
              startAngle: 170,
              endAngle: 10,
              showLabels: false,
              ranges: <GaugeRange>[
                GaugeRange(
                  startValue: 0,
                  endValue: 150,
                  color: statusColor,
                  startWidth: 5,
                  endWidth: 5,
                ),
              ],
              pointers: <GaugePointer>[
                NeedlePointer(
                  value: isStoppedOrInactive ? 0.0 : currentSpeed,
                  needleEndWidth: 2,
                  needleColor: statusColor,
                ),
              ],
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(
                  widget: Container(
                    margin: EdgeInsets.only(top: 10),
                    child: Text(
                      isStoppedOrInactive
                          ? '0 Km/h'
                          : '${currentSpeed.toInt()} Km/h',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  angle: 90,
                  positionFactor: 0.5,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
