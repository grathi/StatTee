import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const _kKey        = 'hasSeenAppTour';
  static const _kStatsTip   = 'hasSeenStatsTip';
  static const _kProfileTip = 'hasSeenProfileTip';
  static const _kRoundsTip  = 'hasSeenRoundsTip';
  static const _kScorecardTip = 'hasSeenScorecardTip';

  static Future<bool> hasSeenTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kKey) ?? false;
  }

  static Future<void> markTourSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kKey, true);
  }

  /// For testing/debugging — resets the flag so the tour shows again next launch.
  static Future<void> resetTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKey);
  }

  // ── Stats tip ──────────────────────────────────────────────────────────────

  static Future<bool> hasSeenStatsTip() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kStatsTip) ?? false;
  }

  static Future<void> markStatsTipSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kStatsTip, true);
  }

  // ── Profile tip ────────────────────────────────────────────────────────────

  static Future<bool> hasSeenProfileTip() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kProfileTip) ?? false;
  }

  static Future<void> markProfileTipSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kProfileTip, true);
  }

  // ── Rounds tip ─────────────────────────────────────────────────────────────

  static Future<bool> hasSeenRoundsTip() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kRoundsTip) ?? false;
  }

  static Future<void> markRoundsTipSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRoundsTip, true);
  }

  // ── Scorecard tip ──────────────────────────────────────────────────────────

  static Future<bool> hasSeenScorecardTip() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kScorecardTip) ?? false;
  }

  static Future<void> markScorecardTipSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kScorecardTip, true);
  }
}
