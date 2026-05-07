import 'package:flutter/material.dart';
import '../../../models/bus_models.dart';
import '../../../widgets/bus_overlay.dart';
import '../../../widgets/flight_overlay.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/app_spacing.dart';

/// 라벨/값 정보 항목 (정류소/차량 패널 공통).
class InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const InfoItem({
    super.key,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodySm.copyWith(
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// 일반 시내버스 차량 상세 패널.
class BusDetailPanel extends StatelessWidget {
  final BusPosition bus;
  final TrackedBusRoute route;
  final VoidCallback onClose;
  const BusDetailPanel({
    super.key,
    required this.bus,
    required this.route,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final color = route.color;
    final congestionText = switch (bus.congestion) {
      0 => '정보없음',
      1 || 2 => '여유',
      3 => '보통',
      4 => '혼잡',
      5 => '매우혼잡',
      6 => '만차',
      _ => '정보없음',
    };
    final congestionColor = switch (bus.congestion) {
      1 || 2 => AppColors.success,
      3 => AppColors.warning,
      4 || 5 => AppColors.danger,
      6 => const Color(0xFF8B0000),
      _ => AppColors.textMuted,
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15)),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.directions_bus,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.routeName,
                          style: AppTypography.titleMd.copyWith(color: color),
                        ),
                        Text(
                          '${bus.plainNo} · ${bus.busType == 1 ? "저상버스" : "일반버스"}',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose,
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: InfoItem(
                      label: '혼잡도',
                      value: congestionText,
                      valueColor: congestionColor,
                    ),
                  ),
                  Expanded(
                    child: InfoItem(
                      label: '상태',
                      value: bus.stopFlag == 1 ? '정차 중' : '운행 중',
                      valueColor: color,
                    ),
                  ),
                  if (bus.sectOrd != null)
                    Expanded(
                      child: InfoItem(
                        label: '구간',
                        value: '${bus.sectOrd}번째',
                        valueColor: AppColors.textSecondary,
                      ),
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

/// 비행기 상세 패널.
class FlightDetailPanel extends StatelessWidget {
  final FlightRenderData flight;
  final VoidCallback onClose;
  const FlightDetailPanel({
    super.key,
    required this.flight,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final phaseColor = switch (flight.phase) {
      '상승' => const Color(0xFF00E676),
      '순항' => Colors.white,
      '하강' => const Color(0xFFFF9100),
      '이착륙' => const Color(0xFFFF5252),
      '지상' => Colors.grey,
      _ => Colors.white,
    };
    final altText = flight.onGround
        ? '지상'
        : '${(flight.altitude / 1000).toStringAsFixed(1)}km';
    final speedText = '${(flight.velocity * 3.6).round()}km/h';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        border: Border.all(color: phaseColor.withValues(alpha: 0.4), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: phaseColor.withValues(alpha: 0.12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: phaseColor.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(Icons.flight, size: 20, color: phaseColor),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          flight.callsign.isNotEmpty
                              ? flight.callsign
                              : flight.icao24,
                          style: AppTypography.titleMd.copyWith(
                            color: phaseColor,
                          ),
                        ),
                        Text(
                          '${flight.airline} · ${flight.originCountry}',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose,
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: InfoItem(
                      label: '상태',
                      value: flight.phase,
                      valueColor: phaseColor,
                    ),
                  ),
                  Expanded(
                    child: InfoItem(
                      label: '고도',
                      value: altText,
                      valueColor: AppColors.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: InfoItem(
                      label: '속도',
                      value: speedText,
                      valueColor: AppColors.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: InfoItem(
                      label: '방향',
                      value: '${flight.heading.round()}°',
                      valueColor: AppColors.textSecondary,
                    ),
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

/// 한강버스 차량 상세 패널.
class VesselDetailPanel extends StatelessWidget {
  final RiverBusVessel vessel;
  final VoidCallback onClose;
  const VesselDetailPanel({
    super.key,
    required this.vessel,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF00ACC1);
    final dirText = vessel.direction == 0 ? '정방향' : '역방향';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12)),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.directions_boat,
                        size: 20,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '한강버스 ${vessel.routeName}',
                          style: AppTypography.titleMd.copyWith(color: color),
                        ),
                        Text(
                          '$dirText · ${vessel.phase}',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose,
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: InfoItem(
                      label: vessel.phase == '정차' ? '정차 중' : '다음',
                      value: vessel.currentStopName ?? vessel.nextStopName,
                      valueColor: color,
                    ),
                  ),
                  Expanded(
                    child: InfoItem(
                      label: '진행',
                      value: '${(vessel.progress * 100).round()}%',
                      valueColor: AppColors.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: InfoItem(
                      label: '상태',
                      value: vessel.phase,
                      valueColor: vessel.phase == '정차'
                          ? AppColors.warning
                          : color,
                    ),
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
