import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../data/travel_themes.dart';
import '../../../services/environment_service.dart';
import '../../../services/spotify_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../data/travel_styles.dart';
import '../../../services/seoul_tourism_service.dart';
import '../../../services/settings_service.dart';

/// 여행 (Day Plan) 바텀시트 패널.
/// 위→아래: AI/저장 액션 → 테마 추천 8장(가로 스와이프) → Spotify 분위기(연결 시) → 이번 주 이벤트.
class TravelPanel extends StatefulWidget {
  final VoidCallback onUseAi;
  final VoidCallback onUseSaved;
  final VoidCallback onClose;
  final ValueChanged<TravelTheme> onUseTheme;

  const TravelPanel({
    super.key,
    required this.onUseAi,
    required this.onUseSaved,
    required this.onClose,
    required this.onUseTheme,
  });

  @override
  State<TravelPanel> createState() => _TravelPanelState();
}

class _TravelPanelState extends State<TravelPanel> {
  final _tourism = SeoulTourismService.instance;
  final _spotify = SpotifyService.instance;
  List<CulturalEvent> _events = [];
  bool _loading = true;

  /// 사용자가 튜토리얼에서 고른 무드. 'mixed' 와 빈값은 굳이 노출 안 함.
  TravelStyle? get _userStyle {
    final s = travelStyleByKey(
      SettingsService.instance.getString(kTravelStylePrefKey),
    );
    if (s == null || s.key == 'mixed') return null;
    return s;
  }

  @override
  void initState() {
    super.initState();
    _load();
    _spotify.addListener(_onSpotifyChanged);
  }

  @override
  void dispose() {
    _spotify.removeListener(_onSpotifyChanged);
    super.dispose();
  }

  void _onSpotifyChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load({bool force = false}) async {
    if (mounted) setState(() => _loading = true);
    final events = await _tourism.getEvents(limit: 6, forceRefresh: force);
    if (!mounted) return;
    setState(() {
      _events = events;
      _loading = false;
    });
  }

  /// 시간대/날씨/사용자 스타일로 테마 정렬: 매칭 시 상단으로.
  /// 사용자 스타일 (튜토리얼 AI 파트에서 선택) 매칭이 가장 강한 신호.
  List<TravelTheme> _sortedThemes() {
    final env = EnvironmentService.instance.current;
    final hour = DateTime.now().hour;
    final weather = env?.weather;
    final style = SettingsService.instance.getString(kTravelStylePrefKey);

    int score(TravelTheme t) {
      var s = 0;
      if (t.bestHours != null && t.bestHours!.contains(hour)) s += 10;
      if (weather != null &&
          t.bestWeather != null &&
          t.bestWeather!.contains(weather)) {
        s += 20;
      }
      // 스타일 매칭 (+40, 가장 강한 가중치)
      if (_themeMatchesStyle(t.id, style)) s += 40;
      return s;
    }

    final list = [...kTravelThemes];
    list.sort((a, b) => score(b).compareTo(score(a)));
    return list;
  }

  /// 사용자 스타일에 매칭되는 테마인지. mixed/빈값 → 모두 false.
  bool _themeMatchesStyle(String themeId, String style) {
    final s = travelStyleByKey(style);
    if (s == null) return false;
    return s.matchingThemeIds.contains(themeId);
  }

