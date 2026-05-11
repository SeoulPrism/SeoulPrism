// 멀티플레이어 프로필 아바타 — avatarUrl 있으면 사진, 없으면 색상 원 + 이모지.
// 같은 시각 언어를 profile_view 헤더 / profile_edit_sheet / peer_profile_card
// 어디서나 쓰기 위해 분리.

import 'package:flutter/material.dart';

import '../../models/multiplayer_models.dart';

class ProfileAvatar extends StatelessWidget {
  final MultiplayerProfile? profile;
  /// 프로필 자체가 없을 때 (게스트/익명) fallback 으로 쓰는 이름. 첫 글자 사용.
  final String? fallbackInitial;
  final double size;
  final double emojiSize;
  /// 외곽 테두리 색상 (선택). null 이면 테두리 없음.
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    required this.profile,
    this.fallbackInitial,
    this.size = 80,
    this.emojiSize = 40,
    this.borderColor,
    this.borderWidth = 1.5,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = profile;
    final hasUrl = (p?.avatarUrl ?? '').isNotEmpty;

    final inner = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: hasUrl
            ? _NetworkAvatar(
                url: p!.avatarUrl!,
                fallback: _emojiOrInitial(p, cs),
              )
            : _emojiOrInitial(p, cs),
      ),
    );

    final decorated = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: borderWidth),
      ),
      child: inner,
    );

    if (onTap == null) return decorated;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: decorated,
    );
  }

  Widget _emojiOrInitial(MultiplayerProfile? p, ColorScheme cs) {
    if (p != null) {
      return Container(
        color: p.safePinColor,
        alignment: Alignment.center,
        child: Text(p.pinEmoji, style: TextStyle(fontSize: emojiSize)),
      );
    }
    final initial = (fallbackInitial ?? '').trim();
    if (initial.isEmpty) {
      return Container(
        color: cs.secondaryContainer,
        alignment: Alignment.center,
        child: Icon(Icons.person_rounded,
            size: emojiSize, color: cs.onSecondaryContainer),
      );
    }
    return Container(
      color: cs.secondaryContainer,
      alignment: Alignment.center,
      child: Text(
        initial.characters.first.toUpperCase(),
        style: TextStyle(
          fontSize: emojiSize * 0.85,
          fontWeight: FontWeight.w800,
          color: cs.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _NetworkAvatar extends StatelessWidget {
  final String url;
  final Widget fallback;
  const _NetworkAvatar({required this.url, required this.fallback});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      loadingBuilder: (_, child, prog) {
        if (prog == null) return child;
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      // 네트워크 실패 / 만료된 URL — 이모지 fallback 으로 우아하게 회귀.
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
