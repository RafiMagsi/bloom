import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/bloom_content.dart';
import '../state/bloom_scope.dart';
import '../theme/bloom_theme.dart';
import '../widgets/motion.dart';

/// 04 — Mood Journal: emoji check-in, private note, history view.
class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  final TextEditingController _note = TextEditingController();
  int? _selected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe place to read inherited state; guard keeps user edits intact.
    if (_selected == null) {
      final existing = BloomScope.of(context).todayMood;
      if (existing != null) {
        _selected = existing.moodIndex;
        _note.text = existing.note;
      }
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final index = _selected;
    if (index == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
    await BloomScope.of(context).saveMood(moodIndex: index, note: _note.text);
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Saved 💗  Today you feel ${kMoods[index].label.toLowerCase()}.',
          ),
          backgroundColor: BloomPalette.orchidDeep,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final controller = BloomScope.of(context);
    final today = controller.todayMood;
    final history = controller.moods;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
        children: revealAll([
          Text('PRIVATE & JUST FOR YOU', style: BloomText.overline()),
          const SizedBox(height: 6),
          Text('Mood Journal', style: BloomText.h1()),
          const SizedBox(height: 6),
          Text(
            'How are you feeling today?',
            style: BloomText.text(color: BloomPalette.inkSoft),
          ),
          const SizedBox(height: 16),

          // ---- Mood cards ------------------------------------------------
          Container(
            padding: const EdgeInsets.all(16),
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
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.92,
              children: List.generate(kMoods.length, (i) {
                final mood = kMoods[i];
                final selected = _selected == i;
                final pop = selected ? 1.05 : 1.0;
                return GestureDetector(
                  key: Key('mood-$i'),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selected = i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut,
                    transformAlignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(pop, pop, 1),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? BloomPalette.blushSoft
                          : BloomPalette.cream,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: selected
                            ? BloomPalette.blushDeep
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: BloomPalette.blushDeep
                                    .withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(mood.emoji,
                            style: TextStyle(
                                fontSize: selected ? 36 : 32)),
                        const SizedBox(height: 6),
                        Text(
                          mood.label,
                          style: BloomText.body(12.5,
                              wght: 700,
                              color: selected
                                  ? BloomPalette.blushDeep
                                  : BloomPalette.inkSoft),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),

          // ---- Note ------------------------------------------------------
          TextField(
            controller: _note,
            maxLength: 180,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            style: BloomText.text(),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'A few words about your day… (optional)',
              hintStyle: BloomText.text(color: BloomPalette.inkSoft),
              filled: true,
              fillColor: BloomPalette.card,
              contentPadding: const EdgeInsets.all(18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: BloomPalette.blush),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ---- Save ------------------------------------------------------
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: _selected == null ? null : BloomTheme.blushGradient,
                color: _selected == null ? BloomPalette.blushSoft : null,
                borderRadius: BorderRadius.circular(26),
                boxShadow: _selected == null
                    ? null
                    : [
                        BoxShadow(
                          color: BloomPalette.blushDeep
                              .withValues(alpha: 0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('save-mood'),
                  onTap: _selected == null ? null : _save,
                  borderRadius: BorderRadius.circular(26),
                  child: SizedBox(
                    height: 56,
                    child: Center(
                      child: Text(
                        _selected == null
                            ? 'Pick a mood to save'
                            : today == null
                                ? 'Save my check-in'
                                : 'Update my check-in',
                        // Disabled stays readable: rose on blush.
                        style: BloomText.button(
                          color: _selected == null
                              ? BloomPalette.blushDeep.withValues(alpha: 0.75)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),

          // ---- History ---------------------------------------------------
          Text('YOUR JOURNEY', style: BloomText.overline()),
          const SizedBox(height: 12),
          _MoodStrip(entries: history),
          const SizedBox(height: 14),
          if (history.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: BloomPalette.card,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                children: [
                  const Text('🌱', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  Text(
                    'Your mood story starts today.',
                    style: BloomText.small(color: BloomPalette.inkSoft),
                  ),
                ],
              ),
            )
          else
            ...history.take(30).map((e) {
              final mood = kMoods[
                  e.moodIndex.clamp(0, kMoods.length - 1)];
              const months = [
                'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
              ];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BloomPalette.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: BloomPalette.ink.withValues(alpha: 0.04),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 42,
                      child: Column(
                        children: [
                          Text(
                            '${e.date.day}',
                            style: BloomText.display(24, wght: 700),
                          ),
                          Text(
                            months[e.date.month - 1],
                            style: BloomText.caption(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(mood.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(mood.label, style: BloomText.cardTitle()),
                          if (e.note.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              e.note,
                              style: BloomText.caption(
                                color: BloomPalette.inkSoft,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ]),
      ),
    );
  }
}

/// Last 7 days of moods at a glance.
class _MoodStrip extends StatelessWidget {
  const _MoodStrip({required this.entries});

  final List<dynamic> entries;

  @override
  Widget build(BuildContext context) {
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();
    return Row(
      children: List.generate(7, (i) {
        final day = now.subtract(Duration(days: 6 - i));
        final key =
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        String? emoji;
        for (final e in entries) {
          final d = e.date;
          final k =
              '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          if (k == key) {
            emoji = kMoods[e.moodIndex.clamp(0, kMoods.length - 1)].emoji;
            break;
          }
        }
        final isToday = i == 6;
        return Expanded(
          child: Column(
            children: [
              Container(
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: emoji != null
                      ? BloomPalette.blushSoft
                      : BloomPalette.card,
                  border: Border.all(
                    color: isToday
                        ? BloomPalette.blushDeep
                        : BloomPalette.ink.withValues(alpha: 0.05),
                    width: isToday ? 1.8 : 1,
                  ),
                ),
                child: Center(
                  child: emoji != null
                      ? Text(emoji, style: const TextStyle(fontSize: 19))
                      : Text(
                          letters[day.weekday - 1],
                          style: BloomText.caption(),
                        ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                isToday ? 'Today' : letters[day.weekday - 1],
                style: BloomText.body(10.5,
                    wght: 700,
                    color: isToday
                        ? BloomPalette.blushDeep
                        : BloomPalette.inkSoft),
              ),
            ],
          ),
        );
      }),
    );
  }
}
