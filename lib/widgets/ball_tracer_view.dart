import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/swing_analysis.dart';
import '../theme/app_theme.dart';

// ── Public entry point ────────────────────────────────────────────────────────

class BallTracerView extends StatefulWidget {
  final SwingAnalysis analysis;

  const BallTracerView({super.key, required this.analysis});

  @override
  State<BallTracerView> createState() => _BallTracerViewState();
}

class _BallTracerViewState extends State<BallTracerView> {
  late VideoPlayerController _controller;
  int _posMs = 0;
  bool _initialized = false;
  String? _videoError;

  // Manual point selection (used when AI returns no ball path)
  final List<Offset> _manualPoints = []; // normalized 0–1

  // ignore: unused_element
  bool get _hasAiTrace => widget.analysis.ballPath.isNotEmpty;

  static const _pointLabels = ['Start', 'Mid', 'End'];

  @override
  void initState() {
    super.initState();
    final path = widget.analysis.videoLocalPath;
    if (path != null && File(path).existsSync()) {
      _controller = VideoPlayerController.file(File(path));
      _controller.initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
        _controller.addListener(_onVideoTick);
      }).catchError((Object e) {
        if (mounted) {
          setState(() => _videoError = e is PlatformException
              ? 'Unsupported video format'
              : 'Failed to load video');
        }
      });
    } else {
      _videoError = 'Video file not found';
    }
  }

  void _onVideoTick() {
    if (!mounted) return;
    final newMs = _controller.value.position.inMilliseconds;
    if (newMs != _posMs) setState(() => _posMs = newMs);
  }

  @override
  void dispose() {
    if (_initialized) {
      _controller.removeListener(_onVideoTick);
      _controller.dispose();
    }
    super.dispose();
  }

  void _togglePlay() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      if (_controller.value.position >= _controller.value.duration) {
        _controller.seekTo(Duration.zero);
      }
      _controller.play();
    }
    setState(() {});
  }

  void _onTapUp(TapUpDetails details, Size widgetSize) {
    // Ball tracking disabled — tap always plays/pauses
    _togglePlay();

    // ── Re-enable manual point selection when ball tracking is ready ──────────
    // if (_hasAiTrace) {
    //   _togglePlay();
    //   return;
    // }
    // if (_manualPoints.length >= 3) {
    //   setState(() => _manualPoints.clear());
    //   return;
    // }
    // final norm = Offset(
    //   (details.localPosition.dx / widgetSize.width).clamp(0.0, 1.0),
    //   (details.localPosition.dy / widgetSize.height).clamp(0.0, 1.0),
    // );
    // setState(() => _manualPoints.add(norm));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (_videoError != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0C1A0A), Color(0xFF111A10)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_golf_rounded,
                    color: const Color(0xFF4A7A2A).withValues(alpha: 0.5),
                    size: 48),
                const SizedBox(height: 10),
                Text(
                  'Video preview unavailable',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: c.accent, strokeWidth: 2),
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        onTapUp: (d) => _onTapUp(d, size),
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Layer 1 — Video
              VideoPlayer(_controller),

              // Layer 2 — AI neon tracer (re-enable when ball tracking is ready)
              // if (_hasAiTrace)
              //   CustomPaint(
              //     painter: BallTracerPainter(
              //       points: widget.analysis.ballPath,
              //       currentPositionMs: _posMs,
              //     ),
              //   ),

              // Layer 2b — Manual Bezier tracer (re-enable when ball tracking is ready)
              // if (!_hasAiTrace && _manualPoints.isNotEmpty)
              //   CustomPaint(
              //     painter: ManualTracerPainter(points: _manualPoints),
              //   ),

              // Layer 3 — Play/pause hint
              if (!_controller.value.isPlaying)
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 32),
                  ),
                ),

              // Layer 4 — Manual mode UI (re-enable when ball tracking is ready)
              // if (!_hasAiTrace) ...[
              //   _buildManualInstructions(),
              //   Positioned(
              //     bottom: 12,
              //     left: 12,
              //     child: GestureDetector(
              //       onTap: _togglePlay,
              //       child: Container(
              //         width: 40,
              //         height: 40,
              //         decoration: BoxDecoration(
              //           color: Colors.black.withValues(alpha: 0.55),
              //           shape: BoxShape.circle,
              //           border: Border.all(
              //             color: Colors.white.withValues(alpha: 0.3),
              //           ),
              //         ),
              //         child: Icon(
              //           _controller.value.isPlaying
              //               ? Icons.pause_rounded
              //               : Icons.play_arrow_rounded,
              //           color: Colors.white,
              //           size: 22,
              //         ),
              //       ),
              //     ),
              //   ),
              //   if (_manualPoints.isNotEmpty)
              //     Positioned(
              //       bottom: 12,
              //       left: 60,
              //       child: GestureDetector(
              //         onTap: () => setState(() => _manualPoints.clear()),
              //         child: Container(
              //           padding: const EdgeInsets.symmetric(
              //               horizontal: 10, vertical: 6),
              //           decoration: BoxDecoration(
              //             color: Colors.black.withValues(alpha: 0.55),
              //             borderRadius: BorderRadius.circular(20),
              //             border: Border.all(
              //               color: Colors.white.withValues(alpha: 0.2),
              //             ),
              //           ),
              //           child: const Text('Reset',
              //               style: TextStyle(
              //                   color: Colors.white70, fontSize: 12)),
              //         ),
              //       ),
              //     ),
              // ],

              // Layer 5 — Shot stats card (bottom-right)
              Positioned(
                bottom: 12,
                right: 12,
                child: ShotStatsCard(
                  shotData: widget.analysis.shotData,
                  c: c,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ignore: unused_element
  Widget _buildManualInstructions() {
    if (_manualPoints.length >= 3) return const SizedBox.shrink();

    final nextLabel = _pointLabels[_manualPoints.length];
    final stepDots = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final done = i < _manualPoints.length;
        final active = i == _manualPoints.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 8 : 6,
          height: active ? 8 : 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? const Color(0xFFCCFF44)
                : active
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
          ),
        );
      }),
    );

    return Positioned(
      top: 12,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tap $nextLabel position',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              stepDots,
            ],
          ),
        ),
      ),
    );
  }
}

