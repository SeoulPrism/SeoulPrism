import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import '../services/environment_service.dart';

/// 지도 위 강수 효과 오버레이.
/// Mapbox SDK 2.22.1 에 snow/rain API 가 없어서 Flutter CustomPainter 로 직접 그림.
/// IgnorePointer 로 모든 탭은 지도까지 통과.
class WeatherOverlay extends StatefulWidget {
  final EnvironmentData? environment;

  const WeatherOverlay({super.key, this.environment});

  @override
  State<WeatherOverlay> createState() => _WeatherOverlayState();
}

class _WeatherOverlayState extends State<WeatherOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final List<_Particle> _particles = [];
  Size _size = Size.zero;
  Duration _last = Duration.zero;
  final _rng = Random();

  // Thunderstorm flash — 0.0 ~ 1.0, 페이드 아웃.
  double _flash = 0.0;
  double _nextFlashAt = 0.0;
  double _elapsed = 0.0;

  WeatherCondition? get _weather => widget.environment?.weather;
  bool get _isLight => widget.environment?.lightPreset == 'day' ||
      widget.environment?.lightPreset == 'dawn';

  bool get _hasParticles {
    final w = _weather;
    return w == WeatherCondition.rain ||
        w == WeatherCondition.drizzle ||
        w == WeatherCondition.snow ||
        w == WeatherCondition.thunderstorm;
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    if (_hasParticles) _ticker.start();
    _scheduleNextFlash();
  }

  @override
  void didUpdateWidget(WeatherOverlay old) {
    super.didUpdateWidget(old);
    if (old.environment?.weather != widget.environment?.weather) {
      _particles.clear();
      if (_hasParticles && !_ticker.isActive) {
        _ticker.start();
      } else if (!_hasParticles && _ticker.isActive) {
        _ticker.stop();
        setState(() {}); // 마지막 프레임 비우기
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _scheduleNextFlash() {
    // 5~12 초 사이 랜덤
    _nextFlashAt = _elapsed + 5.0 + _rng.nextDouble() * 7.0;
  }

  void _tick(Duration now) {
    final dtMs = (now - _last).inMilliseconds;
    _last = now;
    if (dtMs <= 0 || _size == Size.zero) return;
    final dt = (dtMs / 1000.0).clamp(0.0, 0.05); // 50ms cap (lag spike 방어)
    _elapsed += dt;

    // 파티클 spawn
    final target = _targetCount();
    while (_particles.length < target) {
      _particles.add(_spawn(initial: true));
    }

    // 업데이트
    for (final p in _particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.age += dt;
      // 화면 밖 → 위로 재배치
      if (p.y > _size.height + 20 || p.x < -20 || p.x > _size.width + 20) {
        final fresh = _spawn(initial: false);
        p
          ..x = fresh.x
          ..y = fresh.y
          ..vx = fresh.vx
          ..vy = fresh.vy
          ..size = fresh.size
          ..age = 0;
      }
    }

    // Thunderstorm flash
    if (_weather == WeatherCondition.thunderstorm) {
      if (_flash > 0) {
        _flash -= dt * 3.0; // 0.33s 페이드아웃
        if (_flash < 0) _flash = 0;
      }
      if (_elapsed >= _nextFlashAt) {
        _flash = 0.6 + _rng.nextDouble() * 0.3;
        _scheduleNextFlash();
      }
    } else {
      _flash = 0;
    }

    setState(() {});
  }

  int _targetCount() {
    return switch (_weather) {
      WeatherCondition.rain => 120,
      WeatherCondition.thunderstorm => 150,
      WeatherCondition.drizzle => 60,
      WeatherCondition.snow => 80,
      _ => 0,
    };
  }

  _Particle _spawn({required bool initial}) {
    final w = _weather;
    final width = _size.width;
    final height = _size.height;
    // initial=true: 화면 어디든. initial=false: 위에서 떨어지기 시작.
    final x = _rng.nextDouble() * (width + 100) - 50;
    final y = initial
        ? _rng.nextDouble() * height
        : -20 - _rng.nextDouble() * 30;

    switch (w) {
      case WeatherCondition.rain:
      case WeatherCondition.thunderstorm:
        return _Particle(
          x: x,
          y: y,
          vx: -40 + _rng.nextDouble() * 10, // 살짝 사선
          vy: 700 + _rng.nextDouble() * 250, // 빠름
          size: 1.0 + _rng.nextDouble() * 0.4,
        );
      case WeatherCondition.drizzle:
        return _Particle(
          x: x,
          y: y,
          vx: -20 + _rng.nextDouble() * 6,
          vy: 350 + _rng.nextDouble() * 100,
          size: 0.8 + _rng.nextDouble() * 0.3,
        );
      case WeatherCondition.snow:
        return _Particle(
          x: x,
          y: y,
          vx: -15 + _rng.nextDouble() * 30, // 양쪽으로 흔들림
          vy: 60 + _rng.nextDouble() * 60,  // 느림
          size: 2.0 + _rng.nextDouble() * 2.5,
        );
      default:
        return _Particle(x: x, y: y, vx: 0, vy: 0, size: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasParticles && _flash <= 0) return const SizedBox.shrink();

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final newSize = Size(constraints.maxWidth, constraints.maxHeight);
          if (newSize != _size) {
            _size = newSize;
          }
          return CustomPaint(
            size: newSize,
            painter: _WeatherPainter(
              particles: _particles,
              weather: _weather,
              isLight: _isLight,
              flash: _flash,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double age;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
  }) : age = 0;
}

class _WeatherPainter extends CustomPainter {
  final List<_Particle> particles;
  final WeatherCondition? weather;
  final bool isLight;
  final double flash;

  _WeatherPainter({
    required this.particles,
    required this.weather,
    required this.isLight,
    required this.flash,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weather == WeatherCondition.snow) {
      _paintSnow(canvas);
    } else if (weather == WeatherCondition.rain ||
        weather == WeatherCondition.thunderstorm ||
        weather == WeatherCondition.drizzle) {
      _paintRain(canvas);
    }

    // Thunderstorm flash overlay (전체 화면 흰빛)
    if (flash > 0) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: flash * 0.35);
      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  void _paintRain(Canvas canvas) {
    final color = isLight
        ? const Color(0xFF6FA8DC).withValues(alpha: 0.55)
        : const Color(0xFFB8D4F0).withValues(alpha: 0.45);
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4;
    for (final p in particles) {
      // 속도 방향으로 짧은 선
      final len = weather == WeatherCondition.drizzle ? 6.0 : 12.0;
      // 정규화
      final mag = sqrt(p.vx * p.vx + p.vy * p.vy);
      if (mag == 0) continue;
      final nx = p.vx / mag;
      final ny = p.vy / mag;
      paint.strokeWidth = p.size * 1.4;
      canvas.drawLine(
        Offset(p.x, p.y),
        Offset(p.x + nx * len, p.y + ny * len),
        paint,
      );
    }
  }

  void _paintSnow(Canvas canvas) {
    final color = (isLight ? Colors.white : const Color(0xFFEFF4FA))
        .withValues(alpha: 0.85);
    final paint = Paint()
      ..color = color
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 0.6);
    for (final p in particles) {
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherPainter old) => true;
}
