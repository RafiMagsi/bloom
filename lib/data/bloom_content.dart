import 'package:flutter/material.dart';

import '../theme/bloom_theme.dart';

/// Expressive emoji mood cards for the Mood Check-In.
class MoodOption {
  const MoodOption(this.emoji, this.label);

  final String emoji;
  final String label;
}

const List<MoodOption> kMoods = [
  MoodOption('😄', 'Amazing'),
  MoodOption('🙂', 'Good'),
  MoodOption('😌', 'Calm'),
  MoodOption('😐', 'Meh'),
  MoodOption('😢', 'Low'),
  MoodOption('😣', 'Overwhelmed'),
];

/// Suggested habit presets for the Glow-Up Routine.
class HabitPreset {
  const HabitPreset(this.emoji, this.name);

  final String emoji;
  final String name;
}

const List<HabitPreset> kMorningPresets = [
  HabitPreset('🧴', 'Skincare routine'),
  HabitPreset('💧', 'Glass of water'),
  HabitPreset('🤸', '10-min stretch'),
  HabitPreset('🌤️', 'Sunlight walk'),
  HabitPreset('📓', 'Journal 3 lines'),
  HabitPreset('🛏️', 'Make the bed'),
  HabitPreset('💊', 'Take vitamins'),
  HabitPreset('🧘', '5-min meditation'),
];

const List<HabitPreset> kEveningPresets = [
  HabitPreset('🌙', 'Night skincare'),
  HabitPreset('📖', 'Read 10 pages'),
  HabitPreset('🙏', 'Gratitude note'),
  HabitPreset('📵', 'Phone-free hour'),
  HabitPreset('🍵', 'Herbal tea'),
  HabitPreset('😴', 'Sleep by 11'),
  HabitPreset('🛁', 'Relaxing shower'),
  HabitPreset('🌸', 'Reflect on my day'),
];

/// Daily inspiration quotes — deterministic per day, no storage needed.
const List<String> kQuotes = [
  "You don't have to be perfect. You just have to be kind to yourself.",
  'Small habits. Softer days. A better you.',
  'Glow at your own pace 🌸',
  'Rest is part of the progress.',
  'The most magnetic women build quiet routines.',
  'Speak to yourself like someone you love.',
  'One gentle step today is still a step.',
  'You are not behind. You are blooming.',
  'A soft life starts with disciplined self-love.',
  'Do it for the woman you are becoming.',
];

String quoteOfDay(DateTime date) {
  final dayIndex = date.difference(DateTime(date.year)).inDays;
  return kQuotes[dayIndex % kQuotes.length];
}

/// The 30-Day Reset Challenge — one small goal per day (Bloom.pdf §1).
const List<String> kChallengeDays = [
  'Write one sentence about what you want this month 🌱',
  'Drink 8 glasses of water 💧',
  '10-minute morning stretch 🤸',
  'No phone for the first 30 minutes after waking 📵',
  'Do your skincare morning and night 🧴',
  'Read 10 pages 📖',
  'Tidy one corner of your room 🧹',
  'Take a 20-minute walk outside 🚶‍♀️',
  'Write 3 lines in your journal 📓',
  'Sleep before 11pm 🌙',
  'Compliment yourself in the mirror 🪞',
  'Cook one meal you love 🥗',
  'Unfollow 5 accounts that do not inspire you 📱',
  'Digital sunset — no screens after 10pm 🌇',
  'Move your body for 30 minutes 🏃‍♀️',
  'Say no to something that drains you 🙅‍♀️',
  'Drink your morning water before coffee ☕',
  'Spend 15 minutes decluttering 🧺',
  'Send a kind message to someone 💬',
  'Take yourself on a solo date ☕🌸',
  "Plan next week's routines 📅",
  'Early night — 8 hours of sleep 😴',
  'Skip sugar for one day 🍬',
  'Stretch and breathe for 5 minutes 🧘‍♀️',
  'Wear something that makes you feel confident 👗',
  'Write down 3 wins, however small 🏆',
  'Do one thing you have been postponing ⚡',
  'Reflect: how have you changed this month? 🪞',
  'Speak kindly to yourself all day 💗',
  'Celebrate you — you did it 🌸🎉',
];

/// Milestones celebrated along the challenge.
const List<int> kChallengeMilestones = [7, 14, 21, 30];

/// What the user is tracking for each achievement.
enum AchievementMetric {
  currentStreak,
  totalCompletions,
  moodEntries,
  challengeDays,
}

class Achievement {
  const Achievement({
    required this.id,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.metric,
    required this.target,
  });

  final String id;
  final String emoji;
  final String title;
  final String subtitle;
  final AchievementMetric metric;
  final int target;
}

const List<Achievement> kAchievements = [
  Achievement(
    id: 'first-bloom',
    emoji: '🌱',
    title: 'First Bloom',
    subtitle: 'Complete your first habit',
    metric: AchievementMetric.totalCompletions,
    target: 1,
  ),
  Achievement(
    id: 'week-of-glow',
    emoji: '🔥',
    title: 'Week of Glow',
    subtitle: 'Keep a 7-day streak',
    metric: AchievementMetric.currentStreak,
    target: 7,
  ),
  Achievement(
    id: 'steady-rhythm',
    emoji: '💫',
    title: 'Steady Rhythm',
    subtitle: 'Finish 50 habit check-ins',
    metric: AchievementMetric.totalCompletions,
    target: 50,
  ),
  Achievement(
    id: 'heart-listener',
    emoji: '💗',
    title: 'Heart Listener',
    subtitle: 'Write 10 mood entries',
    metric: AchievementMetric.moodEntries,
    target: 10,
  ),
  Achievement(
    id: 'halfway-bloom',
    emoji: '🌿',
    title: 'Halfway Bloom',
    subtitle: 'Reach day 15 of your reset',
    metric: AchievementMetric.challengeDays,
    target: 15,
  ),
  Achievement(
    id: 'fully-bloomed',
    emoji: '🌸',
    title: 'Fully Bloomed',
    subtitle: 'Finish the 30-day reset',
    metric: AchievementMetric.challengeDays,
    target: 30,
  ),
];

/// Seed habits shown on first launch so the dashboard feels alive instantly.
List<Map<String, dynamic>> seedHabits() => [
      {'id': 'seed-skincare-am', 'name': 'Skincare routine', 'emoji': '🧴', 'routine': 'morning'},
      {'id': 'seed-water-am', 'name': 'Glass of water', 'emoji': '💧', 'routine': 'morning'},
      {'id': 'seed-stretch-am', 'name': '10-min stretch', 'emoji': '🤸', 'routine': 'morning'},
      {'id': 'seed-skincare-pm', 'name': 'Night skincare', 'emoji': '🌙', 'routine': 'evening'},
      {'id': 'seed-read-pm', 'name': 'Read 10 pages', 'emoji': '📖', 'routine': 'evening'},
      {'id': 'seed-sleep-pm', 'name': 'Sleep by 11', 'emoji': '😴', 'routine': 'evening'},
    ];

/// Soft decorative palette for shared painters.
List<Color> confettiColors() => const [
      BloomPalette.blush,
      BloomPalette.blushDeep,
      BloomPalette.orchid,
      BloomPalette.orchidDeep,
      BloomPalette.honey,
      Colors.white,
    ];
