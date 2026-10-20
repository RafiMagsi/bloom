import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/bloom_theme.dart';

/// Animated completion ring for the daily dashboard (orchid progress accent).
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.child,
    this.size = 132,
    this.stroke = 13,
  });

  final double progress;
  final Widget child;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _RingPainter(value, stroke),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.fraction, this.stroke);

  final double fraction;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Soft track.
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = BloomPalette.blushSoft;
    canvas.drawCircle(center, radius, track);

    if (fraction <= 0.001) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [
          BloomPalette.blush,
          BloomPalette.blushDeep,
          BloomPalette.orchidDeep,
          BloomPalette.blush,
        ],
        stops: [0.0, 0.45, 0.8, 1.0],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(rect);

    // Glow beneath the arc.
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + 9
      ..strokeCap = StrokeCap.round
      ..color = BloomPalette.blush.withValues(alpha: 0.22);
    canvas.drawArc(rect, -math.pi / 2, fraction * 2 * math.pi, false, glow);

    canvas.drawArc(rect, -math.pi / 2, fraction * 2 * math.pi, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.stroke != stroke;
}
