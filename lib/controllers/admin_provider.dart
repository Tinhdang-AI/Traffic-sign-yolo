import 'package:flutter/foundation.dart';
import '../services/profile_service.dart';

class AdminProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  bool _isAdmin = false;
  bool _isLoading = false;

  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;

  AdminProvider() {
    _checkAdminStatus();
    _listenToAdminChanges();
  }

  Future<void> _checkAdminStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isAdmin = await _profileService.isCurrentUserAdmin();
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      _isAdmin = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _listenToAdminChanges() {
    _profileService.adminStatusStream().listen((isAdmin) {
      _isAdmin = isAdmin;
      notifyListeners();
    });
  }

  /// Get current user profile
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    try {
      return await _profileService.getCurrentUserProfile();
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  /// Set user as admin (admin only)
  Future<void> makeUserAdmin(String userId) async {
    if (!_isAdmin) {
      throw Exception('Only admins can perform this action');
    }

    try {
      await _profileService.setAdminStatus(
        userId: userId,
        isAdmin: true,
      );
    } catch (e) {
      debugPrint('Error making user admin: $e');
      rethrow;
    }
  }

  /// Remove admin status from user (admin only)
  Future<void> removeAdminStatus(String userId) async {
    if (!_isAdmin) {
      throw Exception('Only admins can perform this action');
    }

    try {
      await _profileService.setAdminStatus(
        userId: userId,
        isAdmin: false,
      );
    } catch (e) {
      debugPrint('Error removing admin status: $e');
      rethrow;
    }
  }

  /// Get all admin users
  Future<List<Map<String, dynamic>>> getAdminUsers() async {
    try {
      return await _profileService.getAdminUsers();
    } catch (e) {
      debugPrint('Error fetching admins: $e');
      return [];
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
