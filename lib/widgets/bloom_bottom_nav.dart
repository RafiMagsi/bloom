import 'package:flutter/material.dart';

import '../theme/bloom_theme.dart';

/// Frosted pill bottom navigation for the four main tabs.
class BloomBottomNav extends StatelessWidget {
  const BloomBottomNav({
    super.key,
    required this.index,
    required this.onChanged,
  });

  final int index;
  final void Function(int) onChanged;

  static const List<String> labels = ['Home', 'Routine', 'Mood', 'Progress'];

  static const List<IconData> icons = [
    Icons.spa_outlined,
    Icons.wb_sunny_outlined,
    Icons.favorite_border,
    Icons.insights_outlined,
  ];

  static const List<IconData> activeIcons = [
    Icons.spa,
    Icons.wb_sunny,
    Icons.favorite,
    Icons.insights,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: BloomPalette.card.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: BloomPalette.ink.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: BloomPalette.ink.withValues(alpha: 0.10),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // One blush pill glides to the active tab.
          Positioned.fill(
            child: AnimatedAlign(
              alignment: Alignment(-1 + 2 * index / (labels.length - 1), 0),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              child: FractionallySizedBox(
                widthFactor: 1 / labels.length,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: BloomPalette.blushSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: List.generate(labels.length, (i) {
              final active = i == index;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: active,
                  label: labels[i],
                  child: InkWell(
                    key: Key('nav-${labels[i].toLowerCase()}'),
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => onChanged(i),
                    child: SizedBox(
                      height: 52,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            scale: active ? 1.12 : 1,
                            duration: const Duration(milliseconds: 380),
                            curve: Curves.easeOutBack,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: Icon(
                                active ? activeIcons[i] : icons[i],
                                key: ValueKey(active),
                                size: 22,
                                color: active
                                    ? BloomPalette.blushDeep
                                    : BloomPalette.inkSoft,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 260),
                            style: BloomText.body(10.5,
                                wght: 700,
                                color: active
                                    ? BloomPalette.blushDeep
                                    : BloomPalette.inkSoft),
                            child: Text(labels[i]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
