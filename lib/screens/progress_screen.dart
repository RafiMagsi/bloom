import 'package:flutter/material.dart';

import '../data/bloom_content.dart';
import '../state/bloom_scope.dart';
import '../theme/bloom_theme.dart';
import '../widgets/achievement_card.dart';
import '../widgets/challenge_sheet.dart';
import '../widgets/habit_glyph.dart';
import '../widgets/glow_calendar.dart';
import '../widgets/motion.dart';
import '../widgets/share_progress_card.dart';
import '../widgets/weekly_chart.dart';

/// 05 — My Progress: weekly stats, challenge milestones, achievements,
/// and a shareable progress card (Bloom.pdf §1, §5).
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  String _weekLetter(DateTime day) => 'MTWTFSS'[day.weekday - 1];

  @override
  Widget build(BuildContext context) {
    final controller = BloomScope.of(context);
    final now = DateTime.now();
    final week = controller.weeklyCompletion;
    final labels = List.generate(
      7,
      (i) => _weekLetter(now.subtract(Duration(days: 6 - i))),
    );
    final consistency = (controller.weekAverage * 100).round();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
        children: revealAll([
          Text('LOOK HOW FAR YOU HAVE COME', style: BloomText.overline()),
          const SizedBox(height: 6),
          Text('My Progress', style: BloomText.h1()),
          const SizedBox(height: 16),

          // ---- Stats row -------------------------------------------------
          Row(
            children: [
              _StatCard(
                icon: Icons.local_fire_department_rounded,
                tint: const Color(0xFFF2A07E),
                value: controller.currentStreak,
                label: 'day streak',
              ),
              const SizedBox(width: 10),
              _StatCard(
                icon: Icons.task_alt_rounded,
                tint: BloomPalette.orchidDeep,
                value: controller.totalCompletions,
                label: 'check-ins',
              ),
              const SizedBox(width: 10),
              _StatCard(
                icon: Icons.favorite_rounded,
                tint: BloomPalette.blushDeep,
                value: controller.moods.length,
                label: 'mood entries',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ---- Glow calendar ---------------------------------------------
          GlowCalendar(controller: controller),
          const SizedBox(height: 16),

          // ---- Weekly chart ----------------------------------------------
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              color: BloomPalette.card,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: BloomPalette.ink.withValues(alpha: 0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('This week', style: BloomText.h3()),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: BloomPalette.orchidSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '$consistency% consistent',
                        style: BloomText.body(12.5,
                            wght: 700, color: BloomPalette.orchidDeep),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                WeeklyChart(values: week, labels: labels),
                const SizedBox(height: 10),
                Text(
                  'Completion of your habits, day by day.',
                  style: BloomText.caption(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---- Challenge milestones ---------------------------------------
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF8F0FB), Color(0xFFEFE2F6)],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: BloomPalette.orchid.withValues(alpha: 0.45),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const IconTile(
                      icon: Icons.local_florist_rounded,
                      tint: BloomPalette.orchidDeep,
                      size: 34,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('30-Day Reset Challenge',
                          style: BloomText.h3()),
                    ),
                    Text(
                      controller.challengeActive
                          ? 'Day ${controller.challengeDay}'
                          : 'Not started',
                      style: BloomText.small(color: BloomPalette.orchidDeep),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      end: controller.challengeActive
                          ? controller.challengeProgress
                          : 0,
                    ),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 9,
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation(
                        BloomPalette.orchidDeep,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${controller.challengeDone.length} of 30 days complete',
                  style: BloomText.caption(color: BloomPalette.orchidDeep),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kChallengeMilestones.map((m) {
                    final reached = controller.challengeDone.length >= m;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: reached
                            ? BloomPalette.orchidDeep
                            : Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        reached ? 'Day $m · 🎉' : 'Day $m · 🔒',
                        style: BloomText.body(12.5,
                            wght: 700,
                            color: reached
                                ? Colors.white
                                : BloomPalette.inkSoft),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => showChallengeSheet(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BloomPalette.orchidDeep,
                      side: BorderSide(
                        color: BloomPalette.orchidDeep.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: Text(
                      controller.challengeActive
                          ? 'Open my challenge'
                          : 'Start the challenge',
                      style: BloomText.button(color: BloomPalette.orchidDeep),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ---- Achievements ------------------------------------------------
          Text('ACHIEVEMENTS', style: BloomText.overline()),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.74,
            children: [
              for (final a in kAchievements)
                AchievementCard(
                  achievement: a,
                  unlocked: controller.isUnlocked(a),
                  value: controller.metricValue(a.metric),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ---- Shareable card --------------------------------------------
          Text('SHARE YOUR GLOW', style: BloomText.overline()),
          const SizedBox(height: 12),
          const ShareProgressCard(),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.tint,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color tint;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: BloomPalette.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: BloomPalette.ink.withValues(alpha: 0.04),
          ),
          boxShadow: [
            BoxShadow(
              color: BloomPalette.ink.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            IconTile(icon: icon, tint: tint, size: 34),
            const SizedBox(height: 6),
            CountUp(value: value, style: BloomText.display(28, wght: 700)),
            Text(
              label,
              textAlign: TextAlign.center,
              style: BloomText.body(11,
                  wght: 700, color: BloomPalette.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

