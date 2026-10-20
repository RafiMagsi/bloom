import 'package:flutter/foundation.dart';

import '../data/bloom_content.dart';
import '../models/habit.dart';
import '../models/mood_entry.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

/// Single source of truth for the app. Every mutation persists locally (Hive)
/// and notifies listeners — no backend, no login (Bloom.pdf §3).
///
/// Updates are optimistic: state changes and listeners fire immediately so
/// animations respond on the same frame as the tap; the disk write follows.
class BloomController extends ChangeNotifier {
  BloomController() {
    _load();
  }

  late List<Habit> _habits;
  late Map<String, List<String>> _completions;
  late List<MoodEntry> _moods;
  DateTime? _challengeStart;
  late List<int> _challengeDone;
  late bool _onboardingDone;
  late String _userName;
  late bool _morningReminder;
  late bool _eveningReminder;

  void _load() {
    _habits = StorageService.loadHabits();
    _completions = StorageService.snapshotCompletions();
    _moods = StorageService.loadMoods();
    _challengeStart = StorageService.challengeStart;
    _challengeDone = List<int>.from(StorageService.challengeDone)..sort();
    _onboardingDone = StorageService.onboardingDone;
    _userName = StorageService.userName;
    _morningReminder = StorageService.morningReminder;
    _eveningReminder = StorageService.eveningReminder;
  }

  static String _key(DateTime d) => StorageService.dateKey(d);

  // ---- Greeting / profile ---------------------------------------------------

  bool get onboardingDone => _onboardingDone;
  String get userName => _userName;

  String greetingFor(DateTime now) {
    final hour = now.hour;
    final word = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final who = _userName.trim().isEmpty ? 'beautiful' : _userName.trim();
    return '$word, $who';
  }

  Future<void> completeOnboarding() async {
    _onboardingDone = true;
    notifyListeners();
    await StorageService.setOnboardingDone(true);
  }

  Future<void> setUserName(String name) async {
    _userName = name;
    notifyListeners();
    await StorageService.setUserName(name);
  }

  Future<void> setMorningReminder(bool value) async {
    _morningReminder = value;
    await StorageService.setMorningReminder(value);
    await NotificationService.configureReminders(
      morning: _morningReminder,
      evening: _eveningReminder,
    );
    notifyListeners();
  }

  Future<void> setEveningReminder(bool value) async {
    _eveningReminder = value;
    await StorageService.setEveningReminder(value);
    await NotificationService.configureReminders(
      morning: _morningReminder,
      evening: _eveningReminder,
    );
    notifyListeners();
  }

  bool get morningReminder => _morningReminder;
  bool get eveningReminder => _eveningReminder;

  // ---- Habits & completions -------------------------------------------------

  List<Habit> get habits => List.unmodifiable(_habits);

  List<Habit> habitsFor(RoutineType type) =>
      _habits.where((h) => h.routine == type).toList();

  Set<String> get todayDone {
    final raw = _completions[_key(DateTime.now())] ?? const <String>[];
    return raw.where((id) => _habits.any((h) => h.id == id)).toSet();
  }

  bool isDone(String habitId) => todayDone.contains(habitId);

  int get todayTotal => _habits.length;
  int get todayDoneCount => todayDone.length;

  double get todayProgress =>
      todayTotal == 0 ? 0 : todayDoneCount / todayTotal;

  Future<void> toggleHabit(Habit habit) async {
    final now = DateTime.now();
    final ids = List<String>.from(_completions[_key(now)] ?? const <String>[]);
    if (!ids.remove(habit.id)) {
      ids.add(habit.id);
    }
    _completions[_key(now)] = ids;
    notifyListeners();
    await StorageService.setCompletedIds(now, ids);
  }

  Future<void> addHabit({
    required String name,
    required String emoji,
    required RoutineType routine,
  }) async {
    _habits.add(Habit(
      id: 'h${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      emoji: emoji,
      routine: routine,
    ));
    notifyListeners();
    await StorageService.saveHabits(_habits);
  }

