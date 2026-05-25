import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteStep {
  final LatLng location;
  final String instruction;
  final double distance;
  final String maneuver;

  RouteStep({
    required this.location,
    required this.instruction,
    required this.distance,
    required this.maneuver,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    final maneuverNode = json['maneuver'] ?? {};
    final locationNode = maneuverNode['location'] as List<dynamic>? ?? [0.0, 0.0];
    return RouteStep(
      location: LatLng(locationNode[1] as double, locationNode[0] as double),
      instruction: maneuverNode['instruction'] ?? '',
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      maneuver: maneuverNode['type'] ?? '',
    );
  }
}
