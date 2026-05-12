// 프로필 사진 업로드 픽커.
// iOS = CupertinoActionSheet (Liquid Glass 컨벤션)
// Android = M3 ModalBottomSheet + 드래그핸들.

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';

enum AvatarAction { gallery, camera, remove }

class AvatarPicker {
  /// 사용자가 사진을 선택/촬영/삭제 중 하나를 결정. 취소하면 null.
  /// [hasExisting] = 현재 사진이 있을 때만 삭제 액션 노출.
  static Future<AvatarAction?> show(
    BuildContext context, {
    required bool hasExisting,
  }) {
    if (Platform.isIOS) {
      return _showIOS(context, hasExisting: hasExisting);
    }
    return _showAndroid(context, hasExisting: hasExisting);
  }

  static Future<AvatarAction?> _showIOS(
    BuildContext context, {
    required bool hasExisting,
  }) async {
    final l = AppL10n.of(context);
    return showCupertinoModalPopup<AvatarAction>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l.profileEditAvatarLabel),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, AvatarAction.gallery),
            child: Text(l.profileEditAvatarChoose),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, AvatarAction.camera),
            child: Text(l.profileEditAvatarCamera),
          ),
          if (hasExisting)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, AvatarAction.remove),
              child: Text(l.profileEditAvatarRemove),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          isDefaultAction: true,
          child: Text(l.commonCancel),
        ),
      ),
    );
  }

  static Future<AvatarAction?> _showAndroid(
    BuildContext context, {
    required bool hasExisting,
  }) async {
    return showModalBottomSheet<AvatarAction>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final l = AppL10n.of(ctx);
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Text(
                    l.profileEditAvatarLabel,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library_rounded,
                      color: cs.onSurfaceVariant),
                  title: Text(l.profileEditAvatarChoose),
                  onTap: () => Navigator.pop(ctx, AvatarAction.gallery),
                ),
                ListTile(
                  leading: Icon(Icons.photo_camera_rounded,
                      color: cs.onSurfaceVariant),
                  title: Text(l.profileEditAvatarCamera),
                  onTap: () => Navigator.pop(ctx, AvatarAction.camera),
                ),
                if (hasExisting)
                  ListTile(
                    leading: Icon(Icons.delete_outline_rounded, color: cs.error),
                    title: Text(
                      l.profileEditAvatarRemove,
                      style: TextStyle(color: cs.error),
                    ),
                    onTap: () => Navigator.pop(ctx, AvatarAction.remove),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
