// import 'dart:math' as math;
// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:camera/camera.dart';
// import 'package:geolocator/geolocator.dart';
// import '../theme/app_colors.dart';
// import '../services/detection_service.dart';
// import '../services/location_service.dart';
// import '../models/detection_result.dart';

// class ARDetectionScreen extends StatefulWidget {
//   const ARDetectionScreen({super.key});
//   @override
//   State<ARDetectionScreen> createState() => _ARDetectionScreenState();
// }

// class _ARDetectionScreenState extends State<ARDetectionScreen>
//     with TickerProviderStateMixin {
//   late final AnimationController _pulseCtrl;
//   late final AnimationController _waveCtrl;
//   late final Animation<double> _pulse;
//   static const int _stableFrameThreshold = 2;
//   static const double _stableConfidenceThreshold = 0.80;
//   static const double _confidenceSmoothingFactor = 0.35;

//   CameraController? _cameraController;
//   Timer? _detectionTimer;
//   List<DetectionResult> _detections = [];
//   bool _isProcessing = false;
//   Position? _currentPosition;
//   double _currentSpeed = 0.0;
//   StreamSubscription<Position>? _positionSubscription;
//   final Map<String, int> _labelStreak = {};
//   final Map<String, double> _smoothedConfidence = {};

//   @override
//   void initState() {
//     super.initState();
//     _pulseCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 900),
//     )..repeat(reverse: true);
//     _pulse = Tween<double>(
//       begin: 0.6,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

//     _waveCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1200),
//     )..repeat();

//     _initParams();
//   }

//   Future<void> _initParams() async {
//     await _initCameraAndModel();
//     await _initLocation();
//   }

//   Future<void> _initLocation() async {
//     final hasPermission = await LocationService.instance.startTracking();
//     if (hasPermission) {
//       _positionSubscription = LocationService.instance.positionStream.listen((
//         position,
//       ) {
//         if (mounted) {
//           setState(() {
//             _currentPosition = position;
//             _currentSpeed = LocationService.instance.currentSpeedKmH;
//           });
//         }
//       });
//     }
//   }

//   Future<void> _initCameraAndModel() async {
//     // Load Model
//     await DetectionService.instance.initialize();

//     // Setup Camera
//     final cameras = await availableCameras();
//     if (cameras.isEmpty) return;

//     _cameraController = CameraController(
//       cameras[0],
//       ResolutionPreset.medium,
//       enableAudio: false,
//       imageFormatGroup: ImageFormatGroup.jpeg, // Hỗ trợ chụp ảnh jpeg tốt hơn
//     );

//     await _cameraController!.initialize();
//     if (!mounted) return;
//     setState(() {});

//     // Chạy loop lấy frame từ camera thay vì dùng startImageStream để tối ưu hiệu năng
//     _detectionTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
//       _processFrame();
//     });
//   }

//   Future<void> _processFrame() async {
//     if (_isProcessing ||
//         _cameraController == null ||
//         !_cameraController!.value.isInitialized) {
//       return;
//     }

//     _isProcessing = true;
//     try {
//       final file = await _cameraController!.takePicture();
//       final bytes = await file.readAsBytes();

//       // Xoá file tạm
//       try {
//         File(file.path).deleteSync();
//       } catch (_) {}

//       final results = await DetectionService.instance.detect(bytes);
//       if (mounted) {
//         setState(() {
//           _detections = _stabilizeDetections(results);
//         });
//       }
//     } catch (e) {
//       print('Lỗi xử lý frame: $e');
//     } finally {
//       _isProcessing = false;
//     }
//   }

//   List<DetectionResult> _stabilizeDetections(List<DetectionResult> results) {
//     final currentLabels = <String>{};

//     for (final result in results) {
//       currentLabels.add(result.label);

//       final previousConfidence = _smoothedConfidence[result.label];
//       _smoothedConfidence[result.label] = previousConfidence == null
//           ? result.confidence
//           : (previousConfidence * (1 - _confidenceSmoothingFactor)) +
//                 (result.confidence * _confidenceSmoothingFactor);

