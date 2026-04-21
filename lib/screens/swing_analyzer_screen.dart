import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import 'package:video_player/video_player.dart';
import '../models/swing_analysis.dart';
import '../services/swing_analysis_service.dart';
import '../theme/app_theme.dart';
import '../utils/l10n_extension.dart';
import '../widgets/ball_tracer_view.dart';

enum _AnalyzerState { idle, picking, recording, hinting, uploading, analyzing, result, error }

class SwingAnalyzerScreen extends StatefulWidget {
  const SwingAnalyzerScreen({super.key});

  @override
  State<SwingAnalyzerScreen> createState() => _SwingAnalyzerScreenState();
}

class _SwingAnalyzerScreenState extends State<SwingAnalyzerScreen> {
  _AnalyzerState _state = _AnalyzerState.idle;
  SwingAnalysis? _analysis;
  String? _errorMessage;
  String _statusMessage = 'Uploading video…';
  int _progressPct = 0;
  StreamSubscription<SwingJobStatus>? _jobSub;
  final ScreenshotController _screenshotController = ScreenshotController();
  final _shareKey = GlobalKey();

  // Ball hint state
  File? _pendingVideoFile;
  Offset? _ballHint;
  VideoPlayerController? _hintVideoController;

  @override
  void dispose() {
    _jobSub?.cancel();
    _hintVideoController?.dispose();
    super.dispose();
  }

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
      await _enterHinting(File(picked.path));
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
      await _enterHinting(videoFile);
    } catch (e) {
      _setError('Camera error: $e');
    }
  }

  // ── Hinting ────────────────────────────────────────────────────────────────

  Future<void> _enterHinting(File videoFile) async {
    _hintVideoController?.dispose();
    VideoPlayerController? ctrl;
    try {
      ctrl = VideoPlayerController.file(videoFile);
      await ctrl.initialize();
      await ctrl.seekTo(Duration.zero);
    } catch (_) {
      // Dolby Vision / HEVC files can't be previewed on some Android devices.
      // Proceed without video preview — user taps on a dark background.
      ctrl?.dispose();
      ctrl = null;
    }
    if (!mounted) return;
    setState(() {
      _pendingVideoFile = videoFile;
      _ballHint = null;
      _hintVideoController = ctrl;
      _state = _AnalyzerState.hinting;
    });
  }

  // ── Analysis ──────────────────────────────────────────────────────────────

  Future<void> _runAnalysis(File videoFile, {Offset? hint}) async {
    _hintVideoController?.dispose();
    _hintVideoController = null;
    setState(() {
      _state = _AnalyzerState.uploading;
      _statusMessage = 'Uploading video…';
      _progressPct = 0;
    });
    try {
      final stream = await SwingAnalysisService.analyzeVideo(
        videoFile,
        ballHint: hint,
        onProgress: (p) {
          if (mounted) {
            setState(() {
              _progressPct = (p * 100).round();
              _statusMessage = 'Uploading… $_progressPct%';
            });
          }
        },
      );

      setState(() {
        _state = _AnalyzerState.analyzing;
        _statusMessage = 'Queued…';
        _progressPct = 0;
      });

      _jobSub?.cancel();
      _jobSub = stream.listen(
        (status) async {
          if (!mounted) return;
          switch (status.state) {
            case SwingJobState.queued:
              setState(() => _statusMessage = 'Queued…');
            case SwingJobState.processing:
              setState(() {
                _progressPct = status.progress;
                _statusMessage = 'Analysing… ${status.progress}%';
              });
            case SwingJobState.completed:
              await _jobSub?.cancel();
              final uid = FirebaseAuth.instance.currentUser!.uid;
              final analysis = SwingAnalysis(
                userId: uid,
                createdAt: DateTime.now(),
                videoLocalPath: videoFile.path,
                outputVideoUrl: status.outputVideoUrl,
                ballPath: status.ballPath,
                shotData: status.shotData ??
                    const ShotData(carryYards: 0, maxHeightYards: 0, launchAngle: 0),
              );
              final saved = await SwingAnalysisService.saveAnalysis(analysis);
              if (mounted) setState(() { _analysis = saved; _state = _AnalyzerState.result; });
            case SwingJobState.failed:
              await _jobSub?.cancel();
              _setError(status.errorMessage ?? 'Processing failed on server.');
          }
        },
        onError: (Object e) => _setError('Stream error: $e'),
      );

      // Timeout after 10 minutes
      Future.delayed(const Duration(minutes: 10), () {
        if (mounted && _state == _AnalyzerState.analyzing) {
          _jobSub?.cancel();
          _setError('Processing timed out. Please try again.');
        }
      });
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
      final shareBox = _shareKey.currentContext?.findRenderObject() as RenderBox?;
      final shareOrigin = shareBox == null ? null : shareBox.localToGlobal(Offset.zero) & shareBox.size;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: context.l10n.swingAnalyzerShareText,
        sharePositionOrigin: shareOrigin,
      );
    }
  }

  Future<void> _saveVideo() async {
    final path = _analysis?.videoLocalPath;
    if (path == null || !File(path).existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.swingAnalyzerNoVideoFile)),
        );
      }
      return;
    }
    try {
      await Gal.putVideo(path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.swingAnalyzerVideoSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.swingAnalyzerCouldNotSave(e.toString()))),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        backgroundColor: c.scaffoldBg,
        foregroundColor: c.primaryText,
        title: Text(context.l10n.swingAnalyzerTitle,
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: c.primaryText)),
        actions: [
          if (_state == _AnalyzerState.result) ...[
            IconButton(
              icon: const Icon(Icons.download_rounded),
              onPressed: _saveVideo,
              tooltip: context.l10n.swingAnalyzerSaveToGallery,
            ),
            IconButton(
              key: _shareKey,
              icon: const Icon(Icons.share_rounded),
              onPressed: _shareFrame,
              tooltip: context.l10n.swingAnalyzerShare,
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
        return _buildLoading(c, context.l10n.swingAnalyzerLoadingVideo);
      case _AnalyzerState.hinting:
        return _buildHinting(c);
      case _AnalyzerState.uploading:
        return _buildAnalyzing(c, title: context.l10n.swingAnalyzerUploading);
      case _AnalyzerState.analyzing:
        return _buildAnalyzing(c, title: context.l10n.swingAnalyzerAnalyzing);
      case _AnalyzerState.result:
        return _buildResult(c);
      case _AnalyzerState.error:
        return _buildError(c);
    }
  }

  // ── Hinting: tap ball position ─────────────────────────────────────────────

  Widget _buildHinting(AppColors c) {
    final ctrl = _hintVideoController;
    final videoUnavailable = ctrl == null;
    final hasHint = _ballHint != null;

    // Video size: use controller's size when available, else 16:9 placeholder
    final videoSize = (!videoUnavailable && ctrl.value.isInitialized)
        ? ctrl.value.size
        : const Size(16, 9);

    return Column(
      key: const ValueKey('hinting'),
      children: [
        // Instruction bar
        Container(
          width: double.infinity,
          color: c.accentBg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.touch_app_rounded, color: c.accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  videoUnavailable
                      ? (hasHint ? 'Tap to reposition the ball' : context.l10n.swingAnalyzerPreviewUnavailable)
                      : (hasHint ? context.l10n.swingAnalyzerReposition : context.l10n.swingAnalyzerTapBall),
                  style: TextStyle(
                    color: c.primaryText,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Video frame (or dark placeholder) with tap overlay
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Fit video into available space preserving aspect ratio
              final vAspect = videoSize.width / videoSize.height;
              final cAspect = constraints.maxWidth / constraints.maxHeight;
              double renderW, renderH;
              if (vAspect > cAspect) {
                renderW = constraints.maxWidth;
                renderH = constraints.maxWidth / vAspect;
              } else {
                renderH = constraints.maxHeight;
                renderW = constraints.maxHeight * vAspect;
              }

              return GestureDetector(
                onTapUp: (details) {
                  // Map tap to video-frame coordinates, offset for centering
                  final dx = (constraints.maxWidth - renderW) / 2;
                  final dy = (constraints.maxHeight - renderH) / 2;
                  final localX = (details.localPosition.dx - dx) / renderW;
                  final localY = (details.localPosition.dy - dy) / renderH;
                  if (localX >= 0 && localX <= 1 && localY >= 0 && localY <= 1) {
                    setState(() => _ballHint = Offset(localX, localY));
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(color: c.scaffoldBg),
                    if (!videoUnavailable)
                      SizedBox(
                        width: renderW,
                        height: renderH,
                        child: VideoPlayer(ctrl),
                      )
                    else
                      // Placeholder with golf ball icon hint
                      SizedBox(
                        width: renderW,
                        height: renderH,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sports_golf_rounded,
                                  color: c.secondaryText,
                                  size: 48),
                              const SizedBox(height: 8),
                              Text(
                                'Tap where the ball is sitting',
                                style: TextStyle(
                                  color: c.secondaryText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Crosshair at tapped position
                    if (hasHint)
                      Positioned(
                        left: (constraints.maxWidth - renderW) / 2 +
                            _ballHint!.dx * renderW,
                        top: (constraints.maxHeight - renderH) / 2 +
                            _ballHint!.dy * renderH,
                        child: const _Crosshair(),
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        // Action buttons
        Container(
          color: c.cardBg,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Row(
            children: [
              // Skip button
              Expanded(
                child: GestureDetector(
                  onTap: () => _runAnalysis(_pendingVideoFile!),
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: c.accentBg,
                      shape: SuperellipseShape(
                        borderRadius: BorderRadius.circular(28),
                        side: BorderSide(color: c.accentBorder),
                      ),
                    ),
                    child: Text(context.l10n.swingAnalyzerSkip,
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: c.accent)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Analyze button (enabled only after tap)
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: hasHint
                      ? () => _runAnalysis(_pendingVideoFile!, hint: _ballHint)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 50,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: hasHint ? c.accent : c.accentBg,
                      shape: SuperellipseShape(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics_rounded,
                            size: 18,
                            color: hasHint ? Colors.white : c.secondaryText),
                        const SizedBox(width: 8),
                        Text(context.l10n.swingAnalyzerAnalyze,
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: hasHint ? Colors.white : c.secondaryText)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
                color: c.accentBg,
                shape: BoxShape.circle,
                border: Border.all(color: c.accentBorder),
              ),
              child: Icon(Icons.sports_golf_rounded,
                  color: c.accent, size: 38),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.swingAnalyzerAITracerTitle,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  color: c.primaryText,
                  fontSize: 24,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.swingAnalyzerAITracerDesc,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: c.secondaryText, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () => _showUpcomingDialog(c),
              child: Opacity(
                opacity: 0.5,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: c.accent,
                    shape: SuperellipseShape(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(context.l10n.swingAnalyzerButton,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpcomingDialog(AppColors c) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.accentBg,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.sports_golf_rounded, color: c.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Text(context.l10n.swingAnalyzerComingSoon,
                style: TextStyle(
                    color: c.primaryText,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
          ],
        ),
        content: Text(
          context.l10n.swingAnalyzerComingSoonMsg,
          style: TextStyle(color: c.secondaryText, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.swingAnalyzerGotIt,
                style: TextStyle(
                    color: c.accent,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _sourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool primary = true,
  }) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: primary ? c.accent : c.accentBg,
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(28),
            side: primary
                ? BorderSide.none
                : BorderSide(color: c.accentBorder),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: primary ? Colors.white : c.accent),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: primary ? Colors.white : c.accent)),
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
              color: c.accent, strokeWidth: 2.5),
          const SizedBox(height: 20),
          Text(message,
              style: TextStyle(
                  color: c.secondaryText, fontSize: 15)),
        ],
      ),
    );
  }

  // ── Analyzing / Uploading ──────────────────────────────────────────────────

  Widget _buildAnalyzing(AppColors c, {required String title}) {
    return Center(
      key: ValueKey('analyzing-$_state'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: _progressPct > 0
                  ? CircularProgressIndicator(
                      value: _progressPct / 100,
                      color: c.accent,
                      strokeWidth: 3,
                    )
                  : CircularProgressIndicator(
                      color: c.accent,
                      strokeWidth: 3,
                    ),
            ),
            const SizedBox(height: 24),
            Text(title,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    color: c.primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: c.secondaryText,
                  fontSize: 14,
                  height: 1.5),
            ),
            const SizedBox(height: 40),
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
            color: c.cardBg,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.swingAnalyzerShotAnalysis,
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        color: c.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _statTile(context.l10n.swingAnalyzerCarry, '${analysis.shotData.carryYards.round()} yds',
                        Icons.straighten_rounded),
                    const SizedBox(width: 12),
                    _statTile(context.l10n.swingAnalyzerHeight, '${analysis.shotData.maxHeightYards.round()} yds',
                        Icons.height_rounded),
                    const SizedBox(width: 12),
                    _statTile(context.l10n.swingAnalyzerLaunch, '${analysis.shotData.launchAngle.round()}°',
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
                            context.l10n.swingAnalyzerPathNotDetected,
                            style: TextStyle(
                                color: c.secondaryText,
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
                      color: c.accent,
                      shape: SuperellipseShape(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_rounded, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(context.l10n.swingAnalyzerAnotherSwing,
                            style: const TextStyle(
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
    final c = AppColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: ShapeDecoration(
          color: c.accentBg,
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: c.accentBorder),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c.accent, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    color: c.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: c.secondaryText,
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
            Text(context.l10n.swingAnalyzerFailed,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    color: c.primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? context.l10n.swingAnalyzerFailedMsg,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: c.secondaryText,
                  fontSize: 13,
                  height: 1.5),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => setState(() => _state = _AnalyzerState.idle),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: ShapeDecoration(
                  color: c.accent,
                  shape: SuperellipseShape(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(context.l10n.swingAnalyzerTryAgain,
                    style: const TextStyle(
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fiber_manual_record,
                        color: Colors.white, size: 10),
                    const SizedBox(width: 5),
                    Text(context.l10n.swingAnalyzerRecording,
                        style: const TextStyle(
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
    final c = AppColors.of(context);
    // Just show a placeholder when ball path is empty
    return Container(
      color: c.accentBg,
      height: 240,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_off_rounded,
                color: c.secondaryText, size: 36),
            const SizedBox(height: 12),
            Text(context.l10n.swingAnalyzerBallNotDetected,
                style: TextStyle(color: c.secondaryText, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ── Crosshair overlay for ball hint ──────────────────────────────────────────

class _Crosshair extends StatelessWidget {
  const _Crosshair();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(-16, -16),
      child: CustomPaint(
        size: const Size(32, 32),
        painter: _CrosshairPainter(),
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4ADE80)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    const r = 7.0;
    const arm = 6.0;

    // Circle
    canvas.drawCircle(Offset(cx, cy), r, paint);
    // Arms
    canvas.drawLine(Offset(cx - r - arm, cy), Offset(cx - r, cy), paint);
    canvas.drawLine(Offset(cx + r, cy), Offset(cx + r + arm, cy), paint);
    canvas.drawLine(Offset(cx, cy - r - arm), Offset(cx, cy - r), paint);
    canvas.drawLine(Offset(cx, cy + r), Offset(cx, cy + r + arm), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
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
    final c = AppColors.of(context);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, w) => Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.lerp(
            c.accentBg,
            c.accent,
            _anim.value,
          ),
        ),
      ),
    );
  }
}
