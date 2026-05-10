import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../services/seoul_tourism_service.dart';

/// 여행 (Day Plan) 바텀시트 패널.
/// 상단: 서울 문화행사 가로 카드 슬라이더 (영감용).
/// 하단: 일정 생성 CTA — AI / 저장 장소.
class TravelPanel extends StatefulWidget {
  /// AI 모드 진입 (일정 생성 — Gemini).
  final VoidCallback onUseAi;

  /// 즐겨찾기 / 방문 기록 기반 일정 생성.
  final VoidCallback onUseSaved;

  /// 패널 닫기.
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

  Future<void> _load() async {
    final events = await _tourism.getEvents(limit: 12);
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
          padding: const EdgeInsets.only(top: 12),
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
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '여행',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: txtPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '하루 코스를 만들어 지도에 표시해 드려요',
                style: AppTypography.bodySm.copyWith(
                  color: txtMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 서울 행사 가로 슬라이더
              _SectionHeader(
                title: '서울 가볼만한 곳',
                subtitle: '이번주 진행 중인 문화행사',
                textColor: txtPrimary,
                mutedColor: txtMuted,
              ),
              const SizedBox(height: 10),
              _buildEventCarousel(txtPrimary, txtMuted),
              const Spacer(),
              // CTA — 하단 고정
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: [
                    _Cta(
                      icon: Icons.auto_awesome,
                      label: 'AI 가 추천해줘요',
                      subtitle: 'Gemini 가 시간/날씨 고려해 자동 생성',
                      onTap: widget.onUseAi,
                      primary: true,
                    ),
                    const SizedBox(height: 10),
                    _Cta(
                      icon: Icons.bookmark_outline_rounded,
                      label: '내 저장 장소로 만들기',
                      subtitle: '즐겨찾기 + 방문 기록 기반 동선 자동 생성',
                      onTap: widget.onUseSaved,
                      primary: false,
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 16),
                  ],
                ),
              ),
            ],
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
                      Colors.white.withValues(alpha: 0.75),
                      Colors.white.withValues(alpha: 0.85),
                    ]
                  : [
                      Colors.black.withValues(alpha: 0.40),
                      Colors.black.withValues(alpha: 0.50),
                      Colors.black.withValues(alpha: 0.65),
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

  Widget _buildEventCarousel(Color txtPrimary, Color txtMuted) {
    if (_loading) {
      return SizedBox(
        height: 180,
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
      );
    }
    if (_events.isEmpty) {
      return SizedBox(
        height: 60,
        child: Center(
          child: Text(
            '행사 정보를 불러오지 못했어요.',
            style: AppTypography.caption.copyWith(color: txtMuted),
          ),
        ),
      );
    }
    return SizedBox(
      height: 200,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: _events.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) =>
            _EventCard(event: _events[i], onTap: () => _open(_events[i])),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color textColor;
  final Color mutedColor;
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(color: mutedColor),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CulturalEvent event;
  final VoidCallback onTap;
  const _EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cs = Theme.of(context).colorScheme;
    final isM3 = Platform.isAndroid;
    final bg = isM3
        ? cs.surfaceContainerHighest
        : (isLight
            ? Colors.white.withValues(alpha: 0.65)
            : Colors.white.withValues(alpha: 0.08));
    final txtPrimary = isM3
        ? cs.onSurface
        : (isLight ? const Color(0xFF1C1C1E) : Colors.white);
    final txtMuted = isM3
        ? cs.onSurfaceVariant
        : (isLight
            ? const Color(0xFF6E6E73)
            : Colors.white.withValues(alpha: 0.55));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (isLight ? Colors.black : Colors.white)
                .withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: _buildImage(isLight),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: txtPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (event.guName.isNotEmpty)
                      Text(
                        event.guName,
                        style:
                            TextStyle(fontSize: 10, color: txtMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (event.isOngoing)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '진행 중',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        if (event.isOngoing) const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.shortDate,
                            style: TextStyle(fontSize: 9, color: txtMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(bool isLight) {
    final placeholder = Container(
      width: 160,
      height: 100,
      color: AppColors.accent.withValues(alpha: 0.12),
      child: Icon(
        Icons.event_rounded,
        size: 36,
        color: AppColors.accent,
      ),
    );
    final url = event.imageUrl;
    if (url == null || !url.startsWith('http')) return placeholder;
    return Image.network(
      url,
      width: 160,
      height: 100,
      fit: BoxFit.cover,
      loadingBuilder: (ctx, child, prog) =>
          prog == null ? child : placeholder,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}

class _Cta extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool primary;
  const _Cta({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isM3 = Platform.isAndroid;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final bg = primary
        ? AppColors.accent.withValues(alpha: 0.16)
        : (isM3
            ? cs.surfaceContainerHighest
            : (isLight
                ? Colors.black.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.08)));
    final iconColor = primary
        ? AppColors.accent
        : (isM3 ? cs.onSurface : (isLight ? Colors.black87 : Colors.white));
    final labelColor = primary
        ? AppColors.accent
        : (isM3 ? cs.onSurface : (isLight ? Colors.black87 : Colors.white));
    final subColor = isM3
        ? cs.onSurfaceVariant
        : (isLight
            ? const Color(0xFF6E6E73)
            : Colors.white.withValues(alpha: 0.55));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: primary
              ? Border.all(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodyMd.copyWith(
                      color: labelColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(color: subColor),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: subColor,
            ),
          ],
        ),
      ),
    );
  }
}
