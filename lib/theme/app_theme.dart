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
// AppTheme — ThemeData definitions
// ---------------------------------------------------------------------------
abstract class AppTheme {
  static const _fontFamily = 'Nunito';

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
// AppColors — semantic color tokens (light only)
// ---------------------------------------------------------------------------
class AppColors {
  const AppColors._();

  factory AppColors.of(BuildContext context) => const AppColors._();

  // ── Backgrounds & gradients ──────────────────────────────────────────────
  Color get scaffoldBg => const Color(0xFFF2FBF0);

  List<Color> get bgGradient =>
      [const Color(0xFFE8F5D8), const Color(0xFFF2FBF0), const Color(0xFFF8FFF4)];

  // ── Cards ────────────────────────────────────────────────────────────────
  Color get cardBg => Colors.white;

  List<Color> get cardGradient => [Colors.white, const Color(0xFFF5FBF0)];

  Color get cardBorder => const Color(0xFF7BC344).withValues(alpha: 0.12);

  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF7BC344).withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  // ── Sheet / modal backgrounds ────────────────────────────────────────────
  Color get sheetBg => Colors.white;

  // ── Text ─────────────────────────────────────────────────────────────────
  Color get primaryText => const Color(0xFF0F172A);

  Color get secondaryText => const Color(0xFF0F172A).withValues(alpha: 0.55);

  Color get tertiaryText => const Color(0xFF0F172A).withValues(alpha: 0.35);

  // ── Accent — fairway lime green ───────────────────────────────────────────
  Color get accent => const Color(0xFF5A9E1F);

  Color get accentBg => const Color(0xFF7BC344).withValues(alpha: 0.10);

  Color get accentBorder => const Color(0xFF7BC344).withValues(alpha: 0.30);

  // ── Form fields ───────────────────────────────────────────────────────────
  Color get fieldBg => Colors.white;

  Color get fieldBorder => const Color(0xFF7BC344).withValues(alpha: 0.18);

  Color get fieldLabel => const Color(0xFF0F172A).withValues(alpha: 0.50);

  Color get fieldIcon => const Color(0xFF0F172A).withValues(alpha: 0.35);

  Color get fieldText => const Color(0xFF0F172A);

  // ── Surfaces ─────────────────────────────────────────────────────────────
  Color get divider => const Color(0xFF7BC344).withValues(alpha: 0.10);

  Color get iconContainerBg => const Color(0xFF7BC344).withValues(alpha: 0.10);

  Color get iconContainerBorder => const Color(0xFF7BC344).withValues(alpha: 0.15);

  Color get iconColor => const Color(0xFF0F172A);

  // ── Bottom nav ────────────────────────────────────────────────────────────
  Color get navBg => Colors.white.withValues(alpha: 0.50);

  Color get navBorder => const Color(0xFF7BC344).withValues(alpha: 0.15);

  Color get navInactive => const Color(0xFF0F172A).withValues(alpha: 0.35);
}
