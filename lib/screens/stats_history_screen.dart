import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class StatsHistoryScreen extends StatefulWidget {
  const StatsHistoryScreen({super.key});
  @override
  State<StatsHistoryScreen> createState() => _StatsHistoryScreenState();
}

class _StatsHistoryScreenState extends State<StatsHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MetricRow(),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    title: 'Biểu đồ tốc độ',
                    subtitle: 'Chuyến đi gần nhất (km/h)',
                  ),
                  const SizedBox(height: 12),
                  _SpeedChart(),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    title: 'Sự kiện quan trọng',
                    subtitle: 'Phát hiện trong 7 ngày qua',
                  ),
                  const SizedBox(height: 12),
                  _EventCard(
                    icon: Icons.block,
                    iconColor: AppColors.tertiaryContainer,
                    title: 'Biển Dừng',
                    time: 'Hôm nay, 08:42',
                    location: 'Nguyễn Huệ & Lê Lợi',
                    count: '3 lần',
                  ),
                  const SizedBox(height: 8),
                  _EventCard(
                    icon: Icons.speed,
                    iconColor: AppColors.primaryContainer,
                    title: 'Vượt tốc độ',
                    time: 'Hôm qua, 17:15',
                    location: 'Xa lộ Hà Nội',
                    count: '1 lần',
                  ),
                  const SizedBox(height: 8),
                  _EventCard(
                    icon: Icons.warning_amber,
                    iconColor: AppColors.secondaryContainer,
                    title: 'Người đi bộ',
                    time: '11/05, 09:00',
                    location: 'Phạm Văn Đồng',
                    count: '5 lần',
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    title: 'Phân tích AI',
                    subtitle: 'Đánh giá hành vi lái xe',
                  ),
                  const SizedBox(height: 12),
                  _AIAnalysisCard(),
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
      padding: EdgeInsets.only(top: top + 8, left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.satellite_alt,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'SENTINEL AI',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.5,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              _HeaderChip(label: 'THỐNG KÊ & LỊCH SỬ'),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Phân tích & Thống kê',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          Text(
            'Dữ liệu hành trình và hiệu suất an toàn gần đây.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  const _HeaderChip({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title, subtitle;
  const _SectionTitle({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.onSurfaceVariant.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            value: '98',
            unit: '%',
            label: 'Độ chính xác nhận diện',
            change: '+2.4%',
            changePositive: true,
            icon: Icons.verified_outlined,
            accent: AppColors.primaryContainer,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            value: '3',
            unit: 'lần',
            label: 'Can thiệp thủ công',
            change: '-1 so với tuần trước',
            changePositive: true,
            icon: Icons.touch_app_outlined,
            accent: AppColors.secondaryContainer,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String value, unit, label, change;
  final bool changePositive;
  final IconData icon;
  final Color accent;

  const _MetricCard({
    required this.value,
    required this.unit,
    required this.label,
    required this.change,
    required this.changePositive,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: accent,
                ),
              ),
              const SizedBox(width: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: accent.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                changePositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: changePositive
                    ? const Color(0xFF4CAF50)
                    : AppColors.tertiaryContainer,
              ),
              const SizedBox(width: 3),
              Text(
                change,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: changePositive
                      ? const Color(0xFF4CAF50)
                      : AppColors.tertiaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeedChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final speeds = [35.0, 52.0, 67.0, 45.0, 80.0, 58.0, 42.0, 70.0, 55.0, 38.0];
    final maxSpeed = 100.0;
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vận tốc (km/h)',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Giới hạn: 60 km/h',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: CustomPaint(
              painter: _SpeedChartPainter(speeds: speeds, maxSpeed: maxSpeed),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedChartPainter extends CustomPainter {
  final List<double> speeds;
  final double maxSpeed;
  const _SpeedChartPainter({required this.speeds, required this.maxSpeed});

  @override
  void paint(Canvas canvas, Size s) {
    final limitY = s.height * (1 - 60 / maxSpeed);
    // Speed limit line
    canvas.drawLine(
      Offset(0, limitY),
      Offset(s.width, limitY),
      Paint()
        ..color = AppColors.secondaryContainer.withOpacity(0.5)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final barW = s.width / (speeds.length * 2 - 1);
    for (int i = 0; i < speeds.length; i++) {
      final h = s.height * (speeds[i] / maxSpeed);
      final x = i * barW * 2;
      final isOver = speeds[i] > 60;
      final color = isOver
          ? AppColors.tertiaryContainer
          : AppColors.primaryContainer;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, s.height - h, barW, h),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color, color.withOpacity(0.3)],
          ).createShader(Rect.fromLTWH(x, s.height - h, barW, h)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _EventCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, time, location, count;
  const _EventCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.time,
    required this.location,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$time · $location',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AIAnalysisCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryContainer.withOpacity(0.15),
            AppColors.surfaceContainerHigh,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryContainer.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Phân tích hành vi AI',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Phân tích định lượng cho thấy cải thiện 14% trong việc duy trì điểm tập trung sau sự kiện xúc giác. Xu hướng hiện tại cho thấy sự phù hợp cao với các giao thức lái xe an toàn 2024.',
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.6,
              color: AppColors.onSurfaceVariant.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 12),
          _ProgressBar(
            label: 'An toàn tổng thể',
            value: 0.94,
            color: AppColors.primaryContainer,
          ),
          const SizedBox(height: 8),
          _ProgressBar(
            label: 'Tuân thủ tốc độ',
            value: 0.87,
            color: AppColors.secondaryContainer,
          ),
          const SizedBox(height: 8),
          _ProgressBar(
            label: 'Phản ứng cảnh báo',
            value: 0.98,
            color: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _ProgressBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: AppColors.outlineVariant.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(value * 100).toInt()}%',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
