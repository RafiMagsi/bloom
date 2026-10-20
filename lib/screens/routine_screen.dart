import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../state/bloom_scope.dart';
import '../theme/bloom_theme.dart';
import 'habit_detail_screen.dart';
import '../widgets/add_habit_sheet.dart';
import '../widgets/habit_tile.dart';
import '../widgets/habit_glyph.dart';
import '../widgets/motion.dart';

/// 03 — My Routine: add, edit, complete habits; morning & evening rituals.
class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    final controller = BloomScope.of(context);
    final routine =
        _segment == 0 ? RoutineType.morning : RoutineType.evening;
    final habits = controller.habitsFor(routine);
    final presets =
        _segment == 0 ? 'Morning rituals ☀️' : 'Evening rituals 🌙';

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
        children: revealAll([
          Text('MY GLOW-UP ROUTINE', style: BloomText.overline()),
          const SizedBox(height: 6),
          Text('My Routine', style: BloomText.h1()),
          const SizedBox(height: 6),
          Text(
            'Tiny rituals, done lovingly — $presets.',
            style: BloomText.text(color: BloomPalette.inkSoft),
          ),
          const SizedBox(height: 18),

          // Segmented morning / evening control.
          BloomSegmented(
            labels: const ['Morning', 'Evening'],
            icons: const [Icons.wb_sunny_rounded, Icons.nightlight_round],
            index: _segment,
            keyPrefix: 'routine-segment-',
            verticalPadding: 13,
            onChanged: (i) => setState(() => _segment = i),
          ),
          const SizedBox(height: 16),

          SlideSwitcher(
            direction: _segment == 0 ? -1 : 1,
            child: Column(
              key: ValueKey(_segment),
              children: habits.isEmpty
                  ? [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 34, horizontal: 22),
                        decoration: BoxDecoration(
                          color: BloomPalette.card,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          children: [
                            const Text('🌷', style: TextStyle(fontSize: 42)),
                            const SizedBox(height: 10),
                            Text(
                              'Your $_segmentName routine is a blank canvas',
                              style: BloomText.cardTitle(),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Add one small habit you will actually enjoy.',
                              style: BloomText.caption(),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ]
                  : [
                      for (final h in habits)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: HabitTile(
                            habit: h,
                            done: controller.isDone(h.id),
                            onTap: () => controller.toggleHabit(h),
                            onOpen: () => openHabitDetail(context, h),
                            onEdit: () => showAddHabitSheet(
                              context,
                              controller: controller,
                              routine: routine,
                              editing: h,
                            ),
                          ),
                        ),
                    ],
            ),
          ),
          const SizedBox(height: 8),

          // Add habit button.
          InkWell(
            key: const Key('add-habit'),
            onTap: () => showAddHabitSheet(
              context,
              controller: controller,
              routine: routine,
            ),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: BloomPalette.blush.withValues(alpha: 0.7),
                  width: 1.6,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded,
                      size: 22, color: BloomPalette.blushDeep),
                  const SizedBox(width: 8),
                  Text(
                    'Add a habit',
                    style: BloomText.button(color: BloomPalette.blushDeep),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: BloomPalette.blushSoft.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const IconTile(
                  icon: Icons.lightbulb_rounded,
                  tint: Color(0xFFE5A93A),
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Keep habits small enough to feel easy — momentum is the real glow-up.',
                    style: BloomText.small(color: BloomPalette.ink),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  String get _segmentName => _segment == 0 ? 'morning' : 'evening';
}
