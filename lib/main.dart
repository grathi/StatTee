import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/rounds_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/onboarding_service.dart';
import 'services/notification_service.dart';
import 'services/round_service.dart';
import 'services/smart_notification_service.dart';
import 'services/friends_service.dart';
import 'screens/friends_screen.dart';
import 'screens/group_round_invite_screen.dart';
import 'services/remote_config_service.dart';

/// Global navigator key — lets NotificationService navigate without a context.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Top-level FCM background handler (app terminated / background).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  unawaited(RemoteConfigService.init());
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Register tap handler BEFORE starting background init so getInitialMessage()
  // (cold-start tap) is guaranteed to find the callback already set.
  NotificationService.onNotificationTap = _handleNotificationTap;

  // Run notification setup in background — never block app launch.
  // FCM.getToken() can hang indefinitely on physical devices without this.
  unawaited(_initNotificationsInBackground());

  _scheduleStreakReminderIfNeeded();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,   // black icons for light screens
    statusBarBrightness: Brightness.light,       // iOS
  ));
  runApp(const TeeStatsApp());
}

Future<void> _initNotificationsInBackground() async {
  try {
    await NotificationService.init().timeout(const Duration(seconds: 10));
    await NotificationService.scheduleDailyTips()
        .timeout(const Duration(seconds: 5));
  } catch (_) {
    // Notification setup failed — app continues normally without it.
  }
  // Ensure email is synced to Firestore so this user is discoverable by friends.
  try {
    await FriendsService.ensureProfileSynced();
  } catch (_) {}
}

void _handleNotificationTap(Map<String, dynamic> data) {
  final route = data['route'] as String?;
  if (route == null) return;
  final nav = navigatorKey.currentState;
  if (nav == null) return;
  switch (route) {
    case 'rounds':
      nav.push(MaterialPageRoute(builder: (_) => const RoundsScreen()));
    case 'groupRound':
      final sessionId = data['sessionId'] as String?;
      if (sessionId != null) {
        nav.push(MaterialPageRoute(
          builder: (_) => GroupRoundInviteScreen(sessionId: sessionId),
        ));
      }
    case 'friendRequest':
      nav.push(MaterialPageRoute(builder: (_) => const FriendsScreen()));
    default:
      nav.popUntil((r) => r.isFirst);
  }
}

// ---------------------------------------------------------------------------
// Streak reminder
// ---------------------------------------------------------------------------
void _scheduleStreakReminderIfNeeded() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  try {
    final rounds = await RoundService.allCompletedRoundsStream().first;
    if (rounds.isEmpty) return;
    final lastRound = rounds.first.completedAt ?? rounds.first.startedAt;
    await NotificationService.evaluateStreak(lastRound);
  } catch (_) {}
}

// ---------------------------------------------------------------------------
// App root
// ---------------------------------------------------------------------------
class TeeStatsApp extends StatefulWidget {
  const TeeStatsApp({super.key});

  @override
  State<TeeStatsApp> createState() => _TeeStatsAppState();
}

class _TeeStatsAppState extends State<TeeStatsApp> {
  late final AppLifecycleListener _lifecycleListener;

  /// Timestamp when the app was last sent to background.
  DateTime? _pausedAt;

  /// Minimum time the app must be in the background before smart notifications
  /// are re-evaluated on resume. Prevents firing when users briefly switch apps.
  static const _minBackgroundDuration = Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onPause:  _onAppPause,
      onResume: _onAppResume,
    );
  }

  void _onAppPause() {
    _pausedAt = DateTime.now();
  }

  /// Called every time the app returns to the foreground.
  /// Only evaluates if the app was backgrounded for at least [_minBackgroundDuration].
  Future<void> _onAppResume() async {
    final paused = _pausedAt;
    _pausedAt = null;

    // Skip if we don't know when it was paused (cold start) or too brief.
    if (paused == null) return;
    if (DateTime.now().difference(paused) < _minBackgroundDuration) return;

    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      final ctx = await SmartNotificationService.buildContext();
      await SmartNotificationService.evaluate(ctx);
    } catch (_) {}
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeeStats',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: const AuthGate(),
    );
  }
}

// ---------------------------------------------------------------------------
// Auth gate
// ---------------------------------------------------------------------------
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool? _seenOnboarding;

  @override
  void initState() {
    super.initState();
    OnboardingService.hasSeenTour().then((seen) {
      if (mounted) setState(() => _seenOnboarding = seen);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_seenOnboarding == null) return const _SplashScreen();
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }
        if (snapshot.hasData && snapshot.data != null) {
          if (!_seenOnboarding!) return const OnboardingScreen();
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: AppColors.of(context).accent,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}
