import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import 'package:path/path.dart' show join;
import 'package:camera/camera.dart' show CameraImage, ImageFormatGroup;

import '../models/detection_result.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Internal messages
// ─────────────────────────────────────────────────────────────────────────────

class _WorkerBootstrap {
  final SendPort replyTo;
  final String modelPath;
  final List<String> labels;

  const _WorkerBootstrap({
    required this.replyTo,
    required this.modelPath,
    required this.labels,
  });
}

class _WorkerInitResult {
  final SendPort sendPort;
  final bool isYoloV8;
  final int numDetections;
  final int numClasses;
  final bool isFloat;
  final bool isNCHW;

  const _WorkerInitResult({
    required this.sendPort,
    required this.isYoloV8,
    required this.numDetections,
    required this.numClasses,
    required this.isFloat,
    required this.isNCHW,
  });
}

class _InferenceRequest {
  final int id;
  final SendPort replyTo;

  // JPEG bytes (snapshot mode)
  final Uint8List? jpegBytes;

  // YUV420 plane bytes (stream mode)
  final Uint8List? yBytes;
  final Uint8List? uBytes;
  final Uint8List? vBytes;
  final int? width;
  final int? height;
  final int? yRowStride;
  final int? uvRowStride;
  final int? uvPixelStride;

  const _InferenceRequest({
    required this.id,
    required this.replyTo,
    this.jpegBytes,
    this.yBytes,
    this.uBytes,
    this.vBytes,
    this.width,
    this.height,
    this.yRowStride,
    this.uvRowStride,
    this.uvPixelStride,
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

      // Copy model to local databases directory to use memory-mapping (mmap)
      final dbPath = await getDatabasesPath();
      final modelPath = join(dbPath, 'best.tflite');
      final modelFile = File(modelPath);

      if (!await modelFile.exists()) {
        print('[DetectionService] Copying model from assets to $modelPath to enable memory-mapping...');
        final byteData = await rootBundle.load('assets/models/best.tflite');
        final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
        await modelFile.writeAsBytes(bytes, flush: true);
        print('[DetectionService] Model copied successfully.');
      }

      // 2. Spawn persistent worker
      final readyPort = ReceivePort();
      _workerIsolate = await Isolate.spawn(
        _workerMain,
        _WorkerBootstrap(
          replyTo:   readyPort.sendPort,
          modelPath: modelFile.path,
          labels:    List.unmodifiable(_labels),
        ),
        debugName: 'DetectionWorker',
      );

      final msg = await readyPort.first;
      readyPort.close();

      if (msg is String) {
        throw StateError('Worker failed to initialize: $msg');
      }

      if (msg is! _WorkerInitResult) {
        throw StateError('Worker failed to start: $msg');
      }

      _workerSendPort = msg.sendPort;
      _isInitialized = true;
      print('[DetectionService] ✅ Ready  isYoloV8=${msg.isYoloV8}  detections=${msg.numDetections}  classes=${msg.numClasses}');
    } catch (e) {
      _isInitialized = false;
      print('[DetectionService] ❌ initialize() failed: $e');
      rethrow;
    }
  }

