// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:traffic_detect/models/community_report.dart';
// import 'package:traffic_detect/services/community_service.dart';
// import '../theme/app_colors.dart';

// class CommunityReportScreen extends StatefulWidget {
//   const CommunityReportScreen({super.key});
//   @override
//   State<CommunityReportScreen> createState() => _CommunityReportScreenState();
// }

// class _CommunityReportScreenState extends State<CommunityReportScreen> {
//   int? _selectedType;
//   bool _submitted = false;
//   bool _isSubmitting = false;
//   String? _submitError;
//   bool _isLoadingReports = true;
//   List<CommunityReport> _reports = [];

//   late TextEditingController _descriptionController;
//   late CommunityService _communityService;

//   final _types = [
//     _IncidentType(
//       Icons.camera_alt_outlined,
//       'Radar tốc độ',
//       'speeding',
//       AppColors.secondaryContainer,
//     ),
//     _IncidentType(
//       Icons.car_crash_outlined,
//       'Tai nạn',
//       'accident',
//       AppColors.tertiaryContainer,
//     ),
//     _IncidentType(
//       Icons.warning_amber_outlined,
//       'Chướng ngại vật',
//       'obstacle',
//       AppColors.secondaryContainer,
//     ),
//     _IncidentType(
//       Icons.local_police_outlined,
//       'Cảnh sát',
//       'police',
//       AppColors.primaryContainer,
//     ),
//     _IncidentType(
//       Icons.construction_outlined,
//       'Công trình',
//       'construction',
//       AppColors.secondaryContainer,
//     ),
//     _IncidentType(
//       Icons.water_outlined,
//       'Ngập lụt',
//       'flooding',
//       AppColors.primaryContainer,
//     ),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _descriptionController = TextEditingController();
//     _communityService = CommunityService();
//     _loadReports();
//   }

//   @override
//   void dispose() {
//     _descriptionController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadReports() async {
//     setState(() => _isLoadingReports = true);
//     try {
//       final position = await Geolocator.getCurrentPosition(
//         locationSettings: const LocationSettings(
//           accuracy: LocationAccuracy.high,
//         ),
//       );
//       final reports = await _communityService.getNearbyReports(
//         position.latitude,
//         position.longitude,
//         radiusKm: 10.0,
//       );
//       setState(() => _reports = reports);
//     } catch (e) {
//       debugPrint('Error loading reports: $e');
//     } finally {
//       setState(() => _isLoadingReports = false);
//     }
//   }

//   Future<void> _submitReport() async {
//     if (_selectedType == null) return;

//     setState(() {
//       _isSubmitting = true;
//       _submitError = null;
//     });

//     try {
//       final position = await Geolocator.getCurrentPosition(
//         locationSettings: const LocationSettings(
//           accuracy: LocationAccuracy.high,
//         ),
//       );

//       final violationType = _types[_selectedType!].violationType;
//       final description = _descriptionController.text.trim();

//       await _communityService.createReport(
//         latitude: position.latitude,
//         longitude: position.longitude,
//         violationType: violationType,
//         description: description.isEmpty
//             ? 'No additional details'
//             : description,
//         reportedBy: 'local_${DateTime.now().millisecondsSinceEpoch}',
//         imageUrl: null,
//       );

//       setState(() {
//         _submitted = true;
//         _selectedType = null;
//         _descriptionController.clear();
//       });

//       // Reload reports after submission
//       Future.delayed(const Duration(seconds: 2), _loadReports);
//     } catch (e) {
//       setState(() => _submitError = 'Lỗi gửi báo cáo: ${e.toString()}');
//       debugPrint('Error submitting report: $e');
//     } finally {
//       setState(() => _isSubmitting = false);
//     }
//   }

