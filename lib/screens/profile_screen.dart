import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traffic_detect/core/theme/app_colors.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'community_report_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(top),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  _buildProfileInfo(),
                  const SizedBox(height: 24),
                  _buildMenuSection([
                    _MenuItem(
                        icon: Icons.person_outline,
                        iconColor: AppColors.primary,
                        title: 'Thông tin cá nhân'),
                  ]),
                  const SizedBox(height: 12),
                  _buildMenuSection([
                    _MenuItem(
                        icon: Icons.notifications_active_outlined,
                        iconColor: AppColors.secondary,
                        title: 'Cài đặt thông báo'),
                    _MenuItem(
                        icon: Icons.campaign_outlined,
                        iconColor: AppColors.secondary,
                        title: 'Báo cáo sự cố',
                        subtitle: 'Cảnh báo tai nạn, ngập lụt, công trình...',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CommunityReportScreen()),
                          );
                        }),
                  ]),
                  const SizedBox(height: 12),
                  _buildMenuSection([
                    _MenuItem(
                        icon: Icons.help_outline,
                        iconColor: AppColors.onSurfaceVariant,
                        title: 'Hỗ trợ'),
                  ]),
                  const SizedBox(height: 12),
                  _buildMenuSection([
                    _MenuItem(
                      icon: Icons.logout,
                      iconColor: AppColors.error,
                      title: 'Đăng xuất',
                      titleColor: AppColors.error,
                      hideArrow: true,
                      onTap: () async {
                        await _authService.signOut();
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ]),
                  const SizedBox(height: 40),
                  _buildFooter(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double top) {
    return Container(
      padding: EdgeInsets.only(top: top + 12, left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(children: [
        const Icon(Icons.menu, color: AppColors.onSurfaceVariant, size: 24),
        const SizedBox(width: 16),
        Text(
          'SENTINEL AI',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: AppColors.onSurface,
          ),
        ),
        const Spacer(),
        const Icon(Icons.account_circle, color: AppColors.primary, size: 24),
      ]),
    );
  }

  Widget _buildProfileInfo() {
    final user = _authService.currentUser;
    final displayName = user?.email?.split('@').first ?? 'Người dùng Sentinel';
    final email = user?.email ?? 'Chưa cập nhật email';

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryContainer.withOpacity(0.6), width: 2),
                boxShadow: [
                  BoxShadow(color: AppColors.primaryContainer.withOpacity(0.15), blurRadius: 20)
                ],
                image: const DecorationImage(
                  image: NetworkImage('https://i.pravatar.cc/150?img=11'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 3),
              ),
              child: const Icon(Icons.edit, size: 14, color: AppColors.onPrimary),
            )
          ],
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        // Text(
        //   '+84 901 234 567', // Static placeholder for phone
        //   style: GoogleFonts.inter(
        //     fontSize: 12,
        //     fontWeight: FontWeight.w500,
        //     color: AppColors.onSurfaceVariant,
        //   ),
        // ),
        // const SizedBox(height: 2),
        Text(
          email,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.onSurfaceVariant.withOpacity(0.6),
          ),
        ),
      ],
    );
  }


  Widget _buildMenuSection(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              return Column(
                children: [
                  entry.value,
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.white.withOpacity(0.04),
                      indent: 56,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Text(
            'SENTINEL AI v3.4.2',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hệ thống giám sát an toàn thông minh',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.onSurfaceVariant.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}


class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final bool hideArrow;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.hideArrow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? AppColors.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!hideArrow)
              Icon(Icons.chevron_right, size: 18, color: AppColors.onSurfaceVariant.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
