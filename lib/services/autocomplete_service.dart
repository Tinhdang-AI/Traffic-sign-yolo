import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AutocompleteResult {
  final String displayName;
  final double latitude;
  final double longitude;
  final String placeType; // city, town, village, road, etc.

  AutocompleteResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.placeType,
  });

  factory AutocompleteResult.fromJson(Map<String, dynamic> json) {
    return AutocompleteResult(
      displayName: json['display_name'] ?? 'Unknown',
      latitude: (json['lat'] as dynamic).toDouble(),
      longitude: (json['lon'] as dynamic).toDouble(),
      placeType: json['type'] ?? 'place',
    );
  }
}

class AutocompleteService {
  static final AutocompleteService _instance = AutocompleteService._internal();

  factory AutocompleteService() {
    return _instance;
  }

  AutocompleteService._internal();

  Timer? _debounceTimer;
  final Duration _debounceDuration = const Duration(milliseconds: 300);

  /// Get autocomplete suggestions with debouncing
  Future<List<AutocompleteResult>> getSuggestions(
    String query, {
    VoidCallback? onStartSearch,
    VoidCallback? onEndSearch,
  }) async {
    // Cancel previous request
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      return [];
    }

    onStartSearch?.call();

    final completer = Completer<List<AutocompleteResult>>();

    _debounceTimer = Timer(_debounceDuration, () async {
      try {
        final url = Uri.https('nominatim.openstreetmap.org', '/search.php', {
          'q': query,
          'format': 'json',
          'limit': '5',
          'countrycodes': 'vn', // Focus on Vietnam
          'accept-language': 'vi',
        });

        final response = await http
            .get(
              url,
              headers: {
                'User-Agent': 'TrafficDetectApp',
                'Accept-Language': 'vi-VN,vi;q=0.9',
              },
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          final results = data
              .map((item) => AutocompleteResult.fromJson(item))
              .toList();
          onEndSearch?.call();
          completer.complete(results);
        } else {
          onEndSearch?.call();
          completer.complete([]);
        }
      } catch (e) {
        onEndSearch?.call();
        completer.complete([]);
      }
    });

    return completer.future;
  }

  void cancelPending() {
    _debounceTimer?.cancel();
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}
