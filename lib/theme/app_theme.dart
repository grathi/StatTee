import 'package:flutter/material.dart';
import 'package:superellipse_shape/superellipse_shape.dart';

// ---------------------------------------------------------------------------
// ClipSuperellipse — drop-in replacement for ClipSmoothRect
// ---------------------------------------------------------------------------
class ClipSuperellipse extends StatelessWidget {
  final double cornerRadius;
  final Widget child;
  const ClipSuperellipse({super.key, required this.cornerRadius, required this.child});

  @override
  Widget build(BuildContext context) => ClipPath(
        clipper: _SuperellipseClipper(BorderRadius.circular(cornerRadius)),
        child: child,
      );
}

class _SuperellipseClipper extends CustomClipper<Path> {
  final BorderRadius borderRadius;
  const _SuperellipseClipper(this.borderRadius);
  @override
  Path getClip(Size size) =>
      SuperellipseShape(borderRadius: borderRadius).getOuterPath(Offset.zero & size);
  @override
  bool shouldReclip(_SuperellipseClipper old) => old.borderRadius != borderRadius;
}

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
          seedColor: const Color(0xFF7BC344),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0C0E1A),
        fontFamily: _fontFamily,
        useMaterial3: true,
      );

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7BC344),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF2FBF0),
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
      isDark ? const Color(0xFF0C0E1A) : const Color(0xFFF2FBF0);

  List<Color> get bgGradient => isDark
      ? [const Color(0xFF080A14), const Color(0xFF0F1225), const Color(0xFF080A14)]
      : [const Color(0xFFE8F5D8), const Color(0xFFF2FBF0), const Color(0xFFF8FFF4)];

  // ── Cards ────────────────────────────────────────────────────────────────
  Color get cardBg =>
      isDark ? Colors.white.withValues(alpha: 0.07) : Colors.white;

  List<Color> get cardGradient => isDark
      ? [Colors.white.withValues(alpha: 0.085), Colors.white.withValues(alpha: 0.046)]
      : [Colors.white, const Color(0xFFF5FBF0)];

  Color get cardBorder => isDark
      ? Colors.white.withValues(alpha: 0.10)
      : const Color(0xFF7BC344).withValues(alpha: 0.12);

  List<BoxShadow> get cardShadow => isDark
      ? []
      : [
          BoxShadow(
            color: const Color(0xFF7BC344).withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
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

  // ── Accent — fairway lime green (matched to illustration) ────────────────
  Color get accent =>
      isDark ? const Color(0xFF8FD44E) : const Color(0xFF5A9E1F);

  Color get accentBg => isDark
      ? const Color(0xFF8FD44E).withValues(alpha: 0.12)
      : const Color(0xFF7BC344).withValues(alpha: 0.10);

  Color get accentBorder => isDark
      ? const Color(0xFF8FD44E).withValues(alpha: 0.40)
      : const Color(0xFF7BC344).withValues(alpha: 0.30);

  // ── Form fields ───────────────────────────────────────────────────────────
  Color get fieldBg => isDark
      ? Colors.white.withValues(alpha: 0.07)
      : Colors.white;

  Color get fieldBorder => isDark
      ? Colors.white.withValues(alpha: 0.10)
      : const Color(0xFF7BC344).withValues(alpha: 0.18);

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
      : const Color(0xFF7BC344).withValues(alpha: 0.10);

  Color get iconContainerBg => isDark
      ? Colors.white.withValues(alpha: 0.08)
      : const Color(0xFF7BC344).withValues(alpha: 0.10);

  Color get iconContainerBorder => isDark
      ? Colors.white.withValues(alpha: 0.12)
      : const Color(0xFF7BC344).withValues(alpha: 0.15);

  Color get iconColor => isDark ? Colors.white : const Color(0xFF0F172A);

  // ── Bottom nav ────────────────────────────────────────────────────────────
  Color get navBg => isDark
      ? const Color(0xFF0C0E1A).withValues(alpha: 0.50)
      : Colors.white.withValues(alpha: 0.50);

  Color get navBorder => isDark
      ? Colors.white.withValues(alpha: 0.08)
      : const Color(0xFF7BC344).withValues(alpha: 0.15);

  Color get navInactive => isDark
      ? Colors.white.withValues(alpha: 0.35)
      : const Color(0xFF0F172A).withValues(alpha: 0.35);
}
