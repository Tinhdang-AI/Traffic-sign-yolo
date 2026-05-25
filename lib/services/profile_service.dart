import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  final SupabaseClient _supabase = Supabase.instance.client;

  factory ProfileService() {
    return _instance;
  }

  ProfileService._internal();

  /// Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('profiles')
          .select('is_admin')
          .eq('id', userId)
          .single();

      return response['is_admin'] as bool? ?? false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Get current user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  /// Create profile for new user
  Future<void> createProfile({
    required String userId,
    required String email,
    String? displayName,
  }) async {
    try {
      await _supabase.from('profiles').insert({
        'id': userId,
        'email': email,
        'display_name': displayName ?? email.split('@')[0],
        'is_admin': false,
      });
    } catch (e) {
      print('Error creating profile: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? avatarUrl,
    String? phone,
  }) async {
    try {
      await _supabase.from('profiles').update({
        if (displayName != null) 'display_name': displayName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (phone != null) 'phone': phone,
      }).eq('id', userId);
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  /// Set admin status (admin only)
  Future<void> setAdminStatus({
    required String userId,
    required bool isAdmin,
  }) async {
    try {
      final currentUserIsAdmin = await isCurrentUserAdmin();
      if (!currentUserIsAdmin) {
        throw Exception('Only admins can change admin status');
      }

      await _supabase
          .from('profiles')
          .update({'is_admin': isAdmin}).eq('id', userId);
    } catch (e) {
      print('Error setting admin status: $e');
      rethrow;
    }
  }

  /// Get all admin users
  Future<List<Map<String, dynamic>>> getAdminUsers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('is_admin', true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching admin users: $e');
      return [];
    }
  }

  /// Stream admin status changes
  Stream<bool> adminStatusStream() {
    return _supabase.auth.onAuthStateChange.asyncMap((_) async {
      return await isCurrentUserAdmin();
    });
  }
}
