import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../services/onboarding_service.dart';
import '../theme/app_theme.dart';

// ── Anchor ────────────────────────────────────────────────────────────────────

enum TourAnchor { above, below }

// ── TourStep ──────────────────────────────────────────────────────────────────

class TourStep {
  final GlobalKey targetKey;
  final String title;
  final String body;
  final TourAnchor anchor;
  /// Called before computing the target rect. Use for scrolling into view.
  final Future<void> Function()? beforeShow;

  const TourStep({
    required this.targetKey,
    required this.title,
    required this.body,
    this.anchor = TourAnchor.below,
    this.beforeShow,
  });
}

// ── TourOverlay ───────────────────────────────────────────────────────────────

class TourOverlay extends StatefulWidget {
  final List<TourStep> steps;
  final VoidCallback onComplete;

  const TourOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
  });

  @override
  State<TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<TourOverlay>
    with TickerProviderStateMixin {
  int _stepIndex = 0;

  // Animate the spotlight hole between steps
  late AnimationController _holeCtrl;
  late Animation<double>    _holeFade;

  // Animate the tooltip card in/out
  late AnimationController _cardCtrl;
  late Animation<double>    _cardFade;
  late Animation<Offset>    _cardSlide;

  Rect? _currentRect;

  @override
  void initState() {
    super.initState();

    _holeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _holeFade = CurvedAnimation(parent: _holeCtrl, curve: Curves.easeInOut);

    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _cardFade  = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut));

    // Delay first frame so all widgets are laid out
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goToStep(0, animate: false);
    });
  }

  @override
  void dispose() {
    _holeCtrl.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  // ── Step navigation ────────────────────────────────────────────────────────

  /// Returns the screen Rect for the given step's target key, or null if unmounted.
  Rect? _rectForStep(int index) {
    if (index >= widget.steps.length) return null;
    final ctx = widget.steps[index].targetKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final pos  = box.localToGlobal(Offset.zero);
    final size = box.size;
    return Rect.fromLTWH(pos.dx, pos.dy, size.width, size.height);
  }

  Future<void> _goToStep(int index, {bool animate = true}) async {
    // Run beforeShow for the target step (if any) so it can scroll into view
    if (index < widget.steps.length) {
      await widget.steps[index].beforeShow?.call();
      // Wait a frame so the scroll settles before we measure the rect
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
    if (!mounted) return;

    // Find first valid step from index onward
    int i = index;
    Rect? rect;
    while (i < widget.steps.length) {
      rect = _rectForStep(i);
      if (rect != null) break;
      i++;
    }

    if (rect == null) {
      // All remaining steps have null keys — complete the tour
      await _finish();
      return;
    }

    if (animate) {
      await _cardCtrl.reverse();
      await _holeCtrl.reverse();
    }

    if (!mounted) return;
    setState(() {
      _stepIndex   = i;
      _currentRect = rect;
    });

    _holeCtrl.forward(from: animate ? 0 : 1);
    _cardCtrl.forward(from: 0);
  }

  void _advance() => _goToStep(_stepIndex + 1);

  Future<void> _finish() async {
    await OnboardingService.markTourSeen();
    if (mounted) widget.onComplete();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sw   = MediaQuery.of(context).size.width;
    final sh   = MediaQuery.of(context).size.height;
    final step = _stepIndex < widget.steps.length
        ? widget.steps[_stepIndex]
        : null;
    final rect = _currentRect;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // ── 1. Dark overlay with animated spotlight hole ─────────────────
          AnimatedBuilder(
            animation: _holeFade,
            builder: (context, child) => CustomPaint(
              size: Size(sw, sh),
              painter: _SpotlightPainter(
                rect:    rect,
                opacity: _holeFade.value,
              ),
            ),
          ),

          // ── 2. Tap anywhere on overlay → advance ─────────────────────────
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _advance,
            child: SizedBox(width: sw, height: sh),
          ),

          // ── 3. Tooltip card ───────────────────────────────────────────────
          if (step != null && rect != null)
            _PositionedCard(
              step:      step,
              rect:      rect,
              stepIndex: _stepIndex,
              total:     widget.steps.length,
              sw:        sw,
              sh:        sh,
              fadeAnim:  _cardFade,
              slideAnim: _cardSlide,
              onNext:    _advance,
              onSkip:    _finish,
            ),
        ],
      ),
    );
  }
}

