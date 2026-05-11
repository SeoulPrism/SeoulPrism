import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/multiplayer_models.dart';
import '../../services/multiplayer_service.dart';
import '../../widgets/adaptive/adaptive.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/multiplayer/profile_avatar.dart';

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
      // 화면 70% 시작 / 위로 드래그하면 95% 까지 / 아래로 50% 까지.
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scroll) => SingleChildScrollView(
          controller: scroll,
          child: const MultiplayerProfileEditSheet(),
        ),
      ),
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
  bool _uploadingAvatar = false;
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
    final l = AppL10n.of(context);
    final nickname = _nicknameCtrl.text.trim();
    final birthYearStr = _birthYearCtrl.text.trim();

    if (nickname.isEmpty || nickname.length > 20) {
      setState(() => _error = l.profileEditNicknameInvalid);
      return;
    }
    final birthYear = int.tryParse(birthYearStr);
    if (birthYear == null ||
        birthYear < 1900 ||
        birthYear > DateTime.now().year) {
      setState(() => _error = l.profileEditBirthInvalid);
      return;
    }
    if (DateTime.now().year - birthYear < MultiplayerService.kMinAgeYears) {
      setState(() => _error = l.profileEditAgeRestriction);
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
    final l = AppL10n.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, bottomInset + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.profileEditTitle,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface)),
            const SizedBox(height: 4),
            Text(l.profileEditSubtitle,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            const SizedBox(height: 24),

            _AvatarSection(
              profile: MultiplayerService.instance.myProfile,
              previewEmoji: _pinEmoji,
              previewColor: _pinColor,
              uploading: _uploadingAvatar,
              onTap: _uploadingAvatar ? null : _openAvatarPicker,
            ),
            const SizedBox(height: 22),

            _Label(text: l.profileEditNicknameLabel),
            AdaptiveTextField(
              controller: _nicknameCtrl,
              placeholder: l.profileEditNicknamePlaceholder,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            const SizedBox(height: 18),

            _Label(text: l.profileEditBirthLabel),
            AdaptiveTextField(
              controller: _birthYearCtrl,
              placeholder: l.profileEditBirthPlaceholder,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            const SizedBox(height: 18),

            _Label(text: l.profileEditEmojiLabel),
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

            _Label(text: l.profileEditColorLabel),
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

            _Label(text: l.profileEditVisibilityLabel),
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
              segments: [
                AdaptiveSegment(
                    value: 'ghost',
                    label: l.profileEditVisibilityGhost,
                    icon: Icons.visibility_off_rounded),
                AdaptiveSegment(
                    value: 'friends',
                    label: l.profileEditVisibilityFriends,
                    icon: Icons.people_alt_rounded),
                AdaptiveSegment(
                    value: 'selected_groups',
                    label: l.profileEditVisibilityGroup,
                    icon: Icons.group_outlined),
                AdaptiveSegment(
                    value: 'public',
                    label: l.profileEditVisibilityPublic,
                    icon: Icons.public_rounded),
              ],
            ),
            const SizedBox(height: 8),
            Text(_visibilityHint(context),
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            if (_visibility == 'selected_groups') ...[
              const SizedBox(height: 12),
              _VisibleGroupsPicker(),
            ],

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
              label: _saving ? l.profileEditSaving : l.profileEditSave,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      );
  }

  Future<void> _openAvatarPicker() async {
    final l = AppL10n.of(context);
    final hasExisting =
        (MultiplayerService.instance.myProfile?.avatarUrl ?? '').isNotEmpty;
    final source = await showModalBottomSheet<_AvatarAction>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) {
        final cs2 = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: Text(l.profileEditAvatarChoose),
                  onTap: () => Navigator.pop(ctx, _AvatarAction.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_rounded),
                  title: Text(l.profileEditAvatarCamera),
                  onTap: () => Navigator.pop(ctx, _AvatarAction.camera),
                ),
                if (hasExisting)
                  ListTile(
                    leading: Icon(Icons.delete_outline_rounded,
                        color: cs2.error),
                    title: Text(l.profileEditAvatarRemove,
                        style: TextStyle(color: cs2.error)),
                    onTap: () => Navigator.pop(ctx, _AvatarAction.remove),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (source == null || !mounted) return;
    switch (source) {
      case _AvatarAction.gallery:
        await _pickAndUpload(ImageSource.gallery);
      case _AvatarAction.camera:
        await _pickAndUpload(ImageSource.camera);
      case _AvatarAction.remove:
        await _confirmAndRemoveAvatar();
    }
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final picker = ImagePicker();
      // 큰 사진을 그대로 올리면 Storage 비용 + 다운로드 지연. 한 변 1024px,
      // 80% 품질로 줄여서 평균 100-300KB 수준으로 정리.
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (picked == null || !mounted) return;
      setState(() => _uploadingAvatar = true);
      await MultiplayerService.instance.uploadMyAvatar(File(picked.path));
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);
      final l = AppL10n.of(context);
      showAppSnackBar(l.profileEditAvatarFailed);
    }
  }

  Future<void> _confirmAndRemoveAvatar() async {
    final l = AppL10n.of(context);
    await showAdaptiveConfirmDialog(
      context: context,
      title: l.profileEditAvatarRemoveConfirmTitle,
      content: l.profileEditAvatarRemoveConfirmBody,
      confirmText: l.profileEditAvatarRemove,
      isDestructive: true,
      onConfirm: () async {
        try {
          await MultiplayerService.instance.removeMyAvatar();
          if (mounted) setState(() {});
        } catch (_) {
          if (mounted) showAppSnackBar(AppL10n.of(context).profileEditAvatarFailed);
        }
      },
    );
  }

  Future<bool> _confirmPublic() async {
    final l = AppL10n.of(context);
    bool result = false;
    await showAdaptiveConfirmDialog(
      context: context,
      title: l.profileEditPublicDialogTitle,
      content: l.profileEditPublicDialogBody,
      confirmText: l.profileEditPublicDialogConfirm,
      isDestructive: true,
      onConfirm: () {
        result = true;
      },
    );
    return result;
  }

  String _visibilityHint(BuildContext ctx) {
    final l = AppL10n.of(ctx);
    return switch (_visibility) {
      'ghost' => l.profileEditVisibilityGhostDesc,
      'friends' => l.profileEditVisibilityFriendsDesc,
      'selected_groups' => l.profileEditVisibilityGroupDesc,
      'public' => l.profileEditVisibilityPublicDesc,
      _ => '',
    };
  }

  Color _hexToColor(String hex) {
    final v = int.parse(hex.substring(1), radix: 16);
    return Color(0xFF000000 | v);
  }
}

