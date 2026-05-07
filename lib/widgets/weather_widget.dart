import 'package:flutter/material.dart';
import 'adaptive/adaptive.dart';
import '../services/environment_service.dart';
import '../theme/app_colors.dart';

/// 지도 위 날씨/시간 위젯 (리퀴드 글라스)
/// 탭하면 옆으로 길쭉하게 펼쳐지며 주간 예보
class WeatherTimeWidget extends StatefulWidget {
  final EnvironmentData? environment;

  const WeatherTimeWidget({super.key, this.environment});

  @override
  State<WeatherTimeWidget> createState() => _WeatherTimeWidgetState();
}

class _WeatherTimeWidgetState extends State<WeatherTimeWidget> {
  bool _expanded = false;
  List<DailyForecast>? _forecast;
  bool _loading = false;

  void _toggle() async {
    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }
    setState(() => _expanded = true);
    if (_forecast == null) {
      setState(() => _loading = true);
      final forecast = await EnvironmentService.instance.fetchWeeklyForecast();
      if (mounted) setState(() { _forecast = forecast; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final env = widget.environment;
    if (env == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final timeIcon = switch (env.timeOfDay) {
      DayPhase.dawn => Icons.wb_twilight,
      DayPhase.day => Icons.wb_sunny,
      DayPhase.dusk => Icons.wb_twilight,
      DayPhase.night => Icons.nights_stay,
    };
    final weatherColor = _weatherColor(env.weather);
    final isBright = env.lightPreset == 'day' || env.lightPreset == 'dawn';
    final fg = isBright ? const Color(0xFF333333) : const Color(0xFFB0B0B0);
    final fgSub = isBright ? const Color(0xFF666666) : const Color(0xFF8E8E93);

    final compactWidth = 58.0;
    final expandedWidth = MediaQuery.of(context).size.width - 80;

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        width: _expanded ? expandedWidth : compactWidth,
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(),
        child: AdaptiveGlassContainer.rect(
          cornerRadius: _expanded ? 20 : 999,
          interactive: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 150 && _expanded) {
                return _buildExpanded(env, timeStr, timeIcon, weatherColor, fg, fgSub);
              }
              return _buildCompact(timeIcon, timeStr, env, weatherColor, fg);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(IconData timeIcon, String timeStr, EnvironmentData env, Color weatherColor, Color fg) {
    return SizedBox(
      width: 58,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(timeIcon, size: 16, color: fg),
            const SizedBox(height: 4),
            FittedBox(child: Text(timeStr, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg))),
            const SizedBox(height: 20),
            Icon(env.weatherIcon, size: 16, color: weatherColor),
            const SizedBox(height: 4),
            FittedBox(child: Text('${env.temperature.toStringAsFixed(0)}°', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: weatherColor))),
          ],
        ),
      ),
    );
  }

  Widget _buildExpanded(EnvironmentData env, String timeStr, IconData timeIcon, Color weatherColor, Color fg, Color fgSub) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 현재 날씨 + 주간 평균
          Row(
            children: [
              Icon(env.weatherIcon, size: 20, color: weatherColor),
              const SizedBox(width: 6),
              Text('${env.temperature.toStringAsFixed(0)}°', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fg)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  env.weatherDescription,
                  style: TextStyle(fontSize: 12, color: fgSub),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              if (_forecast != null && _forecast!.isNotEmpty) ...[
                Text('주간 ', style: TextStyle(fontSize: 10, color: fgSub)),
                Text('${_weeklyAvgMin()}°', style: TextStyle(fontSize: 10, color: Colors.lightBlueAccent.withValues(alpha: 0.8))),
                Text(' / ', style: TextStyle(fontSize: 10, color: fgSub)),
                Text('${_weeklyAvgMax()}°', style: TextStyle(fontSize: 10, color: Colors.orangeAccent.withValues(alpha: 0.9))),
              ] else ...[
                Icon(timeIcon, size: 14, color: fgSub),
                const SizedBox(width: 4),
                Text(timeStr, style: TextStyle(fontSize: 11, color: fgSub)),
              ],
            ],
          ),

          const SizedBox(height: 10),
          Container(height: 0.5, color: const Color(0x30FFFFFF)),
          const SizedBox(height: 10),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5))),
            )
          else if (_forecast != null && _forecast!.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _forecast!.map((f) => _buildDayColumn(f, fg, fgSub)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDayColumn(DailyForecast f, Color fg, Color fgSub) {
    final now = DateTime.now();
    final isToday = f.date.day == now.day && f.date.month == now.month;
    final dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final dayName = isToday ? '오늘' : dayNames[f.date.weekday - 1];
    final weatherColor = _descriptionColor(f.description);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(dayName, style: TextStyle(fontSize: 12, fontWeight: isToday ? FontWeight.w700 : FontWeight.w500, color: isToday ? fg : fgSub)),
        const SizedBox(height: 4),
        Icon(f.weatherIcon, size: 18, color: weatherColor),
        const SizedBox(height: 4),
        Text('${f.maxTemp.toStringAsFixed(0)}°', style: TextStyle(fontSize: 11, color: Colors.orangeAccent.withValues(alpha: 0.9))),
        Text('${f.minTemp.toStringAsFixed(0)}°', style: TextStyle(fontSize: 10, color: Colors.lightBlueAccent.withValues(alpha: 0.8))),
      ],
    );
  }

  String _weeklyAvgMin() {
    if (_forecast == null || _forecast!.isEmpty) return '-';
    final avg = _forecast!.map((f) => f.minTemp).reduce((a, b) => a + b) / _forecast!.length;
    return avg.toStringAsFixed(0);
  }

  String _weeklyAvgMax() {
    if (_forecast == null || _forecast!.isEmpty) return '-';
    final avg = _forecast!.map((f) => f.maxTemp).reduce((a, b) => a + b) / _forecast!.length;
    return avg.toStringAsFixed(0);
  }

  Color _weatherColor(WeatherCondition w) {
    return switch (w) {
      WeatherCondition.clear => AppColors.weatherClear,
      WeatherCondition.cloudy => AppColors.weatherCloudy,
      WeatherCondition.rain => AppColors.weatherRain,
      WeatherCondition.drizzle => AppColors.weatherDrizzle,
      WeatherCondition.snow => AppColors.weatherSnow,
      WeatherCondition.fog => AppColors.weatherFog,
      WeatherCondition.thunderstorm => AppColors.weatherThunder,
    };
  }

  Color _descriptionColor(String desc) {
    if (desc.contains('맑')) return AppColors.weatherClear;
    if (desc.contains('흐')) return AppColors.weatherCloudy;
    if (desc.contains('비') || desc.contains('소나기')) return AppColors.weatherRain;
    if (desc.contains('눈')) return AppColors.weatherSnow;
    if (desc.contains('안개')) return AppColors.weatherFog;
    if (desc.contains('뇌우')) return AppColors.weatherThunder;
    return AppColors.weatherCloudy;
  }
}
