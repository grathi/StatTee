import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Notification IDs
const int kNotifPersonalBest  = 1000;
const int kNotifStreakReminder = 1001;
const int kNotifTipBase       = 2000;
const int kNotifRoundReminder = 3000;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static final _fcm    = FirebaseMessaging.instance;

  static const _channelId   = 'stattee_main';
  static const _channelName = 'TeeTime Notifications';
  static const _tipCount    = 2;

  // Callback set by the app so taps can trigger navigation
  static void Function(String? payload)? onNotificationTap;

  // ── Init ─────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    tz.initializeTimeZones();
    await _initLocalNotifications();
    await _initFCM();
  }

  static Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (details) {
        onNotificationTap?.call(details.payload);
      },
    );

    // Android high-importance channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Golf round alerts and tips',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _initFCM() async {
    // iOS: show banner even when app is in foreground
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    try {
      await _saveToken(
        await _fcm.getToken().timeout(const Duration(seconds: 8)),
      );
    } catch (_) {}
    _fcm.onTokenRefresh.listen(_saveToken);

    // Foreground FCM — display via local notifications (Android)
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // Notification tap when app is in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      onNotificationTap?.call(msg.data['route'] as String?);
    });

    // Notification tap when app was terminated
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      // Delay so the widget tree is ready
      Future.delayed(const Duration(milliseconds: 800), () {
        onNotificationTap?.call(initial.data['route'] as String?);
      });
    }
  }

  static Future<void> _saveToken(String? token) async {
    if (token == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'fcmToken': token}, SetOptions(merge: true));
  }

  static Future<void> _showForegroundNotification(RemoteMessage msg) async {
    final notification = msg.notification;
    if (notification == null) return;
    await _plugin.show(
      msg.hashCode,
      notification.title,
      notification.body,
      _details(payload: msg.data['route'] as String?),
    );
  }

  // ── FCM token ─────────────────────────────────────────────────────────────

  static Future<String?> getToken() => _fcm.getToken();

  // ── Personal Best Alert ───────────────────────────────────────────────────

  static Future<void> showPersonalBest(int score) async {
    await _plugin.show(
      kNotifPersonalBest,
      '🏆 New Personal Best!',
      'You scored $score — your best round yet. Keep it up!',
      _details(payload: 'rounds'),
    );
  }

  // ── Round Reminder (scheduled 1 h before a tee time) ─────────────────────

  static Future<void> scheduleRoundReminder(DateTime teeTime, String courseName) async {
    final reminderTime = teeTime.subtract(const Duration(hours: 1));
    if (reminderTime.isBefore(DateTime.now())) return;

    final tzTime = tz.TZDateTime.from(reminderTime, tz.local);
    await _plugin.zonedSchedule(
      kNotifRoundReminder,
      '⛳ Tee time in 1 hour!',
      'Get ready for your round at $courseName.',
      tzTime,
      _details(payload: 'home'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelRoundReminder() => _plugin.cancel(kNotifRoundReminder);

  // ── Streak Reminder ───────────────────────────────────────────────────────

  static Future<void> scheduleStreakReminder() async {
    await cancelStreakReminder();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9, 0);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      kNotifStreakReminder,
      '⛳ Time to hit the course!',
      "It's been a while since your last round. Get out there!",
      scheduled,
      _details(payload: 'home'),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelStreakReminder() => _plugin.cancel(kNotifStreakReminder);

  // ── Streak check (call after every round save) ────────────────────────────

  static Future<void> evaluateStreak(DateTime? lastRoundDate) async {
    if (lastRoundDate == null) return;
    final days = DateTime.now().difference(lastRoundDate).inDays;
    if (days >= 7) {
      await scheduleStreakReminder();
    } else {
      await cancelStreakReminder();
    }
  }

  // ── Daily Golf Tips ───────────────────────────────────────────────────────

  static Future<void> scheduleDailyTips() async {
    await cancelDailyTips();
    final rng = Random();
    final now = tz.TZDateTime.now(tz.local);
    final windows = [(start: 8, end: 11), (start: 13, end: 17)];

    for (var i = 0; i < _tipCount; i++) {
      final w = windows[i];
      final hour   = w.start + rng.nextInt(w.end - w.start);
      final minute = rng.nextInt(60);

      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));

      final tip = _tips[rng.nextInt(_tips.length)];
      await _plugin.zonedSchedule(
        kNotifTipBase + i,
        tip.title,
        tip.body,
        scheduled,
        _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static Future<void> cancelDailyTips() async {
    for (var i = 0; i < _tipCount; i++) {
      await _plugin.cancel(kNotifTipBase + i);
    }
  }

  // ── Cancel all ────────────────────────────────────────────────────────────

  static Future<void> cancelAll() => _plugin.cancelAll();

  // ── Smart notification (fired by SmartNotificationService) ───────────────

  static Future<void> showSmartNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(id, title, body, _details(payload: payload));
  }

  // ── Notification settings (stored in Firestore per user) ──────────────────

  static Future<Map<String, bool>> getSettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return _defaultSettings;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data()?['notificationSettings'] as Map<String, dynamic>?;
    if (data == null) return _defaultSettings;
    return {
      'tips':    data['tips']    as bool? ?? true,
      'streak':  data['streak']  as bool? ?? true,
      'roundReminder': data['roundReminder'] as bool? ?? true,
      'personalBest':  data['personalBest']  as bool? ?? true,
    };
  }

  static const _defaultSettings = {
    'tips': true, 'streak': true, 'roundReminder': true, 'personalBest': true,
  };

  static Future<void> saveSettings(Map<String, bool> settings) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'notificationSettings': settings}, SetOptions(merge: true));

    // Apply immediately
    if (settings['tips'] == true) {
      await scheduleDailyTips();
    } else {
      await cancelDailyTips();
    }
    if (settings['streak'] == false) {
      await cancelStreakReminder();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static NotificationDetails _details({String? payload}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Golf round alerts and tips',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}

class _Tip {
  final String title;
  final String body;
  const _Tip(this.title, this.body);
}

const _tips = [
  _Tip('⛳ Course tip',        'Aim for the fat part of the green — consistency beats hero shots every time.'),
  _Tip('🏌️ Swing thought',    'Keep your head still through impact. Your eyes should track the ball, not lead the swing.'),
  _Tip('📊 Stats insight',    'Did you know? Reducing 3-putts is the fastest way to lower your handicap.'),
  _Tip('🌬️ Wind play',        'Into the wind? Take one more club and swing easy. Less spin, more control.'),
  _Tip('🎯 Short game',       '60% of all golf shots happen within 100 yards. Chip in some practice today!'),
  _Tip('💪 Stay patient',     "Bogeys happen to everyone — even the pros. Reset, breathe, and play the next shot."),
  _Tip('📐 Alignment check',  'Most amateur misses come from alignment, not swing. Check your feet and shoulders before every tee shot.'),
  _Tip('🌟 Confidence boost', "Your best round is still ahead of you. Every round is a new opportunity."),
  _Tip('🏌️ Tempo tip',        "Swing at 80% effort and you'll find more fairways. Speed comes from tempo, not force."),
  _Tip('📍 Pin position',     'When the pin is tucked, aim for the middle. Safe pars beat double bogeys every day.'),
  _Tip('🧠 Mental game',      'Play one shot at a time. Forget the last hole — focus only on the shot in front of you.'),
  _Tip('☀️ Perfect day!',     'The weather looks good — why not book a tee time and get out there today?'),
  _Tip('🏅 Practice drill',   "Putt with your eyes closed to build feel. It trains distance control better than watching the hole."),
  _Tip('🎯 Fairway woods',    "Struggling with fairway woods? Tee the ball low and sweep it — don't try to lift it."),
  _Tip('⛳ Round ready?',      "Your clubs are waiting. A quick 9 holes is the perfect midweek reset."),
];
