import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:traffic_detect/core/theme/app_colors.dart';
import '../services/auth_service.dart';
import '../controllers/settings_provider.dart';
import 'login_screen.dart';
import 'user_profile_screen.dart';
import 'support_screen.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isEn = settings.isEnglish;
        
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Column(
            children: [
              _buildHeader(top, colorScheme),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      _buildProfileInfo(colorScheme),
                      const SizedBox(height: 24),
                      _buildMenuSection([
                        _MenuItem(
                          icon: Icons.person_outline,
                          iconColor: colorScheme.primary,
                          title: isEn ? 'Personal Information' : 'Thông tin cá nhân',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                            );
                          },
                        ),
                      ], colorScheme),
                      const SizedBox(height: 12),
                      _buildMenuSection([
                        _MenuItem(
                          icon: Icons.dark_mode_outlined,
                          iconColor: colorScheme.secondary,
                          title: isEn ? 'Dark Mode' : 'Chế độ tối',
                          hideArrow: true,
                          trailing: Switch(
                            value: settings.darkMode,
                            onChanged: (val) => settings.toggleTheme(val),
                            activeColor: colorScheme.primary,
                          ),
                        ),
                        _MenuItem(
                          icon: Icons.language,
                          iconColor: Colors.green,
                          title: isEn ? 'Language: English' : 'Ngôn ngữ: Tiếng Việt',
                          hideArrow: true,
                          trailing: Switch(
                            value: settings.isEnglish,
                            onChanged: (val) => settings.toggleLanguage(val),
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.white54,
                          ),
                        ),
                      ], colorScheme),
                      const SizedBox(height: 12),
                      _buildMenuSection([
                        _MenuItem(
                          icon: Icons.help_outline,
                          iconColor: colorScheme.onSurfaceVariant,
                          title: isEn ? 'Support' : 'Hỗ trợ',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SupportScreen()),
                            );
                          },
                        ),
                      ], colorScheme),
                      const SizedBox(height: 12),
                      _buildMenuSection([
                        _MenuItem(
                          icon: Icons.logout,
                          iconColor: colorScheme.error,
                          title: isEn ? 'Logout' : 'Đăng xuất',
                          titleColor: colorScheme.error,
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
                      ], colorScheme),
                      const SizedBox(height: 40),
                      _buildFooter(colorScheme, isEn),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildHeader(double top, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.only(top: top + 12, left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: colorScheme.outline.withOpacity(0.1))),
      ),
      child: Row(children: [
        Icon(Icons.menu, color: colorScheme.onSurfaceVariant, size: 24),
        const SizedBox(width: 16),
        Text(
          'SENTINEL AI',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        Icon(Icons.account_circle, color: colorScheme.primary, size: 24),
      ]),
    );
  }

  Widget _buildProfileInfo(ColorScheme colorScheme) {
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
                border: Border.all(color: colorScheme.primaryContainer.withOpacity(0.6), width: 2),
                boxShadow: [
                  BoxShadow(color: colorScheme.primaryContainer.withOpacity(0.15), blurRadius: 20)
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
                color: colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 3),
              ),
              child: Icon(Icons.edit, size: 14, color: colorScheme.onPrimary),
            )
          ],
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(List<_MenuItem> items, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
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
                      color: colorScheme.outline.withOpacity(0.1),
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

  Widget _buildFooter(ColorScheme colorScheme, bool isEn) {
    return Center(
      child: Column(
        children: [
          Text(
            'SENTINEL AI v3.4.2',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isEn ? 'Smart Safety Monitoring System' : 'Hệ thống giám sát an toàn thông minh',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
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
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.hideArrow = false,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                      color: titleColor ?? colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (!hideArrow && trailing == null)
              Icon(Icons.chevron_right, size: 18, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
