import 'dart:async';
import 'package:geolocator/geolocator.dart';

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

    // 3. Bắt đầu lắng nghe vị trí update (độ chính xác cao cho giao thông)
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2, // Cập nhật mỗi 2 mét
    );

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

  void dispose() {
    stopTracking();
    _positionController.close();
  }
}
