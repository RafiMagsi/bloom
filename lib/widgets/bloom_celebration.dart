import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/bloom_theme.dart';
import 'bloom_painter.dart';

/// Full-screen "You bloomed today" moment for finishing every ritual:
/// a blush veil, the Bloom mark unfurling and a soft petal shower.
/// Tap anywhere to close; it also settles away on its own.
class BloomCelebration {
  BloomCelebration._();

  static void show(
    BuildContext context, {
    required String name,
    required int rituals,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _BloomCelebrationView(
        name: name,
        rituals: rituals,
        onDone: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }
}

class _Petal {
  _Petal(math.Random r)
      : x = r.nextDouble(),
        delay = r.nextDouble() * 0.35,
        speed = 0.55 + r.nextDouble() * 0.6,
        sway = 12 + r.nextDouble() * 26,
        spin = (r.nextDouble() - 0.5) * 8,
        size = 7 + r.nextDouble() * 9,
        color = const [
          Color(0xFFF7B6C9),
          Color(0xFFF08FB0),
          Color(0xFFE9C2F0),
          Color(0xFFC79BE0),
          Color(0xFFF6D29A),
          Colors.white,
        ][r.nextInt(6)];

  final double x, delay, speed, sway, spin, size;
  final Color color;
}

class _BloomCelebrationView extends StatefulWidget {
  const _BloomCelebrationView({
    required this.name,
    required this.rituals,
    required this.onDone,
  });

  final String name;
  final int rituals;
  final VoidCallback onDone;

  @override
  State<_BloomCelebrationView> createState() => _BloomCelebrationViewState();
}

class _BloomCelebrationViewState extends State<_BloomCelebrationView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  )
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    })
    ..forward();
  final List<_Petal> _petals = () {
    final r = math.Random(7);
    return List.generate(42, (_) => _Petal(r));
  }();
  bool _closing = false;

  void _close() {
    if (_closing) return;
    _closing = true;
    // Jump to the fade-out section.
    if (_t.value < 0.82) _t.value = 0.82;
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  double _seg(double a, double b, [Curve c = Curves.easeOutCubic]) =>
      c.transform(((_t.value - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final who = widget.name.trim().isEmpty ? '' : ', ${widget.name.trim()}';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _close,
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, _) {
          final veilIn = _seg(0, 0.12);
          final out = _seg(0.82, 1, Curves.easeIn);
          final veil = veilIn * (1 - out);
          final mark = _seg(0.04, 0.32, Curves.elasticOut);
          final text = _seg(0.2, 0.4);
          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: BloomPalette.petalMist.withValues(alpha: 0.86 * veil),
              ),
              CustomPaint(
                painter: _PetalShower(_petals, _t.value, 1 - out),
              ),
              Center(
                child: Opacity(
                  opacity: (1 - out).clamp(0.0, 1.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.rotate(
                        angle: (1 - mark) * -0.9,
                        child: Transform.scale(
                          scale: 0.2 + 0.8 * mark,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF6C177)
                                      .withValues(alpha: 0.45 * mark),
                                  blurRadius: 60,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: const BloomMark(
                              size: 150,
                              tile: true,
                              cornerRadius: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      Opacity(
                        opacity: text,
                        child: Transform.translate(
                          offset: Offset(0, (1 - text) * 16),
                          child: Column(
                            children: [
                              Text(
                                'You bloomed today$who',
                                textAlign: TextAlign.center,
                                style: BloomText.display(
                                  30,
                                  wght: 600,
                                  color: BloomPalette.mauveInk,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'All ${widget.rituals} rituals done — '
                                'be proud of yourself 🌸',
                                textAlign: TextAlign.center,
                                style: BloomText.body(
                                  15,
                                  wght: 700,
                                  color: BloomPalette.blushDeep,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PetalShower extends CustomPainter {
  _PetalShower(this.petals, this.t, this.opacity);

  final List<_Petal> petals;
  final double t;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    for (final p in petals) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final y = -40 + local * p.speed * (size.height + 120);
      final x = p.x * size.width + math.sin(local * 6 + p.x * 9) * p.sway;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * local + p.x * 6);
      final petal = Path()
        ..moveTo(0, -p.size)
        ..quadraticBezierTo(p.size * 0.7, -p.size * 0.2, 0, p.size * 0.6)
        ..quadraticBezierTo(-p.size * 0.7, -p.size * 0.2, 0, -p.size)
        ..close();
      canvas.drawPath(
        petal,
        Paint()..color = p.color.withValues(alpha: 0.9 * opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PetalShower oldDelegate) =>
      oldDelegate.t != t || oldDelegate.opacity != opacity;
}
