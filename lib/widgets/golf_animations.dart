import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

// ── BouncingGolfBall ──────────────────────────────────────────────────────────

class BouncingGolfBall extends StatefulWidget {
  final Color color;
  final double size;
  const BouncingGolfBall({super.key, required this.color, this.size = 36});

  @override
  State<BouncingGolfBall> createState() => _BouncingGolfBallState();
}

class _BouncingGolfBallState extends State<BouncingGolfBall>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s       = widget.size;
    final ballSize = s * 0.28;
    final bounceH  = s * 0.44;
    final shadowH  = s * 0.083;
    final totalH   = shadowH + bounceH + ballSize + s * 0.05;
    return SizedBox(
      width: s,
      height: totalH,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = math.sin(_ctrl.value * math.pi);
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                bottom: 0,
                child: Container(
                  width: ballSize - t * (ballSize * 0.33),
                  height: shadowH,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.25 - t * 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Positioned(
                bottom: shadowH + t * bounceH,
                child: Container(
                  width: ballSize,
                  height: ballSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(-0.35, -0.45),
                      radius: 0.85,
                      colors: [
                        Color(0xFFFFFFFF),
                        Color(0xFFE8E8E0),
                        Color(0xFFCCCCC0),
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                  child: CustomPaint(painter: _DimplePainter()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DimplePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;

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
        final dist = math.sqrt((dx - cx) * (dx - cx) + (dy - cy) * (dy - cy));
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── GolfSaveOverlay ───────────────────────────────────────────────────────────

/// Shows a non-blocking "Saved ✓" pill overlay for ~1.2 s after a successful
/// hole-score save. Call [GolfSaveOverlay.show] from the happy path of a save.
class GolfSaveOverlay {
  static void show(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _GolfSaveOverlayWidget(onDone: () {
        if (entry.mounted) entry.remove();
      }),
    );
    overlay.insert(entry);
  }
}

class _GolfSaveOverlayWidget extends StatefulWidget {
  final VoidCallback onDone;
  const _GolfSaveOverlayWidget({required this.onDone});

  @override
  State<_GolfSaveOverlayWidget> createState() => _GolfSaveOverlayWidgetState();
}

class _GolfSaveOverlayWidgetState extends State<_GolfSaveOverlayWidget>
    with TickerProviderStateMixin {
  late AnimationController _exitCtrl;
  late AnimationController _ballCtrl;
  bool _done = false;

  @override
  void initState() {
    super.initState();

    _exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));

    // Single bounce — forward once, no repeat
    _ballCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();

    Future.delayed(const Duration(milliseconds: 950), () async {
      if (!mounted) return;
      await _exitCtrl.forward();
      if (mounted && !_done) {
        _done = true;
        widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _exitCtrl.dispose();
    _ballCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Positioned(
      top: MediaQuery.of(context).padding.top + 72,
      left: 0,
      right: 0,
      child: Center(
        child: FadeTransition(
          opacity: ReverseAnimation(
              CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn)),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                  color: const Color(0xFF7BC344).withValues(alpha: 0.30)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7BC344).withValues(alpha: 0.20),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SingleBounceBall(controller: _ballCtrl),
                const SizedBox(width: 10),
                Text(
                  'Saved',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: c.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF5A9E1F), size: 16),
              ],
            ),
          )
              .animate()
              .slideY(
                  begin: -0.4,
                  end: 0,
                  duration: 250.ms,
                  curve: Curves.easeOutCubic)
              .fadeIn(duration: 250.ms),
        ),
      ),
    );
  }
}

/// A 24 px golf ball that bounces once using an externally-owned controller.
class _SingleBounceBall extends StatelessWidget {
  final AnimationController controller;
  const _SingleBounceBall({required this.controller});

  @override
  Widget build(BuildContext context) {
    const s        = 24.0;
    const ballSize = s * 0.65;
    const bounceH  = s * 0.35;
    const shadowH  = s * 0.10;
    return SizedBox(
      width: s,
      height: s,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          final t = math.sin(controller.value * math.pi);
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                bottom: 0,
                child: Container(
                  width: ballSize - t * (ballSize * 0.33),
                  height: shadowH,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12 - t * 0.08),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Positioned(
                bottom: shadowH + t * bounceH,
                child: Container(
                  width: ballSize,
                  height: ballSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(-0.35, -0.45),
                      radius: 0.85,
                      colors: [
                        Color(0xFFFFFFFF),
                        Color(0xFFE8E8E0),
                        Color(0xFFCCCCC0),
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                  child: CustomPaint(painter: _DimplePainter()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── CloudSyncPulse ────────────────────────────────────────────────────────────

/// Shows a non-blocking "Synced" badge in the top-right corner for ~2 s after
/// data is confirmed written to Firestore. Call [CloudSyncPulse.show].
class CloudSyncPulse {
  static void show(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CloudSyncPulseWidget(onDone: () {
        if (entry.mounted) entry.remove();
      }),
    );
    overlay.insert(entry);
  }
}

class _CloudSyncPulseWidget extends StatefulWidget {
  final VoidCallback onDone;
  const _CloudSyncPulseWidget({required this.onDone});

  @override
  State<_CloudSyncPulseWidget> createState() => _CloudSyncPulseWidgetState();
}

class _CloudSyncPulseWidgetState extends State<_CloudSyncPulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _exitCtrl;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    Future.delayed(const Duration(milliseconds: 1700), () async {
      if (!mounted) return;
      await _exitCtrl.forward();
      if (mounted && !_done) {
        _done = true;
        widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safePadTop = MediaQuery.of(context).padding.top;
    return Positioned(
      top: safePadTop + 12,
      right: 16,
      child: FadeTransition(
        opacity: ReverseAnimation(
            CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
                color: const Color(0xFF7BC344).withValues(alpha: 0.30)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5A9E1F).withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_done_rounded,
                  size: 14, color: Color(0xFF5A9E1F)),
              const SizedBox(width: 5),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF5A9E1F),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Synced',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: const Color(0xFF0F172A).withValues(alpha: 0.75),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        )
            .animate()
            .scale(
                begin: const Offset(0.85, 0.85),
                duration: 220.ms,
                curve: Curves.easeOutBack)
            .fadeIn(duration: 220.ms)
            .shimmer(
                delay: 400.ms,
                duration: 600.ms,
                color: const Color(0xFF7BC344).withValues(alpha: 0.35)),
      ),
    );
  }
}
