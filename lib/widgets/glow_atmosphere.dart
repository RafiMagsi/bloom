import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Which atmosphere layer to paint — split so the light leak and bokeh can
/// sit behind the portrait while sparkles float in front of it.
enum GlowLayer { back, front }

/// Dreamy light: an iridescent light leak, drifting bokeh and twinkling
/// golden sparkles. Every motion uses whole cycles of [ambient] so the
/// 0…1 loop is seamless.
class GlowAtmosphere extends StatelessWidget {
  const GlowAtmosphere({
    super.key,
    required this.ambient,
    required this.layer,
    this.intensity = 1,
  });

  final Animation<double> ambient;
  final GlowLayer layer;

  /// 0…1 fade used by the entrance sequence.
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _AtmospherePainter(ambient, layer, intensity),
        size: Size.infinite,
      ),
    );
  }
}

class _Sparkle {
  _Sparkle(math.Random r)
      : x = r.nextDouble(),
        y = r.nextDouble(),
        size = 0.6 + r.nextDouble() * r.nextDouble() * 3.4,
        rise = 1 + r.nextInt(2),
        twinkle = 2 + r.nextInt(5),
        phase = r.nextDouble(),
        wobble = 4 + r.nextDouble() * 10,
        warm = r.nextBool();

  final double x, y, size, phase, wobble;
  final int rise, twinkle;
  final bool warm;
}

class _Bokeh {
  _Bokeh(this.x, this.y, this.radius, this.alpha, this.color);

  final double x, y, radius, alpha;
  final Color color;
}

class _AtmospherePainter extends CustomPainter {
  _AtmospherePainter(this.ambient, this.layer, this.intensity)
      : super(repaint: ambient);

  final Animation<double> ambient;
  final GlowLayer layer;
  final double intensity;

  static final List<_Sparkle> _sparkles = () {
    final r = math.Random(11);
    return List.generate(46, (_) => _Sparkle(r));
  }();

  static final List<_Bokeh> _bokeh = [
    _Bokeh(0.86, 0.12, 0.13, 0.55, Colors.white),
    _Bokeh(0.1, 0.42, 0.09, 0.45, const Color(0xFFFFE1E9)),
    _Bokeh(0.92, 0.5, 0.07, 0.4, const Color(0xFFFFF1E2)),
    _Bokeh(0.2, 0.08, 0.06, 0.35, Colors.white),
    _Bokeh(0.74, 0.3, 0.05, 0.3, const Color(0xFFFFD9E3)),
    _Bokeh(0.05, 0.7, 0.11, 0.3, Colors.white),
    _Bokeh(0.95, 0.78, 0.09, 0.28, const Color(0xFFFFE1E9)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;
    final v = ambient.value;
    if (layer == GlowLayer.back) {
      _lightLeak(canvas, size, v);
      _paintBokeh(canvas, size, v);
    } else {
      _paintSparkles(canvas, size, v);
    }
  }

  void _lightLeak(Canvas canvas, Size size, double v) {
    final breathe = 0.55 + 0.2 * math.sin(v * 2 * math.pi * 2);
    final sweep = math.sin(v * 2 * math.pi) * 0.04;
    canvas.save();
    // Anchored in the top-left corner, clear of the face.
    canvas.translate(size.width * (-0.06 + sweep), -size.height * 0.04);
    canvas.rotate(-0.7);
    final rect = Rect.fromLTWH(
      -size.width * 0.2,
      -size.height * 0.1,
      size.width * 0.3,
      size.height * 0.42,
    );
    final colors = [
      const Color(0xFFFFFFFF).withValues(alpha: 0),
      const Color(0xFFFFD6E2).withValues(alpha: 0.55),
      const Color(0xFFFFE6CC).withValues(alpha: 0.6),
      const Color(0xFFF1DBFF).withValues(alpha: 0.45),
      const Color(0xFFFFFFFF).withValues(alpha: 0),
    ];
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            for (final c in colors)
              c.withValues(alpha: c.a * breathe * intensity),
          ],
          stops: const [0.0, 0.32, 0.5, 0.68, 1.0],
        ).createShader(rect)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.04),
    );
    // A thin bright core in the leak.
    canvas.drawRect(
      Rect.fromLTWH(
        rect.left + rect.width * 0.47,
        rect.top,
        rect.width * 0.05,
        rect.height,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35 * breathe * intensity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.012),
    );
    canvas.restore();
  }

  void _paintBokeh(Canvas canvas, Size size, double v) {
    final d = size.shortestSide;
    for (var i = 0; i < _bokeh.length; i++) {
      final b = _bokeh[i];
      final a = v * 2 * math.pi;
      final c = Offset(
        size.width * b.x + math.sin(a + i) * d * 0.018,
        size.height * b.y + math.cos(a * 2 + i * 1.7) * d * 0.012,
      );
      final r = d * b.radius;
      final pulse = 0.8 + 0.2 * math.sin(a * 3 + i * 2.1);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              b.color.withValues(alpha: b.alpha * pulse * intensity),
              b.color.withValues(alpha: b.alpha * 0.55 * pulse * intensity),
              b.color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.7, 1.0],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
  }

  void _paintSparkles(Canvas canvas, Size size, double v) {
    for (final s in _sparkles) {
      final y = (s.y - v * s.rise) % 1.0;
      final x = s.x * size.width +
          math.sin((v * 3 + s.phase) * 2 * math.pi) * s.wobble;
      final tw = 0.5 + 0.5 * math.sin((v * s.twinkle + s.phase) * 2 * math.pi);
      // Fade at the edges of the travel and in the lower mist.
      final edge = math.min(1.0, math.min(y, 1 - y) * 6);
      final alpha = tw * edge * intensity * (y > 0.62 ? 0.4 : 1.0);
      if (alpha <= 0.02) continue;
      final p = Offset(x, y * size.height);
      final color = s.warm ? const Color(0xFFFFE7B8) : Colors.white;

      canvas.drawCircle(
        p,
        s.size * 2.4,
        Paint()
          ..color = color.withValues(alpha: 0.28 * alpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.size * 1.6),
      );
      if (s.size > 2.4) {
        _star(canvas, p, s.size * (1.4 + tw * 0.8),
            Paint()..color = color.withValues(alpha: 0.95 * alpha));
      } else {
        canvas.drawCircle(
          p,
          s.size * 0.55,
          Paint()..color = color.withValues(alpha: 0.95 * alpha),
        );
      }
    }
  }

  void _star(Canvas canvas, Offset at, double r, Paint paint) {
    final path = Path()
      ..moveTo(at.dx, at.dy - r)
      ..quadraticBezierTo(at.dx, at.dy, at.dx + r, at.dy)
      ..quadraticBezierTo(at.dx, at.dy, at.dx, at.dy + r)
      ..quadraticBezierTo(at.dx, at.dy, at.dx - r, at.dy)
      ..quadraticBezierTo(at.dx, at.dy, at.dx, at.dy - r)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_AtmospherePainter oldDelegate) =>
      oldDelegate.intensity != intensity || oldDelegate.layer != layer;
}