//       final previousStreak = _labelStreak[result.label] ?? 0;
//       _labelStreak[result.label] = (previousStreak + 1).clamp(0, 5);
//     }

//     final staleLabels = _labelStreak.keys
//         .where((label) => !currentLabels.contains(label))
//         .toList();
//     for (final label in staleLabels) {
//       final nextValue = (_labelStreak[label] ?? 0) - 1;
//       if (nextValue <= 0) {
//         _labelStreak.remove(label);
//         _smoothedConfidence.remove(label);
//       } else {
//         _labelStreak[label] = nextValue;
//       }
//     }

//     final stableResults = results.where((result) {
//       final streak = _labelStreak[result.label] ?? 0;
//       final confidence = _smoothedConfidence[result.label] ?? result.confidence;
//       return streak >= _stableFrameThreshold ||
//           confidence >= _stableConfidenceThreshold;
//     }).toList();

//     if (stableResults.isNotEmpty) {
//       return stableResults;
//     }

//     if (results.isEmpty) {
//       return const [];
//     }

//     final best = results.reduce((a, b) => a.confidence >= b.confidence ? a : b);
//     return [best];
//   }

//   double _displayConfidence(String label, double rawConfidence) {
//     return _smoothedConfidence[label] ?? rawConfidence;
//   }

//   @override
//   void dispose() {
//     _detectionTimer?.cancel();
//     _positionSubscription?.cancel();
//     LocationService.instance.stopTracking();
//     _cameraController?.dispose();
//     DetectionService.instance.dispose();
//     _pulseCtrl.dispose();
//     _waveCtrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final top = MediaQuery.of(context).padding.top;

//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           // Camera preview
//           if (_cameraController != null &&
//               _cameraController!.value.isInitialized)
//             SizedBox.expand(
//               child: FittedBox(
//                 fit: BoxFit.cover,
//                 child: SizedBox(
//                   width:
//                       _cameraController!.value.previewSize?.height ??
//                       size.width,
//                   height:
//                       _cameraController!.value.previewSize?.width ??
//                       size.height,
//                   child: CameraPreview(_cameraController!),
//                 ),
//               ),
//             )
//           else
//             SizedBox.expand(child: CustomPaint(painter: _RoadPainter())),

//           // AR ribbon
//           Positioned.fill(child: CustomPaint(painter: _RibbonPainter())),

//           // Detection boxes
//           ..._detections.map((d) {
//             final left = d.boundingBox.left * size.width;
//             final topBox = d.boundingBox.top * size.height;
//             return Positioned(
//               left: left,
//               top: topBox,
//               child: _DetectionBox(
//                 label: d.displayLabel.isNotEmpty ? d.displayLabel : d.label,
//                 conf:
//                     '${(_displayConfidence(d.label, d.confidence) * 100).toInt()}%',
//                 borderColor: AppColors.tertiaryContainer,
//                 glowColor: AppColors.tertiaryContainer,
//                 alpha: 1.0,
//                 icon: Icons.warning_amber_rounded,
//                 iconBg: AppColors.tertiaryContainer,
//               ),
//             );
//           }),

//           // Top bar
//           _buildTopBar(top),

//           // Warning alert top right
//           if (_detections.isNotEmpty)
//             Positioned(
//               top: top + 16,
//               right: 16,
//               child: _AlertWarning(
//                 label: _detections.first.label,
//                 confidence: _displayConfidence(
//                   _detections.first.label,
//                   _detections.first.confidence,
//                 ),
//               ),
//             ),

//           // Speed HUD left
//           Positioned(
//             left: 16,
//             bottom: 108,
//             child: _SpeedHUD(speed: _currentSpeed),
//           ),

//           // Nav HUD right
//           Positioned(right: 16, bottom: 108, child: _NavHUD()),

