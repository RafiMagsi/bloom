import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/bloom_theme.dart';

/// Bloom's shared motion language — one set of timings and curves so every
/// screen moves the same, soft way.
class BloomMotion {
  BloomMotion._();

  static const Curve settle = Curves.easeOutCubic;
  static const Curve glide = Curves.easeInOutCubic;

  /// Bottom sheets: an unhurried rise, a quicker exit.
  static const AnimationStyle sheet = AnimationStyle(
    duration: Duration(milliseconds: 460),
    reverseDuration: Duration(milliseconds: 280),
  );

  /// Mauve scrim behind sheets instead of flat grey.
  static Color get scrim => BloomPalette.mauveInk.withValues(alpha: 0.32);
}

/// Hands a screen its entrance animation (0 → 1). The shell replays it every
/// time a tab is opened; [Reveal]s below pick it up.
class EntranceScope extends InheritedWidget {
  const EntranceScope({
    super.key,
    required this.animation,
    required super.child,
  });

  final Animation<double> animation;

  static Animation<double>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EntranceScope>()?.animation;

  @override
  bool updateShouldNotify(EntranceScope oldWidget) =>
      oldWidget.animation != animation;
}

/// Floats its child up and in, a beat after the item before it ([order]).
class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.order, required this.child});

  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final parent = EntranceScope.maybeOf(context);
    if (parent == null) return child;
    final start = (order * 0.055).clamp(0.0, 0.5);
    final t = CurvedAnimation(
      parent: parent,
      curve: Interval(start, start + 0.5, curve: BloomMotion.settle),
    );
    return AnimatedBuilder(
      animation: t,
      child: child,
      builder: (context, child) => Opacity(
        opacity: t.value,
        child: Transform.translate(
          offset: Offset(0, (1 - t.value) * 26),
          child: Transform.scale(scale: 0.985 + 0.015 * t.value, child: child),
        ),
      ),
    );
  }
}

/// Wraps each item of a screen's list in a [Reveal] for a cascading entrance.
List<Widget> revealAll(List<Widget> items) => [
  for (var i = 0; i < items.length; i++) Reveal(order: i, child: items[i]),
];

/// Lets a bottom sheet's content cascade in on the sheet's own route
/// animation (and drift back out as it closes).
class SheetEntrance extends StatelessWidget {
  const SheetEntrance({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return EntranceScope(
      animation: ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation,
      child: child,
    );
  }
}

/// Two-option pill control whose white thumb glides between options.
class BloomSegmented extends StatelessWidget {
  const BloomSegmented({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.keyPrefix,
    this.verticalPadding = 12,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  /// Each option gets `Key('$keyPrefix$i')` when set.
  final String? keyPrefix;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final n = labels.length;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BloomPalette.creamDeep,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              alignment: Alignment(n == 1 ? 0 : -1 + 2 * index / (n - 1), 0),
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutBack,
              child: FractionallySizedBox(
                widthFactor: 1 / n,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: BloomPalette.card,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: BloomPalette.ink.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: List.generate(n, (i) {
              final active = i == index;
              return Expanded(
                child: GestureDetector(
                  key: keyPrefix == null ? null : Key('$keyPrefix$i'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (i == index) return;
                    HapticFeedback.selectionClick();
                    onChanged(i);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: verticalPadding),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 260),
                      style: BloomText.body(
                        14.5,
                        wght: 700,
                        color: active ? BloomPalette.ink : BloomPalette.inkSoft,
                      ),
                      child: Text(labels[i], textAlign: TextAlign.center),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Swaps content with a soft directional slide + fade, e.g. when a segment
/// changes. [direction] is +1 to come in from the right, −1 from the left.
class SlideSwitcher extends StatelessWidget {
  const SlideSwitcher({super.key, required this.child, this.direction = 1});

  final Widget child;
  final int direction;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 360),
      curve: BloomMotion.settle,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 380),
        reverseDuration: const Duration(milliseconds: 220),
        switchInCurve: BloomMotion.settle,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        transitionBuilder: (child, animation) {
          final incoming = child.key == this.child.key;
          final dx = (incoming ? 0.12 : -0.12) * direction;
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(dx, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: child,
      ),
    );
  }
}

/// Counts up to [value] when it first appears or changes.
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 1100),
  });

  final int value;
  final TextStyle style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      // Starts at 0 on first build; later changes animate from the
      // current value.
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutQuart,
      builder: (context, v, _) => Text('${v.round()}', style: style),
    );
  }
}