// ── AI Trace Painter ──────────────────────────────────────────────────────────

class BallTracerPainter extends CustomPainter {
  final List<BallPoint> points;
  final int currentPositionMs;

  const BallTracerPainter({
    required this.points,
    required this.currentPositionMs,
  });

  Offset _toPixel(BallPoint p, Size size) =>
      Offset(p.x * size.width, p.y * size.height);

  @override
  void paint(Canvas canvas, Size size) {
    final visible = points.where((p) => p.t <= currentPositionMs).toList();
    if (visible.length < 2) return;

    final pixelPts = visible.map((p) => _toPixel(p, size)).toList();
    final path = _buildCatmullRomPath(pixelPts);

    _drawNeonPath(canvas, path);

    final tip = pixelPts.last;
    canvas.drawCircle(tip, 5,
        Paint()
          ..color = Colors.white
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawCircle(tip, 3.5, Paint()..color = const Color(0xFFCCFF44));
  }

  Path _buildCatmullRomPath(List<Offset> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts[0].dx, pts[0].dy);
    if (pts.length == 2) {
      path.lineTo(pts[1].dx, pts[1].dy);
      return path;
    }
    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = pts[(i - 1).clamp(0, pts.length - 1)];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = pts[(i + 2).clamp(0, pts.length - 1)];
      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6.0,
        p1.dy + (p2.dy - p0.dy) / 6.0,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6.0,
        p2.dy - (p3.dy - p1.dy) / 6.0,
      );
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(BallTracerPainter old) =>
      old.currentPositionMs != currentPositionMs || old.points != points;
}

// ── Manual Tracer Painter ─────────────────────────────────────────────────────

class ManualTracerPainter extends CustomPainter {
  final List<Offset> points; // normalized 0–1, up to 3

  const ManualTracerPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final px = points
        .map((p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList();

    // Draw smooth curve through all placed points
    if (px.length >= 2) {
      final path = _buildPath(px);
      _drawNeonPath(canvas, path);
    }

    // Draw labeled dot for each point
    for (int i = 0; i < px.length; i++) {
      _drawPointMarker(canvas, px[i], i);
    }
  }

  /// Builds a smooth curve that passes THROUGH all user-placed points.
  /// - 2 points: straight line
  /// - 3 points: quadratic Bézier whose control point is derived so the
  ///             curve passes exactly through the mid tap position.
  Path _buildPath(List<Offset> px) {
    final path = Path()..moveTo(px[0].dx, px[0].dy);

    if (px.length == 2) {
      path.lineTo(px[1].dx, px[1].dy);
    } else {
      // For quadratic Bézier to pass through p1 (mid):
      // cp = 2*p1 - 0.5*(p0 + p2)
      final p0 = px[0], p1 = px[1], p2 = px[2];
      final cp = Offset(
        2 * p1.dx - 0.5 * (p0.dx + p2.dx),
        2 * p1.dy - 0.5 * (p0.dy + p2.dy),
      );
      path.quadraticBezierTo(cp.dx, cp.dy, p2.dx, p2.dy);
    }
    return path;
  }

  void _drawPointMarker(Canvas canvas, Offset center, int index) {
    // Outer glow ring
    canvas.drawCircle(
      center,
      14,
      Paint()
        ..color = const Color(0xFFCCFF44).withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // White border circle
    canvas.drawCircle(
      center,
      10,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill,
    );
    // Neon fill
    canvas.drawCircle(
      center,
      8,
      Paint()..color = const Color(0xFF7BC344),
    );

    // Index number label
    final tp = TextPainter(
      text: TextSpan(
        text: '${index + 1}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      center - Offset(tp.width / 2, tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(ManualTracerPainter old) => old.points != points;
}

// ── Shared neon path drawing ──────────────────────────────────────────────────

void _drawNeonPath(Canvas canvas, Path path) {
  // Layer 1: Outer glow halo
  canvas.drawPath(
    path,
    Paint()
      ..color = const Color(0xFF7BC344).withValues(alpha: 0.22)
      ..strokeWidth = 14
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round,
  );
  // Layer 2: Inner glow
  canvas.drawPath(
    path,
    Paint()
      ..color = const Color(0xFF8FD44E).withValues(alpha: 0.55)
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round,
  );
  // Layer 3: Crisp neon core
  canvas.drawPath(
    path,
    Paint()
      ..color = const Color(0xFFCCFF44)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round,
  );
}

// ── Shot Stats Card ───────────────────────────────────────────────────────────

class ShotStatsCard extends StatelessWidget {
  final ShotData shotData;
  final AppColors c;

  const ShotStatsCard({super.key, required this.shotData, required this.c});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF7BC344).withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statRow('Carry', '${shotData.carryYards.round()} yds'),
              const SizedBox(height: 4),
              _statRow('Height', '${shotData.maxHeightYards.round()} yds'),
              const SizedBox(height: 4),
              _statRow('Launch', '${shotData.launchAngle.round()}°'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label  ',
          style: const TextStyle(
            color: Color(0xFF8FD44E),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
