import 'package:flutter/material.dart';
import '../../../data/river_bus_data.dart';
import 'place_action_button.dart';

/// 한강버스 선착장 상세 패널.
class RiverBusStopPanel extends StatelessWidget {
  final RiverBusStop stop;
  final VoidCallback onClose;
  final void Function(String name, {double? lat, double? lng}) onDeparture;
  final void Function(String name, {double? lat, double? lng}) onArrival;

  const RiverBusStopPanel({
    super.key,
    required this.stop,
    required this.onClose,
    required this.onDeparture,
    required this.onArrival,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final routes = RiverBusData.routes
        .where((r) => r.stopIds.contains(stop.id))
        .toList();
    final now = DateTime.now();
    final currentMin = now.hour * 60 + now.minute;
    final stopLabel = '${stop.name} 선착장';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF00ACC1).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00ACC1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_boat,
                    size: 18,
                    color: Color(0xFF00ACC1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stopLabel,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        stop.address,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: cs.onSurfaceVariant),
                  onPressed: onClose,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...routes.map((r) {
              final isActive = r.isActive;
              String nextTime = '운항 종료';
              if (isActive) {
                for (
                  int dep = r.firstDeparture;
                  dep <= r.lastDeparture;
                  dep += r.intervalMin
                ) {
                  if (dep > currentMin) {
                    final h = dep ~/ 60;
                    final m = dep % 60;
                    nextTime =
                        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
                    break;
                  }
                }
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Color(r.color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        r.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(r.color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      isActive ? '다음 $nextTime' : '정비 중',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? const Color(0xFF00ACC1)
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
            Row(
              children: [
                PlaceActionButton(
                  icon: Icons.trip_origin,
                  label: '출발',
                  color: cs.primary,
                  onTap: () {
                    onClose();
                    onDeparture(stopLabel, lat: stop.lat, lng: stop.lng);
                  },
                ),
                const SizedBox(width: 8),
                PlaceActionButton(
                  icon: Icons.place,
                  label: '도착',
                  color: Colors.redAccent,
                  onTap: () {
                    onClose();
                    onArrival(stopLabel, lat: stop.lat, lng: stop.lng);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
