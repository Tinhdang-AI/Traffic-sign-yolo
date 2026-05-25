import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../controllers/settings_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  int _step = 1; // 1: Request OTP, 2: Verify OTP & Reset
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _requestOTP() async {
    final isEn = context.read<SettingsProvider>().isEnglish;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEn ? 'Please enter email!' : 'Vui lòng nhập email!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEn ? 'OTP has been sent to your email!' : 'Mã xác nhận đã được gửi đến email của bạn!')),
        );
        setState(() {
          _step = 2;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${isEn ? 'Error' : 'Lỗi'}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyAndResetPassword() async {
    final isEn = context.read<SettingsProvider>().isEnglish;
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (otp.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEn ? 'Please fill all fields!' : 'Vui lòng điền đầy đủ thông tin!')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEn ? 'Passwords do not match!' : 'Mật khẩu xác nhận không khớp!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.verifyOTPAndResetPassword(email, otp, newPassword);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEn ? 'Password changed successfully! You can login.' : 'Đổi mật khẩu thành công! Bạn có thể đăng nhập.')),
        );
        Navigator.pop(context); // Trở về trang đăng nhập
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = '${isEn ? 'Error' : 'Lỗi'}: $e';
        if (e.toString().contains('Token has expired or is invalid')) {
          errorMsg = isEn ? 'OTP is incorrect or expired!' : 'Mã xác nhận không đúng hoặc đã hết hạn!';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<SettingsProvider>().isEnglish;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () {
            if (_step == 2) {
              setState(() => _step = 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              _buildFormCard(isEn),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryContainer.withOpacity(0.3)),
          ),
          child: const Icon(
            Icons.lock_reset,
            color: AppColors.primary,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'SENTINEL AI',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isEn) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04)),
      ),
      child: _step == 1 ? _buildStep1Form(isEn) : _buildStep2Form(isEn),
    );
  }

  Widget _buildStep1Form(bool isEn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEn ? 'Forgot password' : 'Quên mật khẩu',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isEn ? 'Enter your email to receive OTP' : 'Nhập email của bạn để nhận mã xác nhận (OTP)',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Email',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _emailController,
          hint: 'example@gmail.com',
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _requestOTP,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20, height: 20, 
                    child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2)
                  )
                : Text(
                    isEn ? 'GET OTP' : 'LẤY MÃ XÁC NHẬN',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.onPrimary,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Form(bool isEn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEn ? 'Reset password' : 'Đổi mật khẩu',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isEn ? 'Please enter OTP and new password' : 'Vui lòng nhập mã OTP vừa nhận và mật khẩu mới',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        
        _buildFieldLabel(isEn ? 'OTP Code' : 'Mã xác nhận (OTP)'),
        _buildTextField(
          controller: _otpController,
          hint: isEn ? '6-digit code' : 'Mã 6 chữ số',
          prefixIcon: Icons.pin_outlined,
        ),
        const SizedBox(height: 16),
        
        _buildFieldLabel(isEn ? 'New password' : 'Mật khẩu mới'),
        _buildTextField(
          controller: _newPasswordController,
          hint: '••••••••',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscureNewPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureNewPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _obscureNewPassword = !_obscureNewPassword;
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        
        _buildFieldLabel(isEn ? 'Confirm password' : 'Xác nhận mật khẩu'),
        _buildTextField(
          controller: _confirmPasswordController,
          hint: '••••••••',
          prefixIcon: Icons.verified_user_outlined,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
        ),
        const SizedBox(height: 32),
        
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyAndResetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20, height: 20, 
                    child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2)
                  )
                : Text(
                    isEn ? 'RESET PASSWORD' : 'ĐỔI MẬT KHẨU',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.onPrimary,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          prefixIcon: Icon(prefixIcon, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5), size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
