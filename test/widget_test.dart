import 'dart:io';

import 'package:bloom/main.dart';
import 'package:bloom/services/storage_service.dart';
import 'package:bloom/state/bloom_controller.dart';
import 'package:bloom/widgets/challenge_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('bloom_test');
    await StorageService.init(path: tempDir.path);
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
    await tester.pump(); // route push begins
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('01 Welcome shows the brand and starts the reset',
      (tester) async {
    await pumpApp(tester);

    expect(find.text('Bloom'), findsOneWidget);
    expect(
      find.text('Small habits. Softer days. A better you.'),
      findsOneWidget,
    );
    expect(find.text('Start Your Reset'), findsOneWidget);

    await startFromWelcome(tester);

    expect(find.byKey(const Key('home-greeting')), findsOneWidget);
    expect(find.byKey(const Key('progress-ring')), findsOneWidget);
    expect(StorageService.onboardingDone, isTrue);

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

  testWidgets('03 Routine tab adds a habit that shows up in the list',
      (tester) async {
    await pumpApp(tester);
    await startFromWelcome(tester);

    await tester.tap(find.byKey(const Key('nav-routine')));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('My Routine'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-habit')));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('New habit'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Glow walk');
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.text('Add habit'));
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
    expect(find.text('This week'), findsOneWidget);
    expect(find.textContaining('% consistent'), findsOneWidget);
    expect(find.text('30-Day Reset Challenge'), findsOneWidget);
    expect(find.text('First Bloom'), findsOneWidget);
    expect(find.text('Share my progress'), findsOneWidget);

    // Start and complete day 1 of the 30-day reset.
    await tester.ensureVisible(find.text('Start the challenge'));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.text('Start the challenge'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ChallengeSheet), findsOneWidget);

    await tester.tap(find.byKey(const Key('start-challenge')));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Day 1 of 30'), findsOneWidget);

    await tester.tap(find.byKey(const Key('complete-challenge-day')));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Completed today ✓'), findsOneWidget);
    expect(StorageService.challengeDone, contains(1));

    await tester.pumpWidget(const SizedBox());
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
