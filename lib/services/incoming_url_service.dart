import 'package:flutter/services.dart';

/// 위젯/Control/외부 앱에서 넘어온 URL 처리.
/// iOS native (SceneDelegate) 가 'seoul_prism/incoming_url' 채널로 전달.
class IncomingUrlService {
  static final IncomingUrlService instance = IncomingUrlService._();
  IncomingUrlService._();

  static const _channel = MethodChannel('seoul_prism/incoming_url');
  void Function(Uri url)? _listener;

  /// 단일 listener 등록. 새로 등록 시 이전 것은 대체.
  void onUrl(void Function(Uri url) listener) {
    _listener = listener;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'handle') {
        final urlStr = call.arguments as String?;
        if (urlStr != null) {
          try {
            _listener?.call(Uri.parse(urlStr));
          } catch (_) {}
        }
      }
      return null;
    });
  }
}
