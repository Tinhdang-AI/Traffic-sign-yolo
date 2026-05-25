import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import '../widgets/traffic_sign_icon.dart';

class StatsHistoryScreen extends StatefulWidget {
  const StatsHistoryScreen({super.key});

  @override
  State<StatsHistoryScreen> createState() => _StatsHistoryScreenState();
}

class _StatsHistoryScreenState extends State<StatsHistoryScreen> {
  List<HistoryItem> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    DatabaseService.historyChangeNotifier.addListener(_loadHistory);
  }

  @override
  void dispose() {
    DatabaseService.historyChangeNotifier.removeListener(_loadHistory);
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await DatabaseService().getDetectionHistory();
    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllHistory() async {
    setState(() {
      _isLoading = true;
    });
    await DatabaseService().clearDetectionHistory();
    await _loadHistory();
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF17181D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        title: Text(
          'Xóa lịch sử quét?',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Tất cả lịch sử quét biển báo sẽ bị xóa vĩnh viễn và không thể khôi phục.',
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllHistory();
            },
            child: Text(
              'Xóa tất cả',
              style: GoogleFonts.inter(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0E),
      body: Column(
        children: [
          _buildHeader(top),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF60A5FA),
                    ),
                  )
                : _history.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        color: const Color(0xFF60A5FA),
                        backgroundColor: const Color(0xFF17181D),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _history.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = _history[index];
                            return _HistoryCard(item: item);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double top) {
    return Container(
      padding: EdgeInsets.only(top: top + 16, left: 16, right: 16, bottom: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0C0E),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: Colors.white38,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'LỊCH SỬ QUÉT',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: Colors.white54,
                ),
              ),
              const Spacer(),
              if (_history.isNotEmpty) ...[
                IconButton(
                  icon: const Icon(
                    Icons.delete_sweep_outlined,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: _showClearDialog,
                  tooltip: 'Xóa tất cả lịch sử',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                const SizedBox(width: 4),
              ],
              _HeaderChip(label: '${_history.length} BIỂN BÁO'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Lịch sử nhận diện',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Danh sách các biển báo giao thông đã quét được.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: Colors.white38,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 64,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có lịch sử quét',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Các biển báo đã quét sẽ hiển thị tại đây.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white24,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF17253D), // Dark navy blue from screenshot
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF60A5FA), // Light blue text from screenshot
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final HistoryItem item;
  
  const _HistoryCard({required this.item});

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} - ${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}';
  }

  String _cleanLocationName(String loc) {
    final parts = loc
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.isEmpty ? loc.trim() : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF17181D), // Premium dark graphite color from screenshot
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: TrafficSignIcon thumbnail
          TrafficSignIcon(
            label: item.label,
            size: 44,
          ),
          const SizedBox(width: 14),
          // Center content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title (Sign label in bold all-caps)
                Text(
                  item.label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                // Time row with access_time_rounded icon
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: Colors.white38,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(item.timestamp),
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Location row with location_on_outlined icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: Colors.white38,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _cleanLocationName(item.displayLocationName),
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          height: 1.35,
                          color: Colors.white60,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Right: Pill-shaped confidence badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HistoryConfidenceBadge(confidence: item.confidence),
              const SizedBox(height: 16),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onPressed: () => _showDeleteSingleDialog(context),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                splashRadius: 20,
                tooltip: 'Xóa biển báo này',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteSingleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF17181D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        title: Text(
          'Xóa biển báo này?',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa biển báo "${item.label.toUpperCase()}" này ra khỏi lịch sử không?',
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Hủy',
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await DatabaseService().deleteDetectionHistoryItem(item.id);
            },
            child: Text(
              'Xóa',
              style: GoogleFonts.inter(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryConfidenceBadge extends StatelessWidget {
  final double confidence;
  const _HistoryConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final confPercent = (confidence * 100).toInt().clamp(0, 100);
    final bool isHigh = confidence >= 0.70;
    
    final Color badgeColor = isHigh ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final Color backgroundColor = badgeColor.withOpacity(0.08);
    final IconData iconData = isHigh ? Icons.check_circle : Icons.info_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: 12,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            '$confPercent%',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}
