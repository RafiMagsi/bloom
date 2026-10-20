import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/habit.dart';
import '../theme/bloom_theme.dart';

/// A habit row with a satisfying spring pop when checked off.
class HabitTile extends StatelessWidget {
  const HabitTile({
    super.key,
    required this.habit,
    required this.done,
    required this.onTap,
    this.onEdit,
  });

  final Habit habit;
  final bool done;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('habit-${habit.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: done ? BloomPalette.orchidSoft : BloomPalette.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: done
                ? BloomPalette.orchid.withValues(alpha: 0.45)
                : BloomPalette.ink.withValues(alpha: 0.05),
          ),
          boxShadow: done
              ? null
              : [
                  BoxShadow(
                    color: BloomPalette.ink.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          children: [
            Text(habit.emoji, style: const TextStyle(fontSize: 23)),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: done
                    ? BloomText.cardTitle(
                        color: BloomPalette.inkSoft,
                      ).copyWith(
                        decoration: TextDecoration.lineThrough,
                        decorationColor: BloomPalette.orchidDeep,
                        decorationThickness: 1.6,
                      )
                    : BloomText.cardTitle(),
                child: Text(
                  habit.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (onEdit != null)
              IconButton(
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.edit_rounded,
                  size: 17,
                  color: BloomPalette.inkSoft.withValues(alpha: 0.8),
                ),
              ),
            const SizedBox(width: 6),
            // Spring pop driven by the done flag (both directions).
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: done ? 1 : 0),
              duration: const Duration(milliseconds: 430),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                final pulse =
                    1.0 + 0.13 * math.sin(math.min(value, 1.0) * math.pi);
                return Transform.scale(scale: pulse, child: child);
              },
              child: AnimatedContainer(
                key: done ? Key('habit-done-${habit.id}') : null,
                duration: const Duration(milliseconds: 260),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? BloomPalette.orchidDeep : Colors.transparent,
                  border: Border.all(
                    color: done
                        ? BloomPalette.orchidDeep
                        : BloomPalette.blush.withValues(alpha: 0.55),
                    width: 1.7,
                  ),
                ),
                child: Icon(
                  done ? Icons.check_rounded : Icons.add_rounded,
                  size: 18,
                  color: done
                      ? Colors.white
                      : BloomPalette.blushDeep.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
