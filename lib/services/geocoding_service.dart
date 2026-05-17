import 'dart:convert';
import 'package:http/http.dart' as http;

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

  /// Reverse geocode a coordinate into a readable location label.
  /// Falls back to Nominatim's display name when structured fields are sparse.
  static Future<String> reverseGeocodeAddress(
    double latitude,
    double longitude,
  ) async {
    try {
      return await _nominatimReverseGeocode(latitude, longitude);
    } catch (_) {
      return '';
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

  static Future<String> _nominatimReverseGeocode(
    double latitude,
    double longitude,
  ) async {
    final url = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'format': 'jsonv2',
      'addressdetails': '1',
      'zoom': '18',
      'accept-language': 'vi',
    });

    final resp = await http.get(
      url,
      headers: {
        'User-Agent': 'traffic_detect_app/1.0',
      },
    );

    if (resp.statusCode != 200) {
      throw Exception('Nominatim reverse error ${resp.statusCode}');
    }

    final Map<String, dynamic> data = json.decode(resp.body);
    final Map<String, dynamic> address =
        (data['address'] as Map?)?.cast<String, dynamic>() ?? const {};

    final parts = <String>[];

    final road = _firstNonEmpty([
      address['house_number'],
      address['road'],
      address['pedestrian'],
      address['footway'],
      address['path'],
    ]);
    if (road.isNotEmpty) {
      parts.add(road);
    }

    final locality = _firstNonEmpty([
      address['suburb'],
      address['neighbourhood'],
      address['quarter'],
      address['village'],
      address['town'],
      address['city_district'],
      address['municipality'],
    ]);
    if (locality.isNotEmpty && locality != road) {
      parts.add(locality);
    }

    final city = _firstNonEmpty([
      address['city'],
      address['county'],
      address['district'],
      address['province'],
      address['state'],
      address['region'],
    ]);
    if (city.isNotEmpty && city != locality) {
      parts.add(city);
    }

    if (parts.isNotEmpty) {
      return _cleanLocationLabel(parts.join(', '));
    }

    final displayName = (data['display_name'] ?? '').toString();
    if (displayName.isNotEmpty) {
      return _cleanLocationLabel(displayName);
    }

    return '';
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  static String _cleanLocationLabel(String value) {
    final parts = value
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.isEmpty ? value.trim() : parts.join(', ');
  }
}
