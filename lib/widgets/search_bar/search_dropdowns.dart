import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/bus_models.dart';
import '../../services/place_search_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../search_bar.dart' show StationSearchResult;
import 'search_tiles.dart';

/// 검색 dropdown 외곽 (M3 surface 또는 Glass blur).
class _DropdownShell extends StatelessWidget {
  final double radius;
  final double maxHeight;
  final Widget child;
  const _DropdownShell({
    required this.radius,
    required this.maxHeight,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      final cs = Theme.of(context).colorScheme;
      return Material(
        elevation: 3,
        shadowColor: cs.shadow.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(radius),
        color: cs.surfaceContainer,
        surfaceTintColor: cs.surfaceTint,
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: child,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: AppColors.glassDropOpacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

Color _separatorColor(BuildContext context, {required bool thick}) {
  final isM3 = Platform.isAndroid;
  if (isM3) {
    final v = Theme.of(context).colorScheme.outlineVariant;
    return thick ? v : v.withValues(alpha: 0.5);
  }
  return AppColors.divider;
}

/// 일반 검색 결과 dropdown — 지하철역 + 버스 + 장소 3섹션.
class CombinedDropdown extends StatelessWidget {
  final List<StationSearchResult> stations;
  final List<BusRouteInfo> buses;
  final List<PlaceSearchResult> places;
  final void Function(StationSearchResult) onStationSelect;
  final void Function(BusRouteInfo) onBusSelect;
  final void Function(PlaceSearchResult) onPlaceSelect;
  final double radius;
  final double maxHeight;

  const CombinedDropdown({
    super.key,
    required this.stations,
    required this.buses,
    required this.places,
    required this.onStationSelect,
    required this.onBusSelect,
    required this.onPlaceSelect,
    required this.radius,
    this.maxHeight = 350,
  });

  @override
  Widget build(BuildContext context) {
    final busCount = buses.take(5).length;
    final totalCount = stations.length + busCount + places.length;
    final stationEnd = stations.length - 1;
    final busEnd = stations.length + busCount - 1;

    return _DropdownShell(
      radius: radius,
      maxHeight: maxHeight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        shrinkWrap: true,
        itemCount: totalCount,
        separatorBuilder: (_, i) {
          final isSection =
              (i == stationEnd && (busCount > 0 || places.isNotEmpty)) ||
              (i == busEnd && places.isNotEmpty);
          if (isSection) {
            return Divider(
              height: 16,
              thickness: 0.5,
              indent: 16,
              endIndent: 16,
              color: _separatorColor(context, thick: true),
            );
          }
          return Divider(
            height: 1,
            indent: 48,
            color: _separatorColor(context, thick: false),
          );
        },
        itemBuilder: (_, i) {
          if (i < stations.length) {
            return StationTile(
              result: stations[i],
              onSelect: onStationSelect,
            );
          }
          final busIdx = i - stations.length;
          if (busIdx < busCount) {
            final r = buses[busIdx];
            return BusTile(route: r, onTap: () => onBusSelect(r));
          }
          final p = places[i - stations.length - busCount];
          return PlaceTile(place: p, onTap: () => onPlaceSelect(p));
        },
      ),
    );
  }
}

/// 길찾기 모드 검색 dropdown — 내 위치 + 지하철역 + 장소.
class NavCombinedDropdown extends StatelessWidget {
  final bool showCurrentLocation;
  final List<StationSearchResult> stationResults;
  final List<PlaceSearchResult> placeResults;
  final VoidCallback onCurrentLocation;
  final void Function(StationSearchResult) onStationSelect;
  final void Function(PlaceSearchResult) onPlaceSelect;
  final double radius;
  final double maxHeight;

  const NavCombinedDropdown({
    super.key,
    required this.showCurrentLocation,
    required this.stationResults,
    required this.placeResults,
    required this.onCurrentLocation,
    required this.onStationSelect,
    required this.onPlaceSelect,
    required this.radius,
    this.maxHeight = 280,
  });

  @override
  Widget build(BuildContext context) {
    final cur = showCurrentLocation ? 1 : 0;
    final totalCount = cur + stationResults.length + placeResults.length;
    final stationEnd = cur + stationResults.length - 1;

    return _DropdownShell(
      radius: radius,
      maxHeight: maxHeight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        shrinkWrap: true,
        itemCount: totalCount,
        separatorBuilder: (_, i) {
          if (i == stationEnd && placeResults.isNotEmpty) {
            return Divider(
              height: 16,
              thickness: 0.5,
              indent: 16,
              endIndent: 16,
              color: _separatorColor(context, thick: true),
            );
          }
          return Divider(
            height: 1,
            indent: 48,
            color: _separatorColor(context, thick: false),
          );
        },
        itemBuilder: (_, i) {
          if (showCurrentLocation && i == 0) {
            return CurrentLocationTile(onTap: onCurrentLocation);
          }
          final stationIndex = i - cur;
          if (stationIndex < stationResults.length) {
            return StationTile(
              result: stationResults[stationIndex],
              onSelect: onStationSelect,
            );
          }
          final p = placeResults[stationIndex - stationResults.length];
          return PlaceTile(place: p, onTap: () => onPlaceSelect(p));
        },
      ),
    );
  }
}
