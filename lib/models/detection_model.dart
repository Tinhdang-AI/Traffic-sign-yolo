// Detection History Model
class DetectionModel {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final double confidence;
  final String detectionType; // speeding, parking, running_red_light, etc
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;

  DetectionModel({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.confidence,
    required this.detectionType,
    this.metadata,
    this.createdAt,
  });

  factory DetectionModel.fromJson(Map<String, dynamic> json) {
    return DetectionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      detectionType: json['detectionType'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'confidence': confidence,
      'detectionType': detectionType,
      'metadata': metadata,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

// Heatmap Data Model
class HeatmapPointModel {
  final double latitude;
  final double longitude;
  final double intensity; // 0.0 - 1.0
  final int count;
  final String violationType;

  HeatmapPointModel({
    required this.latitude,
    required this.longitude,
    required this.intensity,
    required this.count,
    required this.violationType,
  });

  factory HeatmapPointModel.fromJson(Map<String, dynamic> json) {
    return HeatmapPointModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      intensity: (json['intensity'] as num).toDouble(),
      count: json['count'] as int,
      violationType: json['violationType'] as String,
    );
  }
}
