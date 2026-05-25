import 'package:flutter/foundation.dart' show debugPrint;
import 'package:traffic_detect/models/community_report.dart';
import 'package:traffic_detect/services/database_service.dart';
import 'package:traffic_detect/services/nextjs_api_service.dart';

class CommunityService {
  static final CommunityService _instance = CommunityService._internal();
  final DatabaseService _dbService = DatabaseService();
  final NestJsApiService _apiService = NestJsApiService();

  factory CommunityService() {
    return _instance;
  }

  CommunityService._internal();

  /// Create and submit a community report.
  /// Syncs with backend API and saves locally for offline support.
  Future<String> createReport({
    required String name,
    required double latitude,
    required double longitude,
    required String violationType,
    required String description,
    required String reportedBy,
    required String? imageUrl,
  }) async {
    try {
      debugPrint('📤 Creating report: $name');

      final response = await _apiService.createReport(
        name: name,
        latitude: latitude,
        longitude: longitude,
        violationType: violationType,
        description: description,
        imageUrl: imageUrl,
      );

      final reportId = response['id'] as String;
      final isVerified = response['isVerified'] as bool? ?? false;
      final aiConfidence = response['aiConfidence'] as double?;

      // Save to local cache
      await _dbService.insertPendingReport(
        id: reportId,
        latitude: latitude,
        longitude: longitude,
        violationType: violationType,
        description: description,
        timestamp: DateTime.now(),
        reportedBy: reportedBy,
        imageUrl: imageUrl,
        isVerified: isVerified,
      );

      await _dbService.markReportAsSynced(reportId);

      debugPrint('✅ Report created: $reportId (verified: $isVerified, confidence: ${aiConfidence ?? "N/A"})');
      return reportId;
    } catch (e) {
      debugPrint('❌ Error creating report: $e');
      rethrow;
    }
  }

  /// Get nearby reports from backend with local fallback.
  Future<List<CommunityReport>> getNearbyReports(
    double latitude,
    double longitude, {
    double radiusKm = 5.0,
  }) async {
    try {
      try {
        // Try to fetch from backend first
        final response = await _apiService.getNearbyReports(
          latitude: latitude,
          longitude: longitude,
          radiusKm: radiusKm,
        );

        final reports = response['reports'] as List? ?? [];
        return reports.map((report) {
          return CommunityReport(
            id: report['id'] as String,
            latitude: report['latitude'] as double,
            longitude: report['longitude'] as double,
            violationType: report['violationType'] as String,
            description: report['description'] as String,
            upvotes: report['upvotes'] as int? ?? 0,
            timestamp: DateTime.parse(report['createdAt'] as String),
            reportedBy: report['userId'] as String,
            imageUrl: report['imageUrl'] as String?,
            isVerified: report['isVerified'] as bool? ?? false,
          );
        }).toList();
      } catch (e) {
        debugPrint('⚠️ Backend error, falling back to local cache: $e');
        // Fall back to local cache
        return _getLocalNearbyReports(latitude, longitude, radiusKm);
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching nearby reports: $e');
      return [];
    }
  }

  /// Get all reports from backend with local fallback.
  Future<List<CommunityReport>> getAllReports({int limit = 50}) async {
    try {
      try {
        final response = await _apiService.getAllReports(limit: limit);
        final reports = response;

        return reports.map((report) {
          return CommunityReport(
            id: report['id'] as String,
            latitude: report['latitude'] as double,
            longitude: report['longitude'] as double,
            violationType: report['violationType'] as String,
            description: report['description'] as String,
            upvotes: report['upvotes'] as int? ?? 0,
            timestamp: DateTime.parse(report['createdAt'] as String),
            reportedBy: report['userId'] as String,
            imageUrl: report['imageUrl'] as String?,
            isVerified: report['isVerified'] as bool? ?? false,
          );
        }).toList();
      } catch (e) {
        debugPrint('⚠️ Backend error, falling back to local cache: $e');
        return _getLocalAllReports();
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching all reports: $e');
      return [];
    }
  }

  /// Upvote a report.
  Future<void> upvoteReport(String reportId) async {
    try {
      await _apiService.upvoteReport(reportId);
      // Also update local cache
      await _dbService.incrementReportUpvotes(reportId);
      debugPrint('✅ Report upvoted: $reportId');
    } catch (e) {
      debugPrint('❌ Error upvoting report: $e');
      rethrow;
    }
  }

  /// Get reports by violation type.
  Future<List<CommunityReport>> getReportsByType(String violationType) async {
    try {
      // Fetch all reports and filter locally
      final allReports = await getAllReports(limit: 100);
      return allReports.where((r) => r.violationType == violationType).toList();
    } catch (e) {
      debugPrint('❌ Error fetching reports by type: $e');
      return [];
    }
  }

  /// Delete a report.
  Future<void> deleteReport(String reportId) async {
    try {
      await _apiService.deleteReport(reportId);
      // Also delete from local cache
      await _dbService.deleteLocalReport(reportId);
      debugPrint('✅ Report deleted: $reportId');
    } catch (e) {
      debugPrint('❌ Error deleting report: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // LOCAL CACHE HELPERS
  // ─────────────────────────────────────────────

  Future<List<CommunityReport>> _getLocalNearbyReports(
    double latitude,
    double longitude,
    double radiusKm,
  ) async {
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
          timestamp: DateTime.fromMillisecondsSinceEpoch(report['timestamp'] as int),
          reportedBy: report['reportedBy'] as String,
          imageUrl: report['imageUrl'] as String?,
          isVerified: (report['isVerified'] as int? ?? 0) == 1,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching local reports: $e');
      return [];
    }
  }

  Future<List<CommunityReport>> _getLocalAllReports() async {
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
          timestamp: DateTime.fromMillisecondsSinceEpoch(report['timestamp'] as int),
          reportedBy: report['reportedBy'] as String,
          imageUrl: report['imageUrl'] as String?,
          isVerified: (report['isVerified'] as int? ?? 0) == 1,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching local reports: $e');
      return [];
    }
  }
}
