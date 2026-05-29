import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String _baseUrl = 'http://192.168.1.109:3000/api/v1'; // Port 3000 = NestJS backend
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  static final ApiClient _instance = ApiClient._internal();
  static ApiClient get instance => _instance;

  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;
  String? _accessToken;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal()
      : _httpClient = http.Client(),
        _secureStorage = const FlutterSecureStorage();

  // ─── Initialization ─────────────────────────────────────────────────────────
  Future<void> init() async {
    _accessToken = await _secureStorage.read(key: _tokenKey);
  }

  // ─── Token Management ───────────────────────────────────────────────────────
  Future<void> setToken(String token) async {
    _accessToken = token;
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<void> setRefreshToken(String token) async {
    await _secureStorage.write(key: _refreshTokenKey, value: token);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  String? getAccessToken() => _accessToken;

  // ─── HTTP Methods ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic>? body,
  ) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _httpClient.patch(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _getHeaders(),
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await _httpClient.delete(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    String filePath,
    String fieldName,
  ) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$endpoint'))
        ..headers.addAll(_getHeaders())
        ..files.add(await http.MultipartFile.fromPath(fieldName, filePath));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonResponse;
      } else {
        throw ApiException(
          jsonResponse['message'] ?? 'Upload failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Upload error: $e');
    }
  }

  // ─── Private Helpers ────────────────────────────────────────────────────────
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonBody;
      } else if (response.statusCode == 401) {
        clearTokens();
        throw UnauthorizedException(
          jsonBody['message'] ?? 'Unauthorized',
        );
      } else if (response.statusCode == 403) {
        throw ForbiddenException(
          jsonBody['message'] ?? 'Forbidden',
        );
      } else if (response.statusCode == 404) {
        throw NotFoundException(
          jsonBody['message'] ?? 'Not found',
        );
      } else if (response.statusCode == 429) {
        throw RateLimitException(
          jsonBody['message'] ?? 'Too many requests',
        );
      } else {
        throw ApiException(
          jsonBody['message'] ?? 'An error occurred',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to parse response: $e');
    }
  }
}

// ─── Custom Exceptions ───────────────────────────────────────────────────────
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message, statusCode: 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException(String message) : super(message, statusCode: 403);
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message, statusCode: 404);
}

class RateLimitException extends ApiException {
  RateLimitException(String message) : super(message, statusCode: 429);
}
