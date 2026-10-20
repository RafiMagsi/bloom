import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/bloom_theme.dart';
import '../widgets/bloom_bottom_nav.dart';
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
          const _PetalBackdrop(),
          _FadeThroughStack(
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
      bottomNavigationBar: BloomBottomNav(
        index: _index,
        onChanged: _go,
      ),
    );
  }
}

/// Like [IndexedStack] (every tab keeps its state) but switching tabs plays a
/// Material "fade through": the old tab fades out quickly, the new one fades
/// in while gently scaling up and rising into place — and its content
/// cascades in via [EntranceScope] / [Reveal].
class _FadeThroughStack extends StatefulWidget {
  const _FadeThroughStack({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<_FadeThroughStack> createState() => _FadeThroughStackState();
}

class _FadeThroughStackState extends State<_FadeThroughStack>
    with TickerProviderStateMixin {
  late final AnimationController _switch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  );
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();
  late int _previous = widget.index;

  @override
  void didUpdateWidget(_FadeThroughStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _previous = oldWidget.index;
      _switch.forward(from: 0);
      _entrance.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _switch.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _switch,
      builder: (context, _) {
        final t = _switch.value;
        final animating = t < 1;
        final fadeOut = 1 - Curves.easeOut.transform((t / 0.35).clamp(0.0, 1.0));
        final fadeIn = Curves.easeOutCubic
            .transform(((t - 0.25) / 0.75).clamp(0.0, 1.0));

        return Stack(
          fit: StackFit.expand,
          children: List.generate(widget.children.length, (i) {
            final active = i == widget.index;
            final outgoing = animating && i == _previous && !active;
            final visible = active || outgoing;
            final entering = active && animating;
            final opacity = entering ? fadeIn : (outgoing ? fadeOut : 1.0);
            final rise = entering ? 1 - fadeIn : 0.0;
            // One fixed wrapper shape so tabs never lose their state.
            return Offstage(
              offstage: !visible,
              child: TickerMode(
                enabled: visible,
                child: IgnorePointer(
                  ignoring: !active,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(0, rise * 14),
                      child: Transform.scale(
                        scale: 1 - 0.03 * rise,
                        child: EntranceScope(
                          animation: active
                              ? _entrance
                              : kAlwaysCompleteAnimation,
                          child: widget.children[i],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Airy background behind every tab: soft rose and orchid glows on petal
/// white, so screens feel lit rather than flat.
class _PetalBackdrop extends StatelessWidget {
  const _PetalBackdrop();

  @override
  Widget build(BuildContext context) {
    Widget glow(Color color, double size) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        );
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -140,
            right: -120,
            child: glow(const Color(0xFFFFD9E4), 420),
          ),
          Positioned(
            top: 260,
            left: -170,
            child: glow(const Color(0xFFF1E1FA), 380),
          ),
          Positioned(
            bottom: -160,
            right: -90,
            child: glow(const Color(0xFFFFE3EC), 360),
          ),
        ],
      ),
    );
  }
}
