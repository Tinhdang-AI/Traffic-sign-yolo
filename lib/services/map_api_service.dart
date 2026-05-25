import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/env.dart';

class MapApiService {
  static const String _baseUrl = 'https://maps.vietmap.vn/api/reverse/v3';

  /// Lấy giới hạn tốc độ tại một tọa độ. Trả về [int] nếu có, null nếu không tìm thấy.
  static Future<int?> getSpeedLimit(double lat, double lng) async {
    try {
      final url = Uri.parse('$_baseUrl?apikey=${Env.vietmapServicesKey}&lat=$lat&lng=$lng');
      
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Vietmap Reverse API v3 trả về mảng kết quả, ta duyệt qua để tìm speed_limit
        if (data is List && data.isNotEmpty) {
          for (var item in data) {
            if (item['speed_limit'] != null && item['speed_limit'] > 0) {
              return item['speed_limit'] as int;
            }
          }
        }
      } else {
        print('🗺️ [MapApiService] Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('🗺️ [MapApiService] Network error: $e');
    }
    return null;
  }
}
