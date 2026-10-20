import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../data/bloom_content.dart';
import '../data/demo_month.dart';
import '../models/habit.dart';
import '../models/mood_entry.dart';

/// Local persistence (Hive) — no backend, no login, per Bloom.pdf §3.
class StorageService {
  StorageService._();

  static const String _settingsBox = 'bloom_settings';
  static const String _habitsBox = 'bloom_habits';
  static const String _completionsBox = 'bloom_completions';
  static const String _moodsBox = 'bloom_moods';
  static const String _challengeBox = 'bloom_challenge';
  static const List<String> _allBoxes = [
    _settingsBox,
    _habitsBox,
    _completionsBox,
    _moodsBox,
    _challengeBox,
  ];

  static Future<void> init({String? path}) async {
    if (path == null) {
      await Hive.initFlutter();
    } else {
      Hive.init(path);
    }
    for (final name in _allBoxes) {
      if (!Hive.isBoxOpen(name)) {
        await Hive.openBox(name);
      }
    }
  }

  /// Runs Hive work in the root zone so a write always completes, whichever
  /// zone triggered it. (Widget tests drive taps inside a fake-async zone
  /// where Hive's IO callbacks never land, leaving its write lock held.)
  static Future<void> _io(Future<void> Function() op) => Zone.root.run(op);

  static Box get _s => Hive.box(_settingsBox);
  static Box get _h => Hive.box(_habitsBox);
  static Box get _c => Hive.box(_completionsBox);
  static Box get _m => Hive.box(_moodsBox);
  static Box get _ch => Hive.box(_challengeBox);

  /// Stable 'yyyy-MM-dd' key so lists group cleanly regardless of locale.
  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---- Settings -------------------------------------------------------------

  static bool get onboardingDone =>
      _s.get('onboardingDone', defaultValue: false) as bool;
  static Future<void> setOnboardingDone(bool v) =>
      _io(() => _s.put('onboardingDone', v));

  static String get userName =>
      (_s.get('userName', defaultValue: '') as String?) ?? '';
  static Future<void> setUserName(String v) =>
      _io(() => _s.put('userName', v));

  static bool get morningReminder =>
      _s.get('morningReminder', defaultValue: true) as bool;
  static Future<void> setMorningReminder(bool v) =>
      _io(() => _s.put('morningReminder', v));

  static bool get eveningReminder =>
      _s.get('eveningReminder', defaultValue: true) as bool;
  static Future<void> setEveningReminder(bool v) =>
      _io(() => _s.put('eveningReminder', v));

  // ---- Habits ---------------------------------------------------------------

  static List<Habit> loadHabits() {
    final raw = _h.get('all');
    if (raw == null) {
      // First launch: seed a gentle starter routine so the dashboard feels alive.
      return seedHabits()
          .map((e) => Habit.fromMap(Map<dynamic, dynamic>.from(e)))
          .toList();
    }
    return (raw as List)
        .map((e) => Habit.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> saveHabits(List<Habit> habits) =>
      _io(() => _h.put('all', habits.map((e) => e.toMap()).toList()));

  // ---- Habit completions ----------------------------------------------------

  static List<String> completedIds(DateTime d) =>
      (_c.get(dateKey(d)) as List?)?.cast<String>() ?? const <String>[];

  static Future<void> setCompletedIds(DateTime d, List<String> ids) =>
      _io(() => _c.put(dateKey(d), ids));

  /// All completions: dateKey → habit ids (for streaks, weekly chart, totals).
  static Map<String, List<String>> snapshotCompletions() {
    return _c.toMap().map((key, value) => MapEntry(
          key as String,
          (value as List).cast<String>(),
        ));
  }

  // ---- Moods ----------------------------------------------------------------

  static List<MoodEntry> loadMoods() {
    final entries = _m
        .toMap()
        .map((key, value) =>
            MapEntry(key as String, MoodEntry.fromMap(value as Map)))
        .values
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  static Future<void> saveMood(MoodEntry entry) =>
      _io(() => _m.put(dateKey(entry.date), entry.toMap()));

  // ---- 30-Day challenge -----------------------------------------------------

  static DateTime? get challengeStart {
    final ms = _ch.get('start');
    return ms == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(ms as int);
  }

  static Future<void> startChallenge(DateTime start) => _io(() async {
        await _ch.put('start', start.millisecondsSinceEpoch);
        await _ch.put('done', <int>[]);
      });

  static List<int> get challengeDone =>
      (_ch.get('done') as List?)?.cast<int>() ?? const <int>[];

  static Future<void> setChallengeDone(List<int> days) =>
      _io(() => _ch.put('done', days));

  // ---- Demo month -----------------------------------------------------------

  /// First launch only: fills the past 30 days with an office-girl demo
  /// month (habits, check-ins, moods, challenge). Never overwrites days or
  /// settings the user already has.
  static Future<void> seedDemoMonthIfNeeded({DateTime? today}) async {
    if (_s.get('demoSeeded', defaultValue: false) as bool) return;
    final demo = DemoMonth.generate(today ?? DateTime.now(), dateKey);

    if (_h.get('all') == null) {
      await _h.put('all', demo.habits);
    }
    for (final entry in demo.completions.entries) {
      if (!_c.containsKey(entry.key)) {
        await _c.put(entry.key, entry.value);
      }
    }
    for (final mood in demo.moods) {
      if (!_m.containsKey(dateKey(mood.date))) {
        await saveMood(mood);
      }
    }
    if (_ch.get('start') == null) {
      await _ch.put('start', demo.challengeStart.millisecondsSinceEpoch);
      await _ch.put('done', demo.challengeDone);
    }
    await _s.put('demoSeeded', true);
  }

  // ---- Reset (settings sheet / tests) ---------------------------------------

  /// Wipes everything. The demo month is marked as used so a reset really
  /// starts from a blank slate.
  static Future<void> clearAll() => _io(() async {
        await Future.wait([
          _s.clear(),
          _h.clear(),
          _c.clear(),
          _m.clear(),
          _ch.clear(),
        ]);
        await _s.put('demoSeeded', true);
      });
}