//           // Voice wave center
//           Positioned(
//             bottom: 100,
//             left: 0,
//             right: 0,
//             child: Center(
//               child: AnimatedBuilder(
//                 animation: _waveCtrl,
//                 builder: (_, __) => _VoiceWave(t: _waveCtrl.value),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTopBar(double top) {
//     return Positioned(
//       top: 0,
//       left: 0,
//       right: 0,
//       child: Container(
//         height: top + kToolbarHeight,
//         padding: EdgeInsets.only(top: top, left: 16, right: 16),
//         color: AppColors.surfaceContainer.withOpacity(0.70),
//         child: Row(
//           children: [
//             const Icon(Icons.satellite_alt, color: AppColors.primary, size: 20),
//             const SizedBox(width: 8),
//             Text(
//               'SENTINEL AI',
//               style: GoogleFonts.inter(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: 4,
//                 color: AppColors.primary,
//               ),
//             ),
//             // const Spacer(),
//             // Column(
//             //   mainAxisAlignment: MainAxisAlignment.center,
//             //   crossAxisAlignment: CrossAxisAlignment.end,
//             //   children: [
//             //     Text(
//             //       'GPS ACTIVE',
//             //       style: GoogleFonts.inter(
//             //         fontSize: 10,
//             //         fontWeight: FontWeight.w700,
//             //         letterSpacing: 1.5,
//             //         color: AppColors.primary,
//             //       ),
//             //     ),
//             //     Text(
//             //       _currentPosition != null
//             //           ? 'LAT: ${_currentPosition!.latitude.toStringAsFixed(4)}°'
//             //           : 'SEARCHING...',
//             //       style: GoogleFonts.inter(
//             //         fontSize: 9,
//             //         color: AppColors.onSurfaceVariant.withOpacity(0.55),
//             //       ),
//             //     ),
//             //   ],
//             // ),
//             // const SizedBox(width: 8),
//             // const Icon(
//             //   Icons.signal_cellular_alt,
//             //   color: AppColors.primary,
//             //   size: 18,
//             // ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _RoadPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size s) {
//     canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF0A0F1A));
//     final skyR = Rect.fromLTWH(0, 0, s.width, s.height * 0.56);
//     canvas.drawRect(
//       skyR,
//       Paint()
//         ..shader = const LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [Color(0xFF0B1120), Color(0xFF16253A)],
//         ).createShader(skyR),
//     );

//     final roadTop = s.height * 0.52;
//     final roadPath = Path()
//       ..moveTo(0, s.height)
//       ..lineTo(s.width, s.height)
//       ..lineTo(s.width * 0.75, roadTop)
//       ..lineTo(s.width * 0.25, roadTop)
//       ..close();
//     canvas.drawPath(
//       roadPath,
//       Paint()
//         ..shader = LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [const Color(0xFF1A2030), const Color(0xFF22293A)],
//         ).createShader(Rect.fromLTWH(0, roadTop, s.width, s.height - roadTop)),
//     );

//     final dp = Paint()
//       ..color = Colors.white.withOpacity(0.35)
//       ..strokeWidth = 3;
//     for (int i = 0; i < 7; i++) {
//       final y1 = s.height * 0.58 + i * 46.0;
//       final y2 = y1 + 26;
//       if (y2 > s.height) break;
//       canvas.drawLine(Offset(s.width / 2, y1), Offset(s.width / 2, y2), dp);
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter _) => false;
// }

// class _RibbonPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size s) {
//     final path = Path()
//       ..moveTo(s.width * 0.46, s.height)
//       ..lineTo(s.width * 0.54, s.height)
//       ..lineTo(s.width * 0.52, s.height * 0.60)
//       ..lineTo(s.width * 0.48, s.height * 0.60)
//       ..close();
//     canvas.drawPath(
//       path,
//       Paint()
//         ..shader = LinearGradient(
//           begin: Alignment.bottomCenter,
//           end: Alignment.topCenter,
//           colors: [
//             AppColors.primaryContainer.withOpacity(0.40),
//             Colors.transparent,
//           ],
//         ).createShader(Rect.fromLTWH(0, 0, s.width, s.height)),
//     );
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter _) => false;
// }