  Future<void> _open(CulturalEvent e) async {
    final raw = e.homepageUrl ?? e.orgLink;
    if (raw == null) return;
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isM3 = Platform.isAndroid;
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final txtPrimary = isM3
        ? cs.onSurface
        : (isLight ? const Color(0xFF1C1C1E) : Colors.white);
    final txtMuted = isM3
        ? cs.onSurfaceVariant
        : (isLight
            ? const Color(0xFF6E6E73)
            : Colors.white.withValues(alpha: 0.55));

    final content = Column(
      children: [
        // 드래그 핸들
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: txtMuted.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _load(force: true),
            color: AppColors.accent,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(txtPrimary, txtMuted)),
                SliverToBoxAdapter(child: const SizedBox(height: 14)),
                // 1. 당신의 테마 — 최상단 히어로. 골랐을 때만 노출 (mixed 제외).
                //    헤더 없이 카드 자체가 시그니처: "당신의 테마" 라벨이 카드 안에 박힘.
                if (_userStyle != null) ...[
                  SliverToBoxAdapter(
                    child: _UserStyleCard(
                      style: _userStyle!,
                      txtPrimary: txtPrimary,
                      txtMuted: txtMuted,
                      onTap: () {
                        final match = _sortedThemes().firstWhere(
                          (t) => _userStyle!.matchingThemeIds.contains(t.id),
                          orElse: () => _sortedThemes().first,
                        );
                        widget.onUseTheme(match);
                      },
                    ),
                  ),
                  SliverToBoxAdapter(child: const SizedBox(height: 16)),
                ],
                // 2. AI / 저장 액션 — 사용자 정의 코스 생성.
                SliverToBoxAdapter(
                  child: _HeroAction(
                    onTap: widget.onUseAi,
                  ),
                ),
                SliverToBoxAdapter(child: const SizedBox(height: 8)),
                SliverToBoxAdapter(
                  child: _SecondaryAction(
                    onTap: widget.onUseSaved,
                    txtPrimary: txtPrimary,
                    txtMuted: txtMuted,
                  ),
                ),
                SliverToBoxAdapter(child: const SizedBox(height: 26)),
                // 3. 큐레이션 테마 — 8개 미리 만들어둔 코스.
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    title: AppL10n.of(context).travelThemeTitle,
                    subtitle: AppL10n.of(context).travelThemeSubtitle,
                    txtPrimary: txtPrimary,
                    txtMuted: txtMuted,
                  ),
                ),
                SliverToBoxAdapter(child: const SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: _ThemeCarousel(
                    themes: _sortedThemes(),
                    onTap: widget.onUseTheme,
                  ),
                ),
                if (_spotify.isConnected && _spotify.currentTrack != null) ...[
                  SliverToBoxAdapter(child: const SizedBox(height: 24)),
                  SliverToBoxAdapter(
                    child: _SpotifyMoodTile(
                      track: _spotify.currentTrack!,
                      txtPrimary: txtPrimary,
                      txtMuted: txtMuted,
                      onUseTheme: widget.onUseTheme,
                    ),
                  ),
                ],
                SliverToBoxAdapter(child: const SizedBox(height: 28)),
                SliverToBoxAdapter(
                  child: _buildInspirationHeader(txtPrimary, txtMuted),
                ),
                SliverToBoxAdapter(child: const SizedBox(height: 10)),
                _buildEventSliver(txtPrimary, txtMuted),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (isM3) {
      return Material(
        elevation: 6,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        color: cs.surfaceContainerHigh,
        surfaceTintColor: cs.surfaceTint,
        clipBehavior: Clip.antiAlias,
        child: content,
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          decoration: BoxDecoration(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isLight
                  ? [
                      Colors.white.withValues(alpha: 0.70),
                      Colors.white.withValues(alpha: 0.78),
                      Colors.white.withValues(alpha: 0.88),
                    ]
                  : [
                      Colors.black.withValues(alpha: 0.40),
                      Colors.black.withValues(alpha: 0.52),
                      Colors.black.withValues(alpha: 0.68),
                    ],
            ),
            border: Border(
              top: BorderSide(
                color: (isLight ? Colors.black : Colors.white)
                    .withValues(alpha: 0.10),
                width: 0.5,
              ),
            ),
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildHeader(Color txtPrimary, Color txtMuted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppL10n.of(context).travelTitle,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: txtPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppL10n.of(context).travelSubtitle,
            style: AppTypography.bodySm.copyWith(
              color: txtMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required Color txtPrimary,
    required Color txtMuted,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: txtPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(color: txtMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildInspirationHeader(Color txtPrimary, Color txtMuted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppL10n.of(context).travelEventsTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: txtPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppL10n.of(context).travelEventsSubtitle,
                  style: AppTypography.caption.copyWith(color: txtMuted),
                ),
              ],
            ),
          ),
          if (_events.isNotEmpty)
            Text(
              AppL10n.of(context).travelEventsCount(_events.length),
              style: AppTypography.caption
                  .copyWith(color: txtMuted, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }

  Widget _buildEventSliver(Color txtPrimary, Color txtMuted) {
    if (_loading) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 120,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: txtMuted,
              ),
            ),
          ),
        ),
      );
    }
    if (_events.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Text(
            AppL10n.of(context).travelEventsLoadError,
            style: AppTypography.bodySm.copyWith(color: txtMuted, height: 1.5),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList.separated(
        itemCount: _events.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) => _EventTile(
          event: _events[i],
          onTap: () => _open(_events[i]),
          txtPrimary: txtPrimary,
          txtMuted: txtMuted,
        ),
      ),
    );
  }
}

