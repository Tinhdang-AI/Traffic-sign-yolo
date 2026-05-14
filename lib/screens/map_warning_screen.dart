import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/directions_service.dart';
import '../services/geocoding_service.dart';
import '../services/voice_guidance_service.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_colors.dart';
import '../services/location_service.dart';
import '../providers/navigation_provider.dart';

class MapWarningScreen extends StatefulWidget {
  const MapWarningScreen({super.key});

  @override
  State<MapWarningScreen> createState() => _MapWarningScreenState();
}

class _MapWarningScreenState extends State<MapWarningScreen> {
  GoogleMapController? mapController;
  LatLng _center = const LatLng(10.762622, 106.660172); // Default
  double _currentSpeed = 0.0;
  bool _isTracking = false;
  StreamSubscription<Position>? _positionSubscription;
  final TextEditingController _destinationController = TextEditingController();

  LatLng? _currentLatLng;
  LatLng? _destinationLatLng;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  double _heading = 0.0;
  double _bearingToDestination = 0.0;
  BitmapDescriptor? _navArrowIcon;

  // Voice guidance
  late VoiceGuidanceService _voiceService;

  NavigationProvider get _nav => context.read<NavigationProvider>();

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceGuidanceService();
    _voiceService.init();
    _initLocation();
    _initNavIcon();
  }

  Future<void> _initNavIcon() async {
    try {
      final bytes = await _drawArrowPng(96, AppColors.primary);
      _navArrowIcon = BitmapDescriptor.fromBytes(bytes);
      if (mounted) setState(() {});
    } catch (_) {
      // fallback left as default marker
    }
  }

  Future<Uint8List> _drawArrowPng(int size, Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    );

    final paint = Paint()..color = color;
    // draw a simple triangular navigation arrow pointing up
    final path = Path();
    final cx = size / 2;
    final top = size * 0.18;
    final bottom = size * 0.78;
    final left = size * 0.28;
    final right = size * 0.72;

    path.moveTo(cx, top);
    path.lineTo(right, bottom);
    path.lineTo(cx, bottom * 0.85);
    path.lineTo(left, bottom);
    path.close();

    // shadow circle background
    final circlePaint = Paint()..color = Colors.white.withOpacity(0.05);
    canvas.drawCircle(Offset(cx, cx), size * 0.5, circlePaint);

    canvas.drawPath(path, paint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> _initLocation() async {
    final hasPermission = await LocationService.instance.startTracking();
    if (hasPermission) {
      _positionSubscription = LocationService.instance.positionStream.listen((
        position,
      ) {
        if (mounted) {
          setState(() {
            _center = LatLng(position.latitude, position.longitude);
            _currentLatLng = _center;
            _currentSpeed = LocationService.instance.currentSpeedKmH;
            _isTracking = true;
            if (position.heading >= 0 && position.heading.isFinite) {
              _heading = position.heading;
              _nav.setHeading(_heading);
            }
          });

          // Update map camera with tilt and heading in driving mode
          if (_nav.isDrivingMode && mapController != null) {
            _updateMapCamera();
          } else {
            mapController?.animateCamera(CameraUpdate.newLatLng(_center));
          }

          _refreshMapOverlays();
          _updateRouteMetrics();
        }
      });
    } else {
      setState(() {
        _nav.setSearchError('Cần cấp quyền vị trí để tìm đường.');
      });
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    LocationService.instance.stopTracking();
    _voiceService.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (_isTracking && _center.latitude != 10.762622) {
      mapController?.animateCamera(CameraUpdate.newLatLng(_center));
    }
    _refreshMapOverlays();
  }

  Future<void> _searchRoute() async {
    final query = _destinationController.text.trim();
    if (query.isEmpty) {
      _nav.setSearchError('Vui lòng nhập điểm đến.');
      return;
    }

    if (_currentLatLng == null) {
      _nav.setSearchError('Đang chờ định vị hiện tại. Vui lòng thử lại.');
      return;
    }

    _nav.setSearching(true);
    _nav.setSearchError(null);

    try {
      final result = await GeocodingService.geocodeAddress(query);
      final destination = LatLng(result.latitude, result.longitude);

      setState(() {
        _destinationLatLng = destination;
      });
      _nav.setDestinationLatLng(destination);
      _nav.setDestinationLabel(result.displayName);

      _refreshMapOverlays();

      // call OSRM API to get street polyline and ETA (free, no key required)
      try {
        final directions = await DirectionsService.getDirections(
          origin: _currentLatLng!,
          destination: destination,
        );

        final etaDate = DateTime.now().add(
          Duration(seconds: directions.durationSeconds),
        );

        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route_line'),
              points: directions.points,
              color: AppColors.primary,
              width: 6,
              geodesic: true,
            ),
          };
        });

        _nav.setRouteSummary(
          etaText:
              '${etaDate.hour.toString().padLeft(2, '0')}:${etaDate.minute.toString().padLeft(2, '0')}',
          distanceText: directions.distanceText,
          routeHint: '${directions.durationText}, ${directions.distanceText}',
        );
        _nav.setDrivingMode(true);
        _nav.setSteps(directions.steps);
        _nav.setOffRoute(false);

        _refreshMapOverlays();

        // Announce the first instruction after a short delay
        if (_nav.voiceEnabled && directions.steps.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _voiceService.speakInstruction(
              directions.steps.first.vietnameseInstruction,
            );
          });
        }

        if (mapController != null && _currentLatLng != null) {
          final bounds = _boundsFrom(_currentLatLng!, destination);
          await mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 70),
          );
        }
      } catch (e) {
        _nav.setSearchError(
          'Không thể lấy tuyến đường chi tiết: ${e.toString()}',
        );
      }
    } catch (e) {
      _nav.setSearchError(e.toString());
    } finally {
      _nav.setSearching(false);
    }
  }

  LatLngBounds _boundsFrom(LatLng a, LatLng b) {
    final south = math.min(a.latitude, b.latitude);
    final north = math.max(a.latitude, b.latitude);
    final west = math.min(a.longitude, b.longitude);
    final east = math.max(a.longitude, b.longitude);
    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  void _refreshMapOverlays() {
    final nextMarkers = <Marker>{};
    final nextPolylines = <Polyline>{};

    if (_currentLatLng != null) {
      nextMarkers.add(
        Marker(
          markerId: const MarkerId('current_position'),
          position: _currentLatLng!,
          infoWindow: const InfoWindow(title: 'Vị trí hiện tại'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    // Navigation arrow marker (rotates to show bearing to destination)
    if (_currentLatLng != null) {
      nextMarkers.add(
        Marker(
          markerId: const MarkerId('nav_arrow'),
          position: _currentLatLng!,
          anchor: const Offset(0.5, 0.5),
          rotation: _bearingToDestination,
          infoWindow: const InfoWindow(title: 'Hướng đi'),
          icon:
              _navArrowIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    if (_destinationLatLng != null) {
      nextMarkers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLatLng!,
          infoWindow: InfoWindow(title: _nav.destinationLabel),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    // Polylines will be replaced with real route from DirectionsService

    if (!mounted) return;
    setState(() {
      _markers = nextMarkers;
      _polylines = nextPolylines;
    });
  }

  void _updateRouteMetrics() {
    if (_currentLatLng == null || _destinationLatLng == null) {
      _nav.setRouteSummary(
        etaText: '--:--',
        distanceText: '-',
        routeHint: 'Không có chỉ dẫn cho tuyến này',
      );
      return;
    }

    // Check for off-route condition (only every 5 seconds to save CPU)
    final now = DateTime.now();
    if (_nav.isDrivingMode &&
        _polylines.isNotEmpty &&
        (_nav.lastOffRouteCheck == null ||
            now.difference(_nav.lastOffRouteCheck!) >
                const Duration(seconds: 5))) {
      _checkIfOffRoute();
      _nav.setLastOffRouteCheck(now);
    }

    final distanceMeters = Geolocator.distanceBetween(
      _currentLatLng!.latitude,
      _currentLatLng!.longitude,
      _destinationLatLng!.latitude,
      _destinationLatLng!.longitude,
    );
    final speedForEstimate = _currentSpeed > 5 ? _currentSpeed : 35.0;
    final etaMinutes = ((distanceMeters / 1000) / speedForEstimate * 60).clamp(
      1,
      24 * 60,
    );
    final etaDate = DateTime.now().add(Duration(minutes: etaMinutes.round()));

    _bearingToDestination = Geolocator.bearingBetween(
      _currentLatLng!.latitude,
      _currentLatLng!.longitude,
      _destinationLatLng!.latitude,
      _destinationLatLng!.longitude,
    );
    _nav.setBearingToDestination(_bearingToDestination);

    // Update current step if we have steps
    if (_nav.isDrivingMode && _nav.currentSteps.isNotEmpty) {
      _updateCurrentStep();
    }

    _nav.setRouteSummary(
      etaText:
          '${etaDate.hour.toString().padLeft(2, '0')}:${etaDate.minute.toString().padLeft(2, '0')}',
      distanceText: _formatDistance(distanceMeters),
      routeHint: _buildRouteHint(distanceMeters),
    );
  }

  /// Check if user drifted more than 50m away from the route
  void _checkIfOffRoute() {
    if (_currentLatLng == null || _polylines.isEmpty) return;

    final polyline = _polylines.first;
    double minDistance = double.infinity;

    for (final point in polyline.points) {
      final distance = Geolocator.distanceBetween(
        _currentLatLng!.latitude,
        _currentLatLng!.longitude,
        point.latitude,
        point.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    final wasOffRouteProvider = _nav.isOffRoute;
    final isOffRoute = minDistance > 50;
    _nav.setOffRoute(isOffRoute);

    if (isOffRoute && !wasOffRouteProvider && _nav.voiceEnabled) {
      _voiceService.speakOffRoute();
    }
  }

  /// Track which turn-by-turn step we're on and announce when approaching
  void _updateCurrentStep() {
    if (_nav.currentSteps.isEmpty || _currentLatLng == null) return;

    // Find the closest upcoming step
    for (int i = _nav.currentStepIndex; i < _nav.currentSteps.length; i++) {
      final step = _nav.currentSteps[i];
      final distToStep = Geolocator.distanceBetween(
        _currentLatLng!.latitude,
        _currentLatLng!.longitude,
        step.location.latitude,
        step.location.longitude,
      );

      if (distToStep < 100) {
        // We've reached this step, move to next
        _nav.setCurrentStepIndex(i + 1);
      } else if (distToStep < 150 && distToStep >= 100) {
        // Approaching this step (100-150m), announce if not yet announced
        final now = DateTime.now();
        if (_nav.lastStepAnnounceTime == null ||
            now.difference(_nav.lastStepAnnounceTime!) >
                const Duration(seconds: 10)) {
          if (_nav.voiceEnabled) {
            final nextStep = _nav.currentSteps[i];
            _voiceService.speakInstruction(
              '${nextStep.vietnameseInstruction} vào ${nextStep.name}',
            );
          }
          _nav.setLastStepAnnounceTime(now);
        }
        break;
      }
    }

    // Check if arrived
    if (_currentLatLng != null && _destinationLatLng != null) {
      final arrivalDistance = Geolocator.distanceBetween(
        _currentLatLng!.latitude,
        _currentLatLng!.longitude,
        _destinationLatLng!.latitude,
        _destinationLatLng!.longitude,
      );

      if (arrivalDistance < 30 && _nav.voiceEnabled) {
        _voiceService.speakArrival();
      }
    }
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }

  String _buildRouteHint(double distanceMeters) {
    // If we have turn-by-turn steps, use them
    if (_nav.currentSteps.isNotEmpty &&
        _nav.currentStepIndex < _nav.currentSteps.length) {
      final nextStep = _nav.currentSteps[_nav.currentStepIndex];
      return '${nextStep.vietnameseInstruction} vào ${nextStep.name} (${nextStep.distanceText})';
    }

    // Fallback to bearing-based instruction
    final turn = _turnInstruction();
    if (distanceMeters < 80) {
      return 'Bạn đã đến gần điểm đến.';
    }
    return '$turn, còn ${_formatDistance(distanceMeters)}';
  }

  String _turnInstruction() {
    final delta = ((_bearingToDestination - _heading + 540) % 360) - 180;
    if (delta.abs() < 15) return 'Đi thẳng theo hướng hiện tại';
    if (delta.abs() < 45) {
      return delta > 0 ? 'Chếch phải nhẹ' : 'Chếch trái nhẹ';
    }
    if (delta.abs() < 120) {
      return delta > 0 ? 'Rẽ phải' : 'Rẽ trái';
    }
    return 'Quay đầu khi an toàn';
  }

  IconData _directionIcon(NavigationProvider nav) {
    final delta = ((nav.bearingToDestination - nav.heading + 540) % 360) - 180;
    if (delta.abs() < 15) return Icons.straight;
    if (delta.abs() < 45) {
      return delta > 0 ? Icons.turn_slight_right : Icons.turn_slight_left;
    }
    if (delta.abs() < 120) {
      return delta > 0 ? Icons.turn_right : Icons.turn_left;
    }
    return Icons.u_turn_right;
  }

  Future<void> _zoomIn() async {
    if (mapController == null) return;
    await mapController!.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    if (mapController == null) return;
    await mapController!.animateCamera(CameraUpdate.zoomOut());
  }

  /// Update map camera with 3D tilt and heading rotation when driving
  void _updateMapCamera() {
    if (mapController == null || _currentLatLng == null) return;

    // 3D tilt effect (15 degrees) for better navigation view
    final tilt = 15.0;
    // Zoom level 18 is good for turn-by-turn navigation
    const zoom = 18.0;

    final cameraUpdate = CameraUpdate.newCameraPosition(
      CameraPosition(
        target: _currentLatLng!,
        zoom: zoom,
        bearing: _heading, // Rotate map to match device heading
        tilt: tilt,
      ),
    );

    mapController!.animateCamera(cameraUpdate);
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final top = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Persistent map + top bar (map height fixed to 30% to match previous driving layout)
          Column(
            children: [
              _buildTopBar(top),
              SizedBox(
                height: screenHeight * 0.3,
                width: double.infinity,
                child: _MapView(
                  center: _currentLatLng ?? _center,
                  onMapCreated: _onMapCreated,
                  markers: _markers,
                  polylines: _polylines,
                  onZoomIn: _zoomIn,
                  onZoomOut: _zoomOut,
                ),
              ),
              // filler so the column fills the screen without recreating the map
              const Expanded(child: SizedBox.shrink()),
            ],
          ),

          if (nav.isDrivingMode && nav.destinationLatLng != null)
            // Driving overlay sits below the map (30% top)
            Positioned.fill(
              top: screenHeight * 0.3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Destination + ETA
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Đến: ${nav.destinationLabel}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${nav.etaText} · ${nav.distanceText}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // The in-map navigation arrow is shown as a Marker on the map.

                  // Route hint
                  Container(
                    margin: const EdgeInsets.only(top: 30),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      nav.routeHint,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Exit button when driving
          if (nav.isDrivingMode && nav.destinationLatLng != null)
            Positioned(
              top: screenHeight * 0.32,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _destinationController.clear();
                    _destinationLatLng = null;
                    _polylines.clear();
                    _markers.clear();
                    _nav.resetNavigation();
                  });
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryContainer,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.tertiaryContainer.withValues(
                          alpha: 0.4,
                        ),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),

          // Search / info panel when not driving
          if (!(nav.isDrivingMode && nav.destinationLatLng != null))
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SearchRouteCard(
                      controller: _destinationController,
                      isLoading: nav.isSearching,
                      onSearch: _searchRoute,
                    ),
                    if (nav.searchError != null) ...[
                      const SizedBox(height: 10),
                      _WarningCard(
                        icon: Icons.error_outline,
                        iconColor: AppColors.tertiaryContainer,
                        title: 'Không tìm thấy tuyến đường',
                        subtitle: nav.searchError!,
                        tag: 'LỖI',
                        tagColor: AppColors.tertiaryContainer,
                      ),
                    ],
                    const SizedBox(height: 12),
                    _RouteBar(
                      destination: nav.destinationLabel,
                      routeHint: nav.routeHint,
                      directionIcon: _directionIcon(nav),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(double top) {
    return Container(
      padding: EdgeInsets.only(top: top, left: 16, right: 16, bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.satellite_alt, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            'SENTINEL AI',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 3.5,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'BẢN ĐỒ & CẢNH BÁO',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapView extends StatelessWidget {
  final LatLng center;
  final void Function(GoogleMapController) onMapCreated;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const _MapView({
    required this.center,
    required this.onMapCreated,
    required this.markers,
    required this.polylines,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      width: double.infinity,
      color: const Color(0xFF0D1520),
      child: Stack(
        children: [
          GoogleMap(
            onMapCreated: onMapCreated,
            initialCameraPosition: CameraPosition(target: center, zoom: 14.0),
            mapType: MapType.hybrid,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: markers,
            polylines: polylines,
          ),
          // Top overlay info
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer.withOpacity(0.85),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.my_location,
                    color: AppColors.primary,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Hồ Chí Minh City',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Zoom controls
          Positioned(
            right: 10,
            bottom: 10,
            child: Column(
              children: [
                _MapButton(icon: Icons.add, onTap: onZoomIn),
                const SizedBox(height: 4),
                _MapButton(icon: Icons.remove, onTap: onZoomOut),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(icon, color: AppColors.onSurface, size: 18),
        ),
      ),
    );
  }
}

class _SearchRouteCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSearch;

  const _SearchRouteCard({
    required this.controller,
    required this.isLoading,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.place_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSearch(),
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.onSurface,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Nhập điểm đến',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant.withOpacity(0.65),
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: isLoading ? null : onSearch,
            icon: isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.background,
                    ),
                  )
                : const Icon(Icons.search, size: 16),
            label: Text(
              'Tìm đường',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle, tag;
  final Color tagColor;
  const _WarningCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(color: iconColor.withOpacity(0.08), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: iconColor.withOpacity(0.4)),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tagColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: tagColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: tagColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteBar extends StatelessWidget {
  final String destination;
  final String routeHint;
  final IconData directionIcon;

  const _RouteBar({
    required this.destination,
    required this.routeHint,
    required this.directionIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryContainer.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(directionIcon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đến: $destination',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  routeHint,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.primary, size: 22),
        ],
      ),
    );
  }
}
