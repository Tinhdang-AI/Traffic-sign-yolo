import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/database_service.dart';
import 'package:traffic_detect/core/theme/app_colors.dart';
import '../widgets/traffic_sign_icon.dart';
import 'package:provider/provider.dart';
import '../controllers/settings_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  Position? _currentPosition;
  bool _isLoading = true;
  HistoryItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    _initMap();
    DatabaseService.historyChangeNotifier.addListener(_onHistoryChanged);
  }

  @override
  void dispose() {
    DatabaseService.historyChangeNotifier.removeListener(_onHistoryChanged);
    super.dispose();
  }

  void _onHistoryChanged() {
    if (mounted) {
      _loadHistoryMarkers();
    }
  }

  Future<void> _initMap() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (e) {
      debugPrint("Could not get location: $e");
    }
    
    await _loadHistoryMarkers();

    setState(() {
      _isLoading = false;
    });
  }

  Future<BitmapDescriptor> _createCustomMarker(Uint8List bytes, _SignTypeInfo signInfo) async {
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 100,
        targetHeight: 100,
      );
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ui.Image image = fi.image;

      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      
      const double size = 120.0;
      const double radius = size / 2;
      
      final double circleY = 50.0;
      final double circleRadius = 45.0;
      final double pinBottomY = 115.0;
      final double triangleWidth = 24.0;

      // Draw shadow for both pin and circle
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      final Path shadowPath = Path()
        ..addOval(Rect.fromCircle(center: Offset(radius, circleY + 2), radius: circleRadius))
        ..moveTo(radius - triangleWidth / 2, circleY + 25)
        ..lineTo(radius, pinBottomY + 2)
        ..lineTo(radius + triangleWidth / 2, circleY + 25)
        ..close();
      canvas.drawPath(shadowPath, shadowPaint);

      // Draw outer white shape
      final Paint borderPaint = Paint()..color = Colors.white;
      final Path pinPath = Path()
        ..addOval(Rect.fromCircle(center: Offset(radius, circleY), radius: circleRadius))
        ..moveTo(radius - triangleWidth / 2, circleY + 25)
        ..lineTo(radius, pinBottomY)
        ..lineTo(radius + triangleWidth / 2, circleY + 25)
        ..close();
      canvas.drawPath(pinPath, borderPaint);

      // Draw inner category color ring
      final Paint categoryPaint = Paint()
        ..color = signInfo.badgeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;
      canvas.drawCircle(Offset(radius, circleY), circleRadius - 3.5, categoryPaint);

      // Draw inner circle clip path for image
      canvas.save();
      final Path clipPath = Path()
        ..addOval(Rect.fromCircle(center: Offset(radius, circleY), radius: circleRadius - 7));
      canvas.clipPath(clipPath);

      // Draw the image
      paintImage(
        canvas: canvas,
        rect: Rect.fromCircle(center: Offset(radius, circleY), radius: circleRadius - 7),
        image: image,
        fit: BoxFit.cover,
      );
      
      canvas.restore();

      // Convert to image
      final ui.Picture picture = pictureRecorder.endRecording();
      final ui.Image markerImage = await picture.toImage(size.toInt(), (size + 30).toInt());
      final ByteData? byteData = await markerImage.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint('Error generating custom marker: $e');
    }
    
    return BitmapDescriptor.defaultMarkerWithHue(signInfo.markerHue);
  }

  Future<BitmapDescriptor> _createFallbackMarker(_SignTypeInfo signInfo, String label) async {
    try {
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      
      const double size = 120.0;
      const double radius = size / 2;
      
      final double circleY = 50.0;
      final double circleRadius = 45.0;
      final double pinBottomY = 115.0;
      final double triangleWidth = 24.0;

      // 1. Vẽ bóng đổ cho ghim
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      final Path shadowPath = Path()
        ..addOval(Rect.fromCircle(center: Offset(radius, circleY + 2), radius: circleRadius))
        ..moveTo(radius - triangleWidth / 2, circleY + 25)
        ..lineTo(radius, pinBottomY + 2)
        ..lineTo(radius + triangleWidth / 2, circleY + 25)
        ..close();
      canvas.drawPath(shadowPath, shadowPaint);

      // 2. Vẽ ghim màu trắng bên ngoài
      final Paint borderPaint = Paint()..color = Colors.white;
      final Path pinPath = Path()
        ..addOval(Rect.fromCircle(center: Offset(radius, circleY), radius: circleRadius))
        ..moveTo(radius - triangleWidth / 2, circleY + 25)
        ..lineTo(radius, pinBottomY)
        ..lineTo(radius + triangleWidth / 2, circleY + 25)
        ..close();
      canvas.drawPath(pinPath, borderPaint);

      // 3. Vẽ biển báo vector tùy chỉnh bên trong ghim
      final double innerRadius = circleRadius - 4;
      final Offset center = Offset(radius, circleY);
      final lowerLabel = label.toLowerCase();

      if (lowerLabel.contains('cấm') || lowerLabel.contains('tốc độ tối đa') || lowerLabel.contains('hạn chế') || lowerLabel.contains('dừng lại')) {
        // Biển báo cấm (Nền trắng, viền đỏ)
        canvas.drawCircle(center, innerRadius, Paint()..color = Colors.white);
        canvas.drawCircle(center, innerRadius - 2, Paint()
          ..color = const Color(0xFFE50000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8.0);
        
        if (lowerLabel.contains('ngược chiều') || lowerLabel.contains('cấm đi ngược chiều') || lowerLabel.contains('cấm đường cấm')) {
          // Biển cấm đi ngược chiều (Nền đỏ, thanh trắng nằm ngang)
          canvas.drawCircle(center, innerRadius - 2, Paint()..color = const Color(0xFFE50000));
          canvas.drawRect(
            Rect.fromCenter(center: center, width: innerRadius * 1.3, height: innerRadius * 0.35),
            Paint()..color = Colors.white,
          );
        } else if (lowerLabel.contains('dừng lại') || lowerLabel.contains('stop')) {
          // Biển STOP (Hình bát giác màu đỏ, chữ STOP trắng)
          final double stopRadius = innerRadius - 2;
          final Path octagon = Path();
          for (int i = 0; i < 8; i++) {
            final double angle = (i * 45 - 22.5) * pi / 180;
            final double x = radius + stopRadius * cos(angle);
            final double y = circleY + stopRadius * sin(angle);
            if (i == 0) {
              octagon.moveTo(x, y);
            } else {
              octagon.lineTo(x, y);
            }
          }
          octagon.close();
          canvas.drawPath(octagon, Paint()..color = const Color(0xFFE50000));
          
          final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
          tp.text = const TextSpan(
            text: 'STOP',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          );
          tp.layout();
          tp.paint(canvas, Offset(radius - tp.width / 2, circleY - tp.height / 2));
        } else if (lowerLabel.contains('tốc độ tối đa')) {
          // Biển tốc độ tối đa (Viền đỏ, số tốc độ đen)
          final matches = RegExp(r'\d+').allMatches(lowerLabel);
          final speedStr = matches.isNotEmpty ? matches.first.group(0) : '50';
          final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
          tp.text = TextSpan(
            text: speedStr,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          );
          tp.layout();
          tp.paint(canvas, Offset(radius - tp.width / 2, circleY - tp.height / 2));
        } else {
          // Biển cấm khác (Có gạch chéo đỏ)
          canvas.drawLine(
            Offset(radius - innerRadius * 0.5, circleY - innerRadius * 0.5),
            Offset(radius + innerRadius * 0.5, circleY + innerRadius * 0.5),
            Paint()
              ..color = const Color(0xFFE50000)
              ..strokeWidth = 6.0,
          );
        }
      } else if (lowerLabel.contains('chú ý') || lowerLabel.contains('nguy hiểm') || lowerLabel.contains('giao nhau')) {
        // Biển cảnh báo nguy hiểm (Hình tam giác vàng, viền đỏ, dấu chấm than đen)
        canvas.drawCircle(center, innerRadius, Paint()..color = Colors.white);
        
        final Path triangle = Path()
          ..moveTo(radius, circleY - innerRadius * 0.8)
          ..lineTo(radius - innerRadius * 0.85, circleY + innerRadius * 0.7)
          ..lineTo(radius + innerRadius * 0.85, circleY + innerRadius * 0.7)
          ..close();
        canvas.drawPath(triangle, Paint()..color = const Color(0xFFFFCC00));
        canvas.drawPath(triangle, Paint()
          ..color = const Color(0xFFE50000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.0);
          
        final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
        tp.text = const TextSpan(
          text: '!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        );
        tp.layout();
        tp.paint(canvas, Offset(radius - tp.width / 2, circleY - tp.height / 1.7));
      } else if (lowerLabel.contains('chỉ được') || lowerLabel.contains('tốc độ tối thiểu') || lowerLabel.contains('vòng xuyến') || lowerLabel.contains('hướng phải đi')) {
        // Biển hiệu lệnh (Tròn xanh lam, mũi tên trắng hướng đi)
        canvas.drawCircle(center, innerRadius, Paint()..color = const Color(0xFF00539F));
        canvas.drawCircle(center, innerRadius - 2, Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0);
          
        final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
        tp.text = TextSpan(
          text: String.fromCharCode(Icons.arrow_upward_rounded.codePoint),
          style: TextStyle(
            fontSize: 30,
            fontFamily: Icons.arrow_upward_rounded.fontFamily,
            color: Colors.white,
          ),
        );
        tp.layout();
        tp.paint(canvas, Offset(radius - tp.width / 2, circleY - tp.height / 2));
      } else if (lowerLabel.contains('hết') || lowerLabel.contains('kết thúc')) {
        // Biển hết hiệu lệnh cấm (Tròn xám trắng có vạch chéo)
        canvas.drawCircle(center, innerRadius, Paint()..color = Colors.white);
        canvas.drawCircle(center, innerRadius - 2, Paint()
          ..color = Colors.grey
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0);
          
        final slashPaint = Paint()
          ..color = Colors.grey.shade400
          ..strokeWidth = 3.0;
        for (int i = -2; i <= 2; i++) {
          final double offset = i * 6.0;
          canvas.drawLine(
            Offset(radius - innerRadius * 0.5 + offset, circleY + innerRadius * 0.5),
            Offset(radius + innerRadius * 0.5 + offset, circleY - innerRadius * 0.5),
            slashPaint,
          );
        }
      } else {
        // Biển chỉ dẫn (Hình vuông xanh lam)
        canvas.drawCircle(center, innerRadius, Paint()..color = Colors.white);
        
        final double rectSize = innerRadius * 1.3;
        canvas.drawRect(
          Rect.fromCenter(center: center, width: rectSize, height: rectSize),
          Paint()..color = const Color(0xFF00539F),
        );
        canvas.drawRect(
          Rect.fromCenter(center: center, width: rectSize - 4, height: rectSize - 4),
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
        
        final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
        tp.text = const TextSpan(
          text: 'i',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        );
        tp.layout();
        tp.paint(canvas, Offset(radius - tp.width / 2, circleY - tp.height / 2));
      }

      final ui.Picture picture = pictureRecorder.endRecording();
      final ui.Image markerImage = await picture.toImage(size.toInt(), (size + 30).toInt());
      final ByteData? byteData = await markerImage.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint('Error generating custom fallback marker: $e');
    }
    
    return BitmapDescriptor.defaultMarkerWithHue(signInfo.markerHue);
  }

  Future<void> _loadHistoryMarkers() async {
    final history = await DatabaseService().getDetectionHistory();

    // ── 1. Build geographic clusters (80 m radius) ──────────────────────────
    final List<_MapCluster> clusters = [];
    for (final item in history) {
      bool added = false;
      for (final cluster in clusters) {
        final dist = Geolocator.distanceBetween(
          item.latitude, item.longitude,
          cluster.avgLat, cluster.avgLng,
        );
        if (dist <= 80.0) {
          cluster.add(item);
          added = true;
          break;
        }
      }
      if (!added) clusters.add(_MapCluster(item));
    }

    // ── 2. Build one Marker per cluster ─────────────────────────────────────
    final markerFutures = clusters.map((cluster) async {
      final dominantInfo = _parseSignType(cluster.dominantLabel);

      final BitmapDescriptor icon;
      if (cluster.count > 1) {
        // Numbered circle marker
        icon = await _createClusterMarker(cluster.count, dominantInfo.badgeColor);
      } else {
        // Single-item: use the existing photo/vector marker
        final item = cluster.items.first;
        if (item.imageBytes != null && item.imageBytes!.isNotEmpty) {
          icon = await _createCustomMarker(item.imageBytes!, dominantInfo);
        } else {
          icon = await _createFallbackMarker(dominantInfo, item.label);
        }
      }

      return Marker(
        markerId: MarkerId('cluster_${cluster.avgLat}_${cluster.avgLng}'),
        position: LatLng(cluster.avgLat, cluster.avgLng),
        icon: icon,
        zIndexInt: cluster.count,
        onTap: () {
          if (cluster.count == 1) {
            setState(() => _selectedItem = cluster.items.first);
            _animateTo(cluster.avgLat, cluster.avgLng);
          } else {
            _showClusterSheet(cluster);
          }
        },
      );
    });

    final newMarkers = await Future.wait(markerFutures);

    if (!mounted) return;
    setState(() {
      _markers
        ..clear()
        ..addAll(newMarkers);
      _circles.clear(); // circles no longer used – clustering replaced them
      if (_selectedItem != null &&
          !history.any((item) => item.id == _selectedItem!.id)) {
        _selectedItem = null;
      }
    });
  }

  // ── Cluster marker canvas ─────────────────────────────────────────────────
  Future<BitmapDescriptor> _createClusterMarker(int count, Color color) async {
    const double size = 96.0;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final double r = size / 2;
    final Offset center = Offset(r, r);

    // Outer glow ring
    canvas.drawCircle(
      center, r,
      Paint()..color = color.withAlpha(70),
    );
    // White border
    canvas.drawCircle(
      center, r - 8,
      Paint()..color = Colors.white,
    );
    // Solid fill
    canvas.drawCircle(
      center, r - 11,
      Paint()..color = color,
    );

    // Count text
    final String text = count > 99 ? '99+' : '$count';
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: count > 9 ? 20 : 24,
          fontWeight: FontWeight.w800,
        ),
      )
      ..layout();
    tp.paint(canvas, Offset(r - tp.width / 2, r - tp.height / 2));

    final ui.Image img = await recorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final ByteData? bd = await img.toByteData(format: ui.ImageByteFormat.png);
    if (bd != null) {
      return BitmapDescriptor.bytes(bd.buffer.asUint8List());
    }
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  }

  // ── Cluster bottom-sheet ─────────────────────────────────────────────────
  void _showClusterSheet(_MapCluster cluster) {
    final isEn = context.read<SettingsProvider>().isEnglish;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.layers_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  isEn
                      ? '${cluster.count} signs at this location'
                      : '${cluster.count} biển báo tại vị trí này',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: cluster.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (ctx, i) {
                final item = cluster.items[i];
                final info = _parseSignType(item.label);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  tileColor: AppColors.surfaceContainer,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: info.badgeColor.withAlpha(40),
                      shape: BoxShape.circle,
                      border: Border.all(color: info.badgeColor.withAlpha(120)),
                    ),
                    child: Icon(info.icon, color: info.badgeColor, size: 20),
                  ),
                  title: Text(
                    item.label.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    item.displayLocationName,
                    style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedItem = item);
                    _animateTo(item.latitude, item.longitude);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _animateTo(double lat, double lng) async {
    final controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 16),
      ),
    );
  }

  void _closeSelected() {
    setState(() {
      _selectedItem = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<SettingsProvider>().isEnglish;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    // Default to a location if position is not available
    final initialCameraPosition = CameraPosition(
      target: _currentPosition != null
          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
          : const LatLng(21.028511, 105.804817),
      zoom: 14.0,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialCameraPosition,
            onMapCreated: (controller) => _controller.complete(controller),
            markers: _markers,
            circles: _circles,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            mapType: MapType.normal,
            onTap: (_) => _closeSelected(),
          ),
          
          // Header Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 24,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0.9),
                    AppColors.background.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: const Icon(Icons.map_outlined, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn ? 'Sign Map' : 'Bản đồ Biển báo',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          isEn ? 'Collected signs' : 'Các biển báo đã thu thập',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Legend Overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 90,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEn ? 'Map Legend' : 'Chú giải biển báo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildLegendItem(Colors.redAccent, isEn ? 'Prohibition (Red)' : 'Biển cấm (Đỏ)'),
                  const SizedBox(height: 6),
                  _buildLegendItem(Colors.orangeAccent, isEn ? 'Warning (Orange)' : 'Nguy hiểm (Cam)'),
                  const SizedBox(height: 6),
                  _buildLegendItem(Colors.blueAccent, isEn ? 'Mandatory/Info (Blue)' : 'Hiệu lệnh / Chỉ dẫn (Xanh)'),
                  const SizedBox(height: 6),
                  _buildLegendItem(Colors.purpleAccent, isEn ? 'End restriction (Gray)' : 'Hết cấm (Tím/Xám)'),
                ],
              ),
            ),
          ),

          // Current Location Button
          Positioned(
            right: 16,
            bottom: _selectedItem != null ? 160 : 120, // adjust based on selected card
            child: FloatingActionButton.small(
              heroTag: 'my_location',
              backgroundColor: AppColors.surfaceContainer,
              onPressed: () async {
                if (_currentPosition != null) {
                  _animateTo(_currentPosition!.latitude, _currentPosition!.longitude);
                }
              },
              child: const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),

          // Selected Marker Info Card
          if (_selectedItem != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 100, // Above the bottom nav bar gap
              child: _buildInfoCard(_selectedItem!, isEn),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(HistoryItem item, bool isEn) {
    final signInfo = _parseSignType(item.label);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Sign Image Thumbnail
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: item.imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        item.imageBytes!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: TrafficSignIcon(
                        label: item.label,
                        size: 40,
                        isEn: isEn,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: signInfo.badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: signInfo.badgeColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(signInfo.icon, size: 14, color: signInfo.badgeColor),
                        const SizedBox(width: 4),
                        Text(
                          signInfo.title,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: signInfo.badgeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${isEn ? 'Feature:' : 'Đặc điểm:'} ${signInfo.shapeDesc}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.displayLocationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                    Text(
                      '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')} - ${item.timestamp.day.toString().padLeft(2, '0')}/${item.timestamp.month.toString().padLeft(2, '0')}/${item.timestamp.year}',
                      style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Close button
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
              onPressed: _closeSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _SignTypeInfo {
  final String title;
  final String shapeDesc;
  final Color badgeColor;
  final IconData icon;
  final double markerHue;
  
  _SignTypeInfo(this.title, this.shapeDesc, this.badgeColor, this.icon, this.markerHue);
}

_SignTypeInfo _parseSignType(String label) {
  final lower = label.toLowerCase();
  
  // ─── Biển báo cấm (đỏ) ────────────────────────────────────────────────────
  if (lower.contains('cấm') ||
      lower.contains('tốc độ tối đa') ||
      lower.contains('hạn chế') ||
      lower.contains('dừng lại')) {
    // STOP bát giác
    if (lower.contains('dừng lại')) {
      return _SignTypeInfo('Biển dừng lại (STOP)',
          'Hình bát giác đỏ, chữ STOP trắng — dừng hoàn toàn',
          AppColors.error, Icons.block, BitmapDescriptor.hueRed);
    }
    // Cấm rẽ + quay đầu
    if (lower.contains('rẽ') && lower.contains('quay đầu')) {
      final dir = lower.contains('phải') ? 'phải' : 'trái';
      return _SignTypeInfo('Cấm rẽ & quay đầu $dir',
          'Tròn viền đỏ — cấm rẽ và quay đầu về phía $dir',
          AppColors.error, Icons.remove_circle_outline, BitmapDescriptor.hueRed);
    }
    // Cấm vượt
    if (lower.contains('vượt')) {
      return _SignTypeInfo('Biển cấm vượt',
          'Tròn viền đỏ — 2 xe hơi (đỏ+đen) với gạch chéo đỏ',
          AppColors.error, Icons.remove_circle_outline, BitmapDescriptor.hueRed);
    }
    // Cấm đỗ / dừng
    if (lower.contains('đỗ') || lower.contains('cấm dừng')) {
      return _SignTypeInfo('Biển cấm đỗ xe',
          'Tròn xanh viền đỏ, gạch chéo đỏ',
          AppColors.error, Icons.local_parking, BitmapDescriptor.hueRed);
    }
    // Tốc độ tối đa
    if (lower.contains('tốc độ tối đa')) {
      final m = RegExp(r'\d+').firstMatch(lower);
      final spd = m?.group(0) ?? '';
      return _SignTypeInfo('Tốc độ tối đa${spd.isNotEmpty ? " $spd km/h" : ""}',
          'Tròn viền đỏ — số $spd km/h bên trong',
          AppColors.error, Icons.speed, BitmapDescriptor.hueRed);
    }
    // Chiều cao
    if (lower.contains('chiều cao')) {
      return _SignTypeInfo('Hạn chế chiều cao',
          'Tròn viền đỏ — ký hiệu chiều cao tối đa',
          AppColors.error, Icons.height, BitmapDescriptor.hueRed);
    }
    // Cấm ngược chiều
    if (lower.contains('ngược chiều')) {
      return _SignTypeInfo('Cấm đi ngược chiều',
          'Tròn đỏ — thanh ngang trắng (biển P.102)',
          AppColors.error, Icons.remove_circle_outline, BitmapDescriptor.hueRed);
    }
    return _SignTypeInfo('Biển báo cấm', 'Hình tròn viền đỏ, nền trắng, gạch chéo đỏ',
        AppColors.error, Icons.remove_circle_outline, BitmapDescriptor.hueRed);

  // ─── Biển cảnh báo nguy hiểm (vàng) ──────────────────────────────────────
  } else if (lower.contains('chú ý')) {
    return _SignTypeInfo('Biển cảnh báo', 'Hình tam giác đều, viền đỏ, nền vàng',
        AppColors.secondary, Icons.warning_amber_rounded, BitmapDescriptor.hueYellow);

  // ─── Biển hiệu lệnh & chỉ dẫn (xanh dương) ───────────────────────────────
  } else if (lower.contains('chỉ được') ||
      lower.contains('tốc độ tối thiểu') ||
      lower.contains('vòng xuyến') ||
      lower.contains('hướng phải đi') ||
      lower.contains('bắt đầu đường ưu tiên') ||
      lower.contains('khu vực đông dân cư') ||
      lower.contains('ngoài khu vực')) {
    return _SignTypeInfo('Biển hiệu lệnh', 'Hình tròn / chữ nhật, nền xanh',
        AppColors.primaryContainer, Icons.info_outline, BitmapDescriptor.hueAzure);

  // ─── Hết hiệu lực (xám/tím) ───────────────────────────────────────────────
  } else if (lower.contains('hết tốc độ') ||
      lower.contains('hết lệnh cấm') ||
      lower.contains('kết thúc đường ưu tiên')) {
    return _SignTypeInfo('Hết hiệu lực', 'Hình tròn, viền đen, gạch chéo',
        Colors.grey, Icons.not_interested, BitmapDescriptor.hueViolet);

  // ─── Biển chỉ dẫn / thông tin (xanh nhạt) ────────────────────────────────
  } else {
    return _SignTypeInfo('Biển chỉ dẫn', 'Hình vuông/chữ nhật, nền xanh',
        AppColors.primary, Icons.map, BitmapDescriptor.hueCyan);
  }
}

// ── Geographic cluster for the map ──────────────────────────────────────────
class _MapCluster {
  final List<HistoryItem> items;

  _MapCluster(HistoryItem first) : items = [first];

  void add(HistoryItem item) => items.add(item);

  int get count => items.length;

  double get avgLat =>
      items.map((e) => e.latitude).reduce((a, b) => a + b) / items.length;
  double get avgLng =>
      items.map((e) => e.longitude).reduce((a, b) => a + b) / items.length;

  String get dominantLabel {
    final counts = <String, int>{};
    for (final item in items) {
      counts[item.label] = (counts[item.label] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

