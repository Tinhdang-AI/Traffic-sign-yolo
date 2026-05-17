import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class VoiceSettingsScreen extends StatefulWidget {
  const VoiceSettingsScreen({super.key});
  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen>
    with SingleTickerProviderStateMixin {
  int _voiceType = 0;
  double _speechRate = 0.55;
  double _volume = 0.80;
  String _language = 'vi-VN';
  bool _autoAlert = true;
  bool _hapticFeedback = true;
  bool _pedestrianAlert = true;
  bool _speedAlert = true;
  bool _trafficAlert = false;
  late final AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  final _voices = [
    _VoiceOption('AI Nam', Icons.person_outline, 'Giọng nam tiêu chuẩn'),
    _VoiceOption('AI Nữ', Icons.person_2_outlined, 'Giọng nữ tiêu chuẩn'),
    _VoiceOption('AI Trung lập', Icons.smart_toy_outlined, 'Giọng trung tính'),
  ];

  final _languages = [
    _LangOption('vi-VN', '🇻🇳', 'Tiếng Việt'),
    // _LangOption('en-US', '🇺🇸', 'English (US)'),
    // _LangOption('zh-CN', '🇨🇳', '中文'),
  ];

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        _buildHeader(top),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Voice preview
              _VoicePreviewCard(waveCtrl: _waveCtrl),
              const SizedBox(height: 24),

              // Voice type
              _SettingsLabel('Loại giọng nói AI'),
              const SizedBox(height: 10),
              ...List.generate(_voices.length, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _VoiceTypeCard(
                  option: _voices[i],
                  selected: _voiceType == i,
                  onTap: () => setState(() => _voiceType = i),
                ),
              )),
              const SizedBox(height: 20),

              // Language
              _SettingsLabel('Ngôn ngữ'),
              const SizedBox(height: 10),
              Row(children: _languages.map((l) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: l != _languages.last ? 8 : 0),
                  child: _LangCard(
                    option: l,
                    selected: _language == l.code,
                    onTap: () => setState(() => _language = l.code),
                  ),
                ),
              )).toList()),
              const SizedBox(height: 24),

              // Speech rate
              _SettingsLabel('Tốc độ nói'),
              const SizedBox(height: 8),
              _SliderCard(
                value: _speechRate,
                minLabel: 'Chậm',
                maxLabel: 'Nhanh',
                displayValue: '${(_speechRate * 100).toInt()}%',
                color: AppColors.primaryContainer,
                onChanged: (v) => setState(() => _speechRate = v),
              ),
              const SizedBox(height: 16),

              // Volume
              _SettingsLabel('Âm lượng'),
              const SizedBox(height: 8),
              _SliderCard(
                value: _volume,
                minLabel: 'Im lặng',
                maxLabel: 'Tối đa',
                displayValue: '${(_volume * 100).toInt()}%',
                color: AppColors.secondaryContainer,
                onChanged: (v) => setState(() => _volume = v),
              ),
              const SizedBox(height: 24),

              // Alert toggles
              _SettingsLabel('Cảnh báo tự động'),
              const SizedBox(height: 10),
              _ToggleCard(
                icon: Icons.notifications_active_outlined,
                iconColor: AppColors.primaryContainer,
                title: 'Cảnh báo giọng nói',
                subtitle: 'Thông báo bằng giọng nói khi phát hiện biển',
                value: _autoAlert,
                onChanged: (v) => setState(() => _autoAlert = v),
              ),
              const SizedBox(height: 8),
              _ToggleCard(
                icon: Icons.vibration_outlined,
                iconColor: AppColors.secondaryContainer,
                title: 'Phản hồi rung',
                subtitle: 'Rung khi có cảnh báo quan trọng',
                value: _hapticFeedback,
                onChanged: (v) => setState(() => _hapticFeedback = v),
              ),
              const SizedBox(height: 8),
              _ToggleCard(
                icon: Icons.directions_walk,
                iconColor: AppColors.tertiaryContainer,
                title: 'Cảnh báo người đi bộ',
                subtitle: 'Phát hiện người đi bộ gần lối qua',
                value: _pedestrianAlert,
                onChanged: (v) => setState(() => _pedestrianAlert = v),
              ),
              const SizedBox(height: 8),
              _ToggleCard(
                icon: Icons.speed,
                iconColor: AppColors.secondaryContainer,
                title: 'Cảnh báo tốc độ',
                subtitle: 'Thông báo khi vượt giới hạn tốc độ',
                value: _speedAlert,
                onChanged: (v) => setState(() => _speedAlert = v),
              ),
              const SizedBox(height: 8),
              _ToggleCard(
                icon: Icons.traffic_outlined,
                iconColor: AppColors.primaryContainer,
                title: 'Cảnh báo giao thông',
                subtitle: 'Thông tin ùn tắc và tình hình giao thông',
                value: _trafficAlert,
                onChanged: (v) => setState(() => _trafficAlert = v),
              ),
              const SizedBox(height: 24),

              // Test button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.record_voice_over, size: 20),
                  label: Text('Thử giọng nói AI',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader(double top) {
    return Container(
      padding: EdgeInsets.only(top: top + 8, left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: Row(children: [
        const Icon(Icons.satellite_alt, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text('SENTINEL AI',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 3.5, color: AppColors.primary)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('CÀI ĐẶT GIỌNG NÓI',
              style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.primary)),
        ),
      ]),
    );
  }
}

