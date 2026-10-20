import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/bloom_content.dart';
import '../models/habit.dart';
import '../state/bloom_controller.dart';
import '../theme/bloom_theme.dart';
import 'habit_glyph.dart';
import 'motion.dart';

/// Bottom sheet to add or edit a habit in a routine.
Future<void> showAddHabitSheet(
  BuildContext context, {
  required BloomController controller,
  required RoutineType routine,
  Habit? editing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: BloomMotion.scrim,
    sheetAnimationStyle: BloomMotion.sheet,
    builder: (_) => _AddHabitSheet(
      controller: controller,
      routine: routine,
      editing: editing,
    ),
  );
}

class _AddHabitSheet extends StatefulWidget {
  const _AddHabitSheet({
    required this.controller,
    required this.routine,
    this.editing,
  });

  final BloomController controller;
  final RoutineType routine;
  final Habit? editing;

  @override
  State<_AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<_AddHabitSheet> {
  late final TextEditingController _name;
  late String _emoji;
  late final bool _editing;

  static const List<String> _extraEmojis = [
    '🌸',
    '💗',
    '✨',
    '🫧',
    '🎯',
    '🍎',
    '🌬️',
    '🕯️',
  ];

  @override
  void initState() {
    super.initState();
    _editing = widget.editing != null;
    _name = TextEditingController(text: widget.editing?.name ?? '');
    _emoji = widget.editing?.emoji ?? '🌸';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  List<HabitPreset> get _presets =>
      widget.routine == RoutineType.morning ? kMorningPresets : kEveningPresets;

  void _save() {
    final text = _name.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.mediumImpact();
    if (_editing) {
      widget.controller.updateHabit(
        widget.editing!.copyWith(name: text, emoji: _emoji),
      );
    } else {
      widget.controller.addHabit(
        name: text,
        emoji: _emoji,
        routine: widget.routine,
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final emojis = <String>{
      ..._presets.map((p) => p.emoji),
      ..._extraEmojis,
      _emoji,
    }.toList();

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
        decoration: const BoxDecoration(
          color: BloomPalette.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SheetEntrance(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: revealAll([
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: BloomPalette.creamDeep,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _editing ? 'Edit habit' : 'New habit',
                  style: BloomText.h2(),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.routine == RoutineType.morning
                      ? 'Added to your morning glow-up ☀️'
                      : 'Added to your evening reset 🌙',
                  style: BloomText.caption(),
                ),
                const SizedBox(height: 20),
                Text('NAME', style: BloomText.overline()),
                const SizedBox(height: 8),
                TextField(
                  controller: _name,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.sentences,
                  style: BloomText.cardTitle(),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'e.g. Skin care routine',
                    hintStyle: BloomText.cardTitle(color: BloomPalette.inkSoft),
                    filled: true,
                    fillColor: BloomPalette.cream,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: BloomPalette.blush),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('PICK A MATCHING VIBE', style: BloomText.overline()),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presets
                      .map(
                        (p) => ActionChip(
                          avatar: HabitGlyph(emoji: p.emoji, size: 24),
                          label: Text(
                            p.name,
                            style: BloomText.small(
                              color: _name.text == p.name
                                  ? Colors.white
                                  : BloomPalette.ink,
                            ),
                          ),
                          backgroundColor: _name.text == p.name
                              ? BloomPalette.blushDeep
                              : BloomPalette.cream,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          onPressed: () => setState(() {
                            _name.text = p.name;
                            _emoji = p.emoji;
                          }),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                Text('CHOOSE AN ICON', style: BloomText.overline()),
                const SizedBox(height: 10),
                SizedBox(
                  height: 46,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: emojis.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final selected = emojis[i] == _emoji;
                      return GestureDetector(
                        onTap: () => setState(() => _emoji = emojis[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? BloomPalette.blushSoft
                                : BloomPalette.cream,
                            border: Border.all(
                              color: selected
                                  ? BloomPalette.blushDeep
                                  : Colors.transparent,
                              width: 1.8,
                            ),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: HabitGlyph(emoji: emojis[i], size: 36),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (_editing)
                      TextButton(
                        onPressed: () {
                          widget.controller.removeHabit(widget.editing!.id);
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Remove',
                          style: BloomText.button(color: BloomPalette.rose),
                        ),
                      ),
                    Expanded(
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _name,
                        builder: (context, value, _) {
                          final enabled = value.text.trim().isNotEmpty;
                          return AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: enabled
                                    ? BloomTheme.blushGradient
                                    : null,
                                color: enabled ? null : BloomPalette.blushSoft,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: enabled
                                    ? [
                                        BoxShadow(
                                          color: BloomPalette.blushDeep
                                              .withValues(alpha: 0.4),
                                          blurRadius: 18,
                                          offset: const Offset(0, 8),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: enabled ? _save : null,
                                  borderRadius: BorderRadius.circular(24),
                                  child: SizedBox(
                                    height: 54,
                                    child: Center(
                                      child: Text(
                                        _editing ? 'Save changes' : 'Add habit',
                                        // Disabled stays readable: rose on blush.
                                        style: BloomText.button(
                                          color: enabled
                                              ? Colors.white
                                              : BloomPalette.blushDeep
                                                  .withValues(alpha: 0.75),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
