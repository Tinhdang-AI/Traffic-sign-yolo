import 'package:flutter/foundation.dart' show debugPrint;
import 'package:traffic_detect/models/community_report.dart';
import 'package:traffic_detect/services/database_service.dart';
import 'package:uuid/uuid.dart';

class CommunityService {
  static final CommunityService _instance = CommunityService._internal();
  final DatabaseService _dbService = DatabaseService();

  factory CommunityService() {
    return _instance;
  }

  CommunityService._internal();

  /// Create and submit a community report.
  /// Saves locally so the app works without Firebase.
  Future<String> createReport({
    required double latitude,
    required double longitude,
    required String violationType,
    required String description,
    required String reportedBy,
    required String? imageUrl,
  }) async {
    try {
      final reportId = const Uuid().v4();
      final now = DateTime.now();

      await _dbService.insertPendingReport(
        id: reportId,
        latitude: latitude,
        longitude: longitude,
        violationType: violationType,
        description: description,
        timestamp: now,
        reportedBy: reportedBy,
        imageUrl: imageUrl,
      );

      await _dbService.markReportAsSynced(reportId);

      debugPrint('✅ Report created and saved locally: $reportId');
      return reportId;
    } catch (e) {
      debugPrint('❌ Error creating report: $e');
      rethrow;
    }
  }

  /// Get nearby reports from local cache only.
  Future<List<CommunityReport>> getNearbyReports(
    double latitude,
    double longitude, {
    double radiusKm = 5.0,
  }) async {
    try {
      final localReports = await _dbService.getLocalReportsNearby(
        latitude,
        longitude,
        radiusKm: radiusKm,
      );

      return localReports.map((report) {
        return CommunityReport(
          id: report['id'] as String,
          latitude: report['latitude'] as double,
          longitude: report['longitude'] as double,
          violationType: report['violationType'] as String,
          description: report['description'] as String,
          upvotes: report['upvotes'] as int? ?? 0,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            report['timestamp'] as int,
          ),
          reportedBy: report['reportedBy'] as String,
          imageUrl: report['imageUrl'] as String?,
          isVerified: false,
        );
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Error fetching nearby reports: $e');
      return [];
    }
  }

  /// Get all reports from local cache only.
  Future<List<CommunityReport>> getAllReports() async {
    try {
      final localReports = await _dbService.getAllLocalReports();

      return localReports.map((report) {
        return CommunityReport(
          id: report['id'] as String,
          latitude: report['latitude'] as double,
          longitude: report['longitude'] as double,
          violationType: report['violationType'] as String,
          description: report['description'] as String,
          upvotes: report['upvotes'] as int? ?? 0,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            report['timestamp'] as int,
          ),
          reportedBy: report['reportedBy'] as String,
          imageUrl: report['imageUrl'] as String?,
          isVerified: false,
        );
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Error fetching all reports: $e');
      return [];
    }
  }

  /// Upvote a report locally.
  Future<void> upvoteReport(String reportId) async {
    try {
      await _dbService.incrementReportUpvotes(reportId);
      debugPrint('✅ Report upvoted locally: $reportId');
    } catch (e) {
      debugPrint('❌ Error upvoting report: $e');
      rethrow;
    }
  }

  /// Get reports by violation type from local cache.
  Future<List<CommunityReport>> getReportsByType(String violationType) async {
    try {
      final localReports = await _dbService.getAllLocalReports();
      return localReports
          .where((report) => report['violationType'] == violationType)
          .map((report) {
            return CommunityReport(
              id: report['id'] as String,
              latitude: report['latitude'] as double,
              longitude: report['longitude'] as double,
              violationType: report['violationType'] as String,
              description: report['description'] as String,
              upvotes: report['upvotes'] as int? ?? 0,
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                report['timestamp'] as int,
              ),
              reportedBy: report['reportedBy'] as String,
              imageUrl: report['imageUrl'] as String?,
              isVerified: false,
            );
          })
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching reports by type: $e');
      return [];
    }
  }
}
