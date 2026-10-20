import 'dart:math' as math;

import '../models/mood_entry.dart';
import 'bloom_content.dart';

/// A believable past month for an office-working woman: steady weekday
/// rituals, softer weekends, one quarter-end crunch week, a sick day that
/// broke her streak, and a 30-day reset that's well under way.
///
/// Deterministic for a given [today], so the story is stable across launches.
class DemoMonth {
  DemoMonth._({
    required this.habits,
    required this.completions,
    required this.moods,
    required this.challengeStart,
    required this.challengeDone,
  });

  final List<Map<String, dynamic>> habits;

  /// dateKey (yyyy-MM-dd) → completed habit ids. Today is left empty.
  final Map<String, List<String>> completions;
  final List<MoodEntry> moods;
  final DateTime challengeStart;
  final List<int> challengeDone;

  static const int days = 30;

  /// Starter routine plus two 9-to-5 rituals. Keeps the seed ids so existing
  /// references stay valid.
  static List<Map<String, dynamic>> officeHabits() => [
        ...seedHabits().where((h) => h['routine'] == 'morning'),
        {'id': 'seed-lunch-am', 'name': 'Pack a healthy lunch', 'emoji': '🥗', 'routine': 'morning'},
        ...seedHabits().where((h) => h['routine'] == 'evening'),
        {'id': 'seed-walk-pm', 'name': 'Walk after work', 'emoji': '🚶‍♀️', 'routine': 'evening'},
      ];

  factory DemoMonth.generate(DateTime today, String Function(DateTime) key) {
    final rand = math.Random(2026);
    final midnight = DateTime(today.year, today.month, today.day);
    DateTime daysAgo(int n) => midnight.subtract(Duration(days: n));

    // Crunch week = Mon–Fri of the week two weeks back; she calls in sick
    // on its Friday, which resets her streak.
    final anchor = daysAgo(14);
    final crunchMonday = anchor.subtract(Duration(days: anchor.weekday - 1));
    bool inCrunch(DateTime d) {
      final diff = d.difference(crunchMonday).inDays;
      return diff >= 0 && diff <= 3;
    }

    final sickDay = crunchMonday.add(const Duration(days: 4));

    final completions = <String, List<String>>{};
    final moods = <MoodEntry>[];
    final notes = _NotePicker(rand);

    for (var n = days; n >= 1; n--) {
      final day = daysAgo(n);
      final isSick = day == sickDay;
      final weekend = day.weekday >= DateTime.saturday;
      final crunch = inCrunch(day);
      // A small upward trend in the most recent week.
      final lift = n <= 7 ? 0.06 : 0.0;

      if (!isSick) {
        final done = <String>[];
        void roll(String id, double p) {
          if (rand.nextDouble() < (p + lift).clamp(0.0, 0.99)) done.add(id);
        }

        if (crunch) {
          roll('seed-skincare-am', 0.9);
          roll('seed-water-am', 0.6);
          roll('seed-stretch-am', 0.2);
          roll('seed-lunch-am', 0.35);
          roll('seed-skincare-pm', 0.75);
          roll('seed-read-pm', 0.15);
          roll('seed-sleep-pm', 0.2);
          roll('seed-walk-pm', 0.15);
        } else if (weekend) {
          final saturday = day.weekday == DateTime.saturday;
          roll('seed-skincare-am', 0.85);
          roll('seed-water-am', 0.8);
          roll('seed-stretch-am', 0.75);
          roll('seed-skincare-pm', 0.9);
          roll('seed-read-pm', 0.85);
          roll('seed-sleep-pm', saturday ? 0.35 : 0.85);
          roll('seed-walk-pm', 0.7);
        } else {
          final friday = day.weekday == DateTime.friday;
          roll('seed-skincare-am', 0.97);
          roll('seed-water-am', 0.92);
          roll('seed-stretch-am', 0.62);
          roll('seed-lunch-am', friday ? 0.45 : 0.85);
          roll('seed-skincare-pm', 0.88);
          roll('seed-read-pm', 0.5);
          roll('seed-sleep-pm', friday ? 0.35 : 0.74);
          roll('seed-walk-pm', 0.55);
        }
        // Even on a rough day she does her morning skincare.
        if (done.isEmpty) done.add('seed-skincare-am');
        completions[key(day)] = done;
      }

      // Mood check-ins on most days, always on the hard ones.
      final logged = isSick || crunch || rand.nextDouble() < 0.82;
      if (logged) {
        final note = isSick
            ? _sickNote
            : crunch
                ? notes.next(_crunchNotes)
                : weekend
                    ? notes.next(_weekendNotes)
                    : notes.next(_workdayNotes);
        moods.add(MoodEntry(
          date: day.add(Duration(hours: 21, minutes: rand.nextInt(50))),
          moodIndex: note.$1,
          note: note.$2,
        ));
      }
    }

    // 30-day reset started 22 days ago (today is day 23). She missed the
    // sick day and one busy day in the crunch.
    final challengeStart = daysAgo(22);
    int challengeDay(DateTime d) => d.difference(challengeStart).inDays + 1;
    final skipped = {challengeDay(sickDay), challengeDay(crunchMonday) + 1};
    final challengeDone = [
      for (var d = 1; d <= 22; d++)
        if (!skipped.contains(d)) d,
    ];

    moods.sort((a, b) => b.date.compareTo(a.date));
    return DemoMonth._(
      habits: officeHabits(),
      completions: completions,
      moods: moods,
      challengeStart: challengeStart.add(const Duration(hours: 7, minutes: 30)),
      challengeDone: challengeDone,
    );
  }
}

