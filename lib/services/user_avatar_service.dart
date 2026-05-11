// 일반 사용자 프로필 사진 — Supabase Storage `avatars` 버킷 + auth.users.user_metadata.avatar_url.
// Seoul Live(multiplayer profiles) 와 무관 — 누구나 가질 수 있음.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserAvatarService {
  UserAvatarService._();
  static final UserAvatarService instance = UserAvatarService._();

  SupabaseClient get _sb => Supabase.instance.client;

  /// 현재 로그인 사용자의 avatar URL (user_metadata 에서 읽음). null 이면 미설정.
  String? get currentAvatarUrl {
    final raw = _sb.auth.currentUser?.userMetadata?['avatar_url'];
    if (raw is String && raw.trim().isNotEmpty) return raw;
    return null;
  }

  /// [file] 을 Storage 에 업로드하고 user_metadata.avatar_url 갱신.
  /// 반환값 = public URL. 이전 파일은 fire-and-forget 으로 정리.
  ///
  /// 경로: `<user_id>/<millis>.<ext>` — RLS 가 본인 폴더만 INSERT 허용.
  Future<String> uploadAvatar(File file) async {
    final user = _sb.auth.currentUser;
    if (user == null) {
      throw StateError('로그인이 필요합니다.');
    }

    var ext = file.path.split('.').last.toLowerCase();
    if (ext.isEmpty || ext.length > 5) ext = 'jpg';
    final contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' || 'heif' => 'image/heic',
      _ => 'image/jpeg',
    };
    final objectPath =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _sb.storage.from('avatars').upload(
          objectPath,
          file,
          fileOptions: FileOptions(
            upsert: false,
            contentType: contentType,
            cacheControl: '3600',
          ),
        );
    final url = _sb.storage.from('avatars').getPublicUrl(objectPath);

    final old = currentAvatarUrl;
    await _sb.auth.updateUser(UserAttributes(data: {'avatar_url': url}));

    // 이전 파일은 비동기 정리 — 실패해도 무시.
    if (old != null) {
      unawaited(_deleteByPublicUrl(old));
    }
    return url;
  }

  Future<void> removeAvatar() async {
    final user = _sb.auth.currentUser;
    if (user == null) return;
    final old = currentAvatarUrl;
    await _sb.auth.updateUser(UserAttributes(data: {'avatar_url': null}));
    if (old != null) {
      unawaited(_deleteByPublicUrl(old));
    }
  }

  Future<void> _deleteByPublicUrl(String url) async {
    try {
      const marker = '/avatars/';
      final i = url.indexOf(marker);
      if (i < 0) return;
      final path = url.substring(i + marker.length).split('?').first;
      if (path.isEmpty) return;
      await _sb.storage.from('avatars').remove([path]);
    } catch (e) {
      debugPrint('[UserAvatar] cleanup failed: $e');
    }
  }
}
