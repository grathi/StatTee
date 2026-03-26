import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/swing_analysis.dart';
import '../services/swing_analysis_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ball_tracer_view.dart';

enum _AnalyzerState { idle, picking, recording, analyzing, result, error }

class SwingAnalyzerScreen extends StatefulWidget {
  const SwingAnalyzerScreen({super.key});

  @override
  State<SwingAnalyzerScreen> createState() => _SwingAnalyzerScreenState();
}

class _SwingAnalyzerScreenState extends State<SwingAnalyzerScreen> {
  _AnalyzerState _state = _AnalyzerState.idle;
  SwingAnalysis? _analysis;
  String? _errorMessage;
  String _statusMessage = 'Preparing video…';
  final ScreenshotController _screenshotController = ScreenshotController();

  // ── Video picking ─────────────────────────────────────────────────────────

  Future<void> _pickFromLibrary() async {
    setState(() => _state = _AnalyzerState.picking);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );
      if (picked == null) {
        setState(() => _state = _AnalyzerState.idle);
        return;
      }
      await _runAnalysis(File(picked.path));
    } catch (e) {
      _setError('Could not load video: $e');
    }
  }

  Future<void> _recordNewSwing() async {
    setState(() => _state = _AnalyzerState.recording);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _setError('No cameras available on this device.');
        return;
      }
      if (!mounted) return;
      final videoFile = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (_) => _CameraRecorderScreen(camera: cameras.first),
        ),
      );
      if (videoFile == null) {
        setState(() => _state = _AnalyzerState.idle);
        return;
      }
      await _runAnalysis(videoFile);
    } catch (e) {
      _setError('Camera error: $e');
    }
  }

  // ── Analysis ──────────────────────────────────────────────────────────────

  Future<void> _runAnalysis(File videoFile) async {
    setState(() {
      _state = _AnalyzerState.analyzing;
      _statusMessage = 'Preparing video…';
    });
    try {
      final analysis = await SwingAnalysisService.analyzeVideo(
        videoFile,
        onProgress: (p) {
          if (mounted) {
            setState(() => _statusMessage = p < 0.99
                ? 'Transcoding… ${(p * 100).round()}%'
                : 'Analyzing ball flight…');
          }
        },
      );
      final saved = await SwingAnalysisService.saveAnalysis(analysis);
      if (mounted) setState(() { _analysis = saved; _state = _AnalyzerState.result; });
    } catch (e) {
      _setError('Analysis failed: $e');
    }
  }

  void _setError(String msg) {
    if (mounted) setState(() { _errorMessage = msg; _state = _AnalyzerState.error; });
  }

  // ── Share screenshot ──────────────────────────────────────────────────────

  Future<void> _shareFrame() async {
    final bytes = await _screenshotController.capture();
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/swing_tracer.png');
    await file.writeAsBytes(bytes);
    if (mounted) {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out my swing trace from TeeStats! 🏌️',
      );
    }
  }

  Future<void> _saveVideo() async {
    final path = _analysis?.videoLocalPath;
    if (path == null || !File(path).existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No video file to save')),
        );
      }
      return;
    }
    try {
      await Gal.putVideo(path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video saved to gallery')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save video: $e')),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Swing Analyzer',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
        actions: [
          if (_state == _AnalyzerState.result) ...[
            IconButton(
              icon: const Icon(Icons.download_rounded),
              onPressed: _saveVideo,
              tooltip: 'Save to gallery',
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: _shareFrame,
              tooltip: 'Share',
            ),
          ],
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _buildBody(c),
      ),
    );
  }

  Widget _buildBody(AppColors c) {
    switch (_state) {
      case _AnalyzerState.idle:
        return _buildIdle(c);
      case _AnalyzerState.picking:
      case _AnalyzerState.recording:
        return _buildLoading(c, 'Loading video…');
      case _AnalyzerState.analyzing:
        return _buildAnalyzing(c);
      case _AnalyzerState.result:
        return _buildResult(c);
      case _AnalyzerState.error:
        return _buildError(c);
    }
  }

  // ── Idle: source picker ───────────────────────────────────────────────────

  Widget _buildIdle(AppColors c) {
    return Center(
      key: const ValueKey('idle'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF7BC344).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF7BC344).withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.sports_golf_rounded,
                  color: Color(0xFF7BC344), size: 38),
            ),
            const SizedBox(height: 24),
            const Text(
              'AI Swing Tracer',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Record or upload a golf swing video.\nGemini AI will track the ball and overlay a live tracer.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 40),
            _sourceButton(
              icon: Icons.videocam_rounded,
              label: 'Record New Swing',
              onTap: _recordNewSwing,
            ),
            const SizedBox(height: 14),
            _sourceButton(
              icon: Icons.photo_library_rounded,
              label: 'Choose from Library',
              onTap: _pickFromLibrary,
              primary: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool primary = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: primary ? const Color(0xFF5A9E1F) : Colors.white.withValues(alpha: 0.08),
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(28),
            side: primary
                ? BorderSide.none
                : BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Widget _buildLoading(AppColors c, String message) {
    return Center(
      key: const ValueKey('loading'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
              color: const Color(0xFF7BC344), strokeWidth: 2.5),
          const SizedBox(height: 20),
          Text(message,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 15)),
        ],
      ),
    );
  }

  // ── Analyzing ─────────────────────────────────────────────────────────────

  Widget _buildAnalyzing(AppColors c) {
    return Center(
      key: const ValueKey('analyzing'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                color: const Color(0xFF7BC344),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text('Analyzing ball flight…',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 14,
                  height: 1.5),
            ),
            const SizedBox(height: 40),
            // Animated hint dots
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _AnimatedDot(delay: i * 200)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Result ────────────────────────────────────────────────────────────────

  Widget _buildResult(AppColors c) {
    final analysis = _analysis!;
    final hasPath = analysis.ballPath.length >= 2;

    return SingleChildScrollView(
      key: const ValueKey('result'),
      child: Column(
        children: [
          // Video + tracer
          Screenshot(
            controller: _screenshotController,
            child: hasPath
                ? BallTracerView(analysis: analysis)
                : _NoTracePreview(analysis: analysis),
          ),

          // Stats panel
          Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shot Analysis',
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _statTile('Carry', '${analysis.shotData.carryYards.round()} yds',
                        Icons.straighten_rounded),
                    const SizedBox(width: 12),
                    _statTile('Height', '${analysis.shotData.maxHeightYards.round()} yds',
                        Icons.height_rounded),
                    const SizedBox(width: 12),
                    _statTile('Launch', '${analysis.shotData.launchAngle.round()}°',
                        Icons.trending_up_rounded),
                  ],
                ),
                if (!hasPath) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFFBBC05).withValues(alpha: 0.1),
                      shape: SuperellipseShape(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                            color: const Color(0xFFFBBC05).withValues(alpha: 0.3)),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: Color(0xFFFBBC05), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ball path not detected. Try better lighting or a closer angle.',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => setState(() {
                    _state = _AnalyzerState.idle;
                    _analysis = null;
                  }),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: const Color(0xFF5A9E1F),
                      shape: SuperellipseShape(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Analyze Another Swing',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: ShapeDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF7BC344), size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError(AppColors c) {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFFF6B6B), size: 30),
            ),
            const SizedBox(height: 20),
            const Text('Analysis Failed',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Something went wrong. Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  height: 1.5),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => setState(() => _state = _AnalyzerState.idle),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: ShapeDecoration(
                  color: const Color(0xFF5A9E1F),
                  shape: SuperellipseShape(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text('Try Again',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── In-app camera recorder ────────────────────────────────────────────────────

class _CameraRecorderScreen extends StatefulWidget {
  final CameraDescription camera;
  const _CameraRecorderScreen({required this.camera});

  @override
  State<_CameraRecorderScreen> createState() => _CameraRecorderScreenState();
}

class _CameraRecorderScreenState extends State<_CameraRecorderScreen> {
  late CameraController _cam;
  bool _initialized = false;
  bool _recording = false;

  @override
  void initState() {
    super.initState();
    _cam = CameraController(widget.camera, ResolutionPreset.high,
        enableAudio: true);
    _cam.initialize().then((_) {
      if (mounted) setState(() => _initialized = true);
    });
  }

  @override
  void dispose() {
    _cam.dispose();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    if (!_recording) {
      await _cam.startVideoRecording();
      setState(() => _recording = true);
    } else {
      final xfile = await _cam.stopVideoRecording();
      if (mounted) Navigator.pop(context, File(xfile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_initialized) CameraPreview(_cam) else const SizedBox(),
          // Record button
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _initialized ? _toggleRecord : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _recording
                        ? const Color(0xFFFF3B30)
                        : const Color(0xFF7BC344),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Icon(
                    _recording ? Icons.stop_rounded : Icons.fiber_manual_record,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ),
          ),
          // Cancel
          Positioned(
            top: 52,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context, null),
            ),
          ),
          if (_recording)
            Positioned(
              top: 56,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: ShapeDecoration(
                  color: const Color(0xFFFF3B30).withValues(alpha: 0.85),
                  shape: SuperellipseShape(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_manual_record,
                        color: Colors.white, size: 10),
                    SizedBox(width: 5),
                    Text('REC',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── No-trace fallback (video only) ───────────────────────────────────────────

class _NoTracePreview extends StatefulWidget {
  final SwingAnalysis analysis;
  const _NoTracePreview({required this.analysis});

  @override
  State<_NoTracePreview> createState() => _NoTracePreviewState();
}

class _NoTracePreviewState extends State<_NoTracePreview> {
  @override
  Widget build(BuildContext context) {
    // Just show a placeholder when ball path is empty
    return Container(
      color: Colors.black,
      height: 240,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility_off_rounded,
                color: Colors.white38, size: 36),
            const SizedBox(height: 12),
            Text('Ball not detected in video',
                style:
                    TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ── Animated loading dot ──────────────────────────────────────────────────────

class _AnimatedDot extends StatefulWidget {
  final int delay;
  const _AnimatedDot({required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward(from: 0);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, w) => Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.lerp(
            Colors.white.withValues(alpha: 0.15),
            const Color(0xFF7BC344),
            _anim.value,
          ),
        ),
      ),
    );
  }
}
