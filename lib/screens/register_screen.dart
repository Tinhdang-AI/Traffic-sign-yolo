import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_colors.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import 'package:provider/provider.dart';
import '../controllers/settings_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    final isEn = context.read<SettingsProvider>().isEnglish;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEn ? 'Please agree to terms!' : 'Vui lòng đồng ý với các điều khoản!')),
      );
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEn ? 'Please fill all fields!' : 'Vui lòng điền đầy đủ thông tin!')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEn ? 'Passwords do not match!' : 'Mật khẩu xác nhận không khớp!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.registerWithEmailPassword(email, password);
      await _authService.updateUserProfile(displayName: name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEn ? 'Registration successful!' : 'Đăng ký thành công!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainShell()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        String errorMsg = isEn ? 'Registration failed!' : 'Đăng ký thất bại!';
        if (e.message.contains('already exists')) {
          errorMsg = isEn ? 'Email is already in use!' : 'Email đã được sử dụng!';
        } else if (e.message.contains('Password')) {
          errorMsg = isEn ? 'Password is not strong enough!' : 'Mật khẩu không đủ mạnh!';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<SettingsProvider>().isEnglish;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(isEn),
                    const SizedBox(height: 32),
                    _buildForm(isEn),
                    const SizedBox(height: 24),
                    _buildTermsCheckbox(isEn),
                    const SizedBox(height: 32),
                    _buildRegisterButton(isEn),
                    const Spacer(),
                    const SizedBox(height: 40),
                    _buildFooter(isEn),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEn) {
    return Column(
      children: [
        Text(
          'SENTINEL AI',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isEn ? 'Create an account' : 'Đăng ký tài khoản',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isEn ? 'New generation smart driving\nsupport system' : 'Hệ thống hỗ trợ lái xe thông minh thế\nhệ mới',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(bool isEn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(isEn ? 'Full name' : 'Họ và tên'),
        _buildTextField(
          controller: _nameController,
          hint: isEn ? 'Enter your full name' : 'Nhập họ và tên của bạn',
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: 20),
        
        _buildFieldLabel(isEn ? 'Email' : 'Email'),
        _buildTextField(
          controller: _emailController,
          hint: isEn ? 'example@sentinel.ai' : 'vidu@sentinel.ai',
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: 20),

        _buildFieldLabel(isEn ? 'Password' : 'Mật khẩu'),
        _buildTextField(
          controller: _passwordController,
          hint: '••••••••',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscurePassword,
        ),
        const SizedBox(height: 20),

        _buildFieldLabel(isEn ? 'Confirm' : 'Xác nhận'),
        _buildTextField(
          controller: _confirmPasswordController,
          hint: '••••••••',
          prefixIcon: Icons.verified_user_outlined,
          obscureText: _obscureConfirmPassword,
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
          fontWeight: FontWeight.w600,
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
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox(bool isEn) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreeToTerms,
            onChanged: (value) {
              setState(() {
                _agreeToTerms = value ?? false;
              });
            },
            activeColor: AppColors.primary,
            checkColor: AppColors.onPrimary,
            side: BorderSide(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              children: [
                TextSpan(text: isEn ? 'I agree to the ' : 'Tôi đồng ý với '),
                TextSpan(
                  text: isEn ? 'Terms of Service' : 'Điều khoản dịch vụ',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
                TextSpan(text: isEn ? ' and ' : ' và '),
                TextSpan(
                  text: isEn ? 'Privacy Policy' : 'Chính sách bảo mật',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
                TextSpan(text: isEn ? ' of Sentinel AI.' : ' của Sentinel AI.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton(bool isEn) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
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
                isEn ? 'REGISTER' : 'ĐĂNG KÝ',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.onPrimary,
                ),
              ),
      ),
    );
  }

  Widget _buildFooter(bool isEn) {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              children: [
                TextSpan(text: isEn ? 'Already have an account? ' : 'Đã có tài khoản? '),
                TextSpan(
                  text: isEn ? 'Login now' : 'Đăng nhập ngay',
                  style: TextStyle(
                    color: AppColors.primary, 
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
