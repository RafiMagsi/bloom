import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../state/bloom_scope.dart';
import '../theme/bloom_theme.dart';
import '../widgets/bloom_painter.dart';
import 'bloom_shell.dart';

/// 01 — Welcome: brand introduction, hero illustration, "Start Your Reset".
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _bob;

  static const List<List<String>> _features = [
    ['🌸', 'A dashboard that makes progress feel beautiful'],
    ['💗', 'Mood check-ins that feel like a hug'],
    ['🌿', 'A 30-day reset, one small goal at a time'],
  ];

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _bob.dispose();
    super.dispose();
  }

  Widget _enter(int index, Widget child) {
    final start = index * 0.11;
    final anim = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, math.min(1, start + 0.45), curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  Future<void> _start() async {
    final controller = BloomScope.of(context);
    await controller.completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(fadeRoute(const BloomShell()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BloomPalette.cream,
      body: Stack(
        children: [
          // Soft brand washes.
          Positioned(
            top: -110,
            right: -90,
            child: _blob(340, const Color(0xFFFCE7EE)),
          ),
          Positioned(
            bottom: -120,
            left: -100,
            child: _blob(320, const Color(0xFFE7F0E8)),
          ),
          Positioned(
            top: 240,
            left: -70,
            child: _blob(180, const Color(0xFFFFF1DE)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _enter(
                      0,
                      Text(
                        'DROPTICKS AI PRESENTS',
                        style: BloomText.overline(
                          color: BloomPalette.inkSoft,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _enter(
                      1,
                      AnimatedBuilder(
                        animation: _bob,
                        builder: (context, child) {
                          final t = _bob.value * 2 * math.pi;
                          return Transform.translate(
                            offset: Offset(0, math.sin(t) * 9),
                            child: Transform.rotate(
                              angle: math.sin(t) * 0.035,
                              child: child,
                            ),
                          );
                        },
                        child: const BloomRosette(size: 216),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _enter(
                      2,
                      Text(
                        'Bloom',
                        style: BloomText.display(
                          72,
                          wght: 700,
                          letterSpacing: -1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _enter(
                      3,
                      Text(
                        'Small habits. Softer days. A better you.',
                        textAlign: TextAlign.center,
                        style: BloomText.display(
                          21,
                          wght: 600,
                          fontStyle: FontStyle.italic,
                          color: BloomPalette.blushDeep,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    _enter(
                      4,
                      Column(
                        children: _features
                            .map(
                              (f) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: BloomPalette.card,
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          BloomPalette.ink.withValues(alpha: 0.05),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Text(f[0],
                                        style: const TextStyle(fontSize: 20)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        f[1],
                                        style: BloomText.small(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _enter(
                      5,
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: BloomTheme.blushGradient,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: BloomPalette.blushDeep
                                  .withValues(alpha: 0.45),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: const Key('start-reset'),
                            onTap: _start,
                            borderRadius: BorderRadius.circular(30),
                            child: SizedBox(
                              height: 60,
                              child: Center(
                                child: Text(
                                  'Start Your Reset',
                                  style: BloomText.button(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _enter(
                      6,
                      Column(
                        children: [
                          Text(
                            'No signup · everything stays on your phone',
                            style: BloomText.caption(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Made with 💗 by DropTicks AI',
                            style: BloomText.overline(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }
}
