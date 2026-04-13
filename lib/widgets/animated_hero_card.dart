import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/round.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';

// ── AnimatedHeroCard ──────────────────────────────────────────────────────────
//
// Replaces the static HeroActionCard in the home screen carousel.
// Receives optional WeatherNow and Round to adapt its appearance and CTA text.
// Falls back to the original green gradient style when weather is null.

class AnimatedHeroCard extends StatefulWidget {
  final double hPad;
  final double sw;
  final double sh;
  final double labelSize;
  final double bodySize;
  final VoidCallback onTap;
  final WeatherNow? weather;    // null → default green mode
  final Round? activeRound;     // null → "Start Round"

  const AnimatedHeroCard({
    super.key,
    required this.hPad,
    required this.sw,
    required this.sh,
    required this.labelSize,
    required this.bodySize,
    required this.onTap,
    this.weather,
    this.activeRound,
  });

  @override
  State<AnimatedHeroCard> createState() => _AnimatedHeroCardState();
}

class _AnimatedHeroCardState extends State<AnimatedHeroCard>
    with TickerProviderStateMixin {
  // Weather particle animation (rain streaks / fog drift)
  late AnimationController _particleCtrl;

  // Flag sway — speed driven by windSpeed
  late AnimationController _flagCtrl;

  // CTA button press feedback
  final ValueNotifier<bool> _tapped = ValueNotifier(false);

  double get _windSpeed => widget.weather?.windSpeed ?? 0;

  @override
  void initState() {
    super.initState();

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    final flagDuration = (1800 - _windSpeed * 40).clamp(600, 1800).toInt();
    _flagCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: flagDuration),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(AnimatedHeroCard old) {
    super.didUpdateWidget(old);
    // Adjust flag speed when windSpeed changes
    if (old.weather?.windSpeed != widget.weather?.windSpeed) {
      final ms = (1800 - _windSpeed * 40).clamp(600, 1800).toInt();
      _flagCtrl.duration = Duration(milliseconds: ms);
      if (!_flagCtrl.isAnimating) _flagCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _particleCtrl.dispose();
    _flagCtrl.dispose();
    _tapped.dispose();
    super.dispose();
  }

  // ── Derived helpers ────────────────────────────────────────────────────────

  /// Lowercase condition string, empty when no weather
  String get _cond => widget.weather?.condition.toLowerCase() ?? '';

  bool get _isSunny    => _cond.contains('clear') || _cond.contains('sunny');
  bool get _isCloudy   => _cond.contains('cloud');
  bool get _isRainy    => _cond.contains('rain') || _cond.contains('drizzle') || _cond.contains('shower');
  bool get _isFoggy    => _cond.contains('fog') || _cond.contains('mist') || _cond.contains('haze');
  bool get _hasWeather => widget.weather != null;

  /// Top-to-bottom sky gradient based on condition
  List<Color> get _skyColors {
    if (_isSunny)  return const [Color(0xFF1A88C9), Color(0xFF3DB8F5)];
    if (_isCloudy) return const [Color(0xFF4A7A9B), Color(0xFF6B9BB8)];
    if (_isRainy)  return const [Color(0xFF2D3F52), Color(0xFF445566)];
    if (_isFoggy)  return const [Color(0xFF8899AA), Color(0xFFAABBC0)];
    // Default — keep original dark green hero gradient
    return const [Color(0xFF1A3A08), Color(0xFF3D6E14), Color(0xFF5A9E1F)];
  }

  /// Time-of-day tint overlay (bottom gradient)
  _TimeOfDayTint get _todTint {
    final h = DateTime.now().hour;
    if (h >= 5  && h < 10) return _TimeOfDayTint.morning;
    if (h >= 10 && h < 16) return _TimeOfDayTint.midday;
    if (h >= 16 && h < 20) return _TimeOfDayTint.evening;
    return _TimeOfDayTint.night;
  }

  /// AI insight chip text
  String get _insightText {
    if (!_hasWeather) return '🏌️ Ready to play';
    if (_isRainy)    return '🌧️ Wet course — drop a club';
    if (_isFoggy)    return '🌫️ Low visibility — play safe';
    if (_windSpeed >= 15) return '💨 Wind: ${widget.weather!.windLabel}';
    if (_isSunny && _windSpeed < 5) return '💡 Ideal conditions today';
    return '🏌️ ${widget.weather!.conditionSummary}';
  }

  /// CTA button label based on activeRound state
  String get _ctaLabel {
    final r = widget.activeRound;
    if (r == null) return 'Start Round';
    if (r.status == RoundStatus.active) return 'Resume Round – Hole ${r.currentHole}';
    return 'Continue Round';
  }

  @override
  Widget build(BuildContext context) {
    final sw       = widget.sw;
    final sh       = widget.sh;
    final innerPad = (sw * 0.058).clamp(18.0, 26.0);
    final isDefault = !_hasWeather;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.hPad),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: ShapeDecoration(
            // Sky gradient (or default green gradient)
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDefault
                  ? const [Color(0xFF1A3A08), Color(0xFF3D6E14), Color(0xFF5A9E1F)]
                  : _skyColors,
              stops: isDefault ? const [0.0, 0.55, 1.0] : null,
            ),
            shape: SuperellipseShape(borderRadius: BorderRadius.circular(48)),
            shadows: const [
              BoxShadow(
                color: Color(0x725A9E1F),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // ── Layer 1: Time-of-day tint (bottom gradient) ─────────────
              if (_todTint != _TimeOfDayTint.midday)
                Positioned.fill(
                  child: ClipSuperellipse(
                    cornerRadius: 40,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            _todTint.color.withValues(alpha: _todTint.alpha),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55],
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Layer 2: Course silhouette hills ─────────────────────────
              Positioned.fill(
                child: ClipSuperellipse(
                  cornerRadius: 40,
                  child: CustomPaint(painter: _CourseSilhouettePainter()),
                ),
              ),

              // ── Layer 3: hero.png photo overlay ──────────────────────────
              Positioned.fill(
                child: ClipSuperellipse(
                  cornerRadius: 40,
                  child: Image.asset(
                    'assets/hero.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                  ),
                ),
              ),

              // ── Layer 4: Left-fade vignette ───────────────────────────────
              Positioned.fill(
                child: ClipSuperellipse(
                  cornerRadius: 40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.58),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.60],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Layer 5: Sunny glare (radial top-right) ───────────────────
              if (_isSunny)
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: sw * 0.45,
                    height: sw * 0.45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Layer 6: Weather particles (rain / fog / clouds) ──────────
              if (_isRainy || _isFoggy || _isCloudy)
                Positioned.fill(
                  child: ClipSuperellipse(
                    cornerRadius: 40,
                    child: AnimatedBuilder(
                      animation: _particleCtrl,
                      builder: (_, __) => CustomPaint(
                        painter: _WeatherParticlePainter(
                          progress: _particleCtrl.value,
                          isRain: _isRainy,
                          isFog: _isFoggy,
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Layer 7: Weather tint (rain dark / fog light) ─────────────
              if (_isRainy || _isFoggy)
                Positioned.fill(
                  child: ClipSuperellipse(
                    cornerRadius: 40,
                    child: ColoredBox(
                      color: _isRainy
                          ? Colors.black.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                ),

              // ── Layer 8: Animated flag ────────────────────────────────────
              Positioned.fill(
                child: ClipSuperellipse(
                  cornerRadius: 40,
                  child: AnimatedBuilder(
                    animation: _flagCtrl,
                    builder: (_, __) => CustomPaint(
                      painter: _AnimatedFlagPainter(
                        sway: _flagCtrl.value,
                        windSpeed: _windSpeed,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Layer 9: UI — chip + heading + CTA ──────────────────────
              Padding(
                padding: EdgeInsets.all(innerPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // AI insight chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: ShapeDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: SuperellipseShape(
                            borderRadius: BorderRadius.circular(40)),
                      ),
                      child: Text(
                        _insightText,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: widget.labelSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    SizedBox(height: sh * 0.012),

                    // Heading
                    Text(
                      'Start Round',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: Colors.white,
                        fontSize: (sw * 0.075).clamp(26.0, 34.0),
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),

                    SizedBox(height: sh * 0.010),

                    // CTA pill button with tap feedback
                    _CTAButton(
                      label: _ctaLabel,
                      labelSize: widget.labelSize,
                      onTap: widget.onTap,
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            // Entry animation — fade + slide up
            .animate()
            .fadeIn(duration: 500.ms, curve: Curves.easeOut)
            .slideY(
                begin: 0.06,
                end: 0,
                duration: 500.ms,
                curve: Curves.easeOutCubic),
      ),
    );
  }
}

// ── CTA Button with tap feedback ──────────────────────────────────────────────

class _CTAButton extends StatefulWidget {
  final String label;
  final double labelSize;
  final VoidCallback onTap;

  const _CTAButton({
    required this.label,
    required this.labelSize,
    required this.onTap,
  });

  @override
  State<_CTAButton> createState() => _CTAButtonState();
}

class _CTAButtonState extends State<_CTAButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.35), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.labelSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: widget.labelSize * 1.15),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Painters ──────────────────────────────────────────────────────────────────

/// Recreated locally so the widget file is self-contained (same logic as in
/// home_screen.dart — grass hill silhouette).
class _CourseSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height * 0.75);
    path.cubicTo(size.width * 0.25, size.height * 0.55,
        size.width * 0.50, size.height * 0.65, size.width * 0.70, size.height * 0.50);
    path.cubicTo(size.width * 0.82, size.height * 0.42,
        size.width * 0.90, size.height * 0.48, size.width, size.height * 0.44);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Animated flag pole + triangular pennant at the right-center of the card.
/// [sway] is 0..1 (from AnimationController.repeat(reverse: true)).
/// [windSpeed] drives how far the flag tip moves.
class _AnimatedFlagPainter extends CustomPainter {
  final double sway;      // 0..1
  final double windSpeed;

  const _AnimatedFlagPainter({required this.sway, required this.windSpeed});

  @override
  void paint(Canvas canvas, Size size) {
    // Pole base sits on the silhouette hill at ~68% width, 50% height
    final poleX   = size.width  * 0.68;
    final poleTop = size.height * 0.22;
    final poleBot = size.height * 0.52;

    final polePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(poleX, poleTop), Offset(poleX, poleBot), polePaint);

    // Flag tip oscillation: maxSway 0–8px based on windSpeed
    final maxSway = (windSpeed / 30 * 8).clamp(1.0, 8.0);
    final swayPx  = math.sin(sway * math.pi) * maxSway;

    final flagH    = size.height * 0.08;
    final tipX     = poleX + flagH * 1.4 + swayPx;
    final tipY     = poleTop + flagH * 0.5;

    final flagPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    final flagPath = Path()
      ..moveTo(poleX, poleTop)
      ..lineTo(tipX, tipY)
      ..lineTo(poleX, poleTop + flagH)
      ..close();

    canvas.drawPath(flagPath, flagPaint);
  }

  @override
  bool shouldRepaint(_AnimatedFlagPainter old) =>
      old.sway != sway || old.windSpeed != windSpeed;
}

/// Rain streaks (diagonal lines) or fog wisps (large translucent ovals).
/// [progress] is AnimationController.value (0..1, repeating).
class _WeatherParticlePainter extends CustomPainter {
  final double progress;
  final bool isRain;
  final bool isFog;

  const _WeatherParticlePainter({
    required this.progress,
    required this.isRain,
    required this.isFog,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isRain) {
      _paintRain(canvas, size);
    } else if (isFog) {
      _paintFog(canvas, size);
    } else {
      _paintClouds(canvas, size);
    }
  }

  void _paintRain(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    const streakCount = 22;
    const streakH = 12.0;
    const angleX  = 3.0;  // slight diagonal

    final rng = math.Random(42); // fixed seed — consistent positions
    for (int i = 0; i < streakCount; i++) {
      final x = rng.nextDouble() * size.width;
      // Offset by progress so streaks travel downward continuously
      final rawY = rng.nextDouble() * size.height + progress * size.height;
      final y    = rawY % size.height;

      canvas.drawLine(
        Offset(x + angleX, y),
        Offset(x, y + streakH),
        paint,
      );
    }
  }

  void _paintFog(Canvas canvas, Size size) {
    final rng = math.Random(7);
    for (int i = 0; i < 4; i++) {
      // Each wisp drifts horizontally at slightly different speeds
      final speed   = 0.3 + i * 0.15;
      final baseX   = (rng.nextDouble() * size.width - size.width * 0.3 +
              progress * size.width * speed) %
          (size.width * 1.3) - size.width * 0.15;
      final baseY   = size.height * (0.20 + i * 0.18);
      final wispW   = size.width  * (0.45 + rng.nextDouble() * 0.35);
      final wispH   = size.height * (0.08 + rng.nextDouble() * 0.06);

      final rect  = Rect.fromCenter(
          center: Offset(baseX, baseY), width: wispW, height: wispH);
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawOval(rect, paint);
    }
  }

  void _paintClouds(Canvas canvas, Size size) {
    // Two slow-drifting cloud ovals
    for (int i = 0; i < 2; i++) {
      final offsetFrac = (progress + i * 0.5) % 1.0;
      final cx = offsetFrac * (size.width + 60) - 30;
      final cy = size.height * (0.18 + i * 0.14);
      final cw = size.width  * 0.32;
      final ch = size.height * 0.10;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, cy), width: cw, height: ch),
          paint);
    }
  }

  @override
  bool shouldRepaint(_WeatherParticlePainter old) =>
      old.progress != progress;
}

/// Copy of _DimplePainter from golf_animations.dart — kept local so this widget
/// file is fully self-contained with no cross-file coupling.
class _DimplePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height / 2;
    final r  = size.width  / 2;

    canvas.save();
    canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)));

    final dimpleR    = r * 0.13;
    final spacing    = r * 0.36;
    final shadowPaint = Paint()
      ..color = const Color(0x55888880)
      ..style = PaintingStyle.stroke
      ..strokeWidth = dimpleR * 0.6;
    final innerPaint = Paint()
      ..color = const Color(0x22000000)
      ..style = PaintingStyle.fill;

    for (int row = -4; row <= 4; row++) {
      final offsetX = (row.isOdd ? spacing * 0.5 : 0.0);
      for (int col = -4; col <= 4; col++) {
        final dx   = cx + col * spacing + offsetX;
        final dy   = cy + row * spacing * 0.88;
        final dist =
            math.sqrt((dx - cx) * (dx - cx) + (dy - cy) * (dy - cy));
        if (dist + dimpleR > r * 0.95) continue;
        final c = Offset(dx, dy);
        canvas.drawCircle(c, dimpleR, innerPaint);
        canvas.drawCircle(c, dimpleR, shadowPaint);
      }
    }

    final highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.7),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(cx - r * 0.28, cy - r * 0.32),
        radius: r * 0.38,
      ));
    canvas.drawCircle(
        Offset(cx - r * 0.28, cy - r * 0.32), r * 0.38, highlightPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Time of day enum ──────────────────────────────────────────────────────────

enum _TimeOfDayTint { morning, midday, evening, night }

extension _TimeOfDayTintExt on _TimeOfDayTint {
  Color get color {
    switch (this) {
      case _TimeOfDayTint.morning: return const Color(0xFFFF8C00); // warm amber
      case _TimeOfDayTint.evening: return const Color(0xFFFF5733); // pink/orange
      case _TimeOfDayTint.night:   return const Color(0xFF0A1628); // deep navy
      default:                     return Colors.transparent;
    }
  }

  double get alpha {
    switch (this) {
      case _TimeOfDayTint.morning: return 0.20;
      case _TimeOfDayTint.evening: return 0.25;
      case _TimeOfDayTint.night:   return 0.30;
      default:                     return 0.0;
    }
  }
}
