import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

enum HazardType {
  speedCamera,
  construction,
  accident,
  policeCheckpoint,
  heavyTraffic,
  flooding,
  potholes,
  other,
}

class TrafficHazard {
  final String id;
  final HazardType type;
  final LatLng location;
  final String description;
  final DateTime reportedAt;
  final int upvotes;
  final bool isExpired; // Hazards older than 24 hours are expired

  TrafficHazard({
    required this.id,
    required this.type,
    required this.location,
    required this.description,
    required this.reportedAt,
    this.upvotes = 0,
    bool? isExpired,
  }) : isExpired = isExpired ?? _isOlderThan24Hours(reportedAt);

  static bool _isOlderThan24Hours(DateTime dateTime) {
    return DateTime.now().difference(dateTime) > const Duration(hours: 24);
  }

  String get hazardEmoji {
    switch (type) {
      case HazardType.speedCamera:
        return '📷';
      case HazardType.construction:
        return '🚧';
      case HazardType.accident:
        return '⚠️';
      case HazardType.policeCheckpoint:
        return '🚔';
      case HazardType.heavyTraffic:
        return '🚗';
      case HazardType.flooding:
        return '💧';
      case HazardType.potholes:
        return '🕳️';
      case HazardType.other:
        return '❗';
    }
  }

  String get hazardName {
    switch (type) {
      case HazardType.speedCamera:
        return 'Radar tốc độ';
      case HazardType.construction:
        return 'Công trình đường bộ';
      case HazardType.accident:
        return 'Tai nạn';
      case HazardType.policeCheckpoint:
        return 'Kiểm soát giao thông';
      case HazardType.heavyTraffic:
        return 'Ùn tắc';
      case HazardType.flooding:
        return 'Ngập nước';
      case HazardType.potholes:
        return 'Ổ gà';
      case HazardType.other:
        return 'Khác';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'location': {'lat': location.latitude, 'lng': location.longitude},
      'description': description,
      'reportedAt': reportedAt.toIso8601String(),
      'upvotes': upvotes,
    };
  }

  factory TrafficHazard.fromJson(Map<String, dynamic> json) {
    final type = HazardType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => HazardType.other,
    );

    return TrafficHazard(
      id: json['id'] as String,
      type: type,
      location: LatLng(
        (json['location']['lat'] as num).toDouble(),
        (json['location']['lng'] as num).toDouble(),
      ),
      description: json['description'] as String,
      reportedAt: DateTime.parse(json['reportedAt'] as String),
      upvotes: json['upvotes'] as int? ?? 0,
    );
  }
}

class TrafficHazardService {
  static final TrafficHazardService _instance =
      TrafficHazardService._internal();

  factory TrafficHazardService() {
    return _instance;
  }

  TrafficHazardService._internal();

  // In a real app, these would connect to a backend Firebase/REST API
  final List<TrafficHazard> _hazards = [];

  /// Get hazards near a location (within 5km)
  Future<List<TrafficHazard>> getHazardsNearby(LatLng center) async {
    // Filter expired hazards
    final activeHazards = _hazards.where((h) => !h.isExpired).toList();

    // Calculate distance and filter
    return activeHazards.where((hazard) {
      final distance = _calculateDistance(center, hazard.location);
      return distance < 5000; // 5km
    }).toList();
  }

  /// Report a new hazard
  Future<void> reportHazard(TrafficHazard hazard) async {
    try {
      // In real app: POST to backend
      _hazards.add(hazard);
      print('Hazard reported: ${hazard.hazardName}');
    } catch (e) {
      print('Error reporting hazard: $e');
      rethrow;
    }
  }

  /// Upvote a hazard
  Future<void> upvoteHazard(String hazardId) async {
    try {
      final index = _hazards.indexWhere((h) => h.id == hazardId);
      if (index != -1) {
        // In real app: POST to backend
        print('Upvoted hazard: $hazardId');
      }
    } catch (e) {
      print('Error upvoting hazard: $e');
    }
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const earthRadius = 6371000; // meters
    final dLat = _toRadians(p2.latitude - p1.latitude);
    final dLng = _toRadians(p2.longitude - p1.longitude);
    final a =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_toRadians(p1.latitude)) *
            math.cos(_toRadians(p2.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2));
    final c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }
}
