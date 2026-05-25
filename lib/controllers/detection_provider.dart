import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import '../services/detection_service.dart';
import '../services/location_service.dart';
import '../services/voice_guidance_service.dart';
import '../models/detection_result.dart';
import '../services/database_service.dart';

class DetectionProvider extends ChangeNotifier {
  static const int _stableFrameThreshold = 2;
  static const double _stableConfidenceThreshold = 0.80;
  static const double _confidenceSmoothingFactor = 0.35;

  CameraController? _cameraController;
  Timer? _detectionTimer;
  List<DetectionResult> _detections = [];
  bool _isProcessing = false;
  Position? _currentPosition;
  double _currentSpeed = 0.0;
  StreamSubscription<Position>? _positionSubscription;
  final Map<String, int> _labelStreak = {};
  final Map<String, double> _smoothedConfidence = {};

  bool _voiceEnabled = true;
  String? _activeSpeedLimit;
  bool _isInitialized = false;

  final Map<String, DateTime> _spokenSignsCooldown = {};
  final Map<String, DateTime> _lastSavedHistory = {};

  CameraController? get cameraController => _cameraController;
  List<DetectionResult> get detections => _detections;
  Position? get currentPosition => _currentPosition;
  double get currentSpeed => _currentSpeed;
  String? get activeSpeedLimit => _activeSpeedLimit;
  bool get voiceEnabled => _voiceEnabled;
  bool get isInitialized => _isInitialized;

  DetectionProvider() {
    _initLocation();
  }

  void setVoiceEnabled(bool val) {
    _voiceEnabled = val;
    notifyListeners();
  }

