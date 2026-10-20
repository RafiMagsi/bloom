import 'package:flutter/material.dart';

import '../theme/bloom_theme.dart';

/// Animated weekly consistency chart — rounded gradient bars, staggered grow-in.
class WeeklyChart extends StatelessWidget {
  const WeeklyChart({
    super.key,
    required this.values,
    required this.labels,
    this.barHeight = 168,
  });

  /// 7 completion ratios, oldest → newest (last = today).
  final List<double> values;
  final List<String> labels;
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 950),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(values.length, (i) {
            final local = ((t - i * 0.06) * 1.5).clamp(0.0, 1.0);
            final eased = Curves.easeOutCubic.transform(local);
            final ratio = values[i].clamp(0.0, 1.0);
            final isToday = i == values.length - 1;
            final full = ratio <= 0.001 ? 7.0 : (18 + ratio * (barHeight - 18));
            final height = full * eased;
            return Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: barHeight,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 17,
                        height: height,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: ratio <= 0.001
                              ? null
                              : LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: isToday
                                      ? const [
                                          Color(0xFFF6B4C7),
                                          BloomPalette.blushDeep,
                                        ]
                                      : const [
                                          Color(0xFFF3B3C8),
                                          Color(0xFFC08AC8),
                                          BloomPalette.orchidDeep,
                                        ],
                                ),
                          color: ratio <= 0.001
                              ? BloomPalette.creamDeep
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    labels[i],
                    style: BloomText.body(11.5,
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
      },
    );
  }
}
