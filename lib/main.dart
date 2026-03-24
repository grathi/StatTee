import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/round_service.dart';

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
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.init();
  await NotificationService.scheduleDailyTips();
  _scheduleStreakReminderIfNeeded();

  // Route to the correct tab when a notification is tapped
  NotificationService.onNotificationTap = _handleNotificationTap;

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const StatTeeApp());
}

void _handleNotificationTap(String? route) {
  // Navigate based on the payload/route field in the notification
  // Currently a no-op beyond ensuring the app is open — deep-linking
  // can be extended here (e.g. push RoundsScreen for route == 'rounds')
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
// Theme controller — re-evaluates every minute, fires only on boundary cross
// ---------------------------------------------------------------------------
class _ThemeController extends ChangeNotifier {
  ThemeMode _mode = resolveThemeModeFromTime();
  Timer? _timer;

  ThemeMode get mode => _mode;

  _ThemeController() {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      final next = resolveThemeModeFromTime();
      if (next != _mode) {
        _mode = next;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// App root
// ---------------------------------------------------------------------------
class StatTeeApp extends StatefulWidget {
  const StatTeeApp({super.key});

  @override
  State<StatTeeApp> createState() => _StatTeeAppState();
}

class _StatTeeAppState extends State<StatTeeApp> {
  final _themeController = _ThemeController();

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, _) => MaterialApp(
        title: 'StatTee',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _themeController.mode,
        home: const AuthGate(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Auth gate
// ---------------------------------------------------------------------------
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }
        if (snapshot.hasData && snapshot.data != null) {
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