// ── Spotlight painter ─────────────────────────────────────────────────────────

class _SpotlightPainter extends CustomPainter {
  final Rect?  rect;
  final double opacity;

  static const double _kPad    = 10.0;
  static const double _kRadius = 14.0;

  _SpotlightPainter({required this.rect, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.72 * opacity);

    if (rect == null) {
      canvas.drawRect(Offset.zero & size, overlayPaint);
      return;
    }

    final paddedRect = rect!.inflate(_kPad);
    final rRect = RRect.fromRectAndRadius(
        paddedRect, const Radius.circular(_kRadius));

    final fullScreen = Path()..addRect(Offset.zero & size);
    final hole       = Path()..addRRect(rRect);

    final cutout = Path.combine(PathOperation.difference, fullScreen, hole);
    canvas.drawPath(cutout, overlayPaint);

    // Subtle glow border around the spotlight
    final borderPaint = Paint()
      ..color = const Color(0xFF7BC344).withValues(alpha: 0.55 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(rRect, borderPaint);
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.rect != rect || old.opacity != opacity;
}

// ── Positioned tooltip card ───────────────────────────────────────────────────

class _PositionedCard extends StatelessWidget {
  final TourStep       step;
  final Rect           rect;
  final int            stepIndex;
  final int            total;
  final double         sw;
  final double         sh;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final VoidCallback   onNext;
  final AsyncCallback  onSkip;

  static const double _kCardWidth  = 300.0;
  static const double _kCardHPad   = 16.0;
  static const double _kNotchSize  = 10.0;

  const _PositionedCard({
    required this.step,
    required this.rect,
    required this.stepIndex,
    required this.total,
    required this.sw,
    required this.sh,
    required this.fadeAnim,
    required this.slideAnim,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final c      = AppColors.of(context);
    final isLast = stepIndex == total - 1;

    // Card width clamped to screen
    final cardW  = _kCardWidth.clamp(0.0, sw - _kCardHPad * 2);
    // Horizontal centre of spotlight rect, clamped so card stays on screen
    final centreX = rect.left + rect.width / 2;
    final cardLeft = (centreX - cardW / 2)
        .clamp(_kCardHPad, sw - cardW - _kCardHPad);

    // Vertical position
    const spotPad  = _SpotlightPainter._kPad;
    const notchH   = _kNotchSize;
    const cardVPad = 6.0;
    double? top;
    double? bottom;
    bool arrowUp; // true = notch points up (card is below spotlight)

    if (step.anchor == TourAnchor.below) {
      top     = rect.bottom + spotPad + notchH + cardVPad;
      arrowUp = true;
    } else {
      bottom  = sh - rect.top + spotPad + notchH + cardVPad;
      arrowUp = false;
    }

    // Notch horizontal offset relative to card
    final notchOffsetX = (centreX - cardLeft - _kNotchSize).clamp(
        16.0, cardW - 16.0 - _kNotchSize * 2);

    return Positioned(
      left:   cardLeft,
      top:    top,
      bottom: bottom,
      width:  cardW,
      child: FadeTransition(
        opacity: fadeAnim,
        child: SlideTransition(
          position: slideAnim,
          child: GestureDetector(
            // Prevent taps on the card from propagating to the overlay
            onTap: () {},
            child: _TourCard(
              c:            c,
              step:         step,
              stepIndex:    stepIndex,
              total:        total,
              isLast:       isLast,
              arrowUp:      arrowUp,
              notchOffsetX: notchOffsetX,
              notchSize:    _kNotchSize,
              onNext:       onNext,
              onSkip:       onSkip,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tour card ─────────────────────────────────────────────────────────────────

class _TourCard extends StatelessWidget {
  final AppColors      c;
  final TourStep       step;
  final int            stepIndex;
  final int            total;
  final bool           isLast;
  final bool           arrowUp;
  final double         notchOffsetX;
  final double         notchSize;
  final VoidCallback   onNext;
  final AsyncCallback  onSkip;

  const _TourCard({
    required this.c,
    required this.step,
    required this.stepIndex,
    required this.total,
    required this.isLast,
    required this.arrowUp,
    required this.notchOffsetX,
    required this.notchSize,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final body  = (sw * 0.034).clamp(12.5, 15.0);
    final label = (sw * 0.028).clamp(10.5, 12.5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Notch above card ──────────────────────────────────────────────
        if (arrowUp) _Notch(offset: notchOffsetX, size: notchSize, up: true, color: c.cardBorder),

        // ── Card body ─────────────────────────────────────────────────────
        Container(
          decoration: ShapeDecoration(
            color: c.sheetBg,
            shape: SuperellipseShape(
              borderRadius: BorderRadius.circular(36),
              side: BorderSide(color: c.cardBorder),
            ),
            shadows: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            (sw * 0.04).clamp(14.0, 18.0),
            (sw * 0.038).clamp(13.0, 16.0),
            (sw * 0.04).clamp(14.0, 18.0),
            (sw * 0.032).clamp(11.0, 14.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row: title + step counter
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      step.title,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: c.primaryText,
                        fontSize: body * 1.05,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF5A9E1F).withValues(alpha: 0.12),
                      shape: SuperellipseShape(
                        borderRadius: BorderRadius.circular(40),
                        side: BorderSide(color: const Color(0xFF5A9E1F).withValues(alpha: 0.28)),
                      ),
                    ),
                    child: Text(
                      '${stepIndex + 1} / $total',
                      style: TextStyle(
                        color: const Color(0xFF5A9E1F),
                        fontSize: label * 0.9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: (sw * 0.018).clamp(6.0, 8.0)),
              // Body text
              Text(
                step.body,
                style: TextStyle(
                  color: c.secondaryText,
                  fontSize: body * 0.88,
                  height: 1.5,
                ),
              ),
              SizedBox(height: (sw * 0.032).clamp(10.0, 14.0)),
              // Footer: Skip + Next/Done
              Row(
                children: [
                  GestureDetector(
                    onTap: onSkip,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: c.tertiaryText,
                        fontSize: label,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onNext,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: (sw * 0.04).clamp(14.0, 18.0),
                        vertical: (sw * 0.018).clamp(6.0, 8.0),
                      ),
                      decoration: ShapeDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7BC344), Color(0xFF5A9E1F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: SuperellipseShape(borderRadius: BorderRadius.circular(24)),
                        shadows: [
                          BoxShadow(
                            color: const Color(0xFF5A9E1F).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isLast ? 'Done' : 'Next',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color: Colors.white,
                              fontSize: label * 1.05,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isLast
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: label * 1.1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Notch below card ──────────────────────────────────────────────
        if (!arrowUp) _Notch(offset: notchOffsetX, size: notchSize, up: false, color: c.cardBorder),
      ],
    );
  }
}

// ── Triangle notch ────────────────────────────────────────────────────────────

class _Notch extends StatelessWidget {
  final double offset; // from left edge of card
  final double size;
  final bool   up;     // true = points upward (card is below the spotlight)
  final Color  color;

  const _Notch({
    required this.offset,
    required this.size,
    required this.up,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: offset),
      child: CustomPaint(
        size: Size(size * 2, size),
        painter: _NotchPainter(up: up, color: color),
      ),
    );
  }
}

class _NotchPainter extends CustomPainter {
  final bool  up;
  final Color color;
  _NotchPainter({required this.up, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = Colors.white;
    final border = Paint()
      ..color  = color
      ..style  = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    if (up) {
      // Triangle pointing up
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
      path.close();
    } else {
      // Triangle pointing down
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
      path.close();
    }
    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(_NotchPainter old) => old.up != up || old.color != color;
}
