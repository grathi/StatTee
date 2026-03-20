import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'stattee_main';
  static const _channelName = 'StatTee Notifications';
  static const _streakId = 1001;

  static Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Golf round alerts and reminders',
      importance: Importance.defaultImportance,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ── Personal Best Alert ──────────────────────────────────────────────────

  static Future<void> showPersonalBest(int score) async {
    await _plugin.show(
      1000,
      '🏆 New Personal Best!',
      'You scored $score — your best round yet. Keep it up!',
      _details(),
    );
  }

  // ── Streak Reminder ──────────────────────────────────────────────────────

  /// Schedule a daily reminder at 9 AM if the user hasn't played recently.
  /// Call this from main.dart on app launch (after checking last round date).
  static Future<void> scheduleStreakReminder() async {
    await cancelStreakReminder(); // avoid duplicates

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, 9, 0, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _streakId,
      '⛳ Time to hit the course!',
      "It's been a while since your last round. Get out there!",
      scheduled,
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }

  static Future<void> cancelStreakReminder() async {
    await _plugin.cancel(_streakId);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Golf round alerts and reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
