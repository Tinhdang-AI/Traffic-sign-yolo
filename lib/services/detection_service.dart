import 'dart:math' as math;
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

import '../models/detection_result.dart';

/// Service load model TFLite và chạy inference nhận diện biển báo
class DetectionService {
  static final DetectionService instance = DetectionService._();
  DetectionService._();

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  // Kích thước input của model (thay đổi nếu model của bạn khác)
  static const int inputSize = 640; // YOLOv8 thường là 640x640
  static const double confidenceThreshold = 0.50; // Chỉ lấy kết quả >= 50%
  static const double iouThreshold = 0.45; // NMS IoU threshold

  bool get isInitialized => _isInitialized;

  // ─────────────────────────────────────────────
  // KHỞI TẠO MODEL
  // ─────────────────────────────────────────────

  /// Gọi hàm này 1 lần khi app khởi động
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Load labels từ assets/labels/labels.txt
      final labelData = await rootBundle.loadString('assets/labels/labels.txt');
      _labels = labelData
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      // 2. Load model từ assets/models/best.tflite
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(
        'assets/models/best.tflite',
        options: options,
      );

      _isInitialized = true;
      print('[DetectionService] ✅ Model loaded: ${_labels.length} labels');
      print(
        '[DetectionService] Input shape: ${_interpreter!.getInputTensor(0).shape}',
      );
      print(
        '[DetectionService] Output shape: ${_interpreter!.getOutputTensor(0).shape}',
      );
    } catch (e) {
      _isInitialized = false;
      print('[DetectionService] ❌ Failed to initialize: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // CHẠY INFERENCE
  // ─────────────────────────────────────────────

  /// Nhận ảnh dạng Uint8List (JPEG/PNG) → trả về danh sách phát hiện
  Future<List<DetectionResult>> detect(Uint8List imageBytes) async {
    if (!_isInitialized || _interpreter == null) {
      print('[DetectionService] ⚠️ Not initialized yet');
      return [];
    }

    try {
      // Chạy trong compute isolate để không block UI thread
      return await Isolate.run(
        () => _runInference(
          imageBytes: imageBytes,
          labels: _labels,
          interpreter: _interpreter!,
        ),
      );
    } catch (e) {
      print('[DetectionService] ❌ Inference error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // PRIVATE — XỬ LÝ INFERENCE
  // ─────────────────────────────────────────────

  static List<DetectionResult> _runInference({
    required Uint8List imageBytes,
    required List<String> labels,
    required Interpreter interpreter,
  }) {
    // 1. Decode ảnh
    final image = img.decodeImage(imageBytes);
    if (image == null) return [];

    // 2. Resize về kích thước input của model
    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    // 3. Chuẩn hóa pixel về [0.0, 1.0] và đưa vào tensor Float32
    final inputTensor = _imageToFloat32(resized);

    // 4. Chuẩn bị output tensor
    // YOLOv8 output: [1, num_classes+4, num_detections]
    // Lấy shape từ model thực tế
    final outputShape = interpreter.getOutputTensor(0).shape;
    final outputTensor = List.generate(
      outputShape[0],
      (_) => List.generate(
        outputShape[1],
        (_) => List.filled(outputShape[2], 0.0),
      ),
    );

    // 5. Chạy inference
    interpreter.run(inputTensor, outputTensor);

    // 6. Parse kết quả
    final rawResults = _parseYoloOutput(
      output: outputTensor[0],
      labels: labels,
      originalWidth: image.width.toDouble(),
      originalHeight: image.height.toDouble(),
    );

    // 7. Áp dụng NMS để loại bỏ boxes trùng lặp
    return _applyNMS(rawResults);
  }

  /// Convert ảnh thành Float32List chuẩn hóa [0,1]
  static List<List<List<List<double>>>> _imageToFloat32(img.Image image) {
    return [
      List.generate(inputSize, (y) {
        return List.generate(inputSize, (x) {
          final pixel = image.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        });
      }),
    ];
  }

  /// Parse output YOLOv8 format: [84, 8400] hoặc tương tự
  static List<DetectionResult> _parseYoloOutput({
    required List<List<double>> output,
    required List<String> labels,
    required double originalWidth,
    required double originalHeight,
  }) {
    final results = <DetectionResult>[];
    final now = DateTime.now();

    // YOLOv8: output[i] = [cx, cy, w, h, class0_conf, class1_conf, ...]
    // output shape: [4 + numClasses, numBoxes]
    final modelClassCount = math.max(0, output.length - 4);
    final numClasses = labels.isEmpty
        ? modelClassCount
        : math.min(labels.length, modelClassCount);
    final numBoxes = output[0].length;

    for (int b = 0; b < numBoxes; b++) {
      // Lấy confidence của từng class
      double maxConf = 0;
      int classIdx = 0;
      for (int c = 0; c < numClasses; c++) {
        final conf = output[4 + c][b];
        if (conf > maxConf) {
          maxConf = conf;
          classIdx = c;
        }
      }

      if (maxConf < confidenceThreshold) continue;

      // Bounding box (chuẩn hóa)
      final cx = output[0][b];
      final cy = output[1][b];
      final w = output[2][b];
      final h = output[3][b];

      final left = (cx - w / 2).clamp(0.0, 1.0);
      final top = (cy - h / 2).clamp(0.0, 1.0);
      final right = (cx + w / 2).clamp(0.0, 1.0);
      final bottom = (cy + h / 2).clamp(0.0, 1.0);

      final label = (labels.isNotEmpty && classIdx < labels.length)
          ? labels[classIdx]
          : 'CLASS_$classIdx';

      results.add(
        DetectionResult(
          label: label,
          confidence: maxConf,
          boundingBox: Rect.fromLTRB(left, top, right, bottom),
          timestamp: now,
        ),
      );
    }

    return results;
  }

  /// Non-Maximum Suppression — loại bỏ các boxes quá gần nhau
  static List<DetectionResult> _applyNMS(List<DetectionResult> detections) {
    if (detections.isEmpty) return [];

    // Sắp xếp theo confidence giảm dần
    final sorted = [...detections]
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    final kept = <DetectionResult>[];

    for (final candidate in sorted) {
      bool suppress = false;
      for (final kept_ in kept) {
        if (candidate.label == kept_.label) {
          final iou = _computeIoU(candidate.boundingBox, kept_.boundingBox);
          if (iou > iouThreshold) {
            suppress = true;
            break;
          }
        }
      }
      if (!suppress) kept.add(candidate);
    }

    return kept;
  }

  /// Tính IoU (Intersection over Union) giữa 2 bounding box
  static double _computeIoU(Rect a, Rect b) {
    final intersection = a.intersect(b);
    if (intersection.isEmpty) return 0;

    final intersectionArea = intersection.width * intersection.height;
    final unionArea =
        (a.width * a.height) + (b.width * b.height) - intersectionArea;
    return unionArea == 0 ? 0 : intersectionArea / unionArea;
  }

  // ─────────────────────────────────────────────
  // CLEANUP
  // ─────────────────────────────────────────────

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
