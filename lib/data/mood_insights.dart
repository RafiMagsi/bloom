import '../models/mood_entry.dart';
import 'bloom_content.dart';

/// How bright each mood feels, 0 (heavy) … 1 (radiant), indexed like
/// [kMoods] — used for trends and comparisons.
const List<double> kMoodValence = [1.0, 0.8, 0.68, 0.45, 0.22, 0.1];

/// One plain-language observation about her month.
class MoodInsight {
  const MoodInsight(this.emoji, this.text);

  final String emoji;
  final String text;
}

const List<String> _weekdays = [
  'Mondays',
  'Tuesdays',
  'Wednesdays',
  'Thursdays',
  'Fridays',
  'Saturdays',
  'Sundays',
];

/// Gentle insights from the last 30 days of check-ins. Each one only appears
/// when there is enough data to say it honestly.
List<MoodInsight> computeMoodInsights({
  required List<MoodEntry> moods,
  required double Function(DateTime day) completionOn,
  required DateTime today,
}) {
  final since = DateTime(today.year, today.month, today.day)
      .subtract(const Duration(days: 30));
  final recent = moods.where((m) => !m.date.isBefore(since)).toList();
  if (recent.length < 5) return const [];

  double valence(MoodEntry m) =>
      kMoodValence[m.moodIndex.clamp(0, kMoodValence.length - 1)];
  double avg(Iterable<double> xs) => xs.reduce((a, b) => a + b) / xs.length;

  final insights = <MoodInsight>[];

  // Most frequent mood.
  final counts = <int, int>{};
  for (final m in recent) {
    counts[m.moodIndex] = (counts[m.moodIndex] ?? 0) + 1;
  }
  final top = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
  final mood = kMoods[top.key.clamp(0, kMoods.length - 1)];
  insights.add(MoodInsight(
    mood.emoji,
    '${mood.label} was your most frequent mood — ${top.value} days this month.',
  ));

  // Brightest weekday (needs at least two check-ins on that day).
  final byWeekday = <int, List<double>>{};
  for (final m in recent) {
    byWeekday.putIfAbsent(m.date.weekday, () => []).add(valence(m));
  }
  final eligible = byWeekday.entries.where((e) => e.value.length >= 2);
  if (eligible.length >= 3) {
    final best = eligible
        .reduce((a, b) => avg(b.value) > avg(a.value) ? b : a);
    insights.add(MoodInsight(
      '✨',
      'You glow brightest on ${_weekdays[best.key - 1]}.',
    ));
  }

  // Rituals ↔ mood.
  final high = <double>[];
  final low = <double>[];
  for (final m in recent) {
    (completionOn(m.date) >= 0.6 ? high : low).add(valence(m));
  }
  if (high.length >= 3 && low.length >= 3) {
    final h = avg(high), l = avg(low);
    if (h > l + 0.05) {
      final pct = ((h - l) / l * 100).round();
      insights.add(MoodInsight(
        '🌸',
        'On days you keep most of your rituals, your mood is $pct% brighter.',
      ));
    }
  }
  return insights;
}
