import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:traffic_detect/models/community_report.dart';
import 'package:traffic_detect/services/community_service.dart';
import 'package:traffic_detect/services/location_service.dart';
import 'package:traffic_detect/core/theme/app_colors.dart';

class CommunityReportScreen extends StatefulWidget {
  const CommunityReportScreen({super.key});
  @override
  State<CommunityReportScreen> createState() => _CommunityReportScreenState();
}

class _CommunityReportScreenState extends State<CommunityReportScreen> {
  int? _selectedType;
  bool _submitted = false;
  bool _isSubmitting = false;
  String? _submitError;
  bool _isLoadingReports = true;
  List<CommunityReport> _reports = [];

  late TextEditingController _descriptionController;
  late CommunityService _communityService;

  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  final _types = [
    _IncidentType(
      Icons.camera_alt_outlined,
      'Radar tốc độ',
      'speeding',
      AppColors.secondaryContainer,
    ),
    _IncidentType(
      Icons.car_crash_outlined,
      'Tai nạn',
      'accident',
      AppColors.tertiaryContainer,
    ),
    _IncidentType(
      Icons.warning_amber_outlined,
      'Chướng ngại vật',
      'obstacle',
      AppColors.secondaryContainer,
    ),
    _IncidentType(
      Icons.local_police_outlined,
      'Cảnh sát',
      'police',
      AppColors.primaryContainer,
    ),
    _IncidentType(
      Icons.construction_outlined,
      'Công trình',
      'construction',
      AppColors.secondaryContainer,
    ),
    _IncidentType(
      Icons.water_outlined,
      'Ngập lụt',
      'flooding',
      AppColors.primaryContainer,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _communityService = CommunityService();
    _loadReports();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoadingReports = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final reports = await _communityService.getNearbyReports(
        position.latitude,
        position.longitude,
        radiusKm: 10.0,
      );
      setState(() => _reports = reports);
    } catch (e) {
      debugPrint('Error loading reports: $e');
    } finally {
      setState(() => _isLoadingReports = false);
    }
  }

  Future<void> _submitReport() async {
    if (_selectedType == null) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final violationType = _types[_selectedType!].violationType;
      final description = _descriptionController.text.trim();

      await _communityService.createReport(
        latitude: position.latitude,
        longitude: position.longitude,
        violationType: violationType,
        description: description.isEmpty
            ? 'No additional details'
            : description,
        reportedBy: 'local_${DateTime.now().millisecondsSinceEpoch}',
        imageUrl: _image?.path,
        name: '',
      );

      setState(() {
        _submitted = true;
        _selectedType = null;
        _image = null;
        _descriptionController.clear();
      });

      // Reload reports after submission
      Future.delayed(const Duration(seconds: 2), _loadReports);
    } catch (e) {
      setState(() => _submitError = 'Lỗi gửi báo cáo: ${e.toString()}');
      debugPrint('Error submitting report: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _upvoteReport(String reportId) async {
    try {
      await _communityService.upvoteReport(reportId);
      // Reload reports to show updated upvotes
      _loadReports();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi upvote: $e')));
      }
      debugPrint('Error upvoting report: $e');
    }
  }

  Future<void> _callEditReport({
    required String id,
    required String violationType,
    required String description,
    String? imageUrl,
    required bool reVerify,
  }) async {
    final service = _communityService as dynamic;
    final methods = ['editReport', 'updateReport'];

    for (final method in methods) {
      try {
        await Function.apply(
          service
              .noSuchMethod(Invocation.method(Symbol(method), const [], const {})),
          const [],
          {
            #id: id,
            #violationType: violationType,
            #description: description,
            #imageUrl: imageUrl,
            #reVerify: reVerify,
          },
        );
        return;
      } catch (_) {
        // Try next fallback method
      }
    }

    // Direct dynamic invocation fallback for typical service APIs
    try {
      await service.updateReport(
        id: id,
        violationType: violationType,
        description: description,
        imageUrl: imageUrl,
        reVerify: reVerify,
      );
      return;
    } catch (_) {}

    throw UnsupportedError('CommunityService does not support report editing');
  }

