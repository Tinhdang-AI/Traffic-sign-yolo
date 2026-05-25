import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

import '../models/detection_result.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Internal messages
// ─────────────────────────────────────────────────────────────────────────────

class _WorkerBootstrap {
  final SendPort replyTo;
  final int interpreterAddress;
  final List<String> labels;
  final int numDetections;
  final int numClasses;
  final bool isYoloV8; // true → output [1, cols, detections]; false → [1, detections, cols]
  final bool isFloat;  // true → float32 input [0,1]; false → uint8 [0,255]

  const _WorkerBootstrap({
    required this.replyTo,
    required this.interpreterAddress,
    required this.labels,
    required this.numDetections,
    required this.numClasses,
    required this.isYoloV8,
    required this.isFloat,
  });
}

class _InferenceRequest {
  final int id;
  final Uint8List imageBytes;
  final SendPort replyTo;
  const _InferenceRequest({
    required this.id,
    required this.imageBytes,
    required this.replyTo,
  });
}

class _InferenceReply {
  final int id;
  final List<DetectionResult> results;
  final String? error;
  const _InferenceReply({required this.id, required this.results, this.error});
}

// ─────────────────────────────────────────────────────────────────────────────
// DetectionService
// ─────────────────────────────────────────────────────────────────────────────

class DetectionService {
  static final DetectionService instance = DetectionService._();
  DetectionService._();

  Interpreter? _interpreter; // lives on main isolate
  List<String> _labels = [];
  bool _isInitialized = false;

  Isolate? _workerIsolate;
  SendPort? _workerSendPort;
  int _requestId = 0;

  static const int inputSize = 640;
  static const double confidenceThreshold = 0.35; // lowered for debugging
  static const double iouThreshold = 0.45;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Labels
      final labelData = await rootBundle.loadString('assets/labels/labels.txt');
      _labels = labelData
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      print('[DetectionService] Labels: ${_labels.length}');

      // 2. Load interpreter on MAIN isolate — it will share its address with worker
      final options = InterpreterOptions()..threads = 4;
      if (Platform.isAndroid) {
        try {
          options.addDelegate(XNNPackDelegate());
        } catch (_) {
          // fallback
        }
      } else if (Platform.isIOS) {
        try {
          options.addDelegate(GpuDelegate());
        } catch (_) {}
      }

      _interpreter = await Interpreter.fromAsset(
        'assets/models/best.tflite',
        options: options,
      );