/// 사용자 그룹 picker — visibility=selected_groups 전용.
/// 선택 즉시 서버 반영 (저장 버튼과 무관).
class _VisibleGroupsPicker extends StatefulWidget {
  @override
  State<_VisibleGroupsPicker> createState() => _VisibleGroupsPickerState();
}

class _VisibleGroupsPickerState extends State<_VisibleGroupsPicker> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(MultiplayerService.instance.myVisibleGroupIds);
  }

  Future<void> _toggle(String groupId) async {
    final newSet = Set<String>.from(_selected);
    if (newSet.contains(groupId)) {
      newSet.remove(groupId);
    } else {
      newSet.add(groupId);
    }
    setState(() => _selected = newSet);
    try {
      await MultiplayerService.instance.setMyVisibleGroups(newSet);
    } catch (_) {/* UI 는 이미 반영 — 실패 시 다음 새로고침에 정정 */}
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final groups = MultiplayerService.instance.friendGroups;
    if (groups.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(AppL10n.of(context).profileEditNoGroups,
            style:
                TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: groups.map((g) {
        final on = _selected.contains(g.id);
        return GestureDetector(
          onTap: () => _toggle(g.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: on ? cs.primaryContainer : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: on ? cs.primary : Colors.transparent, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(g.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(g.name,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: on ? cs.onPrimaryContainer : cs.onSurface)),
                if (on) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.check_rounded,
                      size: 14, color: cs.onPrimaryContainer),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
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

enum _AvatarAction { gallery, camera, remove }

/// 편집 시트 상단의 큰 아바타 + 카메라 뱃지 + 업로드 진행 상태.
/// 사진이 없으면 현재 선택 중인 핀 컬러 + 이모지로 미리보기.
class _AvatarSection extends StatelessWidget {
  final MultiplayerProfile? profile;
  final String previewEmoji;
  final String previewColor;
  final bool uploading;
  final VoidCallback? onTap;

  const _AvatarSection({
    required this.profile,
    required this.previewEmoji,
    required this.previewColor,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(context);

    // 사진 없을 때는 현재 시트에서 막 고른 이모지/색상을 즉시 반영.
    final preview = profile == null
        ? null
        : MultiplayerProfile(
            userId: profile!.userId,
            nickname: profile!.nickname,
            pinColor: previewColor,
            pinEmoji: previewEmoji,
            visibility: profile!.visibility,
            birthYear: profile!.birthYear,
            avatarUrl: profile!.avatarUrl,
          );

    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ProfileAvatar(
                profile: preview,
                size: 96,
                emojiSize: 48,
                borderColor: cs.outlineVariant,
                onTap: onTap,
              ),
              // 카메라 뱃지 — 우하단.
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary,
                    border: Border.all(color: cs.surface, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: uploading
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : Icon(Icons.camera_alt_rounded,
                          size: 16, color: cs.onPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            uploading ? l.profileEditAvatarUploading : l.profileEditAvatarTapHint,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
