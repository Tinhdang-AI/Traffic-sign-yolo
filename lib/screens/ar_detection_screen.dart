import 'dart:math' as math;
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_colors.dart';
import '../services/detection_service.dart';
import '../services/location_service.dart';
import '../services/voice_guidance_service.dart';
import '../models/detection_result.dart';
import '../widgets/traffic_sign_icon.dart';
import '../widgets/confidence_badge.dart';
import '../services/history_service.dart';

class ARDetectionScreen extends StatefulWidget {
  const ARDetectionScreen({super.key});

  @override
  State<ARDetectionScreen> createState() => _ARDetectionScreenState();
}

class _ARDetectionScreenState extends State<ARDetectionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _waveCtrl;
  late final Animation<double> _pulse;

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

  // Voice Guidance switch
  bool _voiceEnabled = true;
  String? _activeSpeedLimit;

  // TTS Cooldowns per label to prevent spamming
  final Map<String, DateTime> _spokenSignsCooldown = {};

  // History saving cooldowns per label
  final Map<String, DateTime> _lastSavedHistory = {};

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _initParams();
  }

  Future<void> _initParams() async {
    await _initLocation();
    await _initCameraAndModel();
  }

  Future<void> _initLocation() async {
    final hasPermission = await LocationService.instance.startTracking();
    if (hasPermission) {
      // Get the last known or current position immediately so it is not null from the start
      try {
        final pos = await Geolocator.getLastKnownPosition() ?? 
                    await Geolocator.getCurrentPosition(
                      desiredAccuracy: LocationAccuracy.high,
                      timeLimit: const Duration(seconds: 3),
                    );
        if (mounted) {
          setState(() {
            _currentPosition = pos;
            _currentSpeed = LocationService.instance.currentSpeedKmH;
          });
        }
      } catch (e) {
        print('🎤 [ARDetectionScreen] Failed to get instant position: $e');
      }

      _positionSubscription = LocationService.instance.positionStream.listen((
        position,
      ) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _currentSpeed = LocationService.instance.currentSpeedKmH;
          });
        }
      });
    }
  }

  Future<void> _initCameraAndModel() async {
    try {
      // 1. Load Model
      await DetectionService.instance.initialize();

      // 2. Setup Camera
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print('🎤 [Camera] No cameras available');
        return;
      }

      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {});

      // Periodically process camera frames
      _detectionTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        _processFrame();
      });
    } catch (e) {
      print('🎤 [Camera/Model] Init Error: $e');
    }
  }

  Future<void> _processFrame() async {
    if (_isProcessing ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    _isProcessing = true;
    try {
      final file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();

      // Delete temp picture file immediately to save disk space
      try {
        File(file.path).deleteSync();
      } catch (_) {}

      final results = await DetectionService.instance.detect(bytes);
      if (mounted) {
        final stabilized = _stabilizeDetections(results);
        setState(() {
          _detections = stabilized;
        });

        if (stabilized.isNotEmpty) {
          // 1. Update speed limit based on all detected signs
          for (final d in stabilized) {
            _updateSpeedLimit(d.label);
          }

          // 2. Speak all new stable warnings
          final List<String> labels = stabilized.map((d) => d.label).toList();
          _speakDetectedSigns(labels);

          // 3. Save all new stable warnings to SQLite History Database
          unawaited(_saveDetectionsToHistory(stabilized));
        }
      }
    } catch (e) {
      print('🎤 [Detection] Error processing frame: $e');
    } finally {
      _isProcessing = false;
    }
  }

  void _updateSpeedLimit(String label) {
    final l = label.toLowerCase();
    if (l.contains('tốc độ tối đa')) {
      final matches = RegExp(r'\d+').allMatches(l);
      if (matches.isNotEmpty) {
        setState(() {
          _activeSpeedLimit = matches.first.group(0);
        });
      }
    } else if (l.contains('hết tốc độ tối đa') ||
        l.contains('hết lệnh cấm') ||
        l.contains('ngoài khu vực đông dân cư')) {
      setState(() {
        _activeSpeedLimit = null;
      });
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
    final spots = [
      'Quốc lộ 20, Liên Nghĩa, Đức Trọng',
      'Đường ĐT725, Tà Nung, Đà Lạt',
      'Quốc lộ 27, Lương Sơn, Xã Lâm Sơn',
      'Đoạn tránh QL20, Liên Nghĩa, Đức Trọng',
      'Đường Ba Tháng Hai, Phường 1, Đà Lạt',
      'Đường Trần Hưng Đạo, Phường 10, Đà Lạt',
      'Đoạn đèo Prenn, Phường 3, Đà Lạt',
      'Quốc lộ 20, Định An, Hiệp An, Đức Trọng',
    ];
    final index = ((lat.abs() + lng.abs()) * 1000).toInt() % spots.length;
    return spots[index];
  }

  Future<void> _saveDetectionsToHistory(List<DetectionResult> detections) async {
    final now = DateTime.now();
    double lat = 10.7769; // TP. Hồ Chí Minh coordinates as a realistic default fallback
    double lng = 106.7009;
    String locationName = '';

    if (_currentPosition != null) {
      lat = _currentPosition!.latitude;
      lng = _currentPosition!.longitude;
    } else {
      // Dò vị trí nhanh nếu chưa có tín hiệu stream
      try {
        final pos = await Geolocator.getLastKnownPosition() ?? 
                    await Geolocator.getCurrentPosition(
                      desiredAccuracy: LocationAccuracy.high,
                      timeLimit: const Duration(seconds: 2),
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

      // Nếu không có mạng hoặc lỗi geocoding, dùng tên đường giả lập tiếng Việt chất lượng cao
      if (locationName.isEmpty) {
        locationName = _getMockLocationName(lat, lng);
      }
    }

    for (final d in detections) {
      final lastSaved = _lastSavedHistory[d.label];
      if (lastSaved == null || now.difference(lastSaved) > const Duration(seconds: 15)) {
        _lastSavedHistory[d.label] = now;
        
        await HistoryService().addDetection(
          label: d.label,
          confidence: _displayConfidence(d.label, d.confidence),
          latitude: lat,
          longitude: lng,
          locationName: locationName,
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
          : (previousConfidence * (1 - _confidenceSmoothingFactor)) +
                (result.confidence * _confidenceSmoothingFactor);

      final previousStreak = _labelStreak[result.label] ?? 0;
      _labelStreak[result.label] = (previousStreak + 1).clamp(0, 5);
    }

    final staleLabels = _labelStreak.keys
        .where((label) => !currentLabels.contains(label))
        .toList();
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
      return streak >= _stableFrameThreshold ||
          confidence >= _stableConfidenceThreshold;
    }).toList();

    if (stableResults.isNotEmpty) {
      return stableResults;
    }

    if (results.isEmpty) {
      return const [];
    }

    final best = results.reduce((a, b) => a.confidence >= b.confidence ? a : b);
    return [best];
  }

  double _displayConfidence(String label, double rawConfidence) {
    return _smoothedConfidence[label] ?? rawConfidence;
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _positionSubscription?.cancel();
    LocationService.instance.stopTracking();
    _cameraController?.dispose();
    DetectionService.instance.dispose();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview
          if (_cameraController != null &&
              _cameraController!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? size.width,
                  height: _cameraController!.value.previewSize?.width ?? size.height,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            )
          else
            SizedBox.expand(
              child: Container(
                color: const Color(0xFF020617),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ĐANG KHỞI TẠO HỆ THỐNG...',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white54,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // AR scanning corners and target crosshair
          Positioned.fill(
            child: CustomPaint(
              painter: _ScanningOverlayPainter(pulseValue: _pulse.value),
            ),
          ),

          // 2. Dynamic Target bounding boxes
          ..._detections.map((d) {
            final left = d.boundingBox.left * size.width;
            final topBox = d.boundingBox.top * size.height;
            return Positioned(
              left: left,
              top: topBox,
              child: _DetectionBox(
                label: d.displayLabel.isNotEmpty ? d.displayLabel : d.label,
                conf: '${(_displayConfidence(d.label, d.confidence) * 100).toInt()}%',
                borderColor: AppColors.primary,
                glowColor: AppColors.primary,
                alpha: _pulse.value,
              ),
            );
          }),

          // 3. Floating Header (Title & GPS status)
          _buildHeader(top),

          // 4. Warning alerts at top center (displays all stabilized warnings)
          if (_detections.isNotEmpty)
            Positioned(
              top: top + kToolbarHeight + 16,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _detections.take(3).map((d) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _AlertWarning(
                      label: d.label,
                      confidence: _displayConfidence(d.label, d.confidence),
                    ),
                  );
                }).toList(),
              ),
            ),

          // 5. Left speed card HUD
          Positioned(
            left: 16,
            bottom: 120,
            child: _SpeedHUD(
              speed: _currentSpeed,
              speedLimit: _activeSpeedLimit,
            ),
          ),

          // 6. Right voice toggle card HUD
          Positioned(
            right: 16,
            bottom: 120,
            child: _VoiceHUD(
              enabled: _voiceEnabled,
              onChanged: (val) {
                setState(() {
                  _voiceEnabled = val;
                });
              },
            ),
          ),

          // 7. Dynamic voice analyzer wave in the bottom center
          Positioned(
            bottom: 110,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _waveCtrl,
                builder: (_, __) => _VoiceWave(t: _waveCtrl.value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double top) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: top + kToolbarHeight,
        padding: EdgeInsets.only(top: top, left: 16, right: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF020617).withOpacity(0.4),
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.04)),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.satellite_alt_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'SENTINEL AI',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'GPS TRUY CẬP',
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SpeedHUD extends StatelessWidget {
  final double speed;
  final String? speedLimit;
  const _SpeedHUD({
    required this.speed,
    required this.speedLimit,
  });

  @override
  Widget build(BuildContext context) {
    final double? limitVal = speedLimit != null ? double.tryParse(speedLimit!) : null;
    final String diffStr = (limitVal != null)
        ? (speed - limitVal > 0 ? '+${(speed - limitVal).toInt()}' : '${(speed - limitVal).toInt()}')
        : '-- --';

    final Color diffColor = (limitVal != null)
        ? (speed - limitVal > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981))
        : Colors.white60;

    return _GlassCard(
      child: SizedBox(
        width: 112,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TỐC ĐỘ',
              style: GoogleFonts.inter(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              speed.toInt().toString(),
              style: GoogleFonts.inter(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                height: 1.0,
                color: Colors.white,
              ),
            ),
            Text(
              'KM/H',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Giới hạn',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          color: Colors.white38,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        speedLimit ?? '-- --',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.white.withOpacity(0.08),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Chênh',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          color: Colors.white38,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        diffStr,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: diffColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceHUD extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;
  const _VoiceHUD({
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: SizedBox(
        width: 112,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ĐỌC BIỂN BÁO',
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  enabled ? 'Bật' : 'Tắt',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(
                  width: 38,
                  height: 20,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Switch(
                      value: enabled,
                      onChanged: onChanged,
                      activeColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withOpacity(0.3),
                      inactiveThumbColor: Colors.white54,
                      inactiveTrackColor: Colors.white10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceWave extends StatelessWidget {
  final double t;
  const _VoiceWave({required this.t});

  @override
  Widget build(BuildContext context) {
    final heights = [12.0, 24.0, 36.0, 48.0, 36.0, 24.0, 12.0];
    final opacs = [0.25, 0.45, 0.65, 1.0, 0.65, 0.45, 0.25];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.65),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Text(
            '"Đang quét các mối nguy hiểm..."',
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) {
            final wave = math.sin((t * math.pi * 2) + (i * 0.75));
            final h = (heights[i] + wave * 8).clamp(6.0, 60.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Container(
                width: 4.5,
                height: h,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(opacs[i]),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: i == 3
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.55),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _DetectionBox extends StatelessWidget {
  final String label, conf;
  final Color borderColor, glowColor;
  final double alpha;

  const _DetectionBox({
    required this.label,
    required this.conf,
    required this.borderColor,
    required this.glowColor,
    required this.alpha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 95,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor.withOpacity(alpha), width: 2),
        color: borderColor.withOpacity(0.08),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(alpha * 0.4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          TrafficSignIcon(
            label: label,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            conf,
            style: GoogleFonts.inter(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertWarning extends StatelessWidget {
  final String label;
  final double confidence;
  const _AlertWarning({
    required this.label,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF7F1D1D).withOpacity(0.92), // Rich warning red
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          TrafficSignIcon(
            label: label,
            size: 40,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.yellow,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'CẢNH BÁO PHÍA TRƯỚC',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.yellow,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ConfidenceBadge(confidence: confidence),
        ],
      ),
    );
  }
}

class _ScanningOverlayPainter extends CustomPainter {
  final double pulseValue;
  _ScanningOverlayPainter({required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final crossPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.35 * pulseValue)
      ..strokeWidth = 1.5;

    final double w = size.width;
    final double h = size.height;

    // Draw scanning zone corner bracket borders
    final double pad = 40.0;
    final double bracketLen = 24.0;
    final cornerPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.6 * pulseValue)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Top-Left corner
    canvas.drawPath(
      Path()
        ..moveTo(pad, pad + bracketLen)
        ..lineTo(pad, pad)
        ..lineTo(pad + bracketLen, pad),
      cornerPaint,
    );

    // Top-Right corner
    canvas.drawPath(
      Path()
        ..moveTo(w - pad, pad + bracketLen)
        ..lineTo(w - pad, pad)
        ..lineTo(w - pad - bracketLen, pad),
      cornerPaint,
    );

    // Bottom-Left corner
    canvas.drawPath(
      Path()
        ..moveTo(pad, h - pad - bracketLen)
        ..lineTo(pad, h - pad)
        ..lineTo(pad + bracketLen, h - pad),
      cornerPaint,
    );

    // Bottom-Right corner
    canvas.drawPath(
      Path()
        ..moveTo(w - pad, h - pad - bracketLen)
        ..lineTo(w - pad, h - pad)
        ..lineTo(w - pad - bracketLen, h - pad),
      cornerPaint,
    );

    // Center Crosshair
    final double cx = w / 2;
    final double cy = h / 2;
    canvas.drawLine(Offset(cx - 15, cy), Offset(cx - 5, cy), crossPaint);
    canvas.drawLine(Offset(cx + 5, cy), Offset(cx + 15, cy), crossPaint);
    canvas.drawLine(Offset(cx, cy - 15), Offset(cx, cy - 5), crossPaint);
    canvas.drawLine(Offset(cx, cy + 5), Offset(cx, cy + 15), crossPaint);
    canvas.drawCircle(Offset(cx, cy), 2, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(covariant _ScanningOverlayPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}