//   Future<void> _upvoteReport(String reportId) async {
//     try {
//       await _communityService.upvoteReport(reportId);
//       // Reload reports to show updated upvotes
//       _loadReports();
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Lỗi upvote: $e')));
//       }
//       debugPrint('Error upvoting report: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final top = MediaQuery.of(context).padding.top;
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: Column(
//         children: [
//           _buildHeader(top),
//           Expanded(child: _submitted ? _buildSuccessView() : _buildForm()),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeader(double top) {
//     return Container(
//       padding: EdgeInsets.only(top: top + 8, left: 16, right: 16, bottom: 16),
//       decoration: BoxDecoration(
//         color: AppColors.surfaceContainer,
//         border: Border(
//           bottom: BorderSide(color: Colors.white.withOpacity(0.07)),
//         ),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.satellite_alt, color: AppColors.primary, size: 18),
//           const SizedBox(width: 8),
//           Text(
//             'SENTINEL AI',
//             style: GoogleFonts.inter(
//               fontSize: 12,
//               fontWeight: FontWeight.w700,
//               letterSpacing: 3.5,
//               color: AppColors.primary,
//             ),
//           ),
//           const Spacer(),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//             decoration: BoxDecoration(
//               color: AppColors.secondaryContainer.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Text(
//               'BÁO CÁO CỘNG ĐỒNG',
//               style: GoogleFonts.inter(
//                 fontSize: 8,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: 1.2,
//                 color: AppColors.secondary,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildForm() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Báo cáo sự cố',
//             style: GoogleFonts.inter(
//               fontSize: 22,
//               fontWeight: FontWeight.w700,
//               color: AppColors.onSurface,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'Cảnh báo người dùng Sentinel khác về nguy hiểm đường bộ.',
//             style: GoogleFonts.inter(
//               fontSize: 12,
//               color: AppColors.onSurfaceVariant.withOpacity(0.7),
//             ),
//           ),
//           const SizedBox(height: 20),

//           // Map snapshot
//           _MapSnapshot(),
//           const SizedBox(height: 20),

//           // Incident types
//           Text(
//             'Loại sự cố',
//             style: GoogleFonts.inter(
//               fontSize: 14,
//               fontWeight: FontWeight.w700,
//               color: AppColors.onSurface,
//             ),
//           ),
//           const SizedBox(height: 10),
//           GridView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 3,
//               mainAxisSpacing: 10,
//               crossAxisSpacing: 10,
//               childAspectRatio: 1.0,
//             ),
//             itemCount: _types.length,
//             itemBuilder: (_, i) => _IncidentTypeButton(
//               type: _types[i],
//               selected: _selectedType == i,
//               onTap: () => setState(() => _selectedType = i),
//             ),
//           ),
//           const SizedBox(height: 20),

//           // Description
//           Text(
//             'Mô tả thêm (tuỳ chọn)',
//             style: GoogleFonts.inter(
//               fontSize: 14,
//               fontWeight: FontWeight.w700,
//               color: AppColors.onSurface,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Container(
//             decoration: BoxDecoration(
//               color: AppColors.surfaceContainer,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: Colors.white.withOpacity(0.1)),
//             ),
//             child: TextField(
//               controller: _descriptionController,
//               maxLines: 3,
//               style: GoogleFonts.inter(
//                 fontSize: 13,
//                 color: AppColors.onSurface,
//               ),
//               decoration: InputDecoration(
//                 hintText: 'Mô tả ngắn về sự cố...',
//                 hintStyle: GoogleFonts.inter(
//                   fontSize: 13,
//                   color: AppColors.onSurfaceVariant.withOpacity(0.5),
//                 ),
//                 border: InputBorder.none,
//                 contentPadding: const EdgeInsets.all(14),
//               ),
//             ),
//           ),
//           const SizedBox(height: 8),

//           // Error message
//           if (_submitError != null)
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: AppColors.tertiaryContainer.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(
//                   color: AppColors.tertiaryContainer.withOpacity(0.5),
//                 ),
//               ),
//               child: Text(
//                 _submitError!,
//                 style: GoogleFonts.inter(
//                   fontSize: 12,
//                   color: AppColors.tertiaryContainer,
//                 ),
//               ),
//             ),
//           const SizedBox(height: 16),

//           // Submit button
//           SizedBox(
//             width: double.infinity,
//             height: 52,
//             child: ElevatedButton.icon(
//               onPressed: _selectedType != null && !_isSubmitting
//                   ? _submitReport
//                   : null,
//               icon: _isSubmitting
//                   ? SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor: AlwaysStoppedAnimation<Color>(
//                           _selectedType != null
//                               ? Colors.white
//                               : AppColors.onSurfaceVariant.withOpacity(0.4),
//                         ),
//                       ),
//                     )
//                   : const Icon(Icons.emergency_share, size: 20),
//               label: Text(
//                 _isSubmitting ? 'Đang gửi...' : 'Gửi cảnh báo',
//                 style: GoogleFonts.inter(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.secondaryContainer,
//                 foregroundColor: Colors.white,
//                 disabledBackgroundColor: AppColors.surfaceContainerHigh,
//                 disabledForegroundColor: AppColors.onSurfaceVariant.withOpacity(
//                   0.4,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),

//           // Community feed
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Cảnh báo cộng đồng gần đây',
//                 style: GoogleFonts.inter(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.onSurface,
//                 ),
//               ),
//               if (!_isLoadingReports)
//                 GestureDetector(
//                   onTap: _loadReports,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: AppColors.primaryContainer.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Icon(
//                       Icons.refresh,
//                       size: 16,
//                       color: AppColors.primary,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//           const SizedBox(height: 10),

//           if (_isLoadingReports)
//             Center(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 24),
//                 child: CircularProgressIndicator(
//                   valueColor: AlwaysStoppedAnimation<Color>(
//                     AppColors.primary.withOpacity(0.6),
//                   ),
//                 ),
//               ),
//             )
//           else if (_reports.isEmpty)
//             Center(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 24),
//                 child: Text(
//                   'Chưa có báo cáo nào gần đây',
//                   style: GoogleFonts.inter(
//                     fontSize: 13,
//                     color: AppColors.onSurfaceVariant.withOpacity(0.6),
//                   ),
//                 ),
//               ),
//             )
//           else
//             Column(
//               children: _reports.take(3).map((report) {
//                 return Column(
//                   children: [
//                     _CommunityFeedItem(
//                       report: report,
//                       onUpvote: () => _upvoteReport(report.id),
//                     ),
//                     const SizedBox(height: 8),
//                   ],
//                 );
//               }).toList(),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSuccessView() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 80,
//               height: 80,
//               decoration: BoxDecoration(
//                 color: const Color(0xFF4CAF50).withOpacity(0.15),
//                 shape: BoxShape.circle,
//                 border: Border.all(
//                   color: const Color(0xFF4CAF50).withOpacity(0.5),
//                 ),
//               ),
//               child: const Icon(
//                 Icons.check_rounded,
//                 color: Color(0xFF4CAF50),
//                 size: 40,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'Cảnh báo đã được gửi!',
//               style: GoogleFonts.inter(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w700,
//                 color: AppColors.onSurface,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Cảm ơn bạn đã đóng góp cho cộng đồng SENTINEL AI. Người dùng trong khu vực đã được thông báo.',
//               textAlign: TextAlign.center,
//               style: GoogleFonts.inter(
//                 fontSize: 13,
//                 color: AppColors.onSurfaceVariant.withOpacity(0.7),
//                 height: 1.6,
//               ),
//             ),
//             const SizedBox(height: 28),
//             TextButton(
//               onPressed: () => setState(() {
//                 _submitted = false;
//                 _selectedType = null;
//                 _loadReports();
//               }),
//               child: Text(
//                 'Báo cáo khác',
//                 style: GoogleFonts.inter(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.primary,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _IncidentType {
//   final IconData icon;
//   final String label;
//   final String violationType;
//   final Color color;
//   const _IncidentType(this.icon, this.label, this.violationType, this.color);
// }

// class _IncidentTypeButton extends StatelessWidget {
//   final _IncidentType type;
//   final bool selected;
//   final VoidCallback onTap;
//   const _IncidentTypeButton({
//     required this.type,
//     required this.selected,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         decoration: BoxDecoration(
//           color: selected
//               ? type.color.withOpacity(0.2)
//               : AppColors.surfaceContainer,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(
//             color: selected ? type.color : Colors.white.withOpacity(0.08),
//             width: selected ? 1.5 : 1,
//           ),
//           boxShadow: selected
//               ? [BoxShadow(color: type.color.withOpacity(0.3), blurRadius: 12)]
//               : null,
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               type.icon,
//               color: selected
//                   ? type.color
//                   : AppColors.onSurfaceVariant.withOpacity(0.6),
//               size: 26,
//             ),
//             const SizedBox(height: 6),
//             Text(
//               type.label,
//               textAlign: TextAlign.center,
//               style: GoogleFonts.inter(
//                 fontSize: 10,
//                 fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
//                 color: selected
//                     ? type.color
//                     : AppColors.onSurfaceVariant.withOpacity(0.7),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _MapSnapshot extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 150,
//       decoration: BoxDecoration(
//         color: const Color(0xFF0D1520),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.white.withOpacity(0.08)),
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(16),
//         child: Stack(
//           children: [
//             SizedBox.expand(child: CustomPaint(painter: _MiniMapPainter())),
//             Center(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     width: 28,
//                     height: 28,
//                     decoration: BoxDecoration(
//                       color: AppColors.secondaryContainer,
//                       shape: BoxShape.circle,
//                       boxShadow: [
//                         BoxShadow(
//                           color: AppColors.secondaryContainer.withOpacity(0.6),
//                           blurRadius: 12,
//                         ),
//                       ],
//                     ),
//                     child: const Icon(
//                       Icons.location_on,
//                       color: Colors.white,
//                       size: 16,
//                     ),
//                   ),
//                   Container(
//                     width: 2,
//                     height: 6,
//                     color: AppColors.secondaryContainer,
//                   ),
//                 ],
//               ),
//             ),
//             Positioned(
//               bottom: 8,
//               left: 8,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: AppColors.surfaceContainer.withOpacity(0.9),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(
//                       Icons.my_location,
//                       color: AppColors.secondary,
//                       size: 12,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       'Vị trí hiện tại của bạn',
//                       style: GoogleFonts.inter(
//                         fontSize: 10,
//                         fontWeight: FontWeight.w600,
//                         color: AppColors.onSurface,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _MiniMapPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size s) {
//     canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF0D1520));
//     final gridP = Paint()
//       ..color = const Color(0xFF1A2535)
//       ..strokeWidth = 0.8;
//     for (double x = 0; x < s.width; x += 24) {
//       canvas.drawLine(Offset(x, 0), Offset(x, s.height), gridP);
//     }
//     for (double y = 0; y < s.height; y += 24) {
//       canvas.drawLine(Offset(0, y), Offset(s.width, y), gridP);
//     }
//     final rp = Paint()
//       ..color = const Color(0xFF243040)
//       ..strokeWidth = 10
//       ..strokeCap = StrokeCap.round;
//     canvas.drawLine(
//       Offset(0, s.height * 0.5),
//       Offset(s.width, s.height * 0.5),
//       rp,
//     );
//     canvas.drawLine(
//       Offset(s.width * 0.5, 0),
//       Offset(s.width * 0.5, s.height),
//       rp,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter _) => false;
// }

// class _CommunityFeedItem extends StatefulWidget {
//   final CommunityReport report;
//   final VoidCallback onUpvote;

//   const _CommunityFeedItem({required this.report, required this.onUpvote});

//   @override
//   State<_CommunityFeedItem> createState() => _CommunityFeedItemState();
// }

// class _CommunityFeedItemState extends State<_CommunityFeedItem> {
//   bool? _voted;

//   final _iconMap = {
//     'speeding': Icons.camera_alt,
//     'accident': Icons.car_crash,
//     'obstacle': Icons.warning_amber,
//     'police': Icons.local_police,
//     'construction': Icons.construction,
//     'flooding': Icons.water,
//   };

//   final _colorMap = {
//     'speeding': AppColors.secondaryContainer,
//     'accident': AppColors.tertiaryContainer,
//     'obstacle': AppColors.secondaryContainer,
//     'police': AppColors.primaryContainer,
//     'construction': AppColors.secondaryContainer,
//     'flooding': AppColors.primaryContainer,
//   };

//   final _labelMap = {
//     'speeding': 'Radar tốc độ',
//     'accident': 'Tai nạn',
//     'obstacle': 'Chướng ngại vật',
//     'police': 'Cảnh sát',
//     'construction': 'Công trình',
//     'flooding': 'Ngập lụt',
//   };

//   @override
//   Widget build(BuildContext context) {
//     final icon = _iconMap[widget.report.violationType] ?? Icons.warning;
//     final color = _colorMap[widget.report.violationType] ?? AppColors.primary;
//     final label =
//         _labelMap[widget.report.violationType] ?? widget.report.violationType;
//     final timeAgo = _getTimeAgo(widget.report.timestamp);

//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: AppColors.surfaceContainer,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: Colors.white.withOpacity(0.05)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 38,
//                 height: 38,
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.15),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(icon, color: color, size: 20),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       label,
//                       style: GoogleFonts.inter(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w700,
//                         color: AppColors.onSurface,
//                       ),
//                     ),
//                     Text(
//                       '$timeAgo · ${widget.report.upvotes} người xác nhận',
//                       style: GoogleFonts.inter(
//                         fontSize: 10,
//                         color: AppColors.onSurfaceVariant.withOpacity(0.6),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: AppColors.surfaceContainerHigh,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(
//                       Icons.thumb_up_outlined,
//                       size: 12,
//                       color: AppColors.primary,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       '${widget.report.upvotes}',
//                       style: GoogleFonts.inter(
//                         fontSize: 11,
//                         fontWeight: FontWeight.w700,
//                         color: AppColors.primary,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 10),
//           if (widget.report.description.isNotEmpty)
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   widget.report.description,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: GoogleFonts.inter(
//                     fontSize: 11,
//                     color: AppColors.onSurfaceVariant.withOpacity(0.8),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//               ],
//             ),
//           Text(
//             'Báo cáo này có chính xác không?',
//             style: GoogleFonts.inter(
//               fontSize: 11,
//               color: AppColors.onSurfaceVariant.withOpacity(0.7),
//             ),
//           ),
//           const SizedBox(height: 6),
//           Row(
//             children: [
//               _VoteButton(
//                 label: '✓ Đúng',
//                 active: _voted == true,
//                 activeColor: const Color(0xFF4CAF50),
//                 onTap: () {
//                   setState(() => _voted = true);
//                   widget.onUpvote();
//                 },
//               ),
//               const SizedBox(width: 8),
//               _VoteButton(
//                 label: '✗ Sai',
//                 active: _voted == false,
//                 activeColor: AppColors.tertiaryContainer,
//                 onTap: () => setState(() => _voted = false),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   String _getTimeAgo(DateTime dateTime) {
//     final now = DateTime.now();
//     final diff = now.difference(dateTime);

//     if (diff.inSeconds < 60) return 'vừa xong';
//     if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
//     if (diff.inHours < 24) return '${diff.inHours} giờ trước';
//     if (diff.inDays < 7) return '${diff.inDays} ngày trước';
//     return '${(diff.inDays / 7).floor()} tuần trước';
//   }
// }

// class _VoteButton extends StatelessWidget {
//   final String label;
//   final bool active;
//   final Color activeColor;
//   final VoidCallback onTap;
//   const _VoteButton({
//     required this.label,
//     required this.active,
//     required this.activeColor,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 180),
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
//         decoration: BoxDecoration(
//           color: active
//               ? activeColor.withOpacity(0.2)
//               : AppColors.surfaceContainerHigh,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(
//             color: active ? activeColor : Colors.white.withOpacity(0.1),
//           ),
//         ),
//         child: Text(
//           label,
//           style: GoogleFonts.inter(
//             fontSize: 11,
//             fontWeight: FontWeight.w700,
//             color: active
//                 ? activeColor
//                 : AppColors.onSurfaceVariant.withOpacity(0.6),
//           ),
//         ),
//       ),
//     );
//   }
// }
