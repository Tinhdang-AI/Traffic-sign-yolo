import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NominatimResult {
  final String displayName;
  final double latitude;
  final double longitude;

  NominatimResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}

class GeocodingService {
  /// Geocode address using Nominatim (free OpenStreetMap service)
  static Future<NominatimResult> geocodeAddress(String query) async {
    if (query.trim().isEmpty) {
      throw Exception('Địa chỉ không được để trống');
    }

    // Try Nominatim first (free, no API key needed)
    try {
      return await _nominatimGeocode(query);
    } catch (e) {
      throw Exception(
        'Không thể tìm địa chỉ: $query. Vui lòng kiểm tra và thử lại.',
      );
    }
  }

  static Future<NominatimResult> _nominatimGeocode(String query) async {
    final url = Uri.https('nominatim.openstreetmap.org', '/search.php', {
      'q': query,
      'format': 'json',
      'limit': '1',
      'countrycodes': 'vn', // Prioritize Vietnam
      'accept-language': 'vi', // Vietnamese results
    });

    final resp = await http.get(
      url,
      headers: {
        'User-Agent': 'traffic_detect_app/1.0', // Nominatim requires User-Agent
      },
    );

    if (resp.statusCode != 200) {
      throw Exception('Nominatim error ${resp.statusCode}');
    }

    final List<dynamic> data = json.decode(resp.body);
    if (data.isEmpty) {
      throw Exception('Không tìm thấy kết quả cho: $query');
    }

    final first = data[0];
    return NominatimResult(
      displayName: first['display_name'] ?? query,
      latitude: double.parse(first['lat'] ?? '0'),
      longitude: double.parse(first['lon'] ?? '0'),
    );
  }
}
