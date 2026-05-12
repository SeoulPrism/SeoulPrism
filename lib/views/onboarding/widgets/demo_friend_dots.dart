import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Seoul Live 페이지의 데모 — 친구 아바타 dot 3개가 다른 위치에서
/// 공통 목적지(중앙 오렌지 핀)로 수렴하는 모션을 반복.
/// 화면 좌표만 사용 (Mapbox annotation 미사용) — 정확한 위경도 매핑은 데모에 과함.
class DemoFriendDots extends StatefulWidget {
  const DemoFriendDots({super.key});

  @override
  State<DemoFriendDots> createState() => _DemoFriendDotsState();
}

class _Friend {
  final String initial;
  final Color color;
  final Offset start;
  final int startMeters;
  const _Friend({
    required this.initial,
    required this.color,
    required this.start,
    required this.startMeters,
  });
}

class _DemoFriendDotsState extends State<DemoFriendDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _dest = Offset(0.5, 0.5);
  static const _friends = <_Friend>[
    _Friend(
      initial: 'J',
      color: Color(0xFF7C5CFF),
      start: Offset(0.16, 0.22),
      startMeters: 540,
    ),
    _Friend(
      initial: 'M',
      color: Color(0xFF5CC8FF),
      start: Offset(0.84, 0.28),
      startMeters: 380,
    ),
    _Friend(
      initial: 'S',
      color: Color(0xFFFF6B9D),
      start: Offset(0.22, 0.82),
      startMeters: 620,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) {
              final t = _ctrl.value;
              // 0 ~ 0.78: 다가옴. 0.78 ~ 0.90: 만난 상태 hold. 0.90 ~ 1.0: 페이드아웃 후 리셋.
              final reachT = math.min(t / 0.78, 1.0);
              final eased = Curves.easeInOutCubic.transform(reachT);
              final meetHold = t >= 0.78 && t < 0.90;
              final fadeOut = t < 0.95 ? 1.0 : (1.0 - (t - 0.95) / 0.05);
              final destPx = Offset(_dest.dx * w, _dest.dy * h);

              return Stack(
                children: [
                  for (final f in _friends)
                    _buildFriendDot(f, w, h, destPx, eased, meetHold, fadeOut),
                  // 중앙 오렌지 핀 — 도달하면 펄스.
                  _buildDestinationPin(destPx, reachT >= 1.0),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFriendDot(
    _Friend f,
    double w,
    double h,
    Offset destPx,
    double eased,
    bool meetHold,
    double fadeOut,
  ) {
    final startPx = Offset(f.start.dx * w, f.start.dy * h);
    final pos = Offset.lerp(startPx, destPx, eased)!;
    final meters = (f.startMeters * (1 - eased)).round();
    final label = meetHold ? '도착' : '${meters}m';

    return Positioned(
      left: pos.dx - 22,
      top: pos.dy - 22,
      child: Opacity(
        opacity: fadeOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [f.color, f.color.withValues(alpha: 0.6)],
                ),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: f.color.withValues(alpha: 0.5),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                f.initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationPin(Offset destPx, bool arrived) {
    final pulseScale = arrived
        ? 1.0 + 0.15 * math.sin(_ctrl.value * math.pi * 6)
        : 1.0;
    return Positioned(
      left: destPx.dx - 18,
      top: destPx.dy - 36,
      child: Transform.scale(
        scale: pulseScale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7A00), Color(0xFFFFC371)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF7A00).withValues(alpha: 0.6),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.place_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(height: 2),
            // 핀 꼬리 (작은 삼각형).
            CustomPaint(
              size: const Size(10, 6),
              painter: _PinTailPainter(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFF7A00);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
