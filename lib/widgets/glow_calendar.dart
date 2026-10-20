import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/bloom_content.dart';
import '../state/bloom_controller.dart';
import '../theme/bloom_theme.dart';
import 'motion.dart';

/// Five weeks of days, each glowing rose → orchid by how many rituals she
/// kept, with a dot for the mood she logged. Tap a day for its story.
class GlowCalendar extends StatefulWidget {
  const GlowCalendar({super.key, required this.controller});

  final BloomController controller;

  @override
  State<GlowCalendar> createState() => _GlowCalendarState();
}

/// Petal → rose ramp for the day tiles; only a perfect day turns orchid.
Color glowColor(double ratio) {
  const stops = [
    Color(0xFFF9E4EA),
    Color(0xFFF9CADA),
    Color(0xFFF3A3BF),
    Color(0xFFE57BA3),
    Color(0xFFB860A6),
  ];
  final t = ratio.clamp(0.0, 1.0) * (stops.length - 1);
  final i = t.floor().clamp(0, stops.length - 2);
  return Color.lerp(stops[i], stops[i + 1], t - i)!;
}

class _GlowCalendarState extends State<GlowCalendar> {
  static const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  late DateTime _selected;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    // Yesterday has a full story; today is still being written.
    final t = _today;
    _selected = DateTime(t.year, t.month, t.day - 1);
  }

  @override
  Widget build(BuildContext context) {
    final today = _today;
    // 5 weeks, Monday-first, ending with the week that contains today.
    // Calendar-field arithmetic keeps days exact across DST changes.
    final first = DateTime(
      today.year,
      today.month,
      today.day + 7 - today.weekday - 34,
    );
    final days = List.generate(
      35,
      (i) => DateTime(first.year, first.month, first.day + i),
    );
    final entrance = EntranceScope.maybeOf(context) ?? kAlwaysCompleteAnimation;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      decoration: BoxDecoration(
        color: BloomPalette.card,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: BloomPalette.blushDeep.withValues(alpha: 0.08),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Your glow month', style: BloomText.h3())),
              Text(
                _months[today.month - 1],
                style: BloomText.small(color: BloomPalette.blushDeep),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Each day glows with the rituals you kept.',
            style: BloomText.caption(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final l in _weekdayLetters)
                Expanded(
                  child: Center(
                    child: Text(
                      l,
                      style: BloomText.body(
                        11.5,
                        wght: 800,
                        color: BloomPalette.inkSoft,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 6.0;
              final cell = (constraints.maxWidth - gap * 6) / 7;
              return AnimatedBuilder(
                animation: entrance,
                builder: (context, _) => Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (var i = 0; i < days.length; i++)
                      _dayTile(
                        days[i],
                        cell,
                        // Diagonal wave as the card arrives.
                        _wave(entrance.value, (i % 7) + (i ~/ 7)),
                        isFuture: days[i].isAfter(today),
                        isToday: days[i] == today,
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _legend(),
          const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: BloomMotion.settle,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(a),
                  child: child,
                ),
              ),
              child: _dayStory(_selected, key: ValueKey(_selected)),
            ),
          ),
        ],
      ),
    );
  }

  double _wave(double t, int diag) {
    final start = 0.25 + diag * 0.035;
    return Curves.easeOutBack.transform(((t - start) / 0.3).clamp(0.0, 1.0));
  }

  Widget _dayTile(
    DateTime day,
    double size,
    double appear, {
    required bool isFuture,
    required bool isToday,
  }) {
    final c = widget.controller;
    final ratio = isFuture ? 0.0 : c.completionOn(day);
    final mood = isFuture ? null : c.moodOn(day);
    final selected = day == _selected;
    final fill = isFuture ? Colors.transparent : glowColor(ratio);
    final dark = ratio >= 0.55;

    return Opacity(
      opacity: appear.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 0.6 + 0.4 * appear,
        child: GestureDetector(
          onTap: isFuture
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  setState(() => _selected = day);
                },
          child: AnimatedScale(
            scale: selected ? 1.12 : 1,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(size * 0.34),
                border: isToday || selected
                    ? Border.all(
                        color: selected
                            ? BloomPalette.ink.withValues(alpha: 0.75)
                            : BloomPalette.blushDeep,
                        width: 1.8,
                      )
                    : isFuture
                    ? Border.all(color: BloomPalette.creamDeep, width: 1.2)
                    : null,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: fill.withValues(alpha: 0.6),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: BloomText.body(
                      math.min(13.5, size * 0.33),
                      wght: 800,
                      color: isFuture
                          ? BloomPalette.inkSoft.withValues(alpha: 0.45)
                          : dark
                          ? Colors.white
                          : BloomPalette.ink,
                    ),
                  ),
                  if (mood != null)
                    Positioned(
                      bottom: size * 0.11,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              kMoodColors[mood.moodIndex.clamp(
                                0,
                                kMoodColors.length - 1,
                              )],
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _legend() {
    return Row(
      children: [
        Text('Less', style: BloomText.caption()),
        const SizedBox(width: 8),
        for (final r in const [0.0, 0.25, 0.5, 0.75, 1.0])
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: glowColor(r),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        const SizedBox(width: 4),
        Text('More', style: BloomText.caption()),
      ],
    );
  }

  Widget _dayStory(DateTime day, {Key? key}) {
    final c = widget.controller;
    final done = c.completedCountOn(day);
    final total = c.todayTotal;
    final mood = c.moodOn(day);
    final isToday = day == _today;
    final title = isToday
        ? 'Today'
        : '${_weekdayNames[day.weekday - 1]}, ${day.day} ${_months[day.month - 1]}';
    final moodOption = mood == null
        ? null
        : kMoods[mood.moodIndex.clamp(0, kMoods.length - 1)];

    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BloomPalette.cream,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: glowColor(c.completionOn(day)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                moodOption?.emoji ?? '🌱',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: BloomText.cardTitle()),
                const SizedBox(height: 2),
                Text(
                  '$done of $total rituals'
                  '${moodOption == null ? '' : ' · felt ${moodOption.label.toLowerCase()}'}',
                  style: BloomText.small(color: BloomPalette.blushDeep),
                ),
                if (mood != null && mood.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '“${mood.note}”',
                    style: BloomText.body(
                      13.5,
                      wght: 500,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                      color: BloomPalette.inkSoft,
                    ),
                  ),
                ],
                if (mood == null && done == 0 && !isToday) ...[
                  const SizedBox(height: 4),
                  Text(
                    'A rest day — those count too.',
                    style: BloomText.caption(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
