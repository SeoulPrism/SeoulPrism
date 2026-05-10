import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../services/seoul_tourism_service.dart';

/// 여행 (Day Plan) 바텀시트 패널.
/// 위쪽: 일정 만들기 액션 두 개 (AI / 저장 장소).
/// 아래쪽: "여행 영감" — 서울 문화행사 세로 리스트.
class TravelPanel extends StatefulWidget {
  final VoidCallback onUseAi;
  final VoidCallback onUseSaved;
  final VoidCallback onClose;

  const TravelPanel({
    super.key,
    required this.onUseAi,
    required this.onUseSaved,
    required this.onClose,
  });

  @override
  State<TravelPanel> createState() => _TravelPanelState();
}

class _TravelPanelState extends State<TravelPanel> {
  final _tourism = SeoulTourismService.instance;
  List<CulturalEvent> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    if (mounted) setState(() => _loading = true);
    final events = await _tourism.getEvents(limit: 20, forceRefresh: force);
    if (!mounted) return;
    setState(() {
      _events = events;
      _loading = false;
    });
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
                SliverToBoxAdapter(child: const SizedBox(height: 18)),
                SliverToBoxAdapter(
                  child: _HeroAction(
                    onTap: widget.onUseAi,
                  ),
                ),
                SliverToBoxAdapter(child: const SizedBox(height: 10)),
                SliverToBoxAdapter(
                  child: _SecondaryAction(
                    onTap: widget.onUseSaved,
                    txtPrimary: txtPrimary,
                    txtMuted: txtMuted,
                  ),
                ),
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
            '여행',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: txtPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '경복궁부터 한강 야경까지, 하루 코스를 짜드려요',
            style: AppTypography.bodySm.copyWith(
              color: txtMuted,
              height: 1.4,
            ),
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
                  '여행 영감',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: txtPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '서울에서 진행 중인 문화행사',
                  style: AppTypography.caption.copyWith(color: txtMuted),
                ),
              ],
            ),
          ),
          if (_events.isNotEmpty)
            Text(
              '${_events.length}개',
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
            '행사 정보를 불러오지 못했어요. 아래로 당겨서 다시 시도해 주세요.',
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
                    const Text(
                      'AI 가 일정을 짜드려요',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '시간 · 날씨 · 동선 자동 고려',
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
                      '저장한 장소로 만들기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: txtPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '즐겨찾기 + 방문 기록 기반 동선',
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
                        _Tag(label: '진행 중', color: Colors.green),
                      if (event.isFree)
                        _Tag(label: '무료', color: Colors.teal),
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
