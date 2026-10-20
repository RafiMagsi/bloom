import 'package:flutter/material.dart';

/// Bloom brand palette — petal pinks, rose, orchid and deep plum ink.
/// Text colours are tuned for contrast (ink ≈ 12:1, inkSoft ≈ 5:1 on cream).
class BloomPalette {
  BloomPalette._();

  // Surfaces.
  static const Color cream = Color(0xFFFFF5F7); // app background
  static const Color creamDeep = Color(0xFFF9E4EA); // chips, tracks
  static const Color card = Color(0xFFFFFFFF);

  // Rose — the primary accent.
  static const Color blush = Color(0xFFF2A3BA);
  static const Color blushDeep = Color(0xFFD9668A);
  static const Color blushSoft = Color(0xFFFDE7EE);
  static const Color rose = Color(0xFFC9506F);

  // Orchid — success / "done" accent.
  static const Color orchid = Color(0xFFC7A2DD);
  static const Color orchidDeep = Color(0xFF8E5BAE);
  static const Color orchidSoft = Color(0xFFF4EBFA);

  // Ink.
  static const Color ink = Color(0xFF3A2430);
  static const Color inkSoft = Color(0xFF75606B);
  static const Color honey = Color(0xFFF0B36B);

  // Landing "glow" palette — petal pinks, dusty rose and rose gold.
  static const Color petal = Color(0xFFF7C9D2);
  static const Color petalMist = Color(0xFFFFF5F7);
  static const Color dustyRose = Color(0xFFE29AA5);
  static const Color dustyRoseDeep = Color(0xFFCF7E8B);
  static const Color roseGold = Color(0xFFE8B49C);
  static const Color mauveInk = Color(0xFF4A2D39);
  static const Color mauveSoft = Color(0xFF7F6470);
}

/// Typography — Playfair Display (elegant high-contrast serif) for headings,
/// Nunito (soft, rounded, very legible) for everything else. Both fonts are
/// variable, so every style pins its `wght` axis explicitly.
class BloomText {
  BloomText._();

  static const String displayFamily = 'PlayfairDisplay';
  static const String bodyFamily = 'Nunito';

  static FontWeight _weight(double wght) =>
      FontWeight.values[((wght / 100).round() - 1).clamp(0, 8)];

  static TextStyle display(
    double size, {
    double wght = 600,
    Color color = BloomPalette.ink,
    double? height,
    double? letterSpacing,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return TextStyle(
      fontFamily: displayFamily,
      fontSize: size,
      fontWeight: _weight(wght),
      fontVariations: [FontVariation('wght', wght)],
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }

  static TextStyle body(
    double size, {
    double wght = 500,
    Color color = BloomPalette.ink,
    double? height,
    double? letterSpacing,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: size,
      fontWeight: _weight(wght),
      fontVariations: [FontVariation('wght', wght)],
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }

  // Named styles used across the app.
  static TextStyle overline({Color color = BloomPalette.inkSoft}) =>
      body(11.5, wght: 800, letterSpacing: 1.8, color: color);

  static TextStyle h1({Color color = BloomPalette.ink}) =>
      display(31, wght: 600, height: 1.12, letterSpacing: -0.3, color: color);

  static TextStyle h2({Color color = BloomPalette.ink}) =>
      display(24, wght: 600, height: 1.15, letterSpacing: -0.2, color: color);

  static TextStyle h3({Color color = BloomPalette.ink}) =>
      display(20, wght: 600, height: 1.2, color: color);

  static TextStyle cardTitle({Color color = BloomPalette.ink}) =>
      body(16, wght: 700, color: color);

  static TextStyle text({Color color = BloomPalette.ink, double size = 15}) =>
      body(size, wght: 500, height: 1.45, color: color);

  static TextStyle small({Color color = BloomPalette.ink}) =>
      body(13.5, wght: 700, color: color);

  static TextStyle caption({Color color = BloomPalette.inkSoft}) =>
      body(12.5, wght: 600, height: 1.4, color: color);

  static TextStyle button({Color color = Colors.white}) =>
      body(16, wght: 800, letterSpacing: 0.3, color: color);
}

class BloomTheme {
  BloomTheme._();

  static const LinearGradient blushGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF3A6BF), BloomPalette.blushDeep],
  );

  static const LinearGradient orchidGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD3AEE6), BloomPalette.orchidDeep],
  );

  static List<BoxShadow> cardShadow({Color color = const Color(0x143A2430)}) {
    return [
      BoxShadow(
        color: color,
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ];
  }

  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: BloomPalette.blush,
      primary: BloomPalette.blushDeep,
      secondary: BloomPalette.orchidDeep,
      surface: BloomPalette.card,
      brightness: Brightness.light,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: BloomPalette.cream,
      splashColor: BloomPalette.blushSoft,
      highlightColor: BloomPalette.blushSoft,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: BloomPalette.blushDeep,
        selectionColor: BloomPalette.blushSoft,
        selectionHandleColor: BloomPalette.blushDeep,
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: BloomText.bodyFamily,
        bodyColor: BloomPalette.ink,
        displayColor: BloomPalette.ink,
      ),
    );
  }
}
