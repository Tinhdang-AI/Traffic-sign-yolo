/// Kết quả detect từ một lần inference TFLite.
/// Chỉ dùng kiểu Dart thuần (không dùng dart:ui.Rect)
/// để đối tượng này có thể truyền qua Isolate SendPort.
class DetectionResult {
  /// Nhãn nhận diện được (ví dụ: "STOP", "SPEED_LIMIT_60")
  final String label;

  /// Độ tin cậy từ 0.0 đến 1.0
  final double confidence;

  /// Bounding box chuẩn hóa 0.0–1.0
  final double left;
  final double top;
  final double right;
  final double bottom;

  /// Thời điểm phát hiện
  final DateTime timestamp;

  const DetectionResult({
    required this.label,
    required this.confidence,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.timestamp,
  });

  double get width  => right - left;
  double get height => bottom - top;

  /// Nhãn đẹp để hiển thị lên UI
  String get displayLabel {
    switch (label) {
      case 'STOP':
        return 'BIỂN DỪNG';
      case 'NO_ENTRY':
        return 'CẤM VÀO';
      case 'SPEED_LIMIT_30':
        return 'GIỚI HẠN: 30 KM/H';
      case 'SPEED_LIMIT_45':
        return 'GIỚI HẠN: 45 KM/H';
      case 'SPEED_LIMIT_60':
        return 'GIỚI HẠN: 60 KM/H';
      case 'SPEED_LIMIT_80':
        return 'GIỚI HẠN: 80 KM/H';
      case 'SPEED_LIMIT_100':
        return 'GIỚI HẠN: 100 KM/H';
      case 'NO_PARKING':
        return 'CẤM ĐỖ XE';
      case 'ONE_WAY':
        return 'ĐƯỜNG MỘT CHIỀU';
      case 'GIVE_WAY':
        return 'NHƯỜNG ĐƯỜNG';
      case 'PEDESTRIAN_CROSSING':
        return 'NGƯỜI ĐI BỘ';
      case 'SCHOOL_ZONE':
        return 'KHU VỰC TRƯỜNG HỌC';
      default:
        return label.replaceAll('_', ' ');
    }
  }

  /// Phần trăm để hiển thị (ví dụ: "97%")
  String get confidenceText => '${(confidence * 100).toInt()}%';

  /// Chỉ lấy tốc độ giới hạn nếu là biển tốc độ
  int? get speedLimit {
    if (label.startsWith('SPEED_LIMIT_')) {
      return int.tryParse(label.replaceFirst('SPEED_LIMIT_', ''));
    }
    return null;
  }

  @override
  String toString() => 'DetectionResult(label: $label, confidence: $confidenceText)';
}
