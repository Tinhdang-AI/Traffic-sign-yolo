import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'ar_detection_screen.dart';
import 'stats_history_screen.dart';
import 'community_report_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ARDetectionScreen(),
    const StatsHistoryScreen(),
    const CommunityReportScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _SentinelBottomNav(
        currentIndex: _currentIndex,
        items: const [
          _NavItem(Icons.center_focus_weak_rounded, Icons.center_focus_strong_rounded, 'AR Scan'),
          _NavItem(Icons.history, Icons.history, 'History'),
          _NavItem(Icons.group_outlined, Icons.group, 'Community'),
          _NavItem(Icons.person_outline, Icons.person, 'Profile'),
        ],
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

class _SentinelBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _SentinelBottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer.withOpacity(0.90),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.52),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: items.asMap().entries.map((e) {
            final idx = e.key;
            final item = e.value;
            final active = currentIndex == idx;
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: () => onTap(idx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: active
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.primaryContainer.withOpacity(0.28),
                              AppColors.primaryContainer.withOpacity(0.12),
                            ],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active ? item.activeIcon : item.icon,
                        color: active
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant.withOpacity(0.58),
                        size: 21,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: active
                              ? AppColors.onSurface
                              : AppColors.onSurfaceVariant.withOpacity(0.66),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
