import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';
import '../theme/app_theme.dart';
import '../utils/l10n_extension.dart';

class ScorecardUploadScreen extends StatefulWidget {
  const ScorecardUploadScreen({super.key, this.initialCourseName, this.initialLocation});

  final String? initialCourseName;
  final String? initialLocation;

  @override
  State<ScorecardUploadScreen> createState() => _ScorecardUploadScreenState();
}

class _ScorecardUploadScreenState extends State<ScorecardUploadScreen> {
  final _picker       = ImagePicker();
  final _nameCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();

  bool    _analyzing = false;
  bool    _saving    = false;
  String? _error;

  CourseData? _extracted;
  int _selectedTeeIndex = 0;

  double get _sw => MediaQuery.of(context).size.width;
  double get _hPad => (_sw * 0.055).clamp(18.0, 28.0);
  double get _body => (_sw * 0.036).clamp(13.0, 16.0);
  double get _label => (_sw * 0.030).clamp(11.0, 13.0);

  @override
  void initState() {
    super.initState();
    _nameCtrl.text     = widget.initialCourseName ?? '';
    _locationCtrl.text = widget.initialLocation   ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  // ── Image picker ─────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    setState(() { _error = null; _extracted = null; });
    try {
      final file = await _picker.pickImage(
        source:       source,
        imageQuality: 85,
        maxWidth:     1800,
      );
      if (file == null || !mounted) return;
      final bytes    = await file.readAsBytes();
      final mimeType = file.mimeType ?? 'image/jpeg';
      await _analyze(bytes, mimeType);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not open image.');
    }
  }

  Future<void> _analyze(Uint8List bytes, String mimeType) async {
    setState(() => _analyzing = true);
    try {
      final data   = await CourseService.analyzeScorecard(bytes, mimeType);
      final course = _parseCourseData(data);
      if (mounted) {
        setState(() {
          _extracted        = course;
          _selectedTeeIndex = 0;
          _analyzing        = false;
        });
        _nameCtrl.text     = course.name.isNotEmpty     ? course.name     : _nameCtrl.text;
        _locationCtrl.text = course.location.isNotEmpty ? course.location : _locationCtrl.text;
      }
    } catch (e) {
      if (mounted) setState(() { _error = context.l10n.scorecardUploadFailed(e.toString()); _analyzing = false; });
    }
  }

  CourseData _parseCourseData(Map<String, dynamic> data) {
    final tees = (data['tees'] as List<dynamic>? ?? [])
        .map((t) => CourseTee.fromJson(t as Map<String, dynamic>))
        .toList();
    return CourseData(
      id:       CourseService.docId(data['courseName'] as String? ?? ''),
      name:     data['courseName'] as String? ?? '',
      location: data['location']   as String? ?? '',
      tees:     tees,
    );
  }

