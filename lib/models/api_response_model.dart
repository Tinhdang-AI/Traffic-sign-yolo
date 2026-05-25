// API Response Wrapper
class ApiResponseModel<T> {
  final T? data;
  final String? message;
  final bool success;
  final int? total;
  final int? statusCode;

  ApiResponseModel({
    this.data,
    this.message,
    required this.success,
    this.total,
    this.statusCode,
  });

  factory ApiResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponseModel(
      data: fromJsonT != null ? fromJsonT(json) : null,
      message: json['message'] as String?,
      success: json['success'] as bool? ?? false,
      total: json['total'] as int?,
      statusCode: json['statusCode'] as int?,
    );
  }
}

// Pagination Response
class PaginatedResponseModel<T> {
  final List<T> items;
  final int total;
  final int limit;
  final int offset;

  PaginatedResponseModel({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  int get pages => (total / limit).ceil();
  int get currentPage => (offset / limit).toInt() + 1;
  bool get hasMore => offset + items.length < total;
}

// Upload Response
class UploadResponseModel {
  final String url;
  final String path;

  UploadResponseModel({
    required this.url,
    required this.path,
  });

  factory UploadResponseModel.fromJson(Map<String, dynamic> json) {
    return UploadResponseModel(
      url: json['url'] as String,
      path: json['path'] as String,
    );
  }
}

// Admin Dashboard Stats
class AdminDashboardModel {
  final int totalUsers;
  final int totalReports;
  final int verifiedReports;
  final int pendingReports;
  final int rejectedReports;
  final int totalDetections;
  final List<int> weeklyReportTrend;
  final Map<String, int> violationTypeBreakdown;

  AdminDashboardModel({
    required this.totalUsers,
    required this.totalReports,
    required this.verifiedReports,
    required this.pendingReports,
    required this.rejectedReports,
    required this.totalDetections,
    required this.weeklyReportTrend,
    required this.violationTypeBreakdown,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      totalUsers: json['totalUsers'] as int,
      totalReports: json['totalReports'] as int,
      verifiedReports: json['verifiedReports'] as int,
      pendingReports: json['pendingReports'] as int,
      rejectedReports: json['rejectedReports'] as int,
      totalDetections: json['totalDetections'] as int,
      weeklyReportTrend: List<int>.from(json['weeklyReportTrend'] as List),
      violationTypeBreakdown: Map<String, int>.from(
        json['violationTypeBreakdown'] as Map<String, dynamic>,
      ),
    );
  }
}
