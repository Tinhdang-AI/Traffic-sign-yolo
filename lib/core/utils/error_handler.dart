import 'dart:io';
import 'dart:async';

/// Retry policy for network requests with exponential backoff
class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
  });
}

/// Generic retry wrapper for async functions
Future<T> retryWithExponentialBackoff<T>(
  Future<T> Function() operation, {
  RetryConfig config = const RetryConfig(),
}) async {
  Duration delay = config.initialDelay;
  Exception? lastError;

  for (int attempt = 0; attempt < config.maxRetries; attempt++) {
    try {
      return await operation();
    } catch (e) {
      lastError = Exception('Attempt ${attempt + 1} failed: $e');

      if (attempt < config.maxRetries - 1) {
        // Exponential backoff delay before retry
        await Future.delayed(delay);

        // Calculate next delay with exponential backoff
        final nextDelay = (delay.inMilliseconds * config.backoffMultiplier)
            .toInt();
        delay = Duration(
          milliseconds: nextDelay.clamp(0, config.maxDelay.inMilliseconds),
        );
      }
    }
  }

  throw lastError ??
      Exception('Operation failed after ${config.maxRetries} attempts');
}

/// Error type for better error handling
enum ErrorType {
  network,
  timeout,
  notFound,
  unauthorized,
  serverError,
  unknown,
}

class AppException implements Exception {
  final String message;
  final ErrorType type;
  final dynamic originalError;

  AppException({required this.message, required this.type, this.originalError});

  @override
  String toString() => 'AppException[$type]: $message';

  String get userMessage {
    switch (type) {
      case ErrorType.network:
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra đường truyền.';
      case ErrorType.timeout:
        return 'Yêu cầu hết thời gian chờ. Vui lòng thử lại.';
      case ErrorType.notFound:
        return 'Không tìm thấy địa chỉ yêu cầu.';
      case ErrorType.unauthorized:
        return 'Bạn không có quyền truy cập.';
      case ErrorType.serverError:
        return 'Lỗi máy chủ. Vui lòng thử lại sau.';
      case ErrorType.unknown:
        return 'Đã xảy ra lỗi không xác định.';
    }
  }
}

/// Convert exception to AppException
AppException parseException(dynamic error) {
  if (error is AppException) return error;

  String message = error.toString();
  ErrorType type = ErrorType.unknown;

  if (error is TimeoutException) {
    type = ErrorType.timeout;
    message = 'Yêu cầu hết thời gian chờ';
  } else if (error is SocketException) {
    type = ErrorType.network;
    message = 'Lỗi kết nối mạng';
  } else if (error is FormatException) {
    type = ErrorType.unknown;
    message = 'Lỗi định dạng dữ liệu';
  } else if (message.contains('Connection refused')) {
    type = ErrorType.network;
    message = 'Kết nối bị từ chối';
  } else if (message.contains('404')) {
    type = ErrorType.notFound;
    message = 'Không tìm thấy';
  } else if (message.contains('401')) {
    type = ErrorType.unauthorized;
    message = 'Xác thực không thành công';
  } else if (message.contains('500')) {
    type = ErrorType.serverError;
    message = 'Lỗi máy chủ';
  }

  return AppException(message: message, type: type, originalError: error);
}
