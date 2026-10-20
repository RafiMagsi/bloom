import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/habit.dart';
import '../state/bloom_scope.dart';
import '../theme/bloom_theme.dart';
import '../widgets/add_habit_sheet.dart';
import '../widgets/habit_glyph.dart';
import '../widgets/motion.dart';

/// Hero tags shared by [HabitTile] and the detail page.
String habitCardTag(String id) => 'habit-card-$id';
String habitGlyphTag(String id) => 'habit-glyph-$id';

/// Opens a habit's story: the tile's card and icon fly up into the header
/// (Hero), and the details cascade in beneath.
Future<void> openHabitDetail(BuildContext context, Habit habit) {
  HapticFeedback.lightImpact();
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 560),
      reverseTransitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, _, _) => HabitDetailScreen(habitId: habit.id),
      transitionsBuilder: (context, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    ),
  );
}

/// The card shape that flies during the Hero — content-free so nothing is
/// squeezed mid-flight.
Widget habitCardShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromContext,
  BuildContext toContext,
) {
  return Material(
    color: Colors.transparent,
    child: Container(
      decoration: BoxDecoration(
        color: BloomPalette.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: BloomPalette.blushDeep.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
    ),
  );
}

/// The icon scales smoothly between sizes during the Hero.
Widget habitGlyphShuttle(String emoji) =>
    FittedBox(child: HabitGlyph(emoji: emoji, size: 96));

class HabitDetailScreen extends StatelessWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final String habitId;

  @override
  Widget build(BuildContext context) {
    final controller = BloomScope.of(context);
    final habit = controller.habits.where((h) => h.id == habitId).firstOrNull;
    if (habit == null) {
      // Deleted while open — just close.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const Scaffold(backgroundColor: BloomPalette.cream);
    }
    final glyph = glyphFor(habit.emoji);
    final tint = glyph?.tint ?? BloomPalette.blushDeep;
    final doneToday = controller.isDone(habit.id);
    final streak = controller.habitStreak(habit.id);
    final month = controller.habitDaysInLast(habit.id, 30);
    final morning = habit.routine == RoutineType.morning;
    final route = ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation;

    return Scaffold(
      backgroundColor: BloomPalette.cream,
      body: EntranceScope(
        animation: route,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Row(
                children: [
                  _RoundButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  _RoundButton(
                    icon: Icons.edit_rounded,
                    onTap: () => showAddHabitSheet(
                      context,
                      controller: controller,
                      routine: habit.routine,
                      editing: habit,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ---- Hero header ---------------------------------------------
              // Card background and icon are sibling Heroes (heroes can't
              // nest); the tile's card grows into this one.
              Stack(
                children: [
                  Positioned.fill(
                    child: Hero(
                      tag: habitCardTag(habit.id),
                      flightShuttleBuilder: habitCardShuttle,
                      child: Container(
                        decoration: BoxDecoration(
                          color: BloomPalette.card,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: tint.withValues(alpha: 0.16),
                              blurRadius: 30,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                    child: Column(
                      children: [
                        Hero(
                          tag: habitGlyphTag(habit.id),
                          flightShuttleBuilder: (_, _, _, _, _) =>
                              habitGlyphShuttle(habit.emoji),
                          child: HabitGlyph(emoji: habit.emoji, size: 96),
                        ),
                        const SizedBox(height: 16),
                        Reveal(
                          order: 1,
                          child: Text(
                            habit.name,
                            textAlign: TextAlign.center,
                            style: BloomText.h1(),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Reveal(
                          order: 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                morning
                                    ? Icons.wb_sunny_rounded
                                    : Icons.nightlight_round,
                                size: 16,
                                color: morning
                                    ? const Color(0xFFE5A93A)
                                    : BloomPalette.orchidDeep,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                morning ? 'Morning ritual' : 'Evening ritual',
                                style: BloomText.small(
                                  color: BloomPalette.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ---- Stats -----------------------------------------------------
              Reveal(
                order: 3,
                child: Row(
                  children: [
                    _Stat(
                      icon: Icons.local_fire_department_rounded,
                      tint: const Color(0xFFF2A07E),
                      value: '$streak',
                      label: 'day streak',
                    ),
                    const SizedBox(width: 10),
                    _Stat(
                      icon: Icons.calendar_month_rounded,
                      tint: tint,
                      value: '$month/30',
                      label: 'last 30 days',
                    ),
                    const SizedBox(width: 10),
                    _Stat(
                      icon: Icons.insights_rounded,
                      tint: BloomPalette.orchidDeep,
                      value: '${(month / 30 * 100).round()}%',
                      label: 'consistency',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ---- Five-week history -----------------------------------------
              Reveal(
                order: 4,
                child: _History(habitId: habit.id, tint: tint),
              ),
              const SizedBox(height: 20),

              // ---- Today -------------------------------------------------------
              Reveal(
                order: 5,
                child: _TodayButton(
                  done: doneToday,
                  onTap: () => controller.toggleHabit(habit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BloomPalette.card,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: BloomPalette.ink),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.tint,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color tint;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: BloomPalette.card,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            IconTile(icon: icon, tint: tint, size: 32),
            const SizedBox(height: 8),
            Text(value, style: BloomText.display(22, wght: 700)),
            Text(
              label,
              textAlign: TextAlign.center,
              style: BloomText.body(
                11.5,
                wght: 700,
                color: BloomPalette.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 35 small blooms, Monday-first, one per day; filled when kept.
class _History extends StatelessWidget {
  const _History({required this.habitId, required this.tint});

  final String habitId;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final controller = BloomScope.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final first = DateTime(
      today.year,
      today.month,
      today.day + 7 - today.weekday - 34,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: BloomPalette.card,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last five weeks', style: BloomText.h3()),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final l in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Center(
                    child: Text(
                      l,
                      style: BloomText.body(
                        11.5,
                        wght: 800,
                        color: BloomPalette.inkSoft,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (var w = 0; w < 5; w++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  for (var d = 0; d < 7; d++)
                    Expanded(
                      child: Center(
                        child: Builder(
                          builder: (context) {
                            final day = DateTime(
                              first.year,
                              first.month,
                              first.day + w * 7 + d,
                            );
                            final future = day.isAfter(today);
                            final done =
                                !future && controller.habitDoneOn(habitId, day);
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: done
                                    ? tint
                                    : future
                                    ? Colors.transparent
                                    : Color.lerp(tint, Colors.white, 0.85),
                                border: day == today
                                    ? Border.all(
                                        color: BloomPalette.ink.withValues(
                                          alpha: 0.6,
                                        ),
                                        width: 1.6,
                                      )
                                    : future
                                    ? Border.all(color: BloomPalette.creamDeep)
                                    : null,
                              ),
                              child: done
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            );
                          },
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

class _TodayButton extends StatelessWidget {
  const _TodayButton({required this.done, required this.onTap});

  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        // Gradient → gradient so the colour change blends smoothly.
        gradient: done
            ? const LinearGradient(
                colors: [BloomPalette.orchidSoft, BloomPalette.orchidSoft],
              )
            : BloomTheme.blushGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: done
            ? null
            : [
                BoxShadow(
                  color: BloomPalette.blushDeep.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('habit-detail-toggle'),
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: SizedBox(
            height: 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  done ? Icons.check_circle_rounded : Icons.add_circle_rounded,
                  color: done ? BloomPalette.orchidDeep : Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  done ? 'Done today — lovely' : 'Mark as done today',
                  style: BloomText.button(
                    color: done ? BloomPalette.orchidDeep : Colors.white,
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
