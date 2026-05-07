import 'dart:io';
import 'package:flutter/material.dart';
import '../../../services/device_profile_service.dart';
import '../../../services/settings_service.dart';
import '../../../theme/app_typography.dart';
import '../widgets/page_card.dart';

class OptimizationPage extends StatefulWidget {
  static const id = 'optimization_v1';
  const OptimizationPage({super.key});

  @override
  State<OptimizationPage> createState() => _OptimizationPageState();
}

class _OptimizationPageState extends State<OptimizationPage> {
  late String _selected;
  bool _advancedOpen = false;

  @override
  void initState() {
    super.initState();
    _selected = SettingsService.instance.qualityPreset;
  }

  void _select(String preset) {
    setState(() => _selected = preset);
    SettingsService.instance.setQualityPreset(preset);
  }

  @override
  Widget build(BuildContext context) {
    final dp = DeviceProfileService.instance;
    final tierLabel = switch (dp.profile.tier) {
      DeviceTier.flagship => '플래그십',
      DeviceTier.high => '상위',
      DeviceTier.mid => '중급',
      DeviceTier.low => '저사양',
    };
    final cs = Theme.of(context).colorScheme;
    final isIos = Platform.isIOS;
    final titleColor = isIos ? Colors.white : cs.onSurface;
    final subColor = isIos ? Colors.white.withValues(alpha: 0.7) : cs.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: PageCard(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '내 기기에 맞춰',
                style: AppTypography.displayLg.copyWith(
                  color: titleColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '실시간 시각화는 GPU 부담이 커요.\n기기에 맞게 골라주세요.',
                style: AppTypography.bodySm.copyWith(color: subColor),
              ),
              const SizedBox(height: 20),
              _DetectionRow(model: dp.rawModel, tier: tierLabel),
              const SizedBox(height: 18),
              _PresetTile(
                preset: 'high',
                title: '고품질',
                detail: '60fps · 5초 갱신 · 안티얼라이어싱 ON',
                recommended: dp.profile.qualityPreset == 'high',
                selected: _selected == 'high',
                onTap: () => _select('high'),
              ),
              const SizedBox(height: 8),
              _PresetTile(
                preset: 'medium',
                title: '부드러움',
                detail: '30fps · 10초 갱신',
                recommended: dp.profile.qualityPreset == 'medium',
                selected: _selected == 'medium',
                onTap: () => _select('medium'),
              ),
              const SizedBox(height: 8),
              _PresetTile(
                preset: 'low',
                title: '배터리 절약',
                detail: '20fps · 30초 갱신 · 효과 OFF',
                recommended: dp.profile.qualityPreset == 'low',
                selected: _selected == 'low',
                onTap: () => _select('low'),
              ),
              const SizedBox(height: 16),
              _AdvancedToggle(
                open: _advancedOpen,
                onTap: () => setState(() => _advancedOpen = !_advancedOpen),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                child: _advancedOpen
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _LayerToggles(onChanged: () => setState(() {})),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdvancedToggle extends StatelessWidget {
  final bool open;
  final VoidCallback onTap;
  const _AdvancedToggle({required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isIos = Platform.isIOS;
    final color = isIos ? Colors.white.withValues(alpha: 0.7) : cs.primary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: open ? 0.25 : 0,
              child: Icon(Icons.chevron_right, size: 18, color: color),
            ),
            const SizedBox(width: 4),
            Text(
              '고급 — 표시할 레이어 선택',
              style: AppTypography.bodySm.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayerToggles extends StatelessWidget {
  final VoidCallback onChanged;
  const _LayerToggles({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = SettingsService.instance;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LayerRow(
          icon: Icons.directions_subway,
          color: const Color(0xFF00B0FF),
          label: '지하철 (실시간 열차 위치)',
          subtitle: '서울 지하철 + 광역철도. GPU 부담이 가장 큼',
          value: s.showTrains,
          onChanged: (v) {
            s.setShowTrains(v);
            onChanged();
          },
        ),
        _LayerRow(
          icon: Icons.directions_bus,
          color: const Color(0xFF00E676),
          label: '시내버스',
          subtitle: '서울 + 경기 시내버스 실시간 위치',
          value: s.showBuses,
          onChanged: (v) {
            s.setShowBuses(v);
            onChanged();
          },
        ),
        _LayerRow(
          icon: Icons.directions_boat,
          color: const Color(0xFF00ACC1),
          label: '한강버스',
          subtitle: '한강 운항 선박',
          value: s.showRiverBus,
          onChanged: (v) {
            s.setShowRiverBus(v);
            onChanged();
          },
        ),
        _LayerRow(
          icon: Icons.flight,
          color: const Color(0xFFFFC400),
          label: '항공기',
          subtitle: '인천공항 주변 실시간 항공기',
          value: s.showFlights,
          onChanged: (v) {
            s.setShowFlights(v);
            onChanged();
          },
        ),
      ],
    );
  }
}

class _LayerRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _LayerRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isIos = Platform.isIOS;
    final labelColor = isIos ? Colors.white : cs.onSurface;
    final subColor =
        isIos ? Colors.white.withValues(alpha: 0.55) : cs.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySm.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(color: subColor),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeThumbColor: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetectionRow extends StatelessWidget {
  final String model;
  final String tier;
  const _DetectionRow({required this.model, required this.tier});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isIos = Platform.isIOS;
    final bg = isIos
        ? Colors.white.withValues(alpha: 0.08)
        : cs.surfaceContainerHighest;
    final fg = isIos ? Colors.white : cs.onSurface;
    final sub = isIos ? Colors.white.withValues(alpha: 0.6) : cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.phone_iphone, size: 18, color: fg.withValues(alpha: 0.85)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model,
                  style: AppTypography.bodySm.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$tier 등급으로 감지됨',
                  style: AppTypography.caption.copyWith(color: sub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  final String preset;
  final String title;
  final String detail;
  final bool recommended;
  final bool selected;
  final VoidCallback onTap;

  const _PresetTile({
    required this.preset,
    required this.title,
    required this.detail,
    required this.recommended,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isIos = Platform.isIOS;

    final bg = selected
        ? (isIos
            ? Colors.white.withValues(alpha: 0.18)
            : cs.primaryContainer)
        : (isIos
            ? Colors.white.withValues(alpha: 0.04)
            : cs.surfaceContainerHighest);
    final border = selected
        ? (isIos ? Colors.white.withValues(alpha: 0.6) : cs.primary)
        : (isIos
            ? Colors.white.withValues(alpha: 0.08)
            : cs.outlineVariant);
    final titleColor = selected
        ? (isIos ? Colors.white : cs.onPrimaryContainer)
        : (isIos ? Colors.white : cs.onSurface);
    final detailColor =
        isIos ? Colors.white.withValues(alpha: 0.6) : cs.onSurfaceVariant;
    final radioColor = selected
        ? (isIos ? Colors.white : cs.primary)
        : (isIos
            ? Colors.white.withValues(alpha: 0.5)
            : cs.onSurfaceVariant);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 22,
              color: radioColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTypography.bodyMd.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676)
                                .withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '권장',
                            style: AppTypography.caption.copyWith(
                              color: const Color(0xFF00E676),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: AppTypography.caption.copyWith(color: detailColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