  Future<void> updateHabit(Habit habit) async {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index == -1) return;
    _habits[index] = habit;
    notifyListeners();
    await StorageService.saveHabits(_habits);
  }

  Future<void> removeHabit(String habitId) async {
    _habits.removeWhere((h) => h.id == habitId);
    notifyListeners();
    await StorageService.saveHabits(_habits);
  }

  // ---- Streak, totals, weekly chart ---------------------------------------

  int get currentStreak {
    var streak = 0;
    var day = DateTime.now();
    // Today only counts once something is checked off; otherwise streak
    // continues from yesterday.
    final todayIds = _completions[_key(day)] ?? const <String>[];
    if (todayIds.isEmpty) {
      day = day.subtract(const Duration(days: 1));
    }
    while (streak < 3650) {
      final ids = _completions[_key(day)] ?? const <String>[];
      if (ids.isEmpty) break;
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get totalCompletions => _completions.values.fold<int>(
        0,
        (sum, ids) => sum + ids.where((id) => _habits.any((h) => h.id == id)).length,
      );

  /// Completion ratio for the last 7 days, oldest → newest (last = today).
  List<double> get weeklyCompletion {
    final now = DateTime.now();
    final total = todayTotal == 0 ? 1 : todayTotal;
    return List<double>.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final ids = _completions[_key(day)] ?? const <String>[];
      final valid = ids.where((id) => _habits.any((h) => h.id == id)).length;
      return (valid / total).clamp(0.0, 1.0);
    });
  }

  double get weekAverage =>
      weeklyCompletion.reduce((a, b) => a + b) / 7;

  // ---- Mood journal ---------------------------------------------------------

  List<MoodEntry> get moods => List.unmodifiable(_moods);

  MoodEntry? get todayMood {
    final today = _key(DateTime.now());
    for (final entry in _moods) {
      if (_key(entry.date) == today) return entry;
    }
    return null;
  }

  Future<void> saveMood({required int moodIndex, String note = ''}) async {
    final entry = MoodEntry(
      date: DateTime.now(),
      moodIndex: moodIndex,
      note: note.trim(),
    );
    _moods.removeWhere((e) => _key(e.date) == _key(entry.date));
    _moods.insert(0, entry);
    _moods.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    await StorageService.saveMood(entry);
  }

  // ---- 30-Day Reset Challenge ----------------------------------------------

  bool get challengeActive => _challengeStart != null;

  DateTime? get challengeStart => _challengeStart;

  /// 1…30 once started (stays at 30 after the month ends).
  int get challengeDay {
    final start = _challengeStart;
    if (start == null) return 0;
    final midnight = DateTime(start.year, start.month, start.day);
    final today = DateTime.now();
    final elapsed = DateTime(today.year, today.month, today.day)
        .difference(midnight)
        .inDays + 1;
    return elapsed.clamp(1, 30);
  }

  List<int> get challengeDone => List.unmodifiable(_challengeDone);

  bool isChallengeDayDone(int day) => _challengeDone.contains(day);

  double get challengeProgress => _challengeDone.length / 30;

  Future<void> startChallenge() async {
    final now = DateTime.now();
    _challengeStart = now;
    _challengeDone = <int>[];
    notifyListeners();
    await StorageService.startChallenge(now);
  }

  /// Marks today's challenge goal complete; returns newly unlocked
  /// achievements so the caller can celebrate them.
  Future<List<Achievement>> completeChallengeDay() async {
    final day = challengeDay;
    if (_challengeStart == null || _challengeDone.contains(day)) {
      return const <Achievement>[];
    }
    final before = _unlockedIds();
    _challengeDone.add(day);
    _challengeDone.sort();
    final unlocked = _newUnlocks(before);
    notifyListeners();
    await StorageService.setChallengeDone(List.of(_challengeDone));
    return unlocked;
  }

  Future<List<Achievement>> undoChallengeDay(int day) async {
    if (!_challengeDone.contains(day)) return const <Achievement>[];
    final before = _unlockedIds();
    _challengeDone.remove(day);
    final unlocked = _newUnlocks(before);
    notifyListeners();
    await StorageService.setChallengeDone(List.of(_challengeDone));
    return unlocked;
  }

  // ---- Achievements ---------------------------------------------------------

  int metricValue(AchievementMetric metric) {
    switch (metric) {
      case AchievementMetric.currentStreak:
        return currentStreak;
      case AchievementMetric.totalCompletions:
        return totalCompletions;
      case AchievementMetric.moodEntries:
        return _moods.length;
      case AchievementMetric.challengeDays:
        return _challengeDone.length;
    }
  }

  bool isUnlocked(Achievement achievement) =>
      metricValue(achievement.metric) >= achievement.target;

  double achievementProgress(Achievement achievement) =>
      (metricValue(achievement.metric) / achievement.target).clamp(0.0, 1.0);

  Set<String> _unlockedIds() =>
      kAchievements.where(isUnlocked).map((a) => a.id).toSet();

  List<Achievement> _newUnlocks(Set<String> before) => kAchievements
      .where((a) => isUnlocked(a) && !before.contains(a.id))
      .toList();

  // ---- Reset ---------------------------------------------------------------

  Future<void> resetAll() async {
    await StorageService.clearAll();
    _load();
    notifyListeners();
  }
}
