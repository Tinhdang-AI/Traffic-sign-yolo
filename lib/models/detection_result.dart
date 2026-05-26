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

  /// Nhãn đẹp để hiển thị lên UI (capitalize nhãn tiếng Việt từ model)
  String get displayLabel {
    if (label.isEmpty) return '';
    return label[0].toUpperCase() + label.substring(1);
  }

  /// Phần trăm để hiển thị (ví dụ: "97%")
  String get confidenceText => '${(confidence * 100).toInt()}%';

  /// Chỉ lấy tốc độ giới hạn nếu là biển tốc độ (label tiếng Việt từ model)
  int? get speedLimit {
    final match = RegExp(r'tốc độ tối đa (\d+)').firstMatch(label);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  @override
  String toString() => 'DetectionResult(label: $label, confidence: $confidenceText)';
}
