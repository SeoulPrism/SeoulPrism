import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/favorites_service.dart';
import '../../../services/place_search_service.dart';
import 'place_action_button.dart';

/// POI/장소 상세 패널.
/// - 출발/도착 버튼: [onDeparture] / [onArrival] 콜백 (좌표 함께 전달).
/// - 정보 버튼/카드 탭: [onShowWebView] (place.placeUrl 있을 때만).
/// - 닫기: [onClose].
class PlaceDetailPanel extends StatefulWidget {
  final PlaceSearchResult place;
  final VoidCallback onClose;
  final VoidCallback onShowWebView;
  final void Function(String name, {double? lat, double? lng}) onDeparture;
  final void Function(String name, {double? lat, double? lng}) onArrival;

  const PlaceDetailPanel({
    super.key,
    required this.place,
    required this.onClose,
    required this.onShowWebView,
    required this.onDeparture,
    required this.onArrival,
  });

  @override
  State<PlaceDetailPanel> createState() => _PlaceDetailPanelState();
}

class _PlaceDetailPanelState extends State<PlaceDetailPanel> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final place = widget.place;
    final hasDetail = place.address.isNotEmpty;
    final hasDistance = place.distance != null && place.distance!.isNotEmpty;
    final hasPhone = place.phone != null && place.phone!.isNotEmpty;
    final hasUrl = place.placeUrl != null && place.placeUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GestureDetector(
        onTap: hasUrl ? widget.onShowWebView : null,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (place.category.isNotEmpty)
                              Text(
                                place.category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.primary,
                                ),
                              ),
                            if (hasDistance) ...[
                              Text(
                                '  ·  ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                formatPlaceDistance(place.distance!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      FavoritesService.instance.isFavorite(place.name)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 20,
                      color: FavoritesService.instance.isFavorite(place.name)
                          ? Colors.redAccent
                          : cs.onSurfaceVariant,
                    ),
                    onPressed: () async {
                      await FavoritesService.instance.toggle(
                        FavoritePlace(
                          name: place.name,
                          address: place.address,
                          category: place.category,
                          lat: place.lat,
                          lng: place.lng,
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: widget.onClose,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              if (hasDetail || hasPhone) ...[
                const SizedBox(height: 6),
                if (hasDetail)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          place.address,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                if (hasPhone) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse('tel:${place.phone}')),
                    child: Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 14, color: cs.primary),
                        const SizedBox(width: 4),
                        Text(
                          place.phone!,
                          style: TextStyle(fontSize: 12, color: cs.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  PlaceActionButton(
                    icon: Icons.trip_origin,
                    label: '출발',
                    color: cs.primary,
                    onTap: () {
                      widget.onClose();
                      widget.onDeparture(
                        place.name,
                        lat: place.lat,
                        lng: place.lng,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  PlaceActionButton(
                    icon: Icons.place,
                    label: '도착',
                    color: Colors.redAccent,
                    onTap: () {
                      widget.onClose();
                      widget.onArrival(
                        place.name,
                        lat: place.lat,
                        lng: place.lng,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  PlaceActionButton(
                    icon: Icons.info_outline,
                    label: '정보',
                    color: cs.tertiary,
                    onTap: () {
                      if (hasUrl) widget.onShowWebView();
                    },
                  ),
                ],
              ),
              if (hasUrl)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text(
                      '탭하여 사진·리뷰·영업시간 보기',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
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