  Future<void> _save() async {
    final course = _extracted;
    if (course == null) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { setState(() => _error = context.l10n.scorecardUploadValidation); return; }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final updated = CourseData(
      id:       CourseService.docId(name),
      name:     name,
      location: _locationCtrl.text.trim(),
      tees:     course.tees,
    );
    setState(() => _saving = true);
    try {
      await CourseService.saveCourse(updated, uid);
      if (mounted) Navigator.of(context).pop(updated);
    } catch (e) {
      if (mounted) setState(() { _saving = false; _error = 'Save failed: $e'; });
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
        elevation:       0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.primaryText, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _extracted != null ? context.l10n.scorecardUploadReviewTitle : context.l10n.scorecardUploadUploadTitle,
          style: TextStyle(color: c.primaryText, fontWeight: FontWeight.w700, fontSize: _body * 1.1),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _analyzing
              ? _buildAnalyzing(c)
              : _extracted != null
                  ? _buildReview(c)
                  : _buildPickerView(c),
        ),
      ),
    );
  }

  // ── Picker view ──────────────────────────────────────────────────────────

  Widget _buildPickerView(AppColors c) {
    return SingleChildScrollView(
      key: const ValueKey('picker'),
      padding: EdgeInsets.symmetric(horizontal: _hPad, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Illustration card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: ShapeDecoration(
              color: c.cardBg,
              shape: SuperellipseShape(borderRadius: BorderRadius.circular(28)),
              shadows: c.cardShadow,
            ),
            child: Column(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color:        c.accentBg,
                    borderRadius: BorderRadius.circular(24),
                    border:       Border.all(color: c.accentBorder),
                  ),
                  child: Icon(Icons.document_scanner_outlined, color: c.accent, size: 30),
                ),
                const SizedBox(height: 16),
                Text(context.l10n.scorecardUploadTitle,
                    style: TextStyle(color: c.primaryText, fontSize: _body * 1.1, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    context.l10n.scorecardUploadDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.secondaryText, fontSize: _label * 1.1, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          _sectionLabel(c, context.l10n.scorecardUploadChooseSource),
          const SizedBox(height: 12),

          // Camera button
          _actionButton(
            icon:   Icons.camera_alt_rounded,
            label:  context.l10n.scorecardUploadTakePhoto,
            onTap:  () => _pickImage(ImageSource.camera),
            c:      c,
            filled: true,
          ),
          const SizedBox(height: 10),
          // Gallery button
          _actionButton(
            icon:   Icons.photo_library_rounded,
            label:  context.l10n.scorecardUploadFromGallery,
            onTap:  () => _pickImage(ImageSource.gallery),
            c:      c,
            filled: false,
          ),

          if (_error != null) ...[
            const SizedBox(height: 20),
            _errorBanner(c, _error!),
          ],
        ],
      ),
    );
  }

  // ── Analyzing ─────────────────────────────────────────────────────────────

  Widget _buildAnalyzing(AppColors c) {
    return Center(
      key: const ValueKey('analyzing'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color:        c.accentBg,
              borderRadius: BorderRadius.circular(24),
              border:       Border.all(color: c.accentBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: CircularProgressIndicator(color: c.accent, strokeWidth: 2.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(context.l10n.scorecardUploadAnalyzing,
              style: TextStyle(color: c.primaryText, fontSize: _body, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(context.l10n.scorecardUploadAnalyzingNote,
              style: TextStyle(color: c.tertiaryText, fontSize: _label)),
        ],
      ),
    );
  }

  // ── Review view ───────────────────────────────────────────────────────────

  Widget _buildReview(AppColors c) {
    final course  = _extracted!;
    final hasTees = course.tees.isNotEmpty;

    return SingleChildScrollView(
      key: const ValueKey('review'),
      padding: EdgeInsets.symmetric(horizontal: _hPad, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Course name + location card
          Container(
            padding: EdgeInsets.all((_sw * 0.045).clamp(14.0, 20.0)),
            decoration: ShapeDecoration(
              color: c.cardBg,
              shape: SuperellipseShape(borderRadius: BorderRadius.circular(24)),
              shadows: c.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel(c, context.l10n.scorecardUploadCourseName),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameCtrl,
                  style: TextStyle(color: c.primaryText, fontSize: _body * 1.1, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText:        context.l10n.scorecardUploadCourseNameHint,
                    hintStyle:       TextStyle(color: c.tertiaryText, fontWeight: FontWeight.w400),
                    filled:          true,
                    fillColor:       c.fieldBg,
                    enabledBorder:   OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:   BorderSide(color: c.fieldBorder),
                    ),
                    focusedBorder:   OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:   BorderSide(color: c.accent, width: 1.5),
                    ),
                    contentPadding:  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    isDense:         true,
                    prefixIcon: Icon(Icons.golf_course_rounded, color: c.fieldIcon, size: _body * 1.2),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _locationCtrl,
                  style: TextStyle(color: c.secondaryText, fontSize: _body),
                  decoration: InputDecoration(
                    hintText:        context.l10n.scorecardUploadCityState,
                    hintStyle:       TextStyle(color: c.tertiaryText),
                    filled:          true,
                    fillColor:       c.fieldBg,
                    enabledBorder:   OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:   BorderSide(color: c.fieldBorder),
                    ),
                    focusedBorder:   OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:   BorderSide(color: c.accent, width: 1.5),
                    ),
                    contentPadding:  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    isDense:         true,
                    prefixIcon: Icon(Icons.location_on_outlined, color: c.fieldIcon, size: _body * 1.2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (!hasTees) ...[
            _errorBanner(c, context.l10n.scorecardUploadNoTeeData),
          ] else ...[
            // Tee chips
            if (course.tees.length > 1) ...[
              _sectionLabel(c, context.l10n.scorecardUploadSelectTee),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(course.tees.length, (i) {
                    final tee = course.tees[i];
                    final sel = i == _selectedTeeIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTeeIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin:   const EdgeInsets.only(right: 8),
                        padding:  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: ShapeDecoration(
                          color: sel ? c.accentBg : c.cardBg,
                          shape: SuperellipseShape(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: sel ? c.accentBorder : c.fieldBorder,
                              width: sel ? 1.5 : 1.0,
                            ),
                          ),
                        ),
                        child: Text(
                          tee.name,
                          style: TextStyle(
                            color:      sel ? c.accent : c.secondaryText,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            fontSize:   _label * 1.1,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Hole table
            _buildHoleTable(course.tees[_selectedTeeIndex], c),
          ],

          if (_error != null) ...[
            const SizedBox(height: 12),
            _errorBanner(c, _error!),
          ],

          const SizedBox(height: 28),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() { _extracted = null; _error = null; }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: ShapeDecoration(
                      color: c.cardBg,
                      shape: SuperellipseShape(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: c.fieldBorder),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(context.l10n.scorecardUploadRetake,
                        style: TextStyle(color: c.secondaryText, fontWeight: FontWeight.w600, fontSize: _body)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: hasTees && !_saving ? _save : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: ShapeDecoration(
                      color: hasTees ? c.accent : c.accentBg,
                      shape: SuperellipseShape(borderRadius: BorderRadius.circular(14)),
                    ),
                    alignment: Alignment.center,
                    child: _saving
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(context.l10n.scorecardUploadSaveUse,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: _body)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Hole table ────────────────────────────────────────────────────────────

  Widget _buildHoleTable(CourseTee tee, AppColors c) {
    final displayHoles = tee.effectiveHoles;
    final hasYardage   = displayHoles.any((h) => h.yardage  > 0);
    final hasHandicap  = displayHoles.any((h) => h.handicap > 0);
    final cols         = [
      context.l10n.scorecardUploadHoleHeader,
      context.l10n.scorecardUploadParHeader,
      if (hasYardage) context.l10n.scorecardUploadYdsHeader,
      if (hasHandicap) context.l10n.scorecardUploadHcpHeader,
    ];

    return Container(
      decoration: ShapeDecoration(
        color: c.cardBg,
        shape: SuperellipseShape(borderRadius: BorderRadius.circular(24)),
        shadows: c.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            color: c.accentBg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: cols.map((h) => Expanded(
                child: Text(h,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.accent, fontWeight: FontWeight.w700,
                      fontSize: _label, letterSpacing: 0.8)),
              )).toList(),
            ),
          ),
          // Rows
          ...displayHoles.asMap().entries.map((entry) {
            final i = entry.key;
            final h = entry.value;
            final isOdd      = i.isOdd;
            final hasWarning = h.par == 0 || (hasYardage && h.yardage == 0);
            return Container(
              color: hasWarning
                  ? Colors.red.shade50
                  : isOdd
                      ? c.accentBg.withValues(alpha: 0.4)
                      : c.cardBg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(child: _cell(h.hole.toString(), c, bold: true,
                      color: hasWarning ? Colors.red.shade700 : c.accent)),
                  Expanded(child: _cell(h.par == 0 ? '—' : h.par.toString(), c,
                      color: hasWarning ? Colors.red.shade600 : c.primaryText)),
                  if (hasYardage)
                    Expanded(child: _cell(h.yardage == 0 ? '—' : h.yardage.toString(), c,
                        color: hasWarning ? Colors.red.shade600 : c.secondaryText)),
                  if (hasHandicap)
                    Expanded(child: _cell(h.handicap == 0 ? '—' : h.handicap.toString(), c,
                        color: c.tertiaryText)),
                ],
              ),
            );
          }),
          // Rating footer
          if (tee.courseRating > 0 || tee.slopeRating > 0)
            Container(
              color: c.accentBg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_golf_rounded, size: 13, color: c.accent),
                  const SizedBox(width: 6),
                  Text(context.l10n.scorecardUploadRatingFooter(tee.courseRating.toStringAsFixed(1)),
                      style: TextStyle(color: c.accent, fontSize: _label, fontWeight: FontWeight.w600)),
                  Container(width: 1, height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: c.accentBorder),
                  Text(context.l10n.scorecardUploadSlopeFooter(tee.slopeRating.toString()),
                      style: TextStyle(color: c.accent, fontSize: _label, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(String text, AppColors c, {bool bold = false, Color? color}) =>
      Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color:      color ?? c.primaryText,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            fontSize:   _body,
          ));

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(AppColors c, String text) => Text(
        text,
        style: TextStyle(
          color:       c.accent,
          fontSize:    _label,
          fontWeight:  FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required AppColors c,
    required bool filled,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: ShapeDecoration(
            color: filled ? c.accent : c.cardBg,
            shape: SuperellipseShape(
              borderRadius: BorderRadius.circular(14),
              side: filled
                  ? BorderSide.none
                  : BorderSide(color: c.accentBorder, width: 1.5),
            ),
            shadows: filled ? null : c.cardShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: filled ? Colors.white : c.accent, size: _body * 1.3),
              const SizedBox(width: 10),
              Text(label,
                  style: TextStyle(
                    color:      filled ? Colors.white : c.accent,
                    fontWeight: FontWeight.w600,
                    fontSize:   _body,
                  )),
            ],
          ),
        ),
      );

  Widget _errorBanner(AppColors c, String message) => Container(
        padding: const EdgeInsets.all(14),
        decoration: ShapeDecoration(
          color: Colors.red.shade50,
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.red.shade200),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: TextStyle(color: Colors.red.shade700, fontSize: _label * 1.05, height: 1.4)),
            ),
          ],
        ),
      );
}