  Future<List<DetectionResult>> detect({
    Uint8List? jpegBytes,
    CameraImage? cameraImage,
  }) async {
    if (!_isInitialized || _workerSendPort == null) return [];

    try {
      final replyPort = ReceivePort();
      final id = ++_requestId;

      if (cameraImage != null) {
        final planes = cameraImage.planes;
        if (planes.length == 1 || cameraImage.format.group == ImageFormatGroup.jpeg) {
          _workerSendPort!.send(_InferenceRequest(
            id:        id,
            replyTo:   replyPort.sendPort,
            jpegBytes: planes[0].bytes,
          ));
        } else if (planes.length >= 3) {
          _workerSendPort!.send(_InferenceRequest(
            id:             id,
            replyTo:        replyPort.sendPort,
            yBytes:         planes[0].bytes,
            uBytes:         planes[1].bytes,
            vBytes:         planes[2].bytes,
            width:          cameraImage.width,
            height:         cameraImage.height,
            yRowStride:     planes[0].bytesPerRow,
            uvRowStride:    planes[1].bytesPerRow,
            uvPixelStride:  planes[1].bytesPerPixel ?? 1,
          ));
        } else {
          print('[DetectionService] ❌ Unsupported camera image format: planes=${planes.length}, group=${cameraImage.format.group}');
          return [];
        }
      } else if (jpegBytes != null) {
        _workerSendPort!.send(_InferenceRequest(
          id:        id,
          replyTo:   replyPort.sendPort,
          jpegBytes: jpegBytes,
        ));
      } else {
        return [];
      }

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
  // Worker isolate — loads and owns Interpreter instance
  // ──────────────────────────────────────────────────────────────────────────
  static void _workerMain(_WorkerBootstrap bootstrap) async {
    Interpreter? interpreter;
    try {
      // 1. Load interpreter inside the background isolate
      final options = InterpreterOptions()..threads = 2;
      interpreter = Interpreter.fromFile(
        File(bootstrap.modelPath),
        options: options,
      );

      // 2. Read exact shapes & dtypes from model to detect format
      final inputTensor  = interpreter.getInputTensor(0);
      final outputTensor = interpreter.getOutputTensor(0);

      final inputShape  = inputTensor.shape;
      final outputShape = outputTensor.shape;
      final inputDtype  = inputTensor.type.toString();

      int numDetections = 8400;
      int numClasses    = bootstrap.labels.length;
      bool isYoloV8      = false;

      if (outputShape.length == 3) {
        final d1 = outputShape[1];
        final d2 = outputShape[2];
        if (d1 < d2) {
          isYoloV8      = true;
          numClasses    = d1 - 4;
          numDetections = d2;
        } else {
          isYoloV8      = false;
          numDetections = d1;
          numClasses    = d2 - 5;
        }
      } else if (outputShape.length == 2) {
        isYoloV8      = false;
        numDetections = outputShape[0];
        numClasses    = outputShape[1] - 5;
      }

      if (numClasses != bootstrap.labels.length) {
        numClasses = bootstrap.labels.length;
      }

      final bool isFloat = inputDtype.toLowerCase().contains('float');
      final bool isNCHW = (inputShape.length == 4 && inputShape[1] == 3);

      final receivePort = ReceivePort();
      bootstrap.replyTo.send(_WorkerInitResult(
        sendPort:      receivePort.sendPort,
        isYoloV8:      isYoloV8,
        numDetections: numDetections,
        numClasses:    numClasses,
        isFloat:       isFloat,
        isNCHW:        isNCHW,
      ));

      await for (final msg in receivePort) {
        if (msg is _InferenceRequest) {
          try {
            final results = _runInference(
              interpreter:   interpreter,
              labels:        bootstrap.labels,
              numDetections: numDetections,
              numClasses:    numClasses,
              isYoloV8:      isYoloV8,
              isFloat:       isFloat,
              isNCHW:        isNCHW,
              jpegBytes:     msg.jpegBytes,
              yBytes:        msg.yBytes,
              uBytes:        msg.uBytes,
              vBytes:        msg.vBytes,
              width:         msg.width,
              height:        msg.height,
              yRowStride:    msg.yRowStride,
              uvRowStride:   msg.uvRowStride,
              uvPixelStride: msg.uvPixelStride,
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
          interpreter.close();
          receivePort.close();
          break;
        }
      }
    } catch (e, st) {
      bootstrap.replyTo.send('Initialization failed: $e\n$st');
      interpreter?.close();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Inference — runs in worker isolate
  // ──────────────────────────────────────────────────────────────────────────
  static List<DetectionResult> _runInference({
    required Interpreter interpreter,
    required List<String> labels,
    required int numDetections,
    required int numClasses,
    required bool isYoloV8,
    required bool isFloat,
    required bool isNCHW,
    Uint8List? jpegBytes,
    Uint8List? yBytes,
    Uint8List? uBytes,
    Uint8List? vBytes,
    int? width,
    int? height,
    int? yRowStride,
    int? uvRowStride,
    int? uvPixelStride,
  }) {
    // 1. Prepare flat input buffer
    final int inputLength = inputSize * inputSize * 3;
    final Float32List? floatBuffer = isFloat ? Float32List(inputLength) : null;
    final Uint8List? uint8Buffer = !isFloat ? Uint8List(inputLength) : null;

    final int channelSize = inputSize * inputSize;
    img.Image? image;

    if (jpegBytes != null) {
      final rawImage = img.decodeImage(jpegBytes);
      if (rawImage == null) return [];
      image = img.bakeOrientation(rawImage);

      // Scale & pad from img.Image to flat tensor buffer
      final int origW = image.width;
      final int origH = image.height;
      final double scale = math.min(inputSize / origW, inputSize / origH);
      final int newW = (origW * scale).round();
      final int newH = (origH * scale).round();
      final int padX = (inputSize - newW) ~/ 2;
      final int padY = (inputSize - newH) ~/ 2;

      for (int ty = 0; ty < inputSize; ty++) {
        for (int tx = 0; tx < inputSize; tx++) {
          double r = 114.0;
          double g = 114.0;
          double b = 114.0;

          if (tx >= padX && tx < padX + newW && ty >= padY && ty < padY + newH) {
            final int sx = ((tx - padX) / scale).floor().clamp(0, origW - 1);
            final int sy = ((ty - padY) / scale).floor().clamp(0, origH - 1);
            final pixel = image.getPixelSafe(sx, sy);
            r = pixel.r.toDouble();
            g = pixel.g.toDouble();
            b = pixel.b.toDouble();
          }

          if (isFloat) {
            if (isNCHW) {
              final int offset = ty * inputSize + tx;
              floatBuffer![offset] = r / 255.0;
              floatBuffer[offset + channelSize] = g / 255.0;
              floatBuffer[offset + 2 * channelSize] = b / 255.0;
            } else {
              final int offset = (ty * inputSize + tx) * 3;
              floatBuffer![offset] = r / 255.0;
              floatBuffer[offset + 1] = g / 255.0;
              floatBuffer[offset + 2] = b / 255.0;
            }
          } else {
            if (isNCHW) {
              final int offset = ty * inputSize + tx;
              uint8Buffer![offset] = r.round().clamp(0, 255);
              uint8Buffer[offset + channelSize] = g.round().clamp(0, 255);
              uint8Buffer[offset + 2 * channelSize] = b.round().clamp(0, 255);
            } else {
              final int offset = (ty * inputSize + tx) * 3;
              uint8Buffer![offset] = r.round().clamp(0, 255);
              uint8Buffer[offset + 1] = g.round().clamp(0, 255);
              uint8Buffer[offset + 2] = b.round().clamp(0, 255);
            }
          }
        }
      }
    } else if (yBytes != null &&
        uBytes != null &&
        vBytes != null &&
        width != null &&
        height != null &&
        yRowStride != null &&
        uvRowStride != null &&
        uvPixelStride != null) {
      
      // Scale, rotate & convert from YUV directly to flat tensor buffer
      final int origW = height!; // rotated width
      final int origH = width!;  // rotated height
      final double scale = math.min(inputSize / origW, inputSize / origH);
      final int newW = (origW * scale).round();
      final int newH = (origH * scale).round();
      final int padX = (inputSize - newW) ~/ 2;
      final int padY = (inputSize - newH) ~/ 2;

      for (int ty = 0; ty < inputSize; ty++) {
        for (int tx = 0; tx < inputSize; tx++) {
          int r = 114;
          int g = 114;
          int b = 114;

          if (tx >= padX && tx < padX + newW && ty >= padY && ty < padY + newH) {
            final int rx = ((tx - padX) / scale).floor().clamp(0, origW - 1);
            final int ry = ((ty - padY) / scale).floor().clamp(0, origH - 1);
            
            // Back to YUV coordinates (90 degrees clockwise rotation inverse mapping)
            final int sx = ry;
            final int sy = height! - 1 - rx;

            final int yIndex = sy * yRowStride! + sx;
            final int uvX = sx ~/ 2;
            final int uvY = sy ~/ 2;
            final int uvIndex = uvY * uvRowStride! + uvX * uvPixelStride!;

            if (yIndex < yBytes.length && uvIndex < uBytes.length && uvIndex < vBytes.length) {
              final int yp = yBytes[yIndex];
              final int up = uBytes[uvIndex];
              final int vp = vBytes[uvIndex];

              r = (yp + (vp - 128) * 1436 ~/ 1024).clamp(0, 255);
              g = (yp - (up - 128) * 354 ~/ 1024 - (vp - 128) * 714 ~/ 1024).clamp(0, 255);
              b = (yp + (up - 128) * 1814 ~/ 1024).clamp(0, 255);
            }
          }

          if (isFloat) {
            if (isNCHW) {
              final int offset = ty * inputSize + tx;
              floatBuffer![offset] = r / 255.0;
              floatBuffer[offset + channelSize] = g / 255.0;
              floatBuffer[offset + 2 * channelSize] = b / 255.0;
            } else {
              final int offset = (ty * inputSize + tx) * 3;
              floatBuffer![offset] = r / 255.0;
              floatBuffer[offset + 1] = g / 255.0;
              floatBuffer[offset + 2] = b / 255.0;
            }
          } else {
            if (isNCHW) {
              final int offset = ty * inputSize + tx;
              uint8Buffer![offset] = r;
              uint8Buffer[offset + channelSize] = g;
              uint8Buffer[offset + 2 * channelSize] = b;
            } else {
              final int offset = (ty * inputSize + tx) * 3;
              uint8Buffer![offset] = r;
              uint8Buffer[offset + 1] = g;
              uint8Buffer[offset + 2] = b;
            }
          }
        }
      }
    } else {
      return [];
    }

    // 2. Set input tensor data (Zero Copy assignment)
    final inputTensor = interpreter.getInputTensor(0);
    inputTensor.data = isFloat ? floatBuffer!.buffer.asUint8List() : uint8Buffer!;

    // 3. Run model
    interpreter.invoke();

    // 4. Read output tensor directly (Zero Copy view)
    final outputTensor = interpreter.getOutputTensor(0);
    final Float32List outputFloats = Float32List.sublistView(outputTensor.data);

    // 5. Parse detections
    final detections = <DetectionResult>[];

    if (isYoloV8) {
      // Shape [1, 4 + numClasses, numDetections]
      for (var i = 0; i < numDetections; i++) {
        var classId  = 0;
        var bestProb = outputFloats[4 * numDetections + i];
        for (var c = 1; c < numClasses; c++) {
          final p = outputFloats[(4 + c) * numDetections + i];
          if (p > bestProb) {
            bestProb = p;
            classId  = c;
          }
        }

        if (bestProb < confidenceThreshold) continue;

        final cx = outputFloats[0 * numDetections + i];
        final cy = outputFloats[1 * numDetections + i];
        final w  = outputFloats[2 * numDetections + i];
        final h  = outputFloats[3 * numDetections + i];

        final int origW = (yBytes != null) ? height! : (image != null ? image.width : 640);
        final int origH = (yBytes != null) ? width! : (image != null ? image.height : 640);
        final double scale = math.min(inputSize / origW, inputSize / origH);
        final double padX = (inputSize - origW * scale) / 2;
        final double padY = (inputSize - origH * scale) / 2;

        detections.add(DetectionResult(
          label:      classId < labels.length ? labels[classId] : 'Unknown',
          confidence: bestProb,
          left:       ((cx - w / 2 - padX) / (origW * scale)).clamp(0.0, 1.0),
          top:        ((cy - h / 2 - padY) / (origH * scale)).clamp(0.0, 1.0),
          right:      ((cx + w / 2 - padX) / (origW * scale)).clamp(0.0, 1.0),
          bottom:     ((cy + h / 2 - padY) / (origH * scale)).clamp(0.0, 1.0),
          timestamp:  DateTime.now(),
        ));
      }
    } else {
      // YOLOv5 shape [1, numDetections, 5 + numClasses]
      final int cols = 5 + numClasses;
      for (var i = 0; i < numDetections; i++) {
        final int offset = i * cols;
        final double objectness = outputFloats[offset + 4];
        if (objectness < confidenceThreshold) continue;

        var classId  = 0;
        var bestProb = outputFloats[offset + 5];
        for (var c = 1; c < numClasses; c++) {
          final p = outputFloats[offset + 5 + c];
          if (p > bestProb) { bestProb = p; classId = c; }
        }

        final score = objectness * bestProb;
        if (score < confidenceThreshold) continue;

        final cx = outputFloats[offset + 0];
        final cy = outputFloats[offset + 1];
        final w  = outputFloats[offset + 2];
        final h  = outputFloats[offset + 3];

        final int origW = (yBytes != null) ? height! : (image != null ? image.width : 640);
        final int origH = (yBytes != null) ? width! : (image != null ? image.height : 640);
        final double scale = math.min(inputSize / origW, inputSize / origH);
        final double padX = (inputSize - origW * scale) / 2;
        final double padY = (inputSize - origH * scale) / 2;

        detections.add(DetectionResult(
          label:      classId < labels.length ? labels[classId] : 'Unknown',
          confidence: score,
          left:       ((cx - w / 2 - padX) / (origW * scale)).clamp(0.0, 1.0),
          top:        ((cy - h / 2 - padY) / (origH * scale)).clamp(0.0, 1.0),
          right:      ((cx + w / 2 - padX) / (origW * scale)).clamp(0.0, 1.0),
          bottom:     ((cy + h / 2 - padY) / (origH * scale)).clamp(0.0, 1.0),
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
    _workerIsolate  = null;
    _workerSendPort = null;
    _isInitialized  = false;
  }
}
