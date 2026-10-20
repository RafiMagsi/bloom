import 'package:flutter/material.dart';

/// Bloom brand palette — blush pink, warm cream, sage green (per Bloom.pdf §2).
class BloomPalette {
  BloomPalette._();

  static const Color cream = Color(0xFFFBF4EC);
  static const Color creamDeep = Color(0xFFF4E9DC);
  static const Color card = Color(0xFFFFFCF9);

  static const Color blush = Color(0xFFF3A8BF);
  static const Color blushDeep = Color(0xFFDE7F9C);
  static const Color blushSoft = Color(0xFFFCE7EE);
  static const Color rose = Color(0xFFD96C8E);

  static const Color sage = Color(0xFF93B49A);
  static const Color sageDeep = Color(0xFF6D9676);
  static const Color sageSoft = Color(0xFFE7F0E8);

  static const Color ink = Color(0xFF453A3F);
  static const Color inkSoft = Color(0xFF94848A);
  static const Color honey = Color(0xFFF0B36B);
}

/// Typography — elegant serif display (Cormorant Garamond) + rounded body (Quicksand).
/// Both fonts are variable, so every style pins its `wght` axis explicitly.
class BloomText {
  BloomText._();

  static const String displayFamily = 'CormorantGaramond';
  static const String bodyFamily = 'Quicksand';

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
      body(11.5, wght: 700, letterSpacing: 2.4, color: color);

  static TextStyle h1({Color color = BloomPalette.ink}) =>
      display(34, wght: 700, height: 1.05, letterSpacing: -0.4, color: color);

  static TextStyle h2({Color color = BloomPalette.ink}) =>
      display(26, wght: 700, height: 1.1, letterSpacing: -0.2, color: color);

  static TextStyle h3({Color color = BloomPalette.ink}) =>
      display(21, wght: 700, height: 1.15, color: color);

  static TextStyle cardTitle({Color color = BloomPalette.ink}) =>
      body(16, wght: 700, color: color);

  static TextStyle text({Color color = BloomPalette.ink, double size = 15}) =>
      body(size, wght: 500, height: 1.45, color: color);

  static TextStyle small({Color color = BloomPalette.ink}) =>
      body(13, wght: 600, color: color);

  static TextStyle caption({Color color = BloomPalette.inkSoft}) =>
      body(12, wght: 600, height: 1.35, color: color);

  static TextStyle button({Color color = Colors.white}) =>
      body(16, wght: 700, letterSpacing: 0.4, color: color);
}

class BloomTheme {
  BloomTheme._();

  static const LinearGradient blushGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF6B4C7), BloomPalette.blushDeep],
  );

  static const LinearGradient sageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA9C6AE), BloomPalette.sageDeep],
  );

  static List<BoxShadow> cardShadow({Color color = const Color(0x14453A3F)}) {
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
      secondary: BloomPalette.sageDeep,
      surface: BloomPalette.card,
      brightness: Brightness.light,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: BloomPalette.cream,
      splashColor: BloomPalette.blushSoft,
      highlightColor: BloomPalette.blushSoft,
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