/// 메인 액션 — AI 일정 짜기 (그라데이션 강조).
class _HeroAction extends StatelessWidget {
  final VoidCallback onTap;
  const _HeroAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accent,
                AppColors.accent.withValues(alpha: 0.78),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppL10n.of(context).travelAiTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      AppL10n.of(context).travelAiSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 보조 액션 — 저장 장소로 만들기.
class _SecondaryAction extends StatelessWidget {
  final VoidCallback onTap;
  final Color txtPrimary;
  final Color txtMuted;
  const _SecondaryAction({
    required this.onTap,
    required this.txtPrimary,
    required this.txtMuted,
  });

  @override
  Widget build(BuildContext context) {
    final isM3 = Platform.isAndroid;
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = isM3
        ? cs.surfaceContainerHighest
        : (isLight
            ? Colors.black.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.07));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                Icons.bookmark_outline_rounded,
                size: 22,
                color: txtPrimary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppL10n.of(context).travelFromSavedTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: txtPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppL10n.of(context).travelFromSavedSubtitle,
                      style: AppTypography.caption.copyWith(color: txtMuted),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: txtMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 사용자가 튜토리얼에서 고른 무드 — 여행 패널 최상단 히어로 카드.
/// 자체 헤더 라벨 + 큰 이모지 + CTA 까지 한 카드 안에 다 박혀 있어
/// 별도 섹션 헤더 없이도 독립적으로 시그니처 역할.
class _UserStyleCard extends StatelessWidget {
  final TravelStyle style;
  final Color txtPrimary;
  final Color txtMuted;
  final VoidCallback onTap;
  const _UserStyleCard({
    required this.style,
    required this.txtPrimary,
    required this.txtMuted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c0 = style.palette[0];
    final c1 = style.palette[3];
    final c2 = style.palette[5];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  c0.withValues(alpha: 0.28),
                  c1.withValues(alpha: 0.18),
                  c2.withValues(alpha: 0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: c0.withValues(alpha: 0.55),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: c0.withValues(alpha: 0.22),
                  blurRadius: 22,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 카드 자체에 박힌 작은 라벨 — 섹션 헤더 대신.
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: c0,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: c0.withValues(alpha: 0.7),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppL10n.of(context).travelYourTheme,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: c0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c0.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        style.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            style.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: txtPrimary,
                              height: 1.1,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            style.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: txtMuted,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // CTA hint — 카드 하단.
                Row(
                  children: [
                    Text(
                      AppL10n.of(context).travelStartWithMood,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: c0,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: c0,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 행사 세로 타일 — 큰 썸네일 + 정보.
class _EventTile extends StatelessWidget {
  final CulturalEvent event;
  final VoidCallback onTap;
  final Color txtPrimary;
  final Color txtMuted;
  const _EventTile({
    required this.event,
    required this.onTap,
    required this.txtPrimary,
    required this.txtMuted,
  });

  @override
  Widget build(BuildContext context) {
    final isM3 = Platform.isAndroid;
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = isM3
        ? cs.surfaceContainerHighest.withValues(alpha: 0.6)
        : (isLight
            ? Colors.white.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.05));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (isLight ? Colors.black : Colors.white)
                .withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildImage(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: txtPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (event.place.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: txtMuted,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            event.guName.isNotEmpty
                                ? '${event.guName} · ${event.place}'
                                : event.place,
                            style: TextStyle(
                              fontSize: 11,
                              color: txtMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (event.isOngoing)
                        _Tag(label: AppL10n.of(context).travelEventBadgeOngoing,
                            color: Colors.green),
                      if (event.isFree)
                        _Tag(label: AppL10n.of(context).travelEventBadgeFree,
                            color: Colors.teal),
                      if (event.shortDate.isNotEmpty)
                        Text(
                          event.shortDate,
                          style: TextStyle(
                            fontSize: 10,
                            color: txtMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final placeholder = Container(
      width: 72,
      height: 72,
      color: AppColors.accent.withValues(alpha: 0.12),
      child: Icon(
        Icons.event_rounded,
        size: 28,
        color: AppColors.accent,
      ),
    );
    final url = event.imageUrl;
    if (url == null || !url.startsWith('http')) return placeholder;
    return Image.network(
      url,
      width: 72,
      height: 72,
      fit: BoxFit.cover,
      loadingBuilder: (ctx, child, prog) =>
          prog == null ? child : placeholder,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}

/// 테마 카드 가로 스와이프 리스트.
class _ThemeCarousel extends StatelessWidget {
  final List<TravelTheme> themes;
  final ValueChanged<TravelTheme> onTap;
  const _ThemeCarousel({required this.themes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: themes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _ThemeCard(
          theme: themes[i],
          onTap: () => onTap(themes[i]),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final TravelTheme theme;
  final VoidCallback onTap;
  const _ThemeCard({required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(theme.colorStart), Color(theme.colorEnd)],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(theme.colorStart).withValues(alpha: 0.30),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(theme.emoji, style: const TextStyle(fontSize: 22)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    AppL10n.of(context).travelThemeStops(theme.stops.length),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              theme.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              theme.subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.92),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Spotify 현재 트랙 → 분위기 매칭 한 줄 추천.
class _SpotifyMoodTile extends StatefulWidget {
  final SpotifyTrack track;
  final Color txtPrimary;
  final Color txtMuted;
  final ValueChanged<TravelTheme> onUseTheme;
  const _SpotifyMoodTile({
    required this.track,
    required this.txtPrimary,
    required this.txtMuted,
    required this.onUseTheme,
  });

  @override
  State<_SpotifyMoodTile> createState() => _SpotifyMoodTileState();
}

class _SpotifyMoodTileState extends State<_SpotifyMoodTile> {
  SpotifyAudioFeatures? _features;
  TravelTheme? _matched;
  String? _lastFetchedTrackId;

  @override
  void initState() {
    super.initState();
    _fetchAndMatch();
  }

  @override
  void didUpdateWidget(covariant _SpotifyMoodTile old) {
    super.didUpdateWidget(old);
    if (old.track.trackId != widget.track.trackId) {
      _features = null;
      _matched = null;
      _fetchAndMatch();
    }
  }

  Future<void> _fetchAndMatch() async {
    final id = widget.track.trackId;
    if (id == null || id == _lastFetchedTrackId) {
      // trackId 없으면 키워드 fallback 만으로 매칭.
      setState(() => _matched = _matchByKeywords());
      return;
    }
    _lastFetchedTrackId = id;
    final f = await SpotifyService.instance.getAudioFeatures(id);
    if (!mounted) return;
    setState(() {
      _features = f;
      _matched = f != null ? _matchByFeatures(f) : _matchByKeywords();
    });
  }

  /// valence×energy 4분면 + danceability 가중치로 kTravelThemes 매칭.
  TravelTheme _matchByFeatures(SpotifyAudioFeatures f) {
    final highValence = f.valence >= 0.5;
    final highEnergy = f.energy >= 0.5;
    String preferredId;
    if (highValence && highEnergy) {
      // 신나는 기분 — K팝 / 한강 / 카페
      preferredId = f.danceability > 0.6 ? 'kpop' : 'hangang_wind';
    } else if (highValence && !highEnergy) {
      // 차분한 행복 — 카페 / 궁궐
      preferredId = f.tempo < 110 ? 'palace_walk' : 'cafe_hop';
    } else if (!highValence && highEnergy) {
      // 격렬한 어두움 — 야경
      preferredId = 'night_view';
    } else {
      // 우울하고 차분 — 우중 실내 / 야경
      preferredId = f.energy < 0.3 ? 'rainy_indoor' : 'night_view';
    }
    return kTravelThemes.firstWhere(
      (t) => t.id == preferredId,
      orElse: () => kTravelThemes.first,
    );
  }

  /// Audio Features 미연동 fallback — 곡명 키워드 기반.
  TravelTheme _matchByKeywords() {
    final t = '${widget.track.name} ${widget.track.artist}'.toLowerCase();
    String id;
    if (t.contains('night') ||
        t.contains('밤') ||
        t.contains('moon') ||
        t.contains('야')) {
      id = 'night_view';
    } else if (t.contains('rain') || t.contains('비')) {
      id = 'rainy_indoor';
    } else if (t.contains('summer') ||
        t.contains('여름') ||
        t.contains('beach')) {
      id = 'hangang_wind';
    } else if (t.contains('coffee') ||
        t.contains('cafe') ||
        t.contains('lofi')) {
      id = 'cafe_hop';
    } else if (t.contains('love') || t.contains('사랑')) {
      id = 'palace_walk';
    } else if (t.contains('food') || t.contains('맛')) {
      id = 'foodie_day';
    } else {
      id = 'hangang_wind';
    }
    return kTravelThemes.firstWhere(
      (x) => x.id == id,
      orElse: () => kTravelThemes.first,
    );
  }

  String _suggestionLine(BuildContext ctx) {
    final l = AppL10n.of(ctx);
    final theme = _matched;
    if (theme == null) return l.travelMoodAnalyzing;
    final f = _features;
    if (f == null) return '${theme.emoji} ${theme.title}';
    // valence 별 톤 다르게.
    final tone = f.valence >= 0.6
        ? l.travelMoodExcited
        : f.valence >= 0.4
            ? l.travelMoodToday
            : f.energy >= 0.6
                ? l.travelMoodIntense
                : l.travelMoodCalm;
    return '$tone ${theme.emoji} ${theme.title}';
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    final txtPrimary = widget.txtPrimary;
    final txtMuted = widget.txtMuted;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = isLight
        ? Colors.black.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.06);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _matched == null
              ? null
              : () => widget.onUseTheme(_matched!),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF1DB954).withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: track.albumImageUrl != null
                      ? Image.network(
                          track.albumImageUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _albumPlaceholder(),
                        )
                      : _albumPlaceholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.music_note_rounded,
                            size: 12,
                            color: Color(0xFF1DB954),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            AppL10n.of(context).travelTodayMoodLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1DB954),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _suggestionLine(context),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: txtPrimary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${track.name} · ${track.artist}',
                        style: TextStyle(fontSize: 10, color: txtMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _albumPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      color: const Color(0xFF1DB954).withValues(alpha: 0.18),
      child: const Icon(
        Icons.music_note_rounded,
        color: Color(0xFF1DB954),
        size: 22,
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
