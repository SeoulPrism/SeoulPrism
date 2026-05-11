import 'dart:io';
import 'package:flutter/material.dart';
import '../../../data/travel_styles.dart';
import '../../../services/settings_service.dart';
import '../../../theme/app_typography.dart';
import '../../ai_mode_view.dart';
import '../widgets/page_card.dart';

/// 튜토리얼 AI 파트. 4개 여행 스타일 카드가 위로 떠오르고,
/// 사용자가 하나를 누르면 AI 글로우 팔레트가 그 스타일에 맞춰 변함.
class PathfindingPage extends StatefulWidget {
  static const id = 'pathfinding_v1';
  const PathfindingPage({super.key});

  @override
  State<PathfindingPage> createState() => _PathfindingPageState();
}

class _PathfindingPageState extends State<PathfindingPage>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _paletteCtrl;
  String? _selected; // 'chill' | 'play' | 'history' | 'mixed'
  List<Color>? _fromPalette;
  List<Color>? _toPalette;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _paletteCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // 이전 세션에서 선택한 스타일이 있으면 복원
    final saved = SettingsService.instance.getString(kTravelStylePrefKey);
    final restored = travelStyleByKey(saved);
    if (restored != null) {
      _selected = restored.key;
      _toPalette = restored.palette;
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _paletteCtrl.dispose();
    super.dispose();
  }

  void _select(TravelStyle spec) {
    if (_selected == spec.key) return;
    setState(() {
      _fromPalette = _toPalette ?? kDefaultStylePalette;
      _toPalette = spec.palette;
      _selected = spec.key;
    });
    SettingsService.instance.setString(kTravelStylePrefKey, spec.key);
    _paletteCtrl
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isIos = Platform.isIOS;
    final titleColor = isIos ? Colors.white : cs.onSurface;
    final bodyColor =
        isIos ? Colors.white.withValues(alpha: 0.78) : cs.onSurfaceVariant;

    return AnimatedBuilder(
      animation: _paletteCtrl,
      builder: (context, _) {
        final palette = _fromPalette == null || _toPalette == null
            ? _toPalette // 첫 적용 (보간 없음)
            : lerpPalette(_fromPalette!, _toPalette!, _paletteCtrl.value);

        return Stack(
          children: [
            Positioned.fill(child: AiModeView(palette: palette)),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: PageCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '오늘은 어떤 여행?',
                        style: AppTypography.displayLg.copyWith(
                          color: titleColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'AI 비서가 너의 무드에 맞춰 코스를 짜줄게.\n나중에 언제든 바꿀 수 있어.',
                        style: AppTypography.bodyMd.copyWith(
                          color: bodyColor,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _StyleGrid(
                        selected: _selected,
                        entry: _entryCtrl,
                        onSelect: _select,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 4개 스타일 카드 (2x2 그리드, 스태거 entry)
// ─────────────────────────────────────────────────────────────────

class _StyleGrid extends StatelessWidget {
  final String? selected;
  final AnimationController entry;
  final void Function(TravelStyle) onSelect;
  const _StyleGrid({
    required this.selected,
    required this.entry,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int row = 0; row < 2; row++) ...[
          Row(
            children: [
              for (int col = 0; col < 2; col++) ...[
                Expanded(
                  child: _AnimatedRise(
                    index: row * 2 + col,
                    entry: entry,
                    child: _StyleCard(
                      spec: kTravelStyles[row * 2 + col],
                      selected: selected == kTravelStyles[row * 2 + col].key,
                      onTap: () => onSelect(kTravelStyles[row * 2 + col]),
                    ),
                  ),
                ),
                if (col == 0) const SizedBox(width: 10),
              ],
            ],
          ),
          if (row == 0) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// 카드 하나가 아래에서 위로 떠오르는 entry 애니메이션 — index 마다 스태거.
class _AnimatedRise extends StatelessWidget {
  final int index;
  final AnimationController entry;
  final Widget child;
  const _AnimatedRise({
    required this.index,
    required this.entry,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.12).clamp(0.0, 0.7);
    final end = (start + 0.55).clamp(0.0, 1.0);
    final curve = CurvedAnimation(
      parent: entry,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curve,
      child: child, // 필드를 미리 캐시 — AnimatedBuilder 가 매 틱마다 재빌드하지 않음
      builder: (_, inner) {
        final v = curve.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 24),
            child: inner,
          ),
        );
      },
    );
  }
}

class _StyleCard extends StatelessWidget {
  final TravelStyle spec;
  final bool selected;
  final VoidCallback onTap;
  const _StyleCard({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIos = Platform.isIOS;
    final cs = Theme.of(context).colorScheme;
    final accent = spec.palette[0];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: isIos ? 0.22 : 0.18)
                : (isIos
                    ? Colors.white.withValues(alpha: 0.07)
                    : cs.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.85)
                  : (isIos
                      ? Colors.white.withValues(alpha: 0.14)
                      : cs.outlineVariant.withValues(alpha: 0.5)),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(spec.emoji, style: const TextStyle(fontSize: 22)),
                  if (selected)
                    Icon(Icons.check_circle, size: 16, color: accent),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                spec.title,
                style: AppTypography.bodyMd.copyWith(
                  color: isIos ? Colors.white : cs.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                spec.subtitle,
                style: AppTypography.bodySm.copyWith(
                  color: isIos
                      ? Colors.white.withValues(alpha: 0.68)
                      : cs.onSurfaceVariant,
                  fontSize: 11,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 스타일 정의는 lib/data/travel_styles.dart 로 이동 — AI 서비스/여행 패널/추천 탭이 공유.
