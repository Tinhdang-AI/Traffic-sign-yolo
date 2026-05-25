import 'package:permission_handler/permission_handler.dart' as ph;

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Check if microphone permission is granted
  Future<bool> isMicrophoneGranted() async {
    final status = await ph.Permission.microphone.status;
    return status.isGranted;
  }

  /// Request microphone permission. Returns true if granted.
  Future<bool> requestMicrophonePermission() async {
    final status = await ph.Permission.microphone.request();
    return status.isGranted;
  }

  /// Request microphone and return the full status
  Future<ph.PermissionStatus> requestMicrophoneStatus() async {
    return await ph.Permission.microphone.request();
  }

  /// Open app settings for manual permission grant
  Future<bool> openAppSettings() async {
    return await ph.openAppSettings();
  }
}
