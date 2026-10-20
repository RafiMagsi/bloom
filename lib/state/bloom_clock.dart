/// Time source for time-of-day styling (evening atmosphere). Overridable so
/// tests and previews can show evening at any hour.
class BloomClock {
  BloomClock._();

  static DateTime Function() now = DateTime.now;

  /// Dusk to dawn: 6pm – 5am.
  static bool get isEvening {
    final h = now().hour;
    return h >= 18 || h < 5;
  }
}
