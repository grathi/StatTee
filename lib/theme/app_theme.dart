import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Time-based theme helper
// ---------------------------------------------------------------------------
/// 06:00–19:00 → light, 19:00–06:00 → dark
ThemeMode resolveThemeModeFromTime() {
  final hour = DateTime.now().hour;
  return (hour >= 6 && hour < 19) ? ThemeMode.light : ThemeMode.dark;
}

// ---------------------------------------------------------------------------
// AppTheme — ThemeData definitions
// ---------------------------------------------------------------------------
abstract class AppTheme {
  static const _fontFamily = 'Nunito';

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0C0E1A),
        fontFamily: _fontFamily,
        useMaterial3: true,
      );

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: _fontFamily,
        useMaterial3: true,
      );
}

// ---------------------------------------------------------------------------
// AppColors — semantic color tokens per brightness
// ---------------------------------------------------------------------------
class AppColors {
  final bool isDark;

  const AppColors._(this.isDark);

  factory AppColors.of(BuildContext context) =>
      AppColors._(Theme.of(context).brightness == Brightness.dark);

  // ── Backgrounds & gradients ──────────────────────────────────────────────
  Color get scaffoldBg =>
      isDark ? const Color(0xFF0C0E1A) : const Color(0xFFF8FAFC);

  List<Color> get bgGradient => isDark
      ? [const Color(0xFF080A14), const Color(0xFF0F1225), const Color(0xFF080A14)]
      : [const Color(0xFFEEF2FF), const Color(0xFFF8FAFC), const Color(0xFFEEF2FF)];

  // ── Cards ────────────────────────────────────────────────────────────────
  Color get cardBg =>
      isDark ? Colors.white.withValues(alpha: 0.07) : Colors.white;

  Color get cardBorder => isDark
      ? Colors.white.withValues(alpha: 0.10)
      : const Color(0xFF4F46E5).withValues(alpha: 0.08);

  List<BoxShadow> get cardShadow => isDark
      ? []
      : [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ];

  // ── Sheet / modal backgrounds ────────────────────────────────────────────
  Color get sheetBg =>
      isDark ? const Color(0xFF0F1225) : Colors.white;

  // ── Text ─────────────────────────────────────────────────────────────────
  Color get primaryText => isDark ? Colors.white : const Color(0xFF0F172A);

  Color get secondaryText => isDark
      ? Colors.white.withValues(alpha: 0.55)
      : const Color(0xFF0F172A).withValues(alpha: 0.55);

  Color get tertiaryText => isDark
      ? Colors.white.withValues(alpha: 0.35)
      : const Color(0xFF0F172A).withValues(alpha: 0.35);

  // ── Accent ───────────────────────────────────────────────────────────────
  Color get accent =>
      isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5);

  Color get accentBg => isDark
      ? const Color(0xFF818CF8).withValues(alpha: 0.12)
      : const Color(0xFF4F46E5).withValues(alpha: 0.08);

  Color get accentBorder => isDark
      ? const Color(0xFF818CF8).withValues(alpha: 0.40)
      : const Color(0xFF4F46E5).withValues(alpha: 0.25);

  // ── Form fields ───────────────────────────────────────────────────────────
  Color get fieldBg => isDark
      ? Colors.white.withValues(alpha: 0.07)
      : const Color(0xFFF1F5F9);

  Color get fieldBorder => isDark
      ? Colors.white.withValues(alpha: 0.10)
      : const Color(0xFF4F46E5).withValues(alpha: 0.15);

  Color get fieldLabel => isDark
      ? Colors.white.withValues(alpha: 0.50)
      : const Color(0xFF0F172A).withValues(alpha: 0.50);

  Color get fieldIcon => isDark
      ? Colors.white.withValues(alpha: 0.38)
      : const Color(0xFF0F172A).withValues(alpha: 0.35);

  Color get fieldText => isDark ? Colors.white : const Color(0xFF0F172A);

  // ── Surfaces ─────────────────────────────────────────────────────────────
  Color get divider => isDark
      ? Colors.white.withValues(alpha: 0.08)
      : const Color(0xFF4F46E5).withValues(alpha: 0.08);

  Color get iconContainerBg => isDark
      ? Colors.white.withValues(alpha: 0.08)
      : const Color(0xFF4F46E5).withValues(alpha: 0.08);

  Color get iconContainerBorder => isDark
      ? Colors.white.withValues(alpha: 0.12)
      : const Color(0xFF4F46E5).withValues(alpha: 0.12);

  Color get iconColor => isDark ? Colors.white : const Color(0xFF0F172A);

  // ── Bottom nav ────────────────────────────────────────────────────────────
  Color get navBg => isDark
      ? const Color(0xFF0C0E1A).withValues(alpha: 0.92)
      : Colors.white.withValues(alpha: 0.92);

  Color get navBorder => isDark
      ? Colors.white.withValues(alpha: 0.08)
      : const Color(0xFF4F46E5).withValues(alpha: 0.10);

  Color get navInactive => isDark
      ? Colors.white.withValues(alpha: 0.35)
      : const Color(0xFF0F172A).withValues(alpha: 0.35);
}