/// Cycles through a pool without repeating until it is exhausted.
class _NotePicker {
  _NotePicker(this._rand);

  final math.Random _rand;
  final Map<List<(int, String)>, List<(int, String)>> _queues = {};

  (int, String) next(List<(int, String)> pool) {
    final queue = _queues.putIfAbsent(pool, () => []);
    if (queue.isEmpty) queue.addAll(List.of(pool)..shuffle(_rand));
    return queue.removeLast();
  }
}

// Mood indices follow kMoods: 0 Amazing, 1 Good, 2 Calm, 3 Meh, 4 Low,
// 5 Overwhelmed.
const List<(int, String)> _workdayNotes = [
  (0, 'Nailed the client presentation — my manager loved it ✨'),
  (1, 'Inbox zero by 4pm. Treated myself to an iced matcha 🍵'),
  (1, 'Lunch walk with Priya — fresh air fixed my whole afternoon'),
  (2, 'Deep-work morning, headphones on, phone in my bag 🎧'),
  (1, 'Took every screen break I promised myself. Shoulders say thanks'),
  (3, 'Back-to-back meetings, barely remembered to drink water'),
  (2, 'Left the office on time. Pink sunset on the walk home 🌇'),
  (0, 'Got the green light on my project proposal 🎉'),
  (1, 'Packed lunch all week — saving money and feeling lighter 🥗'),
  (3, 'Commute was chaos, but my podcast saved me'),
  (1, 'Great 1:1 today. Feeling seen and supported at work'),
  (2, 'Quiet office day. Desk stretches every hour 🧘‍♀️'),
  (4, 'Long day of spreadsheets. Eyes tired, heart tired'),
  (1, 'Coffee with my mentor — so much inspiration ☕'),
  (2, 'WFH day: candle on, cosy socks, calm focus 🕯️'),
];

const List<(int, String)> _crunchNotes = [
  (5, 'Quarter-end deadline week. Skipped lunch again 😮‍💨'),
  (4, 'Stayed late finishing the report. Takeout and no walk'),
  (5, 'Five meetings and a launch. Brain is soup'),
  (3, 'Felt behind all day. Reminding myself rest is part of progress 💗'),
  (4, 'Deck prep till 10pm. Night skincare was my five minutes of peace'),
];

const (int, String) _sickNote =
    (4, 'Called in sick — tea, blankets and zero guilt 🍵');

const List<(int, String)> _weekendNotes = [
  (1, 'Brunch with the girls, laughed until my cheeks hurt 🥂'),
  (2, 'Slow Saturday — farmers market and a long bath 🛁'),
  (1, 'Sunday reset: laundry, meal prep, fresh sheets 🌸'),
  (0, 'Pilates class, then a nap in the sun. Perfect day'),
  (2, 'Read in bed for an hour. No alarms, no emails 📖'),
  (1, 'Face mask + rom-com night. Fully recharged 🧖‍♀️'),
  (3, 'Lazy day, a little Sunday-scaries creeping in'),
  (0, 'Hiked with my sister and finally saw the sea 🌊'),
];
