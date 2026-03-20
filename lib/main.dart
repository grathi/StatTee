import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/round_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();
  _scheduleStreakReminderIfNeeded();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const StatTeeApp());
}

// ---------------------------------------------------------------------------
// Streak reminder — scheduled once on app launch if user is signed in
// ---------------------------------------------------------------------------
void _scheduleStreakReminderIfNeeded() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  try {
    // Get last completed round date
    final rounds = await RoundService.allCompletedRoundsStream().first;
    if (rounds.isEmpty) return;
    final lastRound = rounds.first.completedAt ?? rounds.first.startedAt;
    final daysSince = DateTime.now().difference(lastRound).inDays;
    if (daysSince >= 7) {
      await NotificationService.scheduleStreakReminder();
    } else {
      await NotificationService.cancelStreakReminder();
    }
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
