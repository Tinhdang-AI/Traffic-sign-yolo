// Report & Community Reports Models
class ReportModel {
  final String id;
  final String userId;
  final String name;
  final double latitude;
  final double longitude;
  final String violationType;
  final String? description;
  final String? imageUrl;
  final String status; // pending, verified, rejected
  final bool isVerified;
  final double? aiConfidence;
  final int upvotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ReportModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.violationType,
    this.description,
    this.imageUrl,
    required this.status,
    required this.isVerified,
    this.aiConfidence,
    required this.upvotes,
    this.createdAt,
    this.updatedAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      violationType: json['violationType'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      status: json['status'] as String,
      isVerified: json['isVerified'] as bool,
      aiConfidence: json['aiConfidence'] as double?,
      upvotes: json['upvotes'] as int? ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'violationType': violationType,
      'description': description,
      'imageUrl': imageUrl,
      'status': status,
      'isVerified': isVerified,
      'aiConfidence': aiConfidence,
      'upvotes': upvotes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

// Report with distance (for nearby reports)
class NearbyReportModel extends ReportModel {
  final double distance; // in kilometers

  NearbyReportModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.latitude,
    required super.longitude,
    required super.violationType,
    required this.distance,
    super.description,
    super.imageUrl,
    required super.status,
    required super.isVerified,
    super.aiConfidence,
    required super.upvotes,
    super.createdAt,
    super.updatedAt,
  });

  factory NearbyReportModel.fromJson(Map<String, dynamic> json) {
    return NearbyReportModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      violationType: json['violationType'] as String,
      distance: (json['distance'] as num).toDouble(),
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      status: json['status'] as String,
      isVerified: json['isVerified'] as bool,
      aiConfidence: json['aiConfidence'] as double?,
      upvotes: json['upvotes'] as int? ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }
}
