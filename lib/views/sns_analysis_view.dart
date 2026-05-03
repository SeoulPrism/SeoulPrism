import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/sns_content_models.dart';
import '../services/day_plan_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../widgets/adaptive/adaptive.dart';
import '../core/map_interface.dart';
import 'day_plan_view.dart';

class SnsAnalysisView extends StatefulWidget {
  final SnsAnalysisResult result;
  final IMapController? mapController;
  final void Function(List<DayPlan> plans)? onPlansGenerated;

  const SnsAnalysisView({
    super.key,
    required this.result,
    this.mapController,
    this.onPlansGenerated,
  });

  @override
  State<SnsAnalysisView> createState() => _SnsAnalysisViewState();
}

class _SnsAnalysisViewState extends State<SnsAnalysisView> {
  late List<ExtractedPlace> _places;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _places = List.from(widget.result.places);
    _showMarkersOnMap();
  }

  void _showMarkersOnMap() {
    final mc = widget.mapController;
    if (mc == null) return;
    mc.clearCircleMarkers();
    for (int i = 0; i < _places.length; i++) {
      final p = _places[i];
      if (p.hasCoordinates) {
        mc.addCircleMarker(
          'analysis_$i', p.lat!, p.lng!,
          color: _categoryColor(p.category),
          radius: 10,
          strokeColor: Colors.white,
          strokeWidth: 2,
        );
      }
    }
  }

  void _removePlace(int index) {
    setState(() => _places.removeAt(index));
    _showMarkersOnMap();
  }

  Future<void> _generatePlans() async {
    if (_places.isEmpty || _loading) return;
    setState(() => _loading = true);

    try {
      final plans = await DayPlanService.instance.generatePlans(_places);
      if (!mounted) return;

      // 지도 위 오버레이로 표시
      Navigator.of(context).pop(); // 분석 뷰 닫기
      widget.onPlansGenerated?.call(plans);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('플랜 생성 실패: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _categoryColor(String category) {
    return switch (category) {
      '맛집' => Colors.orange,
      '카페' => Colors.brown,
      '관광' => Colors.blue,
      '쇼핑' => Colors.pink,
      '문화' => Colors.purple,
      '자연' => Colors.green,
      _ => AppColors.accent,
    };
  }

  IconData _categoryIcon(String category) {
    return switch (category) {
      '맛집' => Icons.restaurant,
      '카페' => Icons.coffee,
      '관광' => Icons.photo_camera,
      '쇼핑' => Icons.shopping_bag,
      '문화' => Icons.museum,
      '자연' => Icons.park,
      _ => Icons.place,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const isM3 = true;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: isM3 ? cs.surface : const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '분석 결과',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isM3 ? cs.onSurface : Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 분위기 헤더
          if (widget.result.overallMood.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: AdaptiveSurfaceCard(
                borderRadius: 16,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.result.overallMood,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isM3 ? cs.onSurface : Colors.white,
                      ),
                    ),
                    if (widget.result.keywords.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: widget.result.keywords.map((k) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isM3
                                  ? cs.secondaryContainer
                                  : AppColors.accent.withValues(alpha: 0.15),
                            ),
                            child: Text(
                              '#$k',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isM3 ? cs.onSecondaryContainer : AppColors.accent,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // 장소 리스트
          Expanded(
            child: _places.isEmpty
                ? Center(
                    child: Text(
                      '추출된 장소가 없습니다',
                      style: TextStyle(color: isM3 ? cs.onSurfaceVariant : Colors.white60),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: _places.length,
                    itemBuilder: (context, index) {
                      return _buildPlaceItem(index, isM3, cs);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            height: 52,
            child: _loading
                ? Center(
                    child: Platform.isIOS
                        ? const CupertinoActivityIndicator()
                        : const CircularProgressIndicator(),
                  )
                : AdaptiveGlassButton(
                    label: '일정 만들기 (${_places.length}곳)',
                    onPressed: _places.isNotEmpty ? _generatePlans : null,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceItem(int index, bool isM3, ColorScheme cs) {
    final place = _places[index];
    final color = _categoryColor(place.category);
    final icon = _categoryIcon(place.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey('${place.name}_$index'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _removePlace(index),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.red.withValues(alpha: 0.2),
          ),
          child: const Icon(Icons.delete, color: Colors.red),
        ),
        child: AdaptiveSurfaceCard(
          borderRadius: 16,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 번호 + 카테고리 아이콘
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: isM3 ? 0.15 : 0.2),
                ),
                child: Center(
                  child: Icon(icon, size: 20, color: color),
                ),
              ),
              const SizedBox(width: 12),
              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isM3 ? cs.onSurface : Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: color.withValues(alpha: 0.15),
                          ),
                          child: Text(
                            place.category,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.activity,
                      style: TextStyle(
                        fontSize: 13,
                        color: isM3 ? cs.onSurfaceVariant : Colors.white70,
                      ),
                    ),
                    if (place.nearestStation != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '📍 ${place.nearestStation}역 · ${place.estimatedMinutes}분',
                        style: TextStyle(
                          fontSize: 11,
                          color: isM3 ? cs.onSurfaceVariant.withValues(alpha: 0.7) : Colors.white38,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
