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

/// Glossy rose-gold logo medallion with a woman's profile — the landing
/// screen's brand mark.
class BloomMedallion extends StatelessWidget {
  const BloomMedallion({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: BloomPalette.dustyRoseDeep.withValues(alpha: 0.35),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.1),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: size * 0.2,
            spreadRadius: size * 0.02,
          ),
        ],
      ),
      child: CustomPaint(painter: const _MedallionPainter()),
    );
  }
}

class _MedallionPainter extends CustomPainter {
  const _MedallionPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.scale(s);
    const c = Offset(50, 50);
    final disc = Path()..addOval(Rect.fromCircle(center: c, radius: 50));

    canvas.drawPath(
      disc,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.35),
          radius: 1.0,
          colors: [Color(0xFFFFEDEC), Color(0xFFF4C1C3), Color(0xFFDC8E98)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: 50)),
    );

    canvas.save();
    canvas.clipPath(disc);

    // Hair — flowing back and down behind the neck.
    final hair = Path()
      ..moveTo(63, 31)
      ..cubicTo(61, 22, 54, 17, 46, 17.5)
      ..cubicTo(31, 18.5, 23, 31, 25, 47)
      ..cubicTo(26.5, 58, 22, 67, 24, 78)
      ..cubicTo(26, 90, 36, 97, 46, 100)
      ..cubicTo(39, 90, 39, 80, 43, 72)
      ..cubicTo(46.5, 65, 45.5, 56, 47.5, 48)
      ..cubicTo(49.5, 39, 55, 33, 63, 31)
      ..close();
    canvas.drawPath(
      hair,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9A0A9), Color(0xFFC0667A)],
        ).createShader(const Rect.fromLTWH(22, 17, 42, 83)),
    );

    // Face profile facing right.
    final face = Path()
      ..moveTo(49, 23)
      ..cubicTo(57, 22.5, 62.5, 28, 63.6, 36)
      ..cubicTo(64, 39, 63.8, 41, 64.8, 43.4)
      ..lineTo(68.6, 51)
      ..cubicTo(69.2, 52.6, 67.8, 53.6, 65.8, 53.6)
      ..cubicTo(66.6, 55, 66.8, 56, 65.8, 57)
      ..cubicTo(67, 58.2, 66.8, 59.6, 65.4, 60.2)
      ..cubicTo(65.4, 62.2, 66, 64.2, 64.2, 66.4)
      ..cubicTo(62, 69, 58, 70, 54.5, 69.6)
      ..cubicTo(55, 76, 57, 84, 60, 100)
      ..lineTo(40, 100)
      ..cubicTo(43, 86, 43, 74, 42, 64)
      ..cubicTo(41, 50, 42, 30, 49, 23)
      ..close();
    canvas.drawPath(
      face,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFFFF7F4), Color(0xFFF8D6D1)],
        ).createShader(const Rect.fromLTWH(40, 22, 30, 78)),
    );
    // Closed eye + blush.
    canvas.drawPath(
      Path()
        ..moveTo(56.5, 41.5)
        ..quadraticBezierTo(59, 43.6, 61.4, 41.8),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFB0707B),
    );
    canvas.drawCircle(
      const Offset(57, 51),
      5,
      Paint()
        ..color = const Color(0xFFF29CAC).withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    // Front lock falling over the shoulder.
    canvas.drawPath(
      Path()
        ..moveTo(47.5, 22)
        ..cubicTo(44, 34, 46, 52, 44, 64)
        ..cubicTo(43, 74, 45, 86, 50, 100)
        ..lineTo(44, 100)
        ..cubicTo(39, 86, 39.5, 74, 41, 62)
        ..cubicTo(42.5, 48, 40.5, 32, 47.5, 22)
        ..close(),
      Paint()..color = const Color(0xFFD27E8E).withValues(alpha: 0.9),
    );

    // Gloss highlight.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: 43),
      math.pi * 1.05,
      math.pi * 0.42,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    canvas.restore();

    // Rim.
    canvas.drawCircle(
      c,
      48.8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..shader = const SweepGradient(
          colors: [
            Colors.white,
            Color(0xFFF2C4B4),
            Color(0xFFD99A8C),
            Color(0xFFF7DCD0),
            Colors.white,
          ],
        ).createShader(Rect.fromCircle(center: c, radius: 50)),
    );
  }

  @override
  bool shouldRepaint(_MedallionPainter oldDelegate) => false;
}