// class _DetectionBox extends StatelessWidget {
//   final String label, conf;
//   final Color borderColor, glowColor, iconBg;
//   final double alpha;
//   final IconData icon;
//   const _DetectionBox({
//     required this.label,
//     required this.conf,
//     required this.borderColor,
//     required this.glowColor,
//     required this.alpha,
//     required this.icon,
//     required this.iconBg,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 88,
//       height: 88,
//       decoration: BoxDecoration(
//         border: Border.all(color: borderColor.withOpacity(alpha), width: 2),
//         color: borderColor.withOpacity(0.07),
//         boxShadow: [
//           BoxShadow(color: glowColor.withOpacity(alpha * 0.6), blurRadius: 14),
//         ],
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             label,
//             textAlign: TextAlign.center,
//             style: GoogleFonts.inter(
//               fontSize: 7,
//               fontWeight: FontWeight.w700,
//               letterSpacing: 0.8,
//               color: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 5),
//           Container(
//             width: 32,
//             height: 32,
//             decoration: BoxDecoration(
//               color: iconBg,
//               shape: BoxShape.circle,
//               boxShadow: [
//                 BoxShadow(color: iconBg.withOpacity(0.45), blurRadius: 8),
//               ],
//             ),
//             child: Icon(icon, color: Colors.white, size: 16),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             conf,
//             style: GoogleFonts.inter(
//               fontSize: 8,
//               fontWeight: FontWeight.w600,
//               color: Colors.white.withOpacity(0.65),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _WarningBadge extends StatelessWidget {
//   final String text;
//   const _WarningBadge({required this.text});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
//       decoration: BoxDecoration(
//         color: AppColors.tertiaryContainer,
//         borderRadius: BorderRadius.circular(999),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.tertiaryContainer.withOpacity(0.55),
//             blurRadius: 18,
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Icon(Icons.warning_rounded, color: Colors.white, size: 16),
//           const SizedBox(width: 7),
//           Text(
//             text,
//             style: GoogleFonts.inter(
//               fontSize: 10,
//               fontWeight: FontWeight.w700,
//               letterSpacing: 1.1,
//               color: Colors.white,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _SpeedHUD extends StatelessWidget {
//   final double speed;
//   const _SpeedHUD({required this.speed});

