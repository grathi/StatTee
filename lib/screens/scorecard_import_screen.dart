import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/group_round.dart';
import '../models/hole_score.dart';
import '../models/round.dart';
import '../models/scorecard_import_data.dart';
import '../services/group_round_service.dart';
import '../services/places_service.dart';
import '../services/round_service.dart';
import '../services/scorecard_ocr_service.dart';
import '../theme/app_theme.dart';
import 'group_round_results_screen.dart';
import 'round_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point helper — shows source picker then runs OCR before pushing screen
// ─────────────────────────────────────────────────────────────────────────────

/// Shows a bottom sheet to pick gallery or camera, runs OCR, then pushes
/// [ScorecardImportScreen] on success.  Call from any screen.
Future<void> showScorecardImportFlow(
  BuildContext context, {
  String? sessionId,
  GroupRound? session,
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SourcePickerSheet(c: AppColors.of(ctx)),
  );
  if (source == null || !context.mounted) return;

  // Wait for the bottom sheet to fully dismiss before presenting the
  // system photo picker — iOS blocks two simultaneous VC presentations.
  await Future.delayed(const Duration(milliseconds: 400));
  if (!context.mounted) return;

  // Pick the image FIRST
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: source,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 88,
  );
  if (picked == null || !context.mounted) return;

  // NOW show the loading overlay while Gemini processes
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _OcrLoadingDialog(),
  );

  try {
    final data = await ScorecardOcrService.analyzeImage(File(picked.path));

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // close loading

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScorecardImportScreen(
          data: data,
          sessionId: sessionId,
          session: session,
        ),
      ),
    );
  } on ScorecardNotDetectedException catch (e) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    _showErrorDialog(context, e.reason, canEditManually: false);
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    final msg = e.toString();
    _showErrorDialog(
      context,
      msg.contains('timed out') || msg.contains('SocketException')
          ? "Couldn't reach the AI service. Check your connection and try again."
          : msg, // show actual error for debugging
      canEditManually: false,
    );
  }
}

