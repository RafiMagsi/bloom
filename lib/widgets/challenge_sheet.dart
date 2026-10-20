import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/bloom_content.dart';
import '../state/bloom_controller.dart';
import '../state/bloom_scope.dart';
import '../theme/bloom_theme.dart';
import 'confetti_celebration.dart';
import 'motion.dart';

/// Bottom sheet for the 30-Day Reset Challenge (start, track, complete, undo).
Future<void> showChallengeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: BloomMotion.scrim,
    sheetAnimationStyle: BloomMotion.sheet,
    builder: (_) => const ChallengeSheet(),
  );
}

class ChallengeSheet extends StatelessWidget {
  const ChallengeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BloomScope.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
      decoration: const BoxDecoration(
        color: BloomPalette.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => _Body(controller: controller),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.controller});

  final BloomController controller;

  Future<void> _complete(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final unlocks = await controller.completeChallengeDay();
    if (!context.mounted) return;
    final day = controller.challengeDay;
    final completeMsgDay = day;
    if (kChallengeMilestones.contains(day)) {
      ConfettiCelebration.show(
        context,
        message: 'Day $day complete — milestone unlocked 🎉',
      );
    } else if (unlocks.isNotEmpty) {
      ConfettiCelebration.show(
        context,
        message: '${unlocks.first.emoji} ${unlocks.first.title} unlocked!',
      );
    } else {
      ConfettiCelebration.show(context, message: 'Day $completeMsgDay complete 🌸');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.challengeActive) return _Intro(controller: controller);

    final day = controller.challengeDay;
    final doneToday = controller.isChallengeDayDone(day);
    final goal = kChallengeDays[day - 1];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: BloomPalette.creamDeep,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('30-DAY RESET', style: BloomText.overline()),
                    const SizedBox(height: 4),
                    Text('Day $day of 30', style: BloomText.h2()),
                  ],
                ),
              ),
              Text('🌿', style: const TextStyle(fontSize: 34)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  BloomPalette.orchidSoft,
                  BloomPalette.orchidSoft.withValues(alpha: 0.45),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("TODAY'S SMALL GOAL", style: BloomText.overline(color: BloomPalette.orchidDeep)),
                const SizedBox(height: 8),
                Text(goal, style: BloomText.h3()),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('YOUR 30 DAYS', style: BloomText.overline()),
          const SizedBox(height: 10),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: List.generate(30, (i) {
              final n = i + 1;
              final isDone = controller.isChallengeDayDone(n);
              final isToday = n == day;
              final isFuture = n > day;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? BloomPalette.orchidDeep
                      : isToday
                          ? BloomPalette.blushSoft
                          : BloomPalette.cream,
                  border: Border.all(
                    color: isDone
                        ? BloomPalette.orchidDeep
                        : isToday
                            ? BloomPalette.blushDeep
                            : isFuture
                                ? BloomPalette.creamDeep
                                : BloomPalette.orchid.withValues(alpha: 0.5),
                    width: isToday ? 2 : 1.4,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded,
                          size: 15, color: Colors.white)
                      : Text(
                          '$n',
                          style: BloomText.body(11,
                              wght: 700,
                              color: isToday
                                  ? BloomPalette.blushDeep
                                  : isFuture
                                      ? BloomPalette.inkSoft
                                          .withValues(alpha: 0.6)
                                      : BloomPalette.orchidDeep),
                        ),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            children: kChallengeMilestones
                .map(
                  (m) => Chip(
                    avatar: Text(
                      controller.challengeDone.length >= m ? '🎉' : '🔒',
                      style: const TextStyle(fontSize: 13),
                    ),
                    label: Text(
                      'Day $m',
                      style: BloomText.small(
                        color: controller.challengeDone.length >= m
                            ? BloomPalette.orchidDeep
                            : BloomPalette.inkSoft,
                      ),
                    ),
                    backgroundColor: controller.challengeDone.length >= m
                        ? BloomPalette.orchidSoft
                        : BloomPalette.cream,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: doneToday ? null : BloomTheme.orchidGradient,
                color: doneToday ? BloomPalette.orchidSoft : null,
                borderRadius: BorderRadius.circular(26),
                boxShadow: doneToday
                    ? null
                    : [
                        BoxShadow(
                          color: BloomPalette.orchidDeep.withValues(alpha: 0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('complete-challenge-day'),
                  onTap: doneToday ? null : () => _complete(context),
                  borderRadius: BorderRadius.circular(26),
                  child: Center(
                    child: Text(
                      doneToday ? 'Completed today ✓' : 'Complete day $day',
                      style: BloomText.button(
                        color: doneToday
                            ? BloomPalette.orchidDeep
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (doneToday)
            Center(
              child: TextButton(
                onPressed: () => controller.undoChallengeDay(day),
                child: Text(
                  'Undo',
                  style: BloomText.small(color: BloomPalette.inkSoft),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.controller});

  final BloomController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: BloomPalette.creamDeep,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text('🌱', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text('30-Day Reset Challenge', style: BloomText.h2(), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'One small goal a day for a month — gentle milestones, satisfying\ncelebrations, and a version of you that feels proud.',
            textAlign: TextAlign.center,
            style: BloomText.text(color: BloomPalette.inkSoft),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: BloomTheme.orchidGradient,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: BloomPalette.orchidDeep.withValues(alpha: 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('start-challenge'),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    controller.startChallenge();
                  },
                  borderRadius: BorderRadius.circular(26),
                  child: Center(
                    child: Text('Begin my reset', style: BloomText.button()),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
