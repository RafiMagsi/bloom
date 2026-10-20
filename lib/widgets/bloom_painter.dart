import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/bloom_theme.dart';

/// Hand-painted bloom rosette used as the welcome hero illustration.
class BloomRosette extends StatelessWidget {
  const BloomRosette({super.key, this.size = 230});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _BloomRosettePainter(),
    );
  }
}

class _BloomRosettePainter extends CustomPainter {
  const _BloomRosettePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2;

    // Soft halo behind the flower.
    final halo = Paint()
      ..shader = RadialGradient(
        colors: [
          BloomPalette.blushSoft,
          BloomPalette.blushSoft.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r * 0.99, halo);

    // Outer blush petals.
    for (var i = 0; i < 8; i++) {
      _petal(
        canvas,
        center,
        angle: i * math.pi / 4,
        length: r * 0.86,
        width: r * 0.5,
        base: const Color(0xFFFBD3DE),
        tip: BloomPalette.blushDeep,
      );
    }
    // Inner cream petals, offset by half a step.
    for (var i = 0; i < 8; i++) {
      _petal(
        canvas,
        center,
        angle: i * math.pi / 4 + math.pi / 8,
        length: r * 0.55,
        width: r * 0.34,
        base: const Color(0xFFFFF7F1),
        tip: const Color(0xFFF6B4C7),
      );
    }

    // Center.
    final centerPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFFFE7C9), BloomPalette.honey],
      ).createShader(
          Rect.fromCircle(center: center, radius: r * 0.21));
    canvas.drawCircle(center, r * 0.21, centerPaint);
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(center - Offset(r * 0.05, r * 0.05), r * 0.05, dot);

    // Sparkles.
    final sparkle = Paint()..color = Colors.white.withValues(alpha: 0.9);
    _sparkle(canvas, center + Offset(r * 0.66, -r * 0.62), r * 0.09, sparkle);
    _sparkle(canvas, center + Offset(-r * 0.7, r * 0.5), r * 0.07, sparkle);
    _sparkle(canvas, center + Offset(r * 0.52, r * 0.7), r * 0.055, sparkle);
  }

  void _petal(
    Canvas canvas,
    Offset center, {
    required double angle,
    required double length,
    required double width,
    required Color base,
    required Color tip,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(width / 2, -length * 0.55, 0, -length)
      ..quadraticBezierTo(-width / 2, -length * 0.55, 0, 0)
      ..close();
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [base, tip],
      ).createShader(Rect.fromLTWH(-width / 2, -length, width, length));
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _sparkle(Canvas canvas, Offset at, double r, Paint paint) {
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
  bool shouldRepaint(_BloomRosettePainter oldDelegate) => false;
}
