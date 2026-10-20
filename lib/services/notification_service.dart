import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local reminders for the morning and evening routine (Bloom.pdf §3 stack).
/// Best-effort: if a platform refuses, the app keeps working without them.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'bloom_reminders',
      'Self-care reminders',
      channelDescription:
          'Gentle nudges for your morning and evening glow-up routine.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  static Future<void> init() async {
    if (_ready) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: settings);
    _ready = true;
  }

  /// Schedules/replaces the two daily reminders.
  static Future<void> configureReminders({
    required bool morning,
    required bool evening,
  }) async {
    try {
      await init();
      await _plugin.cancelAll();
      if (morning) {
        await _requestPermissions();
        await _plugin.periodicallyShow(
          id: 1,
          repeatInterval: RepeatInterval.daily,
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: 'Good morning, beautiful 🌸',
          body: 'Your glow-up routine is waiting for you.',
        );
      }
      if (evening) {
        await _requestPermissions();
        await _plugin.periodicallyShow(
          id: 2,
          repeatInterval: RepeatInterval.daily,
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: 'Evening reset 🌙',
          body: 'A few gentle habits and your day is complete.',
        );
      }
    } catch (e) {
      // Reminders are a nice-to-have; never block the app on platform quirks.
      debugPrint('Bloom reminders skipped: $e');
    }
  }

  static Future<void> _requestPermissions() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    final mac = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    await mac?.requestPermissions(alert: true, badge: true, sound: true);
  }
}
