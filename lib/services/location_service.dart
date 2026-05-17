import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  StreamSubscription<Position>? _positionStreamSubscription;
  final _positionController = StreamController<Position>.broadcast();
  Position? _currentPosition;

  Stream<Position> get positionStream => _positionController.stream;
  Position? get currentPosition => _currentPosition;

  /// Yêu cầu permission và bắt đầu theo dõi GPS
  Future<bool> startTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Kiểm tra dịch vụ 위치 có bật không
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false; // Dịch vụ vị trí bị tắt
    }

    // 2. Kiểm tra/Xin quyền
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false; // Quyền bị từ chối
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false; // Quyền bị từ chối vĩnh viễn
    }

    // 3. Bắt đầu lắng nghe vị trí update (độ chính xác cao cho giao thông, cập nhật liên tục)
    final LocationSettings locationSettings;
    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
      );
    } else if (Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        activityType: ActivityType.otherNavigation,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );
    }

    _positionStreamSubscription?.cancel();
    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _currentPosition = position;
            _positionController.add(position);
          },
        );

    return true;
  }

  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _currentPosition = null;
  }

  // Tốc độ km/h
  double get currentSpeedKmH {
    if (_currentPosition == null) return 0.0;
    // position.speed là m/s -> m/s * 3.6 = km/h
    final speed = _currentPosition!.speed * 3.6;
    return speed < 0 ? 0.0 : speed;
  }

  /// Lấy địa chỉ thực tế từ tọa độ GPS tiếng Việt (loại bỏ Plus Code thô, có backup Nominatim)
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    // 1. Thử dùng dịch vụ Geocoding mặc định của hệ thống
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        final List<String> parts = [];
        
        // Trích xuất tên đường (thoroughfare) hoặc số nhà (subThoroughfare)
        String streetInfo = '';
        final String? thoroughfare = place.thoroughfare;
        final String? subThoroughfare = place.subThoroughfare;
        
        if (thoroughfare != null && thoroughfare.isNotEmpty && !thoroughfare.contains('+')) {
          if (subThoroughfare != null && subThoroughfare.isNotEmpty && !subThoroughfare.contains('+')) {
            streetInfo = '$subThoroughfare $thoroughfare';
          } else {
            streetInfo = thoroughfare;
          }
        } else if (place.street != null && place.street!.isNotEmpty && !place.street!.contains('+')) {
          streetInfo = place.street!;
        } else if (place.name != null && place.name!.isNotEmpty && !place.name!.contains('+')) {
          streetInfo = place.name!;
        }

        if (streetInfo.isNotEmpty) {
          parts.add(streetInfo);
        }

        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          parts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }
        if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
          parts.add(place.subAdministrativeArea!);
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          parts.add(place.administrativeArea!);
        }
        
        if (parts.isNotEmpty) {
          final List<String> uniqueParts = [];
          for (final p in parts) {
            final trimmed = p.trim();
            if (trimmed.isNotEmpty && !uniqueParts.contains(trimmed)) {
              uniqueParts.add(trimmed);
            }
          }
          return uniqueParts.join(', ');
        }
      }
    } catch (e) {
      print('🎤 [LocationService] Native Geocoding Failed: $e');
    }

    // 2. Nếu Geocoding hệ thống lỗi, dùng Nominatim OpenStreetMap API dự phòng
    try {
      final backupAddress = await _getBackupAddressFromNominatim(latitude, longitude);
      if (backupAddress.isNotEmpty) {
        return backupAddress;
      }
    } catch (_) {}

    // 3. Nếu mất mạng hoàn toàn, trả về tọa độ số học chính xác thay vì dùng địa chỉ giả lập
    return 'Tọa độ: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  /// Dịch vụ định vị dự phòng dùng API Nominatim (OpenStreetMap) tiếng Việt
  Future<String> _getBackupAddressFromNominatim(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&accept-language=vi',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'SentinelAITrafficDetector/1.0',
      }).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        if (address != null) {
          final List<String> parts = [];
          
          final String? road = address['road'] ?? address['suburb'] ?? address['neighbourhood'];
          if (road != null && road.isNotEmpty && !road.contains('+')) {
            parts.add(road);
          }
          
          final String? village = address['village'] ?? address['town'] ?? address['hamlet'];
          if (village != null && village.isNotEmpty) {
            parts.add(village);
          }
          
          final String? county = address['county'] ?? address['district'] ?? address['city_district'];
          if (county != null && county.isNotEmpty) {
            parts.add(county);
          }

          final String? state = address['state'] ?? address['province'] ?? address['city'];
          if (state != null && state.isNotEmpty) {
            parts.add(state);
          }

          if (parts.isNotEmpty) {
            final List<String> uniqueParts = [];
            for (final p in parts) {
              final trimmed = p.trim();
              if (trimmed.isNotEmpty && !uniqueParts.contains(trimmed)) {
                uniqueParts.add(trimmed);
              }
            }
            return uniqueParts.join(', ');
          }
        }
        
        final String? displayName = data['display_name'];
        if (displayName != null && displayName.isNotEmpty) {
          return displayName;
        }
      }
    } catch (e) {
      print('🎤 [LocationService] Backup Nominatim Failed: $e');
    }
    return '';
  }

  void dispose() {
    stopTracking();
    _positionController.close();
  }
}
