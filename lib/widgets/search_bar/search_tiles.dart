import 'package:flutter/material.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/bus_models.dart';
import '../../models/subway_models.dart';
import '../../services/place_search_service.dart';
import '../../widgets/bus_overlay.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../search_bar.dart' show StationSearchResult;

/// 지하철역 (StationSearchResult) 검색 결과 tile.
/// 환승역(allLineIds 합집합 길이 > 1)이면 노선색 그라데이션 + "지하철" 라벨.
class StationTile extends StatelessWidget {
  final StationSearchResult result;
  final void Function(StationSearchResult) onSelect;
  const StationTile({super.key, required this.result, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final r = result;
    final lineIds = r.allLineIds.isEmpty ? <String>[r.lineId] : r.allLineIds;
    final allColors = <Color>[];
    for (final id in lineIds) {
      final c = SubwayColors.lineColors[id];
      if (c != null && !allColors.contains(c)) allColors.add(c);
    }
    if (allColors.isEmpty) allColors.add(r.lineColor);
    final hasTrf = allColors.length > 1;

    return GestureDetector(
      onTap: () => onSelect(r),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: allColors.length > 1
                    ? LinearGradient(
                        colors: allColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: allColors.length == 1 ? r.lineColor : null,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.subway, size: 15, color: Colors.white),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.station.name,
                    style: AppTypography.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (hasTrf)
                    Text(
                      lineIds
                          .map((id) => SubwayColors.lineNames[id] ?? id)
                          .join(' · '),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textDisabled,
                      ),
                    ),
                ],
              ),
            ),
            if (hasTrf)
              ShaderMask(
                shaderCallback: (bounds) =>
                    LinearGradient(colors: allColors).createShader(bounds),
                child: Text(
                  AppL10n.of(context).searchTileSubway,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              )
            else
              Text(
                r.lineName,
                style: AppTypography.bodySm.copyWith(color: r.lineColor),
              ),
          ],
        ),
      ),
    );
  }
}

/// "내 위치" 항목 — 길찾기 dropdown 에서 활성 필드에 현재 위치 채우기.
class CurrentLocationTile extends StatelessWidget {
  final VoidCallback onTap;
  const CurrentLocationTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.my_location,
                size: 16,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                AppL10n.of(context).chatMyLocation,
                style: AppTypography.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 버스 노선 tile.
class BusTile extends StatelessWidget {
  final BusRouteInfo route;
  final VoidCallback onTap;
  const BusTile({super.key, required this.route, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = BusColors.fromRouteType(route.routeType);
    final typeName = busTypeName(route.routeType);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Icon(Icons.directions_bus, size: 15, color: color),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.busRouteNm,
                    style: AppTypography.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (route.stStationNm.isNotEmpty || route.edStationNm.isNotEmpty)
                    Text(
                      '${route.stStationNm} → ${route.edStationNm}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textDisabled,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(typeName, style: AppTypography.caption.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

/// 카카오 검색 결과 (장소) tile.
class PlaceTile extends StatelessWidget {
  final PlaceSearchResult place;
  final VoidCallback onTap;
  const PlaceTile({super.key, required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final icon = placeIcon(place.category);
    final color = placeColor(place.category);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(child: Icon(icon, size: 15, color: color)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: AppTypography.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (place.address.isNotEmpty)
                    Text(
                      place.address,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textDisabled,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              place.category,
              style: AppTypography.caption.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 공유 helper ──────────────────────────

String busTypeName(int type) {
  switch (type) {
    case 3: return '간선';
    case 4: return '지선';
    case 5: return '순환';
    case 6: return '광역';
    case 7: return '인천';
    case 8: return '경기';
    default: return '버스';
  }
}

IconData placeIcon(String category) {
  switch (category) {
    case '음식점': return Icons.restaurant;
    case '카페': return Icons.local_cafe;
    case '공원': return Icons.park;
    case '쇼핑': return Icons.shopping_bag;
    case '의료': return Icons.local_hospital;
    case '교육': return Icons.school;
    case '숙박': return Icons.hotel;
    case '금융': return Icons.account_balance;
    case '교통': return Icons.directions_transit;
    case '주소': return Icons.pin_drop;
    case '도시': return Icons.location_city;
    case '동네': return Icons.holiday_village;
    case '도로': return Icons.edit_road;
    default: return Icons.place;
  }
}

Color placeColor(String category) {
  switch (category) {
    case '음식점': return Colors.orange;
    case '카페': return const Color(0xFF795548);
    case '공원': return Colors.green;
    case '쇼핑': return Colors.pink;
    case '의료': return Colors.red;
    case '교육': return Colors.indigo;
    case '숙박': return Colors.purple;
    case '금융': return Colors.teal;
    case '교통': return Colors.blue;
    case '주소': return Colors.blueGrey;
    case '도시': return Colors.deepPurple;
    case '동네': return Colors.amber;
    case '도로': return Colors.grey;
    default: return Colors.blueAccent;
  }
}
