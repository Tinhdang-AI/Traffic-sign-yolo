import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'ar_detection_screen.dart';
import 'stats_history_screen.dart';
import 'community_report_screen.dart';
import 'profile_screen.dart';
import 'map_sos_screen.dart';

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
    const MapScreen(),
    const CommunityReportScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _SentinelBottomNav(
        currentIndex: _currentIndex,
        items: const [
          _NavItem(Icons.center_focus_weak_rounded, Icons.center_focus_strong_rounded, 'AR Scan'),
          _NavItem(Icons.history, Icons.history, 'History'),
          _NavItem(Icons.map_rounded, Icons.map_rounded, 'Map'), // placeholder
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
      minimum: const EdgeInsets.fromLTRB(10, 0, 10, 12),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withOpacity(0.90),
              borderRadius: BorderRadius.circular(24),
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
                
                if (idx == 2) {
                  return const Expanded(child: SizedBox.shrink());
                }

                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
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
                        borderRadius: BorderRadius.circular(16),
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
                          const SizedBox(height: 4),
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
          Positioned(
            top: -24,
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: currentIndex == 2
                        ? [AppColors.secondary, AppColors.secondaryContainer]
                        : [AppColors.primary, AppColors.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (currentIndex == 2 ? AppColors.secondaryContainer : AppColors.primaryContainer).withOpacity(0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: AppColors.background, width: 4),
                ),
                child: Center(
                  child: Icon(
                    Icons.map_rounded,
                    size: 28,
                    color: currentIndex == 2 ? AppColors.onSecondary : AppColors.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