void _showErrorDialog(BuildContext context, String message,
    {required bool canEditManually}) {
  final c = AppColors.of(context);
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: c.sheetBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: c.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFFF6B6B), size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Read Scorecard',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: c.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: c.secondaryText, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                showScorecardImportFlow(context);
              },
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: ShapeDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7BC344), Color(0xFF5A9E1F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: SuperellipseShape(
                      borderRadius: BorderRadius.circular(28)),
                  shadows: [
                    BoxShadow(
                      color: const Color(0xFF5A9E1F).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                height: 46,
                decoration: ShapeDecoration(
                  color: c.cardBg,
                  shape: SuperellipseShape(
                    borderRadius: BorderRadius.circular(28),
                    side: BorderSide(color: c.cardBorder),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: c.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Source picker sheet
// ─────────────────────────────────────────────────────────────────────────────

class _SourcePickerSheet extends StatelessWidget {
  final AppColors c;
  const _SourcePickerSheet({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: c.sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: c.cardBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
                color: c.divider, borderRadius: BorderRadius.circular(2)),
          ),
          Text(
            'Import Scorecard',
            style: TextStyle(
              fontFamily: 'Nunito',
              color: c.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'How would you like to add your scorecard?',
            style: TextStyle(color: c.tertiaryText, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _SourceTile(
            icon: Icons.camera_alt_rounded,
            label: 'Take a Photo',
            sub: 'Photograph your paper scorecard',
            c: c,
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          const SizedBox(height: 10),
          _SourceTile(
            icon: Icons.photo_library_rounded,
            label: 'Choose from Library',
            sub: 'Select an existing photo',
            c: c,
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final AppColors c;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.c,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: ShapeDecoration(
          color: c.cardBg,
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(40),
            side: BorderSide(color: c.cardBorder),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: ShapeDecoration(
                color: c.accent.withValues(alpha: 0.12),
                shape: SuperellipseShape(
                    borderRadius: BorderRadius.circular(24)),
              ),
              child: Icon(icon, color: c.accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          color: c.primaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  Text(sub,
                      style:
                          TextStyle(color: c.tertiaryText, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: c.tertiaryText, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OCR loading dialog
// ─────────────────────────────────────────────────────────────────────────────

class _OcrLoadingDialog extends StatelessWidget {
  const _OcrLoadingDialog();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: c.sheetBg,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                  color: c.accent, strokeWidth: 2.5),
              const SizedBox(height: 20),
              Text(
                'Reading your scorecard…',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: c.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Analysing with AI — this takes a few seconds',
                style: TextStyle(color: c.tertiaryText, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main review/edit screen
// ─────────────────────────────────────────────────────────────────────────────

class ScorecardImportScreen extends StatefulWidget {
  final ScorecardImportData data;
  final String? sessionId;
  final GroupRound? session;
  const ScorecardImportScreen({
    super.key,
    required this.data,
    this.sessionId,
    this.session,
  });

  @override
  State<ScorecardImportScreen> createState() =>
      _ScorecardImportScreenState();
}

class _ScorecardImportScreenState extends State<ScorecardImportScreen> {
  late final TextEditingController _courseNameCtrl;
  late final TextEditingController _ratingCtrl;
  late final TextEditingController _slopeCtrl;
  late List<ImportedHole> _holes;
  late DateTime _roundDate;
  late int _totalHoles;
  bool _saving = false;

  // ── Location autocomplete (mirrors StartRoundScreen) ──────────────────────
  final _courseNameFocus   = FocusNode();
  final _overlayController = OverlayPortalController();
  final _layerLink         = LayerLink();
  String? _selectedPlaceId;
  String  _locationText    = '';
  List<GolfCourseSuggestion> _suggestions     = [];
  bool                       _loadingSuggestions = false;
  Timer?                     _debounce;

  // ── Warning accordion ─────────────────────────────────────────────────────
  bool _warningExpanded = true;

  static Color _scoreColor(int diff) {
    if (diff <= -2) return const Color(0xFFFFD700);
    if (diff == -1) return const Color(0xFF4CAF82);
    if (diff == 0) return const Color(0xFF64B5F6);
    if (diff == 1) return const Color(0xFFFFB74D);
    return const Color(0xFFE53935);
  }

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    final sess = widget.session;
    _courseNameCtrl = TextEditingController(
        text: d.courseName.isNotEmpty ? d.courseName : (sess?.courseName ?? ''));
    _ratingCtrl = TextEditingController(
        text: d.courseRating?.toString() ?? sess?.courseRating?.toString() ?? '');
    _slopeCtrl = TextEditingController(
        text: d.slopeRating?.toString() ?? sess?.slopeRating?.toString() ?? '');
    _holes = List.from(d.holes);
    _roundDate = d.roundDate;
    _totalHoles = d.totalHoles;
    _locationText = d.courseLocation.isNotEmpty ? d.courseLocation : (sess?.courseLocation ?? '');
    _courseNameCtrl.addListener(_onCourseNameChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _courseNameCtrl.removeListener(_onCourseNameChanged);
    _courseNameCtrl.dispose();
    _ratingCtrl.dispose();
    _slopeCtrl.dispose();
    _courseNameFocus.dispose();
    super.dispose();
  }

  // ── Autocomplete logic ────────────────────────────────────────────────────

  void _onCourseNameChanged() {
    if (_selectedPlaceId != null) return;
    _debounce?.cancel();
    final text = _courseNameCtrl.text.trim();
    if (text.length < 2) {
      setState(() => _suggestions = []);
      if (_overlayController.isShowing) _overlayController.hide();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _loadingSuggestions = true);
      if (!_overlayController.isShowing) _overlayController.show();
      final results = await PlacesService.autocomplete(
        input: text,
        location: null,
        lat: null,
        lng: null,
        locationName: null,
      );
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _loadingSuggestions = false;
      });
    });
  }

  Future<void> _selectSuggestion(GolfCourseSuggestion s) async {
    if (_overlayController.isShowing) _overlayController.hide();
    _selectedPlaceId = s.placeId;
    _courseNameCtrl.text = s.name;
    setState(() {
      _suggestions = [];
      _locationText = s.address;
    });
    FocusScope.of(context).unfocus();
  }

  bool get _hasUnreadable => _holes.any((h) => h.score == 0);
  int get _totalPar => _holes.fold(0, (s, h) => s + h.par);
  int get _totalScore => _holes.fold(0, (s, h) => s + h.score);

  String get _warningText {
    final parts = <String>[];
    if (widget.data.warningMessage != null) {
      parts.add(widget.data.warningMessage!);
    }
    if (_hasUnreadable) {
      parts.add(
          'Holes in red have unreadable scores — tap the score stepper to fix them.');
    }
    return parts.join('\n');
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _roundDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _roundDate = picked);
  }

  Future<void> _confirmImport() async {
    if (_courseNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a course name.')),
      );
      return;
    }
    if (_hasUnreadable) {
      final ok = await showDialog<bool>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        builder: (ctx) {
          final c = AppColors.of(ctx);
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: c.sheetBg,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: c.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB74D).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFFFB74D).withValues(alpha: 0.25)),
                    ),
                    child: const Icon(Icons.edit_note_rounded,
                        color: Color(0xFFFFB74D), size: 26),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Some Scores Missing',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: c.primaryText,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A few holes still show 0. They\'ll be saved as 0 strokes — you can edit them after import.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: c.secondaryText,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Primary — Import Anyway (gradient)
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, true),
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: ShapeDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7BC344), Color(0xFF5A9E1F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: SuperellipseShape(
                            borderRadius: BorderRadius.circular(28)),
                        shadows: [
                          BoxShadow(
                            color: const Color(0xFF5A9E1F).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Import Anyway',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Secondary — Fix First (outlined)
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, false),
                    child: Container(
                      width: double.infinity,
                      height: 46,
                      decoration: ShapeDecoration(
                        color: c.cardBg,
                        shape: SuperellipseShape(
                          borderRadius: BorderRadius.circular(28),
                          side: BorderSide(color: c.cardBorder),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Fix First',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: c.primaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      if (ok != true || !mounted) return;
    }

    setState(() => _saving = true);
    try {
      final courseName = _courseNameCtrl.text.trim();
      final location = _locationText.trim();
      final rating = double.tryParse(_ratingCtrl.text);
      final slope = int.tryParse(_slopeCtrl.text);

      final holeScores = _holes
          .map((h) => HoleScore(
                hole: h.hole,
                par: h.par,
                score: h.score,
                putts: 0,
                fairwayHit: false,
                gir: false,
              ))
          .toList();

      // ── Group round path ────────────────────────────────────────────────
      if (widget.sessionId != null && widget.session != null) {
        final sess = widget.session!;
        final roundId = await RoundService.startRound(
          courseName:     courseName.isEmpty ? sess.courseName : courseName,
          courseLocation: location.isEmpty ? sess.courseLocation : location,
          totalHoles:     _totalHoles,
          courseRating:   rating ?? sess.courseRating,
          slopeRating:    slope ?? sess.slopeRating,
        );
        await GroupRoundService.joinSession(widget.sessionId!, roundId);
        await RoundService.saveAllHoleScores(roundId, holeScores);
        await RoundService.completeRound(roundId);
        final totalScore = _holes.fold(0, (s, h) => s + h.score);
        final effectiveRating = rating ?? sess.courseRating;
        final scoreDiff = effectiveRating != null
            ? (totalScore - effectiveRating).toDouble()
            : 0.0;
        await GroupRoundService.reportCompletion(
          widget.sessionId!,
          roundId:    roundId,
          totalScore: totalScore,
          scoreDiff:  scoreDiff,
        );
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => GroupRoundResultsScreen(
              sessionId:  widget.sessionId!,
              myRoundId:  roundId,
              courseName: courseName.isEmpty ? sess.courseName : courseName,
            ),
          ),
          (route) => route.isFirst,
        );
        return;
      }

      // ── Normal import path ───────────────────────────────────────────────
      final roundId = await RoundService.startRound(
        courseName: courseName.isEmpty ? 'Imported Round' : courseName,
        courseLocation: location,
        totalHoles: _totalHoles,
        courseRating: rating,
        slopeRating: slope,
      );

      await RoundService.saveAllHoleScores(roundId, holeScores);

      // Backdate round to the user-selected date
      await FirebaseFirestore.instance
          .collection('rounds')
          .doc(roundId)
          .update({'startedAt': Timestamp.fromDate(_roundDate)});

      await RoundService.completeRound(roundId);

      if (!mounted) return;

      // Fetch the saved round and navigate to detail
      final snap = await FirebaseFirestore.instance
          .collection('rounds')
          .doc(roundId)
          .get();
      final round = Round.fromFirestore(snap);

      if (!mounted) return;
      Navigator.pop(context); // pop import screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RoundDetailScreen(round: round)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final sw = MediaQuery.of(context).size.width;
    final warning = _warningText;

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        backgroundColor: c.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.close_rounded, color: c.primaryText, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Review Scorecard',
          style: TextStyle(
            fontFamily: 'Nunito',
            color: c.primaryText,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_saving)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: c.accent, strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _confirmImport,
              child: Text(
                'Import',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: c.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding:
            EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: 12),
        children: [
          _buildCourseInfo(c, sw),
          if (warning.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildWarningBanner(c, warning),
          ],
          const SizedBox(height: 16),
          _buildHoleTable(c),
          const SizedBox(height: 20),
          _buildTotalsRow(c),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Course Info ────────────────────────────────────────────────────────────

  Widget _buildCourseInfo(AppColors c, double sw) {
    final fieldDecoration = InputDecoration(
      filled: true,
      fillColor: c.fieldBg,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.accent, width: 1.5),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(c, 'Course'),
        const SizedBox(height: 8),

        // ── Course name with autocomplete ────────────────────────────────
        OverlayPortal(
          controller: _overlayController,
          overlayChildBuilder: (_) => _buildSuggestionsOverlay(c, sw),
          child: CompositedTransformTarget(
            link: _layerLink,
            child: TextField(
              controller: _courseNameCtrl,
              focusNode: _courseNameFocus,
              style: TextStyle(
                  color: c.fieldText,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600),
              onTap: () {
                if (_selectedPlaceId != null) {
                  setState(() {
                    _selectedPlaceId = null;
                    _locationText = '';
                  });
                }
              },
              decoration: fieldDecoration.copyWith(
                hintText: 'Course name',
                prefixIcon: Icon(Icons.golf_course_rounded,
                    color: c.fieldIcon, size: 18),
                suffixIcon: _loadingSuggestions
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: c.accent),
                        ),
                      )
                    : (_courseNameCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: c.tertiaryText, size: 18),
                            onPressed: () {
                              _courseNameCtrl.clear();
                              _selectedPlaceId = null;
                              _overlayController.hide();
                              setState(() {
                                _suggestions = [];
                                _locationText = '';
                              });
                            },
                          )
                        : null),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── Location chip (read-only, populated by autocomplete) ──────────
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.fieldBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.fieldBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on_rounded,
                  color: _locationText.isNotEmpty
                      ? c.accent
                      : c.tertiaryText,
                  size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _locationText.isNotEmpty
                      ? _locationText
                      : 'Location — search a course above',
                  style: TextStyle(
                    color: _locationText.isNotEmpty
                        ? c.fieldText
                        : c.tertiaryText,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ratingCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: c.fieldText),
                decoration:
                    fieldDecoration.copyWith(hintText: 'Rating'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _slopeCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: c.fieldText),
                decoration:
                    fieldDecoration.copyWith(hintText: 'Slope'),
              ),
            ),
            const SizedBox(width: 10),
            // Date chip
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: c.fieldBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.fieldBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 14, color: c.accent),
                    const SizedBox(width: 6),
                    Text(
                      '${_roundDate.day}/${_roundDate.month}/${_roundDate.year}',
                      style: TextStyle(
                          color: c.primaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // 9H / 18H toggle
            Container(
              decoration: BoxDecoration(
                color: c.fieldBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.fieldBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [9, 18].map((n) {
                  final sel = _totalHoles == n;
                  return GestureDetector(
                    onTap: () => setState(() => _totalHoles = n),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: sel
                            ? c.accent.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        '${n}H',
                        style: TextStyle(
                          color: sel ? c.accent : c.tertiaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Suggestions overlay (same pattern as StartRoundScreen) ─────────────────

  Widget _buildSuggestionsOverlay(AppColors c, double sw) {
    final hPad = sw * 0.04;
    return Positioned(
      width: sw - (hPad * 2),
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 52),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: ShapeDecoration(
              color: c.sheetBg,
              shape: SuperellipseShape(
                borderRadius: BorderRadius.circular(32),
                side: BorderSide(color: c.cardBorder),
              ),
              shadows: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _loadingSuggestions && _suggestions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: c.accent),
                    ),
                  )
                : _suggestions.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No golf courses found',
                          style: TextStyle(
                              color: c.secondaryText, fontSize: 13),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding:
                            const EdgeInsets.symmetric(vertical: 6),
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: c.divider),
                        itemBuilder: (_, i) {
                          final s = _suggestions[i];
                          return InkWell(
                            onTap: () => _selectSuggestion(s),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: ShapeDecoration(
                                      color: c.accentBg,
                                      shape: SuperellipseShape(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Icon(
                                        Icons.golf_course_rounded,
                                        color: c.accent,
                                        size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.name,
                                          style: TextStyle(
                                            fontFamily: 'Nunito',
                                            color: c.primaryText,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (s.address.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            s.address,
                                            style: TextStyle(
                                                color: c.tertiaryText,
                                                fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.north_west_rounded,
                                      color: c.tertiaryText, size: 14),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }

  // ── Warning banner (accordion) ─────────────────────────────────────────────

  Widget _buildWarningBanner(AppColors c, String text) {
    const amber = Color(0xFFFF9800);
    return GestureDetector(
      onTap: () => setState(() => _warningExpanded = !_warningExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: amber.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: amber.withValues(alpha: 0.30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row (always visible) ──────────────────────────────
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: amber, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _hasUnreadable
                        ? 'Some scores could not be read'
                        : 'Review before importing',
                    style: const TextStyle(
                        color: amber,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(
                  _warningExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: amber,
                  size: 18,
                ),
              ],
            ),
            // ── Expandable detail ─────────────────────────────────────────
            if (_warningExpanded) ...[
              const SizedBox(height: 8),
              Text(
                text,
                style: const TextStyle(color: amber, fontSize: 12, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Hole table ─────────────────────────────────────────────────────────────

  Widget _buildHoleTable(AppColors c) {
    return Container(
      decoration: ShapeDecoration(
        color: c.cardBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(40),
          side: BorderSide(color: c.cardBorder),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            decoration: ShapeDecoration(
              color: const Color(0xFF1A3A08),
              shape: SuperellipseShape(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _headerCell('Hole', flex: 1),
                _headerCell('Par', flex: 2),
                _headerCell('Score', flex: 2),
                _headerCell('+/-', flex: 1, center: true),
              ],
            ),
          ),
          // Hole rows
          ..._holes.asMap().entries.map((entry) {
            final idx = entry.key;
            final h = entry.value;
            final isLast = idx == _holes.length - 1;
            final diff = h.score == 0 ? null : h.score - h.par;
            final unreadable = h.score == 0;
            return Container(
              decoration: BoxDecoration(
                color: unreadable
                    ? const Color(0xFFFF6B6B).withValues(alpha: 0.06)
                    : null,
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                            color: c.divider, width: 0.5)),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  // Hole number
                  Expanded(
                    child: Text(
                      '${h.hole}',
                      style: TextStyle(
                          color: c.secondaryText,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  // Par stepper
                  Expanded(
                    flex: 2,
                    child: _Stepper(
                      value: h.par,
                      min: 3,
                      max: 5,
                      color: c.accent,
                      onChanged: (v) =>
                          setState(() => _holes[idx].par = v),
                    ),
                  ),
                  // Score stepper
                  Expanded(
                    flex: 2,
                    child: _Stepper(
                      value: h.score,
                      min: 1,
                      max: 12,
                      color: unreadable
                          ? const Color(0xFFFF6B6B)
                          : (diff != null
                              ? _scoreColor(diff)
                              : c.accent),
                      onChanged: (v) =>
                          setState(() => _holes[idx].score = v),
                    ),
                  ),
                  // Diff chip
                  Expanded(
                    child: Center(
                      child: diff == null
                          ? Text('?',
                              style: TextStyle(
                                  color: const Color(0xFFFF6B6B),
                                  fontWeight: FontWeight.w700))
                          : _DiffChip(diff: diff),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _headerCell(String text,
      {int flex = 1, bool center = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ── Totals row ─────────────────────────────────────────────────────────────

  Widget _buildTotalsRow(AppColors c) {
    final score = _totalScore;
    final par = _totalPar;
    final diff = score - par;
    final diffLabel =
        diff == 0 ? 'E' : diff > 0 ? '+$diff' : '$diff';
    final diffColor = _scoreColor(diff);

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: ShapeDecoration(
        color: c.cardBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(32),
          side: BorderSide(color: c.cardBorder),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _totalItem(c, 'Par', '$par', c.tertiaryText),
          Container(width: 1, height: 28, color: c.divider),
          _totalItem(c, 'Score', '$score', c.primaryText),
          Container(width: 1, height: 28, color: c.divider),
          _totalItem(c, 'vs Par', diffLabel, diffColor),
        ],
      ),
    );
  }

  Widget _totalItem(
      AppColors c, String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(color: c.tertiaryText, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontFamily: 'Nunito',
                color: valueColor,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _sectionLabel(AppColors c, String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
          color: c.tertiaryText,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stepper widget
// ─────────────────────────────────────────────────────────────────────────────

class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final Color color;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepBtn(
          icon: Icons.remove,
          onTap: value > min ? () => onChanged(value - 1) : null,
          color: color,
        ),
        SizedBox(
          width: 26,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _StepBtn(
          icon: Icons.add,
          onTap: value < max ? () => onChanged(value + 1) : null,
          color: color,
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _StepBtn(
      {required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: onTap != null
              ? color.withValues(alpha: 0.12)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 12,
            color: onTap != null
                ? color
                : color.withValues(alpha: 0.25)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Diff chip
// ─────────────────────────────────────────────────────────────────────────────

class _DiffChip extends StatelessWidget {
  final int diff;
  const _DiffChip({required this.diff});

  static Color _color(int d) {
    if (d <= -2) return const Color(0xFFFFD700);
    if (d == -1) return const Color(0xFF4CAF82);
    if (d == 0) return const Color(0xFF64B5F6);
    if (d == 1) return const Color(0xFFFFB74D);
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(diff);
    final label =
        diff == 0 ? 'E' : diff > 0 ? '+$diff' : '$diff';
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Nunito',
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
