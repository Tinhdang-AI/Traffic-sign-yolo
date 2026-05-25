import 'dart:async';

enum ZoneType {
  urban, // Khu đông dân cư
  rural, // Ngoài khu đông dân cư
  unknown
}

class TrafficRuleState {
  final ZoneType zoneType;
  final int? temporarySpeedLimit;
  final bool isOvertakingProhibited;
  final bool isHornProhibited;
  final bool isParkingProhibited;
  final bool isStoppingProhibited;

  TrafficRuleState({
    this.zoneType = ZoneType.unknown,
    this.temporarySpeedLimit,
    this.isOvertakingProhibited = false,
    this.isHornProhibited = false,
    this.isParkingProhibited = false,
    this.isStoppingProhibited = false,
  });

  /// Tính toán giới hạn tốc độ hiện tại dựa trên State Machine
  int? get activeSpeedLimit {
    if (temporarySpeedLimit != null) {
      return temporarySpeedLimit;
    }
    
    // Giả định tốc độ tối đa mặc định theo luật VN (đối với xe ô tô con trên đường đôi/có dải phân cách)
    switch (zoneType) {
      case ZoneType.urban:
        return 60; // 60 km/h trong khu đông dân cư (đường đôi)
      case ZoneType.rural:
        return 90; // 90 km/h ngoài khu đông dân cư (đường đôi)
      case ZoneType.unknown:
      default:
        return null;
    }
  }

  TrafficRuleState copyWith({
    ZoneType? zoneType,
    int? temporarySpeedLimit,
    bool? isOvertakingProhibited,
    bool? isHornProhibited,
    bool? isParkingProhibited,
    bool? isStoppingProhibited,
    bool clearTemporarySpeedLimit = false,
  }) {
    return TrafficRuleState(
      zoneType: zoneType ?? this.zoneType,
      temporarySpeedLimit: clearTemporarySpeedLimit ? null : (temporarySpeedLimit ?? this.temporarySpeedLimit),
      isOvertakingProhibited: isOvertakingProhibited ?? this.isOvertakingProhibited,
      isHornProhibited: isHornProhibited ?? this.isHornProhibited,
      isParkingProhibited: isParkingProhibited ?? this.isParkingProhibited,
      isStoppingProhibited: isStoppingProhibited ?? this.isStoppingProhibited,
    );
  }
}

class TrafficRuleEngine {
  static final TrafficRuleEngine instance = TrafficRuleEngine._();
  TrafficRuleEngine._();

  TrafficRuleState _currentState = TrafficRuleState();
  
  // Broadcast stream để UI có thể lắng nghe sự thay đổi trạng thái luật giao thông
  final _stateController = StreamController<TrafficRuleState>.broadcast();
  Stream<TrafficRuleState> get stateStream => _stateController.stream;
  
  TrafficRuleState get currentState => _currentState;

  void processDetection(String label) {
    final lower = label.toLowerCase();
    bool stateChanged = false;
    TrafficRuleState newState = _currentState;

    // 1. Nhận diện khu vực đông dân cư
    if (lower == 'khu vực đông dân cư') {
      if (newState.zoneType != ZoneType.urban) {
        newState = newState.copyWith(zoneType: ZoneType.urban, clearTemporarySpeedLimit: true);
        stateChanged = true;
      }
    } else if (lower == 'ngoài khu vực đông dân cư') {
      if (newState.zoneType != ZoneType.rural) {
        newState = newState.copyWith(zoneType: ZoneType.rural, clearTemporarySpeedLimit: true);
        stateChanged = true;
      }
    }

    // 2. Nhận diện giới hạn tốc độ (tạm thời ghi đè tốc độ khu vực)
    if (lower.contains('tốc độ tối đa') && !lower.contains('hết')) {
      final match = RegExp(r'\d+').firstMatch(lower);
      if (match != null) {
        final speed = int.tryParse(match.group(0)!);
        if (speed != null && newState.temporarySpeedLimit != speed) {
          newState = newState.copyWith(temporarySpeedLimit: speed);
          stateChanged = true;
        }
      }
    } 
    // 3. Nhận diện Hết giới hạn tốc độ
    else if (lower.contains('hết tốc độ tối đa')) {
      if (newState.temporarySpeedLimit != null) {
        newState = newState.copyWith(clearTemporarySpeedLimit: true);
        stateChanged = true;
      }
    }

    // 4. Nhận diện Hết mọi lệnh cấm (DP.135)
    if (lower == 'hết lệnh cấm') {
      newState = newState.copyWith(
        clearTemporarySpeedLimit: true,
        isOvertakingProhibited: false,
        isHornProhibited: false,
      );
      stateChanged = true;
    }

    // 5. Cấm vượt / Hết cấm vượt
    if (lower == 'cấm vượt') {
      if (!newState.isOvertakingProhibited) {
        newState = newState.copyWith(isOvertakingProhibited: true);
        stateChanged = true;
      }
    }

    // 6. Cấm đỗ / Cấm dừng đỗ
    if (lower == 'cấm đỗ') {
       if (!newState.isParkingProhibited) {
         newState = newState.copyWith(isParkingProhibited: true);
         stateChanged = true;
       }
    } else if (lower == 'cấm dừng, đỗ') {
       if (!newState.isStoppingProhibited) {
         newState = newState.copyWith(isStoppingProhibited: true, isParkingProhibited: true);
         stateChanged = true;
       }
    }

    if (stateChanged) {
      _currentState = newState;
      _stateController.add(_currentState);
      print('🚦 [TrafficRuleEngine] State updated: Limit=${newState.activeSpeedLimit}, Urban=${newState.zoneType}');
    }
  }

  void reset() {
    _currentState = TrafficRuleState();
    _stateController.add(_currentState);
  }
}
