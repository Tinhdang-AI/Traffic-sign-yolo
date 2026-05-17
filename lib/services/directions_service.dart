// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import '../models/route_step.dart';

// class DirectionsResult {
//   final List<LatLng> points;
//   final int distanceMeters;
//   final String distanceText;
//   final int durationSeconds;
//   final String durationText;
//   final List<RouteStep> steps;

//   DirectionsResult({
//     required this.points,
//     required this.distanceMeters,
//     required this.distanceText,
//     required this.durationSeconds,
//     required this.durationText,
//     this.steps = const [],
//   });
// }

// class DirectionsService {
//   /// Call OSRM API (Open Source Routing Machine) — free, no API key required
//   static Future<DirectionsResult> getDirections({
//     required LatLng origin,
//     required LatLng destination,
//   }) async {
//     // OSRM endpoint for driving routes
//     final url = Uri.https(
//       'router.project-osrm.org',
//       '/route/v1/driving/${destination.longitude},${destination.latitude};${origin.longitude},${origin.latitude}',
//       {
//         'overview': 'full', // returns full polyline
//         'alternatives': 'false',
//         'steps': 'true', // Enable turn-by-turn steps
//         'annotations': 'duration,distance',
//         'geometries': 'geojson',
//       },
//     );

//     final resp = await http.get(url);
//     if (resp.statusCode != 200) {
//       throw Exception('OSRM API error ${resp.statusCode}: ${resp.body}');
//     }

//     final Map<String, dynamic> data = json.decode(resp.body);
//     if ((data['code'] ?? '') != 'Ok') {
//       throw Exception('OSRM API returned code ${data['code']}');
//     }

//     final route = (data['routes'] as List).first;

//     // Parse polyline from geometry (GeoJSON format)
//     final geometry = route['geometry'];
//     final points = <LatLng>[];
//     if (geometry is Map && geometry['coordinates'] is List) {
//       for (final coord in geometry['coordinates']) {
//         if (coord is List && coord.length >= 2) {
//           points.add(
//             LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble()),
//           );
//         }
//       }
//     }

//     final distanceMeters = (route['distance'] ?? 0).toInt();
//     final distanceKm = (distanceMeters / 1000).toStringAsFixed(1);
//     final distanceText = '$distanceKm km';

//     final durationSeconds = (route['duration'] ?? 0).toInt();
//     final minutes = (durationSeconds / 60).round();
//     final hours = minutes ~/ 60;
//     final mins = minutes % 60;
//     final durationText = hours > 0 ? '${hours}h ${mins}min' : '${mins}min';

//     // Parse turn-by-turn steps
//     // final steps = <RouteStep>[];
//     // final legsList = route['legs'] as List?;
//     // if (legsList != null) {
//     //   for (final leg in legsList) {
//     //     final stepsList = leg['steps'] as List?;
//     //     if (stepsList != null) {
//     //       for (final step in stepsList) {
//     //         steps.add(RouteStep.fromJson(step));
//     //       }
//     //     }
//     //   }
//     // }

//     return DirectionsResult(
//       points: points,
//       distanceMeters: distanceMeters,
//       distanceText: distanceText,
//       durationSeconds: durationSeconds,
//       durationText: durationText,
//       steps: steps,
//     );
//   }

//   // Decode polyline algorithm returns list of [lat, lng]
//   static List<List<double>> _decodePolyline(String encoded) {
//     if (encoded.isEmpty) return [];
//     final List<List<double>> poly = [];
//     int index = 0, len = encoded.length;
//     int lat = 0, lng = 0;

//     while (index < len) {
//       int shift = 0, result = 0;
//       int b;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
//       lat += dlat;

//       shift = 0;
//       result = 0;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
//       lng += dlng;

//       poly.add([lat / 1e5, lng / 1e5]);
//     }
//     return poly;
//   }
// }
