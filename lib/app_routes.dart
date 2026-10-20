import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Soft fade + slight rise transition used between top-level screens.
Route<T> fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 430),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Petal-reveal: the next page blooms out of [origin] (global position, e.g.
/// the tapped button) inside an expanding circle edged with a rosy glow,
/// settling from a slight zoom.
Route<T> bloomRevealRoute<T>(Widget page, {required Offset origin}) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 950),
    reverseTransitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final reveal = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
      );
      final settle = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.25, 1, curve: Curves.easeOutCubic),
      );
      return AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) {
          final size = MediaQuery.sizeOf(context);
          final far = [
            Offset.zero,
            Offset(size.width, 0),
            Offset(0, size.height),
            Offset(size.width, size.height),
          ].map((c) => (c - origin).distance).reduce(math.max);
          // +2 so the fully-open circle never trims a corner pixel.
          final radius = (far + 2) * reveal.value;
          // Keep one tree shape throughout so the page keeps its state.
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipPath(
                clipper: _CircleClipper(origin, radius),
                child: Transform.scale(
                  scale: 1.06 - 0.06 * settle.value,
                  child: Opacity(
                    opacity: (0.35 + 0.65 * settle.value).clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: _RevealGlowPainter(
                    origin,
                    radius,
                    1 - Curves.easeIn.transform(animation.value),
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

class _CircleClipper extends CustomClipper<Path> {
  _CircleClipper(this.center, this.radius);

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: center, radius: radius));

  @override
  bool shouldReclip(_CircleClipper oldClipper) =>
      oldClipper.radius != radius || oldClipper.center != center;
}

class _RevealGlowPainter extends CustomPainter {
  _RevealGlowPainter(this.center, this.radius, this.strength);

  final Offset center;
  final double radius;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    if (strength <= 0 || radius <= 0) return;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF7C9D2).withValues(alpha: 0),
          const Color(0xFFF2A9B8).withValues(alpha: 0.75 * strength),
          Colors.white.withValues(alpha: 0.9 * strength),
          const Color(0xFFF7C9D2).withValues(alpha: 0),
        ],
        stops: const [0.0, 0.88, 0.96, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius + 13))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, radius, ring);
  }

  @override
  bool shouldRepaint(_RevealGlowPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.strength != strength;
}