  Future<void> initCameraAndModel() async {
    if (_isInitialized) return;

    try {
      await DetectionService.instance.initialize();
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      _isInitialized = true;
      notifyListeners();

      _detectionTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        _processFrame();
      });
    } catch (e) {
      debugPrint('🎤 [Camera/Model] Init Error: $e');
    }
  }

  Future<void> _initLocation() async {
    try {
      final hasPermission = await LocationService.instance.startTracking();
      if (hasPermission) {
        try {
          final pos = await Geolocator.getLastKnownPosition() ??
                      await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high,
                        timeLimit: const Duration(seconds: 3),
                      );
          _currentPosition = pos;
          _currentSpeed = LocationService.instance.currentSpeedKmH;
          notifyListeners();
        } catch (e) {
          debugPrint('🎤 [DetectionProvider] Failed to get instant position: $e');
        }

        _positionSubscription = LocationService.instance.positionStream.listen((position) {
          _currentPosition = position;
          _currentSpeed = LocationService.instance.currentSpeedKmH;
          notifyListeners();
        });
      }
    } catch (e) {
      debugPrint('🎤 [Location] Init Error: $e');
    }
  }

  Future<void> _initParams() async {
    await _initLocation();
    await _initCameraAndModel();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _initCameraAndModel() async {
    try {
      await DetectionService.instance.initialize();
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      notifyListeners();

      _detectionTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        _processFrame();
      });
    } catch (e) {
      debugPrint('🎤 [Camera/Model] Init Error: $e');
    }
  }

  Future<void> _processFrame() async {
    if (_isProcessing || _cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _isProcessing = true;
    try {
      final file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();

      try {
        File(file.path).deleteSync();
      } catch (_) {}

      final results = await DetectionService.instance.detect(bytes);
      final stabilized = _stabilizeDetections(results);
      _detections = stabilized;
      notifyListeners();

      if (stabilized.isNotEmpty) {
        for (final d in stabilized) {
          _updateSpeedLimit(d.label);
        }
        final List<String> labels = stabilized.map((d) => d.label).toList();
        _speakDetectedSigns(labels);
        _saveDetectionsToHistory(stabilized, bytes); // unawaited
      }
    } catch (e) {
      debugPrint('🎤 [Detection] Error processing frame: $e');
    } finally {
      _isProcessing = false;
    }
  }

  void _updateSpeedLimit(String label) {
    final l = label.toLowerCase();
    if (l.contains('tốc độ tối đa')) {
      final matches = RegExp(r'\d+').allMatches(l);
      if (matches.isNotEmpty) {
        _activeSpeedLimit = matches.first.group(0);
        notifyListeners();
      }
    } else if (l.contains('hết tốc độ tối đa') || l.contains('hết lệnh cấm') || l.contains('ngoài khu vực đông dân cư')) {
      _activeSpeedLimit = null;
      notifyListeners();
    }
  }

  void _speakDetectedSigns(List<String> labels) {
    if (!_voiceEnabled) return;
    final now = DateTime.now();
    final List<String> signsToSpeak = [];

    for (final label in labels) {
      final lastSpoken = _spokenSignsCooldown[label];
      if (lastSpoken == null || now.difference(lastSpoken) > const Duration(seconds: 15)) {
        _spokenSignsCooldown[label] = now;
        signsToSpeak.add(label);
      }
    }

    if (signsToSpeak.isNotEmpty) {
      final announcement = signsToSpeak.join(' và ');
      VoiceGuidanceService().speakTrafficSign(announcement);
    }
  }

  String _getMockLocationName(double lat, double lng) {
    return LocationService.getMockLocationNameStatic(lat, lng);
  }

  Future<void> _saveDetectionsToHistory(List<DetectionResult> detections, Uint8List imageBytes) async {
    final now = DateTime.now();
    double lat = 10.7769;
    double lng = 106.7009;
    String locationName = '';

    final currentPos = LocationService.instance.currentPosition ?? _currentPosition;
    if (currentPos != null) {
      lat = currentPos.latitude;
      lng = currentPos.longitude;
    } else {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 3),
        );
        _currentPosition = pos;
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (_) {
        locationName = "Đang kết nối GPS...";
      }
    }

    if (locationName.isEmpty) {
      try {
        locationName = await LocationService.instance.getAddressFromCoordinates(lat, lng);
      } catch (_) {}
      if (locationName.isEmpty) {
        locationName = _getMockLocationName(lat, lng);
      }
    }

    for (final d in detections) {
      final lastSaved = _lastSavedHistory[d.label];
      if (lastSaved == null || now.difference(lastSaved) > const Duration(seconds: 15)) {
        _lastSavedHistory[d.label] = now;
        await DatabaseService().addDetectionHistory(
          label: d.label,
          confidence: displayConfidence(d.label, d.confidence),
          latitude: lat,
          longitude: lng,
          locationName: locationName,
          imageBytes: imageBytes,
        );
      }
    }
  }

  List<DetectionResult> _stabilizeDetections(List<DetectionResult> results) {
    final currentLabels = <String>{};

    for (final result in results) {
      currentLabels.add(result.label);
      final previousConfidence = _smoothedConfidence[result.label];
      _smoothedConfidence[result.label] = previousConfidence == null
          ? result.confidence
          : (previousConfidence * (1 - _confidenceSmoothingFactor)) + (result.confidence * _confidenceSmoothingFactor);

      final previousStreak = _labelStreak[result.label] ?? 0;
      _labelStreak[result.label] = (previousStreak + 1).clamp(0, 5);
    }

    final staleLabels = _labelStreak.keys.where((label) => !currentLabels.contains(label)).toList();
    for (final label in staleLabels) {
      final nextValue = (_labelStreak[label] ?? 0) - 1;
      if (nextValue <= 0) {
        _labelStreak.remove(label);
        _smoothedConfidence.remove(label);
      } else {
        _labelStreak[label] = nextValue;
      }
    }

    final stableResults = results.where((result) {
      final streak = _labelStreak[result.label] ?? 0;
      final confidence = _smoothedConfidence[result.label] ?? result.confidence;
      return streak >= _stableFrameThreshold || confidence >= _stableConfidenceThreshold;
    }).toList();

    if (stableResults.isNotEmpty) return stableResults;
    if (results.isEmpty) return const [];

    final best = results.reduce((a, b) => a.confidence >= b.confidence ? a : b);
    return [best];
  }

  double displayConfidence(String label, double rawConfidence) {
    return _smoothedConfidence[label] ?? rawConfidence;
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _positionSubscription?.cancel();
    LocationService.instance.stopTracking();
    _cameraController?.dispose();
    DetectionService.instance.dispose();
    super.dispose();
  }
}