//   @override
//   Widget build(BuildContext context) {
//     return _GlassCard(
//       child: SizedBox(
//         width: 108,
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'TỐC ĐỘ',
//               style: GoogleFonts.inter(
//                 fontSize: 8,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: 1.5,
//                 color: AppColors.onSurfaceVariant.withOpacity(0.65),
//               ),
//             ),
//             Text(
//               speed.toInt().toString(),
//               style: GoogleFonts.inter(
//                 fontSize: 46,
//                 fontWeight: FontWeight.w700,
//                 height: 1.05,
//                 color: AppColors.primary,
//               ),
//             ),
//             Text(
//               'KM/H',
//               style: GoogleFonts.inter(
//                 fontSize: 10,
//                 fontWeight: FontWeight.w700,
//                 color: AppColors.primaryFixedDim,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Divider(color: Colors.white.withOpacity(0.1), height: 1),
//             const SizedBox(height: 8),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 _StatCell(
//                   label: 'Giới hạn',
//                   value: '45',
//                   color: AppColors.onSurface,
//                 ),
//                 _StatCell(
//                   label: 'Chênh',
//                   value: '-3',
//                   color: AppColors.secondary,
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _StatCell extends StatelessWidget {
//   final String label, value;
//   final Color color;
//   const _StatCell({
//     required this.label,
//     required this.value,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Text(
//           label,
//           style: GoogleFonts.inter(
//             fontSize: 8,
//             color: AppColors.onSurfaceVariant.withOpacity(0.55),
//           ),
//         ),
//         Text(
//           value,
//           style: GoogleFonts.inter(
//             fontSize: 17,
//             fontWeight: FontWeight.w600,
//             color: color,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _NavHUD extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return _GlassCard(
//       child: SizedBox(
//         width: 145,
//         child: Row(
//           children: [
//             const Icon(
//               Icons.turn_right_rounded,
//               color: AppColors.primary,
//               size: 34,
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   RichText(
//                     text: TextSpan(
//                       style: GoogleFonts.inter(
//                         fontSize: 19,
//                         fontWeight: FontWeight.w700,
//                         color: AppColors.primary,
//                       ),
//                       children: [
//                         const TextSpan(text: '1.2 '),
//                         TextSpan(
//                           text: 'km',
//                           style: GoogleFonts.inter(
//                             fontSize: 11,
//                             color: AppColors.primary,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Đường Nguyễn Huệ',
//                     style: GoogleFonts.inter(
//                       fontSize: 10,
//                       height: 1.4,
//                       color: AppColors.onSurfaceVariant,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _VoiceWave extends StatelessWidget {
//   final double t;
//   const _VoiceWave({required this.t});

//   @override
//   Widget build(BuildContext context) {
//     final heights = [14.0, 28.0, 42.0, 56.0, 42.0, 28.0, 14.0];
//     final opacs = [0.25, 0.45, 0.65, 1.0, 0.65, 0.45, 0.25];
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
//           decoration: BoxDecoration(
//             color: Colors.black.withOpacity(0.55),
//             borderRadius: BorderRadius.circular(999),
//           ),
//           child: Text(
//             '"Đang quét các mối nguy hiểm..."',
//             style: GoogleFonts.inter(
//               fontSize: 10,
//               fontWeight: FontWeight.w700,
//               letterSpacing: 1.2,
//               color: AppColors.primary,
//             ),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: List.generate(7, (i) {
//             final wave = math.sin((t * math.pi * 2) + (i * 0.75));
//             final h = (heights[i] + wave * 10).clamp(6.0, 72.0);
//             return Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 2.5),
//               child: Container(
//                 width: 5,
//                 height: h,
//                 decoration: BoxDecoration(
//                   color: AppColors.primary.withOpacity(opacs[i]),
//                   borderRadius: BorderRadius.circular(3),
//                   boxShadow: i == 3
//                       ? [
//                           BoxShadow(
//                             color: AppColors.primary.withOpacity(0.55),
//                             blurRadius: 12,
//                           ),
//                         ]
//                       : null,
//                 ),
//               ),
//             );
//           }),
//         ),
//       ],
//     );
//   }
// }

// class _GlassCard extends StatelessWidget {
//   final Widget child;
//   const _GlassCard({required this.child});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: AppColors.surfaceContainer.withOpacity(0.68),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.white.withOpacity(0.10)),
//         boxShadow: [
//           BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 24),
//         ],
//       ),
//       child: child,
//     );
//   }
// }

// class _AlertWarning extends StatelessWidget {
//   final String label;
//   final double confidence;
//   const _AlertWarning({required this.label, required this.confidence});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: AppColors.tertiaryContainer.withOpacity(0.95),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: AppColors.tertiaryContainer.withOpacity(0.7),
//           width: 1.5,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.tertiaryContainer.withOpacity(0.6),
//             blurRadius: 20,
//             spreadRadius: 2,
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(
//                 Icons.warning_amber_rounded,
//                 color: Colors.white,
//                 size: 20,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 'CẢM SỬ DỤNG',
//                 style: GoogleFonts.inter(
//                   fontSize: 9,
//                   fontWeight: FontWeight.w700,
//                   letterSpacing: 1.2,
//                   color: Colors.white.withOpacity(0.85),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             label,
//             style: GoogleFonts.inter(
//               fontSize: 14,
//               fontWeight: FontWeight.w700,
//               color: Colors.white,
//               letterSpacing: 0.5,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Container(
//             height: 4,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(2),
//               color: Colors.white.withOpacity(0.2),
//             ),
//             child: Align(
//               alignment: Alignment.centerLeft,
//               child: Container(
//                 width: 90 * confidence,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(2),
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             '${(confidence * 100).toInt()}% confidence',
//             style: GoogleFonts.inter(
//               fontSize: 10,
//               fontWeight: FontWeight.w600,
//               color: Colors.white.withOpacity(0.75),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
