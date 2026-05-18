import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  static const List<_DashboardTab> _tabs = [
    _DashboardTab(Icons.dashboard_outlined, Icons.dashboard, 'Tổng quan'),
    _DashboardTab(Icons.emergency_outlined, Icons.emergency, 'SOS khẩn cấp'),
    _DashboardTab(Icons.people_outline, Icons.people, 'Người dùng'),
    _DashboardTab(Icons.report_outlined, Icons.report, 'Báo cáo'),
    _DashboardTab(Icons.smart_toy_outlined, Icons.smart_toy, 'AI model'),
    _DashboardTab(Icons.receipt_long_outlined, Icons.receipt_long, 'Nhật ký'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1100;

          if (isWide) {
            return Row(
              children: [
                _DashboardSidebar(
                  tabs: _tabs,
                  selectedIndex: _selectedIndex,
                  onTap: (index) => setState(() => _selectedIndex = index),
                ),
                Expanded(
                  child: _DashboardContent(
                    title: _tabs[_selectedIndex].label,
                    child: _dashboardBody(context),
                  ),
                ),
              ],
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(_tabs[_selectedIndex].label),
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_outlined),
                ),
              ],
            ),
            drawer: Drawer(
              backgroundColor: AppColors.surfaceContainer,
              child: SafeArea(
                child: _DashboardSidebar(
                  tabs: _tabs,
                  selectedIndex: _selectedIndex,
                  onTap: (index) {
                    setState(() => _selectedIndex = index);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
            body: _dashboardBody(context),
          );
        },
      ),
    );
  }

  Widget _dashboardBody(BuildContext context) {
    switch (_selectedIndex) {
      case 0:
        return const _OverviewTab();
      case 1:
        return const _EmergencyTab();
      case 2:
        return const _UsersTab();
      case 3:
        return const _ReportsTab();
      case 4:
        return const _ModelTab();
      case 5:
        return const _LogsTab();
      default:
        return const _OverviewTab();
    }
  }
}

