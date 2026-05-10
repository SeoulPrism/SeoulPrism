import 'package:flutter/material.dart';

import '../../models/multiplayer_models.dart';
import '../../services/multiplayer_service.dart';
import '../../widgets/adaptive/adaptive.dart';

/// 멀티플레이어 프로필 편집 — 닉네임/핀색상/이모지/가시성/출생연도.
class MultiplayerProfileEditSheet extends StatefulWidget {
  const MultiplayerProfileEditSheet({super.key});

  static Future<MultiplayerProfile?> show(BuildContext context) {
    return showModalBottomSheet<MultiplayerProfile>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const MultiplayerProfileEditSheet(),
    );
  }

  @override
  State<MultiplayerProfileEditSheet> createState() =>
      _MultiplayerProfileEditSheetState();
}

class _MultiplayerProfileEditSheetState
    extends State<MultiplayerProfileEditSheet> {
  late TextEditingController _nicknameCtrl;
  late TextEditingController _birthYearCtrl;
  String _pinColor = '#7C5CFF';
  String _pinEmoji = '📍';
  // 기본값을 friends 로 — ghost 는 의도적으로 비공개를 원하는 사용자가 직접 선택.
  String _visibility = 'friends';
  bool _saving = false;
  String? _error;

  static const _emojiPalette = [
    '📍', '🦊', '🐻', '🐼', '🐯', '🦁', '🐸', '🐧',
    '🐳', '🦋', '🌸', '⭐', '🌙', '🔥', '⚡', '🎯',
  ];
  static const _colorPalette = [
    '#7C5CFF', '#FF5C8D', '#5CC8FF', '#FFB05C',
    '#5CFFB0', '#B05CFF', '#FF5C5C', '#5C8DFF',
  ];

  @override
  void initState() {
    super.initState();
    final p = MultiplayerService.instance.myProfile;
    _nicknameCtrl = TextEditingController(text: p?.nickname ?? '');
    _birthYearCtrl =
        TextEditingController(text: p?.birthYear.toString() ?? '');
    if (p != null) {
      _pinColor = p.pinColor;
      _pinEmoji = p.pinEmoji;
      _visibility = p.visibility;
    }
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _birthYearCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nickname = _nicknameCtrl.text.trim();
    final birthYearStr = _birthYearCtrl.text.trim();

    if (nickname.isEmpty || nickname.length > 20) {
      setState(() => _error = '닉네임은 1~20자로 입력해주세요.');
      return;
    }
    final birthYear = int.tryParse(birthYearStr);
    if (birthYear == null ||
        birthYear < 1900 ||
        birthYear > DateTime.now().year) {
      setState(() => _error = '출생연도(YYYY) 를 정확히 입력해주세요.');
      return;
    }
    if (DateTime.now().year - birthYear < MultiplayerService.kMinAgeYears) {
      setState(() => _error = '14세 미만은 멀티플레이를 이용할 수 없습니다.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final wasFirstProfile = MultiplayerService.instance.myProfile == null;
      final profile = await MultiplayerService.instance.upsertMyProfile(
        nickname: nickname,
        birthYear: birthYear,
        pinColor: _pinColor,
        pinEmoji: _pinEmoji,
        visibility: _visibility,
      );
      if (!mounted) return;
      if (wasFirstProfile) {
        // 첫 가입 — Seoul Live 활성화 + 메인 지도로 복귀해 인트로/튜토리얼 노출.
        Navigator.of(context).popUntil((r) => r.isFirst);
      } else {
        Navigator.pop(context, profile);
      }
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, bottomInset + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('프로필 설정',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface)),
            const SizedBox(height: 4),
            Text('친구방에서 다른 사람에게 보여질 모습을 정해주세요.',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            const SizedBox(height: 24),

            _Label(text: '닉네임 (중복 허용)'),
            AdaptiveTextField(
              controller: _nicknameCtrl,
              placeholder: '예: 서울탐험가',
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            const SizedBox(height: 18),

            _Label(text: '출생연도 (만 14세 이상만 가입)'),
            AdaptiveTextField(
              controller: _birthYearCtrl,
              placeholder: '예: 2000',
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            const SizedBox(height: 18),

            _Label(text: '핀 이모지'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojiPalette.map((e) {
                final selected = e == _pinEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _pinEmoji = e),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: selected
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                      border: Border.all(
                        color: selected ? cs.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            _Label(text: '핀 색상'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colorPalette.map((hex) {
                final selected = hex == _pinColor;
                return GestureDetector(
                  onTap: () => setState(() => _pinColor = hex),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hexToColor(hex),
                      border: Border.all(
                        color: selected ? cs.onSurface : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            _Label(text: '위치 공개 범위'),
            AdaptiveSegmented<String>(
              selected: _visibility,
              onSelected: (v) async {
                if (v == 'public' && _visibility != 'public') {
                  // 전체 공개 전환 — 강한 확인 다이얼로그.
                  final ok = await _confirmPublic();
                  if (!ok) return;
                }
                setState(() => _visibility = v);
              },
              segments: const [
                AdaptiveSegment(
                    value: 'ghost', label: '비공개', icon: Icons.visibility_off_rounded),
                AdaptiveSegment(
                    value: 'friends', label: '친구방', icon: Icons.people_alt_rounded),
                AdaptiveSegment(
                    value: 'public', label: '전체 공개', icon: Icons.public_rounded),
              ],
            ),
            const SizedBox(height: 8),
            Text(_visibilityHint(),
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_error!,
                    style:
                        TextStyle(color: cs.onErrorContainer, fontSize: 13)),
              ),
            ],

            const SizedBox(height: 28),
            AdaptiveGlassButton(
              label: _saving ? '저장 중...' : '저장',
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmPublic() async {
    bool result = false;
    await showAdaptiveConfirmDialog(
      context: context,
      title: '전체 공개로 전환',
      content: '내 위치가 모르는 사람을 포함한 모든 Seoul Live 사용자에게 '
          '실시간으로 보여집니다.\n\n'
          '• 부적절한 만남 / 스토킹 위험에 유의하세요\n'
          '• 언제든 비공개/친구방으로 되돌릴 수 있어요\n'
          '• 차단/신고는 친구 프로필 또는 채팅 메뉴에서',
      confirmText: '계속',
      isDestructive: true,
      onConfirm: () {
        result = true;
      },
    );
    return result;
  }

  String _visibilityHint() => switch (_visibility) {
        'ghost' => '위치를 보내지 않습니다. 다른 사람의 위치도 볼 수 없어요.',
        'friends' => '친구방에 입장한 동안만 같은 방 멤버에게 위치가 보여요.',
        'public' => '⚠️ Seoul Live 사용자 누구나 내 위치를 볼 수 있어요. 친구방에서도 동일하게 송신돼요.',
        _ => '',
      };

  Color _hexToColor(String hex) {
    final v = int.parse(hex.substring(1), radix: 16);
    return Color(0xFF000000 | v);
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant)),
    );
  }
}
