import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/bloom_clock.dart';
import '../state/bloom_controller.dart';
import '../state/bloom_scope.dart';
import '../theme/bloom_theme.dart';
import '../widgets/bloom_bottom_nav.dart';
import '../widgets/bloom_celebration.dart';
import '../widgets/motion.dart';
import 'home_screen.dart';
import 'mood_screen.dart';
import 'progress_screen.dart';
import 'routine_screen.dart';

/// Root shell: four tabs + the frosted bottom navigation.
class BloomShell extends StatefulWidget {
  const BloomShell({super.key});

  @override
  State<BloomShell> createState() => _BloomShellState();
}

class _BloomShellState extends State<BloomShell> {
  int _index = 0;
  BloomController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = BloomScope.of(context);
    if (!identical(controller, _controller)) {
      _controller?.dayBloomed.removeListener(_celebrate);
      _controller = controller..dayBloomed.addListener(_celebrate);
    }
  }

  @override
  void dispose() {
    _controller?.dayBloomed.removeListener(_celebrate);
    super.dispose();
  }

  /// Every ritual done — the day's big moment.
  void _celebrate() {
    final controller = _controller;
    if (controller == null || !mounted) return;
    HapticFeedback.heavyImpact();
    BloomCelebration.show(
      context,
      name: controller.userName,
      rituals: controller.todayTotal,
    );
  }

  void _go(int index) {
    if (index == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BloomPalette.cream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background layer: one continuous scene that glides between tabs.
          _SceneBackdrop(index: _index),
          // Foreground layer: each tab's objects leave and arrive on their own.
          _ChoreographedStack(
            index: _index,
            children: [
              HomeScreen(onNavigate: _go),
              const RoutineScreen(),
              const MoodScreen(),
              const ProgressScreen(),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BloomBottomNav(index: _index, onChanged: _go),
    );
  }
}

/// Keeps every tab alive (like [IndexedStack]) but never fades a screen as a
/// whole. Switching tabs reverses the old tab's presence — its objects slip
/// away one by one opposite to the direction of travel — while the new tab's
/// objects stream in from the side you're heading towards. Each object is a
/// [Reveal] reading this tab's [EntranceScope].
class _ChoreographedStack extends StatefulWidget {
  const _ChoreographedStack({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<_ChoreographedStack> createState() => _ChoreographedStackState();
}

class _ChoreographedStackState extends State<_ChoreographedStack>
    with TickerProviderStateMixin {
  static const double _travel = 72;

  late final List<AnimationController> _presence = [
    for (var i = 0; i < widget.children.length; i++)
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1150),
        reverseDuration: const Duration(milliseconds: 480),
      )..addStatusListener(_onStatus),
  ];
  late final List<double> _drift = List.filled(widget.children.length, 0);
  Timer? _intro;

  @override
  void initState() {
    super.initState();
    // First arrival: once the background has begun to dissolve in, the
    // objects rise into place (no sideways travel).
    _intro = Timer(const Duration(milliseconds: 280), () {
      if (mounted && _presence[widget.index].isDismissed) {
        _presence[widget.index].forward();
      }
    });
  }

  void _onStatus(AnimationStatus status) {
    // A tab that finished leaving can go offstage (and stop ticking).
    if (status == AnimationStatus.dismissed && mounted) setState(() {});
  }

  @override
  void didUpdateWidget(_ChoreographedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    final from = oldWidget.index, to = widget.index;
    if (from == to) return;
    final dir = to > from ? 1.0 : -1.0;
    _drift[from] = -_travel * dir; // leaves towards where we came from
    _drift[to] = _travel * dir; // arrives from where we're going
    _presence[from].reverse();
    // Arrivals are offset a beat inside [Reveal] (sideways travel), so the
    // new objects flow past the leaving ones instead of colliding.
    _presence[to].forward(from: 0);
  }

  @override
  void dispose() {
    _intro?.cancel();
    for (final c in _presence) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          Builder(
            builder: (context) {
              final active = i == widget.index;
              final presence = _presence[i];
              final visible =
                  active || presence.isAnimating || presence.value > 0;
              return Offstage(
                offstage: !visible,
                child: TickerMode(
                  enabled: visible,
                  // Only the visible tab takes part in Hero flights (Home and
                  // Routine share habit tags).
                  child: HeroMode(
                    enabled: active,
                    child: IgnorePointer(
                      ignoring: !active,
                      child: EntranceScope(
                        animation: presence,
                        drift: _drift[i],
                        child: widget.children[i],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// One glow in a background scene: position (alignment), size (fraction of
/// the screen's longest side) and colour.
class _Glow {
  const _Glow(this.x, this.y, this.size, this.color);

  final double x, y, size;
  final Color color;

  static _Glow lerp(_Glow a, _Glow b, double t) => _Glow(
    a.x + (b.x - a.x) * t,
    a.y + (b.y - a.y) * t,
    a.size + (b.size - a.size) * t,
    Color.lerp(a.color, b.color, t)!,
  );
}

/// The background layer. Each tab has its own arrangement of soft glows;
/// changing tabs glides continuously between arrangements (positions, sizes
/// and colours), with a slow counter-drift for depth. Evenings shift the
/// palette to dusk lavender and add a few stars.
class _SceneBackdrop extends StatelessWidget {
  const _SceneBackdrop({required this.index});

  final int index;

  static const List<List<_Glow>> _scenes = [
    // Home — rose morning.
    [
      _Glow(1.05, -1.05, 0.62, Color(0xFFFFD6E3)),
      _Glow(-1.15, -0.05, 0.56, Color(0xFFF1E1FA)),
      _Glow(0.95, 1.05, 0.52, Color(0xFFFFE3EC)),
    ],
    // Routine — warm peach.
    [
      _Glow(-1.0, -1.0, 0.6, Color(0xFFFFE1D3)),
      _Glow(1.15, 0.05, 0.54, Color(0xFFFFD6E3)),
      _Glow(-0.55, 1.1, 0.55, Color(0xFFF6E3FA)),
    ],
    // Mood — dreamy lilac.
    [
      _Glow(0.25, -1.15, 0.68, Color(0xFFEADCF9)),
      _Glow(-1.15, 0.5, 0.52, Color(0xFFFFDCE8)),
      _Glow(1.1, 0.75, 0.56, Color(0xFFF1E2FB)),
    ],
    // Progress — rose gold.
    [
      _Glow(1.05, -0.55, 0.6, Color(0xFFFFE0D4)),
      _Glow(-1.05, -1.0, 0.54, Color(0xFFFAD8E5)),
      _Glow(0.0, 1.15, 0.64, Color(0xFFEFE0FA)),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final evening = BloomClock.isEvening;
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: index.toDouble()),
        duration: const Duration(milliseconds: 1250),
        curve: Curves.easeInOutCubic,
        builder: (context, pos, _) => CustomPaint(
          painter: _ScenePainter(pos, evening),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.pos, this.evening);

  /// Fractional tab position, e.g. 1.4 = 40% of the way from tab 1 to 2.
  final double pos;
  final bool evening;

  static const _dusk = Color(0xFFE2CDF4);

  @override
  void paint(Canvas canvas, Size size) {
    if (evening) {
      final sky = Offset.zero & size;
      canvas.drawRect(
        sky,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF1E4F7), BloomPalette.cream],
            stops: [0.0, 0.55],
          ).createShader(sky),
      );
    }

    final scenes = _SceneBackdrop._scenes;
    final a = pos.floor().clamp(0, scenes.length - 1);
    final b = (a + 1).clamp(0, scenes.length - 1);
    final t = pos - a;
    final longest = size.longestSide;
    // Background counter-drift: slower than the foreground, opposite way.
    final parallax = -pos * 26;

    for (var i = 0; i < scenes[a].length; i++) {
      var g = _Glow.lerp(scenes[a][i], scenes[b][i], t);
      if (evening) {
        g = _Glow(g.x, g.y, g.size, Color.lerp(g.color, _dusk, 0.55)!);
      }
      final c = Offset(
        size.width / 2 + g.x * size.width / 2 + parallax,
        size.height / 2 + g.y * size.height / 2,
      );
      final r = g.size * longest;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [g.color, g.color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    if (evening) _stars(canvas, size, parallax * 0.5);
  }

  static const _starField = [
    (0.12, 0.05, 3.2),
    (0.3, 0.11, 2.0),
    (0.52, 0.04, 2.6),
    (0.7, 0.09, 3.6),
    (0.88, 0.16, 2.2),
    (0.22, 0.2, 1.8),
    (0.62, 0.22, 2.0),
    (0.93, 0.05, 1.8),
    (0.42, 0.17, 1.6),
  ];

  void _stars(Canvas canvas, Size size, double shift) {
    final paint = Paint()
      ..color = const Color(0xFFB79BE0).withValues(alpha: 0.55);
    for (final (x, y, r) in _starField) {
      final at = Offset(x * size.width + shift, y * size.height);
      final path = Path()
        ..moveTo(at.dx, at.dy - r * 2)
        ..quadraticBezierTo(at.dx, at.dy, at.dx + r * 2, at.dy)
        ..quadraticBezierTo(at.dx, at.dy, at.dx, at.dy + r * 2)
        ..quadraticBezierTo(at.dx, at.dy, at.dx - r * 2, at.dy)
        ..quadraticBezierTo(at.dx, at.dy, at.dx, at.dy - r * 2)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_ScenePainter oldDelegate) =>
      oldDelegate.pos != pos || oldDelegate.evening != evening;
}
