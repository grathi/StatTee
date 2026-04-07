import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/onboarding_service.dart';
import '../utils/l10n_extension.dart';
import 'home_screen.dart';

// ---------------------------------------------------------------------------
// Slide data
// ---------------------------------------------------------------------------
class _Slide {
  final String tag;
  final IconData tagIcon;
  final String title;
  final String body;
  final Color accentColor;
  final bool isAiSlide;

  const _Slide({
    required this.tag,
    required this.tagIcon,
    required this.title,
    required this.body,
    required this.accentColor,
    this.isAiSlide = false,
  });
}

// ---------------------------------------------------------------------------
// OnboardingScreen
// ---------------------------------------------------------------------------
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _page = 0;

  late AnimationController _contentCtrl;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  // Single looping controller shared by all visual painters
  late AnimationController _visualCtrl;

  @override
  void initState() {
    super.initState();

    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _contentFade = CurvedAnimation(
        parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic));

    _visualCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _contentCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _contentCtrl.dispose();
    _visualCtrl.dispose();
    super.dispose();
  }

  List<_Slide> _buildSlides(BuildContext context) {
    final l10n = context.l10n;
    return [
      _Slide(
        tag: l10n.onboardingScoreTrackingTag,
        tagIcon: Icons.sports_golf_rounded,
        title: l10n.onboardingTrackEveryRoundTitle,
        body: l10n.onboardingScoreTrackingBody,
        accentColor: const Color(0xFF7BC344),
      ),
      _Slide(
        tag: l10n.onboardingPerformanceTag,
        tagIcon: Icons.bar_chart_rounded,
        title: l10n.onboardingGolfDNATitle,
        body: l10n.onboardingPerformanceBody,
        accentColor: const Color(0xFF4CAF8A),
      ),
      _Slide(
        tag: l10n.onboardingMultiplayerTag,
        tagIcon: Icons.group_rounded,
        title: l10n.onboardingPlayTogetherTitle,
        body: l10n.onboardingMultiplayerBody,
        accentColor: const Color(0xFF5BB8A0),
      ),
      _Slide(
        tag: l10n.onboardingSocialTag,
        tagIcon: Icons.emoji_events_rounded,
        title: l10n.onboardingFriendsLeaderboardTitle,
        body: l10n.onboardingSocialBody,
        accentColor: const Color(0xFF7BC344),
      ),
      _Slide(
        tag: l10n.onboardingAITag,
        tagIcon: Icons.auto_awesome_rounded,
        title: l10n.onboardingPersonalCaddieTitle,
        body: l10n.onboardingAIBody,
        accentColor: const Color(0xFF6ECFF6),
        isAiSlide: true,
      ),
    ];
  }

  Future<void> _finish() async {
    await OnboardingService.markTourSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const HomeScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _next(List<_Slide> slides) {
    if (_page < slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _onPageChanged(int i) {
    setState(() => _page = i);
    _contentCtrl.forward(from: 0);
  }

  CustomPainter _painterForSlide(int index, double t, Color color) {
    switch (index) {
      case 0:
        return _ScorecardPainter(t: t, color: color);
      case 1:
        return _StatsPainter(t: t, color: color);
      case 2:
        return _MultiplayerPainter(t: t, color: color);
      case 3:
        return _LeaderboardPainter(t: t, color: color);
      default:
        return _AiCaddiePainter(t: t, color: color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slides      = _buildSlides(context);
    final slide       = slides[_page];
    final size        = MediaQuery.sizeOf(context);
    final visualHeight = size.height * 0.50;
    final isLast      = _page == slides.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // white icons on dark background
      child: Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      // ── FAB — bottom-right ──────────────────────────────────────────────
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // "Swing. Track. Win." label fades in on last slide
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isLast ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8, right: 4),
                child: Text(
                  context.l10n.onboardingTagline,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: slide.accentColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            // Fixed 62×62 circle FAB — only icon changes
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: slide.accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: slide.accentColor.withValues(alpha: 0.45),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () => _next(slides),
                  customBorder: const CircleBorder(),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: isLast
                          ? const Icon(
                              key: ValueKey('check'),
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 28,
                            )
                          : const Icon(
                              key: ValueKey('arrow'),
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      body: Stack(
        children: [
          // ── Main content ───────────────────────────────────────────────
          Column(
            children: [
              // Visual panel
              SizedBox(
                height: visualHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: const Color(0xFF0D1117)),

                    AnimatedBuilder(
                      animation: _visualCtrl,
                      builder: (_, __) => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: CustomPaint(
                          key: ValueKey(_page),
                          size: Size(size.width, visualHeight),
                          painter: _painterForSlide(
                              _page, _visualCtrl.value, slide.accentColor),
                        ),
                      ),
                    ),

                    // Bottom fade
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      height: 72,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              const Color(0xFF0D1117),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Text content + dots
              Expanded(
                child: PageView.builder(
                  controller: _pageCtrl,
                  onPageChanged: _onPageChanged,
                  itemCount: slides.length,
                  itemBuilder: (_, i) => _ContentPage(
                    slide: slides[i],
                    contentFade: i == _page
                        ? _contentFade
                        : const AlwaysStoppedAnimation(1.0),
                    contentSlide: i == _page
                        ? _contentSlide
                        : const AlwaysStoppedAnimation(Offset.zero),
                    currentPage: _page,
                    totalPages: slides.length,
                  ),
                ),
              ),
            ],
          ),

          // ── Skip — top-right overlay ────────────────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isLast ? 0.0 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: TextButton(
                    onPressed: isLast ? null : _finish,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      context.l10n.skip,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.40),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ), // Scaffold
    ); // AnnotatedRegion
  }
}

// ---------------------------------------------------------------------------
// Content panel (tag + title + body + dots only — no buttons)
// ---------------------------------------------------------------------------
class _ContentPage extends StatelessWidget {
  const _ContentPage({
    required this.slide,
    required this.contentFade,
    required this.contentSlide,
    required this.currentPage,
    required this.totalPages,
  });

  final _Slide slide;
  final Animation<double> contentFade;
  final Animation<Offset> contentSlide;
  final int currentPage;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            28, 4, 28, (size.height * 0.025).clamp(12.0, 24.0)),
        child: FadeTransition(
          opacity: contentFade,
          child: SlideTransition(
            position: contentSlide,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag — badge pill for every slide
                _SlideBadge(color: slide.accentColor, icon: slide.tagIcon, label: slide.tag),

                const SizedBox(height: 8),

                // Title
                Text(
                  slide.title,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: (size.width * 0.100).clamp(30.0, 44.0),
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.08,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 10),

                // Body
                Text(
                  slide.body,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: (size.width * 0.037).clamp(13.0, 15.5),
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.52),
                    height: 1.62,
                  ),
                ),

                if (slide.isAiSlide) ...[
                  const SizedBox(height: 14),
                  _GeminiBadge(),
                ],

                const Spacer(),

                // Dots — bottom-left, away from FAB
                Row(
                  children: List.generate(totalPages, (i) {
                    final active = i == currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(right: 8),
                      width: active ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active
                            ? slide.accentColor
                            : Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 80), // space for FAB
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Unified slide badge — same pill style for all slides
// ---------------------------------------------------------------------------
class _SlideBadge extends StatelessWidget {
  const _SlideBadge({
    required this.color,
    required this.icon,
    required this.label,
  });
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _GeminiBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded,
              size: 13, color: Colors.white.withValues(alpha: 0.45)),
          const SizedBox(width: 5),
          Text(
            context.l10n.onboardingPoweredByGemini,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.42),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PAINTERS — one per slide
// ============================================================================

// ---------------------------------------------------------------------------
// Slide 1: Score Tracking
// Animated golf hole layout — 9 circles appear one by one with score numbers
// ---------------------------------------------------------------------------
class _ScorecardPainter extends CustomPainter {
  const _ScorecardPainter({required this.t, required this.color});
  final double t;
  final Color color;

  static const _scores = [4, 3, 5, 4, 3, 4, 5, 3, 4];
  static const _pars   = [4, 3, 5, 4, 3, 5, 4, 3, 4];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height / 2;

    // 9 holes arranged in a 3×3 grid
    const cols = 3;
    const rows = 3;
    final cellW = size.width  * 0.22;
    final cellH = size.height * 0.22;
    final startX = cx - (cols - 1) / 2 * cellW;
    final startY = cy - (rows - 1) / 2 * cellH;

    for (int i = 0; i < 9; i++) {
      // Each hole appears sequentially with a stagger
      final revealT = ((t * 9) - i).clamp(0.0, 1.0);
      if (revealT <= 0) continue;

      final row = i ~/ cols;
      final col = i % cols;
      final hx  = startX + col * cellW;
      final hy  = startY + row * cellH;
      final eased = _easeOutCubic(revealT);

      final score = _scores[i];
      final par   = _pars[i];
      final diff  = score - par;

      // Colour: birdie = green, bogey = red/orange, par = white
      final nodeColor = diff < 0
          ? color
          : diff > 0
              ? const Color(0xFFFF7043)
              : Colors.white.withValues(alpha: 0.70);

      // Scale-in circle
      final radius = 22.0 * eased;
      canvas.drawCircle(
        Offset(hx, hy),
        radius + 6,
        Paint()
          ..color = nodeColor.withValues(alpha: 0.14 * eased)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawCircle(
        Offset(hx, hy),
        radius,
        Paint()
          ..color = nodeColor.withValues(alpha: 0.25 * eased)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Score number
      if (eased > 0.5) {
        final tp = TextPainter(
          text: TextSpan(
            text: '$score',
            style: TextStyle(
              color: nodeColor.withValues(alpha: eased),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
            canvas, Offset(hx - tp.width / 2, hy - tp.height / 2));
      }

      // Hole number (tiny, above circle)
      if (eased > 0.6) {
        final tp2 = TextPainter(
          text: TextSpan(
            text: '${i + 1}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.28 * eased),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp2.paint(canvas,
            Offset(hx - tp2.width / 2, hy - 30 * eased));
      }

      // Draw connecting line to next hole (left-to-right, top-to-bottom)
      if (i < 8) {
        final nextReveal = ((t * 9) - (i + 1)).clamp(0.0, 1.0);
        if (nextReveal > 0) {
          final nextRow = (i + 1) ~/ cols;
          final nextCol = (i + 1) % cols;
          final nx2 = startX + nextCol * cellW;
          final ny2 = startY + nextRow * cellH;
          canvas.drawLine(
            Offset(hx, hy),
            Offset(hx + (nx2 - hx) * _easeOutCubic(nextReveal),
                   hy + (ny2 - hy) * _easeOutCubic(nextReveal)),
            Paint()
              ..color = color.withValues(alpha: 0.18 * nextReveal)
              ..strokeWidth = 1.0,
          );
        }
      }
    }

    // Ambient glow
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.38,
      Paint()
        ..color = color.withValues(alpha: 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50),
    );
  }

  double _easeOutCubic(double t) => 1 - math.pow(1 - t, 3).toDouble();

  @override
  bool shouldRepaint(_ScorecardPainter old) => old.t != t;
}

// ---------------------------------------------------------------------------
// Slide 2: Golf DNA / Stats
// Animated bar chart — 6 bars grow upward with labels, then pulse
// ---------------------------------------------------------------------------
class _StatsPainter extends CustomPainter {
  const _StatsPainter({required this.t, required this.color});
  final double t;
  final Color color;

  static const _labels  = ['FWY', 'GIR', 'PUTTS', 'HCP', 'BOGEY', 'PAR'];
  static const _heights = [0.72, 0.55, 0.85, 0.42, 0.65, 0.90];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final barW   = size.width  * 0.075;
    final maxH   = size.height * 0.48;
    final gap    = size.width  * 0.080;
    final totalW = (_labels.length - 1) * gap;
    final startX = cx - totalW / 2;
    final baseY  = cy + maxH * 0.50;

    // Pulse factor — subtle breathe after bars are fully grown
    final allGrown = t > 0.8;
    final pulse = allGrown
        ? 1.0 + math.sin((t - 0.8) / 0.2 * 2 * math.pi) * 0.03
        : 1.0;

    for (int i = 0; i < _labels.length; i++) {
      final stagger = (i / _labels.length);
      final barT    = ((t - stagger * 0.5) / 0.6).clamp(0.0, 1.0);
      final eased   = _easeOutCubic(barT);

      final bh  = maxH * _heights[i] * eased * pulse;
      final bx  = startX + i * gap;
      final top = baseY - bh;

      // Bar glow
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bx - barW / 2 - 3, top - 4, barW + 6, bh + 4),
          const Radius.circular(8),
        ),
        Paint()
          ..color = color.withValues(alpha: 0.18 * eased)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // Bar fill — gradient
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bx - barW / 2, top, barW, bh),
          const Radius.circular(6),
        ),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              color.withValues(alpha: 0.55 * eased),
              color.withValues(alpha: 0.90 * eased),
            ],
          ).createShader(Rect.fromLTWH(bx - barW / 2, top, barW, bh)),
      );

      // Label
      if (eased > 0.3) {
        final tp = TextPainter(
          text: TextSpan(
            text: _labels[i],
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35 * eased),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas,
            Offset(bx - tp.width / 2, baseY + 6));
      }

      // Value on top
      if (eased > 0.7) {
        final pct = (_heights[i] * 100).round();
        final tp2 = TextPainter(
          text: TextSpan(
            text: '$pct',
            style: TextStyle(
              color: color.withValues(alpha: eased),
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp2.paint(canvas, Offset(bx - tp2.width / 2, top - 14));
      }
    }

    // Baseline
    canvas.drawLine(
      Offset(startX - barW, baseY),
      Offset(startX + totalW + barW, baseY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.10)
        ..strokeWidth = 1.0,
    );

    // Background glow
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.40,
      Paint()
        ..color = color.withValues(alpha: 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48),
    );
  }

  double _easeOutCubic(double t) => 1 - math.pow(1 - t, 3).toDouble();

  @override
  bool shouldRepaint(_StatsPainter old) => old.t != t;
}

// ---------------------------------------------------------------------------
// Slide 3: Multiplayer / Play Together
// 4 player nodes orbit a central flag, connecting lines pulse
// ---------------------------------------------------------------------------
class _MultiplayerPainter extends CustomPainter {
  const _MultiplayerPainter({required this.t, required this.color});
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height / 2;

    // Central flag/hole icon
    final pulse = 0.88 + math.sin(t * 2 * math.pi) * 0.12;
    canvas.drawCircle(
      Offset(cx, cy),
      32 * pulse,
      Paint()
        ..color = color.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      20,
      Paint()..color = color.withValues(alpha: 0.85),
    );
    // Flag pole
    final flagPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy - 12), Offset(cx, cy + 12), flagPaint);
    // Flag pennant
    final path = Path()
      ..moveTo(cx, cy - 12)
      ..lineTo(cx + 10, cy - 7)
      ..lineTo(cx, cy - 2)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);

    // 4 player nodes — names + avatars
    const avatarNames = ['You', 'Alex', 'Sam', 'Chris'];
    const orbitRadius = 0.34; // fraction of width
    final r = size.width * orbitRadius;

    for (int i = 0; i < 4; i++) {
      final baseAngle = (i / 4) * 2 * math.pi;
      final angle     = baseAngle + t * 2 * math.pi * 0.25;
      final px = cx + math.cos(angle) * r;
      final py = cy + math.sin(angle) * r;

      // Connecting line — pulses in opacity
      final linePulse = (math.sin(t * 2 * math.pi + i) + 1) / 2;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(px, py),
        Paint()
          ..color = color.withValues(alpha: 0.12 + linePulse * 0.15)
          ..strokeWidth = 1.2,
      );

      // Score badge travelling along the line
      final progress = (t + i * 0.25) % 1.0;
      final badgeX   = cx + math.cos(angle) * r * progress;
      final badgeY   = cy + math.sin(angle) * r * progress;
      canvas.drawCircle(
        Offset(badgeX, badgeY),
        4,
        Paint()..color = color.withValues(alpha: 0.55),
      );

      // Avatar circle
      canvas.drawCircle(
        Offset(px, py),
        22,
        Paint()
          ..color = color.withValues(alpha: 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        Offset(px, py),
        16,
        Paint()..color = color.withValues(alpha: 0.80),
      );
      canvas.drawCircle(
        Offset(px, py),
        16,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Initials
      final initial = avatarNames[i][0];
      final tp = TextPainter(
        text: TextSpan(
          text: initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(px - tp.width / 2, py - tp.height / 2));

      // Name label
      final tp2 = TextPainter(
        text: TextSpan(
          text: avatarNames[i],
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.42),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp2.paint(canvas, Offset(px - tp2.width / 2, py + 20));
    }
  }

  @override
  bool shouldRepaint(_MultiplayerPainter old) => old.t != t;
}

// ---------------------------------------------------------------------------
// Slide 4: Friends & Leaderboard
// Animated leaderboard rows slide in + rank numbers count up
// ---------------------------------------------------------------------------
class _LeaderboardPainter extends CustomPainter {
  const _LeaderboardPainter({required this.t, required this.color});
  final double t;
  final Color color;

  static const _names  = ['Alex K.', 'You', 'Sam W.', 'Chris M.', 'Jordan'];
  static const _scores = [-3, -2, 1, 2, 4];
  static const _rounds = [12, 9, 14, 7, 11];

  @override
  void paint(Canvas canvas, Size size) {
    final cx     = size.width  / 2;
    final cy     = size.height / 2;
    final rowH   = size.height * 0.115;
    final rowW   = size.width  * 0.80;
    final startY = cy - ((_names.length - 1) / 2) * rowH;

    for (int i = 0; i < _names.length; i++) {
      final stagger = i * 0.12;
      final rowT    = ((t - stagger) / 0.55).clamp(0.0, 1.0);
      final eased   = _easeOutCubic(rowT);
      if (eased <= 0) continue;

      final ry  = startY + i * rowH;
      final rx  = cx - rowW / 2 + (1 - eased) * 40; // slide in from right
      final isMe = i == 1; // "You" highlighted

      // Row background
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(rx, ry - rowH * 0.40, rowW, rowH * 0.80),
        const Radius.circular(12),
      );

      if (isMe) {
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = color.withValues(alpha: 0.18 * eased)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        canvas.drawRRect(
          rrect,
          Paint()..color = color.withValues(alpha: 0.14 * eased),
        );
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = color.withValues(alpha: 0.35 * eased)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      } else {
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.04 * eased),
        );
      }

      // Rank number
      final rankColor = i == 0
          ? const Color(0xFFFFD700)
          : i == 1
              ? const Color(0xFFC0C0C0)
              : i == 2
                  ? const Color(0xFFCD7F32)
                  : Colors.white.withValues(alpha: 0.40);

      final rankTp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color: rankColor.withValues(alpha: eased),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      rankTp.paint(
          canvas, Offset(rx + 12, ry - rankTp.height / 2));

      // Avatar dot
      canvas.drawCircle(
        Offset(rx + 46, ry),
        12,
        Paint()
          ..color = (isMe ? color : Colors.white)
              .withValues(alpha: 0.22 * eased),
      );

      // Name
      final nameTp = TextPainter(
        text: TextSpan(
          text: _names[i],
          style: TextStyle(
            color: (isMe ? Colors.white : Colors.white.withValues(alpha: 0.65))
                .withValues(alpha: eased),
            fontSize: isMe ? 13 : 12,
            fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      nameTp.paint(
          canvas, Offset(rx + 66, ry - nameTp.height / 2));

      // Score (right side)
      final score    = _scores[i];
      final scoreStr = score == 0 ? 'E' : (score > 0 ? '+$score' : '$score');
      final scoreCol = score < 0
          ? color
          : score == 0
              ? Colors.white.withValues(alpha: 0.60)
              : const Color(0xFFFF7043);

      final scoreTp = TextPainter(
        text: TextSpan(
          text: scoreStr,
          style: TextStyle(
            color: scoreCol.withValues(alpha: eased),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      scoreTp.paint(
          canvas,
          Offset(rx + rowW - scoreTp.width - 12,
              ry - scoreTp.height / 2));
    }

    // Background glow
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.42,
      Paint()
        ..color = color.withValues(alpha: 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 52),
    );
  }

  double _easeOutCubic(double t) => 1 - math.pow(1 - t, 3).toDouble();

  @override
  bool shouldRepaint(_LeaderboardPainter old) => old.t != t;
}

// ---------------------------------------------------------------------------
// Slide 5: AI Caddie — orbiting nodes + pulsing core (original)
// ---------------------------------------------------------------------------
class _AiCaddiePainter extends CustomPainter {
  const _AiCaddiePainter({required this.t, required this.color});
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height / 2;

    final pulse = 0.85 + math.sin(t * 2 * math.pi) * 0.15;

    canvas.drawCircle(
      Offset(cx, cy),
      64 * pulse,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      28 * pulse,
      Paint()
        ..color = color.withValues(alpha: 0.48)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      19,
      Paint()..color = color.withValues(alpha: 0.90),
    );

    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      final a  = i * math.pi / 4;
      final dx = math.cos(a) * 10;
      final dy = math.sin(a) * 10;
      canvas.drawLine(
          Offset(cx - dx, cy - dy), Offset(cx + dx, cy + dy), linePaint);
    }

    final orbits = [
      (r: size.width * 0.28, speed: 1.0,  dot: 6.0, alpha: 0.80),
      (r: size.width * 0.37, speed: 0.62, dot: 5.0, alpha: 0.55),
      (r: size.width * 0.20, speed: 1.45, dot: 4.0, alpha: 0.65),
    ];

    for (final (i, o) in orbits.indexed) {
      final angle = t * 2 * math.pi * o.speed + (i * 2.1);
      final ox = cx + math.cos(angle) * o.r;
      final oy = cy + math.sin(angle) * o.r;

      canvas.drawLine(
        Offset(cx, cy),
        Offset(ox, oy),
        Paint()
          ..color = color.withValues(alpha: 0.12)
          ..strokeWidth = 1.0,
      );
      canvas.drawCircle(
        Offset(ox, oy),
        o.dot + 5,
        Paint()
          ..color = color.withValues(alpha: o.alpha * 0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        Offset(ox, oy),
        o.dot,
        Paint()..color = color.withValues(alpha: o.alpha),
      );
    }

    final rng = math.Random(42);
    for (int i = 0; i < 14; i++) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final dist  = size.width * (0.10 + rng.nextDouble() * 0.36);
      final phase = rng.nextDouble();
      final blink = (math.sin((t + phase) * 2 * math.pi) + 1) / 2;
      final sx = cx + math.cos(angle) * dist;
      final sy = cy + math.sin(angle) * dist;
      canvas.drawCircle(
        Offset(sx, sy),
        1.4 + blink * 1.6,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12 + blink * 0.28),
      );
    }
  }

  @override
  bool shouldRepaint(_AiCaddiePainter old) => old.t != t || old.color != color;
}
