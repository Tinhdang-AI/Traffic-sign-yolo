import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'traffic_rule_engine.dart';
import 'map_api_service.dart';

class HybridSpeedLimitService {
  static final HybridSpeedLimitService instance = HybridSpeedLimitService._();
  HybridSpeedLimitService._();

  int? _mapSpeedLimit;
  int? _currentHybridSpeedLimit;

  final _hybridSpeedController = StreamController<int?>.broadcast();
  Stream<int?> get hybridSpeedStream => _hybridSpeedController.stream;

  StreamSubscription? _ruleEngineSubscription;

  void initialize() {
    _ruleEngineSubscription = TrafficRuleEngine.instance.stateStream.listen((state) {
      _evaluateHybridSpeedLimit();
    });
  }

  Position? _lastFetchedPosition;

  /// Gọi hàm này khi có thay đổi vị trí GPS để lấy giới hạn tốc độ từ bản đồ
  Future<void> updateLocation(Position position) async {
    bool shouldFetch = false;
    
    if (_lastFetchedPosition == null) {
      shouldFetch = true;
    } else {
      final distance = Geolocator.distanceBetween(
        _lastFetchedPosition!.latitude,
        _lastFetchedPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      // Chỉ gọi API lại nếu đã di chuyển trên 50 mét để tránh nghẽn request và tiết kiệm cost
      if (distance > 50) {
        shouldFetch = true;
      }
    }

    if (shouldFetch) {
      _lastFetchedPosition = position;
      final limit = await MapApiService.getSpeedLimit(position.latitude, position.longitude);
      
      if (limit != null) {
        _mapSpeedLimit = limit;
        _evaluateHybridSpeedLimit();
      }
    }
  }

  void _evaluateHybridSpeedLimit() {
    final cameraSpeedLimit = TrafficRuleEngine.instance.currentState.activeSpeedLimit;

    // Logic Hybrid:
    // 1. Nếu Camera vừa nhận diện được biển báo rõ ràng (tốc độ hoặc khu đông dân cư), ưu tiên Camera.
    // 2. Nếu Camera không có dữ liệu (chưa quét được), dùng Map Data.
    // 3. (Tuỳ chọn nâng cao): Nếu Camera báo 50 nhưng Map báo 80 liên tục trong 1km, có thể do Camera nhận nhầm biển trên xe tải -> Chuyển về Map.

    int? newLimit = cameraSpeedLimit ?? _mapSpeedLimit;

    if (_currentHybridSpeedLimit != newLimit) {
      _currentHybridSpeedLimit = newLimit;
      _hybridSpeedController.add(_currentHybridSpeedLimit);
      print('🗺️ [HybridSpeedLimit] Updated limit: $_currentHybridSpeedLimit km/h (Camera: $cameraSpeedLimit, Map: $_mapSpeedLimit)');
    }
  }

  void dispose() {
    _ruleEngineSubscription?.cancel();
    _hybridSpeedController.close();
  }
}
