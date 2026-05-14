class CommunityReport {
  final String id;
  final double latitude;
  final double longitude;
  final String violationType; // 'speeding', 'red_light', 'parking', etc.
  final String description;
  final int upvotes;
  final DateTime timestamp;
  final String reportedBy; // userId
  final String? imageUrl;
  final bool isVerified;

  CommunityReport({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.violationType,
    required this.description,
    required this.upvotes,
    required this.timestamp,
    required this.reportedBy,
    this.imageUrl,
    required this.isVerified,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'violationType': violationType,
      'description': description,
      'upvotes': upvotes,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'reportedBy': reportedBy,
      'imageUrl': imageUrl,
      'isVerified': isVerified,
    };
  }

  factory CommunityReport.fromMap(Map<String, dynamic> data) {
    return CommunityReport(
      id: data['id'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      violationType: data['violationType'] as String? ?? '',
      description: data['description'] as String? ?? '',
      upvotes: data['upvotes'] as int? ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        data['timestamp'] as int? ?? 0,
      ),
      reportedBy: data['reportedBy'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      isVerified: data['isVerified'] as bool? ?? false,
    );
  }

  CommunityReport copyWith({
    String? id,
    double? latitude,
    double? longitude,
    String? violationType,
    String? description,
    int? upvotes,
    DateTime? timestamp,
    String? reportedBy,
    String? imageUrl,
    bool? isVerified,
  }) {
    return CommunityReport(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      violationType: violationType ?? this.violationType,
      description: description ?? this.description,
      upvotes: upvotes ?? this.upvotes,
      timestamp: timestamp ?? this.timestamp,
      reportedBy: reportedBy ?? this.reportedBy,
      imageUrl: imageUrl ?? this.imageUrl,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
