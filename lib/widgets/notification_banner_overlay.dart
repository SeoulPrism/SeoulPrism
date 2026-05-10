import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/notification_service.dart';

/// 앱 전체 상단에 떠있는 인앱 알림 배너.
/// MaterialApp 의 builder 에 감싸서 사용.
class NotificationBannerOverlay extends StatefulWidget {
  final Widget child;
  const NotificationBannerOverlay({super.key, required this.child});

  @override
  State<NotificationBannerOverlay> createState() =>
      _NotificationBannerOverlayState();
}

class _NotificationBannerOverlayState extends State<NotificationBannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  String? _title;
  String? _body;
  Timer? _hideTimer;

  void _onBanner(String title, String body, Map<String, String> data) {
    HapticFeedback.lightImpact();
    setState(() {
      _title = title;
      _body = body;
    });
    _ctrl.forward(from: 0);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    NotificationService.instance.addBannerListener(_onBanner);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _ctrl.dispose();
    NotificationService.instance.removeBannerListener(_onBanner);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, -1.2),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _ctrl,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            )),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: GestureDetector(
                  onTap: () {
                    _ctrl.reverse();
                    _hideTimer?.cancel();
                  },
                  child: _Banner(title: _title ?? '', body: _body ?? ''),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final String title;
  final String body;
  const _Banner({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bgIos = Colors.black.withValues(alpha: 0.55);

    final inner = Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7C5CFF), Color(0xFF5CC8FF)],
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.notifications_active_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Platform.isIOS ? Colors.white : cs.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    )),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Platform.isIOS
                            ? Colors.white.withValues(alpha: 0.85)
                            : cs.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.3,
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (Platform.isIOS) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: bgIos,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 0.5,
              ),
            ),
            child: inner,
          ),
        ),
      );
    }
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      color: cs.surfaceContainerHigh,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: inner,
      ),
    );
  }
}
