import 'dart:async';
import 'dart:io';

import 'package:bloom/data/mood_insights.dart';
import 'package:bloom/main.dart';
import 'package:bloom/models/mood_entry.dart';
import 'package:bloom/screens/habit_detail_screen.dart';
import 'package:bloom/screens/progress_screen.dart';
import 'package:bloom/state/bloom_clock.dart';
import 'package:bloom/widgets/habit_glyph.dart';
import 'package:bloom/services/storage_service.dart';
import 'package:bloom/state/bloom_controller.dart';
import 'package:bloom/widgets/challenge_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'support/fake_video_player.dart';

/// Loads a bundled font so layouts are measured with real glyphs, not the
/// test framework's wide placeholder font.
Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    FakeVideoPlayerPlatform.install();
    tempDir = await Directory.systemTemp.createTemp('bloom_test');
    await StorageService.init(path: tempDir.path);
    await _loadFont('PlayfairDisplay', 'assets/fonts/PlayfairDisplay.ttf');
    await _loadFont('Nunito', 'assets/fonts/Nunito.ttf');
  });

  setUp(() async {
    await StorageService.clearAll();
  });

  tearDownAll(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {
      // Best-effort temp cleanup.
    }
  });

  Future<BloomController> pumpApp(WidgetTester tester) async {
    // A real phone viewport (iPhone 14-ish), not the 800×600 default.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final controller = BloomController();
    await tester.pumpWidget(BloomApp(controller: controller));
    // Let the entrance animation get going (no pumpAndSettle: ambient loops).
    await tester.pump(const Duration(milliseconds: 400));
    return controller;
  }

  Future<void> startFromWelcome(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('start-reset')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('start-reset')));
    // First launch asks her name on a frosted card.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.enterText(find.byKey(const Key('name-field')), 'Ava');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('name-continue')));
    await tester.pump(); // route push begins
    // Let the bloom-reveal transition fully open.
    await tester.pump(const Duration(milliseconds: 1200));
  }

  testWidgets('01 Welcome shows the brand and starts the reset',
      (tester) async {
    await pumpApp(tester);

    expect(find.text('Bloom'), findsOneWidget);
    expect(
      find.text('Small habits. Softer days. A better you.'),
      findsOneWidget,
    );
    expect(find.text('Get Started'), findsOneWidget);

    await startFromWelcome(tester);

    expect(find.byKey(const Key('home-greeting')), findsOneWidget);
    expect(find.byKey(const Key('progress-ring')), findsOneWidget);
    expect(StorageService.onboardingDone, isTrue);
    // The name she typed is saved and greets her on Home.
    expect(StorageService.userName, 'Ava');
    expect(find.textContaining('Ava'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('02 Checking a habit updates the ring, streak and count',
      (tester) async {
    await pumpApp(tester);
    await startFromWelcome(tester);

    expect(find.text('0%'), findsOneWidget);
    expect(find.text('0 of 6 habits complete'), findsOneWidget);

    await tester.tap(find.byKey(const Key('habit-seed-skincare-am')));
    await tester.pump(const Duration(milliseconds: 450));

    expect(
      find.byKey(const Key('habit-done-seed-skincare-am')),
      findsOneWidget,
    );
    // 1 of 6 = 17%.
    expect(find.text('17%'), findsOneWidget);
    expect(find.text('1 of 6 habits complete'), findsOneWidget);
    expect(find.text('1 day streak'), findsOneWidget);

    // Untoggle returns the ring to zero.
    await tester.tap(find.byKey(const Key('habit-seed-skincare-am')));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('0%'), findsOneWidget);
    expect(find.byKey(const Key('habit-done-seed-skincare-am')), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('02b Finishing every ritual celebrates the day', (tester) async {
    final controller = await pumpApp(tester);
    await startFromWelcome(tester);

    // Tick everything; the last one blooms the day.
    for (final habit in controller.habits) {
      unawaited(controller.toggleHabit(habit));
    }
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('You bloomed today, Ava'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('bloomed ✨'), findsOneWidget);

    // It settles away on its own.
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('You bloomed today, Ava'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('02c Tapping a habit icon opens its detail page', (tester) async {
    await pumpApp(tester);
    await startFromWelcome(tester);

    await tester.tap(find.descendant(
      of: find.byKey(const Key('habit-seed-skincare-am')),
      matching: find.byType(HabitGlyph),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(HabitDetailScreen), findsOneWidget);
    expect(find.text('Morning ritual'), findsOneWidget);
    expect(find.text('Last five weeks'), findsOneWidget);

    await tester.tap(find.byKey(const Key('habit-detail-toggle')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Done today — lovely'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(HabitDetailScreen), findsNothing);
    expect(find.byKey(const Key('habit-done-seed-skincare-am')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('03 Routine tab adds a habit that shows up in the list',
      (tester) async {
    await pumpApp(tester);
    await startFromWelcome(tester);

    await tester.tap(find.byKey(const Key('nav-routine')));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('My Routine'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-habit')));
    // Sheet rises (460ms) while its content cascades in.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('New habit'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Glow walk');
    await tester.pump(const Duration(milliseconds: 120));
    await tester.ensureVisible(find.text('Add habit'));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.text('Add habit'));
    // Let the sheet finish sliding away.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Glow walk'), findsOneWidget);
    // Persisted for next launch.
    expect(
      StorageService.loadHabits().map((h) => h.name),
      contains('Glow walk'),
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('04 Mood check-in saves a private entry', (tester) async {
    await pumpApp(tester);
    await startFromWelcome(tester);

    await tester.tap(find.byKey(const Key('nav-mood')));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Mood Journal'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mood-2'))); // 😌 Calm
    await tester.pump(const Duration(milliseconds: 350));

    await tester.enterText(
      find.byType(TextField).first,
      'Slow morning, good tea.',
    );
    await tester.ensureVisible(find.byKey(const Key('save-mood')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('save-mood')));
    await tester.pump(const Duration(milliseconds: 600));

    final moods = StorageService.loadMoods();
    expect(moods, hasLength(1));
    expect(moods.first.moodIndex, 2);
    expect(moods.first.note, 'Slow morning, good tea.');
    // Entry shows in the journey list.
    expect(find.text('Slow morning, good tea.'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('05 Progress screen renders stats and runs the challenge',
      (tester) async {
    await pumpApp(tester);
    await startFromWelcome(tester);

    await tester.tap(find.byKey(const Key('nav-progress')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('My Progress'), findsOneWidget);
    expect(find.text('Your glow month'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    expect(find.textContaining('% consistent'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('30-Day Reset Challenge'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ProgressScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('30-Day Reset Challenge'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('First Bloom'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ProgressScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('First Bloom'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Share my progress'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ProgressScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Share my progress'), findsOneWidget);

    // Start and complete day 1 of the 30-day reset.
    await tester.scrollUntilVisible(
      find.text('Start the challenge'),
      -300,
      scrollable: find
          .descendant(
            of: find.byType(ProgressScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.text('Start the challenge'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ChallengeSheet), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('start-challenge')));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.byKey(const Key('start-challenge')));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Day 1 of 30'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('complete-challenge-day')));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.byKey(const Key('complete-challenge-day')));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Completed today ✓'), findsOneWidget);
    expect(StorageService.challengeDone, contains(1));

    await tester.pumpWidget(const SizedBox());
  });

  test('demo month seeds a realistic office-girl history once', () async {
    await Hive.box('bloom_settings').delete('demoSeeded');
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await StorageService.saveMood(
      MoodEntry(date: yesterday, moodIndex: 0, note: 'my own entry'),
    );

    await StorageService.seedDemoMonthIfNeeded();
    final c = BloomController();

    expect(c.habits, hasLength(8));
    expect(c.habits.map((h) => h.name), contains('Pack a healthy lunch'));
    expect(c.todayDoneCount, 0, reason: 'today is left for the user');
    expect(c.currentStreak, inInclusiveRange(7, 16));
    expect(c.totalCompletions, greaterThan(100));
    expect(c.moods.length, inInclusiveRange(20, 30));
    expect(c.todayMood, isNull);
    expect(c.challengeDay, 23);
    expect(c.challengeDone, hasLength(20));
    // Existing data is never overwritten.
    expect(
      c.moods.firstWhere((m) => m.date.day == yesterday.day).note,
      'my own entry',
    );

    // Second call is a no-op.
    await StorageService.seedDemoMonthIfNeeded();
    expect(BloomController().moods, hasLength(c.moods.length));
  });

  test('demo month yields honest mood insights + calendar data', () async {
    await Hive.box('bloom_settings').delete('demoSeeded');
    await StorageService.seedDemoMonthIfNeeded();
    final c = BloomController();

    final insights = c.moodInsights.map((i) => i.text).toList();
    expect(insights.first, contains('most frequent mood'));
    expect(insights, contains(contains('You glow brightest on')));
    // The crunch week (few rituals, heavy moods) makes this one true.
    expect(insights, contains(contains('% brighter')));

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    expect(c.completionOn(yesterday), greaterThan(0));
    expect(c.completionOn(DateTime.now()), 0);
  });

  test('mood insights stay quiet without enough check-ins', () {
    final now = DateTime.now();
    final insights = computeMoodInsights(
      moods: [
        for (var i = 1; i <= 3; i++)
          MoodEntry(date: now.subtract(Duration(days: i)), moodIndex: 1),
      ],
      completionOn: (_) => 1,
      today: now,
    );
    expect(insights, isEmpty);
  });

  test('evening atmosphere follows the clock', () {
    addTearDown(() => BloomClock.now = DateTime.now);
    BloomClock.now = () => DateTime(2026, 10, 20, 21);
    expect(BloomClock.isEvening, isTrue);
    BloomClock.now = () => DateTime(2026, 10, 20, 9);
    expect(BloomClock.isEvening, isFalse);
  });

  test('data persists across app restarts (Hive)', () async {
    final first = BloomController();
    expect(first.habits, isNotEmpty);

    await first.toggleHabit(first.habits.first);
    await first.saveMood(moodIndex: 4, note: 'tired but trying');
    await first.startChallenge();
    await first.completeChallengeDay();

    // Fresh controller = fresh app launch.
    final second = BloomController();
    expect(second.isDone(first.habits.first.id), isTrue);
    expect(second.currentStreak, 1);
    expect(second.moods, hasLength(1));
    expect(second.moods.first.moodIndex, 4);
    expect(second.challengeActive, isTrue);
    expect(second.challengeDone, [1]);
    expect(second.totalCompletions, 1);
  });
}
