import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class SpeedometerWidget extends StatelessWidget {
  final double currentSpeed;

  const SpeedometerWidget({super.key, required this.currentSpeed});

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: Colors.green.withAlpha(100),
      width: 100,
      height: 70,
      child: SfRadialGauge(
        axes: <RadialAxis>[
          RadialAxis(
            minimum: 0,
            maximum: 180,
            startAngle: 180,
            endAngle: 0,
            radiusFactor: 1,
            axisLineStyle: AxisLineStyle(
              thickness: 2,
              color: Colors.grey[300],
              thicknessUnit: GaugeSizeUnit.logicalPixel,
            ),
            showFirstLabel: true,
            showLastLabel: true,
            showLabels: true,
            axisLabelStyle: GaugeTextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
            labelsPosition: ElementsPosition.outside,
            pointers: <GaugePointer>[
              // Current speed needle (main needle)
              NeedlePointer(
                value: currentSpeed.toDouble(),
                needleColor: Colors.black,
                knobStyle: KnobStyle(
                  color: Colors.black,
                  borderColor: Colors.black,
                  borderWidth: 0.2,
                  sizeUnit: GaugeSizeUnit.logicalPixel,
                ),
                needleLength: 0.5,
                needleStartWidth: 0.1,
                needleEndWidth: 1,
              ),
            ],
            maximumLabels: 5,
            labelOffset: 5,
            annotations: [
              GaugeAnnotation(
                angle: 90,
                positionFactor: 0.45,
                widget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${currentSpeed.toInt()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'km/h',
                      style: TextStyle(fontSize: 8, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
