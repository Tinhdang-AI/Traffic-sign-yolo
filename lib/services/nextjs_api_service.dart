import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'api_service.dart';

/// NestJS Backend API Service for Sentinel
class NestJsApiService {
  static final NestJsApiService _instance = NestJsApiService._internal();
  final ApiService _apiService = ApiService();
  final SupabaseClient _supabase = Supabase.instance.client;

  factory NestJsApiService() {
    return _instance;
  }

  NestJsApiService._internal() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final token = data.session?.accessToken;
      _apiService.setToken(token);
    });

    final initialToken = _supabase.auth.currentSession?.accessToken;
    if (initialToken != null) {
      _apiService.setToken(initialToken);
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      return await _apiService.post('/auth/register', {
        'email': email,
        'password': password,
        'displayName': displayName,
      });
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      return await _apiService.get('/auth/me');
    } catch (e) {
      debugPrint('Get current user error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.post('/auth/logout', {});
      _apiService.setToken(null);
    } catch (e) {
      debugPrint('Logout error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      return await _apiService.post('/auth/refresh', {
        'refreshToken': refreshToken,
      });
    } catch (e) {
      debugPrint('Refresh token error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createReport({
    required String name,
    required double latitude,
    required double longitude,
    required String violationType,
    required String description,
    String? imageUrl,
  }) async {
    try {
      return await _apiService.post('/reports', {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'violationType': violationType,
        'description': description,
        if (imageUrl != null) 'imageUrl': imageUrl,
      });
    } catch (e) {
      debugPrint('Create report error: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getAllReports({int limit = 50, int offset = 0}) async {
    try {
      final response = await _apiService.get(
        '/reports?limit=$limit&offset=$offset',
      );
      return response is List ? response : response['reports'] ?? [];
    } catch (e) {
      debugPrint('Get all reports error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getNearbyReports({
    required double latitude,
    required double longitude,
    double radiusKm = 5,
  }) async {
    try {
      return await _apiService.get(
        '/reports/nearby?latitude=$latitude&longitude=$longitude&radiusKm=$radiusKm',
      );
    } catch (e) {
      debugPrint('Get nearby reports error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> upvoteReport(String reportId) async {
    try {
      return await _apiService.post('/reports/$reportId/upvote', {});
    } catch (e) {
      debugPrint('Upvote report error: $e');
      rethrow;
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      await _apiService.delete('/reports/$reportId');
    } catch (e) {
      debugPrint('Delete report error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> recordDetection({
    required double latitude,
    required double longitude,
    required double confidence,
    required String detectionType,
    String? description,
    String? imageUrl,
  }) async {
    try {
      return await _apiService.post('/history', {
        'latitude': latitude,
        'longitude': longitude,
        'detectionType': detectionType,
        if (description != null) 'description': description,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'confidence': confidence,
      });
    } catch (e) {
      debugPrint('Record detection error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDetectionHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      return await _apiService.get(
        '/history?limit=$limit&offset=$offset',
      );
    } catch (e) {
      debugPrint('Get detection history error: $e');
      rethrow;
    }
  }

  Future<String> uploadImage(List<int> imageBytes, String filename) async {
    try {
      final path = 'reports/${DateTime.now().millisecondsSinceEpoch}_$filename';
      await _supabase.storage.from('reports').uploadBinary(path, Uint8List.fromList(imageBytes));
      return _supabase.storage.from('reports').getPublicUrl(path);
    } catch (e) {
      debugPrint('Upload image error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      return await _apiService.get('/admin/dashboard/stats');
    } catch (e) {
      debugPrint('Get dashboard stats error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAdminReports({
    String? status,
    String? violationType,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var endpoint = '/admin/reports?limit=$limit&offset=$offset';
      if (status != null) endpoint += '&status=$status';
      if (violationType != null) endpoint += '&violationType=$violationType';

      return await _apiService.get(endpoint);
    } catch (e) {
      debugPrint('Get admin reports error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateReportStatus({
    required String reportId,
    required String status,
    String? notes,
  }) async {
    try {
      return await _apiService.patch('/admin/reports/$reportId/status', {
        'status': status,
        if (notes != null) 'notes': notes,
      });
    } catch (e) {
      debugPrint('Update report status error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getHeatmapData({int limit = 1000}) async {
    try {
      return await _apiService.get('/admin/history/heatmap?limit=$limit');
    } catch (e) {
      debugPrint('Get heatmap data error: $e');
      rethrow;
    }
  }
}
