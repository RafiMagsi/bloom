import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/bloom_content.dart';
import '../theme/bloom_theme.dart';
import 'motion.dart';

/// Portrait for each achievement (Unsplash License — see README).
const Map<String, String> kAchievementPhotos = {
  'first-bloom': 'assets/images/ach_first_bloom.jpg',
  'week-of-glow': 'assets/images/ach_week_of_glow.jpg',
  'steady-rhythm': 'assets/images/ach_steady_rhythm.jpg',
  'heart-listener': 'assets/images/ach_heart_listener.jpg',
  'halfway-bloom': 'assets/images/ach_halfway_bloom.jpg',
  'fully-bloomed': 'assets/images/ach_fully_bloomed.jpg',
};

const Map<String, IconData> kAchievementIcons = {
  'first-bloom': Icons.eco_rounded,
  'week-of-glow': Icons.local_fire_department_rounded,
  'steady-rhythm': Icons.auto_awesome_rounded,
  'heart-listener': Icons.favorite_rounded,
  'halfway-bloom': Icons.spa_rounded,
  'fully-bloomed': Icons.local_florist_rounded,
};

/// A photo card for one achievement: full colour and glowing once earned;
/// softened, muted and locked (with progress) until then.
class AchievementCard extends StatefulWidget {
  const AchievementCard({
    super.key,
    required this.achievement,
    required this.unlocked,
    required this.value,
  });

  final Achievement achievement;
  final bool unlocked;

  /// Current metric value (e.g. streak days) towards the target.
  final int value;

  @override
  State<AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<AchievementCard> {
  bool _pressed = false;

  static const List<double> _muted = [
    // ~20% saturation with a faint rose cast.
    0.40, 0.48, 0.12, 0, 14,
    0.26, 0.62, 0.12, 0, 4,
    0.26, 0.48, 0.26, 0, 10,
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    final a = widget.achievement;
    final unlocked = widget.unlocked;
    final entrance =
        EntranceScope.maybeOf(context) ?? kAlwaysCompleteAnimation;
    final settle = CurvedAnimation(
      parent: entrance,
      curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
    );
    final progress = (widget.value / a.target).clamp(0.0, 1.0);

    Widget photo = Image.asset(
      kAchievementPhotos[a.id] ?? kAchievementPhotos.values.first,
      fit: BoxFit.cover,
      alignment: const Alignment(0, -0.3),
      width: double.infinity,
      height: double.infinity,
      cacheWidth: 520,
      gaplessPlayback: true,
    );
    if (!unlocked) {
      photo = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 1.6, sigmaY: 1.6),
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(_muted),
          child: photo,
        ),
      );
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: HapticFeedback.selectionClick,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 160),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: (unlocked ? BloomPalette.blushDeep : BloomPalette.ink)
                    .withValues(alpha: unlocked ? 0.3 : 0.08),
                blurRadius: unlocked ? 22 : 14,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // The photo settles from a gentle zoom as the screen arrives.
                AnimatedBuilder(
                  animation: settle,
                  builder: (context, child) => Transform.scale(
                    scale: 1.14 - 0.14 * settle.value,
                    child: child,
                  ),
                  child: photo,
                ),
                if (!unlocked)
                  ColoredBox(color: Colors.white.withValues(alpha: 0.18)),
                // Legibility gradient for the text.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        BloomPalette.mauveInk.withValues(alpha: 0.15),
                        BloomPalette.mauveInk.withValues(alpha: 0.82),
                      ],
                      stops: const [0.35, 0.55, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Badge(
                            icon: kAchievementIcons[a.id] ??
                                Icons.auto_awesome_rounded,
                            unlocked: unlocked,
                          ),
                          const Spacer(),
                          _Chip(
                            unlocked
                                ? 'Unlocked'
                                : '${widget.value.clamp(0, a.target)}/${a.target}',
                            icon: unlocked
                                ? Icons.check_rounded
                                : Icons.lock_rounded,
                            highlight: unlocked,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        a.title,
                        style: BloomText.display(
                          18,
                          wght: 700,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        a.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: BloomText.body(
                          12.5,
                          wght: 700,
                          height: 1.3,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                      if (!unlocked) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (context, v, _) => LinearProgressIndicator(
                              value: v,
                              minHeight: 5,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.3),
                              valueColor: const AlwaysStoppedAnimation(
                                Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.unlocked});

  final IconData icon;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: unlocked ? BloomTheme.blushGradient : null,
        color: unlocked ? null : Colors.white.withValues(alpha: 0.75),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Icon(
        icon,
        size: 17,
        color: unlocked ? Colors.white : BloomPalette.inkSoft,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {required this.icon, required this.highlight});

  final String label;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.white.withValues(alpha: 0.92)
            : BloomPalette.mauveInk.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: highlight ? BloomPalette.blushDeep : Colors.white,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: BloomText.body(
              11,
              wght: 800,
              color: highlight ? BloomPalette.blushDeep : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
