import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/bloom_content.dart';

/// Full-screen confetti burst + message for milestone moments.
class ConfettiCelebration {
  ConfettiCelebration._();

  static void show(BuildContext context, {String message = 'Beautiful work 🌸'}) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ConfettiView(
        message: message,
        onFinished: () {
          try {
            entry.remove();
          } catch (_) {
            // Overlay may already be gone when the route changes.
          }
        },
      ),
    );
    overlay.insert(entry);
  }
}

class _ConfettiView extends StatefulWidget {
  const _ConfettiView({required this.message, required this.onFinished});

  final String message;
  final VoidCallback onFinished;

  @override
  State<_ConfettiView> createState() => _ConfettiViewState();
}

class _ConfettiViewState extends State<_ConfettiView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final math.Random _random = math.Random(20261020);
  Size _size = Size.zero;
  List<_ConfettiPiece> _pieces = const [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onFinished();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_ConfettiPiece> _buildPieces(Size size) {
    final origin = Offset(size.width / 2, size.height * 0.56);
    return List.generate(56, (i) {
      final angle = -math.pi / 2 + (_random.nextDouble() - 0.5) * math.pi * 1.35;
      final speed = size.width * (0.45 + _random.nextDouble() * 0.75);
      return _ConfettiPiece(
        origin: origin,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        size: 6 + _random.nextDouble() * 8,
        color: confettiColors()[i % confettiColors().length],
        spin: (_random.nextDouble() - 0.5) * 9,
        phase: _random.nextDouble(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        type: MaterialType.transparency,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            if (size != _size) {
              _size = size;
              _pieces = _buildPieces(size);
            }
            final messageIn = CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.04, 0.24, curve: Curves.easeOutBack),
            );
            final messageOut = CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.78, 0.98, curve: Curves.easeIn),
            );
            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _ConfettiPainter(_controller, _pieces),
                ),
                Center(
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0, end: 1)
                        .animate(messageIn)
                        .drive(Tween<double>(begin: 1, end: 1)),
                    child: FadeTransition(
                      opacity: ReverseAnimation(messageOut),
                      child: ScaleTransition(
                        scale: messageIn,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 26,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Text(
                            widget.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'CormorantGaramond',
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF453A3F),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ConfettiPiece {
  _ConfettiPiece({
    required this.origin,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.spin,
    required this.phase,
  });

  final Offset origin;
  final double vx;
  final double vy;
  final double size;
  final Color color;
  final double spin;
  final double phase;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.animation, this.pieces) : super(repaint: animation);

  final Animation<double> animation;
  final List<_ConfettiPiece> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value * 1.7; // seconds
    if (t <= 0) return;
    final fade = (1 - ((animation.value - 0.72) / 0.28).clamp(0.0, 1.0))
        .clamp(0.0, 1.0);

    for (final p in pieces) {
      final x = p.origin.dx + p.vx * t;
      final y = p.origin.dy + p.vy * t + 0.5 * 1150 * t * t;
      if (y > size.height + 30 || x < -40 || x > size.width + 40) continue;

      final localFade =
          (fade * (0.65 + 0.35 * ((p.phase + animation.value) % 1)))
              .clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: localFade);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: p.size,
        height: p.size * 0.62,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => false;
}
