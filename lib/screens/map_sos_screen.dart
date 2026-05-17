import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/history_service.dart';
import '../theme/app_colors.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};
  Position? _currentPosition;
  bool _isLoading = true;
  HistoryItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint("Could not get location: $e");
    }
    
    await _loadHistoryMarkers();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadHistoryMarkers() async {
    final history = await HistoryService().getHistory();
    final Set<Marker> newMarkers = {};
    
    for (var item in history) {
      final signInfo = _parseSignType(item.label);
      newMarkers.add(
        Marker(
          markerId: MarkerId(item.id),
          position: LatLng(item.latitude, item.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(signInfo.markerHue),
          onTap: () {
            setState(() {
              _selectedItem = item;
            });
            _animateTo(item.latitude, item.longitude);
          },
        ),
      );
    }
    
    setState(() {
      _markers.addAll(newMarkers);
    });
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialCameraPosition,
            onMapCreated: (controller) => _controller.complete(controller),
            markers: _markers,
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
                    AppColors.background.withOpacity(0.9),
                    AppColors.background.withOpacity(0.0),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Icon(Icons.map_outlined, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bản đồ Biển báo',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Các biển báo đã thu thập',
                          style: TextStyle(
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
                color: AppColors.surfaceContainerHighest.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chú giải biển báo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildLegendItem(Colors.redAccent, 'Biển cấm (Đỏ)'),
                  const SizedBox(height: 6),
                  _buildLegendItem(Colors.orangeAccent, 'Nguy hiểm (Cam)'),
                  const SizedBox(height: 6),
                  _buildLegendItem(Colors.blueAccent, 'Hiệu lệnh / Chỉ dẫn (Xanh)'),
                  const SizedBox(height: 6),
                  _buildLegendItem(Colors.purpleAccent, 'Hết cấm (Tím/Xám)'),
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
              child: _buildInfoCard(_selectedItem!),
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
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
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

  Widget _buildInfoCard(HistoryItem item) {
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
          color: AppColors.surfaceContainerHighest.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
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
                color: AppColors.background,
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
                  : const Icon(Icons.traffic, color: AppColors.onSurfaceVariant),
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
                      color: signInfo.badgeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: signInfo.badgeColor.withOpacity(0.3)),
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
                    'Đặc điểm: ${signInfo.shapeDesc}',
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
                          item.locationName,
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
  
  if (lower.contains('cấm') || lower.contains('tốc độ tối đa') || lower.contains('hạn chế') || lower.contains('dừng lại')) {
    if (lower.contains('dừng lại')) {
      return _SignTypeInfo('Biển báo cấm', 'Hình bát giác, nền đỏ, chữ trắng', AppColors.error, Icons.block, BitmapDescriptor.hueRed);
    }
    return _SignTypeInfo('Biển báo cấm', 'Hình tròn, viền đỏ, nền trắng', AppColors.error, Icons.remove_circle_outline, BitmapDescriptor.hueRed);
  } else if (lower.contains('chú ý') || lower.contains('nguy hiểm') || lower.contains('giao nhau')) {
    return _SignTypeInfo('Biển cảnh báo', 'Hình tam giác đều, viền đỏ, nền vàng', AppColors.secondary, Icons.warning_amber_rounded, BitmapDescriptor.hueYellow);
  } else if (lower.contains('chỉ được') || lower.contains('tốc độ tối thiểu') || lower.contains('vòng xuyến') || lower.contains('hướng phải đi')) {
    return _SignTypeInfo('Biển hiệu lệnh', 'Hình tròn, nền xanh, hình trắng', AppColors.primaryContainer, Icons.info_outline, BitmapDescriptor.hueAzure);
  } else if (lower.contains('hết') || lower.contains('kết thúc')) {
    return _SignTypeInfo('Hết hiệu lệnh cấm', 'Hình tròn, viền đen, gạch chéo', Colors.grey, Icons.not_interested, BitmapDescriptor.hueViolet);
  } else {
    return _SignTypeInfo('Biển chỉ dẫn', 'Hình vuông/chữ nhật, nền xanh', AppColors.primary, Icons.map, BitmapDescriptor.hueCyan);
  }
}
