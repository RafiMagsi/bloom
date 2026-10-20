import 'package:flutter/material.dart';

import '../theme/bloom_theme.dart';

/// A refined line icon + its pastel tint, standing in for an emoji.
class GlyphStyle {
  const GlyphStyle(this.icon, this.tint);

  final IconData icon;
  final Color tint;
}

// Pastel tints that sit happily inside the rose / orchid palette.
const Color _rose = Color(0xFFEC7FA5);
const Color _peach = Color(0xFFF2A07E);
const Color _gold = Color(0xFFE5A93A);
const Color _mint = Color(0xFF62B897);
const Color _sky = Color(0xFF7FA3E6);
const Color _lilac = Color(0xFFA98BE0);
const Color _plum = Color(0xFF9A5C8C);

/// Habit emoji (as stored) → icon. Unknown emoji fall back to the emoji
/// itself on a blush tile, so nothing a user picked ever disappears.
const Map<String, GlyphStyle> kHabitGlyphs = {
  '🧴': GlyphStyle(Icons.spa_rounded, _rose),
  '💧': GlyphStyle(Icons.water_drop_rounded, _sky),
  '🤸': GlyphStyle(Icons.accessibility_new_rounded, _peach),
  '🌤': GlyphStyle(Icons.wb_sunny_rounded, _gold),
  '📓': GlyphStyle(Icons.edit_note_rounded, _lilac),
  '🛏': GlyphStyle(Icons.bed_rounded, _lilac),
  '💊': GlyphStyle(Icons.medication_rounded, _mint),
  '🧘': GlyphStyle(Icons.self_improvement_rounded, _lilac),
  '🌙': GlyphStyle(Icons.nightlight_round, _plum),
  '📖': GlyphStyle(Icons.menu_book_rounded, _rose),
  '🙏': GlyphStyle(Icons.volunteer_activism_rounded, _rose),
  '📵': GlyphStyle(Icons.phonelink_erase_rounded, _plum),
  '🍵': GlyphStyle(Icons.emoji_food_beverage_rounded, _mint),
  '😴': GlyphStyle(Icons.bedtime_rounded, _sky),
  '🛁': GlyphStyle(Icons.bathtub_rounded, _sky),
  '🌸': GlyphStyle(Icons.local_florist_rounded, _rose),
  '🥗': GlyphStyle(Icons.restaurant_rounded, _mint),
  '🚶‍♀️': GlyphStyle(Icons.directions_walk_rounded, _peach),
  '🚶': GlyphStyle(Icons.directions_walk_rounded, _peach),
  '💗': GlyphStyle(Icons.favorite_rounded, _rose),
  '✨': GlyphStyle(Icons.auto_awesome_rounded, _gold),
  '🫧': GlyphStyle(Icons.bubble_chart_rounded, _sky),
  '🎯': GlyphStyle(Icons.track_changes_rounded, _peach),
  '🍎': GlyphStyle(Icons.eco_rounded, _mint),
  '🌬': GlyphStyle(Icons.air_rounded, _sky),
  '🕯': GlyphStyle(Icons.wb_incandescent_rounded, _gold),
};

/// Looks up an emoji, ignoring the invisible variation selector some
/// keyboards add (e.g. "🌤️" vs "🌤").
GlyphStyle? glyphFor(String emoji) =>
    kHabitGlyphs[emoji] ?? kHabitGlyphs[emoji.replaceAll('️', '')];

/// Pastel rounded tile with the habit's icon.
class HabitGlyph extends StatelessWidget {
  const HabitGlyph({super.key, required this.emoji, this.size = 40});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = glyphFor(emoji);
    return IconTile(
      size: size,
      tint: style?.tint ?? BloomPalette.blush,
      icon: style?.icon,
      fallback: emoji,
    );
  }
}

/// The shared pastel icon tile used for habits, stats and settings.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.tint,
    this.icon,
    this.fallback,
    this.size = 40,
    this.solid = false,
  });

  final Color tint;
  final IconData? icon;

  /// Text (emoji) shown when there is no icon.
  final String? fallback;
  final double size;

  /// White icon on a saturated tile (for highlighted states).
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.36),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: solid
              ? [Color.lerp(tint, Colors.white, 0.25)!, tint]
              : [
                  Color.lerp(tint, Colors.white, 0.86)!,
                  Color.lerp(tint, Colors.white, 0.72)!,
                ],
        ),
      ),
      child: Center(
        child: icon != null
            ? Icon(
                icon,
                size: size * 0.52,
                color: solid
                    ? Colors.white
                    : Color.lerp(tint, BloomPalette.ink, 0.3),
              )
            : Text(fallback ?? '', style: TextStyle(fontSize: size * 0.48)),
      ),
    );
  }
}
