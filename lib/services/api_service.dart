import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // Use computer's local Wi-Fi IP instead of localhost so physical phones/emulators can reach the backend
  static const String baseUrl = 'http://192.168.1.109:3000/api/v1';
  static const Duration timeout = Duration(seconds: 30);

  final http.Client _httpClient;

  ApiService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _httpClient
          .get(uri, headers: _buildHeaders())
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('GET $endpoint Error: $e');
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _httpClient
          .post(
            uri,
            headers: _buildHeaders(),
            body: jsonEncode(data),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('POST $endpoint Error: $e');
      rethrow;
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _httpClient
          .patch(
            uri,
            headers: _buildHeaders(),
            body: jsonEncode(data),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('PATCH $endpoint Error: $e');
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _httpClient
          .put(
            uri,
            headers: _buildHeaders(),
            body: jsonEncode(data),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('PUT $endpoint Error: $e');
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _httpClient
          .delete(uri, headers: _buildHeaders())
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('DELETE $endpoint Error: $e');
      rethrow;
    }
  }

  /// Lấy bản đồ cộng đồng đã dedup — biển báo gần vị trí người dùng.
  /// Backend gọi Supabase RPC `get_map_signs_near`:
  ///   - Lọc trong bán kính [radiusKm] km (mặc định 5km)
  ///   - Nhiều user quét cùng 1 biển báo (< 10m, cùng label) → chỉ giữ confidence cao nhất
  ///   - Tối ưu cho mobile: giới hạn [limit] marker (mặc định 500)
  Future<List<Map<String, dynamic>>> getCommunityMapData({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
    int limit = 500,
  }) async {
    try {
      final endpoint = '/history/map?lat=$lat&lng=$lng&radius=$radiusKm&limit=$limit';
      final resp = await get(endpoint);
      final json = resp as Map<String, dynamic>;
      final list = json['data'] as List<dynamic>? ?? [];
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('getCommunityMapData Error: $e');
      rethrow;
    }
  }

  dynamic _handleResponse(http.Response response) {

    try {
      final body = response.body;
      final decoded = body.isNotEmpty ? jsonDecode(body) : null;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }

      final errorMsg = decoded?['message'] ?? 'API Error';
      throw ApiException(
        statusCode: response.statusCode,
        message: errorMsg,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('Response parsing error: $e');
      rethrow;
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
