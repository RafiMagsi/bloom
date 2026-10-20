import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/habit.dart';
import '../theme/bloom_theme.dart';
import '../screens/habit_detail_screen.dart';
import 'habit_glyph.dart';

/// A habit row with a satisfying spring pop when checked off.
class HabitTile extends StatelessWidget {
  const HabitTile({
    super.key,
    required this.habit,
    required this.done,
    required this.onTap,
    this.onEdit,
    this.onOpen,
  });

  final Habit habit;
  final bool done;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  /// Opens the habit's detail page (tap the icon, or long-press the row).
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('habit-${habit.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      onLongPress: onOpen,
      // The card background is its own Hero (heroes can't nest), so it can
      // grow into the detail header while the icon flies separately.
      child: Stack(
        children: [
          Positioned.fill(
            child: Hero(
              tag: habitCardTag(habit.id),
              flightShuttleBuilder: habitCardShuttle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: done ? BloomPalette.orchidSoft : BloomPalette.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: done
                        ? BloomPalette.orchid.withValues(alpha: 0.45)
                        : BloomPalette.ink.withValues(alpha: 0.05),
                  ),
                  boxShadow: done
                      ? null
                      : [
                          BoxShadow(
                            color: BloomPalette.ink.withValues(alpha: 0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onOpen,
                  child: Hero(
                    tag: habitGlyphTag(habit.id),
                    flightShuttleBuilder: (_, _, _, _, _) =>
                        habitGlyphShuttle(habit.emoji),
                    child: HabitGlyph(emoji: habit.emoji, size: 40),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: done
                        ? BloomText.cardTitle(
                            color: BloomPalette.inkSoft,
                          ).copyWith(
                            decoration: TextDecoration.lineThrough,
                            decorationColor: BloomPalette.orchidDeep,
                            decorationThickness: 1.6,
                          )
                        : BloomText.cardTitle(),
                    child: Text(
                      habit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.edit_rounded,
                      size: 17,
                      color: BloomPalette.inkSoft.withValues(alpha: 0.8),
                    ),
                  ),
                const SizedBox(width: 6),
                // Spring pop driven by the done flag (both directions), with a
                // burst of petals the moment it's checked off.
                _PetalBurst(
                  play: done,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: done ? 1 : 0),
                    duration: const Duration(milliseconds: 430),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      final pulse =
                          1.0 + 0.13 * math.sin(math.min(value, 1.0) * math.pi);
                      return Transform.scale(scale: pulse, child: child);
                    },
                    child: AnimatedContainer(
                      key: done ? Key('habit-done-${habit.id}') : null,
                      duration: const Duration(milliseconds: 260),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? BloomPalette.orchidDeep
                            : Colors.transparent,
                        border: Border.all(
                          color: done
                              ? BloomPalette.orchidDeep
                              : BloomPalette.blush.withValues(alpha: 0.55),
                          width: 1.7,
                        ),
                      ),
                      child: Icon(
                        done ? Icons.check_rounded : Icons.add_rounded,
                        size: 18,
                        color: done
                            ? Colors.white
                            : BloomPalette.blushDeep.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Petals and a soft ring that burst out of the check circle when [play]
/// turns on. Paints outside its bounds; never on first build.
class _PetalBurst extends StatefulWidget {
  const _PetalBurst({required this.play, required this.child});

  final bool play;
  final Widget child;

  @override
  State<_PetalBurst> createState() => _PetalBurstState();
}

class _PetalBurstState extends State<_PetalBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  @override
  void didUpdateWidget(_PetalBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) _burst.forward(from: 0);
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _BurstPainter(_burst),
      child: widget.child,
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t) : super(repaint: t);

  final Animation<double> t;

  static const _colors = [
    Color(0xFFF7A9C0),
    BloomPalette.blushDeep,
    BloomPalette.orchid,
    Color(0xFFF6C177),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    if (v <= 0 || v >= 1) return;
    final c = size.center(Offset.zero);
    final reach = Curves.easeOutCubic.transform(v);
    final fade = 1 - Curves.easeIn.transform(v);

    canvas.drawCircle(
      c,
      size.width / 2 + reach * 14,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * fade
        ..color = BloomPalette.orchid.withValues(alpha: 0.6 * fade),
    );
    for (var i = 0; i < 10; i++) {
      final angle = i * 2 * math.pi / 10 + (i.isEven ? 0.12 : -0.08);
      final dist = size.width / 2 + reach * (20 + (i % 3) * 6);
      final p = c + Offset(math.cos(angle), math.sin(angle)) * dist;
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(angle + v * 3);
      final s = 4.5 * (1 - v * 0.4);
      final petal = Path()
        ..moveTo(0, -s)
        ..quadraticBezierTo(s * 0.8, 0, 0, s)
        ..quadraticBezierTo(-s * 0.8, 0, 0, -s)
        ..close();
      canvas.drawPath(
        petal,
        Paint()..color = _colors[i % _colors.length].withValues(alpha: fade),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) => false;
}
