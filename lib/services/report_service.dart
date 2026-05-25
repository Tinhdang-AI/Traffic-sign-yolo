import 'api_client.dart';
import '../models/report_model.dart';

class ReportService {
  final ApiClient _apiClient;

  ReportService(this._apiClient);

  // ─── Create Report ──────────────────────────────────────────────────────────
  Future<ReportModel> createReport({
    required String name,
    required double latitude,
    required double longitude,
    required String violationType,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final response = await _apiClient.post(
        '/reports',
        {
          'name': name,
          'latitude': latitude,
          'longitude': longitude,
          'violationType': violationType,
          if (description != null) 'description': description,
          if (imageUrl != null) 'imageUrl': imageUrl,
        },
      );
      return ReportModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // ─── Get All Reports ────────────────────────────────────────────────────────
  Future<List<ReportModel>> getAllReports({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get(
        '/reports?limit=$limit&offset=$offset',
      );
      final List<dynamic> data = response['reports'] ?? [];
      return data.map((item) => ReportModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // ─── Get Nearby Reports ─────────────────────────────────────────────────────
  Future<List<NearbyReportModel>> getNearbyReports({
    required double latitude,
    required double longitude,
    double radiusKm = 5,
  }) async {
    try {
      final response = await _apiClient.get(
        '/reports/nearby?latitude=$latitude&longitude=$longitude&radiusKm=$radiusKm',
      );
      final List<dynamic> data = response['reports'] ?? [];
      return data.map((item) => NearbyReportModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // ─── Upvote Report ──────────────────────────────────────────────────────────
  Future<void> upvoteReport(String reportId) async {
    try {
      await _apiClient.post('/reports/$reportId/upvote', null);
    } catch (e) {
      rethrow;
    }
  }

  // ─── Delete Report ──────────────────────────────────────────────────────────
  Future<void> deleteReport(String reportId) async {
    try {
      await _apiClient.delete('/reports/$reportId');
    } catch (e) {
      rethrow;
    }
  }
}