class _SettingsLabel extends StatelessWidget {
  final String text;
  const _SettingsLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface));
  }
}

class _VoicePreviewCard extends StatelessWidget {
  final AnimationController waveCtrl;
  const _VoicePreviewCard({required this.waveCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryContainer.withOpacity(0.2), AppColors.surfaceContainerHigh],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryContainer.withOpacity(0.3)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.primaryContainer.withOpacity(0.5), blurRadius: 16)],
            ),
            child: const Icon(Icons.record_voice_over, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Cài đặt Giọng nói AI',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
              Text('Tuỳ chỉnh giọng đọc cảnh báo',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant.withOpacity(0.7))),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        // Wave visualiser
        AnimatedBuilder(
          animation: waveCtrl,
          builder: (_, __) {
            const bars = [12.0, 20.0, 28.0, 36.0, 44.0, 36.0, 28.0, 20.0, 12.0];
            const ops  = [0.2,  0.35, 0.55, 0.75, 1.0,  0.75, 0.55, 0.35, 0.2];
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(bars.length, (i) {
                final wave = math.sin((waveCtrl.value * math.pi * 2) + i * 0.65);
                final h = (bars[i] + wave * 10).clamp(4.0, 60.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    width: 6,
                    height: h,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(ops[i]),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: i == 4
                          ? [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 10)]
                          : null,
                    ),
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 8),
        Text('"Phát hiện biển dừng — Hãy dừng xe!"',
            style: GoogleFonts.inter(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.primary.withOpacity(0.8))),
      ]),
    );
  }
}

class _VoiceOption {
  final String name, desc;
  final IconData icon;
  const _VoiceOption(this.name, this.icon, this.desc);
}

class _VoiceTypeCard extends StatelessWidget {
  final _VoiceOption option;
  final bool selected;
  final VoidCallback onTap;
  const _VoiceTypeCard({required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer.withOpacity(0.15) : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryContainer : Colors.white.withOpacity(0.07),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryContainer.withOpacity(0.25) : AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(option.icon,
                color: selected ? AppColors.primary : AppColors.onSurfaceVariant.withOpacity(0.6), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(option.name,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.primary : AppColors.onSurface)),
              Text(option.desc,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant.withOpacity(0.6))),
            ]),
          ),
          if (selected)
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                  color: AppColors.primaryContainer, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 13),
            ),
        ]),
      ),
    );
  }
}

class _LangOption {
  final String code, flag, name;
  const _LangOption(this.code, this.flag, this.name);
}

class _LangCard extends StatelessWidget {
  final _LangOption option;
  final bool selected;
  final VoidCallback onTap;
  const _LangCard({required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer.withOpacity(0.15) : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryContainer : Colors.white.withOpacity(0.07),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(children: [
          Text(option.flag, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(option.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? AppColors.primary : AppColors.onSurfaceVariant.withOpacity(0.7))),
        ]),
      ),
    );
  }
}

class _SliderCard extends StatelessWidget {
  final double value;
  final String minLabel, maxLabel, displayValue;
  final Color color;
  final ValueChanged<double> onChanged;
  const _SliderCard({
    required this.value,
    required this.minLabel,
    required this.maxLabel,
    required this.displayValue,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(minLabel, style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant.withOpacity(0.6))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(displayValue,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ),
          Text(maxLabel, style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant.withOpacity(0.6))),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            inactiveTrackColor: AppColors.outlineVariant.withOpacity(0.4),
            overlayColor: color.withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(value: value, onChanged: onChanged),
        ),
      ]),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? iconColor.withOpacity(0.25) : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: value ? iconColor.withOpacity(0.15) : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              color: value ? iconColor : AppColors.onSurfaceVariant.withOpacity(0.5), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
            Text(subtitle,
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.onSurfaceVariant.withOpacity(0.6))),
          ]),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: iconColor,
          inactiveThumbColor: AppColors.outline,
          inactiveTrackColor: AppColors.surfaceContainerHigh,
        ),
      ]),
    );
  }
}