      // 3. Read exact shapes & dtypes from model
      final inputTensor  = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);

      final inputShape  = inputTensor.shape;
      final outputShape = outputTensor.shape;
      final inputDtype  = inputTensor.type.toString();

      print('[DetectionService] Input  shape=$inputShape dtype=$inputDtype');
      print('[DetectionService] Output shape=$outputShape');

      // ── Detect model format ──────────────────────────────────────────────
      // YOLOv5: [1, numDetections, 5+numClasses]  e.g. [1, 25200, 85]
      // YOLOv8: [1, 4+numClasses, numDetections]  e.g. [1,    63, 8400]
      //         (transposed, no objectness score)
      int  numDetections = 8400;
      int  numClasses    = _labels.length;
      bool isYoloV8      = false;

      if (outputShape.length == 3) {
        final d1 = outputShape[1];
        final d2 = outputShape[2];
        // YOLOv8: d1 = 4+classes (small), d2 = detections (large)
        // YOLOv5: d1 = detections (large), d2 = 5+classes (small)
        if (d1 < d2) {
          // YOLOv8 format: [1, 4+classes, detections]
          isYoloV8      = true;
          numClasses    = d1 - 4; // no objectness in YOLOv8
          numDetections = d2;
          print('[DetectionService] Format=YOLOv8  classes=$numClasses  detections=$numDetections');
        } else {
          // YOLOv5 format: [1, detections, 5+classes]
          isYoloV8      = false;
          numDetections = d1;
          numClasses    = d2 - 5;
          print('[DetectionService] Format=YOLOv5  classes=$numClasses  detections=$numDetections');
        }
      } else if (outputShape.length == 2) {
        isYoloV8      = false;
        numDetections = outputShape[0];
        numClasses    = outputShape[1] - 5;
        print('[DetectionService] Format=YOLOv5-2D  classes=$numClasses  detections=$numDetections');
      }

      // Clamp numClasses to label count
      if (numClasses != _labels.length) {
        print('[DetectionService] ⚠️ numClasses($numClasses) adjusted to labels.length=${_labels.length}');
        numClasses = _labels.length;
      }

      final bool isFloat = inputDtype.toLowerCase().contains('float');

      // 4. Spawn persistent worker
      final readyPort = ReceivePort();
      _workerIsolate = await Isolate.spawn(
        _workerMain,
        _WorkerBootstrap(
          replyTo:            readyPort.sendPort,
          interpreterAddress: _interpreter!.address,
          labels:             List.unmodifiable(_labels),
          numDetections:      numDetections,
          numClasses:         numClasses,
          isYoloV8:           isYoloV8,
          isFloat:            isFloat,
        ),
        debugName: 'DetectionWorker',
      );

      final msg = await readyPort.first;
      readyPort.close();

      if (msg is! SendPort) {
        throw StateError('Worker failed to start: $msg');
      }
      _workerSendPort = msg;

      _isInitialized = true;
      print('[DetectionService] ✅ Ready  isYoloV8=$isYoloV8  detections=$numDetections  classes=$numClasses');
    } catch (e) {
      _isInitialized = false;
      print('[DetectionService] ❌ initialize() failed: $e');
      rethrow;
    }
  }

  Future<List<DetectionResult>> detect(Uint8List imageBytes) async {
    if (!_isInitialized || _workerSendPort == null) return [];

    try {
      final replyPort = ReceivePort();
      final id = ++_requestId;

      _workerSendPort!.send(_InferenceRequest(
        id:         id,
        imageBytes: imageBytes,
        replyTo:    replyPort.sendPort,
      ));

      final reply = await replyPort.first as _InferenceReply;
      replyPort.close();

      if (reply.error != null) {
        print('[DetectionService] ❌ Worker: ${reply.error}');
        return [];
      }
      return reply.results;
    } catch (e) {
      print('[DetectionService] ❌ detect(): $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Worker isolate — uses Interpreter.fromAddress() (official tflite API)
  // ──────────────────────────────────────────────────────────────────────────
  static void _workerMain(_WorkerBootstrap bootstrap) async {
    final interpreter = Interpreter.fromAddress(
      bootstrap.interpreterAddress,
      allocated: true,
    );

    final receivePort = ReceivePort();
    bootstrap.replyTo.send(receivePort.sendPort);

    await for (final msg in receivePort) {
      if (msg is _InferenceRequest) {
        try {
          final results = _runInference(
            imageBytes:    msg.imageBytes,
            interpreter:   interpreter,
            labels:        bootstrap.labels,
            numDetections: bootstrap.numDetections,
            numClasses:    bootstrap.numClasses,
            isYoloV8:      bootstrap.isYoloV8,
            isFloat:       bootstrap.isFloat,
          );
          msg.replyTo.send(_InferenceReply(id: msg.id, results: results));
        } catch (e, st) {
          msg.replyTo.send(_InferenceReply(
            id:      msg.id,
            results: [],
            error:   '$e\n$st',
          ));
        }
      } else if (msg == 'dispose') {
        receivePort.close();
        break;
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Inference — runs in worker isolate
  // ──────────────────────────────────────────────────────────────────────────
  static List<DetectionResult> _runInference({
    required Uint8List imageBytes,
    required Interpreter interpreter,
    required List<String> labels,
    required int numDetections,
    required int numClasses,
    required bool isYoloV8,
    required bool isFloat,
  }) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return [];

    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    // ── Input tensor: shape [1, 640, 640, 3] ────────────────────────────────
    final inputList = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = resized.getPixelSafe(x, y);
            if (isFloat) {
              return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
            } else {
              return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
            }
          },
        ),
      ),
    );

    // ── Output tensor — must EXACTLY match model output shape ───────────────
    // YOLOv8: [1, 4+numClasses, numDetections]  e.g. [1, 63, 8400]
    // YOLOv5: [1, numDetections, 5+numClasses]  e.g. [1, 25200, 85]
    final List outputList;
    if (isYoloV8) {
      final int cols = 4 + numClasses;
      outputList = List.generate(
        1,
        (_) => List.generate(
          cols,
          (_) => List<double>.filled(numDetections, 0.0),
        ),
      );
    } else {
      final int cols = 5 + numClasses;
      outputList = List.generate(
        1,
        (_) => List.generate(
          numDetections,
          (_) => List<double>.filled(cols, 0.0),
        ),
      );
    }

    interpreter.run(inputList, outputList);

    // ── Parse detections ────────────────────────────────────────────────────
    final detections = <DetectionResult>[];

    if (isYoloV8) {
      // YOLOv8: output[0] shape = [4+numClasses, numDetections]
      // row = feature axis (cx/cy/w/h then class probs), col = detection index
      final features = outputList[0] as List; // length = 4 + numClasses
      for (var i = 0; i < numDetections; i++) {
        var classId  = 0;
        var bestProb = (features[4] as List<double>)[i];
        for (var c = 1; c < numClasses; c++) {
          final p = (features[4 + c] as List<double>)[i];
          if (p > bestProb) {
            bestProb = p;
            classId  = c;
          }
        }

        if (bestProb < confidenceThreshold) continue;

        final cx = (features[0] as List<double>)[i];
        final cy = (features[1] as List<double>)[i];
        final w  = (features[2] as List<double>)[i];
        final h  = (features[3] as List<double>)[i];

        detections.add(DetectionResult(
          label:      classId < labels.length ? labels[classId] : 'Unknown',
          confidence: bestProb,
          left:       ((cx - w / 2) / inputSize).clamp(0.0, 1.0),
          top:        ((cy - h / 2) / inputSize).clamp(0.0, 1.0),
          right:      ((cx + w / 2) / inputSize).clamp(0.0, 1.0),
          bottom:     ((cy + h / 2) / inputSize).clamp(0.0, 1.0),
          timestamp:  DateTime.now(),
        ));
      }
    } else {
      // YOLOv5: output[0][i] = [cx, cy, w, h, objectness, c0, c1, ...]
      final rows = outputList[0] as List<List<double>>;
      final int requiredCols = 5 + numClasses;
      for (final row in rows) {
        if (row.length < requiredCols) continue;
        final objectness = row[4];
        if (objectness < confidenceThreshold) continue;

        var classId  = 0;
        var bestProb = row[5];
        for (var c = 1; c < numClasses; c++) {
          final p = row[5 + c];
          if (p > bestProb) { bestProb = p; classId = c; }
        }

        final score = objectness * bestProb;
        if (score < confidenceThreshold) continue;

        final cx = row[0]; final cy = row[1];
        final w  = row[2]; final h  = row[3];

        detections.add(DetectionResult(
          label:      classId < labels.length ? labels[classId] : 'Unknown',
          confidence: score,
          left:       ((cx - w / 2) / inputSize).clamp(0.0, 1.0),
          top:        ((cy - h / 2) / inputSize).clamp(0.0, 1.0),
          right:      ((cx + w / 2) / inputSize).clamp(0.0, 1.0),
          bottom:     ((cy + h / 2) / inputSize).clamp(0.0, 1.0),
          timestamp:  DateTime.now(),
        ));
      }
    }

    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    return _nms(detections);
  }

  static List<DetectionResult> _nms(List<DetectionResult> detections) {
    final filtered = <DetectionResult>[];
    for (final d in detections) {
      var keep = true;
      for (final e in filtered) {
        if (_iou(d, e) > iouThreshold) {
          keep = false;
          break;
        }
      }
      if (keep) filtered.add(d);
    }
    return filtered;
  }

  static double _iou(DetectionResult a, DetectionResult b) {
    final xA = math.max(a.left,   b.left);
    final yA = math.max(a.top,    b.top);
    final xB = math.min(a.right,  b.right);
    final yB = math.min(a.bottom, b.bottom);
    if (xA >= xB || yA >= yB) return 0.0;
    final inter = (xB - xA) * (yB - yA);
    final union = a.width * a.height + b.width * b.height - inter;
    return union <= 0 ? 0.0 : inter / union;
  }

  void dispose() {
    _workerSendPort?.send('dispose');
    _workerIsolate?.kill(priority: Isolate.beforeNextEvent);
    _interpreter?.close();
    _workerIsolate  = null;
    _workerSendPort = null;
    _interpreter    = null;
    _isInitialized  = false;
  }
}