  void _editReport(CommunityReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditReportSheet(
        report: report,
        types: _types,
        onSave: (updatedType, updatedDesc, updatedImage) async {
          setState(() {
            _isLoadingReports = true;
          });
          try {
            await _callEditReport(
              id: report.id,
              violationType: updatedType,
              description: updatedDesc,
              imageUrl: updatedImage?.path,
              reVerify: updatedImage?.path != report.imageUrl,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cập nhật báo cáo thành công!'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            }
            _loadReports();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Lỗi cập nhật: $e'),
                  backgroundColor: AppColors.tertiaryContainer,
                ),
              );
            }
          } finally {
            if (mounted) {
              setState(() => _isLoadingReports = false);
            }
          }
        },
      ),
    );
  }

  void _confirmDeleteReport(String reportId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        title: Text(
          'Xóa báo cáo',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa báo cáo sự cố này không? Hành động này không thể hoàn tác.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: GoogleFonts.inter(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoadingReports = true);
              try {
                await _communityService.deleteReport(reportId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Xóa báo cáo thành công!'),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                }
                _loadReports();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khi xóa báo cáo: $e'),
                      backgroundColor: AppColors.tertiaryContainer,
                    ),
                  );
                }
                setState(() => _isLoadingReports = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tertiaryContainer,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Xóa',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(top),
          Expanded(child: _submitted ? _buildSuccessView() : _buildForm()),
        ],
      ),
    );
  }

  Widget _buildHeader(double top) {
    return Container(
      padding: EdgeInsets.only(top: top + 8, left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.satellite_alt, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            'SENTINEL AI',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 3.5,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'BÁO CÁO CỘNG ĐỒNG',
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Báo cáo sự cố',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cảnh báo người dùng Sentinel khác về nguy hiểm đường bộ.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),

          // Map snapshot
          _MapSnapshot(),
          const SizedBox(height: 20),

          // Incident types
          Text(
            'Loại sự cố',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: _types.length,
            itemBuilder: (_, i) => _IncidentTypeButton(
              type: _types[i],
              selected: _selectedType == i,
              onTap: () => setState(() => _selectedType = i),
            ),
          ),
          const SizedBox(height: 20),

          // Description
          Text(
            'Mô tả thêm (tuỳ chọn)',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text Field
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Mô tả ngắn về sự cố...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant.withOpacity(0.4),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  ),
                ),

                // Selected Image Preview
                if (_image != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _image!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _image = null),
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Divider separating content from action bar
                Divider(
                  color: Colors.white.withOpacity(0.06),
                  height: 1,
                  thickness: 1,
                ),

                // Bottom Action Row (Camera and Plus Gallery Upload)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      // Camera Button (Chụp ảnh)
                      IconButton(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.camera_alt_outlined, size: 20),
                        color: AppColors.primary,
                        tooltip: 'Chụp ảnh bằng Camera',
                        splashRadius: 20,
                      ),
                      // Plus Button (Tải ảnh lên từ Thư viện)
                      IconButton(
                        onPressed: _pickImageFromGallery,
                        icon: const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 20,
                        ),
                        color: AppColors.primary,
                        tooltip: 'Tải ảnh lên từ thư viện',
                        splashRadius: 20,
                      ),
                      const Spacer(),
                      if (_image != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.greenAccent.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.greenAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Đã đính kèm ảnh',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Error message
          if (_submitError != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.tertiaryContainer.withOpacity(0.5),
                ),
              ),
              child: Text(
                _submitError!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.tertiaryContainer,
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _selectedType != null && !_isSubmitting
                  ? _submitReport
                  : null,
              icon: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _selectedType != null
                              ? Colors.white
                              : AppColors.onSurfaceVariant.withOpacity(0.4),
                        ),
                      ),
                    )
                  : const Icon(Icons.emergency_share, size: 20),
              label: Text(
                _isSubmitting ? 'Đang gửi...' : 'Gửi cảnh báo',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryContainer,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.surfaceContainerHigh,
                disabledForegroundColor: AppColors.onSurfaceVariant.withOpacity(
                  0.4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Community feed
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cảnh báo cộng đồng gần đây',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              if (!_isLoadingReports)
                GestureDetector(
                  onTap: _loadReports,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.refresh,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (_isLoadingReports)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary.withOpacity(0.6),
                  ),
                ),
              ),
            )
          else if (_reports.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Chưa có báo cáo nào gần đây',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
              ),
            )
          else
            Column(
              children: _reports.map((report) {
                return Column(
                  children: [
                    _CommunityFeedItem(
                      report: report,
                      onUpvote: () => _upvoteReport(report.id),
                      onEdit: () => _editReport(report),
                      onDelete: () => _confirmDeleteReport(report.id),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.5),
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF4CAF50),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Cảnh báo đã được gửi!',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cảm ơn bạn đã đóng góp cho cộng đồng SENTINEL AI. Người dùng trong khu vực đã được thông báo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurfaceVariant.withOpacity(0.7),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            TextButton(
              onPressed: () => setState(() {
                _submitted = false;
                _selectedType = null;
                _loadReports();
              }),
              child: Text(
                'Báo cáo khác',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncidentType {
  final IconData icon;
  final String label;
  final String violationType;
  final Color color;
  const _IncidentType(this.icon, this.label, this.violationType, this.color);
}

class _IncidentTypeButton extends StatelessWidget {
  final _IncidentType type;
  final bool selected;
  final VoidCallback onTap;
  const _IncidentTypeButton({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected
              ? type.color.withOpacity(0.2)
              : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? type.color : Colors.white.withOpacity(0.08),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: type.color.withOpacity(0.3), blurRadius: 12)]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type.icon,
              color: selected
                  ? type.color
                  : AppColors.onSurfaceVariant.withOpacity(0.6),
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              type.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected
                    ? type.color
                    : AppColors.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapSnapshot extends StatefulWidget {
  const _MapSnapshot({super.key});

  @override
  State<_MapSnapshot> createState() => _MapSnapshotState();
}

class _MapSnapshotState extends State<_MapSnapshot> {
  Position? _currentPosition;
  bool _loadingLocation = true;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _loadingLocation = false;
          _markers.clear();
          _markers.add(
            Marker(
              markerId: const MarkerId('current_pos'),
              position: LatLng(position.latitude, position.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('Error getting location for minimap: $e');
      if (mounted) {
        setState(() {
          _loadingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            if (_loadingLocation)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            else if (_currentPosition == null)
              Center(
                child: Text(
                  'Không thể tải vị trí hiện tại',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                ),
              )
            else
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  zoom: 15.0,
                ),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                mapType: MapType.normal,
              ),
            // "Vị trí cảnh báo thực tế" Label Overlay
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.my_location,
                      color: AppColors.secondary,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Vị trí cảnh báo thực tế',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityFeedItem extends StatefulWidget {
  final CommunityReport report;
  final VoidCallback onUpvote;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CommunityFeedItem({
    required this.report,
    required this.onUpvote,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_CommunityFeedItem> createState() => _CommunityFeedItemState();
}

class _CommunityFeedItemState extends State<_CommunityFeedItem> {
  bool? _voted;
  String _locationAddress = 'Đang tải vị trí...';
  bool _isLoadingAddress = true;

  @override
  void initState() {
    super.initState();
    _resolveAddress();
  }

  Future<void> _resolveAddress() async {
    try {
      final address = await LocationService.instance.getAddressFromCoordinates(
        widget.report.latitude,
        widget.report.longitude,
      );
      if (mounted) {
        setState(() {
          _locationAddress = address;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationAddress =
              '${widget.report.latitude.toStringAsFixed(4)}, ${widget.report.longitude.toStringAsFixed(4)}';
          _isLoadingAddress = false;
        });
      }
    }
  }

  String _formatFullTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    final year = time.year.toString();
    return '$hour:$minute - $day/$month/$year';
  }

  final _iconMap = {
    'speeding': Icons.camera_alt,
    'accident': Icons.car_crash,
    'obstacle': Icons.warning_amber,
    'police': Icons.local_police,
    'construction': Icons.construction,
    'flooding': Icons.water,
  };

  final _colorMap = {
    'speeding': AppColors.secondaryContainer,
    'accident': AppColors.tertiaryContainer,
    'obstacle': AppColors.secondaryContainer,
    'police': AppColors.primaryContainer,
    'construction': AppColors.secondaryContainer,
    'flooding': AppColors.primaryContainer,
  };

  final _labelMap = {
    'speeding': 'Radar tốc độ',
    'accident': 'Tai nạn',
    'obstacle': 'Chướng ngại vật',
    'police': 'Cảnh sát',
    'construction': 'Công trình',
    'flooding': 'Ngập lụt',
  };

  @override
  Widget build(BuildContext context) {
    final icon = _iconMap[widget.report.violationType] ?? Icons.warning;
    final color = _colorMap[widget.report.violationType] ?? AppColors.primary;
    final label =
        _labelMap[widget.report.violationType] ?? widget.report.violationType;
    final timeAgo = _getTimeAgo(widget.report.timestamp);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$timeAgo · ${widget.report.upvotes} người xác nhận',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.thumb_up_outlined,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.report.upvotes}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: AppColors.onSurfaceVariant.withOpacity(0.6),
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: AppColors.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    widget.onEdit();
                  } else if (value == 'delete') {
                    widget.onDelete();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.edit_outlined,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sửa',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          color: AppColors.tertiaryContainer,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Xóa',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.tertiaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Time & Date Row
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 12,
                color: Colors.white38,
              ),
              const SizedBox(width: 6),
              Text(
                _formatFullTime(widget.report.timestamp),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Location Address Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 12,
                color: Colors.white38,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _locationAddress,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 1.35,
                    color: AppColors.onSurfaceVariant.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.report.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(widget.report.imageUrl!),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
          if (widget.report.description.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.report.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          if (widget.report.isVerified)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified,
                    color: Color(0xFF4CAF50),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Đã xác thực bởi AI',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Text(
              'Chờ cộng đồng xác minh',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _VoteButton(
                  label: '✓ Đúng',
                  active: _voted == true,
                  activeColor: const Color(0xFF4CAF50),
                  onTap: () {
                    setState(() => _voted = true);
                    widget.onUpvote();
                  },
                ),
                const SizedBox(width: 8),
                _VoteButton(
                  label: '✗ Sai',
                  active: _voted == false,
                  activeColor: AppColors.tertiaryContainer,
                  onTap: () => setState(() => _voted = false),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${(diff.inDays / 7).floor()} tuần trước';
  }
}

class _VoteButton extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;
  const _VoteButton({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withOpacity(0.2)
              : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? activeColor : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active
                ? activeColor
                : AppColors.onSurfaceVariant.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}

class _EditReportSheet extends StatefulWidget {
  final CommunityReport report;
  final List<_IncidentType> types;
  final Function(String type, String description, File? image) onSave;

  const _EditReportSheet({
    required this.report,
    required this.types,
    required this.onSave,
  });

  @override
  State<_EditReportSheet> createState() => _EditReportSheetState();
}

class _EditReportSheetState extends State<_EditReportSheet> {
  late String _selectedViolationType;
  late TextEditingController _descriptionController;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _imageRemoved = false;

  @override
  void initState() {
    super.initState();
    _selectedViolationType = widget.report.violationType;
    _descriptionController = TextEditingController(
      text: widget.report.description,
    );
    if (widget.report.imageUrl != null && widget.report.imageUrl!.isNotEmpty) {
      _image = File(widget.report.imageUrl!);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _imageRemoved = false;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _imageRemoved = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 20, 16, bottomInset + 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chỉnh sửa báo cáo',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Loại sự cố',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.types.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final type = widget.types[index];
                  final isSelected =
                      _selectedViolationType == type.violationType;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedViolationType = type.violationType;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 90,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? type.color.withOpacity(0.2)
                            : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? type.color
                              : Colors.white.withOpacity(0.06),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            type.icon,
                            color: isSelected
                                ? type.color
                                : AppColors.onSurfaceVariant.withOpacity(0.6),
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type.label,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isSelected
                                  ? type.color
                                  : AppColors.onSurfaceVariant.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Mô tả chi tiết',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nhập mô tả mới cho sự cố...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant.withOpacity(0.4),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  if (_image != null && !_imageRemoved)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _image!,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _imageRemoved = true;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Divider(color: Colors.white.withOpacity(0.05), height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          color: AppColors.primary,
                          tooltip: 'Chụp ảnh mới',
                        ),
                        IconButton(
                          onPressed: _pickImageFromGallery,
                          icon: const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 18,
                          ),
                          color: AppColors.primary,
                          tooltip: 'Tải ảnh mới từ thư viện',
                        ),
                        const Spacer(),
                        if (_image != null && !_imageRemoved)
                          Text(
                            'Đã chọn ảnh',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final finalImage = _imageRemoved ? null : _image;
                  widget.onSave(
                    _selectedViolationType,
                    _descriptionController.text.trim(),
                    finalImage,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Lưu thay đổi',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
