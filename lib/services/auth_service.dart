import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  User? get currentUser => _supabase.auth.currentUser;

  String? get accessToken => _supabase.auth.currentSession?.accessToken;

  Future<AuthResponse> signInWithEmailPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      debugPrint('SignIn Error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('SignIn Error: $e');
      rethrow;
    }
  }

  Future<AuthResponse> registerWithEmailPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      debugPrint('Register Error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Register Error: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfile({
    String? displayName,
    String? phoneNumber,
  }) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            if (displayName != null) 'display_name': displayName,
            if (phoneNumber != null) 'phone': phoneNumber,
          },
        ),
      );
    } catch (e) {
      debugPrint('Update Profile Error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Sign Out Error: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('Reset Password Error: $e');
      rethrow;
    }
  }

  Future<void> verifyOTPAndResetPassword(String email, String otp, String newPassword) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.recovery,
      );
      
      if (response.session != null) {
        await _supabase.auth.updateUser(
          UserAttributes(password: newPassword),
        );
      } else {
        throw const AuthException('Không thể tạo phiên khôi phục bảo mật. Vui lòng thử lại!');
      }
    } on AuthException catch (e) {
      debugPrint('Verify OTP Error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Verify OTP Error: $e');
      rethrow;
    }
  }
}
