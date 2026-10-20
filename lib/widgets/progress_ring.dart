import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/bloom_theme.dart';

/// Animated completion ring for the daily dashboard (rose → orchid). When
/// the day is complete it turns gold-rose and breathes with a soft halo.
class ProgressRing extends StatefulWidget {
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
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  bool get _complete => widget.progress >= 0.999;

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    if (_complete && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!_complete && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: widget.progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) => SizedBox.square(
            dimension: widget.size,
            child: CustomPaint(
              painter: _RingPainter(
                value,
                widget.stroke,
                bloomed: _complete && value >= 0.999,
                pulse: Curves.easeInOut.transform(_pulse.value),
              ),
              child: Center(child: child),
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(
    this.fraction,
    this.stroke, {
    required this.bloomed,
    required this.pulse,
  });

  final double fraction;
  final double stroke;
  final bool bloomed;
  final double pulse;

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
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: bloomed
            ? const [
                Color(0xFFF6C177),
                BloomPalette.blushDeep,
                Color(0xFFB860A6),
                Color(0xFFF6C177),
              ]
            : const [
                BloomPalette.blush,
                BloomPalette.blushDeep,
                BloomPalette.orchidDeep,
                BloomPalette.blush,
              ],
        stops: const [0.0, 0.45, 0.8, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);

    // Glow beneath the arc — a breathing golden halo once the day blooms.
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + (bloomed ? 10 + 8 * pulse : 9)
      ..strokeCap = StrokeCap.round
      ..color = bloomed
          ? const Color(0xFFF6C177).withValues(alpha: 0.22 + 0.2 * pulse)
          : BloomPalette.blush.withValues(alpha: 0.22);
    if (bloomed) glow.maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawArc(rect, -math.pi / 2, fraction * 2 * math.pi, false, glow);

    canvas.drawArc(rect, -math.pi / 2, fraction * 2 * math.pi, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.stroke != stroke ||
      oldDelegate.bloomed != bloomed ||
      oldDelegate.pulse != pulse;
}