class _DashboardSidebar extends StatelessWidget {
  final List<_DashboardTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _DashboardSidebar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 288,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryContainer, AppColors.secondaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  'SENTINEL ADMIN',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bản quản trị web tối giản để theo dõi app.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withOpacity(0.18)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_tethering, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Chế độ preview nội bộ',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final selected = index == selectedIndex;
                return _SidebarItem(
                  icon: selected ? tab.activeIcon : tab.icon,
                  label: tab.label,
                  selected: selected,
                  onTap: () => onTap(index),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: tabs.length,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trạng thái hệ thống',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _StatusRow(label: 'API', value: 'Chưa kết nối', color: AppColors.secondary),
                  const SizedBox(height: 8),
                  _StatusRow(label: 'Realtime', value: 'Mock data', color: AppColors.primary),
                  const SizedBox(height: 8),
                  _StatusRow(label: 'Model', value: 'v1.0.0', color: AppColors.tertiary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryContainer.withOpacity(0.18) : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: selected ? AppColors.primary : AppColors.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.onSurface : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final String title;
  final Widget child;

  const _DashboardContent({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF111214), Color(0xFF171A1F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Các dữ liệu hiện đang là mock để bạn dựng giao diện trước.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _ActionChip(
                  icon: Icons.refresh,
                  label: 'Làm mới',
                  onTap: () {},
                ),
                const SizedBox(width: 12),
                _ActionChip(
                  icon: Icons.file_upload_outlined,
                  label: 'Xuất báo cáo',
                  onTap: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _MetricCard(title: 'Người dùng', value: '1.284', subtitle: '+12 hôm nay', icon: Icons.people_outline, accent: AppColors.primaryContainer),
              _MetricCard(title: 'SOS hôm nay', value: '18', subtitle: '4 cần xử lý gấp', icon: Icons.emergency_outlined, accent: AppColors.tertiaryContainer),
              _MetricCard(title: 'Báo cáo chờ duyệt', value: '42', subtitle: '10 báo cáo mới', icon: Icons.report_outlined, accent: AppColors.secondaryContainer),
              _MetricCard(title: 'Model active', value: 'v1.0.0', subtitle: 'TFLite YOLO', icon: Icons.smart_toy_outlined, accent: AppColors.primaryContainer),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 1000;
              final chartWidth = twoColumns ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(width: chartWidth, child: const _PanelCard(title: 'Hoạt động gần đây', child: _ActivityList())),
                  SizedBox(width: chartWidth, child: const _PanelCard(title: 'Khu vực rủi ro', child: _RiskMapPlaceholder())),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmergencyTab extends StatelessWidget {
  const _EmergencyTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        _PanelCard(
          title: 'SOS khẩn cấp',
          child: Column(
            children: [
              _EmergencyItem(name: 'Nguyễn Văn A', note: 'Va chạm nhẹ tại Q.1', time: '2 phút trước', level: 'Cao'),
              SizedBox(height: 12),
              _EmergencyItem(name: 'Trần Thị B', note: 'Không xác định vị trí', time: '7 phút trước', level: 'Trung bình'),
              SizedBox(height: 12),
              _EmergencyItem(name: 'Lê Văn C', note: 'Yêu cầu hỗ trợ dẫn đường', time: '15 phút trước', level: 'Thấp'),
            ],
          ),
        ),
      ],
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        _PanelCard(
          title: 'Người dùng',
          child: _UsersTable(),
        ),
      ],
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        _PanelCard(
          title: 'Báo cáo cần xử lý',
          child: Column(
            children: [
              _ReportItem(title: 'Biển báo che khuất', status: 'Chờ duyệt', reporter: 'user_1024'),
              SizedBox(height: 12),
              _ReportItem(title: 'Sai vị trí biển cấm rẽ trái', status: 'Đang xử lý', reporter: 'user_1542'),
              SizedBox(height: 12),
              _ReportItem(title: 'Khu vực có nguy cơ tai nạn', status: 'Mới', reporter: 'user_8891'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModelTab extends StatelessWidget {
  const _ModelTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        _PanelCard(
          title: 'AI model',
          child: Column(
            children: [
              _ModelItem(version: 'v1.0.0', status: 'Đang chạy', note: 'best.tflite | YOLOv8-like | 640x640'),
              SizedBox(height: 12),
              _ModelItem(version: 'v1.1.0', status: 'Staging', note: 'Đang chờ test nội bộ'),
              SizedBox(height: 12),
              _ModelItem(version: 'v0.9.2', status: 'Lưu trữ', note: 'Bản cũ để rollback nhanh'),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogsTab extends StatelessWidget {
  const _LogsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        _PanelCard(
          title: 'Nhật ký hệ thống',
          child: _LogsList(),
        ),
      ],
    );
  }
}

class _PanelCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _PanelCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                'Mock data',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('07:45', 'Người dùng mới đăng ký', Icons.person_add_alt_1_outlined),
      ('08:10', 'Có 4 SOS được tạo', Icons.emergency_outlined),
      ('08:42', 'Model đánh dấu 12 biển báo', Icons.smart_toy_outlined),
      ('09:01', 'Có 6 báo cáo chờ duyệt', Icons.report_outlined),
    ];

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _TimelineRow(time: item.$1, label: item.$2, icon: item.$3),
            ),
          )
          .toList(),
    );
  }
}

class _RiskMapPlaceholder extends StatelessWidget {
  const _RiskMapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [AppColors.primaryContainer.withOpacity(0.24), AppColors.tertiaryContainer.withOpacity(0.18)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, color: AppColors.primary, size: 54),
            const SizedBox(height: 12),
            Text(
              'Bản đồ rủi ro sẽ gắn dữ liệu sau',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Hiển thị hotspot, số lượt cảnh báo và khu vực SOS.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String time;
  final String label;
  final IconData icon;

  const _TimelineRow({required this.time, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            time,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 3),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withOpacity(0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: AppColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmergencyItem extends StatelessWidget {
  final String name;
  final String note;
  final String time;
  final String level;

  const _EmergencyItem({
    required this.name,
    required this.note,
    required this.time,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.tertiaryContainer.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.emergency_outlined, color: AppColors.tertiary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  note,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _SeverityChip(label: level),
              const SizedBox(height: 8),
              Text(
                time,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final String label;

  const _SeverityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.tertiaryContainer.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.tertiary,
        ),
      ),
    );
  }
}

class _UsersTable extends StatelessWidget {
  const _UsersTable();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Người dùng')),
          DataColumn(label: Text('Vai trò')),
          DataColumn(label: Text('Trạng thái')),
          DataColumn(label: Text('Thiết bị')),
        ],
        rows: const [
          DataRow(cells: [DataCell(Text('user_1024')), DataCell(Text('Người dùng')), DataCell(Text('Hoạt động')), DataCell(Text('Android'))]),
          DataRow(cells: [DataCell(Text('mod_0001')), DataCell(Text('Quản trị')), DataCell(Text('Hoạt động')), DataCell(Text('Web'))]),
          DataRow(cells: [DataCell(Text('user_8891')), DataCell(Text('Người dùng')), DataCell(Text('Tạm khóa')), DataCell(Text('iOS'))]),
        ],
      ),
    );
  }
}

class _ReportItem extends StatelessWidget {
  final String title;
  final String status;
  final String reporter;

  const _ReportItem({required this.title, required this.status, required this.reporter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Báo cáo bởi $reporter',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _StatusPill(label: status),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _ModelItem extends StatelessWidget {
  final String version;
  final String status;
  final String note;

  const _ModelItem({required this.version, required this.status, required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.memory_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  version,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  note,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _StatusPill(label: status),
        ],
      ),
    );
  }
}

class _LogsList extends StatelessWidget {
  const _LogsList();

  @override
  Widget build(BuildContext context) {
    const logs = [
      ('09:12', 'Admin xem danh sách SOS'),
      ('09:04', 'Model v1.0.0 được gắn active'),
      ('08:58', 'Người dùng user_1024 tạo báo cáo mới'),
      ('08:41', 'App nhận 3 tín hiệu cảnh báo giao thông'),
    ];

    return Column(
      children: logs
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TimelineRow(time: item.$1, label: item.$2, icon: Icons.bolt_outlined),
            ),
          )
          .toList(),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.16),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ],
    );
  }
}

class _DashboardTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _DashboardTab(this.icon, this.activeIcon, this.label);
}