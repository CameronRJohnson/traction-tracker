import 'package:flutter/material.dart';

class FillingBox extends StatelessWidget {
  final double weight;
  final double speed;
  final double lateralAcceleration;
  final String weatherCondition;

  const FillingBox({
    super.key,
    required this.weight,
    required this.speed,
    required this.lateralAcceleration,
    required this.weatherCondition,
  });

  @override
  Widget build(BuildContext context) {
    double gForceThreshold = _getThreshold(weatherCondition);

    double fillPercentage =
        (lateralAcceleration / gForceThreshold).clamp(0.0, 1.0);

    Color fillColor = _getFillColor(fillPercentage);

    return Stack(
      children: [
        Positioned.fill(
          child: ClipRect(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: fillPercentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: fillColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _getThreshold(String weatherCondition) {
    switch (weatherCondition.toLowerCase()) {
      case 'rainy':
        return 1.5;
      case 'snowy':
        return 1.2;
      default:
        return 2.0; // Default threshold
    }
  }

  Color _getFillColor(double fillPercentage) {
    if (fillPercentage <= 0.5) {
      return Color.lerp(Colors.green, Colors.yellow, fillPercentage * 2)!;
    } else {
      return Color.lerp(Colors.yellow, Colors.red, (fillPercentage - 0.5) * 2)!;
    }
  }
}
