import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../data/bloom_content.dart';
import '../models/habit.dart';
import '../state/bloom_scope.dart';
import '../theme/bloom_theme.dart';
import '../widgets/challenge_sheet.dart';
import '../widgets/habit_tile.dart';
import '../widgets/progress_ring.dart';
import '../widgets/settings_sheet.dart';
import 'welcome_screen.dart';

/// 02 — Home: greeting, daily routine, progress ring, streak, inspiration.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onNavigate});

  final void Function(int index) onNavigate;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _segment = 0; // 0 = morning, 1 = evening
  late final AnimationController _flame;

  @override
  void initState() {
    super.initState();
    _flame = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flame.dispose();
    super.dispose();
  }

  String _dateLine(DateTime now) {
    const weekdays = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    return '${weekdays[now.weekday - 1]} · ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = BloomScope.of(context);
    final now = DateTime.now();
    final routine =
        _segment == 0 ? RoutineType.morning : RoutineType.evening;
    final habits = controller.habitsFor(routine);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
        children: [
          // ---- Header -----------------------------------------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_dateLine(now), style: BloomText.overline()),
                    const SizedBox(height: 6),
                    Text(
                      controller.greetingFor(now),
                      key: const Key('home-greeting'),
                      style: BloomText.h1(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _IconBubble(
                icon: Icons.settings_rounded,
                onTap: () => showSettingsSheet(
                  context,
                  controller: controller,
                  onReplayWelcome: () => Navigator.of(context)
                      .pushReplacement(fadeRoute(const WelcomeScreen())),
                  onResetData: () async {
                    await controller.resetAll();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        fadeRoute(const WelcomeScreen()),
                        (_) => false,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ---- Ring + streak + challenge ---------------------------------
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: BloomPalette.card,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: BloomPalette.ink.withValues(alpha: 0.06),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                ProgressRing(
                  key: const Key('progress-ring'),
                  progress: controller.todayProgress,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(controller.todayProgress * 100).round()}%',
                        key: const Key('progress-percent'),
                        style: BloomText.h2(color: BloomPalette.sageDeep),
                      ),
                      Text('today', style: BloomText.caption()),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedBuilder(
                        animation: _flame,
                        builder: (context, child) {
                          final t = 1 + 0.05 * _flame.value;
                          return Transform.scale(scale: t, child: child);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFE0B8), Color(0xFFF0B36B)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 15)),
                              const SizedBox(width: 6),
                              Text(
                                controller.currentStreak == 0
                                    ? 'Start today'
                                    : '${controller.currentStreak} day streak',
                                style: BloomText.body(13,
                                    wght: 700, color: const Color(0xFF8A5A22)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () => showChallengeSheet(context),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: BloomPalette.sageSoft,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                controller.challengeActive
                                    ? 'Day ${controller.challengeDay}/30'
                                    : '30-day reset',
                                style: BloomText.body(13,
                                    wght: 700,
                                    color: BloomPalette.sageDeep),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 11,
                                color: BloomPalette.sageDeep,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${controller.todayDoneCount} of ${controller.todayTotal} habits complete',
                        style: BloomText.caption(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ---- Today's routine -------------------------------------------
          Row(
            children: [
              Expanded(
                child: Text("TODAY'S ROUTINE", style: BloomText.overline()),
              ),
              TextButton(
                onPressed: () => widget.onNavigate(1),
                child: Text(
                  'Edit routine',
                  style: BloomText.small(color: BloomPalette.blushDeep),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: BloomPalette.creamDeep,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: List.generate(2, (i) {
                final active = _segment == i;
                return Expanded(
                  child: GestureDetector(
                    key: Key('home-segment-$i'),
                    onTap: () => setState(() => _segment = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: active ? BloomPalette.card : Colors.transparent,
                        borderRadius: BorderRadius.circular(17),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color:
                                      BloomPalette.ink.withValues(alpha: 0.07),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        i == 0 ? '☀️  Morning' : '🌙  Evening',
                        textAlign: TextAlign.center,
                        style: BloomText.body(14,
                            wght: 700,
                            color: active
                                ? BloomPalette.ink
                                : BloomPalette.inkSoft),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          if (habits.isEmpty)
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: BloomPalette.card,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                children: [
                  const Text('🌷', style: TextStyle(fontSize: 34)),
                  const SizedBox(height: 8),
                  Text(
                    'Nothing here yet — add your first habit',
                    style: BloomText.small(color: BloomPalette.inkSoft),
                  ),
                ],
              ),
            )
          else
            ...habits.map(
              (h) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: HabitTile(
                  habit: h,
                  done: controller.isDone(h.id),
                  onTap: () => controller.toggleHabit(h),
                ),
              ),
            ),
          const SizedBox(height: 14),

          // ---- Daily inspiration -----------------------------------------
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF6B4C7), Color(0xFFD97A9B)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: BloomPalette.blushDeep.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DAILY INSPIRATION',
                  style: BloomText.overline(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  quoteOfDay(now),
                  style: BloomText.display(23,
                      wght: 700,
                      fontStyle: FontStyle.italic,
                      height: 1.2,
                      color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ---- Challenge teaser -------------------------------------------
          InkWell(
            onTap: () => showChallengeSheet(context),
            borderRadius: BorderRadius.circular(28),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: BloomPalette.sageSoft,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: BloomPalette.sage.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '30-DAY RESET CHALLENGE',
                          style: BloomText.overline(
                            color: BloomPalette.sageDeep,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          controller.challengeActive
                              ? 'You are on day ${controller.challengeDay} — keep the glow going'
                              : 'Start a guided month of small wins',
                          style: BloomText.cardTitle(),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              end: controller.challengeActive
                                  ? controller.challengeProgress
                                  : 0,
                            ),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            builder: (context, v, _) => LinearProgressIndicator(
                              value: v,
                              minHeight: 7,
                              backgroundColor: Colors.white,
                              valueColor: const AlwaysStoppedAnimation(
                                BloomPalette.sageDeep,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: BloomPalette.sageDeep,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BloomPalette.card,
      shape: CircleBorder(
        side: BorderSide(
          color: BloomPalette.ink.withValues(alpha: 0.05),
        ),
      ),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: BloomPalette.inkSoft),
        ),
      ),
    );
  }
}
